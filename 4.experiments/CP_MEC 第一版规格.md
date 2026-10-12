# CP/MEC 第一版规格

| 缩写 | 英文全称                          | 中文含义                           |
| ---- | --------------------------------- | ---------------------------------- |
| CP   | Command Processor                 | 命令处理器                         |
| MEC  | Micro Engine Compute              | 计算命令处理微引擎                 |
| HQD  | Hardware Queue Descriptor         | 硬件队列描述；用于保存队列驻留状态 |
| MQD  | Memory Queue Descriptor           | 内存中的队列描述对象               |
| KIQ  | Kernel Interface Queue            | 内核接口队列                       |
| HIQ  | HSA Interface Queue               | HSA 接口队列                       |
| HSA  | Heterogeneous System Architecture | 异构系统架构                       |
| AQL  | Architected Queuing Language      | HSA 定义的队列包格式与提交协议     |
| PCIe | Peripheral Component Interconnect Express | 高速外设互连总线 |
| BAR | Base Address Register | PCIe 基址寄存器；用于描述设备资源窗口 |
| QEMU | Quick Emulator | 仿真与虚拟化工具 |
| CPU | Central Processing Unit | 中央处理器 |
| RV32 | 32-bit RISC-V | 本版 CP 使用的原生 32 位 RISC-V 模型 |
| PMU | Platform Management Unit | 平台管理单元；后续裸机事件循环参考 ZynqMP PMU Firmware |
| TCG | Tiny Code Generator | QEMU 的动态代码生成基础设施 |
| VRAM | Video RAM | 教学设备的显存后备存储 |
| RAM | Random Access Memory | 随机存取存储器；Host RAM 与设备 VRAM 分开 |
| DMA | Direct Memory Access | 直接内存访问 |
| IOMMU | Input/Output Memory Management Unit | 输入输出内存管理单元 |
| SMMUv3 | System Memory Management Unit version 3 | Arm 系统内存管理单元第三版 |
| MSI-X | Message Signaled Interrupts Extended | 扩展消息中断 |
| PC | Program Counter | 程序计数器，保存取指地址 |
| GC | Graphics and Compute | AMD 图形与计算模块；本清单采用 GC 9.4.3 寄存器定义 |
| VMID | Virtual Memory Identifier | 虚拟地址空间标识；用于选择设备地址翻译上下文 |
| IB | Indirect Buffer | 间接命令缓冲区，由队列中的命令引用 |
| EOP | End of Pipe | 执行结束相关处理；本清单涉及其缓冲区、指针与状态 |
| GDS | Global Data Share | 全局数据共享；本清单涉及相关资源状态寄存器 |
| IQ | 未核实 | 寄存器名称中的内部对象缩写；其英文展开与处理流程待核实 |
| RPTR | Read Pointer | 读指针，记录队列或缓冲区的消费进度 |
| WPTR | Write Pointer | 写指针，记录队列或缓冲区的生产进度 |

## 1. 已确定的槽位分工

**[DESIGN]** 第一版设置 4 个 HQD 槽位，分别用于 1 个 KIQ、1 个 HIQ 和 2 个用户 AQL Queue。

```text
4 个 HQD 槽位
  ├─ KIQ：1 个
  ├─ HIQ：1 个
  ├─ AQL Queue A：1 个
  └─ AQL Queue B：1 个
```

这里的槽位指保存队列驻留状态的位置；HIQ 是其中一条队列的名称。

### 1.1 HQD 保存队列状态，CP 访问并处理队列命令

**[DESIGN]** 每个 HQD 槽位是一组寄存器，四个槽位组成保存四条队列状态的寄存器数组。每组保存对应 Queue 的 Ring 地址、容量、读写进度和启用状态等信息；命令包保存在 Ring 中。

**CP 是这份队列状态的使用者：CP 访问 HQD，根据其中的信息找到 Ring，再读取、解析并处理命令包。** 管理命令与计算任务的处理过程如下：

