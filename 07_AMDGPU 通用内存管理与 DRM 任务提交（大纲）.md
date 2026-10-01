# AMDGPU 通用内存管理与 DRM 任务提交（第七章大纲）

| 缩写 | 英文全称 | 中文含义 |
| --- | --- | --- |
| AMDGPU | AMD GPU Linux Kernel Driver | AMD GPU Linux 内核驱动 |
| API | Application Programming Interface | 应用程序编程接口 |
| AQL | Architected Queuing Language | HSA 队列包格式与提交协议 |
| BAR | Base Address Register | PCIe 基址寄存器及其设备地址窗口 |
| BO | Buffer Object | 驱动管理的缓冲对象 |
| BSP | Board Support Package | 板级支持包 |
| CDNA | Compute DNA | AMD 数据中心计算 GPU 架构系列 |
| CLR | Compute Language Runtime | AMD 计算语言运行时 |
| CP | Command Processor | GPU 命令处理器 |
| CPU | Central Processing Unit | 中央处理器 |
| DMA | Direct Memory Access | 直接内存访问 |
| DMA-BUF | Direct Memory Access Buffer | Linux 缓冲区共享机制 |
| DRM | Direct Rendering Manager | Linux 直接渲染管理框架 |
| fd | File Descriptor | 文件描述符；在当前进程的文件表中定位打开文件 |
| GEM | Graphics Execution Manager | DRM 缓冲对象管理框架 |
| GFP | Get Free Pages | Linux 页面分配标志 |
| GPU | Graphics Processing Unit | 图形处理器 |
| GPUVA | GPU Virtual Address | GPU 虚拟地址 |
| GPUVM | GPU Virtual Memory | GPU 虚拟地址空间及其页表管理 |
| GTT | Graphics Translation Table | AMDGPU 中主要表示 GPU 可访问的系统内存域 |
| HBM | High Bandwidth Memory | 本模型中的设备本地高带宽内存 |
| HSA | Heterogeneous System Architecture | 异构系统架构 |
| IB | Indirect Buffer | 普通 GPU 命令提交使用的间接命令缓冲区 |
| ioctl | Input/Output Control | 用户态向内核驱动发出控制请求的接口 |
| IOMMU | Input/Output Memory Management Unit | 主机侧的设备地址翻译与访问保护单元 |
| KFD | Kernel Fusion Driver | AMD GPU 计算内核驱动组件 |
| LRU | Least Recently Used | 最近最少使用；用于资源回收选择 |
| MEC | Micro Engine Compute | AMD GPU 计算命令处理引擎 |
| MMU | Memory Management Unit | 内存管理单元 |
| PCIe | Peripheral Component Interconnect Express | Host 与独立 GPU 之间的高速互连 |
| PDE | Page Directory Entry | 页目录项 |
| PFN | Page Frame Number | 页框编号 |
| PTE | Page Table Entry | 页表项 |
| RAM | Random-Access Memory | 随机访问存储器；system RAM 指主机内存 |
| ROCr | ROCm Runtime | ROCm 的 HSA 用户态运行时 |
| SDMA | System Direct Memory Access | AMD GPU 的专用搬运引擎 |
| SG | Scatter-Gather | 分散页面的聚集描述 |
| SVM | Shared Virtual Memory | 共享虚拟内存 |
| syncobj | Synchronization Object | DRM 同步对象，保存 Fence 的引用 |
| TLB | Translation Lookaside Buffer | 地址翻译缓存 |
| TTM | Translation Table Maps | DRM 缓冲区放置、驱逐与迁移管理框架 |
| VM | Virtual Memory | 虚拟内存 |
| VMID | Virtual Memory ID | GPU 当前硬件地址空间上下文的编号 |
| VMA | Virtual Memory Area | Linux 虚拟内存区域 |
| VRAM | Video Random-Access Memory | 驱动中的设备本地显存域 |

## 7.0 学习定位与贯穿任务

00～05 已经建立软件栈、地址与存储、AQL 提交、实际访存和缺页恢复的关系，06 把这些内容放回一项应用的初始化、执行、完成与退出。第七章从这条已走通的 AQL 主线进入公共驱动能力，沿一项普通 DRM 提交继续解释内部实现。全文按“建立对象与地址 → 提交任务 → 依赖与完成 → 迁移 → 更新与错误处理”的顺序展开。

