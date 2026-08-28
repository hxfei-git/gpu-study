# GPU 内存管理基础

## 缩写表

| 缩写    | 英文全称                                  | 中文含义                                 |
| ------- | ----------------------------------------- | ---------------------------------------- |
| AMDGPU  | AMD GPU Linux Kernel Driver               | AMD GPU Linux 内核驱动                   |
| API     | Application Programming Interface         | 应用程序编程接口                         |
| AQL     | Architected Queuing Language              | HSA 定义的架构化队列包格式               |
| BAR     | Base Address Register                     | PCIe 基址寄存器；用于暴露设备地址窗口    |
| BO      | Buffer Object                             | 驱动用于管理一块缓冲区的对象             |
| CLR     | Common Language Runtime                   | ROCm 中承接上层计算接口的运行时层        |
| CP      | Command Processor                         | GPU 命令处理器                           |
| CPU     | Central Processing Unit                   | 中央处理器                               |
| DMA     | Direct Memory Access                      | 设备直接内存访问                         |
| DRM     | Direct Rendering Manager                  | Linux 直接渲染管理框架                   |
| FB      | Frame Buffer                              | 帧缓冲；源码中的 FB BAR 指显存窗口        |
| GART    | Graphics Address Remapping Table          | 图形地址重映射表                         |
| GEM     | Graphics Execution Manager                | DRM 的图形内存对象管理框架               |
| GPU     | Graphics Processing Unit                  | 图形处理器                               |
| GPUVA   | GPU Virtual Address                       | GPU 虚拟地址                             |
| GPUVM   | GPU Virtual Memory                        | GPU 虚拟地址空间及其页表                 |
| GTT     | Graphics Translation Table                | AMDGPU 中主要表示 GPU 可访问的系统内存域 |
| HMM     | Heterogeneous Memory Management           | 异构内存管理                             |
| HQD     | Hardware Queue Descriptor                 | 硬件队列描述状态                         |
| HSA     | Heterogeneous System Architecture         | 异构系统架构                             |
| IB      | Indirect Buffer                           | 间接命令缓冲区                           |
| IOMMU   | Input/Output Memory Management Unit       | 输入/输出内存管理单元                    |
| IOVA    | Input/Output Virtual Address              | 输入/输出虚拟地址                        |
| ioctl   | Input/Output Control                      | 用户态向内核驱动发送控制请求的接口       |
| KFD     | Kernel Fusion Driver                      | Linux AMD GPU 计算驱动接口               |
| KiB     | Kibibyte                                  | 二进制千字节，1 KiB 等于 1024 字节       |
| MEC     | Micro Engine Compute                      | AMD GPU 中处理计算队列的命令处理引擎     |
| MMIO    | Memory-Mapped Input/Output                | 内存映射输入/输出                        |
| MMU     | Memory Management Unit                    | 内存管理单元                             |
| MQD     | Memory Queue Descriptor                   | 保存在内存中的队列配置描述               |
| PA      | Physical Address                          | 物理地址                                 |
| PASID   | Process Address Space ID                  | 进程地址空间标识                         |
| PCIe    | Peripheral Component Interconnect Express | 高速外设互连总线                         |
| PFN     | Page Frame Number                         | 物理页框编号                             |
| PTE     | Page Table Entry                          | 页表项                                   |
| RAM     | Random Access Memory                      | 随机存取存储器；本文主要指系统内存       |
| ROCr    | ROCm Runtime                              | ROCm 的 HSA 用户态运行时                 |
| SC      | Sequential Consistency                    | 顺序一致性内存顺序                       |
| SDMA    | System Direct Memory Access               | AMD GPU 中负责数据搬运的专用引擎         |
| SG      | Scatter-Gather                            | 分散—聚集页面描述                       |
| SVM     | Shared Virtual Memory                     | 共享虚拟内存                             |
| TLB     | Translation Lookaside Buffer              | 地址翻译缓存                             |
| TTM     | Translation Table Maps                    | DRM 的缓冲对象放置和迁移管理器           |
| UAPI    | User-space Application Programming Interface | 内核提供给用户态的接口                |
| USERPTR | User Pointer                              | 使用现有用户态指针及页面的内存路径       |
| VA      | Virtual Address                           | 虚拟地址                                 |
| VMID    | Virtual Memory ID                         | GPU 活动地址空间使用的硬件上下文编号     |
| VRAM    | Video Random-Access Memory                | GPU 本地显存                             |
| WC      | Write Combining                           | 写合并                                   |

> 缩写表只用于查阅。正文会在概念首次出现时重新解释，不要求预先背诵。

## 全文大纲

GPU 内存管理不是单纯的“申请显存”。一块内存要真正被 CPU 和 GPU 使用，至少要同时解决位置、地址、映射、生命周期和可见性问题。

| 章节    | 核心问题                      | AQL 在本章中的位置                   |
| ------- | ----------------------------- | ------------------------------------ |
| 第 0 章 | GPU 内存管理到底要解决什么    | 用一段 16 KiB AQL Ring 固定问题背景  |
| 第 1 章 | CPU 和 GPU 怎样找到真正的数据 | Ring 只是 system RAM 映射的一个例子  |
| 第 2 章 | 内存怎样分配、映射并安全释放  | Ring 只演示 Queue 为什么必须持有引用 |
| 第 3 章 | CPU 和 GPU 怎样看见彼此的写入 | Packet→Doorbell 只演示发布顺序      |

> **[BOUNDARY]** 本文不展开完整 AQL Dispatch、MQD/HQD、CP/MEC 调度，也不展开通用 DRM/GEM/TTM 框架和普通 IB 提交。这些内容登记在 [待补充的知识点](./待补充的知识点.md)。本文只保留理解 AQL 内存行为所必需的接口和对象关系。

Linux 虚拟地址、物理页、页表和 DMA 的 CPU 侧基础可在 [01_Linux 内存管理基础](<./01_Linux 内存管理基础.md>) 中回看。本文 Linux 源码统一基于本地版本 `248951ddc14de84de3910f9b13f51491a8cd91df`，ROCr 源码基于 `ba56a24c6132c5d195686ae4adf969ca1222fbba`，ROCm CLR 源码基于 `81277d69e3352e7144ced2ee9601484f9b48d950`。

## 0. GPU 内存管理要解决什么

### 0.1 一块 GPU 可用内存涉及四个问题

假设程序需要一段 16 KiB、CPU 和 GPU 都能访问的缓冲区。“成功申请了 16 KiB”只回答了一小部分问题：

| 问题                     | 要确认什么                                         | 没解决时会怎样                          |
| ------------------------ | -------------------------------------------------- | --------------------------------------- |
| 数据放在哪里             | system RAM 还是 VRAM；由哪些页面或显存区间承载     | 根本不知道数据的实际存储位置            |
| CPU/GPU 使用什么地址     | CPU VA、GPUVA、DMA 地址、IOVA、PA 分别属于谁       | 把不同地址空间中的数字误当成同一地址    |
| 怎样建立访问关系         | CPU 页表、GPU 页表、必要时的 IOMMU 映射是否存在    | 地址存在，但访问会 fault 或到达错误位置 |
| 怎样保证生命周期与可见性 | 使用期间对象和映射是否有效；写入是否按正确顺序可见 | 提前释放、读取旧数据或读取半写入数据    |

这四个问题可以压缩成一条主线：

```text
存储资源已经存在
        ↓
CPU和GPU各自获得可用地址
        ↓
页表或窗口把地址连接到存储资源
        ↓
使用者持有对象和映射，防止资源提前消失
        ↓
同步与缓存规则保证双方看到正确内容
```

这里的“对象”只是驱动管理资源和生命周期的手段，不是另一份数据；“地址”只是访问者找到数据的名字，也不是数据本身。

### 0.2 CPU 和 GPU 访问内存的总矩阵

本文以带独立 VRAM 的离散 AMD GPU 为主。先固定最常见的四种访问：

| 访问者 | 目标       | 典型路径                                    | 是否经过 PCIe |
| ------ | ---------- | ------------------------------------------- | ------------- |
| CPU    | system RAM | CPU VA → CPU MMU → Host PA → RAM         | 否            |
| CPU    | VRAM       | CPU VA → CPU 页表 → PCIe BAR 窗口 → VRAM | 是            |
| GPU    | system RAM | GPUVA → GPU MMU → DMA 地址 → PCIe → RAM | 是            |
| GPU    | VRAM       | GPUVA → GPU MMU → 本地显存地址 → VRAM    | 否            |

分别画出来是：

```text
CPU访问system RAM                 CPU访问CPU可见VRAM

CPU load/store                    CPU load/store
      ↓                                 ↓
CPU MMU                           CPU MMU
      ↓                                 ↓
Host PA                           BAR映射的MMIO地址
      ↓                                 ↓ PCIe
system RAM                        VRAM


GPU访问system RAM                 GPU访问本地VRAM

GPU load/store或取包              GPU load/store
      ↓                                 ↓
GPU MMU                           GPU MMU
      ↓                                 ↓
DMA地址                           本地显存地址
      ↓ PCIe                            ↓
system RAM                        VRAM
```

