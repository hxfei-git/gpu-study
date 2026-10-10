# AMD CP 功能分析与实验规格

| 缩写 | 英文全称 | 中文含义 |
| --- | --- | --- |
| AMD | Advanced Micro Devices | 超威半导体公司；本文分析的 GPU 厂商 |
| CP | Command Processor | 命令处理器 |
| CPU | Central Processing Unit | 中央处理器 |
| GPU | Graphics Processing Unit | 图形处理器 |
| GPGPU | General-Purpose Computing on Graphics Processing Units | 利用 GPU 进行通用计算 |
| CDNA | Compute DNA | AMD 数据中心计算 GPU 架构系列 |
| QEMU | Quick Emulator | 仿真与虚拟化工具 |
| HSA | Heterogeneous System Architecture | 异构系统架构 |
| AQL | Architected Queuing Language | HSA 定义的队列包格式与提交协议 |
| ROCm | Radeon Open Compute | AMD GPU 计算软件平台 |
| ROCr | ROCm Runtime | AMD 的 HSA 用户态运行时 |
| KFD | Kernel Fusion Driver | AMD GPU 计算相关内核驱动组件 |
| MQD | Memory Queue Descriptor | 内存队列描述符 |
| HQD | Hardware Queue Descriptor | 队列驻留时使用的硬件描述状态 |
| HWS | Hardware Scheduling | KFD 使用硬件／固件进行队列调度的模式 |
| MEC | Micro Engine Compute | AMD GPU 处理计算队列的命令处理引擎 |
| VMID | Virtual Memory Identifier | GPU 硬件地址空间标识 |
| ISA | Instruction Set Architecture | 指令集架构 |
| ABI | Application Binary Interface | 应用二进制接口；本文用于描述软件与设备的数据和启动约定 |
| ID | Identifier | 标识符；Packet ID 用于标识队列中的包 |
| LLVM | LLVM（项目名称，源自 Low Level Virtual Machine） | 编译器基础设施项目；本文引用其 AMDGPU 后端文档 |
| RV32 | 32-bit RISC-V | 本实验计算执行器采用的指令集方向，以及拟议控制核的指令集方向；具体支持范围分别约定 |
| VRAM | Video RAM | 设备显存；本实验由 QEMU 提供后备存储 |
| DMA | Direct Memory Access | 直接内存访问 |
| IOMMU | Input/Output Memory Management Unit | 输入输出内存管理单元 |
| SMMUv3 | System Memory Management Unit version 3 | Arm 系统内存管理单元第三版 |
| GPUVM | GPU Virtual Memory | GPU 虚拟内存及地址空间管理 |
| wptr | Write Pointer | 队列写索引；AMD 的预留语义与教学方案的发布语义须分别理解 |
| rptr | Read Pointer | 队列读索引，用于管理包槽位的回收 |
| PCIe | Peripheral Component Interconnect Express | Host 与独立 GPU 之间的互连 |
| BAR | Base Address Register | PCIe 基址寄存器；用于描述设备的地址窗口 |
| MMIO | Memory-Mapped Input/Output | 内存映射输入输出 |
| PC | Program Counter | 程序计数器，保存取指位置 |
| SRAM | Static Random-Access Memory | 静态随机存取存储器；本文用于拟议 CP 的私有存储 |
| TCG | Tiny Code Generator | QEMU 的动态代码生成基础设施 |
| SIMT | Single Instruction, Multiple Threads | 单指令、多线程执行模型 |
| KIQ | Kernel Interface Queue | 驱动使用的内核接口队列 |
| KCQ | Kernel Compute Queue | 驱动管理的内核计算队列 |
| HIQ | HSA Interface Queue | KFD 向调度固件提交管理命令的接口队列 |
| PSP | Platform Security Processor | AMD 平台安全处理器，参与固件加载 |
| MES | Micro Engine Scheduler | AMD 的微引擎调度器；本次流程不采用此路径 |
| PM4 | PM4（AMD 命令包格式名称） | 本文用于队列管理命令 |
| IB | Indirect Buffer | 间接命令缓冲区 |
| DWORD | Double Word | 本文为 32 位、4 字节的数据单位 |
| GC | Graphics and Compute | AMD 图形与计算模块 |
| XCC | Accelerated Compute Complex | MI300X 的计算复合体；本文按一个实例解释寄存器操作 |
| EOP | End of Pipe | 管线结束相关处理；本文涉及队列的 EOP 缓冲配置 |
| IOVA | Input/Output Virtual Address | 设备 DMA 使用的输入输出虚拟地址 |
| CUDA | Compute Unified Device Architecture | NVIDIA 的通用 GPU 计算平台 |

## 1. 分析范围与阅读顺序

第一阶段已经跑通应用到设备的计算流程，当前进入用户 AQL Queue、Doorbell、CP 与 Signal 阶段。接下来先确定 CP 的功能、输入输出和执行边界，再据此复审队列及任务协议。

本文是友商分析与教学设计讨论稿。第 2、3 节解释任务流程与 AMD 功能，第 4、5 节记录教学设计要求和待复审的协议。第 6～10 节保存本轮讨论中的问题与回答，按实验目标、QEMU 执行模型、寄存器、启动流程、多队列状态的依赖顺序整理。问题保留原意和主要措辞，回答采用源码核验后的说明；重复问题共用必要的图示，不作为逐字聊天日志。实验阶段安排、寄存器和数据布局统一维护在 [QEMU GPGPU 四阶段实验大纲](<./QEMU GPGPU 实验大纲.md>) 中；本文不另设实验进度记录。

**[BOUNDARY]** AMD 分析采用外部 Host CPU + MI300X 独立 GPU（CDNA 3）模型，围绕 AQL 计算提交路径展开。HSA 的 Packet Processor 是处理队列包的协议角色；AMD CP 及配合它工作的派发硬件承担相关功能。QEMU 中的教学 CP 是自定义模块，不能据其实现推定 MI300X 内部结构。

当前已明确的目标是：在 PCIe GPGPU 内增加一个能执行自定义固件的独立控制核，让固件管理队列和派发任务。现有 RV32 计算执行器继续执行应用 kernel。本文新增的控制核方案仍是设计讨论，不能据此认定控制核或第二阶段已经实现。

公开资料能够确认软件可见的行为、驱动配置和固件接口。CP 内部流水线、逐周期调度算法和吞吐数量不在本文结论范围内。Linux 源码中的固件加载函数也不能作为 CP 固件内部解析流程的实现源码。

> **[SOURCE]** Linux 固定基线 `248951ddc14de84de3910f9b13f51491a8cd91df`，[drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L560-L584) 的 [560–584 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L560-L584) 请求 MEC 固件二进制并登记 CP 微码条目。它证明驱动与固件的装载关系，不提供固件内部算法。

## 2. 一次向量加法经过 CP 的过程

**[DESIGN] 示例条件：** 应用提交一次向量加法，处理 1024 个元素，每个 workgroup 包含 256 个 work-item。运行时已经准备好代码、参数、输入数据和完成 Signal，Signal 初值为 1。正常主线采用有效映射和充足资源，Packet 的 acquire/release scope 均取 SYSTEM，Host 以 acquire 语义等待完成。

设备接下来需要读取任务、建立执行状态、启动计算，再向应用报告完成。下图补充的是原始硬件框图没有展开的对象访问与执行顺序；它是逻辑流程图，不表示这些步骤全部位于一个物理 CP 模块中。

```text
驱动准备队列
  └─ 配置 Ring、读写索引、Doorbell、地址空间和执行资源
                         │
                         ▼
运行时写入 AQL Packet，最后发布有效 Header
  └─ Packet 指向 Kernel 描述对象、参数和完成 Signal
                         │
                         ▼
运行时写 Doorbell，通知设备检查队列
                         │
                         ▼
设备派发前端
  读取有效包
    → 检查顺序与依赖
    → 读取 Kernel 描述对象
    → 建立执行上下文
    → 派发 workgroup / wavefront
                         │
                         ▼
计算单元执行 Kernel 指令，写入结果
                         │
                         ▼
设备完成规定的内存同步，更新 completion Signal
                         │
                         ▼
Host 检查 Signal，确认完成并使用结果
```

CP 负责组织任务并启动执行，计算单元负责执行 kernel 的算术、访存和控制流指令。对应到 QEMU 教学设备，就是 CP 管理任务，RV32 执行器运行 kernel。这里“执行上下文”指启动和继续执行一项任务所需的信息，例如代码入口、参数、维度以及执行进度。