**[DESIGN]** 沿用外部 Host CPU + MI300X / CDNA 3 独立 GPU，通过 PCIe 连接 system RAM 与 HBM；Host IOMMU 开启翻译。P、R 分别打开同一块 GPU 的 DRM render 设备。正常案例先把 X、Y 都放在 GTT/system RAM，取支持 CPU 映射、允许当前设备访问且映射保持有效的 BO；Y 的允许域包含 GTT 与 VRAM，未被 pin，为后面的迁移保留合法目标。P 的 CPU 线程填写 X、完成写入交接后，通过 DRM 请求同一 GPU 的 SDMA 把 X 复制到 Y；R 取得共享 Y，以 CPU 读取并逐项校验 `Y[i] = X[i]`。本轮设备和 Host 使用结束前，不重写 X/Y、不复用完成对象。实验时核对实际设备、内存属性与接口支持。

P 的 GPUVA 映射和设备 DMA 地址在提交前准备；CPU 的访问映射与访问交接在 §7.1、§7.3 说明。主线先验证单进程拷贝，再加入 R。§7.4 单独改变 Y 的位置条件，推演 GTT → HBM/VRAM 的迁移；迁移后根据当前存储和映射重新安排 CPU 读取，不沿用正常案例的直接读取条件。

```text
P：建立 X/Y 的 BO、CPU 映射和 GPUVA，填写并交付 X
    → 准备 SDMA 拷贝命令及依赖，提交 job，关联保存完成 Fence 的 syncobj
    → 把 Y 的 DMA-BUF 和 syncobj 的文件引用交给 R
设备：job 依赖满足，驱动向选定硬件 Ring 写入启动 IB 的命令
    → SDMA 复制 X → Y，完成 Fence 向等待者报告本轮结束
R：导入共享对象与完成对象，建立 Y 的 CPU 映射
    → 等待本轮完成，取得 CPU 读取条件，校验 Y 并结束读取
    → 各使用者结束后释放；位置迁移另从 §7.4 的条件重新推演
```

正常复制、跨进程读取、位置迁移和错误处理分别有明确起点。正文的总图、对象图和时序图使用同一组 X/Y 对象，不为每个子机制另换案例。syncobj 保存本轮完成 Fence 的引用，使 P、R 可以等待同一项工作；其导出、导入和等待到 §7.3 展开。

本章必须始终保持两条提交路径的边界：

```text
AQL：用户态发布 AQL Packet → Doorbell → CP/MEC
普通 DRM：提交请求 → job / scheduler → IB → 硬件 Ring
```

