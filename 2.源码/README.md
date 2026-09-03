# 笔记源码基线

本目录对应 `../1.笔记` 中全部 Markdown 笔记使用的源码证据。各仓库默认处于 detached HEAD，目的是让本地代码与笔记中的固定版本一致，而不是跟随远端分支更新。

除非段落另有说明，下面的命令都从仓库根目录运行。

## 1. 下载清单

| 本地目录 | 上游仓库 | 本地 HEAD / 对象 | 状态 | 主要对应内容 |
|---|---|---|---|---|
| `linux` | <https://github.com/torvalds/linux.git> | `248951ddc14de84de3910f9b13f51491a8cd91df` | 精确 | Linux 进程、MM/HMM、AMDGPU/KFD、GPUVM、SVM、Queue、PCIe、DMA/IOMMU |
| `rocm-clr` | <https://github.com/ROCm/clr.git> | `81277d69e3352e7144ced2ee9601484f9b48d950` | 精确 | OpenCL API、Command/Event、ROCr backend、AQL、Device Queue |
| `rocr-runtime` | <https://github.com/ROCm/rocr-runtime.git> | `ba56a24c6132c5d195686ae4adf969ca1222fbba` | 精确 | HSA Queue、signal、KFD driver、libhsakmt |
| `rocm-device-libs` | <https://github.com/ROCm/ROCm-Device-Libs.git> | `1915fc612c243bdbc656608ecba3fa9618d6afc3` | 精确，但上游快照仅含重定向 README | 笔记中的 Device Library 证据边界 |
| `pal` | <https://github.com/GPUOpen-Drivers/pal.git> | `9fab16015e522fff05890a045a1e9d8d3c23a636` | 精确 | PAL GFX9 dispatch packet 与 command buffer |
| `pocl` | <https://github.com/vortexgpgpu/pocl.git> | `42fad325efaee07915307ab802f1527171b434d0` | 精确 | POCL Command/Event 依赖图和 Vortex backend |
| `vortex` | <https://github.com/vortexgpgpu/vortex.git> | `d76b7f24e658867ab57e3942d7c648c3e6af072d` | 公开上游替代版本 | Vortex runtime Queue/Event、CP ring、device 接口 |

## 2. 两个版本边界

### 2.1 Vortex 本地 worktree

笔记记录的 Vortex 基线 `16aa1d033063c76b158923c9a1e4949747578751` 来自原环境的 `.worktrees/docker-simx-dev`。该对象不在公开的 `vortexgpgpu/vortex` 仓库中，GitHub 公共 commit 搜索也没有结果，因此无法从公开上游精确重建。

本目录保存的是能够公开取得的 Vortex 上游快照 `d76b7f24e658867ab57e3942d7c648c3e6af072d`。笔记涉及的 `sw/runtime/common/vortex2_internal.h`、`queue.cpp`、`event.cpp` 和 `device.cpp` 均存在，但涉及 Vortex 的逐行结论仍应以“替代版本”处理。POCL 的固定 Vortex fork commit 已精确取得，不受此限制。

### 2.2 历史 CLR

除当前 CLR 工作树外，参考文档还引用历史对象 `914c2eb8b60a13436eb532c9e256ad68b49e3b20`，并通过 `20c71738491871ee7d373240c0e3e51b84bcd992^1` 引用该 merge 的第一父提交。当前本地对象库既不包含 `914c2eb8b60a13436eb532c9e256ad68b49e3b20`，也不包含 merge `20c71738491871ee7d373240c0e3e51b84bcd992`，同时缺少 `refs/notes-baselines/clr-historical`，因此相关历史源码暂时无法在本地复现。

这个缺口影响 `1.笔记/5. AMD 队列提交：从 API 到 AQL 与硬件.md` 中对历史 `palvirtual.cpp` 的检索，不影响当前 CLR 工作树 `81277d69e3352e7144ced2ee9601484f9b48d950`，也不影响 `02_GPU 内存管理基础.md` 使用的现行 CLR 源码。恢复历史对象并重新建立固定 ref 后，才能再次使用原笔记中的历史检索命令。

## 3. Linux 工作树说明

Linux 使用面向笔记的 sparse checkout，保留以下源码范围：

- `drivers/gpu/drm/amd`、DRM/TTM、KFD/AMDGPU；
- `mm`、`kernel`、`include/linux`、相关 UAPI；
- `arch/x86` 与笔记引用的 RISC-V `current.h`；
- PCI/PCI Endpoint、IOMMU、DMA 与相关 Documentation。

Windows 的大小写不敏感文件系统无法同时准确展开 Linux 树中少数仅大小写不同的文件名。整体 `git status` 可能因此显示与笔记无关的 netfilter/litmus 文件差异；上述笔记相关路径已单独核验，与固定 commit 一致。

## 4. 路径对应

旧笔记中的 `.kernel-src/<repo>/...` 对应本目录的 `<repo>/...`。例如：

```text
.kernel-src/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c
→ 2.源码/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c

.kernel-src/rocm-clr/rocclr/device/rocm/rocvirtual.cpp
→ 2.源码/rocm-clr/rocclr/device/rocm/rocvirtual.cpp
```

## 5. 快速核验

```powershell
git -C .\2.源码\linux rev-parse HEAD
git -C .\2.源码\rocm-clr rev-parse HEAD
git -C .\2.源码\rocr-runtime rev-parse HEAD
git -C .\2.源码\rocm-device-libs rev-parse HEAD
git -C .\2.源码\pal rev-parse HEAD
git -C .\2.源码\pocl rev-parse HEAD
git -C .\2.源码\vortex rev-parse HEAD
```

## 6. 文档自依赖检查

从仓库根目录运行：

```powershell
pwsh -File .\tools\check-doc-dependencies.ps1
```

该检查会验证笔记中的本地 Markdown 链接、章节锚点、`2.源码/...` 路径、源码行号范围、七个源码仓库的固定 commit，以及历史 CLR 对象。检查不访问网络。当前历史 CLR 对象和固定 ref 缺失，因此检查会报告对应错误；其余固定源码基线仍可正常核验。