> **[SPEC]** 仓库中的 [AMD Instinct MI300 Instruction Set Architecture](<../3.资料/amd-instinct-mi300-cdna3-instruction-set-architecture.pdf>)，封面日期 **2025-08-05**，第 1 章、原文第 3～4 页，区分命令处理与计算执行职责。[LLVM 18.1.8 AMDGPU 文档的 Kernel Dispatch 小节](https://releases.llvm.org/18.1.8/docs/AMDGPUUsage.html#kernel-dispatch) 说明 AQL Packet Processor 由 CP 与派发硬件协作实现。

## 3. AMD CP 的功能与教学设计要求

以下按任务的生命周期整理九项功能。每节先解释 AMD 公开语义或源码中可以确认的行为，再用 `[DESIGN]` 写出自研 CP 需要回答的问题。这些教学要求不代表 MI300X 的实际寄存器定义。

### 3.1 CP-01：接收队列配置，建立队列上下文

CP 要处理一个队列，首先必须知道 Ring 在哪里、容量多大，到哪里读取或报告队列索引，以及哪个 Doorbell 对应该队列。设备还要确定该队列使用的地址空间、执行资源和是否允许执行。

AMD 驱动将这些信息组织进 MQD。MQD 保存在内存中；队列驻留到硬件时，对应信息进入 HQD。在 HWS 路径中，驱动把队列交给调度固件管理。

```text
驱动准备 Queue 的内存描述 MQD
  → 把队列交给 HWS 管理
  → 队列驻留时建立对应 HQD 状态
  → 设备按队列配置处理后续发布的 AQL Packet
```

创建队列、使队列驻留和提交一个 AQL Packet 是不同阶段。应用正常提交每个任务时不需要重新创建 MQD。图中只表达描述与驻留的关系，不限定 MI300X 整卡只有一份 MQD 或一个 HQD。

**[DESIGN]** 自研 CP 必须提供独立于普通任务提交的队列配置入口。配置生效后，CP 能独立找到后续任务；运行期间修改地址等关键配置，必须有明确的停机或切换条件。

> **[SOURCE]** Linux `248951ddc14de84de3910f9b13f51491a8cd91df`：
>
> - [drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c#L279-L333)，[279–333 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c#L279-L333)：配置 Ring、索引地址、Doorbell 和 VMID。
> - [drivers/gpu/drm/amd/amdkfd/kfd_priv.h](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_priv.h#L142-L146)，[142–146 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_priv.h#L142-L146)：说明 HWS 将 MQD 装入 HQD 的关系。

### 3.2 CP-02：接收 Doorbell，识别有效任务并消费 Ring

运行时先准备 Packet 内容，最后发布有效 Header，再通知设备。CP 必须区分软件预留了一个位置，还是这个位置上的包已经可以执行。

多生产者队列中，后面的生产者可能先完成写包，而前面的槽位仍是 INVALID。设备不能因为看到了更大的写索引或 Doorbell 值，就执行尚未发布的包。

AMD/HSA 队列中存在两个独立的进度：

```text
Ring 消费进度：哪些 Packet 槽位可以重新使用
任务完成进度：哪些 Kernel 已经完成执行
```

`read_index` 用来管理槽位回收。应用判断任务完成，需要检查对应的 completion Signal。因此，即使包槽已经可以复用，参数、代码和完成对象仍可能被正在执行的任务使用。

**[DESIGN]** 自研 CP 必须按队列顺序处理有效包，遇到尚未发布的队头包时等待。重复通知不能重复执行任务，执行期间新增任务不能因通知合并而丢失。归还 Ring 槽位前，必须保存后续执行仍然需要的信息。

> **[SOURCE]** ROCr 固定基线 `ba56a24c6132c5d195686ae4adf969ca1222fbba`，[runtime/hsa-runtime/core/runtime/amd_blit_kernel.cpp](https://github.com/ROCm/rocr-runtime/blob/ba56a24c6132c5d195686ae4adf969ca1222fbba/runtime/hsa-runtime/core/runtime/amd_blit_kernel.cpp#L844-L901) 的 [844–901 行](https://github.com/ROCm/rocr-runtime/blob/ba56a24c6132c5d195686ae4adf969ca1222fbba/runtime/hsa-runtime/core/runtime/amd_blit_kernel.cpp#L844-L901) 展示预留位置、等待空间、发布 Header，以及用最后一个 Packet ID 通知 Doorbell 的过程。

> **[SPEC]** [HSA System Architecture 1.2](https://hsafoundation.com/wp-content/uploads/2021/02/HSA-SysArch-1.2.pdf)，发布日期 **2018-05-02**，§2.8.3、原文第 20～21 页：Packet 槽位回收可以早于任务完成；槽位归还前需要先使 INVALID 可见。

### 3.3 CP-03：解析 Dispatch，取得描述对象并建立启动状态

一次 Dispatch 需要回答三个问题：

```text
执行什么：Kernel 描述对象 → 代码入口、资源要求
处理多少：grid_size、workgroup_size
使用什么输入：kernarg_address → 参数内存
```

在 AMD 的代码对象约定中，`kernel_object` 对应 Kernel 描述对象的地址。描述对象提供入口位置和启动配置；CP 根据描述信息安排 kernel 所需的初始执行状态。

例如，参数地址、workgroup 编号等信息必须在 kernel 开始执行时按约定出现在相应寄存器中。参数中的数组指针则由 kernel 在实际访存时使用。

**[DESIGN]** 自研 CP 应将外部 Packet 转换成明确的执行请求，至少包含任务标识、代码入口、参数位置、执行维度和完成目标。CP 与执行器之间必须有固定的启动约定。

现有教学方案把参数复制到预留的 VRAM 参数页，再让 RV32 的 `a0` 指向该页。这部分用于适配现有执行器，需要与 AMD 的参数传递方式分别说明。

> **[SPEC]** [LLVM 18.1.8：Kernel Descriptor](https://releases.llvm.org/18.1.8/docs/AMDGPUUsage.html#kernel-descriptor) 与 [Initial Kernel Execution State](https://releases.llvm.org/18.1.8/docs/AMDGPUUsage.html#initial-kernel-execution-state) 规定描述对象和初始执行状态。MI300 ISA，**2025-08-05**，§3.13、原文第 17 页，也描述了 wave 启动时的寄存器初始化。

### 3.4 CP-04：组织工作派发，处理执行资源不足

沿用第 2 节的向量加法例子，任务规模如下：

```text
1024 个 work-item
  ÷ 每个 workgroup 256 个
  = 4 个 workgroup

在 MI300X 的 wavefront64 模型下：
每个 workgroup 包含 4 个 wavefront
整个 Dispatch 包含 16 个 wavefront
```

这描述的是任务规模。16 个 wavefront 能否同时启动，还取决于寄存器、组内共享存储和其他执行资源是否充足。

规格需要区分三种情况：

- 配置无法支持，例如单个 workgroup 的资源要求超过允许范围，需要报告错误。
- 资源暂时被占用，任务仍然合法，需要等待资源可用。
- 任务已经派发，仍需跟踪执行完成，才能完成整个 Dispatch。

AMD 的工作派发由 CP、派发硬件和计算单元协作完成。上述算术规模可以推导出来，但不能据此推定 CP 的实际派发周期或内部调度算法。

**[DESIGN]** 教学设备第一版可以只允许一个活动 kernel。CP 必须识别执行器的忙、完成和故障等结果，并在执行器可接收任务时才派发下一项工作。

> **[SPEC]** MI300 ISA，**2025-08-05**，§1.1、原文第 4 页定义 wavefront 为 64 个 work-item。[AMD MI300 微架构说明，ROCm 6.3.2，2025-01-14](https://rocm.docs.amd.com/en/docs-6.3.2/conceptual/gpu-arch/mi300.html) 说明异步计算引擎向计算单元发送 workgroup 的关系。

### 3.5 CP-05：执行任务依赖与队列屏障

任务 B 需要等待任务 A 的结果时，可以有两种不同的约束。

第一种是 Packet Header 的 `barrier` 位。置位后，当前包启动前需要等待同一队列的全部前序包完成。例如 A、B 都在同一队列，B 设置 `barrier=1`，B 启动前就要等 A 及其他前序任务完成。

第二种是独立的 Barrier-AND / Barrier-OR Packet。这类包通过 Signal 表达依赖，可以连接不同任务或不同队列：

```text
队列 A：Kernel A ──完成──→ Signal A
                              │
队列 B：Barrier-AND 等待 Signal A
           → 条件满足后，允许后续 Kernel B 推进
```

AND 等待全部有效依赖满足，OR 等待至少一个有效依赖满足。Barrier Packet 还会阻挡本队列后继包的推进。Header barrier 位与 Barrier Packet 类型需要分别理解，不能合并成一个屏障开关。

**[DESIGN]** 自研 CP 的规格应分别说明前序任务完成约束和显式 Signal 依赖。第一版可以只实现 `KERNEL_DISPATCH + barrier=1`；对未支持的 Barrier Packet 明确报错。

> **[SOURCE]** ROCr `ba56a24c6132c5d195686ae4adf969ca1222fbba`，[runtime/hsa-runtime/inc/hsa.h](https://github.com/ROCm/rocr-runtime/blob/ba56a24c6132c5d195686ae4adf969ca1222fbba/runtime/hsa-runtime/inc/hsa.h#L2880-L2884) 的 [2880–2884 行](https://github.com/ROCm/rocr-runtime/blob/ba56a24c6132c5d195686ae4adf969ca1222fbba/runtime/hsa-runtime/inc/hsa.h#L2880-L2884) 定义 Header barrier；[3126–3204 行](https://github.com/ROCm/rocr-runtime/blob/ba56a24c6132c5d195686ae4adf969ca1222fbba/runtime/hsa-runtime/inc/hsa.h#L3126-L3204) 定义 Barrier Packet 的五个依赖 Signal 槽。

### 3.6 CP-06：落实任务开始和结束时的内存可见性

CP 的规格必须保证数据交接顺序。对于 Host 发布输入、GPU 计算、Host 等待结果的例子，需要表达：

```text
Host 写好输入与参数
  → 正确发布任务
  → Dispatch 按指定 scope 执行 acquire
  → Kernel 执行并写入结果
  → 按指定 scope 执行 release
  → 更新完成 Signal
  → Host 以 acquire 语义确认完成
```

这里有三层不同的同步。发布 Header 保证设备不会使用半写入的 Packet；Packet 的 acquire/release 约束任务访问的数据；Host 等待 Signal 完成结果交接。Doorbell 通知还必须遵守平台规定的内存与设备访问顺序，不能只靠 `volatile` 保证上述关系。

**[DESIGN]** 自研 CP 必须规定这些动作之间的顺序。即使 QEMU 使用一致性内存，也需要保留这份顺序约定，后续 A57、设备访问和驱动实现按该约定配合。

若以后支持 Barrier Packet，它的 acquire 位于依赖满足之后，不能提前到等待依赖之前。

> **[SOURCE]** ROCr `ba56a24c6132c5d195686ae4adf969ca1222fbba`，[runtime/hsa-runtime/inc/hsa.h](https://github.com/ROCm/rocr-runtime/blob/ba56a24c6132c5d195686ae4adf969ca1222fbba/runtime/hsa-runtime/inc/hsa.h#L2845-L2912) 的 [2845–2912 行](https://github.com/ROCm/rocr-runtime/blob/ba56a24c6132c5d195686ae4adf969ca1222fbba/runtime/hsa-runtime/inc/hsa.h#L2845-L2912) 定义 fence scope 与 Dispatch 同步语义。[runtime/hsa-runtime/core/runtime/amd_aql_queue.cpp](https://github.com/ROCm/rocr-runtime/blob/ba56a24c6132c5d195686ae4adf969ca1222fbba/runtime/hsa-runtime/core/runtime/amd_aql_queue.cpp#L468-L482) 的 [468–482 行](https://github.com/ROCm/rocr-runtime/blob/ba56a24c6132c5d195686ae4adf969ca1222fbba/runtime/hsa-runtime/core/runtime/amd_aql_queue.cpp#L468-L482) 展示常规硬件 Doorbell 路径的排序与写入；这里的指令不能直接照搬到 A57。

> **[SPEC]** [HSA System Architecture 1.2](https://hsafoundation.com/wp-content/uploads/2021/02/HSA-SysArch-1.2.pdf)，**2018-05-02**，§2.9.1～2.9.2、原文第 25～27 页，区分 Dispatch 与 Barrier 的同步阶段。

### 3.7 CP-07：完成任务，更新 Signal 并配合等待通知

AMD/HSA 的正常完成语义是对非空 completion Signal 原子减一。下面两个用例都能表达：

```text
一个任务使用一个 Signal：
初值 1 → 完成一次 → 0

三个任务共同使用一个 Signal：
初值 3 → 2 → 1 → 0
```

第二个用例说明原子操作的意义：多个任务共同报告完成时，不能相互覆盖更新。Signal 值是等待条件的一部分，具体任务是否失败还需要结合错误路径判断。

应用可以轮询 Signal，也可以通过事件阻塞等待。被唤醒后仍然需要检查 Signal 条件，不能规定收到一次中断就代表某个指定任务成功。

**[DESIGN]** 自研 CP 必须保证每项任务的完成更新只发生一次，且晚于规定的结果写入和同步。通知合并或重复唤醒不能影响结果判断；错误处理必须有独立路径，不能只依赖成功 Signal。

> **[SPEC]** [HSA System Architecture 1.2](https://hsafoundation.com/wp-content/uploads/2021/02/HSA-SysArch-1.2.pdf)，**2018-05-02**，§2.9.2、原文第 26～27 页，规定完成阶段的原子递减。

> **[SOURCE]** ROCr `ba56a24c6132c5d195686ae4adf969ca1222fbba`，[runtime/hsa-runtime/core/runtime/interrupt_signal.cpp](https://github.com/ROCm/rocr-runtime/blob/ba56a24c6132c5d195686ae4adf969ca1222fbba/runtime/hsa-runtime/core/runtime/interrupt_signal.cpp#L157-L207) 的 [157–207 行](https://github.com/ROCm/rocr-runtime/blob/ba56a24c6132c5d195686ae4adf969ca1222fbba/runtime/hsa-runtime/core/runtime/interrupt_signal.cpp#L157-L207) 展示检查 Signal、阻塞等待和唤醒后重新检查的过程。这是 Host 运行时的等待实现，不是 CP 固件源码。

### 3.8 CP-08：报告错误，阻止错误队列继续推进

错误可能出现在不同阶段：

```text
取包：队列内存访问失败
解析：包格式、维度或资源要求不合法
准备：描述对象或参数访问失败
执行：非法指令、非法访存等执行异常
完成：完成状态写回失败
```

这些错误不必全部由 CP 检测。非法指令可能由计算执行单元检测，地址访问错误可能来自内存管理硬件。CP、运行时和驱动需要共同形成可观察的错误路径。

AMD 运行时具有队列异常处理和错误回调。正常 completion Signal 不承担所有错误报告职责；任务异常终止时，不能假定 Signal 一定按正常完成方式递减。

**[DESIGN]** 自研 CP 至少保存错误原因、出错阶段、任务标识和相关地址，并停止该队列继续派发。即使 Signal 所在内存无法写入，Host 也必须能够通过队列错误退出等待。

> **[SOURCE]** ROCr `ba56a24c6132c5d195686ae4adf969ca1222fbba`，[runtime/hsa-runtime/core/runtime/amd_aql_queue.cpp](https://github.com/ROCm/rocr-runtime/blob/ba56a24c6132c5d195686ae4adf969ca1222fbba/runtime/hsa-runtime/core/runtime/amd_aql_queue.cpp#L1178-L1230) 的 [1178–1230 行](https://github.com/ROCm/rocr-runtime/blob/ba56a24c6132c5d195686ae4adf969ca1222fbba/runtime/hsa-runtime/core/runtime/amd_aql_queue.cpp#L1178-L1230) 展示错误分类、暂停队列和调用错误回调。

> **[SPEC]** [HSA System Architecture 1.2](https://hsafoundation.com/wp-content/uploads/2021/02/HSA-SysArch-1.2.pdf)，**2018-05-02**，§2.9.3、原文第 27～29 页，区分异常终止与正常 completion 阶段。

### 3.9 CP-09：停止、卸载与抢占，确认设备停止访问资源

进程退出、超时处理和队列销毁都依赖这一项。规格需要区分三个动作：

- 正常排空：已提交任务执行完成，再停止队列。
- 终止：放弃后续执行，允许任务留下部分结果。
- 保存并恢复：保存执行状态，之后从中断位置继续执行。

AMD 队列管理路径具有卸载、抢占及状态保存相关支持。驱动发送卸载请求后，还要检查完成与失败信息；请求已经发出，不能直接作为释放队列内存的依据。

**[DESIGN]** 自研 CP 第一版至少实现正常排空和终止后的静止确认。只有确认取包、执行和后续回调都不会再访问旧资源，驱动才能释放内存。

QEMU 执行器每运行一段指令就让出主循环，是实现异步推进的基础。要支持可恢复抢占，还需要额外定义保存内容、恢复入口和状态生命周期。

> **[SOURCE]** Linux `248951ddc14de84de3910f9b13f51491a8cd91df`，[drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c#L2574-L2605) 的 [2574–2605 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c#L2574-L2605) 展示卸载请求、等待确认和检查抢占失败的过程。

## 4. QEMU 第一版 CP 的功能约定

### 4.1 CP 与驱动、运行时和执行器的接口

**[DESIGN]** 基于前述功能，第一版先确定每个接口交接什么，以及什么时候可以进入下一步。以下是逻辑接口，不是已经实现的函数名或最终 ABI。

```text
驱动给 CP：
  固件、启动入口、启动与复位控制
  队列配置、启用请求、停止请求

用户态给 CP：
  已发布的任务、Doorbell 通知

CP 给执行器：
  已验证的执行请求
  包含入口、参数、维度、任务标识

执行器给 CP：
  需要继续 / 执行完成 / 执行故障 / 已取消

CP 给 Host：
  队列消费进度、任务完成信息、错误信息、静止确认
```

控制核的寄存器、取指执行、DMA 和内部派发接口由 QEMU 设备模型提供；解析 AQL、检查队列与组织任务的策略由自定义固件执行。控制核与计算执行器分别保存自己的 PC 和寄存器状态，具体设计见第 7 节。

执行器返回“需要继续”时，当前任务仍然活动，CP 应安排后续执行；只有“执行完成”才进入正常完成写回。执行故障或取消需要走各自的终止路径。

### 4.2 规模与能力边界

**[DESIGN]** 第一版规模沿用实验大纲中的取值：一个 Queue、64 个包槽、64 字节 Packet、同时执行一个 kernel，保留 RV32 后端。A57 与 SMMUv3 系统 IOMMU 支持继续沿用。

多队列调度、并发 kernel、Barrier Packet、GPU 地址隔离和可恢复抢占作为后续能力。系统 IOMMU 对设备 DMA 的地址翻译，与未来 GPUVM 对 kernel 地址空间的管理分开说明；现有教学设备的 kernel 仍使用 VRAM 偏移。

这里不复制寄存器偏移、共享区布局和 Signal 编码。具体参数以 [实验大纲第二阶段](<./QEMU GPGPU 实验大纲.md#22-第二阶段用户-aql-queuedoorbellcp-与-signal>) 为统一入口，协议取舍经过第 5 节的复审后再更新该大纲。

### 4.3 第一版必须保证的行为

**[DESIGN]** 以下行为用于判断 CP 是否履行上述功能约定，尚不表示实现已经通过验收。

1. 驱动加载并启动独立 CP 固件；替换固件后，无需重新编译 QEMU 即可改变控制程序行为。连续提交多个任务后，CP 能独立推进，正常提交不需要逐任务调用驱动启动。
2. 遇到未发布的队头包时等待，重复 Doorbell 不会重复执行。
3. Ring 槽位释放后，活动任务使用的参数、代码和完成对象仍受保护。
4. 长 kernel 执行期间，状态查询和停止请求仍能得到处理。
5. 取包、执行或完成写回失败时，等待者能够获知错误。
6. 报告 `QUIESCED` 后，不再访问旧队列内存；`FAULT` 本身不能作为释放依据。

## 5. 冻结协议前需要复审的三项设计

### 5.1 写索引、有效 Header 与 Doorbell 的关系

实验草案把 `wptr` 定义为发布进度，Doorbell 只写入 `1`。AMD 提交中还存在预留进度、有效 Header 和 Packet ID 通知之间的关系。

**[DESIGN]** 需要明确 CP 根据哪个状态判断当前包可执行，以及重复通知、尚未发布的槽位和后续多生产者提交分别怎样处理。即使第一版保留简单的 Doorbell，也应保留有效 Header 的发布语义。

### 5.2 单任务完成状态与共享 Signal

实验草案使用单任务的 `value=0` 加状态字段；AMD/HSA 支持原子递减，错误通过另外的路径报告。

**[DESIGN]** 保留单任务 Signal 时，需要明确它是教学完成对象；若选择共享计数语义，CP 就需要支持不会丢失更新的原子操作。无论选择哪种方式，都必须保证一次完成只更新一次，并为 Signal 写回失败保留队列错误路径。

### 5.3 Kernel 描述对象与 RV32 参数适配

实验草案采用自定义描述对象和 RV32 参数页。AMD 路径中需要保留的核心关系是：Packet 找到 Kernel 描述对象，描述对象与 Dispatch 信息共同决定启动状态。

**[DESIGN]** 需要明确描述对象由谁生成、哪些字段由 CP 检查，以及哪些内容交给执行器使用。参数复制到 VRAM 的适配方式与 AMD 参数访问约定分别记录。这三项取舍将决定 CP 保存的状态、执行的原子操作，以及后续扩展是否需要修改协议。

## 6. 实验方向与固件控制核的目标

### 6.1 从现有计算流程转向 AMD 风格的软件栈

> **提问：** 目前我的试验阶段，已经完成了：进阶实验一，设计类 CUDA 的 GPGPU 软件栈，并且搭配 A57 并支持 IOMMU。但是我的所有学习内容都是基于 AMDGPU，所以我希望最终的结果并不是类 CUDA 的 GPGPU 软件栈，而是类 AMD 的 GPGPU 软件栈。调整后有哪些工作需要做？
>
> **追问：** 我有点没看懂你的这个计划，意思是已经算我第一阶段完成了吗？

**回答：** 按你的实验反馈，第一阶段已经完成：应用能够通过驱动把计算交给 PCIe 设备，A57 和系统 IOMMU 已纳入实验。方向调整后，已有计算执行器、设备 DMA、驱动资源管理和运行验证仍可使用。需要继续建立的是 AMD/HSA 风格的用户态队列、通知、命令处理和完成机制。

```text
已有第一阶段
应用 → 驱动准备资源和启动参数 → 设备执行 kernel → 返回结果

第二阶段目标
驱动先建立队列并启动 CP 固件
应用 → 在用户队列中发布 AQL Packet → 写 Doorbell
     → CP 固件取包并派发 → 计算执行器运行 kernel
     → 设备更新 Signal → 应用确认完成
```

这表示第一阶段的成果被保留，第二阶段尚需实现和验证。AMD 风格首先体现在对象关系与提交语义；仅把接口改名为 AQL、MQD 或 CP，不能形成相应的软件栈。也不要求本阶段直接兼容完整 AMD 驱动、运行时或固件二进制。

> **提问：** 那我切入到第二阶段：用户 AQL Queue + Doorbell + CP + Signal。请给我一个更加具体的硬件规格，和软件需要完成的内容。

**回答：** 设备需要提供队列配置、Doorbell、取包、派发、完成写回和错误报告；驱动需要分配并映射资源、配置地址、加载固件和管理启停；运行时需要发布 Packet、通知队列并等待 Signal。当前第一版按一个 Queue、64 个 64 字节包槽、同时执行一个 kernel 展开。功能要求见第 3、4 节；已有参数草案在实验大纲中维护，不能把尚待复审的布局当作已冻结协议。

> **提问：** 接下来，我们先固定协议和 CP，我觉得应该先定 CP，请先基于 AMD 的 CP 实现的功能，给我一份规格，我先做一下友商分析。

**回答：** 先确定 CP 需要从 Packet 得到什么、向执行器交付什么、什么时候可以报告完成，再冻结寄存器和内存协议。第 3 节的九项功能用于这轮分析。随后讨论进一步明确了实现目标：CP 应是执行独立固件的控制核。

### 6.2 驱动加载的固件由设备内部控制引擎执行

> **提问：** 等一下，看看我的笔记中，这个 CP 是 amd 驱动加载的时候，把对应的 Firmware 加载进去执行的吗？

**回答：** 对于这里讨论的 AMD 计算命令处理路径，MEC 运行相应微码。Host 上的驱动负责请求固件文件、准备加载资源并组织启动，MEC 在 GPU 内执行微码。Host CPU 不执行 MEC 微码。

```text
Host Linux 驱动
  请求 MEC 固件文件
    → 准备固件加载资源
    → 按平台加载路径把固件交给设备
    → 配置启动所需状态并解除 MEC 停止状态
                             │
                             ▼
GPU 内的 MEC 执行固件
  读取管理命令或队列包 → 组织后续设备操作
```

MI300X 本文主线采用 PSP 固件加载路径。驱动请求 `gc_9_4_3_mec.bin`，通过 PSP 的固件加载流程准备设备微码，随后进入 CP 恢复与队列初始化。源码还保留非 PSP 直接加载分支；不能把该分支的每次寄存器写入说成主线都会执行。

**[BOUNDARY]** 驱动源码能证明固件如何被请求、提交加载以及何时启停 MEC。它不包含 MEC 固件内部的完整指令实现，也没有在这里提供可据以实现二进制兼容 MEC 的完整 ISA。

> **[SOURCE]** Linux `248951ddc14de84de3910f9b13f51491a8cd91df`：
>
> - [drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L560-L584)（[560–584 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L560-L584)）请求固件并登记微码
> - [drivers/gpu/drm/amd/amdgpu/amdgpu_psp.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_psp.c#L3298-L3330)（[3298–3330 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_psp.c#L3298-L3330)）构造并执行固件加载命令
> - [drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L2243-L2278)（[2243–2278 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L2243-L2278)）根据加载方式进入 CP 恢复流程。

> **提问：** 我觉得自定义固件的控制核，才是我真正的目标，因为这个更加贴近于实际，我可以在 QEMU 中再模拟一个 CP/MEC 核吗？

**回答：** 可以。实验目标应改为在设备内部模拟一个具有独立取指、寄存器和私有存储状态的控制核。它执行你编译的固件，固件通过内部 DMA、队列和派发接口控制计算执行器。

**[DESIGN]** 可以采用自定义 RV32 标量控制核，以便使用现成工具链编译固件。这个选择借鉴的是“驱动加载固件、设备控制核执行固件”的结构。它不说明 AMD MEC 使用 RISC-V，也不承诺运行 AMD 的固件二进制。

## 7. QEMU 中的 A57、计算执行器与独立 CP

### 7.1 当前模拟了哪些执行状态

> **提问：** 其实我现在还是对整体架构有些不明确，目前的架构是 A57 + PCIe（GPGPU），相当于一个 A57 核 + 一个 device，不知道是什么核的吗？
>
> **追问：** 先不用这样，你先回答我的问题，其实我是好奇，目前我是一个 A57 核 + GPGPU 核吗？

**回答：** 在当前实验配置下，可以先理解为“A57 系统 CPU + 一块包含计算执行器的 PCIe GPGPU 设备”。“一块设备”与“一个核”是不同层面的数量：设备还包括寄存器、显存、DMA、中断和多个 lane 的执行状态。

下图是当前 QEMU 对象与状态的逻辑关系，不是 MI300X 的物理结构图。

```text
QEMU 模拟的机器
├─ A57 系统 CPU
│    保存 ARM 寄存器、PC 等状态
│    执行 Linux、驱动和应用的 CPU 端指令
│
└─ PCIe GPGPU 设备
     ├─ 寄存器、VRAM、DMA、中断
     └─ RV32 计算执行器
          为 lane 保存寄存器和 PC
          从 VRAM 取出应用 kernel 指令并解释执行
```

当前计算执行器实现了部分 RV32 整数、乘除及浮点操作，不能据此称为完整的 RV32 指令集实现。当前设备也还没有一个加载独立固件、持续保存控制程序执行上下文的 CP。

> **[SOURCE]** QEMU 教学仓库 `049ed3eb6ba06c3b464dcff8871fd4463a441569`：
>
> - [hw/gpgpu/gpgpu.h](https://github.com/hxfei-git/gpu-study-qemu/blob/049ed3eb6ba06c3b464dcff8871fd4463a441569/hw/gpgpu/gpgpu.h#L70-L91)（[70–91 行](https://github.com/hxfei-git/gpu-study-qemu/blob/049ed3eb6ba06c3b464dcff8871fd4463a441569/hw/gpgpu/gpgpu.h#L70-L91)）是设备状态
> - [hw/gpgpu/gpgpu_core.h](https://github.com/hxfei-git/gpu-study-qemu/blob/049ed3eb6ba06c3b464dcff8871fd4463a441569/hw/gpgpu/gpgpu_core.h#L72-L94)（[72–94 行](https://github.com/hxfei-git/gpu-study-qemu/blob/049ed3eb6ba06c3b464dcff8871fd4463a441569/hw/gpgpu/gpgpu_core.h#L72-L94)）保存 lane 与 warp 的执行状态
> - [hw/gpgpu/gpgpu_core.c](https://github.com/hxfei-git/gpu-study-qemu/blob/049ed3eb6ba06c3b464dcff8871fd4463a441569/hw/gpgpu/gpgpu_core.c#L213-L245)（[213–245 行](https://github.com/hxfei-git/gpu-study-qemu/blob/049ed3eb6ba06c3b464dcff8871fd4463a441569/hw/gpgpu/gpgpu_core.c#L213-L245)）按当前 PC 从 VRAM 取指并进入译码。

### 7.2 两种指令分别由各自的执行器推进

> **提问：** 不管是 A57 核，还是 GPGPU 计算执行器，都是 QEMU 模拟的，那 QEMU 是一个循环吗？这个循环看到 A57 的指令，就去模拟 A57 核，看到 GPGPU 的指令，就去模拟 GPGPU？
>
> **追问：** 你理解我想问什么吗？我想问 QEMU 是怎么模拟这两个的。

**回答：** QEMU 分别保存 A57 与设备计算线程的状态，分别使用对应的执行器。A57 的取指位置由 A57 的 PC 决定；GPU kernel 的取指位置由计算执行器保存的 PC 决定。它们没有混在同一条指令流中，等待一个循环猜测指令属于谁。

以 TCG 模式为例，QEMU 把 A57 的 ARM 指令块翻译成运行 QEMU 的主机可以执行的代码。教学 GPGPU 则在 C 代码中解释 RV32 指令：读出操作码和操作数，计算结果，修改模拟寄存器和 PC。例如模拟加法时，若两个源寄存器保存 3 和 5，QEMU 的 C 代码计算 8，再把 8 写进目标模拟寄存器。

当前 GPU 启动路径尤其需要看清：

```text
A57 执行驱动中的 MMIO 写操作
  → QEMU 把该写操作交给 GPGPU 寄存器回调
  → gpgpu_kernel_write() 收到 DISPATCH
  → gpgpu_dispatch_kernel()
  → gpgpu_core_exec_kernel() 同步执行整个 kernel
       按 GPU lane 的 PC 从 VRAM 取指、译码、修改执行状态
  → 执行完成，寄存器回调返回
  → 发起这次 MMIO 的 A57 执行路径继续推进
```

所以，当前教学 GPU 的执行发生在设备回调调用的解释器中，并没有因为“有一块 GPU”就自动得到独立执行线程。A57 上传 GPU 代码时，只是在搬运数据；等 GPU 解释器从对应地址取指，这些数据才作为 GPU 指令执行。

QEMU 还有处理定时器和设备事件的循环，CPU 执行也可能采用不同线程配置。理解本实验不需要先假定整个 QEMU 只有一个线程，或每个设备都有一个线程；关键是各自保存什么状态、由哪个调用或事件推进。

> **[SOURCE]** QEMU 教学仓库 `049ed3eb6ba06c3b464dcff8871fd4463a441569`：
>
> - [hw/gpgpu/gpgpu_regs.c](https://github.com/hxfei-git/gpu-study-qemu/blob/049ed3eb6ba06c3b464dcff8871fd4463a441569/hw/gpgpu/gpgpu_regs.c#L79-L90)（[79–90 行](https://github.com/hxfei-git/gpu-study-qemu/blob/049ed3eb6ba06c3b464dcff8871fd4463a441569/hw/gpgpu/gpgpu_regs.c#L79-L90)）将 MMIO 操作交给启动寄存器处理
> - [hw/gpgpu/gpgpu_dispatch.c](https://github.com/hxfei-git/gpu-study-qemu/blob/049ed3eb6ba06c3b464dcff8871fd4463a441569/hw/gpgpu/gpgpu_dispatch.c#L14-L39)（[14–39 行](https://github.com/hxfei-git/gpu-study-qemu/blob/049ed3eb6ba06c3b464dcff8871fd4463a441569/hw/gpgpu/gpgpu_dispatch.c#L14-L39)）同步调用计算执行器
> - [hw/gpgpu/gpgpu_dispatch.c](https://github.com/hxfei-git/gpu-study-qemu/blob/049ed3eb6ba06c3b464dcff8871fd4463a441569/hw/gpgpu/gpgpu_dispatch.c#L72-L113)（[72–113 行](https://github.com/hxfei-git/gpu-study-qemu/blob/049ed3eb6ba06c3b464dcff8871fd4463a441569/hw/gpgpu/gpgpu_dispatch.c#L72-L113)）包含 `DISPATCH` 写处理
> - [accel/tcg/cpu-exec.c](https://github.com/hxfei-git/gpu-study-qemu/blob/049ed3eb6ba06c3b464dcff8871fd4463a441569/accel/tcg/cpu-exec.c#L428-L439)（[428–439 行](https://github.com/hxfei-git/gpu-study-qemu/blob/049ed3eb6ba06c3b464dcff8871fd4463a441569/accel/tcg/cpu-exec.c#L428-L439)）是 TCG 翻译块执行入口附近的代码。

### 7.3 设备内部 CP 不加入 Linux 的系统 CPU 列表

> **提问：** “它位于 GPGPU 设备内部，A57 上的 Linux 不需要把它当作另一颗系统 CPU。”这个是什么意思？

**回答：** A57 负责运行 Linux。Linux 调度器把应用线程和内核线程安排到系统 CPU 上。新 CP 则属于 PCIe 设备内部，驱动通过设备接口管理它：加载固件、设置入口、启动、查询状态和复位。

```text
Linux 调度器 → A57 → 应用线程、内核线程

GPGPU 驱动 → PCIe BAR 寄存器 → CP 启动与状态控制
                                  │
                                  ▼
                          CP 执行设备固件
                                  │
                                  ▼
                          控制计算执行器
```

因此 Linux 不需要把 CP 加入系统 CPU 拓扑，也不把普通 Linux 线程调度到 CP。驱动仍然知道这个控制核存在，并管理它的生命周期。这与你熟悉的“主处理器通过设备接口加载和控制一个嵌入式控制器”更接近。

### 7.4 在 PCIe 设备中实现可执行固件的控制核

> **提问：** 那我们回到 CP 的制定，我该如何给 PCIe 的 GPGPU 增加一个独立的核呢？感觉不太好搞啊。

**回答：** 可以先在现有设备内部增加一个标量指令解释器，不必先把它注册为 Linux 可见的系统 CPU。独立控制核至少要有自己的 PC、通用寄存器、存储空间、复位状态，以及按固件指令修改这些状态的执行器。

**[DESIGN]** 第一版可按下面的结构实现，容量与命名均为讨论值，尚未冻结寄存器偏移。

```text
GPGPU 设备
├─ Host 控制接口
│    固件装载窗口、入口、START、RESET、状态和错误报告
│
├─ CP 标量控制核
│    PC、32 个整数寄存器、私有 SRAM（建议从 64 KiB 开始）
│    HALTED / RUNNING / WAITING / FAULT 状态
│    独立的固件指令解释器
│
├─ CP 可访问的内部接口
│    DMA 请求及结果、Doorbell 事件、计算派发及完成事件
│
└─ 现有 RV32 计算执行器
     保留应用 kernel 的 lane、寄存器、PC 和计算数据
```

固件装载与运行按以下顺序展开：

```text
驱动取得 cp-fw.bin
  → 把固件装入 CP 私有 SRAM
  → 写 CP 入口与 START
  → CP 从入口取指，初始化栈和固件数据
  → 固件报告 FW_READY
  → 驱动允许创建和启用队列

Doorbell 到达
  → 唤醒等待中的 CP
  → 固件通过 DMA 读取 Packet
  → 固件检查 Packet，写内部派发接口
  → 计算执行器运行 kernel
  → 固件处理完成事件并更新 Signal
```

实现时，需要先分清以下几项边界。

- **指令执行与队列策略：** QEMU C 代码实现指令、DMA 和设备接口；固件实现取包、验证和调度逻辑。如果固件只调用一个“处理整个 AQL 队列”的特殊指令，而实际策略仍全写在 QEMU C 代码中，就没有达到这次自定义固件的目标。
- **控制状态与计算状态：** CP 拥有独立寄存器和 PC，不能直接借用一个正在执行 kernel 的 lane。可以复用经过整理的指令运算辅助代码，但两类执行上下文必须分开。
- **固件工具链与指令覆盖：** 现有计算解释器只支持部分指令。要运行普通 C 固件，须按所选编译选项补齐启动代码、分支跳转、字节和半字访存等必需行为，并明确非法指令如何进入故障状态。
- **异步推进：** 每次事件只执行有限数量的 CP 指令，再保存 PC 并交还 QEMU。可以先用虚拟时钟定时器，每次最多执行例如 1000 条指令；等待事件时停止取指，由 Doorbell 或完成事件唤醒。这个数值是调试用预算，不是硬件周期模型。
- **地址与复位：** 32 位 CP 本地指针不限制 DMA 只能用 32 位地址。DMA 接口应保留完整 IOVA，并通过现有 PCI DMA 路径经过系统 IOMMU；复位需要取消后续事件并停止访问旧资源。

不能在一次 MMIO 回调里直接进入固件的永久循环，否则回调不会返回。计算执行器目前同步运行整个 kernel，也需要逐步改成可以保存进度、分段执行，才能满足运行中停止和状态查询要求。

普通 `qemu-system-aarch64` 构建按目标架构包含 CPU 实现，不能假定只创建一个 RISC-V CPU 对象就能在当前二进制里运行。设备内部解释器可以把第一版的改动限定在教学设备中；是否以后接入更完整的 CPU 模型，可以另行评估。

> **[SOURCE]** QEMU 教学仓库 `049ed3eb6ba06c3b464dcff8871fd4463a441569`：
>
> - [configs/targets/aarch64-softmmu.mak](https://github.com/hxfei-git/gpu-study-qemu/blob/049ed3eb6ba06c3b464dcff8871fd4463a441569/configs/targets/aarch64-softmmu.mak#L1-L2)（[1–2 行](https://github.com/hxfei-git/gpu-study-qemu/blob/049ed3eb6ba06c3b464dcff8871fd4463a441569/configs/targets/aarch64-softmmu.mak#L1-L2)）指定 ARM 目标
> - [meson.build](https://github.com/hxfei-git/gpu-study-qemu/blob/049ed3eb6ba06c3b464dcff8871fd4463a441569/meson.build#L4240-L4251)（[4240–4251 行](https://github.com/hxfei-git/gpu-study-qemu/blob/049ed3eb6ba06c3b464dcff8871fd4463a441569/meson.build#L4240-L4251)）展示按目标组织架构构建
> - [hw/gpgpu/gpgpu_dma.c](https://github.com/hxfei-git/gpu-study-qemu/blob/049ed3eb6ba06c3b464dcff8871fd4463a441569/hw/gpgpu/gpgpu_dma.c#L41-L65)（[41–65 行](https://github.com/hxfei-git/gpu-study-qemu/blob/049ed3eb6ba06c3b464dcff8871fd4463a441569/hw/gpgpu/gpgpu_dma.c#L41-L65)）使用 PCI DMA 访问接口并检查事务结果。[include/qemu/aio.h](https://github.com/hxfei-git/gpu-study-qemu/blob/049ed3eb6ba06c3b464dcff8871fd4463a441569/include/qemu/aio.h#L464-L471)（[464–471 行](https://github.com/hxfei-git/gpu-study-qemu/blob/049ed3eb6ba06c3b464dcff8871fd4463a441569/include/qemu/aio.h#L464-L471)）还提醒：自我重新调度的底半部回调可能立即再次执行，因此不能把它当作必然让出的固件无限循环。

**[DESIGN]** 最小验证先让固件计算 `20 + 22`，将 42 写入结果寄存器后停止；替换固件为 `20 + 23`，无需重新编译 QEMU 就得到 43。然后依次加入 C 固件、DMA、内部计算派发和 AQL 队列。这样每一步都能验证“正在执行固件指令”，而不是只验证设备回调返回了预设值。

共享 Signal 的原子递减还需要明确的原子服务。普通 DMA 读出数值再写回，不能在存在并发写入时替代原子递减；第一版若只支持单任务、单写者的 `1 → 0`，应继续标为教学完成语义。

## 8. Host 可见寄存器与控制核内部状态

### 8.1 固件、寄存器与内存协议共同组成接口

> **提问：** 之前通过 PCIe 的方式，如果增加类似于 CP 的规格，实际上还是增加寄存器对吧，然后寄存器和具体的操作对应起来。现在真的增加了一个 CP 核，甚至还有固件，那么就不需要增加寄存器了，走的是一些规定的协议，来确定操作吗？
>
> **追问：** 这个 CP 控制核的一些寄存器，可以通过 BAR 空间映射出去对吧？

**回答：** 可以通过 BAR 暴露控制核需要交给 Host 的寄存器。增加固件后，这些接口仍然需要，只是每个任务的详细内容可以放进内存队列，由固件读取。

```text
Host 驱动写 BAR 控制寄存器
  → 装载、启动、复位 CP，配置队列

应用写内存中的 AQL Packet
  → 描述要执行哪个 kernel、参数在哪里、完成后更新哪个 Signal

应用写 Doorbell 窗口
  → 通知设备检查队列

CP 固件读 Packet、写设备内部接口
  → 组织计算与完成处理
```

BAR 描述设备的地址窗口。映射窗口后，Host 访问某个偏移，QEMU 回调再读写对应状态。可以暴露 `CP_ENTRY`、`CP_CTRL`、`CP_STATUS`、`CP_RESULT` 这样的教学寄存器，也可以给固件装载提供地址与数据窗口。上述名称是实验拟议名称，不是 AMD 寄存器。

控制核的通用寄存器、当前 PC 和内部临时状态可以保留在设备内部。只有调试或管理确有需要的部分才映射出去。Host 能操作启动寄存器，与 Host 能逐个访问控制核所有寄存器，是两个不同的设计选择。

### 8.2 AMD 寄存器分别控制启动、队列和诊断状态

> **提问：** 你先把 AMD 的 CP 的相关寄存器给我看下。
>
> **追问：** 其实我还是有些不了解这些寄存器的含义，做了什么，怎么使用。

**回答：** 可以沿“启动固件 → 准备队列 → 运行与诊断”来读这些寄存器。先看各组怎样配合，第 9 节再按实际顺序说明 Host 写哪些值。

```text
MEC 运行控制
  CP_MEC_CNTL → 停止／解除停止、复位相关控制

固件访问配置（直接加载分支）
  CP_CPC_IC_BASE_* → 固件指令存储的访问位置与属性
  CP_MEC_ME1_UCODE_ADDR / DATA → 微码相关装载端口

队列槽位配置
  GRBM_GFX_CNTL → 选择要访问的引擎、管线和队列槽位
  CP_MQD_* → 内存 MQD 的位置及访问属性
  CP_HQD_* → 当前所选槽位的 Ring、索引、Doorbell、VMID 和状态

观察执行情况
  CP_CPC_STATUS 等 → 查看忙碌或停滞状态
  CP_MEC1_INSTR_PNTR → 指令位置相关诊断字段
```

以下表格供集中查寄存器名。偏移来自 GC 9.4.3 头文件，单位是 DWORD；`BASE_IDX` 选择 GC 寄存器段，不能把它当作 BAR 编号。

| 寄存器 | 头文件偏移 | BASE_IDX | 本文关心的用途 |
| --- | --- | --- | --- |
| `GRBM_GFX_CNTL` | `0x0022` | 0 | 选择寄存器窗口对应的引擎、管线与队列 |
| `CP_CPC_STATUS` | `0x0084` | 0 | 读取命令处理状态 |
| `CP_MEC_CNTL` | `0x008d` | 0 | 控制 MEC 停止、复位等状态 |
| `CP_MEC1_INSTR_PNTR` | `0x01a8` | 0 | 指令位置相关诊断 |
| `CP_CPC_IC_BASE_LO / HI` | `0x10b9 / 0x10ba` | 0 | 固件指令存储基址配置 |
| `CP_CPC_IC_BASE_CNTL` | `0x10bb` | 0 | 固件取指的 VMID、缓存属性 |
| `CP_MQD_BASE_ADDR / HI` | `0x1245 / 0x1246` | 0 | 所选槽位对应的 MQD 地址 |
| `CP_HQD_ACTIVE` | `0x1247` | 0 | 所选队列槽位是否激活 |
| `CP_HQD_VMID` | `0x1248` | 0 | 队列使用的地址空间标识 |
| `CP_HQD_PQ_BASE / HI` | `0x124d / 0x124e` | 0 | Ring 基址的编码 |
| `CP_HQD_PQ_RPTR` | `0x124f` | 0 | 队列消费进度 |
| `CP_HQD_PQ_RPTR_REPORT_ADDR / HI` | `0x1250 / 0x1251` | 0 | 读指针回报地址 |
| `CP_HQD_PQ_WPTR_POLL_ADDR / HI` | `0x1252 / 0x1253` | 0 | 写指针轮询地址 |
| `CP_HQD_PQ_DOORBELL_CONTROL` | `0x1254` | 0 | Doorbell 关联及使能 |
| `CP_HQD_PQ_CONTROL` | `0x1256` | 0 | Ring 容量和队列模式 |
| `CP_HQD_DEQUEUE_REQUEST` | `0x125d` | 0 | 发起所选队列的卸载请求 |
| `CP_HQD_PQ_WPTR_LO / HI` | `0x127b / 0x127c` | 0 | 队列写指针 |
| `CP_MEC_ME1_UCODE_ADDR / DATA` | `0x581a / 0x581b` | 1 | 微码装载地址／数据端口 |

在直接 MMIO 访问中，还要加上实际 GC 实例的寄存器段基址，再将 DWORD 偏移乘 4，才能得到字节地址。读取某条队列的 `CP_HQD_*` 前还要选择队列窗口。仅有上表中的数值，不足以直接对 BAR 相同偏移进行访问。

MI300X 的驱动寄存器 MMIO 与 Doorbell 使用不同窗口：这里对应 BAR5 与 BAR2。教学设备的 BAR 分配应按自身代码解释，不复制 AMD 的 BAR 编号作为既有事实。

> **[SOURCE]** Linux `248951ddc14de84de3910f9b13f51491a8cd91df`：
>
> - [drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_offset.h](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_offset.h#L76-L142)（[76–142 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_offset.h#L76-L142)）、[drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_offset.h](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_offset.h#L3042-L3046)（[3042–3046 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_offset.h#L3042-L3046)）、[drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_offset.h](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_offset.h#L3282-L3397)（[3282–3397 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_offset.h#L3282-L3397)）、[drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_offset.h](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_offset.h#L7100-L7107)（[7100–7107 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_offset.h#L7100-L7107)）给出寄存器偏移
> - [drivers/gpu/drm/amd/amdgpu/soc15_common.h](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/soc15_common.h#L27-L36)（[27–36 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/soc15_common.h#L27-L36)）组合段基址与寄存器偏移
> - [drivers/gpu/drm/amd/amdgpu/amdgpu_reg_access.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_reg_access.c#L494-L510)（[494–510 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_reg_access.c#L494-L510)）将 DWORD 偏移转换为 MMIO 字节偏移
> - [drivers/gpu/drm/amd/amdgpu/amdgpu_device.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_device.c#L3846-L3859)（[3846–3859 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_device.c#L3846-L3859)）选择寄存器 BAR
> - [drivers/gpu/drm/amd/amdgpu/amdgpu_doorbell_mgr.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_doorbell_mgr.c#L204-L211)（[204–211 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_doorbell_mgr.c#L204-L211)）初始化 Doorbell 窗口。

### 8.3 持续执行依赖控制核的内部 PC 与指令状态

> **提问：** 很奇怪呀，`CP_*` 的一系列寄存器，并不能体现 CP 作为一个持续运行的核，有些部分感觉都是只读的，有些不理解。

**回答：** Host 可见的 `CP_*` 是整个命令处理子系统对外提供的配置与观察接口。一个控制核持续执行程序，依赖内部 PC、寄存器、取指与执行逻辑；这些状态不必完整映射给 Host。

```text
内部控制程序
  PC 指向固件下一条指令
    → 取指、译码、执行
    → 修改内部寄存器和 PC
    → 继续执行，或等待事件

Host 观察接口
  STATUS ← 由设备根据内部运行情况更新
  Host 读取 STATUS，了解当前状态
```

一个寄存器对 Host 只读，表示 Host 不能通过这个接口写它。设备仍然可以在内部更新它。忙碌状态变成空闲，也可能只是固件或硬件正在等待新工作，不能据此否认内部控制核存在。

`CP_MEC_CNTL` 控制 MEC 是否允许运行；`CP_HQD_ACTIVE` 标记某个队列槽位的激活状态。两者管理的对象不同。`CP_CPC_IC_BASE_*` 是固件存储访问配置，也不能直接解释为 CPU 常见的复位入口 PC。

**[BOUNDARY]** `CP_MEC1_INSTR_PNTR` 提供指令位置相关字段，不能只看名字就声称 Host 可以用它设置启动 PC。公开寄存器名和驱动使用方式，也不足以还原 MEC 的完整内部寄存器架构。

> **[SOURCE]** Linux `248951ddc14de84de3910f9b13f51491a8cd91df`：
>
> - [drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_sh_mask.h](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_sh_mask.h#L766-L787)（[766–787 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_sh_mask.h#L766-L787)）定义 MEC 的停止、复位等控制位
> - [drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_sh_mask.h](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_sh_mask.h#L1056-L1057)（[1056–1057 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_sh_mask.h#L1056-L1057)）定义指令位置字段
> - [drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L67-L98)（[67–98 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L67-L98)）把相关寄存器用于状态采集。

## 9. AMD 的固件启动、KIQ 配置与后续提交

### 9.1 从固件加载到管理命令执行的顺序

> **提问：** 这样吧，你直接把 AMD 的流程给我，包括几部分：1. 启动 CP，怎么配的寄存器；2. 初始化队列，怎么配的 CP 寄存器；3. 运行时，需要配 CP 吗？

**回答：** 以下采用 MI300X、GC 9.4.3、首次正常初始化、PSP 加载固件、未启用 MES 的流程。用户 AQL 队列按 KFD HWS 路径说明。为读清顺序，先看一个 GC/XCC 实例；驱动会处理相应实例，图中不推导整卡队列数量。

```text
Host 驱动请求并准备 MEC 固件
  → PSP 固件加载流程
  → 进入该实例的 CP 恢复流程
      ① 写 CP_MEC_CNTL，使 MEC 停止
      ② Host 直接配置 KIQ 的 HQD，置 ACTIVE = 1
      ③ 写 CP_MEC_CNTL = 0，允许 MEC 运行
      ④ 准备 KCQ 的 MQD，通过 KIQ 发 MAP_QUEUES
           → MEC 处理管理命令，建立目标队列状态
      ⑤ 执行队列测试

之后 KFD 建立 HIQ 和用户队列
  → 通过管理命令与调度固件使用户队列驻留
  → 应用写 AQL Packet 和 Doorbell，提交计算任务
```

这里必须保留源码中的顺序：`kcq_resume()` 先允许 MEC 运行，再初始化 KCQ 的内存 MQD 并通过 KIQ 映射。不能写成“所有队列都直接配好寄存器，再统一启动 MEC”。

### 9.2 固件装载与 MEC 启停寄存器

在当前代码的停机函数中，Host 写 `CP_MEC_CNTL` 的停止、管线复位和指令缓存失效位；这些位合起来是 `0x503f_0010`。允许运行时，该函数向 `CP_MEC_CNTL` 写 0。这里记录的是这个函数的实际取值，不是所有 AMD 硬件通用的复位值。

主线采用 PSP 加载，所以 `cp_resume()` 不再执行非 PSP 的直接微码装载函数。若阅读直接加载分支，会看到另外一组操作：

```text
Host 先停止 MEC
  → CP_CPC_IC_BASE_CNTL：配置 VMID 与缓存属性
  → CP_CPC_IC_BASE_LO / HI：配置固件指令存储基址
  → CP_MEC_ME1_UCODE_ADDR：选择跳转表装载位置
  → CP_MEC_ME1_UCODE_DATA：逐项写入固件中的跳转表
  → 写入相应版本信息
```

此处分配好的固件缓冲区与装载端口共同参与启动准备。`UCODE_DATA` 循环读取的是固件头中 `jt_offset`、`jt_size` 指定的跳转表范围，不能简化为“把整个固件都逐字写入这个寄存器”。PSP 路径的内部硬件写入也不能按这段 Host 代码自行补全。

> **[SOURCE]** Linux `248951ddc14de84de3910f9b13f51491a8cd91df`：
>
> - [drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L1731-L1749)（[1731–1749 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L1731-L1749)）启停 MEC
> - [drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L1752-L1797)（[1752–1797 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L1752-L1797)）是直接加载分支
> - [drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L2226-L2278)（[2226–2278 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L2226-L2278)）证明 KIQ、MEC 启动与 KCQ 初始化的实际顺序。

### 9.3 Host 直接为 KIQ 建立初始硬件状态

> **提问：** 等一下，第一次这些寄存器：`CP_MQD_BASE_ADDR / HI`、`CP_MQD_CONTROL`、`CP_HQD_PQ_BASE / HI`、`CP_HQD_PQ_CONTROL`、读写指针地址、Doorbell 配置、`CP_HQD_VMID`、`CP_HQD_ACTIVE`，是为了创建 KIQ 的状态，Host 配置的对吗？

**回答：** 是。在本节的首次初始化路径中，Host 驱动先准备 KIQ 的内存 MQD，再选择 KIQ 的硬件槽位，把 MQD 中的配置写入对应寄存器。此时 MEC 仍处于停止状态。

下面保留这组配置及其含义。箭头表示 Host 写入；这是按用途整理的清单，完整函数还包含 EOP、轮询开关及旧队列清理等步骤。

```text
CP_MQD_BASE_ADDR / HI
    ← KIQ 的 MQD 地址

CP_MQD_CONTROL
    ← MQD 访问配置，本路径 VMID 为 0

CP_HQD_PQ_BASE / HI
    ← KIQ Ring 地址右移 8 位后的编码

CP_HQD_PQ_CONTROL
    ← Ring 容量、内核队列模式等配置

CP_HQD_PQ_RPTR_REPORT_ADDR / HI
    ← 读指针回报到哪块内存

CP_HQD_PQ_WPTR_POLL_ADDR / HI
    ← 如启用轮询，从哪块内存读取写指针

CP_MEC_DOORBELL_RANGE_LOWER / UPPER
    ← MEC 接收的 Doorbell 范围；这是 MEC 范围配置

CP_HQD_PQ_DOORBELL_CONTROL
    ← KIQ 的 Doorbell 编号、使能等配置

CP_HQD_PQ_WPTR_LO / HI
    ← 初始写指针

CP_HQD_VMID
    ← 0，供这条驱动内部队列使用

CP_HQD_ACTIVE
    ← 1，激活所选 KIQ 硬件队列槽位
```

这些地址的编码不能一概右移 8 位。Ring 基址按该寄存器要求编码；MQD 基址和索引回报地址使用各自的地址字段。写指针轮询地址即使已经配置，也要在轮询使能时才按该方式使用。

实际函数先关闭写指针轮询，设置 EOP 缓冲和 Doorbell 配置；发现原槽位仍 ACTIVE 时，才发卸载请求并等待清理。随后写入本次 MQD、Ring、指针地址、Doorbell、VMID 等状态，最后激活队列。在使用 Doorbell 时，还设置对应使能。外围代码通过 `GRBM_GFX_CNTL` 选择 KIQ 槽位，并在锁保护下完成配置。

> **[SOURCE]** Linux `248951ddc14de84de3910f9b13f51491a8cd91df`：
>
> - [drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L1961-L2072)（[1961–2072 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L1961-L2072)）是完整的 KIQ 寄存器初始化函数
> - [drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L2115-L2159)（[2115–2159 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L2115-L2159)）说明正常初始化时准备 MQD、选择窗口和调用该函数的顺序。

### 9.4 KIQ 的激活与 MEC 的运行分别发生

> **提问：** 我没懂 KIQ 和 MEC 的区别，为什么要配置好 KIQ，才去启动 MEC 呢？

**回答：** KIQ 是存放管理命令的队列，MEC 是执行命令处理固件的引擎。驱动先给 MEC 准备好一条可以接收管理命令的队列，再让 MEC 运行，后续便能通过这条队列管理其他队列。

```text
Host 先准备 KIQ Ring 和 HQD
  保存 Ring 在哪、Doorbell 是哪个、读写到哪里
                  │
                  ▼
Host 解除 MEC 停止状态
                  │
                  ▼
MEC 执行固件，读取 KIQ 中已提交的管理命令
  例如 MAP_QUEUES → 建立另一条队列的硬件状态
```

**[INFERENCE]** “先准备命令入口，再启动处理引擎”有助于理解该驱动的初始化安排。这里证明的是代码采用这个顺序，不能扩展为“MEC 在任何情况下都必须依赖 KIQ 才能执行第一条固件指令”。

> **提问：** 等一下，如果完成第二步，并且将队列设置为激活状态，那么硬件真的在运行吗？还是等 MEC 启动后才运行？
>
> **追问：** 也就是说，一定要等 MEC 启动后，KIQ 才能真正地处理一些命令吗？

**回答：** 在上述顺序中，第二步只完成 KIQ 的状态配置与激活。MEC 仍停止，所以不会因为 `CP_HQD_ACTIVE = 1` 就开始执行 KIQ 中的命令。第三步允许 MEC 运行后，MEC 才能执行固件，并在 KIQ 有有效命令时处理这些命令。

```text
时刻 A：KIQ ACTIVE = 1，MEC 停止
        KIQ 状态已准备，MEC 尚未处理其中的命令

时刻 B：KIQ ACTIVE = 1，MEC 允许运行
        MEC 可以处理 KIQ；若没有新命令，则等待
```

Host 能读写寄存器，说明相应设备接口在响应。队列槽位 ACTIVE，说明队列具备激活状态。MEC 的固件是否运行、队列当前是否有工作，还要分别看引擎状态和队列进度。

### 9.5 后续映射队列：先写 Ring，再敲 KIQ Doorbell

> **提问：** 第四步，你写得太抽象了，我看不懂你是什么意思，写的是寄存器还是怎么操作的，你得给我讲清楚。

**回答：** 第四步的主要动作是：Host 把管理命令写入 KIQ Ring 的内存，再写 KIQ 的 Doorbell 通知设备。它不等同于再次逐个写目标队列的 `CP_HQD_*` 寄存器。

假设驱动要建立一条新的内部计算队列 Q，已经分配 Q 的 Ring、MQD 和写指针回报内存，KIQ 也已经可用。

```text
Host 填写 Q 的 MQD（普通内存写入）
  包括 Q 的 Ring 地址、容量、Doorbell 等
             │
             ▼
Host 向 KIQ Ring 写 MAP_QUEUES 命令（普通内存写入）
  命令里带 Q 的 MQD 地址、写指针地址、目标槽位和 Doorbell 编号
             │
             ▼
Host 提交 KIQ Ring
  填充对齐 → 内存屏障 → 更新 KIQ 写指针回报内存
             │
             ▼
Host 写 KIQ 的 Doorbell（设备窗口写入）
  通知的是 KIQ 自己的新写指针
             │
             ▼
MEC 读取 KIQ 中的 MAP_QUEUES
  → 设备根据 Q 的 MQD 建立 Q 的硬件队列状态
```

该路径的 `MAP_QUEUES` 一共写入 7 个 DWORD。第一个是命令头，后面依次携带目标队列选择信息、Q 的 Doorbell 编号、Q 的 MQD 地址低／高位、Q 的写指针地址低／高位。

“Q 的 Doorbell 编号放在命令里”与“Host 敲 KIQ 的 Doorbell 提交这个命令”是两件事。前者告诉设备以后怎样识别 Q 的通知，后者告诉设备现在有新的 KIQ 管理命令。

`amdgpu_ring_write()` 实际把一个 DWORD 写入 Ring 的 CPU 映射，并推进软件 `wptr`。`amdgpu_ring_commit()` 做填充对齐和内存屏障后调用写指针提交函数。GC 9.4.3 的这条 Doorbell 路径先更新写指针回报内存，再进行 64 位 Doorbell 写入。

KIQ 的对齐要求还会影响最终写指针。不能仅因 `MAP_QUEUES` 有 7 个 DWORD，就断定本次 Doorbell 一定写 7；应使用提交、填充之后的 KIQ 写指针。这个写指针按 PM4 DWORD 计数，与后文 AQL 的 Packet ID 分开理解。

**[BOUNDARY]** Host 驱动源码能证明它发送了哪些管理命令、携带哪些地址。设备内部加载 HQD 的具体固件指令及每个寄存器的内部写入时刻，不在这些 Host 函数中公开。

> **[SOURCE]** Linux `248951ddc14de84de3910f9b13f51491a8cd91df`：
>
> - [drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L199-L228)（[199–228 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L199-L228)）构造 7 DWORD 的映射命令
> - [drivers/gpu/drm/amd/amdgpu/amdgpu_gfx.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_gfx.c#L711-L770)（[711–770 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_gfx.c#L711-L770)）经 KIQ 提交 KCQ 映射
> - [drivers/gpu/drm/amd/amdgpu/amdgpu_ring.h](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_ring.h#L494-L499)（[494–499 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_ring.h#L494-L499)）写 Ring 内存
> - [drivers/gpu/drm/amd/amdgpu/amdgpu_ring.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_ring.c#L169-L189)（[169–189 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_ring.c#L169-L189)）提交 Ring
> - [drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L3025-L3036)（[3025–3036 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L3025-L3036)）更新写指针并写 Doorbell
> - [drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L4846-L4853)（[4846–4853 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L4846-L4853)）给出 KIQ 对齐及写指针函数。

### 9.6 用户 AQL 队列经过 KFD 的管理路径

> **提问：** 那么后续如果为了创建一个新的 Queue，Host 还需要配置这些状态吗？

**回答：** 新 Queue 仍需要自己的 Ring、索引、Doorbell 和地址空间状态。Host 仍参与创建，但正常管理路径可以由 Host 准备内存描述并发送命令，再由设备建立驻留状态，无须像第一次建立 KIQ 那样逐项直接写 HQD。

对于第 9.5 节的驱动内部计算队列，Host 通过 KIQ 提交 `MAP_QUEUES`。对于用户 AQL 队列，本文采用的 KFD HWS 路径还包含 HIQ 和运行列表：

```text
先建立 KFD 的 HIQ
  Host 准备 HIQ MQD → 通过 KIQ 的 MAP_QUEUES 映射 HIQ

再建立用户 AQL 队列 Q
  Host 准备 Q 的 MQD
    → 在 runlist IB 中写 MAP_PROCESS、MAP_QUEUES
    → 向 HIQ 写指向这个 IB 的 RUN_LIST 命令
    → 提交 HIQ
    → 调度固件处理运行列表
    → Q 驻留时，把相应描述装入可用 HQD 槽位
```

`RUN_LIST` 在 HIQ 中，`MAP_PROCESS` 与 `MAP_QUEUES` 在它引用的 IB 中。不要把这三个命令描述为全部直接顺序写入 HIQ。

以 64 个 64 字节 AQL 包组成的 4096 字节 Ring 为例，MQD 的队列容量字段按 DWORD 数编码：`log2(4096 / 4) - 1 = 9`。Ring 基址按要求右移 8 位保存；索引地址和 Doorbell 则写进各自字段。这些是内存 MQD 的准备动作。

普通用户队列的 MQD 初始化不能照搬 KIQ 的 `ACTIVE = 1`。在本路径中，使队列驻留属于后续管理命令和固件调度过程。用户队列的最终 VMID 也不能从 KIQ 的 VMID 0 推出；进程映射与 HWS 的地址空间资源管理参与后续配置。

驱动也保留直接加载 HQD 的实现，因此“有 HWS”不能推导为“Host 永远失去写 HQD 的能力”。解释某次创建时，应先确认调用的是哪条路径。

> **[SOURCE]** Linux `248951ddc14de84de3910f9b13f51491a8cd91df`：
>
> - [drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gfx_v9.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gfx_v9.c#L301-L350)（[301–350 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gfx_v9.c#L301-L350)）通过 KIQ 映射 HIQ
> - [drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c#L271-L338)（[271–338 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c#L271-L338)）填写普通队列 MQD
> - [drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c#L727-L791)（[727–791 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c#L727-L791)）处理 GC 9.4.3 的实例化描述
> - [drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c#L2179-L2197)（[2179–2197 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c#L2179-L2197)）创建队列并进入调度
> - [drivers/gpu/drm/amd/amdkfd/kfd_packet_manager.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager.c#L181-L241)（[181–241 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager.c#L181-L241)）构建运行列表 IB
> - [drivers/gpu/drm/amd/amdkfd/kfd_packet_manager.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager.c#L359-L386)（[359–386 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager.c#L359-L386)）向管理队列提交指向 IB 的命令。另见 [drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gc_9_4_3.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gc_9_4_3.c#L284-L355)（[284–355 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gc_9_4_3.c#L284-L355)）的直接 HQD 加载函数，须与这里的 HWS 主线分开。

### 9.7 正常运行时发布 Packet，不逐任务重配 HQD

队列已经建立并正常驻留后，应用提交一个 kernel 的主线如下。例子采用普通 64 位硬件 Doorbell 路径，Signal 初值为 1。

```text
运行时预留一个槽位
  取到旧 write_index = 37，预留进度推进到 38
    → 等待 Ring 有空间
    → 写入第 37 个 Packet 的内容，尚未发布有效 Header
    → 以 release 语义发布有效 Header
    → 向该 AQL 队列的 Doorbell 写 Packet ID 37

设备读取已发布的 Packet
  → 组织并执行 kernel
  → 完成规定的 release 操作
  → 原子递减 completion Signal：1 → 0

Host 以 acquire 语义观察 Signal
  → 确认完成后使用计算结果
```

这里预留后的 `write_index = 38`、通知的 Packet ID 37、设备的 Ring 消费进度分别承担不同作用。应用不能仅靠 `rptr` 前进判断 kernel 已经完成。

运行过程中，驱动仍可能因为队列创建、销毁、调度、异常或复位执行管理操作。准确说法是：正常逐任务提交通过 Packet 与 Doorbell 完成，不需要为每个 kernel 重写一遍 `CP_HQD_*`。

> **[SOURCE]** ROCr `ba56a24c6132c5d195686ae4adf969ca1222fbba`：
>
> - [runtime/hsa-runtime/core/runtime/amd_blit_kernel.cpp](https://github.com/ROCm/rocr-runtime/blob/ba56a24c6132c5d195686ae4adf969ca1222fbba/runtime/hsa-runtime/core/runtime/amd_blit_kernel.cpp#L844-L901)（[844–901 行](https://github.com/ROCm/rocr-runtime/blob/ba56a24c6132c5d195686ae4adf969ca1222fbba/runtime/hsa-runtime/core/runtime/amd_blit_kernel.cpp#L844-L901)）展示预留、发布和 Packet ID 通知
> - [runtime/hsa-runtime/core/runtime/amd_aql_queue.cpp](https://github.com/ROCm/rocr-runtime/blob/ba56a24c6132c5d195686ae4adf969ca1222fbba/runtime/hsa-runtime/core/runtime/amd_aql_queue.cpp#L468-L482)（[468–482 行](https://github.com/ROCm/rocr-runtime/blob/ba56a24c6132c5d195686ae4adf969ca1222fbba/runtime/hsa-runtime/core/runtime/amd_aql_queue.cpp#L468-L482)）包含普通 Doorbell 写路径及 release 接口。

> **[SPEC]** [HSA System Architecture 1.2](https://hsafoundation.com/wp-content/uploads/2021/02/HSA-SysArch-1.2.pdf)，**2018-05-02**，§2.8.3、原文第 19～21 页区分包槽位与任务完成；§2.9.1～2.9.2、原文第 25～27 页规定派发的内存同步及完成 Signal 更新关系。

## 10. 多条 Queue 的寄存器状态与访问窗口

### 10.1 HQD 保存某个驻留队列的状态

> **提问：** 也就是说，这些寄存器的状态，是体现当前 Queue 的状态对吗？

**回答：** 对 `CP_HQD_*` 这组队列寄存器，可以这样理解：它们描述当前所选硬件槽位中的驻留队列，包括 Ring 在哪里、使用哪个 Doorbell、读写到了哪里、是否激活。

“当前”指 Host 寄存器访问窗口选中的槽位，不能直接理解为整个 GPU 此刻唯一正在执行的队列。Host 选择一个窗口用于查看或配置，也不表示命令处理引擎接下来只能调度这个队列。

前面的清单还混有 MEC 范围寄存器。`CP_MEC_CNTL` 控制引擎，`CP_MEC_DOORBELL_RANGE_LOWER / UPPER` 配置 MEC 的 Doorbell 范围，不能把它们也说成每个 Queue 都独占的一份 HQD 状态。

### 10.2 MEC 启动后，Host 的访问权限不会统一变为只读

> **提问：** 那么，会不会存在当 MEC 启动之后，这些寄存器的状态，都是由 MEC 配置，Host 只读呢？

**回答：** 正常队列运行时，确实有大量状态由设备维护。例如 Host 发送映射命令后，设备建立目标 HQD；队列继续消费时，设备更新进度。采用这种分工，可以避免 Host 为每次执行反复配置寄存器。

但“运行时通常由设备管理”是操作分工，不是所有寄存器在 MEC 启动后都统一变成 Host 只读。Host 驱动仍保留初始化、受控卸载、故障恢复和复位等操作。具体寄存器是否可写、在哪个阶段可以写，要分别看接口定义与使用条件。

设备维护状态也不必全部由 MEC 固件执行一条写寄存器指令来完成；部分进度可能由配套硬件逻辑更新。Host 驱动源码通常不足以区分每次内部更新来自哪一个微操作。

```text
正常提交
  Host 发布 Packet → 设备更新消费和完成进度

受控管理
  Host 请求停止／卸载 → 等待完成确认
    → 才能按相应路径重新配置或释放资源
```

因此驱动不应在活动队列执行过程中随意改写 Ring 基址或 VMID。仍然有写接口，与可以在任意时刻安全写入，是两回事。

> **[SOURCE]** Linux `248951ddc14de84de3910f9b13f51491a8cd91df`：
>
> - [drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gc_9_4_3.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gc_9_4_3.c#L284-L355)（[284–355 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gc_9_4_3.c#L284-L355)）提供 Host 写 HQD 的加载路径
> - [drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L2075-L2113)（[2075–2113 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L2075-L2113)）发起卸载并等待状态变化
> - [drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c#L2574-L2605)（[2574–2605 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c#L2574-L2605)）展示 HWS 卸载后的完成与失败检查。

### 10.3 同一组寄存器地址访问不同的队列槽位

> **提问：** 而且我不理解，这组寄存器，每个有很多吗？怎么能够表示那么多 Queue 呢？

**回答：** 硬件有多个队列槽位，每个槽位需要保留自己的队列状态。Host 不必为每个槽位使用一套不同的 `CP_HQD_*` 地址；驱动先通过选择寄存器指定槽位，再通过同一组寄存器地址访问被选中的那份状态。

以下只举同一实例内两个槽位的逻辑例子，不表示 MI300X 只有两个槽位，也不表示内部状态一定用怎样的物理电路存储。

```text
设备保留的队列状态
  槽位 0：KIQ，Ring 基址 A，读指针 12，ACTIVE = 1
  槽位 1：队列 Q，Ring 基址 B，读指针 5，ACTIVE = 1

Host 写 GRBM_GFX_CNTL，选择槽位 0
  读 CP_HQD_PQ_BASE → 得到 A 对应的编码
  读 CP_HQD_PQ_RPTR → 得到 12

Host 写 GRBM_GFX_CNTL，选择槽位 1
  读同一个 CP_HQD_PQ_BASE 地址 → 得到 B 对应的编码
  读同一个 CP_HQD_PQ_RPTR 地址 → 得到 5
```

切换窗口只改变 Host 接下来访问哪份状态。槽位 0 的内容仍然保留，不会因为 Host 切到槽位 1 就消失。

`GRBM_GFX_CNTL` 的选择包含 `MEID`、`PIPEID`、`QUEUEID`，并有 `VMID` 字段。驱动按目标实例选择寄存器段，再选择具体引擎、管线和队列；访问时用锁保护“选择窗口 → 读写寄存器 → 恢复选择”的过程，避免其他执行路径中途改掉选择。

> **[SOURCE]** Linux `248951ddc14de84de3910f9b13f51491a8cd91df`：
>
> - [drivers/gpu/drm/amd/amdgpu/soc15.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/soc15.c#L363-L372)（[363–372 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/soc15.c#L363-L372)）将选择字段写入 `GRBM_GFX_CNTL`
> - [drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gfx_v9.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gfx_v9.c#L50-L70)（[50–70 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gfx_v9.c#L50-L70)）在锁保护下选择和释放队列窗口
> - [drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_sh_mask.h](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_sh_mask.h#L384-L391)（[384–391 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_sh_mask.h#L384-L391)）定义窗口选择字段。

### 10.4 内存 MQD 使软件队列数量不必等于驻留槽位数

上一节解决的是“多个硬件槽位怎样通过同一组地址访问”。还有另一层：软件可以建立比同时可用硬件槽位更多的队列，因此需要保存未驻留队列的描述。

```text
内存中的逻辑队列描述
  MQD_A → Ring A、指针、Doorbell、其他队列状态
  MQD_B → Ring B、指针、Doorbell、其他队列状态
  MQD_C → Ring C、指针、Doorbell、其他队列状态

有限的硬件 HQD 槽位
  槽位 0 当前装入 A 的状态
  槽位 1 当前装入 B 的状态

调度发生切换
  按规定卸载、保存 B 的必要状态
    → 槽位 1 装入 C 的状态
    → 设备可以从 C 的队列继续取包
```

这个示意只说明内存描述与驻留状态之间的关系。具体可创建队列数量、每个进程限制、可用槽位和调度策略，还取决于驱动资源与配置，不能由示意中的三个 MQD 推出整卡数量。

MQD 保存队列在内存中的描述；HQD 是队列驻留时设备正在使用的状态。选窗口用于访问某个 HQD，调度切换用于改变哪个逻辑队列驻留，两种动作应分别理解。

> **[SOURCE]** Linux `248951ddc14de84de3910f9b13f51491a8cd91df`：
>
> - [drivers/gpu/drm/amd/amdkfd/kfd_priv.h](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_priv.h#L142-L146)（[142–146 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_priv.h#L142-L146)）说明 HWS 与 MQD 装入 HQD 的关系
> - [drivers/gpu/drm/amd/amdkfd/kfd_packet_manager_v9.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager_v9.c#L227-L296)（[227–296 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_packet_manager_v9.c#L227-L296)）构造交给硬件调度器的队列映射描述。

**[DESIGN]** 教学第一版只有一条 Queue，可以先保存一份队列状态，不必立即复制 AMD 的窗口选择和多队列调度。独立固件控制核仍然可以在这份状态上完成取包、派发与完成处理。以后增加多个硬件槽位时，再定义选择窗口或每槽位独立地址，并明确 MQD 装入、卸载与状态保存协议。