```text
KIQ/HIQ 中的 MAP_QUEUES 命令
  → CP 解析命令，取得 MQD 地址和队列映射信息
  → 读取 MQD 中的 Ring 地址、容量、索引地址和 Doorbell 配置
  → 将队列配置装入目标 HQD 槽位
  → 建立目标队列的驻留状态

用户 AQL 队列中的 Kernel Dispatch Packet
  → CP 解析包，取得任务规模、参数地址和完成 Signal
  → 根据 kernel_object 读取 Kernel 描述对象，取得代码入口和资源要求
  → 准备并派发 kernel，让计算单元执行
```

向 KIQ／HIQ 写入 `MAP_QUEUES`，称为“提交一条管理命令”；向用户 AQL 队列写入 Kernel Dispatch Packet，称为“提交计算任务”。

**[DESIGN]** 第一版不引入 IB。管理命令和 AQL Packet 直接放入各自的 Ring，CP 从 Ring 读取并处理；本版不实现引用 IB 的间接命令执行。`CP_HQD_IB_BASE_ADDR`、`CP_HQD_IB_BASE_ADDR_HI`、`CP_HQD_IB_RPTR` 和 `CP_HQD_IB_CONTROL` 均不采用。KIQ、AQL 与 IB 的关系及取舍依据见[第一版不引入 IB](<./CP_MEC 第一版寄存器定义.md#7-第一版不引入-ib>)。

HQD 的填充分为两个阶段：

- **建立首个管理入口时，由 Host 填充。** Host 直接配置 KIQ 对应的 HQD，使设备能够找到 KIQ Ring。
- **后续由 CP 按管理命令填充。** Host 准备内存中的 MQD，并通过 KIQ／HIQ 提交相应管理命令；CP 读取描述信息，建立目标队列的 HQD 状态。

队列运行期间，CP 使用并维护队列进度。HQD 保存状态，CP 执行固件、处理队列命令，计算执行器执行 kernel。

### 1.2 固定轮流选择与阻塞执行

**[DESIGN]** 第一版由裸机 CP 固件按固定规则选择队列：每轮先检查 KIQ、HIQ，各处理至多一条可处理的管理命令，再轮流检查 A、B。每次提交一个完整 Dispatch，阻塞等待计算执行器完成，处理结果后再选择下一条队列；不在执行中途抢占。未激活或没有可处理命令的队列直接跳过。等待计算完成期间，CP 暂不处理其他队列，包括 KIQ、HIQ。

本版暂不采用 `CP_HQD_PERSISTENT_STATE`、`CP_HQD_PIPE_PRIORITY`、`CP_HQD_QUEUE_PRIORITY` 和 `CP_HQD_QUANTUM`。完整流程、限制与后续扩展见[队列选择与调度扩展说明](<./CP_MEC 第一版寄存器定义.md#5-第一版队列选择与后续调度扩展>)；后续裸机事件循环参考 AMD/Xilinx ZynqMP PMU Firmware。这里确认的是实现方案，队列功能仍待接入和验证。

**[DESIGN]** 第一版也不采用 `CP_HQD_IQ_TIMER` 和 `CP_HQD_IQ_RPTR`。等待计算完成由 CP 固件轮询执行器状态实现，本版不建立 IQ 命令缓冲区或维护 IQ 读取进度。以后可先用裸机事件循环和固件内存中的状态推进等待任务；是否需要独立的 IQ 硬件机制及寄存器，按实际需求另行确认。当前等待流程、限制与扩展条件见[第一版不引入 IQ](<./CP_MEC 第一版寄存器定义.md#8-第一版不引入-iq>)。

## 2. 远端设备与 CP 固件启动

**[DESIGN]** 本轮先让 A57 Linux 通过 PCIe 代理访问远端设备，并装载、启动和替换 CP 固件。CP 使用 QEMU 原生 `rv32` 模型，由 TCG 执行；现有计算解释器继续执行应用 kernel。本轮只接入复位、入口和基本固件运行，队列、Doorbell 事件和 CP 派发接口另行讨论。

```text
进程 A：A57 Linux
  └─ vfio-user-pci 代理
       ├─ 配置空间与 BAR 请求 ──────────→ 进程 B：gpgpu-cp
       │                                  ├─ gpu0：寄存器、VRAM、DMA、中断
       │                                  ├─ 原有 RV32 计算解释器
       │                                  └─ 原生 RV32 CP（默认保持复位）
       ├─ PCI DMA 接口 ←── B 的 DMA 请求       │
       │     └─ SMMUv3（启用时）→ Host RAM     └─ 地址 0 起映射同一份 VRAM
       └─ Linux 中断处理 ←── B 的 MSI-X 通知
```

`none` 与 `smmuv3` 都采用消息 DMA：B 请求访问设备 DMA 地址，A 调用代理设备的 PCI DMA 接口，再返回数据或错误。SMMUv3 的翻译、权限检查和故障记录发生在 A。启动选项 `x-dma-via-socket=on` 控制传输方式，不增加硬件寄存器。原单进程入口继续使用现有设备。

### 2.1 Host 与 CP 访问同一份 VRAM

CP 地址 `0～vram_size-1` 对应 VRAM 的相同字节偏移。Host 通过 BAR2 访问这份存储；例如固件入口在 VRAM 偏移 `0x1000`，Host 写 `BAR2 基址 + 0x1000`，CP 从地址 `0x1000` 取指。Host 的 BAR 总线地址不能直接填入 CP 入口寄存器。

本轮不新增私有存储，也不永久划出固件分区。固件测试与原软件栈测试分别运行，并各自明确代码和结果地址。BAR 写入、DMA 写入、计算解释器写入和冷复位清零都应使对应 TCG 指令翻译失效，支持在相同地址替换固件。

### 2.2 BAR0 控制寄存器

`0x0500 CP_CTRL` 与 `0x0504 CP_RESET_VECTOR` 都采用对齐、小端的 32 位访问。

`CP_CTRL` 的 bit 0 是可读写的 `RESET_HOLD`，默认 1；bit 1 是只读的 `PRESENT`。连接 CP 的设备默认读回 3，解除复位后读回 2。写入相同复位状态不会重新启动 CPU，保留位读零、写入忽略，`PRESENT` 的写入也忽略。置位 `RESET_HOLD` 恢复 CP 的原生复位状态，并持续阻止取指；清零后从已配置的入口运行。

`CP_RESET_VECTOR` 保存 CP 地址空间中的 32 位入口，默认 0。只有保持复位时可以修改；入口必须位于 VRAM 内且按 2 字节对齐。有效修改同步更新 CPU 的复位向量和复位态 PC。非法地址或运行期间修改入口会保留原值，并置位已有 `ERROR_STATUS.INVALID_CMD`。

没有连接 CP 的单进程设备对这两个寄存器读零、写入忽略。

### 2.3 固件装载与复位顺序

```text
Host 写 CP_CTRL.RESET_HOLD = 1，读回确认
  → 经 BAR2 写入固件和所需数据
  → 写 CP_RESET_VECTOR
  → 执行访问屏障，读回确认写入完成
  → 写 CP_CTRL.RESET_HOLD = 0
  → CP 从指定入口执行，把结果写回 VRAM
  → Host 经 BAR2 读取结果
```

复位与启动在目标 CPU 线程中同步完成。`GLOBAL_CTRL.ENABLE` 只控制原有设备功能；CP 通过自己的控制位解除复位。

CP 单独复位保留 VRAM、入口，以及原 DMA、派发和中断状态。`GLOBAL_CTRL.RESET` 复位设备状态并使 CP 回到保持复位、入口为 0 的默认值，VRAM 保留。设备冷复位先停止 CP，再清零 VRAM 并恢复全部默认状态。

**[BOUNDARY]** 双进程模式本版不支持断线重连和迁移。CP 目前只访问设备本地 VRAM，尚未接入异步 Host DMA、队列或计算派发。以上接口属于 QEMU 教学设备，不能作为 MI300X 的寄存器或内部核实现结论。

2026-10-11 的基础实现与测试结果见 [远端设备与 CP 验收记录](<./远端 GPGPU 与 RISC-V CP 验收记录.md>)。队列功能的完成状态仍按实验大纲记录。

### 2.4 配置并激活 KIQ 后启动 CP

**[DESIGN]** 队列功能接入后，采用先配置并激活 KIQ、再启动 CP 的顺序。在第 2.3 节的固件启动流程中，Host 应在解除 CP 复位前完成 KIQ 配置：

```text
Host 保持 CP 复位（CP_CTRL.RESET_HOLD = 1）
  → 装载固件，设置 CP_RESET_VECTOR
  → 准备 KIQ Ring 和相关内存，保持 KIQ 槽位 ACTIVE = 0
  → 填写 KIQ 对应的 HQD，保证配置和内存初始化对 CP 可见
  → 最后设置 KIQ 槽位 ACTIVE = 1
  → 解除 CP 复位（CP_CTRL.RESET_HOLD = 0）
  → CP 固件检查 KIQ 槽位的 ACTIVE，再检查并处理可用命令
```

这里的 KIQ 就绪，是指 Host 已准备好 Ring，并完成 HQD 配置和激活。CP 固件在 `ACTIVE = 0` 时暂不处理该队列，在 `ACTIVE = 1` 时检查是否有可处理的命令；Ring 可以暂时为空，CP 启动后等待后续提交。完整启动图和 AMD 参考事实见[队列激活状态说明](<./CP_MEC 第一版寄存器定义.md#2-队列激活状态>)。无需额外增加“通知 CP 检查 KIQ 配置”的寄存器；其余 HQD 字段和访问方式继续在后续条目中讨论。

## 3. 后续讨论与补充

以下为待讨论清单。逐项讨论，经用户确认后，将结论补入本文的已确定规格，并删除对应条目。

1. **HQD 的具体字段和访问方式。** 确定每个槽位的其余字段、Host 选择槽位的方式、CP 的访问方式，以及各字段由谁读取和更新。首次 KIQ 的配置与激活顺序已在第 2.4 节确定。AMD 参考清单见[第 3.1 节](#31-amd-gc-943-队列装载寄存器清单)，按行记录是否采用。

2. **KIQ／HIQ 管理命令的最小接口。** 确定 `MAP_QUEUES` 等所需命令携带的信息、目标槽位的选择方式，以及成功或失败的报告方式。Host 需要能够判断新队列何时可用。

3. **CP 的取包地址与发布规则。** 确定 Ring、MQD、参数的存储位置和地址类型，读写索引的推进方式，以及 Doorbell 与队列的对应关系。明确 CP 怎样判断包已准备好，避免读取尚未写完的内容。`CP_HQD_VMID` 已确定采用；实验支持多少个 VMID 上下文（“槽位”），待 MEC 规格确定后再讨论，见[队列地址空间标识说明](<./CP_MEC 第一版寄存器定义.md#3-队列地址空间标识>)。

4. **CP 与计算执行器的交接。** 补入已讨论的“保留现有分发寄存器及 PCIe BAR 映射，正常任务改由 CP 访问”约定。队列选择与阻塞等待规则已在第 1.2 节确定；进一步明确提交、忙、完成与错误状态的接口，以及执行结果怎样返回 CP 并更新 Signal。

5. **队列停止和出错后的收尾。** 确定 Host 的停止请求、CP 不再访问队列的确认方式，以及命令非法或计算失败时的结果报告。明确队列内存何时可以释放。

### 3.1 AMD GC 9.4.3 队列装载寄存器清单

本节列出 AMD GC 9.4.3 驱动装载 HQD 时使用的连续寄存器区间，供后续逐行讨论本实验的取舍。表中“采用/不采用”一列记录已确认的决定；留空表示尚未决定。

“详细说明”列链接到[第一版寄存器定义](<./CP_MEC 第一版寄存器定义.md>)中的对应小节，保存讨论中的解释与图示；尚未补充说明的行先留空。

区间从 `CP_MQD_BASE_ADDR`（`0x1245`）到 `CP_HQD_AQL_DISPATCH_ID_HI`（`0x127f`），共 59 个 32 位位置、236 字节，包含保留位置和同址别名。“AMD 偏移”是寄存器段内以 32 位字为单位的偏移；“槽内偏移”是相对于区间起点换算出的字节偏移：

```text
槽内偏移 =（AMD 偏移 − 0x1245）× 4
```

例如 `CP_HQD_PQ_CONTROL` 的 AMD 偏移为 `0x1256`，换算后的槽内偏移为 `0x044`。

表中的主 Ring 是软件提交命令的环形缓冲区，IB 是命令引用的间接命令缓冲区，EOP 指执行结束相关处理。

**[BOUNDARY]** 部分寄存器只公开了字段名称，缺少完整行为说明。这些条目标注“待核实”，表示其具体用途或行为仍需核对；该标记不代替“采用/不采用”的决定。

| AMD 偏移 | 槽内偏移 | 寄存器原名 | 中文名称与用途 | 采用/不采用 | 详细说明 |
|---|---|---|---|---|---|
| `0x1245` | `0x000` | `CP_MQD_BASE_ADDR` | MQD 基址低位：保存内存中队列描述对象的地址低位，供设备定位 MQD。 | 采用 | [MQD 基址](<./CP_MEC 第一版寄存器定义.md#1-mqd-基址>) |
| `0x1246` | `0x004` | `CP_MQD_BASE_ADDR_HI` | MQD 基址高位：与前一个寄存器共同确定 MQD 地址。 | 采用 | [MQD 基址](<./CP_MEC 第一版寄存器定义.md#1-mqd-基址>) |
| `0x1247` | `0x008` | `CP_HQD_ACTIVE` | 队列激活状态：标记该槽位中的队列是否已启用；激活后仍需检查是否有可处理的命令，AMD 驱动卸载队列时也会检查此状态。 | 采用 | [队列激活状态](<./CP_MEC 第一版寄存器定义.md#2-队列激活状态>) |
| `0x1248` | `0x00c` | `CP_HQD_VMID` | 队列地址空间标识：保存队列及 IB 使用的虚拟地址空间编号等信息，供设备选择地址翻译上下文。 | 采用 | [队列地址空间标识](<./CP_MEC 第一版寄存器定义.md#3-队列地址空间标识>) |
| `0x1249` | `0x010` | `CP_HQD_PERSISTENT_STATE` | 队列持久状态与控制：包含预加载请求、预加载量，以及队列切换、恢复和重新启动 wave 等相关字段。 | 不采用 | [取舍与执行方案](<./CP_MEC 第一版寄存器定义.md#5-第一版队列选择与后续调度扩展>) |
| `0x124a` | `0x014` | `CP_HQD_PIPE_PRIORITY` | 管线优先级：保存管线层面的调度优先级配置。 | 不采用 | [取舍与执行方案](<./CP_MEC 第一版寄存器定义.md#5-第一版队列选择与后续调度扩展>) |
| `0x124b` | `0x018` | `CP_HQD_QUEUE_PRIORITY` | 队列优先级：保存这条队列的调度优先级配置。 | 不采用 | [取舍与执行方案](<./CP_MEC 第一版寄存器定义.md#5-第一版队列选择与后续调度扩展>) |
| `0x124c` | `0x01c` | `CP_HQD_QUANTUM` | 调度时间片控制：配置时间片的使能、尺度和持续长度，并包含时间片活动状态。 | 不采用 | [取舍与执行方案](<./CP_MEC 第一版寄存器定义.md#5-第一版队列选择与后续调度扩展>) |
| `0x124d` | `0x020` | `CP_HQD_PQ_BASE` | 主 Ring 基址编码低位：用于定位命令 Ring；驱动将 Ring 字节地址右移 8 位后填写。 | 采用 | [Ring 的定位与命令消费](<./CP_MEC 第一版寄存器定义.md#61-ring-的定位与命令消费>) |
| `0x124e` | `0x024` | `CP_HQD_PQ_BASE_HI` | 主 Ring 基址编码高位：与前一个寄存器共同保存 Ring 基址编码。 | 采用 | [Ring 的定位与命令消费](<./CP_MEC 第一版寄存器定义.md#61-ring-的定位与命令消费>) |
| `0x124f` | `0x028` | `CP_HQD_PQ_RPTR` | 主 Ring 读指针：保存设备对主 Ring 的消费进度，用于确定后续读取位置。 | 采用 | [读位置与进度存放地址](<./CP_MEC 第一版寄存器定义.md#62-ring-内的读位置与进度存放地址>) |
| `0x1250` | `0x02c` | `CP_HQD_PQ_RPTR_REPORT_ADDR` | 读指针回报地址低位：指定设备把消费进度写回到哪块内存，供软件读取。 | 采用 | [读位置与进度存放地址](<./CP_MEC 第一版寄存器定义.md#62-ring-内的读位置与进度存放地址>) |
| `0x1251` | `0x030` | `CP_HQD_PQ_RPTR_REPORT_ADDR_HI` | 读指针回报地址高位：与前一个寄存器共同确定回报目标地址。 | 采用 | [读位置与进度存放地址](<./CP_MEC 第一版寄存器定义.md#62-ring-内的读位置与进度存放地址>) |
| `0x1252` | `0x034` | `CP_HQD_PQ_WPTR_POLL_ADDR` | 写指针轮询地址低位：指定设备从哪块内存读取软件维护的写指针。 | 采用 | [读位置与进度存放地址](<./CP_MEC 第一版寄存器定义.md#62-ring-内的读位置与进度存放地址>) |
| `0x1253` | `0x038` | `CP_HQD_PQ_WPTR_POLL_ADDR_HI` | 写指针轮询地址高位：与前一个寄存器共同确定写指针的读取地址。 | 采用 | [读位置与进度存放地址](<./CP_MEC 第一版寄存器定义.md#62-ring-内的读位置与进度存放地址>) |
| `0x1254` | `0x03c` | `CP_HQD_PQ_DOORBELL_CONTROL` | 队列 Doorbell 控制：配置 Doorbell 偏移、使能和相关模式，将 Doorbell 通知与该队列关联。 | 采用 | [Doorbell 与 Ring 控制](<./CP_MEC 第一版寄存器定义.md#63-doorbell-与-ring-控制>) |
| `0x1255` | `0x040` | 保留位置 | 保留：寄存器头文件未定义名称，MQD 对应位置也标为保留。 |  |  |
| `0x1256` | `0x044` | `CP_HQD_PQ_CONTROL` | 主 Ring 控制：配置 Ring 容量、读指针回报、写指针模式、执行限制和权限等。 | 采用 | [Doorbell 与 Ring 控制](<./CP_MEC 第一版寄存器定义.md#63-doorbell-与-ring-控制>) |
| `0x1257` | `0x048` | `CP_HQD_IB_BASE_ADDR` | IB 基址低位：保存当前间接命令缓冲区的地址低位，供 CP 继续读取其中的命令。 | 不采用 | [第一版不引入 IB](<./CP_MEC 第一版寄存器定义.md#7-第一版不引入-ib>) |
| `0x1258` | `0x04c` | `CP_HQD_IB_BASE_ADDR_HI` | IB 基址高位：与前一个寄存器共同确定 IB 地址。 | 不采用 | [第一版不引入 IB](<./CP_MEC 第一版寄存器定义.md#7-第一版不引入-ib>) |
| `0x1259` | `0x050` | `CP_HQD_IB_RPTR` | IB 读指针：保存间接命令缓冲区的消费位置。 | 不采用 | [第一版不引入 IB](<./CP_MEC 第一版寄存器定义.md#7-第一版不引入-ib>) |
| `0x125a` | `0x054` | `CP_HQD_IB_CONTROL` | IB 控制：包含 IB 长度、执行禁止、缓存策略、权限和正在处理 IB 等字段。 | 不采用 | [第一版不引入 IB](<./CP_MEC 第一版寄存器定义.md#7-第一版不引入-ib>) |
| `0x125b` | `0x058` | `CP_HQD_IQ_TIMER` | IQ 定时与处理控制：包含等待时间、重试类型、重新计时、中断及处理状态等字段；IQ 的内部处理流程待核实。 | 不采用 | [第一版不引入 IQ](<./CP_MEC 第一版寄存器定义.md#8-第一版不引入-iq>) |
| `0x125c` | `0x05c` | `CP_HQD_IQ_RPTR` | IQ 读位置：保存 IQ 相关读取偏移；对应内部对象及推进规则待核实。 | 不采用 | [第一版不引入 IQ](<./CP_MEC 第一版寄存器定义.md#8-第一版不引入-iq>) |
| `0x125d` | `0x060` | `CP_HQD_DEQUEUE_REQUEST` | 队列卸载／抢占请求：请求排空、复位 wave 或保存 wave 等处理，以卸载队列。 |  |  |
| `0x125e` | `0x064` | `CP_HQD_DMA_OFFLOAD`<br>`CP_HQD_OFFLOAD` | 处理转交控制，同址别名：包含 DMA、AQL、EOP 的 offload 及使能字段；具体转交对象和工作流程待核实。 |  |  |
| `0x125f` | `0x068` | `CP_HQD_SEMA_CMD` | 信号量命令状态：包含重试和结果字段；具体命令握手语义待核实。 |  |  |
| `0x1260` | `0x06c` | `CP_HQD_MSG_TYPE` | 内部消息动作控制：包含动作类型和保存状态标志；消息来源及处理流程待核实。 |  |  |
| `0x1261` | `0x070` | `CP_HQD_ATOMIC0_PREOP_LO` | 原子操作预操作值 0 的低位：保存 `ATOMIC0_PREOP` 相关数据的低 32 位；具体用途待核实。 |  |  |
| `0x1262` | `0x074` | `CP_HQD_ATOMIC0_PREOP_HI` | 原子操作预操作值 0 的高位：与前一个寄存器组成对应的 64 位数据；具体用途待核实。 |  |  |
| `0x1263` | `0x078` | `CP_HQD_ATOMIC1_PREOP_LO` | 原子操作预操作值 1 的低位：保存另一组 `ATOMIC1_PREOP` 相关数据的低 32 位；具体用途待核实。 |  |  |
| `0x1264` | `0x07c` | `CP_HQD_ATOMIC1_PREOP_HI` | 原子操作预操作值 1 的高位：与前一个寄存器组成对应的 64 位数据；具体用途待核实。 |  |  |
| `0x1265` | `0x080` | `CP_HQD_HQ_SCHEDULER0`<br>`CP_HQD_HQ_STATUS0` | 内部队列状态 0，同址别名：状态定义包含队列空闲、卸载状态、卸载重试计数等字段；另有调度器名称。 |  |  |
| `0x1266` | `0x084` | `CP_HQD_HQ_CONTROL0`<br>`CP_HQD_HQ_SCHEDULER1` | 内部队列控制／调度字，同址别名：公开定义只给出整体控制或调度字段，具体行为待核实。 |  |  |
| `0x1267` | `0x088` | `CP_MQD_CONTROL` | MQD 访问控制：配置访问 MQD 使用的地址空间、权限、缓存策略及相关处理控制。 |  |  |
| `0x1268` | `0x08c` | `CP_HQD_HQ_STATUS1` | 内部队列状态 1：扩展状态字；公开定义仅给出 `STATUS` 字段，具体状态含义待核实。 |  |  |
| `0x1269` | `0x090` | `CP_HQD_HQ_CONTROL1` | 内部队列控制 1：扩展控制字；公开定义仅给出 `CONTROL` 字段，具体控制含义待核实。 |  |  |
| `0x126a` | `0x094` | `CP_HQD_EOP_BASE_ADDR` | EOP 缓冲区基址编码低位：定位执行结束相关处理使用的缓冲区。 |  |  |
| `0x126b` | `0x098` | `CP_HQD_EOP_BASE_ADDR_HI` | EOP 缓冲区基址编码高位：与前一个寄存器共同确定 EOP 缓冲区位置。 |  |  |
| `0x126c` | `0x09c` | `CP_HQD_EOP_CONTROL` | EOP 处理控制：包含缓冲区容量、处理使能、取数器暂停、执行限制和相关状态。 |  |  |
| `0x126d` | `0x0a0` | `CP_HQD_EOP_RPTR` | EOP 读指针及取数控制：保存消费进度，同时包含取数器初始化、复位和卸载等待状态等字段。 |  |  |
| `0x126e` | `0x0a4` | `CP_HQD_EOP_WPTR` | EOP 写指针及缓冲状态：保存写入进度，并包含缓冲区空和可用量等信息。 |  |  |
| `0x126f` | `0x0a8` | `CP_HQD_EOP_EVENTS` | EOP 事件状态：记录事件计数，以及计算管线部分刷新是否处于等待状态。 |  |  |
| `0x1270` | `0x0ac` | `CP_HQD_CTX_SAVE_BASE_ADDR_LO` | 上下文保存区基址低位：指定队列执行状态保存到哪块内存，用于保存与恢复执行上下文。 |  |  |
| `0x1271` | `0x0b0` | `CP_HQD_CTX_SAVE_BASE_ADDR_HI` | 上下文保存区基址高位：与前一个寄存器共同确定保存区地址。 |  |  |
| `0x1272` | `0x0b4` | `CP_HQD_CTX_SAVE_CONTROL` | 上下文保存控制：配置保存相关策略和执行禁止等控制。 |  |  |
| `0x1273` | `0x0b8` | `CP_HQD_CNTL_STACK_OFFSET` | 控制栈当前偏移：记录保存区内控制栈的位置；驱动也据此计算控制栈已使用空间。 |  |  |
| `0x1274` | `0x0bc` | `CP_HQD_CNTL_STACK_SIZE` | 控制栈容量：指定控制栈区域的大小。 |  |  |
| `0x1275` | `0x0c0` | `CP_HQD_WG_STATE_OFFSET` | 工作组状态偏移：记录工作组执行状态在上下文保存区中的位置。 |  |  |
| `0x1276` | `0x0c4` | `CP_HQD_CTX_SAVE_SIZE` | 上下文保存区容量：指定保存执行上下文所用区域的大小。 |  |  |
| `0x1277` | `0x0c8` | `CP_HQD_GDS_RESOURCE_STATE` | 全局共享资源状态：包含资源需求／获取标志，以及全局同步资源的大小和位置；具体资源分配语义待核实。 |  |  |
| `0x1278` | `0x0cc` | `CP_HQD_ERROR` | 队列错误状态：记录 AQL 处理，以及 Ring、IB、EOP、索引读写等访问路径的相关错误。 |  |  |
| `0x1279` | `0x0d0` | `CP_HQD_EOP_WPTR_MEM` | 内存侧 EOP 写指针相关值：公开字段为 `WPTR`；与其他 EOP 指针之间的同步关系待核实。 |  |  |
| `0x127a` | `0x0d4` | `CP_HQD_AQL_CONTROL` | AQL 队列处理控制：驱动创建 AQL 队列时会设置其中的 `CONTROL0` 字段；各控制位的完整固件语义待核实。 |  |  |
| `0x127b` | `0x0d8` | `CP_HQD_PQ_WPTR_LO` | 主 Ring 写指针低位：保存设备侧写指针的低 32 位，反映队列生产进度。 |  |  |
| `0x127c` | `0x0dc` | `CP_HQD_PQ_WPTR_HI` | 主 Ring 写指针高位：与前一个寄存器共同组成 64 位写指针。 |  |  |
| `0x127d` | `0x0e0` | `CP_HQD_AQL_CONTROL_1` | AQL 扩展控制位置：该版本头文件将整个寄存器标为 `RESERVED`，未公开有效控制字段。 |  |  |
| `0x127e` | `0x0e4` | `CP_HQD_AQL_DISPATCH_ID` | AQL 消费编号低位：保存 `CONSUMED_OFFSET` 的低 32 位；具体推进时机待核实。 |  |  |
| `0x127f` | `0x0e8` | `CP_HQD_AQL_DISPATCH_ID_HI` | AQL 消费编号高位：与前一个寄存器组成 64 位消费编号状态。 |  |  |

> **[SOURCE]** 以下源码均为仓库固定 Linux 版本 `248951ddc14de84de3910f9b13f51491a8cd91df`：
>
> - 寄存器名称、偏移及同址别名：[drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_offset.h](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_offset.h#L3282-L3403) 的 [3282–3403 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_offset.h#L3282-L3403)；公开位字段：[drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_sh_mask.h](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_sh_mask.h#L16323-L16747) 的 [16323–16747 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_sh_mask.h#L16323-L16747)。
> - HQD 装载区间：[drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gc_9_4_3.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gc_9_4_3.c#L284-L303) 的 [284–303 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gc_9_4_3.c#L284-L303)；保留位置：[drivers/gpu/drm/amd/include/v9_structs.h](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/v9_structs.h#L306-L319) 的 [306–319 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/v9_structs.h#L306-L319)。
> - 队列配置的实际填写过程：[drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L1826-L1958) 的 [1826–1958 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L1826-L1958)。
> - AQL 与上下文保存配置：[drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c#L184-L245) 的 [184–245 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c#L184-L245)；控制栈与状态保存区的使用量计算见该文件的 [380–405 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c#L380-L405)。
> - 队列卸载与抢占请求：[drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gfx_v9.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gfx_v9.c#L524-L573) 的 [524–573 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gfx_v9.c#L524-L573)。
