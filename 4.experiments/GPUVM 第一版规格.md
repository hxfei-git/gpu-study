# GPUVM 第一版规格

| 缩写   | 英文全称                                               | 中文含义                                                    |
| ------ | ------------------------------------------------------ | ----------------------------------------------------------- |
| GPUVM  | GPU Virtual Memory                                     | GPU 虚拟内存；设备地址空间及其映射管理                      |
| VM     | Virtual Memory                                         | 虚拟内存；本文指 GPU 地址空间及其上下文                     |
| GPUVA  | GPU Virtual Address                                    | GPU 虚拟地址                                                |
| GPU    | Graphics Processing Unit                               | 图形处理器                                                  |
| CPU    | Central Processing Unit                                | 中央处理器                                                  |
| QEMU   | Quick Emulator                                         | 仿真与虚拟化工具                                            |
| GPGPU  | General-Purpose Computing on Graphics Processing Units | 利用 GPU 进行通用计算；本项目的教学设备                     |
| DRM    | Direct Rendering Manager                               | Linux 图形设备内核框架                                      |
| GEM    | Graphics Execution Manager                             | DRM 图形内存对象管理框架                                    |
| BO     | Buffer Object                                          | 保存实际存储及其属性的缓冲对象                              |
| TTM    | Translation Table Maps                                 | Linux 图形内存管理框架；AMDGPU 用于管理对象的存储位置与迁移 |
| PTE    | Page Table Entry                                       | 页表叶子项，保存目标页地址和权限                            |
| PDE    | Page Directory Entry                                   | 页目录项，定位下一级页表                                    |
| GART   | Graphics Address Remapping Table                       | 图形地址重映射表；用于说明 AMDGPU 管理上下文的翻译          |
| MMU    | Memory Management Unit                                 | 内存管理单元                                                |
| TLB    | Translation Lookaside Buffer                           | 地址翻译缓存                                                |
| VMID   | Virtual Memory Identifier                              | 设备虚拟地址空间标识；用于选择页表上下文                    |
| CP     | Command Processor                                      | 命令处理器                                                  |
| MEC    | Micro Engine Compute                                   | 计算命令处理微引擎；用于第二阶段规格题名                    |
| HQD    | Hardware Queue Descriptor                              | 保存队列驻留状态的硬件描述                                  |
| MQD    | Memory Queue Descriptor                                | 内存中的队列描述对象                                        |
| KIQ    | Kernel Interface Queue                                 | 内核接口队列                                                |
| HIQ    | HSA Interface Queue                                    | HSA 接口队列                                                |
| IH     | Interrupt Handler                                      | 中断记录与分发模块                                          |
| IRQ    | Interrupt Request                                      | 中断请求；本文沿用独立错误中断路径                          |
| ACK    | Acknowledgment                                         | 确认；本文用于翻译失效完成确认                              |
| HSA    | Heterogeneous System Architecture                      | 异构系统架构                                                |
| HSAKMT | HSA Kernel Mode Thunk                                  | HSA 用户态与 KFD 内核接口之间的调用封装                     |
| KFD    | Kernel Fusion Driver                                   | AMD GPU 计算相关内核驱动组件                                |
| AQL    | Architected Queuing Language                           | HSA 定义的队列包格式与提交协议                              |
| RV32   | 32-bit RISC-V                                          | 本实验计算执行器使用的 32 位 RISC-V 模型                    |
| RV64   | 64-bit RISC-V                                          | 本实验原生 CP 使用的 64 位 RISC-V 模型                      |
| VRAM   | Video RAM                                              | 教学设备的显存后备存储                                      |
| RAM    | Random Access Memory                                   | 随机存取存储器；Host RAM 与 VRAM 分开                       |
| DMA    | Direct Memory Access                                   | 直接内存访问                                                |
| IOVA   | I/O Virtual Address                                    | 设备通过系统 IOMMU 访问内存时使用的地址                     |
| IOMMU  | Input/Output Memory Management Unit                    | 输入输出内存管理单元                                        |
| SMMUv3 | System Memory Management Unit version 3                | Arm 系统内存管理单元第三版                                  |
| BAR    | Base Address Register                                  | PCI 设备基址寄存器；描述设备资源窗口                        |
| PCI    | Peripheral Component Interconnect                      | 外设互连总线                                                |
| API    | Application Programming Interface                      | 应用编程接口                                                |

本文是第三阶段的**收敛版规格草案，日期为 2026-10-19**。按本轮目标，首版只完成固定存储下的 GPUVM：应用申请对象，设备按页表访问，两个进程相互隔离，任务结束后安全回收。第三阶段验收完成后整理项目演示和实现说明，用于求职；换页等扩展不作为开始面试的前提。

**[DESIGN]** 正文按一套最小方案展开，供本轮规格对齐。沿用 AMDGPU 的对象与映射分离、按上下文翻译、权限检查和失效同步关系，针对教学设备固定容量并限制动态操作。下文的具体配置仍属草案，尚未接入 DRM/GEM 或设备 GPUVM；本轮缩小范围不表示代码已完成或所有参数已确认。

