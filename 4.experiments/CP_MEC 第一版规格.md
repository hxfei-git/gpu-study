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
KIQ 中的 MAP_QUEUES 命令
  → CP 解析命令，取得 MQD 地址和队列映射信息
  → 读取 MQD 中的 Ring 地址、容量、索引地址和 Doorbell 配置
  → 将队列配置装入目标 HQD 槽位
  → 建立目标队列的驻留状态

用户 AQL 队列中的 Kernel Dispatch Packet
  → CP 解析包，取得任务规模、参数地址和完成 Signal
  → 根据 kernel_object 读取 Kernel 描述对象，取得代码入口和资源要求
  → 准备并派发 kernel，让计算单元执行
```

向 KIQ 写入 `MAP_QUEUES`，称为“提交一条管理命令”；向用户 AQL 队列写入 Kernel Dispatch Packet，称为“提交计算任务”。

**[DESIGN]** 第一版采用 `CP_HQD_AQL_CONTROL` 记录队列格式，整个寄存器的值定义为：`0` 表示非 AQL，`1` 表示 AQL。KIQ、HIQ 配置为 `0`，用户 AQL Queue A、B 配置为 `1`；CP 根据该值选择命令解析流程。该约定是本版的自定义语义，具体流程和 AMD 参考依据见[队列格式选择说明](<./CP_MEC 第一版寄存器定义.md#20-aql-与非-aql-队列的格式选择>)。

**[DESIGN]** 第一版不引入 IB。管理命令和 AQL Packet 直接放入各自的 Ring，CP 从 Ring 读取并处理；本版不实现引用 IB 的间接命令执行。`CP_HQD_IB_BASE_ADDR`、`CP_HQD_IB_BASE_ADDR_HI`、`CP_HQD_IB_RPTR` 和 `CP_HQD_IB_CONTROL` 均不采用。KIQ、AQL 与 IB 的关系及取舍依据见[第一版不引入 IB](<./CP_MEC 第一版寄存器定义.md#7-第一版不引入-ib>)。

HQD 的填充分为两个阶段：

- **首次 CP 启动前，由 Host 配置 KIQ。** Host 准备 KIQ 的 MQD、Ring 和相关内存，并直接填写 KIQ 对应的 HQD，使设备能够找到 KIQ Ring。
- **启动后，由 CP 通过 KIQ 命令配置。** Host 准备内存中的 MQD，通过 KIQ 提交相应管理命令；CP 读取描述信息并填写目标 HQD。Host 不再直接改写 HQD 中的队列配置，访问方式及配置权限见[第 2.5 节](#25-host-选槽窗口与-cp-直接访问)。

队列运行期间，CP 使用并维护队列进度。HQD 保存状态，CP 执行固件、处理队列命令，计算执行器执行 kernel。

### 1.2 固定轮流选择与阻塞执行

**[DESIGN]** 第一版由裸机 CP 固件按固定规则选择队列：每轮先检查 KIQ、HIQ，各处理至多一条可处理的管理命令，再轮流检查 A、B。每次提交一个完整 Dispatch，阻塞等待计算执行器完成，处理结果后再选择下一条队列；不在执行中途抢占。未激活或没有可处理命令的队列直接跳过。等待计算完成期间，CP 暂不处理其他队列，包括 KIQ、HIQ。

本版暂不采用 `CP_HQD_PERSISTENT_STATE`、`CP_HQD_PIPE_PRIORITY`、`CP_HQD_QUEUE_PRIORITY` 和 `CP_HQD_QUANTUM`。完整流程、限制与后续扩展见[队列选择与调度扩展说明](<./CP_MEC 第一版寄存器定义.md#5-第一版队列选择与后续调度扩展>)；后续裸机事件循环参考 AMD/Xilinx ZynqMP PMU Firmware。这里确认的是实现方案，队列功能仍待接入和验证。

**[DESIGN]** 第一版也不采用 `CP_HQD_IQ_TIMER` 和 `CP_HQD_IQ_RPTR`。等待计算完成由 CP 固件轮询执行器状态实现，本版不建立 IQ 命令缓冲区或维护 IQ 读取进度。以后可先用裸机事件循环和固件内存中的状态推进等待任务；是否需要独立的 IQ 硬件机制及寄存器，按实际需求另行确认。当前等待流程、限制与扩展条件见[第一版不引入 IQ](<./CP_MEC 第一版寄存器定义.md#8-第一版不引入-iq>)。

### 1.3 新通知更新生产进度，CP 推进消费位置

**[DESIGN]** 队列运行期间，新通知只更新设备掌握的生产进度；消费位置由 CP 根据实际消费情况推进，不能用新通知中的进度覆盖。CP 继续从自己保存的位置按顺序处理命令，即使通知已经指向更后面的包，也不能跳过尚未消费的包。

例如，CP 下一待消费包是 10，Host 连续发布包 10、11、12 并发出通知。设备掌握的生产进度可以更新到“已发布至包 12”，消费位置仍保留为 10；CP 随后按 10、11、12 的顺序处理并自行推进。这个例子及首次配置、恢复队列与运行时更新的区别，见[生产进度与消费位置的更新规则](<./CP_MEC 第一版寄存器定义.md#64-新通知更新生产进度cp-推进消费位置>)。

### 1.4 Dispatch 完成后推进读进度并回报

**[DESIGN]** 队列驻留期间，以 `CP_HQD_PQ_RPTR` 保存的消费位置为依据，由 CP 推进；读进度回报内存保存 CP 发布的副本，MQD 在卸载保存时接收需要恢复的进度。Host 不根据新通知改写消费位置，也不独立推进这些副本。

第一版 AQL Dispatch 的正常成功路径采用以下顺序：

```text
读取并解析 Dispatch，保持原消费位置
  → 提交计算，阻塞等待整个 Dispatch 完成
  → 确认结果写回，完成任务清理
  → 按完成协议发布 Signal，此后不再访问该任务的参数等资源
  → 将原 Ring 包槽标为 INVALID
  → 推进 CP_HQD_PQ_RPTR
  → 向 RPTR_REPORT_ADDR 指向的内存回报新进度
  → Host 观察到新进度后，可以复用已消费包占用的 Ring 槽
