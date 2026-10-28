
# CP/MEC 第一版规格

| 缩写   | 英文全称                                  | 中文含义                                       |
| ------ | ----------------------------------------- | ---------------------------------------------- |
| CP     | Command Processor                         | 命令处理器                                     |
| MEC    | Micro Engine Compute                      | 计算命令处理微引擎                             |
| IH     | Interrupt Handler                         | 中断记录与分发模块                             |
| IRQ    | Interrupt Request                         | 中断请求                                       |
| ACK    | Acknowledgment                            | 确认；本版用于确认已经读取执行结果             |
| HQD    | Hardware Queue Descriptor                 | 硬件队列描述；保存驻留队列的状态               |
| MQD    | Memory Queue Descriptor                   | 内存中的队列描述对象                           |
| KIQ    | Kernel Interface Queue                    | 内核接口队列；本版负责建立和卸载 HIQ           |
| HIQ    | HSA Interface Queue                       | HSA 接口队列；本版负责管理用户队列             |
| HSA    | Heterogeneous System Architecture         | 异构系统架构                                   |
| HSAKMT | HSA Kernel Mode Thunk                     | HSA 用户态与 KFD 内核接口之间的调用封装        |
| KFD    | Kernel Fusion Driver                      | AMD GPU 计算相关内核驱动组件                   |
| ROCm   | Radeon Open Compute                       | AMD GPU 计算软件平台                           |
| ROCr   | ROCm Runtime                              | AMD 的 HSA 用户态运行时                        |
| GPUVM  | GPU Virtual Memory                        | GPU 虚拟内存管理                               |
| AQL    | Architected Queuing Language              | HSA 定义的队列包格式与提交协议                 |
| ABI    | Application Binary Interface | 二进制接口 |
| GPUVA  | GPU Virtual Address | GPU 虚拟地址 |
| DRM    | Direct Rendering Manager | Linux 图形设备内核框架 |
| GEM    | Graphics Execution Manager | DRM 内存对象管理框架 |
| BO     | Buffer Object | 保存实际存储与引用的缓冲对象 |
| CSR    | Control and Status Register | 控制与状态寄存器；用于读取启动信息 |
| SGPR   | Scalar General-Purpose Register | 本实验每 Warp 共享的启动状态 |
| VGPR   | Vector General-Purpose Register | 本实验各 Lane 独有的启动状态 |
| ALU    | Arithmetic Logic Unit | 算术逻辑单元 |
| TLB    | Translation Lookaside Buffer | 地址翻译缓存 |
| API    | Application Programming Interface         | 应用编程接口                                   |
| PCIe   | Peripheral Component Interconnect Express | 高速外设互连总线                               |
| BAR    | Base Address Register                     | PCIe 基址寄存器；描述设备资源窗口              |
| QEMU   | Quick Emulator                            | 仿真与虚拟化工具                               |
| CPU    | Central Processing Unit                   | 中央处理器                                     |
| GPU    | Graphics Processing Unit                  | 图形处理器                                     |
| RV32   | 32-bit RISC-V                             | 本版计算解释器使用的 32 位 RISC-V 模型         |
| RV64   | 64-bit RISC-V                             | 本版 CP 使用的原生 64 位 RISC-V 模型           |
| M-mode | Machine Mode                              | RISC-V 机器特权级；CP 裸机固件的运行模式       |
| TCG    | Tiny Code Generator                       | QEMU 的动态代码生成基础设施                    |
| VRAM   | Video RAM                                 | 教学设备的显存后备存储                         |
| RAM    | Random Access Memory                      | 随机存取存储器；Host RAM 与设备 VRAM 分开      |
| DMA    | Direct Memory Access                      | 直接内存访问                                   |
| IOVA   | I/O Virtual Address                       | 设备访存使用的虚拟地址                         |
| IOMMU  | Input/Output Memory Management Unit       | 设备访存的地址翻译与权限检查单元               |
| SMMUv3 | System Memory Management Unit version 3   | Arm 系统内存管理单元第三版                     |
| MSI-X  | Message Signaled Interrupts Extended      | 扩展消息中断                                   |
| PC     | Program Counter                           | 程序计数器，保存取指地址                       |
| SP     | Stack Pointer                             | 栈指针；固件使用 RISC-V 的 `sp` 寄存器       |
| VMID   | Virtual Memory Identifier                 | 用户上下文编号；开启 GPUVM 时选择页表             |
| IB     | Indirect Buffer                           | 间接命令缓冲区；本版不引入                     |
| IQ     | 未核实                                    | AMD 寄存器中的内部对象缩写；本版不引入         |
| EOP    | End of Pipe                               | 执行结束相关处理；本版不建立独立 EOP 缓冲区    |
| LDS    | Local Data Share                          | AMD 的工作组片上共享存储；实验共享存储留作扩展 |
| RPTR   | Read Pointer                              | 读指针，记录消费进度                           |
| WPTR   | Write Pointer                             | 写指针，记录生产进度                           |

