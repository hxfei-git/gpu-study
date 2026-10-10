# QEMU GPGPU 四阶段实验大纲

| 缩写 | 英文全称 | 中文含义 |
| --- | --- | --- |
| QEMU | Quick Emulator | 仿真与虚拟化工具 |
| GPU | Graphics Processing Unit | 图形处理器 |
| GPGPU | General-Purpose Computing on Graphics Processing Units | 利用 GPU 进行通用计算；本项目也用于指代教学计算设备 |
| CUDA | Compute Unified Device Architecture | 统一计算设备架构；此处仅用于原实验题名 |
| KFD | Kernel Fusion Driver | AMD GPU 计算相关内核驱动组件 |
| ROCm | Radeon Open Compute | AMD GPU 计算软件平台 |
| ROCr | ROCm Runtime | AMD 的 HSA 用户态运行时 |
| CP | Command Processor | 命令处理器 |
| DRM | Direct Rendering Manager | Linux 图形设备内核框架 |
| GEM | Graphics Execution Manager | DRM 的图形内存对象管理框架 |
| GPUVA | GPU Virtual Address | GPU 虚拟地址 |
| MMU | Memory Management Unit | 内存管理单元 |
| VMID | Virtual Memory Identifier | GPU 硬件地址空间标识 |
| TLB | Translation Lookaside Buffer | 地址翻译缓存 |
| AQL | Architected Queuing Language | HSA 定义的队列包格式与提交协议 |
| HSA | Heterogeneous System Architecture | 异构系统架构 |
| CPU | Central Processing Unit | 中央处理器 |
| ARM64 | Arm 64-bit Architecture | Arm 64 位架构；本实验运行 Linux 的处理器架构 |
| RV32 | 32-bit RISC-V | 本实验计算 kernel 使用的 32 位 RISC-V 指令集 |
| API | Application Programming Interface | 应用编程接口 |
| ABI | Application Binary Interface | 应用二进制接口；本文用于约定软件与设备之间的数据布局 |
| RAM | Random Access Memory | 随机存取存储器；本文的系统 RAM 指 Linux 客体内存 |
| VRAM | Video RAM | 设备显存；本实验由 QEMU 提供后备存储 |
| DMA | Direct Memory Access | 直接内存访问 |
| IOMMU | Input/Output Memory Management Unit | 输入输出内存管理单元 |
| SMMUv3 | System Memory Management Unit version 3 | Arm 系统内存管理单元第三版 |
| IOVA | I/O Virtual Address | 设备经系统 IOMMU 访问内存时使用的地址 |
| PCI | Peripheral Component Interconnect | 外设互连总线 |
| BAR | Base Address Register | PCI 基址寄存器；用于描述设备资源窗口 |
| MMIO | Memory-Mapped I/O | 内存映射输入输出 |
| MSI-X | Message Signaled Interrupts Extended | 扩展消息中断 |
| H2D | Host to Device | 主机到设备的数据搬运 |
| D2H | Device to Host | 设备到主机的数据搬运 |
| GPUVM | GPU Virtual Memory | GPU 虚拟内存及地址空间管理 |
| PC | Program Counter | 程序计数器；保存执行器的指令位置 |
| ReLU | Rectified Linear Unit | 修正线性单元；本实验的计算示例之一 |
| KiB | Kibibyte | 二进制千字节，1 KiB 为 1024 字节 |
| ioctl | Input/Output Control | 用户态向驱动发送控制请求的系统调用 |
| wptr | Write Pointer | 本规格中的队列发布索引，不是内存地址 |
| rptr | Read Pointer | 本规格中的队列消费索引，不是内存地址 |

## 1. 当前进度与实验范围

根据用户反馈，前 10 个基础实验和第一阶段“进阶实验一：设计类 CUDA 的 GPGPU 软件栈”已完成，并已搭配 A57、支持 SMMUv3 系统 IOMMU。第一阶段成果继续保留，当前进入第二阶段：用户 AQL Queue、Doorbell、CP 与 Signal。

第二阶段目前完成的是范围与 v1 规格约定，尚未记录实现完成或运行验收通过。第一阶段的实现与历史验证记录见 [软件栈说明](<./gpu-study-qemu/software/gpgpu/README.md>)；本大纲中的设计取值不作为已有设备能力。