```

读进度用于判断 Ring 槽是否可复用，任务结果按 Signal 和错误协议判断。上述时序不确定索引的位宽、计数单位或回绕编码，也不规定异常时是否推进；具体例子和状态副本关系见[消费位置与 Ring 槽复用](<./CP_MEC 第一版寄存器定义.md#65-dispatch-完成后的读进度与-ring-槽复用>)。

### 1.5 管理命令后追加写完成标记命令

**[DESIGN]** 第一版采用在同一个 KIQ 中，先提交管理命令、随后追加一条写完成标记命令的方式确认管理操作完成。完成地址和预期值由后面的写标记命令携带；Host 读取该地址，等待本次预期值出现。

以正常成功的队列配置为例：

```text
Host 准备完成标记内存，并保证初始化对 CP 可见
  → 向 KIQ 提交 MAP_QUEUES
  → 在同一 KIQ 中追加写完成标记命令

CP 按 KIQ 中的命令顺序处理
  → 完整配置目标 HQD，并使目标队列可用
  → 执行后面的写标记命令，将预期值写到指定内存

Host 观察到本次完成标记
  → 按管理命令的结果协议确认队列配置完成
```

CP 必须先让前面的管理操作达到规定的完成条件，才能发布后面的标记；仅发起异步操作后立即写标记，不能满足这个约定。卸载操作的完成条件还须包括目标队列相关访问已经结束、必要状态已经保存。标记确认的是前面的管理操作，用户 AQL Kernel 的完成仍由各自的 Signal 协议处理。

本节确定命令组织方式和正常成功路径的先后关系。写标记命令的名称、编码、地址类型、标记位宽、访问与复用规则，以及失败后是否继续执行后续命令、怎样报告失败，仍待确定。具体例子、卸载边界与 AMD 参考路径见[管理命令后的完成标记](<./CP_MEC 第一版寄存器定义.md#94-管理命令后追加写完成标记命令>)。

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
  → 准备 KIQ Ring、MQD 和相关内存，保持 KIQ 槽位 ACTIVE = 0
  → 填写 KIQ 对应的 HQD，保证配置和内存初始化对 CP 可见
  → 最后设置 KIQ 槽位 ACTIVE = 1
  → 解除 CP 复位（CP_CTRL.RESET_HOLD = 0）
  → CP 固件检查 KIQ 槽位的 ACTIVE，再检查并处理可用命令
```