本文集中保存本实验已经确认的架构、行为与接口约束；各项接口决定与接入边界集中记录在[第 9 节](#spec-open-interfaces)。寄存器名称参考 AMD，实验语义以本文的 `[DESIGN]` 为准，不声明兼容 AMD 的完整硬件协议。

实验阶段和完成状态见[实验大纲](<./QEMU GPGPU 实验大纲.md>)。对象关系、设计取舍、AMD/gem5 证据，以及代码与接口说明见[软件实现、参考与扩展](<./CP_MEC 软件实现、参考与扩展.md#implementation>)。双进程设备和 CP Host 访存窗口已接入；2026-10-17 原生 CP 迁移至 RV64，窗口增加对齐的 8 字节读写，当时的 CP 回归通过 8/8。第二阶段用户态向上实现到[HSAKMT 风格接口库](#spec-host-api-scope)；既有流程中由“运行时”完成的参数组织、AQL 发布和 Signal 判断，由实验程序等调用方承担，暂不设计 ROCr/HSA 运行时。

2026-10-19 已实现共享协议、设备队列入口、RV64 固件、驱动与 HSAKMT 风格接口库。CP 回归通过 16/16，新内核上的五组 Linux 队列验收和四种同步组合回归均通过。第 9 节确认记录中的“尚待实现”保留其确认时点含义；实际运行数量与后续扩展统一见[大纲进度说明](<./QEMU GPGPU 实验大纲.md#current-progress>)。本次采用的 IH 地址、错误枚举和复位字段补在第 7.1 节，执行器错误枚举补在第 6.3.3 节，当前源码入口见[实现说明](<./CP_MEC 软件实现、参考与扩展.md#implementation>)。

寄存器查阅见 [GPGPU 虚拟加速器硬件手册](<./QEMU_2026_GPGPU_硬件手册.html>)，其中按功能列出地址、位域、访问权限及复位行为；本文继续保存完整的队列协议、软件约定和规格确认记录。已确认规格与实现状态分别维护；2026-10-19 复核中的管理结果码校验缺口及验证范围见[大纲复核记录](<./QEMU GPGPU 实验大纲.md#stage-two-spec-review>)，该缺口已在第三阶段修复，未知结果继续保留资源。

**[DESIGN]** 2026-10-28 起，当前接口为版本 2：设备／固件队列协议、DRM 与 GPUVM 编码统一升级，旧组件明确拒绝。用户端只使用 DRM/GEM 与 AQL Queue；设备属性 `gpuvm=on/off` 决定用户地址是否翻译，默认开启。第 1～8 节按当前接口说明；第 9 节保留原确认时点记录，其旧地址与参数窗口约定不再作为执行要求。历史验收数量也不作为当前入口的固定计数。

当前计算验证统一为 `test-gpgpu-stack`：ARM virt、A57、1 GiB、`IOMMU=none`，分别运行 GPUVM 开／关下的向量加法 17,003 个结果、矩阵乘法 437 个结果与 ReLU 513 个结果。结果以实际逐元素比较为准，不追加专项测试。当前公共库和绑定接口见[GPUVM 规格第 8 节](<./GPUVM 第一版规格.md#gpuvm-device-host-interface>)。

<a id="spec-overview"></a>

## 1. 整体架构与执行路径

**[DESIGN]** 第一版使用一个 QEMU 原生 RV64 CP，由 TCG 在 M-mode 执行裸机固件，不启用页表；现有 RV32 计算解释器继续执行应用 Kernel。4 个 HQD 槽位中，槽位 0 用于 KIQ，槽位 1 用于 HIQ，槽位 2、3 由 CP 按创建请求分配给用户 AQL Queue。计算执行器一次处理一个完整 Dispatch。

```text
Host 配置并确认 Outbound，准备 KIQ 的 Ring、MQD 与 HQD，启动 CP
  → 驱动经 KIQ 请求建立 HIQ，确认管理操作完成
  → 应用经内存接口申请 Ring 和进度区，再请求创建用户 Queue，驱动准备 MQD
  → 驱动经 HIQ 提交 MAP_QUEUES，指定 USER_AQL 和 MQD 地址
  → CP 从槽位 2、3 中选择空闲槽位；无空闲槽位则报告创建失败
  → CP 读取用户队列的 MQD，配置并激活所选 HQD
  → 驱动确认配置成功，接口库将队列标识和 Doorbell 入口交给调用方
  → Host 向用户 AQL Ring 发布 Dispatch 并通知设备
  → RV64 CP 根据 HQD 找到 Ring，读取并解析 Dispatch
  → CP 通过分发接口向 RV32 计算执行器提交任务，等待完成
  → CP 发布完成 Signal，释放包槽并回报消费进度
  → Host 读取结果，复用已经消费的 Ring 槽
```

原生 CP 执行队列固件，计算执行器执行应用 Kernel，两者各自保存寄存器和取指位置。2026-10-17 的 RV64 迁移只改变原生 CP；计算线程的寄存器和 Kernel 指令仍按 RV32 执行。执行主体、构建入口及参数交接边界见[CP 与计算执行器的位宽](<./CP_MEC 软件实现、参考与扩展.md#cp-executor-widths>)。上图规定本阶段的队列执行顺序，实际运行结果见大纲进度说明。

本文用户态流程中的“运行时”泛指准备应用数据的调用方。槽位预留、Header 发布、8 字节 Doorbell 更新、Signal 等待与事件配合、排空及 Queue 销毁统一由 HSAKMT 风格公共库承担；示例链接 `libgpgpu-kmt.a`。旧 Runtime、`libgpgpu.a` 和同步提交入口已删除。

<a id="spec-user-queue-capacity"></a>

**[DESIGN]** 全设备最多同时存在 **两条用户 Queue**，每个上下文最多一条，所有应用共享这两个名额，KIQ、HIQ 不计入其中。用户队列按申请创建，各自的 Ring、MQD 和进度区由驱动分配。文中的 Queue A、B、MQD_A、MQD_B 只是示例名称，不是预先固定的队列身份或地址，也不与槽位 2、3 永久绑定。

假设其他创建条件均满足，下面演示两个名额的分配与复用；槽位选择只用于举例：

```text
第 1 次申请 → 驱动提交 MAP_QUEUES → CP 选择空闲槽位 2，创建队列
第 2 次申请 → 驱动提交 MAP_QUEUES → CP 选择空闲槽位 3，创建队列
第 3 次申请 → 驱动提交 MAP_QUEUES → CP 发现无空闲用户槽位
                                  → 报告失败，驱动向应用返回名额已满

槽位 2 对应的队列成功销毁，完成清理并归还名额
  → 后续申请可以创建新的 Queue，复用槽位 2
  → 为新 Queue 准备自己的 Ring、MQD 和进度区
```

驱动负责准备资源和提交请求，CP 负责判断用户槽位是否空闲并分配；满额时报告失败，驱动将结果返回应用。本版不先创建更多逻辑队列再等待 HQD。仅有 `ACTIVE = 0` 或发出销毁请求，尚不能归还名额；仍需满足既有卸载与资源回收条件。CP 的占用记录、重复请求处理和槽位释放条件见[第 4.2 节](#spec-management-slot-state)，每次管理请求的结果通过[第 4.4 节](#spec-management-result)的独立结果区返回。错误退出与正常卸载按第 7 节执行，强制恢复留作后续扩展；应用创建接口与错误返回见[9.7.3 的已确认接口](#spec-host-queue-create)。

HQD 保存状态，CP 读取状态并执行命令，计算执行器执行 Kernel。管理命令与 AQL Packet 直接保存在各自的 Ring 中，本版不引入 IB 间接命令执行，也不建立 IQ 或 EOP 缓冲区。不提供可配置的队列／管线优先级和时间片，也不实现运行中的抢占和计算现场保存；取舍详解见[AMD 寄存器对照](<./CP_MEC 软件实现、参考与扩展.md#amd-registers>)，后期方向见[扩展项](<./CP_MEC 软件实现、参考与扩展.md#extensions>)。

**[DESIGN]** 第一版沿用 RV32 执行器为每个 lane 固定提供的通用、浮点寄存器，不增加 `COMPUTE_PGM_RSRC1/2` 资源配置寄存器。`Y[i] = a × X[i] + b` 中不随线程变化的只读 `a`、`b` 放在参数块中，各线程读取后计算，无需 LDS。工作组共享存储、组内屏障和可配置寄存器资源列为[后续扩展](<./CP_MEC 软件实现、参考与扩展.md#compute-resource-extension>)；概念与已有实现见[线程寄存器、参数与共享存储](<./CP_MEC 软件实现、参考与扩展.md#kernel-registers-lds>)。第二阶段仍只运行不依赖工作组共享存储和屏障的 Kernel。

双进程设备关系如下。队列、Doorbell 与 CP 派发沿用图中的传输层，接口规则见后续章节：

```text
进程 A：A57 Linux
  └─ vfio-user-pci 代理
       ├─ 配置空间与 BAR 请求 ──────────→ 进程 B：gpgpu-cp
       │                                  ├─ gpu0：寄存器、VRAM、DMA、中断
       │                                  ├─ 原有 RV32 计算解释器
       │                                  └─ 原生 RV64 CP（默认保持复位）
       ├─ PCI DMA 接口 ←── B 的 DMA 请求       │
       │     └─ SMMUv3（启用时）→ Host RAM     └─ 地址 0 起映射同一份 VRAM
       └─ Linux 中断处理 ←── B 的 MSI-X 通知
```

`none` 与 `smmuv3` 都采用消息 DMA：B 请求访问设备 DMA 地址，A 调用代理设备的 PCI DMA 接口，再返回数据或错误。SMMUv3 的翻译、权限检查和故障记录发生在 A。启动选项 `x-dma-via-socket=on` 控制传输方式，不增加硬件寄存器。原单进程入口继续使用现有设备。

**[BOUNDARY]** 双进程模式本版不支持断线重连和迁移。CP 通过本地地址访问 VRAM，通过下文的访存窗口读写 Host RAM。上述设备接口属于 QEMU 教学设备，不能作为 MI300X 的寄存器或内部核实现结论。

<a id="spec-objects-addresses"></a>

## 2. 队列对象、地址空间与 HQD 访问

Host 建立一条队列时，需要准备 Ring、MQD 和进度内存。MQD 保存队列配置与需要恢复的状态；装入 HQD 后，CP 使用 HQD 中的活动状态读取 Ring。卸载保存时，消费位置和错误快照写回原 MQD，供以后恢复或诊断。MQD 的 64 字节布局与装载、保存范围见[第 2.6 节](#spec-mqd-format)。

**[DESIGN]** GPU 物理空间连续分为 VRAM `[0, vram_size)` 与 Outbound `[vram_size, 0x1_0000_0000)`。用户访问在 GPUVM 开启时先翻译，关闭时直接使用输入地址；管理对象始终使用 GPU 物理地址。两类访问汇入同一个物理入口，再按范围访问 VRAM 或经 PCIe DMA 访问 Host RAM。

<a id="spec-ring-mqd-storage"></a>

**[DESIGN]** 用户 Ring、KIQ Ring、HIQ Ring 和所有 MQD 均放在 Host RAM，由驱动使用 `dma_alloc_coherent()` 分配设备可访问的一致性内存。CP 通过 [Host 访存窗口](#cp-host-window)读取命令、装载 MQD，并在卸载保存时写回必要状态。

```text
驱动管理资源（显式管理域，输入为 GPU 物理地址）
  ├─ KIQ Ring、HIQ Ring：位于 Host RAM，保存管理命令
  └─ MQD_A：位于 Host RAM，保存 Queue A 的配置与可恢复状态
       │ CP 读取配置；卸载时保存必要状态
       ▼
HQD 槽位 2：Queue A 当前的活动状态
  ├─ MQD 的 GPU 物理地址 → 读取驱动管理的 MQD_A
  ├─ 用户 Ring 的 GPU 地址 → 读取进程 A 位于 Host RAM 的 Ring
  ├─ 队列 VMID = 1 → 开启时选择页表，关闭时保留来源编号
  ├─ PQ_RPTR → 保存当前消费位置
  ├─ RPTR_REPORT_ADDR → 指定向哪里回报消费进度
  └─ WPTR_POLL_ADDR → 指定从哪里读取软件生产进度
```

- 用户 Ring 由运行时请求创建，驱动分配后使用 `dma_mmap_coherent()` 映射给所属应用；运行时通过用户映射直接填写 AQL Packet。
- KIQ、HIQ Ring 由驱动分配和填写管理命令，不映射给普通应用。
- 所有 MQD 由驱动分配、初始化并管理生命周期，不映射给普通应用；CP 在装载和卸载保存时访问。

驱动按队列生命周期保留这些对象；Host BO 独立分配，CPU 映射由 GEM 引用保活，数据搬运使用对象间 COPY。Ring 保存命令包；Kernel 代码、描述对象、参数和输入输出数据分别按[第 2.3 节](#spec-kernel-data-storage)准备。分配后的访问关系与已有源码依据见[Ring 与 MQD 的分配和访问](<./CP_MEC 软件实现、参考与扩展.md#ring-mqd-storage>)。

**[DESIGN]** KIQ、HIQ 的 VMID 为 0，用户上下文使用 1、2。开启 GPUVM 时用户编号选择已配置的页表；关闭时仍保存编号用于故障归属和资源管理，但不创建页表，不提供页权限隔离，也不强制进程独占。CP 的访问域由显式参数传递，不再用 `VMID == 0` 判断管理或用户访问。

`RPTR_REPORT_ADDR / HI` 与 `WPTR_POLL_ADDR / HI` 保存的是地址，各地址指向的内存保存进度数值。本版将进度区与 Ring 命令区分开分配，Host 通过自己的映射访问相应内存，见[进度与完成值的分配](#spec-shared-state-storage)。消费位置、生产进度的更新规则见第 5、6 节。

**[DESIGN]** Host 和 CP 通过两个入口访问同一份 HQD 状态：

```text
Host 访问 BAR0：
  BAR0 + 0x0600           HQD_SELECT
  BAR0 + 0x0700～0x07ff   当前选中槽位的寄存器窗口

CP 直接按槽位访问：
  CP_HQD_BASE = 0xffff_0000
  地址 = CP_HQD_BASE + 槽位编号 × 0x100 + 字段偏移
```

设备内部保存 4 份独立的 HQD 状态，Host 共用一个访问窗口。Host 选择槽位 2 时，窗口显示 Queue A 的状态；改选槽位 3 后，同一窗口显示 Queue B 的状态，Queue A 的内容仍然保留。选择只改变 Host 接下来访问哪份状态，不改变 CP 正在处理哪条队列。Host 驱动用锁保护选择和窗口访问；CP 使用普通寄存器读写指令按槽位寻址，QEMU 将访问转到对应 HQD，CP 不使用 `HQD_SELECT`。两套入口访问同一份状态，关系图见[HQD 访问说明](<./CP_MEC 软件实现、参考与扩展.md#hqd-window>)，完整地址与无效选槽规则见[第 8.3 节](#spec-hqd-address-map)。

首次启动前 Host 在 CP 保持复位时配置 KIQ；启动后由 CP 处理管理命令，KIQ 负责 HIQ 的配置，HIQ 负责用户队列的配置，具体分工见[第 4 节](#spec-management)。Host 对 HQD 只读，仍可写 `HQD_SELECT` 选择查看对象。需要使用正在配置的地址时，Host 须等待该次配置完成。复位值、访问宽度、权限和非法访问处理见[第 8.2 节](#spec-hqd-access-rules)；生产、消费进度已确定为 32 位，见[第 5.2.1 节](#spec-ring-progress)；共享内存的完整读写要求见[第 2.2.1 节](#spec-shared-value-integrity)，发布同步也须遵守这些规则，Host 的选槽锁不能替代共享字段访问与发布同步。

<a id="cp-host-window"></a>

### 2.1 CP 本地窗口与公共物理入口

CP 已取得一个队列对象地址，需要通过本地 load/store 完成访问。固件先保存访问域、VMID、源 HQD 槽与阶段，再把对象地址写入本地窗口基址；窗口入口保留在 CP 的独立地址空间。

```text
CP 本地窗口 load/store
  → 窗口基址 + 窗口内偏移，得到 GPU 存储地址
  → 显式访问域
      ├─ 用户域：gpuvm=on 时按 VMID 翻译，off 时直通
      └─ 管理域：输入直接作为 GPU 物理地址
  → 公共物理入口
      ├─ [0, vram_size) → VRAM
      └─ [vram_size, 0x1_0000_0000) → 减 vram_size 得到 Host IOVA
                                          → PCIe DMA → SMMUv3（启用时）→ Host RAM
```

CP 的代码、栈和控制寄存器仍使用自己的裸机地址；Host 经 BAR2 读写 VRAM。下面只列 CP 本地窗口，不能将这些地址当作 RV32 Kernel 的特殊地址：

```text
0x8000_0000 … 0x8000_ffff    CP 的 64 KiB 访存窗口
0xfffe_0000 / 0xfffe_0004    窗口目标基址的低／高位
0xfffe_0008                 访问域：0 管理、1 用户
0xfffe_000c                 用户 VMID
0xfffe_0010                 源 HQD 槽
0xfffe_0014                 访问阶段
```

基址按 64 KiB 对齐，固件写完高低位后再访问。窗口支持自然对齐的 1、2、4、8 字节小端访问，8 字节由 RV64 的 `LD/SD` 完成。失败返回原生 load/store access fault，已完成的写入保留；窗口不修改独立 COPY 的 DMA 完成状态。

例如 `gpuvm=off`、64 MiB VRAM 时，GPU 物理地址 `0x4500_1234` 对应 Host IOVA `0x4100_1234`。CP 设置基址 `0x4500_0000`，读取本地 `0x8000_1234`，公共物理入口再减去 `0x0400_0000`。IOVA 0 对应 GPU 物理地址 `0x0400_0000`，不排除该页。窗口覆盖只选择路由，实际 Host 存储及 IOMMU 映射必须有效。

全设备 Outbound 窗口由驱动在 CP 启动前配置并确认：GPU 基址为 `vram_size`，Host IOVA 基址为 0，长度为 `0x1_0000_0000 - vram_size`。BAR0 `0x0b00～0x0b18` 保存这些值、使能和确认状态；运行期间拒绝重配置。驱动设置 31 位 DMA mask，每次分配用 64 位算术检查完整区间，再保存原始 DMA 地址和转换后的 GPU 物理地址；释放和 CPU 映射仍用原始地址。

停止时先保持 CP 复位，等待在途物理访问结束，再确认整体复位已关闭窗口。未确认停止时保留相关资源。BO 分配、队列创建与进程退出均不重配窗口。

<a id="spec-memory-access-context"></a>

#### 2.1.1 访存上下文与队列错误归属

CP 已根据 Queue A 的 HQD 找到 Ring，接下来读取包内容。以下按 `gpuvm=off`、用户 `VMID = 1` 举例，说明固件在访问前保存什么，以及失败后怎样找到所属队列。

```text
CP 正在处理 Queue A，位于 HQD 槽位 2
  │
  │ 固件记录本次访问：
  │   所属槽位 = 2
  │   操作 = 读取 Ring
  │   GPU 物理地址 = 0x4500_0080
  ▼
配置 Host 访存窗口
  窗口基址 = 0x4500_0000
  CP 本地读取地址 = 0x8000_0080
  │
  ▼
经 Outbound 访问 Host IOVA 0x4100_0080
  ├─ 成功：取得数据，继续解析命令
  │
  └─ 失败：触发 CP 访存异常
             │
             ▼
           固件异常处理
             → 根据保存的槽位 2，找到 Queue A
             → 记录队列错误
             → 停止 Queue A 后续取包
```

**[DESIGN]** 固件在访问前保存所属 HQD 槽位、访问阶段和完整目标地址，访问失败后据此区分“读取 Ring 失败”“写回消费进度失败”等情况。队列归属由槽位确定，访问域和用户 VMID 分别保存。处理 KIQ 或 HIQ 的映射命令时，记录来源管理队列、目标种类和 MQD 地址；CP 选定目标槽位后，再记录该槽位，例如“HIQ 正在为 CP 选定的槽位 2 读取 MQD”。尚未选定目标槽位时，错误仍关联到来源管理队列和本次请求。

普通 Host 访问成功时，同步取得读值或完成写请求；失败时进入原生访存异常，由固件按上述上下文处理。能够归属到用户队列的访问错误，记录到该槽位的 `CP_HQD_ERROR`，并停止这条队列后续取包；CP 可以继续处理 KIQ 和其他正常队列。KIQ 实际通道故障，或 CP 固件代码、栈等访问异常时，停止队列调度并保留相关资源，设备恢复留作后续扩展。

失败后不自动重新执行整个任务，也不盲目重试完成更新。例如 Kernel 已执行完、Signal 更新失败时，不能重新运行 Kernel。已经发生的写入保留；停止取包后仍须按卸载或恢复协议确认访问结束，才能释放资源。具体错误编码、Host 通知、失败阶段的收尾及恢复步骤见[第 7 节](#spec-errors-unmap)和 9.6。

<a id="spec-host-atomic-access"></a>
<a id="spec-signal-single-writer"></a>

#### 2.1.2 Signal 的 64 位读写与单一更新者

Host 为任务 T1 准备 Signal S，提交前将 64 位的 `S.value` 初始化为 `1`。发布任务后，Host 只读取这个值，由 CP 在任务成功完成后将它减为 `0`。本阶段一次使用中的 Signal 对应一个任务，不作为多个任务的共享完成计数。

```text
Host 准备任务 T1
  → 将 Host RAM 中的 S.value 初始化为 1（64 位）
  → 发布引用 S 的 Dispatch
  → 此后 Host 只查询或等待，不再修改本次任务的 value

CP 执行任务 T1
  → 确认结果写回并完成任务清理
  → 通过 Host 窗口读取 S.value = 1
  → 在 CP 本地减一，得到 0
  → 通过 Host 窗口将完整的 64 位值 0 写回 S.value

Host 等待任务 T1
  → 观察到 S.value == 0
  → 按完成发布协议读取任务结果
```

**[DESIGN]** `value` 保留 64 位有符号整数，按 8 字节对齐。Host 在提交前初始化为 `1`；从任务发布到本次使用结束，只有 CP 可以更新 `value`，Host 不与 CP 并发写入。CP 在正常完成路径上执行一次“读取、减一、写回”，将 `1` 改为 `0`，无需专门的原子加或原子读改写入口。计算执行器不另行更新同一 Signal。

`S.value` 的 GPU 地址存入 64 位协议槽，高 32 位须为零；按[第 2.5.2 节](#spec-signal-layout)的布局，`value` 位于 Signal 起始地址的偏移 `0x00`。每次任务的完成更新只执行一次；访存失败仍按所属队列记录错误，不盲目重复减一。Host 重新初始化或复用 Signal 前，必须先满足[第 2.5.3 节](#spec-signal-notify-wait)及[第 7.1.7 节](#spec-ih-object-lifetime)已经确定的旧任务、旧通知与对象引用条件；应用释放接口见[9.7.4 的已确认接口](#spec-host-object-release)。

**[BOUNDARY]** 单一更新者省去了并发读改写之间的冲突，仍须保证 Host 与 CP 取得完整的 64 位值，并保证结果写回先于完成值发布。窗口支持对齐的 8 字节读写；完整字段访问遵守[第 2.2.1 节](#spec-shared-value-integrity)，具体可见性操作见[第 6.4 节](#spec-dispatch-visibility)。通知槽标记和防止漏唤醒的等待协议已按[第 2.5.3 节](#spec-signal-notify-wait)确定，中断交付沿用[第 7.1.5 节](#spec-ih-signal-notify)。多更新者的原子读改写列为[后续扩展](<./CP_MEC 软件实现、参考与扩展.md#signal-atomic-extension>)，不作为第二阶段必需接口。

> **[SOURCE]** 实验子仓库固定提交 `57543dd54b6b046b888277272fa84af81746b1ac`：[hw/riscv/gpgpu-cp.c](https://github.com/hxfei-git/gpu-study-qemu/blob/57543dd54b6b046b888277272fa84af81746b1ac/hw/riscv/gpgpu-cp.c#L44) 的 [44–99 行](https://github.com/hxfei-git/gpu-study-qemu/blob/57543dd54b6b046b888277272fa84af81746b1ac/hw/riscv/gpgpu-cp.c#L44-L99)实现普通窗口读写；[hw/remote/vfio-user-obj.c](vscode://file/home/book/1.project/gpu_study/4.experiments/gpu-study-qemu/hw/remote/vfio-user-obj.c:134:1) 的 [134–163 行](vscode://file/home/book/1.project/gpu_study/4.experiments/gpu-study-qemu/hw/remote/vfio-user-obj.c:134:1)按读写方向分别调用消息访问接口。

<a id="spec-shared-state-storage"></a>

### 2.2 进度与完成值的分配和映射

**[DESIGN]** 生产进度、消费进度、管理完成标记和 Signal 均使用驱动分配的 Host RAM 一致性内存，分配与用户映射沿用 `dma_alloc_coherent()`、`dma_mmap_coherent()`。以 Queue A 的一次创建和任务 T1 为例，下图说明 CP 从哪里取得访问目标；`W_A`、`R_A`、`M1` 和 `S1` 是内存位置或对象的名称，用于区分访问目标；进度数值的含义见[第 5.2.1 节](#spec-ring-progress)。

```text
Queue A 的 HQD
  ├─ WPTR_POLL_ADDR：生产进度的读取地址
  │    └─→ Host RAM 中的 W_A
  │          运行时发布进度，CP 读取
  │
  └─ RPTR_REPORT_ADDR：消费进度的回报地址
       └─→ Host RAM 中的 R_A
             CP 回报进度，运行时读取

HIQ Ring 中按顺序排列的管理命令
  ├─ MAP_QUEUES：配置并激活 Queue A
  └─ WRITE_COMPLETION：写完成标记
       └─ 完成地址 → Host RAM 中的 M1
                       CP 完成前面的管理操作后写入，驱动读取

Ring_A 中任务 T1 的 Dispatch
  └─ completion_signal：完成对象的引用
       └─→ Host RAM 中的 Signal S1
             CP 按完成协议更新，运行时等待或查询
```

这里的 `completion_signal` 在 64 位槽中保存 Signal S1 的 GPU 地址，字段与通知槽的关系见[第 2.5 节](#spec-signal-representation)。M1 是保存标记值的内存位置，HIQ 中的第二条命令执行向 M1 写值的操作；KIQ 建立 HIQ 时也采用同一管理队列内后附标记的形式，见[管理命令与完成确认](#spec-management)。

- **进度区按队列分配。** 每条队列独立分配一块进度内存，生产进度与消费回报均保存 32 位数值，使用其中不同的位置，各位置至少按 8 字节对齐，与 Ring 包槽分开。用户队列的进度区映射给所属应用；运行时写生产进度、读消费进度，CP 执行相反方向的访问。KIQ、HIQ 也各有独立进度区，由驱动承担 Host 侧读写，不映射给普通应用。进度区在创建队列时准备，卸载并满足回收条件后释放。
- **管理标记按管理请求使用。** 驱动单独管理一块完成标记区，按请求分配结果区。每个在途管理请求独占 16 字节，至少按 8 字节对齐，包含 8 字节完成标记、4 字节结果码和 4 字节保留空间，仅供驱动和 CP 访问。`WRITE_COMPLETION` 携带结果区起始地址和待写入的 64 位无符号序号，先写结果码、再写完成标记，命令布局见[第 4.1 节](#spec-management-packet-format)，结果区布局见[第 4.4 节](#spec-management-result)。结果区的保留与回收由管理请求控制，不与目标队列的进度区绑定；驱动确认卸载结果并满足生命周期条件后，再回收目标队列资源。标记初值为 0、预期值使用递增序号，等待和复用规则见[第 4.3 节](#spec-management-marker)。
- **Signal 按应用上下文管理。** 调用方经内存接口申请驱动分配的 Host 共享块，映射到所属应用，并在本上下文中按需布置、初始化和使用 Signal。该区域可以作为内存池，不要求每个 Signal 单独占用整页。Signal 的生命周期独立于 Ring 槽和具体队列；任务 T1 完成且包槽已复用时，只要应用还在使用 S1，就不能将 S1 分给新任务。本阶段一次使用中的 Signal 只对应一个任务，重新初始化沿用[通知与对象寿命条件](#spec-signal-notify-wait)，应用释放接口见[9.7.4 的已确认接口](#spec-host-object-release)。

**[BOUNDARY]** 本节确定存储位置、分配归属和映射范围。普通进度和管理标记通过 CP Host 窗口读写；Signal 按[单一更新者规则](#spec-signal-single-writer)由 Host 初始化、CP 完成时减为 `0`。动态字段的完整读写要求见下节，具体字段编码及失败收尾按第 9 节的已确认约定执行。一次提交中四类值的配合见[进度与完成值的使用过程](<./CP_MEC 软件实现、参考与扩展.md#shared-state-usage>)。

<a id="spec-shared-value-integrity"></a>

#### 2.2.1 动态字段的完整读写

Host 等待任务完成时会读取 Signal，CP 则在完成路径中更新同一字段。管理完成标记和通知槽也有读写交错的情况。一次读取必须取得完整值，不能把两次更新中的不同部分拼在一起：

```text
CP 正在更新一个 64 位值
          ↓
Host 只能读到完整旧值或完整新值
不能读到“高半部是新的、低半部是旧的”
```

**[DESIGN]** Signal 的 `value`、管理完成标记和通知槽中的 64 位字段均至少按 8 字节对齐。Host 与 CP 每次按完整的 64 位值读取或写入，不采用拆成两个 32 位、反复读取再拼接的协议。Signal 保留 64 位有符号含义，管理完成标记保留 64 位无符号含义；具体布局仍按各对象的约定确定。

生产进度 `W` 和消费回报 `R` 沿用[第 5.2.1 节](#spec-ring-progress)的 32 位数值，每次按完整的 32 位值访问，存放位置继续至少按 8 字节对齐。

完整读取和写入是 Host、CP 与 QEMU 访存后端共同承担的接口要求，覆盖指令、窗口回调、消息传输到最终内存访问的路径。CP 发出一次 `LD/SD` 或消息长度为 8 字节，只能说明访问形式；后端仍须保证读取方取得完整旧值或完整新值。当前代码保留等宽访问。2026-10-19 的 CP 并发读写结果作为历史记录，不列入当前执行要求；记录及端到端验收状态见[大纲进度说明](<./QEMU GPGPU 实验大纲.md#current-progress>)。

字段值完整，还须满足相关数据的发布顺序。AQL 继续按[第 5.2.2 节](#spec-aql-reserve-publish)先更新 `W` 预留，再填写包体、发布有效 Header；CP 确认 Header 有效并保证包体可见后才解析。按[第 6 节](#spec-dispatch-completion)，CP 确认结果写回后发布 Signal，结束旧槽访问并将 Header 置为 `INVALID` 后回报新 `R`；Host 完成相应同步后，才读取结果或复用槽。具体屏障须结合 Host 映射、CP 窗口和后端落实并验证。

**[BOUNDARY]** Signal 继续由 CP 单独更新，不增加原子读改写入口；固定地址配置仍按原有高低位寄存器和配置完成规则处理。AQL 首部按[第 5.2.2 节](#spec-aql-header-access)以完整的 32 位值访问，提交者模型已按 9.4.4 确认；通知槽布局与唤醒流程已按 9.5.4 确认。

<a id="spec-kernel-data-storage"></a>

### 2.3 Kernel 代码、参数块与数组的存储和访问

**[DESIGN]** 现有三个示例固定把代码、描述对象和数组放在 VRAM，把参数及队列相关对象放在 Host coherent 存储。库返回统一的 `gpu_address`，调用方用该值填写描述对象、AQL 和参数中的数组指针；参数的 `cpu` 映射供 Host 填写数据。

以向量加法为例，下面设 `gpuvm=off`、VRAM 为 64 MiB，参数的 Host IOVA 为 `0x4100_2000`：

```text
Dispatch.kernel_object = 0x4000 → VRAM 中的16字节描述对象
  └─ code_entry = 0x8000 → 执行器经公共入口从 VRAM 取指

Dispatch.kernarg_address = 0x4500_2000 → 启动时 a0 = 0x4500_2000
  └─ 普通内存读取 → Outbound → Host IOVA 0x4100_2000 的参数块
       ├─ X = 0x1_0000 → VRAM 中的 X
       ├─ Y = 0x2_0000 → VRAM 中的 Y
       ├─ Z = 0x3_0000 → VRAM 中的 Z
       └─ N → 元素数量
```

开启 GPUVM 时流程相同，但这些字段使用绑定返回的 GPUVA，先由所属 VM 页表翻译，再进入公共物理入口。CP 读取描述对象和 Kernel 取指都走这一入口，关闭 GPUVM 时也能访问 Outbound，不保留只许 VRAM 的旁路。

Host 发布前准备好全部内容，发布后保持代码、参数、数组和 Signal 的存储有效，直到确认任务不再访问。Kernel 参数读取使用真实 `a0`，不经过 CP 的本地窗口，也不经过旧 RV32 参数窗口；完整启动和范围规则见[第 6.2 节](#spec-kernel-descriptor)。

<a id="spec-address-values"></a>

### 2.4 GPU 地址的编码与访问域

驱动已为 Queue A 绑定 Ring，接下来把 Ring 的 GPU 地址交给 CP。下例使用关闭 GPUVM 时的物理地址，窗口换算条件与上节相同：

```text
Host IOVA 0x4100_0000 → Ring 的 GPU 物理地址 0x4500_0000
  → 驱动填写 MQD.ring_base = 0x4500_0000
  → HIQ 管理命令提供 MQD 的 GPU 物理地址
  → CP 按管理域读取 MQD，再配置 HQD
      ├─ CP_HQD_PQ_BASE = 0x4500_0000
      ├─ CP_HQD_PQ_BASE_HI = 0
      └─ VMID = 1
  → CP 按用户域读取 Ring → 公共物理入口 → Host IOVA 0x4100_0000
```

**[DESIGN]** 协议字段仍按原宽度保存字节地址，两个 32 位寄存器分别保存低、高位，不预先右移压缩。版本 2 的 GPU 存储地址限定为 32 位，64 位字段的高 32 位须为零；地址加长度等计算用 64 位，先校验再缩窄。

用户 Ring、进度、描述对象、参数、Signal 和通知槽使用 GPUVA 或 GPU 物理地址，取决于设备 `gpuvm` 属性。管理 Ring、MQD、管理完成区、IH 与 COPY 物理端点一律保存 GPU 物理地址。`dma_addr_t` 只供驱动的 DMA API 使用，不能直接填入这些设备字段。Host CPU 指针也不写入 GPU 地址字段。

<a id="spec-shared-endian"></a>

#### 2.4.1 共享对象中的小端字段

设 GPUVM 关闭，Host 已取得 Signal S 的 GPU 物理地址 `0x4500_3000`，接下来把它写入 Dispatch 的 `completion_signal` 字段。CP 读取这个 64 位字段时，需要按相同的字节顺序还原地址：

```text
completion_signal 的数值 = 0x4500_3000
         │
         │ Host 按小端写入 Dispatch 中的 8 字节字段
         ▼
字段内偏移： +0  +1  +2  +3  +4  +5  +6  +7
对应字节：   00  30  00  45  00  00  00  00
         │
         │ CP 按小端读取这 8 个字节
         ▼
还原物理地址 = 0x4500_3000
```

**[DESIGN]** Ring 命令、MQD、Signal、通知槽、Kernel 描述对象和参数块中的多字节字段统一采用小端格式：低地址存低有效字节，高地址存高有效字节。该规则同时适用于 Host RAM 和 VRAM 中的这些对象；驱动、运行时、CP 和计算执行器按同一规则读写各自访问的字段。图中的 `00`、`30` 等均为十六进制字节。

小端规则规定一个字段内部的字节排列，地址的数值含义和低、高 32 位寄存器拆分规则仍按第 2.4 节执行。字段顺序、偏移、保留空间和对象总大小在各自的布局中确定，最低对齐要求统一按第 2.4.2 节执行。

<a id="spec-address-validation"></a>

#### 2.4.2 地址位宽、对象对齐与访问校验

CP 已从 Dispatch 取得描述对象的 GPU 地址，接下来要读取描述对象并取得代码入口。沿用第 2.3 节的取值，先检查字段和访问范围，再把入口交给计算执行器：

```text
CP 取得 kernel_object：64 位无符号地址，数值为 0x4000
  → 检查高 32 位为零、描述对象地址按 8 字节对齐
  → 按描述对象大小检查完整 GPU 地址范围
  → 按用户域读取 GPU 地址 0x4000 处的描述对象
  → 取得其中的代码入口地址：32 位无符号数，数值为 0x8000
  → 交给 RV32 计算执行器
  → 执行器检查入口按 4 字节对齐，并检查实际访存范围
```

**[DESIGN]** `kernel_object`、`kernarg_address` 和 `completion_signal` 保留 64 位字段，保存用户 GPU 地址并检查高 32 位为零。代码入口与参数中的数组地址为 32 位，转换前检查完整范围。公共物理入口拒绝跨 VRAM／Outbound 边界的非法范围，用户访问继续保护 VRAM 首页和固件保留区；开启翻译时还检查映射及权限。

**[DESIGN]** 对象采用以下最低对齐要求：

- 用户 AQL Ring、KIQ Ring、HIQ Ring 的起始地址按 64 字节对齐。
- KIQ、HIQ 中每条管理命令固定为 32 字节，命令起点按 32 字节对齐，字段布局见[第 4.1 节](#spec-management-packet-format)。
- MQD、Kernel 描述对象、参数块、生产／消费进度存放位置和管理完成标记位置，至少按 8 字节对齐。Signal 和通知槽沿用第 2.5 节的 8 字节对齐要求。
- RV32 Kernel 代码入口按 4 字节对齐；普通数组按元素类型自然对齐，例如 32 位元素按 4 字节对齐。
- 结构内的多字节标量字段按自身宽度自然对齐，例如 32 位字段按 4 字节、64 位字段按 8 字节对齐。

驱动在创建和配置对象时检查，CP 在解析对象引用时检查，计算执行器检查实际执行的访存。检查内容包括地址对齐、乘加计算不溢出，以及整段访问范围有效。VRAM 访问必须完整落在实际容量内；Host RAM 访问还必须处理访存接口返回的错误。

校验失败就拒绝该次访问，不截断地址、不自动调整地址。访存过程中发生的失败交给错误协议处理，不承诺撤销已经发生的写入。用户 VMID 为 1、2；开启 GPUVM 时按页表隔离，关闭时共享物理空间；访存失败按[第 2.1.1 节](#spec-memory-access-context)关联当前队列并停止相应取包，具体错误码、通知及失败收尾已按第 7 节和 9.6 确认。

**[BOUNDARY]** 这些是教学设备的接口约定，不套用 AMD 的完整对象布局。MQD 布局已在 9.2.1 确认，见[第 2.6 节](#spec-mqd-format)；管理命令布局已在 9.3.2 确认，见[第 4.1 节](#spec-management-packet-format)。进度值采用[第 5.2.1 节](#spec-ring-progress)确定的 32 位包编号；Kernel 描述对象、参数布局和启动接口按版本 2 更新，见[第 6.2 节](#spec-kernel-descriptor)；Signal 的 24 字节布局及通知、等待协议已按[9.5.4](#spec-signal-completion-protocol)确定，见[第 2.5.2 节](#spec-signal-layout)和[第 2.5.3 节](#spec-signal-notify-wait)。

<a id="spec-signal-representation"></a>

### 2.5 Signal 的 GPU 地址、字段位宽与对齐

运行时为任务 T1 准备 Signal S，将 S 的引用填入 Dispatch。CP 取得这个引用后，需要找到完成值和通知信息；Host 驱动则需要根据事件编号找到等待线程。

**[DESIGN]** 本实验的 `completion_signal` 在 64 位槽中保存 S 的用户 GPU 地址。S 保存完成值 `value`、事件编号 `event_id` 和通知槽地址 `event_mailbox_ptr`；通知槽也位于 Host RAM。下面设 GPUVM 关闭，地址和事件编号为示例；初值 `1` 与 CP 完成后减为 `0` 的规则见[第 2.1.2 节](#spec-signal-single-writer)，图中不规定字段偏移和完整通知协议：

```text
AQL Dispatch
  └─ completion_signal：64 位
       保存 S 的物理地址 = 0x4500_3000
         │
         │ CP 按物理地址访问 Host RAM
         ▼
Host RAM 中的 Signal S
  ├─ value：64 位有符号整数
  │    └─ 保存完成计数，本例初值为 1
  │
  ├─ event_id：32 位无符号整数
  │    └─ 保存事件编号，本例为 7
  │
  └─ event_mailbox_ptr：64 位
       保存 M7 的物理地址 = 0x4500_4000
         │
         │ CP 需要发送完成通知时，按这个地址写入
         ▼
Host RAM 中的通知槽 M7
  └─ 64 位通知标记

Host 驱动
  └─ 所属进程的事件表
       └─ 编号 7 → Event E7 → 等待队列 → T0
```

`completion_signal` 和 `event_mailbox_ptr` 均按无符号 64 位地址解释。CP 先用包中的物理地址访问 S，再用 S 中的物理地址访问通知槽 M7；Host 软件通过自己的映射准备这些对象。驱动按所属进程和 `event_id` 查找事件及等待队列。事件表的具体实现不在本节规定。

**[DESIGN]** Signal 起始地址、其中的 64 位字段以及通知槽地址均至少按 8 字节对齐。`value` 使用 64 位有符号整数，`event_id` 使用 32 位无符号整数，通知槽保存 64 位标记。图中展示对象引用关系，Signal 的具体偏移、保留字段和 24 字节总大小见[第 2.5.2 节](#spec-signal-layout)。

**[BOUNDARY]** 本节不增加设备虚拟地址或页表翻译。Signal 按[单一更新者规则](#spec-signal-single-writer)使用 64 位值：Host 提交前置 `1`，提交后只读，由 CP 完成时减为 `0`，Host 等待值为 `0`。完整字段读写已按[第 2.2.1 节](#spec-shared-value-integrity)确定，通知按[第 7.1.5 节](#spec-ih-signal-notify)依次更新完成值、写通知槽、发布 IH 记录并中断通知 Host。Signal 布局、通知槽标记和防止漏唤醒的等待协议已按 9.5.4 补齐；具体可见性操作已按[第 6.4 节](#spec-dispatch-visibility)确定，资源回收接口已按[9.7.4](#spec-host-object-release)确定。

<a id="spec-signal-blocked-wait"></a>

#### 2.5.1 默认等待先短暂轮询，再进入内核事件等待

Host 已发布任务 T1，接下来等待 `S.value == 0`。第二阶段默认采用 `HSA_WAIT_STATE_BLOCKED` 对应的等待方式，由实验运行时先读取完成值，必要时经 Host 驱动进入事件等待。以下按 Signal 有效、任务尚无已知错误的正常路径说明：

```text
Host 开始等待 S.value == 0
  → 先读取 S.value
       ├─ 已经是 0：完成必要的同步后返回
       └─ 仍然是 1：短暂主动轮询
                        │
                        └─ 仍未完成、也未超时
                             → 进入 Host 内核事件等待，线程睡眠
                             → 设备通知到达，驱动唤醒线程
                             → 再读 S.value，判断条件
```

**[DESIGN]** 主动轮询预算为约 `200 μs`，从本次等待开始计时。等待条件提前满足时直接结束等待；等待期限先到时按超时规则返回，不要求先用完轮询预算。约 `200 μs` 后仍未完成且未超时，才进入内核事件等待。唤醒后复查 `S.value`；若仍未满足条件且未超时，继续事件等待，不重新计算一轮 `200 μs` 的主动轮询预算。

阻塞等待依赖设备通知和 Host 驱动的事件处理。[正常完成通知](#spec-ih-signal-notify)经 IH 记录交付，驱动用记录中的 MQD 地址找到队列所属进程，再按 `event_id` 找到等待事件。驱动保存“已通知”状态，在登记等待者后再次检查条件，处理通知先到、线程后登记的情况；具体规则见[第 2.5.3 节](#spec-signal-notify-wait)。`S.value` 更新与读取结果之间的同步规则见[第 6.4 节](#spec-dispatch-visibility)，错误退出按[第 7.3 节](#spec-failure-retirement)执行，事件查询、等待的返回值与超时参数见[9.7.4 的已确认接口](#spec-host-task-wait)。

**[DESIGN]** 第二阶段只提供上述默认等待方式，`HSA_WAIT_STATE_ACTIVE` 的持续主动等待列为[后续扩展](<./CP_MEC 软件实现、参考与扩展.md#signal-active-wait-extension>)。默认方式开头的短暂轮询属于本阶段流程；运行时的单次查询接口也不等同于持续主动等待模式。

> **[SOURCE]** ROCr 固定版本 `ba56a24c6132c5d195686ae4adf969ca1222fbba`：[runtime/hsa-runtime/core/runtime/interrupt_signal.cpp](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/interrupt_signal.cpp:138:1) 的 [138–198 行](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/interrupt_signal.cpp:138:1)在等待开始时记录时间，设置 `200 μs` 阈值，并在主动检查、超时判断和内核事件等待之间选择；[201–207 行](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/interrupt_signal.cpp:201:1)补充 acquire 同步。这是本实验默认等待方式的参考。

<a id="spec-signal-layout"></a>

#### 2.5.2 Signal 的 24 字节布局

Host 为任务 T1 准备 Signal S，CP 根据 Dispatch 中的 `completion_signal` 找到 S。沿用前文已确定的 Host RAM 位置、字段位宽和最低对齐，本节补齐具体布局：

```text
偏移 0x00：value              64 位有符号数，提交前为 1
偏移 0x08：event_id           32 位无符号事件编号
偏移 0x0c：reserved           32 位，填 0
偏移 0x10：event_mailbox_ptr  64 位通知槽 GPU 地址
总大小：24 字节
```

**[DESIGN]** Signal 位于 Host RAM 一致性内存，起始地址至少按 8 字节对齐，所有多字节字段采用小端格式。偏移 `0x0c` 的 4 字节保留字段用于让后面的 64 位地址自然对齐。完整 24 字节对象和通知槽的对齐、地址溢出及访问范围按[第 2.4.2 节](#spec-address-validation)检查。这是本实验的布局，不套用 AMD 的完整 Signal 对象格式。

Host 在发布任务前填好 Signal，提交后保持固定字段不变，完成值仍按单一更新者规则由 CP 更新一次。CP 在发布完成值前取得并保存通知所需的事件编号和通知槽地址，之后按保存的信息完成通知。

<a id="spec-signal-notify-wait"></a>

#### 2.5.3 通知槽标记与防止漏唤醒的等待登记

以下仍使用 Signal S、事件编号 7 和通知槽 M7。完成值、默认等待方式和 IH 交付顺序沿用前文，本节补齐通知槽写入值及驱动如何记住提前到达的通知：

```text
Host 准备 Signal S
  → value = 1，event_id = 7，通知槽初值为 0
  → 发布 Dispatch
          ↓
CP 确认计算完成、结果写回
  → S.value：1 → 0
  → 向通知槽写入 7
  → 提交 SIGNAL_NOTIFY，事件编号为 7
          ↓
驱动找到所属进程中的事件 E7
  → 记住“通知已经到达”
  → 唤醒等待线程
          ↓
Host 重新读取 S.value
  → 确认等于 0，完成同步后返回
```

**[DESIGN]** 每个使用中的 Signal 独占事件和通知槽。驱动在所属进程内分配非零的 32 位无符号 `event_id`，同一进程中存活事件的编号不能重复。通知槽占 8 字节，至少按 8 字节对齐，提交前初始化为 `0`；CP 完成时写入零扩展到 64 位的 `event_id`，本例写入 `7`。

驱动处理对应 IH 记录时，用 `mqd_addr` 找到队列所属进程，再按 `event_id` 找到事件，确认事件与通知槽的关联。在事件对象中记录“已通知”后，再清零通知槽并唤醒等待者。事件状态保存在驱动内部，不占用 Signal 的保留字段。

清零通知槽不清除事件对象中的“已通知”状态。Signal、事件和通知槽只有在旧通知及相关处理全部结束后，才能按资源复用协议重新初始化；不能只因 `S.value == 0` 就立即复用事件编号或通知槽。复用继续遵守[旧记录与对象寿命](#spec-ih-object-lifetime)，具体资源接口已按 9.7 确认。

**[DESIGN]** 默认等待仍先检查 Signal，约 `200 μs` 后仍未完成且未超时，再进入内核事件等待。驱动中的通知处理与等待登记必须正确同步，通知状态与等待者的关联不能在竞争中丢失：

```text
通知先到：
  驱动保存“已通知”
    → 线程随后请求等待
    → 发现通知已到，直接返回复查 Signal

线程先进入等待：
  登记等待者
    → 再次检查通知状态
    → 尚未通知才睡眠
    → 驱动先保存通知状态，再唤醒线程
```

等待返回不清除“已通知”状态；同一任务有多个等待线程时，可以一并唤醒。线程最终仍通过 `S.value == 0` 判断成功，重复唤醒不会重复修改 Signal。等待期限、唤醒后的复查以及不重新开始一轮主动轮询的规则继续按[第 2.5.1 节](#spec-signal-blocked-wait)执行。

> **[SOURCE]** Linux 固定基线 `248951ddc14de84de3910f9b13f51491a8cd91df`：[include/linux/wait.h](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/linux/include/linux/wait.h:302:1) 的 [302–351 行](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/linux/include/linux/wait.h:302:1)在登记等待后复查条件，并要求通知方先改变等待条件，再唤醒线程。

**[BOUNDARY]** 本节与第 2.5.2 节已按[9.5.4](#spec-signal-completion-protocol)确认。具体内存屏障见[第 6.4 节](#spec-dispatch-visibility)；Signal 访问失败、通知失败和错误唤醒按第 7 节执行，资源管理接口已按[9.7](#spec-host-api-scope)确认。

<a id="spec-mqd-format"></a>

### 2.6 MQD 的字段布局与装载、保存范围

驱动已经为 Queue A 准备好 Ring 和进度内存，接下来把这些对象的地址写进 MQD_A。CP 根据管理命令选择空闲用户槽位并找到 MQD_A，本例假设选中槽位 2。下面按正常装载、运行和卸载的顺序展示这份描述对象的使用过程：

```text
Host 驱动填写 Host RAM 中的 MQD_A
  ├─ 队列配置：Ring 地址、进度地址、容量控制、Doorbell、VMID、格式
  └─ 保存状态：saved_rptr、saved_error；首次均为 0
       │
       │ HIQ 中的 MAP_QUEUES 携带 queue_kind = USER_AQL、MQD_A 物理地址
       ▼
CP 选择空闲用户槽位，本例选中槽位 2；读取并校验 MQD_A
  → 把 MQD_A 自身地址写入 HQD 的 CP_MQD_BASE_ADDR / HI
  → 把 MQD_A 中的队列配置装入 HQD
  → 从 saved_rptr 恢复消费位置，从 wptr_poll_addr 读取当前生产进度
  → 最后设置 ACTIVE = 1
       │
       ▼
Queue A 驻留期间
  → CP 使用 HQD 中的配置和消费位置处理命令
  → 消费进度另行回报到 rptr_report_addr 指向的 Host RAM
       │
       │ Host 停止提交并排空 Queue A，再经 HIQ 提交 UNMAP_QUEUES
       ▼
CP 开始卸载：清除 ACTIVE、关闭 Doorbell 使能，槽位仍占用
  → 确认目标队列相关在途访问已经结束
  → 将 32 位消费位置零扩展到 64 位，写入 MQD_A.saved_rptr
  → 将错误快照写入 MQD_A.saved_error
  → 达到卸载完成条件后，按管理结果和完成标记协议通知 Host
```

**[DESIGN]** KIQ、HIQ 和用户 AQL Queue 共用以下 MQD 布局。每个对象占 **64 字节**，位于驱动分配的 Host RAM 一致性内存中，起始地址至少按 **8 字节对齐**。多字节字段采用小端格式；除保留字节外，下列字段均为无符号整数。偏移从 MQD 起始地址计算：

```text
MQD：64 字节，偏移范围 0x00～0x3f
  ├─ 0x00  ring_base          64 位 / 8 字节：Ring 的 GPU 地址
  ├─ 0x08  rptr_report_addr   64 位 / 8 字节：消费进度回报位置的 GPU 地址
  ├─ 0x10  wptr_poll_addr     64 位 / 8 字节：生产进度存放位置的 GPU 地址
  ├─ 0x18  pq_control        32 位 / 4 字节：Ring 容量与控制
  ├─ 0x1c  doorbell_control  32 位 / 4 字节：队列 Doorbell 配置
  ├─ 0x20  vmid              32 位 / 4 字节：管理队列为 0，用户队列为 1 或 2
  ├─ 0x24  aql_control       32 位 / 4 字节：0 为非 AQL，1 为 AQL
  ├─ 0x28  saved_rptr        64 位 / 8 字节：零扩展保存 32 位消费位置，高 32 位为 0
  ├─ 0x30  saved_error       32 位 / 4 字节：卸载时保存的错误快照
  └─ 0x34～0x3f reserved              12 字节：保留
```

`ring_base`、`rptr_report_addr` 和 `wptr_poll_addr` 管理队列保存 GPU 物理地址，用户队列保存本模式的 GPU 地址，分别装入 HQD 的 `CP_HQD_PQ_BASE / HI`、`CP_HQD_PQ_RPTR_REPORT_ADDR / HI` 和 `CP_HQD_PQ_WPTR_POLL_ADDR / HI`。每组地址按[第 2.4 节](#spec-address-values)直接拆成低、高 32 位。四个配置字段分别对应 HQD 的 Ring 控制、Doorbell 控制、VMID 和 AQL 控制寄存器；`pq_control` 保存 Ring 字节容量，`doorbell_control` 保存偏移和独立使能，完整编码见[第 8.1 节](#spec-hqd-field-encoding)。

**[DESIGN]** 驱动和 CP 按以下规则使用这份布局：

1. **首次初始化。** 每条存活队列使用独立的 MQD。驱动填写配置，并把 `saved_rptr`、`saved_error` 和保留区清零。从发布映射请求到成功卸载，驱动保持配置字段不变；相关管理操作和卸载收尾完成前，MQD 内存及其物理地址保持有效，不释放或复用。首次启动的 KIQ 由 Host 按同一套配置填写 HQD，再按第 3 节启动 CP。
2. **装载与激活。** `MAP_QUEUES` 提供目标队列种类和 MQD 物理地址；CP 根据种类确定可用的 HQD 范围，并为用户队列选择空闲槽位，再读取、校验并装入配置，恢复消费位置，最后激活。MQD 不重复保存自身地址，也不保存 `ACTIVE`；两者分别来自管理命令和装载流程。错误队列按[第 7.2.4 节](#spec-queue-error-rebuild)清理后重建；未绑定 MQD 的 `saved_error` 非零时拒绝激活，返回参数非法结果 `status = 4`，重新映射不清错或重放失败任务。
3. **驻留与卸载保存。** 驻留期间 CP 在 HQD 中维护活动状态，不在每个包完成后更新 MQD。正常卸载前由 Host 排空队列；CP 开始卸载时清除 `ACTIVE`、关闭 Doorbell 使能，确认相关在途访问结束后，只写回 `saved_rptr` 与 `saved_error`，配置字段保持原值。保存失败继续保留槽位占用，能够安全回报时按[第 4.4 节](#spec-management-result)返回结果码 `5`；目标队列尚无错误时记录编号 `10`，已有首次错误时保留原值，见[第 7.2.3 节](#spec-management-error-separation)。异常退出按[第 7.3 节](#spec-failure-retirement)处理，需要强制停止或故障复位的处理列入[后续异常恢复扩展](<./QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)，正常回收继续遵守已确认的对象寿命条件。
4. **重新装载。** 正常成功卸载后，CP 从 `saved_rptr` 恢复消费位置；生产进度始终从 `wptr_poll_addr` 指向的共享内存读取，MQD 不缓存一份生产进度。正常重装要求 `saved_error = 0`；错误快照非零的队列须按[清理后重建规则](#spec-queue-error-rebuild)处理，不直接清错续跑。

**[DESIGN]** 消费进度 `R` 表示下一待消费包的编号，采用 32 位无符号数。卸载保存时，CP 将 HQD 中的完整 `R` 零扩展写入 64 位 `saved_rptr`；正常重新装载先检查高 32 位为零，再恢复低 32 位，高位非零则拒绝配置。例如当前 `R = 7`：

```text
HQD 中 R = 7（32 位）
  → 卸载保存：saved_rptr 的高 32 位 = 0，低 32 位 = 7
  → 正常重装：检查高 32 位为 0，再把低 32 位的 7 装回 HQD
  → 从共享内存读取保留的生产进度 W，继续处理剩余包
```

进度初值、包地址、满空判断和计数溢出的规则见[第 5.2.1 节](#spec-ring-progress)。MQD 不随每个包更新，正常重装也不清零已保存的进度。

**[BOUNDARY]** 故障队列清除 `ACTIVE` 并保留占用，按[第 7.2 节](#spec-queue-error-policy)处理。正常卸载前排空、清除 `ACTIVE` 和关闭 Doorbell 的规则见[第 7.4 节](#spec-unmap-drain)，任务卡住后的强制停止和复位恢复列入[后续异常恢复扩展](<./QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)。

<a id="spec-boot"></a>

## 3. 固件装载、KIQ 配置与 CP 启动

<a id="spec-firmware-layout"></a>

### 3.1 固件存储与已有控制寄存器

Host 装载固件后，CP 要持续从 VRAM 取指，并使用其中的栈和全局数据。驱动为 Kernel 和应用数据分配显存时，需要避开这些空间。

**[DESIGN]** 第二阶段采用 64 MiB VRAM 配置。Linux 内核驱动维护设备统一的显存管理功能，管理从偏移 0 开始的前 60 MiB；最后 4 MiB 固定保留给 CP 固件。下面的地址均为 VRAM 字节偏移，不引入设备虚拟地址：

```text
VRAM：0x0000_0000 ～ 0x03ff_ffff（64 MiB）
│
├─ Linux 内核驱动统一管理：0x0000_0000 ～ 0x03bf_ffff（60 MiB）
│    ├─ 首个 Host 页：登记为保留，避免普通显存分配结果为 0
│    └─ 其余空间：由驱动分配、记录占用和回收
│         └─ Kernel 描述对象、Kernel 代码、X/Y/Z 等应用数据
│
└─ CP 固件保留区：0x03c0_0000 ～ 0x03ff_ffff（4 MiB）
     │
     ├─ 0x03c0_0000 ～ 0x03fe_ffff（4032 KiB）
     │    ├─ 固件入口：0x03c0_0000
     │    ├─ 固件代码、只读常量
     │    ├─ 已初始化的全局变量
     │    └─ 启动时清零的全局变量、静态工作区
     │
     └─ 0x03ff_0000 ～ 0x03ff_ffff（64 KiB）
          └─ CP 栈，向低地址增长
               初始 sp = 0x0400_0000
```

CP 地址 `0～vram_size-1` 对应 VRAM 的相同字节偏移。Host 经 `BAR2 基址 + 0x03c0_0000` 写入入口代码，将 `CP_RESET_VECTOR` 设置为 `0x03c0_0000`；解除复位后，CP 从这个本地地址取指。Host 的 BAR 总线地址不能直接填入 CP 入口寄存器。

固件按固定入口链接，第一版不处理运行地址重定位。链接脚本安排代码、只读常量、全局变量和静态工作区，检查它们完整落在前 4032 KiB 内，不得越入栈区。Host 装载时检查目标范围，固件内容越界就拒绝装载。`sp` 初始指向栈区末尾的后一位置，压栈时先减小，再访问栈内地址；栈预算为 64 KiB。4 MiB 是固定保留容量，后续若调整容量或地址布局，须同步修改链接脚本和驱动中的范围定义。

驱动中的显存管理功能按设备维护一份统一的空闲、占用和保留状态，记录已分配区间及其所属上下文，负责实际 VRAM 空间的分配与回收。管理范围从偏移 0 开始，覆盖完整的前 60 MiB；首个 Host 页也由该功能登记为保留，普通分配从保留页之后开始。

**[DESIGN]** 参考 AMD 驱动的做法，底层复用内核通用伙伴分配器：目标内核提供 `gpu_buddy` 时使用该接口；目标内核仍提供 `drm_buddy` 时使用对应实现。驱动按设备建立一个分配器实例，管理前 60 MiB，并负责请求校验、并发保护、对象归属及释放时机。普通显存对象仍申请固定连续区间；开启 GPUVM 时由页表映射到该物理区间，关闭时绑定直接返回物理地址。

```text
应用通过运行时申请 VRAM
  → Linux 内核驱动检查大小、对齐和其他请求条件
  → 调用 gpu_buddy 或目标内核的 drm_buddy，从前 60 MiB 分配区间
  → 驱动记录占用与所属上下文，将分配结果交给运行时
  → 运行时准备数据，CP 和执行器按对象绑定返回的 GPU 地址访问 VRAM
  → 设备访问结束且满足资源释放条件后，驱动调用分配器回收区间
```

QEMU 提供显存存储和设备访问接口；应用、运行时和 CP 使用驱动已经分配的显存对象。通用伙伴分配器组织空闲块并完成分配、拆分、回收与合并，驱动维护对象所属上下文及使用状态。构建时须核对目标内核的头文件、配置与导出符号，并启用对应组件；两种接口的关系和 AMD 依据见[通用伙伴分配器说明](<./CP_MEC 软件实现、参考与扩展.md#vram-buddy-allocator>)。

末尾 4 MiB 固件保留区不进入普通显存分配池。这块保留区属于设备，应用退出、队列销毁或 CP 暂时复位都不释放它。更新固件前先停止 CP，并确认相关设备访问已经结束；CP 单独复位的影响见第 3.3 节。

**[BOUNDARY]** 用户访问在公共入口继续保护 VRAM 首页和固件存储区。当前工作区保留固定固件链接布局与启动初始化，任务统一经队列提交；代码与测试说明见[实现说明](<./CP_MEC 软件实现、参考与扩展.md#implementation>)。

BAR 写入、DMA 写入、计算解释器写入和冷复位清零都应使对应 TCG 指令翻译失效，支持在相同地址替换固件。以下控制寄存器已经接入：

`0x0500 CP_CTRL` 与 `0x0504 CP_RESET_VECTOR` 都采用对齐、小端的 32 位访问。

`CP_CTRL` 的 bit 0 是可读写的 `RESET_HOLD`，默认 1；bit 1 是只读的 `PRESENT`。连接 CP 的设备默认读回 3，解除复位后读回 2。写入相同复位状态不会重新启动 CPU，保留位读零、写入忽略，`PRESENT` 的写入也忽略。置位 `RESET_HOLD` 恢复 CP 的原生复位状态，并持续阻止取指；清零后从已配置的入口运行。

`CP_RESET_VECTOR` 保存 CP 地址空间中的 32 位入口，默认 0。只有保持复位时可以修改；入口必须位于 VRAM 内且按 2 字节对齐。有效修改同步更新 CPU 的复位向量和复位态 PC。非法地址或运行期间修改入口会保留原值，并置位已有 `ERROR_STATUS.INVALID_CMD`。

没有连接 CP 的单进程设备对这两个寄存器读零、写入忽略。

### 3.2 配置并激活 KIQ 后解除复位

版本 2 先在 CP 保持复位、没有活跃 HQD 或在途访问时配置 Outbound，并读取确认状态；随后按下列顺序配置 IH、KIQ 和固件。两种 GPUVM 状态都必须核对设备版本与固件握手值为 2。

**[DESIGN]** 队列模式在固件启动流程中配置 KIQ，顺序如下：

```text
Host 写 CP_CTRL.RESET_HOLD = 1，读回确认
  → 经 BAR2 将固件代码和已初始化数据装入固定保留区
  → 设置 CP_RESET_VECTOR = 0x03c0_0000
  → 准备 KIQ Ring、MQD 和相关内存，保持 KIQ 槽位 ACTIVE = 0
  → 通过 HQD 窗口填写 Ring 地址、容量、指针、MQD 地址、Doorbell 配置和队列格式
  → 保证配置和内存初始化对 CP 可见
  → 最后设置 KIQ 槽位 ACTIVE = 1
  → 执行访问屏障，读回确认写入完成
  → 写 CP_CTRL.RESET_HOLD = 0
  → CP 从固定入口执行固件，设置 sp = 0x0400_0000
  → 清零未初始化全局变量，初始化异常处理和内部状态
  → 检查 KIQ 的 ACTIVE 和可用命令，开始处理队列
```

Host 必须同时准备内存中的 KIQ MQD 和对应 HQD；只准备 MQD，尚未运行的 CP 无法据此找到 KIQ Ring。`ACTIVE = 0` 时暂不处理该队列；`ACTIVE = 1` 时检查可用命令。Ring 可以为空，激活不要求 Kernel 已开始执行。无需额外增加“通知 CP 检查 KIQ 配置”的寄存器。

`CP_HQD_AQL_CONTROL` 的整个 32 位值定义为：`0` 表示非 AQL，`1` 表示 AQL。KIQ、HIQ 配置为 `0`，申请创建的用户 AQL Queue 配置为 `1`；CP 据此选择解析流程。其他数值属于非法编码，不能把任意非零值都当作 AQL。队列格式须在激活前配置好，非法编码和运行期间修改格式按[第 8.2 节](#spec-hqd-access-rules)拒绝并报告；解释与 AMD 参考见[队列格式选择](<./CP_MEC 软件实现、参考与扩展.md#queue-format>)。

### 3.3 复位的影响范围

复位与启动在目标 CPU 线程中同步完成。`GLOBAL_CTRL.ENABLE` 只控制原有设备功能；CP 通过自己的控制位解除复位。

CP 单独复位清零 Host 访存窗口的基址，保留 VRAM、入口，以及原 DMA、派发和中断状态。`GLOBAL_CTRL.RESET` 复位设备状态并使 CP 回到保持复位、入口为 0 的默认值，VRAM 保留。设备冷复位先停止 CP，再清零 VRAM 并恢复全部默认状态。

**[DESIGN]** 设备冷复位或整体复位将所有 HQD 寄存器与 `HQD_SELECT` 清零；CP 单独复位保留 HQD 内容，供诊断和后续恢复使用。寄存器默认状态见[第 8.2 节](#spec-hqd-access-rules)，故障后的队列恢复列入[后续异常恢复扩展](<./QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)。

**[DESIGN]** 固件重新启动仍按第 3.2 节装载和初始化：Host 恢复已初始化数据，固件设置栈、清零未初始化全局变量并初始化内部状态，不能依赖 CP 单独复位清空这些内容。

CP 单独复位不能据此被解释为目标队列的全部访问已结束。队列的恢复、错误和资源释放条件按第 7、9 节确定。

<a id="spec-management"></a>

## 4. 管理命令与完成确认

**[DESIGN]** 第一版采用“KIQ 建立 HIQ，再由 HIQ 管理用户队列”的分工。驱动先按第 3 节准备 KIQ 并启动 CP，再建立 HIQ，并按应用申请创建用户队列。下图假设两条动态创建的队列分别记作 A、B，CP 为它们选中了槽位 2、3；箭头表示驱动提交命令、CP 选择槽位并装载目标队列，每条队列都有自己的 Ring：

```text
Host 在 CP 复位期间配置 HQD[0]：KIQ，然后启动 CP
  │
  │ 驱动向 KIQ Ring 提交 MAP_QUEUES
  │   queue_kind = HIQ，mqd_addr = MQD_HIQ 的物理地址
  ▼
CP 读取 MQD_HIQ，配置并激活 HQD[1]：HIQ
  │ 驱动通过 KIQ 后附完成标记确认 HIQ 可用
  │
  │ 驱动向 HIQ Ring 提交 MAP_QUEUES
  │   queue_kind = USER_AQL，mqd_addr = 本次用户队列 MQD 的物理地址
  ├─ MQD_A → CP 选择空闲槽位 2，配置 HQD[2]：Queue A
  └─ MQD_B → CP 选择空闲槽位 3，配置 HQD[3]：Queue B
       │ 驱动通过 HIQ 后附完成标记确认相应用户队列可用
       ▼
运行时向用户 AQL Ring 发布 Dispatch，通知该用户队列的 Doorbell
  → CP 从用户 Ring 取包，提交计算
```

KIQ、HIQ 的命令都由 Host 内核驱动填写；用户运行时只向自己的 AQL Ring 发布计算任务。这里的两级分工针对队列管理，用户 Dispatch 直接保存在用户 Ring 中。

两条管理队列均只支持 `MAP_QUEUES`、`UNMAP_QUEUES` 和后附写完成标记命令 `WRITE_COMPLETION`，允许的目标按队列区分：

- **KIQ，槽位 0：** 映射、卸载命令只针对槽位 1 的 HIQ，写标记命令确认同一 KIQ 中前面的管理操作。
- **HIQ，槽位 1：** 映射、卸载命令只针对槽位 2、3 的用户队列，写标记命令确认同一 HIQ 中前面的管理操作。
- **用户队列，使用槽位 2、3：** CP 按创建请求选择空闲槽位，处理 AQL Packet，不接收上述管理命令。

KIQ 和 HIQ 均不通过这些命令映射或卸载自身，也不允许越过上述目标范围。错误入口、非法目标和不支持的命令按管理错误处理，不自动转交另一条队列；请求结果返回与管理通道故障按[第 4.4 节](#spec-management-result)处理。首次 KIQ 仍由 Host 配置，正常卸载 HIQ 前须按[第 7.4 节](#spec-unmap-drain)完成用户队列清理及 HIQ 请求回报；运行期间 KIQ 重配和故障 HIQ 重建列入[后续异常恢复扩展](<./QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)。

本版管理命令直接保存在各自的 Ring 中，固定的是 HQD 槽位数量和管理／用户用途，具体用户队列由 CP 按请求绑定到空闲槽位。用户队列总数按[两个创建名额](#spec-user-queue-capacity)限制，不增加 `RUN_LIST`、`MAP_PROCESS` 或 IB 间接执行。映射、卸载命令名称参考 AMD，`WRITE_COMPLETION` 为实验自定义名称，三者的具体编码均由本实验定义；AMD 的 HIQ 与 runlist 关系见[管理队列分工与 AMD 参考](<./CP_MEC 软件实现、参考与扩展.md#management>)。

下面以已经建立 HIQ、准备创建一条用户队列为例。Host 准备好目标队列的 Ring、MQD 和管理结果区，再提交管理命令与后续写标记命令：

```text
Host 完整填写本次 MQD，保证 CP 可读取且读取期间内容稳定
  → 初始化本次结果区，保证 CP 可见
  → 向 HIQ 提交 MAP_QUEUES，携带 queue_kind = USER_AQL 与本次 MQD 地址
  → 在同一 HIQ Ring 中紧接着放入 WRITE_COMPLETION，携带完成地址与预期值
  → 按提交协议发布命令并通知设备

CP 按 HIQ 命令顺序处理
  → 从用户槽位 2、3 中选择空闲槽位；本例假设分配成功
  → 读取本次 MQD，完整填写目标 HQD 的地址高低位及其他配置
  → 激活目标队列，使它可以被处理，暂存本次成功结果
  → 执行后面的 WRITE_COMPLETION，先写结果码，再写完成标记

Host 观察到本次预期标记
  → 完成读取同步，再读结果码，确认配置结果
```

CP 必须先让管理操作达到规定的完成条件，并保证本次结果状态对 Host 可见，才能发布后面的标记；使用异步接口时也须等待相关操作完成。两条命令在对应管理 Ring 中按逻辑顺序相邻，执行时遵守第 5 节的队列选择规则，不要求在同一轮检查中连续执行。

这里向 HIQ 先放入映射本次队列的 `MAP_QUEUES`，再放入写完成标记命令；Ring、MQD 等资源由驱动事先准备。驱动从[管理完成标记区](#spec-shared-state-storage)取得本次结果区 M1，后面的命令携带 M1 的 GPU 物理地址和预期值。M1 位于 HIQ Ring 外；CP 执行 `WRITE_COMPLETION` 时，先在结果区偏移 8 字节处写结果码，再在开头写完成标记。

建立 HIQ 时，对应的映射命令和写标记命令都放入 KIQ。驱动确认这次配置成功后，才能使用 HIQ 提交用户队列管理命令。两个 Ring 各自按序消费，HIQ 中的标记不能用来确认 KIQ 中的操作，反之亦然。

卸载采用相同组织方式：先提交 `UNMAP_QUEUES`，再追加 `WRITE_COMPLETION`，完成条件见第 7 节。管理标记针对前面的管理操作，Host 读到本次序号后仍须检查结果码；用户 Kernel 通过各自的 Signal 协议确认完成。普通管理失败也返回结果，回报路径自身出错则停止故障管理 Ring，见[第 4.4 节](#spec-management-result)。完整例子与 AMD 参考见[后续写完成标记命令](<./CP_MEC 软件实现、参考与扩展.md#completion-marker>)。

命令范围、队列分工、字段布局、重复请求处理、标记使用和失败结果返回规则已确认，见下文第 4.1～4.4 节。管理通道故障的基本退出与资源保留按 9.6 执行，强制恢复留作后续扩展。

<a id="spec-management-packet-format"></a>

### 4.1 管理命令的 32 字节布局

驱动已建立 HIQ，并准备好本次用户队列的 Ring、MQD 和进度区，MQD 在示例中记作 MQD_A。接下来要在 HIQ Ring 中表达“请求建立一条用户 AQL Queue，配置来自 MQD_A”，由 CP 选择空闲用户槽位。以下以连续的两个空闲命令位置为例，说明字段放在哪里、CP 怎样使用；生产进度和命令发布顺序按第 5 节及 9.4 的已确认规则执行。

```text
Host RAM 中的 HIQ Ring
  └─ MAP_QUEUES 命令包（32 字节）
       ├─ opcode = 1              → 请求映射队列
       ├─ queue_kind = USER_AQL    → 要建立的是用户 AQL Queue
       └─ mqd_addr                → Host RAM 中的 MQD_A
            │
            │ CP 通过 Host 访存窗口读取命令
            ▼
CP 检查来源为 HIQ、目标种类为 USER_AQL
  → 从槽位 2、3 中选择空闲槽位；本例选中槽位 2
  → 读取 MQD_A，把配置装入 HQD[2]，最后激活

同一 HIQ Ring 中后附的 WRITE_COMPLETION（32 字节）
  ├─ opcode = 3                   → CP 选择写完成标记处理
  ├─ completion_addr             → Host RAM 中的 16 字节结果区 M1
  └─ completion_value = 7         → 先写 M1 + 8 的结果码，再向 M1 写入 64 位值 7
                                       │
                                       ▼
                                  驱动读到 M1 == 7，同步后读取结果码
```

本例中的 `7` 是驱动为该请求分配的预期序号，标记初始化为 `0`，结果码初始化为 `0xffff_ffff`；序号分配、等待和复用规则见[第 4.3 节](#spec-management-marker)。图中假设映射成功，CP 回报结果码 `0`；无空闲用户槽位时回报 `1`。两种情况都先写结果码、再写序号，完整协议见[第 4.4 节](#spec-management-result)。

**[DESIGN]** `MAP_QUEUES`、`UNMAP_QUEUES` 都在命令包偏移 `0x04` 保存 32 位 `queue_kind`，表示目标队列种类：`1` 为 `HIQ`，`2` 为 `USER_AQL`，`0` 和其他值均非法。驱动构造命令结构体后，将字段写入 Host RAM 中的管理 Ring，CP 取包时读取。MQD 继续使用已确认的 64 字节布局，不增加 `queue_kind` 成员；HQD 继续保留 15 个寄存器位置，不增加队列种类寄存器。

Queue A 建立后，驱动持有 MQD_A 的物理地址，CP 也已将这个地址保存在 Queue A 对应的 HQD 中。驱动请求卸载时，仍用该地址标识 Queue A，由 CP 找到它当前占用的槽位：

```text
驱动向 HIQ 提交 UNMAP_QUEUES
  ├─ queue_kind = USER_AQL（数值 2）
  └─ mqd_addr = MQD_A 的 GPU 物理地址
       │ CP 通过 Host 访存窗口读取命令
       ▼
CP 检查用户槽位 2、3 的当前绑定
  → 比较 HQD 中保存的完整 MQD 地址
  → 找到 Queue A 所在的槽位，本例为槽位 2
  → 按既定流程卸载，并保存必要状态
```

**[DESIGN]** CP 在允许的目标范围内，只对当前绑定的槽位进行匹配：将 `CP_MQD_BASE_ADDR / HI` 拼成完整的 64 位地址，与命令中的 `mqd_addr` 比较。来自 KIQ、目标为 `HIQ` 的卸载请求只检查槽位 1；来自 HIQ、目标为 `USER_AQL` 的请求检查用户槽位 2、3。MQD 的独立分配和地址保留遵守[第 2.6 节](#spec-mqd-format)：相关管理操作和卸载收尾完成前，驱动不能释放或复用该 MQD。没有匹配项、重复请求和异常占用的处理见[第 4.2 节](#spec-management-slot-state)，结果码和返回位置见[第 4.4 节](#spec-management-result)。

**[DESIGN]** 三种管理命令统一为 **32 字节**，起点按 **32 字节对齐**，多字节字段采用[小端格式](#spec-shared-endian)。包长固定，不设置长度字段。以下偏移均从当前命令起点计算；`u32`、`u64` 分别表示 32 位、64 位无符号整数。所有保留字节填写 `0`。

```text
MAP_QUEUES：装载目标队列
  0x00  u32  opcode = 1
  0x04  u32  queue_kind：1 = HIQ，2 = USER_AQL
  0x08  u64  mqd_addr
  0x10       保留 16 字节，填 0

UNMAP_QUEUES：卸载目标队列
  0x00  u32  opcode = 2
  0x04  u32  queue_kind：1 = HIQ，2 = USER_AQL
  0x08  u64  mqd_addr
  0x10       保留 16 字节，填 0

WRITE_COMPLETION：写管理完成标记
  0x00  u32  opcode = 3
  0x04  u32  保留，填 0
  0x08  u64  completion_addr
  0x10  u64  completion_value
  0x18       保留 8 字节，填 0
```

每条 `MAP_QUEUES`、`UNMAP_QUEUES` 只处理一条目标队列。CP 知道当前正在读取哪个 HQD 对应的 Ring，据此判断命令来源；`queue_kind` 表示本次要映射或卸载的目标队列种类。首次 KIQ 由 Host 在 CP 复位期间直接配置到槽位 0，不经 `MAP_QUEUES` 创建。后续映射只允许以下两种组合：

```text
来源：KIQ Ring（HQD[0]）
  └─ queue_kind = HIQ（数值 1）
       └─ CP 使用专留的槽位 1，装载 MQD_HIQ

来源：HIQ Ring（HQD[1]）
  └─ queue_kind = USER_AQL（数值 2）
       └─ CP 检查用户槽位 2、3
            ├─ 有空闲：选定一个槽位，装载本次 MQD
            └─ 无空闲：报告创建失败
```

MQD 中的 `aql_control` 只说明包格式：KIQ、HIQ 均为 `0`，用户 AQL Queue 为 `1`，不能单靠这个字段区分 KIQ 和 HIQ。CP 结合命令来源与 `queue_kind` 判断本次映射或卸载的目标种类是否合法。

`UNMAP_QUEUES` 匹配到队列后，使用该 HQD 中保留的 MQD 地址保存必要状态。`WRITE_COMPLETION` 没有目标队列字段，偏移 `0x04` 的零是保留值，不表示操作槽位 0。

`mqd_addr`、`completion_addr` 都保存保存在 64 位槽中的 **GPU 物理字节地址**（高 32 位为零），至少按 8 字节对齐，不右移编码。前者指向已确认的 64 字节 MQD，后者指向[第 4.4 节](#spec-management-result)的 16 字节结果区。CP 执行 `WRITE_COMPLETION` 时，先将前一条管理操作的 32 位结果码写入 `completion_addr + 8`，保证结果可见，再向 `completion_addr` 写入完整的 64 位 `completion_value`。结果码由 CP 按来源管理 Ring 暂存，命令不增加结果码字段。地址及整段访问范围按[第 2.4.2 节](#spec-address-validation)校验，完成地址须覆盖完整 16 字节结果区。

对已经发布的管理命令，`opcode = 0` 和其他未定义编号均为非法命令。保留区非零或地址校验失败时，拒绝该命令。对于 `MAP_QUEUES`、`UNMAP_QUEUES`，`queue_kind` 不属于 `1`、`2`，或目标种类与来源管理队列不符合上述分工时，同样拒绝处理。请求结果、命令配对和回报故障按[第 4.4 节](#spec-management-result)处理，强制恢复步骤列入[后续异常恢复扩展](<./QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)。尚未发布的 Ring 空间是否可读由提交协议判断，不能把空槽中的零当成一条已提交命令。

**[BOUNDARY]** 本节已确定三种管理命令的完整布局、操作编号、队列种类编码和卸载目标的查找方法。管理命令不采用 AQL 包头，普通用户 Ring 继续按 AQL 格式处理。生产／消费进度按第 5 节确定；普通管理失败继续回报，管理通道故障停止后续消费，失败后的进度处理按[第 7.3 节](#spec-failure-retirement)执行。重复请求和槽位占用见[第 4.2 节](#spec-management-slot-state)，标记的初始化、发布与复用见[第 4.3 节](#spec-management-marker)，结果返回协议见[第 4.4 节](#spec-management-result)。

<a id="spec-management-slot-state"></a>

### 4.2 槽位绑定、重复请求与释放

驱动按申请动态准备队列和 MQD，再向管理 Ring 提交请求。CP 处理映射或卸载前，需要根据 `queue_kind` 确定目标范围，并用 `mqd_addr` 的完整物理地址查找当前绑定。下面的流程统一按实际地址识别目标：

```text
Host 提交管理命令
  ├─ queue_kind：目标队列种类
  └─ mqd_addr：完整的 MQD 物理地址
       │
       ▼
CP 检查允许范围内的槽位及当前绑定
  ├─ 映射：判断重复、选择空闲槽位或报告满额
  └─ 卸载：查找绑定、完成卸载并释放槽位
```

**[DESIGN]** CP 固件在已有固件保留区的私有数据中，维护每个 HQD 槽位的占用状态和绑定的 MQD 物理地址。装载中、已绑定、卸载中、异常尚未清理的槽位都算占用。已装载队列的记录与 HQD 保存的 MQD 地址对应；`ACTIVE = 0` 不能单独作为空闲依据。这些是固件内部记录，不增加 MQD 字段或 HQD 寄存器。

CP 按完整 MQD 物理地址检查重复映射。同一个地址已经出现在占用记录中时，返回失败，结果含义为“重复映射”，保留原绑定、配置和消费位置，也不为它分配第二个槽位：

```text
收到 MAP_QUEUES
  ├─ mqd_addr 已在占用记录中
  │    → 返回“重复映射”
  │    → 保留原绑定、配置和消费位置
  │
  └─ mqd_addr 尚未绑定
       ├─ 有可用槽位 → 分配并装载
       └─ 无可用槽位 → 返回失败
```

新的用户队列由 CP 从槽位 2、3 中选择空闲槽位，满额时返回“名额已满”。HIQ 使用专留槽位 1；该槽位已占用时，拒绝用另一份 MQD 覆盖。全设备仍最多同时存在两条用户 Queue，创建名额和复用范围沿用[第 1 节](#spec-user-queue-capacity)。

收到 `UNMAP_QUEUES` 后，CP 在允许范围内匹配 `mqd_addr`。找到当前绑定时，处理对应队列的卸载；没有找到时，返回失败，结果含义为“队列未映射”，不修改其他槽位。成功卸载后，该地址尚未重新绑定时，再次提交卸载也返回“队列未映射”。本版不为此保存历史卸载记录。

正常卸载前，Host 按[第 7.4 节](#spec-unmap-drain)停止提交并等待排空，再请求 CP 卸载。CP 按以下顺序释放槽位：

```text
将槽位标为卸载中，清除 ACTIVE、关闭 Doorbell 使能，停止继续取包
  → 确认相关在途访问结束
  → 成功写回 saved_rptr、saved_error
  → 解除绑定，将槽位标为空闲
```

保存失败或无法确认访问结束时，继续保留占用。映射中途失败时，只有确认队列尚未激活、相关访问已结束、部分配置已经撤销，才归还槽位；否则保留占用，故障恢复留作后续扩展。Host 释放 MQD、Ring 等内存，仍须确认管理结果并满足已有生命周期约定。

**[BOUNDARY]** 本节确定请求处理结果和槽位释放条件。“重复映射”“名额已满”“队列未映射”的结果码、返回位置及后附标记处理见[第 4.4 节](#spec-management-result)；强制停止和故障复位步骤列入[后续异常恢复扩展](<./QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)。

<a id="spec-management-marker"></a>

### 4.3 管理完成标记的取值、发布与复用

驱动已准备好本次用户队列的 MQD，接下来经 HIQ 请求 CP 建立队列，并等待配置结果。管理命令和后附的 `WRITE_COMPLETION` 都放在提交该请求的 HIQ Ring 中；新建的用户 Ring 保存 AQL Dispatch，结果区则是 Ring 外的独立内存。下面的对象均位于 Host RAM，M 表示本次请求结果区的起始物理地址，完成标记位于结果区开头：

```text
HIQ Ring：保存驱动提交的管理命令
  │
  ├─ 第 1 条：MAP_QUEUES
  │    └─ mqd_addr → 本次分配的 MQD
  │                       └─ ring_base → 本次用户队列的 Ring
  │                                        └─ 保存 AQL Dispatch
  │
  └─ 第 2 条：WRITE_COMPLETION
       └─ completion_addr → Host RAM 中的结果区 M
                              ├─ completion：完成标记
                              └─ status：本次管理结果
```

管理 HIQ 时，对应的映射或卸载命令及其 `WRITE_COMPLETION` 放在 KIQ Ring 中。每次请求的两条命令必须位于对应的管理 Ring，按 Ring 的逻辑顺序相邻。相邻是命令保存顺序，CP 仍可按既有调度规则在不同轮次处理这两条命令。

以下以正常成功路径说明标记的使用，本次预期序号假设为 `7`：

```text
驱动为本次请求取得结果区 M
  → 初始化 completion = 0、status = 0xffff_ffff，保留字段填 0
  → 本次预期值假设为 7

HIQ Ring 中按顺序放入：
  ① MAP_QUEUES 或 UNMAP_QUEUES
  ② WRITE_COMPLETION
       completion_addr  = M
       completion_value = 7

CP 完成前面的管理操作，暂存本次成功结果
  → 执行 WRITE_COMPLETION，先向 M + 8 写入 status = 0
  → 保证本次结果状态对 Host 可见
  → 向 M 写入完整的 64 位值 7

Host 读到 M 处的 completion == 7
  → 完成读取同步，再读取 M + 8 的 status
  → 满足回收条件后，归还结果区
```

**[DESIGN]** 每个在途管理请求独占一个 16 字节结果区，至少按 8 字节对齐。一次映射或卸载请求及其后附完成命令共用本次结果区；其中完成标记占 8 字节，结果码占 4 字节，另有 4 字节保留空间，布局见[第 4.4 节](#spec-management-result)。驱动按请求分配，尚未结束的请求使用不同结果区，不固定绑定某条用户队列。

驱动将标记初始化为 `0`，并按设备为每次管理请求分配新的 64 位无符号序号，从 `1` 开始。例如本次预期值为 `7`，下一次分配 `8`。CP 直接写入命令中的 `completion_value`，Host 按“等于本次预期值”判断，不把任意非零值当作完成。第一版不支持序号回绕复用。

驱动必须先完成整个结果区的初始化，再将管理命令和 `WRITE_COMPLETION` 成对发布到对应管理 Ring。CP 先结束前面的管理操作并暂存结果，再由 `WRITE_COMPLETION` 写结果码、写标记，保证 Host 看到预期值后能够读取本次结果。完成标记的完整读写沿用[第 2.2.1 节](#spec-shared-value-integrity)和 9.4.3 已确认的规则：每次取得完整的 64 位旧值或新值，不能取得新旧部分拼出的混合值。具体屏障与后端访问路径遵守[第 6.4 节](#spec-dispatch-visibility)。

Host 使用带超时的轮询等待管理标记，两次检查之间可以短暂休眠。读到本次预期值后，Host 完成相应读取同步，再检查管理结果；标记出现本身不替代成败判断。

<a id="spec-management-submit-lock"></a>

**[DESIGN]** KIQ、HIQ 各自串行保护管理请求的发布。两个进程同时创建或销毁队列时，驱动在对应 Ring 的提交锁内检查消费回报，确认至少两个可复用槽，再将本次管理命令和 `WRITE_COMPLETION` 写入逻辑相邻的位置。两条命令都写完并保证可见后，一次将 `W` 增加 `2`，按模 `2^32` 发布，再通知 Doorbell。不能只发布前一条命令，就让另一请求插入其后。

例如请求 T1、T2 同时使用 HIQ，T1 先取得提交锁：

```text
驱动准备 T1 的 MQD 和独立结果区
  → 取得 HIQ 提交锁，确认两个空槽
  → 写入 T1 的管理命令、T1 的 WRITE_COMPLETION
  → 保证两条命令可见，一次发布新 W，再通知 Doorbell
  → 释放提交锁，T1 等待自己的结果区

T2 随后取得同一提交锁
  → 按相同规则发布自己的命令对
  → 释放提交锁，T2 等待自己的结果区
```

相邻按逻辑包编号判断，允许前一条命令位于 Ring 末槽、后一条位于槽 0；单条命令仍不跨 Ring 末尾。空间不足时，本次请求尚未发布，不能推进 `W` 或覆盖旧槽。驱动发布 `W` 前完成命令写入同步，CP 读到新 `W` 后完成读取同步，再读取命令。等待结果时已释放提交锁，也不能持有会阻塞中断处理或其他必要操作的锁；各请求继续独占自己的结果区。这些锁与屏障只约束管理命令发布，不改变用户 AQL 的并行取号和填包规则。

只有确认 CP 不会再写入旧请求的结果区，且 Host 已结束旧请求的等待和结果处理，才允许复用这块内存。复用时将完成标记重新置为 `0`、结果码置为 `0xffff_ffff`、保留字段填 `0`，交给使用新序号的请求。等待超时不能直接清零、释放或复用结果区；必须保留，直到旧请求结束，或恢复流程确认相关访问已终止，再按上述条件回收。

**[BOUNDARY]** 本节确定标记的使用、等待和结果区复用规则。管理失败的结果码、回报顺序，以及管理通道故障后的等待退出方式见[第 4.4 节](#spec-management-result)；强制停止和故障复位步骤列入[后续异常恢复扩展](<./QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)。

<a id="spec-management-result"></a>

### 4.4 管理结果的写回与失败处理

驱动已经为新申请的用户队列准备好 MQD，并向 HIQ 提交映射请求。假设两个用户队列名额都已占用，CP 无法创建本次队列，需要把失败原因返回给驱动。下面以本次预期序号为 `7`、结果区起始物理地址为 M 举例：

```text
HIQ Ring 中的本次请求
  │
  ├─ ① MAP_QUEUES
  │      mqd_addr → 本次申请的 MQD
  │
  │    CP 发现没有空闲槽位
  │      → 在固件私有数据中暂存 status = 1
  │
  └─ ② WRITE_COMPLETION
         completion_addr  = M
         completion_value = 7
           │
           ├─ 先向 Host RAM 的 M + 8 写入 status = 1
           ├─ 保证结果码对 Host 可见
           └─ 再向 Host RAM 的 M 写入 completion = 7

Host 读到 completion == 7
  → 完成读取同步
  → 读取 M + 8 处的 status
  → 得知本次创建失败，原因是“无可用槽位”
```

**[DESIGN]** 每个在途管理请求独占一个 16 字节结果区，位于 Host RAM，至少按 8 字节对齐，多字节字段采用小端格式。结果区开头的 8 字节保存完成序号，后面保存本次管理操作的结果码。以下偏移从结果区起始物理地址 M 计算：

```text
0x00  u64  completion   8 字节，完成标记
0x08  u32  status       4 字节，本次管理操作的结果码
0x0c  u32  reserved     4 字节，保留并填 0
```

驱动发布请求前将 `completion` 初始化为 `0`，`status` 初始化为 `0xffff_ffff`，`reserved` 填 `0`。`completion_addr` 保存 M，CP 按完整的 16 字节结果区校验访问范围，包含地址加法和范围溢出检查。不同在途请求使用不同结果区；请求数量增加时增加结果区份数，每个完成标记仍使用完整的 64 位序号。序号分配、等待与复用继续遵守[第 4.3 节](#spec-management-marker)。

**[DESIGN]** CP 执行 `MAP_QUEUES` 或 `UNMAP_QUEUES` 后，在固件保留区的私有数据中暂存本次结果。KIQ、HIQ 各有一份暂存状态，按来源管理 Ring 关联，不混用交替调度的结果：

```text
CP 固件私有数据
  ├─ KIQ：等待后附 WRITE_COMPLETION 回报的管理结果
  └─ HIQ：等待后附 WRITE_COMPLETION 回报的管理结果
```

紧随其后的 `WRITE_COMPLETION` 取出该 Ring 的暂存结果，先向 `completion_addr + 8` 写入完整的 32 位结果码，保证结果可见，再向 `completion_addr` 写入完整的 64 位 `completion_value`。回报完成后，清除本次暂存状态。该命令同时负责结果码和完成标记的写回；[第 4.1 节](#spec-management-packet-format)的 32 字节命令布局保持不变，结果码不增加到命令包、MQD 或 HQD 中。

名额已满、重复映射、卸载目标不存在等普通管理失败，也执行后附完成命令，随后可以继续处理该管理 Ring。MQD 访问失败时，只有固件能够安全结束本次处理并继续回报，才走相同流程。槽位保留、停止目标队列取包和资源释放仍按[第 4.2 节](#spec-management-slot-state)及已有访存错误规则执行；收到失败结果后，Host 仍须检查生命周期条件才能回收资源。

**[DESIGN]** `status` 使用以下 32 位编码：

```text
0：成功
1：无可用槽位，包括 HIQ 专留槽位已被占用
2：重复映射
3：队列未映射
4：管理命令参数非法
5：MQD 读取或状态保存失败
6：操作未能正常收尾，需要恢复

0xffff_ffff：初始值，尚无有效结果
```

Host 先等待完成标记等于本次预期序号，再完成读取同步并读取 `status`。`0` 表示本次管理操作成功，`1～6` 表示对应失败；完成序号已经匹配，但结果码仍是初始值或未知编码时，报告协议错误。这些是每次请求的结果码，`CP_HQD_ERROR` 的队列故障编号、首次记录和清理后重建规则见[第 7.2 节](#spec-queue-error-policy)。

**[DESIGN]** 无法读取管理 Ring、已发布命令配对错误、结果码或完成标记写回失败，均按管理队列故障处理。配对错误包括管理命令后面已发布的下一条命令不是 `WRITE_COMPLETION`，以及没有前一条管理操作的孤立完成命令；不能把旧请求的暂存结果交给下一请求。尚未发布的 Ring 空间仍按发布协议等待，不据此判断命令配对错误。

CP 将故障记录到来源 KIQ／HIQ 的 `CP_HQD_ERROR`，停止该管理 Ring 后续消费，不自动重放管理操作。结果码写入失败时不继续写完成标记；标记写入报错时不盲目重试，也不承诺撤销已经发生的写入。KIQ 实际通道故障统一按[第 7.2.2 节](#spec-queue-error-stop-scope)停止全部新取包和新派发；HIQ 故障停止 HIQ，KIQ 和已驻留的正常用户队列继续处理。

Host 使用带超时的轮询，并在本次标记未匹配时检查来源管理队列的故障：

```text
本次完成序号已匹配
  → 同步并读取本次结果码

本次序号未匹配，但来源管理队列已故障
  → 返回管理通道故障，本次操作结果可能尚无法确定

未取得完成结果或明确故障，且等待超时
  → 返回超时
```

故障或超时后继续保留相关内存，按[第 4.3 节](#spec-management-marker)和恢复流程确认结果区及目标队列资源的回收条件。返回通道故障或超时本身不结束设备访问。

**[BOUNDARY]** 9.3.5 的结果区布局、请求结果码、后附完成命令行为和故障等待退出方式均已确认。队列故障编号、首次记录和停止范围已按[第 7.2 节](#spec-queue-error-policy)确定，失败后的进度处理与等待退出已按[第 7.3 节](#spec-failure-retirement)确定，强制恢复列入[后续异常恢复扩展](<./QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)，正常回收继续遵守已确认的对象寿命条件；驱动向应用返回的接口形式已按 9.7 确认。

<a id="spec-submit-consume"></a>

## 5. 命令发布、进度读取与队列选择

<a id="spec-ring-packet-boundaries"></a>

### 5.1 Ring 固定包槽与末尾回绕

驱动已分配 Ring，Host 要向空槽填写完整命令，CP 要按槽位顺序读取。下面以一个 256 字节、每包 64 字节的用户 AQL Ring 为例，说明包槽边界与循环复用；图中的槽位均指 Ring 包槽。

```text
Ring 内字节范围：

槽 0            槽 1            槽 2            槽 3
[0～63]   →     [64～127]  →    [128～191]  →   [192～255]
  ↑                                                 │
  └────────────── 末尾回绕 ─────────────────────────┘

槽 0 的再次使用：
CP 消费旧包并回报进度
  → Host 确认槽 0 可复用
  → Host 填入并发布下一轮的新包
  → CP 再次走到槽 0 时，按发布状态判断能否读取
```

**[DESIGN]** KIQ、HIQ 的管理 Ring 每槽固定为 32 字节，用户 AQL Ring 每槽固定为 64 字节，每条命令完整占用一个槽。Ring 基址沿用[第 2.4.2 节](#spec-address-validation)的 64 字节对齐要求；从基址起按包大小连续划分，管理命令起点按 32 字节对齐，AQL 包起点按 64 字节对齐。两类 Ring 的字节容量仍为[第 8.1 节](#spec-hqd-field-encoding)规定的 64 字节～64 KiB 的 2 的幂。

管理 Ring 的槽数为“字节容量 ÷ 32”，AQL Ring 的槽数为“字节容量 ÷ 64”。因此同样是 256 字节，管理 Ring 可放 8 条命令，AQL Ring 可放 4 个包；图中的 256 字节只用于举例，不指定各队列的默认容量。

**[DESIGN]** 每个包必须完整位于 Ring 内，不能拆成位于末尾和开头的两段。现有容量都是包大小的整数倍，按固定槽位排列即可，无需末尾填充命令。最后一个槽处理完后，下一个物理槽回到槽 0，继续使用原内存，不整体清空 Ring；物理槽回绕时，逻辑包编号按[第 5.2.1 节](#spec-ring-progress)继续累计。

**[DESIGN]** 创建用户 AQL Ring 时，Host 将每个槽的 Header 初始化为 `INVALID`。正常 Dispatch 按[第 6 节](#spec-dispatch-completion)完成并收尾后，CP 将旧包槽标为 `INVALID`，推进并回报消费进度；Host 观察到对应消费回报后，才能覆盖该槽并发布下一轮的新包。

CP 回绕到槽 0 时，先根据生产、消费进度确认当前编号是否已被预留，再根据 Header 判断能否处理。AQL Header 仍为 `INVALID` 时等待，不能仅凭槽内残留的旧包体再次执行任务。管理 Ring 不使用 AQL Header，按管理命令的发布协议判断可读范围。

**[BOUNDARY]** 本节确定固定包槽、物理末尾回绕和再次取包的条件。进度单位、位宽、满空判断和计数溢出见[第 5.2.1 节](#spec-ring-progress)；完整字段读写按 9.4.3 执行；包体、Header、生产进度、Doorbell 的发布与刷新规则已按 9.4.4、9.4.5 确认。失败包按[第 7.3 节](#spec-failure-retirement)停止正常收尾。

### 5.2 包发布与 CP 队列选择

<a id="spec-ring-progress"></a>

#### 5.2.1 进度编号、满空判断与恢复

Host 提交用户 AQL 包时，先取得自己的包编号，再等待对应物理槽可复用；CP 取包时则从自己的消费位置继续。沿用上节的 256 字节 AQL Ring，共 4 个槽。假设尚未发生计数溢出，Host 已预留包 0～8，且这些包的 Header 均已完成有效发布，CP 已消费并归还包 0～5：

```text
Host RAM 中的生产进度 W = 9
  │ CP 读取：预留范围到包 8 为止，是否发布还须检查 Header
  ▼
HQD 中的消费进度 R = 6
  │ CP 从包 6 开始处理
  ▼
本例 Header 均已有效，按序处理：包 6 → 包 7 → 包 8
占用 3 个槽，还剩 1 个空槽
  │
  │ CP 完成包 6 并收尾
  ▼
HQD 中 R 改为 7 → 向 Host RAM 回报 R = 7
  │
  ▼
Host 读取消费回报，可以复用包 6 原来占用的槽
```

**[DESIGN]** 两类 Ring 均按包计数，使用 32 位无符号进度，`R` 表示下一待消费包的编号。用户 AQL Queue 的 `W` 表示下一待预留包的编号：Host 通过原子读改写推进 `W`，取得本次预留编号，然后等待对应物理槽可复用。取得编号时，物理槽可能仍由旧包占用，也可能已经归还、Header 为 `INVALID`；取得编号本身不允许覆盖旧包。包体写完后，再以 release 语义发布有效 Header；CP 取得新 `W` 后仍须检查当前包的 Header。已预留但尚未发布的包计入 `W`。

管理 Ring 没有 AQL Header，沿用以 `W` 标出已发布命令范围的约定：驱动准备好命令，再更新 `W`。管理命令占 32 字节、AQL 包占 64 字节，但每消费一包，`R` 都增加 `1`。正常 Dispatch 仍按[第 6 节](#spec-dispatch-completion)完成并收尾后才推进 `R`。两类 Ring 的发布条件见[下节](#spec-aql-reserve-publish)。

包编号持续累加，仅在超过 32 位范围时按模 `2^32` 回绕。找到物理包槽时，才按 Ring 槽数取模：

```text
S = 每包字节数：管理命令为 32，AQL 为 64
N = Ring 字节容量 ÷ S

包编号 P 对应的槽号 = P mod N
包地址 = Ring 基址 + 槽号 × S
```

上例中，包 6 位于 `6 mod 4 = 2` 号槽，地址为“Ring 基址 + 128 字节”；包 7 位于槽 3，包 8 回到槽 0。物理槽回到开头时，包编号仍为 `8`，不随槽号改成 `0`。

**[DESIGN]** 用户 AQL Queue 允许先取编号、再等空槽。对观察到的进度，差值 `D = (W - R) mod 2^32` 表示已预留但尚未归还的编号数量，包括正在等待旧槽释放的预留。因此，`D` 可以大于物理槽数 `N`，不能直接把它当作物理占用槽数，也不能仅凭 `D > N` 报进度错误。

```text
D = (W - R) mod 2^32

D = 0       → 本次进度快照中没有已预留、尚未归还的编号
0 < D < N   → 已有预留，当前窗口内仍有未预留的位置
D >= N      → 当前窗口内的位置均已预留；后续编号可以先取，但须等槽

AQL 包是否已经发布，仍由该包的 Header 判断。
```

每个提交线程必须按自己的包编号 `P` 判断能否填写物理槽。下面的 `R` 使用 Host 读取到的消费回报，`N` 为这条 Ring 的槽数：

```text
先原子推进 W，取得本次编号 P
  → 反复读取完整的消费回报 R
  → 计算本次编号到回报位置的距离：(P - R) mod 2^32
      ├─ 距离 >= N：旧槽尚不可复用，等待并重读 R
      └─ 距离 < N：本次编号已进入可写窗口
          → 完成消费回报对应的同步，确认旧 Header 为 INVALID
          → 在 P mod N 号槽填写包体
          → 发布有效 Header，再通知 Doorbell
```

等待时使用已取得的 `P`，不能要求全局 `W - R` 先降到容量以内。后面的线程也可能已经取号，使 `W` 继续增加；这不妨碍已经进入可写窗口的较早编号填包。

例如仍取 4 个槽，当前 `R = 10`、`W = 14`，包 10～13 已预留且尚未归还。另一个线程继续取号：

```text
Host 原子取到 P = 14，W 从 14 增加到 15
  → D = 15 - 10 = 5，大于容量 4，属于允许的预留状态
  → 包 14 使用槽 2，但槽 2 当前仍保存包 10
  → P - R = 14 - 10 = 4，Host 等待，不改动槽 2

CP 完成包 10 的处理和收尾
  → 将槽 2 的 Header 置 INVALID，再向 Host 回报 R = 11

Host 取得新回报并完成同步
  → P - R = 14 - 11 = 3，小于容量 4
  → 可以在槽 2 填写包 14
```

全部 `N` 个槽都可使用，不额外空出一个槽。消费回报尚未更新时，Host 继续等待相应旧槽。CP 使用 HQD 中的 `R` 和取得的 `W` 判断是否存在待处理编号；即使 `D > 0`，当前 Header 为 `INVALID` 时也须等待发布。

管理 Ring 的 `W` 保存已发布边界，仍由驱动在有空间时写完整命令后推进。它的有效已发布范围不能超过 `N` 个尚未归还的包，不能套用用户 AQL 的提前取号规则。每次管理请求须先取得两个可复用槽，再成对发布；并发保护按[第 4.3 节](#spec-management-submit-lock)执行，失败处理按[第 4.4 节](#spec-management-result)执行。

**[DESIGN]** 进度增量和差值都明确按模 `2^32` 计算。下面仍取 4 个槽，展示数值溢出前后的连续使用：

```text
R = 0xffff_fffe
W = 0x0000_0001

D = (W - R) mod 2^32 = 3

三个已预留、尚未归还的包编号：
0xffff_fffe → 0xffff_ffff → 0x0000_0000

对应物理槽：
     2      →      3     →      0
```

不能用普通的 `W < R` 判断进度错误，也不因计数溢出而清空 Ring。现有容量除以包大小后，槽数都是 2 的幂，最大为 2048；每个槽数都整除 `2^32`，因此计数溢出后仍可用同一公式定位下一槽。用户 AQL 允许预留超出物理容量的编号，但每个线程仍须满足上述 `P` 与 `R` 的条件才能写槽，差值检查也不能代替 Header 发布协议。32 位模运算还要求预留进度领先最老未归还编号的距离必须小于 `2^32`；运行时必须限制在途预留数量，避免活跃编号重复。验证须覆盖预留上限与跨计数溢出的并发行为，已运行的用例及结果见[大纲进度说明](<./QEMU GPGPU 实验大纲.md#current-progress>)。

**[DESIGN]** `CP_HQD_PQ_RPTR` 的整个 32 位值保存当前 `R`，固件不另存消费编号的高位。Host RAM 中的生产进度和消费回报也保存 32 位无符号数，存放位置沿用至少 8 字节对齐的约定；指定这些位置的地址仍保留 64 位槽；管理队列使用 GPU 物理地址，用户队列使用本模式的 GPU 地址。

首次创建时，`W`、HQD 消费进度、消费回报和 `MQD.saved_rptr` 均初始化为 `0`。正常卸载前，Host 按[第 7.4 节](#spec-unmap-drain)停止提交并等到消费回报 `R == W`；CP 卸载时将当前 `R` 零扩展到 64 位，保存到 `MQD.saved_rptr`，高 32 位填零。重新装载先检查高 32 位为零，再恢复低 32 位；高位非零则拒绝该配置。生产进度继续从共享内存读取保留的 `W`，不因重新装载而清零。MQD 的字段布局与装载、保存流程见[第 2.6 节](#spec-mqd-format)。

**[BOUNDARY]** 本节已确定进度数值及正常初始化、恢复规则。字段完整读写和发布同步遵守[第 2.2.1 节](#spec-shared-value-integrity)，用户 AQL 的多生产者主方案见[第 9.4.4 节](#spec-ring-submitters)，Header 的完整 32 位访问、管理 Ring 的串行发布及取号约束也已确认。生产进度按[第 5.2.3 节](#spec-doorbell-notification)刷新；失败包和回报失败按[第 7.3 节](#spec-failure-retirement)处理，强制恢复步骤列入[后续异常恢复扩展](<./QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)。

#### 5.2.2 包发布与队列选择

<a id="spec-aql-header-access"></a>

Host 已准备任务资源，接下来向一个可复用的 AQL 槽填包。Kernel Dispatch 的 `header`、`setup` 各占 16 位，位于包开头的同一个 32 位字中：

```text
包起始地址 + 0x00：32 位 full_header
  ├─ 低 16 位：header，包含包类型等控制位
  └─ 高 16 位：setup，包含执行维度

Host 保持包类型为 INVALID，填写其余包体
  → 将有效 header 与 setup 合成一个 32 位值
  → 按 release 顺序完整写入 full_header
  → 通知 Doorbell

CP 完整读取同一个 32 位字
  ├─ 类型为 INVALID：保留 R，后续再检查
  └─ 类型有效：完成读取同步，再读取、校验其余包体
```

**[DESIGN]** 包开头的 4 字节按 4 字节对齐，Host 与 CP 均以完整的 32 位值读写，只能观察到完整旧值或完整新值；不把共享 Ring 中的 `header`、`setup` 拆成两次 16 位访问。Host 可以在私有临时变量中分别准备字段，向共享槽发布时必须合并。槽初始化和 CP 归还槽时，将这个 32 位字写为 `0x0000_0001`，即包类型为 `INVALID`、其余首部位清零；无需清空后面 60 字节。填包期间首部保持无效，最后一次完整的 32 位写入才发布有效包。

这里要求完整的原子读取或写入，不增加首部的原子读改写操作。Host 发布前后沿用[第 6.4 节](#spec-dispatch-visibility)的屏障，CP 取得有效首部后同步读取包体；Host、CP 窗口与 QEMU 后端共同保证该 32 位访问完整。归还槽时，CP 先恢复 `INVALID` 并保证可见，再回报新 `R`；Host 读取相应消费回报并同步后才复用，具体顺序见[第 6 节](#spec-dispatch-completion)。

> **[SPEC]** [HSA System Architecture 1.2](https://hsafoundation.com/wp-content/uploads/2021/02/HSA-SysArch-1.2.pdf#page=20)，**2018-05-02**，§2.8.3，原文第 **20～21 页**要求包开头的 32 位采用 32 位原子事务，并要求 `INVALID` 全局可见后才推进读索引。规范允许在任务仍未完成时归还包槽；本实验仍按已确认流程，在整个 Dispatch 完成及成功收尾后归还，不能据此推定 MI300X 固件采用相同的回收时机。

> **[SOURCE]** ROCr 固定提交 `ba56a24c6132c5d195686ae4adf969ca1222fbba`：[runtime/hsa-runtime/inc/hsa.h](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/inc/hsa.h:2959:1) 的 [2959～2976 行](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/inc/hsa.h:2959:1)定义两个 16 位字段与 32 位 `full_header` 的共用布局；[runtime/hsa-runtime/core/runtime/amd_blit_kernel.cpp](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/amd_blit_kernel.cpp:863:1) 的 [863～901 行](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/runtime/hsa-runtime/core/runtime/amd_blit_kernel.cpp:863:1)在 `BlitKernel::PopulateQueue()` 中保持无效类型填包，再以 32 位 release 存储发布 `full_header`。

<a id="spec-aql-reserve-publish"></a>

**[DESIGN]** 用户 AQL Queue 先更新预留进度 `W`，再填写包体，最后发布有效 Header 并通知 Doorbell。继续上例，假设 CP 已归还包 6～8，此时 `R = W = 9`，Host 接着预留包 9。下图展示 CP 提前观察到新 `W` 时可能发生的交错；包 9 位于 `9 mod 4 = 1` 号槽：

```text
Host 原子预留包 9，W 从 9 增加到 10
  → 读取 R = 9，确认包 9 对应的槽 1 可复用
  → 槽 1 的 Header 仍为 INVALID

CP 若此时检查这条队列
  → 读到 W = 10、R = 9
  → 检查包 9 的 Header，读到 INVALID
  → 保持 R = 9，等待该包发布，暂不按有效包解析包体

Host 继续填写包 9
  → 保持 Header 为 INVALID，写完包体
  → 以 release 语义发布有效 Header
  → 按通知协议写 Doorbell；同一个包不再增加 W

CP 再次检查包 9 的 Header
  → 确认有效，并取得包体的可见性
  → 读取、解析包体，再提交执行
  → 正常完成并收尾后，按第 6 节推进和回报 R
```

`W` 让 CP 知道当前编号已被预留，Header 才完成包体与消费者之间的交接。CP 可以读取 Header 来判断状态；看到 `INVALID` 时，不能把尚未完成填写的包体当作有效命令，也不跳过当前 `R` 处理后面的包。这个队列暂时没有可处理包，按下文调度规则等待后续检查。

Host 发布有效 Header 后，`W` 可以保持不变。因此重试协议必须能在 `W` 不变时发现 Header 的变化，不能只等写索引再次增长。CP 按正常队列选择规则重新检查，通知与生产进度刷新按[第 5.2.3 节](#spec-doorbell-notification)处理。AMD 运行时的固定源码与本版取舍见[预留与发布参考](<./CP_MEC 软件实现、参考与扩展.md#aql-reserve-publish>)。

<a id="spec-aql-multi-producer"></a>

**[DESIGN]** 同一条用户 AQL Queue 支持多个 Host 线程提交。Host 原子更新共享内存中的 32 位 `W`，为各线程分配不同包编号；CP 只读取 `W`。每个线程等自己的物理槽可复用后，独立填写和发布，不用一把锁把所有线程的填包、Header 发布和通知过程串起来。

假设 `R = W = 10`，且至少有两个可复用槽，两个线程分别提交一包：

```text
线程 1：原子更新 W，取得包编号 10 → 填写包 10
线程 2：原子更新 W，取得包编号 11 → 填写包 11
两个线程取得不同编号后，可以并行填包。

线程 2 先写完：
  → 发布包 11 的有效 Header，再通知 Doorbell

CP 检查包 10，发现仍为 INVALID：
  → 保持消费位置，等待后续检查

线程 1 写完：
  → 发布包 10 的有效 Header，再通知 Doorbell
  → CP 按包 10、包 11 的顺序处理
```

取号必须是一次原子读改写，不能由独立的读取和写回拼成；它保证各线程取得不同编号，包体可见性则由后续 Header 发布保证。`W` 保持 32 位对象和 32 位访问，存放位置至少按 8 字节对齐，并映射为支持 Host CPU 原子操作的共享普通内存。原子预留在 Host 线程之间完成，不要求 CP 的访存窗口提供原子加法。

每个线程只能填写自己预留、且已满足槽复用条件的包；填写期间 Header 保持 `INVALID`。CP 遇到当前包尚未发布时不跳过它，按下文规则检查其他队列，后续仍能在 `W` 不变时发现 Header 发布。调用方须在原子取号前完成可能失败的资源准备和参数检查。正常路径取号后必须完成发布，第一版不提供取消预留编号的能力，不能回退共享 `W`。

<a id="spec-aql-reservation-lifetime"></a>

**[DESIGN]** 调用方先准备代码、参数、Signal 和事件等资源，再进入预留、填包、发布过程。以下以线程已取得编号 `P` 为例：

```text
可能失败的资源准备、参数检查 → 成功后才原子取号
  → 取得 P，等待对应物理槽
  → 填包、发布有效首部、通知 Doorbell
  → 本次发布结束

取号后线程异常退出，P 留下 INVALID 空洞
  → CP 仍停在 P，不跳过它
  → 调用方停止继续使用这条队列，保留必要资源
  → 不回退 W、不自行填补空洞；补洞和自动恢复留作扩展
```

异常退出的资源保护沿用[第 7 节](#spec-errors-unmap)和[第 9.7 节](#spec-host-api-scope)，不能把提交线程退出当作设备访问已结束。CP 看到 `INVALID` 仍按未发布处理，不新增自动识别空洞或超时清除包槽的协议。在途预留数量由调用方的提交代码限制，保证 `W` 领先最老未归还编号的距离小于 `2^32`；具体限额随接入落实，须防止活跃编号重复。

管理 Ring 没有 AQL Header，仍以已发布的 `W` 确定可读命令范围：驱动按[管理 Ring 串行发布规则](#spec-management-submit-lock)取得两个空槽，写完本次命令对，再一次发布 `W` 并通知设备。`opcode` 只表示操作类型，不作为独立发布标记。

CP 根据 `CP_HQD_PQ_WPTR_POLL_ADDR / HI` 读取对应队列的软件进度，并用固件变量保存本次处理所需的值；本版不采用 `CP_HQD_PQ_WPTR_LO / HI`。

Doorbell 通知设备有包发布，CP 通过读取共享 `W` 刷新自己掌握的生产进度。队列驻留期间，以 `CP_HQD_PQ_RPTR` 保存的消费位置为依据，由 CP 按实际消费情况推进。通知不能覆盖消费位置或跳过尚未消费的包。例如下一待消费包为 10，Host 连续发布并通知包 10、11、12 后，CP 仍从 10 开始按序处理。

Ring 地址、容量、消费位置、生产进度及包的发布状态共同决定可处理的命令。Doorbell 通过 HQD 中的 BAR4 相对偏移与队列关联，字段编码见[第 8.1 节](#spec-hqd-field-encoding)，入口分配、通知写入值和重新读取生产进度的时机见[第 5.2.3 节](#spec-doorbell-notification)。看到尚未发布的 AQL `INVALID` 槽，应按发布协议等待，不能仅凭该值报告坏包。

**[DESIGN]** 裸机固件按固定规则选择队列：

```text
开始一轮检查
  → 检查 KIQ、HIQ，各处理至多一条可处理的管理命令
  → 从上次记录的位置开始，轮流检查用户槽位 2、3
      ├─ 未激活或没有可处理命令：跳过
      ├─ 两条都没有可处理命令：回到主循环
      └─ 找到可执行 Dispatch
          → 提交整个 Dispatch，轮询执行器直到完成
          → 按第 6 节收尾，记录下次优先检查另一条用户队列
          → 回到主循环
```

等待计算完成期间，CP 暂不处理其他队列，包括 KIQ、HIQ；Host 在 Ring 有空位时仍可继续发布。以下把当前分配在用户槽位 2、3 的两条队列记作 A、B。若 A、B 始终就绪，执行顺序为 A1、B1、A2、B2；B 无任务时跳过 B，继续 A。轮流选择保证提交机会，不保证两条队列占用相同计算时间。

A、B 的 HQD 可以同时保持驻留，轮换处理无需换出另一个槽位。若当前 Dispatch 一直不结束，普通队列处理也会停住；等待超时只结束本次等待，强制中止和复位收尾列入[后续异常恢复扩展](<./QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)。本版不增加可配置的优先级或时间片寄存器，也不实现中途抢占。调度限制及扩展依据见[固定轮流选择与阻塞执行](<./CP_MEC 软件实现、参考与扩展.md#scheduling>)。

<a id="spec-doorbell-notification"></a>

#### 5.2.3 Doorbell 入口、通知值与队列复查

沿用上一节的两个线程例子：Queue A 已激活，包 10、11 均已取得可复用槽，此时 `W = 12、R = 10`，本例不再预留其他包。线程 2 先发布包 11，线程 1 随后发布包 10；两次通知写入同一个 Doorbell 入口：

```text
线程 2：发布包 11 的有效 Header → Doorbell ← 11
CP 检查 Queue A：
  → 读取 W = 12，从 R = 10 检查 Header
  → 包 10 仍为 INVALID，保持 R，暂时检查其他队列

线程 1：发布包 10 的有效 Header → Doorbell ← 10
CP 再次检查 Queue A：
  → W 仍为 12，包 10 的 Header 已有效
  → 处理包 10，正常完成并收尾后推进 R = 11
  → 按既定调度再次轮到 Queue A，继续处理已发布的包 11
  → 包 11 正常完成并收尾后，R = 12，此时队列为空

包 11 不需要补发 Doorbell 通知。
```

**[DESIGN]** KIQ、HIQ 和每条用户 Queue 各用独立的 Doorbell 入口。管理队列的入口由驱动保留，用户 Queue 的入口在创建时由驱动分配；驱动将 BAR4 相对偏移写入 MQD，CP 装入 HQD 后建立入口与队列的对应。用户入口不固定绑定 HQD 槽位 2 或 3；入口与队列一同保留，旧映射和销毁后的复用按 9.7 的生命周期规则落实。

每个入口按 8 字节对齐，Host 每次完整写入 64 位小端值。低 32 位保存已发布包的编号 `P`，高 32 位填零；共享内存中的 `W`、`R` 继续按 32 位访问。Doorbell 控制字段仍以 4 字节为偏移单位，8 字节入口要求对应的偏移字段值为偶数；完整 8 字节访问必须落在 BAR4 内。配置值与通知值的换算见[第 8.1 节](#spec-hqd-field-encoding)。

用户 AQL 包先发布有效 Header，再向 Doorbell 写 `P`。同一线程连续发布一批包时，可以在这批包全部发布后，用最后一个包编号通知一次；通知不能引用尚未发布的包。管理 Ring 先写完整命令、发布新的 `W`，再以本次最后一个包编号通知，即 `(W - 1) mod 2^32`。

多个 Host 线程的通知值允许乱序，如上图中的 `11 → 10`。后写入的 `10` 不会撤销包 11 的通知，也不能把消费位置或已知工作范围缩回包 10。设备不能仅因数值较小或与前次相同就丢弃有效通知；重复、连续或合并通知都必须保留继续发现已发布包的能力。CP 从当前 `R` 按顺序检查 Header，不能用通知值直接覆盖 `R`，也不能把最后一次通知值直接当作共享 `W`。

**[DESIGN]** 第一版 CP 每次按主循环轮到一条活跃队列时，都根据 `CP_HQD_PQ_WPTR_POLL_ADDR / HI` 重新读取 `W`，再从 `R` 检查当前包。`W = R` 时本次无包可取；用户 AQL 的当前 Header 为 `INVALID` 时保留 `R`，转去检查其他队列，后续再次读取 Header。这个复查过程不以 `W` 增长或再次收到 Doorbell 为前提。

Doorbell 提供有包发布的通知，CP 在该队列下一次被检查时取得最新进度和发布状态。队列读空后仍参加后续轮询；CP 等待计算完成期间到达的提交，在返回主循环后检查。已发布的包可按序继续处理，无需为同一批已通知工作逐包补发通知。调度仍按第 5.2.2 节执行，不要求一次清空整条 Ring；本实验仍在整个 Dispatch 完成并收尾后推进 `R`，任务结果通过 Signal 和错误协议确认。

**[BOUNDARY]** Doorbell、队列轮询及并发提交遵守本节约定。AMD/HSA 的乱序通知、按序派发与任务完成语义见[Doorbell 参考](<./CP_MEC 软件实现、参考与扩展.md#doorbell>)；本实验每次检查队列时读取 `W`，不据此推定 AMD 固件的内部轮询方式。

<a id="spec-dispatch-completion"></a>

## 6. 计算提交、完成 Signal 与 Ring 槽复用

CP 按[第 6.1 节](#spec-dispatch-packet)检查 AQL Dispatch，以用户地址域读取 Kernel 描述对象，再把代码入口、参数地址、声明长度和任务规模交给执行器。执行器以真实 `a0` 读取参数，并按同一 GPUVM 状态完成取指和数组读写，见[代码与参数的访问关系](#spec-kernel-data-storage)。

**[DESIGN]** 保留现有分发寄存器及 PCIe BAR 映射，正常任务改由 CP 访问这些分发接口。CP 向执行器交付的描述字段和参数访问方式见[第 6.2 节](#spec-kernel-descriptor)，CP 地址映射、长度寄存器、提交与结果确认规则见[第 6.3 节](#spec-executor-dispatch)。这些接口与分段执行已接入，代码说明见[计算派发实现](<./CP_MEC 软件实现、参考与扩展.md#dispatch>)。

正常成功路径采用以下顺序：

```text
读取并解析 Dispatch，保持原消费位置
  → 提交计算，阻塞等待整个 Dispatch 完成
  → 确认结果写回，完成任务清理
  → 按完成协议发布 Signal，此后不再访问该任务的参数等资源
  → 完整写入 32 位首部，将原 Ring 包槽恢复为 INVALID
  → 保证 INVALID 对 Host 可见
  → 推进 CP_HQD_PQ_RPTR
  → 向 RPTR_REPORT_ADDR 指向的内存回报新进度
  → Host 观察到新进度后，可以复用已消费包占用的 Ring 槽
```

**[DESIGN]** CP 结束旧包槽访问后，以完整的 32 位写入恢复无效首部，执行带编译器内存约束的 `fence iorw, iorw`，再推进 HQD 中的 `R` 并向 Host 回报；后端须保证无效首部先于新回报可见。Host 取得允许本次编号使用该槽的消费回报后，执行带编译器内存约束的 `dmb sy`，以完整的 32 位读取确认首部为 `INVALID`，然后填写新包。读取和写入仍遵守[完整访问规则](#spec-aql-header-access)，某一步失败时按[第 7.3 节](#spec-failure-retirement)停止正常收尾。

读进度用于判断 Ring 槽是否可复用，任务结果按 Signal 和错误协议判断。回报内存保存 CP 发布的进度副本；MQD 在卸载保存时接收需要恢复的状态，下次驻留时再装回 HQD。Host 不独立推进这些副本。回报尚未完成时，Host 可能读到旧值，因此应暂缓复用对应槽位。进度副本与槽位复用的例子见[消费进度与回报](<./CP_MEC 软件实现、参考与扩展.md#consumption>)。

本版的 32 位消费进度按[第 5.2.1 节](#spec-ring-progress)表示，不采用 `CP_HQD_AQL_DISPATCH_ID / HI`，推进时机仍遵守上述顺序。Signal 按[第 2.1.2 节](#spec-signal-single-writer)由 CP 单独更新，仍须保证 64 位读写完整性和结果可见性。Dispatch 必须提供有效 Signal，包校验失败按下节停止所属队列后续取包；执行失败、写回失败及基本资源收尾按第 7 节和 9.6 执行，强制恢复留作后续扩展。

<a id="spec-dispatch-packet"></a>

### 6.1 Kernel Dispatch 的布局、尺寸与字段校验

Host 要计算 1024 个元素的向量加法，已经准备好 Kernel 描述对象、参数块和完成 Signal。下面沿一次提交说明包里的信息怎样交给执行器：

```text
Host 准备一个 64 字节 Kernel Dispatch 包
  ├─ kernel_object：Kernel 描述对象的位置
  ├─ kernarg_address：参数块的位置，保存数组位置和 N
  ├─ grid_size = (1024, 1, 1)：总共启动 1024 个线程
  ├─ workgroup_size = (256, 1, 1)：每组 256 个线程
  └─ completion_signal：本次任务的完成 Signal
          ↓
CP 检查包，读取 Kernel 描述对象
  → 换算成 4 个工作组，每组 256 个线程
  → 交给执行器
  → 成功完成并确认结果写回后，更新 Signal
```

**[DESIGN]** 第一版用户 AQL Queue 只执行 Kernel Dispatch。采用标准 AQL Kernel Dispatch 的 64 字节布局，保留字段偏移和位宽；字段取值的支持范围，以及描述对象、参数和 Signal 的引用方式，按本实验约定执行。独立的 Barrier-AND、Barrier-OR、Agent Dispatch 和厂商自定义包暂不支持；管理命令继续使用 KIQ、HIQ 的独立格式。

#### 6.1.1 标准包布局与本版字段取值

以下按包起点列出字节偏移，多字节字段采用小端格式。`grid_size` 和 `workgroup_size` 分别由三个轴的字段组成；参数地址和完成引用都保留完整 64 位：

```text
字节偏移  字段                     位宽
0x00      header                   16
0x02      setup                    16
0x04      workgroup_size_x         16
0x06      workgroup_size_y         16
0x08      workgroup_size_z         16
0x0a      reserved0                16
0x0c      grid_size_x              32
0x10      grid_size_y              32
0x14      grid_size_z              32
0x18      private_segment_size     32
0x1c      group_segment_size       32
0x20      kernel_object            64
0x28      kernarg_address          64
0x30      reserved2                64
0x38      completion_signal        64
总大小：64 字节
```

`header` 和 `setup` 各占 16 位，共用包开头的 4 字节；共享槽的这个首部按[第 5.2.2 节](#spec-aql-header-access)以完整的 32 位值读写和发布。字段布局保持不变。有效 Dispatch 的 Header 按以下规则填写：

```text
header：
  bits 7:0    type          = 2（KERNEL_DISPATCH）
  bit 8       barrier       = 0 或 1
  bits 10:9   acquire scope = 2（SYSTEM）
  bits 12:11  release scope = 2（SYSTEM）
  bits 15:13  保留，填 0

setup：
  bits 1:0    dimensions = 1、2 或 3
  bits 15:2   保留，填 0
```

因此，有效 Dispatch 的 `header` 为 `0x1402` 或 `0x1502`，区别只在 `barrier` 位；这两个值不用于槽初始化或尚未发布的状态。CP 读到 `type = 1（INVALID）` 时按发布协议等待，不继续用未发布的包体做字段校验。其他包类型按本版不支持处理。

**[DESIGN]** `reserved0`、`reserved2` 及 Header、setup 中的保留位全部填零。`group_segment_size = 0`，不申请工作组共享存储；`private_segment_size = 0`，不通过 Dispatch 申请每线程私有存储。线程继续使用现有固定寄存器，相关扩展见[资源说明](<./CP_MEC 软件实现、参考与扩展.md#kernel-registers-lds>)。

三个对象引用都必须有效：`kernel_object`、`kernarg_address`、`completion_signal` 分别保存描述对象、参数块和 Signal 的用户 GPU 地址。第一版每个任务都提供独立的完成 Signal，不采用省略完成 Signal 的提交方式。对象的位宽、对齐、计算溢出和完整访问范围按[第 2.4.2 节](#spec-address-validation)检查，描述对象、参数长度和向量加法参数布局见[第 6.2 节](#spec-kernel-descriptor)，Signal 的 24 字节布局见[第 2.5.2 节](#spec-signal-layout)。

> **[SPEC]** [HSA System Architecture 1.2](https://hsafoundation.com/wp-content/uploads/2021/02/HSA-SysArch-1.2.pdf)，**2018-05-02**，§2.9.1、表 2–4，原文第 25 页规定 Header 位域；§2.9.6、表 2–7，原文第 29 页规定 64 字节 Kernel Dispatch 布局。标准中的 `completion_signal` 是 Signal 句柄，本实验采用物理地址引用；布局沿用标准，不能据此认定完整 HSA 兼容。运行时字段定义与枚举见[包格式参考](<./CP_MEC 软件实现、参考与扩展.md#dispatch-packet-reference>)。

#### 6.1.2 从线程数量换算工作组数量

**[DESIGN]** `setup.dimensions` 支持 `1、2、3`。三个轴的 `grid_size`、`workgroup_size` 均必须大于零；一维任务的 y、z 轴都填 `1`，二维任务的 z 轴填 `1`。第一版只接受完整工作组，每一维的 `grid_size` 必须是对应 `workgroup_size` 的整数倍。

AQL 的 `grid_size` 表示各轴的线程数量，现有执行器的 `grid_dim` 表示各轴的工作组数量。CP 先检查整除条件，再逐轴换算；上面的向量加法对应：

```text
AQL 包：
  grid_size      = (1024, 1, 1)
  workgroup_size = (256, 1, 1)
          ↓ 逐轴相除，得到工作组数量
执行器启动状态：
  grid_dim       = (4, 1, 1)
  block_dim      = (256, 1, 1)
```

CP 还须检查三个乘积：

- 每组线程数：三个 `workgroup_size` 分量相乘，最多 `1024`。
- 工作组总数：三个换算后的 `grid_dim` 分量相乘，最多 `4096`。
- 实际启动线程总数：三个 `grid_size` 分量相乘，最多 `65536`。

计算过程必须检查溢出，不能先得到截断结果再与上限比较。

末尾数据不足一个完整工作组时，由运行时在发布前补齐包里的线程数量，并由 Kernel 检查实际数据范围。例如实际处理 `N = 1000` 个元素、每组 256 个线程：

```text
运行时：grid_size_x = 1024，workgroup_size_x = 256，参数 N = 1000
  → CP 换算成 4 组，每组 256 个线程
  → Kernel：i < 1000 时处理元素，i >= 1000 时直接退出
```

这个任务按 `1024` 个实际启动线程检查上限。CP 收到 `grid_size_x = 1000、workgroup_size_x = 256` 时，按不满足整除条件拒绝该包，不自行补齐已经发布的任务尺寸。

> **[SOURCE]** 实验子仓库固定版本 `57543dd54b6b046b888277272fa84af81746b1ac`：[hw/gpgpu/gpgpu_core.h](vscode://file/home/book/1.project/gpu_study/4.experiments/gpu-study-qemu/hw/gpgpu/gpgpu_core.h:31:1)的 [31–34 行](vscode://file/home/book/1.project/gpu_study/4.experiments/gpu-study-qemu/hw/gpgpu/gpgpu_core.h:31:1)定义三项上限；[hw/gpgpu/gpgpu_core.c](https://github.com/hxfei-git/gpu-study-qemu/blob/57543dd54b6b046b888277272fa84af81746b1ac/hw/gpgpu/gpgpu_core.c#L570)的 [570–628 行](https://github.com/hxfei-git/gpu-study-qemu/blob/57543dd54b6b046b888277272fa84af81746b1ac/hw/gpgpu/gpgpu_core.c#L570-L628)检查乘积并遍历三维工作组。这些是教学执行器在该基线中的约束，不是 MI300X 的硬件上限；当时尚未接入 AQL 到执行器的换算。

<a id="spec-dispatch-validation"></a>

#### 6.1.3 任务同步与非法包处理

**[DESIGN]** Dispatch 的 acquire、release fence scope 均要求 `SYSTEM`。执行前落实输入和参数的可见性，任务完成时先保证结果写回，再发布完成 Signal；CP、执行器和 Host 软件须实际完成相应同步，不能只检查字段值。包体与 Header 的发布仍按 9.4 的规则执行，Host 等待完成后的同步按[第 6.4 节](#spec-dispatch-visibility)执行。

Header 的 `barrier` 位允许 `0`、`1`。`barrier = 1` 要求当前任务在同队列前序任务完成后启动；本版每次完整执行一个 Dispatch 后才选择下一个，因此两种取值都满足这项要求，`0` 也不使当前执行器并行运行多个 Dispatch。独立 Barrier-AND、Barrier-OR 包仍不支持。

**[DESIGN]** CP 对已发布的包检查类型、保留位、必填对象引用、维度、整除条件、资源字段、同步字段和规模上限。遇到不支持的包或非法字段时，拒绝执行，记录到所属队列的 `CP_HQD_ERROR`，停止该队列后续取包，不静默忽略，也不把 Signal 更新为成功完成。`INVALID` 继续按正常等待处理。队列错误编号见[第 7.2.1 节](#spec-queue-error-codes)；失败后的消费进度、Host 等待退出和资源保留按[第 7.3 节](#spec-failure-retirement)处理。

**[BOUNDARY]** Dispatch 校验、尺寸换算、计算交接及同步遵守本节约定。Kernel 描述对象与 RV32 计算执行器的参数约定已按[9.5.2](#spec-kernel-executor-interface)确定，完整规则见下节；RV64 CP 到执行器的寄存器和结果接口已按[9.5.3](#spec-cp-dispatch-interface)确定，见[第 6.3 节](#spec-executor-dispatch)。

<a id="spec-kernel-descriptor"></a>

### 6.2 Kernel 描述对象、真实参数地址与启动 CSR

CP 已取得 Dispatch，接下来读取 16 字节描述对象、核对 Kernel ABI，并为 RV32 执行器交付配置：

```text
Dispatch → kernel_object → 用户域读取描述对象
  → 检查 kernel_abi_version = 2、代码与参数范围及对齐
  → 保存 gpuvm_enabled、VMID、HQD 槽、代码和参数地址、长度与工作规模
  → 新建 Warp：填写一次共享启动状态，再填写各 Lane 线程坐标
  → 初始化 PC、mhartid，并令各有效 Lane 的 a0 = kernarg_address
  → Kernel 通过 CSR 取得启动坐标，通过普通内存读取参数和数组
```

#### 6.2.1 16 字节 Kernel 描述对象

**[DESIGN]** 描述对象至少按 8 字节对齐，当前示例存于 VRAM；四个字段均为 32 位无符号小端值：

```text
偏移 0x00：code_entry          代码入口的 GPU 地址
偏移 0x04：code_size           代码区域的字节长度
偏移 0x08：kernarg_size        参数块的字节长度
偏移 0x0c：kernel_abi_version  固定为 2
```

CP 拒绝旧值 0 和所有不支持的 ABI。代码入口按 4 字节对齐，代码长度非零且为 4 字节整数倍；使用宽整数检查地址加长度，执行器每次取指仍受声明代码范围约束。描述对象可供同一 Kernel 的多次提交复用，AQL 包仍为 64 字节。

#### 6.2.2 Host 参数块的布局与长度

参数仍位于独立 Host coherent BO，至少按 8 字节对齐，长度为 4 字节至 64 KiB 的 4 字节整数倍。无参数 Kernel 使用 4 字节零占位块。参数内容由应用和 Kernel 约定，CP 只校验地址、长度与对齐。

```text
向量加法参数：共16字节
  0x00：X 的 GPU 地址，32位
  0x04：Y 的 GPU 地址，32位
  0x08：Z 的 GPU 地址，32位
  0x0c：N，32位
```

参数不增加前缀或启动信息指针。地址在 GPUVM 开启时为 GPUVA，关闭时为 GPU 物理地址；传入 RV32 字段前须检查 32 位范围。

<a id="spec-kernarg-window"></a>

#### 6.2.3 计算线程用真实 a0 读取参数

`a0 = kernarg_address`。以 GPUVM 关闭、64 MiB VRAM 为例，参数 Host IOVA 为 `0x4100_2000`，对应 GPU 物理地址 `0x4500_2000`：

```text
Kernel 执行 lw t0, 12(a0)，a0 = 0x4500_2000
  → 普通用户访问 GPU 地址 0x4500_200c
  → 公共物理入口选择 Outbound
  → 减 0x0400_0000 → Host IOVA 0x4100_200c
  → t0 取得 N
```

开启 GPUVM 时，`a0` 保存参数 GPUVA，普通访存先按保存的 VMID 翻译。参数运行时适用普通内存访问规则，不再识别 `0x9000_0000` 参数窗口，不单独拒绝旧窗口写入。CP 自己的本地访存窗口保持独立。

#### 6.2.4 访问校验、资源寿命与失败处理

派发时保留代码、参数范围和对齐检查。执行中，取指还检查声明代码范围，参数和数组读写按普通内存路由、映射及权限处理。高位非法、越界、访存失败或指令错误都使任务失败，由 CP 停止源队列后续取包，不补写成功 Signal。

Host 在发布后保留对象内容、绑定和存储。正常结束先排空和销毁 Queue，再结束事件与旧通知、解绑和释放；开启 GPUVM 时解绑还须完成 TLB 失效。未知结果继续保留资源，关闭 GEM handle 不提前回收已绑定对象，CPU mmap 独立保活存储。

#### 6.2.5 Warp 与 Lane 的只读启动状态

每 Warp 的 `startup_sgpr` 保存 `blockIdx.x/y/z`、`blockDim.x/y/z`、`gridDim.x/y/z`，共 9 个 32 位值；每 Lane 的 `startup_vgpr` 保存 `threadIdx.x/y/z`，共 3 个 32 位值。它们独立于 Kernel 可覆盖的通用寄存器。

```text
0xCC0～0xCC2：THREAD_ID_X / Y / Z
0xCC3～0xCC5：BLOCK_ID_X  / Y / Z
0xCC6～0xCC8：BLOCK_DIM_X / Y / Z
0xCC9～0xCCB：GRID_DIM_X  / Y / Z
0xF14：mhartid，保留现有编号和编码
```

创建新 Warp 时初始化一次，坐标按 X 维变化最快的顺序填写，`gridDim` 表示 Block 数量；同一 Warp 分段继续时不重置，切到下一个 Warp 才重填。CSR 读取仅支持 `CSRRS` 且 `rs1` 编码为 `x0`；`rd=x0` 仍检查 CSR 有效性再丢弃结果，未知 CSR、写入及其他形式报指令错误。汇编器支持 `csrr`、`csrrs`，接受数字和 `.equ` 常量并检查范围。

**[BOUNDARY]** 本轮只实现启动状态及只读接口，不扩展可写 SGPR/VGPR、标量 ALU 或向量指令体系。RV32 的旧控制页已删除；`0x8000_0000`、`0x9000_0000` 在开启翻译时是普通 GPUVA，关闭时只按 VRAM／Outbound 物理布局解释。

<a id="spec-executor-dispatch"></a>

### 6.3 CP 提交计算与读取执行结果

CP 已读取一个有效 Dispatch，接下来把描述对象中的代码信息、包中的参数 GPU 地址和任务规模交给执行器。以下继续使用 1024 个元素的向量加法；本节采用 CP 解析描述对象、执行器接收解析后配置的分工：

```text
CP 读取 Dispatch 和 Kernel 描述对象
  → 取得代码入口、代码长度、参数 GPU 地址和参数长度
  → 换算任务规模：4 个工作组，每组 256 个线程
  → 填写执行器配置，最后写 DISPATCH
          ↓
RV32 计算执行器
  → 从 VRAM 取指，检查是否超出代码范围
  → 通过真实 a0 按普通内存规则读取参数
  → 执行计算并写回结果
  → 保存成功或失败状态
          ↓
CP 读取并确认执行结果
  → 成功：完成收尾，发布 Signal，再释放 Ring 槽
  → 失败：记录队列错误，停止该队列后续取包
```

#### 6.3.1 CP 访问入口与原有启动配置

**[DESIGN]** 保留原有分发寄存器及其 BAR0 偏移。CP 按 `0xfffd_0000 + BAR0 字节偏移` 访问本节定义的寄存器；例如 Host 的 `BAR0 + 0x0330` 与 CP 的 `0xfffd_0330` 都指向同一个 `DISPATCH`。两条入口访问同一份设备状态。

原有配置在队列路径中采用以下含义：

```text
0x0300 / 0x0304  KERNEL_ADDR_LO/HI：代码入口的 GPU 地址
0x0308 / 0x030c  KERNEL_ARGS_LO/HI：参数的 GPU 地址，高 32 位为零
0x0310 / 0x0314 / 0x0318  GRID_DIM_X/Y/Z：工作组数量，本例为 (4, 1, 1)
0x031c / 0x0320 / 0x0324  BLOCK_DIM_X/Y/Z：每组线程数量，本例为 (256, 1, 1)
0x0328  SHARED_MEM_SIZE：第一版填 0
0x0330  DISPATCH：写 1，提交本次配置
```

`KERNEL_ADDR`、`KERNEL_ARGS` 保存用户 GPU 地址，两个高位寄存器均须为零。描述对象由 CP 读取，执行器使用传入的代码入口和真实参数地址，不再解析描述对象或参数窗口。

所有寄存器采用对齐的 32 位小端访问。CP 在空闲时分高、低两次填写 64 位地址，全部配置写完并保证顺序后才写 `DISPATCH`；设备在提交时统一保存本次配置。这里不要求将两个地址寄存器合成一次 64 位原子写入。

#### 6.3.2 代码与参数长度的交付

**[DESIGN]** 增加两个 32 位长度寄存器，CP 分别写入描述对象的 `code_size`、`kernarg_size`，单位均为字节：

```text
BAR0 偏移  寄存器           CP 写入的值
0x032c     KERNEL_CODE_SIZE  code_size
0x0334     KERNEL_ARGS_SIZE  kernarg_size
```

提交时用两个长度检查代码与参数的完整地址范围、对齐和溢出。执行器每次取指继续检查声明代码范围；参数运行时访问按普通内存规则处理，不用 `kernarg_size` 建立额外窗口或逐次参数边界。

#### 6.3.3 提交、执行状态与结果确认

**[DESIGN]** 一次只接收一个任务。新增三个 32 位寄存器，分别保存本次执行状态、失败原因和确认操作：

```text
BAR0 偏移  寄存器          访问与含义
0x0338     DISPATCH_STATUS  只读：0=IDLE，1=BUSY，2=DONE，3=FAILED
0x033c     DISPATCH_ERROR   只读：本次失败原因，成功时为 0
0x0340     DISPATCH_ACK     写 1，确认已经读取本次结果
```

CP 只在 `IDLE` 时填写配置，最后向 `DISPATCH` 写 `1`。设备统一保存本次配置，校验通过后进入 `BUSY` 并执行；提交校验失败则直接返回 `FAILED`，不执行 Kernel。

```text
IDLE → 提交 → BUSY → DONE 或 FAILED
                                  ↓
                         CP 读取并保存结果
                                  ↓
                         写 ACK → 回到 IDLE

提交校验失败：IDLE → 提交 → FAILED → CP 读取结果并写 ACK → IDLE
```

`BUSY` 或存在未确认结果时，拒绝修改配置和再次提交，保留当前任务及结果。`DONE`、`FAILED` 和对应结果保持到 CP 读取并确认；`DISPATCH_ACK` 只用于确认终态结果，不能中止正在执行的任务。CP 必须先保存结果，再确认取走，不能用尚未开始下一任务时读到的旧完成状态判断新任务成功。

本次执行结果单独保存。现有全局错误还会记录 DMA、非法寄存器访问等其他故障，CP 不能仅凭全局状态判断这个 Dispatch 的成败。基本错误退出按第 7 节执行，故障复位恢复留作后续扩展。

**[DESIGN]** 本次接入将 `DISPATCH_ERROR` 定义为以下独立编号，保留到终态确认；这些编号不直接写入 HQD。CP 读取失败结果后，仍以队列错误 `4`（执行器失败）记录所属队列：

```text
0  NONE            没有执行错误
1  INVALID_CONFIG  提交配置不满足尺寸、地址或长度约束
2  CODE_RANGE      取指超出声明范围、对齐错误或取指访问失败
3  INSTRUCTION     无法执行的指令或不支持的 CSR 形式
4  MEMORY          普通存储访问失败
5  BUDGET          累计执行预算耗尽
```

忙时重提、未确认时修改配置、非法寄存器宽度或越权访问均保留当前任务及结果，另置全局 `INVALID_CMD`，不能借此覆盖当前 `DISPATCH_ERROR`。

#### 6.3.4 执行器分段推进与 CP 等待

**[DESIGN]** 启动操作及时返回，执行器后续分段执行，各段之间保留线程状态，执行预算持续累计。CP 检查执行状态期间，执行器必须能够继续推进；Host 在 Ring 有可复用槽时也能继续发布任务。

第一版仍按整个 Dispatch 调度。CP 等待当前任务时不启动其他队列的任务，完成当前任务及收尾后再返回队列主循环。执行器分段推进只是让 QEMU 有机会处理其他活动，不改变本版一次完整执行一个 Dispatch 的队列选择规则。

> **[SOURCE]** 实验子仓库固定版本 `57543dd54b6b046b888277272fa84af81746b1ac`：[hw/gpgpu/gpgpu_regs.h](vscode://file/home/book/1.project/gpu_study/4.experiments/gpu-study-qemu/hw/gpgpu/gpgpu_regs.h:35:1) 的 [35–47 行](vscode://file/home/book/1.project/gpu_study/4.experiments/gpu-study-qemu/hw/gpgpu/gpgpu_regs.h:35:1)定义原有分发寄存器；[hw/gpgpu/gpgpu_dispatch.c](https://github.com/hxfei-git/gpu-study-qemu/blob/57543dd54b6b046b888277272fa84af81746b1ac/hw/gpgpu/gpgpu_dispatch.c#L14) 的 [14–39 行](https://github.com/hxfei-git/gpu-study-qemu/blob/57543dd54b6b046b888277272fa84af81746b1ac/hw/gpgpu/gpgpu_dispatch.c#L14-L39)在提交处理函数内同步执行整个 Kernel，再产生完成或失败通知。该基线当时尚未接入上述 CP 映射、五个新增寄存器和分段执行。

#### 6.3.5 提交权限、结果写回与 Signal

**[DESIGN]** 配置、`DISPATCH` 和 `DISPATCH_ACK` 由 CP 写入，Host 可以读取诊断状态。任务统一来自队列；旧 Host 同步提交旁路已删除。设备接受 Dispatch 时保存 `gpuvm_enabled`，分段执行期间不改变地址模式。

执行器只有在计算结束、结果写回完成且相关访问结束后，才能发布 `DONE`；失败也须结束相关访问后再发布 `FAILED`。CP 读取并保存结果、完成必要清理后，写 `DISPATCH_ACK` 确认取走结果。

确认取走结果后，成功路径继续按第 6 节发布 Signal、通知 Host 和归还 Ring 槽；失败路径记录所属队列错误并停止后续取包，不发布成功 Signal。执行器结果供 CP 收尾使用，Host 仍按 Signal 和错误协议判断任务结果；正常队列路径不直接沿用旧同步提交的计算完成中断来代替 Signal 通知。

**[BOUNDARY]** 本节已按[9.5.3](#spec-cp-dispatch-interface)确认。CP 映射、长度与结果寄存器、配置保存和分段执行已接入，等待期间的发布规则见上文；Signal 布局及等待登记协议已按[9.5.4](#spec-signal-completion-protocol)确认，可见性操作见[第 6.4 节](#spec-dispatch-visibility)，队列错误编号见[第 7.2.1 节](#spec-queue-error-codes)，失败收尾按[第 7.3 节](#spec-failure-retirement)处理，执行器细分错误码见第 6.3.3 节。

<a id="spec-dispatch-visibility"></a>

### 6.4 任务输入、执行结果与完成通知的可见性

继续使用 1024 个元素的向量加法。Host 已准备代码、描述对象、输入数组和参数；CP 取到包后要读取本次输入，Host 看到 Signal 完成后要取得本次输出。各步沿用已经确定的顺序，本节补齐屏障和访问接口的要求：

```text
Host 完成输入准备，发布有效 Header，再通知 Doorbell
  → CP 确认 Header 有效，读取包体和描述对象，配置并启动执行器
  → 执行器完成计算、结果写回及相关访问，发布 DONE
  → CP 保存结果并清理、确认，依次发布 Signal、通知槽和 IH 通知
  → Host 读到 Signal = 0，完成同步，再读取结果
```

#### 6.4.1 Host 准备输入并发布 Header

**[DESIGN]** Host 发布前须完成代码、描述对象和输入数组的 VRAM 上传，写好 Host RAM 参数与包体；通过 DMA 上传时，先确认传输成功完成。Host 仍按第 5.2.2 节原子预留编号，等待对应物理槽可复用，填写期间保持 Header 为 `INVALID`。

A57 用户态运行时封装带编译器内存约束的 `dmb sy`，在有效 Header 发布前及 Doorbell 写入前分别执行：

```text
完成输入准备和包体填写
  → dmb sy
  → 按发布规则写有效 Header
  → dmb sy
  → 按规定宽度写 Doorbell
```

第一个屏障使输入与包体的写入先于有效 Header 对设备可见；第二个屏障保证 Header 发布先于 Doorbell 通知。共享内存采用一致性映射仍须落实这些顺序，`volatile` 访问也须配合屏障。上传接口须以实际传输完成作为可发布的条件，执行一次屏障不能代替等待 DMA 完成。

> **[SOURCE]** Linux 固定版本 `248951ddc14de84de3910f9b13f51491a8cd91df`：
>
> - [Documentation/core-api/dma-api-howto.rst](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/linux/Documentation/core-api/dma-api-howto.rst:373:1) 的 [373–395 行](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/linux/Documentation/core-api/dma-api-howto.rst:373:1)说明一致性内存仍需屏障来排序数据与有效标记。
> - [Documentation/memory-barriers.txt](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/linux/Documentation/memory-barriers.txt:1914:1) 的 [1914–1956 行](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/linux/Documentation/memory-barriers.txt:1914:1)区分共享内存的 DMA 屏障与设备寄存器访问顺序。
> - [arch/arm64/include/asm/barrier.h](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/linux/arch/arm64/include/asm/barrier.h:27:1) 的 [27–29 行](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/linux/arch/arm64/include/asm/barrier.h:27:1)展示含 `memory` 编译器约束的屏障封装。

本实验用户态采用上述 `dmb sy` 封装；内核的 `dma_*` 宏用于驱动中的相应访问，不能直接作为用户态调用。

#### 6.4.2 CP 读取输入并启动执行器

**[DESIGN]** RV64 CP 固件封装带编译器内存约束的 `fence iorw, iorw`。确认 Header 有效后先执行屏障，再读取包体和描述对象；填写全部执行器配置后再执行屏障，最后提交：

```text
读到有效 Header → fence iorw, iorw → 读取包体、描述对象等输入
写完执行器配置 → fence iorw, iorw → 写 DISPATCH = 1
```

第一处落实包发布后的读取顺序；第二处保证代码、参数地址、长度和任务规模全部配置完成后才启动计算。读取 Header、轮询状态及共享字段须使用规定的访问方法，不能让编译器复用上次读取的值。Dispatch 的 acquire、release scope 继续为 `SYSTEM`，输入可见性由 Host 发布、CP 同步与后端访问共同落实。

#### 6.4.3 执行器写回结果后，CP 发布完成通知

**[DESIGN]** QEMU 执行器后端须先完成结果写回及本次相关访问，再发布 `DONE`。跨线程传递配置、结果或终态时，使用锁或 release/acquire 同步保证数据先于状态可见；发布 `FAILED` 也须遵守第 6.3.5 节的访问结束要求。CP 的内存屏障不能代替后端的实际完成和线程同步。

CP 取得并保存 Signal 的事件编号和通知槽地址后，成功路径按下列顺序处理。每处 `fence` 均指带编译器内存约束的 `fence iorw, iorw`：

```text
读到 DONE
  → fence，读取并保存执行结果，完成必要清理，写 DISPATCH_ACK
  → fence，按单一更新者规则将 Signal 从 1 减为 0 并写回
  → fence，向通知槽写入零扩展后的 event_id
  → fence，经 IH_SUBMIT 提交通知
```

确认取走结果后再发布 Signal，Signal 写回成功后再写通知槽，通知槽写入成功后再提交 IH。各次 Host 访问必须确认成功，后端也须保证前一步写入已对后续观察者可见，才能继续后一步；不能把仅已排入请求队列当作写入完成。任何一步失败都转入[第 7.3 节](#spec-failure-retirement)的异常退出流程，停止正常收尾并保留已经发生的写入。

包槽继续在 Signal 发布后按第 6 节归还，完整字段访问仍按[第 2.2.1 节](#spec-shared-value-integrity)执行。内存屏障只补齐顺序要求，不能替代动态字段的完整读写约定。

> **[SOURCE]** 实验子仓库固定版本 `57543dd54b6b046b888277272fa84af81746b1ac`：[target/riscv/insn_trans/trans_rvi.c.inc](vscode://file/home/book/1.project/gpu_study/4.experiments/gpu-study-qemu/target/riscv/insn_trans/trans_rvi.c.inc:947:1) 的 [947–952 行](vscode://file/home/book/1.project/gpu_study/4.experiments/gpu-study-qemu/target/riscv/insn_trans/trans_rvi.c.inc:947:1)将 RISC-V `FENCE` 转为 TCG 内存屏障；[hw/riscv/gpgpu-cp.c](https://github.com/hxfei-git/gpu-study-qemu/blob/57543dd54b6b046b888277272fa84af81746b1ac/hw/riscv/gpgpu-cp.c#L44) 的 [44–84 行](https://github.com/hxfei-git/gpu-study-qemu/blob/57543dd54b6b046b888277272fa84af81746b1ac/hw/riscv/gpgpu-cp.c#L44-L84)通过 Host 访问函数返回读写结果。这两处是当前可用的接入基础，尚不能证明队列、执行器终态与 Signal 的完整可见性协议已经实现。

#### 6.4.4 Host 确认完成后读取结果

**[DESIGN]** Host 按完整 64 位访问规则读到 `Signal = 0` 后，通过同一运行时封装执行带编译器内存约束的 `dmb sy`，再访问结果，落实完成读取的 acquire 语义：

```text
完整读取 Signal，确认值为 0
  → dmb sy
  → 通过现有接口读取或复制 VRAM 结果
  → 若使用 DMA 复制，等待成功完成
  → CPU 使用 Host 结果缓冲区
```

中断或事件唤醒只使线程重新检查 Signal；短暂轮询直接读到完成和阻塞唤醒后读到完成，都执行上述同步。通知处理与等待登记继续按[第 2.5.3 节](#spec-signal-notify-wait)配合，等待者以 Signal 值判断正常完成。

验证时连续提交多轮向量加法，每轮改变输入和预期结果，分别覆盖短暂轮询读到完成、转入阻塞后唤醒，以及前一任务完成时后续任务已经发布的情况；检查参数、输入和结果都属于对应任务，不能只反复计算同一组数据。还须核对后端完成条件和跨线程同步，运行结果不能代替访问顺序审查。

**[BOUNDARY]** 本节已按[9.5.5](#spec-task-visibility)确认；固件、调用方和后端按上述约定完成同步，验证结果统一见[大纲进度说明](<./QEMU GPGPU 实验大纲.md#current-progress>)。Header 的完整 32 位访问、管理 Ring 的串行发布及预留使用约束已按 9.4.4 补齐；错误与资源回收按 9.6、9.7 的已确认规则执行。

<a id="spec-errors-unmap"></a>

## 7. 错误记录、卸载与资源释放

**[DESIGN]** 保留每槽位的 `CP_HQD_ERROR`，用于记录取包、命令校验、执行与完成写回中的实际异常。需要覆盖 Ring 或写指针读取失败、已发布命令非法或不受支持、Dispatch 描述或参数不可用、执行器返回失败、读进度回报失败，以及完成 Signal 无效或无法更新。访存失败的归属与停止取包规则已在[第 2.1.1 节](#spec-memory-access-context)确定。管理请求通过[独立结果区](#spec-management-result)返回成败；管理通道取包、已发布命令配对和结果写回故障记录到来源管理队列，并停止该 Ring 后续消费。错误通知采用[IH 记录通路](#spec-ih-notification)，队列错误编号、首次记录、停止范围及清理后重建按[第 7.2 节](#spec-queue-error-policy)执行；失败收尾按[第 7.3 节](#spec-failure-retirement)处理，强制恢复步骤列入[后续异常恢复扩展](<./QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)。各类异常及诊断关系见[队列错误记录](<./CP_MEC 软件实现、参考与扩展.md#error>)。

访存或执行器必须把失败结果返回 CP，固件才能将错误归到所属队列。原有设备级 `ERROR_STATUS` 不能直接作为已经实现的 `CP_HQD_ERROR` 协议。Host 可通过选槽窗口查询错误；MQD 的 `saved_error` 在卸载保存时接收错误快照，Host 诊断缓冲区在驱动读取时接收副本，均不会自动同步。

Ring 为空、当前 AQL 槽仍为 `INVALID` 或执行器忙属于正常等待。已发布的不支持包和非法字段按[第 6.1.3 节](#spec-dispatch-validation)拒绝执行并停止所属队列后续取包；第一版不执行独立 Barrier 包，也不把它当作依赖等待。Host 等待超时只表明等待期限已到，不能直接据此认定 Kernel 执行失败。

正常卸载时，Host 先停止提交并等待队列排空，再请求 CP 卸载；CP 停止目标队列取包，确认相关访问结束，保存 MQD 后解除绑定。完整流程与 HIQ 关闭顺序见[第 7.4 节](#spec-unmap-drain)。保存字段继续使用[第 2.6 节](#spec-mqd-format)的 `saved_rptr` 和 `saved_error`，槽位释放仍遵守[第 4.2 节](#spec-management-slot-state)的条件。

本版不采用 `CP_HQD_DEQUEUE_REQUEST` 寄存器入口。故障队列的清理不要求先排空，尚未完成的等待按[第 7.3 节](#spec-failure-retirement)报错退出；卸载结果只确认管理操作，任务结果和资源释放仍按各自协议判断。只读到 `ACTIVE = 0`、发现错误或等待超时，都不能证明设备已经结束相关访问。故障时清除 `ACTIVE` 并保留占用的规则见[第 7.2.2 节](#spec-queue-error-stop-scope)；当前任务无法结束时的强制停止、运行期间 KIQ 重配及复位恢复列入[后续异常恢复扩展](<./QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)。

<a id="spec-ih-notification"></a>

### 7.1 IH 记录与 Host 错误通知

CP 发现一条用户队列无法继续处理后，需要把队列身份和错误原因交给 Host。驱动再找到对应 Queue 对象，保存错误状态并通知等待者。

**[DESIGN]** 第二阶段采用简化 IH：全设备共用一个 Host RAM IH Ring，设置七个管理寄存器和一个 CP 提交入口，中断控制沿用 `IRQ_ENABLE / IRQ_STATUS / IRQ_ACK`。设备将记录写入 Ring，发布后中断通知 Host，驱动读取记录并分发处理。本节于 2026-10-18 确认，设备、固件和驱动路径现已接入；记录编码及提交接口属于本实验设计。

以下沿一条用户队列说明完整路径。IH Ring 与记录中的 MQD 匹配地址使用 GPU 物理地址；Signal 与通知槽使用所属队列的用户 GPU 地址：

```text
CP 发现队列错误
  │
  ├─ 保存到该队列的 HQD.CP_HQD_ERROR
  ├─ 按错误规则停止后续取包
  │
  └─ 在固件私有 VRAM 中准备一条 32 字节记录
       ├─ type     = QUEUE_ERROR
       ├─ hqd_slot = 出错队列所在槽位
       ├─ mqd_addr = 该队列的 MQD 物理地址
       └─ data     = 错误码
                │
                │ 将这条临时记录的 VRAM 偏移
                │ 写入 IH_SUBMIT
                ▼
QEMU 设备中的 IH 模块
  │
  ├─ 读取并校验临时记录
  ├─ 根据 Ring 基址、IH_SIZE、IH_WPTR 找到写入位置
  ├─ 将记录写入 Host RAM 中的 IH Ring
  ├─ 保证记录可见，再推进 IH_WPTR
  └─ 通过设备中断通知 Host
                │
                ▼
Host 驱动
  │
  ├─ 根据 IH_RPTR、IH_WPTR 读取记录
  ├─ 用 mqd_addr 找到驱动中的 Queue 对象
  ├─ 直接从 data 取得错误码
  ├─ 保存错误并通知相关等待线程
  └─ 推进 IH_RPTR，归还已经读完的槽
```

`mqd_addr` 用于查找驱动中的队列对象，错误码已经保存在 IH 记录的 `data` 中。Host 处理这条通知时不需要先读取 MQD 或 HQD 才能取得错误码。`CP_HQD_ERROR` 继续提供驻留队列的错误状态查询，`MQD.saved_error` 在卸载保存状态时更新。

IH Ring 保存设备交给 Host 的通知记录。KIQ、HIQ 和用户 AQL Ring 保存 Host 交给 CP 的命令，继续使用各自已有的进度与管理协议。通知到达后，队列卸载和资源释放仍须满足各自的完成条件。

<a id="spec-ih-ring-record"></a>

#### 7.1.1 Ring 存储与记录布局

Linux 内核驱动分配并管理 Host RAM 中的 DMA 一致性内存，作为全设备共用的 IH Ring。基址按 4 KiB 对齐，`IH_SIZE` 保存实际字节容量，驱动默认配置为 4096。容量必须非零、为 32 字节的整数倍，并采用 2 的幂；驱动分配的内存须覆盖配置容量。

```text
Host RAM：IH Ring

默认字节容量 IH_SIZE = 4096
每条记录大小         = 32 字节
记录槽数量 N         = 4096 / 32 = 128

槽 0       偏移 0x0000
槽 1       偏移 0x0020
……
槽 127     偏移 0x0fe0
```

设备侧由 IH 模块统一串行写入，Host 侧由驱动串行消费；128 个槽都可使用。每条记录固定为 32 字节，多字节字段小端：

```text
偏移    大小      字段

0x00    4 字节    type
0x04    4 字节    hqd_slot
0x08    8 字节    mqd_addr
0x10    4 字节    data
0x14   12 字节    reserved，全部填 0
```

三种记录按以下方式解释：

```text
type = 1：SIGNAL_NOTIFY
  hqd_slot = 用户队列所在槽位，取 2 或 3
  mqd_addr = 该队列的 MQD 物理地址
  data     = event_id

type = 2：QUEUE_ERROR
  hqd_slot = 出错队列所在槽位，取 0～3
  mqd_addr = 该队列的 MQD 物理地址
  data     = 提交通知时 CP_HQD_ERROR 的 32 位错误值

type = 3：DEVICE_ERROR
  hqd_slot = 0xffff_ffff，表示没有具体队列
  mqd_addr = 0
  data     = 全局 ERROR_STATUS 的 32 位错误位快照
```

`type = 0` 和其他值暂不使用。记录保存事件发生时的队列身份；Host 不能只按槽位编号，把旧记录交给后来使用同一槽位的新队列。MQD 地址和事件编号的复用条件见[第 7.1.7 节](#spec-ih-object-lifetime)。队列错误值采用[第 7.2.1 节](#spec-queue-error-codes)的 32 位编号。

<a id="spec-ih-registers"></a>

#### 7.1.2 管理寄存器与状态字段

Host 配置 Ring 后，IH 模块根据基址、容量和写进度写入记录；Host 通过读进度归还槽位。以下七个寄存器统一采用对齐的 32 位小端访问。本次接入固定以下 BAR0 字节偏移；CP 诊断读取仍按 `0xfffd_0000 + 偏移` 访问：

```text
0x0800  IH_BASE_LO       Ring 基址低位
0x0804  IH_BASE_HI       Ring 基址高位
0x0808  IH_SIZE          Ring 字节容量
0x080c  IH_WPTR          已发布范围
0x0810  IH_RPTR          Host 消费回报
0x0814  IH_STATUS        通道故障与本次提交结果
0x0818  IH_CTRL          使能与复位
0x081c  IH_SUBMIT        CP 专用提交入口，见下一节
```

字段含义如下：

```text
IH_BASE_LO
  Ring 起始物理字节地址的低 32 位

IH_BASE_HI
  Ring 起始物理字节地址的高 32 位

IH_SIZE
  Ring 的字节容量，驱动默认配置为 4096

IH_WPTR
  下一条待写记录的编号
  由 IH 模块推进，Host 和 CP 只读

IH_RPTR
  下一条待读记录的编号
  由 Host 推进，设备检查更新是否合法

IH_CTRL
  bit 0：ENABLE，使能 IH
  bit 1：RESET，复位请求，处理后自动清零
  其余位保留为 0

IH_STATUS
  bit 0      ：BUSY，当前有 IH 操作正在进行
  bit 1      ：FAULT，IH 通道发生故障
  bits 7:2   ：保留为 0
  bits 15:8  ：ERROR_CODE，锁存首次 IH 故障原因
  bits 23:16 ：LAST_SUBMIT_RESULT，最近一次 CP 提交的结果
  bits 31:24 ：保留为 0
```

Host 只在 IH 已禁用且没有在途写入时修改 `IH_BASE_LO / HI`、`IH_SIZE`。两部分地址按原值直接拆分，完整基址为 `((uint64_t)IH_BASE_HI << 32) | IH_BASE_LO`，不使用移位后的地址编码。`IH_CTRL` 由 Host 控制，`IH_STATUS` 对 Host 只读；CP 对这七个寄存器均只读，通过下节的专用入口提交记录。

`ERROR_CODE` 保存 IH 通道首次故障的原因；`LAST_SUBMIT_RESULT` 保存最近一次 CP 提交的结果，`0` 表示记录已写入且 `IH_WPTR` 已发布，非零表示本次提交失败。其他设备事件可以使通道进入故障状态，但不得覆盖 `LAST_SUBMIT_RESULT`。CP 因而可以分别判断本次记录是否提交成功，以及 IH 通道是否还能继续使用。

**[DESIGN]** 两个字段采用同一组编号，但分别锁存，不能相互替代：

```text
0  OK        成功；错误字段中表示尚无故障
1  DISABLED  IH 未使能时提交
2  CONFIG    基址、容量或完整范围非法
3  FULL      未消费记录已占满 Ring，仍继续提交
4  DMA       Host Ring 写入失败
5  PROTOCOL  非法读进度、权限或寄存器操作
6  RECORD    临时记录地址或记录内容非法
7  FAULTED   通道已故障，拒绝本次提交
```

例如第一次满环提交使 `ERROR_CODE = 3、LAST_SUBMIT_RESULT = 3`；再次提交被拒绝后，前者仍为 `3`，后者更新为 `7`。IH 故障同时置全局 `ERROR_STATUS` 的 bit 4；无法归属队列的固件异常使用 bit 5，二者均通过原错误中断交付。

<a id="spec-ih-submit"></a>

#### 7.1.3 CP 临时记录与同步提交

CP 在[固件私有 VRAM](#spec-firmware-layout)中准备 32 字节临时记录，然后向专用的 `IH_SUBMIT` 写入该缓冲区的 32 位 VRAM 字节偏移。入口同样采用对齐的 32 位小端写入：

```text
固件私有 VRAM
  └─ 临时记录缓冲区：32 字节
          │
          │ CP 填好记录，并保证内容先于提交可见
          ▼
CP 写 IH_SUBMIT
  写入值 = 临时记录缓冲区的 VRAM 字节偏移
          │
          ▼
IH 模块同步处理
  ├─ 成功：写入 Host Ring，发布 W，记录提交成功
  └─ 失败：记录提交失败及必要的通道故障
          │
          ▼
提交写操作返回
  → CP 读取 LAST_SUBMIT_RESULT
  → 此后可以复用临时记录缓冲区
```

固件串行执行“准备记录 → 提交 → 读取结果”，期间不插入另一条 CP 提交。临时缓冲区在提交结束前保持内容不变，IH 模块在写操作返回前完成读取和本次提交的结果更新。提交成功表示记录已经发布给 Host，Host 对记录的消费可能尚未开始。

<a id="spec-ih-progress"></a>

#### 7.1.4 读写进度、回绕与发布

IH 的 W、R 都是 32 位无符号记录编号，初始进度为 0。设备用 W 选择下一写入槽，Host 用 R 选择下一读取槽：

```text
W = IH_WPTR：下一条待写记录
R = IH_RPTR：下一条待读记录
N = IH_SIZE / 32

未读取记录数 D = (W - R) mod 2^32

D = 0：空
D = N：满

记录所在槽 = 记录编号 mod N
记录地址   = Ring 基址 + 槽编号 × 32
```

IH 只发布已经写完的记录，正常运行时满足 `0 ≤ D ≤ N`。默认 128 槽时，物理槽按以下方式循环使用：

```text
写记录 127 → 槽 127
写记录 128 → 槽 0
写记录 129 → 槽 1
```

写记录 128 前，必须确认槽 0 的旧记录已经由 Host 归还。物理槽回绕时 W 不归零，编号继续增加，直到自身发生 32 位回绕；W、R 的差值始终按上述模运算计算。

Host 更新 R 时，设备检查本次归还数量：

```text
本次归还数量 = (新 R - 旧 R) mod 2^32

要求：本次归还数量 ≤ 当前未读取记录数 D
```

非法更新被拒绝，旧 R 保持不变，并按 IH 协议故障处理。`D = N` 表示容量已用满，只有此时继续提交且仍无可用槽，才触发满环提交失败。

发布与归还遵守以下顺序：

```text
设备：
写完整记录 → 保证记录可见 → 更新 W → 发出中断

Host：
读取 W → 完成读取同步 → 读完或复制记录 → 更新 R
```

Host 通过 W 判断记录是否已经完整发布，不要求整条 32 字节记录原子写入。Host 只有读完或完整复制记录后才可归还槽；复制后延后处理所需的对象仍须保留引用。具体内存同步操作随设备、固件和驱动接入落实并验证。

<a id="spec-ih-signal-notify"></a>

#### 7.1.5 中断确认与 Signal 通知

已有中断控制寄存器增加 IH 对应的 `bit 3`，MSI-X 使用向量 3：

```text
IRQ_ENABLE.bit3   允许 IH 中断
IRQ_STATUS.bit3   IH 中断待处理
IRQ_ACK.bit3      Host 确认本次 IH 中断
```

屏蔽 IH 中断不停止写 Ring。重新允许中断时，如果仍有未读记录，设备继续通知。Host 写 `IRQ_ACK` 时若 Ring 仍非空，也必须保留或重新产生通知，避免遗漏并发到达的记录。`IRQ_ACK` 处理的是中断状态，槽位由 `IH_RPTR` 归还。

正常任务完成时，CP 在发布完成值前取得并保存事件编号和通知槽地址，确认结果写回后，依次更新完成值、写通知槽，再提交 `SIGNAL_NOTIFY`：

```text
CP 确认任务结果写回
  → 将 S.value 从 1 更新为 0
  → 按保存的 event_mailbox_ptr，向通知槽写入零扩展到 64 位的 event_id
  → 提交 SIGNAL_NOTIFY，data = event_id
  → IH 写记录并通知 Host
  → 驱动用 mqd_addr 找到 Queue 及其所属进程
  → 在该进程事件表中按 event_id 找到事件
  → 确认事件与通知槽的关联，保存“已通知”状态，再清零通知槽
  → 唤醒等待线程
  → 线程重新检查 S.value
```

Signal 值仍是正常完成的判断条件，IH 负责将通知交给驱动。事件编号结合队列所属进程查找，不能直接在所有进程间按同一个编号查找。默认等待继续采用[短暂轮询后进入内核事件等待](#spec-signal-blocked-wait)的流程；Signal 的 24 字节布局、通知槽标记和防止漏唤醒的登记协议已按[第 2.5.2 节](#spec-signal-layout)、[第 2.5.3 节](#spec-signal-notify-wait)确定，具体可见性操作见[第 6.4 节](#spec-dispatch-visibility)。

<a id="spec-ih-fault-reset"></a>

#### 7.1.6 IH 故障与恢复前提

Ring 已满时再次提交、Host RAM 记录写入失败或非法协议操作，都使 IH 进入故障处理。设备不能覆盖尚未消费的记录：

```text
锁存 IH_STATUS.FAULT 和首次错误原因
  → 拒绝后续提交，保留已经发布的记录
  → 停止继续取包和调度
  → 通过已有 IRQ_ERROR 通知 Host
```

`IRQ_ERROR` 直接走已有错误中断，不依赖故障中的 IH Ring。失败记录不推进 W，也不自动重试；一次失败写入即使已经改变了部分内存，Host 也不能把未发布的槽作为有效记录消费。CP 本次提交的结果继续由 `LAST_SUBMIT_RESULT` 返回。

读取状态或写 `IRQ_ACK` 都不清除 IH 故障。Host 恢复前须停止相关生产者、确认在途写入结束，并处理或按恢复协议明确作废旧通知，然后在 IH 已禁用且 `BUSY = 0` 时请求复位。停止取包和调度后，已经开始的计算或 DMA 仍须按各自停止协议收尾，资源释放条件不能由 IH 故障状态代替。

**[DESIGN]** 冷复位和 `GLOBAL_CTRL.RESET` 清零 IH 基址、容量、W/R、控制与状态。合法的独立 `IH_CTRL.RESET` 仅清零 W/R 与整个 `IH_STATUS`，保留基址和容量，IH 继续禁用；该写入不能同时设置 `ENABLE`。CP 单独复位保留所有 IH 状态。独立 IH 复位不清除全局错误位，也不清空 Host Ring 内容；旧记录由重置后的发布范围判定，不能把残留字节视为新通知。运行期间的恢复流程仍属于后续扩展。

<a id="spec-ih-object-lifetime"></a>

#### 7.1.7 旧记录与对象寿命

驱动收到记录时，HQD 槽位可能已经卸载或用于另一条队列。驱动按记录中的完整 MQD 地址查找原 Queue 对象，并保留旧通知处理所需的对象关系。

```text
队列停止并卸载
  → 确认设备不会再产生该队列的旧记录
  → 处理完已发布记录及驱动已经取走的后续工作
  → 结束旧 Queue、事件和通知槽的相关引用
  → 才允许复用对应 MQD 地址和事件编号
```

仅收到卸载成功结果或中断确认，还不能证明旧通知已经处理完。若驱动先复制记录、归还 IH 槽，再延后处理，复制记录对应的 Queue 和事件引用必须保留到处理结束。应用释放接口见[9.7.4 的已确认接口](#spec-host-object-release)；故障复位后的旧通知处理随后续异常恢复细化，当前继续保留尚不能安全回收的资源。

**[BOUNDARY]** 本节的 IH 容量与布局、寄存器字段、同步提交、进度和发布规则、中断与 Signal 关联、故障处理方向及对象复用前提均已确认，本次工作区已接入设备与固件路径。寄存器偏移、故障枚举和复位字段已按上述规则补齐；Linux 客体的完整验收结果以大纲为准。队列错误编号、停止范围及清理后重建的规则见[第 7.2 节](#spec-queue-error-policy)，失败收尾按[第 7.3 节](#spec-failure-retirement)处理，强制恢复步骤列入[后续异常恢复扩展](<./QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)。

<a id="spec-queue-error-policy"></a>

### 7.2 队列错误编号、停止范围与重建

CP 读取一条按申请创建的用户队列时，发现 Ring 无法访问，需要保存最初的失败原因，停止这条队列，并让 Host 结束相关等待。以下假设这是该队列的首次故障：

```text
CP 读取某条用户队列的 Ring 失败
  │
  ├─ 将该队列的 CP_HQD_ERROR 记为 1
  ├─ 停止该队列后续取包，ACTIVE = 0
  ├─ 保留槽位占用及 MQD 绑定
  │
  └─ 提交 QUEUE_ERROR 中断记录
       ├─ mqd_addr = 该队列的 MQD 地址
       └─ data     = 1
                │
                ▼
Host 驱动
  → 找到对应 Queue，保存队列故障
  → 唤醒相关等待者
  → 通过卸载或设备恢复，确认相关访问结束
  → 处理完旧通知后，再回收资源
```

**[DESIGN]** 本节于 2026-10-18 确认。`CP_HQD_ERROR` 使用 32 位错误编号，由 CP 保留首次错误；队列第一次进入故障状态时提交一次 `QUEUE_ERROR`。错误队列停止取包并清除 `ACTIVE`，但槽位和 MQD 绑定继续保留。以下编号和行为属于本实验协议。

<a id="spec-queue-error-codes"></a>

#### 7.2.1 错误编号与首次记录

`CP_HQD_ERROR` 采用以下编号：

```text
 0：未记录错误
 1：Ring 或共享写进度读取失败
 2：已发布包的类型不支持，或通用格式、字段非法
 3：Kernel 描述对象或参数范围非法、无法读取
 4：计算执行器报告失败
 5：Signal 引用非法，或读取、更新失败
 6：通知槽引用非法，或写入失败
 7：包槽释放或消费进度回报失败
 8：管理命令与 WRITE_COMPLETION 配对错误
 9：管理结果码或完成标记写回失败
10：目标 MQD 状态保存失败
```

CP 在队列第一次出错时写入对应编号；已有非零错误后，后续异常不覆盖它。Host 对该寄存器只读，读取寄存器、处理 IH 记录和确认中断都不清错。固件不因反复检查同一个错误而重复提交 `QUEUE_ERROR`；IH 提交本身失败时按[第 7.1.6 节](#spec-ih-fault-reset)处理。

上述编号表示队列停止的原因。执行器返回失败时，CP 记录编号 `4`；执行器的 `DISPATCH_ERROR` 仍单独保存本次执行的具体原因，其枚举值见第 6.3.3 节。已识别管理命令的普通参数错误继续按[第 7.2.3 节](#spec-management-error-separation)返回本次请求结果，不据此把来源管理队列记为编号 `2`。

<a id="spec-queue-error-stop-scope"></a>

#### 7.2.2 出错队列与停止范围

CP 根据故障对象决定哪些队列停止新取包与新派发：

```text
用户队列故障
  → 停止这条用户队列
  → KIQ、HIQ 和其他正常用户队列继续处理

HIQ 故障
  → 停止 HIQ
  → KIQ 和已驻留的正常用户队列继续处理
  → 暂时不能通过 HIQ 创建或卸载用户队列

KIQ 故障
  → 停止所有队列的新取包与新派发
  → 保留相关资源，设备恢复留作后续扩展

固件代码、栈等无法可靠归属队列的异常
  → 记录设备级故障，停止所有队列调度

IH 自身故障
  → 停止继续取包和调度
  → 经已有 IRQ_ERROR 通知 Host
```

KIQ 的实际通道故障统一按停止全部调度处理，包括取包、已发布命令配对和结果写回故障；普通管理请求失败仍按下一节处理。能够可靠归属队列的故障由 CP 清除该队列的 `ACTIVE`，并在[固件槽位占用记录](#spec-management-slot-state)中保留异常占用状态。

停止新取包与新派发后，已经开始的计算或访存仍须完成收尾。Host 继续保留相应内存和对象引用，直到卸载或恢复流程确认访问结束；`ACTIVE = 0` 不能作为释放资源或归还槽位的依据。故障 HIQ 重建、任务卡住后的强制停止及设备复位步骤列入[后续异常恢复扩展](<./QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)，不作为第二阶段必做内容。

<a id="spec-management-error-separation"></a>

#### 7.2.3 管理请求结果与目标队列故障

名额已满、重复映射、卸载目标不存在，以及已识别管理命令的参数非法，都通过既有的独立结果区返回。来源 KIQ 或 HIQ 可以继续处理后续请求：

```text
本次管理请求失败
  → 暂存本次 status
  → 执行后附 WRITE_COMPLETION
  → Host 取得失败原因
  → 管理队列继续处理后续请求
```

这些失败不把来源管理队列标为故障，结果码继续使用[第 4.4 节](#spec-management-result)的编码。管理 Ring 无法读取、已发布命令配对错误、结果码或完成标记写回失败，则记录来源管理队列错误，并按前节确定停止范围。

目标 MQD 状态保存失败时，如果管理通道仍能安全回报，则返回既定的 `status = 5`，目标槽位继续占用。目标队列尚无错误时，CP 记录 `CP_HQD_ERROR = 10`；已有首次错误时保留原值。这样，Host 能从本次请求结果得知保存失败，同时保留目标队列最初的故障原因。MQD 读取失败也沿用既有请求结果和安全收尾条件，不套用仅表示状态保存失败的编号 `10`。

<a id="spec-queue-error-rebuild"></a>

#### 7.2.4 错误保存与清理后重建

错误队列须先确认访问结束并清理旧状态，再重新创建。第二阶段处理能够安全卸载的故障队列，需要强制停止或故障复位的情况留作后续扩展；清理顺序如下：

```text
错误队列
  → 停止取包
  → 卸载或设备恢复，确认相关访问结束（设备恢复留作后续扩展）
  → 保存诊断信息，处理完旧通知及驱动后续工作
  → 回收旧对象
  → 重新创建队列
```

卸载时，CP 将错误快照保存到 `MQD.saved_error`；保存失败仍按前节保留槽位。`saved_error != 0` 的 MQD 不允许直接重新激活，映射请求返回既定的参数非法结果 `status = 4`。仍处于绑定状态的 MQD 继续先按[重复映射规则](#spec-management-slot-state)拒绝，不能借重新映射清除原状态。

槽位完成清理、用于建立新队列时，由 CP 初始化其错误状态。设备冷复位或整体复位清零 HQD；CP 单独复位保留 HQD，不能借此清错恢复。MQD 地址、事件编号及相关内存的复用继续遵守[旧通知与对象寿命规则](#spec-ih-object-lifetime)。

出错后停止正常收尾，保留已经发生的写入，不自动重放任务或补写成功 Signal。失败包、部分完成状态和等待退出按[第 7.3 节](#spec-failure-retirement)处理。

**[BOUNDARY]** 本节的错误编号、首次记录、停止范围、故障时清除 `ACTIVE`、管理请求与目标故障的区分、错误队列清理后重建均已确认。正常卸载前排空及 `ACTIVE` 清零时机已按[第 7.4 节](#spec-unmap-drain)确定，任务卡住后的停止方法和复位重建步骤列入[后续异常恢复扩展](<./QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)。

<a id="spec-failure-retirement"></a>

### 7.3 失败包停止收尾与已有状态保留

**[DESIGN]** CP 处理当前包时发现异常，第一版按下面的路径结束正常处理：

```text
CP 处理当前包时发现异常
  → 记录错误，按 9.6.1 的范围停止处理
  → 通知 Host，结束尚未完成的等待
  → 保留已有状态
  → 确认相关访问及旧通知处理结束后，清理并重建
```

1. **出错后停止正常收尾。** 不跳过失败包继续执行，不为丢弃失败包而主动清除 AQL Header 或推进消费进度，也不补写成功 Signal。错误记录与停止范围沿用[第 7.2 节](#spec-queue-error-policy)。
2. **已经发生的操作保留。** 已写入的数据、已经更新的 Signal 和消费进度不回退；不自动重新执行 Kernel、重发管理命令或重试完成写入。管理请求的普通失败仍按[既定协议](#spec-management-result)返回结果。
3. **Host 能退出等待，资源暂时保留。** 驱动保存队列或设备故障并唤醒相关等待者，通过错误结束尚未完成的等待。错误、超时和停止取包都不能直接作为释放依据；确认设备访问及旧通知处理结束后，才能按对象寿命规则回收相关资源。
4. **精细恢复留作扩展。** 各个写入步骤失败后的状态组合、逐步故障注入、自动重试和原地恢复列入[后续扩展](<./QEMU GPGPU 实验大纲.md#failure-recovery-extension>)。第一版继续遵守已确定的[完整读写](#spec-shared-value-integrity)和[发布顺序](#spec-dispatch-visibility)。

**[BOUNDARY]** 本节已按[9.6.2](#spec-failure-retirement-rules)确认。正常卸载见[第 7.4 节](#spec-unmap-drain)，任务卡住后的强制停止和复位重建列入[后续异常恢复扩展](<./QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)，具体等待接口已按 9.7 确认。

<a id="spec-unmap-drain"></a>

### 7.4 Host 排空队列与 CP 卸载

**[DESIGN]** 第一版正常卸载采用 Host 先排空队列、CP 再卸载的顺序。以一条用户队列为例，运行时先停止新的提交，并让已经开始的提交完成发布，随后等待已有任务完成：

```text
Host 停止该队列的新提交
  → 等已经开始的提交完成发布
  → 等已有任务完成，消费回报 R 追上 W
  → 向 HIQ 发布 UNMAP_QUEUES → WRITE_COMPLETION

CP 开始处理 UNMAP_QUEUES
  → 槽位标为“卸载中”
  → 清除 ACTIVE，关闭该队列的 Doorbell 使能
  → 确认相关在途访问结束
  → 将 saved_rptr、saved_error 保存到原 MQD
  → 解除绑定，将 HQD 槽位标为空闲
  → 管理操作达到完成条件，CP 暂存成功结果
  → 执行后附 WRITE_COMPLETION，先写结果码，再写完成标记

Host 确认卸载成功
  → 处理完旧通知，满足对象寿命条件后回收相关资源
```

正常路径以消费回报 `R == W` 确认包已经全部消费。例如队列还有三个未执行包，Host 先让它们完成，再提交卸载。停止提交包含等待已开始的提交完成发布；不能在其他线程仍可能预留或发布包时，以一次 `R == W` 判断队列已经排空。进度的完整访问与同步继续沿用[第 5.2.1 节](#spec-ring-progress)的规则。

CP 开始执行卸载时清除 `ACTIVE`，同时关闭该队列的 Doorbell 使能；此时槽位仍保持占用。确认相关访问结束、成功保存 MQD 后，才解除绑定并归还槽位。保存失败继续保留占用，按已有错误规则处理。Host 读到本次预期完成序号，同步并确认 `status = 0` 后，再按[旧通知与对象寿命规则](#spec-ih-object-lifetime)释放相关内存。

故障队列的清理不要求先排空，尚未完成的等待按[第 7.3 节](#spec-failure-retirement)报错退出，相关资源继续保留。任务一直不结束时的强制停止方法列入[后续异常恢复扩展](<./QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)，第二阶段不要求实现。取消未执行任务、保留未执行任务跨卸载续跑列为[后续扩展](<./QEMU GPGPU 实验大纲.md#queue-unmap-extension>)；正常重装仍保留已有消费位置，不把进度清零。

正常卸载 HIQ 前，驱动先完成用户队列清理，并等待 HIQ 的管理请求回报：

```text
停止接受新的用户队列创建请求
  → 经 HIQ 卸载所有用户队列，确认用户槽位全部空闲
  → 确认 HIQ 中的管理请求及后附完成命令全部处理结束
  → 经 KIQ 提交卸载 HIQ 的命令和完成标记命令
  → 确认 HIQ 卸载成功
```

第一版由 Host 保证上述关闭顺序，CP 不在卸载 HIQ 时自动连带卸载用户队列。HIQ 的卸载仍按本节停止取包、结束访问、保存状态、解除绑定和回报结果；返回管理结果的是 KIQ。

**[BOUNDARY]** 本节已按[9.6.3](#spec-unmap-rules)确认。任务卡住后的强制停止、故障 HIQ 重建及设备复位步骤列入[后续异常恢复扩展](<./QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)。

<a id="spec-registers"></a>

## 8. 本版采用的 HQD 寄存器

下表列出已确认采用的 15 个寄存器位置，包括保存首次错误编号的错误记录寄存器。槽内偏移沿用此前清单，不因删去未采用项而重新编号；它们用于第 2 节的 Host 窗口及 CP 槽位直接地址计算。已确认的字段编码见[第 8.1 节](#spec-hqd-field-encoding)，复位值和访问规则见[第 8.2 节](#spec-hqd-access-rules)；消费进度按[第 5.2.1 节](#spec-ring-progress)编码，错误编号按[第 7.2.1 节](#spec-queue-error-codes)编码。AMD 的其他位字段不属于本版接口。

| 槽内偏移  | 寄存器名称                        | 本版用途                                                                       | 决定 | 详细说明                                                            |
| --------- | --------------------------------- | ------------------------------------------------------------------------------ | ---- | ------------------------------------------------------------------- |
| `0x000` | `CP_MQD_BASE_ADDR`              | 保存当前队列 MQD 物理地址低位，MQD 由驱动管理。                                | 采用 | [MQD 基址](<./CP_MEC 软件实现、参考与扩展.md#mqd>)                   |
| `0x004` | `CP_MQD_BASE_ADDR_HI`           | 与前一项共同保存 MQD 地址高位。                                                | 采用 | [MQD 基址](<./CP_MEC 软件实现、参考与扩展.md#mqd>)                   |
| `0x008` | `CP_HQD_ACTIVE`                 | bit 0 标记队列是否激活，其余位填 0；CP 据此判断是否检查队列。                  | 采用 | [队列激活](<./CP_MEC 软件实现、参考与扩展.md#active>)                |
| `0x00c` | `CP_HQD_VMID`                   | 管理队列填 0，用户队列填 1 或 2；开启 GPUVM 时选择页表。                           | 采用 | [队列地址空间](<./CP_MEC 软件实现、参考与扩展.md#vmid>)              |
| `0x020` | `CP_HQD_PQ_BASE`                | 保存 Ring 基址编码低位，用于定位命令 Ring。                                    | 采用 | [Ring 定位](<./CP_MEC 软件实现、参考与扩展.md#ring-base>)            |
| `0x024` | `CP_HQD_PQ_BASE_HI`             | 与前一项共同保存 Ring 基址编码高位。                                           | 采用 | [Ring 定位](<./CP_MEC 软件实现、参考与扩展.md#ring-base>)            |
| `0x028` | `CP_HQD_PQ_RPTR`                | 保存完整的 32 位下一待消费包编号，由 CP 按模 `2^32` 推进。                   | 采用 | [Ring 进度](<./CP_MEC 软件实现、参考与扩展.md#ring-progress>)        |
| `0x02c` | `CP_HQD_PQ_RPTR_REPORT_ADDR`    | 指定设备回报消费进度的内存地址低位。                                           | 采用 | [进度地址与数值](<./CP_MEC 软件实现、参考与扩展.md#ring-progress>)   |
| `0x030` | `CP_HQD_PQ_RPTR_REPORT_ADDR_HI` | 与前一项共同确定消费进度回报地址。                                             | 采用 | [进度地址与数值](<./CP_MEC 软件实现、参考与扩展.md#ring-progress>)   |
| `0x034` | `CP_HQD_PQ_WPTR_POLL_ADDR`      | 指定 CP 读取软件生产进度的内存地址低位。                                       | 采用 | [进度地址与数值](<./CP_MEC 软件实现、参考与扩展.md#ring-progress>)   |
| `0x038` | `CP_HQD_PQ_WPTR_POLL_ADDR_HI`   | 与前一项共同确定生产进度读取地址。                                             | 采用 | [进度地址与数值](<./CP_MEC 软件实现、参考与扩展.md#ring-progress>)   |
| `0x03c` | `CP_HQD_PQ_DOORBELL_CONTROL`    | bits 27:2 保存以 4 字节为单位的 BAR4 相对偏移，bit 30 为独立使能；其余位填 0。 | 采用 | [Doorbell 与 Ring 控制](<./CP_MEC 软件实现、参考与扩展.md#doorbell>) |
| `0x044` | `CP_HQD_PQ_CONTROL`             | 整个 32 位值保存 Ring 字节容量，允许 64 字节～64 KiB 的 2 的幂。               | 采用 | [Doorbell 与 Ring 控制](<./CP_MEC 软件实现、参考与扩展.md#doorbell>) |
| `0x0cc` | `CP_HQD_ERROR`                  | 保存所属队列的首次错误编号，编码与处理规则见第 7.2 节。                        | 采用 | [错误记录](<./CP_MEC 软件实现、参考与扩展.md#error>)                 |
| `0x0d4` | `CP_HQD_AQL_CONTROL`            | 整个寄存器值`0` 为非 AQL、`1` 为 AQL。                                     | 采用 | [队列格式](<./CP_MEC 软件实现、参考与扩展.md#queue-format>)          |

完整的 59 个 AMD 参考位置、同址别名及逐项采用／不采用结论统一保存在[AMD 寄存器对照](<./CP_MEC 软件实现、参考与扩展.md#amd-registers>)。参考表中的保留位置、未采用项不会因保留名称和偏移而成为已实现接口。

<a id="spec-hqd-field-encoding"></a>

### 8.1 Ring 容量、Doorbell 与地址字段的编码

驱动已为 Queue A 分配 Ring，接下来填写 MQD_A，供 CP 装入 HQD。以下示例使用 4096 字节的 Ring，并假设驱动为 Queue A 分配的 Doorbell 位于 BAR4 内偏移 `0x20`；这是演示地址，实际入口按[第 5.2.3 节](#spec-doorbell-notification)由驱动分配。

```text
Host 驱动填写 MQD_A
  ├─ pq_control       = 4096
  └─ doorbell_control = 0x4000_0020
         │
         │ CP 执行 MAP_QUEUES，读取并装入配置
         ▼
Queue A 的 HQD
  ├─ CP_HQD_PQ_CONTROL = 4096
  ├─ CP_HQD_PQ_DOORBELL_CONTROL
  │    ├─ OFFSET = 8  → BAR4 内字节偏移 = 8 × 4 = 0x20
  │    └─ ENABLE = 1  → 启用该队列的 Doorbell 入口
  └─ CP_HQD_ACTIVE = 1（完成配置后最后设置）
         ▲
         │ 对应这个队列的通知入口
Host 写入 BAR4 + 0x20
```

**[DESIGN]** `CP_HQD_PQ_CONTROL` 的整个 32 位无符号数值保存 Ring 的字节容量，KIQ、HIQ 和用户 AQL Ring 使用同一规则。容量必须是 2 的幂，范围为 64 字节～64 KiB，`0` 为非法容量。例如写入 `4096` 表示 4096 字节，可容纳 64 个 64 字节 AQL 包。本版不采用 AMD 的容量对数编码；管理命令固定为[第 4.1 节的 32 字节格式](#spec-management-packet-format)，包槽边界与末尾回绕按[第 5.1 节](#spec-ring-packet-boundaries)处理。

**[DESIGN]** `CP_HQD_PQ_DOORBELL_CONTROL` 只采用偏移和独立使能两个字段，MQD 中的 `doorbell_control` 使用相同编码：

```text
CP_HQD_PQ_DOORBELL_CONTROL：32 位

bit 31       保留，填 0
bit 30       DOORBELL_EN
bits 29:28   保留，填 0
bits 27:2    DOORBELL_OFFSET
bits 1:0     保留，填 0
```

`DOORBELL_OFFSET` 保存相对于整个 BAR4 起点的偏移，单位为 4 字节。这个字段用于定位通知入口，不保存队列编号或 BAR4 的完整物理地址。上例的换算如下：

```text
Doorbell 位于 BAR4 + 0x20

OFFSET 字段值 = 0x20 / 4 = 8
ENABLE       = 1

寄存器值 = (1 << 30) | (8 << 2)
         = 0x4000_0020
```

`0x4000_0020` 是 HQD 的配置值。应用发布包 `P` 后，向该入口完整写入 64 位值，低 32 位为 `P`、高 32 位为零。入口按 8 字节对齐，因此 `OFFSET` 必须为偶数，解码后的完整 8 字节访问范围必须落在 BAR4 内。图中的 `0x20` 和字段值 `8` 满足这些条件；通知与队列复查规则见[第 5.2.3 节](#spec-doorbell-notification)。

使能位按以下规则使用：

- `ENABLE = 0`：关闭该队列的 Doorbell 入口，不改变 `ACTIVE` 或消费位置。
- `ENABLE = 1`：启用该队列的 Doorbell 入口，不自动激活队列。
- `ENABLE = 1、ACTIVE = 0`：通知入口已开启，CP 暂不消费该队列。
- 正常装载时先配置 Doorbell，再读取生产进度，最后设置 `ACTIVE = 1`。首次 KIQ 仍由 Host 在 CP 保持复位时配置；后续队列由 CP 按管理命令装载。

字段位置参考 AMD 的对应定义。独立使能与队列激活的关系、AMD 直接装载 HQD 的顺序及源码依据见[Doorbell 控制说明](<./CP_MEC 软件实现、参考与扩展.md#doorbell>)；本版的通知处理按上述设计与 9.4.5 的协议实现。

**[DESIGN]** `CP_HQD_ACTIVE` 只使用 bit 0，其余位填 0：

```text
CP_HQD_ACTIVE
  ├─ bit 0 = 0：队列未激活，CP 不继续从该队列取包
  ├─ bit 0 = 1：队列已激活，CP 可以检查并处理命令
  └─ bits 31:1：保留，填 0
```

故障队列按[第 7.2.2 节](#spec-queue-error-stop-scope)清除 `ACTIVE` 并保留占用；`ACTIVE = 0` 不单独代表在途访问已经结束。正常卸载按[第 7.4 节](#spec-unmap-drain)由 Host 先排空，CP 开始卸载时清除 `ACTIVE` 并关闭 Doorbell 使能。`CP_HQD_VMID` 在管理队列填 `0`，用户队列填 `1` 或 `2`；`CP_HQD_AQL_CONTROL` 的整个寄存器填 `0` 表示非 AQL 管理队列，填 `1` 表示用户 AQL 队列，其余值暂不支持。

四组地址均保留 64 位寄存器槽，高 32 位为零。MQD 始终是 GPU 物理地址；Ring 和 R/W 地址按管理域或用户域解释：

```text
低位寄存器：地址的低 32 位
高位寄存器：地址的高 32 位

例如地址 = 0x4500_0000
  ├─ LO = 0x4500_0000
  └─ HI = 0x0
```

这四组地址不预先右移压缩，对齐与访问范围按[第 2.4.2 节](#spec-address-validation)校验。Doorbell OFFSET 的 4 字节单位只用于 Doorbell 字段，不改变 GPU 地址的字节编码规则。

**[DESIGN]** `CP_HQD_PQ_RPTR` 的整个 32 位值保存下一待消费包编号，按模 `2^32` 推进；回报内存保存相同的 32 位值，MQD 的 64 位 `saved_rptr` 零扩展保存该值。取槽、满空判断与恢复规则见[第 5.2.1 节](#spec-ring-progress)。

**[BOUNDARY]** `CP_HQD_ERROR` 使用 32 位错误编号，首次记录、停止范围和清理后重建规则已按[第 7.2 节](#spec-queue-error-policy)确定。复位值、读写权限和非法访问处理见[第 8.2 节](#spec-hqd-access-rules)。OFFSET、ENABLE 使用现有 `doorbell_control` 的空间，MQD 仍为 64 字节，HQD 仍采用上述 15 个寄存器位置；这些编码为已确认设计。

<a id="spec-hqd-access-rules"></a>

### 8.2 HQD 的复位值、读写权限与非法访问

Host 首次启动 CP 时需要配置 KIQ；CP 开始运行后，再通过管理命令配置其他队列。下面按这两个阶段说明谁能写 HQD，Host 何时读取配置与状态：

```text
首次启动，CP 保持复位
  → Host 配置 KIQ 的 HQD
  → 最后设置 KIQ.ACTIVE = 1
  → 解除 CP 复位

CP 运行后
  ├─ Host 提交管理命令 → CP 配置或卸载目标队列
  ├─ CP 执行任务      → CP 更新消费进度和错误状态
  └─ Host 读取 HQD    → 查看配置与运行状态
```

**[DESIGN]** 本版采用以下复位与访问规则，适用于 HQD 寄存器入口。`HQD_SELECT` 的有效槽位选择及 CP 地址译码范围见[第 8.3 节](#spec-hqd-address-map)。

1. **复位值。** 设备冷复位或整体复位时，所有 HQD 寄存器清零，`HQD_SELECT = 0`。队列处于未激活状态，Doorbell 未启用；容量为 0 表示尚未配置，必须填入合法容量后才能激活。CP 单独复位保留 HQD 内容，故障后的队列恢复列入[后续异常恢复扩展](<./QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)，不能据此判断相关访问已经结束。
2. **访问宽度。** Host 窗口和 CP 直接入口都采用小端、4 字节对齐的 32 位读写，`HQD_SELECT` 也按对齐的 32 位访问。64 位地址通过低、高两个寄存器分别读写，不支持一次 64 位访问跨过两个寄存器；非法宽度或未对齐请求不能分拆成多个有效访问后部分生效。
3. **Host 与 CP 的写权限。** 首次启动时，Host 在 CP 保持复位期间配置 KIQ，并初始化消费位置。CP 运行后，Host 对 HQD 只读，按[第 4 节的分工](#spec-management)经 KIQ 请求配置 HIQ、经 HIQ 请求配置用户队列，由 CP 执行；Host 仍可写 `HQD_SELECT` 选择查看对象。`CP_HQD_ERROR` 对 Host 始终只读，读取不清除错误，由 CP 按[第 7.2 节](#spec-queue-error-policy)保留首次错误；槽位完成清理并用于建立新队列时，由 CP 初始化错误状态。
4. **运行期间的字段更新。** Ring 地址、MQD 地址、进度地址、容量、VMID、队列格式和 Doorbell OFFSET，须在队列未激活且相关在途访问已结束后修改。运行期间允许 CP 更新消费进度、错误状态、`ACTIVE`，以及单独切换 `DOORBELL_EN`；切换使能时，Doorbell OFFSET 保持原值。`ACTIVE` 的清零时机按[正常卸载](#spec-unmap-drain)及[故障停止规则](#spec-queue-error-stop-scope)执行。
5. **非法访问。** 非法字段值、保留位置 1、越权写入，以及不支持的访问宽度或对齐都拒绝处理。非法写入保留原值，非法读取返回 0，并记录到全局 `ERROR_STATUS.INVALID_CMD`。未采用的寄存器位置按规定宽度读取时返回 0，写入按非法访问处理。这类访问不自动清空队列，也不覆盖队列自身的 `CP_HQD_ERROR`。
6. **完整配置与读取一致性。** 写入地址的低、高两部分期间保持 `ACTIVE = 0`；完整配置满足容量、地址对齐和范围要求后，才允许设置 `ACTIVE = 1`。单次 32 位读取返回完整值，跨多个寄存器读取不保证得到同一时刻的快照。Host 读取正在装载的配置，应等待对应管理操作完成；持续变化的进度值另按 9.4 的发布规则读取。

非法访问的错误记录与队列执行错误分别维护。例如，Host 在 CP 运行时试图改写 Queue A 的 Ring 地址，这次写入被拒绝，原地址保留，全局非法命令标志置位；Queue A 的消费位置和已有错误快照保持原状。Host 需要修改队列时，仍应通过管理命令完成相应操作。

**[BOUNDARY]** 上述读零、保留原值和错误记录是本实验寄存器入口的处理约定，未映射物理地址按[第 8.3 节](#spec-hqd-address-map)交给 CP 访存异常处理。地址与范围校验不保证后续 Host RAM 访存必然成功，实际访问失败仍按[访存错误规则](#spec-cp-memory-interface)处理。寄存器复位不释放 Ring、MQD、Signal 或任务资源，资源释放仍须确认相关访问结束。设备与固件按以上规则处理 HQD。

<a id="spec-hqd-address-map"></a>

### 8.3 Host 选槽窗口与 CP 本地地址

Host 与 CP 都需要读取用户队列的 Ring 地址。设备内部有 4 份独立 HQD 状态，槽位 2、3 供动态创建的用户队列使用；Host 通过一个选槽窗口访问，CP 通过每个槽位的固定地址访问。两套入口访问同一份状态，Host 窗口不另外保存一份 HQD 副本，完整关系图见[HQD 访问说明](<./CP_MEC 软件实现、参考与扩展.md#hqd-window>)。

以下假设 CP 已把两条用户队列 A、B 分配到槽位 2、3。以 Queue A 为例，假设其 Ring 地址低位寄存器保存 `0x9000_0000`。`CP_HQD_PQ_BASE` 在每组 HQD 内的偏移均为 `0x020`：

```text
设备内部实际保存的状态：

HQD[2]：Queue A
  └─ CP_HQD_PQ_BASE = 0x9000_0000
                  ▲
                  │ 两条路径都读取这个字段
                  │
Host 路径：
  写 HQD_SELECT = 2
  读 BAR0 + 0x0700 + 0x020
  即 BAR0 + 0x0720
  → 返回 0x9000_0000

CP 路径：
  读 0xffff_0200 + 0x020
  即 0xffff_0220
  → 返回 0x9000_0000
```

**[DESIGN]** Host 使用 `BAR0 + 0x0600` 的 `HQD_SELECT` 选择槽位，通过 `BAR0 + 0x0700～0x07ff` 的单个窗口访问所选 HQD。CP 的固定基址为 `CP_HQD_BASE = 0xffff_0000`，槽位间隔为 `0x100`，访问地址按“基址 + 槽位编号 × 间隔 + 字段偏移”计算：

```text
CP 本地物理地址：
  0xffff_0000～0xffff_00ff → 槽位 0：KIQ
  0xffff_0100～0xffff_01ff → 槽位 1：HIQ
  0xffff_0200～0xffff_02ff → 槽位 2：供用户队列申请
  0xffff_0300～0xffff_03ff → 槽位 3：供用户队列申请
```

四个槽位共映射 `0x400` 字节，即 1 KiB。每个槽位预留 256 字节的寄存器地址范围，其中采用的 15 个 32 位寄存器占 60 字节，其余位置未采用。这里划定的是 CP 的寄存器地址范围，不从前 60 MiB VRAM 分配池中分配 1 KiB；Ring 和 MQD 仍使用 Host RAM，Ring 容量由 `CP_HQD_PQ_CONTROL` 指定。

`HQD_SELECT` 只改变 Host 窗口的访问对象，不复制 HQD 内容，也不改变 CP 正在处理的队列。接着将它改为 3 时：

```text
Host 仍读取 BAR0 + 0x0720
  → 现在读取 Queue B 的 CP_HQD_PQ_BASE

CP 仍读取 0xffff_0220
  → 仍然读取 Queue A 的 CP_HQD_PQ_BASE
```

**[DESIGN]** `HQD_SELECT` 只接受完整的 32 位数值 `0～3`，不能只取低两位。无效选槽拒绝本次写入、保留原值，并置位全局 `ERROR_STATUS.INVALID_CMD`：

```text
HQD_SELECT 原值 = 2
  → Host 写入 7
  → 拒绝这次写入，HQD_SELECT 仍为 2
  → 置位 ERROR_STATUS.INVALID_CMD
```

Host 驱动用锁保护“选槽—访问窗口”，写入选择值后先回读确认，再访问窗口；选槽失败就结束本次操作。首次 KIQ 配置和运行后只读 HQD 的权限继续按[第 8.2 节](#spec-hqd-access-rules)执行，运行后仍允许 Host 修改 `HQD_SELECT`。

**[DESIGN]** CP 侧的 HQD 映射只覆盖上述 `0x400` 字节。有效槽位内的未采用寄存器位置，按第 8.2 节使用规定宽度读零，写入拒绝并记录全局错误。`0xffff_0400` 这样的越界地址不属于 HQD 映射，按未映射访存异常处理，不截断槽号、不取模，也不折返到槽位 0。落在其他已映射区域的地址仍由该区域处理，不能把所有 HQD 范围外的访问都当作寄存器访问。

**[BOUNDARY]** 本节确定本实验的物理地址映射与选槽行为，不引入虚拟地址或页表翻译，也不规定 AMD 的实际寄存器映射。未映射地址交给 CP 访存异常处理，队列归属、停机与恢复按 9.1.6 和 9.6 的协议落实。HQD 设备入口与固件访问已按上述地址和规则接入。

<a id="spec-open-interfaces"></a>

## 9. 软件接口约定与确认记录

**[BOUNDARY] 历史确认记录。** 本节保留 2026-10-17～2026-10-19 的原始方案与“尚待实现”表述。这里的 VMID 0、Host 物理地址、旧参数窗口、同步回归及调用方提交职责只说明当时版本；当前版本 2 以第 1～8 节及[GPUVM 规格](<./GPUVM 第一版规格.md>)为准，不按本节旧约定恢复兼容实现。

本节沿着“创建用户队列，提交一次计算，再销毁队列”的过程，记录驱动、用户态调用方、CP 固件和 QEMU 共同使用的接口约定。9.1～9.7 的第一版行为与实现边界均已确认；9.4.4 的首部访问、管理 Ring 并发和取号约束已补齐，功能仍须接入和验证。

```text
准备队列和任务所需的内存                  → 9.1 存储位置、地址与 CP 访存
  → 将队列配置写入 MQD                   → 9.2 MQD 布局与 HQD 读写规则
  → 经 HIQ 请求配置，并确认结果          → 9.3 管理命令与完成标记
  → 向 Ring 发布任务、写 Doorbell        → 9.4 包发布与读写进度
  → CP 提交计算，发布完成 Signal         → 9.5 执行器与 Signal
  → 处理失败、卸载并结束设备访问         → 9.6 错误与卸载
  → 应用和驱动回收对象及映射             → 9.7 Host 软件接口与资源管理
```

**[DESIGN]** 下列编号保留各项决定及正文入口。设计已确认不表示实现完成；IH 寄存器地址、细分错误枚举、复位字段初值，以及 Host 接口的正式符号、ioctl 编号、结构体和锁等，在接入时统一定义并验证。强制停止、故障复位恢复等继续按后续扩展处理。以后调整方案时，按一个完整小节集中讨论，并同步更新正文、参考说明与实验大纲。

### 9.1 队列和任务放在哪里，CP 怎样访问

Host 要先为 Queue A 准备内存，CP 才能读取配置和任务。第 2 节已经确定当前主线不引入设备虚拟地址，Host DMA 按直通配置使用物理地址，VRAM 使用区内字节偏移。管理队列与用户队列的 VMID 均固定为 0，用户资源的进程归属由 Host 软件管理，当前不据此选择页表。下面分别记录存储位置、地址含义和实际访问方法。

**9.1.1 Ring 与 MQD 的存储位置**

**已确定：** 用户 Ring、KIQ/HIQ Ring 和所有 MQD 均使用驱动分配的 Host RAM 一致性内存；用户 Ring 映射给所属应用，管理 Ring 和 MQD 由驱动管理，CP 通过 Host 访存窗口访问。分配、映射与对象关系已写入[第 2 节](#spec-ring-mqd-storage)。

本项确认存储位置、分配者和访问方法。地址的通用编码规则见[第 2.4 节](#spec-address-values)，地址位宽、对象对齐及基本访问校验见[第 2.4.2 节](#spec-address-validation)；队列功能仍待实现。

**9.1.2 进度与完成值的存储位置**

**已确定：** 四类值均放在驱动分配的 Host RAM 一致性内存中。生产、消费进度按队列独立分配；管理完成标记由驱动在独立管理区中按请求分配位置；Signal 使用各应用上下文独立的内存区，生命周期不绑定 Ring 槽或具体队列。用户队列进度区及 Signal 区映射给所属应用，管理队列进度区和管理标记区不映射给普通应用。对象关系和分配规则见[第 2.2 节](#spec-shared-state-storage)。

本项只确定存储、分配和映射方式。Signal 引用、字段位宽及对齐已写入[第 2.5 节](#spec-signal-representation)，单一更新者与完成值规则见[第 2.1.2 节](#spec-signal-single-writer)；其余字段布局和数值位宽、发布顺序、通知及复用协议已按 9.3～9.7 确认，接入与验证尚未完成。

<a id="spec-kernel-storage"></a>

**9.1.3 Kernel 代码、描述对象和参数的存储位置**

**已确定：** Kernel 描述对象、代码和输入输出数组放在 VRAM；参数块放在驱动分配、映射给所属应用的 Host RAM 一致性内存。CP 读取描述对象取得代码入口，执行器直接读取 Host RAM 参数块，再按其中的 VRAM 偏移访问数组，不先搬运整块参数。完整关系图及生命周期约束见[第 2.3 节](#spec-kernel-data-storage)。

当前阶段采用物理地址与 VRAM 字节偏移，不引入设备虚拟地址。描述对象的 16 字节布局、参数长度和计算线程的只读参数窗口已在[9.5.2](#spec-kernel-executor-interface)确认；CP 分发寄存器已按[9.5.3](#spec-cp-dispatch-interface)确定，执行器的 Host 参数访问和计算交接仍待实现。

<a id="spec-address-encoding"></a>

**9.1.4 地址字段中保存的数值**

**已确定：** 地址按字节保存原值；Host RAM 物理地址字段保留完整的 64 位，两个 32 位寄存器分别保存低、高 32 位；VRAM 对象使用区内字节偏移，由字段用途区分存储区域。Ring 地址拆分、恢复及 Dispatch 字段的关系图见[第 2.4 节](#spec-address-values)。

Signal 的表示也已确定：`completion_signal` 与 `event_mailbox_ptr` 分别保存 Signal 和通知槽的 64 位 Host RAM 物理地址；`value` 为 64 位有符号整数，`event_id` 为 32 位无符号整数，通知槽标记为 64 位。Signal 起始地址、其中的 64 位字段和通知槽地址至少按 8 字节对齐，完整关系图见[第 2.5 节](#spec-signal-representation)。Ring 命令、MQD、Signal、通知槽、Kernel 描述对象和参数块中的多字节字段统一采用[小端格式](#spec-shared-endian)。

`kernel_object` 保留 64 位且当前要求高 32 位为零；代码入口及参数块中的数组 VRAM 偏移使用 32 位无符号数。Ring 基址按 64 字节对齐，MQD、描述对象、参数块、进度与管理标记位置至少按 8 字节对齐，RV32 Kernel 入口按 4 字节对齐，数组和结构内标量字段按类型自然对齐。驱动、CP 和执行器按各自访问阶段检查对齐、计算溢出和完整范围，校验失败拒绝访问。完整约定见[第 2.4.2 节](#spec-address-validation)。

本项的地址编码、位宽、最低对齐和基本访问校验已确认，不增加页表翻译。进度值已按[第 5.2.1 节](#spec-ring-progress)确定为 32 位；其余对象布局、Signal 完成操作及错误处理按对应小节的已确认约定执行；第二阶段 VMID 固定为 0，按 VMID 的设备访问隔离留到第三阶段，队列功能仍待实现。

Signal 引用与事件编号分别如何使用，见[Signal、通知槽与 Host 等待队列的参考关系](<./CP_MEC 软件实现、参考与扩展.md#signal-event-wait>)。该例解释参考实现中的对象关联，实验地址与字段表示以第 2.5 节为准。

<a id="spec-vmid-scope"></a>

**9.1.5 VMID 的数量与第二阶段的实现范围**

**已确定：** 第二阶段只保留 `VMID = 0`。KIQ、HIQ、用户 AQL Queue 以及 MQD 中保留的 VMID 字段均填写 0，不支持非零编号，不建立按进程分配和回收 VMID 的管理流程。Host RAM 仍按物理地址访问，VRAM 仍按字节偏移访问；Host 软件继续记录队列和内存的所属上下文。正文约定见[第 2 节](#spec-objects-addresses)，四个 HQD 槽位的示例见[VMID 字段说明](<./CP_MEC 软件实现、参考与扩展.md#vmid>)。

多 VMID 的数量、分配与复用、字段传递、页表上下文选择和设备访问隔离列为[第三阶段扩展](<./CP_MEC 软件实现、参考与扩展.md#multi-vmid-extension>)，进入该阶段后再确定具体方案。第二阶段只要求固定值配置与基本访问检查；寄存器非法值按[第 8.2 节](#spec-hqd-access-rules)拒绝并报告，队列错误处理按第 7 节及 9.6 的已确认规则执行。

<a id="spec-cp-memory-interface"></a>

**9.1.6 CP 发起一次访存的接口**

**已确定：** CP 通过[Host 访存窗口](#cp-host-window)读写 Host RAM，VRAM 继续直接访问。窗口指令同步得到结果，失败进入原生访存异常；固件在访问前保存 HQD 槽位、访问阶段和完整目标地址，处理管理命令时保留来源及请求信息，选定目标槽位后再记录该槽位。VMID 统一为 0，不承担队列错误归属。

能够归属到用户队列的访问错误，记录到该槽位的 `CP_HQD_ERROR`，停止这条队列后续取包；KIQ 和其他正常队列可以继续处理。KIQ 实际通道故障，或 CP 固件代码、栈等访问异常时，停止队列调度并保留相关资源，设备恢复留作后续扩展。失败后不自动重放整个任务，也不盲目重试完成更新；停止取包后仍须确认访问结束才能释放资源。完整示例见[第 2.1.1 节](#spec-memory-access-context)。

Signal 保留 64 位有符号 `value`，采用[单一更新者规则](#spec-signal-single-writer)：Host 提交前置 `1`，提交后只读；CP 在任务成功完成后通过窗口读取、在本地减一并写回 `0`。本阶段一次使用中的 Signal 对应一个任务，不增加原子加或原子读改写入口。普通窗口已经实现，队列访存上下文、错误处理与 Signal 流程尚待接入。动态 64 位值的完整访问按[第 2.2.1 节](#spec-shared-value-integrity)实施并验证，通知与等待协议已按[9.5.4](#spec-signal-completion-protocol)确定，可见性操作见[第 6.4 节](#spec-dispatch-visibility)，错误编码和恢复规则按第 7 节及 9.6 执行；多 VMID 传递及隔离留到第三阶段扩展。

<a id="spec-firmware-reservation"></a>

**9.1.7 固件代码、栈和数据的保留范围**

**已确定：** 在 64 MiB VRAM 配置下，固定保留末尾 4 MiB，即 `0x03c0_0000～0x03ff_ffff`，属于设备，不进入应用显存分配池。固件入口固定为 `0x03c0_0000`；前 4032 KiB 保存代码、常量、全局变量和静态工作区，最后 64 KiB 用作向低地址增长的栈，初始 `sp = 0x0400_0000`。完整布局与分配规则见[第 3.1 节](#spec-firmware-layout)。

前 60 MiB，即 `0x0000_0000～0x03bf_ffff`，由 Linux 内核驱动按设备统一管理，底层参考 AMD 复用 `gpu_buddy`；目标内核仍使用 `drm_buddy` 时采用对应实现。驱动负责请求校验、并发保护、对象归属与释放时机，首个页作为管理范围内的保留项处理。接口与构建依赖按目标内核核对，普通显存对象申请连续区间。

固件按固定地址链接，链接和装载时检查范围；Host 保持 CP 复位完成装载和 KIQ 配置，解除复位后由固件设置栈、清零未初始化全局变量并初始化异常处理和内部状态。应用退出、队列销毁或 CP 暂时复位均不释放保留区，更新固件前须停止 CP 并确认相关访问结束。启动顺序见第 3.2 节，复位影响见第 3.3 节。上述布局及分配保护已确认，固件、驱动和相关验证仍待接入。

### 9.2 MQD 的内容与 HQD 的读写规则

驱动填写 MQD_A，CP 读取它并配置 Queue A 的 HQD；卸载时，CP 将需要保留的状态写回 MQD_A。第 8 节已经确定采用的寄存器位置，下面补齐内存布局和每次读写的含义。

<a id="spec-mqd-layout"></a>

**9.2.1 MQD 的字段布局与装载、保存范围**

**已确定：** KIQ、HIQ 和用户队列共用 64 字节 MQD，最低按 8 字节对齐，多字节字段采用小端格式。完整字段、偏移和使用关系见[第 2.6 节](#spec-mqd-format)。驱动填写配置和初始状态，CP 装载配置、恢复消费位置后最后激活；卸载停止取包并确认相关访问结束后，只保存 `saved_rptr` 和 `saved_error`。

MQD 自身地址由管理命令提供，不放在 MQD 内；`ACTIVE` 由装载、卸载流程控制，MQD 不缓存生产进度。`saved_rptr` 保留 64 位存储，零扩展保存 HQD 中的 32 位消费包编号；装载时高 32 位非零则拒绝配置，完整规则见[第 5.2.1 节](#spec-ring-progress)。控制编码已按 9.2.2 确定，错误保存和清理后重建按[第 7.2 节](#spec-queue-error-policy)执行；正常卸载已按[第 7.4 节](#spec-unmap-drain)确定，强制恢复步骤列入[后续异常恢复扩展](<./QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)；本项为设计确认，尚待实现。

<a id="spec-register-encoding"></a>

**9.2.2 已采用寄存器的有效位与数值编码**

**已确定：** 完整编码与示例见[第 8.1 节](#spec-hqd-field-encoding)。`CP_HQD_PQ_CONTROL` 的整个 32 位值直接保存 Ring 字节容量，允许 64 字节～64 KiB 的 2 的幂，`0` 为非法容量。`CP_HQD_PQ_DOORBELL_CONTROL` 的 bits 27:2 保存以 4 字节为单位的 BAR4 相对偏移，bit 30 为独立使能，其余位填 0；正常装载先配置 Doorbell、读取生产进度，最后激活队列。

`CP_HQD_ACTIVE` 只使用 bit 0，`CP_HQD_VMID` 整个值为 `0`，`CP_HQD_AQL_CONTROL` 整个值为 `0` 或 `1`。四组地址寄存器继续按完整的 64 位 Host RAM 物理字节地址直接拆分。MQD 保持 64 字节，HQD 保持 15 个寄存器位置；RPTR 按[第 5.2.1 节](#spec-ring-progress)保存 32 位消费包编号，ERROR 的编码已按第 7.2 节及 9.6 确认。Doorbell 的入口分配、64 位写入、通知值及刷新时机已按[9.4.5](#spec-doorbell-rules)确定，寄存器复位与访问规则已按 9.2.3 确定；本项为设计确认，尚待实现。

<a id="spec-register-access"></a>

**9.2.3 复位值、读写权限与非法访问**

**已确定：** 完整规则见[第 8.2 节](#spec-hqd-access-rules)。设备冷复位或整体复位清零 HQD 与 `HQD_SELECT`，CP 单独复位保留 HQD。寄存器使用小端、4 字节对齐的 32 位访问；首次 KIQ 由保持复位期间的 Host 配置，运行后 Host 对 HQD 只读，配置修改由 CP 按 KIQ、HIQ 各自的管理分工执行。

运行期间固定地址、容量、格式、VMID 和 Doorbell 偏移，CP 仅更新消费进度、错误、ACTIVE 和 Doorbell 使能。非法写入保留原值，非法读取返回 0，并置位全局 `ERROR_STATUS.INVALID_CMD`；未采用位置按规定宽度读零、写入按非法访问处理。Host 读取配置须等待对应管理操作完成，动态进度的一致性按 9.4 的已确认规则执行；错误记录与初始化按[第 7.2 节](#spec-queue-error-policy)执行，正常卸载按[第 7.4 节](#spec-unmap-drain)执行，故障复位恢复列入[后续异常恢复扩展](<./QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)。无效槽位和 CP 本地地址已按 9.2.4 确定；本项为设计确认，尚待实现。

<a id="spec-hqd-address-selection"></a>

**9.2.4 CP 本地地址与无效槽位选择**

**已确定：** 完整地址、关系图入口与访问例子见[第 8.3 节](#spec-hqd-address-map)。设备保存 4 份独立 HQD，Host 共用一个选槽窗口；CP 固定基址为 `0xffff_0000`，槽位间隔为 `0x100`，四个槽位共映射 `0x400` 字节。Host 窗口与 CP 直接地址访问同一份状态，切换选择不复制 HQD 内容，也不改变 CP 正在处理的队列。

`HQD_SELECT` 只接受 `0～3`，无效值拒绝写入、保留原选择并置位全局 `ERROR_STATUS.INVALID_CMD`；驱动在选槽锁内写入并回读确认。槽内未采用位置按第 8.2 节处理，CP 访问 `0xffff_0400` 这样的未映射地址时进入访存异常，不折返到有效槽位。9.2 各项均已确认，具体功能仍待实现。

### 9.3 管理命令的内容与结果确认

驱动已经建立 HIQ、准备好本次用户队列的 MQD，接下来经 HIQ 请求 CP 配置队列。管理操作后追加写完成标记命令；本节记录 CP 实际读取的命令内容，以及 Host 判断本次结果的方法。

<a id="spec-management-command-scope"></a>

**9.3.1 KIQ、HIQ 各自处理的命令**

**已确定：** KIQ 建立 HIQ，再由 HIQ 管理用户队列。两条管理队列均支持映射、卸载和写完成标记；KIQ 的映射、卸载只允许目标槽位 1，HIQ 只允许目标槽位 2、3。用户 AQL Queue 不接收管理命令。

管理操作与后附标记必须位于同一 Ring，驱动确认 HIQ 建立成功后再使用 HIQ。第一版仍直接处理 Ring 中的命令，不增加 runlist IB 或进程映射，也不创建超额逻辑队列等待槽位。完整分工、建立顺序与完成示例见[第 4 节](#spec-management)，队列功能尚待实现。

<a id="spec-management-command-layout"></a>

**9.3.2 命令布局与目标队列的表示**

**已确定：** `MAP_QUEUES`、`UNMAP_QUEUES`、`WRITE_COMPLETION` 的操作编号依次为 `1`、`2`、`3`。三种命令均固定为 32 字节、小端，起点按 32 字节对齐，不设置长度字段；保留区填零，操作编号 `0` 和其他未定义编号非法。完整字段、偏移和使用关系见[第 4.1 节](#spec-management-packet-format)。

`MAP_QUEUES`、`UNMAP_QUEUES` 均在偏移 `0x04` 保存 32 位 `queue_kind`，在偏移 `0x08` 保存 64 位 MQD 地址，后 16 字节保留并填零。种类编码为 `HIQ = 1`、`USER_AQL = 2`，`0` 和其他值非法。映射时，来自 KIQ 的 `HIQ` 请求使用专留槽位 1；来自 HIQ 的 `USER_AQL` 请求由 CP 从槽位 2、3 中选择空闲槽位。

卸载时，CP 在允许的目标范围内，用命令中的 MQD 物理地址匹配当前绑定槽位中保存的完整地址，再按既定流程处理。每条存活队列使用独立的 MQD，相关管理操作和卸载收尾完成前不释放或复用。MQD 仍为 64 字节，HQD 仍为 15 个寄存器位置。MQD 地址和完成地址均为完整的 64 位 Host RAM 物理字节地址，`WRITE_COMPLETION` 写入 64 位无符号标记值。

本小节已确认，功能尚待实现。进度计数见[第 5.2.1 节](#spec-ring-progress)，重复请求和槽位占用见 9.3.3，标记使用与复用见 9.3.4；管理失败后的命令处理及结果返回协议已按 9.3.5 确定。

<a id="spec-management-slot-occupancy"></a>

**9.3.3 重复配置、重复卸载与槽位占用**

**已确定：** 队列和 MQD 按申请动态创建，全设备同时最多两条用户 Queue，由 CP 从槽位 2、3 中分配。CP 在固件保留区的私有数据中维护每槽占用状态和绑定的 MQD 物理地址；装载中、已绑定、卸载中和异常未清理均算占用，`ACTIVE = 0` 不能单独作为空闲依据，不增加 MQD 字段或 HQD 寄存器。

按完整 `mqd_addr` 查重：地址已在占用记录中时返回“重复映射”，保留原绑定、配置和消费位置；新的用户队列无空闲槽位时返回“名额已满”。HIQ 专留槽位已占用时，拒绝用另一份 MQD 覆盖。卸载找不到当前绑定时返回“队列未映射”，不修改其他槽位；成功卸载且尚未重新绑定时，再次卸载同一地址也按此返回，不保存历史卸载记录。

正常卸载须停止取包、确认相关在途访问结束并成功保存必要状态，才解除绑定、释放槽位。映射失败只有在确认尚未激活、相关访问结束且部分配置已撤销时才归还槽位，否则保留占用并进入恢复流程。Host 释放内存仍须确认管理结果并满足资源生命周期约定。

完整流程与图示见[第 4.2 节](#spec-management-slot-state)。本小节已确认，功能尚待实现；请求结果码和返回位置已按 9.3.5 确定，基本错误退出按 9.6 执行，强制停止与故障复位留作后续扩展。

<a id="spec-management-marker-rules"></a>

**9.3.4 完成标记的数值、发布与复用**

**已确定：** 每个在途管理请求独占一个 16 字节、至少按 8 字节对齐的结果区；其中完成标记占 8 字节，其余字段按 9.3.5 确定。驱动按请求分配，不固定绑定用户队列；标记初值为 `0`，预期值使用按设备分配、从 `1` 开始递增的 64 位无符号序号，第一版不支持回绕复用。Host 按等于本次预期值判断，不把任意非零值当作完成。

驱动先初始化整个结果区，再将管理命令与对应的 `WRITE_COMPLETION` 放入提交该请求的 KIQ Ring 或 HIQ Ring，按 Ring 顺序相邻发布。CP 先结束管理操作并暂存结果，再由 `WRITE_COMPLETION` 写结果码、写标记；Host 带超时轮询，可以在检查间短暂休眠，读到预期值并完成相应同步后，再读取管理结果。管理通道故障的等待退出规则见 9.3.5。

完整 64 位访问沿用 9.4.3 和[第 2.2.1 节](#spec-shared-value-integrity)的要求，屏障和后端保证仍须接入并验证。只有确认 CP 不会再写旧请求的结果区，且 Host 已结束等待和结果处理，才可重新初始化并交给新序号请求使用；故障或超时不能直接清零、释放或复用，须等请求结束或恢复流程确认相关访问已终止。

完整对象关系、流程图和规则见[第 4.3 节](#spec-management-marker)。本小节已确认，功能尚待实现；每请求分配空间已随 9.3.5 补齐为 16 字节，完成标记仍为 64 位，失败结果与写回故障按下节处理。

<a id="spec-management-failure"></a>

**9.3.5 管理操作失败后的命令处理**

**已确定：** 每个请求的 16 字节结果区位于 Host RAM，至少按 8 字节对齐，字段采用小端格式：偏移 `0x00` 保存 8 字节 `completion`，偏移 `0x08` 保存 4 字节 `status`，偏移 `0x0c` 为 4 字节保留空间。发布前分别初始化为 `0`、`0xffff_ffff`、`0`；`completion_addr` 指向结果区开头，CP 校验完整 16 字节访问范围。

CP 按 KIQ、HIQ 分别暂存本次管理结果。后附 `WRITE_COMPLETION` 先写 `completion_addr + 8` 的结果码，保证可见，再写完成序号；回报后清除暂存状态，32 字节命令布局不变。普通管理失败也回报，随后可继续处理管理 Ring；MQD 访问失败仅在固件能够安全结束本次处理并继续回报时走此路径，槽位与资源保留仍按 9.3.3。

结果码 `0～6` 依次为成功、无可用槽位、重复映射、队列未映射、管理命令参数非法、MQD 读取或状态保存失败、操作未正常收尾需恢复。Host 读到本次预期序号后同步并读取结果；结果码仍为初始值或未知编码时，报告协议错误。

管理 Ring 取包、已发布命令配对或结果写回出错时，记录来源管理队列的 `CP_HQD_ERROR`，停止该 Ring 后续消费，不自动重放管理操作。结果码写入失败不继续写标记，标记写入报错不盲目重试；KIQ 实际通道故障均停止全部新取包和新派发；HIQ 故障停止 HIQ，KIQ 和已驻留的正常用户队列继续处理。Host 在标记未匹配时检查管理通道故障，故障或超时均可结束等待，但须保留相关内存，不能据此认定操作结果或设备访问已结束。

完整布局、失败示例与等待流程见[第 4.4 节](#spec-management-result)。9.3 各项已确认，功能尚待实现；队列故障编号、首次记录和停止范围已按[第 7.2 节](#spec-queue-error-policy)确定，失败后的进度处理与等待退出已按[第 7.3 节](#spec-failure-retirement)确定，强制恢复列入[后续异常恢复扩展](<./QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)，正常回收继续遵守已确认的对象寿命条件。

### 9.4 Ring 包的发布与读写进度

Queue A 已激活，Host 开始提交任务。Doorbell 通知有包发布，CP 读取共享 `W` 并从自己的消费位置检查包；正常 Dispatch 完成并收尾后才归还 Ring 槽。下面确定双方怎样计算空槽、发布新包和读取进度。

<a id="spec-ring-capacity-boundaries"></a>

**9.4.1 两类 Ring 的容量与包边界**

**已确定：** 管理 Ring 每槽 32 字节，用户 AQL Ring 每槽 64 字节，一条命令完整占用一个槽，不跨越 Ring 末尾，不增加末尾填充命令。容量与基址对齐沿用已有约定，槽数按字节容量除以包大小计算。处理完末槽后回到槽 0，继续使用原内存，不整体清空 Ring。

创建 AQL Ring 时将各槽 Header 初始化为 `INVALID`；Host 根据消费回报复用旧槽，CP 根据新的可消费范围和发布状态读取新包，遇到 `INVALID` 等待。管理 Ring 按自身发布协议判断可读范围。完整图示与规则见[第 5.1 节](#spec-ring-packet-boundaries)，功能尚待实现；进度计数和溢出规则见[第 5.2.1 节](#spec-ring-progress)。

<a id="spec-ring-progress-values"></a>

**9.4.2 进度值的含义、位宽与回绕**

**已确定：** 两类 Ring 均按包计数，`W`、`R` 均为 32 位无符号数，`R` 表示下一待消费包的编号。用户 AQL Queue 的 `W` 表示下一待预留包的编号；Host 先原子取号，等对应物理槽可复用后再填写包体、发布有效 Header。管理 Ring 的 `W` 仍表示已发布范围之后的下一包编号，驱动须先写完整命令再推进。

`P` 为包编号、`N` 为槽数，按 `P mod N` 定位物理槽。用户 AQL 的 `D = (W - R) mod 2^32` 表示已预留但尚未归还的编号数量，可暂时大于 `N`，不能仅凭 `D > N` 报进度错误。每个提交线程须等待 `(P - R) mod 2^32 < N`，取得对应消费回报并完成同步、确认旧 Header 为 `INVALID` 后，才能写入自己的槽。全部 `N` 个槽可用，`D > 0` 仍不保证当前包已发布；管理 Ring 保留按容量限制已发布范围的规则。

进度增量和差值按模 `2^32` 处理，不因物理槽回绕或数值溢出清空 Ring；在途预留不得跨过完整的编号周期，以免活跃编号重复。容量判断已按 2026-10-18 确认的[9.4.4 主方案](#spec-ring-submitters)修订。

HQD 保存完整的 32 位 `R`，共享内存中的生产进度与消费回报也为 32 位，存放位置至少按 8 字节对齐。MQD 的 64 位 `saved_rptr` 零扩展保存 `R`，装载时高 32 位非零则拒绝配置。首次进度均为 `0`，正常重装恢复保存的 `R` 并读取保留的 `W`。完整图示、计算及恢复规则见[第 5.2.1 节](#spec-ring-progress)，功能尚待实现。

<a id="spec-shared-value-access"></a>

**9.4.3 持续变化的 64 位值怎样一致读取**

**已确定：** Signal 完成值、管理完成标记和通知槽中的 64 位字段至少按 8 字节对齐，Host 与 CP 每次完整读写 64 位。读取方只能取得完整旧值或完整新值，不得取得新旧部分拼出的混合值；本版不采用拆成两个 32 位、反复读取再拼接的协议。生产、消费进度继续使用完整的 32 位访问，存放位置仍至少按 8 字节对齐。

完整访问由 Host、CP 和 QEMU 后端共同保证；一次 `LD/SD` 或一条 8 字节消息不能单独证明整条路径满足要求，接入时须核对并验证。Signal 仍由 CP 单独更新，不增加原子读改写入口。

完整读写与相关数据的可见性均须落实：AQL 先推进 `W` 预留、后发布有效 Header；结果写回先于 Signal 完成值发布，旧槽释放先于新 `R` 回报。Host、CP 按各自接收路径完成同步后再使用对应数据。具体要求与图示见[第 2.2.1 节](#spec-shared-value-integrity)。本小节已确认，队列接入、屏障实现和并发验证仍待完成。

<a id="spec-ring-submitters"></a>

**9.4.4 提交者数量与包发布顺序**

**已确定：** 同一条用户 Queue 支持多个 Host 线程原子预留编号、并行填包、分别发布 Header。Host CPU 对共享内存中的 32 位 `W` 执行原子读改写，CP 只读取 `W`；进度区至少按 8 字节对齐，并采用支持 Host CPU 原子操作的内存映射。

提交顺序为“先原子取号 → 等待该编号对应的物理槽可复用 → 保持 `INVALID` 填写包体 → 发布有效 Header → 通知 Doorbell”。线程只填写自己的包，不用一把锁串行保护整个填包和发布过程。取号后 `W - R` 可以暂时大于槽数；9.4.2 已同步改为按各自 `P` 与消费回报 `R` 判断能否写槽，不能仅凭 `D > N` 报错，也不能提前覆盖旧槽。

CP 按包编号顺序处理，当前包为 `INVALID` 时保持消费位置，不跳过它；等待期间按正常调度检查其他队列。后续检查必须能在 `W` 不变时发现 Header 发布。并行交错图见[第 5.2.2 节](#spec-aql-multi-producer)，满队列与回绕规则见[第 5.2.1 节](#spec-ring-progress)。

**2026-10-18 补齐并统一确认以下三项：**

1. **AQL 首部与槽位归还。** `header + setup` 作为一个对齐的 32 位值整体发布，两个字段仍各占 16 位；Host 与 CP 完整读写，沿用既定屏障。CP 在成功收尾后先恢复 `INVALID`，保证可见后再回报新 `R`，Host 同步后复用。布局与发布见[第 5.2.2 节](#spec-aql-header-access)，归还顺序见[第 6 节](#spec-dispatch-completion)。
2. **管理 Ring 并发。** 每条管理 Ring 由驱动串行保护发布过程；确认两个空槽，写完逻辑相邻的“管理命令 → `WRITE_COMPLETION`”，再一次发布新 `W` 并通知设备。发布后释放提交锁，各请求等待自己的结果区。完整流程见[第 4.3 节](#spec-management-submit-lock)，用户 AQL 多生产者规则保持不变。
3. **取号后的发布约束。** 可能失败的资源准备、参数检查放在取号之前；正常路径取号后必须发布，不提供取消预留编号的能力。异常退出留下空洞时停止继续使用该队列并保留必要资源，不回退 `W`；补洞与自动恢复留作扩展。在途预留数量限制随提交代码落实，防止活跃编号重复，见[第 5.2.2 节](#spec-aql-reservation-lifetime)。

**[BOUNDARY]** 本小节的多生产者方案、首部访问与槽位归还、管理发布及预留使用约束均已确认，功能尚待实现和验证。具体锁、屏障封装、映射属性和在途预留限额在接入时落实；现有 32 位进度、64 位 Doorbell 写入和默认等待规则保持不变。

<a id="spec-doorbell-rules"></a>

**9.4.5 Doorbell 的队列对应、写入值与刷新时机**

**已确定：** 每条 Queue 使用独立 Doorbell 入口；管理队列的入口由驱动保留，用户入口在创建时分配，经 MQD 装入 HQD，不固定绑定用户 HQD 槽位。入口按 8 字节对齐，每次完整写入 64 位小端值，低 32 位保存已发布包编号 `P`、高 32 位为零；共享 `W`、`R` 仍使用 32 位访问。

用户 AQL 发布有效 Header 后通知 `P`；同一线程可在连续一批包全部发布后通知最后一个编号。管理 Ring 先发布 `W`，再通知本次最后一个包编号。通知允许 `11 → 10` 这样的乱序，包 10 就绪后，CP 按顺序继续处理包 10、11，无需为包 11 补发通知；通知不能改写 `R`，也不能因最后一个值较小而遗漏已有工作。

CP 每次轮到检查活跃队列时重新读取共享 `W`，从 `R` 检查当前包；队列读空或遇到 `INVALID` 后按正常主循环复查，即使 `W` 未变也能发现 Header 发布。重复或合并通知不改变取包顺序，等待计算期间到达的提交在返回主循环后检查。继续处理已就绪包不要求一次清空 Ring，任务是否完成仍按 Signal 和错误协议判断。

完整规则及 `11 → 10` 交错图见[第 5.2.3 节](#spec-doorbell-notification)，AMD/HSA 依据见[Doorbell 参考](<./CP_MEC 软件实现、参考与扩展.md#doorbell>)。本小节已确认，功能尚待实现和验证；9.4.4 的首部访问、并发发布及预留使用约束也已确认。

### 9.5 从 Dispatch 启动计算并发布 Signal

CP 已经取得一个有效 Dispatch，接下来读取描述对象，向执行器提供代码入口、Host 参数块物理地址与任务规模，阻塞等待完成；参数内容由执行器读取。第 6 节已经确定成功收尾顺序，下面补齐任务格式和交接接口。

<a id="spec-aql-packet-scope"></a>

**9.5.1 第一版支持的 AQL 包与字段**

**已确定：** 第一版只执行 Kernel Dispatch，采用标准 AQL 的 64 字节字段布局，保留位全部填零；独立 Barrier-AND、Barrier-OR、Agent Dispatch 和厂商自定义包暂不支持。`INVALID` 表示尚未发布，CP 按发布协议等待。

支持一维、二维、三维任务，未使用维度的 `grid_size`、`workgroup_size` 均填 `1`，各维非零且必须整除。CP 将 AQL 各轴的线程数量除以每组线程数量，换算为执行器的工作组数量；每组最多 `1024` 个线程、每次最多 `4096` 个工作组、实际启动线程总数最多 `65536`，计算中检查溢出。末尾数据不足一个完整工作组时，由运行时补齐启动尺寸，Kernel 按参数中的实际范围退出多余线程。

Kernel 描述对象、参数块和完成 Signal 都须提供有效引用，分别沿用 VRAM 偏移和 Host 物理地址约定；不省略完成 Signal。`group_segment_size`、`private_segment_size` 均为 `0`，线程继续使用固定寄存器。acquire、release fence scope 均为 `SYSTEM` 并实际落实同步，Header 的 `barrier` 位允许 `0`、`1`，本版继续逐个完整执行 Dispatch。

已发布的包不受支持或字段非法时，记录队列错误并停止该队列后续取包，不静默忽略，不写成功 Signal；错误编号已按[第 7.2.1 节](#spec-queue-error-codes)确定，失败收尾按[第 7.3 节](#spec-failure-retirement)处理。完整包布局、1024 元素向量加法图和尺寸校验规则见[第 6.1 节](#spec-dispatch-packet)。本小节已确认，功能尚待实现和验证。

<a id="spec-kernel-executor-interface"></a>

**9.5.2 Kernel 描述对象与 RV32 计算执行器参数约定**

**已确定：** RV64 CP 读取 Dispatch 和 Kernel 描述对象，向 RV32 计算执行器交付代码入口、代码长度、完整的 64 位 Host 参数地址、参数长度及任务规模。描述对象由运行时加载 Kernel 时生成，位于 VRAM、至少按 8 字节对齐，固定为 16 字节；偏移 `0x00`、`0x04`、`0x08`、`0x0c` 依次保存 32 位小端的 `code_entry`、`code_size`、`kernarg_size`、填零的保留字段。同一 Kernel 可复用描述对象，代码从入口开始，入口按 4 字节对齐，长度为非零的 4 字节整数倍，执行器按声明范围检查取指。

参数块位于 Host RAM，由运行时按 Kernel 的约定填写 32 位小端字段；基址至少按 8 字节对齐，长度为 4 字节至 64 KiB，且为 4 字节的整数倍。无参数 Kernel 使用填零的 4 字节占位块。CP 检查地址和长度，应用字段由 Kernel 解释。

计算执行器保存完整 Host 参数基址和长度，在自己的地址空间提供只读窗口 `0x9000_0000～0x9000_ffff`，各计算线程启动时 `a0 = 0x9000_0000`。Kernel 按 `a0 + 偏移` 读取，执行器检查范围后按完整 Host 基址加偏移直接访存，不搬运整块参数到 VRAM。窗口只接受对齐的 4 字节整数或浮点读取，每次检查实际参数长度、Host 地址溢出和访存结果，写入窗口报错。CP 已有 Host 窗口继续供固件使用。

Host 发布前准备好描述对象、代码和参数，发布后保持内容及存储有效，直到确认任务不再访问。描述对象字段非法、取指或参数越界、窗口写入及 Host 读取失败均使任务失败，记录并停止所属队列后续取包，不发布成功 Signal。完整布局、向量加法流程及地址换算见[第 6.2 节](#spec-kernel-descriptor)。本小节已确认，功能尚待实现和验证；计算交接接口见已确认的[9.5.3](#spec-cp-dispatch-interface)，队列错误编号见[第 7.2.1 节](#spec-queue-error-codes)，失败收尾按[第 7.3 节](#spec-failure-retirement)处理，执行器细分错误码仍需补齐。

<a id="spec-cp-dispatch-interface"></a>

**9.5.3 CP 提交计算与读取执行结果**

**已确定：** 由 CP 解析 Kernel 描述对象，复用原有 BAR0 分发配置，并按 `0xfffd_0000 + BAR0 字节偏移` 访问同一份状态。寄存器采用对齐的 32 位小端访问，地址分高、低两次填写；`KERNEL_ADDR` 继续保存代码入口，队列路径的 `KERNEL_ARGS` 保存完整的 64 位 Host 参数物理地址。新增 `KERNEL_CODE_SIZE`（`0x032c`）、`KERNEL_ARGS_SIZE`（`0x0334`），用于取指和参数访问的实际范围检查；`DISPATCH` 保持 `0x0330`。

一次接收一个任务。CP 在 `IDLE` 填完配置并保证顺序后，向 `DISPATCH` 写 `1`，设备统一保存配置，校验通过后进入 `BUSY`，校验失败返回 `FAILED`。新增只读 `DISPATCH_STATUS`（`0x0338`，`IDLE=0`、`BUSY=1`、`DONE=2`、`FAILED=3`）、只读 `DISPATCH_ERROR`（`0x033c`）和写确认 `DISPATCH_ACK`（`0x0340`）。忙或结果未确认时拒绝修改配置和重复提交；终态结果保留到 CP 读取并写 `ACK=1`，然后回到 `IDLE`，确认操作不能中止执行。

启动后及时返回，执行器分段推进并保留线程状态和累计预算；CP 等待整个 Dispatch，期间 Host 可在有空槽时继续发布。正常队列路径由 CP 独占提交和确认，旧 Host 直接提交路径用于独立回归，不与队列路径同时使用。执行器结束相关访问并完成写回后返回成功，失败也须结束相关访问后返回；CP 保存结果、清理并确认取走后，成功才继续发布 Signal，失败记录并停止所属队列后续取包。

完整寄存器、向量加法流程和状态变化见[第 6.3 节](#spec-executor-dispatch)。本小节已确认，功能尚待实现和验证；Signal 与等待协议见已确认的[9.5.4](#spec-signal-completion-protocol)，队列错误编号见[第 7.2.1 节](#spec-queue-error-codes)，失败收尾按[第 7.3 节](#spec-failure-retirement)处理，执行器细分错误码仍需补齐。

<a id="spec-signal-completion-protocol"></a>

**9.5.4 Signal 的表示与完成操作**

Host 创建一个完成对象，把物理地址放进 Dispatch；CP 完成任务后更新，Host 再据此判断完成。Signal、事件编号与通知槽的字段含义、位宽和最低对齐要求已在[第 2.5 节](#spec-signal-representation)确定。[第 2.1.2 节](#spec-signal-single-writer)也已确定：`value` 为 64 位有符号数，Host 提交前置 `1`，提交后只读，由 CP 在成功完成时减为 `0`，Host 等待值为 `0`。一次使用中的 Signal 对应一个任务，不作为多个任务的共享计数，也不要求原子读改写入口。

Host 默认采用[先短暂轮询、再阻塞等待](#spec-signal-blocked-wait)的方式，设备通知与内核事件唤醒属于第二阶段范围；`HSA_WAIT_STATE_ACTIVE` 的持续主动等待留作扩展。该等待方式已经确定，本项规定通知交付与等待登记的配合。

通知路径已按[第 7.1.5 节](#spec-ih-signal-notify)确定：结果写回后更新 `S.value`，再写通知槽，提交 `SIGNAL_NOTIFY`，经 IH 中断交给 Host。记录用 MQD 地址找到 Queue 所属进程，再用 `event_id` 找到该进程的事件；唤醒后复查 Signal。

**本次补齐并确认：** Signal 固定为 24 字节，起始地址至少按 8 字节对齐、多字节字段小端；偏移 `0x00`、`0x08`、`0x0c`、`0x10` 分别保存 64 位有符号 `value`、32 位无符号 `event_id`、填零的 32 位保留字段和 64 位 `event_mailbox_ptr`。Host 发布前填写完整对象，提交后保持固定字段不变；CP 在发布完成值前取得并保存通知所需的信息。

每个使用中的 Signal 独占事件和通知槽。事件编号由驱动在所属进程内分配，非零且在存活事件中不重复；通知槽为至少 8 字节对齐的 8 字节对象，初值为 `0`，CP 完成时写入零扩展到 64 位的事件编号。驱动按 IH 记录找到事件、确认通知槽关联，先保存“已通知”状态，再清零通知槽并唤醒等待者。

通知处理和等待登记须正确同步，登记后再次检查条件，尚未通知才睡眠；通知提前到达时，之后的等待请求直接返回复查 Signal。等待返回不清除事件的“已通知”状态，同一任务可唤醒多个等待者；只有旧通知与相关处理结束后，才能按资源复用协议重新初始化 Signal、事件和通知槽。Signal 值、完成顺序和约 `200 μs` 的默认等待流程沿用此前已确定规则。

完整布局、通知流程和等待交错图见[第 2.5.2 节](#spec-signal-layout)、[第 2.5.3 节](#spec-signal-notify-wait)。本小节已确认，功能尚待实现和验证；具体可见性操作见下述 9.5.5，错误处理按 9.6 的已确认范围执行，资源接口已按 9.7 确认。

<a id="spec-task-visibility"></a>

**9.5.5 任务数据与完成状态的可见性**

Host 看到 Signal 完成后，要能读到本次 Kernel 的结果；CP 开始计算前，要能取得 Host 准备好的输入。Packet 的 acquire、release scope 仍为 `SYSTEM`，第 6 节的提交和收尾顺序继续沿用。

**本次补齐并确认：** A57 用户态运行时封装带编译器内存约束的 `dmb sy`。Host 完成 VRAM 上传、Host 参数及包体填写后，先执行屏障，再按发布规则写有效 Header；再执行屏障后写 Doorbell。上传采用 DMA 时须先等待成功完成，不能仅用屏障代替等待。

RV64 CP 固件采用带编译器内存约束的 `fence iorw, iorw`：读到有效 Header 后同步再读取输入，写完全部执行器配置后同步再写 `DISPATCH`。QEMU 后端须在结果写回和相关访问完成后发布 `DONE`，跨线程交接用锁或 release/acquire 同步；固件屏障不能代替后端完成。

CP 读到 `DONE` 后同步，保存结果、清理并确认取走，再同步后发布 Signal；随后按“屏障、写通知槽、屏障、提交 IH”的顺序通知 Host，每次访问成功后才继续。Host 完整读到 `Signal = 0` 后执行 `dmb sy`，再读取或复制结果；复制若采用 DMA，还须等待传输完成。事件唤醒后仍复查 Signal。

完整流程和依据见[第 6.4 节](#spec-dispatch-visibility)。本小节已确认，屏障封装、后端同步及变更输入的多轮连续提交验证尚待实现；Header 的完整 32 位访问和管理 Ring 的串行发布也已按 9.4.4 确认。9.6.1～9.6.3 已确认；9.6.4、9.6.5 已转为后续扩展，9.7 的 Host 软件接口也已确认，功能尚待实现。

### 9.6 出错后怎样结束任务，卸载后怎样停止访问

第 7 节已经保留 `CP_HQD_ERROR`，也确定卸载成功必须停止取包、结束相关访问并保存必要状态。9.6.1～9.6.3 确定第二阶段的基本错误退出与正常卸载，避免 Host 只等成功标记或过早释放内存；9.6.4、9.6.5 的强制停止和故障恢复留作后续扩展。

<a id="spec-queue-error-notification"></a>

**9.6.1 错误记录、停止取包与通知**

例如 CP 无法读取一条用户队列的 Ring，需要记录原因，并让等待这条队列的 Host 线程知道已经出错。

**已确定：** `CP_HQD_ERROR` 使用 32 位错误编号 `0～10`，由 CP 保留首次错误，Host 只读；队列第一次进入故障状态时提交一次 `QUEUE_ERROR`。CP 清除出错队列的 `ACTIVE`，保留槽位占用和 MQD 绑定。用户队列故障只停该队列；HIQ 故障停止 HIQ，KIQ 和已驻留的正常用户队列继续处理；KIQ 实际通道故障、固件代码或栈异常停止全部队列的新取包与新派发。

普通管理请求失败继续写回独立结果区，不使来源管理队列故障。MQD 状态保存失败时，能安全回报则返回 `status = 5`，保留目标槽位；目标队列尚无错误时记编号 `10`，已有首次错误时保留原值。错误队列在卸载或设备恢复、确认访问结束并处理完旧通知后重建；`saved_error != 0` 的未绑定 MQD 拒绝重新激活，返回参数非法结果 `status = 4`。槽位清理后用于新队列时由 CP 初始化错误状态，CP 单独复位保留 HQD；不自动重放任务或补写成功 Signal，已发生写入保留。完整编号和流程图见[第 7.2 节](#spec-queue-error-policy)。

IH 通知继续采用全设备共用的 Host RAM Ring，默认 4 KiB，每条记录 32 字节；七个管理寄存器包含字节容量 `IH_SIZE`，CP 经 `IH_SUBMIT` 同步提交固件私有 VRAM 中的记录。记录保存类型、槽位、完整 MQD 地址和事件编号或错误值，W、R 使用 32 位记录编号。先写记录、再发布 W、最后中断通知 Host；首次通道故障和最近一次 CP 提交结果分别保存。IH 故障停止继续取包和调度，经已有 `IRQ_ERROR` 通知；旧通知及后续处理结束前不复用 MQD 地址和事件编号，完整接口见[第 7.1 节](#spec-ih-notification)。

本小节主方案已确认，功能尚待实现。IH 寄存器地址偏移、IH 故障及非零提交结果枚举、复位字段清单仍需在接入前补齐；失败包的基本收尾和正常卸载已按 9.6.2、9.6.3 确定，任务卡住后的强制停止和复位重建已按 9.6.4、9.6.5 列入[后续异常恢复扩展](<./QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)。

<a id="spec-failure-retirement-rules"></a>

**9.6.2 失败包与部分完成的收尾**

**已确定：** 出错后停止正常收尾，不跳过失败包，不为丢弃它而清除 Header 或推进消费进度，不补写成功 Signal。保留已经发生的数据、Signal 和进度更新，不回退，也不自动重放任务、重发管理命令或重试完成写入；普通管理失败继续按既定协议返回结果。

驱动保存故障、唤醒相关等待者，以错误结束尚未完成的等待；相关资源保留到设备访问和旧通知处理结束。完整流程见[第 7.3 节](#spec-failure-retirement)。逐步故障分析、故障注入、自动重试和原地恢复列为[后续扩展](<./QEMU GPGPU 实验大纲.md#failure-recovery-extension>)，第一版仍须保证完整读写和发布顺序。本小节已确认，功能尚待实现；正常卸载见已确认的[9.6.3](#spec-unmap-rules)。

<a id="spec-unmap-rules"></a>

**9.6.3 卸载时未消费的任务与 ACTIVE 清零**

**已确定：** 正常卸载前，Host 停止该队列的新提交，等待已开始的提交完成发布，再等待已有任务完成，以消费回报 `R == W` 确认排空，随后发布 `UNMAP_QUEUES → WRITE_COMPLETION`。CP 开始卸载时，将槽位标为卸载中，清除 `ACTIVE` 并关闭 Doorbell 使能；确认相关访问结束、成功保存 `saved_rptr` 和 `saved_error` 后，才解除绑定并归还槽位。Host 确认本次管理操作成功，处理完旧通知并满足对象寿命条件后回收资源。

故障队列的清理不要求先排空，尚未完成的等待按 9.6.2 报错退出，资源继续保留。正常卸载 HIQ 前，由驱动停止新的用户队列创建请求，卸载所有用户队列，并确认 HIQ 中的管理请求及后附完成命令全部处理结束，再经 KIQ 卸载 HIQ；CP 不自动连带卸载用户队列。

完整流程见[第 7.4 节](#spec-unmap-drain)。取消未执行任务、保留未执行任务跨卸载续跑列为[后续扩展](<./QEMU GPGPU 实验大纲.md#queue-unmap-extension>)。本小节已确认，功能尚待实现；9.6.4、9.6.5 已转为后续扩展，9.7 的 Host 软件接口也已确认，功能尚待实现。

<a id="spec-stalled-task-scope"></a>

**9.6.4 当前任务不结束时的停止与资源处理**

**已确定范围：** 任务长时间不结束时的挂死判断、强制中止、局部复位、设备整体复位恢复及自动恢复，移到[后续异常恢复扩展](<./QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)，不作为第二阶段必做或验收内容。本阶段保留已有的等待超时和资源保护约定：

```text
Host 等待达到超时时间
  → 本次等待返回超时，不自动复位设备或补写成功 Signal
  → 尚不能确认设备访问结束：继续保留相关内存和对象
```

固件等待 Dispatch 时仍暂不处理 KIQ、HIQ；任务一直不结束也会阻挡后续卸载命令，第二阶段暂不解决这一限制。能够正常结束的任务、正常卸载及 9.6.1～9.6.3 已确认的错误记录、等待退出规则继续实现。

<a id="spec-runtime-reset-scope"></a>

**9.6.5 KIQ 重配与复位后的重新建立**

**后续扩展：** 运行期间的 KIQ 重配、故障 HIQ 重建、故障复位后旧队列和旧请求的清理与重新建立，随[异常恢复扩展](<./QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)再细化，不再作为第二阶段的待确认接口。

第二阶段沿用[第 3 节](#spec-boot)的首次固件装载、KIQ 配置和启动流程，以及已确认的正常队列建立与卸载规则。现有复位寄存器和 HQD 保留、清零约定继续保留；CP 单独复位仍不能证明计算与 DMA 已停止。Host 软件接口已按下述 9.7 确认，功能尚待实现。

<a id="spec-host-api-scope"></a>

### 9.7 HSAKMT 风格接口与驱动资源管理

**实现边界已确定：** 本阶段向上实现到满足实验需要的 HSAKMT 风格用户态接口库。库封装设备连接、参数检查、`ioctl`、`mmap` 和必要的软件对象；内核驱动负责资源、队列、事件及错误处理。ROCr/HSA 运行时、通用内存池、通用 Kernel 装载器和高层 Launch 接口暂不设计。已有 CP、AQL、Signal 和 IH 协议继续实现。

下面按一次队列使用过程划分当前职责，箭头表示调用或访问：

```text
上层调用者：实验程序，或以后接入的运行时
  ├─ 申请内存、建立队列、创建事件、等待和释放
  │    ↓
  │  HSAKMT 风格用户态接口库
  │    ↓ ioctl / mmap
  │  Linux 内核驱动
  │    ├─ 分配和记录资源，管理 MQD、Doorbell、内核事件
  │    ├─ 经管理队列请求 CP 建立、卸载用户队列
  │    └─ 消费 IH，保存错误并唤醒等待者
  │
  └─ 准备参数与 Signal、填写 AQL、发布 Header、写 Doorbell
       → CP 取包并派发 → 计算执行器 → Signal 与 IH 完成通知
```

<a id="spec-host-task-submit"></a>

调用方继续遵守已确认的多生产者发布规则、完整字段读写、可见性和对象寿命条件。Signal 的读取判断、约 `200 μs` 主动检查后进入内核事件等待，按[第 2.5.1 节](#spec-signal-blocked-wait)执行；HSAKMT 层提供事件等待，任务完成仍由调用方复查 Signal。逐 Dispatch 发布不增加 `LAUNCH` ioctl。原同步计算路径仍只用于独立回归。

**9.7.1～9.7.4 已于 2026-10-18 统一确认，功能尚待实现和验证。** AMD 函数名用于定位参考接口，不表示已经采用其完整签名或二进制布局。本节确定操作、输入输出和资源归属；正式符号名、ioctl 编号、结构体布局与锁的实现集中在接入时落实。当前不承诺原版 libhsakmt 或 ROCr 可以直接替换、链接运行；保留既定物理地址、VRAM 偏移、32 位队列进度及自定义描述对象等实验约定。

<a id="spec-hsakmt-device"></a>

**9.7.1 设备连接、能力查询与返回状态**

调用方先取得访问驱动的连接，再申请内存、队列和事件。本项规定连接管理、查询内容和调用结果。

**[DESIGN] 已确认：**

1. 提供打开、关闭、接口版本查询和必要设备信息查询，参考 `hsaKmtOpenKFD()`、`hsaKmtCloseKFD()`、`hsaKmtGetVersion()` 与 `hsaKmtGetNodeProperties()`。连接当前教学设备，不建立完整的多设备拓扑或 HSA Agent 体系。版本不匹配时明确拒绝操作，不按未知布局继续解释数据。
2. 同一进程的多个线程共用库连接及其内核上下文，库内重复打开按引用计数管理。不同进程分别建立上下文；所有进程仍共享全设备两个用户队列名额。内存、队列和事件标识只在所属上下文中使用，不作为物理地址或 HQD 槽号。跨进程传递、继承并继续使用对象的能力留作扩展，当前仍须遵守旧映射及引用未结束时不复用资源的条件。
3. 查询返回接口版本、VRAM 总量与普通分配范围、保留区、最大用户队列数、AQL 包大小、Ring 容量范围、地址与进度位宽，以及实际支持的功能。取值来自本规格已确认的能力，不额外模拟 AMD 的全部设备属性。
4. 内核处理函数采用 `0` 或负 `errno`，用户态库参考 `HSAKMT_STATUS` 转换为状态枚举。必要状态包括成功、参数或句柄非法、版本不匹配、内存不足、资源名额不足、暂不可用、不支持、等待超时及一般失败。名额已满对应 `OUT_OF_RESOURCES`；正常释放前仍有已知使用者对应 `UNAVAILABLE`；事件等待超时对应 `WAIT_TIMEOUT`。设备管理结果码、队列首次错误码和接口状态分别保存，不直接把同一个数值跨层解释；原始诊断信息可另行查询。

重复打开对应的关闭只减少连接引用；最后一次正常关闭前，调用方先停止提交并完成队列、事件和内存的释放。仍有可见存活对象时，最后一次关闭返回暂不可用，保留连接。进程直接退出或绕过库关闭设备文件时，由驱动执行已有清理与保留规则；不能确认设备访问结束的资源继续保留，强制恢复仍为后续扩展。

> **[SOURCE]** ROCr 固定版本 `ba56a24c6132c5d195686ae4adf969ca1222fbba`：[libhsakmt/include/hsakmt/hsakmt.h](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/include/hsakmt/hsakmt.h:35:1) 的 [35–116 行](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/include/hsakmt/hsakmt.h:35:1)定义打开、关闭、版本和设备属性查询；[hsakmttypes.h](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/include/hsakmt/hsakmttypes.h:92:1) 的 [92–124 行](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/include/hsakmt/hsakmttypes.h:92:1)定义 `HSAKMT_STATUS`。本节借鉴接口分工与状态分类，连接管理和支持子集以本实验约定为准。

<a id="spec-hsakmt-memory"></a>

**9.7.2 内存申请、CPU 映射与设备访问地址**

调用方需要先取得能够保存 Ring、参数、Signal 或 Kernel 数据的存储，再把相应地址填入管理请求或 AQL。本项规定分配输入、返回对象与地址含义，以及释放前提。

**[DESIGN] 已确认：**

1. 分配接口参考 `hsaKmtAllocMemory()`、`hsaKmtFreeMemory()`，第一版只区分 **Host 共享内存**和 **VRAM**。输入保存位置、字节数和所需对齐；实际区间由驱动选择。Host 共享内存用于 Ring、进度、参数和 Signal 等；VRAM 用于代码、描述对象和数组。驱动继续统一管理前 60 MiB VRAM，并排除已经确定的保留范围。暂不增加任意用户内存注册、按用户指定物理地址分配或完整 GPUVM 映射。
2. 分配成功返回内存对象句柄、实际大小及相应访问资料。句柄供驱动查找对象；Host 对象另返回 CPU 映射所需的信息及完整的 64 位 Host 物理基址，VRAM 对象返回 VRAM 字节偏移。库通过 `mmap` 建立 Host CPU 可用的映射入口。CPU 映射入口、软件句柄、Host 物理地址与 VRAM 偏移分别表示，不合并成含义不明的“设备地址”。
3. 驱动管理请求引用“内存对象句柄＋对象内偏移”，驱动检查归属、对齐和完整范围后取得实际地址。AQL 必须按已确认的字段规则填写，因此调用方可以取得自己对象的 Host 物理地址或 VRAM 偏移；这些数值由驱动分配后返回，不由调用方任意指定。Signal、参数等小对象可以在已分配的共享块内布置，不要求每个对象独占一页，具体分块算法不在本节设计。
4. 释放时，调用方必须先结束相关任务使用；驱动检查已知的队列、事件、映射及在途请求引用。仍被使用时返回暂不可用，不能回收到分配器后交给新对象。库负责解除自己建立且不再使用的映射，其他尚未结束的引用继续阻止底层存储回收或复用。驱动不通过解析不透明 Kernel 参数来猜测全部数据依赖，调用方也不能仅凭等待超时或错误返回就请求释放活动任务的数据。

以下示例只说明返回资料的不同用途：

```text
驱动分配一个 Host 共享内存对象
  ├─ 内存句柄 H           → 后续驱动请求据此查找对象
  ├─ CPU 映射入口         → Host CPU 填写参数或 AQL
  └─ Host 物理基址
       0x1_9000_0000
         + 对象内偏移 0x2000
         = 0x1_9000_2000   → 填入 kernarg_address

驱动分配一个 VRAM 对象
  ├─ 内存句柄 V           → 用于管理分配、拷贝与释放
  └─ VRAM 字节偏移        → 填入 Kernel 描述对象或参数字段
```

已有上传和读回能力继续作为实验的数据拷贝通路，不归入新的 Launch 接口。拷贝与释放按具体对象是否仍被访问来判断；Queue 存在本身不禁止读回已经完成的结果。当前按 DMA 直通配置分配设备可访问的存储，暂不单设 GPU 地址映射、解除映射接口；Host CPU 映射仍通过 `mmap` 建立。当前没有用户选定的 GPU 虚拟地址，不能照搬 AMD 分配结构中的 `va_addr` 含义。

> **[SOURCE]** ROCr 固定版本 `ba56a24c6132c5d195686ae4adf969ca1222fbba`：[hsakmt.h](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/include/hsakmt/hsakmt.h:414:1) 的 [414–452 行](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/include/hsakmt/hsakmt.h:414:1)定义分配与释放接口。Linux 固定版本 `248951ddc14de84de3910f9b13f51491a8cd91df`：[include/uapi/linux/kfd_ioctl.h](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/linux/include/uapi/linux/kfd_ioctl.h:430:1) 的 [430–458 行](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/linux/include/uapi/linux/kfd_ioctl.h:430:1)区分大小、分配句柄、映射信息及虚拟地址。本实验参考对象管理方式，Host 物理地址和 VRAM 偏移仍按[第 2.4 节](#spec-address-values)解释。

<a id="spec-host-queue-create"></a>
<a id="spec-hsakmt-queue"></a>

**9.7.3 队列创建、资源返回、查询与销毁**

调用方已经取得 Ring 和进度存储，现在请求驱动建立一条用户队列。本项规定创建输入、成功返回的资源，以及调用方、接口库和驱动各自的销毁步骤。

**[DESIGN] 已确认：**

1. 创建接口参考 `hsaKmtCreateQueue()`，传入 Ring 的内存句柄、对象内偏移和字节容量，以及保存 R、W 的共享对象句柄与偏移。实际内存仍由驱动通过上一项分配。容量明确传入，沿用 **64 字节～64 KiB、2 的幂**，`0` 非法；不在该底层接口规定默认 4 KiB。第一版只创建用户 AQL Queue，KIQ、HIQ 由驱动初始化路径管理，VMID 固定为 0，不增加优先级等可选策略。
2. 驱动校验资源并取得引用，内部准备 MQD，经 HIQ 提交映射及后附完成命令。CP 继续选择空闲用户槽位；驱动确认管理结果成功后才交付可用队列。两个名额已满时返回资源不足。失败时不交付有效队列标识；已经交给设备的存储须按既有失败回收条件保留或清理，不能仅因创建调用失败就释放。
3. 成功返回软件队列标识和 Doorbell 映射资料。库据此建立 CPU 可访问的门铃入口；映射定位信息与映射内入口的字节偏移分别保存，不与 HQD 中按 4 字节编码的 BAR4 偏移混淆。Ring 和进度对象继续由调用方持有，驱动保持必要引用。软件队列标识用于后续管理，与 HQD 槽位编号分开；MQD 地址仍是驱动与 CP 之间的配置，普通调用方不管理 MQD。
4. 提供最小队列状态查询，返回是否可用、卸载中或故障，以及驱动保存的首次错误和必要的管理诊断。用户态通过队列标识查询，不直接选槽读取 HQD，也不通过查询清除错误。驱动继续通过 MQD 地址关联 IH 记录和队列对象；故障范围、首次记录和资源保留沿用第 7 节。
5. 销毁接口参考 `hsaKmtDestroyQueue()`，由调用方先停止生产、完成已开始的发布，并按正常卸载协议等待任务结束和 `R == W`。库不遍历任务或自动执行高层 Signal 同步。驱动在接受正常卸载前复核队列进度，未排空时返回暂不可用、保持原队列；接受后经 HIQ 卸载，确认设备访问结束、MQD 保存和解绑成功，再完成收尾。故障队列按 9.6 的清理规则处理，不要求先排空。

队列销毁成功后，驱动释放本队列对调用方 Ring、进度对象的引用，库解除自己建立的 Doorbell 映射；调用方另行释放或复用自己的内存。旧通知、旧映射或驱动后续处理尚未结束时，相关资源不能提前复用。已接受的卸载请求若超时或故障，保留队列记录与必要资源，不重复提交原卸载命令，也不自动复位设备。具体管理等待机制沿用[第 4.3 节](#spec-management-marker)。

```text
调用方经内存接口取得 Ring 和进度存储
  → 创建队列：传入这些对象的句柄、偏移与容量
  → 驱动准备 MQD，经 HIQ 请求映射
  → CP 选择空闲槽位并装载
  → 驱动确认成功，返回队列标识及 Doorbell 映射资料

调用方停止提交，按正常协议排空后请求销毁
  → 驱动经 HIQ 请求卸载
  → CP 结束访问、保存 MQD、解除绑定
  → 驱动和库完成相应收尾
  → 调用方按各对象的寿命条件另行释放内存
```

> **[SOURCE]** ROCr 固定版本 `ba56a24c6132c5d195686ae4adf969ca1222fbba`：[hsakmt.h](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/include/hsakmt/hsakmt.h:322:1) 的 [322–380 行](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/include/hsakmt/hsakmt.h:322:1)定义队列创建与销毁；[libhsakmt/src/queues.c](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/queues.c:703:1) 的 [703–750 行](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/queues.c:703:1)组织 Ring、读写指针等参数，提交 ioctl 并返回队列与 Doorbell 资料。Linux 固定版本 `248951ddc14de84de3910f9b13f51491a8cd91df`：[kfd_ioctl.h](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/linux/include/uapi/linux/kfd_ioctl.h:73:1) 的 [73–102 行](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/linux/include/uapi/linux/kfd_ioctl.h:73:1)保存创建输入及返回的队列编号、Doorbell 映射信息。调用方排空与本实验卸载顺序以[第 7.4 节](#spec-unmap-drain)为准。

<a id="spec-host-task-wait"></a>
<a id="spec-hsakmt-event"></a>

**9.7.4 事件创建、等待、错误交付与资源收尾**

调用方需要把一个任务的完成 Signal 与内核等待事件关联，才能在任务未完成时睡眠。本项确定接口如何返回通知资料，以及驱动怎样把队列故障交给相关等待者。

**[DESIGN] 已确认：**

1. 提供事件创建、状态查询、等待和销毁，参考 `hsaKmtCreateEvent()`、`hsaKmtQueryEventState()`、`hsaKmtWaitOnEvent()`、`hsaKmtDestroyEvent()`。第一版只提供本实验完成通知所需的事件，初始状态为未通知；等待返回不消费通知状态，同一事件可以有多个等待者。事件编号、通知槽大小及通知标记沿用[第 2.5 节](#spec-signal-representation)，不增加应用主动设置、复位事件的通用接口。
2. 创建事件时，驱动返回事件标识及通知槽的完整 Host 物理地址。调用方在自己的共享 Signal 中填写 `event_id`、`event_mailbox_ptr`，并在提交前置 `value = 1`。Signal 存储继续由所属应用上下文管理；库不自动为每次 Dispatch 创建高层完成对象。通知槽由驱动分配、CP 写入、驱动按协议清零，普通调用方不直接修改通知槽。
3. 创建事件时登记本次使用的源队列标识，要求队列属于本上下文且可用。驱动保存“队列 → 相关事件”的软件关联；队列故障时，对尚未通知的关联事件保存错误，使等待以失败结束，已通知的事件保留完成状态。晚于故障到来的等待也检查已保存状态，不继续睡眠。这是本实验接口的补充，不是 AMD `hsaKmtCreateEvent()` 原有的队列参数，也不增加 Signal、MQD 或 HQD 字段。事件分配仍归应用上下文；队列卸载后，已完成事件及其软件记录可继续保留到调用方销毁，不因此占住已归还的 HQD 槽位。本阶段一次事件使用关联一条队列，完成并满足回收条件后再销毁重建，不增加跨队列重绑操作。
4. 等待输入为事件标识和 32 位无符号毫秒超时。`0` 表示只检查当前状态，`UINT32_MAX` 表示无调用方设定的等待上限，其余值为本次事件等待的总时限。已通知时返回成功；期限到达返回 `WAIT_TIMEOUT`；源队列或设备故障导致等待无法继续时返回 `WAIT_FAILURE`。库等待的是内核事件；返回成功后，调用方仍须复查 Signal 并执行已确认的读取同步，才能使用任务结果。事件查询不进入睡眠，返回未通知、已通知或失败状态及已保存的错误原因；队列标识仍有效时，也可以查询队列诊断。这里的查询结果由本实验定义；固定版本 `hsaKmtQueryEventState()` 只有连接、空指针检查，随后返回成功，不能照搬它判断实际通知状态。
5. 默认 Signal 等待仍由调用方从本次等待开始主动检查约 `200 μs`，之后将剩余时间交给事件等待，唤醒后复查。库内部不再重复主动检查 `200 μs`；重复唤醒也不重置原 Signal 等待的总时限。等待超时只结束本次等待，事件、Signal 和任务继续保留；等待故障不会使驱动补写成功 Signal。

```text
调用方已取得 Queue 与共享 Signal 存储
  → 请求创建事件，并登记源 Queue
  → 驱动建立事件、通知槽及源队列关联
  → 返回 event_id 和通知槽 Host 物理地址
  → 调用方填写 Signal，并把 Signal 引用写入 AQL

正常完成：CP 更新 Signal、通知槽，提交 IH 通知
  → 驱动找到所属进程与事件，保存已通知状态并唤醒
  → 事件等待返回，调用方复查 Signal

队列故障：驱动按 IH 记录找到 Queue 并保存错误
  → 该 Queue 的相关事件等待以失败结束
  → 调用方取得错误，资源按既定条件保留或清理
```

<a id="spec-host-object-release"></a>

事件销毁及内存回收继续遵守已确认的对象寿命条件。调用方先结束任务和其他线程对对象的使用；仍有在途设备访问、等待者、旧通知或驱动后续处理时，销毁返回暂不可用，保留对象。驱动需要的关联记录保留到最后一次使用结束；不能因为 Signal 已为 0、HQD 的 ACTIVE 已清零，或一个等待调用已经返回，就提前复用事件编号、通知槽、MQD 地址和 Doorbell 入口。

正常退出时，调用方停止生产、完成任务与结果处理，再按依赖关系销毁队列和事件、释放内存，最后关闭连接。进程异常退出后的强制中止、旧映射强制撤销、设备复位和自动恢复，继续放在[后续扩展](<./QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)；当前必须保留尚不能安全回收的资源。上层 Signal API、自动任务回收、参数复制和完整 ROCr 运行时不在本节定义。

> **[SOURCE]** ROCr 固定版本 `ba56a24c6132c5d195686ae4adf969ca1222fbba`：[hsakmt.h](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/include/hsakmt/hsakmt.h:177:1) 的 [177–244 行](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/include/hsakmt/hsakmt.h:177:1)定义事件创建、查询、等待和销毁；[libhsakmt/src/events.c](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/events.c:51:1) 的 [51–145 行](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/events.c:51:1)向 KFD 创建事件，并保存返回的事件编号和通知槽信息；同文件 [213–221 行](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/rocr-runtime/libhsakmt/src/events.c:213:1)中的 `hsaKmtQueryEventState()` 未读取实际事件状态。Linux 固定版本 `248951ddc14de84de3910f9b13f51491a8cd91df`：[kfd_ioctl.h](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/linux/include/uapi/linux/kfd_ioctl.h:289:1) 的 [289–305 行](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/linux/include/uapi/linux/kfd_ioctl.h:289:1)定义事件创建资料，[363–371 行](vscode://file/home/book/1.project/gpu_study/2.%E6%BA%90%E7%A0%81/linux/include/uapi/linux/kfd_ioctl.h:363:1)定义事件等待输入与结果。原始接口和实验补充分别按上述说明使用，具体通知与错误处理仍以本规格第 7 节为准。
