# Run only on a macOS build host. Emits project binaries; never Apple SDK files.
set -Eeuo pipefail
[[ $(uname -s) == Darwin ]]
[[ -n ${THEOS:-} && -f "$THEOS/makefiles/common.mk" ]]
work=$(pwd)
out="$work/port-artifacts"
[[ ! -e "$out" ]]
mkdir "$out"
python3 misc/macws_artifact_contract.py snapshot --root "$work" --manifest "$out/source-snapshot.json"
gmake -C MacWSWindowing clean all FINALPACKAGE=1 STRIP=0 OPTFLAG=-O2 \
    THEOS_PACKAGE_SCHEME=rootless GO_EASY_ON_ME=1
built=MacWSWindowing/.theos/obj/MacWSWindowing.dylib
[[ -s "$built" ]]
dyld_info -arch arm64e -fixups "$built" > "$out/Windowing-fixups.txt"
auth=$(awk '$2 == "__cfstring" && $4 == "auth-bind" && /key=DA/ {n++} END {print n+0}' "$out/Windowing-fixups.txt")
plain=$(awk '$2 == "__cfstring" && $4 == "bind" {n++} END {print n+0}' "$out/Windowing-fixups.txt")
[[ $auth -gt 0 && $plain -eq 0 ]]
otool -L "$built" > "$out/Windowing-load-commands.txt"
! grep -q $'\t/Library/' "$out/Windowing-load-commands.txt"
grep -q $'\t@rpath/CydiaSubstrate.framework/CydiaSubstrate ' "$out/Windowing-load-commands.txt"
cp "$built" "$out/MacWSWindowing.dylib"
python3 misc/macws_artifact_contract.py create --root "$work" \
    --binary "$out/MacWSWindowing.dylib" --manifest "$out/MacWSWindowing.build.json" \
    --source-snapshot "$out/source-snapshot.json"
shasum -a 256 "$out/MacWSWindowing.dylib" > "$out/MacWSWindowing.sha256"
mac_version=$(xcrun --sdk macosx --show-sdk-version)
gmake -C launchservicesd clean all FINALPACKAGE=1 STRIP=0 \
    TARGET="macosx:clang:${mac_version}:13.0" SDKVERSION="$mac_version" GO_EASY_ON_ME=1
guest=launchservicesd/.theos/obj/launchservicesd
[[ -s "$guest" ]]
vtool -show-build "$guest" > "$out/launchservicesd-platform.txt"
grep -q 'platform MACOS' "$out/launchservicesd-platform.txt"
lipo -verify_arch arm64 "$guest"
cp "$guest" "$out/launchservicesd"
shasum -a 256 "$out/launchservicesd" > "$out/launchservicesd.sha256"
sw_vers > "$out/build-host.txt"
xcrun clang --version >> "$out/build-host.txt"
git rev-parse HEAD > "$out/source-revision.txt"
printf 'Apple-linked artifacts built; device runtime acceptance remains pending.\n'