从主机平台的角度看，GPU 对 system RAM 发起的读写属于设备 DMA 访问；这不表示每次访问都由 SDMA 引擎执行。Shader、命令处理前端和 SDMA 都可能成为发起者，SDMA 只是其中专门负责“读源再写目标”的搬运引擎。

还要修正一个常见误区：

> 不是所有 CPU↔GPU 内存访问都经过 PCIe。CPU 访问本机 RAM、GPU 访问本地 VRAM 都不经过 PCIe；只有跨越主机与离散 GPU 边界的路径才通常经过 PCIe。

### 0.3 访问、拷贝和通知不是同一件事

三种动作经常都表现为“写了一个地址”，但目的完全不同：

| 动作 | 本质                                 | 例子                                         |
| ---- | ------------------------------------ | -------------------------------------------- |
| 访问 | 一个执行者对目标地址做 load/store    | GPU Shader 读取 system RAM 中的输入          |
| 拷贝 | 一个引擎读取源地址，再写入目标地址   | SDMA 把 system RAM 数据搬到 VRAM             |
| 通知 | 写设备控制窗口，告诉硬件状态发生变化 | CPU 写 Doorbell MMIO，通知 Queue 有新 Packet |

```text
直接访问：
GPU读取system RAM中的数据

数据拷贝：
SDMA读system RAM → SDMA写VRAM

通知：
CPU写Doorbell → GPU得知“请检查Ring”
```

Doorbell 不包含 Packet 数据，也不会把 Packet 搬到 GPU。Packet 仍留在 Ring 中，GPU 收到通知后再通过已经建立好的地址映射读取它。

### 0.4 贯穿案例：16 KiB AQL Ring

后文使用一段 16 KiB AQL Ring 作为贯穿例子，并作如下教学假设：

| 项目     | 本文假设                                         |
| -------- | ------------------------------------------------ |
| 数据位置 | 4 个 4 KiB system RAM 页面                       |
| CPU 用途 | ROCr 在 Ring 中填写 AQL Packet                   |
| GPU 用途 | GPU 队列前端读取 Packet                          |
| CPU 地址 | 一段连续 CPU VA                                  |
| GPU 地址 | 一段连续 GPUVA                                   |
| 生命周期 | Queue 存活期间，Ring 的 BO 和 GPUVM 映射保持有效 |
| 可见性   | CPU 发布完整 Packet 后，才写 Doorbell            |

```text
同一份16 KiB Ring数据

CPU侧：CPU VA ──→ 4个system RAM页面
                         ↑
GPU侧：GPUVA ──→ GPU页表 ┘
```

这个例子会反复回答四个问题：

1. 4 个页面怎样被 CPU 和 GPU 分别找到？
2. GPUVA 怎样翻译到这些页面？
3. Queue 使用期间，为什么不能删掉映射或释放 BO？
4. CPU 写完 Packet 后，怎样保证 GPU 读到完整内容？

> **[BOUNDARY]** 16 KiB 只是便于画出 4 个页面的示例，不是 ROCr 固定的 Ring 大小。本文也不会借这个例子展开完整 Queue 创建和 Kernel Dispatch。

## 1. GPU 怎样找到真正的数据

### 1.1 数据可能放在哪里

在当前离散 GPU 模型中，最重要的两类物理存储是：

| 存储       | 所在位置     | 谁访问更自然 | 典型特点                                      |
| ---------- | ------------ | ------------ | --------------------------------------------- |
| system RAM | 主机内存     | CPU          | CPU 直接访问；GPU 通常经 PCIe/DMA 访问        |
| VRAM       | GPU 本地内存 | GPU          | GPU 本地高带宽访问；CPU 只能访问 BAR 可见部分 |

GPUVA 并不天然属于某一种存储。一套 GPU 页表可以让不同 GPUVA 页面分别指向 system RAM 或 VRAM。

**[SOURCE]** Linux `248951ddc14de84de3910f9b13f51491a8cd91df` 的 [`drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c`](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c) 第 51～58 行写道：

```c
/*
 * GPUVM is the MMU functionality provided on the GPU.
 * ...
 * The GPUVM page tables can contain a mix
 * VRAM pages and system pages (both memory and MMIO) and system pages
 * can be mapped as snooped (cached system pages) or unsnooped
 * (uncached system pages).
 */
```

中文翻译：

```text
GPUVM 是 GPU 提供的 MMU 功能。

GPUVM 页表可以混合包含 VRAM 页面和 system RAM 页面；
system RAM 页面还可以按 snooped（参与缓存一致性观察）
或 unsnooped（不采用这种观察方式）映射。
```

因此：

```text
GPUVA范围
├─ 某些PTE → VRAM
└─ 某些PTE → system RAM
```

“这是 GPUVA”只说明 GPU 使用什么虚拟地址访问；真正的数据位置要看最终 PTE。

### 1.2 CPU 和 GPU 分别怎样到达数据

CPU 访问 system RAM 使用普通 CPU 地址翻译，这部分已经在 Linux 内存基础中学习过：

```text
CPU VA → CPU MMU / CPU页表 → Host PA → system RAM
```

GPU 访问本地 VRAM 仍然可以从 GPUVA 开始，但最终落在 GPU 本地内存系统中：

```text
GPUVA → GPU MMU / GPU页表 → 本地显存地址 → VRAM
```

GPU 访问 system RAM 则跨过离散 GPU 与主机之间的互连：

```text
GPUVA → GPU MMU / GPU页表 → DMA地址 → PCIe → system RAM
```

CPU 访问 VRAM 时，CPU 不能直接使用 GPUVA。驱动要把可见 VRAM 通过 PCIe BAR 暴露到 CPU 的物理/MMIO 地址空间，再由 CPU 页表建立 CPU VA：

```text
CPU VA
  → CPU页表
  → BAR窗口中的主机物理/MMIO地址
  → PCIe
  → VRAM中的目标位置
```

**[SOURCE]** Linux 的 [`drivers/gpu/drm/amd/amdgpu/amdgpu_gmc.h`](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_gmc.h) 第 223～234 行专门区分 CPU 视角的 aperture 与 GPU 视角的地址：

```c
/* FB's physical address in MMIO space (for CPU to
 * map FB). This is different compared to the agp/
 * gart/vram_start/end field as the later is from
 * GPU's view and aper_base is from CPU's view.
 */
resource_size_t aper_size;
resource_size_t aper_base;
/* 省略mc_vram_size字段及其注释。 */
u64 visible_vram_size;
```

中文翻译：

```text
aper_base/aper_size描述CPU为了映射显存而使用的MMIO窗口；
它不同于从GPU视角描述的GART/VRAM地址。
visible_vram_size表示CPU当前能够直接看见的VRAM范围。
```

Large BAR 与 Small BAR 的基础区别只在“CPU 一次能看见多少 VRAM”：

| 情况      | CPU 可见范围              | 当前阶段的结论                                                     |
| --------- | ------------------------- | ------------------------------------------------------------------ |
| Large BAR | 通常覆盖全部 VRAM         | 落在可见范围内的 VRAM BO 可建立 CPU 直映射                         |
| Small BAR | 只覆盖较小窗口            | 只有窗口内的 VRAM 可直接映射；其他数据可能需要迁移、换窗或 staging |

**[SOURCE]** 同一 Linux 版本的 [`drivers/gpu/drm/amd/amdgpu/amdgpu_device.c`](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_device.c) 第 1115～1122、1152～1155 行说明驱动尝试扩大 BAR 的目标：

```c
/*
 * Try to resize FB BAR to make all VRAM CPU accessible.
 */
int amdgpu_device_resize_fb_bar(struct amdgpu_device *adev)
{
	int rbar_size = pci_rebar_bytes_to_size(adev->gmc.real_vram_size);
	/* ... */
	if (adev->gmc.real_vram_size &&
	    (pci_resource_len(adev->pdev, 0) >= adev->gmc.real_vram_size))
		return 0;
```

中文翻译：驱动尝试把 Frame Buffer BAR 调整到足以让全部 VRAM 对 CPU 可访问；如果 BAR 已经覆盖真实 VRAM 大小，就不必再调整。

> **[BOUNDARY]** BAR 只解决 CPU 能否把某段 VRAM 放入自己的地址空间，不保证这种访问与 GPU 本地访问同样快，也不自动解决缓存一致性。

### 1.3 地址不能混为一谈

| 地址      | 谁使用或解释          | 当前阶段需要记住的含义            |
| --------- | --------------------- | --------------------------------- |
| CPU VA    | CPU 程序、CPU MMU     | CPU 指令中的虚拟地址              |
| GPUVA     | GPU 引擎、GPU MMU     | 某个 GPUVM 中的虚拟地址           |
| DMA 地址  | 设备和主机 DMA 子系统 | 驱动交给设备使用的统一名称        |
| IOVA      | Host IOMMU            | 启用 IOMMU 转换时的一类 DMA 地址  |
| Host PA   | 主机物理内存系统      | system RAM 页面对应的主机物理地址 |
| VRAM 地址 | GPU 本地内存系统      | GPU 到达本地显存资源所用的地址    |