这里的 KIQ 就绪，是指 Host 已准备好 Ring，并完成 HQD 配置和激活。CP 固件在 `ACTIVE = 0` 时暂不处理该队列，在 `ACTIVE = 1` 时检查是否有可处理的命令；Ring 可以暂时为空，CP 启动后等待后续提交。完整启动图和 AMD 参考事实见[队列激活状态说明](<./CP_MEC 第一版寄存器定义.md#2-队列激活状态>)。无需额外增加“通知 CP 检查 KIQ 配置”的寄存器；HQD 的访问方式与启动后的配置权限按第 2.5 节执行。

### 2.5 Host 选槽窗口与 CP 直接访问

**[DESIGN]** Host 和 CP 通过两个入口访问同一份 HQD 状态：

```text
Host 访问 BAR0：
  BAR0 + 0x0600           HQD_SELECT
  BAR0 + 0x0700～0x07ff   当前选中槽位的寄存器窗口

CP 直接按槽位访问：
  CP_HQD_BASE = 0xffff_0000                 暂定基址
  地址 = CP_HQD_BASE + 槽位编号 × 0x100 + 字段偏移
```

Host 选择槽位 2 时，窗口显示 Queue A 的状态；改选槽位 3 后，同一窗口显示 Queue B 的状态。选择只改变 Host 接下来访问哪份状态，不改变 CP 正在处理哪条队列。Host 驱动用锁保护选择和窗口访问；CP 使用普通寄存器读写指令按槽位寻址，QEMU 将访问转到对应 HQD，CP 不使用 `HQD_SELECT`。

首次 CP 启动前，Host 通过窗口配置 KIQ；启动后，HQD 的队列配置统一由 CP 按 KIQ 命令顺序填写。Host 可以选槽查看状态，后续配置请求仍走 KIQ。Host 准备的 MQD 是命令输入，提交后须保证 CP 读取期间内容稳定；CP 将地址的高低位及其余配置填写完整后，再启用队列。

这一约定确定了地址配置的唯一写方，不增加运行期间 Host 与 CP 交替填写地址的流程。动态进度若最终采用 64 位，读方与写方之间的一致性规则仍需结合所选格式确定；本节不据此确定进度位宽。详细过程见[首次 KIQ 配置与运行期间的配置权限](<./CP_MEC 第一版寄存器定义.md#23-首次-kiq-配置与运行期间的配置权限>)。

## 3. 后续讨论与补充

以下为待讨论清单。逐项讨论，经用户确认后，将结论补入本文的已确定规格，并删除对应条目。

1. **HQD 的其余字段与访问细则。** 首次 KIQ 的配置与激活顺序已在第 2.4 节确定；Host 选槽窗口、CP 直接寻址，以及启动后统一由 CP 按 KIQ 命令配置的权限已在第 2.5 节确定。继续确认各字段的复位值、访问宽度、非法访问处理和运行状态的读取规则。AMD 参考清单见[第 3.1 节](#31-amd-gc-943-队列装载寄存器清单)，按行记录是否采用。

2. **KIQ／HIQ 管理命令的最小接口。** 队列配置已确定通过 KIQ 交给 CP，完成确认采用第 1.5 节的后续写标记命令。继续确定管理命令及写标记命令的编码和字段、目标槽位的选择方式、标记的访问与复用规则、其他管理操作的分工，以及失败报告方式。

3. **CP 的取包地址与发布规则。** 第 1.3 节已确定新通知只更新生产进度、消费位置由 CP 推进；第 1.4 节已确定 AQL Dispatch 正常成功路径中的推进与回报时序。继续确定 Ring、MQD、参数的存储位置和地址类型，索引的位宽、单位、回绕与一致性访问，以及 Doorbell 与队列的对应关系、通知携带的内容。明确 CP 怎样判断包已准备好，避免读取尚未写完的内容。`CP_HQD_VMID` 已确定采用；实验支持多少个 VMID 上下文（“槽位”），待 MEC 规格确定后再讨论，见[队列地址空间标识说明](<./CP_MEC 第一版寄存器定义.md#3-队列地址空间标识>)。

4. **CP 与计算执行器的交接。** 补入已讨论的“保留现有分发寄存器及 PCIe BAR 映射，正常任务改由 CP 访问”约定。队列选择与阻塞等待规则已在第 1.2 节确定；进一步明确提交、忙、完成与错误状态的接口，以及执行结果怎样返回 CP 并更新 Signal。

5. **队列停止和出错后的收尾。** 卸载完成通过后续写标记命令确认；继续确定停止取包、结束在途访问和保存状态的具体流程，以及命令非法或计算失败时的结果报告。`CP_HQD_ERROR` 先保留为每条驻留队列的错误记录入口，具体异常见[队列错误记录说明](<./CP_MEC 第一版寄存器定义.md#19-队列错误记录与第一版保留范围>)；错误编码、清除、通知和 MQD 保存规则继续讨论。结合卸载结果与失败处理，明确队列内存何时可以释放。

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
| `0x124f` | `0x028` | `CP_HQD_PQ_RPTR` | 主 Ring 读指针：保存设备对主 Ring 的消费进度；本版 AQL Dispatch 正常完成并收尾后由 CP 推进，新通知不覆盖消费位置。 | 采用 | [读位置与进度存放地址](<./CP_MEC 第一版寄存器定义.md#62-ring-内的读位置与进度存放地址>) |
| `0x1250` | `0x02c` | `CP_HQD_PQ_RPTR_REPORT_ADDR` | 读指针回报地址低位：指定设备把消费进度写回到哪块内存，供软件读取；本版 AQL 正常路径先完成任务、释放包槽，再推进并回报进度，位宽与编码待定。 | 采用 | [读位置与进度存放地址](<./CP_MEC 第一版寄存器定义.md#62-ring-内的读位置与进度存放地址>) |
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
| `0x125d` | `0x060` | `CP_HQD_DEQUEUE_REQUEST` | 队列卸载／抢占请求：请求排空、复位 wave 或保存 wave 等处理，以卸载队列。 | 不采用 | [队列卸载的寄存器与命令入口](<./CP_MEC 第一版寄存器定义.md#9-队列卸载的寄存器与命令入口>) |
| `0x125e` | `0x064` | `CP_HQD_DMA_OFFLOAD`<br>`CP_HQD_OFFLOAD` | Offload 相关字段，同址别名：包含 DMA、AQL、EOP 对应的 `OFFLOAD` 与 `_EN` 字段；读写语义、转交对象及流程待核实。 | 不采用 | [Offload 字段与第一版取舍](<./CP_MEC 第一版寄存器定义.md#10-offload-字段与第一版取舍>) |
| `0x125f` | `0x068` | `CP_HQD_SEMA_CMD` | 信号量操作相关字段：包含 `RETRY` 和 `RESULT`；读写语义及与具体命令的对应关系待核实。 | 不采用 | [信号量操作字段与第一版取舍](<./CP_MEC 第一版寄存器定义.md#11-信号量操作字段与第一版取舍>) |
| `0x1260` | `0x06c` | `CP_HQD_MSG_TYPE` | 内部消息相关字段：包含 3 位的 `ACTION` 和 3 位的 `SAVE_STATE`；消息来源、编码含义及处理流程待核实。 | 不采用 | [内部消息字段与第一版取舍](<./CP_MEC 第一版寄存器定义.md#12-内部消息字段与第一版取舍>) |
| `0x1261` | `0x070` | `CP_HQD_ATOMIC0_PREOP_LO` | 原子操作相关数据 0 的低位：保存 `ATOMIC0_PREOP` 相关数据的低 32 位；数据含义及更新规则待核实。 | 不采用 | [原子操作相关数据与第一版取舍](<./CP_MEC 第一版寄存器定义.md#13-原子操作相关数据与第一版取舍>) |
| `0x1262` | `0x074` | `CP_HQD_ATOMIC0_PREOP_HI` | 原子操作相关数据 0 的高位：与前一个寄存器组成一份 64 位数据；数据含义及更新规则待核实。 | 不采用 | [原子操作相关数据与第一版取舍](<./CP_MEC 第一版寄存器定义.md#13-原子操作相关数据与第一版取舍>) |
| `0x1263` | `0x078` | `CP_HQD_ATOMIC1_PREOP_LO` | 原子操作相关数据 1 的低位：保存 `ATOMIC1_PREOP` 相关数据的低 32 位；数据含义及更新规则待核实。 | 不采用 | [原子操作相关数据与第一版取舍](<./CP_MEC 第一版寄存器定义.md#13-原子操作相关数据与第一版取舍>) |
| `0x1264` | `0x07c` | `CP_HQD_ATOMIC1_PREOP_HI` | 原子操作相关数据 1 的高位：与前一个寄存器组成另一份 64 位数据；数据含义及更新规则待核实。 | 不采用 | [原子操作相关数据与第一版取舍](<./CP_MEC 第一版寄存器定义.md#13-原子操作相关数据与第一版取舍>) |
| `0x1265` | `0x080` | `CP_HQD_HQ_SCHEDULER0`<br>`CP_HQD_HQ_STATUS0` | 队列内部状态与控制 0，同址别名：包含队列空闲、卸载状态、卸载重试计数等字段；驱动还通过对应 MQD 字段的 bit 14 请求 CP 设置调试所需的 `DISPATCH_PTR`。 | 不采用 | [队列内部状态与控制的第一版取舍](<./CP_MEC 第一版寄存器定义.md#14-队列内部状态与控制的第一版取舍>) |
| `0x1266` | `0x084` | `CP_HQD_HQ_CONTROL0`<br>`CP_HQD_HQ_SCHEDULER1` | 队列内部控制／调度字，同址别名：公开定义只给出整体控制或调度字段，具体行为待核实。 | 不采用 | [队列内部状态与控制的第一版取舍](<./CP_MEC 第一版寄存器定义.md#14-队列内部状态与控制的第一版取舍>) |
| `0x1267` | `0x088` | `CP_MQD_CONTROL` | MQD 访问控制：配置访问 MQD 使用的地址空间、权限、缓存策略及相关处理控制。 | 不采用 | [管理资源固定使用 VMID 0](<./CP_MEC 第一版寄存器定义.md#15-mqd-访问控制与固定管理地址空间>) |
| `0x1268` | `0x08c` | `CP_HQD_HQ_STATUS1` | 队列内部状态 1：公开定义仅给出完整的 32 位 `STATUS` 字段，具体状态含义待核实。 | 不采用 | [队列内部状态与控制的第一版取舍](<./CP_MEC 第一版寄存器定义.md#14-队列内部状态与控制的第一版取舍>) |
| `0x1269` | `0x090` | `CP_HQD_HQ_CONTROL1` | 队列内部控制 1：公开定义仅给出完整的 32 位 `CONTROL` 字段，具体控制含义待核实。 | 不采用 | [队列内部状态与控制的第一版取舍](<./CP_MEC 第一版寄存器定义.md#14-队列内部状态与控制的第一版取舍>) |
| `0x126a` | `0x094` | `CP_HQD_EOP_BASE_ADDR` | EOP 缓冲区基址编码低位：定位执行结束相关处理使用的缓冲区。 | 不采用 | [EOP 缓冲区与第一版取舍](<./CP_MEC 第一版寄存器定义.md#16-eop-缓冲区与第一版取舍>) |
| `0x126b` | `0x098` | `CP_HQD_EOP_BASE_ADDR_HI` | EOP 缓冲区基址编码高位：与前一个寄存器共同确定 EOP 缓冲区位置。 | 不采用 | [EOP 缓冲区与第一版取舍](<./CP_MEC 第一版寄存器定义.md#16-eop-缓冲区与第一版取舍>) |
| `0x126c` | `0x09c` | `CP_HQD_EOP_CONTROL` | EOP 处理控制：包含缓冲区容量、处理使能、取数器暂停、执行限制和相关状态。 | 不采用 | [EOP 缓冲区与第一版取舍](<./CP_MEC 第一版寄存器定义.md#16-eop-缓冲区与第一版取舍>) |
| `0x126d` | `0x0a0` | `CP_HQD_EOP_RPTR` | EOP 读指针及取数控制：保存消费进度，同时包含取数器初始化、复位和卸载等待状态等字段。 | 不采用 | [EOP 缓冲区与第一版取舍](<./CP_MEC 第一版寄存器定义.md#16-eop-缓冲区与第一版取舍>) |
| `0x126e` | `0x0a4` | `CP_HQD_EOP_WPTR` | EOP 写指针及缓冲状态：保存写入进度，并包含缓冲区空和可用量等信息。 | 不采用 | [EOP 缓冲区与第一版取舍](<./CP_MEC 第一版寄存器定义.md#16-eop-缓冲区与第一版取舍>) |
| `0x126f` | `0x0a8` | `CP_HQD_EOP_EVENTS` | EOP 事件状态：记录事件计数，以及计算管线部分刷新是否处于等待状态。 | 不采用 | [EOP 缓冲区与第一版取舍](<./CP_MEC 第一版寄存器定义.md#16-eop-缓冲区与第一版取舍>) |
| `0x1270` | `0x0ac` | `CP_HQD_CTX_SAVE_BASE_ADDR_LO` | 上下文保存区基址低位：指定队列执行状态保存到哪块内存，用于保存与恢复执行上下文。 | 不采用 | [上下文保存：后期重要扩展](<./CP_MEC 第一版寄存器定义.md#17-上下文保存与后期恢复执行>) |
| `0x1271` | `0x0b0` | `CP_HQD_CTX_SAVE_BASE_ADDR_HI` | 上下文保存区基址高位：与前一个寄存器共同确定保存区地址。 | 不采用 | [上下文保存：后期重要扩展](<./CP_MEC 第一版寄存器定义.md#17-上下文保存与后期恢复执行>) |
| `0x1272` | `0x0b4` | `CP_HQD_CTX_SAVE_CONTROL` | 上下文保存控制：配置保存相关策略和执行禁止等控制。 | 不采用 | [上下文保存：后期重要扩展](<./CP_MEC 第一版寄存器定义.md#17-上下文保存与后期恢复执行>) |
| `0x1273` | `0x0b8` | `CP_HQD_CNTL_STACK_OFFSET` | 控制栈当前偏移：记录控制栈的位置；驱动根据容量与该偏移计算已使用空间。 | 不采用 | [上下文保存：后期重要扩展](<./CP_MEC 第一版寄存器定义.md#17-上下文保存与后期恢复执行>) |
| `0x1274` | `0x0bc` | `CP_HQD_CNTL_STACK_SIZE` | 控制栈容量：指定控制栈区域的大小。 | 不采用 | [上下文保存：后期重要扩展](<./CP_MEC 第一版寄存器定义.md#17-上下文保存与后期恢复执行>) |
| `0x1275` | `0x0c0` | `CP_HQD_WG_STATE_OFFSET` | 工作组状态偏移：记录工作组现场数据的当前使用边界；驱动据此计算已使用空间。 | 不采用 | [上下文保存：后期重要扩展](<./CP_MEC 第一版寄存器定义.md#17-上下文保存与后期恢复执行>) |
| `0x1276` | `0x0c4` | `CP_HQD_CTX_SAVE_SIZE` | 上下文保存区容量：指定保存执行上下文所用区域的大小。 | 不采用 | [上下文保存：后期重要扩展](<./CP_MEC 第一版寄存器定义.md#17-上下文保存与后期恢复执行>) |
| `0x1277` | `0x0c8` | `CP_HQD_GDS_RESOURCE_STATE` | 专用同步资源状态：包含资源需求／获取标志，以及全局同步资源的大小和位置相关字段；具体编码及分配流程待核实。 | 不采用 | [专用同步资源与第一版取舍](<./CP_MEC 第一版寄存器定义.md#18-专用同步资源与第一版取舍>) |
| `0x1278` | `0x0cc` | `CP_HQD_ERROR` | 队列错误状态：AMD 字段涉及 AQL 处理及多种访问路径；本版保留，用于记录取包、命令校验、执行与完成写回等异常，具体编码待定。 | 采用（先保留） | [队列错误记录与具体异常](<./CP_MEC 第一版寄存器定义.md#19-队列错误记录与第一版保留范围>) |
| `0x1279` | `0x0d0` | `CP_HQD_EOP_WPTR_MEM` | 内存侧 EOP 写指针相关值：公开字段为 `WPTR`；与其他 EOP 指针之间的同步关系待核实。 | 不采用 | [EOP 缓冲区与第一版取舍](<./CP_MEC 第一版寄存器定义.md#16-eop-缓冲区与第一版取舍>) |
| `0x127a` | `0x0d4` | `CP_HQD_AQL_CONTROL` | 队列格式选择：本版自定义整个寄存器值 `0` 为非 AQL、`1` 为 AQL，供 CP 选择解析流程；AMD 原控制字段的完整语义仍待核实。 | 采用 | [AQL 与非 AQL 队列的格式选择](<./CP_MEC 第一版寄存器定义.md#20-aql-与非-aql-队列的格式选择>) |
| `0x127b` | `0x0d8` | `CP_HQD_PQ_WPTR_LO` | 主 Ring 写指针低位：保存设备侧写指针的低 32 位，反映队列生产进度。 |  |  |
| `0x127c` | `0x0dc` | `CP_HQD_PQ_WPTR_HI` | 主 Ring 写指针高位：与前一个寄存器共同组成 64 位写指针。 |  |  |
| `0x127d` | `0x0e0` | `CP_HQD_AQL_CONTROL_1` | AQL 扩展控制位置：该版本头文件将整个寄存器标为 `RESERVED`，未公开有效控制字段。 |  |  |
| `0x127e` | `0x0e4` | `CP_HQD_AQL_DISPATCH_ID` | AQL 消费偏移低位：AMD 公开字段为 `CONSUMED_OFFSET`，完整消费与回报语义待核实；第一版不采用。 | 不采用 | [第一版取舍与读进度回报](<./CP_MEC 第一版寄存器定义.md#21-aql-读进度与内存回报>) |
| `0x127f` | `0x0e8` | `CP_HQD_AQL_DISPATCH_ID_HI` | AQL 消费偏移高位：AMD 公开字段为 `CONSUMED_OFFSET`，与前一个寄存器的完整使用规则待核实；第一版不采用。 | 不采用 | [第一版取舍与读进度回报](<./CP_MEC 第一版寄存器定义.md#21-aql-读进度与内存回报>) |

> **[SOURCE]** 以下源码均为仓库固定 Linux 版本 `248951ddc14de84de3910f9b13f51491a8cd91df`：
>
> - 寄存器名称、偏移及同址别名：[drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_offset.h](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_offset.h#L3282-L3403) 的 [3282–3403 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_offset.h#L3282-L3403)；公开位字段：[drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_sh_mask.h](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_sh_mask.h#L16323-L16747) 的 [16323–16747 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_sh_mask.h#L16323-L16747)。
> - HQD 装载区间：[drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gc_9_4_3.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gc_9_4_3.c#L284-L303) 的 [284–303 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gc_9_4_3.c#L284-L303)；保留位置：[drivers/gpu/drm/amd/include/v9_structs.h](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/v9_structs.h#L306-L319) 的 [306–319 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/v9_structs.h#L306-L319)。
> - 队列配置的实际填写过程：[drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L1826-L1958) 的 [1826–1958 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L1826-L1958)。
> - AQL 与上下文保存配置：[drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c#L184-L245) 的 [184–245 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c#L184-L245)；控制栈与状态保存区的使用量计算见该文件的 [380–405 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c#L380-L405)。
> - 队列卸载与抢占请求：[drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gfx_v9.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gfx_v9.c#L524-L573) 的 [524–573 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gfx_v9.c#L524-L573)。
