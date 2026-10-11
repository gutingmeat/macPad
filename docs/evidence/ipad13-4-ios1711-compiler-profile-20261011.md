# iPad13,4 / iPadOS 17.1.1 compiler identity profile

Date: 2026-10-11. Host: iPad13,4, M1/T8103, 8 GB, iPadOS 17.1.1 / 21B91,
Dopamine rootless. Base source: `a18da08455d8aac96d53b6fe2a00699c4b97f56c`.

## Scope and acceptance boundary

This change adds an exact executable identity to the existing compiler-request
adapter. It retains every instruction, branch-range and wrapper-entry check,
and does not alter the three previously admitted iOS 16 profiles. Unknown
executables retain stock behavior. The reply observer remains diagnostic-only.

**Not yet accepted:** macOS-target compiler requests, native iOS regression,
guest shader reflection, vertex descriptors, WindowServer startup, GPU rendering
and desktop interaction on 21B91. No macPad tweak has been installed on the
device. This profile must not promote iPadOS 17.1.1 into the supported matrix.

## Device-side identity

The executable was read and analyzed on the device. Apple binaries were not
exported or added to Git.

- Path: `/System/Library/Frameworks/Metal.framework/XPCServices/MTLCompilerService.xpc/MTLCompilerService`
- Size: 88,096 bytes
- CPU subtype: arm64e, PAC00
- UUID: `0C384BBA-F155-3104-8E77-EFF227A7F413`
- SHA-256: `b584c2e5b1e80762db5ced927afde1562635a855c52a6f3fc8e48cee20b95f2c`

## RE-confirmed call sites

Device-side LLVM 16 disassembly of `_compileRequestMain` and
`____ZL29MTLCompilerServiceHandleEventPU24objcproto13OS_xpc_object8NSObject_block_invoke`
confirms the service-vtable `+0x18` calls with the original six arguments.
The handler's unrelated `+0x20` call at `+0x21a8` is intentionally excluded.

| Role | Executable offset | Original instruction |
| --- | --- | --- |
| Worker build | `0x1e38` | `0xd63f093f`, `blraaz x9` |
| Handler build, timer path | `0x236c` | `0xd63f091f`, `blraaz x8` |
| Handler build, alternate path | `0x23a4` | `0xd63f091f`, `blraaz x8` |
| Optional reply-data observer | `0x24ec` | `0x94000511`, `bl _xpc_data_create` |

All four instruction words were independently checked against the executable
using its on-device bytes:

```text
offset=0x1e38 expected=0xd63f093f actual=0xd63f093f matches=True
offset=0x236c expected=0xd63f091f actual=0xd63f091f matches=True
offset=0x23a4 expected=0xd63f091f actual=0xd63f091f matches=True
offset=0x24ec expected=0x94000511 actual=0x94000511 matches=True
```

The optional observer call lies in the service reply block; it is not evidence
that guest reflection formats are compatible and must remain disabled in normal
operation.

## Next checks

Build with the appropriate arm64e authenticated fixups, confirm the original
`MTLCodeGenServiceBuildRequest` export in the real injected service, and require
a bounded genuine macOS-target shader compilation plus a native iOS control.
Then proceed to guest/host GPU ABI tests. Do not suppress assertions, skip
validation, or fabricate a successful compiler result.