最容易混淆的是 DMA 地址、IOVA 与 Host PA。DMA 地址是驱动层使用的统一术语；它是否表现为 IOVA，取决于平台是否为设备启用 Host IOMMU。

**[SOURCE]** Linux [`Documentation/core-api/dma-api-howto.rst`](./2.源码/linux/Documentation/core-api/dma-api-howto.rst) 第 81～88 行解释了有无 IOMMU 的差异：

```text
In some simple systems, the device can do DMA directly to physical address
Y. But in many others, there is IOMMU hardware that translates DMA
addresses to physical addresses, e.g., it translates Z to Y.

dma_map_single() ... sets up any required IOMMU mapping and returns the DMA
address Z. The driver then tells the device to do DMA to Z, and the IOMMU
maps it to the buffer at address Y in system RAM.
```

中文翻译：

```text
在简单系统中，设备可能直接对物理地址Y发起DMA。
在许多其他系统中，IOMMU把DMA地址Z翻译成物理地址Y。

DMA映射接口建立必要的IOMMU映射并返回Z；
驱动让设备访问Z，IOMMU再把它映射到system RAM中的Y。
```

于是 system RAM 有两种典型路径。

启用 Host IOMMU：

```text
GPUVA
  → GPU MMU
  → DMA地址（本例是IOVA）
  → Host IOMMU
  → Host PA
  → system RAM
```

未启用 Host IOMMU：

```text
GPUVA
  → GPU MMU
  → 直连DMA/总线地址
  → 主机桥
  → system RAM
```

而访问本地 VRAM 时：

```text
GPUVA
  → GPU MMU
  → 本地显存地址
  → VRAM
```

因此必须记住：

```text
GPUVA不是IOVA
IOVA不是CPU VA
DMA地址不保证等于Host PA
GPU PTE的目标也不一定是IOVA
```

### 1.4 GPU 地址翻译

现在把 GPU MMU、GPU 页表、PTE、GPU TLB 和 Host IOMMU 放进同一张图。假设 GPU 访问位于 system RAM 的 Ring 第 0 页，并且 Host IOMMU 已启用：

```text
GPU引擎发出 GPUVA 0x1000_0120
        │
        ▼
GPU TLB查询
   ┌────┴────┐
   │命中     │未命中
   ▼         ▼
缓存的翻译   从根页表逐级查找
                  │
                  ▼
              最终GPU PTE
                  │ 地址部分：IOVA 0x1234_5000
                  │ 属性：VALID/SYSTEM/READABLE...
                  ▼
翻译结果 0x1234_5120
        │
        ▼
Host IOMMU：IOVA → Host PA
        │
        ▼
system RAM第0页内偏移0x120
```

GPU MMU 负责解释 GPUVA；Host IOMMU 只在设备访问主机内存时解释 IOVA。两者不是同一个 MMU，也不查询同一套页表。

最终 PTE 不是缓冲区数据，而是“目标页面地址 + 访问属性”。

**[SOURCE]** Linux 的 [`drivers/gpu/drm/amd/amdgpu/amdgpu_vm.h`](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.h) 第 57～68 行列出一部分 PTE 属性：

```c
#define AMDGPU_PTE_VALID	(1ULL << 0)
#define AMDGPU_PTE_SYSTEM	(1ULL << 1)
#define AMDGPU_PTE_SNOOPED	(1ULL << 2)
/* 省略与当前说明无关的属性位。 */
#define AMDGPU_PTE_EXECUTABLE	(1ULL << 4)
#define AMDGPU_PTE_READABLE	(1ULL << 5)
#define AMDGPU_PTE_WRITEABLE	(1ULL << 6)
```

`VALID` 表示映射有效，`SYSTEM` 表示目标是 system memory，`READABLE`、`WRITEABLE`、`EXECUTABLE` 表示访问权限。地址部分在不同目标下含义不同：

| PTE 映射目标             | PTE 地址部分可怎样理解 | 后续是否经过 Host IOMMU |
| ------------------------ | ---------------------- | ----------------------- |
| system RAM，IOMMU 开启   | DMA 地址，通常是 IOVA  | 是                      |
| system RAM，IOMMU 未开启 | 直连 DMA/总线地址      | 否                      |
| 本地 VRAM                | GPU 本地显存地址       | 否                      |

**[SOURCE]** Linux [`drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c`](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c) 第 1310～1313、1369～1373 行展示 system RAM BO 的 DMA 地址数组怎样进入 GPUVM 更新：

```c
mem = bo->tbo.resource;
if (mem && (mem->mem_type == TTM_PL_TT ||
	    mem->mem_type == AMDGPU_PL_PREEMPT))
	pages_addr = bo->tbo.ttm->dma_address;

/* 省略权限和代际相关PTE属性处理。 */
r = amdgpu_vm_update_range(adev, vm, false, false, flush_tlb,
			   !uncached, &sync, mapping->start,
			   mapping->last, update_flags,
			   mapping->offset, vram_base, mem,
			   pages_addr, last_update);
```

这里的 `TTM_PL_TT` 表示 TTM 的 system-memory 放置类型。`pages_addr` 的类型是 `dma_addr_t *`。同一文件第 945～957 行在生成具体页面目标时，按页索引从这个 DMA 地址数组取值：

```c
uint64_t amdgpu_vm_map_gart(const dma_addr_t *pages_addr, uint64_t addr)
{
	uint64_t result;

	/* page table offset */
	result = pages_addr[addr >> PAGE_SHIFT];

	/* in case cpu page size != gpu page size*/
	result |= addr & (~PAGE_MASK);
	result &= 0xFFFFFFFFFFFFF000ULL;

	return result;
}
```

中文翻译：`pages_addr` 是每个 system RAM 页面对设备可用的 DMA 地址；函数先按页面索引取出对应地址，再处理 CPU 页大小与 GPU 页大小不同所需的页内偏移。若 Host IOMMU 为该 GPU 提供转换，这些 `dma_addr_t` 值就是 IOVA；否则是直连 DMA/总线地址。

这给出一个更精确的回答：GPU 页表项不是抽象地“永远存 IOVA”，而是为 system RAM 映射写入设备可用的 DMA 地址；只有启用 Host IOMMU 时，这个 DMA 地址才表现为 IOVA。映射 VRAM 时则使用本地显存资源地址。

函数名 `amdgpu_vm_map_gart()` 中虽然带有 `gart`，但这里看到的实际动作是从 system page 的 DMA 地址数组中取值并生成 PTE 目标；不能仅凭函数名再虚构一层固定的“GPUVM→GART→IOVA”硬件翻译。GTT、GART 与 GPUVM 的职责边界在第 1.6 节集中说明。

GPU TLB 只是翻译结果缓存，不是页表。页表修改后，如果旧 TLB 项仍有效，GPU 可能继续使用旧目标：

```text
旧状态：GPUVA G → PTE → 页面P0
                    TLB也缓存G → P0

修改后：GPUVA G → 新PTE → 页面P1
                    TLB仍缓存G → P0
```

正确顺序是：

```text
写完新PTE
  → 等待页表更新完成并可见
  → 使对应GPU TLB旧翻译失效
  → GPU再次访问时重新遍历页表
```

TLB 失效清除的是“旧地址翻译”，不是清空 Ring 或 Kernel 数据。第 2 章会在 `MAP_MEMORY_TO_GPU` 路径中看到“同步页表更新后再 flush TLB”。

### 1.5 地址空间怎样被选择

同一个 GPUVA 数值可以在不同进程中指向不同数据，所以 GPU MMU 在查页表前必须知道“使用哪套地址空间”。

| 名称         | 当前阶段的角色                               |
| ------------ | -------------------------------------------- |
| GPUVM        | 软件管理的一套 GPU 虚拟地址空间及页表        |
| PASID        | 标识进程/地址空间身份的较长期编号            |
| VMID         | GPU 当前活动翻译上下文使用的有限硬件槽位编号 |
| 页表根寄存器 | 告诉 GPU MMU：这个 VMID 的根页表在哪里       |

可以先这样记：

```text
PASID回答：“这是谁的地址空间？”
VMID回答： “当前硬件用哪个活动槽位执行它？”
根页表寄存器回答：“这套页表从哪里开始？”
```

**[SOURCE]** Linux [`drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c`](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c) 第 51～67 行说明，GPU 可以同时激活多套 GPUVM 页表，每个活动 GPUVM 与一个 VMID 关联：

```c
/*
 * GPUVM is the MMU functionality provided on the GPU.
 * ...
 * there can be multiple GPUVM page tables active at any given time.
 * ...
 * Each active GPUVM has an ID associated with it and there is a page table
 * linked with each VMID.
 */
```

中文翻译：

