# AQL 应用的完整运行流程：驱动初始化、执行与资源释放（下）

| 缩写    | 英文全称                                        | 中文含义                                               |
| ------- | ----------------------------------------------- | ------------------------------------------------------ |
| AMDGPU  | AMD GPU Linux Kernel Driver                     | Linux 中的 AMD GPU 驱动                                |
| API     | Application Programming Interface               | 应用程序编程接口                                       |
| AQL     | Architected Queuing Language                    | HSA 的队列包格式与提交协议                             |
| BAR     | Base Address Register                           | PCIe 基址寄存器；描述设备地址窗口                      |
| BO      | Buffer Object                                   | 驱动管理的缓冲对象                                     |
| BSP     | Board Support Package                           | 板级支持包                                             |
| CDNA    | Compute DNA                                     | AMD 数据中心计算 GPU 架构系列                          |
| CLR     | Compute Language Runtime                        | ROCm 的高层语言运行时公共实现                          |
| CP      | Command Processor                               | GPU 命令处理器                                         |
| CPSCH   | Command Processor Scheduling                    | 命令处理器固件调度路径                                 |
| CPU     | Central Processing Unit                         | 中央处理器                                             |
| CU      | Compute Unit                                    | GPU 计算单元                                           |
| CWSR    | Compute Wave Save and Restore                   | 计算 Wave 执行现场的保存与恢复                         |
| DMA     | Direct Memory Access                            | 设备直接访问内存的机制                                 |
| DMA-BUF | Direct Memory Access Buffer                     | Linux 缓冲区共享机制                                   |
| DQM     | Device Queue Manager                            | KFD 的设备队列管理器                                   |
| DRM     | Direct Rendering Manager                        | Linux 图形设备管理框架                                 |
| FD      | File Descriptor                                 | 文件描述符，正文写作 fd                                |
| FIFO    | First In, First Out                             | 先进先出队列                                           |
| GART    | Graphics Address Remapping Table                | AMDGPU 访问系统内存所用的地址重映射表                  |
| GEM     | Graphics Execution Manager                      | DRM 缓冲对象及相关接口的通用支持                       |
| GFP     | Get Free Pages                                  | Linux 内存分配标志                                     |
| GFX     | Graphics                                        | AMD 驱动中的图形／计算核心 IP 命名                     |
| GMC     | Graphics Memory Controller                      | 驱动中的 GPU 内存控制模块                              |
| GPU     | Graphics Processing Unit                        | 图形处理器                                             |
| GPUVA   | GPU Virtual Address                             | GPU 虚拟地址                                           |
| GPUVM   | GPU Virtual Memory                              | GPU 虚拟地址空间及其页表管理                           |
| GTT     | Graphics Translation Table                      | 本文指 AMDGPU 中可供设备访问的系统内存资源域           |
| HBM     | High Bandwidth Memory                           | 高带宽内存；本例为设备本地显存                         |
| HIP     | Heterogeneous-compute Interface for Portability | AMD 异构计算编程接口                                   |
| HIQ     | HSA Interface Queue                             | KFD 向设备提交调度管理命令的内部队列                   |
| HMM     | Heterogeneous Memory Management                 | Linux 异构内存管理机制                                 |
| HQD     | Hardware Queue Descriptor                       | 计算 Queue 驻留时使用的硬件描述状态                    |
| HSA     | Heterogeneous System Architecture               | 异构系统架构                                           |
| HSAKMT  | HSA Kernel Mode Thunk                           | 用户态与 KFD 交互的接口层                              |
| HWS     | Hardware Scheduling                             | KFD 使用硬件／固件进行队列调度的模式                   |
| IB      | Indirect Buffer                                 | 存放设备命令的间接缓冲区                               |
| ID      | Identifier                                      | 标识符或编号，具体作用取决于所属对象                   |
| IH      | Interrupt Handler                               | AMDGPU 的中断记录与处理模块                            |
| IOMMU   | Input/Output Memory Management Unit             | 设备访问主机内存时使用的地址翻译单元                   |
| IOVA    | I/O Virtual Address                             | Host IOMMU 翻译前的设备地址                            |
| IP      | Intellectual Property                           | 本文指按功能组织的硬件模块                             |
| IRQ     | Interrupt Request                               | 中断请求                                               |
| ISA     | Instruction Set Architecture                    | 指令集架构                                             |
| KFD     | Kernel Fusion Driver                            | AMD GPU 的 Linux 计算驱动接口                          |
| KiB     | Kibibyte                                        | 二进制千字节；1 KiB = 1024 字节                        |
| KIQ     | Kernel Interface Queue                          | AMDGPU 内核使用的控制队列                              |
| KMS     | Kernel Mode Setting                             | 内核显示模式设置                                       |
| LDS     | Local Data Share                                | CU 上供同组工作共享的局部存储                          |
| MEC     | Micro Engine Compute                            | AMD GPU 处理计算队列的命令处理引擎                     |
| MES     | Micro Engine Scheduler                          | AMD 的一种设备队列调度实现；本例关闭此分支             |
| MMU     | Memory Management Unit                          | 内存管理单元                                           |
| MQD     | Memory Queue Descriptor                         | 保存在内存中的 Queue 配置与状态描述                    |
| OpenCL  | Open Computing Language                         | 开放计算语言及其异构计算接口                           |
| PASID   | Process Address Space ID                        | 设备使用的进程地址空间标识                             |
| PC      | Program Counter                                 | 程序计数器；记录下一条要执行的指令地址                 |
| PCI     | Peripheral Component Interconnect               | 外设互连；本文也用于 Linux PCI 子系统名称              |
| PCIe    | Peripheral Component Interconnect Express       | Host 与 MI300X 之间的高速互连                          |
| PDD     | Process Device Data                             | KFD 中某个进程在某个逻辑 GPU 上的记录                  |
| PM4     | AMD PM4                                         | AMD 驱动与设备使用的一类命令包格式                     |
| PQM     | Process Queue Manager                           | KFD 的进程队列管理器                                   |
| PSP     | Platform Security Processor                     | 参与 GPU 固件装载等工作的安全处理器                    |
| PTE     | Page Table Entry                                | 页表项                                                 |
| QPD     | Queue Process Device Data                       | PDD 内嵌的队列与调度状态，类型为`qcm_process_device` |
| RAM     | Random-Access Memory                            | 随机存取存储器；system RAM 指主机内存                  |
| RLC     | Run List Controller                             | GPU 运行列表控制器                                     |
| ROCm    | Radeon Open Compute                             | AMD GPU 计算软件平台                                   |
| ROCr    | ROCm Runtime                                    | ROCm 的 HSA 用户态运行时                               |
| SDMA    | System Direct Memory Access                     | AMD GPU 中执行数据搬运等操作的专用引擎                 |
| SVM     | Shared Virtual Memory                           | 共享虚拟内存                                           |
| syncobj | Synchronization Object                          | DRM 同步对象，保存完成 Fence 的引用                    |
| sysfs   | sysfs (system filesystem)                       | Linux 导出设备拓扑和内核对象属性的虚拟文件系统         |
| TLB     | Translation Lookaside Buffer                    | 地址翻译缓存                                           |
| TTM     | Translation Table Maps                          | DRM 中的通用缓冲对象内存管理机制                       |
| USERPTR | User Pointer                                    | 用户提供的地址及其后备页面路径                         |
| VM      | Virtual Memory                                  | 虚拟内存或对应地址空间                                 |
| VMA     | Virtual Memory Area                             | Linux 中连续虚拟地址范围的管理对象                     |
| VMID    | Virtual Memory ID                               | GPU 硬件地址空间上下文编号                             |
| VRAM    | Video Random-Access Memory                      | 设备本地显存；本例对应 MI300X 的 HBM                   |
| XCC     | Accelerator Core Complex                        | 驱动描述的计算复合体实例                               |
| XCD     | Accelerator Complex Die                         | MI300X 的计算芯粒                                      |
| XNACK   | XNACK（AMD 功能名称）                           | GPU 缺页后重试访存的能力及相应进程模式                 |
| EOP     | End of Pipe                                     | 管线末端；本文指 Queue 使用的 EOP 支持缓冲             |
| GWS     | Global Wave Sync                                | 设备级 Wave 同步资源                                   |
| IDR     | ID Radix Tree                                   | Linux 按整数编号保存与查找对象的机制                   |
| ioctl   | Input/Output Control                            | 用户态向内核驱动发送控制请求的接口                     |
| ISR     | Interrupt Service Routine                       | 中断服务例程；本文指筛选中断记录的回调                 |
| RCU     | Read-Copy Update                                | 读、复制、更新；用于并发读者与对象移除协调             |
| SMI     | System Management Interface                     | 系统管理事件接口                                       |
| SRCU    | Sleepable Read-Copy Update                      | 允许读侧睡眠的 RCU 变体                                |

## 本篇大纲

[上半篇](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md>)已介绍 DRM 与 AMDGPU 的框架关系、设备初始化，以及 P 的进程对象、GPUVM、Q0 和可复用存储。本篇为 06 下半篇，包含第 3～6 章：从 P 已有这些资源、准备发起本轮 `vector_add` 开始，继续追踪用户态发布、设备执行、完成通知、下一轮复用和退出收尾，最后通过源码追踪与故障推演检查理解。两篇共用章节编号、术语、贯穿案例和固定源码基线，阅读跨篇小节时沿相对链接回查。

![五段运行流程：前一步留下资源，后一步使用这些资源继续推进](./assets/06/application-lifecycle.png)

这是两篇共用的软件调用与资源使用流程图。本篇展开任务执行、完成与退出，前两段的资源准备回查上篇。[可编辑源图](./assets/06/application-lifecycle.svg)。

