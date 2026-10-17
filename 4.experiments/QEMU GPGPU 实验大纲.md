# QEMU GPGPU 四阶段实验大纲

| 缩写 | 英文全称 | 中文含义 |
| --- | --- | --- |
| QEMU | Quick Emulator | 仿真与虚拟化工具 |
| GPU | Graphics Processing Unit | 图形处理器 |
| GPGPU | General-Purpose Computing on Graphics Processing Units | 利用 GPU 进行通用计算；本项目的教学计算设备 |
| CUDA | Compute Unified Device Architecture | 统一计算设备架构；此处用于原实验题名 |
| ROCm | Radeon Open Compute | AMD GPU 计算软件平台 |
| ROCr | ROCm Runtime | AMD 的 HSA 用户态运行时 |
| HSA | Heterogeneous System Architecture | 异构系统架构 |
| KFD | Kernel Fusion Driver | AMD GPU 计算相关内核驱动组件 |
| CP | Command Processor | 命令处理器 |
| MEC | Micro Engine Compute | 计算命令处理微引擎 |
| AQL | Architected Queuing Language | HSA 定义的队列包格式与提交协议 |
| HQD | Hardware Queue Descriptor | 保存队列驻留状态的硬件描述 |
| MQD | Memory Queue Descriptor | 内存中的队列描述对象 |
| KIQ | Kernel Interface Queue | 内核接口队列 |
| HIQ | HSA Interface Queue | HSA 接口队列 |
| CPU | Central Processing Unit | 中央处理器 |
| RV32 | 32-bit RISC-V | 本实验计算解释器使用的 32 位 RISC-V 模型 |
| RV64 | 64-bit RISC-V | 本实验原生 CP 使用的 64 位 RISC-V 模型 |
| PCI | Peripheral Component Interconnect | 外设互连总线 |
| BAR | Base Address Register | PCI 基址寄存器；用于描述设备资源窗口 |
| VRAM | Video RAM | 设备显存 |
| DMA | Direct Memory Access | 直接内存访问 |
| IOVA | I/O Virtual Address | 设备访存使用的虚拟地址 |
| RAM | Random Access Memory | 随机存取存储器；本文分别说明 Host RAM 和 VRAM |
| IOMMU | Input/Output Memory Management Unit | 输入输出内存管理单元 |
| SMMUv3 | System Memory Management Unit version 3 | Arm 系统内存管理单元第三版 |
| MSI-X | Message Signaled Interrupts Extended | 扩展消息中断 |
| DRM | Direct Rendering Manager | Linux 图形设备内核框架 |
| GEM | Graphics Execution Manager | DRM 图形内存对象管理框架 |
| GPUVA | GPU Virtual Address | GPU 虚拟地址 |
| MMU | Memory Management Unit | 内存管理单元 |
| VMID | Virtual Memory Identifier | 设备虚拟地址空间标识 |
| TLB | Translation Lookaside Buffer | 地址翻译缓存 |
| ReLU | Rectified Linear Unit | 修正线性单元；本实验的计算示例之一 |

<a id="current-progress"></a>

## 1. 当前进度与阅读入口

根据用户反馈，前 10 个基础实验和第一阶段“进阶实验一：设计类 CUDA 的 GPGPU 软件栈”已完成，并已搭配 A57、支持 SMMUv3 系统 IOMMU。第一阶段成果继续使用，当前进入第二阶段：用户 AQL Queue、Doorbell、CP 与 Signal。