```text
GPUVM是GPU提供的MMU功能；
系统可以同时启用多套GPUVM页表；
每个活动GPUVM都有对应标识，每个VMID都关联一套页表。
```

**[SOURCE]** 以 GFXHUB v2.0 为具体例子，[`drivers/gpu/drm/amd/amdgpu/gfxhub_v2_0.c`](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/gfxhub_v2_0.c) 第 120～131 行按 VMID 写入根页表地址寄存器：

```c
static void gfxhub_v2_0_setup_vm_pt_regs(struct amdgpu_device *adev,
					 uint32_t vmid,
					 uint64_t page_table_base)
{
	struct amdgpu_vmhub *hub = &adev->vmhub[AMDGPU_GFXHUB(0)];

	WREG32_SOC15_OFFSET(GC, 0,
			    mmGCVM_CONTEXT0_PAGE_TABLE_BASE_ADDR_LO32,
			    hub->ctx_addr_distance * vmid,
			    lower_32_bits(page_table_base));
	WREG32_SOC15_OFFSET(GC, 0,
			    mmGCVM_CONTEXT0_PAGE_TABLE_BASE_ADDR_HI32,
			    hub->ctx_addr_distance * vmid,
			    upper_32_bits(page_table_base));
}
```

`page_table_base` 是根页表地址；`vmid` 参与选择对应的上下文寄存器；高、低 32 位分别写入两个寄存器。这说明“GPU 有页表”必然还需要一组硬件状态告诉 MMU 使用哪套页表。

PASID 与 VMID 不是同一个编号。Linux KFD 的一种非固件调度路径会从有限 VMID 槽位中选择空闲项，再记录 PASID→VMID 关系：

**[SOURCE]** [`drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c`](./2.源码/linux/drivers/gpu/drm/amd/amdkfd/kfd_device_queue_manager.c) 第 681～700 行：

```c
for (i = dqm->dev->vm_info.first_vmid_kfd;
		i <= dqm->dev->vm_info.last_vmid_kfd; i++) {
	if (!dqm->vmid_pasid[i]) {
		allocated_vmid = i;
		break;
	}
}

/* 省略没有空闲VMID时的错误处理和调试日志。 */
dqm->vmid_pasid[allocated_vmid] = pdd->pasid;
set_pasid_vmid_mapping(dqm, pdd->pasid, allocated_vmid);
qpd->vmid = allocated_vmid;
```

这段代码只用来证明两点：PASID 是进程地址空间身份，VMID 是有限硬件槽位；二者需要建立映射。不同调度模式和 GPU 代际怎样分配、切换 VMID，留到 AQL Queue 调度阶段。

> **[BOUNDARY]** 页表根寄存器名与编程方式会随 GPU 代际变化；“选择上下文、提供根地址、设置翻译参数、维护 TLB”这四类职责不变。故障寄存器和 GPU Page Fault 留到后续阶段。

### 1.6 GTT、GART 和 GPUVM 的区别

三个名字都包含“GPU 访问内存”，但回答的问题不同：

| 名称  | 它主要回答什么                                                           | 不应该怎样理解                      |
| ----- | ------------------------------------------------------------------------ | ----------------------------------- |
| GTT   | 这块 BO 是否属于 GPU 可访问的 system RAM 内存域                          | 不是某个进程的 GPUVA                |
| GART  | GPU 全局/system-memory aperture 怎样把一段设备地址映射到 system RAM 页面 | 不是所有进程 GPUVA 的统一第二级页表 |
| GPUVM | 某个地址空间中的 GPUVA 分别映射到哪些 VRAM/system RAM 页面               | 不是物理存储类型                    |

**[SOURCE]** Linux [`drivers/gpu/drm/amd/amdgpu/amdgpu_gart.c`](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_gart.c) 第 41～47 行给出 GART 的定义：

```c
/*
 * GART
 * The GART (Graphics Aperture Remapping Table) is an aperture
 * in the GPU's address space. System pages can be mapped into
 * the aperture and look like contiguous pages from the GPU's
 * perspective. A page table maps the pages in the aperture
 * to the actual backing pages in system memory.
 */
```

中文翻译：

```text
GART是GPU地址空间中的一个窗口。
system RAM页面可以映射进这个窗口，
从GPU视角看起来像一段连续页面；
GART页表再把窗口中的页面映射到真实system RAM backing页面。
```

**[SOURCE]** Linux [`drivers/gpu/drm/amd/amdgpu/amdgpu_gmc.h`](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_gmc.h) 第 248～254 行进一步限定这段 aperture：

```c
/* GART aperture start and end in MC address space
 * Driver find a hole in the MC address space
 * to place GART by setting VM_CONTEXT0_PAGE_TABLE_START/END_ADDR
 * registers
 * Under VMID0, logical address inside GART aperture will
 * be translated through gpuvm gart page table to access
 * paged system memory
 */
```

中文翻译：

```text
驱动在GPU内存控制器地址空间中选择一段范围放置GART aperture，
并通过VM_CONTEXT0的页表范围寄存器配置它。
在VMID 0下，落在GART aperture内的逻辑地址
通过GART页表翻译后访问分页system RAM。
```

而第 1.1 节引用的 `amdgpu_vm.c` 已经说明，普通 GPUVM 可以同时存在多套页表并混合映射 VRAM 与 system RAM。

因此不要画成固定的三级翻译：

```text
错误模型：
GPUVA → GTT → GART → GPUVM → 数据
```

更准确的关系是：

```text
存储/放置视角：
GTT BO → backing位于system RAM

全局窗口视角：
GART aperture → 把一段设备全局地址映射到system RAM页面

进程地址空间视角：
GPUVM中的GPUVA
   ├─ PTE → system RAM页面（例如GTT/USERPTR backing）
   └─ PTE → VRAM资源
```

GTT BO 可能同时参与 GART 管理和进程 GPUVM 映射，但这是同一份 system RAM backing 被不同管理关系引用，不表示 GPU 的每次普通访问都依次穿过三个名词。

把第 1 章压缩成一句话：

> GPU 指令从所属 GPUVM 中的 GPUVA 出发；VMID 和根页表寄存器选择翻译上下文；GPU MMU 通过 PTE 得到 system RAM 的 DMA 地址或本地 VRAM 地址；若该 DMA 地址是 IOVA，Host IOMMU 再把它翻译为 Host PA。

## 2. GPU 可访问内存怎样建立、映射和释放

第 1 章假设 PTE 已经存在。本章把时间倒回去，看一块内存怎样从“被申请”变成“GPUVA 可以访问”，又怎样安全退出：

```text
选择VRAM/GTT/USERPTR
        ↓
取得页面或显存资源，建立管理对象
        ↓
可选：建立CPU映射
        ↓
MAP_MEMORY_TO_GPU
        ↓
把BO连接到目标GPUVM，写入GPU PTE
        ↓
等待页表更新并使旧TLB翻译失效
        ↓
使用者持有引用和映射
        ↓
使用结束 → UNMAP → FREE
```

### 2.1 三种基础内存来源

KFD 将最基本的内存来源表示为三种基础类型标志；一次常规分配按用途选择其中一种。

**[SOURCE]** Linux [`include/uapi/linux/kfd_ioctl.h`](./2.源码/linux/include/uapi/linux/kfd_ioctl.h) 第 413～428 行：

```c
/* Allocation flags: memory types */
#define KFD_IOC_ALLOC_MEM_FLAGS_VRAM		(1 << 0)
#define KFD_IOC_ALLOC_MEM_FLAGS_GTT		(1 << 1)
#define KFD_IOC_ALLOC_MEM_FLAGS_USERPTR		(1 << 2)
/* 省略Doorbell和MMIO专用类型。 */

/* Allocation flags: attributes/access options */
#define KFD_IOC_ALLOC_MEM_FLAGS_WRITABLE	(1 << 31)
#define KFD_IOC_ALLOC_MEM_FLAGS_EXECUTABLE	(1 << 30)
#define KFD_IOC_ALLOC_MEM_FLAGS_PUBLIC		(1 << 29)
#define KFD_IOC_ALLOC_MEM_FLAGS_AQL_QUEUE_MEM	(1 << 27)
#define KFD_IOC_ALLOC_MEM_FLAGS_COHERENT	(1 << 26)
#define KFD_IOC_ALLOC_MEM_FLAGS_UNCACHED	(1 << 25)
```

中文翻译：

```text
第一组标志选择内存来源：VRAM、GTT或USERPTR。
第二组标志描述访问属性：能否写、能否执行、是否要求CPU可见、
是否用于AQL Queue，以及缓存/一致性属性。
```

三种来源的核心区别是：

