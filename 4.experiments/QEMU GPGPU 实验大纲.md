# QEMU GPGPU 四阶段实验大纲

| 缩写 | 英文全称 | 中文含义 |
| --- | --- | --- |
| QEMU | Quick Emulator | 仿真与虚拟化工具 |
| GPU | Graphics Processing Unit | 图形处理器 |
| GPGPU | General-Purpose Computing on Graphics Processing Units | 利用 GPU 进行通用计算；本项目也用于指代教学计算设备 |
| CUDA | Compute Unified Device Architecture | 统一计算设备架构；此处仅用于原实验题名 |
| KFD | Kernel Fusion Driver | AMD GPU 计算相关内核驱动组件 |
| ROCm | Radeon Open Compute | AMD GPU 计算软件平台 |
| CP | Command Processor | 命令处理器 |
| DRM | Direct Rendering Manager | Linux 图形设备内核框架 |
| GEM | Graphics Execution Manager | DRM 的图形内存对象管理框架 |
| GPUVA | GPU Virtual Address | GPU 虚拟地址 |
| MMU | Memory Management Unit | 内存管理单元 |
| VMID | Virtual Memory Identifier | GPU 硬件地址空间标识 |
| TLB | Translation Lookaside Buffer | 地址翻译缓存 |
| AQL | Architected Queuing Language | HSA 定义的队列包格式与提交协议 |
| HSA | Heterogeneous System Architecture | 异构系统架构 |

## 1. 当前进度与实验范围

当前正在进行第一阶段。根据此前的实验反馈，前 10 个基础实验已完成；接下来围绕“进阶实验一：设计类 CUDA 的 GPGPU 软件栈”，实现应用到设备的计算流程。

本目录已有 `QEMU_2026_讲义.html`、`QEMU_2026_实验.html`、`QEMU_2026_GPGPU_适配.html`，以及 `gpu-study-qemu` 源码目录。后续实验沿用这些材料和代码。

**[DESIGN] 仓库与分支约束：** 实验子仓库为 [hxfei-git/gpu-study-qemu](https://github.com/hxfei-git/gpu-study-qemu)，本地目录为 `4.experiments/gpu-study-qemu`。实验开发统一在 `main` 分支进行，修改代码前先确认当前分支。原仓库 `qemu-camp/qemu-camp-2026-exper-hxfei-git` 的提交历史完整保留；子仓库的 `upstream` 远端指向原仓库，`origin` 指向新仓库。

**[DESIGN]** 参考 AMDGPU / KFD 的设计与代码，在现有设备上逐步实现计算驱动和小型用户态运行时，并按阶段引入 Linux 通用框架。先让应用能够提交计算、取得结果，再补齐任务管理、地址隔离和异常恢复。

**[BOUNDARY]** 实验对象是自定义 QEMU GPGPU 教学设备。实验中的寄存器、命令和页表设计按实际实现说明，与学习笔记中的 MI300X 模型分开；项目不以复现 MI300X 或兼容整套 ROCm 为目标。

## 2. 四阶段实验安排

**[DESIGN]** 当前只保留以下推进方向，具体实现与验证内容在进入相应阶段后展开。

```text
已有 QEMU GPGPU 实验
  → 第一阶段：应用经运行时和驱动完成一次计算（当前）
  → 第二阶段：CP 从队列取命令，异步执行并报告完成
  → 第三阶段：引入 DRM，建立和隔离 GPU 地址空间
  → 第四阶段：处理异常，恢复设备并回收资源
```

### 2.1 第一阶段：跑通应用到设备的计算流程

围绕进阶实验一，补齐 Linux 驱动、用户态运行时、代码加载和参数传递，让计算 kernel 接收输入、执行并返回可核对的结果。

### 2.2 第二阶段：加入 CP 与异步提交

在 QEMU 侧增加 CP，由驱动写入 Ring、通过 Doorbell 通知 CP 取命令。设备执行后写入完成记录并通知驱动，由驱动完成对应 Fence。

先使用简单队列和直接设备显存寻址，暂不引入 DRM / GEM 或 `drm_sched`。

### 2.3 第三阶段：引入 DRM 与虚拟地址管理

先接入 DRM / GEM，按需要引入 `drm_sched`，验证原有计算流程；再加入 GPUVA、页表、MMU、VMID 和 TLB，让地址翻译参与设备实际访存，逐步验证多进程隔离与 VMID 复用。

### 2.4 第四阶段：完善异常处理与资源释放

围绕非法命令、访问 fault、任务超时和进程退出，补齐错误返回、CP / 执行引擎中止、设备复位与资源回收，验证恢复后仍能执行正常任务。

AQL 用户队列留作四阶段之后的可选扩展，是否开展再根据项目进展决定。

## 3. 随进展调整大纲

四阶段用于说明项目的大致方向，不在开始时固定全部功能、接口、工期或验收清单。进入某一阶段后，先看已有实现、当前问题和希望跑通的场景，再细化近期任务。

每完成一段实验，或遇到影响原计划的问题，就根据代码、运行结果和学习反馈更新当前阶段，并调整后续阶段的范围与顺序。必要时拆分、合并或后移工作，避免只因最初列入某阶段就继续扩张任务。

实验计划统一在本大纲维护，当前阶段同步到根目录 `AGENTS.md`。记录进度时区分用户反馈、代码核对和运行验证，不能用文件存在代替实验完成。学习笔记中的理论缺口仍补回首次需要它的章节，第七章大纲继续管理笔记内容。