2026-10-11 已完成双进程设备与原生 RV32 CP 基础接入，包括复位、固件装载、启动和同地址替换固件。2026-10-14 完成 CP Host 访存窗口：CP 用普通读写指令经 IOVA 访问 Host RAM，Host 继续通过 BAR2 和原 DMA 访问 VRAM。CP 回归通过 8/8，双进程和单进程 IOMMU 回归各通过 2/2，原有 A57 GPGPU 设备测试通过 21/21；实现与复现命令见[窗口实现说明](<./CP_MEC 软件实现、参考与扩展.md#cp-host-window-implementation>)。

2026-10-17 原生 CP 已迁移至 RV64，Host 窗口支持自然对齐的 1/2/4/8 字节读写，裸机物理访存、地址编码及 RV32 计算解释器保持原约定。复用现有 CP 用例通过 8/8，单／双进程 IOMMU 各 2/2、两种架构的原有设备用例各 21/21 及 RV32 汇编检查 4/4 通过。Linux 单／双进程与 `none`／`smmuv3` 四种组合均通过三个示例的 17,953 个输出值、68 项运行时检查及装卸载检查；详细验证记录继续保存在上述窗口实现说明中。

队列部分已确认第一版架构，软件接口仍需逐项补齐；尚未记录队列功能实现完成或第二阶段整体验收通过。第一阶段的软件栈和构建入口见[子仓库软件栈说明](<./gpu-study-qemu/software/gpgpu/README.md>)。

本目录的三篇文档分别用于安排实验、查阅约定和理解实现：

- 本大纲维护四阶段安排、当前进度、近期工作和阶段完成标准。
- [CP/MEC 第一版规格](<./CP_MEC 第一版规格.md#spec-overview>)统一维护已确认架构、行为与接口；未定项集中在[待确认接口](<./CP_MEC 第一版规格.md#spec-open-interfaces>)。
- [CP/MEC 软件实现、参考与扩展](<./CP_MEC 软件实现、参考与扩展.md>)说明现有代码怎样配合，保存详细例子、AMD 与 gem5 依据、寄存器取舍及后续扩展。

原有 HTML 讲义、实验材料和 `gpu-study-qemu` 源码继续保留。代码配套文档随子仓库版本维护，本大纲通过链接引用，不另抄一套构建步骤。

**[DESIGN]** 最终目标是参考 ROCr / HSA / KFD 的软件分层、对象关系和提交语义，形成类 AMD 的 GPGPU 教学软件栈。实验对象是自定义 QEMU 设备，寄存器、命令和地址设计按本项目约定实现；不以复现 MI300X 或兼容整套 ROCm 为目标。

实验子仓库为 [hxfei-git/gpu-study-qemu](https://github.com/hxfei-git/gpu-study-qemu)，本地目录是 `4.experiments/gpu-study-qemu`，开发统一使用 `main` 分支。原仓库的提交历史保留，`upstream` 指向原仓库，`origin` 指向新仓库；修改代码前先确认分支和现有工作区状态。

## 2. 四阶段实验安排

第一阶段已完成，当前细化第二阶段。第三、第四阶段只保留推进方向，进入相应阶段后再展开。

```text
第一阶段：应用经运行时和驱动完成计算（已完成）
  → 第二阶段：用户发布 AQL，CP 取包派发，Signal 报告完成（当前）
  → 第三阶段：引入 DRM，建立并隔离 GPU 地址空间
  → 第四阶段：完善异常恢复与资源回收
```

### 2.1 第一阶段：跑通应用到设备的计算流程

已完成 Linux 驱动、用户态运行时、代码加载和参数传递，让计算 kernel 接收输入、执行并返回可核对的结果。A57、PCI / BAR、VRAM、DMA、SMMUv3、MSI-X、RV32 计算解释器及已有计算示例继续作为后续阶段的基础。新增 CP 队列路径时，保留原同步路径的回归验证。

### 2.2 第二阶段：用户 AQL Queue、Doorbell、CP 与 Signal

本阶段要让应用连续发布任务，由设备独立推进计算；提交返回后，应用通过完成对象等待结果。驱动管理资源和队列，运行时组织命令包，CP 固件负责读取、解析和派发。

```text
Host 装载 CP 固件，建立首次 KIQ
  → 通过管理命令建立后续队列
  → 运行时准备代码、参数和 Signal，向用户 Ring 发布 AQL Packet
  → Doorbell 通知设备检查生产进度
  → CP 从自己的消费位置读取任务，交给计算执行器
  → 计算完成并收尾，CP 发布 Signal，回报消费进度
  → 应用检查结果，驱动按卸载协议释放队列资源
```

第一版的队列分工、阻塞执行、消费时序和管理完成协议以[规格](<./CP_MEC 第一版规格.md>)为准。本大纲不再单独规定队列数量、Ring 容量、索引位宽或内存布局。

近期按依赖顺序推进：

1. 补齐接口。先确认地址与访存、MQD 和管理命令，再确认 Ring 发布、进度、计算派发、Signal、错误和卸载。每项决定写回规格对应位置。
2. 接入设备与固件。实现 HQD 访问、管理命令、取包和计算交接，用 QTest 构造任务验证设备行为。
3. 接入驱动和运行时。按[Host 软件流程](<./CP_MEC 软件实现、参考与扩展.md#host-software-flow>)实现创建、映射、提交、等待、卸载与释放，先运行向量加法，再接入矩阵乘和 ReLU。
4. 验证连续提交和失败收尾。覆盖槽位循环复用、队列满、重复或连续 Doorbell、未发布的包、错误完成对象、参数提前复用、计算失败，以及 Ring 读取或 Signal 写回失败；软件侧覆盖创建失败回滚、执行中进程退出和旧映射仍在时的资源保护。

第二阶段的完成标准是：应用能够连续提交多个 AQL 任务；正常提交不等待 Kernel 完成；CP 按已确认规则处理队列；任务结果、消费进度和管理完成分别可观察；成功卸载后设备不再访问已释放的队列资源。

验证应覆盖 `none`、`smmuv3` 两种配置，并保留第一阶段回归。具体断言随接口确定，记录实际运行结果后再更新完成状态；文档写完不作为实现完成依据。

### 2.3 第三阶段：引入 DRM 与虚拟地址管理

先接入 DRM / GEM，再加入 GPUVA、页表、MMU、VMID 和 TLB，使地址翻译参与设备实际访存，逐步验证多进程隔离与 VMID 复用。第二阶段已确认的 VMID 概念及管理地址空间约定继续保留；VMID 数量和具体访存接口仍须按规格中的待定项确认，不因阶段划分自行取消或提前定稿。

普通 DRM 命令提交及 `drm_sched` 按学习需要展开，与用户 AQL Queue 分别说明，不要求每个 AQL Packet 都先包装成普通 DRM job。

### 2.4 第四阶段：完善异常处理与资源释放

在第二阶段的队列卸载和资源保护基础上，围绕非法命令、访问 fault、任务超时及进程退出，完善 CP / 执行引擎中止、设备复位和恢复，验证恢复后能够继续执行正常任务。AQL 用户队列仍属于第二阶段的必达范围。

## 3. 后续扩展与进度维护

后续需要增加 Kernel 执行中途暂停、让出计算资源和恢复执行的能力。第一版暂不采用上下文保存寄存器组；相关接口、现场保存与恢复、完成状态管理见[后续扩展](<./CP_MEC 软件实现、参考与扩展.md#extensions>)。实施阶段随执行器和多队列功能的进展确定，当前不预设工期。

四阶段说明推进方向，不预先固定全部功能和接口。每完成一段实验，或遇到影响计划的问题，就根据代码、运行结果与学习反馈调整近期工作。实验计划统一在本大纲维护，当前阶段同步到根目录 `AGENTS.md`；学习笔记中的理论缺口仍补回首次需要它的位置，第七章大纲继续管理后续笔记。