| 类型    | 数据从哪里来                             | CPU 侧最初是否已有地址                     | GPU 访问前还需要什么                     |
| ------- | ---------------------------------------- | ------------------------------------------ | ---------------------------------------- |
| VRAM    | GPU 本地显存资源                         | 不一定；要看 BAR 可见性与是否建立 CPU 映射 | 映射进目标 GPUVM                         |
| GTT     | 驱动为 BO 分配的 system RAM 页面         | 分配后可通过 mmap 建立 CPU VA              | DMA 映射并写入目标 GPUVM                 |
| USERPTR | 用户已经拥有的 CPU VA 和 system RAM 页面 | 是                                         | 登记/跟踪页面、建立 DMA 地址并写入 GPUVM |

GTT 与 USERPTR 最终都可能让 GPU 访问 system RAM，但页面来源相反：

```text
GTT：    先请求GPU内存 → 驱动分配system RAM页面 → 可再映射给CPU
USERPTR：先有CPU VA和页面 → 驱动登记这些现有页面 → 再映射给GPU
```

`PUBLIC`、`COHERENT`、`UNCACHED` 等是属性，不是第四种物理存储。它们会影响 CPU 可见性、缓存方式或实现选择，但不能取代 VRAM/GTT/USERPTR 这个来源问题。

### 2.2 页面或显存资源从哪里来

**GTT：驱动取得 system RAM 页面**

GTT BO 的 backing 由系统页面组成。AMDGPU 通过 TTM 的页面池为尚无用户页面的对象填充 `ttm->pages[]`。

**[SOURCE]** Linux [`drivers/gpu/drm/amd/amdgpu/amdgpu_ttm.c`](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_ttm.c) 第 1216～1251 行：

```c
/*
 * amdgpu_ttm_tt_populate - Map GTT pages visible to the device
 *
 * Map the pages of a ttm_tt object to an address space visible
 * to the underlying device.
 */
static int amdgpu_ttm_tt_populate(struct ttm_device *bdev,
				  struct ttm_tt *ttm,
				  struct ttm_operation_ctx *ctx)
{
	/* 省略局部变量声明。 */
	/* user pages are bound by amdgpu_ttm_tt_pin_userptr() */
	if (gtt->userptr) {
		ttm->sg = kzalloc_obj(struct sg_table);
		if (!ttm->sg)
			return -ENOMEM;
		return 0;
	}

	/* 省略外部导入检查和pool选择。 */
	ret = ttm_pool_alloc(pool, ttm, ctx);
	if (ret)
		return ret;

	for (i = 0; i < ttm->num_pages; ++i)
		ttm->pages[i]->mapping = bdev->dev_mapping;
	return 0;
}
```

中文翻译：这个函数为 GTT 对象准备设备可见的页面；普通路径由 TTM 页面池分配页面，USERPTR 则跳过这一步，因为页面来自用户已有映射。

当前只需从代码中读出：

```text
GTT BO
  → ttm_pool_alloc()
  → 一组struct page
  → 后续建立设备DMA地址和GPU PTE
```

**USERPTR：从 CPU 页表取得现有页面**

USERPTR 不重新创造一份用户数据。驱动从用户 CPU VA 所属的内存映射取得页面，并跟踪 CPU 页表变化。

**[SOURCE]** Linux [`drivers/gpu/drm/amd/amdgpu/amdgpu_ttm.c`](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_ttm.c) 第 737～803 行：

```c
/*
 * get device accessible pages that back user memory
 * and start HMM tracking CPU page table update
 */
r = amdgpu_hmm_range_get_pages(&bo->notifier, start, ttm->num_pages,
			       readonly, NULL, range);

/* 省略当前函数尾部和amdgpu_ttm_tt_set_user_pages()函数声明。 */
for (i = 0; i < ttm->num_pages; ++i)
	ttm->pages[i] =
		range ? hmm_pfn_to_page(range->hmm_range.hmm_pfns[i]) : NULL;
```

中文翻译：驱动取得支撑这段用户内存的设备可访问页面，同时开始跟踪 CPU 页表更新；随后把 HMM 返回的页框信息转换为 `struct page`。

**[SOURCE]** 同一 Linux 文件 [`drivers/gpu/drm/amd/amdgpu/amdgpu_ttm.c`](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_ttm.c) 第 821～835 行再把这些页面组织成散列表并通过 DMA API 映射给设备：

```c
r = sg_alloc_table_from_pages(ttm->sg, ttm->pages, ttm->num_pages, 0,
			      (u64)ttm->num_pages << PAGE_SHIFT,
			      GFP_KERNEL);
/* 省略错误分支。 */
r = dma_map_sgtable(adev->dev, ttm->sg, direction, 0);
/* 省略错误分支。 */
drm_prime_sg_to_dma_addr_array(ttm->sg, gtt->ttm.dma_address,
			       ttm->num_pages);
```

这条链连接了第 1 章：

```text
用户CPU VA
  → CPU页表中的页面
  → struct page
  → DMA地址数组
  → GPU页表PTE
```

**VRAM：取得显存资源区间**

VRAM BO 的数据位于 GPU 本地显存资源中，驱动管理的是显存地址区间，而不是一组普通 host `struct page`。映射进 GPUVM 时，PTE 最终指向本地显存地址；只有 CPU 需要直接访问且该区间位于 BAR 可见范围时，才另外建立 CPU 侧映射。

**pin 与分配不是一回事**

| 动作     | 回答的问题                                     |
| -------- | ---------------------------------------------- |
| 分配     | 数据存储资源从哪里来；谁拥有它                 |
| pin/固定 | 已有页面或 BO 在使用期间能否被换出、迁移或改变 |
| 映射     | 某个 CPU VA 或 GPUVA 怎样到达这份存储          |

USERPTR 尤其容易被说成“GPU 分配了一块 pinned memory”，但准确顺序是：用户先有内存，驱动再登记并稳定/跟踪这些页面，然后建立设备访问关系。pin 不会凭空创建另一份数据。

> **[BOUNDARY]** USERPTR 页面失效、HMM notifier、迁移与 GPU Page Fault 的完整恢复路径留到 SVM/HMM 阶段；本章只学习正常映射建立时需要哪些页面。

### 2.3 分配和映射是两个阶段

KFD UAPI 本身已经把两个阶段拆开。

**[SOURCE]** Linux [`include/uapi/linux/kfd_ioctl.h`](./2.源码/linux/include/uapi/linux/kfd_ioctl.h) 第 430～478 行：

```c
/* Allocate memory for later SVM (shared virtual memory) mapping.
 *
 * @va_addr:     virtual address of the memory to be allocated
 *               all later mappings on all GPUs will use this address
 * @size:        size in bytes
 * @handle:      buffer handle returned to user mode, used to refer to
 *               this allocation for mapping, unmapping and freeing
 * @mmap_offset: for CPU-mapping the allocation by mmapping a render node
 *               for userptrs this is overloaded to specify the CPU address
 * @gpu_id:      device identifier
 * @flags:       memory type and attributes. See KFD_IOC_ALLOC_MEM_FLAGS above
 */
struct kfd_ioctl_alloc_memory_of_gpu_args {
	__u64 va_addr;
	__u64 size;
	__u64 handle;
	__u64 mmap_offset;
	__u32 gpu_id;
	__u32 flags;
};

/* Map memory to one or more GPUs
 *
 * @handle:                memory handle returned by alloc
 * @device_ids_array_ptr:  array of gpu_ids (__u32 per device)
 * @n_devices:             number of devices in the array
 * @n_success:             number of devices mapped successfully
 *
 * @n_success returns information to the caller how many devices from
 * the start of the array have mapped the buffer successfully. It can
 * be passed into a subsequent retry call to skip those devices. For
 * the first call the caller should initialize it to 0.
 *
 * If the ioctl completes with return code 0 (success), n_success ==
 * n_devices.
 */
struct kfd_ioctl_map_memory_to_gpu_args {
	__u64 handle;
	__u64 device_ids_array_ptr;
	__u32 n_devices;
	__u32 n_success;
};
```

中文翻译：

```text
ALLOC创建或登记一块以后可以映射的内存，返回handle；
这个handle供后续MAP、UNMAP和FREE引用。
mmap_offset用于另外建立CPU映射。

MAP使用同一个handle，把该内存映射到一个或多个GPU；
device_ids数组选择目标GPU，n_success记录已经成功映射的设备数，
从而支持失败后的继续重试；完全成功时n_success等于n_devices。
```

四个核心 ioctl 的职责是：

| ioctl                     | 只回答什么                                |
| ------------------------- | ----------------------------------------- |
| `ALLOC_MEMORY_OF_GPU`   | 创建/登记内存与管理对象，返回 KFD handle  |
| `MAP_MEMORY_TO_GPU`     | 把对象连接到指定 GPU 的 GPUVM，准备 PTE   |
| `UNMAP_MEMORY_FROM_GPU` | 删除指定 GPUVM 中的映射                   |
| `FREE_MEMORY_OF_GPU`    | 在无人使用、没有 GPU 映射后释放对象和存储 |

因此：

```text
ALLOC成功
≠ GPU已经能访问

MAP成功
= 对目标GPUVM建立映射并完成必要同步
```