建议先读第 1 节的使用流程，再读第 2～7 节的对象、访问和回收，最后检查第 9 节的范围记录。推进顺序与验收统一维护在[第三阶段大纲](<./QEMU GPGPU 实验大纲.md#stage-three-vmid>)。

<a id="gpuvm-overview"></a>

## 1. 首版目标与应用使用流程

### 1.1 用 GPUVA 完成一次向量加法

应用 A 要计算 `Z[i] = X[i] + Y[i]`。Host 准备数组、代码和参数，Kernel 使用 GPUVA 读取这些对象。应用 B 可以使用相同 GPUVA，由自己的页表指向另一份存储。

```text
打开设备 → 驱动建立应用地址空间
  → 准备全部对象：分配实际存储、建立 GPUVA 映射、填写内容
  → 创建用户 Queue：MQD/HQD 关联该地址空间的 VMID
  → 向 Ring 发布 AQL，通知 Doorbell
  → CP 按 VMID 翻译用户 Ring、描述对象和完成对象
  → 执行器按同一 VMID 翻译代码、参数和数组访问
  → 写回结果，CP 更新 Signal、通知槽和 IH
  → 应用可继续提交，重复使用已经准备好的对象
  → 停止提交、排空并销毁 Queue
  → 撤销映射、等待 TLB 失效，再回收对象和地址空间
```

首版保留五项能力：DRM/GEM 对象管理、完整用户访存翻译、双进程隔离、同步 TLB 失效及 VMID 复用、基本故障退出与正常回收。CP 继续为 RV64 裸机固件，计算执行器继续为 RV32；全设备仍有两个用户 Queue 名额，首版每个 VM 最多一条用户 Queue，Kernel 执行中途不切换。

> **[SPEC]** [CP/MEC 第一版规格，第 1 节](<./CP_MEC 第一版规格.md#spec-overview>)及[用户队列名额](<./CP_MEC 第一版规格.md#spec-user-queue-capacity>)，2026-10-19 状态：4 个 HQD 用于 KIQ、HIQ 和两个动态用户队列。第三阶段沿用设备容量，增加每个 VM 最多一条用户队列的首版限制。

### 1.2 先准备、重复运行、统一释放

库的普通内存申请同时完成对象创建和 GPU 映射，返回对象句柄、CPU 访问入口及 GPUVA。调用方默认由库选址，不必逐对象操作页表、VMID 或失效寄存器。VRAM 内容继续通过已有上传、下载入口准备和读取。

创建 Queue 前准备好 Ring、进度、代码、描述对象、参数、数组及 Signal 的存储。事件在建 Queue 后关联并分配已有通知槽，再填写 Signal，不增加 GPU 映射。Queue 存活期间可以更新任务数据并重复提交，但保持对象存储位置和 GPU 映射不变；数据的读写仍遵守第二阶段发布与等待协议。确需申请新的 GPU 映射或释放旧对象时，先排空并销毁 Queue，再操作内存并重建 Queue。驱动拒绝不满足条件的请求。

首版每个 BO 只建立一段覆盖整个对象的 GPU 映射，不支持别名、部分撤销、隐式替换或跨进程共享。底层保留同步 `MAP/UNMAP` 便于实现和验证，普通应用由库封装。固定地址只作为隔离测试入口使用，仍执行完整校验。

**[BOUNDARY]** 本期不接入 TTM，不做存储迁移、显存驱逐、换页或缺页恢复，也不在设备缺页时分配后备存储。对象创建时取得全部存储，并持有到安全释放；空间不足返回失败。这里省略的是存储动态管理和恢复，GPUVA 的分页映射、页表遍历及权限检查仍须实现。

### 1.3 AMDGPU 参考与设备边界

源码统一参考仓库 `2.源码/linux` 的固定提交 `248951ddc14de84de3910f9b13f51491a8cd91df`。对象关系按 AMDGPU 核对，MI300X 主线相关的软件路径参考 `gmc_v9_0`、`gfxhub_v1_2`。本设备的地址范围、页表层级和寄存器是教学设计，不声明兼容 MI300X 硬件。

> **[SOURCE]** 固定 Linux 源码：[amdgpu_discovery.c，第 2148～2157 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_discovery.c#L2148-L2157)为 9.4.3 选择 `gmc_v9_0`；[gmc_v9_0.c，第 1487～1493 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gmc_v9_0.c#L1487-L1493)在 `amdgpu_is_multi_aid()` 返回真时选择 `gfxhub_v1_2`；[gfxhub_v1_2.c，第 319～325 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfxhub_v1_2.c#L319-L325)标注其用于 9.4.3 变体。本文据此选择相关驱动参考路径。

CP 自身的固件取指、栈和设备寄存器访问继续使用裸机地址。普通 DRM 命令提交、完整 HSA 运行时、抢占和运行中复位恢复不在本期范围。

<a id="gpuvm-objects"></a>

## 2. 应用上下文、内存对象与实际存储

### 2.1 一个连接持有一个地址空间

应用通过现有 HSAKMT 风格库打开 DRM render node，一个 DRM 文件上下文持有一个 GPU VM。库内线程共享连接；不同文件上下文的句柄、映射、队列和事件各自管理。不增加独立计算设备与 DRM 文件的关联协议，也不支持连接继承或文件描述符传递后的队列使用。

```text
应用 A 的库连接 → DRM 文件上下文 A
                   ├─ 对象句柄 → GEM/BO → 实际存储
                   ├─ GPUVA 映射 → BO、权限、页表
                   ├─ VM → 页表根、绑定的 VMID
                   └─ 用户 Queue → Ring、进度对象和所属 VM
```

驱动创建队列时从文件上下文取得 VMID，应用不能指定其他上下文的编号或页表根。软件 VM 保存地址空间；VMID 是设备选择翻译上下文的编号；HQD 保存已驻留队列的状态，三者分别管理。

> **[SOURCE]** 固定 Linux 源码：[amdgpu.h，第 444～458 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu.h#L444-L458)在 `amdgpu_fpriv` 中保存 `amdgpu_vm`；[amdgpu_kms.c，第 1435～1477 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_kms.c#L1435-L1477)在文件打开时创建并初始化该 VM。[amdgpu_amdkfd_gpuvm.c，第 1564～1587 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gpuvm.c#L1564-L1587)将已有 VM 转为计算 VM；本实验借鉴这种内存管理关系，AQL 提交路径继续单独保留。

### 2.2 一个对象同时提供 CPU 入口与 GPUVA

Host 已为 X 申请对象，需要先写入内容，再把设备可用的地址交给 Kernel。三种数值分别使用：句柄供驱动查找对象，CPU 地址或上传入口供 Host 准备内容，GPUVA 供设备访问。

```text
句柄 H_X → BO_X：保存大小、内存域和引用
             ├─ 存储记录 → 实际 VRAM 区间或 Host 一致性内存
             ├─ CPU 入口 → Host 准备、读取内容
             └─ VM_A 的整对象映射 → GPUVA、权限 → 生成 PTE
```

BO 与映射分开记录，但首版限制为一对象一映射。Host RAM 继续使用驱动分配的一致性内存，VRAM 继续由 `gpu_buddy` 分配；对象创建时固定内存域，之后不搬动。对象逻辑大小单独保存，实际分配和映射向上对齐到 4 KiB，补出的字节初始化为零。

> **[SOURCE]** 固定 Linux 源码：[amdgpu_vm.c，第 1843～1879 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c#L1843-L1879)通过 `bo_va` 关联 BO 与 VM，检查映射重叠，并单独保存 `start`、`last`、`offset` 和 `flags`。本期保留对象与映射分离的关系，并限制为整对象单一映射。

AMDGPU 还通过 TTM 管理允许的存储位置及当前资源。本期只保留 GEM 对象和固定存储；以后若要移动 X，就需要同步旧访问、搬运内容、重写 PTE 并使旧翻译失效。仅使用 `gpu_buddy` 分配显存时，没有这些迁移能力。

> **[SOURCE]** 固定 Linux 源码：[amdgpu_object.h，第 103～115 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_object.h#L103-L115)保存允许域、placement、内嵌 TTM 对象与 VM 关联；[include/drm/ttm/ttm_bo.h，第 73～125 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/include/drm/ttm/ttm_bo.h#L73-L125)区分存储资源与驱动管理的 GPU 映射。这里用于说明未接入 TTM 的边界，不要求本期实现迁移流程。

### 2.3 沿用对象存放位置，保护管理区域

用户 Ring、进度、参数和 Signal 仍放在 Host RAM；描述对象、代码和数组仍放在 VRAM。它们统一用用户 GPUVA 引用，页表再选择 Host 或 VRAM 目标。

KIQ/HIQ Ring、MQD、管理结果区、IH、页表和固件由驱动管理，应用不能把这些区域映射成普通对象。通知槽由驱动预先建立内部映射，见[第 6 节](#gpuvm-signal)。

> **[SPEC]** [CP/MEC 第一版规格，内存对象](<./CP_MEC 第一版规格.md#spec-objects-addresses>)、[Kernel 数据存储](<./CP_MEC 第一版规格.md#spec-kernel-data-storage>)与[固件保留区](<./CP_MEC 第一版规格.md#spec-firmware-layout>)，2026-10-19 状态：普通 VRAM 为前 60 MiB，首个页保留；末尾 4 MiB 固件区不参与普通分配。第三阶段页表也从驱动管理的存储中分配并登记占用。

<a id="gpuvm-addresses"></a>

## 3. GPUVA、页表与地址翻译

### 3.1 32 位 GPUVA 与同地址隔离

首版采用 32 位 GPUVA，匹配 RV32 执行器与现有参数字段。64 位协议地址槽保持宽度，存 GPUVA 时高 32 位必须为零，超范围拒绝而不截断。Host DMA 地址槽仍为 64 位，页表目标按 48 位寻址能力校验，两类位宽分别处理。

GPUVA 零页保持未映射；固定参数窗口 `0x9000_0000～0x9000_ffff` 和内部通知页 `0xffff_f000～0xffff_ffff` 不进入普通分配范围。库默认自动选址，能力查询返回页大小和可用区间。

以下地址仅用于说明两个进程的隔离关系：

```text
Queue A → VMID 1 → 页表 A
  GPUVA 0x0040_0000 → VRAM 偏移 0x0020_0000 → X_A

Queue B → VMID 2 → 页表 B
  GPUVA 0x0040_0000 → VRAM 偏移 0x0060_0000 → X_B
```

两个 Kernel 都读取 `0x0040_0000`，设备根据所属 VMID 选择不同页表。填写其他进程使用过的地址数值，仍然只能查询当前 VM 的映射。

### 3.2 一次请求怎样找到目标页

设备已拿到 VMID、GPUVA、长度和访问类型，接下来查找允许访问的实际存储：

```text
检查 VMID 已绑定且上下文就绪
  → 查该 VMID 的 TLB
  → 未命中时，从页表根逐级读取表项
  → 检查有效位、读/写/取指权限及完整目标范围
  → 目标页地址 + 页内偏移 → 访问 VRAM 或 Host DMA
  → 返回数据或报告本次访问错误
```

页大小固定为 4 KiB，表项为 64 位小端。采用三级页表，每张表按 4 KiB 对齐并占 4 KiB，共 512 项；根目录只使用前 4 项。表页按需分配在受保护 VRAM，用户不能改写。

```text
32 位 GPUVA
  ├─ [31:30]：根目录索引，2 位
  ├─ [29:21]：下级目录索引，9 位
  ├─ [20:12]：叶页表索引，9 位
  └─ [11:0] ：页内偏移，12 位

根目录 VRAM 偏移 → 下级目录 → 叶页表 → 目标页与权限
```

例如 `0x0040_0000` 的三个索引依次为 0、2、0，页内偏移为 0。首次建立这条路径需要三张表，共 12 KiB；相邻页复用已有表。固定三级是本设备的配置。

目录项保存 `VALID` 与下一级表的 VRAM 地址。叶子项采用 AMDGPU 常用位的子集：bit 0 `VALID`、bit 1 `SYSTEM`、bit 4 `EXECUTABLE`、bit 5 `READABLE`、bit 6 `WRITEABLE`；目标地址位为 `[47:12]`，掩码为 `0x0000_ffff_ffff_f000`，其余位填零。`SYSTEM = 1` 选择 Host DMA 页，`SYSTEM = 0` 选择 VRAM 页偏移；后者是本设备简化。

完整表项写入前校验对齐、位宽及目标范围，不能靠掩码隐藏非法地址。无效项写零，不支持的有效项编码报页表错误。代码页开放读与取指，参数和输入页开放读，输出及共享状态按需要开放读写；不同权限的对象分开占页。

> **[SOURCE]** 固定 Linux 源码：[amdgpu_gart.h，第 35～38 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_gart.h#L35-L38)定义 4 KiB GPU 页；[amdgpu_vm.h，第 57～68 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.h#L57-L68)定义上述有效、区域与权限位；[amdgpu_gmc.c，第 163～175 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_gmc.c#L163-L175)将地址和标志写入 8 字节表项；[gmc_v9_0.c，第 1985～1994 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gmc_v9_0.c#L1985-L1994)设置 48 位地址掩码，并对包含 9.4.3 的分支选择 48 位 DMA 能力。[amdgpu_vm.c，第 2392～2425 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c#L2392-L2425)按空间大小计算层级及末级大小。上文固定三级和裁剪标志位是本设备设计，不声明完整硬件格式兼容。

对象和块搬运可以跨页，每一页分别检查。单次标量访问要求自然对齐且不跨页，完整 32/64 位共享字段不能拆成部分写入。跨页操作后续失败时保留先前写入，不提供回滚。

### 3.3 Host DMA 与系统 IOMMU

驱动通过 DMA API 为 Host 对象取得设备可达地址，将该地址写入 GPU 页表。GPUVA 到 Host RAM 的路径如下：

```text
用户 GPUVA + VMID → GPU MMU → Host DMA 地址
  → 现有设备 DMA 通路
      ├─ IOMMU=none   → Host RAM
      └─ IOMMU=smmuv3 → 将 IOVA 交给系统翻译 → Host RAM
```

GPUVM 选择应用地址空间，SMMUv3 处理设备 DMA。首版两层分别配置，不把 GPU VMID 当成系统 IOMMU 的进程标识。DMA 映射在对象仍可能被设备访问时保持有效。

> **[SOURCE]** 固定 Linux 源码：[amdgpu_vm.c，第 1261～1317 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c#L1261-L1317)在更新系统内存映射时取得 BO 的 `dma_address`；[amdgpu_vm_cpu.c，第 94～105 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_vm_cpu.c#L94-L105)将相应目标地址交给表项写入路径。本文沿用 DMA 地址与 GPUVA 分开的处理，不复制 TTM 的完整页管理。

已有 SMMUv3 DMA 回归继续保留；新增 GPUVM 队列还要单独运行端到端用例，不能沿用旧结果代替验证。

<a id="gpuvm-access-paths"></a>

## 4. CP、MQD 与执行器的上下文传递

### 4.1 先读管理 MQD，再按用户 VMID 访问

CP 需要先读取 MQD 才知道用户队列属于哪个地址空间。MQD 自身继续用受信任管理 DMA 地址定位，其中的用户 Ring、R 回报和 W 读取地址改为 GPUVA：

```text
HIQ 命令中的 MQD 管理 DMA 地址
  → CP 按管理域读取 MQD
  → 取得用户 VMID，以及 Ring / R / W 的 GPUVA
  → 装入 HQD → 后续取包和进度访问按该 VMID 翻译
```

保留 64 字节 MQD、现有 HQD 布局和 VMID 字段。管理 Ring、管理完成标记及 IH 继续使用管理 DMA 域；页表根放独立上下文寄存器。上下文未就绪或版本不匹配时拒绝装载，不按地址数值猜测所属域。

### 4.2 一次访存保存一次完整上下文

扩展 CP 现有访存窗口，明确选择管理 DMA 域或用户 GPUVM 域。用户 Ring、进度、描述对象、Signal 和通知槽全部走用户域；管理对象走管理域。CP 代码、栈和寄存器访问保持裸机方式。

每次请求开始时保存地址域、VMID、地址、长度和访问类型，跨进程消息与内存回调使用同一快照。切换队列后，在途请求不能重新读取已经变化的“当前 VMID”。翻译失败返回错误，禁止退回物理地址访问。

### 4.3 执行器沿用参数窗口，用户取指也需翻译

<a id="gpuvm-executor"></a>

AQL 的 `kernel_object`、`kernarg_address`、`completion_signal` 改存用户 GPUVA。16 字节描述对象保持布局，`code_entry` 改为 32 位代码 GPUVA；参数中的数组指针也改为 32 位 GPUVA。

保留只读参数窗口和 `a0 = 0x9000_0000`。执行器保存参数 GPUVA、长度及 VMID，按下面路径读取参数：

```text
读取 a0 + 12 → 检查完整访问落在参数长度内
  → 本次参数 GPUVA + 12 → 按本次 VMID 翻译
  → 读出数组 GPUVA → 数组读写继续按同一 VMID 翻译
```

代码取指同时检查声明的代码范围与页表取指权限。设备接受 Dispatch 时一次保存 VMID、代码与参数地址、长度和任务规模；执行全程使用该快照，任务忙或结果未确认时拒绝覆盖。用户地址不能指向管理寄存器或触发原始 VRAM 访问旁路。

> **[SPEC]** [CP/MEC 第一版规格，描述对象](<./CP_MEC 第一版规格.md#spec-kernel-descriptor>)及[执行器分发](<./CP_MEC 第一版规格.md#spec-executor-dispatch>)，2026-10-19 状态：描述对象为 16 字节，计算线程经固定窗口读取参数，分发时保存完整配置。本期保留执行约定，只将相关用户地址改为 GPUVA。

<a id="gpuvm-context-tlb"></a>

## 5. 固定 VMID、同步更新与 TLB 失效

### 5.1 两个用户地址空间固定驻留

VMID 0 保留受信任管理 DMA 路径，用户 VMID 为 1、2。文件打开时建立软件 VM，首次 GPU 映射时申请 VMID，持有到 VM 销毁。没有名额时返回资源不足，不驱逐其他 VM，不轮换页表根。即使两个 VM 暂未运行，只要仍持有绑定，第三个 VM 也不能取得名额。

驱动完成页表及根地址配置、发布和必要的旧翻译清理后才使上下文就绪。用户不能修改根地址、VMID 绑定或管理上下文。

> **[SOURCE]** 固定 Linux 源码：[gfxhub_v1_2.c，第 42～61 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfxhub_v1_2.c#L42-L61)按 VMID 配置页表根的低、高位；[第 328～365 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfxhub_v1_2.c#L328-L365)配置上下文使能、页表深度及访问故障检查。本设备沿用“VMID 选择根与控制状态”的关系，裁剪实例数量和参数。

**[BOUNDARY]** 管理域直通是本设备简化。AMDGPU 的 VMID 0 也有自己的 GART/页表配置，本期不复制这套管理翻译。

> **[SOURCE]** 固定 Linux 源码：[gfxhub_v1_2.c，第 74～91 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfxhub_v1_2.c#L74-L91)为 VMID 0 设置 GART/页表根，证明真实驱动的管理上下文也有自己的地址翻译配置。

### 5.2 Queue 销毁后同步修改页表

首版运行期间冻结映射。申请新 GPU 映射或撤销映射前，先停止提交，排空并销毁该 VM 的正常 Queue；权限调整也通过撤销后重新映射完成。驱动串行化队列创建、映射更新和 VM 销毁，更新时阻止新队列激活；仅由应用声明“空闲”不足以进入更新。

故障 Queue 不要求排空，沿第二阶段已有错误卸载协议确认相关访问结束、保存状态并解除绑定后，再撤销映射；无法确认则继续保留。清理故障队列不恢复原任务，也不要求新增复位功能。

> **[SPEC]** [CP/MEC 第一版规格，错误队列清理后重建](<./CP_MEC 第一版规格.md#spec-queue-error-rebuild>)与[队列卸载](<./CP_MEC 第一版规格.md#spec-unmap-drain>)，2026-10-19 状态：正常队列先排空；故障队列按错误协议清理，释放仍须等待访问和旧通知结束。

```text
排空并卸载 Queue → 确认旧用户访问结束
  → CPU 写页表，保证设备可见
  → 请求按 VMID 全量失效
  → 设备清理 TLB，阻止旧页表遍历重新填入旧翻译
  → 驱动取得本次 ACK
  → 允许新 Queue 使用映射，或释放已撤销映射的引用
```

TLB 按 VMID 和 GPU 页号区分缓存项，并保存目标页及权限。失效接口一次只接受一个请求，接受时清旧 ACK，完成后发布本次 ACK；驱动串行等待。失效结束保证后续请求使用更新后的翻译，旧数据请求则必须已由队列卸载协议确认结束。

失败或结果未知时禁止该上下文继续创建 Queue，保留相关页表、映射和存储。容量和替换算法采用小型仿真实现，不增加精细区间失效或异步更新。

> **[SOURCE]** 固定 Linux 源码：[amdgpu_vm_cpu.c，第 73～135 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_vm_cpu.c#L73-L135)提供 CPU 写表与发布路径；[gmc_v9_0.c，第 776～879 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gmc_v9_0.c#L776-L879)通过失效请求与 ACK 等待完成。本设备采用 CPU 同步更新，并额外限制为卸载队列后更新，省去运行中页表依赖管理。

### 5.3 结束旧访问和通知后才复用编号

VMID 复用前，先解除旧队列关联、结束旧访问和通知处理，完成翻译失效并撤销旧页表绑定，再交给新 VM。不能只覆盖根地址。

IH 继续按源 MQD 查找原队列、上下文与事件。MQD 地址、事件编号和通知槽也各自等待旧引用结束后再复用，旧记录不能按同编号的新对象解释。

<a id="gpuvm-signal"></a>

## 6. 完成通知与基本故障退出

### 6.1 保留 Signal 协议，通知页预先映射

沿用 24 字节 Signal、64 位有符号值及 CP 单独执行 `1 → 0`。AQL 中的 Signal 地址与 Signal 中的 `event_mailbox_ptr` 改为所属 VM 的 GPUVA，不接受用户指定管理 DMA 目标。

每个 VM 在创建 Queue 前建立一个 4 KiB Host 通知页，内部 GPUVA 为 `0xffff_f000～0xffff_ffff`，提供 512 个 8 字节槽。映射由驱动维护，不向应用开放改页表或 CPU 写通知页的接口。创建事件只分配已有槽，不改变页表；名额不足返回失败。

```text
驱动创建事件 → 返回事件编号和通知槽 GPUVA
  → 应用填写 Signal 并提交 AQL
  → CP 按源队列 VMID 写 Signal 与通知槽，再提交 IH
  → 驱动核对源队列、事件关联和实际通知槽 → 唤醒等待者
```

首版权限以 VM 为边界，不增加 CP 专用 PTE 权限位；同一 VM 内的 Kernel 可能写该 VM 的可写通知页。驱动不能仅凭通知内容授予跨上下文访问或唤醒其他上下文的事件。

完成顺序保持为结果写回及执行确认、Signal、通知槽、IH、包槽失效与消费回报。后续步骤失败时保留已有写入，不重新执行整项任务。

> **[SPEC]** [CP/MEC 第一版规格，Signal 布局](<./CP_MEC 第一版规格.md#spec-signal-layout>)、[可见性](<./CP_MEC 第一版规格.md#spec-dispatch-visibility>)及[失败包收尾](<./CP_MEC 第一版规格.md#spec-failure-retirement>)，2026-10-19 状态：完整 64 位读写、发布顺序和部分完成保留均为已有约束。

### 6.2 缺页报错并停止，不补页或重放

检测未映射、权限错误、越界、无效上下文、页表或存储访问失败。故障信息至少定位源队列、VMID、GPUVA、访问类型和阶段，保留首次故障，读取不自动清除。

```text
CP 取包、描述或完成访问失败 → CP 记录源队列错误
执行器取指、参数或数组访问失败 → 返回失败 → CP 记录源队列错误
  → 停止该队列后续取包和派发 → 经健康 IH 通知驱动
  → 相关等待以错误退出 → 确认访问及引用结束后才能回收

IH 自身故障 → 锁存状态、拒绝新记录、停止新取包和调度
  → 独立 IRQ_ERROR 通知 Host，不再依靠故障 IH Ring
```

可归属单条用户队列的错误停止源队列，保留绑定；另一进程的健康队列继续运行。管理、固件或共享通道故障沿用第二阶段停止范围。页表更新失败则将受影响 VM 置为不可继续使用，直到安全清理。

> **[SOURCE]** 固定 Linux 源码：[gmc_v9_0.c，第 562～565 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gmc_v9_0.c#L562-L565)从中断记录恢复故障地址；[第 633～679 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gmc_v9_0.c#L633-L679)读取访问状态，并区分页表遍历、权限及映射错误。本设备借鉴诊断内容，队列停止及资源保留仍按自己的 CP/IH 协议处理。

> **[SPEC]** [CP/MEC 第一版规格，IH 故障与恢复前提](<./CP_MEC 第一版规格.md#spec-ih-fault-reset>)，2026-10-19 状态：IH 故障经已有 `IRQ_ERROR` 交付，不依赖继续写入故障 Ring。

例如数组跨页，已写回部分 Z 后读取 X 的下一页失败，已写入结果保留，尚未发布的成功 Signal 不更新。如果 Signal 已为 `0` 而后续通知失败，则保留 `0` 并报告通知故障，不能重跑任务。

**[BOUNDARY]** 缺页只做检测、报告和错误退出；不按需补页、不恢复故障指令、不自动重放 Dispatch。错误记录和队列停止后，仍须确认已发出的访问结束，才允许释放存储。

<a id="gpuvm-lifetime"></a>

## 7. 正常回收与异常资源保留

GPU 映射持有 BO 引用，Queue 持有 Ring、进度对象和 VM 引用；CPU 映射、事件、管理请求和旧通知也保留必要引用。关闭句柄先解除句柄引用，实际存储等所有使用结束后回收。

普通关闭由库封装以下顺序，应用只需停止新提交并调用对应关闭操作：

```text
停止提交并完成已预留包的发布 → 等待排空、卸载 Queue
  → 结束事件及旧通知处理 → 撤销 GPU 映射并等待失效
  → 释放对象引用、DMA 映射和实际存储
  → 撤销上下文绑定 → 归还 VMID 和页表
```

驱动不解析任意 Kernel 参数来猜测全部依赖。Queue 存活时保留既有映射；应用遵守输入、输出和 Signal 的使用寿命。正常回收要能重复执行，不能靠每次重启设备清理。

故障队列按第 5.2 节清理，不等待所有包成功完成。进程异常退出、等待超时、管理结果未知或失效未确认时，保留设备仍可能访问的对象、页表和编号。允许返回错误并暂时占用资源，不增加自动复位或挂死恢复；超时只结束本次等待。

接入第三阶段代码前先修复[第二阶段未知管理结果码问题](<./QEMU GPGPU 实验大纲.md#stage-two-spec-review>)。强制中止与运行中复位恢复归第四阶段，不用它们替代正常寿命管理。

<a id="gpuvm-device-host-interface"></a>

## 8. 最小设备接口与 Host API

### 8.1 设备增加上下文、失效和故障入口

设备保存 VMID 0～2 的上下文状态，用户上下文提供页表根低高位、使能与就绪状态；地址范围和层数固定。共享失效入口提供目标 VMID、忙、ACK 和错误状态。CP 窗口及执行器增加地址域或 VMID，故障入口保存首次错误信息。

页表根与失效寄存器由 Host 驱动独占，应用不能映射管理寄存器或整个 VRAM BAR。上下文禁用时才能改根，先写完整配置、发布并清旧翻译，再启用；失效忙时拒绝重复请求。

冷复位和整体复位清除 GPUVM 状态；CP 单独复位保留上下文与 TLB，不能据此释放仍可能被执行器访问的存储。正式偏移、结构和枚举在实现时按现有地址段统一补齐，硬件行为写入[硬件手册](<./QEMU_2026_GPGPU_硬件手册.html>)对应模块。

### 8.2 库封装整对象分配、映射与释放

保留设备、内存、队列和事件四组调用。内存申请返回对象句柄、逻辑大小、CPU 入口及 GPUVA，内部顺序为创建 BO、分配地址、同步 `MAP`，全部成功后才返回；中途失败按实际完成状态撤销或保留，不能遗留可误用的半成品。

底层映射输入只需对象句柄、整对象 GPUVA 与权限。长度使用该对象的页对齐大小，不开放部分对象偏移。驱动校验归属、对齐、保留区、重叠和完整范围；已映射对象再次映射失败。`UNMAP` 同样按整对象处理。

`MAP` 成功表示页表及必要失效已完成；`UNMAP` 成功表示旧映射不能再使用，相关引用已按寿命规则解除。Queue 尚未安全销毁时，两类操作返回忙。创建 Queue 使用已映射对象，VMID 由驱动填写；提交仍直接发布 AQL，不增加逐任务 Launch ioctl。

> **[SOURCE]** 固定 Linux 源码：[amdgpu_gem.c，第 811～886 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_gem.c#L811-L886)校验地址、权限、操作及文件所属对象句柄；[第 944～974 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_gem.c#L944-L974)区分映射、解除、清理与替换。本期只采用同步、整对象 `MAP/UNMAP` 子集。

能力查询返回接口版本、32 位 GPUVA、4 KiB 页、可分配区间、两个用户 VMID、每 VM 一 Queue 及映射更新限制。默认应用不接触物理 DMA 地址。

### 8.3 旧模式独立回归，不做运行中切换

用启动模式和接口版本区分旧同步路径、第二阶段物理地址队列路径、第三阶段 GPUVM 路径。本次设备生命周期内模式固定，旧路径独立启动回归，GPUVM 模式关闭原始物理访问旁路。

保留结构大小不保证旧程序可直接使用新地址语义。现有库和示例在本期适配 GPUVA，不兼容原版 AMD 用户接口，不新增三种模式的统一地址转换层。

<a id="gpuvm-open-interfaces"></a>

## 9. 本轮范围记录与完成条件

### 9.1 首版方案的关键限制

以下保留会影响应用使用和实现规模的核心取舍，正文已经按同一组合展开，便于集中审阅：

<a id="gpuvm-confirm-objects"></a>
<a id="gpuvm-confirm-connection"></a>
<a id="gpuvm-confirm-storage"></a>

- **对象与存储：** 单一 DRM 入口，一个文件一个 VM；GEM 包装固定 Host RAM / VRAM，不接入 TTM。库封装整对象申请与映射，一对象一映射。

<a id="gpuvm-confirm-addresses"></a>
<a id="gpuvm-confirm-va-width"></a>
<a id="gpuvm-confirm-executor"></a>
<a id="gpuvm-scope-rv32"></a>
<a id="gpuvm-confirm-pages"></a>
<a id="gpuvm-confirm-page-format"></a>
<a id="gpuvm-confirm-memory-access"></a>
<a id="gpuvm-confirm-host-dma"></a>

- **地址与页表：** 32 位 GPUVA、RV32 参数窗口、三级 4 KiB 页表、VRAM 表页；权限包含读、写和取指。所有用户访问都经过翻译。

<a id="gpuvm-confirm-access"></a>
<a id="gpuvm-confirm-address-fields"></a>
<a id="gpuvm-confirm-mqd"></a>
<a id="gpuvm-confirm-cp-window"></a>
<a id="gpuvm-confirm-contexts"></a>
<a id="gpuvm-confirm-vmid"></a>
<a id="gpuvm-confirm-reuse"></a>
<a id="gpuvm-confirm-invalidate"></a>
<a id="gpuvm-scope-live-update"></a>

- **驻留与更新：** 管理 DMA 直通，两个固定用户 VMID，每 VM 一条 Queue；Queue 销毁后才改映射，CPU 同步写表并等待按 VMID 全量失效。

<a id="gpuvm-confirm-completion"></a>
<a id="gpuvm-confirm-signal"></a>
<a id="gpuvm-confirm-fault"></a>
<a id="gpuvm-confirm-release"></a>
<a id="gpuvm-confirm-host-api"></a>
<a id="gpuvm-confirm-host-map"></a>
<a id="gpuvm-confirm-compatibility"></a>
<a id="gpuvm-confirm-observability"></a>

- **完成与退出：** 保留 Signal/IH，预映射通知池；用户访问故障停止源队列并错误退出，不恢复或重放；访问、通知和失效都结束后才能回收和复用。

这是收敛后的方案摘要，具体配置仍供用户审阅。原先关于更多页表形式、迁移框架、运行中更新和故障恢复的替代方案移出本期，不再逐项作为开工前的选择题。实现中若发现接口或约束必须改变，先说明原因和影响。

### 9.2 明确留到后续的能力

本期不支持存储迁移与驱逐、超额显存驻留、换页、按需补页、故障恢复与任务重放、VMID 超额轮换、队列驻留时修改映射、异步页表更新、别名与部分撤销、跨进程共享、CP 专用通知权限、抢占及运行中复位恢复。

这些能力的作用和扩展安排集中在[后续 GPUVM 扩展](<./QEMU GPGPU 实验大纲.md#gpuvm-advanced-extension>)。当前只需讲清固定存储、冻结映射和显式失败分别替代了什么条件，不展开完整实现设计。

### 9.3 以可重复演示和验收结束第三阶段

两进程使用相同 GPUVA 得到各自结果，错误访问被拒绝，撤销重映射及 VMID 复用不命中旧状态，正常退出可回收并再次运行，即形成第三阶段的核心成果。正式场景和回归范围见[阶段验收](<./QEMU GPGPU 实验大纲.md#stage-three-acceptance>)。

完成这些验收后，固定代码、运行配置和复现命令，整理设备访问、AQL 提交和 GPUVM 三部分的关系及简化边界，用于项目讲解和面试。后续扩展不推迟第三阶段完成，运行结果按实际实现和验证记录。