- [3. 一项计算从 Runtime 请求到 GPU 执行](#3-一项计算从-runtime-请求到-gpu-执行)：先讲 Queue 驻留与设备执行，再回到 Host 的代码与数据准备、软件提交和 Packet 发布；最后分别看跨 Queue 依赖、多进程调度和缺页三个变体。
- [4. 任务完成：通知 Host 并继续应用工作](#4-任务完成通知-host-并继续应用工作)：区分任务完成、结果可见和数值正确，接上 Signal、中断、Host 线程重新运行与下一轮资源复用；最后用这些阶段定位停滞。
- [5. 应用退出：停止设备访问并释放资源](#5-应用退出停止设备访问并释放资源)：先结束所有异步使用，再分别回收 Queue、任务资源、Runtime 与内核进程对象，并解释任务未完成时的退出。
- [6. 源码追踪、故障推演与小范围验证](#6-源码追踪故障推演与小范围验证)：独立复走调用链，以条件变化检验理解，再完成一项可以审阅的调试练习。

<details>
<summary>小节索引：任务执行、完成通知、退出与源码练习</summary>

- [3. 一项计算从 Runtime 请求到 GPU 执行](#3-一项计算从-runtime-请求到-gpu-执行)
  - [3.1 KFD 和设备固件使用户 Queue 获得驻留条件](#31-kfd-和设备固件使用户-queue-获得驻留条件)
    - [3.1.1 源码导读：DQM 集合怎样变成设备运行列表](#311-源码导读dqm-集合怎样变成设备运行列表)
  - [3.2 设备从 Queue 状态进入 Kernel 执行状态](#32-设备从-queue-状态进入-kernel-执行状态)
  - [3.3 代码、参数与数据在发布前满足使用条件](#33-代码参数与数据在发布前满足使用条件)
  - [3.4 Host 线程与 Runtime 安排本轮软件提交](#34-host-线程与-runtime-安排本轮软件提交)
  - [3.5 从预留槽位到有效发布，再到设备推进](#35-从预留槽位到有效发布再到设备推进)
    - [3.5.1 源码导读：临时 Packet、槽位预留与 Header 发布](#351-源码导读临时-packet槽位预留与-header-发布)
  - [3.6 两条 Queue 完成准备、依赖等待与计算](#36-两条-queue-完成准备依赖等待与计算)
    - [发布前建立两个不同的完成对象](#发布前建立两个不同的完成对象)
    - [先满足依赖，再允许后面的 Dispatch 启动](#先满足依赖再允许后面的-dispatch-启动)
    - [顺序依赖与数据可见性一起传递](#顺序依赖与数据可见性一起传递)
    - [用同一案例解释正常等待、推进和失败](#用同一案例解释正常等待推进和失败)
  - [3.7 两个进程运行时的 CPU 与 GPU 调度](#37-两个进程运行时的-cpu-与-gpu-调度)
    - [CPU 切换线程，已经提交的 GPU 工作继续推进](#cpu-切换线程已经提交的-gpu-工作继续推进)
    - [驻留名额不足时，GPU 保存和恢复已有工作](#驻留名额不足时gpu-保存和恢复已有工作)
  - [3.8 可恢复缺页把设备执行接回 Host 处理](#38-可恢复缺页把设备执行接回-host-处理)
    - [3.8.1 源码导读：故障记录、进程引用与 RAM 恢复分支](#381-源码导读故障记录进程引用与-ram-恢复分支)
    - [RAM 页面变化后的旧映射撤销与恢复](#ram-页面变化后的旧映射撤销与恢复)
    - [故障处理结果与原任务的后续推进](#故障处理结果与原任务的后续推进)
- [4. 任务完成：通知 Host 并继续应用工作](#4-任务完成通知-host-并继续应用工作)
  - [4.1 Kernel 结束、Signal 更新与结果交接](#41-kernel-结束signal-更新与结果交接)
  - [4.2 Signal、通知槽、中断与等待线程的衔接](#42-signal通知槽中断与等待线程的衔接)
    - [4.2.1 沿 WaitAcquire 读取值、转入睡眠并复查](#421-沿-waitacquire-读取值转入睡眠并复查)
    - [4.2.2 沿 IH 记录进入 KFD 工作线程并找到事件](#422-沿-ih-记录进入-kfd-工作线程并找到事件)
    - [4.2.3 用事件锁与条件复查处理通知和睡眠的竞争](#423-用事件锁与条件复查处理通知和睡眠的竞争)
  - [4.3 分别确认完成、可见与数值正确](#43-分别确认完成可见与数值正确)
    - [SVM 变体：GPU 使用后，CPU 读取 A 触发 HBM 迁回](#svm-变体gpu-使用后cpu-读取-a-触发-hbm-迁回)
  - [4.4 下一轮使用已有环境，并等待所有消费者结束](#44-下一轮使用已有环境并等待所有消费者结束)
  - [4.5 用阶段证据判断任务停在何处](#45-用阶段证据判断任务停在何处)
- [5. 应用退出：停止设备访问并释放资源](#5-应用退出停止设备访问并释放资源)
  - [5.1 先结束提交与所有消费者，再归还任务资源](#51-先结束提交与所有消费者再归还任务资源)
  - [5.2 销毁 Queue 时先撤销设备使用](#52-销毁-queue-时先撤销设备使用)
    - [5.2.1 沿 Queue 句柄进入 PQM，并区分映射计数与 BO 引用](#521-沿-queue-句柄进入-pqm并区分映射计数与-bo-引用)
    - [5.2.2 沿 CPSCH 卸载请求确认停止，并追踪超时边界](#522-沿-cpsch-卸载请求确认停止并追踪超时边界)
  - [5.3 内存解除映射、Runtime 关闭与对象收尾](#53-内存解除映射runtime-关闭与对象收尾)
    - [5.3.1 render 文件最终清理中的 AMDGPU 私有状态](#531-render-文件最终清理中的-amdgpu-私有状态)
  - [5.4 任务未完成时的进程退出与后台使用](#54-任务未完成时的进程退出与后台使用)
    - [5.4.1 沿 MMU notifier 停止旧访问，再由最后引用安排释放](#541-沿-mmu-notifier-停止旧访问再由最后引用安排释放)
    - [5.4.2 缺页恢复持有 mm 与退出拆除的竞争](#542-缺页恢复持有-mm-与退出拆除的竞争)
  - [5.5 P 退出以后，设备继续服务 R](#55-p-退出以后设备继续服务-r)
- [6. 源码追踪、故障推演与小范围验证](#6-源码追踪故障推演与小范围验证)
  - [6.1 独立追踪同一项任务](#61-独立追踪同一项任务)
  - [6.2 用故障现象检验调用链](#62-用故障现象检验调用链)
  - [6.3 一次可审阅的调试修改](#63-一次可审阅的调试修改)
  - [6.4 接入第七章的公共驱动能力](#64-接入第七章的公共驱动能力)

</details>

首次阅读先看 §3.1～§3.2：设备如何取得 Q0 的配置，如何执行一份已发布的任务；再读 §3.3～§3.5，追踪 Host 把本轮内容准备好并发布到 Q0 的过程。两部分连起来后，接到 §4 的完成和结果读取，再按 §5 释放资源。源码证据可在理解流程后展开。

§3.6～§3.8 分别改变跨 Queue 依赖、进程竞争和访存条件，每个变体都从明示的起点重新推演。停滞检查放在完成与复用之后的 [§4.5](#45-用阶段证据判断任务停在何处)，可以按已经学过的阶段反查。

00～05 已建立的系统参与者、进程地址空间、内存分配、Packet、地址翻译和缺页处理，会在本次任务用到它们时接回运行过程。正文保留当前步骤需要的条件和状态变化，字段编码与页表算法通过链接回查。下面重列两篇共用的案例条件和源码基线，便于从本篇查阅。

**[DESIGN]** 固定采用外部 Host CPU + MI300X / CDNA 3 独立 GPU，system RAM 与 HBM 经 PCIe 连接；整卡作为一个逻辑 GPU Agent，Host IOMMU 开启翻译。本例 DRM render 编号取 128，P 打开 render 文件与 `/dev/kfd` 后分别得到 fd 7、fd 8。P 在本例 GPU 上使用 PASID 42，VMID 5 是观察时刻的硬件驻留上下文编号；这些编号均为教学取值，实际分配结果可以不同。主线先取资源充足、映射有效、正常完成的条件；固件装载与 Queue 管理的具体配置在用到它们的小节说明。

任务仍有 1024 个元素，Q0 的 Packet 37 发起 `vector_add`，完成 Signal S 初值为 1。Q0 Ring 基址为 `0x1000_0000`，Packet 37 位于 `0x1000_0940`。Ring、Kernarg、S 和 A/B/C 放在 system RAM；代码、Descriptor 与 GPU 页表采用本例的 HBM 布置。A/B/C 使用满足 CPU/GPU 访问与 HSA 同步要求的细粒度系统内存，正常主线通过普通 KFD 内存接口建立 GPU 映射。

本例让 CPU 与 GPU 按 SYSTEM 范围交接输入、参数和结果。Packet 37 的 acquire/release fence scope 均取 SYSTEM，Host 以 acquire 语义等待 S。发布 Packet 的顺序在 §3.5 展开，计算结束后怎样交付结果在 §4 展开。

接口关系从 HSA/ROCr 层展开，便于看清驱动请求。高层 Runtime 应用会由其实现完成相应底层调用，§3.4 再接上 CLR 的提交路径。图中的接口不要求 HIP 应用逐个显式调用，也不把 Stream 与底层 AQL Queue 固定画成一一对应。

源码基线为 Linux `248951ddc14de84de3910f9b13f51491a8cd91df`、ROCr `ba56a24c6132c5d195686ae4adf969ca1222fbba`、CLR `81277d69e3352e7144ced2ee9601484f9b48d950`，后文使用其前 12 位。目录见[源码基线说明](../2.源码/README.md)。`[SOURCE]` 标记实现事实，`[SPEC]` 标记规范语义，`[DESIGN]` 标记教学条件，`[INFERENCE]` 标记条件推演，`[BOUNDARY]` 说明适用范围。

源码文件名链接定位到该处引用的第一段，行号链接分别定位到对应片段的起始行。可在 VS Code 的 Markdown 编辑区中 Ctrl＋左键点击，或在预览中直接点击。本地源码定位采用 VS Code 原生链接，按当前仓库的绝对路径生成；移动仓库目录后需更新这些定位路径。

**[BOUNDARY]** 普通 DRM job、scheduler、TTM、`dma_resv` 及 CPU/SDMA 页表更新后端，按 [07 大纲](<./07_AMDGPU 通用内存管理与 DRM 任务提交（大纲）.md>)展开。本篇解释 AQL 在什么时机使用这些公共能力、接口返回时已经完成什么、还需要等待谁。

## 3. 一项计算从 Runtime 请求到 GPU 执行

P 已有 GPUVM、Q0 和可访问存储，现在要让 MI300X 执行本轮 `vector_add`。本章先看设备怎样取得 Q0 的配置、怎样执行一份已发布的任务，再回到 Host，讲清代码、参数和 Packet 怎样准备并交给设备。

**[DESIGN]** 上篇停在 Q0 新建完成、读写索引均为 0 的时刻。本章省略此前 0～36 的发布与完成，取前序任务均已结束、读写索引都为 37、没有其他 Producer 并发提交的时刻，观察本轮任务。正常主线取映射有效、资源充足；Queue 管理沿关闭 MES 的 HWS/CPSCH 路径，Doorbell 使用已建立的直接映射。§3.1 回看从创建时开始的驻留管理；§3.2 暂取本轮 Packet 已正确发布的条件，先解释设备的执行过程。

```text
上篇已建立：P 的 GPUVM、Q0、Ring、Doorbell 映射及任务存储
    │
    ├─ 先看设备怎样取得配置并执行任务（3.1～3.2）
    │   │
    │   ├─ 3.1 KFD 与固件安排 Q0 驻留
    │   │      PDD/QPD 提供进程配置，MQD 描述 Queue 的地址和进度
    │   │      → KFD 写入运行列表 IB，经内部 HIQ 提交管理命令
    │   │      → 固件安排地址空间上下文，装载 Queue 配置
    │   │      → CP/MEC 具备按 Q0 Ring 地址与进度取包的条件
    │   │
    │   └─ 3.2 观察一份已正确发布的 Packet 37
    │          Q0 已驻留，Packet 可读，前序条件满足
    │          → 读取 Packet、Descriptor，取得入口、参数位置和资源需求
    │          → 执行启动 acquire，安排 Work-group / Wave
    │          → 取指，按 Kernarg 中的地址读取 A/B、写入 C
    │          → 全部工作结束，进入 Packet 的完成阶段
    │
    └─ 再回到 Packet 37 发布前，追踪 Host 的动作（3.3～3.5）
        │
        ├─ 3.3 准备代码、参数、数据与完成对象
        │      取得已装载代码的执行句柄，填写 A/B 和 Kernarg，准备 S
        │      → 每份引用可用，并保留到各自最后使用结束
        │
        ├─ 3.4 Host 线程推进软件提交
        │      直接 HSA 主线：Producer 准备向 Q0 发布
        │      CLR 对照：当前线程直接处理，或 HostQueue 工作线程取出命令
        │      → 处理所需依赖，进入底层 AQL 发布
        │
        └─ 3.5 将 Packet 37 交付到 Q0 Ring
               原子预留编号 → 确认槽位可写 → 填入内容
               → release 写入有效 Header → 写 Doorbell 通知设备
               → 驻留及前序条件满足后，沿 3.2 的路径执行
               → 第 4 章：SYSTEM release → S 从 1 减为 0
                   → Host acquire 等待后读取并校验 C

在上述关系上，分别改变一个条件：
    3.6 跨 Queue 依赖：Q1 写 A → S_ready 报告完成
        → Q0 的 Barrier 等待并完成同步 → Packet 37 计算 → 更新 S
    3.7 多进程调度：Host 切换到 R，P 已提交的 GPU 工作仍可继续
        → 若驻留资源不足，按本节条件保存 Q0 状态 → 恢复后继续原任务
    3.8 可恢复缺页：先启用 XNACK，并用 SVM 管理 A
        → GPU 访问 A 缺页 → Host 恢复页面映射与访问条件
        → 原访问继续，任务完成后再更新 S
```

图中前两部分按讲解顺序排列。实际运行时，Host 必须先发布任务，设备才能读取它；§3.2 先观察发布后的状态，§3.3～§3.5 再说明 Host 怎样准备到这一状态。Queue 驻留管理从创建时已经参与，正常逐次发布复用已有 Ring 与 Doorbell，不要求每次重新提交运行列表。

读到 §3.5 后，应能把“设备已有什么配置”和“Host 本轮交付什么内容”连成一次完整执行。§3.6～§3.8 分别解释依赖、竞争和缺页怎样影响这项任务；第 4 章继续讲完成通知与结果交接。源码摘录、字段细节和证据索引按需展开。

### 3.1 KFD 和设备固件使用户 Queue 获得驻留条件

P 已在上篇创建 Q0，本节先看设备怎样取得这条 Queue 的配置。KFD 已保存 P 的地址空间和 Q0 的 Ring、索引等信息，接下来要把这些配置交给设备，使设备知道从哪里取包、按哪份页表访问。驻留管理从创建 Queue 时已经开始；本例关闭 MES，沿 HWS/CPSCH 路径组织运行列表，再由固件安排硬件上下文。

```text
创建或变更用户 Queue
    → KFD 更新进程设备下的 Queue 集合与 MQD
    → KFD 将进程、Queue 描述写入运行列表 IB
    → 经 HIQ 提交引用该 IB 的 RUN_LIST 管理命令
    → 设备固件安排 Queue 的硬件上下文
    → Q0 驻留时，CP/MEC 按其 Ring 与进度读取 AQL Packet
```

运行列表 IB 保存 `MAP_PROCESS`、`MAP_QUEUES` 等管理命令，内部 HIQ 把运行列表交给设备。用户的 Packet 37 始终保存在 Q0 的 AQL Ring 中。下面沿进程配置和 Queue 配置看设备分别从哪里取得信息：

先取得进程配置。P 的 `kfd_process` 管理进程层面的状态，PDD 保存 P 在 GPU0 上的记录，内嵌 QPD 保存该进程设备关系下的 Queue 集合与调度配置。DQM 是当前 GPU 的 Queue 管理器，要沿这些记录收集本次运行列表需要的进程和 Queue。

PDD 已关联上篇建立的 GPUVM。DQM 登记进程设备关系时，经 AMDGPU 取得该 GPUVM 的根页表地址，保存到 `qpd->page_table_base`；PASID 42 则沿用 P 的 VM 关联。这样，KFD 构造进程管理命令时，已经知道要让设备使用哪份进程地址空间。

再取得 Q0 的配置。Runtime 在创建请求中提供 Ring 和索引地址，KFD 分配 Doorbell 编号与 MQD 存储，并按 Queue 属性填写 MQD。MQD 是设备可访问的内存描述，保存装载 Q0 所需的配置；Q0 的用户 Ring 继续单独存放各轮 AQL Packet。

<details>
<summary>创建顺序补充：首次登记进程设备关系</summary>

按[上篇 §2.4](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#24-q0-的创建把用户存储交给驱动和设备使用>)的创建顺序，首次进程设备登记由内部 `QueueUtility` 触发，应用 Q0 沿用已登记的 QPD。

</details>

```text
PDD / QPD：P 在 GPU0 上的进程配置
    pasid = 42（来自 VM 关联）、根页表地址（来自 GPUVM）
    Queue 集合、内存与陷阱相关状态
        → MAP_PROCESS：告诉设备建立哪份进程执行与地址空间环境

Q0：属于 P 的 Queue
    MQD 设备地址（KFD 分配）
    Doorbell 的 BAR 内索引（由进程分片位置与槽位编号换算）
    写索引地址（Runtime 提供）；MQD 内容中另记录 Runtime 提供的 Ring 地址
        → MAP_QUEUES：告诉设备怎样找到和配置这条 Queue

设备按运行列表建立驻留
    → 当前可用 VMID 承载 P 的地址空间配置
    → MQD 所描述的 Queue 配置进入硬件活动状态
    → CP/MEC 才能沿 Q0 Ring 处理 Packet 37
```

本例 PASID 42 标识 P 的地址空间，VMID 5 是观察时刻承载该配置的硬件上下文。Q0 换出时，PDD、页表和 Ring 仍可保留，恢复时再取得所需驻留资源；VMID 5 不是 P 永久独占的编号。

接着把记录交给设备。KFD 取进程配置生成 `MAP_PROCESS`，再取各活动 Queue 的 MQD 地址、Doorbell 位置和写索引地址生成 `MAP_QUEUES`，把它们写入运行列表 IB。HIQ 中提交的 `RUN_LIST` 引用这份 IB，固件消费管理命令后，再安排进程地址空间与 Queue 硬件上下文。

用 Q0 看这一过程：MQD 告诉设备 Q0 的 Ring 在哪里、按哪些进度位置工作；这些配置装入 HQD 等硬件活动状态后，CP/MEC 才能沿 Q0 Ring 读取用户 Packet。MQD 保存在内存中，HQD 是 Queue 驻留时实际使用的硬件状态；因此，Q0 的内存描述仍存在时，也可能正在等待取得硬件驻留机会。

运行列表 IB 传递的是“服务哪些进程和 Queue、使用什么配置”，Ring 内的 Packet 37 则提供本轮 Kernel 的代码、参数和规模。设备先有读取 Q0 的上下文，才沿用户 Packet 的引用取得本轮代码和参数。

所以要分别确认三个完成点：KFD 软件集合已包含 Q0，Host 已发出对应管理命令，设备已执行管理请求并建立驻留条件。管理提交函数返回，只能先确认 Host 侧已完成的步骤；Packet 37 的执行和 S 的更新还在后面。

**[INFERENCE]** 如果 P 继续向已有且可用的 Q0 发布下一轮任务，Producer 沿 §3.5 更新 Ring 和 Doorbell；如果 P 新建 Q1，设备还需取得 Q1 的 MQD、Ring 与通知配置，KFD 因而要按新的 Queue 集合更新管理状态。销毁或暂停/恢复 Queue 也可能触发相应管理动作。两条路径的触发条件不同，不能把每次 Packet 发布都画成重新提交运行列表。Queue 换出与恢复回查 [03 上篇 §3.3](<./03_AMD GPU 队列与 AQL Dispatch（上）.md#33-queue-换出与恢复时的状态保存>)。

<details>
<summary>依据：固定源码与规范索引</summary>

> **[SOURCE]** Linux `248951ddc14d`：[`kfd_priv.h`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_priv.h:672:1) 第 [672～703](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_priv.h:672:1) 行定义 QPD 的 Queue 列表和页表等配置；[`kfd_packet_manager.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager.c:279:1) 第 [279～318](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager.c:279:1) 行为 GFX9.4.3 选择 `kfd_aldebaran_pm_funcs`；[`kfd_packet_manager_v9.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager_v9.c:89:1) 第 [89～145](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager_v9.c:89:1) 行从 PDD/QPD 构造本例适用的进程 Packet，第 [227～296](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager_v9.c:227:1) 行构造 Queue Packet。名称含 `aldebaran` 的共用函数由当前 IP 分支明确选中，本篇只使用该分支支持的关系。

</details>

<details>
<summary>依据：固定源码与规范索引</summary>

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_device_queue_manager.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:627:1) 第 [627～641](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:627:1) 行分配 Doorbell 槽位并换算 BAR 内索引，第 [1536～1561](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:1536:1) 行取得根页表地址并保存到 QPD，第 [2126～2200](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2126:1) 行分配 Doorbell/MQD、登记 Queue 并在活动条件下更新调度，第 [2266～2286](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2266:1)、[2643～2656](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2643:1) 行连接运行列表提交与重新映射；[`amdgpu_amdkfd_gpuvm.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gpuvm.c:1621:1) 第 [1621～1630](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gpuvm.c:1621:1) 行返回当前 GPUVM 的根页表地址。[`kfd_packet_manager.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager.c:181:1) 第 [181～240](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager.c:181:1) 行组织进程与 Queue 描述，第 [359～398](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager.c:359:1) 行提交运行列表。这里限定 `enable_mes` 为关闭的传统 CPSCH 分支；源码中的其他分支不作为本例的实际路径。

</details>

**[BOUNDARY]** 源码公开了 Host 如何描述和提交 Queue 管理请求。设备固件内部的精确选择算法、时间片和逐周期行为，不从这些接口反推。

#### 3.1.1 源码导读：DQM 集合怎样变成设备运行列表

本例已创建或变更 Queue，DQM 需要把当前可运行集合重新交给固件。先固定 `enable_mes` 关闭、使用 CPSCH，且没有 Reset 占用当前设备的条件；函数入口与所持锁来自 Queue 管理调用者。运行列表重新提交可能涉及其他进程和 Queue，不能把它当作只处理 Packet 37 的调用。

```text
Queue 管理调用者持 dqm->lock，修改 qpd 的 Queue 集合
    → execute_queues_cpsch：取得 Reset 保护，撤销已有运行列表
        → map_queues_cpsch：检查调度状态、活动数量和已有列表
            → pm_send_runlist：组织本轮运行列表并经 HIQ 提交
                1. 调用 pm_create_runlist_ib，构造运行列表 IB
                   IB 中写入 MAP_PROCESS 和活动 Queue 的 MAP_QUEUES 描述
                2. 持 pm->lock，取得 HIQ 槽位并写入 RUN_LIST 命令
                   命令保存上述 IB 的设备地址与长度，供固件找到并读取描述
                3. 调用 kq_submit_packet，更新 HIQ 写索引并通知内部 Doorbell
设备固件消费 HIQ → 读取运行列表 IB → 按进程和 Queue 描述安排驻留
Q0 具备驻留及 Packet 处理条件后，CP/MEC 沿用户 Ring 处理 Packet 37
```

<details>
<summary>可选源码：DQM 构造并提交运行列表</summary>

**[DESIGN]** 沿上述流程需要先认识 DQM 中的 Packet Manager。下面只保留本次提交用到的成员，是教学简化定义：

```text
DQM.packet_mgr：内嵌的 packet_manager
    dqm → 所属设备队列管理器
    pmf → 当前 IP 选定的管理 Packet 编码函数表
    priv_queue → 发送 RUN_LIST 等命令的 HIQ
    lock           保护内部命令构造和提交
    ib_buffer_obj  管理本轮运行列表 IB 的存储片段
```

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_device_queue_manager.h`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.h:247:1) 第 [247](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.h:247:1) 行内嵌 Packet Manager；[`kfd_priv.h`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_priv.h:1448:1) 第 [1448～1475](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_priv.h:1448:1) 行定义其所属 DQM、内部 Queue、锁、IB 和编码回调表。

先读调用入口，尤其是错误传播和锁的要求。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_device_queue_manager.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2641:1) 第 [2641～2657](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2641:1) 行，保留 DQM 锁的调用前提、Reset 读侧保护及先撤销后映射的控制流。

```c
2641:
2642 /* dqm->lock mutex has to be locked before calling this function */
2643 static int execute_queues_cpsch(struct device_queue_manager *dqm,
2644 				enum kfd_unmap_queues_filter filter,
2645 				uint32_t filter_param,
2646 				uint32_t grace_period)
2647 {
2648 	int retval;
2649:
2650 	if (!down_read_trylock(&dqm->dev->adev->reset_domain->sem))
2651 		return -EIO;
2652 	retval = unmap_queues_cpsch(dqm, filter, filter_param, grace_period, false);
2653 	if (!retval)
2654 		retval = map_queues_cpsch(dqm);
2655 	up_read(&dqm->dev->adev->reset_domain->sem);
2656 	return retval;
2657 }
```

注释要求调用者已经持有 `dqm->lock`。第 2650～2655 行先尝试取得 Reset 域的读侧保护；取得失败立即返回 `-EIO`。成功时先撤销旧列表，只有撤销返回 0 才调用新映射；退出前归还 Reset 保护。持有 DQM 锁保证这里看到的 Queue 管理集合与同一组修改互斥，不能只凭 `execute_queues_cpsch` 名称遗漏调用者的锁。

旧列表撤销包含 UNMAP、QUERY_STATUS 和抢占结果检查，完整过程放到 §5.2。本节继续看新映射什么时候真正发送请求。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_device_queue_manager.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2265:1) 第 [2265～2287](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2265:1) 行，保留映射运行列表的入口、全部提前返回条件及 active_runlist 的发布。

```c
2265 /* dqm->lock mutex has to be locked before calling this function */
2266 static int map_queues_cpsch(struct device_queue_manager *dqm)
2267 {
2268 	struct device *dev = dqm->dev->adev->dev;
2269 	int retval;
2270:
2271 	if (!dqm->sched_running || dqm->sched_halt)
2272 		return 0;
2273 	if (dqm->active_queue_count <= 0 || dqm->processes_count <= 0)
2274 		return 0;
2275 	if (dqm->active_runlist)
2276 		return 0;
2277:
2278 	retval = pm_send_runlist(&dqm->packet_mgr, &dqm->queues);
2279 	pr_debug("%s sent runlist\n", __func__);
2280 	if (retval) {
2281 		dev_err(dev, "failed to execute runlist\n");
2282 		return retval;
2283 	}
2284 	dqm->active_runlist = true;
2285:
2286 	return retval;
2287 }
```

注释仍要求先持有 DQM 锁；调试日志记录发送运行列表，错误日志表示运行列表提交失败。这段主要证明一次 `map_queues_cpsch()` 返回 0 的含义由实际分支决定。

第 2271～2276 行分别检查调度未运行或被暂停、没有活动 Queue/进程、已经有活动列表。这些分支直接返回 0，完成的是当前条件判断。走到第 2278 行后才构造和发送本轮运行列表；发送成功再在第 2284 行设置 `active_runlist = true`。这个 Host 软件标志记录本轮运行列表已通过 HIQ 提交；设备随后处理请求，安排各 Queue 的具体硬件驻留。

`pm_send_runlist()` 先调用 `pm_create_runlist_ib()`。后者从 `dqm->queues` 取得每个进程的 QPD，调用 `pm->pmf->map_process` 写进程 Packet，再遍历 `qpd->queues_list`，仅为 `is_active` 的用户 Queue 写 `MAP_QUEUES`。本例 P 的记录提供 PASID 和根页表，Q0 的记录提供 MQD、Doorbell 和索引地址。函数还处理列表容量与 XNACK 配置分组，第一次阅读先代入本例的同一模式和充足资源，再回看分支。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_packet_manager.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager.c:136:1) 第 [136～202](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager.c:136:1) 行给出函数输入、IB 分配与进程 Packet 构造，第 [223～240](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager.c:223:1) 行遍历活动用户 Queue。第 [294～311](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager.c:294:1) 行为 GFX9.4.3 明确选择 `kfd_aldebaran_pm_funcs` 并准备 HIQ；实际 Packet 的字段来源分别定位到 [`kfd_packet_manager_v9.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager_v9.c:89:1) 第 [89～145](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager_v9.c:89:1)、[227～296](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager_v9.c:227:1) 行。函数表中的名字必须由当前 IP 选择证明适用。

下面完整阅读发送函数。两个缓冲有不同内容：runlist IB 保存各进程和 Queue 的描述，HIQ 槽位保存指向该 IB 的 RUN_LIST 管理命令。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_packet_manager.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager.c:359:1) 第 [359～399](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager.c:359:1) 行，保留运行列表构造、HIQ 缓冲取得、命令构造、提交及失败回滚的完整函数。

```c
359 int pm_send_runlist(struct packet_manager *pm, struct list_head *dqm_queues)
360 {
361 	uint64_t rl_gpu_ib_addr;
362 	uint32_t *rl_buffer;
363 	size_t rl_ib_size, packet_size_dwords;
364 	int retval;
365:
366 	retval = pm_create_runlist_ib(pm, dqm_queues, &rl_gpu_ib_addr,
367 					&rl_ib_size);
368 	if (retval)
369 		goto fail_create_runlist_ib;
370:
371 	pr_debug("runlist IB address: 0x%llX\n", rl_gpu_ib_addr);
372:
373 	packet_size_dwords = pm->pmf->runlist_size / sizeof(uint32_t);
374 	mutex_lock(&pm->lock);
375:
376 	retval = kq_acquire_packet_buffer(pm->priv_queue,
377 					packet_size_dwords, &rl_buffer);
378 	if (retval)
379 		goto fail_acquire_packet_buffer;
380:
381 	retval = pm->pmf->runlist(pm, rl_buffer, rl_gpu_ib_addr,
382 					rl_ib_size / sizeof(uint32_t), false);
383 	if (retval)
384 		goto fail_create_runlist;
385:
386 	retval = kq_submit_packet(pm->priv_queue);
387:
388 	mutex_unlock(&pm->lock);
389:
390 	return retval;
391:
392 fail_create_runlist:
393 	kq_rollback_packet(pm->priv_queue);
394 fail_acquire_packet_buffer:
395 	mutex_unlock(&pm->lock);
396 fail_create_runlist_ib:
397 	pm_release_ib(pm);
398 	return retval;
399 }
```

这段位于 Packet Manager 层，主要证明运行列表 IB 与内部 Queue 如何配合，以及失败时按照取得资源的顺序回退。

调试日志中的 `runlist IB address` 指运行列表 IB 的设备地址。第 366～369 行先调用 `pm_create_runlist_ib()`，得到已填写的 IB、设备地址和长度。第 373～379 行计算 RUN_LIST 命令的大小，持 `pm->lock` 取得 HIQ 的待写入区域；第 381～384 行再把 IB 的地址与长度编码进该区域。外层 DQM 锁保护 Queue 集合，`pm->lock` 保护 HIQ 的这次命令构造和提交。

第 386～390 行提交内部 Packet 后释放锁并返回提交结果。第 392～399 行按失败点回滚内部预留、释放锁和 IB。还要注意第 386 行自身失败时直接经第 390 行返回，未进入下面的失败标签；分析某个资源是否已归还，应沿实际跳转确认，不能概括为任意非零返回都会执行所有回滚标签。

进入 `kq_submit_packet()` 可以看到内部命令的具体交付动作。它和用户态的 AQL 发布都写 Ring/索引/Doorbell，但使用不同 Queue、不同 Packet 内容和不同调用者。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_kernel_queue.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_kernel_queue.c:274:1) 第 [274～294](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_kernel_queue.c:274:1) 行，保留内部 Queue 提交的错误判断、Ring 与索引排序、两种 Doorbell 分支及返回。

```c
274 	/* Fatal err detected, packet submission won't go through */
275 	if (amdgpu_amdkfd_is_fed(kq->dev->adev))
276 		return -EIO;
277:
278 	/* Make sure ring buffer is updated before wptr updated */
279 	mb();
280:
281 	if (kq->dev->kfd->device_info.doorbell_size == 8) {
282 		*kq->wptr64_kernel = kq->pending_wptr64;
283 		mb(); /* Make sure wptr updated before ring doorbell */
284 		write_kernel_doorbell64(kq->queue->properties.doorbell_ptr,
285 					kq->pending_wptr64);
286 	} else {
287 		*kq->wptr_kernel = kq->pending_wptr;
288 		mb(); /* Make sure wptr updated before ring doorbell */
289 		write_kernel_doorbell(kq->queue->properties.doorbell_ptr,
290 					kq->pending_wptr);
291 	}
292:
293 	return 0;
294 }
```

该摘录处于第 262 行开始的 `kq_submit_packet(struct kernel_queue *kq)` 内，前面第 264～273 行仅包含 DEBUG 日志。英文注释说明检测到致命设备错误时拒绝提交，以及 Ring 内容先于写索引、写索引先于 Doorbell 的两层排序。

第 275～279 行拒绝致命错误，否则先执行内存屏障。沿本例 8 字节 Doorbell 分支，第 282～285 行写内部 64 位进度、再次排序并通知设备。第 293 行返回 0 时，Host 已执行这些提交动作；固件继续消费 HIQ、读取 runlist IB，建立进程/Queue 驻留条件。完成 S 仍由用户 Dispatch 的执行阶段更新。

**[INFERENCE]** 若 Q0 已在运行列表中，Producer 再发布 Packet 37，主路径只执行 §3.5 的动作；若 P 新建 Q1，需要根据新的集合执行管理更新。若旧列表撤销失败，`execute_queues_cpsch()` 不执行后面的映射调用，不能用旧的 `active_runlist` 值证明新集合已经进入硬件。沿这个例子同时追踪 `retval`、`active_runlist` 和设备确认，才能判断状态停在何处。

跟读时给 `pm->pmf` 的选择、`map_process`/`map_queues` 的调用与 RUN_LIST 的 HIQ 提交各做一个定位标记，然后回答：P 的页表根来自谁，Q0 的 Ring 地址保存在谁，为什么这条控制链不逐次接收用户 Packet 37。

</details>

### 3.2 设备从 Queue 状态进入 Kernel 执行状态

上一节说明了 Q0 怎样取得驻留条件。现在先观察设备如何使用这些配置：假设 Packet 37 已填写完整并正确发布，代码、参数、数组和 S 均可访问，前序条件也已满足。CP/MEC 读取任务描述和代码信息，执行启动 acquire，再由计算前端安排 Work-group/Wave 执行。Host 怎样准备并发布这份 Packet，随后在 §3.3～§3.5 展开。

下面沿设备使用的对象展开。Packet 下的分支表示字段引用谁、保存什么；图下半部再按执行顺序展开。存储位置沿用本章的 system RAM / HBM 布置。

```text
Q0 已装入硬件活动状态
    Ring 基址 = 0x1000_0000，当前读索引 = 37
    当前 VMID 5 → P 的 GPU 页表根（HBM）→ 提供地址翻译上下文
    ↓ CP/MEC 按 Ring 地址和进度取包
Q0 Ring 中的 Packet 37（system RAM，地址 0x1000_0940）
    ├─ kernel_object：Kernel 执行句柄，本例指向 Descriptor
    │      → Descriptor（HBM，保存入口与资源需求）→ 对应机器码
    ├─ kernarg_address：本轮参数区地址
    │      → Kernarg（system RAM，保存 A/B/C 地址和 N）
    ├─ Grid / Work-group：本轮工作规模
    │      → 1024 个 Work-item，每组 256 个
    └─ completion_signal：本轮完成对象
           → S（system RAM），初值为 1

设备取得入口、参数区地址与规模信息，满足前序条件并执行启动 acquire
    → 为 Work-group / Wave 安排执行资源
    → Wave 持有 PC、寄存器和执行掩码，取指并运算
    → 读取 Kernarg，按参数中的地址访问 A/B、写 C
        这些访存使用当前地址空间映射
    → 全部工作完成 → SYSTEM release → 更新 S：1 → 0
    → Host acquire 等待确认完成，再读取 C（第 4 章）
```

这里有两次地址查找：Queue 配置先让设备找到 Packet，Packet 再给出代码、参数和完成对象的引用。Kernarg 中的数组地址用于执行阶段的具体访存。Host 的 Runtime 与 KFD 管理记录继续保留在主机中，设备使用的是已交付的配置和可访问存储。

这是取包与执行的逻辑图。MI300X 的物理结构仍回查 [04 §1.1](<./04_AMD GPU MMU 与地址翻译.md#11-xcdxcciod-与-hbm-的组织>)中的原图。

沿用 03 的启动规模：1024 个 Work-item，每组 256 个，因此本次有 4 个 Work-group。CDNA 3 使用 Wave64，每组分成 4 个 Wave，总计 16 个 Wave。这个数量描述本次逻辑工作，不表示 16 个 Wave 必须在同一瞬间全部驻留，也不表示每个 Wave 固定分配到一个独占 CU。

这里的 Work-item 是本次调用中的一份逻辑工作。在 `vector_add` 中，编号为 i 的工作读取 A[i]、B[i]，再写 C[i]。设备按 Work-group 和 Wave 组织这些工作，取得寄存器等资源后推进执行。

实际并发受寄存器、LDS、Wave 等资源及其他任务占用约束。16 是整次调用的工作总量，设备可先执行其中一部分，再随资源释放推进其余工作。本例 private/group 请求为 0；换成需要 LDS 或私有存储的 Kernel 时，应按实际请求重新判断资源条件。

回看总览图：Linux 给 Host 线程 CPU 时间，Runtime 安排提交和依赖，KFD/固件安排 Queue 驻留，设备再推进 Work-group/Wave。例如一个 Wave 等待访存返回时，Q0 仍可能驻留，Host 线程也可能继续运行。

GPU 沿已有映射访问 system RAM 中的 Ring、Kernarg 和 A/B/C，从 HBM 取得代码；执行时使用设备缓存、寄存器等状态。Host 的 `kfd_process` 保留管理记录，设备使用的是从这些记录取得并交付的配置。

以 `A[5]` 为例，Kernarg 交出的是 A 的基址，执行到取数指令后才产生具体元素地址。**[DESIGN]** 下面取映射有效、这次读取需要到达 system RAM 的情形；设备数据缓存直接返回内容时，不必重复走到 RAM：

```text
Kernarg 保存 A 基址：0x3000_0000
    → Work-item 5 读取 float 元素：基址 + 5 × 4，得到 GPUVA 0x3000_0014
    → 当前 VMID 5 的地址翻译：命中 TLB，或查询 P 的 GPU 页表
    → 得到设备 DMA 地址：A 所在 RAM 页的 IOVA + 页内偏移 0x14
    → 经 PCIe 发出 IOVA 请求，Host IOMMU 将设备地址翻译为主机物理地址
    → 内存访问取得 RAM 中的 A[5]，数据返回正在执行的 Wave，继续计算 C[5]
```

**[DESIGN]** 在这个执行观察点，取 CPU 已写好 `A[5] = 6`、`B[5] = 60`，完整输入规则在 §3.3 说明。Wave 执行对应取数指令，A[5] 的访问按图中路径返回 6，B[5] 按自己的地址与映射返回 60，再计算 66 并写到 C[5]。其他 Work-item 以各自索引处理其他元素。单个元素写完时，其他工作仍可能尚未结束，S 要等整个 Dispatch 的正常完成阶段才更新。

图中只展开 A 的数组读取。机器码从本例 HBM 取得，Kernarg 和 A/B/C 位于 system RAM；各次访问使用相应地址与映射。Wave 获得执行机会之后，访存还要经过自己的翻译和数据访问过程，地址翻译细节回查 [04](<./04_AMD GPU MMU 与地址翻译.md>)。

正在执行的 Wave 保留 PC、寄存器和执行掩码等状态，按资源和指令条件继续推进。Queue 驻留提供取包与地址空间条件，Wave 执行产生具体访存，MMU 与缓存再处理这些访问。

<details>
<summary>依据：固定源码与规范索引</summary>

> **[SPEC]** [MI300 / CDNA 3 ISA](../3.资料/amd-instinct-mi300-cdna3-instruction-set-architecture.pdf)，封面日期 2025-08-05，§1.1、§2、§3.1～§3.3，原文第 4～9 页，定义 Work-group/Wave、存储访问及 PC、寄存器、执行掩码等程序状态。这里描述可见状态与职责，不推定未公开的硬件发射算法。
>
> **[SOURCE]** Queue 配置与 MQD/HQD 关系见固定 Linux `248951ddc14d`，[`kfd_mqd_manager_v9.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c:727:1) 第 [727～835](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c:727:1) 行的 GFX9.4.3 MQD 初始化与更新。取包到执行的规范与接口证据集中在 [03 下篇第 6 章](<./03_AMD GPU 队列与 AQL Dispatch（下）.md#6-cpmec-取包与-kernel-启动>)；翻译上下文接到 [04](<./04_AMD GPU MMU 与地址翻译.md>)。

</details>

全部 Work-group 写完本轮 C 后，进入第 4 章的 SYSTEM release、S 更新和 Host acquire 等待。Q0、代码、参数与映射仍按各自使用关系保留。

至此已经看清设备需要哪些配置，以及它怎样沿 Packet 执行。下面回到 Host 的准备阶段：先取得可用代码、填好本轮参数和输入，再安排软件提交，最后发布 Packet，让设备能够按本节的路径工作。

### 3.3 代码、参数与数据在发布前满足使用条件

已经看过设备怎样沿 Packet 找到代码、参数和数据，现在回到 Packet 37 尚未发布的时刻。Host 要先准备这些被引用的内容，再把引用交给 Queue。Ring 中保存任务描述，机器码、参数区和数组各自保存在 Ring 之外：

```text
Q0 / Packet 37
    ├─ kernel_object → 已装载的 Descriptor → GPU 执行的机器码
    ├─ kernarg_address → 本轮 Kernarg → A、B、C 的 GPUVA 与元素数
    └─ completion_signal → S，提交前 value = 1

以上设备访问都使用对应映射；对象内容保留到各自最后使用者结束
```

先准备代码。编译器生成的 Code Object 包含机器码、Descriptor 和参数元数据，ROCr 装载器把机器码与 Descriptor 放到 GPU 可访问的目标存储，本例采用 HBM。Descriptor 记录代码入口的相对偏移和固定资源需求；应用随后查询到的 `kernel_object` 指向 Descriptor，设备还要根据其中的入口信息找到实际机器码。

Runtime 用执行对象保存已装载代码及符号。应用调用 `hsa_executable_freeze()` 成功后，不能再向该对象装入代码或定义外部变量，但仍可查询 Kernel 符号。沿本例使用 Host 暂存区的装载后端，Freeze 还完成到 HBM 代码存储的复制、写出和代码缓存处理。下面这条路径给 Packet 准备的是一个可用的代码引用。

```text
Code Object：机器码、Descriptor、参数元数据
    → ROCr 装载：准备代码存储，保存 Descriptor 的最终地址
    → freeze：固定执行对象，完成所选后端的代码内容交付
    → 查询 vector_add 的执行句柄，本例取得 Descriptor 地址
    → Packet.kernel_object 指向 Descriptor，再按入口偏移找到机器码
```

已装载代码可供多轮任务复用，直到最后一个使用者结束后才可销毁执行对象。装载地址与 Descriptor 的关系回查 [03 下篇 §4.2.3](<./03_AMD GPU 队列与 AQL Dispatch（下）.md#423-装载后取得-descriptor-地址>)。

再准备本轮参数和数据。沿 [上篇 §2](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#2-应用接入建立进程地址空间与可复用资源>) 已建立的映射，CPU 写入 A/B，并填写 Kernarg。参数元数据规定参数各占多少字节、放在哪个偏移，以及整个参数区的大小与对齐；CPU 按这份布局写入 A/B/C 的 GPUVA 和 `N=1024`，`kernarg_address` 则保存整份参数区的起始地址。具体布局回查 [03 下篇 §4.2](<./03_AMD GPU 队列与 AQL Dispatch（下）.md#42-packet-与代码参数块及数组的引用关系>)。

Kernarg 中放的是本次调用的参数值，其中 A/B/C 参数是地址。设备取得 A 的地址后，执行取数指令时才访问数组内容。因此，CPU 把 A 的地址写对、GPUVM 把该地址映射好、CPU 把本轮 A 的元素填好，是三个分别需要完成的动作。参数区和有效映射可以复用，但 CPU 仍须按本轮调用填写参数，并写好输入元素。

**[DESIGN]** 为使完成后的校验有明确预期，本轮 CPU 写 `A[i] = float(i + 1)`、`B[i] = float(10 * (i + 1))`，预期 `C[i] = float(11 * (i + 1))`，其中 `i = 0..1023`。这些小整数及其和可由单精度格式精确表示。§3.6 只把 A 的填写者改为 Q1 的准备 Kernel，保留同一组输入和预期结果。

最后为本轮准备完成对象 S，初值取 1，把 S 的句柄交给 Packet 的 `completion_signal`。正常完成时，设备在全部工作结束并完成规定同步后将 S 从 1 减为 0；Host 后续观察的是 Ring 之外的这个 Signal 对象。若复用已有 S，须先结束上一轮对它的所有使用，再准备本轮初值。

至此，Host 已有代码句柄、填好的参数区、可访问且内容就绪的输入，以及用于报告完成的 S。它们仍在各自存储中，下一节安排由哪个 Host 线程继续提交，§3.5 才把这些引用写入 Q0。代码、Kernarg、数组和 S 均须保留到各自最后使用结束。

<details>
<summary>依据：固定源码与规范索引</summary>

> **[SOURCE]** ROCr `ba56a24c6132`：[`hsa.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/hsa.cpp:2308:1) 第 [2308～2347](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/hsa.cpp:2308:1)、[2484～2525](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/hsa.cpp:2484:1) 行连接代码装载、freeze 与符号查询；[`amd_loader_context.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/amd_loader_context.cpp:281:1) 第 [281～332](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/amd_loader_context.cpp:281:1)、[347～371](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/amd_loader_context.cpp:347:1) 行给出代码存储、Host 暂存与复制处理；[`executable.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/loader/executable.cpp:1464:1) 第 [1464～1494](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/loader/executable.cpp:1464:1) 行处理 `.kd` Descriptor 并保存符号地址，第 [465～470](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/loader/executable.cpp:465:1)、[521～535](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/loader/executable.cpp:521:1) 行返回执行句柄与参数区属性。CLR `81277d69e335`，[`devkernel.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocm-clr/rocclr/device/devkernel.cpp:362:1) 第 [362～378](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocm-clr/rocclr/device/devkernel.cpp:362:1)、[523～533](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocm-clr/rocclr/device/devkernel.cpp:523:1) 行读取参数偏移、大小和 Kernarg 要求，[`rocvirtual.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocm-clr/rocclr/device/rocm/rocvirtual.cpp:4087:1) 第 [4087～4106](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocm-clr/rocclr/device/rocm/rocvirtual.cpp:4087:1)、[4142～4152](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocm-clr/rocclr/device/rocm/rocvirtual.cpp:4142:1) 行取得参数区并填写 Packet 引用。
>
> **[SPEC]** ROCr 同基线 [`hsa.h`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/inc/hsa.h:4425:1) 第 [4425～4456](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/inc/hsa.h:4425:1) 行说明 freeze 后不能再装入代码对象或定义外部变量，但仍可查询属性；第 [3033～3068](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/inc/hsa.h:3033:1) 行定义 Kernel 对象、参数和完成 Signal 引用。内存布局、执行期间保留与发布条件沿用 [03 下篇第 4 章](<./03_AMD GPU 队列与 AQL Dispatch（下）.md#4-一次-kernel-调用的-aql-packet-编码>)。

</details>

### 3.4 Host 线程与 Runtime 安排本轮软件提交

内容准备好后，要由获得 CPU 执行机会的 Host 线程推进提交。正常主线是 HSA Producer 直接向 Q0 发布；高层 CLR 请求则可能经过下面两条软件路径：

```text
Direct Dispatch：应用线程调用 → 当前线程处理命令与依赖
    → 进入 §3.5 的底层 AQL 发布
软件队列路径：应用线程把命令放入 HostQueue（用户态软件队列）
    → 工作线程取得并处理命令与依赖
    → 进入 §3.5 的底层 AQL 发布
```

先看直接提交。在本章的直接 HSA 主线中，Producer 就是正在 CPU 上执行发布代码的 Host 线程。若应用使用高层 CLR，Direct Dispatch 路径也由当前调用线程推进：处理高层命令的依赖与提交状态，然后进入底层设备提交。这里“直接”描述由谁继续提交，GPU 执行仍发生在之后的设备阶段。

再看软件队列路径。应用线程先把高层命令放入 P 用户态的 HostQueue，工作线程从中取出命令，处理依赖后调用设备提交实现。此时软件命令包含的是这次请求及其依赖关系；后续实现取得 Kernel 代码句柄、准备参数并构造 AQL Packet，才把设备能够解释的任务写到 Q0 Ring。HostQueue 由 CPU 工作线程读取，Q0 Ring 由设备读取，两处保存的内容服务于不同阶段。

**[INFERENCE]** 假设本轮软件命令已进入 HostQueue，但工作线程尚未取出它，且没有其他 Producer 提交：这时 Q0 还没有本轮 Packet 37，设备自然无从执行这次计算。工作线程获得 CPU 时间、处理命令并完成 §3.5 的发布后，设备才有任务可读。这个场景的检查起点是 Host 命令是否已经推进到发布入口。

处理依赖时，Runtime 可以先在 Host 等待前一项工作，也可以把条件表达成设备观察的 Signal 与 Barrier。后一种方式允许 Host 先交付任务，由设备按依赖顺序推进，§3.6 会沿两条 Queue 展开。无论采用哪种方式，都要能找到本次请求最后落在哪条 AQL Queue、使用哪些 Packet ID 和完成对象。

异步 API 返回只说明已完成该接口约定的安排或提交；应沿具体路径判断命令还在软件队列中，还是已发布到设备。Host 要使用结果时，仍须调用对应完成接口等待。高层 Runtime 还可能复用底层 Queue，或按批次跟踪完成，所以不能只凭一个 Stream 名称就推定某一份 Packet 已经结束。

<details>
<summary>依据：固定源码与规范索引</summary>

> **[SOURCE]** CLR `81277d69e335`：[`command.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocm-clr/rocclr/platform/command.cpp:356:1) 第 [356～419](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocm-clr/rocclr/platform/command.cpp:356:1) 行区分 Direct Dispatch 和软件入队；[`commandqueue.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocm-clr/rocclr/platform/commandqueue.cpp:241:1) 第 [241～311](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocm-clr/rocclr/platform/commandqueue.cpp:241:1) 行由工作线程处理命令和事件依赖。高层命令到 AQL 的衔接见 [03 下篇 §4.5](<./03_AMD GPU 队列与 AQL Dispatch（下）.md#45-clr-构造临时-packet-并调用发布函数>)，批次完成见 [§7.4](<./03_AMD GPU 队列与 AQL Dispatch（下）.md#74-runtime-对一批-packet-完成状态的跟踪>)。

</details>

### 3.5 从预留槽位到有效发布，再到设备推进

现在 Producer 已拿到本轮代码句柄、Kernarg 和 S，要把任务放入 Q0。沿本章起点，读写索引均为 37，发布按以下顺序进行：

```text
Producer 原子预留：写索引 37 → 38，取得 ID 37
    → 读取读索引，确认对应槽位可写
    → 填入本轮 Packet 内容，此时仍未允许设备按有效任务处理
    → 按 release 发布协议写入有效 Header
    → 向 Q0 的 Doorbell 通知已发布进度
    → 设备在 Queue 驻留及前序条件满足时读取和处理
```

首先预留编号。Producer 原子增加写索引，取得更新前的 37 作为本次 Packet ID，写索引变为 38。原子操作使并发 Producer 能取得不同编号；具体编号对应的内容是否已经写好，还要由后面的发布动作保证。

**[DESIGN]** 沿用上篇 Q0 的 16 KiB Ring，每个槽位 64 字节，共有 `16 × 1024 / 64 = 256` 个槽位。本轮编号为 37，物理槽位是 `37 % 256 = 37`，字节偏移为 `37 × 64 = 2368 = 0x0940`，所以槽位地址是 `0x1000_0000 + 0x0940 = 0x1000_0940`。后续编号继续增长，物理槽位循环使用；再次使用同一槽位前，Producer 必须根据读索引确认它已可写。

本轮字段也有各自的提供者：`kernel_object` 来自 §3.3 的执行句柄，`kernarg_address` 来自已填写的参数区，完成句柄来自本轮 S。调用者选定 Grid 1024、每组 256；private/group 请求按 Kernel 资源信息与本次动态请求填写，本例取两者为 0。Packet 的 acquire/release fence scope 沿文首取 SYSTEM。

确认槽位可写后，Producer 填写规模、代码句柄、参数地址和完成句柄。填写期间保持 Header 无效，设备才能把“已有编号但尚未写完”与“可解释的任务描述”区分开。全部内容准备好后，Producer 最后以 release 顺序写入有效 Header，交付这份 Packet。

随后写 Q0 的 Doorbell，通知设备检查已发布进度。Header 发布使任务描述按协议变得可读，Doorbell 发出通知；进入执行后，Packet 配置的 acquire/release scope 又约束输入和结果的数据交接。这几个动作发生在不同位置：Host 发布描述，设备按描述执行同步，完成阶段再报告结果。

本例 Doorbell 使用上篇已建立的用户映射，普通发布由用户态直接完成。发布后，设备结合 §3.1 的 Queue 驻留、前序条件和当前进度处理 Packet，再沿 §3.2 已讲过的路径进入 Kernel 执行。

分配、Queue 变更和故障处理仍会按需要进入驱动。每轮向已有 Q0 发布任务时，Producer 复用 Ring、Doorbell 和 GPUVM；§3.1 的管理过程已经提供了设备读取 Q0 所需的配置。

再看发布之后的资源使用。设备读索引越过 37，表示队列消费者已经推进，Ring 槽位可按协议进入后续复用；设备已经取得的任务仍可能继续执行。比如某个 Wave 已取得 Kernarg 中 A 的地址，接下来才发出数组读取；其他工作也可能仍需读取参数。此时应用释放 A 或覆盖 Kernarg，仍可能破坏原任务。

因此，观察 Ring 进度用于判断任务描述消费到了哪里，等待 S 用于确认本轮 Kernel 的正常完成，资源回收还要确认其他消费者也已结束。排查时同时保留单调 Packet ID 与完成对象，避免把同一物理槽位后来写入的内容当成本轮证据。

<details>
<summary>依据：固定源码与规范索引</summary>

> **[SOURCE]** ROCr `ba56a24c6132`，[`hsa.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/hsa.cpp:1058:1) 第 [1058～1069](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/hsa.cpp:1058:1) 行返回更新前的写索引，[`amd_aql_queue.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/amd_aql_queue.cpp:458:1) 第 [458～465](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/amd_aql_queue.cpp:458:1) 行执行原子加法。CLR `81277d69e335`，[`rocvirtual.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocm-clr/rocclr/device/rocm/rocvirtual.cpp:1185:1) 第 [1185～1194](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocm-clr/rocclr/device/rocm/rocvirtual.cpp:1185:1)、[1239～1277](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocm-clr/rocclr/device/rocm/rocvirtual.cpp:1239:1) 行连接槽位写入、Header 发布与 Doorbell，第 [3900～3910](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocm-clr/rocclr/device/rocm/rocvirtual.cpp:3900:1)、[4138～4154](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocm-clr/rocclr/device/rocm/rocvirtual.cpp:4138:1) 行取得启动规模并填写本轮字段。预留、有效发布和多 Producer 的完整证据见 [03 下篇第 5 章](<./03_AMD GPU 队列与 AQL Dispatch（下）.md#5-packet-的发布与-doorbell-通知>)；读索引推进后仍保留任务资源的条件见 [§6.5](<./03_AMD GPU 队列与 AQL Dispatch（下）.md#65-ring-槽位归还后的资源保留>)。

</details>

#### 3.5.1 源码导读：临时 Packet、槽位预留与 Header 发布

本节先在 CLR 中跟读普通 Kernel Dispatch 的发布实现，再进入 ROCr 看 Doorbell 的最终写入。HSA 直接 Producer 遵守同一发布协议；CLR 还管理高层批次、Signal 和 fence 优化，因此本节只代入未进行 Graph 捕获的普通路径，不假定每个高层请求独占一个完成 Signal。

```text
VirtualGPU::submitKernelInternal：取得代码句柄和 Kernarg，构造无效临时 Packet
    → dispatchAqlPacket：普通分支处理先行依赖
    → dispatchGenericAqlPacket：预留 index，等槽位可写，复制 Packet
    → packet_store_release：把 Header 与 setup 一次发布为有效任务
    → HSA Signal 接口 → AqlQueue::StoreRelease / StoreRelaxed：写映射的 Doorbell
设备随后读取 Packet；完成阶段仍按 Packet 的 scope 和 Signal 协议执行
```

<details>
<summary>可选源码：CLR 发布 Packet，ROCr 写入 Doorbell</summary>

先看调用者怎样把“尚未发布”的状态留给发布函数。`dispatchPacket` 是 Host 栈上的临时结构；Ring 中的槽位要到后续函数才写入。

> **[SOURCE]** CLR `81277d69e335`，[`rocvirtual.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocm-clr/rocclr/device/rocm/rocvirtual.cpp:4138:1) 第 [4138～4154](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocm-clr/rocclr/device/rocm/rocvirtual.cpp:4138:1) 行，保留临时结构初始化、无效 Header、代码与参数引用和资源请求。

```cpp
4138   // Initialize the dispatch Packet
4139   hsa_kernel_dispatch_packet_t dispatchPacket{};
4140:
4141   dispatchPacket.header = kInvalidAql;
4142   dispatchPacket.kernel_object = gpuKernel.KernelCodeHandle();
4143:
4144   dispatchPacket.grid_size_x = global[0];
4145   dispatchPacket.grid_size_y = global[1];
4146   dispatchPacket.grid_size_z = global[2];
4147:
4148   dispatchPacket.workgroup_size_x = local[0];
4149   dispatchPacket.workgroup_size_y = local[1];
4150   dispatchPacket.workgroup_size_z = local[2];
4151:
4152   dispatchPacket.kernarg_address = argBuffer;
4153   dispatchPacket.group_segment_size = ldsUsage + sharedMemBytes;
4154   dispatchPacket.private_segment_size = devKernel->workGroupInfo()->privateMemSize_;
```

注释“Initialize the dispatch Packet”表示初始化本轮 Dispatch 描述。这段位于 `VirtualGPU::submitKernelInternal()` 完成参数准备之后，主要证明任务内容先放在临时结构中，Header 仍是 `kInvalidAql`。

第 4139～4142 行把结构清零并设置无效 Header。第 4144～4154 行填写启动规模、Kernarg 和存储请求；本例代入 Grid 1024、每组 256，以及 private/group 请求为 0。后面的第 4155～4167 行按 Kernel 栈使用情况调整 private 请求并检查上限，本次简化条件不进入该分支。有效 Header 另由调用者传入 `dispatchAqlPacket()`，普通分支会进入通用发布函数；捕获分支只复制待保存的 Packet。

> **[SOURCE]** CLR `81277d69e335`，[`rocvirtual.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocm-clr/rocclr/device/rocm/rocvirtual.cpp:1310:1) 第 [1310～1321](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocm-clr/rocclr/device/rocm/rocvirtual.cpp:1310:1) 行区分捕获与实际发布，第 [4191～4206](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocm-clr/rocclr/device/rocm/rocvirtual.cpp:4191:1) 行是本轮调用点。进入普通分支前仍需满足前文的代码、参数、映射与寿命条件。

现在读通用发布函数的入口。这里用原子操作取得尚未递增前的 index；函数后面还要等待槽位可写并发布内容。

> **[SOURCE]** CLR `81277d69e335`，[`rocvirtual.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocm-clr/rocclr/device/rocm/rocvirtual.cpp:1185:1) 第 [1185～1194](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocm-clr/rocclr/device/rocm/rocvirtual.cpp:1185:1) 行，给出发布函数入参、Ring 容量、掩码与索引预留。

```cpp
1185 template <typename AqlPacket>
1186 bool VirtualGPU::dispatchGenericAqlPacket(AqlPacket* packet, uint16_t header, uint16_t rest,
1187                                           bool blocking, bool attach_signal) {
1188   const uint32_t queueSize = gpu_queue_->size;
1189   const uint32_t queueMask = queueSize - 1;
1190   const uint32_t sw_queue_size = queueMask;
1191:
1192   // Check for queue full and wait if needed.
1193   uint64_t index = Hsa::queue_add_write_index_screlease(gpu_queue_, 1);
1194   setFenceDirty(true);
```

注释“Check for queue full and wait if needed”说明这条发布路径会检查容量，需要时等待；实际等待在后面的第 1240 行。第 1193 行经 HSA 接口进入 ROCr 的 `AqlQueue::AddWriteIndexRelease()`，原子加 1，返回旧索引。函数名中的 Release 排序约束发生在这次索引更新；Packet 的字段写入还在后面，需要后续 Header 发布操作交付内容。

> **[SOURCE]** ROCr `ba56a24c6132`，[`hsa.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/hsa.cpp:1058:1) 第 [1058～1071](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/hsa.cpp:1058:1) 行将公开 Queue 句柄转换后调用虚方法；[`amd_aql_queue.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/amd_aql_queue.cpp:463:1) 第 [463～466](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/amd_aql_queue.cpp:463:1) 行实现带 release 顺序的原子加法。

入口后第 1196～1237 行处理 CLR 的 scope 优化和完成 Signal 选择。本篇 SYSTEM scope 条件用于直接 HSA Producer 的贯穿任务；CLR 对照应检查优化后实际发布的 Header 和完成批次。下面接上槽位等待与复制，保留 `blocking` 分支，避免把非阻塞发布和完成等待混为同一行为。

> **[SOURCE]** CLR `81277d69e335`，[`rocvirtual.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocm-clr/rocclr/device/rocm/rocvirtual.cpp:1239:1) 第 [1239～1260](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocm-clr/rocclr/device/rocm/rocvirtual.cpp:1239:1) 行，保留槽位等待、阻塞时的 Signal 准备、槽位寻址与有效发布。

```cpp
1239   // Make sure the slot is free for usage
1240   while ((index - Hsa::queue_load_read_index_scacquire(gpu_queue_)) >= sw_queue_size) {
1241     amd::Os::yield();
1242   }
1243:
1244   // Add blocking command if the original value of read index was behind of the queue size.
1245   // Note: direct dispatch relies on the slot stall above to keep the forward progress
1246   // of the app if a dispatched kernel requires some CPU input for completion
1247   if (blocking) {
1248     if (packet->completion_signal.handle == 0) {
1249       packet->completion_signal = Barriers().ActiveSignal();
1250     }
1251     blocking = true;
1252   }
1253:
1254   TrackQueueProgress(*packet, index);
1255:
1256   AqlPacket* aql_loc = &((AqlPacket*)(gpu_queue_->base_address))[index & queueMask];
1257   *aql_loc = *packet;
1258   if (header != 0) {
1259     packet_store_release(reinterpret_cast<uint32_t*>(aql_loc), header, rest);
1260   }
```

英文注释依次说明：先确保槽位可使用；阻塞路径按需要准备完成对象；Direct Dispatch 的进度还依赖前面的槽位等待。这段主要证明 `index` 的预留、槽位可写和 Header 发布按不同条件推进。

第 1240 行反复用 acquire 读取设备读索引。这里 `sw_queue_size = queueSize - 1`，是这条 CLR 实现采用的等待阈值，应按实际判断式分析容量；HSA Ring 的通用定义回查 03 下篇。**[DESIGN]** 单独取容量 64、`index = 100`、读索引 37，则差值 63，CLR 此处继续等待；读索引到 38 后差值 62，这个槽位才通过当前检查。这个算例从另一时刻取条件，不改变主线 Packet 37 的编号。

第 1256 行以 `index & queueMask` 选择物理槽位，第 1257 行复制仍带无效 Header 的临时结构。第 1258～1260 行在普通 Dispatch 的有效 `header != 0` 条件下，最后调用发布操作。索引分配保证 Producer 得到不同编号；Header 发布把这个编号下已写好的内容交给设备。多 Producer 的连续进度还需按 [03 下篇 §5.5](<./03_AMD GPU 队列与 AQL Dispatch（下）.md#55-多-producer-的发布顺序与-queue-推进>)分析。

> **[SOURCE]** CLR `81277d69e335`，[`rocvirtual.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocm-clr/rocclr/device/rocm/rocvirtual.cpp:1074:1) 第 [1074～1082](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocm-clr/rocclr/device/rocm/rocvirtual.cpp:1074:1) 行，保留 Header 与 rest 合成及 Linux release 原子写入。

```cpp
1074 static inline void packet_store_release(uint32_t* packet, uint16_t header, uint16_t rest) {
1075 #if IS_WINDOWS
1076   std::atomic_ref<uint32_t> atomic_header(*packet);
1077   atomic_header.store(header | (rest << 16), std::memory_order_release);
1078 #else
1079   __atomic_store_n(packet, header | (rest << 16), __ATOMIC_RELEASE);
1080 #endif
1081 }
1082:
```

Linux 分支第 1079 行把低 16 位 Header 和高 16 位 `rest` 合成一个 32 位值，以 release 顺序写到 Packet 起始位置。对本次 Kernel Dispatch，`rest` 是 setup。Host 的发布 release 排序约束与 Packet 中描述设备执行前后同步范围的 acquire/release scope，分别作用于任务描述交付和设备执行的数据交接；跟读时应分别找到它们的代码与规范依据。

第 1261～1273 行是日志和兼容说明，下面继续展示 Doorbell、待完成状态与返回路径。

> **[SOURCE]** CLR `81277d69e335`，[`rocvirtual.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocm-clr/rocclr/device/rocm/rocvirtual.cpp:1274:1) 第 [1274～1293](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocm-clr/rocclr/device/rocm/rocvirtual.cpp:1274:1) 行，保留 Doorbell 通知、待完成状态、条件等待和成功返回。

```cpp
1274   {
1275     Hsa::signal_store_screlease(gpu_queue_->doorbell_signal, index);
1276   }
1277:
1278   // Mark the flag indicating if a dispatch is outstanding.
1279   // We are not waiting after every dispatch.
1280   hasPendingDispatch_ = true;
1281:
1282   // Wait on signal ?
1283   if (blocking) {
1284     LogInfo("Runtime reached the AQL queue limit. SW is much ahead of HW. Blocking AQL queue!");
1285     if (!Barriers().WaitCurrent()) {
1286       LogPrintfError("Failed blocking queue wait with signal [0x%lx]",
1287                      packet->completion_signal.handle);
1288       return false;
1289     }
1290   }
1291:
1292   return true;
1293 }
```

注释说明：标记已有 Dispatch 待完成，普通提交不会每次等待；仅 `blocking` 条件为真才进入完成等待。提示日志说明软件提交进度已领先于硬件，需要阻塞等待；等待失败日志表示当前阻塞 Queue 等待失败，并返回 `false`。

第 1275 行把单调 index 作为 Doorbell 通知值交给 HSA Signal 接口。第 1280 行保存 `hasPendingDispatch_`；非阻塞分支随后返回 `true`，已经发布工作，任务的完成仍由后续协议确认。阻塞分支还调用 `WaitCurrent()`；该调用的等待对象由 CLR 的 Barriers 管理，不能把这里的返回值泛化成整个应用所有异步使用都已结束。

最后进入 ROCr 的 Doorbell 实现。以下取 `enable_dtif()` 关闭、使用已有硬件 Doorbell 映射的分支；代码保留另一分支的条件，避免从函数名推定每次都向内核发请求。

> **[SOURCE]** ROCr `ba56a24c6132`，[`amd_aql_queue.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/amd_aql_queue.cpp:468:1) 第 [468～483](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/amd_aql_queue.cpp:468:1) 行，给出 Doorbell 的特殊 Signal 实现、写入前排序和硬件指针访问。

```cpp
468 void AqlQueue::StoreRelaxed(hsa_signal_value_t value) {
469   if (core::Runtime::runtime_singleton_->flag().enable_dtif()) {
470     HSAKMT_CALL(hsaKmtQueueRingDoorbell(queue_id_));
471   } else {
472     // Hardware doorbell supports AQL semantics.
473     _mm_sfence();
474     *(signal_.hardware_doorbell_ptr) = uint64_t(value);
475     /* signal_ is allocated as uncached so we do not need read-back to flush WC */
476   }
477   return;
478 }
479:
480 void AqlQueue::StoreRelease(hsa_signal_value_t value) {
481   std::atomic_thread_fence(std::memory_order_release);
482   StoreRelaxed(value);
483 }
```

英文注释说明硬件 Doorbell 支持 AQL 语义，以及这份映射的写入不需要用读回刷出写合并。第 480～482 行先做 release fence，再进入第 468～478 行的实现；所选直接映射分支先执行 `_mm_sfence()`，然后经 `signal_.hardware_doorbell_ptr` 写 64 位值。这个指针来自 Queue 创建和 Doorbell 映射，地址来源回接 [上篇 §2.4](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#24-q0-的创建把用户存储交给驱动和设备使用>) 与 [03 上篇 §2.7](<./03_AMD GPU 队列与 AQL Dispatch（上）.md#27-doorbell-是按-process-device-分片按-queue-分槽>)。

**[INFERENCE]** 在有效 Header 尚未发布时，推进写索引只说明槽位编号已被预留。若把有效 Header 写到字段复制之前，设备可能按有效任务解释尚未写好的引用或规模；若只去掉 Doorbell 通知，当前这次发布便缺少本实现的通知动作，能否因已有活动继续推进仍需观察设备状态。这两种变化对应不同证据，不能只凭“GPU 没响应”归为同一个故障。

跟读完成后，在原文件标出临时 Packet、预留编号、容量等待、有效发布、Doorbell 和函数返回六个位置。解释 Packet 37 已被设备消费时，为什么 Kernarg、代码和 A/B/C 仍须保留到最后使用结束。

</details>

Host 已把本轮描述交给 Q0，设备在驻留及前序条件满足后，沿 §3.2 的路径完成计算，再进入 [§4 的完成通知](#4-任务完成通知-host-并继续应用工作)。下面 §3.6～§3.8 分别改变依赖、竞争和访存条件，观察同一项任务还需要等待或恢复哪些步骤。

### 3.6 两条 Queue 完成准备、依赖等待与计算

现在使用 [上篇 §2.5.2](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#252-q1-复用-p-的-gpuvm单独取得-queue-资源>) 创建的 Q1，把 A 的写入从 Host 改为一个准备 Kernel。Q1 写 A，Q0 必须等 A 准备完成再执行 `vector_add`，Host 最后读取 C。代码、映射和 Queue 已经准备好，下面只改变任务的先后关系。

**[DESIGN]** 这是对主线提交条件的独立变体，案例重新从 Packet 37 尚未预留、尚未发布的时刻开始。在这个起点，Q0 的 0～35 和 Q1 的 0～11 已完成；Q0 接下来分配 36、37，Q1 接下来分配 12。Q1 的 Packet 12 执行 `prepare_A`，Q0 的 Packet 36 为 Barrier-AND，Packet 37 执行 `vector_add`。两种案例沿用 Q0 Ring 基址与 Packet 37 地址，便于对照同一任务；它们从各自起点独立推演，实际运行中的 Packet ID 仍继续递增。

两条 Queue 属于 P、指向同一个 GPU Agent，分别保留本轮 Kernarg；S_ready 和 S 初值均为 1，所有使用者结束前不复用。A/B/C 使用前述细粒度系统内存。CPU 预先填好 B 和两份参数，本例采用 SYSTEM 范围完成各处数据交接。

下面按依赖的传递方向阅读。两条 Queue 的发布先后可以变化，图中的箭头表示谁完成后才允许谁继续。

```text
Host：填好 B 与两份 Kernarg，准备 S_ready = 1、S = 1
    → 按发布协议提交 Q1 / Packet 12 和 Q0 / Packet 36、37

Q1 / Packet 12：prepare_A
    SYSTEM acquire → 写 A[i] = i + 1
    → 全部准备工作完成 → SYSTEM release → S_ready：1 → 0
    ↓ S_ready 报告准备完成，供 Q0 检查依赖
Q0 / Packet 36：Barrier-AND，dep_signal[0] 指向 S_ready
    S_ready = 1 → 等待，后继 Packet 37 不能启动
    S_ready = 0 → 执行本 Barrier 的 acquire / release → Barrier 完成
    ↓ 放行同一 Queue 的后继任务
Q0 / Packet 37：vector_add
    SYSTEM acquire → 读 A/B，计算并写 C
    → 全部计算完成 → SYSTEM release → S：1 → 0
    ↓ 报告最终计算完成
Host：acquire 等待 S = 0 → 读取并校验 C
```

S_ready 连接 Q1 的准备任务与 Q0 的 Barrier，S 连接最终计算与 Host。两者均位于 Ring 外；下面再分别解释字段、同步顺序和使用寿命。

<details>
<summary>依据：固定源码与规范索引</summary>

> **[SPEC]** [HSA System Architecture 1.2](https://hsafoundation.com/wp-content/uploads/2021/02/HSA-SysArch-1.2.pdf)（2018-05-02），§2.8.3，原文第 19～20 页：Producer 增加写索引时取得 Packet ID，物理槽位由索引对 Ring 容量取模得到；Ring 槽位的循环使用不重置逻辑 Packet ID。实际下一轮的编号与资源复用见 [§4.4](#44-下一轮使用已有环境并等待所有消费者结束)。

</details>

为便于检验，令 `prepare_A` 写 `A[i] = float(i + 1)`，CPU 预先写 `B[i] = float(10 * (i + 1))`，最终应得到 `C[i] = float(11 * (i + 1))`。这组小整数可由本例单精度格式精确表示，且没有归约运算；`C[0]` 应为 11，`C[5]` 应为 66。

#### 发布前建立两个不同的完成对象

S_ready 表示准备任务的完成，S 表示最终计算的完成。两者初值都为 1，分别由相应 Dispatch 的完成阶段递减：

```text
Q1 / Packet 12：prepare_A
    completion_signal = S_ready   完成准备后把 S_ready 从 1 减为 0

Q0 / Packet 36：Barrier-AND
    dep_signal[0] = S_ready        等待准备任务完成
    其余 dep_signal = 空句柄       本例没有其他依赖
    completion_signal = 空句柄    本例不单独报告 Barrier 完成

Q0 / Packet 37：vector_add
    completion_signal = S         全部计算结束后把 S 从 1 减为 0
```

字段保存的是 Ring 外的 Signal 句柄。12 完成时更新 S_ready，36 只等待它；37 完成时更新 S。将 S_ready 填入 36 的 `completion_signal` 只会指定完成时更新谁，依赖必须放在 `dep_signal` 中。

#### 先满足依赖，再允许后面的 Dispatch 启动

Host 可以先发布 Q0 的 36/37，也可以先发布 Q1 的 12，先后关系由依赖协议保证。但必须让准备任务获得发布机会；若 Host 先等待最终 S、再发布 12，就会阻塞这条依赖链。

当设备处理到 36，若 S_ready 仍为 1，Barrier 等待条件尚未满足，Q0 的 37 不能继续启动。Q1 的 12 可以在其自身条件满足时运行，写 A，完成相应 release 后递减 S_ready。36 观察到依赖满足，再完成自己的同步和收尾，才放行 37。

阻挡后继的是 36 的 Barrier-AND 类型。Header 的 barrier bit 只要求当前 Packet 等同一 Queue 的前序工作完成，不能单独表达 Q1→Q0 的依赖。本例前序工作已结束，36 和 37 的 bit 均可取 0，37 仍须等待 36。

Barrier 由 Packet Processor 处理，等待依赖无需运行占用 CU 的轮询 Kernel；Q1 仍需获得自己的驻留和执行机会。

<details>
<summary>依据：固定源码与规范索引</summary>

> **[SPEC]** [HSA System Architecture 1.2](https://hsafoundation.com/wp-content/uploads/2021/02/HSA-SysArch-1.2.pdf)（2018-05-02），§2.9.1、§2.9.2、§2.9.8、§2.10，原文第 25～27、30～32 页：Header barrier bit 约束本 Queue 前序工作，Barrier-AND 监视依赖 Signal 并在自身完成前阻挡后继 Packet；依赖等待不得占用其他任务取得进展所需的执行资源。ROCr `ba56a24c6132`，[`hsa.h`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/inc/hsa.h:3126:1) 第 [3126～3164](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/inc/hsa.h:3126:1) 行定义依赖 Signal 数组、保留字段和可选完成 Signal。

</details>

#### 顺序依赖与数据可见性一起传递

12 写完 A 后，37 还要按正确同步读到这些写入；37 写完 C 后，CPU 也要满足自己的读取条件。本例把每次交接的生产者和消费者写在同一条路径上：

```text
CPU 写 B、两份 Kernarg，并按协议发布 Packet
    → 12 启动时 SYSTEM acquire，执行 prepare_A
    → 12 完成：写 A 的工作结束 → SYSTEM release → S_ready = 0
    → 36 等 S_ready = 0 → SYSTEM acquire → SYSTEM release → Barrier 完成
    → 37 启动：SYSTEM acquire → 读取 A/B → 写 C
    → 37 完成：SYSTEM release → S = 0
    → Host acquire 等待观察到 S = 0 → 读取并校验 C
```

Header 的发布解决“设备何时可以读取这份有效任务描述”；Packet 的 acquire/release 与 Signal 依赖则建立相应数据交接。Doorbell 只是通知设备检查 Queue，不能替代这两种同步责任。

本例统一使用 SYSTEM，覆盖 CPU 参与的输入、参数和结果交接；Q1 与 Q0 属于同一 GPU Agent，内部交接也沿用这组配置。

注意同步发生的时机：Dispatch 在启动阶段末尾 acquire，随后执行 Kernel；Barrier 先等依赖，再在完成阶段 acquire、release，并按配置更新完成 Signal。

<details>
<summary>依据：固定源码与规范索引</summary>

> **[SPEC]** [HSA System Architecture 1.2](https://hsafoundation.com/wp-content/uploads/2021/02/HSA-SysArch-1.2.pdf)（2018-05-02），§2.9.1～§2.9.2、§3.3.8，原文第 25～27、54 页规定 Packet fence 的作用域与执行阶段；ROCr `ba56a24c6132`，[`hsa.h`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/inc/hsa.h:2885:1) 第 [2885～2912](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/inc/hsa.h:2885:1) 行说明 Dispatch 的 acquire/release 范围。Barrier 的阶段区别按前述系统规范核对，不能把 Dispatch 的时序直接套用到 Barrier。

</details>

#### 用同一案例解释正常等待、推进和失败

S_ready 为 1 时先查 Q1：12 是否已发布、获得驻留并继续执行。S_ready 已为 0 而 S 仍为 1 时，再查 Q0 的 Barrier 是否完成、37 是否启动并完成全部计算。

S 为 0 且 Host 满足 acquire 读取条件后，还要校验 C 的全部 1024 个元素。Signal 只能报告约定的完成状态，不能发现参数、算法或输入轮次错误。

若 12 失败而无法正常更新 S_ready，应结合错误通道收尾；Host 强行把 S_ready 改为 0 会破坏依赖，不能据此使用 C。

12 完成后，A 仍须保留给 37 读取；S_ready 要保持有效且为 0，直到 36 用完。本例没有单独的 Barrier 完成通知，可以保守地等最终 S 完成后再复用 S_ready。

<details>
<summary>依据：固定源码与规范索引</summary>

> **[SPEC]** [HSA System Architecture 1.2](https://hsafoundation.com/wp-content/uploads/2021/02/HSA-SysArch-1.2.pdf)（2018-05-02），§2.9.8，原文第 30～31 页要求依赖值到 0 后持续保持到 Barrier 完成，才能保证其完成。上述 S_ready/S 状态与释放时点是本节明确条件下的 **[INFERENCE]**。同类依赖的字段展开回查 [03 下篇 §7.3](<./03_AMD GPU 队列与 AQL Dispatch（下）.md#73-用-barrier-and-表达跨-queue-依赖>)。

</details>

这个变体在执行前增加了“准备 A → Barrier 等待”的依赖，最终仍由 Packet 37 更新 S，接到 [§4](#4-任务完成通知-host-并继续应用工作)的 Host 完成处理。

### 3.7 两个进程运行时的 CPU 与 GPU 调度

沿总览图的 §3.7，另取 P 已向 Q0 发布 Packet 37、R 即将取得 CPU 时间并提交任务的场景。P、R 的资源归属见 [上篇 §2.5.3](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#253-r-建立自己的进程资源共用-gpu0>)；这里不叠加 Q1 依赖。

**[DESIGN]** P、R 使用独立地址空间和普通 KFD 主上下文，没有显式共享 GPU 缓冲区。P 沿用 PASID 42 和 Q0，R 取 PASID 77，其 Queue 记为 QR。先假定当前配置允许两个进程同时驻留，相关依赖与内存条件均已满足。CPU 时序只选取一个核上的一次线程切换来观察，不假定整台 Host 只有一个核。

P、R 分别持有自己的地址空间与 Queue，共用 GPU0 的 DQM 和设备资源。调度改变执行机会，Q0、QR 和私有数组的归属保持不变。

#### CPU 切换线程，已经提交的 GPU 工作继续推进

**[INFERENCE]** 在 Q0 已驻留、访问条件稳定且没有触发驱逐或错误的前提下，可以出现下面的交错：P 发布 Packet 37 后等待 S；Linux 在某个 CPU 核上改为运行 R；与此同时，GPU 继续执行 P 已提交的计算。R 随后提交自己的任务，在资源和依赖允许时，两份 GPU 工作还可以重叠执行。

```text
观察点 1：P 发布任务
    Host CPU：P 的线程向 Q0 发布 Packet 37
    MI300X：Q0 已驻留，条件满足后读取并执行 Packet 37

观察点 2：P 等待完成，Host 切换线程
    Host CPU：P 等待 S 并睡眠，Linux 在该 CPU 核上改为运行 R
    MI300X：P 的 Q0、映射和任务资源仍有效，计算继续

观察点 3：R 也提交任务
    Host CPU：R 的线程向 QR 发布自己的任务
    MI300X：QR 的驻留、依赖和资源条件满足时，P/R 的工作可重叠

观察点 4：P 的设备任务完成
    MI300X：完成 P 的计算与同步，更新 S；R 的工作仍可继续
    Host CPU：P 获得执行机会并通过 acquire 等待确认完成，再读取 C
```

每个观察点分别写出 Host 与设备的动作，间隔不代表固定时间片。CPU 从 P 切到 R 时，设备是否切换 Queue，要由设备侧的驻留、资源和任务条件判断。

Linux 切换 Host 线程的寄存器、栈与 CPU 地址空间。图示条件下，P 的 Q0 和映射仍有效，已提交的 GPU 工作继续推进；R 获得 CPU 时间后可发布自己的任务，设备再按 QR 的驻留和依赖条件处理。

从任务提交到结果读取，Host 线程在不同阶段需要执行机会。P 发布之前，需要 CPU 时间才能写入任务；P 已发布并进入等待后，Q0、映射和任务引用的存储继续保留，GPU 按已经取得的描述工作；S 完成之后，P 又需要获得 CPU 时间才能从等待返回、读取结果。CPU 调度影响 Host 何时推进这些动作，GPU 的取包和执行则沿自己的状态继续。

<details>
<summary>依据：固定源码与规范索引</summary>

> **[SOURCE]** Linux `248951ddc14d`，[`kernel/sched/core.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/kernel/sched/core.c:5451:1) 第 [5451～5510](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/kernel/sched/core.c:5451:1) 行切换 Host 任务的地址空间和执行状态；[`kfd_packet_manager.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager.c:181:1) 第 [181～240](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager.c:181:1) 行按各进程的 Queue 集合组织设备运行列表。两组入口与 §3.5 的用户态发布路径共同支持上述条件推演。

</details>

#### 驻留名额不足时，GPU 保存和恢复已有工作

现在把条件改为活动需求超过驻留容量。是否换出取决于进程数、Queue 数与当前资源配置，不能仅由“有两个进程”判断。

**[DESIGN]** 为说明被暂停的任务怎样接着运行，选择一次设备调度使 Q0 让出资源、QR 获得驻留的情形。假定 CWSR 已启用、保存区已准备，抢占和恢复均成功。这是状态推演，不断言两个进程的实际轮转顺序或时间片长度。

```text
Q0 的 Packet 37 正在执行
    → 保存 Q0 的队列进度与需要暂停的 Wave 执行现场
    → Q0 让出相应硬件资源，QR 获得本次驻留与执行机会
    → P 的 Ring、映射、代码、数据和保存区继续保留，S 尚未正常完成
    → 以后恢复 Q0 的地址空间、Queue 与 Wave 状态
    → Packet 37 继续剩余工作，最终按 §4 更新 S
```

KFD 构建运行列表时检查进程与 Queue 数量；可同时映射的进程数还受 VMID、并发及隔离配置约束。资源充足时可同时驻留，超出容量时需要安排工作轮流获得资源。

<details>
<summary>依据：固定源码与规范索引</summary>

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_packet_manager.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager.c:46:1) 第 [46～96](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager.c:46:1)、[253～270](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager.c:253:1) 行检查超额使用并处理运行列表；[`kfd_packet_manager_v9.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager_v9.c:148:1) 第 [148～188](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager_v9.c:148:1) 行构造并发进程数量等运行列表信息。源码注释说明该数量受可用 VMID、并发进程配置和隔离配置约束。

</details>

<details>
<summary>配置补充：设备怎样取得 CWSR 保存区地址</summary>

保存区的地址在创建 Q0 时就已确定。HSAKMT 按设备能力计算保存区与控制栈大小，取得 GPU 可访问的存储，把地址和大小放入 `CREATE_QUEUE` 请求。KFD 将这些值存入 Q0 的 Queue 属性，再写入 MQD；当前 GFX9.4.3 路径还按“保存区基址＋本 Queue 各 XCC 的顺序编号×每 XCC 保存区大小”设置各 XCC 的地址。队列配置装入硬件后，设备已有定位保存区的依据，抢占时才把需要暂停的 Wave 现场写入，恢复时再读取。

</details>

抢占前，设备已经需要有地方保存状态。创建 Q0 时，HSAKMT 为保存区与控制栈准备 GPU 可访问存储，把地址和大小交给 KFD，KFD 再写入 Queue 属性与 MQD。因而设备在保存现场时已有可用地址，无须临时向暂停的 Host 线程索取存储；各 XCC 的地址计算保留在上面的配置补充中。

恢复时，Queue 配置与进度让设备重新找到 Q0 原来的工作，CWSR 保存区则提供暂停 Wave 的执行现场。Ring、代码、Kernarg、数组及映射都继续保留，Wave 从保存的状态继续剩余指令，Packet 37 无须由应用重新发布。原来已完成的数组写入也保留，最终仍由本轮正常完成路径更新 S。保存区布局与恢复过程回查 [03 上篇 §3.3](<./03_AMD GPU 队列与 AQL Dispatch（上）.md#33-queue-换出与恢复时的状态保存>)。

<details>
<summary>依据：固定源码与规范索引</summary>

> **[SOURCE]** ROCr `ba56a24c6132`，[`queues.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/queues.c:516:1) 第 [516～582](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/queues.c:516:1) 行准备保存区并把地址交给 KFD；Linux `248951ddc14d`，[`kfd_mqd_manager_v9.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c:235:1) 第 [235～245](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c:235:1)、[727～763](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c:727:1) 行把保存区与控制栈配置写入 MQD，并设置各 XCC 的保存区地址；[`kfd_chardev.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_chardev.c:286:1) 第 [286～293](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_chardev.c:286:1) 行保存请求中的保存区属性。完整保存与恢复的证据和边界见上述 03 小节。

</details>

Host 线程优先级影响 CPU 执行机会，GPU Queue 优先级是设备调度的输入；CPU 上先运行不保证 GPU 上先完成。本例不推定固件的固定时间片或公平比例。

### 3.8 可恢复缺页把设备执行接回 Host 处理

**[DESIGN]** §3.8 从准备阶段另取 SVM 变体：创建 Q0 前启用 XNACK，并选择兼容代码。A 改用 KFD `svm_range` 跟踪的匿名 system RAM，基址仍为 `0x3000_0000`；地址、权限和 GPU 访问授权有效，首次访问却尚缺 GPU 映射。Q0、代码、Kernarg、B/C 和 S 均可用，不叠加依赖或多进程竞争。

这些前提也由准备阶段的请求建立。本变体在应用启动时请求 `HSA_XNACK=1`，ROCr 通过 HSAKMT 向 KFD 设置进程模式。KFD 检查设备支持和已有用户 Queue 状态，成功后把模式保存到 `kfd_process.xnack_enabled`。本例在创建 Q0 前确认实际取得启用状态，并选择兼容该模式的代码。

```text
CPU 准备匿名 RAM 中的 A，地址范围和 CPU 权限有效
    → 应用设置 SVM 属性：A 的地址/长度、允许 GPU0 访问、期望位置为 RAM
    → ROCr/HSAKMT 将属性请求交给 KFD
    → KFD 建立 A 的 svm_range，保存访问位与 preferred_loc = 0（RAM）
    → 本例不预取、不改映射标志，登记后 A 仍在 RAM，GPU 映射待缺页补齐
```

这里的范围登记由应用调用 `hsa_amd_svm_attributes_set()` 触发。位置属性记录的是要求，范围中 A 的实际页面仍在 RAM；首次故障恢复再按这些记录取得页面和准备映射。

两种准备方式的对象和生命周期见 [05 §1.3](<./05_HMM 与 SVM：GPU 缺页恢复与页面迁移.md#13-显式-bo-映射userptr-与-svm>)。这个变体重新选择 A 的管理路径；原来通过普通接口取得的 BO，不能只撤掉映射就当作本例的 SVM 范围。

```text
设备访问 A[5] 遇到可恢复缺页
    → 经 §1 的 IH 故障分支，AMDGPU 调用 KFD SVM 恢复入口
    → 按 PASID 找到 P，再确认 A 的范围和权限
    → Host 的恢复处理取得页面，准备设备地址并更新 GPU 映射
    → 满足更新完成与翻译失效条件，相关设备访问可继续
    → Packet 37 继续计算；完成后才进入 §4
```

设备访问 A[5] 时使用的是 `0x3000_0014`。在本节条件下，地址所属范围有效、GPU 获准读取，但当前 GPU 页表不能完成这次访问所需的翻译，于是设备报告可恢复故障。故障记录提供 PASID 与故障地址等信息，Host 据此定位哪个进程的哪段地址访问受阻。

KFD 先按 PASID 42 找到 P，再取得当前设备和覆盖故障地址的 SVM 范围，检查访问权限与恢复条件。恢复处理同时需要 KFD 进程引用和仍可访问的 mm：引用使软件对象在处理期间可用，mm 用于检查和取得该进程当前的页面。若进程已经退出或权限不满足，就沿对应退出或错误分支结束。对象寿命与地址空间的区别见 [上篇 §2.6](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#26-引用映射与任务完成共同约束资源寿命>)。

本例让 A 留在 RAM，恢复代码先通过 HMM 查询 A 当前对应的 RAM 页面，再为目标 GPU 准备访问这些页面所需的设备 DMA 地址。Host IOMMU 已开启翻译，因此这里的设备地址还要与后续 IOMMU 翻译配合；GPU 页表使用相应设备地址建立 A 的映射。

查询页面和更新 GPU 页表之间，CPU 侧可能改变页面或地址范围。驱动因此需要复查查询结果是否仍有效；若已经失效，就按重试分支重新处理，不能把刚才查到的旧页面继续写进 GPU 映射。确认结果可用后，再提交 GPU 页表更新并处理旧翻译。

页面已取得、页表更新已提交、更新完成且旧翻译已处理，是恢复中的不同进度。只有访问条件满足，受阻的 GPU 访问才能继续取得 A[5]，原 Wave 随后继续计算 C[5]。应用不需要为了补这次映射再发布一份 Packet 37；本轮 S 保持未完成，直到整个任务结束。

这条路径复用上篇建立的 IH 中断通路、进程与 GPUVM 关联，以及 05 的页面恢复过程。恢复映射只补齐访存条件，Host 仍须等待本轮 Kernel 完成。

<details>
<summary>依据：固定源码与规范索引</summary>

> **[SOURCE]** ROCr `ba56a24c6132`，[`flag.h`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/util/flag.h:212:1) 第 [212～215](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/util/flag.h:212:1) 行读取 XNACK 请求，[`amd_kfd_driver.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/driver/kfd/amd_kfd_driver.cpp:542:1) 第 [542～567](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/driver/kfd/amd_kfd_driver.cpp:542:1) 行设置或查询实际模式，[`runtime.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/runtime.cpp:2654:1) 第 [2654～2661](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/runtime.cpp:2654:1)、[2723～2730](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/runtime.cpp:2723:1) 行转换位置属性并提交范围。Linux `248951ddc14d`，[`kfd_chardev.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_chardev.c:1708:1) 第 [1708～1738](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_chardev.c:1708:1) 行处理模式请求，[`kfd_svm.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:3320:1) 第 [3320～3330](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:3320:1) 行更新进程模式，第 [763～806](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:763:1)、[3751～3810](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:3751:1) 行登记范围属性并按条件决定是否迁移或建表。
>
> **[SOURCE]** Linux `248951ddc14d`，[`kfd_svm.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:3047:1) 第 [3047～3267](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:3047:1) 行实现故障恢复入口、进程与地址空间取得、范围处理和引用归还。具体前提与恢复路径见 [05 §1.5](<./05_HMM 与 SVM：GPU 缺页恢复与页面迁移.md#15-可恢复访问的前置条件>)、[第 4 章](<./05_HMM 与 SVM：GPU 缺页恢复与页面迁移.md#4-gpu-故障处理与映射恢复>)。

</details>

#### 3.8.1 源码导读：故障记录、进程引用与 RAM 恢复分支

对应上面的恢复过程，源码入口是 `svm_range_restore_pages()`：先找到进程与范围，再沿 RAM 分支查询页面、准备设备地址和更新 GPU 映射。阅读时重点跟踪“当前引用了谁”和“已经恢复到哪一步”；下面展开锁、字段和返回路径，用于核对这两个问题。

<details>
<summary>可选源码：故障记录、进程引用与 RAM 映射恢复</summary>

本例已经登记 A 的 SVM 范围，GPU 对 A 的读取产生 Retry 故障。现在沿 `svm_range_restore_pages()` 读实际控制流。**[DESIGN]** 本次推演取 Host 页大小 4 KiB、A 位于 RAM、`preferred_loc = 0`，查询和映射最终成功；除用来计算页号外，不改变前面的 SVM 条件。

```text
故障入口：PASID 42、VMID 5、A[5] 的故障页号、时间戳和读写类型
    → 按 PASID 查找并引用 p，检查 drain_pagefaults、设备节点与 XNACK
    → get_task_mm：取得仍存活的地址空间
    → mmap 锁 + svms->lock：查找范围并协调 CPU 地址空间变化
    → migrate_mutex：协调这份范围的页面恢复/迁移
    → 检查重复记录、VMA 权限和恢复位置
    → RAM 路径 validate_and_map：取得当前页面、DMA 映射、确认查询有效、更新 GPU 页表
    → 归还锁、mm 和 p 引用，设备访问按恢复结果继续
```

**[DESIGN]** `p->svms` 管理 P 的 SVM 范围；查询得到的 `prange` 指向其中的 `svm_range`。下面只展开恢复路径需要的成员，是教学简化定义：

```text
svm_range（prange）：本次故障所在的共享虚拟地址范围
    svms → P 的 SVM 范围管理记录
    start / last     首、末页号，计算时包含 last 所在页
    preferred_loc    希望使用的位置；本次取 0，即 system RAM
    actual_loc       当前存储位置；0 表示页面均来自 system RAM
    granularity      恢复/迁移粒度的页数以 log2 编码
    migrate_mutex    协调此范围的恢复与迁移
    dma_addr[]       按 GPU 保存该范围页面的设备 DMA 地址
```

`1UL << granularity` 得到的是页数，`start/last` 的计算也使用页号；与 VMA 交互时，代码再把页号换成字节地址。范围所属关系和成员含义明确后，再进入下方的锁与分支。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_svm.h`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.h:89:1) 第 [89～106](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.h:89:1)、[108～131](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.h:108:1) 行说明位置、粒度和范围成员；恢复入口中对 `p->svms` 的使用见 [`kfd_svm.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:3075:1) 第 [3075～3117](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:3075:1) 行。

入口的 `addr` 是页号。A[5] 的 GPUVA `0x3000_0014` 在 4 KiB 条件下对应页号 `0x3_0000`，页内偏移为 `0x14`。在代码的 `vma_lookup(mm, addr << PAGE_SHIFT)` 处再换回 CPU 字节地址；故障输入和普通 GPUVA 的单位应先确认。

> **[SOURCE]** Linux `248951ddc14d`，[`amdgpu_vm.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c:2986:1) 第 [2986～3022](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c:2986:1) 行保留故障入口、字节地址到页号的转换以及 SVM 恢复调用；[`kfd_svm.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:3047:1) 第 [3047～3113](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:3047:1) 行保留恢复函数入参、按 PASID 取得进程和前置条件检查，第 [3176～3199](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:3176:1) 行检查 VMA 与权限。

`kfd_lookup_process_by_pasid()` 给恢复处理取得进程引用；这让 `p` 的存储在本次处理期间保留。接下来还要取得 mm，才可以安全查询用户范围。两种保护的取得点和归还点要分别记录。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_svm.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:3105:1) 第 [3105～3117](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:3105:1) 行，保留任务引用的存活依据、mm 取得失败分支及 mmap/SVM 锁的取得。

```c
3105 	/* p->lead_thread is available as kfd_process_wq_release flush the work
3106 	 * before releasing task ref.
3107 	 */
3108 	mm = get_task_mm(p->lead_thread);
3109 	if (!mm) {
3110 		pr_debug("svms 0x%p failed to get mm\n", svms);
3111 		r = 0;
3112 		goto out;
3113 	}
3114:
3115 	mmap_read_lock(mm);
3116 retry_write_locked:
3117 	mutex_lock(&svms->lock);
```

英文注释说明 `lead_thread` 的引用由进程释放工作保留，释放前会先等待相应工作结束。此处主要证明：已找到进程之后，还检查线程关联的 mm 是否存活；取得 mm 后才获取地址空间锁和 SVM 范围锁。`get_task_mm()` 失败走 `out` 归还进程引用，本次没有进入页面查询或建表。

已登记 A 的正常分支找到现有 `prange`。原文件第 3137～3162 行还保留范围未找到时的处理：释放 `svms->lock` 和 mmap 读锁，重新取得 mmap 写锁，再重查并按条件创建范围。锁模式改变期间其他线程可能修改范围，因此必须重新进入查找，不能沿用解锁前的结论。第 3162 行取得 `prange->migrate_mutex` 后才检查重复恢复和范围状态。

接着代入 RAM 的条件。`prange->actual_loc == 0` 表示当前页面在 RAM，`best_loc == 0` 表示这次选择 RAM；以下代码先判断是否需要搬运，再调用映射准备。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_svm.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:3211:1) 第 [3211～3242](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:3211:1) 行，保留恢复粒度计算、范围裁剪和完整位置迁移条件分支。

```c
3211 	/* Align migration range start and size to granularity size */
3212 	size = 1UL << prange->granularity;
3213 	start = max_t(unsigned long, ALIGN_DOWN(addr, size), prange->start);
3214 	last = min_t(unsigned long, ALIGN(addr + 1, size) - 1, prange->last);
3215 	if (prange->actual_loc != 0 || best_loc != 0) {
3216 		if (best_loc) {
3217 			r = svm_migrate_to_vram(prange, best_loc, start, last,
3218 					mm, KFD_MIGRATE_TRIGGER_PAGEFAULT_GPU);
3219 			if (r) {
3220 				pr_debug("svm_migrate_to_vram failed (%d) at %llx, falling back to system memory\n",
3221 					 r, addr);
3222 				/* Fallback to system memory if migration to
3223 				 * VRAM failed
3224 				 */
3225 				if (prange->actual_loc && prange->actual_loc != best_loc)
3226 					r = svm_migrate_vram_to_ram(prange, mm, start, last,
3227 						KFD_MIGRATE_TRIGGER_PAGEFAULT_GPU, NULL);
3228 				else
3229 					r = 0;
3230 			}
3231 		} else {
3232 			r = svm_migrate_vram_to_ram(prange, mm, start, last,
3233 					KFD_MIGRATE_TRIGGER_PAGEFAULT_GPU, NULL);
3234 		}
3235 		if (r) {
3236 			pr_debug("failed %d to migrate svms %p [0x%lx 0x%lx]\n",
3237 				 r, svms, start, last);
3238 			goto out_migrate_fail;
3239 		} else {
3240 			migration = true;
3241 		}
3242 	}
```

英文注释说明迁移范围的起点和大小按粒度对齐；迁入 VRAM 失败时尝试回退到 system RAM。相应日志分别记录迁入失败与迁移失败。这段先计算 `start/last`，再以实际位置和目标位置决定是否搬运。两者均为 0 时跳过迁移块，仍继续到第 3244 行建立或恢复 GPU 映射；所以“页面已经在 RAM”只完成了位置条件，后续仍需设备访问条件。

位置迁移分支完整位于原文件第 3216～3242 行，此处不展开其中的 HBM 路径。下面直接接上共同的映射调用和退出路径。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_svm.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:3244:1) 第 [3244～3272](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:3244:1) 行，保留映射调用、错误记录、锁与引用归还，以及 EAGAIN 的返回转换。

```c
3244 	r = svm_range_validate_and_map(mm, start, last, prange, gpuidx, false,
3245 				       false, false);
3246 	if (r)
3247 		pr_debug("failed %d to map svms 0x%p [0x%lx 0x%lx] to gpus\n",
3248 			 r, svms, start, last);
3249:
3250 out_migrate_fail:
3251 	kfd_smi_event_page_fault_end(node, p->lead_thread, addr,
3252 				     migration);
3253:
3254 out_unlock_range:
3255 	mutex_unlock(&prange->migrate_mutex);
3256 out_unlock_svms:
3257 	mutex_unlock(&svms->lock);
3258 	mmap_read_unlock(mm);
3259:
3260 	if (r != -EAGAIN)
3261 		svm_range_count_fault(node, p, gpuidx);
3262:
3263 	mmput(mm);
3264 out:
3265 	kfd_unref_process(p);
3266:
3267 	if (r == -EAGAIN) {
3268 		pr_debug("recover vm fault later\n");
3269 		amdgpu_gmc_filter_faults_remove(node->adev, addr, pasid);
3270 		r = 0;
3271 	}
3272 	return r;
```

映射失败日志表示当前范围尚未完成 GPU 映射；末尾“recover vm fault later”表示这次需要稍后重新恢复。这段主要证明：页面准备和建表错误沿 `r` 返回，范围锁、SVM 锁、mmap 锁、mm 引用和进程引用在对应出口归还；`-EAGAIN` 在外层转换为 0，并移除相应故障过滤记录以允许后续恢复。

继续点进 `svm_range_validate_and_map()`，才看清“恢复映射”的内容。本例有效读权限下，函数按 VMA 范围取得当前页面，再为目标 GPU 准备 DMA 地址；持范围锁复查 HMM 查询结果以及范围是否被并发拆分，确认有效才调用 GPU 映射更新。取到页面、准备地址和写 GPU 表项分开执行，查询结果失效时保留重试条件。

本次调用传入 `wait=false`、`flush_tlb=false`，映射层跳过本层的 Fence 等待，随后仍调用 `kfd_flush_tlb()`。因此，判断访问能否继续时，既要核对异步页表写入的完成条件，也要核对这项翻译失效操作；函数成功返回只说明本次调用按所选分支完成，详细同步条件沿 05 §4.4 继续核对。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_svm.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:1557:1) 第 [1557～1574](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:1557:1) 行把等待条件传给映射函数，按非空 Fence 等待，并调用 `kfd_flush_tlb()`；[`kfd_priv.h`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_priv.h:1560:1) 第 [1560～1567](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_priv.h:1560:1) 行实现这项失效操作。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_svm.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:1679:1) 第 [1679～1701](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:1679:1) 行给出入参和目标 GPU 选择，第 [1763～1779](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:1763:1) 行按 VMA 划分查询区间，第 [1804～1858](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:1804:1) 行连续保留 HMM 查询、DMA 映射、查询有效性与范围拆分检查、GPU 映射更新；第 [1859～1872](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:1859:1) 行归还资源并在成功时更新查询时间戳。页面查询回查 [05 第 3 章](<./05_HMM 与 SVM：GPU 缺页恢复与页面迁移.md#3-cpu-故障处理与-hmm-页面取得>)；GPU 映射更新完成与 TLB 失效回查 [05 §4.4](<./05_HMM 与 SVM：GPU 缺页恢复与页面迁移.md#44-更新完成等待与翻译失效>)。

**[INFERENCE]** 若页面查询后发生范围失效，`amdgpu_hmm_range_valid()` 检查使本次转为 `-EAGAIN`，外层清理后返回 0；这次处理没有完成后续 GPU 映射更新。若进程退出导致取不到 mm，则更早返回。只有沿真实成功分支确认页面和映射已准备好，才接回设备继续执行；即使恢复成功，Packet 37 也还要完成剩余计算并更新 S。

跟读时分别画出 `p` 引用、mm 引用、mmap 锁、`svms->lock` 和 `migrate_mutex` 的取得/释放位置。再代入“CPU 正在迁移 A”与“P 正在退出”两个条件，说明哪些检查使恢复重新查询或停止。细粒度 notifier 协议回查 05，本节关注这份故障记录如何找到正确对象并安全完成调用。

</details>

#### RAM 页面变化后的旧映射撤销与恢复

上面处理首次缺少映射的情形。已有映射以后，如果 Linux 把 A 的后备 RAM 页面换成另一页，KFD 还须先撤销旧 GPU 映射并处理旧翻译，让设备停止沿旧映射访问，再按当前页面恢复。A 的虚拟地址可保持不变，改变的是该地址对应的后备页；下一次恢复仍须查询当前页面，不能复用已经失效的结果。下面给出这一独立场景的完整条件与顺序。

<details>
<summary>扩展场景：A 的地址不变，后备 RAM 页面发生变化</summary>

**[DESIGN]** 单独取 A 已位于 RAM、CPU 与 GPU 映射均有效的时刻。Linux 准备把 A 的数据从旧 RAM 页搬到另一张 RAM 页 Q。A 的虚拟地址与权限保留，期望位置仍为 RAM；进程启用 XNACK，范围未设置要求始终保持 GPU 映射的 `GPU_ALWAYS_MAPPED`。下面取页面迁移和后续恢复成功的情形。

```text
Linux 准备迁移 A 的 RAM 页面
    → 页面变化通知进入 KFD notifier 回调
    → 撤销旧 GPU 映射，等待所需更新并处理旧翻译
    → Linux 搬运数据，CPU 映射改为 RAM 页 Q
    → GPU 后续访问 A 再缺页，HMM 取得当前页 Q
    → 为 Q 准备设备地址并恢复 GPU 映射，访问继续
```

A 的指针保持不变，GPU 后续使用新页面对应的映射。恢复查询若与页面变化交错，KFD 要按失效序号重新确认查询结果。通知与并发检查回查 [05 §6.1](<./05_HMM 与 SVM：GPU 缺页恢复与页面迁移.md#61-页面变化通知与-gpu-映射撤销>)、[§6.2](<./05_HMM 与 SVM：GPU 缺页恢复与页面迁移.md#62-并发查询与建表结果的有效性>)。未启用 XNACK，或范围要求始终保持 GPU 映射时，KFD 改为先暂停 Queue、再主动恢复；这条分支见 [05 §6.4](<./05_HMM 与 SVM：GPU 缺页恢复与页面迁移.md#64-暂停队列后主动恢复映射可选>)。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_svm.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:2660:1) 第 [2660～2695](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:2660:1) 行处理 notifier 与失效序号，第 [2024～2085](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:2024:1) 行按 XNACK 和范围属性选择访问保护方式，第 [1356～1427](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:1356:1) 行撤销 GPU 表项、等待更新并处理 TLB。当前页面的查询与重新映射接到 05 第 3～4 章。

</details>

#### 故障处理结果与原任务的后续推进

处理一条 GPU Retry 故障后，应按实际分支判断它是否补齐了访问条件：

```text
svm_range_restore_pages 处理本条 GPU Retry 故障记录
    ├─ 页面与映射准备成功 → 满足更新条件后，受阻访问继续
    │                         → Packet 37 完成剩余计算 → §4 正常完成
    ├─ 查询失效或页面仍在变化 → 本次暂缓，继续检查后续恢复
    ├─ 旧记录或重复记录 → 跳过本条处理，按当前任务状态继续观察
    └─ 无法恢复 → 错误报告与任务收尾，先结束设备使用再释放资源
```

`svm_range_restore_pages()` 返回 0 可能表示恢复成功、暂缓或跳过。只有确认页面、映射更新和旧翻译处理均完成，才能认为受阻访问可继续；任务完成仍看 S。返回与错误通知回查 [05 §7.1](<./05_HMM 与 SVM：GPU 缺页恢复与页面迁移.md#71-故障返回结果与恢复失败>)、[§7.2](<./05_HMM 与 SVM：GPU 缺页恢复与页面迁移.md#72-故障通知与任务完成等待>)。

<details>
<summary>依据：固定源码与规范索引</summary>

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_svm.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:3070:1) 第 [3070～3113](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:3070:1)、[3164～3186](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:3164:1) 行包含进程退出、过期记录和重复记录的返回，第 [3244～3272](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:3244:1) 行归还资源并将暂缓错误 `-EAGAIN` 转为 0。这里总结处理结果，具体控制流仍在 05 展开。

</details>

**[BOUNDARY]** 本节恢复后 A 仍在 RAM。后文[CPU 迁回场景](#svm-变体gpu-使用后cpu-读取-a-触发-hbm-迁回)另取 A 已在 HBM、GPU 任务已完成的起点，再解释 CPU 读取为何触发迁回。

## 4. 任务完成：通知 Host 并继续应用工作

接着第 3 章的正常任务：Host 已完成 §3.3～§3.5 的准备与发布，设备沿 §3.2 的路径完成本轮计算，接下来要与 Host 交接结果。本章先沿 Host 准备 A/B、Q0 执行 `vector_add`、S 报告完成的单 Queue 主线，走到校验和下一轮复用。读过 §3.6 的两 Queue 变体后，再对照它增加的 S_ready 依赖；§4.3 末尾单独接回 SVM 变体中的 CPU 迁回。

```text
Packet 37 的全部工作完成对 C 的写入
    → 执行 SYSTEM 范围的 release，正常完成路径把 S 从 1 减为 0
    → Host 直接观察 S，或经事件通知后重新检查 S
    → acquire 等待确认本轮条件满足
    → 读取 C，检查全部结果
    → 保留环境提交下一轮，或进入资源释放
```

### 4.1 Kernel 结束、Signal 更新与结果交接

沿本章开头的完成流程，先回到 Packet 37 的计算收尾阶段：某个 Work-item 已经写出 `C[0]`，其他元素还可能在执行。设备要等本例四个 Work-group 全部完成，才进入 Packet 的完成阶段，执行所配置的 release 并更新 S。Host 随后通过 S 确认这一轮计算的结束。

`vector_add` 的各个 Work-item 按索引写 C，S 则由 Packet 的正常完成路径从 1 减为 0。若应用在某个 Work-item 中提前把 S 置 0，Host 就可能在其他 Work-item 仍写 C 时开始读取，破坏本轮的数据交接。

本例 Packet 的 release 采用 SYSTEM 范围，Host 用 acquire 等待观察 S。沿这组配对，GPU 写 C、完成同步、S 更新和 CPU 读取组成明确顺序。映射有效保证 CPU/GPU 能到达相应存储，完成同步保证本轮生产与读取按协议交接，两者都需要。

如果某次任务使用 HBM 输出且 Host 没有可以直接读取的合适映射，还要另外安排结果搬运并等待搬运完成；本篇主线 C 位于细粒度 system RAM，因此 Host 在满足读取条件后直接校验。本例的完成链由 C 的实际存储条件决定，不能把“Signal 完成后直接解引用”泛化到所有分配类型。

> **[SPEC]** ROCr `ba56a24c6132`，[`hsa.h`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/inc/hsa.h:2885:1) 第 [2885～2912](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/inc/hsa.h:2885:1)、[2023～2067](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/inc/hsa.h:2023:1) 行给出 Packet 同步与 acquire 等待语义；[HSA System Architecture 1.2](https://hsafoundation.com/wp-content/uploads/2021/02/HSA-SysArch-1.2.pdf)（2018-05-02）§2.9.2，原文第 26～27 页规定正常完成阶段的 fence 与 Signal 更新顺序。Work-group 完成和 Packet 收尾的衔接见 [03 下篇 §6.2](<./03_AMD GPU 队列与 AQL Dispatch（下）.md#62-packet-的启动准备执行与完成收尾>)。

### 4.2 Signal、通知槽、中断与等待线程的衔接

Packet 37 的完成路径已将 S 从 1 减为 0。Host 线程 T0 接下来要观察这个值，才能按 §4.1 的同步约定读取 C。T0 可能正在主动读取 S，也可能使用 [上篇 §2.3](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#23-申请任务内存并准备完成对象>) 介绍的 `InterruptSignal`，在 KFD Event 上睡眠等待 GPU 的中断通知。两条等待路径都检查 S，阻塞路径还需要通知和线程调度。

```text
GPU 完成路径更新 S
    ├─ Host 正在轮询 → 观察 S → 判断条件并完成 acquire
    └─ 使用 InterruptSignal，Host 已进入事件等待
         → 关联通知槽和中断使 KFD Event 得到处理
         → KFD 唤醒等待线程，使它进入可运行状态
         → Linux 重新调度该线程
         → Runtime 再读 S，确认本轮条件并完成 acquire
```

`InterruptSignal` 在创建时已经保存 KFD Event 以及通知槽相关信息。设备通知经 [上篇 §1](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#1-驱动初始化建立可供应用使用的设备资源>) 建立的 IH 通路返回 Host，KFD 根据事件记录和通知信息找到等待关系。这个过程没有把 C 的数据装进中断记录；C 仍留在原来的存储，Host 按自己的映射读取。

以本轮 S 的通知为例，把 S 关联的 KFD Event 记作 E。创建这份关联时，各个值按下面的过程取得；已有通知页和事件可以按 Runtime 的使用约定复用。

```text
HSAKMT：首次需要通知页时，申请 GPU 可访问的存储，把存储句柄交给 KFD
    → 需要新 Event 时，KFD 创建 E，在 P 的事件表分配编号并选定通知槽
    → HSAKMT 根据通知页基址和槽索引算出槽地址
    → ROCr 在 S 中保存 E 的编号和槽地址，后续设备通知使用这些值
Host 等待 S，当前尚未收到事件且需要阻塞
    → WAIT_EVENTS 带上 E 的编号，KFD 在 P 的事件表找到 E
    → 将等待者登记到 E 的等待队列，通知到来时据此唤醒
```

ROCr 的 Signal 对象保存完成值、E 的编号和通知槽地址；KFD 在 P 的事件表与通知页中保存对应查找关系。设备通知据此找到已登记的等待者：

```text
S：ROCr 的 Signal 对象
    ├─ value：初值 1，GPU 正常完成路径减为 0
    ├─ event_id：E 的事件编号
    └─ event_mailbox_ptr：通知槽地址 → GPU 按地址写入待接收的通知标记

IH 记录中的 PASID 42 与事件标识
    → KFD 后台按 PASID 找到 P
    → 检查 P 的通知槽，按编号从 P 的事件表找到 E
    → E 保存事件状态和等待队列，KFD 更新等待记录并唤醒等待线程
    → Linux 选中该线程执行，ROCr 再读 S.value 并完成 acquire
```

通知槽中的标记用于接收事件；S.value 用于判断本轮计算是否完成。KFD 处理事件时更新等待记录，ROCr 恢复执行后继续检查 S。后台事件处理没有运行在 P 的原提交线程中，因此查找 P 时也要取得相应引用。

KFD 需要进程与事件两层定位信息。设备上可能有 P、R 两个进程，各自又有多条 Queue 和多个 Signal；只有“GPU 有一个完成事件”不足以决定唤醒哪个等待者。事件标识如何压缩、通知槽如何辅助查找，回查 03 的细节即可；这里沿设备记录找到 P，再从 P 找 E 和等待记录。

ROCr 的阻塞等待也不是直接进入一次内核睡眠后就宣布成功。固定实现先保留 Signal 的内部使用引用，反复读取值并判断条件；允许阻塞时先经过短暂主动等待，再调用 KFD 事件等待，返回后继续循环。`WaitAcquire()` 在该过程返回后执行 acquire fence。应用仍须遵守 Signal 的外部生命周期约定，不能一边等待一边无协议地销毁或重置它。

KFD 发出唤醒后，Linux 还要给 T0 CPU 时间，ROCr 才能重新读取 S 并确认条件。KFD 清理的是通知槽，S.value 仍保持本轮的完成值 0；下一轮何时重置 S，由应用的资源复用协议决定。

如果 GPU 已把 S 更新为 0，Host 正忙于其他 CPU 工作，最终业务回调可能稍后才发生。这时设备计算完成到应用处理结果之间的延迟，应沿事件处理、线程调度和 Runtime 回调继续查，确认时间花在了哪一步。

首次沿正常任务阅读，可以接着读 [§4.3](#43-分别确认完成可见与数值正确)，确认取得观察值后怎样使用结果。下面三个小节分别展开值等待、中断转交和睡眠竞争；流程与概念留在正文，原始源码按专题折叠。

#### 4.2.1 沿 WaitAcquire 读取值、转入睡眠并复查

现在回看 GPU 完成之前，等待线程 T0 怎样开始等待。T0 已拿到 S 的句柄，调用 `hsa_signal_wait_scacquire(S, EQ, 0, timeout, BLOCKED)`；它要得到的是本轮 S 的观察值，并在条件满足后读取 C。源码阅读从公开入口进入虚函数，再沿循环走到 KFD 等待，最后回到同一个循环。

```text
T0：hsa_signal_wait_scacquire(S, EQ, 0, ...)
    → Signal::Convert：由句柄取得 ROCr 对象
    → InterruptSignal::WaitAcquire：调用值等待，再完成 acquire
         → WaitRelaxed：临时 Retain，记录一个等待者
         → 读取 S.value
              ├─ 条件满足 → 返回观察值
              ├─ 等待期限已到 → 返回当前观察值
              └─ 继续等待
                   ├─ ACTIVE → 主动检查
                   └─ BLOCKED → 先短暂主动等待，再 WAIT_EVENTS(E)
                                                    ↓ 返回后
                                               重新读取 S.value
```

S 的公开句柄引用、正在执行等待的内部保留引用，以及当前等待者数量分别由 `refcount_`、`retained_`、`waiting_` 记录。`Retain()` 暂时保留 ROCr 对象，匹配的 `Release()` 在退出等待函数时归还；`waiting_` 用于选择可用的等待方式。它们没有替应用证明 Packet 37 已结束，应用仍须保证 GPU 和其他消费者使用 S 时句柄有效。

T0 准备从读值转入事件等待时，GPU 可能恰好完成。理解这个竞争，要先分清 S.value 与 E 中保留的通知状态。事件池为 S 提供自动复位事件 E：`E.auto_reset=true`，`E.signaled` 记录是否还留着一份可接收的通知，等待者自己的 `activated` 则记录本次等待是否已经收到通知。

如果通知到来时 E 上还没有等待者，KFD 将 `E.signaled` 设为 true。稍后 T0 进入 KFD，先把这份状态记入自己的 `activated`，再把 `E.signaled` 自动清为 false。T0 可以直接结束这次事件等待。复位的只是 E 的通知状态，GPU 已写成 0 的 S.value 保持不变。

如果通知到来时已有多个等待者登记在 E 上，KFD 会把它们各自的 `activated` 都设为 true，再唤醒全部已登记等待者；这时自动复位事件无需另外保留 `signaled=true`。因此，自动复位限制的是共享通知状态的保留方式，不能理解为一次只唤醒一个线程。

还有一种交错：T1 已经读到旧的 S.value=1，却晚于 T0 进入 KFD。此时通知可能已被 T0 消费，T1 只检查 `E.signaled=false` 就会再次睡眠。`event_age` 用来保留“自上次观察以来又收到过通知”的证据。KFD 在每次通知时推进 `E.event_age`；每次进入 KFD 等待时，ROCr 交出本次值等待循环上次取得的世代，KFD 比较两者。

**[DESIGN]** 下面取两个已经在等待 S 的线程 T0、T1。二者在各自的本次 `WaitRelaxed()` 循环中，已通过先前的事件等待取得世代 7，随后都读到 S.value=1；新通知到达时，二者暂时都没有登记到 E 的等待队列。7、8 是教学取值，不是 Packet 编号。

```text
起点：S.value=1，E.signaled=false，E.event_age=7
      T0、T1 各自保存上次世代 7，准备进入 KFD 等待
    ↓ GPU 正常完成，将 S.value 从 1 减为 0，并发出通知
KFD 收到通知：E.signaled=true，E.event_age 从 7 增为 8
    ↓ T0 先进入 KFD
T0 取得 activated=true；自动复位使 E.signaled=false
    → 返回世代 8 → ROCr 重读 S.value=0
    ↓ T1 随后进入 KFD
T1 虽然看到 E.signaled=false，但携带的 7 与 E.event_age=8 不同
    → KFD 设置 T1.activated=true，无须睡眠
    → 返回世代 8 → ROCr 重读 S.value=0
```

世代只说明 E 收到过新通知，完成条件仍由 S.value 判断。每次新调用 `WaitRelaxed()` 时，固定实现会把本地 `event_age` 重新设为 1（支持世代）或 0（不支持世代），不会沿用上一次公开 wait 调用的局部变量。0 表示兼容旧接口；在不支持世代且已经存在一个等待者时，ROCr 将新增等待者改为 ACTIVE，让它继续直接检查 S。

> **[SOURCE]** 自动复位与世代检查见 Linux `248951ddc14d`，[`kfd_events.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:641:1) 第 [641～661](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:641:1)、[818～845](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:818:1) 行；收到 Signal 事件后把当前世代交还等待方，见第 [883～918](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:883:1) 行。ROCr `ba56a24c6132` 的 [`interrupt_signal.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/interrupt_signal.cpp:148:1) 第 [148～149](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/interrupt_signal.cpp:148:1) 行设置每次调用的初值与兼容分支，[`events.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/events.c:406:1) 第 [406～410](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/events.c:406:1)、[457～464](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/events.c:457:1) 行在用户态与 KFD 之间传入、取回世代。

<details>
<summary>深入源码：WaitAcquire 的值循环、事件等待与 acquire</summary>

先打开 [`hsa.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/hsa.cpp:1252:1) 第 [1252～1263](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/hsa.cpp:1252:1) 行，确认输入句柄转为哪个对象；接着打开下面的等待实现。不要从 `hsaKmtWaitOnEvent_Ext()` 开始向上猜，因为那一层接收的是 E 的事件信息，已经看不到应用对 S 的比较条件。

> **[SOURCE]** ROCr `ba56a24c6132`，[`interrupt_signal.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/interrupt_signal.cpp:138:1) 第 [138～169](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/interrupt_signal.cpp:138:1) 行给出等待函数入口、内部保留引用、等待者数量、事件世代和循环中的返回条件。

```cpp
138: hsa_signal_value_t InterruptSignal::WaitRelaxed(hsa_signal_condition_t condition,
139:                                                hsa_signal_value_t compare_value,
140:                                                uint64_t timeout,
141:                                                hsa_wait_state_t wait_hint) {
142:   Retain();
143:   MAKE_SCOPE_GUARD([&]() { Release(); });
144:
145:   uint32_t prior = waiting_++;
146:   MAKE_SCOPE_GUARD([&]() { waiting_--; });
147:
148:   uint64_t event_age = core::Runtime::runtime_singleton_->KfdVersion().supports_event_age ? 1 : 0;
149:   if (!event_age && prior != 0) wait_hint = HSA_WAIT_STATE_ACTIVE;
150:
151:   const timer::fast_clock::time_point start_time = timer::fast_clock::now();
152:   const timer::fast_clock::duration fast_timeout = timer::GetFastTimeout(timeout);
153:   const timer::fast_clock::duration kMaxElapsed = std::chrono::microseconds(200);
154:   const uint32_t &signal_abort_timeout =
155:     core::Runtime::runtime_singleton_->flag().signal_abort_timeout();
156:
157:   while (true) {
158:     if (!IsValid()) return 0;
159:
160:     int64_t value = atomic::Load(&signal_.value, std::memory_order_relaxed);
161:
162:     if (CheckSignalCondition(value, condition, compare_value)) {
163:       return value;
164:     }
165:
166:     auto now = timer::fast_clock::now();
167:     if (now - start_time > fast_timeout) {
168:       return value;
169:     }
```

这段代码处于用户态等待线程中，主要证明返回值取自 Signal 值检查。第 142～146 行的两个作用域清理动作分别归还内部引用和等待者计数，无论从哪条正常返回路径离开都执行。第 148～149 行选择是否使用事件世代；第 160～168 行则先查条件、再查时间。

第 158 行在对象已经无效时返回 0。这个分支要求调用者维护 S 的合法生命周期；若另一个线程违规销毁 S，单凭返回 0 无法证明 Packet 37 正常完成。正常主线中 S 始终有效，0 来自第 162～163 行的条件匹配。`Retain()` 保住内部对象存储，与应用保持有效句柄是两层要求。

> **[SOURCE]** ROCr `ba56a24c6132`，[`interrupt_signal.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/interrupt_signal.cpp:173:1) 第 [173～198](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/interrupt_signal.cpp:173:1) 行选择主动等待、短暂等待或 KFD 事件等待；第 [201～208](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/interrupt_signal.cpp:201:1) 行在返回前完成 acquire。

```cpp
173:     if (wait_hint == HSA_WAIT_STATE_ACTIVE) {
174:       if (g_use_mwaitx) {
175:         // Short timeout for active waiting
176:         timer::DoMwaitx(const_cast<int64_t*>(&signal_.value), 1000);
177:       }
178:       continue;
179:     }
180:
181:     if (now - start_time < kMaxElapsed) {
182:       if (g_use_mwaitx) {
183:         // Longer timeout with timer for passive waiting
184:         timer::DoMwaitx(const_cast<int64_t*>(&signal_.value), 60000, true);
185:       }
186:       continue;
187:     }
188:
189:     auto remaining_ms = timer::duration_cast<std::chrono::milliseconds>(
190:       fast_timeout - (now - start_time)).count();
191:
192:     uint32_t wait_ms = std::min<uint32_t>(
193:       static_cast<uint32_t>(std::min<uint64_t>(remaining_ms, 0xFFFFFFFEUL)),
194:       static_cast<uint32_t>(signal_abort_timeout ? signal_abort_timeout * 1000 : 0xFFFFFFFFUL)
195:     );
196:
197:     HSAKMT_CALL(hsaKmtWaitOnEvent_Ext(event_, wait_ms, &event_age));
198:   }
```

两条英文注释分别表示“主动等待使用短超时”与“被动等待的初始阶段可使用带计时器的较长等待”。这里的 `mwaitx` 是否使用取决于运行时条件，不作为本例 Host CPU 的硬件假设。

第 181 行与前一段的 200 μs 阈值比较。允许 BLOCKED 的线程仍会先尝试观察快速完成；超过初始阶段才把剩余时间换成毫秒，交给第 197 行。这里没有接收或检查 `hsaKmtWaitOnEvent_Ext()` 的返回状态，调用结束后直接回到 `while`，T0 从第 158 行开始检查对象有效性，再重读 S.value。

> **[SOURCE]** ROCr `ba56a24c6132`，[`thunk_loader.h`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/inc/thunk_loader.h:56:1) 第 [56～58](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/inc/thunk_loader.h:56:1) 行定义 `HSAKMT_CALL`。该宏只把调用展开为 `thunkLoader()->pfn_hsaKmtWaitOnEvent_Ext(...)`，没有隐藏的错误检查或状态分支；第 197 行是否处理返回状态，应按调用处判断。

```cpp
201: hsa_signal_value_t InterruptSignal::WaitAcquire(
202:     hsa_signal_condition_t condition, hsa_signal_value_t compare_value,
203:     uint64_t timeout, hsa_wait_state_t wait_hint) {
204:   hsa_signal_value_t ret =
205:       WaitRelaxed(condition, compare_value, timeout, wait_hint);
206:   std::atomic_thread_fence(std::memory_order_acquire);
207:   return ret;
208: }
```

这段短函数主要证明：值等待返回以后，ROCr 才执行 acquire fence，然后把该观察值交给调用者。这个 fence 与 §4.1 的设备 release 配合；应用先核对观察值和本轮身份，再按 C 的读取条件使用结果。

> **[SOURCE] 内部对象寿命** ROCr `ba56a24c6132`，[`signal.h`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/inc/signal.h:273:1) 第 [273～281](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/inc/signal.h:273:1)、[447～449](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/inc/signal.h:447:1) 行区分句柄销毁与临时保留；[`signal.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/signal.cpp:167:1) 第 [167～173](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/signal.cpp:167:1) 行在最后一份内部保留引用归还后执行对象销毁。KFD 事件世代的检查见 [`kfd_events.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:832:1) 第 [832～838](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:832:1) 行。事件等待输入与返回世代的交接见 ROCr [`events.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/events.c:406:1) 第 [406～423](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/events.c:406:1)、[457～464](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/events.c:457:1) 行。

> **[SOURCE]** ROCr `ba56a24c6132`，[`interrupt_signal.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/interrupt_signal.cpp:94:1) 第 [94～109](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/interrupt_signal.cpp:94:1) 行保存事件编号和通知槽地址，第 [138～207](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/interrupt_signal.cpp:138:1) 行先检查 Signal、按条件调用 `hsaKmtWaitOnEvent_Ext()`，返回后继续检查；Linux `248951ddc14d`，[`kfd_events.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:95:1) 第 [95～131](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:95:1)、[408～447](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:408:1) 行分配事件编号与通知槽，第 [161～178](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:161:1) 行检查通知槽并按编号查事件，第 [641～660](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:641:1)、[726～794](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:726:1) 行处理事件并唤醒等待者，第 [818～844](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:818:1) 行在事件尚未激活时登记等待者。ROCr [`events.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/events.c:78:1) 第 [78～119](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/events.c:78:1) 行准备本例独立 GPU 路径的通知页、提交创建请求并计算槽地址，第 [406～420](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/events.c:406:1) 行提交等待请求。通知槽和 Signal 的完整关系见 [03 下篇 §7.1](<./03_AMD GPU 队列与 AQL Dispatch（下）.md#71-等待返回超时和唤醒后的状态判断>)。

</details>

**[INFERENCE] 故障推演。** 让本轮 S 仍为 1，有限等待期限先到达。T0 返回 1，应用不能读 C 或归还 Kernarg；应用应记录未满足条件并继续查任务。再让 GPU 已把 S 减为 0，但中断处理尚未推进：主动等待或下一次值复查仍可观察到完成；已经睡眠的线程何时恢复，则还取决于通知与调度。这个区别用于把“计算完成”和“等待线程及时返回”分开定位。

#### 4.2.2 沿 IH 记录进入 KFD 工作线程并找到事件

GPU 现在已经更新 S，并发出了关联 E 的通知。接收方要先从设备记录找到正确的 KFD 节点，再从 PASID 42 找 P，从事件标识找到 E，最终更新等待记录。下面是软件记录的转交过程，补充的是执行上下文与查找关系。

```text
主 IH Ring 中的一条记录：保存来源、节点、PASID 和事件定位信息
    → AMDGPU 读记录并按来源分派，符合转交条件时交给 KFD
    → GFX9.4.3 的 ISR：先检查节点归属，再筛选事件来源
    → 在 interrupt_lock 下将完整记录复制到节点 ih_fifo
    → queue_work：安排该节点的 interrupt_work
    → KFD 工作线程取出记录，调用公共 v9 事件处理
    → 从记录取 PASID 42，查到 P 并取得 kref 引用
    → 在 RCU 读侧检查通知槽、按事件编号从 event_idr 查到 E
    → 清除 E 的通知槽标记，更新 E 与等待者，发出唤醒
    → 归还 RCU 读侧保护与 P 的引用
```

GFX9.4.3 选择 `event_interrupt_class_v9_4_3`，其中 ISR 先检查记录的 Node/VMID 归属，再调用公共 v9 ISR；工作线程使用公共 `event_interrupt_wq_v9()`。本例整卡作为一个逻辑 GPU，接收路径仍要检查记录是否属于该节点。`ih_fifo` 保存复制后的记录，使 IH 的读取可以继续推进，工作线程随后独立处理它。

工作线程从 IH 记录中解出 PASID 与事件标识。正常 CP 完成通知带有“通知槽已更新”的信息；KFD 先取得 P 的引用，在 RCU 读侧检查槽并查找 E，处理结束后归还引用。有效事件标识用于快速查找；快速查找失败且通知页存在时，KFD 再扫描 P 的已通知事件或槽。两条查找路径都限制在 P 的事件集合中。

<details>
<summary>深入源码：IH 记录转交、工作线程与事件查找</summary>

先在 AMDGPU 的 [`amdgpu_ih.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_ih.c:209:1) 第 [209～241](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_ih.c:209:1) 行看到读取循环，再沿 [`amdgpu_irq.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_irq.c:468:1) 第 [468～529](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_irq.c:468:1) 行进入 KFD 分派。之后先确认回调选择，再读入队和工作线程，最后才打开事件处理；这样每次跨文件都能说明交过去的是哪份记录。

> **[SOURCE] 节点与来源筛选** Linux `248951ddc14d`，[`kfd_device.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device.c:140:1) 第 [140～145](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device.c:140:1) 行为 GFX9.4.3 选择事件类；[`kfd_int_process_v9.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_int_process_v9.c:578:1) 第 [578～610](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_int_process_v9.c:578:1) 行给出节点归属包装与回调绑定，第 [329～359](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_int_process_v9.c:329:1) 行进一步检查 PASID、来源及必要的上下文编号。

> **[SOURCE] 记录转交** Linux `248951ddc14d`，[`kfd_device.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device.c:1158:1) 第 [1158～1195](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device.c:1158:1) 行的 `kgd2kfd_interrupt()` 先检查初始化条件，再在节点中筛选和入队；以下是同一函数的完整入队分支。FIFO 写入及溢出处理见 [`kfd_interrupt.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_interrupt.c:105:1) 第 [105～118](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_interrupt.c:105:1) 行。

```c
1184: 		spin_lock_irqsave(&node->interrupt_lock, flags);
1185:
1186: 		if (node->interrupts_active
1187: 		    && interrupt_is_wanted(node, ih_ring_entry,
1188: 			    	patched_ihre, &is_patched)
1189: 		    && enqueue_ih_ring_entry(node,
1190: 			    	is_patched ? patched_ihre : ih_ring_entry)) {
1191: 			queue_work(node->kfd->ih_wq, &node->interrupt_work);
1192: 			spin_unlock_irqrestore(&node->interrupt_lock, flags);
1193: 			return;
1194: 		}
1195: 		spin_unlock_irqrestore(&node->interrupt_lock, flags);
```

这段主要证明筛选、入队、安排工作依次发生在 `interrupt_lock` 保护下。第 1186～1189 行任一条件不满足，就不会执行 `queue_work()`；第 1193 行在成功交给一个节点后返回。FIFO 满时入队函数返回 false 并记录溢出，不能把“上半部看见过记录”作为“等待者一定得到通知”的证据。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_interrupt.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_interrupt.c:136:1) 第 [136～155](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_interrupt.c:136:1) 行在工作线程中逐条处理 FIFO 记录。

```c
136: static void interrupt_wq(struct work_struct *work)
137: {
138: 	struct kfd_node *dev = container_of(work, struct kfd_node, interrupt_work);
139: 	uint32_t *ih_ring_entry;
140: 	unsigned long start_jiffies = jiffies;
141:
142: 	while (dequeue_ih_ring_entry(dev, &ih_ring_entry)) {
143: 		dev->kfd->device_info.event_interrupt_class->interrupt_wq(dev,
144: 								ih_ring_entry);
145: 		kfifo_skip_count(&dev->ih_fifo, dev->kfd->device_info.ih_ring_entry_size);
146:
147: 		if (time_is_before_jiffies(start_jiffies + HZ)) {
148: 			/* If we spent more than a second processing signals,
149: 			 * reschedule the worker to avoid soft-lockup warnings
150: 			 */
151: 			queue_work(dev->kfd->ih_wq, &dev->interrupt_work);
152: 			break;
153: 		}
154: 	}
155: }
```

英文注释说明：连续处理超过约一秒时，重新安排工作，避免长时间处理触发 soft-lockup 警告。第 143 行的回调处理当前记录，第 145 行才从 FIFO 跳过该记录；重新入队的还是同一个节点工作项。

`event_interrupt_wq_v9()` 的正常 CP 通知分支调用 `kfd_signal_event_interrupt(pasid, context_id0, 32, true)`。最后的 true 表示通知槽已经更新；沿下面索引核对进程引用、快速查找与后备扫描。

> **[SOURCE] 事件查找与引用** Linux `248951ddc14d`，[`kfd_int_process_v9.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_int_process_v9.c:362:1) 第 [362～382](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_int_process_v9.c:362:1) 行接收 CP 完成通知；[`kfd_events.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:737:1) 第 [737～799](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:737:1) 行完成进程引用、快速查找、后备扫描与引用归还，第 [161～191](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:161:1) 行按有效标识位数和通知槽查事件；[`kfd_process.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1903:1) 第 [1903～1926](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1903:1) 行在 SRCU 读侧查 PDD，并为返回的 P 增加 `kref`。

</details>

**[INFERENCE] 故障推演。** 已确认 S=0，但 T0 仍睡眠时，按“记录来源和节点 → FIFO 入队 → 工作线程取出 → PASID 查进程 → 通知槽和 E → T0 等待记录”检查。如果 P 已进入退出、查不到 P，事件函数直接返回；如果 FIFO 溢出，先调查通知交付。两种情况都不能通过检查 C 的一个元素来证明等待关系正常。

#### 4.2.3 用事件锁与条件复查处理通知和睡眠的竞争

工作线程与 T0 可能同时操作 E。要避免通知正好到来时 T0 进入长期睡眠，驱动必须协调“检查事件状态”“登记等待者”“通知等待者”这几个动作，还要处理 E 被销毁的情况。

沿用 §4.2.1 的自动复位事件 E，现在补上保护这些状态的锁和等待记录。下面省略无关成员，只表示对象关系，不是源码摘录：

```text
P.event_mutex：串行化事件创建、销毁、等待者的初始化与清理
P.event_idr：事件编号 → E
E（kfd_event）
    signaled：待接收的事件状态
    auto_reset：本例为 true，通知被接收后不再保留 signaled 状态
    event_age：通知世代
    lock：保护上述状态与等待队列更新
    wq：已登记等待者的队列
T0 的 kfd_event_waiter
    event：本次等待的 E；销毁 E 时改为 NULL
    activated：本次等待是否收到事件
    wait：把 T0 登记到 E.wq 的等待队列节点
```

先看 E 的事件锁。T0 在持有 `event_mutex` 的初始化阶段查到 E，再用 `ev->lock` 把“检查已有事件”和“登记新等待者”包在一次临界区内。中断工作线程更新 E 时也取得同一把 `ev->lock`，因此通知只能发生在登记之前或之后，不能插入临界区中间。

```text
通知先到：set_event 保存 signaled / event_age
    → T0 加锁读取到通知 → activated=true → 无须睡眠

T0 先登记：持 ev->lock 检查未通知，加入 E.wq
    → 工作线程取得同一把锁 → 将 T0.activated=true，唤醒 T0

T0 准备调度：先把任务状态设成 TASK_INTERRUPTIBLE，再查 activated
    → 若通知已到，直接离开循环
    → 若随后到，唤醒把任务变回可运行，schedule_timeout 不再长期睡眠
```

`event_mutex` 在建立、清理等待记录时防止事件并发创建或销毁，线程睡眠前会释放它。`ev->lock` 只在读写单个 E 的状态与等待队列时短暂持有。工作线程另用 RCU 读侧保护查到的 E；销毁方从 IDR 移除 E 后，经 `kfree_rcu()` 延后释放存储。查找 P 时取得的 `kref` 则保住进程软件对象，直到本次通知处理结束。

E 被销毁时，KFD 把已登记等待者的 `event` 改为 NULL 并唤醒线程。线程重新检查等待条件，会得到事件等待失败；清理时重新取得 `event_mutex`，避免与销毁方交错访问旧 E。这里要沿三个接口层次看返回结果：

```text
KFD 结束对 E 的等待
    ├─ 等待条件满足 → wait_result=COMPLETE
    ├─ 等待期限用尽 → wait_result=TIMEOUT
    └─ E 已销毁 → wait_result=FAIL，并通过 ioctl 返回错误
         ↓ HSAKMT 包装 ioctl 结果
hsaKmtWaitOnEvent_Ext：返回 SUCCESS、WAIT_TIMEOUT 或 ERROR 等状态
         ↓ 本版本 WaitRelaxed 调用处未检查该状态
ROCr 回到值循环：检查 S 是否有效，重读 S.value，检查比较条件与期限
         ↓ WaitAcquire 完成 acquire fence
hsa_signal_wait_scacquire：向应用返回 Signal 观察值，不返回上述事件状态
```

图中的 COMPLETE 只说明 KFD 的事件等待条件满足。HSAKMT 将内核等待结果转成自己的状态；本版本 `WaitRelaxed()` 没有按该状态分支，仍由自己的值循环决定何时返回。公开 HSA wait 返回的是观察值，应用不能从中直接取出“事件被销毁”或“内核等待超时”的状态码。S 生命周期有效时，应用检查观察值是否满足本轮条件，并结合自己的期限与错误通知决定后续动作；如果 S 被违规销毁，§4.2.1 中的无效对象返回分支也不能证明任务正常完成。

> **[SPEC]** ROCr `ba56a24c6132`，[`hsa.h`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/inc/hsa.h:2023:1) 第 [2023～2067](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/inc/hsa.h:2023:1) 行规定公开 wait 返回 Signal 的观察值，该值可能不满足指定条件；等待也允许在条件未满足时提前恢复。应用必须检查观察值，不能仅凭 wait 返回就读取 C。

<details>
<summary>深入源码：事件锁、唤醒竞争与等待返回状态</summary>

> **[SOURCE]** ROCr `ba56a24c6132`，[`interrupt_signal.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/interrupt_signal.cpp:50:1) 第 [50～62](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/interrupt_signal.cpp:50:1)、[71～89](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/interrupt_signal.cpp:71:1) 行由事件池创建 Signal 事件，`manual_reset=false`。

沿 [`kfd_events.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:958:1) 第 [958～1009](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:958:1) 行进入 `kfd_wait_on_events()`，确认它在初始化期间持有 `event_mutex`、进入睡眠循环前释放。然后读下面两个相互配合的分支。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_events.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:818:1) 第 [818～845](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:818:1) 行将状态检查和等待者登记放在 `ev->lock` 下。

```c
818: static int init_event_waiter(struct kfd_process *p,
819: 		struct kfd_event_waiter *waiter,
820: 		struct kfd_event_data *event_data)
821: {
822: 	struct kfd_event *ev = lookup_event_by_id(p, event_data->event_id);
823:
824: 	if (!ev)
825: 		return -EINVAL;
826:
827: 	spin_lock(&ev->lock);
828: 	waiter->event = ev;
829: 	waiter->activated = ev->signaled;
830: 	ev->signaled = ev->signaled && !ev->auto_reset;
831:
832: 	/* last_event_age = 0 reserved for backward compatible */
833: 	if (waiter->event->type == KFD_EVENT_TYPE_SIGNAL &&
834: 		event_data->signal_event_data.last_event_age) {
835: 		waiter->event_age_enabled = true;
836: 		if (ev->event_age != event_data->signal_event_data.last_event_age)
837: 			waiter->activated = true;
838: 	}
839:
840: 	if (!waiter->activated)
841: 		add_wait_queue(&ev->wq, &waiter->wait);
842: 	spin_unlock(&ev->lock);
843:
844: 	return 0;
845: }
```

英文注释表示 `last_event_age=0` 留作向后兼容。第 828～830 行检查并按自动复位约定消费已有事件；第 833～838 行补充世代检查；只有本次尚未激活时，第 840～841 行才登记等待者。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_events.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:641:1) 第 [641～661](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:641:1) 行在 `ev->lock` 下更新事件与等待者；调用方的加锁和通知槽清理见第 [721～735](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:721:1) 行。

```c
641: static void set_event(struct kfd_event *ev)
642: {
643: 	struct kfd_event_waiter *waiter;
644:
645: 	/* Auto reset if the list is non-empty and we're waking
646: 	 * someone. waitqueue_active is safe here because we're
647: 	 * protected by the ev->lock, which is also held when
648: 	 * updating the wait queues in kfd_wait_on_events.
649: 	 */
650: 	ev->signaled = !ev->auto_reset || !waitqueue_active(&ev->wq);
651: 	if (!(++ev->event_age)) {
652: 		/* Never wrap back to reserved/default event age 0/1 */
653: 		ev->event_age = 2;
654: 		WARN_ONCE(1, "event_age wrap back!");
655: 	}
656:
657: 	list_for_each_entry(waiter, &ev->wq.head, wait.entry)
658: 		WRITE_ONCE(waiter->activated, true);
659:
660: 	wake_up_all(&ev->wq);
661: }
```

第一段英文注释说明：如果自动复位事件已有等待者，本次直接唤醒等待者，事件本身不再保留待消费状态；检查和更新等待队列均受 `ev->lock` 保护。第二条注释表示事件世代回绕时跳过保留的 0、1；警告信息表示世代发生回绕。第 657～660 行先为所有已登记等待者写入 `activated=true`，再唤醒它们，因此自动复位仍可以把同一次通知交给当前已登记的多个等待者。

最后打开睡眠循环，核对任务状态设置与条件检查的先后。下面摘录位于 `kfd_wait_on_events()` 的 `while` 内，进入循环前 `event_mutex` 已释放，结束后还要重新取得它清理等待者。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_events.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:1026:1) 第 [1026～1047](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:1026:1) 行防止检查条件后才设置睡眠状态造成丢失唤醒。

```c
1026: 		/* Set task state to interruptible sleep before
1027: 		 * checking wake-up conditions. A concurrent wake-up
1028: 		 * will put the task back into runnable state. In that
1029: 		 * case schedule_timeout will not put the task to
1030: 		 * sleep and we'll get a chance to re-check the
1031: 		 * updated conditions almost immediately. Otherwise,
1032: 		 * this race condition would lead to a soft hang or a
1033: 		 * very long sleep.
1034: 		 */
1035: 		set_current_state(TASK_INTERRUPTIBLE);
1036:
1037: 		*wait_result = test_event_condition(all, num_events,
1038: 						    event_waiters);
1039: 		if (*wait_result != KFD_IOC_WAIT_RESULT_TIMEOUT)
1040: 			break;
1041:
1042: 		if (timeout <= 0)
1043: 			break;
1044:
1045: 		timeout = schedule_timeout(timeout);
1046: 	}
1047: 	__set_current_state(TASK_RUNNING);
```

英文注释说明：先设为可中断睡眠状态，再查唤醒条件；若并发唤醒已把任务变回可运行，后续调度不会让它长期睡眠，否则这个竞争会造成软挂起或很长的等待。第 1037～1045 行每次醒来都重新判断，并检查剩余超时。

> **[SOURCE] 销毁、返回与清理** Linux `248951ddc14d`，[`kfd_events.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:268:1) 第 [268～285](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:268:1) 行将等待者的事件指针置空、唤醒并延后释放 E；第 [857～877](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:857:1) 行区分 COMPLETE、TIMEOUT 与 FAIL；第 [1011～1023](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:1011:1) 行处理线程信号；第 [939～956](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:939:1)、[1047～1071](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:1047:1) 行恢复任务状态、复制事件数据并清理等待者。

> **[SOURCE] 返回状态的层次** Linux `248951ddc14d`，[`kfd_events.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:1062:1) 第 [1062～1071](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:1062:1) 行在事件失败时设置负错误返回。ROCr `ba56a24c6132`，[`events.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/events.c:389:1) 第 [389～425](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/events.c:389:1)、[457～464](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/events.c:457:1) 行给出 HSAKMT 等待接口、ioctl 错误和超时到状态码的转换，以及返回位置；[`interrupt_signal.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/interrupt_signal.cpp:189:1) 第 [189～208](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/interrupt_signal.cpp:189:1) 行表明 ROCr 调用后继续值循环，随后完成 acquire。`HSAKMT_CALL` 的函数指针展开见 [`thunk_loader.h`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/inc/thunk_loader.h:56:1) 第 [56～58](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/inc/thunk_loader.h:56:1) 行。

</details>

**[INFERENCE] 读码练习。** 把 GPU 通知放在 T0 执行第 829 行之前、登记之后，以及第 1037 行检查之后这三个位置。分别沿 E 的状态、T0 的 `activated`、T0 的任务状态说明它为什么能继续检查。再把“GPU 通知”换成“销毁 E”，沿 NULL 指针标记找到 FAIL 分支；这次退出等待没有提供 C 的正常完成证据。

### 4.3 分别确认完成、可见与数值正确

Host 已从 §4.2 的等待路径取得 S 的一次观察值，接下来要判断能否读取并接受 Packet 37 的结果 C。先检查这个值是否满足本轮等待条件。若本次等待超时，设备任务仍可能继续，应用需要保留资源并检查其状态；确认正常完成和同步条件后，再读取 C。

```text
Host 等待 S，取得本次观察值并核对任务身份与错误状态
    ├─ 未满足完成条件，或出现错误 → 保留资源，检查任务状态或进入错误处理
    └─ 确认本轮正常完成，并已用 acquire 观察到 S = 0
         → 确认 C 的当前映射和存储满足 CPU 读取条件
             ├─ 读取条件不足 → 先取得合法读取条件，再访问 C
             └─ 可以读取 → 逐项校验 C[0..1023]
                  ├─ 与本轮预期一致 → 本轮结果已验证
                  └─ 数值不符 → 检查本轮输入、参数与 Kernel 计算
```

第一层判断是任务正常完成。本例 S 由 Packet 37 的正常完成路径递减，Host 未随意改写它，且没有混用其他轮次。按这个约定观察到 S 为 0，才能把它作为本次完成证据。错误回调、设备停止和超时需要沿相应路径记录，不能把它们统一记成成功。

第二层判断是结果读取条件。确认 GPU 侧完成 release、Host 侧以 acquire 观察到完成，并且 C 的当前映射和存储使用条件仍有效，再读取 C。普通加载恰好读到 S 为 0，不能代替程序本应使用的同步接口。

第三层是业务正确性。在 §3.3 的指定输入下，CPU 逐一检查 1024 个元素是否等于 `float(11 * (i + 1))`。例如 `C[0]` 应为 11，`C[5]` 应为 66；只检查第一个元素会漏掉后面元素的参数或计算错误。对其他浮点算法，需要按计算方式选择比较规则，本例的小整数加法用于让这一轮验证容易理解。

S 可以正常完成而 C 数值错误，例如 Kernarg 指向了错误数组；C 某个元素看起来正确，也可能只是旧值。只有身份、同步和数据校验都对应同一轮任务，才能把记录写成“本轮结果已验证”。

读过 §3.6 的两 Queue 变体后，可以用同样的三层检查：S_ready 只报告 A 的准备完成，Host 仍等待最终 S，再读取 C。该变体采用相同数值，只改变 A 的填写者，因此沿用这里的预期结果。

> **[SPEC]** ROCr `ba56a24c6132`，[`hsa.h`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/inc/hsa.h:2023:1) 第 [2023～2067](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/inc/hsa.h:2023:1) 行规定等待条件与返回的观察值。数值校验方法属于本例的 **[DESIGN]**，未在本次文档修订中执行；正常完成与错误通知的区别接到 [05 §7.2](<./05_HMM 与 SVM：GPU 缺页恢复与页面迁移.md#72-故障通知与任务完成等待>)。

#### SVM 变体：GPU 使用后，CPU 读取 A 触发 HBM 迁回

§3.8 推演的是 A 留在 RAM 时的恢复。这里沿用 SVM 管理路径，另取 HBM 位置策略，观察 CPU 读取时的迁回；正常主线可以直接接 §4.4。**[DESIGN]** 本场景中 A 的期望位置为 GPU0 的 HBM，A 已完成迁入，CPU 页表保留 device-private 条目；Packet 37 已正常完成，应用已满足同步条件。CPU 接下来用原指针读取 A。进程启用 XNACK，范围未要求始终保持 GPU 映射，下面取迁回成功的情形。

```text
GPU 任务完成，应用满足同步条件；A 当前在 HBM
    → CPU 读取 A，device-private 条目使访问进入 CPU 缺页
    → Linux 调用 KFD 的 migrate_to_ram 回调
    → 迁移准备发出通知，先撤销旧 GPU 映射并处理旧翻译
    → 复制 HBM 数据到 RAM 页 Q，等待复制完成并恢复 CPU 映射
    → CPU 重试读取；GPU 以后使用 A 时按当前页面重新恢复映射
```

device-private 条目记录 A 当前由设备私有页面保存，CPU 不能按普通 RAM 映射直接取数，因此这次读取从 CPU 缺页入口触发迁回。原 GPU 任务在本段起点已经完成。迁回后，GPU 原来指向 HBM 的映射已撤销；下一次 GPU 恢复可以映射 RAM，也可以按当时的位置策略再次迁入 HBM。完整过程见 [05 §5.4](<./05_HMM 与 SVM：GPU 缺页恢复与页面迁移.md#54-cpu-再次访问后的-hbm--system-ram>)。

> **[SOURCE]** Linux `248951ddc14d`，[`mm/memory.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/mm/memory.c:4774:1) 第 [4774～4808](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/mm/memory.c:4774:1) 行识别 device-private 条目并调用迁回回调；[`kfd_migrate.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_migrate.c:942:1) 第 [942～1015](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_migrate.c:942:1) 行找到进程与范围并发起迁回，第 [735～763](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_migrate.c:735:1) 行连接迁移准备、复制、等待和收尾；[`mm/migrate_device.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/mm/migrate_device.c:502:1) 第 [502～519](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/mm/migrate_device.c:502:1) 行在迁移收集前发出页面变化通知。旧 GPU 映射保护见 [§3.8 的 RAM 页面变化路径](#ram-页面变化后的旧映射撤销与恢复)及其 notifier 证据。

### 4.4 下一轮使用已有环境，并等待所有消费者结束

Host 已按 §4.3 校验本轮 C，P 接下来准备复用已有环境发起下一轮。Q0、GPUVM、已经装载的代码和保留的分配仍然有效，因此不必重新 probe 设备或执行 `ACQUIRE_VM`；下一轮的输入、Kernarg 和完成状态，要等当前轮次使用结束后再准备。

先沿正常单 Queue 主线。除了等到 Packet 37 的 S 并校验 C，Host 还要确认其他等待者和后续消费者均已结束对这些资源的使用。此时上一轮对数组、参数和 S 的使用全部结束，应用才可以填写新内容并重置完成值。

**[DESIGN]** 假设两轮之间没有其他提交，下一轮继续使用 Q0，编号接着增加：

```text
本轮：Q0 / Dispatch 37 → S = 0 → Host 校验结束，所有使用者离开
    → 重置 S 为 1，填写新一轮 A/B 和 Kernarg
    → Q0 新预留 Packet 38，填写并发布
下一轮：Q0 / Dispatch 38 → Host 等待新结果
```

读过 §3.6 后，再看两 Queue 的复用：最终 S 覆盖了本轮准备与计算依赖链，所有使用者离开后，才重置 S_ready 和 S。仍取两轮之间没有其他提交的条件：

```text
上一轮：Q1 / 12 → Q0 / Barrier 36 → Q0 / Dispatch 37 → Host 校验结束
    → 确认所有等待者和后续消费者均已结束使用
    → 重置 S_ready、S 为 1，填写新一轮的 B 和两份 Kernarg
    → Q1 新预留 13；Q0 新预留 38、39
下一轮：Q1 / 13 → Q0 / Barrier 38 → Q0 / Dispatch 39 → Host 等待新结果
```

两种情形中，新 Packet 都继续引用原来的存储与代码，Signal 值重新表示新一轮状态，Queue 的读写索引继续向前。若以后要重叠多轮，可以为同时在途的轮次保留不同参数、数据缓冲和完成对象，或建立更细的复用协议；复用时点仍需覆盖各对象的最后使用者。

对于多个 Host 模块共享 Runtime 的情况，某个模块结束自己的任务后只归还自己负责的资源与初始化引用。其余线程和 Queue 继续使用 Runtime，直到最后使用者结束。应用决定全部退出时，按 [§5](#5-应用退出停止设备访问并释放资源)解除这些使用关系；下一节先用已经讲过的阶段检查未完成任务。

### 4.5 用阶段证据判断任务停在何处

本节回到尚未确认 Packet 37 完成的观察点：“Host 等待 S，S 一直为 1”。现在要沿发布、依赖、驻留、执行与访存记录，找到最后一个已确认的步骤，再判断任务还缺什么条件。

```text
请求进入 Runtime
    → Producer 实际发布了目标 Packet
    → 目标 Queue 获得处理机会，前序 Packet 和依赖允许推进
    → Kernel 已开始执行，必要访存能够继续
    → 全部工作与完成同步结束，S 被正常更新
    → Host 观察完成并取得可读结果
```

先查发布侧的身份和时间。记录对应的进程、GPU、Queue、Packet ID 和 Signal，再看高层命令是否已经落实为底层发布。只有写索引增长时，仍需查目标槽位的有效发布；看到 Doorbell 写入记录后，还要沿前序 Packet 和 Queue 状态继续判断。没有这组身份，另一个线程或另一条 Queue 的进展很容易被误认成 Packet 37 的进展。

然后查依赖。两 Queue 例子中，S_ready 为 1 且 12 尚未完成，36 的等待符合协议。应转向 Q1 的准备任务；若只盯着 Q0 的最终 S，就会漏掉真正的前置工作。多 Producer 场景则先查是否存在已经预留但尚未发布的前序槽位，两种“前面还没准备好”发生在不同对象上。

接着查 Queue 管理与驻留。KFD 中存在 Q0、MQD 内容完整、运行列表包含 Q0，分别说明软件对象和调度请求的状态。当前 HQD 配置与对应进程上下文，才描述某个观察时刻的硬件驻留。瞬时未驻留在资源竞争时可能是正常调度；应结合前后采样和该进程的实际推进，不从一个快照断言永久挂起。

固定源码提供 `mqds`、`hqds` 和 `rls` 等只读 debugfs 入口，可分别辅助观察内存 Queue 描述、硬件 Queue 状态和运行列表。使用前核对内核配置、权限及当前设备路径；读取结果是某时刻的快照，仍需结合 Queue/进程身份。正文不假定所有环境都已挂载或启用这些入口，也不把原始转储中的每个字段都列为本章必修。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_debugfs.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_debugfs.c:102:1) 第 [102～113](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_debugfs.c:102:1) 行建立 `mqds`、`hqds`、`rls` 只读入口；字段含义接到 [03 上篇第 3 章](<./03_AMD GPU 队列与 AQL Dispatch（上）.md#3-mi300-硬件结构queue-驻留与-mqd-装载>)。本节列出的观察用途是这些入口与已解释对象关系的结合，不是已采集的实机结果。

最后查执行和访存。Queue 读索引已经前进，可以证明消费者取得了进展；要确认 Packet 37 的 Kernel 已开始执行，还需能关联到这次任务的执行记录、调试观察或相应状态。只看到整卡 CU 有活动，可能是 R 在运行。若采用 §3.8 已启用 XNACK 的 SVM 变体，并出现 PASID 42 对 A 的可恢复故障记录，就检查恢复是否取得有效页面、映射更新条件是否满足、设备是否继续。其他故障则按实际类型和错误路径判断。

如果已有不可恢复错误或 Queue 停止记录，应进入错误处理和资源收尾，不再仅通过延长正常 Signal 等待寻找成功。若只是一次等待到期，任务仍可能处在上述某个合法阶段；超时返回没有取消设备工作，资源仍应保留。

**[DESIGN]** 一份简短记录可以按下面的顺序写。每一项都应有实际返回、日志或源码条件，未取得的证据保留空缺，不填猜测结果。

```text
P / GPU0 / Q0 / Packet 37 / Signal S
发布：记录目标 Header 发布和 Doorbell 时刻
依赖：本轮是否有 Barrier 36；S_ready 当前属于哪一轮、由谁更新
驻留：软件 Queue/运行列表情况；当前硬件状态及采样时刻
执行：能否把设备进展或故障明确关联到 Packet 37
完成：S 的本次观察值、等待条件、错误通道状态
数据：Host 读取前满足的同步条件，C 的实际校验结果
```

正常等待、尚未驻留、正在执行、缺页恢复和错误停止，都可能留下 S 未完成的观察结果。从最后一个有证据的步骤继续核对后续条件，才能决定继续等待、推进前置工作，还是处理失败。

## 5. 应用退出：停止设备访问并释放资源

P 决定不再提交新工作。此时需要先确定所有异步使用者已经结束，才按对象关系回收资源。[上篇 §2](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#2-应用接入建立进程地址空间与可复用资源>) 建立的所有权和引用在这里用来回答：哪个对象可以先放，哪个仍被设备、其他 Queue 或 Host 后台工作使用。

```text
停止新的提交，并使 Producer 线程完成提交侧交接
    → 等待本轮任务及其后续消费者结束
    → 正常销毁 Queue，使设备停止使用其 Ring 与辅助状态
    → 归还无人使用的参数、Signal、数据和代码
    → 结束 Runtime 使用并归还设备文件引用
    → 地址空间退出、通知及最后引用触发内核侧最终清理

设备公共内存管理、固件与中断服务继续供 R 使用
```

这是本例选择的正常结束顺序。某份任务资源若已经没有任何使用者，可以更早释放；Runtime 也可能先把资源归还复用池，等池销毁时才释放后备存储。下面把业务完成、Queue 停止和最终对象释放分别讲清。

### 5.1 先结束提交与所有消费者，再归还任务资源

P 决定在 Packet 37 这一轮后退出，不再发起 §4.4 的下一轮。退出方先与所有 Producer 完成线程间交接：禁止新的提交进入，并等正在进行的提交操作结束。否则，一个线程拆除 Q0 时，另一个线程仍可能通过旧指针写 Ring。

接下来按本轮的使用关系收尾。S 报告 Packet 37 正常完成后，退出方还要确认 Host 等待者和数据消费者已经结束：

```text
所有 Producer 已停止进入提交，进行中的提交操作已结束
    → Host 确认 Packet 37 的 S：本轮计算已正常完成
    → 等待线程已离开对 Signal 的使用，Host 已读完 C，其他消费者已结束
    → 本轮数据、参数与 Signal 具备回收条件
    → 按选定结束顺序停用 Queue、归还分配与代码对象
```

S 的完成值确认本轮计算结束；等待线程退出和消费者结束，才使 Signal 与数据不再被使用。应用按接口归还这些资源，[上篇 §2](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#2-应用接入建立进程地址空间与可复用资源>)建立的文件和 BO 引用则由各自持有者归还。后两节继续追踪 Queue 停用和映射撤销。

若采用 §3.6 的两 Queue 变体，T0/T1 先停止对 Q0/Q1 的所有提交，再等待最终 S。12、36、37 按依赖先后完成后，A 的准备和读取已结束，S_ready 的 Barrier 使用也已结束；Host 等待者和其他消费者仍按上图收尾。

等待超时时，退出方还没有取得本轮正常完成的证据。P 可以继续定位，或进入受支持的错误处理，确认相关设备访问已经结束后再回收资源。Host 停止等待后，已发布 Packet 中的地址仍可能被 GPU 使用。

### 5.2 销毁 Queue 时先撤销设备使用

P 已按 §5.1 结束提交和消费者使用，现在请求销毁 Q0。**[DESIGN]** 本节取 Q0 仍标为活动的普通用户 AQL Queue，未启用进程调试，使用 CPSCH 调度且 MES 关闭。

销毁请求经 Runtime、HSAKMT、KFD 进入驱动。ROCr 保存着 [上篇 §2.4](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#24-q0-的创建把用户存储交给驱动和设备使用>) 返回的底层 Queue 句柄；HSAKMT 据此找到用户态 Queue 记录，取出其中的内核 `queue_id`。KFD 用这个编号从 P 的 PQM 找到 Q0，再沿 Queue 的设备关联找到 PDD/DQM。

随后 KFD 将 Q0 标为非活动，卸载设备上的旧运行列表；仍有活动 Queue 时，再提交不含 Q0 的新列表。正常卸载确认后，驱动拆除 Q0 的软件登记与 MQD 等资源，Runtime 继续归还自己管理的 Ring 和辅助存储。设备卸载请求的范围可能还覆盖其他 Queue，§5.2.2 用 Q0、Q1 和 QR 说明筛选范围与后续恢复。

```text
P 请求销毁 Q0，ROCr 使用已保存的底层 Queue 句柄
    → HSAKMT 从用户 Queue 记录取出内核 queue_id
    → DESTROY_QUEUE 携带 queue_id，PQM 按编号找到 Q0
    → 沿 Queue 的设备关联定位 PDD/DQM
    → 将 Q0 移出活动集合，卸载旧列表；仍有活动 Queue 时提交新列表
    → 正常停止成功后，清理 Q0 的软件登记、MQD 与引用
    → Runtime 归还 Ring、scratch 等 Queue 自身资源
    → Q1 或其他 Queue 使用的共享对象继续保留
```

Doorbell 分配记录和 Queue 活动标志会先更新，设备随后才执行卸载控制包。安全回收要等完整停止过程得到确认；若卸载或抢占超时，就要继续追踪错误与恢复处理，确认旧访问怎样结束。

Queue 创建时取得的 Ring、索引和辅助 BO 引用，以及相关映射上的 Queue 使用计数，要在销毁路径中分别归还。映射计数先减少，BO 引用后归还，期间由进程锁等保护映射；§5.2.1 展开这个顺序。保留 BO 存储和保留设备所需映射是两项要求，都必须覆盖设备的最后使用。

Q0 销毁后，P 可以保留 Q1 和 GPUVM。A/B/C、代码或 PDD 是否可以释放，仍取决于其他 Queue、应用和内核关联是否使用它们。首次阅读可先读完下面两节的流程、集合例子和边界说明，再接 [§5.3](#53-内存解除映射runtime-关闭与对象收尾)；源码折叠用于核对实现。

<details>
<summary>深入源码：Queue 销毁的各层入口</summary>

> **[SOURCE]** ROCr `ba56a24c6132`，[`amd_aql_queue.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/amd_aql_queue.cpp:352:1) 第 [352～394](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/amd_aql_queue.cpp:352:1)、[620～627](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/amd_aql_queue.cpp:620:1) 行先停用 Queue，再归还 scratch、Signal、Ring 等资源；[`queues.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/queues.c:785:1) 第 [785～805](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/queues.c:785:1) 行从用户态记录取得内核编号并提交销毁；Linux `248951ddc14d`，[`kfd_device_queue_manager.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2693:1) 第 [2693～2785](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2693:1) 行更新调度与 Queue 登记并释放 MQD；[`kfd_queue.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_queue.c:351:1) 第 [351～384](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_queue.c:351:1) 行归还缓冲引用和相关映射计数。编号查找见 [`kfd_chardev.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_chardev.c:450:1) 第 [450～464](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_chardev.c:450:1) 行，以及 [`kfd_process_queue_manager.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process_queue_manager.c:33:1) 第 [33～44](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process_queue_manager.c:33:1)、[497～523](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process_queue_manager.c:497:1) 行。完整正常与错误边界回查 [03 下篇 §8.1](<./03_AMD GPU 队列与 AQL Dispatch（下）.md#81-rocr-到-kfd-的资源释放顺序>)、[§8.4](<./03_AMD GPU 队列与 AQL Dispatch（下）.md#84-异常清理与错误隔离的边界>)。

</details>

#### 5.2.1 沿 Queue 句柄进入 PQM，并区分映射计数与 BO 引用

退出线程 T0 已取得 Q0 的公开句柄。接下来沿已保存的句柄关系找到内核 Queue，撤销设备使用，再归还各层引用。下图按本节的正常条件展开：

```text
T0：hsa_queue_destroy(Q0 的公开句柄)
    → ROCr 销毁 AqlQueue，先结束内部错误处理器
    → Inactivate：一次性取走 active_，调用 driver.DestroyQueue
    → KFDDriver：hsaKmtDestroyQueue(HSAKMT Queue 句柄)
    → HSAKMT：由用户 queue 对象取出内核 queue_id
    → DESTROY_QUEUE ioctl：取得 P.mutex
    → PQM：queue_id → P 的 Queue 节点 → Q0 → PDD
         ① 减少相关 GPUVM 映射的 queue_refcount
         ② 调用 Q0 所在设备的 DQM，确认停止使用 Q0，再释放其 MQD
         ③ 归还 Q0 持有的 Ring、索引、CWSR 等 BO 引用
         ④ 清理 Queue 节点和 ID，必要时注销空的调度登记
    → 释放 P.mutex，返回用户态
    → HSAKMT / ROCr 释放自己的辅助对象与原始分配
```

`queue_refcount` 保存在 BO 对应的 GPUVM 映射记录中，记录 Queue 对这份映射的使用计数；BO 引用保住后备内存对象。第①步只减少 Q0 对应的映射使用计数，当前 PTE 与 BO 存储仍在；第③步归还的是 KFD 创建 Q0 时取得的那份 BO 引用。ROCr 的原始分配以及其他 Queue 的引用若仍存在，BO 就继续保留。Ring、读写索引和 CWSR 存储都要覆盖设备的最后使用时刻，尤其在队列卸载期间，固件仍可能读取或保存状态。

普通路径中 T0 从第①步到第④步持有 `P.mutex`。另一个线程请求 GPU UNMAP 也要取得同一把锁，因此它在队列停止完成前不能通过本进程接口拆除 Ring 映射。这里还存在 BO reserve 锁和 DQM 锁：分别协调映射计数更新与设备调度集合。先在外层找到锁的范围，再读内部状态，才能理解“计数先减少、存储后释放”为什么成立。

**[BOUNDARY]** 错误路径要分别检查内核清理和用户态返回。PQM 遇到 DQM 返回 `-ETIME` 或 `-EIO` 时，仍继续清理 Queue 节点并归还缓冲引用，再把错误返回；HSAKMT 仅在 ioctl 成功后释放自己的 Queue 辅助对象。ROCr 的 `Inactivate()` 用断言检查底层错误，末尾却固定返回成功，因此这一层的成功返回不足以确认设备正常停止。§5.2.2 继续追踪卸载、超时与恢复。

<details>
<summary>深入源码：句柄查找、映射计数、BO 引用与返回路径</summary>

> **[SOURCE]** ROCr `ba56a24c6132`，[`hsa.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/hsa.cpp:801:1) 第 [801～809](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/hsa.cpp:801:1) 行从公开 Queue 句柄取得 Runtime 对象并调用 `Destroy()`。

沿 `Destroy()` 进入 AqlQueue 析构。析构先与内部错误处理器交接，再停用 Queue，最后释放自身资源。

> **[SOURCE]** ROCr `ba56a24c6132`，[`amd_aql_queue.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/amd_aql_queue.cpp:342:1) 第 [342～395](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/amd_aql_queue.cpp:342:1) 行先终止并等待内部处理器，第 364 行停用 Queue 后再释放 scratch、内部 Signal 和 Ring。以下第 [620～628](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/amd_aql_queue.cpp:620:1) 行给出停用函数。

```cpp
620: hsa_status_t AqlQueue::Inactivate() {
621:   bool active = active_.exchange(false, std::memory_order_relaxed);
622:   if (active) {
623:     auto err = agent_->driver().DestroyQueue(queue_id_);
624:     assert(err == HSA_STATUS_SUCCESS && "Destroy queue failed.");
625:     atomic::Fence(std::memory_order_acquire);
626:   }
627:   return HSA_STATUS_SUCCESS;
628: }
```

英文断言信息表示“驱动销毁 Queue 失败”。第 621～623 行用 `exchange` 取走原活动状态，仅第一个观察到 true 的调用发出底层销毁请求。这里的软件原子操作避免重复请求；设备停止由驱动执行，下一单元继续追踪。该函数通过断言检查驱动返回，却没有把驱动错误作为返回值向上传递，源码末尾固定返回 `HSA_STATUS_SUCCESS`。因此调试异常时要记录底层结果，不能只用这一层的成功返回证明抢占成功；应用也仍须遵守 Queue 句柄的并发使用约定。

> **[SOURCE] 句柄交接与进程锁** ROCr `ba56a24c6132`，[`amd_kfd_driver.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/driver/kfd/amd_kfd_driver.cpp:367:1) 第 [367～372](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/driver/kfd/amd_kfd_driver.cpp:367:1) 行进入 HSAKMT；[`queues.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/queues.c:785:1) 第 [785～805](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/queues.c:785:1) 行从用户 Queue 对象取出内核编号，ioctl 成功后才 `free_queue()`。Linux `248951ddc14d`，[`kfd_chardev.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_chardev.c:449:1) 第 [449～464](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_chardev.c:449:1) 行在 `P.mutex` 下调用 PQM；第 [1392～1444](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_chardev.c:1392:1) 行的 GPU UNMAP 同样持有这把锁。

进入 PQM 后，先读查找部分：`get_queue_by_qid()` 从 P 的队列集合找节点，用户 Queue 分支从 `pqn->q->device` 取得设备，随后据设备找到 PDD。编号错误返回 `-EINVAL`，缺少设备或 PDD 时也不会进入正常停止；这些返回发生在 Queue 资源清理之前。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_process_queue_manager.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process_queue_manager.c:497:1) 第 [497～527](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process_queue_manager.c:497:1) 行建立查找上下文；同一 `pqm_destroy_queue()` 的用户 Queue 分支与返回尾部见第 [536～566](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process_queue_manager.c:536:1) 行。

```c
536: 	if (pqn->q) {
537: 		retval = kfd_queue_unref_bo_vas(pdd, &pqn->q->properties);
538: 		if (retval)
539: 			goto err_destroy_queue;
540:
541: 		dqm = pqn->q->device->dqm;
542: 		retval = dqm->ops.destroy_queue(dqm, &pdd->qpd, pqn->q);
543: 		if (retval) {
544: 			pr_err("Pasid 0x%x destroy queue %d failed, ret %d\n",
545: 				pdd->pasid,
546: 				pqn->q->properties.queue_id, retval);
547: 			if (retval != -ETIME && retval != -EIO)
548: 				goto err_destroy_queue;
549: 		}
550: 		kfd_procfs_del_queue(pqn->q);
551: 		kfd_queue_release_buffers(pdd, &pqn->q->properties);
552: 		pqm_clean_queue_resource(pqm, pqn);
553: 		uninit_queue(pqn->q);
554: 	}
555:
556: 	list_del(&pqn->process_queue_list);
557: 	kfree(pqn);
558: 	clear_bit(qid, pqm->queue_slot_bitmap);
559:
560: 	if (list_empty(&pdd->qpd.queues_list) &&
561: 	    list_empty(&pdd->qpd.priv_queue_list))
562: 		dqm->ops.unregister_process(dqm, &pdd->qpd);
563:
564: err_destroy_queue:
565: 	return retval;
566: }
```

英文错误信息记录 PASID、Queue ID 和驱动错误码。这段主要证明各层清理的次序，以及错误会改变后续控制流。

第 537 行减少映射使用计数，失败则直接走返回。第 542 行调用 DQM，正常返回后第 551 行才归还缓冲引用。第 556～562 行移除 PQM 节点、回收编号，并在设备上的用户及特权 Queue 列表都为空时注销进程调度登记。这个注销处理的是 P 在该设备上的 Queue 管理关系，PDD、GPUVM 与应用分配仍按各自寿命保留。

第 547～548 行将错误路径分开：`-ETIME` 和 `-EIO` 继续走软件清理，然后返回原错误；其他非零返回先退出。发生异常时，先记录实际走过的分支和已清理对象，再沿下一节核对设备停止与恢复结果。

> **[SOURCE] 引用与计数的归还** Linux `248951ddc14d`，[`kfd_queue.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_queue.c:351:1) 第 [351～406](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_queue.c:351:1) 行分别执行 buffer put、CWSR 范围归还与 BO 映射记录的 `queue_refcount` 递减。映射计数操作先 reserve GPUVM 根 BO，再更新相关记录。

</details>

**[INFERENCE] 读码练习。** T0 销毁 Q0，T1 同时解除 Ring 的 GPU 映射。先按本单元普通条件画出两次 `P.mutex` 的取得顺序，指出 T1 何时才可进入 UNMAP。再把 DQM 的返回改为 `-ETIME`，沿第 547 行说明哪些软件对象仍会被清理、HSAKMT 是否会按成功路径释放辅助对象，以及为什么必须继续追踪停止与恢复结果。

#### 5.2.2 沿 CPSCH 卸载请求确认停止，并追踪超时边界

PQM 已找到了 Q0，DQM 接下来更新 §3.1 建立的运行列表，使设备停止使用 Q0。这里再取调度正在运行、旧运行列表已经提交的条件；应用任务已结束，但 Q0 的 Queue 管理状态仍需撤销。

DQM 通过 HIQ 提交卸载和查询控制包，等待固件回写，再检查抢占结果。正常顺序如下：

```text
DQM：取得 dqm->lock，检查 Q0 的销毁状态
    → 归还 Q0 的 Doorbell 分配记录
    → 减少活动 Queue 计数，Q0.is_active=false
    → execute_queues_cpsch：卸载旧运行列表，再检查剩余活动集合
         → 取得 Reset 域的读侧保护
         → UNMAP_QUEUES：按 DYNAMIC_QUEUES 筛选，卸载范围内的动态计算 Queue
         → 将控制完成槽设为 INIT，内存屏障后发送 QUERY_STATUS
         → 等待固件回写 COMPLETED
         → 检查 HIQ MQD 的抢占失败记录，必要时恢复或报告 Hang
         → 释放旧运行列表 IB，active_runlist=false
         → map_queues_cpsch 检查剩余活动 Queue
              ├─ 仍有活动 Queue → 提交新列表：排除 Q0，保留其他活动 Queue
              └─ 已无活动 Queue → 直接返回，不提交新列表
    → 移除 Q0 的 DQM 列表与计数
    → 释放 dqm->lock 后归还 MQD
    → 返回 PQM，由 PQM 再归还 Ring/索引/CWSR 引用
```

图中 DQM 继续使用自己的 Packet Manager 和 HIQ 发送控制包。下面列出本次流程会读取或修改的状态，作为 §3.1 对象关系的补充；这是教学简化表示：

```text
Q0.properties.is_active       Q0 是否纳入下一份运行列表
DQM.active_runlist            DQM 是否保留已提交的运行列表
DQM.packet_mgr                构造控制包、通过 HIQ 提交并管理运行列表 IB
DQM.fence_addr                Host 访问控制完成槽的地址
DQM.fence_gpu_addr            交给固件、用于回写同一完成槽的 GPU 地址
```

控制完成槽用来确认卸载控制流程；Packet 37 的完成 Signal S 则用于应用任务交接。

运行列表描述设备接下来可处理的 Queue。DQM 先把 `Q0.is_active` 改为 false；Packet Manager 重建运行列表时会跳过 Q0。设备可能仍持有旧列表中的 Q0 状态，所以 DQM 还要发送卸载请求，等待控制完成，并检查抢占失败记录，然后才能按正常路径释放 Q0 的 MQD。

若 Q0 是该 DQM 的最后一条活动 Queue，且 Runtime 内部 Queue 等其他 Queue 也已不再活动，卸载后活动计数为零，`map_queues_cpsch()` 直接返回，设备无需接收一份新的运行列表。下面的三 Queue 例子仍有 Q1 和 QR，因此会继续构造并提交新列表。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_device_queue_manager.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2266:1) 第 [2266～2287](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2266:1) 行先检查调度与活动集合；活动 Queue 或进程计数为零时，在调用 `pm_send_runlist()` 前返回。

本例的 `filter` 实际取 `KFD_UNMAP_QUEUES_FILTER_DYNAMIC_QUEUES`。对应控制包选择计算引擎，把 `queue_sel` 编成 `unmap_all_non_static_queues`，即对当前控制范围内的所有非静态计算 Queue 执行请求。这里的“动态”是管理包中的 Queue 类别；筛选没有使用 Q0 的 `queue_id`，也没有按 P 的 PASID 缩小范围。`reset=false` 选择抢占动作，`filter_param=0` 在这个分支不用于指定某条 Queue。

**[DESIGN]** 为了看清卸载范围，从同一个 DQM 管理的 Queue 中选出三条应用 Queue：P 持有 Q0、Q1，R 持有 QR，三者均为普通动态计算 Queue。假设旧运行列表包含三者，Q1 和 QR 的活动资格保持不变，CWSR 已启用且保存区有效。图中只列出这三条应用 Queue；Runtime 内部 `QueueUtility` 等未画出的 Queue 仍按各自类别与活动条件参与同一管理过程。期间没有其他集合变化，本次卸载与新列表提交均正常完成。这里只请求销毁 Q0：

```text
旧运行列表中的应用 Queue（节选）：{P.Q0, P.Q1, R.QR}
    → DQM 仅把 P.Q0 标为非活动
    → DYNAMIC_QUEUES 卸载请求仍覆盖旧范围中的 {P.Q0, P.Q1, R.QR}
    → 正常卸载确认后，按各 Queue 的活动标志重建列表
    → 新运行列表中的应用 Queue（节选）：{P.Q1, R.QR}
    → 清理 P.Q0 的软件节点、MQD 和引用
      P.Q1、R.QR 的软件对象及任务状态保留，后续按新列表取得驻留条件
```

因此，Q1 和 QR 也可能经历驻留撤销与恢复，但此次销毁请求只拆除 Q0 的软件资源。卸载过程可以抢占并保存未结束的工作；其控制完成不保证 Q1、QR 中的应用任务已经算完。尚未完成的任务仍按自己的完成 Signal 和依赖继续推进，保存与恢复过程回接 §3.7。

> **[SOURCE] 卸载范围与新列表筛选** Linux `248951ddc14d`，[`kfd_device_queue_manager.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2744:1) 第 [2744～2756](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2744:1) 行先清除 Q0 的活动标志，其中第 [2748～2750](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2748:1) 行传入 `KFD_UNMAP_QUEUES_FILTER_DYNAMIC_QUEUES`；[`kfd_packet_manager_v9.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager_v9.c:390:1) 第 [390～437](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager_v9.c:390:1) 行构造卸载包，其中第 [427～430](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager_v9.c:427:1) 行选择全部非静态 Queue。新列表由 [`kfd_packet_manager.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager.c:181:1) 第 [181～240](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager.c:181:1) 行遍历各进程和 Queue，其中第 [223～225](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager.c:223:1) 行跳过非活动用户 Queue。

正常停止需要覆盖图中的整条控制路径。驱动先等待 QUERY_STATUS 回写 COMPLETED，再检查 HIQ MQD 中的抢占失败记录：固件可能已经放弃某条 Queue 的卸载请求，却仍完成后面的状态查询。发现失败后，驱动尝试恢复；恢复失败则报告 Hang，并返回错误。Doorbell 分配记录已归还或 `is_active=false`，都只说明前面的软件更新已经发生。

读 `destroy_queue_cpsch()` 时，先定位 `dqm_lock()`、`wait_on_destroy_queue()`、活动判断和 `free_mqd()`。`is_being_destroyed` 保护驱动内部重复销毁；本例未启用进程调试，直接沿普通锁范围读。调试暂停分支可能释放 `P.mutex` 与 DQM 锁后等待，再重新加锁，若以后调试该场景，要重新核对锁范围，不能照搬本单元的普通竞争推演。

**[BOUNDARY]** 超时或 Reset 竞争时，Queue 销毁仍可能继续清理软件节点和 MQD；上一单元已给出 PQM 对 `-ETIME`、`-EIO` 的特殊分支。`destroy_queue_cpsch()` 遇到 `-ETIME` 还设置 `qpd->reset_wavefronts`，后续进程终止可能尝试 Wave 复位。调试这类结果时要继续核对 Hang、Reset 与 Wave 停止，不能以“软件 Queue 查不到了”替代停止证据。§5.4 继续说明退出和最终释放如何处理复位工作。

<details>
<summary>深入源码：动态 Queue 卸载、控制回写与失败恢复</summary>

> **[SOURCE] 销毁状态与 MQD 寿命** Linux `248951ddc14d`，[`kfd_device_queue_manager.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2659:1) 第 [2659～2691](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2659:1) 行检查销毁和调试暂停；第 [2693～2785](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2693:1) 行在 DQM 锁下更新 Doorbell、活动标志和运行列表，释放锁后归还 MQD，以避免循环加锁。第 [2643～2657](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2643:1) 行的 `execute_queues_cpsch()` 在卸载正常返回后才调用 `map_queues_cpsch()`。

接着沿 `unmap_queues_cpsch()` 阅读。调用者已经传入动态 Queue 筛选条件和默认抢占等待条件，`execute_queues_cpsch()` 再把 `reset` 设为 false。下段保留函数入口、前提判断、发送控制包、查询与超时分支。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_device_queue_manager.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2550:1) 第 [2550～2589](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2550:1) 行的 `unmap_queues_cpsch()` 要求调用者已经持有 DQM 锁，检查运行状态并等待控制请求完成。

```c
2550: static int unmap_queues_cpsch(struct device_queue_manager *dqm,
2551: 				enum kfd_unmap_queues_filter filter,
2552: 				uint32_t filter_param,
2553: 				uint32_t grace_period,
2554: 				bool reset)
2555: {
2556: 	struct device *dev = dqm->dev->adev->dev;
2557: 	struct mqd_manager *mqd_mgr;
2558: 	int retval;
2559:
2560: 	if (!dqm->sched_running)
2561: 		return 0;
2562: 	if (!dqm->active_runlist)
2563: 		return 0;
2564: 	if (!down_read_trylock(&dqm->dev->adev->reset_domain->sem))
2565: 		return -EIO;
2566:
2567: 	if (grace_period != USE_DEFAULT_GRACE_PERIOD) {
2568: 		retval = pm_config_dequeue_wait_counts(&dqm->packet_mgr,
2569: 				KFD_DEQUEUE_WAIT_SET_SCH_WAVE, grace_period);
2570: 		if (retval)
2571: 			goto out;
2572: 	}
2573:
2574: 	retval = pm_send_unmap_queue(&dqm->packet_mgr, filter, filter_param, reset);
2575: 	if (retval)
2576: 		goto out;
2577:
2578: 	*dqm->fence_addr = KFD_FENCE_INIT;
2579: 	mb();
2580: 	pm_send_query_status(&dqm->packet_mgr, dqm->fence_gpu_addr,
2581: 				KFD_FENCE_COMPLETED);
2582: 	/* should be timed out */
2583: 	retval = amdkfd_fence_wait_timeout(dqm, KFD_FENCE_COMPLETED,
2584: 					   queue_preemption_timeout_ms);
2585: 	if (retval) {
2586: 		dev_err(dev, "The cp might be in an unrecoverable state due to an unsuccessful queues preemption\n");
2587: 		kfd_hws_hang(dqm);
2588: 		goto out;
2589: 	}
```

第 2582 行英文注释指向后面的超时等待；第 2586 行错误信息说明 Queue 抢占未成功，CP 可能进入无法恢复的状态。这个函数处于旧运行列表撤销阶段，主要证明驱动通过控制包要求设备卸载，并等待固件回写。

第 2560～2565 行先检查调度和旧运行列表是否存在；不存在时直接返回，正在复位而无法取得保护时返回 `-EIO`。第 2574 行发送卸载控制包，失败走公共返回。第 2578～2584 行把控制完成槽复位，用内存屏障排好写入顺序，再发送查询并等待设备回写。这里的 `dqm->fence_addr` 是控制请求的完成槽，应用 Packet 37 的 S 是另一个对象。

固件回写后还要读下面的失败检查。抢占请求可能被固件放弃，同时在 HIQ MQD 中留下未响应 Queue 的 Doorbell 记录，因此仅看到 COMPLETED 仍需继续核对。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_device_queue_manager.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2591:1) 第 [2591～2606](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2591:1) 行在回写后检查计算 Queue 抢占与 SDMA Hang。

```c
2591: 	/* In the current MEC firmware implementation, if compute queue
2592: 	 * doesn't response to the preemption request in time, HIQ will
2593: 	 * abandon the unmap request without returning any timeout error
2594: 	 * to driver. Instead, MEC firmware will log the doorbell of the
2595: 	 * unresponding compute queue to HIQ.MQD.queue_doorbell_id fields.
2596: 	 * To make sure the queue unmap was successful, driver need to
2597: 	 * check those fields
2598: 	 */
2599: 	mqd_mgr = dqm->mqd_mgrs[KFD_MQD_TYPE_HIQ];
2600: 	if (mqd_mgr->check_preemption_failed(mqd_mgr, dqm->packet_mgr.priv_queue->queue->mqd) &&
2601: 	    reset_queues_on_hws_hang(dqm, false))
2602: 		goto reset_fail;
2603:
2604: 	/* Check for SDMA hang and attempt SDMA reset */
2605: 	if (sdma_has_hang(dqm) && reset_queues_on_hws_hang(dqm, true))
2606: 		goto reset_fail;
```

第一段英文注释说明：MEC 固件遇到未及时响应的计算 Queue 时，可能放弃卸载请求而不向驱动返回超时，转而在 HIQ MQD 的 `queue_doorbell_id` 字段记录该 Queue；驱动必须检查这些字段。末条注释表示另外检查 SDMA Hang 并尝试恢复，本例 Q0 沿计算 Queue 的第 2599～2602 行。恢复失败转到 `reset_fail`，成功则继续收尾。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_device_queue_manager.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2615:1) 第 [2615～2626](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2615:1) 行释放旧运行列表 IB，清除活动标志，并区分公共返回与恢复失败返回。

```c
2615: 	pm_release_ib(&dqm->packet_mgr);
2616: 	dqm->active_runlist = false;
2617: out:
2618: 	up_read(&dqm->dev->adev->reset_domain->sem);
2619: 	return retval;
2620:
2621: reset_fail:
2622: 	dqm->is_hws_hang = true;
2623: 	kfd_hws_hang(dqm);
2624: 	up_read(&dqm->dev->adev->reset_domain->sem);
2625: 	return -ETIME;
2626: }
```

这是同一个卸载函数的尾部；中间默认等待条件恢复分支不影响本例。正常处理走到第 2615～2616 行，解除旧运行列表资源；`out` 统一归还 Reset 域的读侧保护。恢复失败则设置 HWS Hang、请求 Hang 处理并返回 `-ETIME`。只有沿发送、回写、抢占检查与必要恢复走完，才能解释此次设备撤销的结果。

> **[SOURCE] 控制包与异常联动** Linux `248951ddc14d`，[`kfd_packet_manager_v9.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager_v9.c:390:1) 第 [390～437](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager_v9.c:390:1)、[441～465](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager_v9.c:441:1) 行编码卸载与查询，后者带控制回写地址和值；[`kfd_packet_manager.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager.c:401:1) 第 [401～424](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager.c:401:1)、[492～513](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager.c:492:1) 行通过特权 Queue 发送。销毁超时的 Wave 标志见 [`kfd_device_queue_manager.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2744:1) 第 [2744～2752](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2744:1) 行，进程终止时的处理见第 [3014～3038](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:3014:1) 行。

本例 HIQ 的 MQD 管理器将 `check_preemption_failed` 绑定到 `check_preemption_failed_v9_4_3()`。这个实现逐个检查所属 XCC 的 HIQ MQD 中记录的 Doorbell 失败标记，并清除相应字段；读间接调用时应沿这项绑定定位本例实现。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_mqd_manager_v9.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c:1054:1) 第 [1054～1061](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c:1054:1) 行为 GFX9.4.3 HIQ 绑定回调，第 [697～713](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c:697:1) 行实现逐 XCC 检查。

</details>

**[INFERENCE] 读码练习。** 假设 QUERY_STATUS 已回写，但 `check_preemption_failed()` 发现 Q0 未响应。沿恢复成功与失败两条路径，分别列出 `active_runlist`、返回值、Hang 状态和 PQM 后续清理；再说明 CWSR 和 Ring 为什么要保留到设备撤销或可靠停止条件建立以后。每个状态值都要放回这条路径解释。

### 5.3 内存解除映射、Runtime 关闭与对象收尾

Q0 已按上一节正常停止，A 的 GPU 使用和本轮 Host 校验也已结束。现在应用把 A 的地址交给释放接口，ROCr 经 HSAKMT 解除 GPU 映射，再归还分配。本例继续采用 MI300X 的普通 KFD 内存路径，下面按两次驱动请求均成功的情况追踪：

```text
确认 A 没有在途设备或 Host 使用者
    → HSAKMT 按 A 的基地址找到分配记录，取出上篇 §2.3 保存的 KFD 句柄
    → KFD 从句柄取得 GPU 标识，找到 PDD
    → 用句柄中的分配编号，从 PDD.alloc_idr 找到内存对象
    → UNMAP_MEMORY_FROM_GPU：解除 GPUVM 中的访问关系
    → 本例 GFX9.4.3：等待页表更新完成 → 刷新目标进程的 TLB
    → 撤销相应设备 DMA 映射，UNMAP 请求成功返回
    → FREE_MEMORY_OF_GPU：按同一句柄再次找到内存对象
    → AMDGPU 后端归还 BO 等资源引用
    → 后端成功后删除 KFD 分配编号；失败则保留编号供进程退出清理
```

这里沿用[上篇 §2.3](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#23-申请任务内存并准备完成对象>)建立的两层查找：应用给 HSAKMT 的是 A 的地址，HSAKMT 给 KFD 的是分配记录中的句柄。句柄中的 GPU 标识用于定位 PDD，分配编号用于从 `alloc_idr` 找回对象。解除映射时先保留分配编号，后面的释放请求才能继续找到同一对象。

本例的 GFX9.4.3 满足 `kfd_flush_tlb_after_unmap()` 中的 `KFD_GC_VERSION(dev) >= IP_VERSION(9, 4, 2)`，因此 `flush_tlb` 为真。KFD 先等待解除映射所需的页表更新完成，再刷新目标进程的 TLB，最后调用 DMA 解除映射。这个顺序让 GPU 的旧翻译先失效，再撤销旧设备地址的访问关系；若页表更新等待失败，当前 UNMAP 请求直接走错误出口，不继续执行后面的刷新和 DMA 解除。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_priv.h`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_priv.h:1569:1) 第 [1569～1574](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_priv.h:1569:1) 行给出刷新条件，本例在第 1571 行满足条件；[`kfd_chardev.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_chardev.c:1446:1) 第 [1446～1467](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_chardev.c:1446:1) 行依次等待页表更新、刷新 TLB、解除 DMA 映射，并保留等待失败的错误出口。

释放请求随后把内存对象交给 AMDGPU 后端。后端归还 BO 等资源引用，KFD 只在后端成功返回后删除分配编号；失败时保留编号，供进程退出时再次清理。BO 的存储何时最终回收还取决于剩余引用，内部实现留到 07 展开。

追踪失败时，还要分开看两个底层请求和它们的上层包装。固定 ROCr 的 `KfdDriver::FreeMemory()` 先调用 `MakeKfdMemoryUnresident()`，再调用 `FreeKfdMemory()`；前一个函数返回 `void`，没有把 UNMAP 的状态交给 `FreeMemory()` 判断，后一个函数才把释放状态转换成最终返回值。因此，`FreeMemory()` 的成功结果直接反映 FREE 路径，不能据此单独证明前一次 UNMAP 成功。调试解除映射失败时，要检查 UNMAP 自己的返回与执行位置；应用一旦交回 A，就应结束对旧指针的使用。

<details>
<summary>深入源码：地址查找、两次请求与资源归还</summary>

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_chardev.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_chardev.c:1392:1) 第 [1392～1482](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_chardev.c:1392:1) 行处理取消 GPU 映射、按条件等待/刷新和 DMA 解除，第 [1230～1279](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_chardev.c:1230:1) 行处理分配句柄查找、后端释放及失败保留；[`amdgpu_amdkfd_gpuvm.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gpuvm.c:1992:1) 第 [1992～2005](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gpuvm.c:1992:1) 行归还后端资源引用。ROCr `ba56a24c6132`，[`amd_kfd_driver.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/driver/kfd/amd_kfd_driver.cpp:350:1) 第 [350～352](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/driver/kfd/amd_kfd_driver.cpp:350:1)、[509～539](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/driver/kfd/amd_kfd_driver.cpp:509:1) 行先解除映射再释放。地址到用户态记录的查找见 ROCr `ba56a24c6132`，[`fmm.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/fmm.c:2138:1) 第 [2138～2174](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/fmm.c:2138:1)、[2181～2213](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/fmm.c:2181:1) 行；内核编号到对象的查找见 Linux 同基线 [`kfd_process.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1863:1) 第 [1863～1869](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1863:1) 行。以上顺序针对普通 KFD 内存接口；SVM 范围撤销继续按 05 的 notifier 与范围管理路径判断。

`amd_kfd_driver.cpp` 第 350～352 行给出两次调用及最终返回；第 538～539 行发出 UNMAP 调用，却没有向外返回状态；第 509～519 行检查 FREE 的状态。KFD 的 FREE 分支在 `kfd_chardev.c` 第 1264～1272 行先调用后端，再按 `ret` 决定是否删除分配编号。

> **[SOURCE]** ROCr `ba56a24c6132`，[`fmm.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/fmm.c:3642:1) 第 [3642～3671](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/fmm.c:3642:1) 行按地址查找对象并进入普通解除映射路径；[`fmm.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/fmm.c:3503:1) 第 [3503～3569](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/fmm.c:3503:1) 行从对象取出句柄及已映射设备，发出 UNMAP 请求，成功后更新用户态映射记录。

</details>

未再使用的分配、Signal 与代码对象归还后，应用再归还 Runtime 初始化引用。最后一份初始化引用归还时，ROCr 卸载装载器并释放 Agent 资源；Agent 在这时销毁自己持有的 `QueueUtility` 等内部 Queue。应用销毁 Q0 后，这些内部 Queue 仍由 Runtime 管理，到相应资源清理时才结束使用。随后 ROCr 结束异步服务、清理事件池，再进入后端卸载。设备公共驱动继续供其他进程使用。

> **[SOURCE]** ROCr `ba56a24c6132`，[`runtime.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/runtime.cpp:2095:1) 第 [2095～2115](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/runtime.cpp:2095:1) 行在卸载时调用各 Agent 的资源清理；[`amd_gpu_agent.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/amd_gpu_agent.cpp:910:1) 第 [910～938](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/amd_gpu_agent.cpp:910:1) 行清理搬运与 scratch 支持，并逐项释放内部 Queue。

Runtime 关闭设备 fd 后，还要等内核中各份引用归还。`close(fd)` 先归还该描述符持有的文件引用；同一 `/dev/kfd` 打开文件进入最终 `kfd_release()` 时，才归还文件持有的 `kfd_process` 引用。PDD 仍持有成功关联的 render 文件，使对应的 DRM 文件记录、AMDGPU 私有记录和 GPUVM 继续存在。

本例随后让 P 正常退出。Linux 在 mm 的最后一份使用引用归还后，进入地址空间最终拆除，并通知 KFD。正常退出也经过这条 MMU notifier 路径；前面已经主动销毁的 Queue 和分配只会减少退出时还需处理的对象。

```text
Runtime 关闭设备 fd，相关打开文件归还自己的引用
    → P 退出；退出线程归还 mm 使用引用
    → 最后一份 mm_users 归还：mmput → __mmput → exit_mmap
    → mmu_notifier_release 通知 KFD：地址空间即将拆除
    → KFD 移除 P 的查找登记，等待相关后台工作，处理剩余 Queue
    → 标记 P.mm 无效，归还 notifier 持有关系；Linux 继续拆除地址空间

文件、notifier 及已取得 P 的后台使用者分别归还 kfd_process 引用
    → 最后一份引用归还，安排 release_work
    → 最终工作等待相关复位完成，回收剩余内存、SVM 范围、PDD 和事件
    → 销毁 PDD 时归还 render 文件引用，接到 §5.3.1 的文件最终清理
```

这里要等的是不同对象各自的最后引用：`mm_users` 决定地址空间何时开始最终拆除，`kfd_process` 的引用决定进程软件记录何时安排最终释放。若 P 结束 GPU 使用后继续做 CPU 工作，mm 仍在使用，退出通知就尚未到来。若通知已经完成，但某个后台使用者仍持有 `kfd_process`，这个软件记录会保留到该使用者归还引用。

[§5.4.1](#541-沿-mmu-notifier-停止旧访问再由最后引用安排释放)展开这条通用退出链的 notifier、引用和后台工作；§5.4 额外改变的是“用户态来不及主动完成清理”的条件。最终释放工作若遇到设备正在复位，会先等待相关复位工作结束，避免旧 Queue 仍可能运行时回收资源。

> **[SOURCE]** ROCr `ba56a24c6132`，[`runtime.cpp`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/runtime.cpp:138:1) 第 [138～155](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/runtime.cpp:138:1)、[2095～2142](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/runtime.cpp:2095:1) 行处理最后初始化引用与卸载。Linux `248951ddc14d`，[`kfd_chardev.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_chardev.c:183:1) 第 [183～195](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_chardev.c:183:1)、[1006～1044](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_chardev.c:1006:1) 行分别归还 KFD 文件引用和保留成功关联的 render 文件引用；[`kfd_process.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1236:1) 第 [1236～1305](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1236:1) 行在最后引用后安排最终释放，先处理复位等待，再回收剩余对象。

> **[SOURCE]** Linux `248951ddc14d`，[`exit.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/kernel/exit.c:581:1) 第 [581～618](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/kernel/exit.c:581:1) 行在退出线程中清空 `current->mm` 并归还 mm 使用引用；[`fork.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/kernel/fork.c:1179:1) 第 [1179～1211](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/kernel/fork.c:1179:1) 行在 `mm_users` 降到零后进入 `exit_mmap()`；[`mmap.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/mm/mmap.c:1273:1) 第 [1273～1282](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/mm/mmap.c:1273:1) 行发出地址空间释放通知。[`kfd_process.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1326:1) 第 [1326～1374](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1326:1) 行处理剩余 Queue、标记 mm 无效并归还 notifier；第 [1376～1395](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1376:1) 行将该处理接到 `.release` 回调，详细带读见 §5.4.1。

#### 5.3.1 render 文件最终清理中的 AMDGPU 私有状态

上面的最终工作开始销毁 PDD。Runtime 已关闭原来的 render fd，PDD 此时执行 `fput(pdd->drm_file)`，归还自己持有的那份文件引用。本例该文件已无其他持有者，于是进入最终 release，DRM 再调用 AMDGPU 的 `postclose` 回调。

```text
Queue 与相关设备访问已经停止，kfd_process 的最后引用已安排最终回收
    → 销毁 PDD，fput 归还 PDD 的 render 文件引用
    → 本例该文件已无其他引用，执行最终 release
    → amdgpu_drm_release → drm_release → drm_file_free
    → amdgpu_driver_postclose_kms：从 drm_file.driver_priv 取得 fpriv
    → 清理 fpriv 中的 GPUVM 与文件私有状态，再释放 fpriv
```

`fpriv` 是这次 render 打开创建的 AMDGPU 私有记录，里面的 `vm` 保存对应 GPUVM。清理回调先临时保留根页表 BO，并记下 VM 中的 PASID，再拆除 GPUVM。若保存的 PASID 非零，回调还要按根 BO 中记录的 Fence 决定何时归还编号：已无待完成的 Fence 时直接归还；还有 Fence 时通常登记完成回调，等完成后归还。内存不足时改为等待后归还。这样，文件私有记录可以先释放，编号则按相应完成条件重新进入分配池。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_process.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1274:1) 第 [1274](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1274:1)、[1119～1139](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1119:1) 行在最终工作中销毁 PDD 并归还文件引用；[`amdgpu_drv.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_drv.c:2959:1) 第 [2959～2976](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_drv.c:2959:1) 行通过文件 release 包装进入 DRM。通用部分的 `postclose` 调用见 [§0.4](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#04-文件最终清理再次调用-amdgpu-回调>)，这里继续跟进 AMDGPU 私有记录和 GPUVM 的拆除。

<details>
<summary>深入源码：postclose 取得私有记录、拆除 GPUVM 与归还 PASID</summary>

进入 AMDGPU 后，先确认回调接收到的对象和私有记录来源：

> **[SOURCE]** Linux `248951ddc14d`，[`amdgpu_kms.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_kms.c:1546:1) 第 [1546～1557](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_kms.c:1546:1) 行。postclose 接收当前 DRM 设备和文件，再取出 AMDGPU 私有记录。

```c
1546: void amdgpu_driver_postclose_kms(struct drm_device *dev,
1547: 				 struct drm_file *file_priv)
1548: {
1549: 	struct amdgpu_device *adev = drm_to_adev(dev);
1550: 	struct amdgpu_fpriv *fpriv = file_priv->driver_priv;
1551: 	struct amdgpu_bo_list *list;
1552: 	struct amdgpu_bo *pd;
1553: 	u32 pasid;
1554: 	int handle;
1555:
1556: 	if (!fpriv)
1557: 		return;
```

第 1550 行取得本次私有记录，第 1556～1557 行处理记录不存在的情况。第 1559～1574 行继续设备条件和其他私有映射清理；同一回调中的 VM 清理及最终释放如下。

> **[SOURCE]** Linux `248951ddc14d`，[`amdgpu_kms.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_kms.c:1576:1) 第 [1576～1600](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_kms.c:1576:1) 行。AMDGPU 清理文件中的 context、GPUVM 和其他私有状态，归还记录并清空指针。

```c
1576: 	pasid = fpriv->vm.pasid;
1577: 	pd = amdgpu_bo_ref(fpriv->vm.root.bo);
1578: 	if (!WARN_ON(amdgpu_bo_reserve(pd, true))) {
1579: 		amdgpu_vm_bo_del(adev, fpriv->prt_va);
1580: 		amdgpu_bo_unreserve(pd);
1581: 	}
1582:
1583: 	amdgpu_ctx_mgr_fini(&fpriv->ctx_mgr);
1584: 	amdgpu_vm_fini(adev, &fpriv->vm);
1585:
1586: 	if (pasid)
1587: 		amdgpu_pasid_free_delayed(pd->tbo.base.resv, pasid);
1588: 	amdgpu_bo_unref(&pd);
1589:
1590: 	idr_for_each_entry(&fpriv->bo_list_handles, list, handle)
1591: 		amdgpu_bo_list_put(list);
1592:
1593: 	idr_destroy(&fpriv->bo_list_handles);
1594: 	mutex_destroy(&fpriv->bo_list_lock);
1595:
1596: 	kfree(fpriv);
1597: 	file_priv->driver_priv = NULL;
1598:
1599: 	pm_runtime_put_autosuspend(dev->dev);
1600: }
```

第 1576～1577 行先保存 PASID，并另外持有 VM 根页表 BO 的引用，供 VM 拆除后的清理使用。第 1584 行拆除 VM；第 1586～1588 行把 PASID 交给延后回收函数，再归还临时根 BO 引用。

这里的 `amdgpu_pasid_free_delayed()` 从根 BO 的 reservation 中取得用于记账的 Fence。无 Fence 时立即释放 PASID；有 Fence 时登记回调，如果 Fence 已经完成则直接执行回调。分配回调记录或汇总 Fence 时内存不足，函数走同步等待分支。因此，判断 PASID 何时可以再次分配，应追踪这次 Fence 与回调，而不是只看 `postclose` 是否返回。

> **[SOURCE]** Linux `248951ddc14d`，[`amdgpu_ids.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_ids.c:98:1) 第 [98～155](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_ids.c:98:1) 行保留完成回调、直接归还、延后登记和内存不足时等待的分支。

第 1590～1597 行继续清理剩余文件状态，释放 `fpriv`，最后清空 `driver_priv`。进入这段私有清理之前，相关设备使用和文件引用已经按前述条件收尾。

</details>

### 5.4 任务未完成时的进程退出与后台使用

§5.3 已经走过正常退出的 MMU notifier 与最终释放路径。现在只改变退出时的工作状态：P 在 Packet 37 完成前退出，Queue 仍有工作，用户态来不及主动清理。Linux 仍通过同一条通知路径要求 KFD 处理剩余设备访问。下面取设备侧终止正常成功、没有并发复位的条件。

```text
P 的地址空间进入退出处理
    → KFD 从进程查找表移除 P，阻止后来的正常查找取得它
    → 取消并等待相关 eviction/restore 后台工作
    → 请求终止 P 的设备 Queue；本图取设备停止正常成功
    → 清理 Queue 管理对象及其持有的映射、缓冲引用
    → 标记 mm 已不再有效
    → 地址空间拆除继续；已有软件引用逐一归还
    → 最后引用触发剩余对象最终释放
```

这次退出需要停止 Packet 37 对 A/B/C 等存储的访问，才能让 Linux 回收或复用页面；退出清理不保证 C 已经算完。

**[BOUNDARY]** 固定实现逐设备调用终止函数，再清理 PQM；外层包装没有汇总出“所有设备均已停止”的成功结果。CPSCH 终止内部有错误与 Wave 复位处理分支。因此图中的完成状态依赖设备停止成功；遇到停止失败或复位时，要沿 [03 下篇 §8.4](<./03_AMD GPU 队列与 AQL Dispatch（下）.md#84-异常清理与错误隔离的边界>)检查旧访问怎样结束，不能只凭软件清理函数返回就判断设备已停止。§5.3 的最终释放等待复位，也属于需要一起核对的条件。

> **[SOURCE]** Linux `248951ddc14d`：[`kfd_process_queue_manager.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process_queue_manager.c:83:1) 第 [83～102](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process_queue_manager.c:83:1)、[168～174](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process_queue_manager.c:168:1) 行逐设备发起终止，未将终止返回值汇总给调用者；[`kfd_device_queue_manager.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2983:1) 第 [2983～3046](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2983:1) 行更新 CPSCH 调度、按条件处理 Wave 复位并清理 MQD。正常停止与异常边界沿用 [03 下篇 §8.5.2](<./03_AMD GPU 队列与 AQL Dispatch（下）.md#852-先结束-gpu-访问再拆除进程地址空间>)。

#### 5.4.1 沿 MMU notifier 停止旧访问，再由最后引用安排释放

下面展开正常退出与任务未完成退出共用的内核路径。Linux 最终拆除 P 的 mm 时，KFD 处理尚未销毁的 Queue；此前已经取得 P 引用的中断或恢复工作，则在结束使用后归还引用。正常清理已经完成时，剩余对象较少；本节的 Packet 37 仍在使用设备，需要在通知回调返回前结束相关访问。

```text
Linux 最终拆除 P 的地址空间（设备终止按正常成功路径）
    → MMU notifier.release，取得关联的 kfd_process P
    → 从 KFD 进程查找表移除 P，等待已有 SRCU 查找读侧结束
    → cancel_delayed_work_sync：取消并等待 eviction / restore 工作
    → 按 PDD 请求 DQM 终止 P 的设备 Queue
    → PQM 归还 Queue 的映射使用记录与缓冲引用，拆除软件 Queue
    → P.mm=NULL，本例主上下文归还 notifier 持有关系
    → release 回调返回，Linux 继续地址空间拆除

此前取得引用的事件处理 / 文件 / notifier 等使用者
    → 分别完成自己的使用，再 kfd_unref_process(P)
    → P.ref 最后归还，kfd_process_ref_release 安排 release_work
    → 工作线程等待相关 Reset 工作结束，再回收剩余 BO / SVM / PDD / Event
    → 归还主线程 task 引用，最后释放 kfd_process 存储
```

KFD 在进程表锁下删除 P 的登记，再等待进程表的 SRCU 查找读侧结束。读者在离开查找保护前取得 `kref`，所以已经持有引用的事件线程仍可完成软件通知并归还 P；后来的查找则无法再取得 P。若已有读者还要查询页面或建立 GPU 映射，须另取有效 mm，§5.4.2 推演这个条件。

`cancel_delayed_work_sync()` 同时处理尚未运行和正在运行的换出、恢复工作。随后 DQM 处理设备 Queue，PQM 才归还 Queue 持有的映射使用记录与缓冲引用。设备停止沿用本节的成功前提；最终 `release_work` 还会等待相关 Reset 工作，再回收剩余资源。

P 的核心成员在这条路径中的关系如下，这是阅读示意：

```text
P（kfd_process）
    mm：用于关联 CPU 地址空间的标识，本身不持有 mm 使用引用；退出后置为 NULL
    pdds[]：P 在每个设备上的记录，内嵌 QPD 队列集合
    pqm：P 的 Queue 节点和编号集合
    eviction_work / restore_work：队列换出和恢复的延迟工作
    ref：P 的 kref 引用计数
    release_work：最后引用归还后执行最终资源回收
    lead_thread：P 持有引用的主线程 task 对象，可供 get_task_mm() 尝试取得 mm
    mmu_notifier：内嵌的地址空间通知对象，回调用它找回 P
```

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_priv.h`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_priv.h:907:1) 第 [907～945](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_priv.h:907:1)、[969～971](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_priv.h:969:1) 行定义上述成员。按 PASID 查找并在 SRCU 读侧内取得 P 引用，见 [`kfd_process.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1903:1) 第 [1903～1926](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1903:1) 行。

<details>
<summary>深入源码：notifier 撤销查找、结束后台工作并处理 Queue</summary>

`exit_mmap()` 先调用 `mmu_notifier_release()`，再继续拆除映射。KFD 回调运行期间，MMU notifier 自己的 SRCU 保护保证关联的 `kfd_process` 仍然存在。

> **[SOURCE] 退出入口** Linux `248951ddc14d`，[`mm/mmap.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/mm/mmap.c:1273:1) 第 [1273～1297](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/mm/mmap.c:1273:1) 行在继续拆除用户映射前发出释放通知；[`kfd_process.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1376:1) 第 [1376～1395](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1376:1) 行把 KFD 回调登记为 `.release`，回调完整主体如下。

```c
1376: static void kfd_process_notifier_release(struct mmu_notifier *mn,
1377: 					struct mm_struct *mm)
1378: {
1379: 	struct kfd_process *p;
1380:
1381: 	/*
1382: 	 * The kfd_process structure can not be free because the
1383: 	 * mmu_notifier srcu is read locked
1384: 	 */
1385: 	p = container_of(mn, struct kfd_process, mmu_notifier);
1386: 	if (WARN_ON(p->mm != mm))
1387: 		return;
1388:
1389: 	kfd_process_notifier_release_internal(p);
1390: }
```

英文注释表示 MMU notifier 的 SRCU 读侧正在保护 `kfd_process`，该结构在这里不能被释放。第 1385 行从内嵌 notifier 找回 P，第 1386～1387 行检查此次通知对应的 mm，再进入内部清理。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_process.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1326:1) 第 [1326～1340](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1326:1) 行先撤销进程查找、等待换出和恢复工作，再停止 Queue 并清理 PQM。

```c
1326: void kfd_process_notifier_release_internal(struct kfd_process *p)
1327: {
1328: 	int i;
1329:
1330: 	kfd_process_table_remove(p);
1331: 	cancel_delayed_work_sync(&p->eviction_work);
1332: 	cancel_delayed_work_sync(&p->restore_work);
1333:
1334: 	/*
1335: 	 * Dequeue and destroy user queues, it is not safe for GPU to access
1336: 	 * system memory after mmu release notifier callback returns because
1337: 	 * exit_mmap free process memory afterwards.
1338: 	 */
1339: 	kfd_process_dequeue_from_all_devices(p);
1340: 	pqm_uninit(&p->pqm);
```

英文注释说明：回调返回后 `exit_mmap` 会继续释放进程内存，GPU 再访问 system RAM 就不安全，因此必须先停止并清理用户 Queue。第 1330～1332 行在处理 Queue 前移除查找登记，并取消、等待换出与恢复工作。

第 1339 行沿各 PDD 调用 `process_termination`，批量处理设备 Queue；第 1340 行再遍历 PQM，归还映射使用计数和 buffer 引用。`pqm_uninit()` 的循环只接续软件对象清理，设备终止由前一行发起；它没有逐条调用 `pqm_destroy_queue()`。

> **[SOURCE] 退出期间的查找与设备终止** Linux `248951ddc14d`，[`kfd_process.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1307:1) 第 [1307～1324](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1307:1) 行在进程表锁下删除登记并等待 SRCU；第 [1350～1352](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1350:1) 行将 mm 置空，第 [1372～1374](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1372:1)、[1302～1305](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1302:1) 行归还 notifier 及其 P 引用。设备循环与 PQM 清理见 [`kfd_process_queue_manager.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process_queue_manager.c:168:1) 第 [168～174](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process_queue_manager.c:168:1)、[83～102](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process_queue_manager.c:83:1)、[218～243](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process_queue_manager.c:218:1) 行。

CPSCH 的进程终止在 DQM 锁下减少活动队列计数、移除 P 的调度登记，再更新运行列表；出错或已有 `reset_wavefronts` 标记时按条件尝试 Wave 复位，之后归还 MQD。它还要释放锁后执行可能涉及内存回收的动作，以免引入锁依赖环。外层逐设备包装没有汇总终止返回，`already_dequeued` 只是避免重复发起终止的记账。故障判断要读内部返回与复位分支，不能把该标志视为所有设备已正常停止的证明。

> **[SOURCE] CPSCH 进程终止** Linux `248951ddc14d`，[`kfd_device_queue_manager.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2958:1) 第 [2958～3046](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:2958:1) 行处理调度登记、卸载和重新生成运行列表、Wave 复位及 MQD 清理；第 [3025～3036](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:3025:1) 行特意在 DQM 锁外释放 MQD，第 [3040～3044](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c:3040:1) 行在锁外执行可能涉及回收的动作。

</details>

<details>
<summary>深入源码：最后引用安排释放工作，等待复位并归还资源</summary>

`kfd_unref_process()` 通过 `kref_put()` 归还引用；最后一份引用归还时，回调把最终资源回收交给工作线程。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_process.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1016:1) 第 [1016～1019](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1016:1) 行归还引用；最后引用进入第 [1286～1292](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1286:1) 行。

```c
1286: static void kfd_process_ref_release(struct kref *ref)
1287: {
1288: 	struct kfd_process *p = container_of(ref, struct kfd_process, ref);
1289:
1290: 	INIT_WORK(&p->release_work, kfd_process_wq_release);
1291: 	queue_work(kfd_process_wq, &p->release_work);
1292: }
```

这段回调初始化并提交 `release_work`。最终 `kfree(p)` 位于工作函数中，何时执行取决于工作调度及其等待条件。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_process.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1236:1) 第 [1236～1245](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1236:1) 行进入最终回收工作并等待相关 GPU Reset；等待实现见第 [1223～1229](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1223:1) 行。

```c
1236: static void kfd_process_wq_release(struct work_struct *work)
1237: {
1238: 	struct kfd_process *p = container_of(work, struct kfd_process,
1239: 					     release_work);
1240: 	struct dma_fence *ef;
1241:
1242: 	/*
1243: 	 * If GPU in reset, user queues may still running, wait for reset complete.
1244: 	 */
1245: 	kfd_process_wait_gpu_reset_complete(p);
```

英文注释说明：GPU 正在复位时用户 Queue 仍可能在运行，释放工作先等复位完成。等待函数逐 PDD `flush_workqueue()`，这个等待属于最终回收所需的设备使用边界。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_process.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1270:1) 第 [1270～1284](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1270:1) 行给出同一工作函数的主要资源回收尾部；其前面的第 [1247～1268](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1247:1) 行先完成 RCU 同步、eviction fence 和对外节点移除。

```c
1270: 	kfd_process_kunmap_signal_bo(p);
1271: 	kfd_process_free_outstanding_kfd_bos(p);
1272: 	svm_range_list_fini(p);
1273:
1274: 	kfd_process_destroy_pdds(p);
1275: 	dma_fence_put(ef);
1276:
1277: 	kfd_event_free_process(p);
1278:
1279: 	mutex_destroy(&p->mutex);
1280:
1281: 	put_task_struct(p->lead_thread);
1282:
1283: 	kfree(p);
1284: }
```

第 1270～1272 行处理通知 BO、未归还 KFD BO 与 SVM 范围；第 1274～1277 行回收 PDD、事件并归还相关 Fence；最后归还主线程 task 引用并释放 P 的存储。PDD 回收还包括 P 的共享 Doorbell 与保留的 render 文件，单条 Queue 销毁时只处理该 Queue 的那一部分。

> **[SOURCE] PDD 的共享资源** Linux `248951ddc14d`，[`kfd_process.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1119:1) 第 [1119～1168](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1119:1) 行销毁 PDD、归还 Doorbell 和关联文件；Event 与通知页回收见 [`kfd_events.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:303:1) 第 [303～319](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_events.c:303:1) 行。

</details>

**[INFERENCE] 读码练习。** 事件工作线程在删除进程表前已经取得 P 的 `kref`，退出通知随后完成。沿“移除登记 → 回调返回 → 事件线程归还引用 → 最后引用安排工作”说明 P 的存储为何仍可用于这次软件收尾；再加入一个正在运行的 Reset 工作，指出最终 BO 和 PDD 回收被推迟在哪个调用处。若事件线程还要读页面，必须转到下面的 mm 使用引用判断。

#### 5.4.2 缺页恢复持有 mm 与退出拆除的竞争

再把 §3.8 的故障恢复接到退出之前。**[DESIGN]** 沿用 05 的有限场景：P 只剩主线程 T0 使用该地址空间，A 已有合法 SVM 范围，设备侧停止成功；恢复工作已经按 PASID 42 取得 P 的软件对象引用。现在只观察恢复方与 T0 谁先操作 `task->mm`，不加入其他临时地址空间使用者。

**[INFERENCE]** 恢复方调用 `get_task_mm(p->lead_thread)`，在任务锁下读取 `task->mm`；非空时当场取得 `mm_users` 引用。T0 也在同一任务锁下清空 `task->mm`，因此有两种结果：

```text
恢复方持有 kfd_process 引用，调用 get_task_mm(p->lead_thread)
    ├─ 成功取得一份 mm_users 使用引用
    │    → 取得 mmap 读锁、SVM 集合锁和范围迁移锁，处理 A 的页面与映射
    │    → T0 清空 task->mm 并归还引用，恢复方仍持有 mm，最终拆除延后
    │    → 恢复方结束操作，依次释放范围迁移锁、SVM 集合锁与 mmap 读锁
    │    → mmput(mm) 归还自己的引用；若为最后一份，触发拆除和退出通知
    │    → kfd_unref_process(p)，归还 KFD 软件对象引用
    └─ 返回空：T0 已先清空 task->mm
         → 不再查询 A 或建立映射，直接归还 KFD 软件对象引用
```

恢复方持有 `mm_users` 引用时，T0 归还自己的引用后可以继续其他退出步骤，地址空间的最终拆除留到最后一次 `mmput()`。因此，恢复方也可能成为触发 notifier 的执行者；调用 `mmput()` 前已经释放上述锁，调用后才归还 P 的引用。mmap 锁和范围锁保护查询、映射与范围状态，`mm_users` 引用只推迟最终拆除。

恢复方持有 P 的软件对象引用后，仍须成功取得可用 mm，才能查询页面或建表。完整引用计数与锁的推演回查 [05 §7.3.1](<./05_HMM 与 SVM：GPU 缺页恢复与页面迁移.md#731-缺页恢复与退出的竞争点>)。

> **[SOURCE]** Linux `248951ddc14d`：[`kfd_svm.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:3070:1) 第 [3070～3117](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:3070:1)、[3135～3162](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:3135:1)、[3244～3265](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:3244:1) 行取得进程和 mm、加锁并依次归还；[`kernel/fork.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/kernel/fork.c:1378:1) 第 [1378～1391](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/kernel/fork.c:1378:1) 行在任务锁下取得 mm，第 [1179～1211](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/kernel/fork.c:1179:1) 行在最后一份 mm 使用引用归还后进入最终拆除；[`kernel/exit.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/kernel/exit.c:581:1) 第 [581～618](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/kernel/exit.c:581:1) 行清空退出线程的 mm 并归还使用引用；[`mm/mmap.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/mm/mmap.c:1273:1) 第 [1273～1297](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/mm/mmap.c:1273:1) 行在最终拆除映射前发出 notifier 释放通知。
>
> [`kfd_process.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1580:1) 第 [1580～1584](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1580:1)、[1647～1648](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1647:1)、[1281～1283](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1281:1) 行保存主线程、取得和归还任务对象引用，第 [1307～1352](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1307:1)、[1376～1395](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_process.c:1376:1) 行在退出通知中移除登记、等待后台工作、停用并拆除 Queue；[`kfd_svm.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:3333:1) 第 [3333～3363](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_svm.c:3333:1) 行处理范围后台工作与清理。

### 5.5 P 退出以后，设备继续服务 R

P 的 Queue、映射和引用已经完成收尾，R 仍持有自己的 Runtime、GPUVM、QR 和数据。沿本章的正常退出条件，设备继续使用[上篇 §1](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#1-驱动初始化建立可供应用使用的设备资源>)准备的公共资源，为 R 处理任务：

```text
P 的使用结束
    → 停用 P 的 Queue，撤销 P 的映射，归还 P 持有的引用
    → P 的最后使用者离开，相关对象完成回收

MI300X 的设备服务继续存在
    → 公共内存管理、IH/中断入口、Firmware、内部控制通路与 KFD 节点仍可用
    → R 沿自己的 GPUVM、QR 和数据继续执行任务
```

正常结束 P 不要求重新初始化整块 GPU；R 的私有资源仍由 R 的使用关系保留。

下一项工作按对象寿命决定准备范围：存活的应用提交下一轮时，复用自己的进程环境和 Queue；新进程到来时，复用设备服务，再建立自己的文件、GPUVM 和 Queue。设备移除、卸载、复位或电源状态变化则进入相应的设备生命周期处理，另行确认公共服务何时可用。

## 6. 源码追踪、故障推演与小范围验证

这一轮回到 Packet 37。打开相应源码，独立说明每个动作的调用者、对象、所选分支、前后状态和退出路径，再用一次观察或受控验证检查推演。文档的链接可用于核对答案；能找到文件还需要继续解释调用上下文和使用条件。

### 6.1 独立追踪同一项任务

这次练习要交付一份 P 从取得设备服务到退出的源码追踪记录。先用[上篇第 0 章](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#0-amdgpu-对-drm-框架的接入与调用>)确认框架入口：从 `amdgpu_kms_driver` 找到设备关联，从 render 打开找到文件操作和私有回调，再沿一次 ioctl 找到实际处理函数。画出 BO 内嵌 GEM/TTM 记录的关系，标出 TTM 调用已登记后端的位置。

随后沿同一组 P、Q0、Packet 37 和 S 追踪。每段记录都应交代调用者已经拿到什么、经过哪个分支、把什么状态交给下一步：

```text
设备准备可用服务 → P 取得文件、GPUVM 与设备关联 → 创建 Q0
    → 发布 Packet 37；按需跟进驻留和访存恢复
    → S 报告完成，Host 结束等待并读取结果
    → 停止 Queue 使用，归还映射与引用，最终回收 P 的资源
```

按下面六个入口核对这条路径，源码摘录保留证明当前结论所需的完整上下文：

1. 从 `amdgpu_pci_probe()` 追到 GFX9.4.3 实现表和 KFD 初始化。记录 IP 软件准备状态、硬件准备调用和 KFD 可用状态的发布位置；再假设一项 KFD 支持资源取得失败，沿真实回滚标签说明已经归还与继续保留的资源。
2. 从 P 的 `/dev/kfd` 打开追到以 mm 为键的进程查找和创建，再从 `ACQUIRE_VM` 追到 PDD 的 VM、PASID 和文件引用。指出两个线程同时打开时怎样避免重复主上下文，以及查找保护退出后靠什么保留对象。
3. 从 `CREATE_QUEUE` 追到 Q0 的 Queue ID、用户缓冲保护、PQM 节点、DQM 回调、MQD 和 Doorbell。指出每份编号属于哪个对象，活动状态由哪些条件计算，哪些错误点撤销已经取得的资源。
4. 在 Runtime 中追踪 Packet 37 的临时描述、预留 index、物理槽位、有效 Header 和 Doorbell。接着单独追一次 Queue 集合变更的 runlist IB、HIQ 提交；解释两条路径使用什么存储、在什么时机进入内核。
5. 从 Host 的 acquire 等待追到 Signal 的值检查和事件等待，再沿 IH/KFD worker 追到等待线程。用 S 的值、通知槽和 Event 编号说明记录怎样找到等待者，以及线程被唤醒后还要检查什么。
6. 从 Queue 销毁追到运行列表撤销与抢占确认，再从进程 notifier 追到工作队列中的最终释放。指出设备继续访问时须保留的缓冲、仍在使用进程对象的工作，以及最终释放的触发条件。若 render 文件已无其他引用，再从 PDD 的文件引用归还追到 postclose，分别记录 VM 拆除与 PASID 延后回收。

实现、行号和讲解分别在 [上篇 §0～§2](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#0-amdgpu-对-drm-框架的接入与调用>)和[本篇 §3～§5](#3-一项计算从-runtime-请求到-gpu-执行)。记录间接调用时，同时保存调用点与实现表选择位置；记录失败时，保存出错调用与实际清理出口。后续源码行号变化时，可以据此重新定位对象和控制流。

<details>
<summary>源码阅读方法与各阶段入口</summary>

**沿调用、对象和使用寿命阅读**

以创建 Q0 为例，调用者已经准备 Ring、索引和支持缓冲；内核把这些存储关联到 P 的设备记录，再建立 Queue/MQD/Doorbell 并提交驻留管理请求。沿这一顺序标出分配、字段赋值和失败回滚，记录每次调用已经改变的对象。

每次进入一个实现函数时，依次检查：

1. 沿本节图找入口、输入对象和交给下一步的结果。先区分发生一次的设备准备、进程或 Queue 变更、逐次 Packet 发布。
2. 打开引用的真实文件，读函数入口、关键调用和返回出口。遇到 `ops->...`、`funcs->...` 等间接调用，回查实现表在哪里被赋值，以及 GFX9.4.3 和当前调度条件选择哪项实现。
3. 追踪关键指针的来源和保存位置。分别记清 Host 管理对象、设备可访问的缓冲、GPU 地址及硬件活动状态；地址相同或字段名称相似时仍按对象核对。
4. 从成功路径反向检查失败标签，再检查互斥锁、读侧保护、引用和异步工作。说明本函数退出时已发布哪些状态、归还哪些资源、还有谁继续使用对象。
5. 代入 P、Q0、Packet 37 和 S，推演一个条件变化。用真实分支解释变化的结果，再记录还有哪项证据需要运行时取得。

原始摘录左侧数字是固定源码的真实行号。摘录之间省略的内容会明确说明；原文件保留完整上下文。`[DESIGN]` 标记的简化结构或状态推演用于教学，实际声明与控制流以链接文件为准。

**各阶段的源码入口**

- [§0.1～§0.5](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#01-drm-核心调用驱动实现通用组件支持资源管理>)：先读 DRM 实现表、设备与节点、render 打开、ioctl 分发和 GEM/TTM 的复用，再追踪文件最终清理及 KFD 对已建立 GPUVM 的使用。据这些字段定位当前设备、处理函数和文件私有状态。
- [上篇 §1.1](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#11-模块注册与-pci-probe>)、[§1.3](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#13-软件初始化与内存基础>)、[§1.5](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#15-psp-启动与固件装载>)～[§1.6](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#16-第二阶段硬件初始化配置并测试内部队列>)、[§1.7](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#17-公共调度与-kfd-节点初始化>)和[§1.8](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#18-完成设备初始化并注册用户入口>)：沿 probe 的初始化顺序，跟读内存准备、固件装载、内部队列配置与测试，再检查 KFD 管理池、节点启动和回滚，最后追到设备注册。记录一次初始化失败阻断的使用条件。
- [§2.1～§2.2](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#21-runtime-进入-kfd建立-p-的进程记录>)和 [§2.4](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#24-q0-的创建把用户存储交给驱动和设备使用>)：从打开文件、关联 VM 追到进程对象与 Queue 创建。核对同进程线程的共享关系、创建时的锁与引用，以及错误发生时已存在的对象。
- [§3.5](#35-从预留槽位到有效发布再到设备推进)和 [§3.1](#31-kfd-和设备固件使用户-queue-获得驻留条件)：跟读用户 Packet 发布和内核运行列表提交，分别定位槽位预留、有效 Header、Doorbell、运行列表和驻留配置的交接。
- [§3.8](#38-可恢复缺页把设备执行接回-host-处理)：从故障记录的 PASID 追到进程、mm、SVM 范围及恢复分支。分别核对进程对象引用、有效 mm 和页面查询结果的保护。
- [§4.2](#42-signal通知槽中断与等待线程的衔接)、[§5.2](#52-销毁-queue-时先撤销设备使用)、[§5.3.1](#531-render-文件最终清理中的-amdgpu-私有状态)和 [§5.4](#54-任务未完成时的进程退出与后台使用)：跟读等待竞态、事件转交、Queue 撤销和异步释放，再沿 PDD 的文件引用归还接到 render postclose。记录中断通知、任务完成和对象最终释放各自的触发条件。

**[BOUNDARY]** 本篇沿固定快照学习 Host 侧公开实现和规范语义。三个源码仓库的固定 commit 用于证据定位；实际部署时还要核对组合版本、内核配置和设备配置。CP/MEC 固件内部调度与逐周期行为只保留接口和规范能证明的范围。普通 DRM job、scheduler、共享 BO 和通用 TTM 迁移继续按 07 展开。

</details>

### 6.2 用故障现象检验调用链

**[DESIGN]** 以下是静态推演练习，不向真实设备注入故障。每题先定位最后一个已有证据的阶段，再列出后面可能经过的分支，用对应小节核对：

```text
观察到现象 → 确认已有证据的阶段 → 列出候选分支
    → 检查分支条件、返回值和对象状态 → 写出还缺哪些运行记录
```

真实机器上的首个失败点，要由该次运行证据确定。练习时保留尚不能排除的分支：

- **设备文件存在，Runtime 没发现可用计算 Agent。** 回到 [上篇 §1.7.6 的节点初始化导读](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#176-dqm-启动计算节点发布与失败回滚>)和[上篇 §2.2](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#22-读取拓扑关联-gpuvm-并建立-agent>)，依次检查 DRM 注册、KFD 初始化、拓扑发布和 Runtime 读取。沿 `void`、`bool` 与错误码的实际传递，指出哪次失败阻断了下一步。
- **创建请求返回错误，担心留下 Q0。** 回到 [上篇 §2.4](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#24-q0-的创建把用户存储交给驱动和设备使用>)，分别代入参数验证失败、PQM/DQM 内部失败，以及 handler 成功后的用户结果拷贝失败。沿各自出口记录 Queue 集合、编号位图、MQD 和缓冲引用的状态，再检查显式销毁或进程退出怎样处理剩余对象。
- **Q0 写索引已超过 37，S 仍为 1。** 回到 §3.5、§3.1 和 §4.5，检查预留之后的 Header 发布、通知、驻留、依赖、访存和完成。若事后读取 Ring 槽位，还要核对该槽位是否已经回收、复用；把当前内容关联到单调 Packet ID，需要相应发布时刻的记录。
- **中断已经到达，Host 仍在等待。** 回到 §4.2，追踪记录所属节点、通知槽、Event 和等待条件。驱动处理通知后，线程还需恢复执行，ROCr 随后重新读取 S。沿正常完成和超时两个返回分支，说明应用应怎样检查观察值，以及何时可以读取本轮结果。
- **故障恢复函数返回 0，S 没有更新。** 回到 §3.8.1，分别代入实际建表成功、取不到 mm、重复记录和 `-EAGAIN` 转换。逐个说明该分支是否恢复了 GPU 映射，以及 Packet 37 还需完成哪些动作才会更新 S。
- **销毁 Queue 遇到抢占超时。** 回到 §5.2，沿 UNMAP、QUERY_STATUS、抢占失败字段和 Reset 协调检查实际分支，并核对 PQM 的软件清理。分别记录设备访问结束的证据、软件对象的清理状态与应用结果的有效性，再沿对应错误路径分析收尾。

### 6.3 一次可审阅的调试修改

选择一处已经读懂的交接，把问题、诊断位置和预期证据写成一项小修改。以 Queue 创建为例，可以检查“请求失败后，软件集合是否保留 Q0”：记录进程、请求的 GPU ID、Queue 类型和失败出口；创建成功后，再记录已分配的 Queue ID。需要观察活动状态时，继续定位保存该状态的 Queue 对象，并确认读取时的保护条件。

```text
提出一个问题 → 沿源码确定成功分支与失败出口 → 选择诊断位置和可读字段
    → 检查锁、引用与发布顺序 → 添加最小诊断 → 分别记录静态、编译和运行结果
```

Queue ID 属于 Queue 的生命周期，Packet ID 属于逐次任务。诊断中保留进程和设备身份，并将两类编号分开，才能把记录关联到同一次创建或提交。

也可以在用户态发布和等待周围，记录预留、有效发布、Doorbell 与等待返回的时间和对象身份。记录本身会扰动时序，观察结果只能支持当次执行。按 [§4.5 的阶段证据](#45-用阶段证据判断任务停在何处)说明已有记录能证明什么，还缺少哪个阶段的证据。

修改前核对当前上下文能否睡眠、持有哪些锁、对象是否仍存活，再选择记录方法。诊断修改保持原有控制流、引用配对和发布顺序；若要改变 Queue/MQD/页表编码或抢占超时策略，则另行分析协议与错误恢复条件。

交付一项练习时，写清：

1. 问题与预期现象，以及沿代码找到的条件和退出路径。
2. 精确的固定版本、修改位置、改动内容及其对锁、引用、错误返回和同步顺序的影响。
3. 验证环境与实际执行的检查。静态源码核对、编译和 MI300X 设备运行分别记录；未做的检查注明未执行。
4. 当次结果支持哪个结论，哪些分支还没有覆盖，诊断修改怎样恢复。

**[DESIGN] 静态分析记录示例：创建失败时记录什么编号。** 以下仅演示审阅记录，未添加诊断代码、编译或在设备上运行。

问题是：能否在 `kfd_ioctl_create_queue()` 的共同错误出口无条件打印局部 `queue_id`？沿源码检查，`queue_id` 在声明时没有初始化，部分失败出口位于 `pqm_create_queue()` 之前。成功分支才把返回的编号写入 `args->queue_id`。

因此，拟加诊断在成功分支记录 Queue ID；失败出口记录进程、请求的 GPU ID 和 `err`，不把未经成功确认的局部值当作 Queue 编号。已经持有 `p->mutex` 的路径，仍在原有成功分支或错误出口解锁；诊断不调整锁、缓冲归还和返回顺序。要判断 Q0 是否残留，还需进入 PQM/DQM 的相应失败分支，追踪集合与资源清理；这一份编号记录本身不足以给出结论。

> **[SOURCE]** Linux `248951ddc14d`，[`kfd_chardev.c`](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_chardev.c:338:1) 第 [338～365](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_chardev.c:338:1) 行定义局部变量、执行参数检查并取得进程锁；第 [395～422](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_chardev.c:395:1) 行按缓冲取得、Queue 创建、成功保存编号的顺序处理；第 [438～447](vscode://file/C:/Users/28431/Desktop/GPU%E5%AD%A6%E4%B9%A0%E8%B5%84%E6%96%99/gpu_study/2.%E6%BA%90%E7%A0%81/linux/drivers/gpu/drm/amd/amdkfd/kfd_chardev.c:438:1) 行保留错误清理、解锁和返回路径。

**[BOUNDARY]** 本文的源码核对与静态推演不代替 MI300X 实测。实际运行前按现有环境核对设备分区、IOMMU、XNACK、队列调度配置和版本组合；选择实验的单一条件后，再沿对应代码检查。

### 6.4 接入第七章的公共驱动能力

沿 §6.1 的追踪记录检查 06：每次交接能否找到已有对象、处理分支和后续使用者，能否解释任务完成后还要等谁归还资源。缺少的环节回到对应小节补齐；00～05 的回查入口列在本节后部。

上篇[第 0 章](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#0-amdgpu-对-drm-框架的接入与调用>)已经介绍 DRM 入口、对象、回调和 AMDGPU 对 GEM/TTM 的使用。[第七章大纲](<./07_AMDGPU 通用内存管理与 DRM 任务提交（大纲）.md>)从这些文件、BO 和 GPUVM 继续，另取 X/Y 的 SDMA 拷贝案例：先由 P 提交复制，再加入 R 读取共享 Y，沿普通 DRM 请求展开提交、完成、迁移和释放。

```text
06 的 AQL 路径
    Runtime 发布用户 Ring 中的 Packet → Doorbell → 设备处理与完成通知
    KFD 管理 Queue 驻留，BO、GPUVM 和同步条件支持其访问

07 的普通 DRM 路径
    P 准备 X/Y 的 BO 与地址 → 提交请求 → job / scheduler
    → 驱动向硬件 Ring 提交启动 IB 的命令
    → SDMA 复制 X 到 Y → 完成与访问条件满足 → R 读取共享 Y
    → 保留 BO，按需迁移；所有使用者结束后归还资源
```

第七章沿新的提交入口读取实现；涉及相同的对象、映射和寿命条件时，再回查 06 的使用位置：

- [上篇 §2](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#2-应用接入建立进程地址空间与可复用资源>) 的 render 文件、BO 与 GPUVM 关系接到 [07 §7.1](<./07_AMDGPU 通用内存管理与 DRM 任务提交（大纲）.md#71-drm-文件bo地址映射与跨进程共享>)，继续追踪 handle、共享对象与各进程映射。
- 本篇 §3 的 AQL 发布和 KFD 驻留用来对照 [07 §7.2](<./07_AMDGPU 通用内存管理与 DRM 任务提交（大纲）.md#72-一次普通-drm-提交从拷贝请求到硬件-ring>)的 context、job、scheduler、IB 和 Ring 路径。
- 本篇 §4 的完成、可见与数值正确接到 [07 §7.3](<./07_AMDGPU 通用内存管理与 DRM 任务提交（大纲）.md#73-dma_fencedma_resv-与依赖和完成传播>)，解释 Fence、依赖保存与共享结果交接。
- [上篇 §2.6](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#26-引用映射与任务完成共同约束资源寿命>)、§3.8 的资源位置变化和 Queue 使用条件接到 [07 §7.4](<./07_AMDGPU 通用内存管理与 DRM 任务提交（大纲）.md#74-ttm-放置驱逐迁移与-kfd-队列协调>)，深入 TTM 迁移与 KFD 队列暂停、恢复。
- 本篇各映射路径要求的更新完成与旧翻译处理接到 [07 §7.5](<./07_AMDGPU 通用内存管理与 DRM 任务提交（大纲）.md#75-gpuvm-更新后端超时与一次小范围验证>)，分别追踪 CPU/SDMA 更新后端及错误结果。

<details>
<summary>回查 00～05：这些知识在本次应用中的使用位置</summary>

- [00：GPU 系统基础](./00_GPU系统基础.md)建立 Host、驱动、Firmware 与设备执行的关系。06 上下篇在 [上篇 §1](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#1-驱动初始化建立可供应用使用的设备资源>) 准备控制服务，在 §3 区分 Host 提交、Queue 驻留和 CU 执行，在 §4 接回结果交付。
- [01：Linux 内存管理基础](<./01_Linux 内存管理基础.md>)解释 CPU 地址空间、页面、DMA 地址及资源寿命。[上篇 §2.1](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#21-runtime-进入-kfd建立-p-的进程记录>)～[上篇 §2.6](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#26-引用映射与任务完成共同约束资源寿命>) 用这些基础连接线程、mm、打开文件和 KFD 对象，§5.4 再用于解释恢复与退出竞争。
- [02：GPU 内存管理基础](<./02_GPU 内存管理基础.md>)让 Ring、参数和数组取得存储与访问地址。[上篇 §2.3](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md#23-申请任务内存并准备完成对象>) 接上分配、授权和映射，§4 区分可访问与本轮写入可见，§5.3 完成解除映射和资源归还。
- [03 上篇](<./03_AMD GPU 队列与 AQL Dispatch（上）.md>)与[下篇](<./03_AMD GPU 队列与 AQL Dispatch（下）.md>)建立 Queue、Packet、驻留、执行与完成协议。06 上下篇把它们串成 Q0 的创建、Packet 37 的发布和执行、S 的更新、下一轮复用及 Queue 停用。
- [04：AMD GPU MMU 与地址翻译](<./04_AMD GPU MMU 与地址翻译.md>)解释设备怎样在当前地址空间中访问 Ring、代码和 A/B/C。本篇 §3.1～§3.2 接上 PASID、VMID 与实际访存，映射变化时仍需满足页表更新和旧翻译失效条件。
- [05：HMM 与 SVM](<./05_HMM 与 SVM：GPU 缺页恢复与页面迁移.md>)处理合法 SVM 地址的缺页、页面迁移与并发变化。本篇 §3.8 回顾 GPU 访问恢复和页面变化，§4.3 接上任务完成后的 CPU 迁回，§5.4 接上地址空间退出；访问恢复之后，原任务继续通过 §4 交付完整结果。

</details>

**[BOUNDARY]** 06 上下篇于 2026-10-01 按固定源码与规范核对资源关系、调用条件和同步语义。示例中的初始化观察、线程交错、两 Queue 数值与完成状态均区分源码事实和教学推演；本次未编译驱动，也未在 MI300X 上运行这些场景。文档已写入、源码已核对和学习者已经掌握分别判断。