本目录已有 `QEMU_2026_讲义.html`、`QEMU_2026_实验.html`、`QEMU_2026_GPGPU_适配.html`，以及 `gpu-study-qemu` 源码目录。后续实验沿用这些材料和代码。

**[DESIGN] 仓库与分支约束：** 实验子仓库为 [hxfei-git/gpu-study-qemu](https://github.com/hxfei-git/gpu-study-qemu)，本地目录为 `4.experiments/gpu-study-qemu`。实验开发统一在 `main` 分支进行，修改代码前先确认当前分支。原仓库 `qemu-camp/qemu-camp-2026-exper-hxfei-git` 的提交历史完整保留；子仓库的 `upstream` 远端指向原仓库，`origin` 指向新仓库。

**[DESIGN]** 最终目标是参考 ROCr / HSA / KFD 的软件分层、对象关系和提交语义，形成类 AMD 的 GPGPU 教学软件栈。第一阶段已经跑通计算；第二阶段由用户态运行时发布 AQL Packet，驱动负责资源和队列管理，设备 CP 取包并通过 Signal 报告完成。后续再引入 Linux 通用框架、地址隔离与异常恢复。

**[BOUNDARY]** 实验对象是自定义 QEMU GPGPU 教学设备。实验中的寄存器、命令和页表设计按实际实现说明，与学习笔记中的 MI300X 模型分开；项目不以复现 MI300X 或兼容整套 ROCm 为目标。

## 2. 四阶段实验安排

**[DESIGN]** 第一阶段已完成，第二阶段在本节细化 v1 规格与近期实现顺序。第三、第四阶段仍只保留推进方向，进入相应阶段后再展开。

```text
已有 QEMU GPGPU 实验
  → 第一阶段：应用经运行时和驱动完成一次计算（已完成，支持 A57 与 SMMUv3）
  → 第二阶段：用户向 AQL Queue 发布任务，Doorbell 通知 CP，Signal 报告完成（当前）
  → 第三阶段：引入 DRM，建立和隔离 GPU 地址空间
  → 第四阶段：处理异常，恢复设备并回收资源
```

### 2.1 第一阶段：跑通应用到设备的计算流程

围绕进阶实验一，已完成 Linux 驱动、用户态运行时、代码加载和参数传递，让计算 kernel 接收输入、执行并返回可核对的结果。A57、PCI / BAR、VRAM、DMA、SMMUv3、MSI-X、RV32 执行器、计算示例和测试环境继续作为后续阶段的基础。

### 2.2 第二阶段：用户 AQL Queue、Doorbell、CP 与 Signal

当前先按 [AMD CP 功能分析与实验规格](<./AMD CP 功能分析与实验规格.md>) 阅读整体执行流程和九项功能，再复审本节的 Queue、Doorbell、Packet 与 Signal 约定。该文档用于友商分析与教学设计讨论；实验阶段安排及协议参数仍统一在本大纲维护，以下 v1 取值保留为本轮复审的基础。

**[DESIGN]** 本阶段 v1 采用单进程、单用户队列和单生产者。应用可以连续提交多个任务，设备一次执行一个 kernel，并按队列顺序推进。正常提交由用户态写包和敲门铃完成；驱动负责创建、映射、等待和销毁等资源管理操作。

以下新增参数、寄存器和状态均属于本阶段设计。这里的“硬件规格”是 QEMU 教学设备对软件提供的行为约定，不代表 MI300X 的实际寄存器或内部实现。

以向量加法为例，应用已有第一阶段的代码、输入数组和数据搬运接口，接下来要通过用户队列提交计算并单独等待完成。下图说明本阶段的执行顺序；对象的布局和具体取值在后续小节展开。

```text
① 准备
应用经现有接口，把代码、输入数组上传到 VRAM
驱动创建 Queue，并映射共享内存和 Doorbell

② 提交
应用调用异步 Launch
  → 运行时准备参数和 Signal
  → 写入 AQL Packet
  → 发布 Packet
  → 写 Doorbell
  → Launch 返回，应用可以继续提交下一项任务

③ 执行
QEMU CP 读取 Packet
  → 找到代码描述和参数
  → 启动 RV32 执行器
  → 把计算结果写入 VRAM
  → 更新对应 Signal，发出完成中断

④ 收尾
应用等待全部任务完成
  → 销毁 Queue
  → 使用现有 D2H 接口读回结果
  → 核对结果、释放资源
```

CP 负责取包和派发，Signal 保存某个任务的完成状态。异步 Launch 返回时，运行时已经发布任务，返回不以 kernel 完成为条件。设备独立推进计算和结果写入，应用通过对应 Signal 等待；短任务也可能在 Launch 返回前完成。

#### 2.2.1 设备规模与支持范围

**[DESIGN]** 本阶段固定以下参数，作为接口实现和验收的共同依据。

| 项目 | 第二阶段 v1 取值 |
| --- | --- |
| CPU 与系统 | 沿用 A57、ARM64 Linux |
| 系统 IOMMU | 保留 `none`、`smmuv3` 两种模式 |
| 进程与队列 | 一个独占会话、一个 Queue |
| 队列生产者 | 一个；运行时通过锁串行化提交 |
| Ring 容量 | 64 个槽位 |
| Packet 大小 | 64 字节，因此 Ring 共 4 KiB |
| 执行能力 | 同时执行一个 kernel，按队列顺序执行 |
| 任务资源 | 64 个 Signal 槽、64 个参数槽 |
| 单次参数大小 | 最多 256 字节 |
| 计算后端 | 保留现有 RV32 执行器 |
| Dispatch 维度 | 支持现有一维、二维、三维任务 |
| 本阶段内存模型 | 代码和计算数据使用 VRAM 偏移；尚不引入 GPUVM |

一个任务即使完成，只要应用还没有回收它的 Signal，就仍占用一个任务资源槽。资源不足时，异步提交返回 `-EAGAIN`，不能覆盖旧任务。同时未完成的任务最多为 64 个；Ring 槽提前回收也不能突破参数槽和 Signal 槽的数量限制。

多队列、多个 kernel 并发、GPU 地址隔离和异步拷贝留待后续扩展。本阶段继续沿用直接设备显存寻址，暂不引入 DRM / GEM 或 `drm_sched`。

#### 2.2.2 共享内存、设备地址与参数传递

驱动为 Queue 新增一块独立的 64 KiB 一致性 DMA 内存。原来的 64 KiB 搬运暂存区继续保留，新共享区使用独立的映射入口。下列地址都是相对于新共享区起点的偏移。

```text
0x0000～0x0fff：生产者控制区，运行时写 wptr
0x1000～0x1fff：消费者控制区，设备写 rptr
0x2000～0x2fff：AQL Ring，64 × 64 字节
0x3000～0x3fff：Signal 区，64 × 32 字节，其余保留
0x4000～0x4fff：Kernel 描述区，64 × 32 字节，其余保留
0x5000～0x8fff：参数区，64 × 256 字节
0x9000～0xffff：保留
```

CPU 和 CP 通过各自的地址访问同一块共享内存：

```text
CPU：通过 mmap 得到的 CPU 虚拟地址访问
CP ：通过驱动配置的 DMA 地址访问
                      │
                      └─ SMMUv3 模式下，该地址是 IOVA
```

驱动向运行时返回共享区的映射信息和设备地址信息。运行时可以计算各对象的设备地址，但不能自行配置任意 DMA 区域。DMA 地址保留 64 位，不因计算后端使用 RV32 而截断。

本版规定：

- `kernel_object` 保存共享区中 Kernel 描述对象的设备地址；
- `kernarg_address` 保存共享参数槽的设备地址；
- 参数里面的数组指针仍然是 32 位 VRAM 偏移；
- `completion_signal` 保存 Signal 句柄，不是地址。

CP 必须检查描述对象、参数和 Signal 都属于当前 Queue 的对应区域，并检查长度、对齐和整数溢出。发布后至任务完成前，运行时不得修改该任务使用的描述对象和参数。

现有 RV32 执行器通过入口寄存器 `a0` 读取 VRAM 中的参数，因此本阶段为 CP 预留一页私有参数空间：

```text
CPU 填写共享参数槽
         │
         ▼
CP 通过 PCI DMA 读取参数
         │
         ▼
复制到预留的 VRAM 参数页
         │
         ▼
RV32 a0 指向该页，kernel 按现有约定读取参数
```

这页固定为 4 KiB，从 VRAM 分配器中排除。一次只执行一个 kernel，因此下一项任务可以在上一项结束后复用同一页。零参数任务将该页开头的一个字清零。

**[BOUNDARY]** CP 搬运参数是保留当前 RV32 后端的教学适配，不作为 MI300X 的真实参数访问流程。第三阶段引入 GPUVM 后，再调整这部分。系统 IOMMU 翻译 CP 对共享区的 DMA 访问；本阶段的 kernel 仍使用 VRAM 偏移，尚未获得 GPU 地址空间隔离。

#### 2.2.3 CP 寄存器与 Doorbell

保留现有 BAR 分工：BAR0 管控制，BAR2 对应 VRAM，BAR4 提供 Doorbell。在 BAR0 的 `0x0500` 分组增加以下寄存器。

```text
偏移     寄存器              作用
0x0500   CP_CTRL             ENABLE、STOP
0x0504   CP_STATUS           DISABLED、IDLE、RUNNING、STOPPING、QUIESCED、FAULT
0x0508   ARENA_BASE_LO       共享区 DMA 地址低 32 位
0x050c   ARENA_BASE_HI       共享区 DMA 地址高 32 位
0x0510   ARENA_SIZE          本版必须为 64 KiB
0x0514   QUEUE_ABI_VERSION   只读，本版为 1
0x0518   FAULT_CODE          错误原因
0x051c   FAULT_STAGE         取包、读取参数、执行或完成写回
0x0520   FAULT_PACKET_ID     出错任务的包编号
0x0524   FAULT_ADDR_LO       出错地址低 32 位
0x0528   FAULT_ADDR_HI       出错地址高 32 位
```

所有寄存器都是小端、32 位访问。地址配置只能在设备尚未启用或已经静止时修改，最后写 `ENABLE` 使整组配置生效。Doorbell 位于 BAR4 的 `0x0000`：

```text
DOORBELL_KICK：32 位写入 1，通知 CP 检查队列
```

Doorbell 回调只安排后续工作，不在回调中运行完整 kernel。重复写 Doorbell 不得重复执行任务。运行时只获得 Doorbell 所在页的映射，BAR0 控制寄存器继续由驱动访问。

**[BOUNDARY]** 本版 Doorbell 不携带包编号，CP 从共享 `wptr` 判断有哪些任务。这是教学门铃约定，不复刻 AMD 的门铃编码。

> **[SOURCE]** 实验基线 `049ed3eb6ba06c3b464dcff8871fd4463a441569`：现有寄存器定义见 [hw/gpgpu/gpgpu_regs.h](https://github.com/hxfei-git/gpu-study-qemu/blob/049ed3eb6ba06c3b464dcff8871fd4463a441569/hw/gpgpu/gpgpu_regs.h#L15-L88) 的 [15–88 行](https://github.com/hxfei-git/gpu-study-qemu/blob/049ed3eb6ba06c3b464dcff8871fd4463a441569/hw/gpgpu/gpgpu_regs.h#L15-L88)；门铃采用 4 字节访问，见 [hw/gpgpu/gpgpu_doorbell.c](https://github.com/hxfei-git/gpu-study-qemu/blob/049ed3eb6ba06c3b464dcff8871fd4463a441569/hw/gpgpu/gpgpu_doorbell.c#L25-L32) 的 [25–32 行](https://github.com/hxfei-git/gpu-study-qemu/blob/049ed3eb6ba06c3b464dcff8871fd4463a441569/hw/gpgpu/gpgpu_doorbell.c#L25-L32)。这些源码用于核对现有布局；新增 CP 寄存器及其语义属于本节设计。

#### 2.2.4 AQL Packet、Kernel 描述对象与队列消费

采用 64 字节 AQL Kernel Dispatch 的字段布局，首版只接受以下子集：

- Packet 类型为 `KERNEL_DISPATCH`；
- `barrier` 固定为 `1`，后一项任务等前一项完成后再执行；
- acquire/release scope 固定为 `SYSTEM`；
- `setup` 接受维数 `1、2、3`，未使用的维度取 `1`；
- `private_segment_size`、`group_segment_size` 和保留字段必须为 `0`；
- 每个有效任务必须提供非零、有效的完成 Signal；
- 不支持的字段取值明确报错。

`grid_size` 表示 work-item 总数。以向量加法为例，原接口传入 4 个 block、每个 block 256 个线程，运行时生成的包字段为：

```text
原接口：grid.x = 4，block.x = 256
                 │ 运行时换算
                 ▼
AQL：grid_size_x = 1024，workgroup_size_x = 256
```

本版要求每个维度的 `grid_size` 都能整除 `workgroup_size`。需要处理尾部元素时，继续扩大执行范围，由 kernel 检查元素下标。维度和线程总量沿用现有设备限制。

> **[SOURCE]** ROCr 固定基线 `ba56a24c6132c5d195686ae4adf969ca1222fbba`，[runtime/hsa-runtime/inc/hsa.h](https://github.com/ROCm/rocr-runtime/blob/ba56a24c6132c5d195686ae4adf969ca1222fbba/runtime/hsa-runtime/inc/hsa.h#L2878-L3070) 的 [2878–3070 行](https://github.com/ROCm/rocr-runtime/blob/ba56a24c6132c5d195686ae4adf969ca1222fbba/runtime/hsa-runtime/inc/hsa.h#L2878-L3070) 定义 Header、维数、Dispatch 字段和 `grid_size` 的数量含义。本节固定的 scope、整除要求及非零 Signal 是教学子集限制，不声明完整 HSA ABI 兼容。

Kernel 描述对象由运行时填写，CP 根据 Packet 中的 `kernel_object` 找到它，再取得代码入口和参数长度。描述对象固定为 32 字节，核心成员如下；未使用空间为保留字段。

```text
version       ：本版描述格式版本
code_offset   ：RV32 代码入口的 VRAM 偏移
code_size     ：代码长度
kernarg_size  ：参数长度，不能超过 256 字节
reserved      ：保留字段，必须为 0
```

这是教学描述格式。CP 取得描述对象和参数后，保存本次任务的执行快照；描述对象和代码仍须保持有效，直到使用它们的任务结束。

队列索引约定如下：

```text
wptr：下一个可发布包的编号，由运行时写
rptr：下一个待消费包的编号，由 CP 写

槽位编号 = 包编号 % 64
满队列条件：wptr - rptr == 64
```

本版索引使用对齐的 32 位字段，累计计数接近 `0x7fff_ffff` 时停止新提交并重建队列。槽位可以反复循环使用，累计计数不允许溢出回绕。CP 应检查索引单调性及 `wptr - rptr` 的合法范围，拒绝越界取包。

CP 消费一项任务的顺序固定为：

```text
检查 wptr 和当前槽位的 Header
  → 读取并校验 Packet、描述对象和参数
  → 保存执行快照
  → 将槽位标为 INVALID，推进 rptr
  → 执行 kernel
  → 更新对应 Signal
  → 继续检查下一项任务
```

`rptr` 前进后，运行时可以复用对应 Ring 槽位；参数槽和 Signal 槽仍需保留到任务完成并被回收。所有空槽初始化为 `INVALID` 类型，不能仅把整块 Ring 清零。遇到尚未发布的 `INVALID` 槽，CP 停止取包，等待后续通知，不跳过该槽。

#### 2.2.5 发布顺序、Signal 与完成通知

运行时已经取得空闲 Ring 槽、参数槽和 Signal 槽，接下来按以下顺序发布任务：

```text
准备参数、Signal 初值和 Packet 包体
  → 保证前面的写入对设备有序可见
  → 一次对齐的 32 位写，发布 Header + Setup
  → 有序更新 wptr
  → 保证共享内存写先于 MMIO 写
  → 写 DOORBELL_KICK
```

A57 运行时应封装专用的共享内存和 MMIO 访问辅助函数，明确使用所需的设备内存屏障，例如发布过程中的 `dmb oshst`。普通指针赋值或 `volatile` 不能替代这套顺序约定。

一致性 DMA 内存解决缓存一致性问题，访问顺序仍由发布协议保证。Header 的发布、任务前后的 `SYSTEM` scope，以及 Host 等待完成后的读取交接分别发生在不同阶段，不能仅设置 Packet 中的 scope 字段就省略其余处理。

> **[SPEC]** Linux v6.1 文档 [Dynamic DMA mapping Guide](https://www.kernel.org/doc/html/v6.1/core-api/dma-api-howto.html)，章节 “Types of DMA mappings” 说明 coherent DMA 内存仍需要适当的内存屏障。这里引用其一致性与访问顺序的区分；A57 用户态辅助函数和 QEMU 设备访问的具体实现仍需按本实验验证。

每个 Signal 槽关联一个任务，由运行时初始化，设备在任务结束时更新。槽长为 32 字节，至少保存以下成员，其余空间保留：

```text
value       ：1 表示尚未结束，0 表示已经结束
status      ：PENDING、SUCCESS、FAILED 或 CANCELED
generation  ：槽位代数，防止旧句柄误指向新任务
packet_id   ：关联的任务编号
```

Signal 句柄为 64 位，由槽位和代数组成；本版 `value` 使用 32 位，只支持一次任务的 `1 → 0`，不实现完整 HSA Signal 原子操作集合。设备检查句柄是否属于当前 Queue、槽位是否有效、代数是否匹配，再访问对应 Signal。

正常完成顺序为：

```text
完成 VRAM 结果写入
  → 写 status = SUCCESS
  → 按规定顺序写 value = 0
  → 发出完成中断
```

应用观察到 `value = 0` 后，执行对应的读取屏障，再检查 `status`。任务结束后仍需确认成功状态；计算结果此时保存在 VRAM，应用要在队列销毁后执行 D2H，才能读取主机输出数组。

完成中断复用现有向量 `0`，DMA 使用向量 `1`，错误使用向量 `2`。驱动中断处理唤醒等待者，等待者根据对应 Signal 判断具体任务的状态。

> **[SOURCE]** 实验基线 `049ed3eb6ba06c3b464dcff8871fd4463a441569`，[hw/gpgpu/gpgpu.h](https://github.com/hxfei-git/gpu-study-qemu/blob/049ed3eb6ba06c3b464dcff8871fd4463a441569/hw/gpgpu/gpgpu.h#L31-L34) 的 [31–34 行](https://github.com/hxfei-git/gpu-study-qemu/blob/049ed3eb6ba06c3b464dcff8871fd4463a441569/hw/gpgpu/gpgpu.h#L31-L34) 定义现有计算、DMA 和错误向量。本阶段复用这些向量，新增 Signal 与等待者的关联。

#### 2.2.6 错误处理、队列停止与资源释放

错误处理至少覆盖非法包、无效句柄、地址错误、执行错误和 DMA 访问失败。发生错误后，CP 停止取新包，记录原因并通知驱动。若 Signal 本身无法写回，等待接口必须能通过队列错误退出，不能只等待 `value` 变零。

正常销毁和强制退出都必须在释放内存前确认设备已经停止访问：

```text
停止用户态提交
  → 正常路径等待已提交任务完成
  → 驱动发 STOP
  → CP 停止取包，结束或取消执行，撤销后续回调
  → 设备报告 QUIESCED
  → 处理剩余任务的取消状态
  → 解除映射并释放共享内存
```

正常路径通过全部 Signal 确认任务结束后，再停止队列。强制退出可以取消尚未结束的任务，但仍要取得设备静止确认。报告 `FAULT` 只说明发生了错误，释放内存前仍须完成停止流程，确认没有回调继续访问共享区。

若旧的共享内存或 Doorbell 映射尚未解除，则保留对应对象，并拒绝创建新队列，避免旧映射影响新队列。等待超时只表示这次等待结束，运行时不能据此释放仍可能被设备访问的资源。

#### 2.2.7 QEMU、驱动与运行时的实现范围

QEMU 侧增加 CP 模块，管理队列配置、取包、校验、执行快照、Signal 写回和错误状态，让现有 Doorbell 回调能够调度 CP。所有共享区访问都沿 PCI DMA 地址空间进行，使 SMMUv3 继续参与翻译；不能把 IOVA 转成 QEMU 进程指针直接访问。

RV32 执行器需要提供可分段执行的接口，把当前 block、warp、PC 和寄存器状态保存下来。每次回调只执行有限工作量，再让出 QEMU 主循环。单次回调预算用完表示稍后继续；非法指令或累计执行超限才表示错误，分段不能重置累计限制。

Linux 驱动增加 Queue 创建、等待、查询状态和销毁接口；分配共享区，设置设备地址，映射共享内存和一页 Doorbell。驱动还要管理等待队列、映射引用和退出清理。等待任务时不能长期持有阻塞其他必要操作的全局锁。

本版规定：Queue 存在期间，COPY、FREE、旧 LAUNCH 和普通 RESET 返回 `-EBUSY`。QEMU 设备侧也要阻止旧派发和搬运路径与 CP 交叉执行。读回结果前，应用先完成并销毁 Queue。队列自己的 STOP 与故障清理仍须可用。

用户态运行时保留现有同步 API，新增显式队列接口，拟采用以下名称；这里只约定用途，不作为可编译的函数声明：

```text
gpgpuQueueCreate(...)
gpgpuLaunchKernelAsync(..., signal_out)
gpgpuSignalQuery(...)
gpgpuSignalWait(..., timeout)
gpgpuSignalDestroy(...)
gpgpuQueueSynchronize(...)
gpgpuQueueDestroy(...)
```

异步 Launch 取得空闲资源、填写参数、生成 Packet、发布并敲门铃，正常提交不再调用 `LAUNCH ioctl`。阻塞等待可以进入驱动。运行时管理描述对象、参数槽和 Signal 的引用，拒绝在任务结束前回收这些资源。

一个完整应用的调用顺序为：

```text
Init
  → Malloc / LoadKernel / H2D
  → QueueCreate
  → 多次 LaunchKernelAsync
  → 等待并检查各 Signal
  → 回收 Signal，QueueDestroy
  → D2H，核对结果
  → Free / Destroy
```

#### 2.2.8 实现顺序与完成标准

按以下四步推进，每一步都应产生可运行结果，再进入下一步。

1. 固定协议和 CP。写出共享区、Packet、描述对象、Signal 和寄存器定义，用 QTest 手工构造任务，验证 Doorbell、取包、执行和完成写回。
2. 接入驱动映射与退出流程。跑通创建、映射、启用、停止、静止确认和销毁，再测试创建失败回滚及进程退出。
3. 接入运行时和计算示例。先让 vector add 通过用户队列执行，再接入矩阵乘和 ReLU，验证连续提交多个任务及结果正确性。
4. 补齐队列与故障验证。至少验证槽位循环复用、满队列、重复 Doorbell、无效 Header、错误 Signal、参数提前复用、执行中退出，以及 Ring 读取或 Signal 写回的 IOMMU fault。

第二阶段完成时，应能观察到：应用连续发布多个 AQL 任务，提交调用不等待 kernel 完成，设备独立推进，每个任务通过自己的 Signal 报告结果；队列销毁后设备不再访问它的内存。可以用足够长的任务验证提交返回时 Signal 仍为 `1`，不要求所有短任务都呈现这一时序。

上述检查需要在 `none` 和 `smmuv3` 两种模式下通过，同时保留第一阶段现有测试的回归结果。记录实际运行命令、通过数量、错误路径和结果核对情况后，再更新本阶段完成状态。

### 2.3 第三阶段：引入 DRM 与虚拟地址管理

先接入 DRM / GEM，验证原有计算流程；再加入 GPUVA、页表、MMU、VMID 和 TLB，让地址翻译参与设备实际访存，逐步验证多进程隔离与 VMID 复用。根据实际地址模型调整第二阶段的 CP 参数搬运适配。

普通 DRM 命令提交及 `drm_sched` 按学习需要另行展开，与用户 AQL Queue 保持两条清楚的提交路径，不要求每个 AQL Packet 都先包装成普通 DRM job。

### 2.4 第四阶段：完善异常处理与资源释放

在第二阶段已有的队列停止、等待退出与资源保护基础上，围绕非法命令、访问 fault、任务超时和进程退出，完善 CP / 执行引擎中止、设备复位与资源回收，验证恢复后仍能执行正常任务。AQL 用户队列属于第二阶段的必达范围。

## 3. 随进展调整大纲

四阶段用于说明项目的大致方向，不在开始时固定全部功能、接口、工期或验收清单。进入某一阶段后，先看已有实现、当前问题和希望跑通的场景，再细化近期任务。

每完成一段实验，或遇到影响原计划的问题，就根据代码、运行结果和学习反馈更新当前阶段，并调整后续阶段的范围与顺序。必要时拆分、合并或后移工作，避免只因最初列入某阶段就继续扩张任务。

实验计划统一在本大纲维护，当前阶段同步到根目录 `AGENTS.md`。记录进度时区分用户反馈、代码核对和运行验证，不能用文件存在代替实验完成。学习笔记中的理论缺口仍补回首次需要它的章节，第七章大纲继续管理笔记内容。
