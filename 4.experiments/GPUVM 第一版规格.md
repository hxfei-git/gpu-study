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

本文是第三阶段的 **AMDGPU 参考版规格草案，日期为 2026-10-19**。组织方式参考[CP/MEC 第一版规格](<./CP_MEC 第一版规格.md>)：第 1～8 节说明对象、执行路径和接口行为，[第 9 节](#gpuvm-open-interfaces)保留核心方案、可选范围、推荐理由和确认状态。

**[DESIGN]** 本版优先参考 AMDGPU 的成熟实现，为本设备提出推荐方案。软件接入、内存管理范围、地址与页表、VMID、映射同步、通知和故障处理等核心决定由用户取舍；参考源码不表示这些决定已经确认。正文用推荐组合讲清完整过程，其中的数值、布局和简化均须结合第 9 节审阅，不能据此直接认定为最终规格或已实现能力。

本项目面向 GPU 驱动岗位学习。规格既要能指导实现，也要能帮助读者沿一次任务解释对象、地址、同步和错误退出。简化某项实现时，仍保留它在 AMDGPU 中解决的问题、本项目采用的替代条件，以及后续扩展会影响哪些环节。

建议先看第 1 节的任务路径，再按“对象与存储 → 地址翻译 → 队列访存 → 更新、通知与释放”的顺序阅读正文，最后到第 9 节对齐方案。寄存器编号、正式结构和锁的具体实现，在核心契约确认后统一落实。

阶段范围、推进顺序和运行记录统一维护在[第三阶段大纲](<./QEMU GPGPU 实验大纲.md#stage-three-vmid>)。本文保存规格讨论和必要简化，不另建实验计划；用户已确认的第二阶段约定、第三阶段待确认方案、代码实现和实际验证分别记录。

<a id="gpuvm-overview"></a>

## 1. 整体架构与一次任务的执行路径

### 1.1 一次任务的准备、执行与回收

应用 A 已有一条用户 AQL Queue，接下来要运行 `Z[i] = X[i] + Y[i]`。第三阶段希望调用方填写 GPUVA，设备根据 Queue A 所属上下文找到实际存储。应用 B 可以使用相同的 GPUVA，由自己的页表指向另一份存储。

**[DESIGN] 推荐方案，待确认：** 继续沿用户 AQL Queue 提交任务，参考 AMDGPU 的 DRM 文件上下文、BO 与 VM 映射关系，由设备 GPUVM 翻译用户访存。下面展示准备、执行和回收的完整路径；各对象的地址含义在第 2～4 节展开。

```text
应用打开设备，经 HSAKMT 风格库申请对象
  → 驱动建立应用上下文，分配 Host RAM / VRAM 存储
  → 为对象建立 GPUVA 映射，填写页表并绑定 VMID
  → 驱动准备 MQD，经管理队列建立用户 Queue
  → 应用向 Ring 发布 AQL，通知 Doorbell
  → CP 按 Queue 的 VMID 翻译 Ring、描述对象和完成对象的 GPUVA
  → CP 将 VMID、代码 GPUVA、参数 GPUVA 等交给 RV32 执行器
  → 执行器翻译取指、参数和数组访问，写回计算结果
  → CP 按完成顺序更新 Signal、通知槽和 IH
  → 应用读取结果，停止提交并排空，驱动卸载 Queue
  → 确认访问和旧通知处理结束，撤销映射并完成翻译失效
  → 回收对象、页表与 VMID
```

**沿用的第二阶段约束：** CP 为 RV64 裸机固件，计算执行器仍为 RV32，一次处理一个完整 Dispatch；全设备仍有两个用户 Queue 名额。引入多个地址空间不自动增加 HQD 或并行执行能力。

> **[SPEC]** [CP/MEC 第一版规格，第 1 节](<./CP_MEC 第一版规格.md#spec-overview>)及[用户队列名额](<./CP_MEC 第一版规格.md#spec-user-queue-capacity>)，2026-10-19 状态：4 个 HQD 分别用于 KIQ、HIQ 和两个动态用户队列；CP 与计算执行器分别执行固件和应用 Kernel。

**[BOUNDARY]** 本文设计的是 QEMU 教学设备。GPU 页表和寄存器不声明兼容 MI300X；CP 自身的裸机取指、栈和设备寄存器访问不因此改成 RISC-V 分页。普通 DRM 命令提交、高层 HSA 运行时、抢占和运行中复位恢复沿用实验大纲的后续范围。

### 1.2 对象、访问和更新三条主线

以下三条线贯穿同一次向量加法任务。读者需要能沿图说明每步的执行主体、已有输入和完成结果，再用后文的字段与源码核对。

```text
对象线：连接 → VM → BO 与实际存储 → CPU/GPU 映射 → 队列和任务引用 → 回收

访问线：CP 或执行器发起一次用户取包、取指、数据或完成写入请求
       → 按本次 VMID 查询 TLB / 页表 → 访问 VRAM 或 Host DMA
       → 返回本次访问结果，再推进任务的下一步

更新线：停止相关使用 → 写页表并发布 → 等待翻译失效 → 恢复使用或回收
故障线：记录访问来源和失败位置 → 停止受影响工作 → 错误等待退出 → 保留或释放资源
```

对象线用于解释“分配了什么、谁持有引用、地址从哪里来”。访问线用于定位“哪个主体按哪套映射访问哪个对象”。更新和故障线用于判断“什么时候可以改变映射或释放存储”。GEM、页表和 TLB 都放回这些具体过程说明，便于沿一次任务核对各自的作用。

取包、取指、参数、数组与 Signal 等用户访问都分别经过访问线中的翻译和权限检查；页表查询不是在全部计算结束后才统一执行。

BO 的迁移与驱逐、异步页表依赖、VMID 超额驻留、可恢复访问故障都应理解其作用；首版是否实现，在对应核心问题中取舍。后文保留这些能力与现有路径的联系，不把暂不实现的内容从知识说明中删去。

本阶段复用第一阶段的设备访问和 DMA，以及第二阶段的 AQL、CP、Signal 和 IH。需要把这些既有流程接到新映射上，逐一说明 Host CPU 怎样准备对象、设备怎样找到存储、完成通知怎样返回，以及最后由谁确认可以回收资源。

### 1.3 AMDGPU 源码基线与适用边界

源码依据统一为仓库 `2.源码/linux` 的固定提交 `248951ddc14de84de3910f9b13f51491a8cd91df`。本文的 `[SOURCE]` 引用均链接到该提交的真实文件与行号；软件通用对象按 AMDGPU 核对，地址掩码和上下文寄存器优先核对 MI300X 主线相关的 `gmc_v9_0`、`gfxhub_v1_2` 路径。驱动代码用于证明软件实现，不替代真实硬件语义的完整规范。

> **[SOURCE]** 固定 Linux 源码：[amdgpu_discovery.c，第 2148～2157 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_discovery.c#L2148-L2157)为 9.4.3 选择 `gmc_v9_0`；[gmc_v9_0.c，第 1487～1493 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gmc_v9_0.c#L1487-L1493)在 `amdgpu_is_multi_aid()` 返回真时选择 `gfxhub_v1_2`；[gfxhub_v1_2.c，第 319～325 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfxhub_v1_2.c#L319-L325)标注其用于 9.4.3 变体。本文据此选择相关驱动参考路径。

<a id="gpuvm-objects"></a>

## 2. DRM/GEM、应用上下文与实际存储

### 2.1 设备连接与应用地址空间

**[DESIGN] 推荐方案，待确认：** 参考 AMDGPU，一个 DRM 文件上下文持有一个 GPU VM；第三阶段通过 DRM render node 提供应用入口，现有 HSAKMT 风格库封装相应操作。库内多个线程共享连接，重复打开按引用计数管理。不同文件上下文的句柄、映射、队列和事件分别归属各自上下文。

这里的“应用上下文”是驱动持有的软件记录。它关联 GEM 对象、GPUVA 映射、页表和 VMID，队列创建时从这个记录取得所属地址空间。普通应用不能在创建请求中任意指定另一个上下文的 VMID。

```text
应用 A 的库连接 → DRM 文件上下文 A
                   ├─ 对象句柄 → GEM 对象 → 实际存储
                   ├─ GPUVA 映射 → 引用对象的指定区间
                   ├─ 地址空间 → 页表根、绑定的 VMID
                   └─ 用户 Queue → 引用 Ring、进度对象和所属地址空间
```

首版不提供跨进程对象共享、文件描述符传递后继续使用队列或继承连接的协议。同一进程绕过库重复打开设备时产生独立文件上下文，不按进程编号隐式合并。

> **[SOURCE]** 固定 Linux 源码：[amdgpu.h，第 444～458 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu.h#L444-L458)在 `amdgpu_fpriv` 中保存 `amdgpu_vm`；[amdgpu_kms.c，第 1435～1477 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_kms.c#L1435-L1477)在文件打开时创建并初始化该 VM。[amdgpu_amdkfd_gpuvm.c，第 1564～1587 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gpuvm.c#L1564-L1587)将已有 VM 转为计算 VM；本实验借鉴这种内存管理关系，AQL 提交路径继续单独保留。

### 2.2 内存对象、CPU 映射与 GPU 映射

应用已经为数组 X 申请对象，提交前需要同时解决两件事：Host 怎样准备数组内容，Kernel 怎样找到数组。对象保存内容和存储归属，CPU 访问入口与 GPUVA 映射分别供两个执行主体使用。

```text
对象句柄 H_X → 驱动据此查找 BO_X（大小、内存域、引用）
                         ├─ 存储记录 → 保存实际 VRAM 区间
                         │              └─ 由资源分配路径取得、占用并归还区间
                         ├─ CPU 映射或拷贝入口 → Host 填写数组内容
                         └─ VM_A 中的映射记录
                              └─ 保存 GPUVA 区间、BO_X 内偏移和权限
                                   → 驱动据此生成实际页表
```

**[DESIGN] 推荐方案，待确认：** 参考 AMDGPU 将 BO、VM 与映射分开管理。BO/GEM 对象保存实际存储及引用；VM 保存应用地址空间；映射记录保存对象内偏移、GPUVA 区间和权限。同一对象可以建立多个不重叠的 GPUVA 映射，解除其中一段映射不销毁对象。

推荐本设备先保留已有分配方式：Host RAM 对象使用驱动分配的一致性内存，VRAM 对象由统一的 `gpu_buddy` 提供实际区间。是否在本阶段接入 TTM 的资源管理、迁移或驱逐，由 [9.1.2](#gpuvm-confirm-storage) 取舍，不能仅因有了 GEM 对象就省去这项讨论。

以数组 X 为例，调用方先取得对象句柄，用上传接口准备数组内容，再请求将对象区间映射到本上下文的 GPUVA。Kernel 参数中填写的是这段 GPUVA。对象句柄用于驱动查找对象，CPU 映射地址用于 Host 访问，GPUVA 用于设备访问，三者分别返回和使用。

对象大小、映射长度及实际分配粒度分别记录。GPU 映射按 4 KiB 页处理，后备存储必须覆盖整段映射。对齐补出的页内字节初始化为零，不得暴露其他对象内容；调用方可用的逻辑大小仍单独返回。

> **[SOURCE]** 固定 Linux 源码：[amdgpu_vm.c，第 1843～1879 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c#L1843-L1879)通过 `bo_va` 关联 BO 与 VM，检查映射重叠，并单独保存 `start`、`last`、`offset` 和 `flags`。该证据说明对象与映射的关系，TTM 接入范围另见第 9 节。

#### 2.2.1 TTM 管理存储位置，GPUVM 管理访问映射

在 AMDGPU 中，BO 内嵌 TTM 对象，TTM 对象又内嵌 GEM 基础对象；这些结构共同描述同一份缓冲对象，不是三份数据副本。GEM 提供对象与句柄等基础关系，TTM 管理后备存储的位置、分配和移动，AMDGPU 的 GPUVM 记录对象在各个 GPU 地址空间中的映射。

BO 的 `placement` 描述允许放在哪里及相应条件，`resource` 描述当前实际放在哪里。例如一个对象可以偏好 VRAM，并允许在资源紧张时转到另一种存储位置；“偏好 VRAM”与“整个寿命固定在 VRAM”是两种范围。`gpu_buddy` 提供实际显存区间的分配能力，单独使用这个分配器不会自动得到对象迁移、驱逐和映射更新流程。

> **[SOURCE]** 固定 Linux 源码：[amdgpu_object.h，第 103～115 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_object.h#L103-L115)保存 BO 的允许域、placement、内嵌 TTM 对象及 VM 关联；[include/drm/ttm/ttm_bo.h，第 73～125 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/include/drm/ttm/ttm_bo.h#L73-L125)区分存储位置、CPU 映射与驱动管理的 GPU 地址空间，并在 TTM 对象中保存 GEM 基础对象及当前 resource；[amdgpu_object.c，第 103～178 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_object.c#L103-L178)把对象内存域转换为具体 placement 条件。

#### 2.2.2 存储迁移会牵动同步和页表更新

继续以 X 为例。应用参数仍可以保存原来的 GPUVA，但如果 X 的实际存储发生迁移，页表就需要改指向新位置。对象身份和 GPUVA 可以不变，后备存储、PTE 目标与访问时序必须一起调整：

```text
为 BO_X 选择允许的新存储位置，安排相关使用的同步
  → 通知 GPUVM：BO_X 的存储将改变，关联映射需要更新
  → 移动数据并改变存储记录
  → 页表更新等待迁移等必要依赖，再写入新目标
  → 后续任务等待页表更新及翻译同步后，按原 GPUVA 访问新存储
```

迁移通知首先改变软件状态，不能把它当作硬件 PTE 和 TLB 已经完成更新。已有访问、迁移操作和后续任务需要按依赖排序，旧存储也不能仅因新位置已分配就提前释放。

> **[SOURCE]** 固定 Linux 源码：[amdgpu_object.c，第 1257～1289 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_object.c#L1257-L1289)在移动通知中关联 GPUVM；[amdgpu_vm.c，第 2266～2317 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c#L2266-L2317)把关联记录标记为已移动、需要更新；[第 1261～1319 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c#L1261-L1319)同步相关使用与迁移依赖；[第 1338～1395 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c#L1338-L1395)安排映射重写及翻译更新。

如果首版选择固定存储，正常任务仍需走完整 GPUVM 访问流程；分配器不能满足请求时明确返回失败，不自动移动正在使用的对象。这个选择可以减少实现范围，但读者仍应能解释迁移为什么需要上面这组同步和映射联动。

### 2.3 用户对象与驱动管理对象

**[DESIGN] 推荐方案，待确认：** 保留第二阶段对象的存储位置，优先改变用户访问地址的含义：用户 Ring、进度、参数和 Signal 在 Host RAM；描述对象、代码和数组在 VRAM。用户 GPUVA 将这些对象放入同一个应用地址空间，叶子映射再区分目标存储。

KIQ/HIQ Ring、MQD、管理结果区、IH、页表和固件区由驱动管理。应用不能申请将这些区域映射为普通可读写对象。事件通知槽的设备映射由驱动建立，其特殊规则见[第 6.1 节](#gpuvm-signal)。

> **[SPEC]** [CP/MEC 第一版规格，第 2 节](<./CP_MEC 第一版规格.md#spec-objects-addresses>)、[Kernel 数据存储](<./CP_MEC 第一版规格.md#spec-kernel-data-storage>)及[固件保留区](<./CP_MEC 第一版规格.md#spec-firmware-layout>)，2026-10-19 状态：普通 VRAM 分配范围为前 60 MiB，首个页登记保留；末尾 4 MiB 固件区不进入普通分配池。第三阶段页表等管理存储也须由驱动登记占用。

<a id="gpuvm-addresses"></a>

## 3. GPUVA、页表与 Host 地址翻译

### 3.1 GPUVA 范围与同地址隔离示例

**[DESIGN] 推荐的教学简化，待确认：** 推荐首版采用 32 位 GPUVA，以匹配 RV32 计算线程的寄存器和现有参数字段。64 位协议地址槽继续保留宽度，保存 GPUVA 时高 32 位必须为零；超出范围应拒绝，不能截断。这是本设备的地址范围选择，不照搬 MI300X 的 GPUVA 位宽。

本节按“32 位 GPUVA＋保留参数窗口”的推荐组合展开，窗口和指针接口的其他选择见 [9.2.1](#gpuvm-confirm-va-width)，相关保留区不能脱离该选择单独定稿。

GPUVA 零页保留为未映射；沿用原参数窗口，保留 `0x9000_0000～0x9000_ffff`，该范围不分配给普通 GPUVA 对象。窗口用法见[第 4.3 节](#gpuvm-executor)。驱动还为通知池保留内部区间，能力查询返回普通可分配区间，库按页对齐选择地址，也支持调用方指定空闲 GPUVA。

Host DMA 地址字段继续用 64 位保存。参考下文 AMDGPU 的 48 位目标地址掩码，GPUVM 模式的实际 DMA 能力设为 48 位；驱动通过 DMA API 申请可达地址，不能把超出范围的地址截断后写入 PTE。地址字段的存储宽度与设备可寻址范围分别校验。

下面仅用示例数值说明隔离关系，不规定最终分配地址：

```text
Queue A 的 VMID → 页表 A
  GPUVA 0x0040_0000 → VRAM 偏移 0x0020_0000 → 数组 X_A

Queue B 的 VMID → 页表 B
  GPUVA 0x0040_0000 → VRAM 偏移 0x0060_0000 → 数组 X_B
```

两个 Kernel 都读取 `0x0040_0000`，设备根据各自 VMID 选择页表，最终读取不同数组。应用填写其他上下文使用过的 GPUVA 数值，也只能在自己的页表中查询。

### 3.2 页表与一次设备访问

设备现在需要完成一次读数组 X 的请求：已经拿到队列所属 VMID、GPUVA 和访问长度，目标是找到允许读取的实际页面。先看访问顺序，再解释推荐页表的索引和编码。

```text
请求：VMID、GPUVA、访问长度、读/写/取指类型
  → 检查 VMID 已绑定且可访问
  → 查询所属上下文的 TLB
  → 未命中：从页表根逐级读取表项
  → 检查有效位、权限、地址计算及目标完整范围
  → 页基址 + 页内偏移 → 访问目标存储
  → 返回数据或访问错误
```

**[DESIGN] 推荐方案，待确认：** 沿用 AMDGPU 的 4 KiB 基本页、64 位表项、分级目录和叶子权限。按本设备的 32 位 GPUVA 固定为三级：根目录、下级目录、叶页表。每张表按 4 KiB 对齐、占 4 KiB，包含 512 个 8 字节表项；根目录仅使用前 4 项，其余填零。各级表按需分配，保存在驱动保护的 VRAM 中。

以下索引、表大小和权限编码展示这一候选方案的完整关系。是否采用这套层级及存放位置，在 [9.3.1](#gpuvm-confirm-page-format) 取舍；保留具体推导是为了能够评估方案，不表示已替用户确定参数。

```text
32 位 GPUVA
  ├─ [31:30]：根目录索引，2 位
  ├─ [29:21]：下级目录索引，9 位
  ├─ [20:12]：叶页表索引，9 位
  └─ [11:0] ：页内偏移，12 位

页表根 VRAM 偏移
  → 根目录项找到下级目录
  → 下级目录项找到叶页表
  → 叶子项给出目标页和权限
  → 目标页地址 + 页内偏移
```

例如 `0x0040_0000` 的根索引为 0、下级目录索引为 2、叶索引与页内偏移均为 0。该路径首次建立时需三张表，共 12 KiB；映射相邻页面可以复用已有目录和叶页表。本设备的三级及根索引位数是教学配置，AMDGPU 会根据地址空间与硬件配置调整层数和末级大小。

页表根和目录项按 VRAM 偏移定位受保护的下一张表，不通过用户 GPUVA 反查页表自身。目录项只使用 `VALID` 与地址位。叶子项采用 AMDGPU 的常用位编号子集：bit 0 为 `VALID`，bit 1 为 `SYSTEM`，bit 4 为 `EXECUTABLE`，bit 5 为 `READABLE`，bit 6 为 `WRITEABLE`；地址位为 `[47:12]`，掩码为 `0x0000_ffff_ffff_f000`。其余位在本版填零，不支持的有效项编码按页表错误处理；无效项初始化和撤销时写零。

`SYSTEM = 1` 时，地址位保存 Host DMA 页地址；`SYSTEM = 0` 时，保存 VRAM 页偏移。把设备本地目标直接解释为 VRAM 偏移，是本实验沿用已有存储布局的简化；AMDGPU 使用自己的设备内存地址布局。所有表项采用小端完整 64 位写入，地址先验证对齐和范围，再与标志组合，不能先掩码后隐藏非法高位。

代码页默认读、取指，描述对象、参数及只读输入页默认读，输出页、Ring、进度、Signal 和通知槽按实际访问开放读写。权限按页生效，要求不同权限的小对象分开布置。共享输入输出对象按读写处理，不从参数名推断权限。

> **[SOURCE]** 固定 Linux 源码：[amdgpu_gart.h，第 35～38 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_gart.h#L35-L38)定义 4 KiB GPU 页；[amdgpu_vm.h，第 57～68 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.h#L57-L68)定义上述有效、区域与权限位；[amdgpu_gmc.c，第 163～175 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_gmc.c#L163-L175)将地址和标志写入 8 字节表项；[gmc_v9_0.c，第 1985～1994 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gmc_v9_0.c#L1985-L1994)设置 48 位地址掩码，并对包含 9.4.3 的分支选择 48 位 DMA 能力。[amdgpu_vm.c，第 2392～2425 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c#L2392-L2425)按空间大小计算层级及末级大小。上文固定三级和裁剪标志位是本设备设计，不声明完整硬件格式兼容。

首版拒绝跨页的单次标量访问；对象和 DMA 搬运可以跨页，由设备按页处理。若一个跨页搬运在后续页面失败，前面已完成的写入保留，不承诺事务回滚。第二阶段要求的自然对齐、完整 32/64 位共享字段访问必须在翻译路径中继续成立，不能拆成会被并发观察到的部分写入。

### 3.3 GPUVM 与 SMMUv3 的两层访问

Host RAM 对象由驱动通过 DMA API 取得可供设备访问的地址，再把该地址用于 GPU 叶子映射。访问链如下，GPU 页表输出的地址统一称为 Host DMA 地址：

```text
用户 GPUVA + VMID
  → 教学设备 GPU MMU → Host DMA 地址
  → 设备现有 DMA 通路
      ├─ IOMMU=none   → Host RAM
      └─ IOMMU=smmuv3 → 以 IOVA 请求系统翻译 → Host RAM
```

GPUVM 区分应用设备地址空间；SMMUv3 处理设备 DMA 访问。首版两层分别配置，不把 GPU VMID 编码成系统 IOMMU 的进程标识。Host DMA 映射与 GPU 映射分别持有引用，撤销顺序须满足第 7 节的访问结束条件。

> **[SOURCE]** 固定 Linux 源码：[amdgpu_vm.c，第 1261～1317 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c#L1261-L1317)在更新系统内存映射时取得 BO 的 `dma_address`；[amdgpu_vm_cpu.c，第 94～105 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_vm_cpu.c#L94-L105)将相应目标地址交给表项写入路径。本文沿用 DMA 地址与 GPUVA 分开的处理，不复制 TTM 的完整页管理。

**[BOUNDARY]** 现有 SMMUv3 DMA 通路的历史回归不证明用户 AQL 队列已经通过两层翻译；第三阶段另行验证该组合，运行安排仍见实验大纲。

<a id="gpuvm-access-paths"></a>

## 4. MQD、CP 与计算执行器的访问上下文

### 4.1 MQD 自身地址与队列中的用户地址

**[DESIGN] 推荐方案，待确认：** 管理命令仍通过驱动提供的 Host DMA 地址找到 MQD。CP 先用管理访问路径读取 MQD，再根据其中的用户 VMID 配置 HQD；不能先依赖尚未读出的用户 VMID 定位 MQD。

用户队列 MQD 中的 Ring 基址、R 回报地址和 W 读取地址改为该应用的 GPUVA。MQD 自身地址、管理 Ring、管理完成标记及 IH 的地址继续属于管理 DMA 域。相同宽度的地址字段按对象用途解释，不能按数值大小猜测地址类型。

```text
HIQ 管理命令：MQD 的管理 DMA 地址
  → CP 按管理域读取 MQD
  → 得到用户 VMID，以及 Ring / R / W 的 GPUVA
  → 装入所选 HQD
  → 后续用户取包和进度访问按该 VMID 翻译
```

保留 64 字节 MQD 及现有 HQD 位置，复用已有 VMID 字段，用户队列只接受本版可用的用户 VMID。页表根、上下文状态及失效控制放在独立的 VM 上下文寄存器中，不塞入 MQD。运行模式决定地址解释，版本不匹配或上下文未就绪时拒绝装载。

### 4.2 CP 的管理访问与用户访问

**[DESIGN] 推荐方案，待确认：** CP 固件继续通过自己的裸机地址访问代码、栈和设备寄存器。扩展现有访存窗口，增加管理 DMA 域与用户 GPUVM 域的选择，并保存用户 VMID。访问用户 Ring、进度、描述对象、Signal 和通知槽时选择用户域；读取管理对象时明确选择管理域。

管理域保留现有完整 DMA 地址含义；用户域使用 GPUVA，经目标 VMID 的 MMU 查到 VRAM 或 Host RAM。一次请求开始时保存地址域、VMID、目标地址及长度，跨进程消息和实际内存回调始终使用这个快照，不再读取可能已经变化的“当前 VMID”。窗口的最低对齐、访问宽度和失败异常继续沿用第二阶段。

CP 在处理下一条队列或进入错误收尾时，不能让上一条队列的用户上下文影响管理访问。错误记录继续保存源 HQD、访问阶段与完整目标地址，并补充地址域和 VMID。

### 4.3 描述对象、参数窗口与执行器快照

<a id="gpuvm-executor"></a>

**[DESIGN] 推荐方案，待确认：** AQL 的 `kernel_object`、`kernarg_address`、`completion_signal` 统一保存所属用户地址空间的 GPUVA。描述对象仍使用 16 字节布局，但 `code_entry` 改为 32 位代码 GPUVA；参数中的数组字段改为 32 位数组 GPUVA。长度、工作组及参数内容的解释沿用各自约定。

保留计算线程的只读参数窗口，`a0 = 0x9000_0000`。执行器保存本次参数 GPUVA、实际长度和 VMID；窗口读取先得到参数偏移，再进行用户 GPUVA 翻译：

```text
计算线程读取 a0 + 12
  → 确认偏移 12 的完整访问落在参数长度内
  → 本次参数 GPUVA + 12
  → 按本次 VMID 翻译 → 读取参数字段

参数字段给出数组 GPUVA
  → 普通数组读写也按本次 VMID 翻译
```

代码取指同样经过本次上下文，既检查声明的代码范围，也检查页表取指权限。队列模式的普通访存不得在翻译失败后退回原有的“按 VRAM 偏移直接访问”路径，用户地址也不能被转交为设备寄存器或管理物理地址。

CP 写入分发配置后，设备在接受 Dispatch 时一次保存 VMID、代码与参数 GPUVA、长度和任务规模。分段执行始终使用这个快照，任务忙或结果尚未确认时拒绝覆盖。旧同步模式的参数和访问方式按第 8 节单独保留。

> **[SPEC]** [CP/MEC 第一版规格，第 6.2 节](<./CP_MEC 第一版规格.md#spec-kernel-descriptor>)及[第 6.3 节](<./CP_MEC 第一版规格.md#spec-executor-dispatch>)，2026-10-19 状态：描述对象为 16 字节，计算线程通过固定窗口读取 Host 参数，分发时保存完整配置。上文保留布局和执行约定，将用户地址改为 GPUVA；这是本实验第三阶段的协议版本变化。

<a id="gpuvm-context-tlb"></a>

## 5. VMID 绑定、TLB 失效与编号复用

### 5.1 软件地址空间与硬件上下文

**[DESIGN] 推荐的教学简化，待确认：** VMID 0 保留为本设备的受信任管理域，用户 VMID 固定为 1、2，以满足两个应用地址空间同时驻留的实验场景。VMID 与 HQD 分别分配，同一 VMID 可以关联多条队列。

打开连接先建立软件 VM，首次建立 GPU 映射时申请用户 VMID，绑定成功后持有到地址空间销毁。没有空闲用户 VMID 时返回资源不足，不驱逐其他上下文，也不引入运行中的上下文轮换。一个上下文可以持有多条 Queue，但仍受全设备两个用户 Queue 名额限制。

这个候选策略限制驻留地址空间数量，不只是限制正在运行的任务数：

```text
VM_A 已建立 GPU 映射 → 持有用户 VMID 1
VM_B 已建立 GPU 映射 → 持有用户 VMID 2
VM_C 请求首次 GPU 映射 → 没有空闲用户 VMID，返回资源不足

即使 A、B 此刻未执行任务，只要绑定尚未回收，C 也不能取得名额。
队列是否有空槽，仍由独立的 HQD 名额判断。
```

驱动分配并初始化页表，先写完整页表根和配置，完成必要发布及旧翻译清理后才使上下文可用。用户队列激活前，CP 检查 VMID 有效且上下文已就绪；应用不能自行配置页表根或管理上下文。

> **[SOURCE]** 固定 Linux 源码：[gfxhub_v1_2.c，第 42～61 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfxhub_v1_2.c#L42-L61)按 VMID 配置页表根的低、高位；[第 328～365 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfxhub_v1_2.c#L328-L365)配置上下文使能、页表深度及访问故障检查。本设备沿用“VMID 选择根与控制状态”的关系，裁剪实例数量和参数。

**[BOUNDARY]** 本设备 VMID 0 沿用第二阶段管理 DMA 路径，不做用户页表遍历。这是实验简化，不能把该直通规则当作 AMDGPU 的通用结论。

> **[SOURCE]** 固定 Linux 源码：[gfxhub_v1_2.c，第 74～91 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gfxhub_v1_2.c#L74-L91)为 VMID 0 设置 GART/页表根，证明真实驱动的管理上下文也有自己的地址翻译配置。

### 5.2 映射修改与失效完成

应用要撤销 X 的映射时，问题不只是把 PTE 写成零：已经发出的读取可能仍在访问 X，后续访问也可能命中旧 TLB。需要分别安排旧访问结束、页表更新完成和翻译缓存失效，才可以继续执行或归还存储。

**[DESIGN] 推荐方案，待确认：** 采用 AMDGPU 已有的 CPU 页表更新方式，Host 驱动直接写受保护的页表，完成写入可见性后发起按 VMID 的 TLB 失效，并等待本次确认。初版失效清理该 VMID 的全部翻译，不先实现按页的精细失效。

本实验尚无完整的运行中任务依赖跟踪，推荐先采用以下条件：所属上下文还有已绑定、卸载中或异常未清理的用户队列时，拒绝普通 GPU 映射的新增、撤销和权限修改。调用方先排空并卸载这些队列，再改变页表。AMDGPU 本身通过同步对象和依赖管理支持更灵活的更新，这个卸载条件只属于本设备首版。

上面的卸载条件是推荐的同步边界，仍须在 [9.5.2](#gpuvm-confirm-invalidate) 确认。它会限制应用在队列存活期间新增映射或释放已有映射；如果本阶段选择支持队列驻留时更新，就要补上能够关闭并发提交窗口的同步协议。

驱动串行化同一上下文的队列创建、页表更新和销毁。开始更新前确认没有未完成的队列创建或卸载，更新期间阻止新队列激活；取得失效完成结果后，才解除相应限制。

事件通知池等必要管理映射在用户队列创建前准备好，后续从已映射的池中分配事件槽，不因每次创建事件而修改页表。

```text
停止提交，排空并卸载本上下文的全部用户队列
  → 驱动确认用户访问结束
  → 准备或修改页表，保证表项写入对设备可见
  → 请求该 VMID 的翻译失效
  → 设备完成相关 TLB 清理，并确认旧页表遍历不会重新填入旧翻译
  → 驱动取得本次完成结果
  → 允许建立新队列，或回收撤销映射不再引用的存储
```

失效接口采用请求与确认状态分离的方式，设备一次只接受一个失效请求，接受时清除旧确认，清理完成后发布本次确认；驱动串行提交并等待，防止把旧确认当成本次完成。失效完成保证后续访问不使用该次更新之前的翻译；旧数据请求是否已经结束由前面的队列卸载确认，不能用清空 TLB 代替。

失效失败或完成状态未知时，将上下文置为不可继续创建队列的状态，保留相关页表、映射与存储，向调用方返回错误。TLB 项至少按 VMID 和 GPU 页号区分，保存目标页及权限；容量和替换策略属于仿真实现细节，不作为需要用户确认的规格项。

> **[SOURCE]** 固定 Linux 源码：[amdgpu_vm_cpu.c，第 73～135 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_vm_cpu.c#L73-L135)提供 CPU 写表、内存屏障及发布路径；[amdgpu_gem.c，第 762～790 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_gem.c#L762-L790)更新对象映射和目录项，并保留相应同步结果；[gmc_v9_0.c，第 776～879 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gmc_v9_0.c#L776-L879)通过失效请求与 ACK 等待完成。这些路径用于说明更新与同步次序，本设备是否加入运行中及异步更新，在 9.5.2 取舍。

在 AMDGPU 的普通 DRM 提交路径中，任务会关联页表更新完成的同步依赖。这样即使软件已经登记了映射，任务也要等实际更新完成后才使用相应地址。推荐的“卸载后同步更新、完成后再建队列”是在本项目中替代这部分运行中依赖管理，不能据此认为同步依赖没有必要。

> **[SOURCE]** 固定 Linux 源码：[amdgpu_cs.c，第 1144～1169 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_cs.c#L1144-L1169)更新相关 BO 映射，并将对象页表及 VM 更新加入提交同步。该证据说明普通 DRM 提交中的更新依赖，不表示本实验或 KFD 的每个用户 AQL 包都经过此函数。

### 5.3 VMID、MQD 与事件身份的分别回收

复用 VMID 前，需要解除旧队列关联、结束旧访问、处理完旧通知、完成翻译失效并撤销旧页表绑定。页表根、TLB 项及在途请求必须能够区分旧、新绑定，不能仅覆盖页表根就把编号交给新上下文。

IH 继续按 MQD 地址找到原队列，再找到所属上下文与事件。VMID、MQD 地址和事件编号分别检查各自的释放条件，首版统一等旧通知及驱动后续处理结束后再归还相关身份；不能把旧 IH 记录按同编号的新绑定解释。

<a id="gpuvm-signal"></a>

## 6. Signal、通知槽与访问故障

### 6.1 Signal 的地址含义与完成发布

**[DESIGN] 推荐方案，待确认：** 保留 24 字节 Signal 布局、64 位有符号完成值、一次使用对应一个任务，以及 CP 单独执行 `1 → 0` 的规则。AQL 的 Signal 引用改为用户 GPUVA；Signal 内的 `event_mailbox_ptr` 也改为所属上下文的通知槽 GPUVA，禁止把用户提供的值直接作为管理 DMA 地址使用。这是保留第二阶段完成协议后的必要适配，不照搬 AMDGPU 的完整事件实现。

推荐每个用户 VM 在队列创建前准备一个 4 KiB Host RAM 通知页，映射到内部 GPUVA `0xffff_f000～0xffff_ffff`，提供 512 个 8 字节通知槽。通知页的大小和位置是待确认的教学配置，确认后由能力查询返回。驱动控制该映射，不向用户开放修改接口，通知页也不作为普通 CPU 可写映射交付。事件创建返回事件编号和对应通知槽 GPUVA，调用方据此填写 Signal；无空闲槽时返回资源不足，不临时扩展页表。

这里的“受保护”指映射由驱动控制，并禁止普通 CPU 写入。页表权限以用户 VM 为边界，首版不增加 CP 专用 PTE 权限位；同一 VM 内的 Kernel 可能写入该 VM 的设备可写页。驱动仍核对通知的源队列和实际槽，通知内容不用于授予跨上下文访问权限。

```text
驱动创建事件 → 关联源队列，返回事件编号和通知槽 GPUVA
  → 调用方填写 Signal，提交带有 Signal GPUVA 的 AQL
  → CP 按源队列 VMID 访问 Signal 和通知槽
  → CP 提交带有源 MQD 和事件编号的 IH 记录
  → 驱动核对源队列、事件关联及实际通知槽，再保存通知并唤醒
```

一个应用伪造通知地址时，设备仍只能访问该应用页表允许的目标，不能进入管理 DMA 域。驱动不能仅凭 IH 中的事件编号就唤醒其他队列的事件。事件编号与槽的复用仍等待旧通知和相关处理结束，不因同一通知页一直保留就提前复用。

完成顺序继续为结果写回及执行确认、Signal、通知槽、IH、包槽失效与消费回报。每步失败后保留已发生的写入，不能回退已经可见的 Signal，也不能因后续通知失败再次执行任务。

> **[SPEC]** [CP/MEC 第一版规格，Signal 布局](<./CP_MEC 第一版规格.md#spec-signal-layout>)、[可见性](<./CP_MEC 第一版规格.md#spec-dispatch-visibility>)及[失败包收尾](<./CP_MEC 第一版规格.md#spec-failure-retirement>)，2026-10-19 状态：完整 64 位读写、发布顺序和部分完成保留均为已有约束。GPUVM 地址翻译须保留这些性质。

### 6.2 故障记录与停止范围

同一任务可能在取包、取指、参数读取、数组访问或完成写入时失败。先定位失败发生在哪一步，再判断由谁报告、停止谁，以及已经发生的写入是否需要保留：

```text
CP 读取 Ring 或描述对象失败
  → CP 按当前队列保存访问错误

执行器取指、读参数或访问数组失败
  → 执行器结束相关访问并返回失败 → CP 记录源队列错误

CP 写 Signal、通知槽失败
  → 停止后续正常收尾，保留已经发布的结果与状态

源队列错误、IH 可用 → 经 IH 交付驱动
IH 通道本身故障 → 锁存故障，拒绝后续 IH 提交，停止新取包和调度
                → 经独立 IRQ_ERROR 通知 Host

驱动从可用通知路径取得故障
  → 停止受影响的后续工作 → 使相关事件等待退出
  → 检查访问、旧通知和引用是否结束 → 决定保留或回收资源
```

IH 故障分支沿用第二阶段已有协议，不尝试继续依靠故障 IH Ring 投递队列错误。驱动经独立错误中断读取锁存状态，并按共享通道故障的既定范围结束相关等待。

> **[SPEC]** [CP/MEC 第一版规格，7.1.6 IH 故障与恢复前提](<./CP_MEC 第一版规格.md#spec-ih-fault-reset>)，2026-10-19 状态：IH 故障锁存、拒绝后续提交并停止新取包和调度，经已有 `IRQ_ERROR` 通知 Host；错误交付不依赖继续向故障 IH Ring 写入记录。

**[DESIGN] 推荐方案，待确认：** 沿用 AMDGPU 按上下文记录访问地址、权限及翻译故障的思路，区分无效 VMID、上下文未就绪、未映射、权限拒绝、地址越界、页表访问失败和目标存储访问失败。故障记录至少能定位源队列、VMID、GPUVA、访问类型和失败阶段，保留第一次故障，读取不自动清除。

能够归属到用户队列的错误，停止该队列的新取包和派发，保留队列绑定并交付错误等待；其他正常上下文继续运行。管理队列、固件或共享基础通道故障的停止范围沿用第二阶段规则。首次故障快照通过设备状态读取，CP/执行器结果与 IH 继续负责交付原有队列错误；新增枚举在现有编号之后集中定义，不复用旧编号改变含义。

> **[SOURCE]** 固定 Linux 源码：[gmc_v9_0.c，第 562～565 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gmc_v9_0.c#L562-L565)从中断记录恢复故障地址；[第 633～679 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/gmc_v9_0.c#L633-L679)读取访问状态，并区分页表遍历、权限及映射错误。本设备借鉴诊断内容，队列停止及资源保留仍按自己的 CP/IH 协议处理。

任务在发布成功完成之前失败时，不补写成功 Signal。若 Signal 已更新而后续通知失败，保留该值及故障信息。错误记录、队列停止和执行器结果确认分别进行，不能只记录一个 fault 就立即释放仍可能被访问的对象。

例如数组跨页，执行器已写回部分 Z，随后读取 X 的下一页失败：已写入的 Z 不回滚，尚未发布成功的 Signal 保持原状态，驱动通过队列错误结束相关等待。如果 Signal 已为 `0`、之后通知写入失败，则保留 `0` 和通知故障，不能把整项计算重新执行一遍。

可恢复缺页还需要确定怎样补齐映射、保留故障位置并安全继续访问，不能直接等同于重跑整个 Dispatch。推荐首版先完成可定位的错误退出和资源保留，把恢复与重放列为明确边界；是否扩展由 [9.6.2](#gpuvm-confirm-fault) 与实验阶段安排共同决定。

<a id="gpuvm-lifetime"></a>

## 7. 撤销映射、关闭上下文与对象寿命

### 7.1 映射引用与存储释放

**[DESIGN] 推荐方案，待确认：** 沿用对象引用与映射分离的管理方式。GPU 映射持有 GEM 对象引用，队列持有 Ring、进度和地址空间引用；事件池、管理请求、CPU 映射及旧通知处理也持有各自需要的引用。关闭对象句柄只解除句柄引用，实际存储在所有必要引用释放后回收。

撤销 GPU 映射须满足第 5.2 节的队列卸载条件。驱动完成页表更新与翻译失效后，才释放这段 GPU 映射对对象的引用。对象若仍有 CPU 映射或其他使用者，存储继续保留；Host DMA 映射在设备可能访问时也继续有效。

驱动不通过解析任意 Kernel 参数推断全部任务依赖。首版采用“队列存活期间保持已有 GPU 映射”的保守规则，由调用方遵守任务数据的内容寿命；不能仅凭一次等待超时覆盖输入、释放 Signal 或拆除参数映射。

### 7.2 正常关闭与异常退出

正常关闭先由调用方停止提交、完成已预留包的发布、排空并销毁队列，再销毁事件、撤销映射和释放对象。驱动完成旧通知处理、翻译失效和上下文解绑后，才归还 VMID 与页表存储。

进程直接退出时，驱动先禁止新操作并尝试按可安全完成的协议清理。任务未结束、管理结果未知或失效未确认时，保留相应上下文和对象；队列名额、VMID 或显存可能因此暂时不能再次使用。等待超时只结束本次等待，不能触发自动复位，也不能作为访问结束的证明。

第二阶段未知管理结果码的资源回收问题应在第三阶段代码接入前修复，后续 GPUVM 清理继续遵守同一原则，进度见[规格复核记录](<./QEMU GPGPU 实验大纲.md#stage-two-spec-review>)。挂死任务的强制中止、运行中复位和恢复仍归第四阶段。

<a id="gpuvm-device-host-interface"></a>

## 8. 设备接口、Host API 与版本边界

### 8.1 设备侧需要补充的接口

**[DESIGN] 推荐方案，待确认：** 参考 AMDGPU 将页表根、上下文控制和失效请求分开设置。设备提供三个上下文记录，用户上下文保存页表根低高位、使能及状态；32 位地址范围和三级深度固定，不增加首版可调层数。共享失效接口保存目标 VMID、忙、确认和错误状态。CP 窗口补充地址域与 VMID，执行器配置补充本次任务的 VMID，故障入口保存首次故障快照。

Host 驱动独占页表上下文及失效配置；CP 按管理协议配置用户 HQD 和执行器，应用不写这些寄存器。上下文未启用时才能修改根地址，先写低高位、保证顺序，再清理旧翻译并启用；失效忙时拒绝重复请求。冷复位和整体复位清除上下文、TLB、失效及故障状态，CP 单独复位保留 GPUVM 状态，仍不能作为停止计算或释放映射的依据。

寄存器偏移、位段和正式枚举在接入时按现有空闲地址段统一分配，补入本节并用编译期检查及设备用例验证；这些编码属于实现工作，不另列成用户确认项。

已有运行期间 HQD 写权限继续保留，不能因为新增页表寄存器就允许 Host 直接覆盖活动用户队列。用户应用不映射设备管理寄存器，不能直接配置物理 DMA 或整个 VRAM BAR。

### 8.2 Host 操作与能力查询

**[DESIGN] 推荐接口，待确认：** 接口库保留设备、内存、队列和事件的分组，参考 AMDGPU 的 `MAP/UNMAP` 操作，在内存组增加 GPUVA 映射与撤销。映射输入包括所属连接、对象句柄、对象内偏移、GPUVA、长度和权限；驱动校验对象归属、页对齐、重叠、保留区及完整范围。自动分配由库选择并提交具体 GPUVA，指定地址重叠时失败，不隐式替换旧映射。推荐先不开放 `CLEAR/REPLACE` 或延后更新，扩展范围在第 9 节取舍。

映射调用成功表示该段页表和必要失效已经完成，可以用于后续队列创建；撤销成功表示该段 GPU 映射已失效，相应引用已按寿命规则解除。API 同步完成这些操作，不把“软件映射记录已插入”当作设备已经可用。

> **[SOURCE]** 固定 Linux 源码：[amdgpu_gem.c，第 811～886 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_gem.c#L811-L886)检查 VM 地址、权限、操作及所属文件的对象句柄；[第 944～974 行](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/amd/amdgpu/amdgpu_gem.c#L944-L974)分别处理映射、解除、清理和替换，并进入后续 VM 更新。正文先按同步 `MAP/UNMAP` 的推荐子集说明，其他接口范围在 9.7.1 取舍。

创建 Queue 时继续引用 Ring 与进度对象，由驱动核对其有效 GPU 映射、取得引用并填写 MQD。VMID 由所属上下文提供；调用方继续直接发布 AQL，不增加逐任务 Launch ioctl。事件和默认 Signal 等待的分工沿用第二阶段，通知地址按第 6 节更新。

能力查询应返回 GPUVM 接口版本、GPUVA 位宽、页大小、可用地址区间、用户 VMID 容量、允许的映射权限及更新限制。接口库应区分对象句柄、CPU 映射入口、GPUVA 和驱动内部 DMA 地址；正常 GPUVM 使用不需要向应用返回可用于原始物理访问的入口。

### 8.3 旧模式与新地址语义的选择

**[DESIGN] 推荐兼容范围，待确认：** 用明确的模式及接口版本区分旧同步路径、第二阶段物理地址队列路径和第三阶段 GPUVM 路径。设备初始化时选择模式，在本次设备生命周期内固定，不提供运行中切换接口；旧模式按独立实验启动流程回归。同一次设备运行只启用相应的提交与访存规则，不让旧原始物理访问接口成为 GPUVM 的旁路。

新旧模式即使保留相同结构大小，`code_entry`、Ring 地址、参数和 Signal 字段的含义也已变化，必须由能力协商明确区分。旧二进制程序不能因为结构大小匹配就被默认为可在 GPUVM 模式运行。旧模式回归保留为独立运行，不要求本阶段兼容标准 AMD 接口或完整 HSA 软件栈。

<a id="gpuvm-open-interfaces"></a>

## 9. 核心方案、推荐理由与确认记录

本节保留 10 组核心设计问题，按一次任务的依赖顺序讨论。每组说明当前任务、AMDGPU 参考、本设备推荐及其他选择的影响。**第三阶段的这些核心方案目前均待用户确认**；“推荐”表示有依据的候选方案，不表示已经定稿。

```text
9.1 设备入口、VM 归属、BO 与存储管理
  → 9.2 Kernel 怎样表达 GPU 地址和参数
  → 9.3 用什么页表保存映射与权限
  → 9.4 管理对象与用户对象怎样分别访问
  → 9.5 VMID 怎样驻留，映射怎样安全更新
  → 9.6 怎样完成通知、报告故障并结束访问
  → 9.7 怎样向调用方交付接口并处理旧模式
```

AMDGPU 已有的对象关系、页表访问检查及同步原则保留为参考，不需要重新发明；它们在本设备中的接入范围和简化方式仍需取舍。寄存器地址编号、已定语义对应的枚举值、辅助函数划分和具体锁实现，在核心契约确认后统一落实，不单独列成设计选择。

<a id="gpuvm-confirm-objects"></a>

### 9.1 DRM/GEM 入口与内存对象管理

<a id="gpuvm-confirm-connection"></a>

**9.1.1 设备入口与 VM 归属：待确认**

应用需要先建立连接，后续对象、队列和事件才能找到所属地址空间。AMDGPU 在 DRM 文件私有对象中持有 VM，计算路径可以关联已有 VM；正文与证据见[第 2.1 节](#gpuvm-objects)。

推荐通过 DRM render node 承载本实验的设备操作，一个 DRM 文件上下文持有一个 VM，现有 HSAKMT 风格库封装连接，线程共享库连接。这样设备文件、对象句柄和 VM 归属可以在同一入口内核对。

需要取舍的是：采用上述单一入口，还是保留独立计算设备入口，再显式取得或关联 DRM VM。后一种方式能进一步学习 DRM 与计算接口的分层，但要补连接关联、身份校验及关闭顺序。两种方式都不能仅按进程编号猜测某个对象属于哪套 VM。

<a id="gpuvm-confirm-storage"></a>

**9.1.2 BO、内存域与 TTM 接入范围：待确认**

BO 要有实际存储，GPUVA 映射才能指向它。AMDGPU 通过 BO、TTM placement/resource 和 GPUVM 映射配合完成存储与访问管理；分配器只承担其中的实际区间分配。完整关系与迁移流程见[第 2.2 节](#gpuvm-objects)。

推荐先用 GEM/BO 包装现有 Host 一致性存储和 VRAM `gpu_buddy`，跑通固定存储下的 GPUVM。无论是否接入 TTM，内存域、对象引用、CPU/GPU 映射和分配失败行为都要讲清并验证。

需要取舍的是：本阶段先固定存储，还是接入 TTM 的基本资源管理，再选择是否做受控迁移或驱逐。接入 TTM 更贴近真实 AMDGPU 的对象生命周期，但会增加目标内核适配、驻留状态和迁移依赖；固定存储则要明确资源不足时返回失败，不能宣称已有自动迁移能力。即使暂不实现迁移，也保留其对 PTE、TLB、CPU 映射与旧访问的影响说明。

<a id="gpuvm-confirm-addresses"></a>

### 9.2 GPUVA 位宽与执行器参数接口

<a id="gpuvm-confirm-va-width"></a>
<a id="gpuvm-confirm-executor"></a>
<a id="gpuvm-scope-rv32"></a>

**9.2.1 GPU 地址与 Kernel 指针的表达：待确认**

调用方要把代码、参数和数组地址交给 RV32 Kernel。现有描述对象和数组参数按 32 位组织，参数通过固定只读窗口访问；扩大地址空间会同时影响这些入口，不能只增加一个页表根寄存器。正文见[第 3.1 节](#gpuvm-addresses)与[第 4.3 节](#gpuvm-executor)。

推荐先采用 32 位 GPUVA，保留 RV32 执行器、16 字节描述对象和参数窗口，代码及数组字段改为 GPUVA。64 位地址槽仍保留宽度并检查高位，Host DMA 目标位宽另按页表格式校验。

需要取舍的是：保留参数窗口，还是在 32 位 GPUVA 下让 `a0` 直接指向参数 GPUVA。直接指向更统一，但需调整参数读取、长度保护和旧 Kernel 的接口约定；保留窗口改动较小，但有特殊地址区间和两步寻址。若要使用更宽 GPUVA，还需设计 RV32 如何表达和访问更宽指针，并评估执行器或参数布局变化。零页、窗口和通知区间应随本项一起确定。

<a id="gpuvm-confirm-pages"></a>

### 9.3 页表层级、存储与权限

<a id="gpuvm-confirm-page-format"></a>
<a id="gpuvm-confirm-memory-access"></a>
<a id="gpuvm-confirm-host-dma"></a>

**9.3.1 本设备的页表结构：待确认**

设备拿到 GPUVA 与 VMID 后，需要沿页表找到实际页面并检查权限。AMDGPU 的 4 KiB 页、64 位表项、分级目录和访问权限提供了参考；本设备究竟保留几级、表页放在哪里、支持哪些位，仍是设计选择。正文的具体推导见[第 3.2 节](#gpuvm-addresses)。

推荐组合为：32 位 GPUVA、三级索引 `2 + 9 + 9 + 12`、4 KiB 表页和 8 字节表项，表页放在受保护 VRAM。采用 AMDGPU 常用有效、区域和读写取指位的子集，实际目标地址按 48 位检查，协议中的 DMA 地址槽继续保留 64 位存储。

可选择另一套较小的教学层级。例如同为 32 位 GPUVA 和 4 KiB 基本页，两级 `10 + 10 + 12` 配合 8 字节表项时，每张表为 8 KiB；它减少一次查表，但表大小和稀疏分配开销不同。表页也可以考虑 Host RAM，但页表遍历本身就要走受信任 DMA 路径。需要一并取舍层级、存放位置、目标地址能力和权限范围，不能把这些参数全当成 AMDGPU 自动给出的结论。

共享字段的完整读写、禁止越界、跨页逐段检查和失败后保留已有写入，属于选定格式后必须满足的访问契约。页表不能把超范围目标先掩码再悄悄映射到另一处。

<a id="gpuvm-confirm-access"></a>

### 9.4 管理域、用户域与 CP 交接

<a id="gpuvm-confirm-address-fields"></a>
<a id="gpuvm-confirm-mqd"></a>
<a id="gpuvm-confirm-cp-window"></a>

**9.4.1 对象地址域与上下文传递：待确认**

CP 先读取 MQD 才知道用户队列的地址空间，因此 MQD 自身和 MQD 内保存的用户地址需要分别解释。所有用户取包、取指、参数、数组、Signal 与通知访问都要有可追踪的上下文，完整路径见[第 4 节](#gpuvm-access-paths)。

推荐用户对象使用 GPUVA，MQD、管理 Ring、管理结果和 IH 继续使用受信任管理 DMA 路径；保留 MQD/HQD 主体布局，扩展 CP 窗口及 Dispatch 上下文快照。每次请求明确地址域、VMID、目标地址和长度，避免切换队列后误用旧上下文。

需要取舍的是：先保留上述管理直通，还是也为管理域建立受保护页表。后者更接近 AMDGPU 为管理上下文配置翻译的关系，但要设计初始页表、启动顺序和管理域故障处理。无论选哪种方式，用户都不能配置管理根或把伪造的 GPUVA 当作物理 DMA 地址；只翻译数组而保留其他用户物理访问，也不能完成本阶段隔离目标。

<a id="gpuvm-confirm-contexts"></a>

### 9.5 VMID 驻留与映射更新

<a id="gpuvm-confirm-vmid"></a>
<a id="gpuvm-confirm-reuse"></a>

**9.5.1 VMID 容量、分配时机与驻留策略：待确认**

软件 VM、VMID 和 HQD 分别表示地址空间、当前翻译上下文编号与驻留队列状态。同一 VM 可以有多条队列，增加 VMID 也不会自动增加第二阶段的两个用户 Queue 名额。正文见[第 5.1 节](#gpuvm-context-tlb)。

推荐先提供两个用户 VMID，首次 GPU 映射时申请并持有到 VM 销毁，没有名额时返回资源不足。这个策略限制的是同时保有 GPU 映射的 VM 数量：即使前两个应用暂时没有执行任务，只要仍持有绑定，第三个 VM 也不能直接取得名额。

需要取舍的是：接受两个固定驻留上下文、增加固定用户 VMID 容量，还是在本阶段引入更多软件 VM 的轮换。增加固定容量主要扩展设备状态和管理范围；轮换还要安排旧访问结束、页表绑定、TLB、队列状态及旧通知的安全复用。具体编号、分配时机和名额不足行为应随策略一起确认。

<a id="gpuvm-confirm-invalidate"></a>
<a id="gpuvm-scope-live-update"></a>

**9.5.2 页表更新方式与队列存活条件：待确认**

AMDGPU 通过更新依赖和同步状态安排页表与后续任务，CPU 写表也是已有实现路径。本项目直接发布 AQL，尚不能靠驱动解析全部任务来建立同样的依赖关系。需要明确更新时谁阻止新访问、谁确认旧访问结束，见[第 5.2 节](#gpuvm-context-tlb)。

推荐首版采用 CPU 同步写表、按 VMID 全量失效并等待本次确认；修改映射前先排空并卸载该 VM 的全部用户队列。这条规则易于验证，但会限制队列存活期间的内存申请、撤销和重新映射。

可选择在队列保持驻留时，通过停止后续取包、等待当前访问结束、更新后继续的协议修改映射；进一步还可接入异步更新和相应依赖。这会增加控制与同步工作，但不必一开始就要求 Kernel 执行中途抢占。需要用户取舍本阶段做到哪一级；仅由应用报告“目前空闲”不足以关闭并发提交窗口。确认请求、失败保留与旧遍历收尾仍是各方案都要满足的条件。

<a id="gpuvm-confirm-completion"></a>

### 9.6 Signal、访问故障与资源释放

<a id="gpuvm-confirm-signal"></a>

**9.6.1 通知槽的访问路径与保护边界：待确认**

Signal 和通知槽是设备写入 Host RAM 的路径，必须放进完整隔离分析。第二阶段的 24 字节 Signal、单一更新者和完成发布顺序继续作为基础，但通知地址怎样取得、谁能写入，需要由第三阶段明确。正文见[第 6.1 节](#gpuvm-signal)。

推荐把 Signal 和通知槽引用改为用户 GPUVA，由驱动预先建立内部通知池映射，运行中创建事件只分配已有槽。这样继续使用用户 VM 做跨上下文隔离，驱动核对源队列、事件和实际通知槽；正文中的 4 KiB、512 槽及固定 GPUVA 只是该方案的建议配置。

需要取舍的是：接受同一 VM 内普通 Kernel 也可能写通知页的权限边界，还是要求通知只能经受信任 CP 路径写入。若要求后者，应由管理记录取得合法目标，或增加能够区分访问主体的权限机制，不能仅给页表加普通写权限就宣称实现 CP 独占。需要一起确认通知池容量、分配和复用协议，并保留对部分完成状态的说明。

<a id="gpuvm-confirm-fault"></a>
<a id="gpuvm-confirm-release"></a>

**9.6.2 故障归属、停止范围与恢复边界：待确认**

取包、取指、参数、数组和完成写入的失败位置不同，错误也可能影响一条队列、整个 VM 或共享管理通道。故障记录、停止后续工作、结束已有访问和释放对象是不同步骤，正文的完整故障路径见[第 6.2 节](#gpuvm-signal)与[第 7 节](#gpuvm-lifetime)。

推荐先实现可定位的首次故障、明确停止范围和错误等待退出，不自动重放任务；能够归属到单条用户队列的错误先停源队列，损坏上下文或共享通道时扩大到相应影响范围。Signal、数组和进度中已经发生的写入保留，无法确认访问结束时继续保留资源。

需要取舍的是：首版保持上述按来源划分的退出，还是为简化实现将用户错误统一提升到 VM 级停止，以及本阶段是否加入受控的可恢复访问故障。统一停止更容易管理，但影响同 VM 的健康队列；恢复需要补齐映射、故障位置与继续执行的协议，不能盲目重跑 Dispatch。强制中止和运行中复位仍按第四阶段范围处理，普通等待超时不能代替访问结束。

<a id="gpuvm-confirm-host-api"></a>

### 9.7 Host 映射 API 与旧模式兼容

<a id="gpuvm-confirm-host-map"></a>
<a id="gpuvm-confirm-compatibility"></a>
<a id="gpuvm-confirm-observability"></a>

**9.7.1 向调用方交付的接口范围：待确认**

调用方需要知道操作返回时已经完成什么、地址何时可以使用，以及旧程序需要怎样适配。AMDGPU 的地址映射操作区分映射、解除、清理与替换；本实验采用哪一组子集及完成语义，是接口契约，见[第 8 节](#gpuvm-device-host-interface)。

推荐先提供同步 GPUVA `MAP/UNMAP`，输入为对象句柄、偏移、GPUVA、长度及权限；支持库选址或指定空闲地址。成功返回须包含页表更新和必要失效的完成。队列创建引用已映射对象，调用方继续直接发布 AQL，不增加逐任务 Launch ioctl。

需要取舍的是：是否在本阶段增加区间清理、替换或异步映射，以及 GPUVM 新接口与旧库、旧物理地址队列模式的兼容范围。建议新语义使用明确版本，旧模式独立启动回归；若希望保留更完整的旧库调用兼容，需要定义转换与拒绝规则。任何兼容方式都不能让旧原始物理访问绕过新的对象归属和隔离检查。

确认上述核心行为后，再集中落实正式结构、错误枚举、寄存器偏移和并发保护，并补回对应正文。用户可从 9.1 开始按依赖逐组对齐，不要求一次决定全部事项。正式验收场景与运行结果继续在[第三阶段大纲](<./QEMU GPGPU 实验大纲.md#stage-three-vmid>)维护。
