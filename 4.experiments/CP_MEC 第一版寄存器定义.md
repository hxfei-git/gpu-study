# CP/MEC 第一版寄存器定义

| 缩写 | 英文全称                          | 中文含义                                                                  |
| ---- | --------------------------------- | ------------------------------------------------------------------------- |
| CP   | Command Processor                 | 命令处理器                                                                |
| MEC  | Micro Engine Compute              | 计算命令处理微引擎                                                        |
| HQD  | Hardware Queue Descriptor         | 硬件队列描述；用于保存队列驻留状态                                        |
| MQD  | Memory Queue Descriptor           | 内存中的队列描述对象                                                      |
| IB   | Indirect Buffer                   | 间接命令缓冲区；保存由 Ring 命令引用的一段 CP 命令，第一版不引入          |
| IQ   | 未核实                            | AMD 寄存器中的内部对象缩写；与定时、重试处理有关，完整流程待核实，第一版不引入 |
| RPTR | Read Pointer                      | 读指针；表示队列的消费进度                                                |
| WPTR | Write Pointer                     | 写指针；表示队列的写入进度                                                |
| GPU  | Graphics Processing Unit          | 图形处理器                                                                |
| KIQ  | Kernel Interface Queue            | 内核接口队列；第一版由 Host 配置的首个管理入口                            |
| HIQ  | HSA Interface Queue               | HSA 接口队列；第一版的另一条管理队列                                      |
| HSA  | Heterogeneous System Architecture | 异构系统架构                                                              |
| RV32 | 32-bit RISC-V                     | 第一版 CP 使用的原生 32 位 RISC-V 模型                                    |
| QEMU | Quick Emulator                    | 本实验使用的设备与 CP 仿真平台                                            |
| PMU  | Platform Management Unit          | 平台管理单元；本文参考 ZynqMP PMU Firmware 的裸机调度实现                 |
| PM4  | AMD PM4                           | AMD GPU 的一类底层命令包协议；用于说明计算 Ring 的 IB 引用及 KIQ 管理命令 |
| GC   | Graphics and Compute              | AMD 图形与计算模块；本文参考 GC 9.4.3 驱动                                |
| VM   | Virtual Memory                    | 虚拟内存；VM 上下文保存地址翻译所需的配置                                 |
| VMID | Virtual Memory Identifier         | 虚拟地址空间标识，用于选择 VM 上下文                                      |
| MMU  | Memory Management Unit            | 内存管理单元，执行地址翻译和权限检查                                      |
| TLB  | Translation Lookaside Buffer      | 地址翻译缓存                                                              |
| AQL  | Architected Queuing Language      | 用户计算队列采用的命令包格式与提交协议                                    |
| KFD  | Kernel Fusion Driver              | AMD GPU 计算相关内核驱动组件                                              |
| XCC  | Accelerator Core Complex          | 驱动管理的计算核心复合体；本模型中对应一个 XCD                            |
| XCD  | Accelerator Complex Die           | 物理计算芯粒                                                              |
| CU   | Compute Unit                      | 执行 Kernel 指令的计算单元                                                |

