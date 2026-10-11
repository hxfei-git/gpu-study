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
| TCG | Tiny Code Generator | QEMU 的动态代码生成基础设施 |
| VRAM | Video RAM | 教学设备的显存后备存储 |
| RAM | Random Access Memory | 随机存取存储器；Host RAM 与设备 VRAM 分开 |
| DMA | Direct Memory Access | 直接内存访问 |
| IOMMU | Input/Output Memory Management Unit | 输入输出内存管理单元 |
| SMMUv3 | System Memory Management Unit version 3 | Arm 系统内存管理单元第三版 |
| MSI-X | Message Signaled Interrupts Extended | 扩展消息中断 |
| PC | Program Counter | 程序计数器，保存取指地址 |

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

HQD 的填充分为两个阶段：

- **建立首个管理入口时，由 Host 填充。** Host 直接配置 KIQ 对应的 HQD，使设备能够找到 KIQ Ring。
- **后续由 CP 按管理命令填充。** Host 准备内存中的 MQD，并通过 KIQ／HIQ 提交相应管理命令；CP 读取描述信息，建立目标队列的 HQD 状态。

队列运行期间，CP 使用并维护队列进度。HQD 保存状态，CP 执行固件、处理队列命令，计算执行器执行 kernel。

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
  → 准备 KIQ Ring，填写 KIQ 对应的 HQD
  → 激活 KIQ，保证配置写入完成
  → 解除 CP 复位（CP_CTRL.RESET_HOLD = 0）
  → CP 执行固件，根据 KIQ 的 HQD 访问 Ring、处理管理命令
```

这里的 KIQ 就绪，是指 Host 已准备好 Ring，并完成 HQD 配置和激活。Ring 可以暂时为空，CP 启动后等待后续命令。无需额外增加“通知 CP 检查 KIQ 配置”的寄存器；HQD 的具体字段和访问方式继续在后续条目中讨论。

## 3. 后续讨论与补充

以下为待讨论清单。逐项讨论，经用户确认后，将结论补入本文的已确定规格，并删除对应条目。

1. **HQD 的具体字段和访问方式。** 确定每个槽位的字段、Host 选择槽位的方式、CP 的访问方式，以及各字段由谁读取和更新。明确配置尚未完成时，怎样阻止 CP 使用这份状态。

2. **KIQ／HIQ 管理命令的最小接口。** 确定 `MAP_QUEUES` 等所需命令携带的信息、目标槽位的选择方式，以及成功或失败的报告方式。Host 需要能够判断新队列何时可用。

3. **CP 的取包地址与发布规则。** 确定 Ring、MQD、参数的存储位置和地址类型，读写索引的推进方式，以及 Doorbell 与队列的对应关系。明确 CP 怎样判断包已准备好，避免读取尚未写完的内容。

4. **CP 与计算执行器的交接。** 补入已讨论的“保留现有分发寄存器及 PCIe BAR 映射，正常任务改由 CP 访问”约定。进一步确定执行器忙时的处理、两条 AQL 队列的选择、计算期间 CP 能否继续处理管理命令，以及执行结果怎样返回 CP 并更新 Signal。

5. **队列停止和出错后的收尾。** 确定 Host 的停止请求、CP 不再访问队列的确认方式，以及命令非法或计算失败时的结果报告。明确队列内存何时可以释放。