**[SOURCE]** Linux [`drivers/gpu/drm/amd/amdkfd/kfd_chardev.c`](./2.源码/linux/drivers/gpu/drm/amd/amdkfd/kfd_chardev.c) 第 1322～1375 行展示 `MAP_MEMORY_TO_GPU` 的关键顺序：

```c
mem = kfd_process_device_translate_handle(
		pdd, GET_IDR_HANDLE(args->handle));

for (i = args->n_success; i < args->n_devices; i++) {
	/* 省略目标GPU查找和绑定。 */
	err = amdgpu_amdkfd_gpuvm_map_memory_to_gpu(
		peer_pdd->dev->adev, (struct kgd_mem *)mem,
		peer_pdd->drm_priv);
	if (err) {
		/* 省略错误日志。 */
		goto map_memory_to_gpu_failed;
	}
	args->n_success = i+1;
}

err = amdgpu_amdkfd_gpuvm_sync_memory(
	dev->adev, (struct kgd_mem *) mem, true);

/* Flush TLBs after waiting for the page table updates to complete */
for (i = 0; i < args->n_devices; i++) {
	/* 省略peer_pdd查找与空指针检查。 */
	kfd_flush_tlb(peer_pdd);
}
```

中文翻译：先把 KFD handle 查成内核内存对象；再建立 GPUVM 映射；等待页表更新完成；最后使对应 GPU TLB 中的旧翻译失效。

这正好闭合第 1 章的控制面：

```text
handle查找对象
  → BO连接到GPUVM
  → 写GPU PTE
  → 等待PTE更新完成
  → 使旧TLB项失效
```

### 2.4 最小内存对象关系

这一节不背结构体，只先分清三类东西：

| 类别         | 本例中的代表                                            | 它负责什么                                    |
| ------------ | ------------------------------------------------------- | --------------------------------------------- |
| 用户标识     | KFD handle                                              | 让用户态在后续 ioctl 中引用同一块内存         |
| 内存管理对象 | `kgd_mem`、`amdgpu_bo`                              | 保存大小、来源、引用和底层存储等管理状态      |
| 映射关系     | `kfd_mem_attachment`、`amdgpu_bo_va`、`amdgpu_vm` | 表示“这个 BO 映射进这套 GPUVM 的哪个 GPUVA” |

**[SOURCE]** Linux [`drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd.h`](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd.h) 第 62～94 行只保留本章所需字段：

```c
struct kfd_mem_attachment {
	struct list_head list;
	bool is_mapped;
	struct amdgpu_bo_va *bo_va;
	struct amdgpu_device *adev;
	uint64_t va;
	uint64_t pte_flags;
};

struct kgd_mem {
	struct mutex lock;
	struct amdgpu_bo *bo;
	struct list_head attachments;
	uint32_t domain;
	unsigned int mapped_to_gpu_memory;
	uint64_t va;
	uint32_t alloc_flags;
	/* 省略同步、导入和进程归属字段。 */
};
```

逐行只读出这些关系：

- `kgd_mem.bo` 指向 AMDGPU 实际管理的 BO。
- `kgd_mem.va` 是计划映射的 GPUVA 起点。
- `domain` 表示 GTT/VRAM 等内存域。
- `attachments` 保存这块内存连接到各 GPUVM 的关系。
- 每个 attachment 中的 `bo_va` 表示“某个 BO 与某个 GPUVM 的连接”，不是另一份数据。

**[SOURCE]** 创建对象时，[`drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gpuvm.c`](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gpuvm.c) 第 1781～1840 行最终把 `kgd_mem` 指向 `amdgpu_bo`，同时把映射计数初始化为 0：

```c
*mem = kzalloc_obj(struct kgd_mem);
/* 省略初始化和BO创建过程。 */
bo = gem_to_amdgpu_bo(gobj);
bo->kfd_bo = *mem;
(*mem)->bo = bo;
(*mem)->va = va;
(*mem)->domain = domain;
(*mem)->mapped_to_gpu_memory = 0;
```

`mapped_to_gpu_memory = 0` 是最直接的证据：BO 已经创建，不等于它已经映射进某个 GPUVM。这里出现的 GEM 只是 AMDGPU 内部复用的通用对象层；本文不展开其 handle 和生命周期框架。

**[SOURCE]** 真正连接到某套 GPUVM 时，Linux [`drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gpuvm.c`](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gpuvm.c) 第 974～990 行创建或复用 `amdgpu_bo_va`：

```c
bo_va = amdgpu_vm_bo_find(vm, bo[i]);
if (!bo_va)
	bo_va = amdgpu_vm_bo_add(adev, vm, bo[i]);
else
	++bo_va->ref_count;

attachment[i]->bo_va = bo_va;
attachment[i]->va = va;
attachment[i]->pte_flags = get_pte_flags(adev, vm, mem);
attachment[i]->adev = adev;
list_add(&attachment[i]->list, &mem->attachments);
```

把不同箭头标清楚后，最小模型是：

```text
用户态KFD handle
        │ 查表
        ▼
kgd_mem                         ← KFD管理状态
├─ bo ────────────────→ amdgpu_bo
│                         │
│                         └─ 管理真正的页面或VRAM资源
│
└─ attachments
      └─ kfd_mem_attachment
            ├─ va / pte_flags
            └─ bo_va ─────→ “这个BO ↔ 这套amdgpu_vm”的映射关系
                                      │
                                      └─ 最终形成GPU PTE
```

需要记住的不是五个名字，而是三句话：

1. handle 只是用户态查表编号，不是地址。
2. `kgd_mem` 与 `amdgpu_bo` 管理同一份内存，不是两份 16 KiB 数据。
3. `amdgpu_bo_va` 表示 BO 与某套 GPUVM 的映射关系；同一 BO 可以映射到不止一个 GPU。

### 2.5 CPU 映射和 GPU 映射分别怎样建立

一份存储可以同时有 CPU 映射和 GPU 映射，但两条路径各自独立：

```text
CPU侧：
CPU VA → CPU页表/BAR窗口 → 数据

GPU侧：
GPUVA → GPU页表 → 数据
```

KFD 的 ALLOC 参数同时提供 `va_addr` 和 `mmap_offset`，正是因为两种映射不是一回事：

| 内存来源 | CPU 映射                                                  | GPU 映射                             |
| -------- | --------------------------------------------------------- | ------------------------------------ |
| GTT      | 用户态以`mmap_offset` 建立 CPU VA，落到 system RAM 页面 | GPUVA→GPU PTE→DMA 地址→system RAM |
| USERPTR  | CPU VA 原本就存在                                         | 取得现有页面后建立 GPU PTE           |
| VRAM     | 仅当资源 CPU 可见时，经 BAR 建立 CPU VA；否则可能不能直映 | GPUVA→GPU PTE→本地 VRAM 地址       |

把 16 KiB GTT Ring 放进来：

```text
CPU写Ring第0页：
CPU VA C0
  → CPU页表
  → Host PA H0
  → system RAM页面P0

GPU读Ring第0页：
GPUVA G0
  → GPU页表
  → DMA地址D0
  → 可选Host IOMMU
  → 同一个system RAM页面P0
```

CPU VA 与 GPUVA 可以数值不同。即使某些统一地址配置让两者数值相同，它们仍由不同 MMU、不同页表关系解释，不能因为数字相同就认为只建立了一张页表。

### 2.6 引用、映射与最终释放

“用户还拿着 handle”“GPUVM 还有映射”“Queue 正在使用”是三种不同的存活关系。AQL Ring 能说明为什么仅有一个 BO 引用还不够。

Queue 建立时，KFD 会确认 Ring GPUVA 确实覆盖一条完整 BO 映射，然后同时增加 BO 引用与 Queue 对映射的使用计数。

**[SOURCE]** Linux [`drivers/gpu/drm/amd/amdkfd/kfd_queue.c`](./2.源码/linux/drivers/gpu/drm/amd/amdkfd/kfd_queue.c) 第 197～220 行：

```c
mapping = amdgpu_vm_bo_lookup_mapping(vm, user_addr);
if (!mapping)
	goto out_err;

if (user_addr != mapping->start ||
    (size != 0 && user_addr + size - 1 != mapping->last)) {
	pr_debug("expected size 0x%llx not equal to mapping addr 0x%llx size 0x%llx\n",
		 expected_size, mapping->start << AMDGPU_GPU_PAGE_SHIFT,
		 (mapping->last - mapping->start + 1) << AMDGPU_GPU_PAGE_SHIFT);
	goto out_err;
}

*pbo = amdgpu_bo_ref(mapping->bo_va->base.bo);
mapping->bo_va->queue_refcount++;
```

这两个计数保护不同关系：

| 动作                 | 保护什么                                       |
| -------------------- | ---------------------------------------------- |
| `amdgpu_bo_ref()`  | BO 对象和底层资源不能提前销毁                  |
| `queue_refcount++` | 这条 BO→GPUVM 映射不能在 Queue 使用期间被删除 |