[第一版规格中的寄存器表](<./CP_MEC 第一版规格.md#31-amd-gc-943-队列装载寄存器清单>)集中记录寄存器名称、偏移、简要用途和是否采用；本文保存逐项讨论中的解释、例子和图示。

**[BOUNDARY]** 本文记录 AMD 参考事实和实验中已确认的设计，实验约定标为 `[DESIGN]`。是否采用，以规格表的“采用/不采用”列为准；写入说明不代表已经决定采用。

## 1. MQD 基址

本节对应 `CP_MQD_BASE_ADDR` 和 `CP_MQD_BASE_ADDR_HI`，两行共用这一份说明。

**[DESIGN]** 第一版采用这两个寄存器，共同保存当前队列的 MQD 地址。

你理解的“把 MQD 中对应的字段装入 HQD”这一步是对的，但还缺少后半程：**队列被换出 HQD 时，需要保存运行后的队列状态，以便以后继续执行。MQD 就是保存这些状态的内存对象。**

因此，MQD 装载后仍然要保留。这两个寄存器保存的就是：**当前这条队列的 MQD 在哪里。**

先用 Queue A 看这个过程。下面只画队列状态的装载和保存关系：

```text
内存中的 MQD_A
保存 Queue A 的配置、可恢复状态
        │
        │ 装载对应字段
        ▼
HQD 槽位 2
保存 Queue A 当前的活动状态
        │
        ├─ 根据 Ring 地址、读位置等信息读取 Queue A 的命令
        │
        └─ 换出时，将需要保留的队列状态保存回 MQD_A

保存完成后：
HQD 槽位 2 可以给 Queue B 使用
MQD_A 继续保留，供 Queue A 下次恢复驻留
```

`CP_MQD_BASE_ADDR` 保存 MQD 的 GPU 地址低 32 位，`CP_MQD_BASE_ADDR_HI` 保存地址高位。驱动初始化 MQD 时，将 MQD 自身的 GPU 地址拆分后填入对应字段；装入 HQD 后，设备侧仍能找到这条队列对应的 MQD。

> **[SOURCE]** 以下资料来自仓库固定 Linux 版本 `248951ddc14de84de3910f9b13f51491a8cd91df`：
>
> - MQD 与 HQD 之间的装载、状态保存关系：[Documentation/gpu/amdgpu/driver-core.rst](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/Documentation/gpu/amdgpu/driver-core.rst#L145-L160) 的 [145–160 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/Documentation/gpu/amdgpu/driver-core.rst#L145-L160)。这里采用通用的队列状态关系，图中的槽位编号用于举例。
> - MQD 自身地址的填写：[drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c#L184-L216) 的 [184–216 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c#L184-L216)；对应字段装入 HQD 的直接装载路径：[drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gc_9_4_3.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gc_9_4_3.c#L284-L303) 的 [284–303 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gc_9_4_3.c#L284-L303)。

## 2. 队列激活状态

本节对应 `CP_HQD_ACTIVE`。以下 `ACTIVE` 指该寄存器中的队列激活位。

**[DESIGN]** 第一版采用此项。Host 完成 KIQ 的 HQD 配置后，最后设置 `ACTIVE = 1`，再解除 CP 复位。CP 固件根据 `ACTIVE` 判断是否可以处理该槽位中的队列。

### 2.1 配置 KIQ、激活队列并启动 CP

Host 已装载固件并设置入口后，在 CP 保持复位期间完成 KIQ 配置。固件装载与复位控制见[规格第 2.3 节](<./CP_MEC 第一版规格.md#23-固件装载与复位顺序>)。

**[DESIGN]** 启动顺序如下：

```text
Host：让 CP 保持复位
  │
  ├─ 准备 KIQ Ring 和相关内存
  ├─ 保持 KIQ 槽位 ACTIVE = 0
  ├─ 填写 HQD：Ring 地址、容量、指针、MQD 地址等
  ├─ 保证前面的配置和内存初始化对 CP 可见
  ├─ 最后设置 KIQ 槽位 ACTIVE = 1
  │
  └─ 解除 CP 复位，让 CP 开始执行固件
          │
          ▼
      CP 固件检查 KIQ 槽位
          │
          ├─ ACTIVE = 0：暂不处理这个队列
          │
          └─ ACTIVE = 1：检查有没有可处理的命令
                  │
                  ├─ 没有：等待后续提交
                  └─ 有：读取并处理，例如 MAP_QUEUES
```

激活表示这个槽位中的队列已经启用，可以被 CP 处理。`ACTIVE = 1` 时，Ring 仍可能为空，或者队列暂时没有获得处理机会；不能据此判断某个 Kernel 正在执行。一个任务处理完后，队列可以继续保持激活，等待下一个任务。

设置 `ACTIVE` 和启动 CP 是两个动作：前者启用队列，后者让处理器开始执行固件。`ACTIVE` 属于 HQD 槽位；槽位改装另一条队列后，它表示新队列的激活状态。

### 2.2 AMD 初始化与卸载路径的参考事实

MI300X 对应的 GC 9.4.3 驱动先停止 MEC，初始化 KIQ 的 MQD 并配置 HQD，在写入队列地址、指针和其他状态后设置 `CP_HQD_ACTIVE = 1`，随后使能 MEC。

就 KIQ 的 HQD 配置而言，设置 `ACTIVE` 是最后的激活动作；但整个初始化函数在它后面还有一次可选的 `CP_PQ_STATUS.DOORBELL_ENABLE` 写入。公开驱动源码能证明上述调用顺序，不能证明 MEC 固件启动后的第一条检查就是读取 `ACTIVE`。第 2.1 节明确要求 CP 固件检查该位，这是本实验的设计约定。

AMD 的卸载路径先写 `CP_HQD_DEQUEUE_REQUEST`，再等待 `ACTIVE` 清零。卸载请求可以选择排空、保存或复位执行状态，因此 `ACTIVE = 0` 不能单独证明所有 Kernel 都成功完成，也不能单独作为释放全部队列内存的依据。

**[BOUNDARY]** 本轮确认寄存器采用、激活含义和首次 KIQ 启动顺序。实验中的停止请求、`ACTIVE` 清零时机及状态保存完成的确认方式，仍按规格中的后续讨论项确定。

> **[SOURCE]** 以下源码均为仓库固定 Linux 版本 `248951ddc14de84de3910f9b13f51491a8cd91df`：
>
> - KIQ 初始化及 MEC 使能顺序：[drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L1952-L1956) 的 [1952–1956 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L1952-L1956)设置 MQD 中的激活值；[1961–2072 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L1961-L2072)配置并激活 KIQ；[2220–2266 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L2220-L2266)先初始化 KIQ，再使能 MEC；[1731–1749 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L1731-L1749)给出使能与停止 MEC 的寄存器操作。
> - 卸载请求与激活位检查：[drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gfx_v9.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gfx_v9.c#L524-L573) 的 [524–573 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gfx_v9.c#L524-L573)；GC 9.4.3 使用该卸载实现的接口绑定见 [drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gc_9_4_3.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gc_9_4_3.c#L533-L544) 的 [533–544 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gc_9_4_3.c#L533-L544)。

## 3. 队列地址空间标识

本节对应 `CP_HQD_VMID`。它保存队列使用的地址空间标识，供设备选择地址翻译上下文；以下先说明其中主队列的 `VMID` 字段。

**[DESIGN]** 第一版采用 `CP_HQD_VMID`。实验支持多少个 VMID 上下文，待 MEC 规格确定后再讨论，本轮不确定数量。

### 3.1 根据队列的 VMID 选择地址翻译上下文

以 AMD 的 Queue B 使用 VMID 9 为例：驱动已经建立页表 B，接下来要让 CP 按这套映射读取 Queue B 的 Ring。下面展示准备和访问过程；访问部分假设 TLB 未命中，需要遍历页表。编号 9 用于说明 AMD 的寄存器关系，不代表实验已确定支持这个编号。

```text
驱动提前准备：
  建立内存中的页表 B
    → 将页表 B 的根地址写入 VM_CONTEXT9 的页表基址寄存器
    → 配置 VM_CONTEXT9 的控制信息
    → 将 Queue B 的 HQD 中的 VMID 设置为 9

CP 读取 Queue B 的命令：
  根据 HQD 发出读取请求：虚拟地址 + VMID 9
    → 地址翻译硬件根据 VMID 9 选择 VM_CONTEXT9
    → 从对应上下文取得页表 B 的根地址
    → 根据虚拟地址遍历页表 B，完成翻译和权限检查
    → 访问实际存储位置，取回命令包
```

VMID 选择使用哪份地址翻译上下文，虚拟地址决定在对应页表中查询哪些表项。上下文寄存器保存页表根地址和控制配置，完整页表保存在内存中；TLB 命中时可以使用缓存的翻译结果。

HQD 槽位保存队列状态，VM 上下文保存地址翻译配置，两者通过 HQD 中的 VMID 关联。VMID 是上下文编号，不能据此推算 MMU 的数量。同一地址空间中的多条队列可以使用同一个 VMID。

### 3.2 AMD 的多组 VM_CONTEXT 寄存器

AMD 使用 `VM_CONTEXTn_*` 表示按上下文编号区分的寄存器，`n` 代表编号。例如 GC 9.4.3 的公开定义中，存在下面这些寄存器：

```text
VM_CONTEXT8_CNTL
  → 上下文 8 的控制配置
VM_CONTEXT8_PAGE_TABLE_BASE_ADDR_LO32
VM_CONTEXT8_PAGE_TABLE_BASE_ADDR_HI32
  → 上下文 8 的页表根地址低位、高位

VM_CONTEXT9_CNTL
  → 上下文 9 的控制配置
VM_CONTEXT9_PAGE_TABLE_BASE_ADDR_LO32
VM_CONTEXT9_PAGE_TABLE_BASE_ADDR_HI32
  → 上下文 9 的页表根地址低位、高位

其他编号也有对应的 VM_CONTEXTn_* 寄存器组。
```

`VM_CONTEXTn_CNTL` 包括上下文使能、页表层级等控制信息。驱动根据 VMID 选择相应的寄存器组，提前写入页表根地址和配置；设备访问时再按请求所属的 VMID 使用对应上下文。

讨论中的“VMID 槽位”是便于理解的比喻，指这些可配置的上下文。AMD 寄存器名称使用 `VM_CONTEXT`，正文采用“VM 上下文”，与 HQD 队列槽位区分。

**[BOUNDARY]** 上述寄存器名称和编号用于解释 AMD 的实现。实验的 VMID 上下文数量留待 MEC 规格确定后确认；本轮也不为实验分配这些上下文寄存器的地址。

> **[SOURCE]** 以下源码均为仓库固定 Linux 版本 `248951ddc14de84de3910f9b13f51491a8cd91df`：
>
> - 多组 VM 上下文控制寄存器：[drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_offset.h](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_offset.h#L1594-L1625) 的 [1594–1625 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_offset.h#L1594-L1625)；上下文 8、9 各自的页表根地址寄存器见该文件的 [1840–1847 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_offset.h#L1840-L1847)。
> - 按 VMID 配置页表根地址：[drivers/gpu/drm/amd/amdgpu/gfxhub_v1_2.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfxhub_v1_2.c#L42-L61) 的 [42–61 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfxhub_v1_2.c#L42-L61)；上下文使能与页表层级配置见该文件的 [343–350 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfxhub_v1_2.c#L343-L350)。
> - 队列 VMID 的填写：[drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c#L320-L322) 的 [320–322 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c#L320-L322)；多个活动地址空间及 VMID 与页表的关系见 [drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c#L51-L85) 的 [51–85 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c#L51-L85)。

## 4. 用户队列在多个 XCC 上驻留与分工

本节沿用 MI300X 的 8 个 XCC 组成一个逻辑 GPU 的教学配置。Host 准备 MEC 固件，并配置各 XCC 的命令处理引擎。各引擎执行同一版本的程序，根据各自的队列状态处理命令；用户 AQL 队列 Q0 在各 XCC 驻留后，再由这些 XCC 分担一次 Dispatch 的 Work-group。

### 4.0 同一份固件与各 XCC 的两个 MEC

**MEC 镜像保存的是程序代码，执行程序的是各 XCC 内的 MEC。** Host 为各 XCC 配置固件和队列，再使能这些命令处理引擎。多个 MEC 可以使用同一版代码，分别依据自己的执行上下文和所处理队列的状态推进。

下面展开“一个镜像、多个执行实例”的关系。F 表示同一份固件的代码内容，箭头表示各实例执行这份代码后处理各自配置的队列；这是一张程序与运行实例的关系图，不表示芯片的物理布局。

```text
同一份 MEC 固件镜像 F：提供共同的程序代码
    │ Host 为各 XCC 配置固件并使能 MEC
    │
    ├─ XCC 0
    │   ├─ MEC1 执行 F → 处理配置给 XCC 0 / MEC1 的队列
    │   └─ MEC2 执行 F → 处理配置给 XCC 0 / MEC2 的队列
    │
    ├─ XCC 1
    │   ├─ MEC1 执行 F → 处理配置给 XCC 1 / MEC1 的队列
    │   └─ MEC2 执行 F → 处理配置给 XCC 1 / MEC2 的队列
    │
    ├─ ……其他 XCC
    │
    └─ XCC 7
        ├─ MEC1 执行 F → 处理配置给 XCC 7 / MEC1 的队列
        └─ MEC2 执行 F → 处理配置给 XCC 7 / MEC2 的队列
```

按固定驱动的枚举关系，8 个 XCC、每个 2 个 MEC，共有 `8 × 2 = 16` 个 MEC 实例位置。这个数量描述执行引擎的范围；镜像文件可以只有一份，各实例是否正在处理命令取决于启用状态和待处理的工作。

镜像提供处理命令所需的程序，队列配置则决定当前实例从哪个 Ring 取命令、使用哪份队列状态。因此，“同一份镜像控制多个 XCC”应理解为：**多个 XCC 内的 MEC 使用同一份程序，各自处理所配置的队列。** 每个 XCC 内的 MEC1 和 MEC2 也遵循这个关系，程序相同不要求它们读取同一条队列或保持相同执行进度。

例如，Q0 的用户队列状态放在各 XCC 的 MEC1 下，各 XCC 的 KIQ 则有自己独立的 Ring 和指定的 MEC/Pipe/Queue 位置。参与 Q0 的命令处理实例读取 Q0 的 Dispatch；负责 KIQ 的实例读取该 XCC 的管理命令，例如 `MAP_QUEUES`。分工首先由队列配置确定，后续对 Q0 的 Work-group 分配才需要参与的 XCC 数量和逻辑编号。

**[INFERENCE]** 按本例固定驱动的资源分配规则，内核计算队列先占用 MEC1 的位置，KIQ 从剩余位置中倒序选择，并要求 Queue 0、排除 MEC2 的 Pipe 2/3，因而会选到 MEC2 的 Pipe 1、Queue 0。这个结果来自驱动的分配策略，不表示 MEC1、MEC2 必须采用两份不同的固件，也不表示每个 MEC 都有一条 KIQ。

AMD 的直接装载路径提供了具体证据：驱动把 MEC 固件中的微码复制到一块缓冲区，再把同一个固件地址配置到各 XCC 的指令基址寄存器。该路径的注释还说明，只有 MEC2 需要运行与 MEC1 不同的微码时，才需要另外装载 MEC2 固件。

> **[SOURCE]** 以下源码均为仓库固定 Linux 版本 `248951ddc14de84de3910f9b13f51491a8cd91df`：
>
> - 每个 XCC 的 MEC 枚举数量：[drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L1063-L1067) 的 [1063–1067 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L1063-L1067)配置 `num_mec = 2`，另行取得 XCC 数量；[1731–1749 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L1731-L1749)按 XCC 控制 MEC 启停，其中包含 ME1、ME2 的停止位。
> - 共用 MEC 固件及逐 XCC 初始化：同文件 [663–681 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L663-L681)准备固件缓冲区；[1752–1797 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L1752-L1797)将 `mec_fw_gpu_addr` 写入对应 XCC 的 `CP_CPC_IC_BASE_LO/HI`，并说明 MEC2 使用不同微码时才需要单独装载；[2243–2266 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L2243-L2266)区分固件装载路径并初始化 KIQ、使能 MEC；[2310–2314 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L2310-L2314)逐个恢复 XCC。
> - KIQ 所在 MEC 的分配依据：[drivers/gpu/drm/amd/amdgpu/amdgpu_gfx.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_gfx.c#L206-L239) 的 [206–239 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_gfx.c#L206-L239)为内核计算队列预留 MEC1 资源；[271–299 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_gfx.c#L271-L299)从未占用的位置选择 KIQ，源码中从 0 开始编号的 `mec == 1` 对应 MEC2；[gfx_v9_4_3.c 的 1801–1810 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L1801-L1810)将选定的 MEC、Pipe、Queue 位置配置为该 XCC 的 KIQ。

### 4.1 各 XCC 的 MEC1 下保留 Q0 的队列状态

Q0 驻留时，在每个 XCC 的 MEC1 下各占用一个 HQD 槽位。图中的箭头表示各 XCC 的命令前端根据本地 HQD 保存的 Ring 地址，访问同一个 Q0 Ring：

```text
XCC 0 的一个 HQD：保存 Q0 的配置和本地状态 ─┐
XCC 1 的一个 HQD：保存 Q0 的配置和本地状态 ─┤
……                                          ├─→ 同一个 Q0 Ring
XCC 7 的一个 HQD：保存 Q0 的配置和本地状态 ─┘
```

也就是：**一条 Q0、一个 Ring，在 8 个 XCC 上各占一个 HQD。** 各份配置中的 Ring 地址相同，但 XCC 编号等本地配置可以不同。这里的“每个 XCC”指 Q0 所属逻辑 GPU 包含的 XCC。

驱动为 Q0 准备各 XCC 对应的 MQD，保存共同的队列属性和各自的上下文配置。Q0 获得驻留资源时，相关状态分别装入对应 XCC 的硬件。HQD 保存地址、容量和进度等队列状态，Dispatch Packet 仍保存在同一个 Ring 中。

这里说的 MEC1 是固定驱动交给 KFD 的用户计算队列资源范围。KIQ 则按 XCC 分别建立，各自有独立的 Ring；不能把 Q0 的跨 XCC 驻留关系套到所有类型的 Queue 上。

> **[SOURCE]** 以下源码均为仓库固定 Linux 版本 `248951ddc14de84de3910f9b13f51491a8cd91df`：
>
> - 用户计算队列使用 MEC1 的资源范围：[drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd.c#L196-L207) 的 [196–207 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd.c#L196-L207)清除 MEC1 范围之外的可用队列位。
> - 同一条队列在各 XCC 上的状态：[drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c#L727-L795) 的 [727–795 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c#L727-L795)使用同一份队列属性初始化各 XCC 的 MQD，并设置各自的上下文保存地址和逻辑 XCC 编号；[905–930 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c#L905-L930)给出直接装载路径中按 XCC 调用 HQD 装载接口的过程。
> - 各 XCC 独立的 KIQ：[drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L1108-L1145) 的 [1108–1145 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L1108-L1145)逐个初始化 XCC 的 KIQ；[drivers/gpu/drm/amd/amdgpu/amdgpu_gfx.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_gfx.c#L306-L339) 的 [306–339 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_gfx.c#L306-L339)从 `kiq[xcc_id]` 取得对应对象并创建 Ring。

### 4.2 相同的 Dispatch 按逻辑 XCC 编号分配 Work-group

现在 Q0 已驻留，Host 向它的 Ring 发布一个 Kernel Dispatch Packet。这次 Dispatch 描述 16 个 Work-group，各 XCC 的命令前端读取并解析同一个 Packet，再向本地 CU 分派自己承担的 Work-group。

下面用每个 XCC 轮流分到一组的方式说明分工。为方便阅读，本例让 XCC 0～7 的逻辑编号也分别为 0～7；实际逻辑编号由队列配置决定，不必与物理编号相同。

```text
同一个 Dispatch：共有 16 个 Work-group
    │
    │ 各 XCC 读取同一个 Packet，按各自的逻辑编号确定工作范围
    │
    ├─ XCC 0：逻辑编号 0 → 本地 CU 执行组 0、8
    ├─ XCC 1：逻辑编号 1 → 本地 CU 执行组 1、9
    ├─ XCC 2：逻辑编号 2 → 本地 CU 执行组 2、10
    ├─ XCC 3：逻辑编号 3 → 本地 CU 执行组 3、11
    ├─ XCC 4：逻辑编号 4 → 本地 CU 执行组 4、12
    ├─ XCC 5：逻辑编号 5 → 本地 CU 执行组 5、13
    ├─ XCC 6：逻辑编号 6 → 本地 CU 执行组 6、14
    └─ XCC 7：逻辑编号 7 → 本地 CU 执行组 7、15
```

各 XCC 需要知道两类信息：共同的信息是 Dispatch 描述的工作范围，以及参与执行的 XCC 数量；各自的信息是当前队列配置中的逻辑 XCC 编号。**分工算法相同，但自身编号不同，算出的工作范围就不同。** 因此，各 XCC 可以使用同一版本的处理程序，分别安排本地 CU 执行自己承担的部分。

**[DESIGN]** 如果在实验固件中表达这种分工，可以读取参与执行的 XCC 数量和当前逻辑编号，再按下面的规则分派。本例将 Work-group 编为 `0～15`；函数名和循环都是教学伪代码，用来说明输入怎样决定分工。

```c
/* 教学伪代码：本例有 8 个 XCC，共同执行 16 个 Work-group。 */
xcc_count = get_participating_xcc_count(); /* 本例为 8 */
my_xcc_id = get_queue_logical_xcc_id();   /* 本例为 0～7 中的一个 */
group_count = 16;                        /* 本次 Dispatch 的 Work-group 总数 */

for (group_id = my_xcc_id; group_id < group_count; group_id += xcc_count) {
    dispatch_to_local_cu(group_id);      /* 向本地 CU 分派该 Work-group */
}
```

这段循环只说明 Work-group 的归属。实际处理还需要各 XCC 协调进度，并在所有部分完成后通知整个 Dispatch 完成。图中的组号不规定实际分配的起点或完成顺序。

> **[SPEC]** AMD 官方文章 [Deep dive into the MI300 compute and memory partition modes](https://rocm.blogs.amd.com/software-tools-optimization/compute-memory-modes/README.html#workgroup-scheduling-behavior)（2025-02-09）“Workgroup scheduling behavior”说明：MI300X 的 8 个 XCD 作为一个逻辑设备时，Work-group 在这些 XCD 间轮转分配。AMD 作者版论文 [Realizing the AMD Exascale Heterogeneous Processor Vision](https://www.computermachines.org/joe/publications/pdfs/isca2024_exascale.pdf#page=9)（2024）§VI-A、图 13，第 9 页说明各 XCD 读取同一个 AQL Packet、分别启动一部分 Work-group，并协调完成；[§VII，第 11 页](https://www.computermachines.org/joe/publications/pdfs/isca2024_exascale.pdf#page=11)确认 MI300X 复用所述 XCD 组件。这里采用适用于 MI300X 的多 XCD 协作关系。

> **[SOURCE]** 固定 Linux 版本 `248951ddc14de84de3910f9b13f51491a8cd91df`，[drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c#L765-L779) 的 [765–779 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c#L765-L779)，为 AQL 队列配置 `compute_tg_chunk_size = 1` 和各自的 `compute_current_logic_xcc_id`，后者按参与的 XCC 数量取模计算。

**[BOUNDARY]** AMD 资料和驱动源码能确认跨 XCC 分工及相关配置，但不能证明上述循环全部由 MEC 固件执行；具体实现可能涉及固件和硬件配合。本节的 8 个 XCC 用于说明 AMD 教学案例，实验中的 XCC 数量及相关寄存器仍待规格确认。

## 5. 第一版队列选择与后续调度扩展

本节对应 `CP_HQD_PERSISTENT_STATE`、`CP_HQD_PIPE_PRIORITY`、`CP_HQD_QUEUE_PRIORITY` 和 `CP_HQD_QUANTUM`。

**[DESIGN]** 第一版暂不采用这四个寄存器。裸机 CP 固件按固定规则轮流选择用户队列，每次提交一个完整 Dispatch，等待它执行完后再选择下一条队列。

**[BOUNDARY]** 本节记录教学设备的实现方案，不用于推断 AMD MEC 内部实现。当前已接入 CP 复位、入口与基本固件运行，队列与 CP 派发接口仍待接入和验证，见[规格第 2 节](<./CP_MEC 第一版规格.md#2-远端设备与-cp-固件启动>)。

### 5.1 固定轮流选择与阻塞执行

本方案使用一个 RV32 CP 和现有计算执行器，计算执行器一次处理一个 Dispatch。4 个 HQD 槽位分别保存 KIQ、HIQ、A、B 的队列状态。相关队列已经配置后，CP 需要从这些状态找到命令，并决定下一次提交谁的任务。

```text
CP 开始一轮检查
  │
  ├─ 检查 KIQ、HIQ，各处理至多一条可处理的管理命令
  │
  └─ 从上次记录的位置开始，轮流检查 A、B
          │
          ├─ 未激活或没有可处理的命令：跳过
          │   └─ 两条都没有可处理命令：回到主循环
          │
          └─ 找到一个可以执行的 Dispatch
                  │
                  ├─ 读取任务参数，提交给计算执行器
                  ├─ 等待本次 Dispatch 完成
                  ├─ 处理执行结果与完成通知
                  └─ 记录下次优先检查另一条队列
                          │
                          └─ 回到主循环
```

一次 Dispatch 可以包含多个 Work-group；本方案等待整个 Dispatch 完成，再决定下一个任务。若 A、B 始终都有可执行任务，执行顺序如下，A1、A2 表示 A 中依次提交的两个 Dispatch，B1、B2 同理：

```text
A1 执行完成 → B1 执行完成 → A2 执行完成 → B2 执行完成
```

B 没有任务时，CP 跳过 B，继续处理 A。CP 不守着空队列等待，也不要求先处理完 A 的全部任务才检查 B。每轮限制管理命令的处理数量，使持续到来的 KIQ、HIQ 命令不会令固件一直停留在管理队列的读取循环中。

固件可以用 `next_queue` 这样的软件变量记录下次先检查 A 还是 B，无需增加可配置的优先级或时间片寄存器。A、B 的 HQD 可以始终保持驻留；从处理 A 改为处理 B 时，CP 改为读取 B 的 HQD 和 Ring，无需因此把 A 换出、把 B 换入。

Ring 读位置怎样推进、结果怎样对 Host 可见、何时更新完成 Signal，仍需在取包和执行器接口中明确。这里确定的是队列选择顺序和一次计算的执行边界。

### 5.2 阻塞等待的行为与限制

第一版先采用最简单的等待方式：提交任务后，CP 轮询计算执行器的完成状态，期间暂不处理 A、B、KIQ、HIQ 中的其他命令。计算执行器继续推进当前任务；阻塞的是 CP 固件对后续队列命令的处理。Host 在 Ring 有空位时仍可继续发布命令。

例如 A1 执行 100 ms，这 100 ms 内 B1 会等待，新到达的管理命令也会等待。A1 完成后，CP 才处理结果并回到主循环。若 A1 一直不结束，普通队列处理也会停住；超时、中止和复位后的收尾需要另行定义。

轮流选择保证的是两条就绪用户队列轮流获得提交机会，不能保证相同的计算时间。A1 很长、B1 很短时，两条队列占用计算执行器的时间仍可能相差很大。第一版接受这一限制，不做运行中的任务抢占。

### 5.3 四个寄存器暂不采用的原因

- `CP_HQD_PERSISTENT_STATE` 包含预加载、切换和恢复相关的控制及状态字段。第一版不实现这些预加载和运行中恢复功能，因此暂不采用。队列的 Ring 地址、消费进度等仍由各自的 HQD 字段保存；[第 1 节](#1-mqd-基址)确认的 MQD 基址及换出时保存队列状态的用途也继续保留。
- `CP_HQD_PIPE_PRIORITY` 对应的管线优先级机制尚未纳入本版。当前由一个 CP 执行固定的队列选择规则，没有需要通过该寄存器配置的 Pipe 优先级策略。
- `CP_HQD_QUEUE_PRIORITY` 用于表达队列优先级。本版 A、B 按固定规则轮流获得提交机会；管理队列的检查顺序写在固件流程中，因此暂不提供可配置的队列优先级。
- `CP_HQD_QUANTUM` 包含时间片使能、尺度、持续长度和活动状态。本版在 Dispatch 完成后选择下一个任务，不按时间片期限切换，因此暂不采用。

> **[SOURCE]** 四个寄存器的字段依据为仓库固定 Linux 版本 `248951ddc14de84de3910f9b13f51491a8cd91df`，[drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_sh_mask.h](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_sh_mask.h#L16341-L16382) 的 [16341–16382 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_sh_mask.h#L16341-L16382)。字段定义用于核对名称和组成；本节的取舍及执行流程属于实验设计。

规格表保留这四行及 AMD 参考偏移，标记为“不采用”。这些参考位置不因本轮取舍而重新编号，也不因此成为实验中已实现的寄存器接口。

### 5.4 后续扩展方向

以下是可选方向，尚未纳入本版实现要求；需要时再确认具体范围和寄存器语义。

**参考 ZynqMP PMU Firmware 的裸机事件循环。** 后续以 AMD/Xilinx 开源的 `Xilinx/embeddedsw` 中 `lib/sw_apps/zynqmp_pmufw` 为实现参考，重点阅读 `xpfw_core.c`、`xpfw_scheduler.c` 和 `xpfw_interrupts.c`。固件自行维护任务表，由定时器中断标记到期任务，再由主循环执行回调。

以下追踪 PMU 固件的定时任务路径，假设核心已就绪，启用了 `ENABLE_SCHEDULER`、`SLEEP_WHEN_IDLE`，且调度器成功启动。其他设备中断有各自的处理入口，不要求全部经过这张定时任务表。

```text
固件登记任务：保存回调函数与执行间隔
  → 启动调度器，配置定时器并使能对应中断
  → 主循环调用 mb_sleep()，等待中断唤醒
  → 定时器中断调用节拍处理函数
      → 更新节拍计数，标记本次需要执行的任务
  → 中断返回，主循环调用 XPfw_SchedulerProcess()
      → 扫描任务表，依次执行已触发任务的回调
      → 当前回调返回后，继续处理后面的任务
  → 本轮处理结束，再次等待中断
```

`xpfw_core.c` 中的 `CorePtr` 指向固件核心对象，其 `Scheduler` 成员保存调度器状态。下面保留讨论中的主循环骨架；这是教学简化，省略就绪检查、条件编译、启动错误处理和中断使能，完整上下文见后面的源码索引。

```c
XPfw_SchedulerStart(&CorePtr->Scheduler);

do {
    mb_sleep();  // 等待中断唤醒

    XPfw_SchedulerProcess(&CorePtr->Scheduler);
} while (TRUE);
```

其中，`XPfw_SchedulerTickHandler()` 更新节拍并标记任务；`XPfw_SchedulerProcess()` 按任务表顺序直接调用已触发任务的回调。这里采用协作式回调调度：前一个回调返回后，主循环才能调用下一个。若某个回调一直等待计算结束，后续回调仍会被推迟；定时器中断可以标记任务，但不会自动把当前回调换成另一个任务。

> **[SOURCE] 可选源码索引**
>
> 本节参考 `Xilinx/embeddedsw` 的 `xilinx_v2025.1`，固定提交 `c0aed2eff7a30f307238ec853fa8fbc45dcabdda`。以下路径均位于该仓库的 `lib/sw_apps/zynqmp_pmufw/src/`：
>
> - 核心主循环：[xpfw_core.c](https://github.com/Xilinx/embeddedsw/blob/c0aed2eff7a30f307238ec853fa8fbc45dcabdda/lib/sw_apps/zynqmp_pmufw/src/xpfw_core.c#L351-L383) 的 [351–383 行](https://github.com/Xilinx/embeddedsw/blob/c0aed2eff7a30f307238ec853fa8fbc45dcabdda/lib/sw_apps/zynqmp_pmufw/src/xpfw_core.c#L351-L383)给出调度器启动、条件编译控制的休眠及任务处理；[324–332 行](https://github.com/Xilinx/embeddedsw/blob/c0aed2eff7a30f307238ec853fa8fbc45dcabdda/lib/sw_apps/zynqmp_pmufw/src/xpfw_core.c#L324-L332)把核心节拍处理转交给调度器。
> - 调度器：[xpfw_scheduler.c](https://github.com/Xilinx/embeddedsw/blob/c0aed2eff7a30f307238ec853fa8fbc45dcabdda/lib/sw_apps/zynqmp_pmufw/src/xpfw_scheduler.c#L25-L44) 的 [25–44 行](https://github.com/Xilinx/embeddedsw/blob/c0aed2eff7a30f307238ec853fa8fbc45dcabdda/lib/sw_apps/zynqmp_pmufw/src/xpfw_scheduler.c#L25-L44)判断任务是否到期；[89–162 行](https://github.com/Xilinx/embeddedsw/blob/c0aed2eff7a30f307238ec853fa8fbc45dcabdda/lib/sw_apps/zynqmp_pmufw/src/xpfw_scheduler.c#L89-L162)包含定时器启停、节拍更新和回调执行；[164–190 行](https://github.com/Xilinx/embeddedsw/blob/c0aed2eff7a30f307238ec853fa8fbc45dcabdda/lib/sw_apps/zynqmp_pmufw/src/xpfw_scheduler.c#L164-L190)登记任务的间隔和回调。
> - 中断入口：[xpfw_interrupts.c](https://github.com/Xilinx/embeddedsw/blob/c0aed2eff7a30f307238ec853fa8fbc45dcabdda/lib/sw_apps/zynqmp_pmufw/src/xpfw_interrupts.c#L156-L159) 的 [156–159 行](https://github.com/Xilinx/embeddedsw/blob/c0aed2eff7a30f307238ec853fa8fbc45dcabdda/lib/sw_apps/zynqmp_pmufw/src/xpfw_interrupts.c#L156-L159)调用核心节拍处理函数；[260–279 行](https://github.com/Xilinx/embeddedsw/blob/c0aed2eff7a30f307238ec853fa8fbc45dcabdda/lib/sw_apps/zynqmp_pmufw/src/xpfw_interrupts.c#L260-L279)读取待处理中断、调用对应处理函数并确认中断。

**[BOUNDARY]** PMU Firmware 是平台管理固件，本节借鉴其裸机任务表、定时触发、中断分发和主循环组织方式，不据此推断 AMD GPU 的 MEC 实现。`mb_sleep()` 是原平台的等待操作；用于本实验时，需要接入 RV32 CP 自身的定时器、中断和等待唤醒机制。

**计算期间继续处理管理命令。** 参考上述组织方式，可以把一次长等待拆成多次短处理：提交计算后返回主循环，后续通过状态检查或完成事件继续处理结果。裸机主循环可以按下面的规则推进：

```text
执行器忙：
    检查是否完成
    处理当前允许执行的管理命令
    暂不提交新的计算任务

执行器完成或空闲：
    有已完成任务时，先处理执行结果与完成通知
    从 A、B 中选择下一个可执行的 Dispatch
```

这个方向需要提交接口及时返回，让计算执行器继续运行，同时让 CP 能检查状态。各处理函数执行有限步骤后返回；没有待处理工作时，再通过中断等待下一次事件。还要明确计算期间允许执行哪些管理命令；停止或卸载正在执行的队列时，必须等待相关访问结束后才能释放资源。它可以改善管理命令的响应，但 B 的计算任务仍需等待 A 让出执行器。

**增加队列优先级。** 如果需要 A 比 B 更优先，可以重新考虑 `CP_HQD_QUEUE_PRIORITY`，定义执行器空闲时怎样选择队列，以及怎样避免低优先级队列长期得不到提交机会。只有实际引入对应的 Pipe 优先级机制后，再考虑 `CP_HQD_PIPE_PRIORITY`。

**增加时间片或更细的执行切换。** 先明确时间片计量的是 CP 处理命令的时间，还是队列占用计算资源的时间，并规定到期后的动作。若希望在一个 Dispatch 完成前转去执行另一条队列，计算执行器需要提供相应的切换边界；若要中途暂停并恢复正在执行的计算，还需要保存和恢复计算上下文。然后再决定是否引入 `CP_HQD_QUANTUM`，以及需要哪些切换、恢复状态字段，不能只增加寄存器就认为抢占已经完成。

## 6. 主 Ring 地址、进度与通知

**[DESIGN]** 第一版采用本节的 9 个功能寄存器，用于定位 Ring、保存消费进度、交换读写进度，以及配置 Doorbell 和 Ring 控制。规格表中 `0x1255` 对应保留位置，继续留空。

本次确认寄存器的用途；具体位域、计数单位、回绕规则和更新时机仍需后续讨论。

### 6.1 Ring 的定位与命令消费

以 Queue A 为例：Host 已为它准备命令 Ring，以及两个保存读写进度的内存位置。CP 处理这条队列时，需要找到 Ring、知道从哪里继续读取，并取得 Host 发布的写进度。这组 HQD 寄存器保存的内容如下：

```text
Queue A 的 HQD
  │
  ├─ CP_HQD_PQ_BASE / CP_HQD_PQ_BASE_HI
  │    → 保存 Ring 基址编码，解码后找到命令 Ring
  │
  ├─ CP_HQD_PQ_RPTR
  │    → 保存当前消费进度，用于确定下一个读取位置
  │
  ├─ CP_HQD_PQ_RPTR_REPORT_ADDR / CP_HQD_PQ_RPTR_REPORT_ADDR_HI
  │    → 指定读进度的回报地址；设备向该处写入进度，Host 读取
  │
  ├─ CP_HQD_PQ_WPTR_POLL_ADDR / CP_HQD_PQ_WPTR_POLL_ADDR_HI
  │    → 指定写进度的读取地址；Host 向该处写入进度，设备读取
  │
  ├─ CP_HQD_PQ_DOORBELL_CONTROL
  │    → 配置与这条队列关联的 Doorbell 通知
  │
  └─ CP_HQD_PQ_CONTROL
       → 配置 Ring 容量及相关处理模式
```

CP 根据 Ring 地址、容量和读写进度定位命令，并按发布协议判断命令包是否可以处理。消费进度通过指定的内存位置回报后，Host 就能读取它。Ring 中保存的是命令包，两个进度位置保存的是数字，它们承担不同的用途。

AMD 驱动填写 `CP_HQD_PQ_BASE` 和 `CP_HQD_PQ_BASE_HI` 对应的 MQD 字段时，先把 Ring 的字节地址右移 8 位，再拆成低位和高位。因此，后面例子中的“Ring 基址”指解码后的地址，不能直接当作 `CP_HQD_PQ_BASE` 的原始寄存器值。

> **[SOURCE]** 仓库固定 Linux 版本 `248951ddc14de84de3910f9b13f51491a8cd91df`，[drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c#L271-L293) 的 [271–293 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c#L271-L293)：`update_mqd()` 从队列属性填写 Ring 容量、右移后的 Ring 地址、`read_ptr` 与 `write_ptr` 的地址，以及 Doorbell 偏移。这段代码说明这些配置怎样进入 MQD；字段装入 HQD 的关系见第 1 节。

### 6.2 Ring 内的读位置与进度存放地址

**下面是用于区分数值与地址的教学例子。** 假设 Queue A 的 Ring 可放 8 个包，每包 64 字节，读写进度都按包编号计数，当前尚未回绕。设备已消费编号 0、1、2 的包，所以下一个读取编号为 3；Host 已发布编号 0 至 4 的包，下一个写入编号为 5。

```text
Ring 基址：0x8000_0000
当前读进度：3
当前写进度：5

读进度 3
  → 换算成 Ring 内字节偏移：3 × 64 = 192 = 0x00c0
  → 下一条命令地址：0x8000_0000 + 0x00c0 = 0x8000_00c0
```

因此，“Ring 中读到了哪里”需要结合基址和进度单位计算。这里的 `3` 是进度值，`0x00c0` 是换算后的字节偏移，`0x8000_00c0` 才是要读取的命令地址。

接着看 Host 怎样知道读进度。设备把数字 `3` 写到另外一个约定的内存位置：

```text
CP_HQD_PQ_RPTR_REPORT_ADDR 与对应 HI
合起来保存：0x9000_0000
                │ 指定设备把读进度写到这里
                ▼
内存地址 0x9000_0000 中保存：3
                │
                └─ Host 读取，得知设备消费进度
```

这对寄存器保存的是**“到哪里回报读进度”**。其中的地址 `0x9000_0000` 指向一个存放进度数字的位置；该位置里的内容 `3` 才表示 Ring 的消费进度。

写进度的传递方向相反。Host 发布命令时维护写进度，设备从指定地址读取这个数字：

```text
Host 把写进度数字写入一个内存位置
例如：内存地址 0x9000_0008 中保存 5
                ▲
                │ 设备根据这个地址读取写进度
                │
CP_HQD_PQ_WPTR_POLL_ADDR 与对应 HI
合起来保存：0x9000_0008
```

这对寄存器保存的是**“到哪里读取写进度”**。例子中的 `5` 表示 Host 已发布到编号 4 的包；设备结合自己的读进度 `3`，知道接下来还有编号 3、4 的包可检查。

两个进度存放位置不要求处于 Ring 命令区内。图中地址均为假定的设备可访问地址；Host 通过自己的映射访问相应内存，不要求双方使用相同的虚拟地址。具体放在什么内存、使用哪种地址及如何保证可见性，仍由后续接口定义。

**[BOUNDARY]** 本例中的包编号只用于讲清“进度值、Ring 内偏移、进度存放地址”三者的关系，不规定 AMD HQD 寄存器的原始编码，也不确定实验的计数单位。消费进度表示命令消费情况，不能单凭它判断 Kernel 已执行完成；完成通知仍需按 Signal 和执行器接口处理。

> **[SOURCE]** 同一固定 Linux 版本，[drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c#L259-L269) 的 [259–269 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdkfd/kfd_mqd_manager_v9.c#L259-L269)在 `load_mqd()` 中根据 AQL 格式设置写指针换算参数。注释区分了按 64 字节包计数的软件 AQL 写指针和按 32 位字计数的 CP 写指针，说明不能把所有位置的进度数值直接视为同一种单位。

### 6.3 Doorbell 与 Ring 控制

`CP_HQD_PQ_DOORBELL_CONTROL` 保存队列 Doorbell 的偏移、使能及相关模式，使设备能把通知与这条队列关联起来。它保存的是 Doorbell 配置；Host 发布命令后，按提交协议写对应的 Doorbell 入口进行通知。

`CP_HQD_PQ_CONTROL` 保存 Ring 容量和相关处理模式。采用这个寄存器后，仍需逐项确定第一版实际支持哪些字段；AMD 定义中的读指针回报、写指针模式、执行限制、权限等功能，不会仅因采用寄存器名称就全部成为本版要求。

**[DESIGN]** 第一版保留写进度轮询地址，也保留 Doorbell 控制。两者怎样配合仍待确认：采用这些寄存器尚未规定 CP 必须一直轮询，也未规定每次收到 Doorbell 都重新读取内存中的写进度。后续需明确通知携带的内容、CP 何时读取写进度，以及读进度何时回报；这些规则与命令包的发布顺序一起确定。

> **[SOURCE]** 仓库固定 Linux 版本 `248951ddc14de84de3910f9b13f51491a8cd91df`，[drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_sh_mask.h](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_sh_mask.h#L16383-L16455) 的 [16383–16455 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_sh_mask.h#L16383-L16455)给出本组寄存器的字段定义，包括 Doorbell 偏移与使能、Ring 容量、写指针模式和读指针更新控制。这些定义用于核对 AMD 字段；完整提交协议还需结合驱动和队列规范确认。

## 7. 第一版不引入 IB

本节对应 `CP_HQD_IB_BASE_ADDR`、`CP_HQD_IB_BASE_ADDR_HI`、`CP_HQD_IB_RPTR` 和 `CP_HQD_IB_CONTROL`。

**[DESIGN]** 第一版不引入 IB，这四个寄存器均不采用。KIQ／HIQ 的管理命令和用户 AQL Packet 直接放入各自的 Ring，由 CP 读取和处理。

### 7.1 KIQ 管理队列与 AQL 计算提交

第一版要完成的过程是：Host 先让 CP 配置用户队列，再通过用户队列提交计算。下面沿用已确定的队列分工，展示拟实现的命令路径：

```text
KIQ／HIQ Ring 中放 MAP_QUEUES
    → CP 根据 MQD 配置目标 HQD
    → 用户队列可以被 CP 处理

用户 AQL Ring 中放 Dispatch Packet
    → CP 根据包中的信息启动 Kernel
    → 等待本次计算完成，处理结果与完成 Signal
```

KIQ 是用于管理队列的入口；AQL Dispatch Packet 用于描述一次计算派发。这两条路径都可以直接从 Ring 取得命令包，不需要先把命令包装成 IB。第一版的 KIQ、HIQ 分工属于实验约定，具体管理命令格式仍需继续确定。

AMD 的 KIQ 也有直接写入 `MAP_QUEUES` 的实现：驱动将命令包及目标队列、MQD 地址等参数写进 KIQ Ring。因此，“每条 KIQ 命令都要先封装成一个 IB”不符合这条实际路径。

> **[SOURCE]** 仓库固定 Linux 版本 `248951ddc14de84de3910f9b13f51491a8cd91df`，[drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L199-L227) 的 [199–227 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L199-L227)，`gfx_v9_4_3_kiq_map_queues()` 直接向 `kiq_ring` 写入 `PACKET3_MAP_QUEUES` 和相应参数。

### 7.2 IB 保存 Ring 引用的一批命令

下面转到 AMD 的另一种计算提交方式：软件生成 PM4 命令，通过 PM4 计算 Ring 提交。这与上一节的用户 AQL 包格式不同，也不是把计算任务放到 KIQ 中。

假设软件需要提交配置资源、设置参数和启动计算等多条命令。软件可以先把这些命令集中放在一块独立内存中，这块命令缓冲区就叫 IB（Indirect Buffer，间接命令缓冲区）。Ring 中再放一条携带 IB 地址和长度的 `INDIRECT_BUFFER` 命令，让 CP 去读取它：

```text
PM4 计算 Ring
    │
    └─ INDIRECT_BUFFER：去地址 X，读取长度为 L 的命令
                   │
                   │ CP 根据地址读取
                   ▼
             Ring 外的 IB
               配置命令 1
               配置命令 2
               启动计算的命令
```

CP 从 Ring 取得 IB 地址，再去 IB 中解析命令；这段命令处理结束后，继续读取 Ring 的后续命令。这里说的是命令读取与处理的顺序，计算本身是否已经完成，仍需按同步和完成通知的语义判断。

IB 让软件可以在独立内存中准备一批命令，提交时向 Ring 写入引用。Ring 不必容纳整批命令，也不必为了提交而再接收一份完整的命令副本。IB 中保存的是 CP 命令；Kernel 机器码和参数是这些命令可能引用的其他对象。

例如软件准备了 IB A、IB B，驱动向计算 Ring 写入两条引用命令：

```text
IB A 中：命令 1、命令 2、命令 3
IB B 中：命令 4、命令 5

计算 Ring 中：
    INDIRECT_BUFFER（A 的地址、长度）
    INDIRECT_BUFFER（B 的地址、长度）
```

这就是“逐个提交 IB”：驱动逐条写入引用命令，CP 再逐块读取 IB。固定源码中，Host 驱动用 `job->ibs[]` 数组描述一个任务的多个 IB，并遍历数组完成提交。数组记录各块 IB 的地址、长度等信息；该路径传给 CP 的是每块 IB 的引用命令，没有把 Host 数组地址作为一个“IB 列表基址”交给 CP。

KIQ 表示一条管理队列，IB 表示一种命令存放方式，两者没有一一对应的封装关系。上面的 IB 示例用于说明 PM4 计算提交，不改变第一版选定的“KIQ／HIQ 管理 + 用户 AQL 派发”路径。

> **[SOURCE] 可选源码索引**
>
> 以下均来自固定 Linux 版本 `248951ddc14de84de3910f9b13f51491a8cd91df`：
>
> - IB 的定义与读取后返回 Ring 的关系：[Documentation/gpu/amdgpu/driver-core.rst](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/Documentation/gpu/amdgpu/driver-core.rst#L177-L182) 的 [177–182 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/Documentation/gpu/amdgpu/driver-core.rst#L177-L182)。
> - Ring 引用外部命令缓冲区，使 Ring 可以保持较小容量：[Documentation/gpu/amdgpu/ring-buffer.rst](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/Documentation/gpu/amdgpu/ring-buffer.rst#L25-L30) 的 [25–30 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/Documentation/gpu/amdgpu/ring-buffer.rst#L25-L30)。
> - 驱动遍历 IB 数组，逐个向 Ring 提交：[drivers/gpu/drm/amd/amdgpu/amdgpu_ib.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_ib.c#L272-L285) 的 [272–285 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_ib.c#L272-L285)。
> - GC 9.4.3 的计算 Ring 写入 `INDIRECT_BUFFER` 包及 IB 地址、长度：[drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L2922-L2955) 的 [2922–2955 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfx_v9_4_3.c#L2922-L2955)。

### 7.3 IB 寄存器记录当前读取状态

支持 IB 的队列在处理一块 IB 时，需要记录当前缓冲区及其消费位置。这四个 AMD 寄存器保存的是当前 IB 的信息：

- `CP_HQD_IB_BASE_ADDR` 和 `CP_HQD_IB_BASE_ADDR_HI` 共同保存当前 IB 基址，指向那块命令缓冲区。
- `CP_HQD_IB_RPTR` 保存当前 IB 内的消费位置，用于继续读取其中的命令。
- `CP_HQD_IB_CONTROL` 包含当前 IB 的长度，以及执行禁止、缓存策略、权限和正在处理 IB 等控制、状态字段。

因此，IB 基址寄存器不用于保存 Host 的 `job->ibs[]` 数组地址，IB 读指针也不是“已处理了几个 IB”的计数。地址、长度和进度只描述读取状态，IB 中的命令仍保存在被引用的内存中。

> **[SOURCE]** 固定 Linux 版本 `248951ddc14de84de3910f9b13f51491a8cd91df`，[drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_sh_mask.h](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_sh_mask.h#L16456-L16477) 的 [16456–16477 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_sh_mask.h#L16456-L16477)定义了本组寄存器的地址、`CONSUMED_OFFSET`、`IB_SIZE` 和控制、状态字段。

### 7.4 第一版直接从 Ring 处理命令

**[DESIGN]** 第一版的 CP 根据所选 HQD 找到 Ring，直接读取该队列格式规定的管理命令或 AQL Packet，并按[第 5 节](#5-第一版队列选择与后续调度扩展)的固定规则处理。每次提交一个 Dispatch，阻塞等待完成后再轮换队列。

本版不实现 `INDIRECT_BUFFER` 命令及 IB 遍历，不分配用于复制 IB 的缓冲区，也不维护软件 IB 列表、基址或读取游标。规格表保留这四行 AMD 参考项及其偏移，均标记为“不采用”。

MQD、Kernel 描述对象、代码和参数仍可保存在 Ring 外的内存中，由相应命令字段引用。CP 读取这些对象是为了配置队列或派发计算；这不属于从 IB 中继续读取另一段 CP 命令的流程。

管理命令的成功、失败确认方式，以及完成 Signal 的具体接口，继续在[规格第 3 节](<./CP_MEC 第一版规格.md#3-后续讨论与补充>)中讨论。

## 8. 第一版不引入 IQ

本节对应 `CP_HQD_IQ_TIMER` 和 `CP_HQD_IQ_RPTR`。

**[DESIGN]** 第一版不采用这两个寄存器。当前方案由 CP 固件轮询计算执行器的完成状态，不建立 IQ 命令缓冲区，也不维护 IQ 读取进度。规格表保留这两行 AMD 参考项及原有偏移，标记为“不采用”。

### 8.1 固件轮询计算完成

沿用[第 5 节](#5-第一版队列选择与后续调度扩展)的固定队列选择规则，假设 CP 已从 Queue A 取得一个可以执行的 Dispatch，接下来需要提交计算并等待结果：

```text
CP 从 Queue A 读取一个 Dispatch
        │
        ├─ 提交给计算执行器
        │
        ├─ 循环读取执行器状态
        │      ├─ 未完成：继续等待
        │      └─ 已完成：处理结果与完成 Signal
        │
        └─ 回到主循环，检查管理队列，再轮到 Queue B
```

等待由 CP 固件的普通循环完成。固件停留在当前处理流程里，计算执行器继续推进任务；这个流程无需把待重试操作交给 IQ，也就没有 IQ 内容需要用 `IQ_RPTR` 记录读取位置。

在 A 的计算结束前，CP 暂不处理 B 和新到达的 KIQ、HIQ 管理命令。若 A 一直不完成，普通队列处理也会停住；超时、中止和复位后的收尾仍需另行确定。增加 IQ 寄存器本身不能解决这些问题。这里记录的是已确定的实现方案，队列功能尚未完成接入和验证。

### 8.2 AMD IQ 的已知字段与待核实行为

AMD GC 9.4.3 的 `CP_HQD_IQ_TIMER` 包含 `WAIT_TIME`、`RETRY_TYPE`、`REARM_TIMER`、`PROCESS_IQ_EN` 和 `PROCESSING_IQ` 等字段，对应等待时间、重试类型、重新计时、处理使能和处理状态。`CP_HQD_IQ_RPTR` 公开了一个 6 位的 `OFFSET` 字段。

> **[SOURCE]** 仓库固定 Linux 版本 `248951ddc14de84de3910f9b13f51491a8cd91df`，[drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_sh_mask.h](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_sh_mask.h#L16478-L16509) 的 [16478–16509 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/include/asic_reg/gc/gc_9_4_3_sh_mask.h#L16478-L16509)给出这两个寄存器的字段定义。

**[BOUNDARY]** 上述字段支持将 IQ 与等待、重试处理联系起来，但尚不能据此还原 AMD 的完整执行流程。IQ 读取偏移的参照位置、单位和推进规则仍未核实；第一版不把这些推测固定为实验寄存器语义。

### 8.3 后续通过事件循环推进等待任务

后续若需要在等待计算完成期间继续处理允许执行的管理命令，可以先沿[第 5.4 节](#54-后续扩展方向)的 ZynqMP PMU Firmware 裸机事件循环方向扩展。提交接口需要及时返回，让计算执行器继续运行，同时让 CP 返回主循环：

```text
提交 A 的计算
    → 固件在自己的内存中记录“A 正在执行”
    → 返回主循环，处理允许执行的其他工作
    → 后续检查完成状态，或收到完成事件
    → 继续完成 A 的收尾
```

这时，固件内存可以保存等待状态；采用事件循环本身不要求引入 `CP_HQD_IQ_TIMER` 或 `CP_HQD_IQ_RPTR`。计算执行器一次处理一个 Dispatch 的约束仍然成立，B 的计算任务需要等 A 完成后再提交。该扩展尚未纳入第一版实现要求。

只有后续设计明确要求 QEMU 设备模型独立承担定时重试、读取 IQ 命令，并需要通过 HQD／MQD 配置或保存恢复这些状态时，再讨论相应寄存器接口及其具体语义。