两条路径对 BO、GPUVM、页表更新与同步能力的使用在对应小节接起来。Runtime 拷贝使用什么引擎，先回查 [02 §2.5.3](<./02_GPU 内存管理基础.md#253-cpusdma-与计算-kernel-的选择>)；本章的 DRM 例子明确从 DRM 提交接口进入。

源码使用[仓库固定基线](./2.源码/README.md)：Linux `248951ddc14de84de3910f9b13f51491a8cd91df`、ROCr `ba56a24c6132c5d195686ae4adf969ca1222fbba`、CLR `81277d69e3352e7144ced2ee9601484f9b48d950`。下面列出的源码是正文展开入口；提交与同步关系的具体索引已按固定基线核对，正文展开时再核对其余实现细节。

## 7.1 DRM 文件、BO、地址映射与跨进程共享

从 P 准备 X/Y 开始，讲清用户态拿到的 handle 怎样找到内核对象，以及这份存储怎样分别被 CPU 和 GPU 访问。接上 [06 §2.2 的文件与 GPUVM 关联](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放.md#22-设备文件mmkfd-上下文与-gpuvm-的关联>)，把本章实际使用的 DRM 文件关系展开。

- 先解释 DRM 文件上下文、handle 表和 GEM 对象的查找关系，再连接 `drm_gem_object`、`ttm_buffer_object` 与 `amdgpu_bo`。区分独立打开设备、共享同一文件引用和进程地址空间，不把“每个进程”简单等同于“一张 handle 表”。
- 沿 CPU 映射说明 mmap offset、VMA 和缺页回调；在这里按实际存储类型回查 `remap_pfn_range()`、`vmf_insert_page()`、`vmf_insert_pfn()` 的适用条件，不把三者画成本例必经的调用链。沿 GPU 映射说明 BO、GPUVA、GPUVM 页表与映射更新条件。先走 system RAM 主线，BAR 可见 HBM 的访问条件留作 §7.4 位置变体的回接。
- P 通过 X 的 DMA-BUF CPU 映射准备输入，写入前后按接口执行 `DMA_BUF_IOCTL_SYNC`：先用 `DMA_BUF_SYNC_START | DMA_BUF_SYNC_WRITE` 开始写入，写完后用 `DMA_BUF_SYNC_END | DMA_BUF_SYNC_WRITE` 结束访问，再把 X 交给 SDMA。后续共享 Y 的读取等待与 CPU 访问协议在 §7.3 展开。
- 加入进程 R：P 导出 Y 的 DMA-BUF 文件引用，R 收到后保留自己的 fd，并导入取得自己 DRM 文件中的 handle。沿 DMA-BUF 建立 R 的 CPU 映射，解释对象身份与两个进程 CPU 指针的关系。若另行选择 R 用 GPU 消费 Y，再在 R 自己的 GPUVM 中建立 GPUVA，用两份不同 GPUVA 指向同一 backing；CPU 校验主线无需这一步。
- 沿 P 关闭 handle、R 继续使用、R 删除映射与释放引用的顺序，说明谁仍然持有对象，以及哪次引用归还才允许最终销毁。共享导入与数据生产完成的等待在 §7.3 连接。
- 按需对照 `kgd_mem->attachments`：同一 backing 的多个映射关系，与为跨设备导入建立辅助管理对象的区别。只解释当前对象关系所需的分支，不另开多 GPU 学习阶段。

本节结束时，应能画出“P/R 各自的文件、handle、CPU 映射 → 共享 BO/backing”以及“P 的 GPUVM → X/Y”的关系，并解释删除一个 handle 后仍可能存在的使用者。对象存活与最后使用者的判断回接 [06 §2.8](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放.md#28-引用映射与任务完成共同约束资源寿命>)。

可选回查：需要定位 Host 元数据跨线程分配或释放时，再说明 `malloc()` 的 arena、线程缓存和元数据锁，区分分配线程记录与 MMU 地址空间归属。该部分只服务于当前对象问题，不作为走通 DRM 拷贝的前提。

源码入口：[drm_file.h](./2.源码/linux/include/drm/drm_file.h)、[drm_gem.c](./2.源码/linux/drivers/gpu/drm/drm_gem.c)、[drm_prime.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/drm_prime.c)、[amdgpu_object.h](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_object.h)、[amdgpu_gem.c](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_gem.c)、[amdgpu_dma_buf.c](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_dma_buf.c)。

## 7.2 一次普通 DRM 提交：从拷贝请求到硬件 Ring

X/Y 已有合法映射，X 的 CPU 写入与交接已经结束，P 接下来要求 SDMA 复制数据。本节沿这一项请求解释提交参数、BO 列表、GPUVM 依赖和硬件执行。对照 [06 §3.3 的用户态 AQL 发布](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放.md#33-从预留槽位到有效发布再到设备推进>)与 [§3.4 的 KFD Queue 驻留](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放.md#34-kfd-和设备固件使用户-queue-获得驻留条件>)，本节从 DRM 提交请求进入另一条实现路径。

```text
P 的 render 文件 + DRM context：找到本次提交所属的执行管理对象
    → 请求的 SDMA 引擎与 Ring 选择 → 对应调度 entity
    → 建立 job，准备 BO、GPUVM 更新依赖和提交依赖
    → scheduler 等待条件满足；准备 job 所需 VMID
    → 驱动在选定硬件 Ring 发出所需页表配置、同步与启动 IB 的命令
    → SDMA 读取 IB，按 P 的 GPUVA 复制 X → Y
```

- 先说明用户态命令缓冲保存什么，以及驱动接收的提交请求引用了哪些 BO 和地址；提交阶段分别完成哪些查找、资源准备和依赖处理。
- 先连接 render 文件中的 DRM context、调度 entity 和本例 SDMA 目标。解释请求中的 context 标识及引擎/Ring 选择怎样找到调度对象；entity 保存提交的调度关系，GPUVM 提供地址翻译，VMID 承载当前硬件翻译上下文。沿本例说明各自的输入和后续使用者。
- 沿 `amdgpu_cs_ioctl()` 进入 `amdgpu_job` / `drm_sched_job`，解释软件调度等待的条件与真正提交给硬件的时机。页表更新完成依赖、先前 BO 使用和显式提交依赖在实际收集处接入；相关 Fence 到 §7.3 展开。
- 跟踪 job 准备阶段取得 VMID，再经 `amdgpu_job_run()`、`amdgpu_ib_schedule()`、GPUVM flush、`amdgpu_ring_emit_ib()` 和 Ring 提交。按当前状态说明页表基址、旧翻译处理与必要同步怎样安排在 IB 执行前；用“复制 X 到 Y”区分 IB 的设备命令地址与 X/Y 的数据地址，不把 VMID 固定为每个 context 永久独占的编号。
- 回看 AQL：分别画出应用的一次工作在哪里被表示为 Packet 或 job/IB，说明 KFD 用户 Queue 与普通 DRM scheduler 的关系。

本节结束时，应能区分“ioctl 已返回、job 已排队、依赖已满足、硬件已执行、数据已可使用”，并指出各状态下一步由谁推进。

> **[SOURCE] 提交对象与硬件执行的源码索引**，Linux `248951ddc14d`：
>
> - [`amdgpu_cs.c`](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_cs.c) 第 45～93 行按 render 文件与 context 标识取得 context，再按引擎、实例与 Ring 取得 entity；
> - [`amdgpu_job.c`](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_job.c) 第 412～418 行在 job 准备阶段取得所需 VMID，第 428～455 行连接实际 IB 提交；
> - [`amdgpu_ib.c`](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_ib.c) 第 184～225 行检查 VMID，并在 IB 命令序列前安排 VM flush 与相应同步条件。

正文继续展开的源码入口：[amdgpu_ctx.c](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_ctx.c)、[amdgpu_ring.c](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_ring.c)、[amdgpu_vm.c](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c)。

## 7.3 dma_fence、dma_resv 与依赖和完成传播

P 已提交写 Y 的任务，R 希望读取 Y。围绕这次生产与消费，先说明一项 Fence 表示哪项工作，再解释 BO 怎样记录仍需协调的异步使用。

**[DESIGN]** 本例选二元 syncobj 表示这一轮复制的完成，不复用它表示另一轮任务。P 在提交中指定输出 syncobj；提交成功、已关联本次完成 Fence 后，导出 syncobj 文件引用。P 通过进程间 fd 传递把该引用与 Y 的 DMA-BUF 引用交给 R，R 在自己的 DRM 文件中导入 syncobj，再等待它。两个引用分别找到本轮完成条件和 Y 的存储，传递某个 fd 的整数值无法替 R 建立这两份引用。

```text
P 的本轮复制
    ├─ Y 的存储 → DMA-BUF fd → 传递给 R
    └─ job 完成 Fence → 输出 syncobj → syncobj fd → 传递给 R
R：导入 syncobj → 等待本轮完成，同时保留 Y 的有效 CPU 映射
    → DMA_BUF_IOCTL_SYNC 开始 CPU 读访问 → 校验全部 Y
    → DMA_BUF_IOCTL_SYNC 结束 CPU 读访问 → 归还本轮使用与引用
```

- 用硬件 Fence 与 scheduler finished Fence 追踪同一 job 的完成，区分调度时点、硬件结束、错误状态和等待者返回。
- 展开 `dma_resv` 保存的 Fence 及用途，说明新的读写任务怎样收集既有依赖，完成后又把哪个 Fence 交给后续使用者。锁保护的是软件状态，异步设备工作的结束由 Fence 等完成条件表示。
- 沿 `AMDGPU_CHUNK_ID_SYNCOBJ_OUT` 说明 job 的完成 Fence 怎样进入 P 的输出 syncobj。P 用 `DRM_IOCTL_SYNCOBJ_HANDLE_TO_FD` 导出整个 syncobj，R 用 `DRM_IOCTL_SYNCOBJ_FD_TO_HANDLE` 导入；本例两个接口的 flags 均为 0，R 再用 `DRM_IOCTL_SYNCOBJ_WAIT` 等待这一轮。两进程保留自己的 handle 和文件引用，所有使用者结束前不重置或销毁完成对象。时间线同步只在后续实际需要多轮并发时回查。
- 回到共享 Y，分别说明导入对象、建立地址和等待生产完成；核对隐式依赖与显式同步各自成立的条件。此处既要找到本轮 Fence，也要保留 R 实际访问的存储与映射，不能仅凭共享对象已经导入就开始读取。
- R 的等待结束后，先核对等待结果与本次错误状态，再以 `DMA_BUF_SYNC_START | DMA_BUF_SYNC_READ` 开始 CPU 访问，读取并逐项校验 Y，最后以 `DMA_BUF_SYNC_END | DMA_BUF_SYNC_READ` 结束访问。按固定 AMDGPU 导出实现说明 CPU 访问准备怎样处理存储位置与访问条件；Fence 的完成状态、CPU 缓存与映射条件、内容正确性分别检查。设备间依赖所需 pipeline 同步在相应提交处解释，AQL 的 SYSTEM release/acquire 配置不直接套用到这条 DRM 路径。
- 沿硬件完成序号、完成中断、`dma_fence_signal()`、scheduler 回调和等待唤醒追踪结果；补充回调注册、并发完成、取消和错误传播的生命周期。
- 结合一次等待说明完成通知、等待超时和 Linux 用户信号中断的区别，并检查完成中断缺失时实现提供的 fallback 处理。

本节结束时，应能沿“谁生产 Y → 谁保存依赖 → 谁确认完成 → 谁取得 CPU 访问条件 → 谁校验 Y”讲通一次交接，并回接 [06 §4.3 的完成、可见与数值正确](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放.md#43-分别确认完成可见与数值正确>)及 03 的 Signal 完成路径。

> **[SOURCE] 共享结果与 CPU 读取的源码索引**，Linux `248951ddc14d`：
>
> - [`amdgpu_cs.c`](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_cs.c) 第 1257～1270 行把提交的完成 Fence 交给输出 syncobj；
> - [`drm_syncobj.c`](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/gpu/drm/drm_syncobj.c#L151-L179) 第 151～179 行说明整个 syncobj 与当前 Fence 两种导出形式，第 856～919 行选择导入、导出路径，第 1323～1363 行实现二元 syncobj 等待接口；
> - [`include/uapi/linux/dma-buf.h`](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/include/uapi/linux/dma-buf.h#L27-L53) 第 27～53 行要求 CPU 映射访问前后调用同步接口，并区分缓存一致性与设备工作等待；[`dma-buf.c`](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/dma-buf/dma-buf.c#L551-L577) 第 551～577 行把读写标志转为 CPU 访问回调；
> - [`amdgpu_dma_buf.c`](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_dma_buf.c) 第 281～319 行在 CPU 读访问前按允许域和 pin 状态尝试调整到 GTT。具体配置下是否移动、如何形成 CPU 访问条件，在正文沿本例分支核对。

源码入口：[dma-resv.h](./2.源码/linux/include/linux/dma-resv.h)、[dma-fence.c](https://github.com/torvalds/linux/blob/248951ddc14de84de3910f9b13f51491a8cd91df/drivers/dma-buf/dma-fence.c)、[amdgpu_sync.c](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_sync.c)、[amdgpu_fence.c](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_fence.c)、[scheduler](./2.源码/linux/drivers/gpu/drm/scheduler)。

## 7.4 TTM 放置、驱逐、迁移与 KFD 队列协调

前面的 GTT 复制与 R 的 CPU 校验已经结束，现在单独改变放置需求：在 Y 已允许的 GTT/VRAM 范围内要求它迁到 HBM。先解释谁提出新的 placement，再跟踪旧使用结束、数据搬运、映射更新和旧存储释放；从这次受控迁移再解释资源压力触发的驱逐。对象存活与访问条件的衔接回查 [06 §2.8](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放.md#28-引用映射与任务完成共同约束资源寿命>)。

- 围绕一次 VRAM/GTT 位置变化解释 placement、资源管理器、LRU、validation 和驱逐；连接系统页面、SG/DMA 地址与本地显存资源，避免重新罗列所有分配接口。
- 说明迁移前怎样协调在途任务，迁移拷贝怎样表示完成，以及已经存在的 GPUVA 怎样在新 backing 可用后继续指向正确数据。
- 若 R 此后再次读取 Y，先按当前允许域、pin 与 CPU 访问请求检查位置及映射；需要迁回 system RAM 或重新准备映射时跟踪相应动作。只有 BAR 与映射条件明确支持时才解释 CPU 直接访问 HBM，不把主线原有 CPU 指针当成可无条件使用的证明。
- 加入 KFD BO 的对照：普通 AQL Packet 不逐次进入 DRM scheduler，因此要专门追踪 KFD eviction fence 如何参与 BO 迁移、用户 Queue 停止与恢复。区分进程 BO 与 SVM BO 的具体处理分支。
- 回看 05 的范围、页面迁移与 notifier，以及 [06 §3.8 的缺页恢复变体](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放.md#38-可恢复缺页把设备执行接回-host-处理>)：说明通用 TTM 资源迁移和 SVM 地址空间协调分别处理什么，哪些底层能力被共同使用。

本节结束时，应能解释“数据已搬完”之后还需要满足哪些映射与同步条件，以及 Queue 暂停期间哪些软件对象仍然存在。

可选回查：实际资源创建或归还出现相应接口时，再说明 `dma_alloc_attrs()`、DMA pool 的属性与释放规则，`devm_kmalloc()`、`dmam_alloc_coherent()` 与设备生命周期的关系，以及原子或中断上下文中的 GFP 限制。`folio_alloc()`、`__get_free_pages()`、`get_zeroed_page()` 按当前分配环节比较，不将全部接口列为迁移主线的前置知识。

源码入口：[ttm_bo.c](./2.源码/linux/drivers/gpu/drm/ttm/ttm_bo.c)、[amdgpu_ttm.c](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_ttm.c)、[amdgpu_amdkfd_fence.c](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_fence.c)、[amdgpu_amdkfd_gpuvm.c](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_amdkfd_gpuvm.c)。

## 7.5 GPUVM 更新后端、超时与一次小范围验证

回到前面反复使用的“映射更新已经完成”。沿实际更新过程解释这个完成条件怎样产生，再选择一项失败或超时检查其传播。

- 先说明页表 BO 的存储位置、CPU 映射与 BAR 访问条件，再分别走通 CPU 更新后端和 SDMA 更新后端。CPU 同步写入、刷出与返回条件单独说明；SDMA 的 IB/job、依赖和完成 Fence 单独说明。
- 从 02 的 `bo_va->last_pt_update → kgd_mem->sync → 外层等待` 和 05 的 `vm->last_update` 出发，追踪完成对象的产生、引用和等待，再接回 04 的页表写入、旧翻译失效与后续访问。
- 在需要改变部分大页映射的例子中，解释目录调整、映射拆分与旧页表释放；CPU VMA 与缺页接口统一回查 §7.1，继续追踪此次 GPU 页表变化。
- 在旧翻译失效之后，区分硬件 TLB/页表缓存、Retry 故障跟踪与驱动软件记录。容量、相联度、替换策略、客户端共享范围及失败翻译是否被缓存，只使用直接适用于 MI300/CDNA 3 的资料或可复核实验；无证据的规格保留边界，不能由其他型号或通用函数名推定，也不作为完成本章的条件。
- 沿一个普通 job 超时或错误案例，检查错误写到哪个完成对象、哪些等待结束、旧结果能否使用，以及 Reset 后应用还需怎样处理任务和资源。对照 [06 §4.5 的阶段证据检查](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放.md#45-用阶段证据判断任务停在何处>)，在本条 DRM 路径中定位实际阻断的依赖或执行阶段。
- 选择一处与这条主线有关的调试信息或小修改，记录问题、源码位置、预期变化和结果。源码推演、构建与设备运行分别记录；缺少设备时保留实测状态，不把静态核对写成运行通过。

本节结束时，应能把“资源分配 → GPUVA 映射 → 提交依赖 → 执行完成 → 迁移或释放”重新画成一条完整流程，并在源码中定位各个交接处。映射撤销和最终释放的前提回接 [06 §5.3](<./06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放.md#53-内存解除映射runtime-关闭与对象收尾>)。

源码入口：[amdgpu_vm.c](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_vm.c)、[amdgpu_vm_cpu.c](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_vm_cpu.c)、[amdgpu_vm_sdma.c](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_vm_sdma.c)、[amdgpu_job.c](./2.源码/linux/drivers/gpu/drm/amd/amdgpu/amdgpu_job.c)。

## 7.6 学习范围与完成标准

完成标准按同一案例检查：能够解释共享对象的所有权与各进程地址、一次普通 DRM 任务的提交和完成、BO 迁移对既有使用者的约束，以及错误后等待和释放怎样继续。用一份源码追踪记录和一项小范围验证支撑这些解释；实际未运行的部分明确保留状态。

本章不扩展显示管线、完整编译器、Device Enqueue、自研 GPU 或多 GPU 系统设计。完成上述主线后，以实际驱动问题决定是否继续查阅相关分支。