**[SOURCE]** 删除 GPUVM 映射前，[`amdgpu_amdkfd_gpuvm.c`](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gpuvm.c) 第 1269～1282 行检查 Queue 使用计数：

```c
struct amdgpu_bo_va *bo_va = entry->bo_va;

if (bo_va->queue_refcount) {
	pr_debug("bo_va->queue_refcount %d\n",
		 bo_va->queue_refcount);
	return -EBUSY;
}

(void)amdgpu_vm_bo_unmap(adev, bo_va, entry->va);
```

只要 Queue 仍可能读取 Ring，`UNMAP_MEMORY_FROM_GPU` 就不能删除这条映射，否则硬件下一次取包会失去有效地址。

即使已经没有 Queue 使用，映射本身仍要先删除，才能最终释放对象。

**[SOURCE]** Linux [`drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gpuvm.c`](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gpuvm.c) 第 1915～1927 行：

```c
mutex_lock(&mem->lock);
mapped_to_gpu_memory = mem->mapped_to_gpu_memory;
mutex_unlock(&mem->lock);

if (mapped_to_gpu_memory > 0) {
	pr_debug("BO VA 0x%llx size 0x%lx is still mapped.\n",
		 mem->va, bo_size);
	return -EBUSY;
}
```

这里的两个 `-EBUSY` 分别表示：

```text
Queue仍使用映射
  → 不能UNMAP

内存仍映射在某个GPUVM
  → 不能FREE
```

安全释放顺序是：

```text
停止使用这块内存
  → Queue放弃映射使用计数和BO引用
  → UNMAP_MEMORY_FROM_GPU删除GPUVM映射
  → 等待页表更新并处理TLB
  → FREE_MEMORY_OF_GPU删除handle、对象和底层资源
```

### 2.7 AQL Ring 案例

ROCr 的 Ring 既可能来自 system allocator，也可能在条件允许时来自 device memory。本文继续使用 system RAM 中的 16 KiB Ring，只为把生命周期串起来。

**[SOURCE]** ROCr [`runtime/hsa-runtime/core/runtime/amd_aql_queue.cpp`](./2.源码/rocr-runtime/runtime/hsa-runtime/core/runtime/amd_aql_queue.cpp) 第 518～535 行：

```cpp
void AqlQueue::AllocRegisteredRingBuffer(uint32_t queue_size_pkts) {
  ring_buf_alloc_bytes_ =
      queue_size_pkts * sizeof(core::AqlPacket);
  assert(IsMultipleOf(ring_buf_alloc_bytes_, 4096) &&
         "Ring buffer sizes must be 4KiB aligned.");

  if (IsDeviceMemRingBuf()) {
    /* 省略Large BAR检查。 */
    ring_buf_ = agent_->coarsegrain_allocator()(
        ring_buf_alloc_bytes_,
        core::MemoryRegion::AllocateExecutable |
        core::MemoryRegion::AllocateUncached);
  } else {
    ring_buf_ = agent_->system_allocator()(
        ring_buf_alloc_bytes_, 0x1000,
        core::MemoryRegion::AllocateExecutable);
  }
}
```

中文翻译：ROCr 先按 Packet 数量计算 Ring 字节数并保证 4 KiB 对齐；根据配置选择设备内存分配器或系统内存分配器。

把本章应用到 system RAM Ring：

```text
1. system allocator取得16 KiB
   → 4个system RAM页面

2. KFD ALLOC
   → KFD handle
   → kgd_mem
   → amdgpu_bo

3. KFD MAP
   → amdgpu_bo_va
   → 目标GPUVM中的4个PTE
   → TLB维护

4. Queue使用Ring
   → KFD持有BO引用
   → queue_refcount保护GPUVM映射

5. Queue停止使用
   → 释放Queue引用
   → UNMAP
   → FREE
```

本案例只要证明一条内存规律：

> GPU 硬件可能继续访问某个 GPUVA 时，底层 BO 和 GPUVM 映射都必须继续存在；只有停止使用以后，才能按“解除映射→释放对象”的顺序回收。

> **[BOUNDARY]** Ring、读写指针怎样传入建队 ioctl，MQD/HQD 怎样保存这些地址，以及硬件怎样取包，属于后续 AQL Queue/Dispatch 文档。本章不继续沿 Queue 调度路径展开。

## 3. CPU 和 GPU 怎样看见彼此的写入

第 1～2 章解决了“地址怎样到达数据”。这仍不足以保证另一个处理器立刻看到最新内容，因为 CPU、GPU 和互连之间还可能存在缓存、写缓冲和乱序观察。

### 3.1 “地址可访问”不等于“数据已经可见”

两个问题必须分开：

| 问题                            | 由什么机制解决                                       |
| ------------------------------- | ---------------------------------------------------- |
| GPUVA 能否找到正确页面          | GPUVM、PTE、TLB、必要时的 Host IOMMU                 |
| GPU 读到的是不是 CPU 刚写的新值 | 缓存属性、一致性机制、release/acquire 与 fence scope |

假设 Ring 的映射完全正确：

```text
GPUVA → 正确PTE → 正确system RAM页面
```

仍然可能发生：

```text
CPU已经执行“写Packet字段”
        ↓
部分写入仍在CPU缓存或写缓冲中
        ↓
GPU先收到Doorbell并读取Ring
        ↓
GPU看到旧字段或半写入Packet
```

所以“页表正确”只保证访问目标正确；“数据可见”还要求发布和观察顺序正确。

### 3.2 HSA 内存类型：fine-grained 与 coarse-grained

HSA 用 fine-grained 和 coarse-grained 描述不同的共享与所有权语义。

**[SPEC]** ROCr 的 HSA 头文件 [`runtime/hsa-runtime/inc/hsa.h`](./2.源码/rocr-runtime/runtime/hsa-runtime/inc/hsa.h) 第 3251～3262 行：

```text
Updates to memory in this region are immediately visible to all the
agents under the terms of the HSA memory model.

Updates to memory in this region can be performed by a single agent at
a time. If a different agent in the system is allowed to access the
region, the application must explicitely invoke hsa_memory_assign_agent
in order to transfer ownership to that agent for a particular buffer.
```

中文翻译：

```text
Fine-grained区域：
在HSA内存模型规定的条件下，对该区域的更新对所有相关Agent可见。

Coarse-grained区域：
同一时刻由一个Agent更新；如果要允许另一个Agent访问，
应用必须显式转移特定缓冲区的所有权。
```

可以先这样比较：

| 类型           | 共享方式                             | 当前阶段的理解                                      |
| -------------- | ------------------------------------ | --------------------------------------------------- |
| fine-grained   | 多个 Agent 可按 HSA 内存模型共享数据 | 适合 CPU/GPU 细粒度协作，但仍需正确的原子操作与同步 |
| coarse-grained | 以单一 Agent 使用和所有权转移为主    | 适合阶段性由 CPU 或 GPU 独占更新                    |

“immediately visible”不能读成“程序不需要同步”。规范已经加了限定：必须在 HSA 内存模型的规则下。若 CPU 和 GPU 对同一位置存在数据竞争，或者缺少 release/acquire，fine-grained 也不会自动修复程序顺序。

### 3.3 AMD 具体缓存属性：coherent 与 uncached

KFD 的 `COHERENT`、`UNCACHED` 是更低层的分配/映射属性。

**[SOURCE]** Linux [`include/uapi/linux/kfd_ioctl.h`](./2.源码/linux/include/uapi/linux/kfd_ioctl.h) 第 424～427 行定义属性位；[`drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gpuvm.c`](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gpuvm.c) 第 1775～1779 行把它们传入 AMDGPU BO 创建属性：

```c
#define KFD_IOC_ALLOC_MEM_FLAGS_AQL_QUEUE_MEM	(1 << 27)
#define KFD_IOC_ALLOC_MEM_FLAGS_COHERENT	(1 << 26)
#define KFD_IOC_ALLOC_MEM_FLAGS_UNCACHED	(1 << 25)

/* 省略其他属性转换。 */
if (flags & KFD_IOC_ALLOC_MEM_FLAGS_COHERENT)
	alloc_flags |= AMDGPU_GEM_CREATE_COHERENT;
if (flags & KFD_IOC_ALLOC_MEM_FLAGS_UNCACHED)
	alloc_flags |= AMDGPU_GEM_CREATE_UNCACHED;
```

这里应当分成两层理解：

| 层次            | 名词                          | 回答的问题                           |
| --------------- | ----------------------------- | ------------------------------------ |
| HSA 编程模型    | fine-grained / coarse-grained | Agent 怎样共享、同步或转移内存所有权 |
| AMDGPU 实现属性 | coherent / uncached           | BO 和映射采用什么一致性、缓存策略    |

它们有关联，但不是同义词：

```text
fine-grained ≠ coherent这个flag
coarse-grained ≠ uncached
uncached也不等于“不需要release/acquire”
```

具体内存池怎样组合这些属性取决于 GPU、平台和运行时策略。当前阶段只建立概念边界，不把 HSA 语义机械翻译成某一个 PTE 位。

### 3.4 release、acquire 与 fence scope

release/acquire 用来建立生产者与消费者之间的先后关系。

```text
生产者：
先写数据
  → release发布“数据已经准备好”

消费者：
acquire观察到发布事件
  → 再读取数据
```

它们有两个方向：

| 方向     | 生产者                        | 消费者             | 要保证什么                                |
| -------- | ----------------------------- | ------------------ | ----------------------------------------- |
| CPU→GPU | CPU 写输入、Kernarg 或 Packet | GPU 读取并执行     | GPU 看到发布事件后，也能看到此前 CPU 写入 |
| GPU→CPU | GPU 写结果                    | CPU 等待完成后读取 | CPU 看到完成事件后，也能看到此前 GPU 写入 |

HSA Packet header 还带有 acquire/release fence scope，用来描述栅栏覆盖的 Agent 范围。

**[SPEC]** [`runtime/hsa-runtime/inc/hsa.h`](./2.源码/rocr-runtime/runtime/hsa-runtime/inc/hsa.h) 第 2886～2906 行：

```text
Acquire fence scope. The value of this sub-field determines the scope and
type of the memory fence operation applied before the packet enters the
active phase.

Release fence scope. The value of this sub-field determines the scope and
type of the memory fence operation applied after kernel completion but
before the packet is completed.
```

中文翻译：

```text
Acquire fence scope决定Packet进入活动阶段前，
执行哪种类型、覆盖多大范围的内存栅栏。

Release fence scope决定Kernel完成后、Packet被标记完成前，
执行哪种类型、覆盖多大范围的内存栅栏。
```

因此，fence scope 不是“要不要使用页表”，也不是“清不清 TLB”；它规定一次内存同步要影响哪些观察者。

### 3.5 普通内存与 MMIO 顺序

AQL Ring 位于普通可共享内存中，Doorbell 则是 MMIO 通知端点。二者虽然都可由 CPU store 写入，但语义不同：

| 写入目标          | 保存什么        | 写入目的           |
| ----------------- | --------------- | ------------------ |
| 普通内存中的 Ring | Packet 数据     | 让 GPU 以后读取    |
| Doorbell MMIO     | 队列进度/通知值 | 触发 GPU 检查 Ring |

所需顺序是：

```text
先写普通内存中的数据
  → 执行必要的release/fence
  → 最后写Doorbell MMIO
```

**[SOURCE]** ROCr [`runtime/hsa-runtime/core/runtime/amd_aql_queue.cpp`](./2.源码/rocr-runtime/runtime/hsa-runtime/core/runtime/amd_aql_queue.cpp) 第 468～482 行展示了当前 x86 路径：

```cpp
void AqlQueue::StoreRelaxed(hsa_signal_value_t value) {
  if (core::Runtime::runtime_singleton_->flag().enable_dtif()) {
    HSAKMT_CALL(hsaKmtQueueRingDoorbell(queue_id_));
  } else {
    // Hardware doorbell supports AQL semantics.
    _mm_sfence();
    *(signal_.hardware_doorbell_ptr) = uint64_t(value);
    /* signal_ is allocated as uncached so we do not need read-back to flush WC */
  }
}

void AqlQueue::StoreRelease(hsa_signal_value_t value) {
  std::atomic_thread_fence(std::memory_order_release);
  StoreRelaxed(value);
}
```

中文翻译：

```text
StoreRelease先建立release顺序，再进入实际Doorbell写入；
当前x86实现还在硬件Doorbell store前执行sfence。
Doorbell映射为uncached，因此这里不需要通过回读刷新写合并。
```

`hardware_doorbell_ptr` 指向 MMIO 窗口，不是 Ring 数据。不同 CPU 架构会使用不同屏障指令，但“先发布普通内存，再通知设备”的跨平台要求不变。

### 3.6 AQL 发布案例

现在只观察 Packet 发布顺序，不展开 Packet 字段和硬件取包过程：

```text
CPU取得Ring槽位
  → 保持header无效
  → 填写Packet其他字段
  → release写入最终有效header
  → 写Doorbell
  → GPU才开始把该槽位当作有效Packet
```

有效 header 必须最后发布。否则 GPU 可能先看到“这是有效 Packet”，再读到尚未写完的其他字段。

**[SOURCE]** ROCm CLR [`rocclr/device/rocm/rocvirtual.cpp`](./2.源码/rocm-clr/rocclr/device/rocm/rocvirtual.cpp) 第 1074～1079、1254～1275 行只保留三个关键动作：

```cpp
static inline void packet_store_release(
    uint32_t* packet, uint16_t header, uint16_t rest) {
#if IS_WINDOWS
  std::atomic_ref<uint32_t> atomic_header(*packet);
  atomic_header.store(header | (rest << 16),
                      std::memory_order_release);
#else
  __atomic_store_n(packet, header | (rest << 16), __ATOMIC_RELEASE);
#endif
}

AqlPacket* aql_loc =
    &((AqlPacket*)(gpu_queue_->base_address))[index & queueMask];
*aql_loc = *packet;
if (header != 0) {
  packet_store_release(
      reinterpret_cast<uint32_t*>(aql_loc), header, rest);
}

/* 省略日志和与当前顺序无关的条件说明。 */
{
  Hsa::signal_store_screlease(
      gpu_queue_->doorbell_signal, index);
}
```

逐行理解：

1. `*aql_loc = *packet` 先把 Packet 内容复制到 Ring 槽位。
2. `packet_store_release()` 再以 release 语义发布最终有效 header。
3. 最后才写 Doorbell，通知 GPU 检查已经发布的槽位。

这段代码只用于证明普通内存与通知的顺序：

```text
Packet数据
  → 有效header
  → Doorbell
```

它没有说明 MQD/HQD 怎样配置、哪个硬件模块读取 Packet，也没有展开 Kernel Dispatch；这些属于后续 AQL 路径。

### 3.7 GPU 完成后的结果可见性

CPU→GPU 发布完整 Packet 只覆盖提交方向。Kernel 写完结果后，还需要建立 GPU→CPU 的发布关系：

```text
Kernel写结果
  → Packet release fence
  → 更新Completion Signal
  → CPU以acquire语义观察Signal
  → CPU读取结果
```

为什么不能只看到 Signal 数值变化就直接读取数据？因为“完成通知”必须和此前 GPU 写结果建立 release/acquire 关系，才能成为可靠的可见性边界。

**[SPEC]** ROCr [`runtime/hsa-runtime/inc/hsa.h`](./2.源码/rocr-runtime/runtime/hsa-runtime/inc/hsa.h) 第 2900～2906 行已经说明，Packet 的 release fence 发生在 Kernel 完成后、Packet 被标记完成前。CPU 侧的 acquire 则体现在 Signal 等待接口中；同一文件第 2023～2067 行写道：

```text
When the wait operation internally loads the value of the passed signal, it
uses the memory order indicated in the function name.

hsa_signal_value_t HSA_API hsa_signal_wait_scacquire(
    hsa_signal_t signal,
    hsa_signal_condition_t condition,
    hsa_signal_value_t compare_value,
    uint64_t timeout_hint,
    hsa_wait_state_t wait_state_hint);
```

中文翻译：

```text
等待操作在内部读取Signal值时，
使用函数名称所指明的内存顺序。

hsa_signal_wait_scacquire()读取Signal时采用SC acquire语义。
```

这里函数名中的 `sc` 表示 sequentially consistent（顺序一致），不是 system scope；同步作用范围由前面单独介绍的 fence scope 决定。

最终可以用两条对称关系记住本章：

```text
CPU → GPU：
CPU写数据
  → release发布
  → GPU acquire
  → GPU读取

GPU → CPU：
GPU写结果
  → release fence
  → Completion Signal
  → CPU acquire
  → CPU读取
```

常见错误可以按“哪一层关系被破坏”分类：

| 错误                           | 可能结果              | 被破坏的层次         |
| ------------------------------ | --------------------- | -------------------- |
| GPUVA 没有有效 PTE             | GPU VM Fault          | 地址翻译             |
| Queue 使用期间删除 Ring 映射   | 后续访问失去目标      | 映射生命周期         |
| 有效 header 发布过早           | GPU 读取半写入 Packet | CPU→GPU 发布顺序    |
| Doorbell 早于普通内存发布      | GPU 过早开始检查 Ring | 普通内存与 MMIO 顺序 |
| CPU 看到完成后没有正确 acquire | 不能据此保证结果可见  | GPU→CPU 发布顺序    |

把全文压缩成最终记忆模型：

```text
数据位置：
system RAM 或 VRAM

地址路径：
CPU VA → CPU页表/BAR → 数据
GPUVA → GPU页表 → DMA地址或VRAM地址 → 数据

建立与释放：
ALLOC → 可选CPU映射 → MAP → 使用者持有引用
      → 停止使用 → UNMAP → FREE

数据可见性：
生产者写数据 → release → 通知/完成 → acquire → 消费者读数据
```
