# Linux 内存管理基础

## 缩写表

| 缩写                  | 英文全称                                                   | 中文含义                                     |
| --------------------- | ---------------------------------------------------------- | -------------------------------------------- |
| ABI                   | Application Binary Interface                               | 应用程序二进制接口                           |
| AF                    | Access Flag                                                | 访问标志                                     |
| AMDGPU                | AMD GPU Linux Kernel Driver                                | AMD GPU Linux 内核驱动                       |
| AP                    | Access Permission                                          | 访问权限                                     |
| API                   | Application Programming Interface                          | 应用程序编程接口                             |
| ARM / ARM64           | Arm Architecture / Arm 64-bit Architecture                 | Arm 架构 / 64 位 Arm 架构                    |
| ASID                  | Address Space Identifier                                   | 地址空间标识符                               |
| AttrIndx              | Attribute Index                                            | 内存属性索引                                 |
| BADDR                 | Base Address                                               | 基地址                                       |
| CLONE_VM              | Clone Virtual Memory flag                                  | 创建任务时共享虚拟地址空间的标志             |
| COW                   | Copy-on-Write                                              | 写时复制                                     |
| CPU                   | Central Processing Unit                                    | 中央处理器                                   |
| DMA                   | Direct Memory Access                                       | 直接内存访问                                 |
| DSB                   | Data Synchronization Barrier                               | 数据同步屏障                                 |
| EL0 / EL1             | Exception Level 0 / Exception Level 1                      | 异常级别 0 / 异常级别 1                      |
| ELR_EL1               | Exception Link Register at Exception Level 1               | 异常级别 1 异常链接寄存器                    |
| ERET                  | Exception Return                                           | 异常返回指令                                 |
| GEM                   | Graphics Execution Manager                                 | 图形执行管理器                               |
| GFP                   | Get Free Pages                                             | Linux 内存分配行为标志                       |
| GPU                   | Graphics Processing Unit                                   | 图形处理器                                   |
| HMM                   | Heterogeneous Memory Management                            | 异构内存管理                                 |
| IOMMU                 | Input/Output Memory Management Unit                        | 输入/输出内存管理单元                        |
| IOVA                  | Input/Output Virtual Address                               | 输入/输出虚拟地址；设备使用的一类 DMA 地址   |
| IPI                   | Inter-Processor Interrupt                                  | 处理器间中断                                 |
| IRQ                   | Interrupt Request                                          | 中断请求                                     |
| ISB                   | Instruction Synchronization Barrier                        | 指令同步屏障                                 |
| KiB / MiB / GiB       | Kibibyte / Mebibyte / Gibibyte                             | 二进制千字节 / 兆字节 / 吉字节               |
| L0～L3                | Level 0 through Level 3                                    | 第 0 级到第 3 级页表                         |
| LR                    | Link Register                                              | 链接寄存器                                   |
| LRU                   | Least Recently Used                                        | 最近最少使用；Linux 页面回收使用的链表类别   |
| MAIR_EL1              | Memory Attribute Indirection Register at Exception Level 1 | 异常级别 1 内存属性间接寄存器                |
| MM                    | Memory Management                                          | 内存管理；`mm_struct` 表示地址空间管理对象 |
| MMIO                  | Memory-Mapped Input/Output                                 | 内存映射输入/输出                            |
| MMU                   | Memory Management Unit                                     | 内存管理单元                                 |
| MPU                   | Memory Protection Unit                                     | 内存保护单元                                 |
| nG                    | non-Global                                                 | 非全局映射标志                               |
| NS                    | Non-secure                                                 | 非安全属性                                   |
| PA                    | Physical Address                                           | 物理地址                                     |
| PAN                   | Privileged Access Never                                    | 特权访问禁止                                 |
| PC                    | Program Counter                                            | 程序计数器                                   |
| PFN                   | Page Frame Number                                          | 物理页框编号                                 |
| PID / TGID            | Process Identifier / Thread Group Identifier               | 任务标识符 / 线程组标识符                    |
| PGD                   | Page Global Directory                                      | 页全局目录                                   |
| PMD                   | Page Middle Directory                                      | 页中间目录                                   |
| PSTATE                | Process State                                              | 处理器状态                                   |
| PTE                   | Page Table Entry                                           | 页表项                                       |
| pt_regs               | Linux structure name; regs means Registers                 | Linux 保存异常现场的寄存器结构体             |
| PUD                   | Page Upper Directory                                       | 页上级目录                                   |
| PXN                   | Privileged Execute Never                                   | 特权级禁止执行                               |
| RAM                   | Random Access Memory                                       | 随机存取存储器；本章主要指系统物理内存       |
| RET                   | Return                                                     | 函数返回指令                                 |
| rmap                  | Reverse Mapping                                            | 反向映射                                     |
| RSS                   | Resident Set Size                                          | 驻留集大小                                   |
| RTOS                  | Real-Time Operating System                                 | 实时操作系统                                 |
| RW                    | Read-Write                                                 | 读写                                         |
| SG                    | Scatter-Gather                                             | 分散—聚集；用条目列表描述多段内存           |
| SH                    | Shareability                                               | 可共享属性                                   |
| SIGSEGV               | Segmentation Violation Signal                              | 段错误信号                                   |
| SP                    | Stack Pointer                                              | 栈指针                                       |
| SP_EL0 / SP_EL1       | Stack Pointer at Exception Level 0 / 1                     | 异常级别 0 / 1 栈指针寄存器                  |
| SPSR_EL1              | Saved Program Status Register at Exception Level 1         | 异常级别 1 保存程序状态寄存器                |
| SVM                   | Shared Virtual Memory                                      | 共享虚拟内存                                 |
| T0SZ                  | TTBR0 Address Space Size Field                             | TTBR0 地址空间大小字段                       |
| TCR_EL1               | Translation Control Register at Exception Level 1          | 异常级别 1 转换控制寄存器                    |
| TG0                   | Translation Granule for TTBR0                              | TTBR0 的转换粒度字段                         |
| TLB                   | Translation Lookaside Buffer                               | 地址转换后备缓冲器（快表）                   |
| TLBI                  | Translation Lookaside Buffer Invalidate                    | TLB 无效化操作                               |
| TTBR0_EL1 / TTBR1_EL1 | Translation Table Base Register 0 / 1 at Exception Level 1 | 异常级别 1 转换表基址寄存器 0 / 1            |
| TTM                   | Translation Table Maps                                     | 转换表映射内存管理器                         |
| UXN                   | Unprivileged Execute Never                                 | 非特权级禁止执行                             |
| VA                    | Virtual Address                                            | 虚拟地址                                     |
| VM                    | Virtual Memory                                             | 虚拟内存                                     |
| VMA                   | Virtual Memory Area                                        | 虚拟内存区域                                 |
| VPN                   | Virtual Page Number                                        | 虚拟页号                                     |
| VRAM                  | Video Random-Access Memory                                 | 显存                                         |

> **[BOUNDARY]** 本文以 ARM/MMU 为切入点，讲解 Linux 地址空间、物理页和常用内存接口。更完整且带本地 Linux/AMDGPU 源码基线的扩展笔记见 [2A. Linux 内存管理基础](<./1.笔记/2A. Linux 内存管理基础：从物理内存、PFN 与 struct page 到 GEM、TTM、HMM.md>)。

## 0. 为什么要引入虚拟地址

在简单的裸机系统中，通常只有一个程序运行。没有启用地址转换时，程序产生的地址可以直接作为物理地址使用：

```text
裸机程序load/store
        │
        ▼
   物理地址PA
        │
        ▼
     物理内存
```

带操作系统的系统需要同时管理多个进程或任务。即使不使用虚拟地址，操作系统也可以通过 MPU、特权级等机制限制各任务能够访问的物理区域。不过，所有程序仍共用一套物理地址编号，程序地址也直接绑定实际物理位置，由此产生以下问题。

### 0.1 所有程序共用同一套地址编号

没有地址转换时，物理地址 `0x4000` 在整个系统中始终表示同一个物理位置。操作系统可以把不同物理区域分配给不同进程：

```text
PA 0x4000～0x7FFF  → 分配给进程A
PA 0x8000～0xBFFF  → 分配给进程B
```

但进程 B 的程序必须按照 `0x8000` 这一实际物理位置运行，或者在加载时进行重定位。操作系统无法在不进行地址转换的情况下，让进程 A 和进程 B 各自使用相同的地址数值，却访问不同的物理位置。

### 0.2 地址隔离与物理内存布局直接绑定

RTOS 等系统可以使用 MPU 为不同任务配置可访问的物理区域：

```text
任务A → 只允许访问物理区域A
任务B → 只允许访问物理区域B
```

因此，直接使用物理地址不代表系统一定没有隔离。但是，这种隔离依赖任务的实际物理位置；当任务被移动、扩展或重新分配内存时，相应的物理区域和访问权限也需要重新管理。

### 0.3 连续内存难以分配

程序通常希望获得一段连续内存。假设页面大小为 4 KiB，程序需要连续的 4 个页面：

```text
程序期望的连续地址

┌───────────┬───────────┬───────────┬───────────┐
│ 0x1000页  │ 0x2000页  │ 0x3000页  │ 0x4000页  │
└───────────┴───────────┴───────────┴───────────┘
```

但物理内存经过多次分配和释放后，空闲页可能分散在不同位置：

```text
低物理地址

PFN 100       ┌──────────┐
              │   空闲   │
PFN 101～319  ├──────────┤
              │  已使用  │
PFN 320       ├──────────┤
              │   空闲   │
PFN 321～699  ├──────────┤
              │  已使用  │
PFN 700       ├──────────┤
              │   空闲   │
PFN 701～899  ├──────────┤
              │  已使用  │
PFN 900       ├──────────┤
              │   空闲   │
              └──────────┘

高物理地址
```

虽然这里共有 4 个空闲物理页，但它们并不连续。如果程序直接使用物理地址，就必须找到 4 个连续的物理页才能得到一段连续地址。

引入虚拟地址后，连续虚拟页可以分别映射到这些离散物理页：

```text
连续虚拟页                 离散物理页

VA 0x1000 ───────────────→ PFN 100
VA 0x2000 ───────────────→ PFN 320
VA 0x3000 ───────────────→ PFN 700
VA 0x4000 ───────────────→ PFN 900
```

程序看到的地址仍然连续，但背后的物理页不需要连续。

### 0.4 虚拟地址提供了什么

Linux 为每个进程提供独立的虚拟地址空间：

```text
进程A虚拟地址空间          进程B虚拟地址空间

VA 0x4000                  VA 0x4000
    │                          │
    ▼                          ▼
进程A页表                   进程B页表
    │                          │
    ▼                          ▼
PFN 100                    PFN 900
```

虽然两个进程使用相同的虚拟地址，但它们可以映射到不同的物理页。

虚拟地址带来的核心能力是：

```text
地址隔离：每个进程拥有自己的地址空间
地址重定位：程序不需要知道实际物理位置
灵活分配：连续虚拟页可以映射离散物理页
```

虚拟地址不是另一份物理内存，而是程序使用的一套地址编号。

### 0.5 引入虚拟地址后产生的新问题

程序使用虚拟地址，但物理内存仍然需要物理地址。因此，系统必须建立：

```text
虚拟地址VA
    │
    │ 地址翻译
    ▼
物理地址PA
```

地址翻译实际以页面为单位：

```text
虚拟页号VPN
    │
    │ 页表映射
    ▼
物理页框编号PFN
```

页内偏移保持不变：

```text
VA = VPN + offset
       │
       │ VPN → PFN
       ▼
PA = PFN对应的页基地址 + 相同offset
```

由此需要解释三个对象：

```text
Linux页表：保存VPN到PFN的映射关系
ARM MMU：按照页表完成地址翻译
TTBR（Translation Table Base Register，转换表基址寄存器）：告诉MMU根页表在哪里
  ├─ TTBR0_EL1（Translation Table Base Register 0, EL1）：Linux通常用于用户地址空间
  └─ TTBR1_EL1（Translation Table Base Register 1, EL1）：Linux通常用于内核地址空间
```

第 1 章将回答：ARM MMU 如何从一个虚拟地址出发，通过 `TTBR` 和多级页表找到最终物理地址？

## 1. ARM MMU：从虚拟地址到物理地址

[BOUNDARY] 本节只讨论 ARM64 EL0/EL1 的 Stage-1 地址翻译，并固定使用 4 KiB granule、48 位用户虚拟地址。暂不讨论虚拟化场景中的 Stage-2 翻译。

### 1.1 Linux、MMU 与 TTBR 分别负责什么

Linux 和 MMU 的分工是：

```text
Linux内核
  ├─ 创建页表
  ├─ 修改虚拟页到物理页的映射
  └─ 进程切换时切换用户地址空间

ARM MMU
  ├─ 接收CPU产生的虚拟地址
  ├─ 查询TLB
  └─ TLB未命中时按照页表完成地址翻译
```

页表存放在内存中，MMU 必须先知道根页表的位置。ARM64 使用 TTBR 保存这个起点：

```text
TTBR0_EL1
  ├─ BADDR（Base Address）：用户地址空间根页表的基地址
  └─ ASID（Address Space Identifier）：标识该地址空间，帮助区分TLB中的不同进程映射

TTBR1_EL1
  └─ Linux通常用它保存内核地址空间的根页表
```

对于用户地址空间，可以把进程切换简化为：

```text
进程的mm_struct
    │
    │ mm->pgd指向该进程的根页表
    ▼
Linux切换地址空间
    │
    │ 设置TTBR0_EL1中的根页表基地址和ASID
    ▼
ARM MMU获得页表遍历起点
```

`TCR_EL1`（Translation Control Register, EL1，EL1 转换控制寄存器）则负责配置地址翻译方式。本节关心其中两个概念：

```text
T0SZ：决定TTBR0_EL1管理的虚拟地址宽度
TG0：决定TTBR0_EL1使用的translation granule大小
```

本节假设：

```text
T0SZ = 16  → 虚拟地址宽度为64 - 16 = 48位
TG0 选择4 KiB granule
```

### 1.2 一个 48 位虚拟地址如何拆分

在 4 KiB granule 下，一页有 `2^12` 个字节，因此虚拟地址低 12 位是页内偏移。其余位被分成 4 组页表索引：

```text
虚拟地址VA

47       39 38       30 29       21 20       12 11         0
┌──────────┬───────────┬───────────┬───────────┬────────────┐
│ L0 index │ L1 index  │ L2 index  │ L3 index  │ page offset│
│   9位    │    9位    │    9位    │    9位    │    12位    │
└──────────┴───────────┴───────────┴───────────┴────────────┘
```

每个 9 位索引可以表示 `0～511`，因此每一级页表都有 512 个条目。

Linux 在这种四级配置下使用的名称大致对应为：

```text
ARM Level 0 → Linux PGD
ARM Level 1 → Linux PUD
ARM Level 2 → Linux PMD
ARM Level 3 → Linux PTE
```

### 1.3 页表在物理内存中是什么样的

一个页表本身也是一个 4 KiB 的物理页。ARM64 的每个页表描述符占 8 字节：

```text
4096字节 / 8字节 = 512个描述符
```

在物理内存中，可以把一个页表页看成下面的数组：

```text
页表页物理基地址
        │
        ▼
┌──────────────────────┐ offset 0x000
│ descriptor[0]  8字节 │
├──────────────────────┤ offset 0x008
│ descriptor[1]  8字节 │
├──────────────────────┤
│ ...                  │
├──────────────────────┤ offset 0xFF8
│ descriptor[511]      │
└──────────────────────┘
```

某个描述符的物理地址为：

```text
描述符PA = 当前页表页的基地址 + index × 8
```

每个 entry 都是一个 64 位 descriptor。MMU 读取完整的 64 位值后，首先检查最低两位 `bits[1:0]`，判断当前 entry 是继续遍历、完成映射，还是翻译失败。

四种 descriptor 可以概括为：

```text
1. Table descriptor（L0、L1、L2）

63                                                        0
┌──────────────┬──────────────────────────┬──────────────┬────┐
│ Table属性     │ Next-level table address │ 忽略/扩展字段 │ 11 │
└──────────────┴──────────────────────────┴──────────────┴────┘
                                       指向下一级页表 ─────┘

2. Block descriptor（L1、L2）

63                                                        0
┌────────────┬──────────────────────┬──────────────────┬────┐
│ Upper attrs│ Output block address │ Lower attributes │ 01 │
└────────────┴──────────────────────┴──────────────────┴────┘
                                      直接完成大块映射 ────┘

3. Page descriptor（L3）

63                                                        0
┌────────────┬──────────────────────┬──────────────────┬────┐
│ Upper attrs│ Output page address  │ Lower attributes │ 11 │
└────────────┴──────────────────────┴──────────────────┴────┘
                                      映射一个4 KiB页 ─────┘

4. Invalid descriptor（所有Level）

63                                                        0
┌───────────────────────────────────────────────────────┬────┐
│                       Ignored                         │ x0 │
└───────────────────────────────────────────────────────┴────┘
                                         产生Translation Fault
```

其中 `x0` 表示只要 `bit[0]=0`，无论 `bit[1]` 是 0 还是 1，entry 都是 Invalid descriptor。

descriptor 类型需要结合当前 Level 判断：

| `bits[1:0]` | L0              | L1          | L2          | L3              |
| ------------- | --------------- | ----------- | ----------- | --------------- |
| `x0`        | Invalid         | Invalid     | Invalid     | Invalid         |
| `01`        | 不支持（Fault） | 1 GiB Block | 2 MiB Block | 不支持（Fault） |
| `11`        | Table → L1     | Table → L2 | Table → L3 | 4 KiB Page      |

`0b11` 的含义取决于当前 Level：

```text
L0、L1、L2中的0b11 → Table descriptor，继续查询下一级
L3中的0b11         → Page descriptor，完成4 KiB页面映射
```

因此，一次四级遍历可能在不同位置结束：

```text
L0 descriptor
  ├─ x0或01 → Translation Fault
  └─ 11 → 进入L1页表
            │
            ├─ x0 → Translation Fault
            ├─ 01 → 映射1 GiB Block，遍历结束
            └─ 11 → 进入L2页表
                      │
                      ├─ x0 → Translation Fault
                      ├─ 01 → 映射2 MiB Block，遍历结束
                      └─ 11 → 进入L3页表
                                │
                                ├─ x0或01 → Translation Fault
                                └─ 11 → 映射4 KiB Page，遍历结束
```

不同叶子 descriptor 中的地址字段宽度也不同：

| 叶子 descriptor | 地址字段        | 对齐要求   | VA 中直接保留的 offset |
| --------------- | --------------- | ---------- | ---------------------- |
| L1 Block        | `bits[47:30]` | 1 GiB 对齐 | `VA[29:0]`           |
| L2 Block        | `bits[47:21]` | 2 MiB 对齐 | `VA[20:0]`           |
| L3 Page         | `bits[47:12]` | 4 KiB 对齐 | `VA[11:0]`           |

descriptor 中的地址字段决定“映射到哪里”，属性字段决定“这段内存如何被访问”：

```text
地址字段
  ├─ Table descriptor → 下一级页表基地址
  ├─ Block descriptor → 最终物理块基地址
  └─ Page descriptor  → 最终物理页基地址

常用访问属性
  ├─ AttrIndx       → 选择内存类型与Cache属性
  ├─ AP             → EL0/EL1的读写权限
  ├─ SH             → Shareability属性
  ├─ AF             → 页面是否已经被访问
  ├─ nG             → TLB映射是否与ASID关联
  └─ UXN / PXN      → EL0/EL1是否禁止执行
```

因此，地址字段相同并不代表访问行为完全相同，最终行为还取决于 descriptor 的权限、执行、内存类型和共享属性。同一个 PA 如果存在多个虚拟别名，Linux 还必须保证这些别名使用兼容的内存类型与 Cache/Shareability 属性。具体属性位的位置和解析方法将在 1.5 节结合完整 descriptor 数值说明。

### 1.4 用一个虚拟地址完成四级页表遍历

假设 CPU 访问下面的用户虚拟地址：

```text
VA = 0x00007F12_34567ABC
```

拆分后得到：

```text
L0 index = 254
L1 index = 72
L2 index = 418
L3 index = 359
offset   = 0xABC
```

再假设：

```text
TTBR0_EL1.BADDR = 0x10000000
```

这表示 Level 0 根页表位于物理地址 `0x10000000`。MMU 的遍历过程如下：

```text
TTBR0_EL1.BADDR = 0x10000000
        │
        │ L0 index = 254
        │ descriptor PA = 0x10000000 + 254 × 8
        │               = 0x100007F0
        │ 从该PA读取8字节descriptor
        ▼
L0[254]：Table descriptor
        │ descriptor地址字段 = Level 1页表PA 0x11000000
        │
        │ L1 index = 72
        │ descriptor PA = 0x11000000 + 72 × 8
        │               = 0x11000240
        │ 从该PA读取8字节descriptor
        ▼
L1[72]：Table descriptor
        │ descriptor地址字段 = Level 2页表PA 0x12000000
        │
        │ L2 index = 418
        │ descriptor PA = 0x12000000 + 418 × 8
        │               = 0x12000D10
        │ 从该PA读取8字节descriptor
        ▼
L2[418]：Table descriptor
        │ descriptor地址字段 = Level 3页表PA 0x13000000
        │
        │ L3 index = 359
        │ descriptor PA = 0x13000000 + 359 × 8
        │               = 0x13000B38
        │ 从该PA读取8字节descriptor
        ▼
L3[359]：Page descriptor
        │ descriptor地址字段 = 最终物理页基地址0x12345000
        ▼
加上原VA的offset 0xABC
        │
        ▼
最终PA = 0x12345000 + 0xABC
       = 0x12345ABC
```

页表只替换虚拟页对应的物理页，页内偏移 `0xABC` 在整个翻译过程中保持不变。

### 1.5 每一级 descriptor 的值如何解析

[BOUNDARY] 下面继续沿用 48 位 PA、4 KiB granule 的基础格式，只解析本例用到的地址、类型和常用访问属性；可选架构扩展占用的位暂不展开。

**L0～L2：Table descriptor**

本例中的 L0、L1、L2 都使用 Table descriptor。将没有使用的属性位设为 0 后，结构可以简化为：

```text
63          59 58          48 47                      12 11        2 1  0
┌─────────────┬──────────────┬──────────────────────────┬───────────┬────┐
│ Table属性=0  │ 保留/忽略=0  │ 下一级页表物理基地址       │ 忽略=0    │ 11 │
└─────────────┴──────────────┴──────────────────────────┴───────────┴────┘
                                                    bits[1:0]=0b11
```

解析时使用两个关键掩码：

```text
TYPE_MASK = 0x0000000000000003   // bits[1:0]
ADDR_MASK = 0x0000FFFFFFFFF000   // bits[47:12]

descriptor类型      = descriptor & TYPE_MASK
下一级页表物理地址   = descriptor & ADDR_MASK
```

本例的三个 Table descriptor 可以完整写成：

| 当前层级 | descriptor 存放 PA | descriptor 64 位值     | 类型位   | 提取出的下一级页表 PA |
| -------- | ------------------ | ---------------------- | -------- | --------------------- |
| L0[254]  | `0x100007F0`     | `0x0000000011000003` | `0b11` | `0x11000000`        |
| L1[72]   | `0x11000240`     | `0x0000000012000003` | `0b11` | `0x12000000`        |
| L2[418]  | `0x12000D10`     | `0x0000000013000003` | `0b11` | `0x13000000`        |

以 L0 为例：

```text
descriptor = 0x0000000011000003

descriptor & TYPE_MASK
= 0x0000000011000003 & 0x3
= 0x3 = 0b11
→ 在L0～L2表示Table descriptor

descriptor & ADDR_MASK
= 0x0000000011000003 & 0x0000FFFFFFFFF000
= 0x0000000011000000
→ 下一级L1页表PA为0x11000000
```

L1 和 L2 使用完全相同的方法，只是地址字段分别变成 `0x12000000` 和 `0x13000000`。

**L3：Page descriptor**

在 L3，`bits[1:0]=0b11` 表示 Page descriptor，不再表示 Table descriptor。同一类型位编码会随当前层级改变含义。

为了给本例补充一个可解析的完整值，假设最终页面具有以下属性：

```text
允许EL0和EL1读写
禁止EL0和EL1执行
Inner Shareable
Access Flag已经置1
Non-Global，由ASID区分不同进程的TLB映射
AttrIndx = 0
```

对应的示例 Page descriptor 为：

```text
L3[359] descriptor = 0x0060000012345F43
```

其主要位域为：

```text
bit 54      UXN      = 1      禁止EL0执行
bit 53      PXN      = 1      禁止EL1执行
bit 52      Contiguous = 0    不使用连续映射提示
bits 47:12  Output Address    = 0x12345000
bit 11      nG       = 1      非全局映射，TLB项与ASID关联
bit 10      AF       = 1      Access Flag已设置
bits 9:8    SH       = 0b11   Inner Shareable
bits 7:6    AP       = 0b01   EL0读写、EL1读写
bit 5       NS       = 0      安全状态细节本节不展开
bits 4:2    AttrIndx = 0b000  选择MAIR_EL1中的第0项
bits 1:0    Type     = 0b11   在L3表示Page descriptor
```

`MAIR_EL1`（Memory Attribute Indirection Register at Exception Level 1，异常级别 1 内存属性间接寄存器）中的第 0 项究竟代表哪种内存类型，由 Linux 对该寄存器的配置决定，本例暂不展开。

这个 Page descriptor 可以按下面的方式解析：

```text
descriptor & TYPE_MASK
= 0x0060000012345F43 & 0x3
= 0x3 = 0b11
→ 当前位于L3，因此是Page descriptor

descriptor & ADDR_MASK
= 0x0060000012345F43 & 0x0000FFFFFFFFF000
= 0x0000000012345000
→ 最终物理页基地址为0x12345000

最终PA
= 物理页基地址 + 原VA的offset
= 0x12345000 + 0xABC
= 0x12345ABC
```

因此，这个例子中的四个 descriptor 完整串联为：

```text
L0 descriptor 0x0000000011000003 → L1页表PA 0x11000000
L1 descriptor 0x0000000012000003 → L2页表PA 0x12000000
L2 descriptor 0x0000000013000003 → L3页表PA 0x13000000
L3 descriptor 0x0060000012345F43 → 数据页PA 0x12345000
                                              + offset 0xABC
                                              = PA 0x12345ABC
```

实际 Linux 创建的 descriptor 可能因为内存类型、权限和可选架构特性而具有不同属性位，但“先解析类型，再用地址掩码提取输出地址”的基本过程不变。

### 1.6 叶子描述符与 PFN 的关系

ARM 页表描述符并没有一个名字叫作“PFN”的独立字段。它保存的是对齐后的输出物理地址。

在 4 KiB 基础页下，可以把叶子描述符中的物理页基地址解释为 PFN：

```text
物理页基地址 = 0x12345000

PFN = 0x12345000 >> 12
    = 0x12345
```

因此，`VPN → PFN` 是对整个页表遍历结果的概念性压缩：

```text
VPN
 ├─ L0 index
 ├─ L1 index
 ├─ L2 index
 └─ L3 index
        │
        ▼
四级页表遍历
        │
        ▼
叶子描述符中的物理页基地址
        │ 右移12位
        ▼
       PFN
```

中间 Table descriptor 指向的页表页也有自己的物理地址和 PFN，但这些 PFN 标识的是页表页，不是程序最终访问的数据页。

### 1.7 为什么有时不需要走到 Level 3

4 KiB 是本节配置中的基础页大小，但 Level 1 和 Level 2 也可以使用 Block descriptor 提前结束遍历：

| 叶子所在层级 | 映射大小 | 包含的 4 KiB PFN 数量 | 页内偏移 |
| ------------ | -------- | --------------------- | -------- |
| Level 1      | 1 GiB    | 262144                | 低 30 位 |
| Level 2      | 2 MiB    | 512                   | 低 21 位 |
| Level 3      | 4 KiB    | 1                     | 低 12 位 |

例如，MMU 在 Level 2 遇到 2 MiB Block descriptor 时：

```text
TTBR0_EL1 → Level 0 → Level 1 → Level 2 Block descriptor
                                         │
                                         └─ 不再查询Level 3

PA = 2 MiB对齐的物理块基地址 + VA低21位
```

2 MiB 的映射不一定使用 PMD Block，也可以由 512 个 4 KiB PTE 组成。下面只讨论 `[1:0] = 0b01` 的 PMD Block descriptor。

PMD 不会逐个保存 512 个 PFN，而是保存 2 MiB 对齐物理块基地址的高位：

```text
PMD Block descriptor
├─ 类型：0b01
├─ 物理块基地址：PA[47:21]
└─ 整个2 MiB共用的权限和内存属性
```

MMU 使用下面的关系完成翻译：

```text
PA = PMD中的物理块基地址 + VA低21位
```

例如物理块基地址为 `0x02000000`：

```text
起始PFN = 0x02000000 >> 12
        = 0x2000

覆盖PFN：0x2000～0x21FF
```

因此，从硬件格式看，PMD 保存的是物理块基地址的高位；从 Linux 的 4 KiB 页面视角看，它也确定了这段物理块的起始 PFN。

> **[SOURCE]** 本地 Linux `248951ddc14d`：[arch/arm64/include/asm/pgtable-hwdef.h](./2.源码/linux/arch/arm64/include/asm/pgtable-hwdef.h) 第 52～57、136～151 行定义 PMD 映射大小、描述符类型和属性；[arch/arm64/include/asm/pgtable.h](./2.源码/linux/arch/arm64/include/asm/pgtable.h) 第 614～630 行实现 PMD Block 类型及起始 PFN 的转换。

### 1.8 MMU 实际执行时还会先查询 TLB

前面的四级遍历描述的是 TLB 未命中时的 translation table walk。一次实际访问可以简化为：

```text
CPU产生VA
    │
    ▼
查询TLB
    │
    ├─ 命中：直接得到地址翻译结果
    │
    └─ 未命中：从TTBR0_EL1开始遍历页表
                    │
                    ├─ 找到有效叶子描述符 → 得到PA并填充TLB
                    └─ 描述符无效         → 产生Translation Fault
```

Translation Fault 如何进入 Linux、Linux 如何分配物理页并更新页表，将在后续 page fault 章节继续说明。

> **[SOURCE]** Arm，[《Learn the Architecture: Memory Management》](<https://developer.arm.com/-/media/Arm%20Developer%20Community/PDF/Learn%20the%20Architecture/LearnTheArchitecture-MemoryManagement-101811_0100_00_en.pdf>)，Version 1.0，§7“Translation granule”、§7.1“The starting level of address translation”、§7.2“Registers that control address translation”。

> **[SOURCE]** [Arm Architecture Reference Manual DDI 0487](https://developer.arm.com/documentation/ddi0487/mc/-Part-D-The-AArch64-System-Level-Architecture/-Chapter-D8-The-AArch64-Virtual-Memory-System-Architecture/-D8-2-Translation-process/-D8-2-8-VMSAv8-64-translation-using-the-4KB-granule?lang=en)，D8.2.8.1“VMSAv8-64 Stage 1 address translation using the 4KB translation granule”。

> **[SOURCE]** Linux kernel [`Documentation/arch/arm64/memory.rst`](https://docs.kernel.org/arch/arm64/memory.html)，“Translation table lookup with 4KB pages”。

> **[SOURCE]** Arm，[《Armv8-A Memory Model》](<https://developer.arm.com/-/media/Arm%20Developer%20Community/PDF/Learn%20the%20Architecture/Armv8-A%20memory%20model%20guide.pdf>)，§3“Describing memory in Armv8-A”、§8“Describing the memory type”、§10“Permissions attributes”、§11“Access Flag”。

> **[SOURCE]** Linux kernel [`arch/arm64/include/asm/pgtable-hwdef.h`](https://github.com/torvalds/linux/blob/master/arch/arm64/include/asm/pgtable-hwdef.h)，ARM64 hardware page-table descriptor bit definitions。

## 2. Linux 进程与地址空间

第 1 章站在硬件视角，说明 MMU 如何从 `TTBR0_EL1` 出发完成 `VA → PA`。本章切换到 Linux 软件视角，回答下面这条主线：

```text
当前运行的是哪个任务？
        │
        ▼
这个任务使用哪个mm_struct？
        │
        ├─ VMA：这段虚拟地址应该如何使用？
        │
        └─ pgd：这套地址空间的根页表在哪里？
                    │
                    ▼
             TTBR、ASID、TLB与MMU
```

> **[SOURCE]** 本章源码基线为本地 `2.源码/linux`，Git commit `248951ddc14de84de3910f9b13f51491a8cd91df`。该提交的根 `Makefile` 标识为 Linux `7.2.0-rc4` 开发阶段。

> **[SOURCE]** `arch/arm64` 已经展开到本地工作目录。本章引用的 ARM64 文件现在都可以从 `2.源码/linux/arch/arm64` 直接打开，并且属于上述同一提交。

### 2.1 `task_struct`：Linux 如何描述任务

Linux 调度器调度的基本对象是任务。用户看到的进程和线程，在内核中都由一个 `struct task_struct` 表示。

#### 2.1.1 进程和线程有什么区别

从用户视角看：

```text
进程：资源隔离和地址空间的边界
线程：进程内部可以被独立调度的一条执行流
```

但 Linux 内核没有分别使用 `process_struct` 和 `thread_struct` 表示二者。无论进程还是线程，调度器看到的都是独立的 `task_struct`：

```text
进程A
├── 主线程   → task_struct A1 ─┐
├── 工作线程 → task_struct A2 ─┼──→ 共享mm_struct A
└── 工作线程 → task_struct A3 ─┘

进程B
└── 主线程   → task_struct B1 ─────→ 独立mm_struct B
```

在本章关心的内存视角下，主要区别是：

| 对象                 | 不同进程之间     | 同一进程的线程之间                                     |
| -------------------- | ---------------- | ------------------------------------------------------ |
| `task_struct`      | 各自独立         | 每个线程也各自独立                                     |
| PID                  | 不同             | 每个线程也有自己的 PID                                 |
| TGID                 | 不同             | 通常相同，用来表示同一线程组                           |
| `mm_struct`        | 通常不同         | 共享同一个                                             |
| VMA、用户页表、ASID  | 各自独立         | 随`mm_struct` 一起共享                               |
| CPU 寄存器和调度状态 | 各自独立         | 每个线程各自独立                                       |
| 内核栈               | 各自独立         | 每个线程各自独立                                       |
| 用户栈               | 位于各自地址空间 | 每个线程使用不同的 VA 范围，但都位于同一个共享地址空间 |

线程的用户栈虽然通常各自占用不同 VMA 或不同虚拟地址范围，但它们仍属于同一个 `mm_struct`。因此，从页表权限角度看，一个线程原则上可以访问同一进程中另一个线程的用户栈；“线程各自有栈”不等于“线程之间有地址隔离”。

```text
线程A的用户栈 ─┐
线程B的用户栈 ─┼──→ 同一个mm_struct、同一套用户页表
线程C的用户栈 ─┘
```

Linux 通过创建任务时的共享选项决定资源关系。对内存而言，最关键的是 `CLONE_VM`：

```text
设置CLONE_VM   → 新任务共享原来的mm_struct，典型线程关系
未设置CLONE_VM → 新任务获得新的mm_struct，典型进程关系
```

所以“进程”和“线程”并不是两种完全不同的内核对象；区别主要在于多个 `task_struct` 之间共享了哪些资源。文件表、文件系统上下文和信号处理状态也可以按创建选项决定是否共享，但本章只继续追踪 `mm_struct`。

本地 `task_struct` 中可以直接看到每个任务自己的内核栈指针、地址空间指针和 PID/TGID：

```c
void *stack;
struct mm_struct *mm;
struct mm_struct *active_mm;
pid_t pid;
pid_t tgid;
```

> **[SOURCE]** 本地 Linux `248951ddc14d`：[include/linux/sched.h](./2.源码/linux/include/linux/sched.h) 第 845、971～972、1071～1072 行；地址空间是否共享的实际分支见 [kernel/fork.c](./2.源码/linux/kernel/fork.c) 第 1568～1601 行。

#### 2.1.2 `current` 如何找到当前任务

Linux 内核用 `current` 表示当前 CPU 正在执行的任务。在这份 ARM64 源码中，`current` 最终调用 `get_current()`，从 `SP_EL0`（Stack Pointer at Exception Level 0，异常级别 0 栈指针寄存器）读取当前 `task_struct` 指针：

```c
static __always_inline struct task_struct *get_current(void)
{
    unsigned long sp_el0;

    asm ("mrs %0, sp_el0" : "=r" (sp_el0));
    return (struct task_struct *)sp_el0;
}

#define current get_current()
```

`SP_EL0` 在这里不是普通内存。ARM64 Linux 在内核执行期间利用该寄存器快速保存当前任务指针。

> **[SOURCE]** 本地 Linux `248951ddc14d`：[arch/arm64/include/asm/current.h](./2.源码/linux/arch/arm64/include/asm/current.h)，第 15～24 行。

#### 2.1.3 `task->mm` 与 `task->active_mm`

`task_struct` 中与地址空间最直接相关的两个成员是：

```c
struct mm_struct *mm;
struct mm_struct *active_mm;
```

它们的含义可以先简化为：

| 成员          | 含义                               |
| ------------- | ---------------------------------- |
| `mm`        | 任务真正拥有或共享的用户地址空间   |
| `active_mm` | 当前执行时实际采用的地址空间上下文 |

对于普通用户线程：

```text
task->mm ─────────┐
                  ├── 指向同一个mm_struct
task->active_mm ──┘
```

对于不需要用户地址空间的内核线程：

```text
task->mm        = NULL
task->active_mm = 临时借用的地址空间
```

内核线程借用 `active_mm`，主要是为了让 CPU 保持一个可用的内存上下文，并不表示这个内核线程拥有或可以任意使用被借用进程的用户内存。

> **[SOURCE]** 本地 Linux `248951ddc14d`：`include/linux/sched.h:826` 定义 `task_struct`，`include/linux/sched.h:971-972` 定义 `mm` 与 `active_mm`；`Documentation/mm/active_mm.rst` 解释二者语义。

#### 2.1.4 多个任务可以共享一个地址空间

同一进程中的线程通常共享一个 `mm_struct`：

```text
task_struct A ──┐
task_struct B ──┼──→ 同一个mm_struct ──→ 同一组VMA和用户页表
task_struct C ──┘
```

因此，后文的 ASID 标识地址空间，不是某个 PID。

Linux 创建新任务时，会使用一组 `clone_flags` 标志决定新旧任务共享哪些资源。`CLONE_VM`（Clone Virtual Memory，共享虚拟地址空间标志）是其中一个标志位：

```c
#define CLONE_VM 0x00000100
```

`CLONE_VM` 是标志位，不是函数，也不表示“复制物理内存”。它告诉内核：

```text
设置CLONE_VM   → 新任务共享当前任务的mm_struct
未设置CLONE_VM → 新任务获得新的mm_struct
```

`clone_flags` 可以同时包含多个标志。表达式 `clone_flags & CLONE_VM` 使用按位与检查其中是否设置了 `CLONE_VM`：结果非 0 表示已经设置，结果为 0 表示没有设置。

源码中的 `copy_mm()` 负责为新任务选择地址空间。先认识其中几个变量：

| 变量        | 含义                                  |
| ----------- | ------------------------------------- |
| `current` | 正在创建新任务的当前任务              |
| `tsk`     | 正在创建的新`task_struct`           |
| `oldmm`   | `current->mm`，即当前任务的地址空间 |
| `mm`      | 最终准备赋给`tsk` 的地址空间        |

核心代码是：

```c
if (clone_flags & CLONE_VM) {
    mmget(oldmm);
    mm = oldmm;
} else {
    mm = dup_mm(tsk, current->mm);
}

tsk->mm = mm;
tsk->active_mm = mm;
```

设置 `CLONE_VM` 时：

```text
假设oldmm这个内核指针的值为0xffff000010000000：

current->mm ──┐
              ├──→ 同一个mm_struct
tsk->mm ──────┘    mm_struct内核虚拟地址：0xffff000010000000

mmget(oldmm)：只把mm_users引用计数加1
mm = oldmm：  只复制指针，不复制mm_struct
```

因此，两个任务共享同一组 VMA、用户页表和 ASID。一个任务修改用户内存或者通过 `mmap()`、`munmap()` 改变地址空间，另一个任务也会看到结果。`mmget()` 增加 `mm_users`，是为了保证一个任务退出后，共享的 `mm_struct` 不会在其他任务仍使用时被释放。

没有设置 `CLONE_VM` 时：

```text
current->mm ──→ 原来的mm_struct

tsk->mm ─────→ dup_mm()创建的新mm_struct
                ├── 复制VMA布局
                └── 建立子进程自己的页表
```

`dup_mm()` 创建的是独立地址空间，但普通 `fork()` 通常不会立即复制所有物理页，而是使用 COW（Copy-on-Write，写时复制）：父子进程的私有映射可以暂时指向同一物理页，某一方写入时再复制该页。

选定地址空间后：

```c
tsk->mm = mm;
tsk->active_mm = mm;
```

把选中的地址空间安装到新用户任务。于是可以概括为：

```text
常见线程创建方式   → 设置CLONE_VM → 多个task_struct共享一个mm_struct
普通fork()        → 不设置CLONE_VM → 子进程获得新的mm_struct
```

`CLONE_VM` 只决定是否共享地址空间，单独设置它并不足以构成通常意义上的完整线程关系；文件表、信号处理等资源是否共享，还由其他创建标志决定。

> **[SOURCE]** 本地 Linux `248951ddc14d`：`include/uapi/linux/sched.h:11` 定义 `CLONE_VM`（该文件当前未展开，但仍在本地 Git 对象中）；[include/linux/sched/mm.h](./2.源码/linux/include/linux/sched/mm.h) 第 131～134 行定义 `mmget()`；[kernel/fork.c](./2.源码/linux/kernel/fork.c) 第 1518～1566 行实现 `dup_mm()`，第 1568～1601 行实现 `copy_mm()`。

共享地址空间并不表示某块内存由某个线程独占。先认识下一节中的
`mm_struct` 核心成员，再由 2.2.2 节区分内核地址空间共享、分配器的逻辑
归属和线程各自使用的栈范围。

### 2.2 `mm_struct`：Linux 如何描述进程地址空间

`struct mm_struct` 是 Linux 对“一套进程虚拟地址空间”的总体描述。它同时连接两类对象：

```text
                       mm_struct
                  ┌────────┴────────┐
                  ▼                 ▼
          软件视角：VMA       硬件视角：页表
        哪些VA可以使用？       VA当前映射到哪里？
```

#### 2.2.1 `mm_struct` 的核心成员

`mm` 来自 MM（Memory Management，内存管理）。`mm_struct` 不是一块用户内存，也不是页表本身；它是 Linux 管理一整套用户虚拟地址空间的总控对象。

下面按职责重新排列字段，其顺序与真实结构体的内存布局不完全相同：

```c
struct mm_struct {
    /* 生命周期 */
    atomic_t mm_count;
    atomic_t mm_users;

    /* VMA组织与保护 */
    struct maple_tree mm_mt;
    int map_count;
    struct rw_semaphore mmap_lock;

    /* 页表 */
    pgd_t *pgd;
    spinlock_t page_table_lock;
    atomic_long_t pgtables_bytes;

    /* 用户地址空间布局 */
    unsigned long task_size;
    unsigned long mmap_base;
    unsigned long start_code, end_code, start_data, end_data;
    unsigned long start_brk, brk, start_stack;

    /* 虚拟内存与驻留内存统计 */
    unsigned long total_vm;
    unsigned long locked_vm;
    atomic64_t pinned_vm;
    /* rss_stat[]等统计字段，此处省略具体数组定义 */

    /* ARM64等架构使用的地址空间上下文 */
    mm_context_t context;

    /* 还有大量统计、锁和子系统状态，此处省略 */
};
```

这些字段可以分成七组：

| 职责               | 关键成员                                                 | 具体含义                                                              |
| ------------------ | -------------------------------------------------------- | --------------------------------------------------------------------- |
| VMA 索引           | `mm_mt`、`map_count`                                 | `mm_mt` 是按 VA 管理 VMA 的 Maple Tree；`map_count` 记录 VMA 数量 |
| VMA 同步           | `mmap_lock`                                            | 主要保护 VMA 树和地址空间布局；`rw` 是 Read-Write（读写）           |
| 页表入口           | `pgd`                                                  | 指向用户根页表的内核虚拟地址，后续转换成物理地址配置给 TTBR           |
| 页表同步和开销     | `page_table_lock`、`pgtables_bytes`                  | 保护部分页表操作和计数；统计各级页表本身占用的内存                    |
| 用户地址布局       | `task_size`、`mmap_base`、`start_*`、`end_*`     | 记录用户地址上限、`mmap()` 布局基准和主程序各区域的摘要位置         |
| 使用量统计         | `total_vm`、`rss_stat`、`locked_vm`、`pinned_vm` | 区分映射的虚拟页、驻留物理页、锁定页和长期固定页                      |
| 生命周期和架构状态 | `mm_users`、`mm_count`、`context`                  | 管理对象生命周期；`context` 保存 ARM64 ASID 等架构相关状态          |

`mm_struct`、`mm_mt` 与 VMA 之间是一对多的索引与反向归属关系：一个
`mm_struct` 内有一棵 `mm_mt`，树按虚拟地址范围索引这个地址空间中的多个
`struct vm_area_struct` 对象；每个 VMA 又通过 `vm_mm` 指回所属的
`mm_struct`。

```text
一个mm_struct
    │
    ├─ mm_mt（Maple Tree，按VA范围建立索引）
    │    ├─ [vm_start, vm_end) ──► VMA A
    │    ├─ [vm_start, vm_end) ──► VMA B
    │    └─ [vm_start, vm_end) ──► VMA C
    │
    └─ pgd ──► 多级页表

VMA A/B/C中的vm_mm ──► 上面的mm_struct
```

因此，`mm_mt` 不是 VMA 本身，也不保存 VA 到 PFN 的页表映射。它负责从
VA 范围定位描述该范围软件规则的 VMA；`pgd` 指向的页表才记录虚拟页当前的
硬件翻译状态。VMA 的具体查找语义、锁规则以及拆分和合并过程在 2.3.5～2.3.6
节继续展开。

> **[SOURCE]** 本地 Linux `248951ddc14d`：`include/linux/mm_types.h:920-936`
> 定义 VMA 的 `[vm_start, vm_end)` 范围及其 `vm_mm` 回指，第 1177 行定义
> `mm_struct.mm_mt`；`include/linux/mm.h:968-973` 中的 `vma_init()` 将
> `vma->vm_mm` 初始化为所属 `mm_struct`。

其中几个布局字段容易被误解：

- `task_size`：该任务用户虚拟地址空间的大小或上限，具体值受 ARM64 配置和进程 ABI 影响。
- `mmap_base`：Linux 为 `mmap()` 选择地址时使用的布局基准，不是“下一块必定分配的地址”。
- `start_code/end_code`：主程序代码区域的摘要边界；动态库等其他可执行映射仍由各自 VMA 描述。
- `start_data/end_data`：主程序数据区域的摘要边界。
- `start_brk/brk`：进程堆的初始 program break（程序堆边界）和当前 program break。
- `start_stack`：程序启动时记录的用户栈位置，不是线程此刻的 SP，也不等于栈 VMA 的完整边界。

假设某个进程的 `mm_struct` 位于内核虚拟地址 `0xffff000010000000`，可以把它理解成下面这个总目录：

```text
task_struct
    │ task->mm
    ▼
mm_struct @ 0xffff000010000000
    │
    ├─ 地址布局摘要
    │    start_code = 0x400000       end_code = 0x410000
    │    start_data = 0x410000       end_data = 0x418000
    │    start_brk  = 0x600000       brk      = 0x620000
    │    mmap_base  = 0x7f0000000000
    │    start_stack= 0x7fffffffe000
    │
    ├─ mm_mt：按虚拟地址组织该地址空间中的VMA
    │
    │    用户虚拟地址空间
    │
    │    低地址
    │      │
    │      ├─ [0x400000, 0x410000)
    │      │     主程序代码VMA
    │      │     通常：可读、可执行、不可写
    │      │     PC可能指向这里
    │      │
    │      ├─ [0x410000, 0x418000)
    │      │     主程序数据VMA
    │      │     保存全局变量和静态变量
    │      │     通常：可读、可写、不可执行
    │      │
    │      ├─ [0x600000, 0x620000)
    │      │     堆VMA
    │      │     malloc()可能从这里获得内存
    │      │
    │      ├─ [0x7f0000000000, 0x7f0000100000)
    │      │     动态库或mmap()建立的VMA
    │      │     PC也可能在这里执行动态库代码
    │      │
    │      └─ [0x7ffffff00000, 0x800000000000)
    │            用户栈VMA
    │            SP通常指向这个范围内
    │    高地址
    │
    ├─ pgd ──→ 用户根页表
    │            └─ 多级页表最终保存VA到PFN的映射
    │
    ├─ context ──→ ARM64 ASID等架构状态
    │
    ├─ 统计
    │    map_count       = VMA数量
    │    total_vm        = VMA总共覆盖多少虚拟页
    │    rss_stat        = 当前有多少页面驻留在物理内存
    │    pgtables_bytes  = 页表自身占用了多少内存
    │
    └─ 锁与生命周期
         mmap_lock、page_table_lock、mm_users、mm_count
```

上图中的地址只是示例。`start_code`、`brk` 等字段只是布局摘要，它们本身不会创建 VMA，也不会建立 PTE：

| 问题                                     | 主要查看对象                                        |
| ---------------------------------------- | --------------------------------------------------- |
| 这段 VA 在软件上是否合法、允许怎样访问？ | `mm_mt` 中的 VMA                                  |
| 这个虚拟页当前映射到哪个物理页？         | `pgd` 指向的多级页表                              |
| 主程序代码、堆、初始栈大致位于哪里？     | `start_code`、`brk`、`start_stack` 等摘要字段 |

`total_vm` 和 RSS（Resident Set Size，驻留集大小）也不能混为一谈。
`total_vm` 没有固定值；它记录当前 `mm_struct` 中由内核计入的 VMA 总页数，
会随地址空间映射的建立、扩大、缩小和删除而动态变化。RSS 则记录这些映射中
当前驻留的匿名页、文件页和共享内存页。

假设页面大小为 4 KiB，某个地址空间在某一时刻的统计值为：

```text
total_vm = N页 → 全部VMA总计覆盖 N × 4 KiB虚拟地址
RSS      = R页 → 其中约有 R × 4 KiB页面当前驻留
```

例如，下面的 `N` 和 `R` 只是某个地址空间在某一时刻的算例，不是
`mm_struct` 的固定值：

```text
N = 3072页 → total_vm表示约12 MiB虚拟地址
R =  768页 → RSS表示约3 MiB驻留页面
```

如果新建一个恰好 16 MiB 的 VMA，在 4 KiB 页面下应理解为：

```text
Δtotal_vm = +4096页
```

它表示原有 `total_vm` 增加 4096 页，而不是被设置成 4096。

[INFERENCE] 各种场景都可以归结为这一区别：

```text
total_vm：VMA一共描述了多少虚拟地址范围
RSS：     其中有多少普通页面当前已经映射并驻留

存在VMA，不等于其中所有页面当前都驻留。
```

由此只会延伸出两类原因：

1. 页面还没有进入 RSS：VMA 已存在，但页面尚未按需分配或调入，例如只使用了
   一部分堆、栈或文件映射。
2. 页面曾经进入 RSS，后来又离开：VMA 仍存在，但页面被回收、换出或主动
   丢弃。

例如，在 4 KiB 页面下映射一个 2 MiB 文件：

```text
mmap()建立2 MiB文件VMA
    → Δtotal_vm = +512页
    → 普通按需映射下，RSS通常不会立即增加512页

访问一个尚未映射的4 KiB文件页
    → 如果内核为它建立新的驻留映射，RSS通常增加1个基页

再次访问同一页
    → 已有映射，RSS不再重复增加

512页最终都已映射并保持驻留
    → 这个文件映射对RSS的贡献可以达到约512页，即2 MiB
```

“新增驻留映射通常使 RSS 增加”不等于“每执行一次访问，RSS 必定加一”。Linux 的 fault-around 机制可能在一次缺页处理中顺便映射附近
已经准备好的多个文件页，所以一次访问有时会让 RSS 增加多页；反过来，预读
只把页面放入文件缓存、尚未映射进当前进程页表时，也不等于已经计入该进程
RSS。

> **[SOURCE]** 本地 Linux `248951ddc14d`：
> [mm/mmap.c](./2.源码/linux/mm/mmap.c) 第 1359～1369 行的
> `vm_stat_account()` 按 VMA 页数更新 `total_vm`；
> [include/linux/mm.h](./2.源码/linux/include/linux/mm.h) 第 3392～3403 行将
> RSS 定义为驻留匿名页、文件页和共享内存页计数之和；
> [Documentation/filesystems/proc.rst](./2.源码/linux/Documentation/filesystems/proc.rst)
> 第 259～262 行给出 `VmRSS`、`RssAnon`、`RssFile` 与 `RssShmem` 的关系；
> [mm/memory.c](./2.源码/linux/mm/memory.c) 第 5775～5815 行说明
> fault-around 会尝试映射缺页地址附近的多个页面，
> [mm/filemap.c](./2.源码/linux/mm/filemap.c) 第 3884～3980 行在映射文件页后
> 按实际映射页数更新 RSS 计数。

软硬件边界如下：MMU 不读取 `mm_struct`。Linux 通过 `mm_struct` 查找 VMA、管理页表并准备 TTBR；进行地址翻译时，MMU 读取的是 TTBR 指向的页表。

> **[SOURCE]** 本地 Linux `248951ddc14d`：[include/linux/mm_types.h](./2.源码/linux/include/linux/mm_types.h) 第 1160～1305 行定义上述核心成员；其中第 1215～1221 行是页表开销、VMA 数量和页表锁，第 1265～1273 行是虚拟内存统计，第 1289～1305 行是程序布局、RSS 与架构上下文。

#### 2.2.2 共享 `mm_struct` 后，内存属于哪个线程

对象关系如下：多个线程各有自己的 `task_struct`，但它们的 `task->mm`
可以指向同一个 `mm_struct`，因而看到同一组 VMA 和同一套用户页表。

```text
线程A ──┐
        ├──→ 同一个mm_struct
线程B ──┘         │
                  ├── 同一个mm_mt
                  ├── 同一个pgd和ASID
                  └── 同一套用户页表

线程A访问VA 0x600000 ─┐
                      ├──→ 同一个PTE → 同一个PFN
线程B访问VA 0x600000 ─┘
```

页表项没有“属于哪个线程”的字段。同一地址空间中的线程使用相同 ASID，因此只要 VA 和页面权限相同，就会得到相同的地址翻译。

对于堆内存，内核通常也不记录“这个内存块属于线程 A”：

```text
线程A调用malloc() → 返回0x601000
线程B调用malloc() → 返回0x602000

Linux内核看到：
mm_struct
└── 堆或匿名映射VMA
    ├── 0x601000所在的虚拟页和PTE
    └── 0x602000所在的虚拟页和PTE
```

哪个块已经分配、块大小是多少等信息主要由用户态 `malloc()` 分配器管理。线程 A 得到的指针也可以传给线程 B 使用，常见分配器通常也允许线程 B 在正确同步后释放它；这是一种程序和分配器的逻辑归属，不是 MMU 强制的访问所有权。

用户栈有所不同：每个线程通常使用不同的虚拟地址范围，并保存自己的用户 SP，但这些栈仍位于同一个 `mm_struct` 中：

```text
共同的mm_struct和用户页表
│
├── 线程A栈VMA
│      A的用户SP → 0x7fffffffd000
│
├── 线程B栈VMA
│      B的用户SP → 0x7ffffeffd000
│
└── 共享的代码、全局数据、堆和动态库映射
```

调度器恢复某个线程时，会恢复该线程自己的用户寄存器现场和 SP。但“各自使用不同栈”不等于页表隔离：线程 A 如果知道线程 B 栈中的地址，并且页面权限允许，原则上仍然可以访问。

因此本节结论是：

```text
代码、全局数据、堆、VMA和用户页表   	→ 地址空间内共享
用户SP、用户栈范围和寄存器现场      	→ 每个线程分别使用
内存块由哪个线程申请               	→ 内核通常不区分
```

> **[BOUNDARY]** `malloc()` 的 arena（分配区）、线程缓存、跨线程释放等分配器内部机制留到用户态内存申请阶段，已登记在 [待补充的知识点](./待补充的知识点.md)。

> **[SOURCE]** 本地 Linux `248951ddc14d`：[kernel/fork.c](./2.源码/linux/kernel/fork.c) 第 1568～1601 行说明 `mm_struct` 的共享；[arch/arm64/kernel/process.c](./2.源码/linux/arch/arm64/kernel/process.c) 第 413～452 行设置新任务的用户 SP。

#### 2.2.3 `mm_users` 与 `mm_count` 为什么是两个计数

这两个计数管理的层次不同：

```text
mm_users
  └─ 有多少真实用户或临时使用者正在使用这套用户地址空间

mm_count
  └─ mm_struct这个内核对象本身还有多少底层引用
```

`mm_users` 整体只占 `mm_count` 中的一个引用，并非每个 `mm_users` 都对应一个 `mm_count`：

```text
两个线程共享地址空间：

mm_users = 2
mm_count = 至少包含“这组真实用户”对应的1个引用
           还可能包含其他内核引用
```

相应的引用接口是：

```text
mmget()  / mmput()  → 操作mm_users
mmgrab() / mmdrop() → 操作mm_count
```

当 `mm_users` 降为 0 时，Linux 可以拆除用户映射；只有 `mm_count` 也降为 0 时，`mm_struct` 对象本身才能最终释放。

> **[SOURCE]** 本地 Linux `248951ddc14d`：`include/linux/mm_types.h:1168-1177,1200-1208`；`include/linux/sched/mm.h:26-55,115-142`。

#### 2.2.4 新地址空间是如何初始化的

`mm_init()` 的主线可以压缩为：

```text
初始化mm_mt和mmap_lock关系
          ↓
设置mm_users、mm_count
          ↓
mm_alloc_pgd()分配根页表
          ↓
init_new_context()初始化架构上下文
```

对应源码中的关键语句是：

```c
mt_init_flags(&mm->mm_mt, MM_MT_FLAGS);
mt_set_external_lock(&mm->mm_mt, &mm->mmap_lock);
atomic_set(&mm->mm_users, 1);
atomic_set(&mm->mm_count, 1);

if (mm_alloc_pgd(mm))
    goto fail_mm_init;

if (init_new_context(p, mm))
    goto fail_nocontext;
```

其中 `mm_alloc_pgd()` 最终执行：

```c
mm->pgd = pgd_alloc(mm);
```

> **[SOURCE]** 本地 Linux `248951ddc14d`：`kernel/fork.c:580-590,1085-1132`。

### 2.3 VMA：Linux 如何描述一段虚拟地址

VMA（Virtual Memory Area，虚拟内存区域）对应 `struct vm_area_struct`。一个 VMA 描述 `mm_struct` 中一段连续虚拟地址的使用规则。

#### 2.3.1 为什么已经有页表，还需要 VMA

页表主要回答：

```text
这个虚拟页当前映射到哪个物理页？
```

但当 PTE 不存在或无效时，仅靠页表无法回答：

```text
这个VA是否属于合法区域？
允许读、写还是执行？
页面应该新建，还是从文件读取？
应该私有复制，还是与其他进程共享？
这是普通内存，还是驱动提供的特殊映射？
```

这些软件规则由 VMA 保存。因此：

```text
VMA：描述“应该怎样”
PTE：描述“当前怎样”
```

#### 2.3.2 `vm_area_struct` 的核心成员

本地源码明确规定，一个 VMA 覆盖半开区间 `[vm_start, vm_end)`：

```text
vm_start <= 合法地址 < vm_end
```

核心成员可以简化为：

```c
struct vm_area_struct {
    unsigned long vm_start;
    unsigned long vm_end;
    struct mm_struct *vm_mm;
    pgprot_t vm_page_prot;
    vm_flags_t vm_flags;
    struct anon_vma *anon_vma;
    const struct vm_operations_struct *vm_ops;
    unsigned long vm_pgoff;
    struct file *vm_file;
    void *vm_private_data;
};
```

| 成员                     | 含义                                               |
| ------------------------ | -------------------------------------------------- |
| `vm_start`、`vm_end` | VMA 覆盖的虚拟地址半开区间                         |
| `vm_mm`                | 该 VMA 属于哪个`mm_struct`                       |
| `vm_flags`             | 读、写、执行、共享、向下增长、特殊映射等软件属性   |
| `vm_page_prot`         | 建立页表映射时使用的页保护属性                     |
| `vm_file`              | 文件映射背后的文件；普通私有匿名映射通常为`NULL` |
| `vm_pgoff`             | VMA 起点在后端对象中的页偏移                       |
| `anon_vma`             | 匿名内存反向映射和 COW 相关管理对象                |
| `vm_ops`               | 打开、关闭、缺页等 VMA 回调                        |
| `vm_private_data`      | 文件系统或驱动附加的私有数据                       |

`vm_flags` 中最直观的标志包括：

```text
VM_READ      允许读
VM_WRITE     允许写
VM_EXEC      允许执行
VM_SHARED    共享映射
VM_GROWSDOWN 可向低地址增长，常见于栈
VM_PFNMAP    直接管理PFN类特殊映射
VM_MIXEDMAP  允许混合类型页面的特殊映射
```

> **[SOURCE]** 本地 Linux `248951ddc14d`：`include/linux/mm_types.h:920-984`；`include/linux/mm.h:398-440`。

#### 2.3.3 匿名、文件、Private、Shared 是两组不同概念

“匿名还是文件”说明页面内容来自哪里：

```text
匿名映射
  ├─ 常见于堆、栈、MAP_ANONYMOUS
  └─ 首次使用时通常获得零填充页面

文件映射
  ├─ 可执行文件、动态库、普通文件mmap
  └─ 页面内容通常来自文件及Page Cache
```

“Private 还是 Shared”说明修改如何传播：

```text
MAP_PRIVATE
  ├─ 读取时可以暂时复用原页面
  └─ 写入仍在共享的页面时，必要时通过COW形成当前地址空间的私有页面

MAP_SHARED
  └─ 多个地址空间可以观察到对共享后端页面的修改
```

例如，同一个可执行文件代码段可以是“文件映射 + Private”，一个进程间共享内存区域可以是“匿名来源 + Shared”。这两组概念不能混为一谈。

以两个进程分别使用 `MAP_PRIVATE` 映射同一个普通文件页为例，写入前可以是：

```text
进程A的PTE ──只读──┐
                   ├──→ Page Cache中的文件页：PFN 100
进程B的PTE ──只读──┘
```

进程 A 第一次写入该页时：

```text
PTE不允许写，产生写权限异常
              │
              ▼
VMA允许写，但映射属于MAP_PRIVATE
              │
              ▼
分配私有页PFN 900，并复制PFN 100的内容
              │
              ▼
进程A的PTE改为可写，并指向PFN 900
              │
              ▼
重新执行写入指令
```

写入后：

```text
进程A的PTE ──可写──→ PFN 900（私有副本）
进程B的PTE ──只读──→ PFN 100（原文件页）
Page Cache           → PFN 100（原文件内容）
```

因此，进程 A 的修改只进入自己的私有副本；原文件以及继续使用原文件页的其他地址空间都看不到这次修改。

这里的“当前地址空间”是当前 `mm_struct` 所管理的地址空间，不是“当前线程”。共享同一个 `mm_struct` 的线程使用同一套页表，因此都能看到这个私有页面中的修改。私有是相对于其他地址空间而言的。

COW 通常按页发生。以 4 KiB 基础页为例，只写一个页面时，通常只处理这个页面，不会复制整个 VMA。`fork()` 后父子地址空间共享页面，是另一种常见的 COW 场景：

```text
开始时：父子进程只读共享同一个物理页
                     │
某一方写入           ▼
              产生写权限异常
                     │
                     ▼
             复制出新的物理页
                     │
                     ▼
             修改当前进程的PTE
```

本地源码用 `is_cow_mapping()` 判断“可写但非共享”的映射，并在复制页表时将父子双方对应的可写 PTE 改成只读，为后续 COW 做准备。发生写保护异常后，私有映射可以复用已经独占的匿名页；不能复用时才复制页面并更新 PTE。

> **[BOUNDARY]** 这里仅说明 COW 的可见性和按页语义；写保护异常、物理页复制和 PTE 更新的完整路径留到后续 Page Fault 阶段。

> **[SOURCE]** 本地 Linux `248951ddc14d`：`include/linux/mm.h:2238-2248`；`mm/memory.c:1097-1112,3853-3925,4244-4336`。

#### 2.3.4 一个 VMA 可以对应很多 PTE

`vm_area_struct` 不保存逐个虚拟页对应的 PTE 或 PFN，也没有一个“本 VMA 的 PTE 数组”。它只描述一段虚拟地址范围的共同规则；真正的逐页翻译状态保存在 `mm->pgd` 所指向的多级页表中。

下面始终使用同一个例子。假设进程有一个 16 KiB 匿名 VMA：

```text
VMA：[0x600000, 0x604000)
权限：可读、可写
后端：匿名内存
```

这个 VMA 的长度为 `0x4000`，在 4 KiB 页面下可以计算出四个虚拟页：

```text
0x604000 - 0x600000 = 0x4000 = 16 KiB
16 KiB ÷ 4 KiB = 4个虚拟页

0x600000～0x600FFF → 第1个4 KiB虚拟页
0x601000～0x601FFF → 第2个4 KiB虚拟页
0x602000～0x602FFF → 第3个4 KiB虚拟页
0x603000～0x603FFF → 第4个4 KiB虚拟页
```

这四行不是存放在 VMA 中的四条记录，而是由 VMA 范围和页面大小计算出来的。现在固定观察某一个时刻，并在本小节后续始终沿用以下状态：

```text
第1页：已经访问并驻留，映射到PFN 100
第2页：尚未建立有效映射
第3页：已经访问并驻留，映射到PFN 900
第4页：曾经驻留，后来被换出
```

此时的完整结构关系是：

```text
mm_struct
   │
   ├─ mm_mt
   │    └─ VMA：[0x600000, 0x604000)，RW，匿名
   │
   └─ pgd
        └─ 多级页表
             ├─ VA页0x600000 → PTE → PFN 100
             ├─ VA页0x601000 → PTE无效
             ├─ VA页0x602000 → PTE → PFN 900
             └─ VA页0x603000 → 非Present PTE中的Swap Entry
```

把 VMA 覆盖的四个虚拟页与同一时刻的页表状态逐项对齐：

| VMA 中的虚拟地址范围   | 虚拟页基地址 | 页表中的当前状态                |
| ---------------------- | ------------ | ------------------------------- |
| `0x600000～0x600FFF` | `0x600000` | 有效 PTE，指向 PFN 100          |
| `0x601000～0x601FFF` | `0x601000` | PTE 无效，当前没有驻留映射      |
| `0x602000～0x602FFF` | `0x602000` | 有效 PTE，指向 PFN 900          |
| `0x603000～0x603FFF` | `0x603000` | 非 Present PTE，保存 Swap Entry |

`mm_mt` 中仍然只有一个 VMA，而且这个 VMA 自身不保存表格右侧的状态。右侧状态来自页表，可以逐页不同。因此，“一个 VMA 对应很多 PTE”只表示这些 PTE 所服务的 VA 都落在该 VMA 范围内，不表示 VMA 持有指向这些 PTE 的列表。

由此可见：

```text
存在VMA ≠ 已经存在有效PTE
存在VMA ≠ 已经分配物理页
```

> **[BOUNDARY]** 本节只用 Swap Entry 表示“该页已经换出”，不展开它的编码、换出和换入过程；这些细节留到后续 Page Fault 阶段。

> **[SOURCE]** 本地 Linux `248951ddc14d`：`include/linux/mm_types.h:920-984,1177-1187` 分别定义 VMA 范围以及 `mm_mt`、`pgd`；`arch/arm64/include/asm/pgtable.h:114-136` 从 PTE 提取物理地址和 PFN。

#### 2.3.5 `mm_mt` 如何管理和查找 VMA

现代 Linux 使用 `mm->mm_mt` 这棵 Maple Tree 按虚拟地址管理 VMA：

```text
mm_struct
   │
   └── mm_mt
        ├── VMA：[0x400000, 0x410000)
        ├── VMA：[0x600000, 0x680000)
        └── VMA：[0x7FFF0000, 0x80000000)
```

本地 `find_vma()` 的核心实现是：

```c
struct vm_area_struct *find_vma(struct mm_struct *mm, unsigned long addr)
{
    unsigned long index = addr;

    mmap_assert_locked(mm);
    return mt_find(&mm->mm_mt, &index, ULONG_MAX);
}
```

一个容易忽略的细节是：`find_vma(mm, addr)` 返回“包含 `addr` 的 VMA，或者位于它后面的第一个 VMA”。因此还要检查：

```c
if (!vma || addr < vma->vm_start)
    /* addr不在普通VMA中 */
```

查找和读取地址空间结构通常需要持有 `mmap_lock` 的读锁；创建、删除、拆分或合并 VMA 通常需要写锁。新内核还提供更细粒度的单 VMA 锁优化，但 VMA 仍是受同步保护的软件对象。

> **[SOURCE]** 本地 Linux `248951ddc14d`：`include/linux/mm_types.h:1177,1235`；`mm/mmap.c:896-908`。

#### 2.3.6 哪些操作会创建或改变 VMA

常见接口与 VMA 的关系是：

| 接口           | 对地址空间的主要影响                                                     |
| -------------- | ------------------------------------------------------------------------ |
| `mmap()`     | 创建文件映射或匿名映射，必要时与相邻兼容 VMA 合并                        |
| `munmap()`   | 删除指定范围，可能先把一个 VMA 拆成几段                                  |
| `mprotect()` | 修改权限；只修改部分范围时可能拆分 VMA                                   |
| `brk()`      | 调整进程堆的结束位置和相关 VMA                                           |
| `malloc()`   | C 库接口，可能在底层使用`brk()` 或 `mmap()`，不是 Linux 内核系统调用 |

例如，只修改一个 VMA 中间 4 KiB 的权限：

```text
修改前：
[--------------- RW ---------------]

mprotect()只把中间一页改为只读

修改后：
[------ RW ------][-- R --][------ RW ------]
       VMA 1       VMA 2       VMA 3
```

反过来，如果两个相邻 VMA 的权限、后端对象、偏移关系等都兼容，Linux 可以把它们合并，以减少 VMA 数量。

`mmap()` 成功首先表示虚拟地址范围和规则已经建立，并不保证所有物理页已经立即准备完成。

> **[SOURCE]** 本地 Linux `248951ddc14d`：`mm/mmap.c:116-205` 的 `brk`，`mm/mmap.c:280-340` 的 `do_mmap()`，`mm/mmap.c:613-618` 的 `mmap_pgoff`，`mm/mmap.c:1062-1079` 的 `munmap`；`mm/mprotect.c:836-988`；`mm/vma.c:495-600` 的 VMA 拆分实现。

#### 2.3.7 VMA 如何参与 Page Fault

当 ARM64 把一次用户访问异常交给 Linux 后，处理路径会先确定异常地址是否属于合法 VMA，再进入通用缺页处理。下面只摘出源码主线，省略解锁和错误码等细节：

```c
vma = lock_mm_and_find_vma(mm, addr, regs);
if (unlikely(!vma))
    goto bad_area;

if (!(vma->vm_flags & vm_flags))
    goto bad_area;

fault = handle_mm_fault(vma, addr, mm_flags, regs);
```

把它翻译成概念流程：

```text
MMU报告地址访问异常
          │
          ▼
Linux根据异常VA查找VMA
          │
          ├─ 找不到VMA
          │     └─ 地址不合法，通常向进程发送SIGSEGV
          │
          ├─ 找到VMA但权限不匹配
          │     └─ 访问不合法，通常向进程发送SIGSEGV
          │
          └─ VMA存在且权限允许
                └─ handle_mm_fault()准备页面并处理页表
```

具体看一次匿名堆页面首次写入。假设页面大小为 4 KiB，程序执行：

```c
*(int *)0x601234 = 10;
```

虚拟地址可以拆成：

```text
VA 0x601234
   ├─ 虚拟页基地址 = 0x601000
   └─ 页内offset   = 0x234
```

为了演示，假设缺页处理最终为它分配到十进制 `PFN 900`：

```text
CPU写VA 0x601234
        │
        ▼
MMU查询TLB和页表
        │
        ▼
VA页0x601000对应的PTE无效
        │
        ▼
MMU触发Translation Fault
CPU进入Linux异常处理
        │
        ▼
Linux使用current->mm查找mm_mt
        │
        ▼
找到堆VMA：[0x600000, 0x620000)
        │
        ├─ 0x601234位于该范围内
        └─ VMA允许写入
        │
        ▼
handle_mm_fault()进入合法缺页处理
为匿名堆页准备物理页：PFN 900
        │
        ▼
建立PTE：VA页0x601000 → PFN 900，可读写、有效
        │
        ▼
返回用户态，重新执行刚才的写指令
        │
        ▼
页内offset保持0x234
最终PA = 900 × 0x1000 + 0x234
       = 0x384234
```

这里的职责边界是：MMU 只读取 TLB 和页表，并在翻译失败时报告异常；Linux 才会通过 `current->mm->mm_mt` 判断地址是否合法，并根据 VMA 规则决定如何处理。

> **[BOUNDARY]** 上例只表示“匿名堆页面首次写入”。文件映射可能从文件或 Page Cache 获得页面，COW 可能复制共享页，换出页面可能需要从交换空间读回；这些分支以及物理页分配、`struct page` 和 PTE 更新细节留到后续 Page Fault 章节。

因此，Page Fault 不等于程序一定出错。它可能只是“VMA 允许访问，但对应 PTE 和物理页尚未准备好”；VMA 合法与 PTE 已经就绪是两件不同的事。

> **[SOURCE]** 本地 Linux `248951ddc14d`：[arch/arm64/mm/fault.c](./2.源码/linux/arch/arm64/mm/fault.c) 第 729～751 行；`mm/mmap_lock.c:496-550`；`mm/memory.c:6417-6425,6651-6716`。

#### 2.3.8 驱动映射为什么也需要 VMA

> **[BOUNDARY]** 本小节只讨论驱动如何把对象映射到进程的 CPU 用户虚拟地址空间；GPU 侧页表映射留到后续 GPU 内存阶段。

用户程序可能通过设备文件请求映射一个驱动对象：

```c
void *ptr = mmap(NULL, size, prot, flags, driver_fd, offset);
```

驱动没有重新实现一套 `mmap()` 系统调用。调用关系是：

```text
用户程序调用Linux mmap()
          │
          ▼
Linux在当前进程的mm_struct中准备VMA
          │
          ▼
Linux调用设备文件的file_operations->mmap()
          │
          ▼
驱动配置Linux传入的VMA
```

例如，驱动管理着一个 16 KiB 缓冲区对象。用户映射成功后，可能得到：

```text
进程CPU虚拟地址：[0x700000, 0x704000)

mm_struct
   │
   ├─ mm_mt
   │    └─ 驱动VMA：[0x700000, 0x704000)
   │         vm_private_data → 驱动缓冲区对象
   │         vm_ops->fault   → 驱动缺页回调
   │
   └─ pgd
        └─ 保存CPU VA到后端页面的实际映射
```

其中：

```text
vm_private_data
  → 说明这段VMA关联的是哪个驱动对象

vm_ops->fault
  → CPU访问尚无有效PTE的页面时，让驱动参与处理
```

通用 Linux 内存管理代码只知道“某个 CPU 虚拟地址发生了异常”，但它不知道：

```text
这是驱动中的哪个缓冲区对象？
故障地址对应对象中的第几个页面？
这个页面当前位于什么存储位置？
用户是否有权访问？
应该映射普通struct page，还是特殊PFN？
```

这些信息由驱动掌握，因此 VMA 需要把地址范围、驱动对象和缺页回调关联起来。

假设用户访问：

```c
value = *(int *)0x702123;
```

如果虚拟页 `0x702000` 还没有有效 PTE，处理过程可以是：

```text
CPU访问VA 0x702123
          │
          ▼
PTE无效，产生缺页异常
          │
          ▼
Linux通过mm_mt找到驱动VMA
          │
          ▼
通过vm_private_data找到驱动缓冲区对象
          │
          ▼
调用vm_ops->fault
          │
          ▼
驱动计算：
0x702000是该VMA中的第3个虚拟页
          │
          ▼
驱动找到缓冲区对象的第3个后端页面
          │
          ▼
调用内核插页接口，把page或PFN安装进CPU进程页表
          │
          ▼
返回用户态，重新执行访问指令
```

驱动建立 CPU 页表映射时，常见思路有两种。

第一种是在 `mmap()` 阶段一次性建立一段映射。假设驱动知道一段从物理地址 `0x80000000` 开始的内存，希望把它映射到前面的 16 KiB 用户 VMA，可以简化为：

```c
static int my_mmap(struct file *filp,
                   struct vm_area_struct *vma)
{
    phys_addr_t phys = 0x80000000;
    unsigned long size;

    size = vma->vm_end - vma->vm_start;

    return remap_pfn_range(vma,
                           vma->vm_start,
                           phys >> PAGE_SHIFT,
                           size,
                           vma->vm_page_prot);
}
```

这里固定使用 4 KiB 页面，因此传给 `remap_pfn_range()` 的起始 PFN 是：

```text
0x80000000 >> 12 = PFN 0x80000
```

假设 `mmap()` 返回的用户地址是 `0x700000`，映射完成后的主要关系是：

```text
用户VA页                 CPU页表                  物理页

0x700000 ─────────────→ PTE ─────────────→ PFN 0x80000 → PA 0x80000000
0x701000 ─────────────→ PTE ─────────────→ PFN 0x80001 → PA 0x80001000
0x702000 ─────────────→ PTE ─────────────→ PFN 0x80002 → PA 0x80002000
0x703000 ─────────────→ PTE ─────────────→ PFN 0x80003 → PA 0x80003000
```

之后用户程序执行：

```c
*(volatile uint32_t *)addr = 0x1234;
```

如果 `addr` 是 `0x700000`，这次 CPU 写入最终到达物理地址 `0x80000000`；访问 `addr + offset`，则到达对应的 `0x80000000 + offset`。因为 PTE 已在 `mmap()` 阶段建立，后续普通访问通常不需要再通过驱动的 `fault` 回调逐页插入。

> **[BOUNDARY]** 该代码只展示 `remap_pfn_range()` 的核心映射关系，假设物理地址已经按页对齐，而且请求长度合法。真实驱动还必须检查这段物理范围确实归驱动管理、映射没有越界，并设置正确的缓存和访问属性，不能把用户给出的任意物理地址直接映射出去。

第二种是先只建立 VMA，等 CPU 真正访问时再逐页映射：

```text
mmap()完成时：
VMA已经存在，但相关PTE暂时无效

CPU首次访问某页时：
进入驱动fault回调
→ 找到该页的后端page或PFN
→ 调用内核接口安装当前页面的PTE
```

这里要区分“选择后端页面”和“写入页表”两个职责：

```text
普通匿名VMA发生缺页
→ Linux内存管理核心选择匿名页并安装PTE
→ 不需要驱动提供vm_ops->fault

驱动VMA发生缺页
→ 驱动的vm_ops->fault决定使用哪个page或PFN
→ 内核插页接口按照页表锁、属性和记账规则安装PTE
```

因此，驱动的 `fault` 回调负责解释驱动对象并选择后端页面，通常不直接取得 `pte_t *` 随意修改页表。驱动已经持有普通 `struct page` 时，可以使用 `vmf_insert_page()` 一类接口；驱动只有 PFN，或者处理特殊设备内存时，可以使用 `vmf_insert_pfn()` 一类接口。具体使用限制以及 GEM、TTM 中的实际处理留到后续驱动映射阶段。

> **[SOURCE]** 本地 Linux `248951ddc14d`：`include/linux/fs.h:1921-1935` 定义设备文件的 `mmap` 回调；`mm/internal.h:155-172`、`mm/vma.c:2483-2504` 展示 Linux 调用文件映射钩子的路径；`include/linux/mm_types.h:920-984` 定义 VMA 核心字段；`include/linux/mm.h:783-833,4532-4533,4547-4565` 定义 VMA 操作、`remap_pfn_range()` 和插页接口；`mm/memory.c:2754-2806,3152-3225` 实现按 PFN 插入和范围映射的主要入口，第 5250～5360 行展示普通匿名页由内存管理核心准备并安装 PTE。

### 2.4 从 `mm->pgd` 到 `TTBR0_EL1`

这一过程要分成两个不同阶段：

```text
创建地址空间
→ 为mm_struct分配根页表

把地址空间切换到某个CPU
→ 将根页表的物理地址配置给MMU
```

首先看创建阶段。每个拥有独立用户地址空间的 `mm_struct` 都需要一个用户根页表。Linux 分配并初始化根页表后，把返回的 C 指针保存在 `mm->pgd`：

```c
static inline int mm_alloc_pgd(struct mm_struct *mm)
{
    mm->pgd = pgd_alloc(mm);
    if (unlikely(!mm->pgd))
        return -ENOMEM;
    return 0;
}
```

这里：

```text
pgd_alloc(mm)
  → 分配并初始化该地址空间的根页表

mm->pgd
  → 保存根页表的内核虚拟地址
```

`mm->pgd` 指向的是页表自身使用的内存，不是程序的数据页；此时也不代表这套页表已经被某个 CPU 使用。

同一张根页表可以从两个角度表示：

```text
Linux内核访问它时：
使用内核虚拟地址mm->pgd

MMU进行页表遍历时：
使用根页表的物理地址
```

这两种地址指向同一块根页表内存：

```text
mm->pgd
内核虚拟地址
      │
      │ 指向同一块页表内存
      ▼
根页表
      ▲
      │
根页表物理地址
```

当调度器需要让某个地址空间在当前 CPU 上运行时，ARM64 的 `cpu_switch_mm()` 接收该地址空间的 `pgd`，并使用 `virt_to_phys()` 得到根页表物理地址：

```c
static inline void cpu_switch_mm(pgd_t *pgd, struct mm_struct *mm)
{
    cpu_do_switch_mm(virt_to_phys(pgd), mm);
}
```

`cpu_do_switch_mm()` 再把物理地址转换成 TTBR 所需的编码形式，并写入 `TTBR0_EL1`：

```c
void cpu_do_switch_mm(phys_addr_t pgd_phys, struct mm_struct *mm)
{
    unsigned long ttbr0 = phys_to_ttbr(pgd_phys);

    /* 此处省略ASID和其他架构、安全配置处理 */

    write_sysreg(ttbr0, ttbr0_el1);
    isb();
}
```

之所以不能把 `mm->pgd` 直接写入 `TTBR0_EL1`，是因为：

```text
mm->pgd
  → Linux内核使用的虚拟地址

TTBR0_EL1.BADDR
  → MMU开始页表遍历时使用的根页表物理地址
```

MMU 必须先找到根页表，才能开始进行虚拟地址翻译，因此根页表入口本身不能依赖这次尚未开始的用户虚拟地址翻译。

把两个阶段连起来，完整主线是：

```text
创建mm_struct
      │
      ▼
pgd_alloc(mm)
      │
      ▼
mm->pgd保存根页表的内核虚拟地址
      │
      │ 该地址空间被切换到某个CPU
      ▼
cpu_switch_mm(mm->pgd, mm)
      │
      ▼
virt_to_phys(mm->pgd)
      │
      ▼
根页表物理地址
      │
      ▼
phys_to_ttbr()
      │
      ▼
写入TTBR0_EL1
      │
      ▼
MMU从根页表开始遍历
```

所以需要区分：

```text
pgd_alloc()
→ 创建该mm_struct的根页表

cpu_switch_mm()
→ 让当前CPU开始使用该地址空间

TTBR0_EL1
→ 当前CPU供MMU进行用户地址翻译的硬件入口
```

> **[BOUNDARY]** 本小节只追踪根页表基地址。ASID 如何区分不同地址空间的 TLB 记录，将在 2.7 节介绍。

> **[SOURCE]** 本地 Linux `248951ddc14d`：`kernel/fork.c:578-587` 分配并保存 `mm->pgd`；`arch/arm64/include/asm/mmu_context.h:56-62` 将 `pgd` 从内核虚拟地址转换为物理地址；`arch/arm64/mm/context.c:349-371` 构造并写入 `TTBR0_EL1`。

### 2.5 TLB：缓存地址翻译结果

如果每次 load/store 都重新读取四级页表，代价会很大。因此 CPU 使用 TLB 缓存最近的地址翻译结果。

```text
没有TLB缓存：
VA → L0 → L1 → L2 → L3 → PA

TLB命中：
VA → TLB → PA
```

#### 2.5.1 TLB entry 的逻辑格式

> [BOUNDARY] Arm 架构规定 TLB 必须表现出的地址翻译和维护行为，但不规定每款 CPU 内部 TLB 存储阵列的真实位布局、组相联方式或层级数量。Linux 也不能像遍历页表一样，通过普通指针读取每条 TLB entry。下图只是行为模型，不是某款 CPU 的二进制格式。

为了学习，可以把一条 Stage 1 用户地址翻译抽象成：

```text
TLB entry（概念结构，不是固定硬件位布局）

┌─────────────────────────────────────────┐
│ Tag：用于判断是否命中                   │
│ ├─ Translation regime：哪套翻译制度     │
│ ├─ VA Tag / VPN：虚拟页或虚拟块编号     │
│ ├─ ASID：非全局映射所属地址空间         │
│ └─ Global / non-Global状态              │
├─────────────────────────────────────────┤
│ Data：命中后使用的翻译结果               │
│ ├─ 输出物理页或物理块基地址             │
│ ├─ 映射大小：4 KiB、2 MiB、1 GiB等      │
│ ├─ 读、写、执行权限                     │
│ └─ 内存类型、共享属性等                 │
└─────────────────────────────────────────┘
```

例如，可以概念性地表示为：

```text
Tag:
  ASID = 42
  VPN  = 0x400

Data:
  PFN       = 0x12345
  page size = 4 KiB
  permission= Read/Write、不可执行
  memory    = Normal Cacheable
```

它表示：

```text
ASID 42中的虚拟页0x400 → 物理页框0x12345
```

页内 offset 不需要参与这项映射替换，仍然从原 VA 原样进入最终 PA。

#### 2.5.2 TLB entry 不等于原始 PTE 的逐位副本

TLB 缓存的是 CPU 完成访问检查所需的翻译信息。它可能来自：

```text
Level 1 Block descriptor → 1 GiB翻译
Level 2 Block descriptor → 2 MiB翻译
Level 3 Page descriptor  → 4 KiB翻译
```

CPU 还可能缓存页表遍历过程中的中间信息，通常称为 translation table walk cache。它们的具体组织同样属于微架构实现，而不是 Linux 可直接读取的统一 C 结构体。

### 2.6 TLB Hit、TLB Miss 与 Translation Fault

一次用户访问可以分成三种结果：

```text
CPU产生VA
   │
   ▼
用VA Tag和ASID等信息查询TLB
   │
   ├─ TLB Hit
   │    └─ 检查缓存的权限和属性，形成PA
   │
   └─ TLB Miss
        │
        ▼
     MMU硬件遍历页表
        │
        ├─ 找到有效叶子descriptor
        │    └─ 得到翻译结果、填充TLB、继续执行
        │
        └─ descriptor无效或访问不被允许
             └─ 产生相应的地址翻译或权限异常
```

两者的区别是：

```text
TLB Miss ≠ Page Fault
```

TLB Miss 只是“缓存中没有结果”，属于正常硬件路径。如果页表中存在有效映射，MMU 完成 table walk 后就能继续执行，Linux 不会因为普通 TLB Miss 而进入异常处理。

只有页表遍历或访问检查失败，CPU 才会进入 Linux 的异常入口。Translation Fault 是其中一种原因，权限异常、Access Flag 异常等是其他可能原因。

### 2.7 ASID：区分不同地址空间的 TLB 记录

假设两个进程都访问 `VA 0x4000`：

```text
进程A：VA 0x4000 → PFN 100
进程B：VA 0x4000 → PFN 900
```

如果 TLB 只用虚拟页号作为 Tag，就无法区分这两条记录。ASID（Address Space Identifier，地址空间标识符）为非全局 TLB 翻译增加地址空间身份：

```text
ASID 10 + VPN 0x4 → PFN 100
ASID 20 + VPN 0x4 → PFN 900
```

#### 2.7.1 ASID 属于 `mm_struct`，不是简单属于 PID

```text
线程A ─┐
       ├──→ 同一个mm_struct ──→ 同一个地址空间ASID
线程B ─┘
```

ARM64 的 `mm_context_t` 被嵌入 `mm_struct.context`，其中 `id` 保存 Linux 管理的上下文编号：

```c
typedef struct {
    atomic64_t id;
    refcount_t pinned;
    /* 其他架构状态省略 */
} mm_context_t;

#define ASID(mm) (atomic64_read(&(mm)->context.id) & 0xffff)
```

因此 ASID 与地址空间生命周期绑定；线程共享 `mm_struct` 时，也共享这套 ASID 上下文。

> **[SOURCE]** 本地 Linux `248951ddc14d`：`include/linux/mm_types.h:1302-1305`；[arch/arm64/include/asm/mmu.h](./2.源码/linux/arch/arm64/include/asm/mmu.h) 第 19～28、56 行。

#### 2.7.2 用户映射通常 `nG = 1`，内核映射通常 `nG = 0`

`nG` 是 not Global（非全局）的缩写。`nG = 1` 表示这是一条 non-Global 翻译；它进入 TLB 后与当前 ASID 关联，只有 ASID 和虚拟页号都匹配时才能命中。普通用户映射通常采用这种方式。

`nG = 0` 表示这是一条 Global 翻译；TLB 匹配该翻译时不要求当前 ASID 相同。所有进程共享的内核地址映射通常采用这种方式。

用户映射需要区分 ASID，是因为相同的用户虚拟地址在不同进程中可能指向不同物理页：

```text
进程A：ASID 10 + VA 0x4000 → PFN 100
进程B：ASID 20 + VA 0x4000 → PFN 900
```

内核地址映射通常由所有进程共享。无论当前运行进程 A 还是进程 B，同一个内核虚拟地址通常都指向同一个物理地址，因此对应的 TLB 记录不需要用 ASID 区分：

```text
进程A运行时：内核VA 0xffff0000 → PFN 500
进程B运行时：内核VA 0xffff0000 → PFN 500
```

`nG = 0` 不表示用户程序可以访问该地址。`nG` 只影响 TLB 是否匹配 ASID；用户态能否访问仍由页表中的访问权限决定。

本地 ARM64 使用 `PTE_NG` 表示 `nG` 位，普通用户页面保护宏包含该标志：

```c
#define PTE_NG (1 << 11)
```

> **[SOURCE]** 本地 Linux `248951ddc14d`：[arch/arm64/include/asm/pgtable-hwdef.h](./2.源码/linux/arch/arm64/include/asm/pgtable-hwdef.h) 第 164～176 行；[arch/arm64/include/asm/pgtable-prot.h](./2.源码/linux/arch/arm64/include/asm/pgtable-prot.h) 第 53～65 行。

> **[BOUNDARY]** ASID 是数量有限的硬件编号，Linux 会在必要时配合 TLB 清理安全复用。本章不展开具体的分配与复用算法。

### 2.8 任务切换时，地址空间和寄存器如何切换

一次任务切换包含两类相关但不同的状态变化：

| 状态类别     | 决定什么                        | 主要对象                            |
| ------------ | ------------------------------- | ----------------------------------- |
| 地址空间状态 | 用户 VA 使用哪套页表和 TLB 记录 | `mm_struct`、PGD、TTBR、ASID      |
| 任务执行现场 | 任务从哪条内核指令继续执行      | 内核寄存器、内核栈、`task_struct` |

调度器先处理地址空间，再调用 `switch_to()` 切换寄存器和内核栈。本节只讨论两个普通用户任务之间的切换；内核线程的 `mm = NULL` 和 `active_mm` 已在 2.1.3 节说明。

> **[SOURCE]** 本地 Linux `248951ddc14d`：[kernel/sched/core.c](./2.源码/linux/kernel/sched/core.c) 第 5471～5513 行先处理地址空间，再调用 `switch_to()`。

#### 2.8.1 任务切换不一定切换地址空间

| 切换对象               | `mm_struct` 的关系    | 地址空间是否需要切换 | 任务执行现场是否需要切换 |
| ---------------------- | ----------------------- | -------------------- | ------------------------ |
| 同一进程中的两个线程   | 共享同一个`mm_struct` | 通常不需要           | 需要                     |
| 两个不同地址空间的进程 | 使用不同的`mm_struct` | 需要                 | 需要                     |

因此，即使两个线程共享全部用户虚拟地址，它们仍有各自的 `task_struct`、内核栈和寄存器现场；调度器仍然需要完成任务切换，只是不必更换用户页表和 ASID。

如果进程 A 和进程 B 使用不同的 `mm_struct`，地址空间切换的主线是：

```text
B->mm->pgd
   │ 转换为根页表物理地址
   ▼
TTBR0_EL1.BADDR ← B的用户根页表

B的地址空间ASID
   ▼
CPU改用B的ASID

执行ISB
   ▼
后续用户地址按照B的地址空间翻译
```

进程 A 的 non-Global TLB 记录可以暂时保留，因为其中带有 A 的 ASID；CPU 改用 B 的 ASID 后，不会把这些记录当成 B 的地址翻译。

> **[SOURCE]** 本地 Linux `248951ddc14d`：[arch/arm64/include/asm/mmu_context.h](./2.源码/linux/arch/arm64/include/asm/mmu_context.h) 第 236～264 行；[arch/arm64/mm/context.c](./2.源码/linux/arch/arm64/mm/context.c) 第 215～270、349～371 行。

#### 2.8.2 按时间顺序看一次完整切换

下面假设 CPU 因定时器中断，从用户态进程 A 切换到另一个地址空间中的进程 B。先明确图中各寄存器的作用：

| 寄存器或状态  | 在本例中的作用                                                           |
| ------------- | ------------------------------------------------------------------------ |
| `x0～x30`   | 用户程序和内核代码使用的通用寄存器                                       |
| `SP_EL0`    | 在 EL0 运行时保存用户栈指针；进入内核后 Linux 可暂时用于保存当前任务指针 |
| `SP_EL1`    | EL1 使用的内核栈指针                                                     |
| `ELR_EL1`   | 保存从异常返回时要继续执行的用户 PC                                      |
| `SPSR_EL1`  | 保存进入异常前的处理器状态 PSTATE                                        |
| LR（`x30`） | 保存内核函数的返回位置，`RET` 使用它返回                               |

用户现场和内核调度现场保存在两个不同位置：

| 保存位置                     | 保存内容                               | 用途                                             |
| ---------------------------- | -------------------------------------- | ------------------------------------------------ |
| A 或 B 内核栈上的`pt_regs` | 用户态`x0～x30`、用户 SP、PC、PSTATE | 将来通过`ERET` 返回该任务的用户态              |
| `task->thread.cpu_context` | 内核态`x19～x29`、SP、LR             | 将来通过`RET` 从该任务在内核中的切换点继续执行 |

`cpu_context` 不需要再保存一份完整的用户寄存器，因为用户现场已经位于 `pt_regs` 中；它只保存恢复内核调用现场所需的寄存器。

```text
                              时间向下
                                  │
T0：进程A在EL0运行                │
──────────────────────────────────┤
地址空间：                        │
  TTBR0_EL1.BADDR = A的用户根页表 │
  当前ASID         = A的ASID      │
寄存器：                          │
  SP_EL0 = A的用户栈指针          │
  SP_EL1 = A的内核栈指针          │
                                  │
                     定时器中断   ▼
                                  │
T1：A进入EL1                      │
──────────────────────────────────┤
硬件：                            │
  ELR_EL1  ← A的用户PC            │
  SPSR_EL1 ← A的用户PSTATE        │
  开始使用A的内核栈               │
Linux异常入口：                   │
  A的pt_regs ← x0～x30、用户SP、PC、PSTATE
  SP_EL0     ← A的task_struct指针 │
                                  │
                     调度器选择B  ▼
                                  │
T2：仍在A的内核栈上，先切换地址空间
──────────────────────────────────┤
  TTBR0_EL1.BADDR ← B的用户根页表 │
  当前ASID         ← B的ASID      │
  执行ISB                         │
                                  │
  此时内核执行现场仍属于A，        │
  但后续用户地址将按B的页表翻译。  │
                                  │
                  cpu_switch_to() ▼
                                  │
T3：切换内核执行现场              │
──────────────────────────────────┤
  A->thread.cpu_context           │
    ← 保存A的x19～x29、SP、LR     │
                                  │
  B->thread.cpu_context           │
    → 恢复B的x19～x29、SP、LR     │
                                  │
  SP      ← B的内核栈指针         │
  SP_EL0  ← B的task_struct指针    │
  RET → B以前在内核中被切走的位置 │
                                  │
                     B准备返回EL0 ▼
                                  │
T4：恢复B的用户现场               │
──────────────────────────────────┤
  x0～x30  ← B的pt_regs           │
  ELR_EL1  ← B的用户PC            │
  SPSR_EL1 ← B的用户PSTATE        │
  SP_EL0   ← B的用户栈指针        │
  ERET → EL0                      │
                                  ▼
进程B从上次停止的位置继续运行
```

这条时间线包含两条不同的切换路径：T2 更换用户地址空间，T3 更换任务的内核寄存器和内核栈。如果 A 和 B 是共享同一个 `mm_struct` 的线程，T2 不需要更换根页表和 ASID，但 T3 仍然必须执行。

> **[BOUNDARY]** 图中只展示普通用户进程之间的主线，不展开安全配置和 `current` 指针恢复等实现分支。

> **[SOURCE]** 本地 Linux `248951ddc14d`：[kernel/sched/core.c](./2.源码/linux/kernel/sched/core.c) 第 5471～5513 行展示地址空间切换先于寄存器和栈切换；[arch/arm64/include/asm/ptrace.h](./2.源码/linux/arch/arm64/include/asm/ptrace.h) 第 152～172 行定义 `pt_regs`；[arch/arm64/include/asm/processor.h](./2.源码/linux/arch/arm64/include/asm/processor.h) 第 136～150 行定义 `cpu_context`；[arch/arm64/kernel/entry.S](./2.源码/linux/arch/arm64/kernel/entry.S) 第 197～224、281～304、335～366、813～848 行保存和恢复异常现场与内核切换现场。

### 2.9 页表修改与 TLB 一致性

页表和 TLB 是两份不同位置的状态。Linux 修改内存中的 PTE，并不会自动让已经缓存的旧 TLB entry 消失。

例如：

```text
修改前：VA 0x4000 → PFN 100

Linux把PTE改成：VA 0x4000 → PFN 900

但旧TLB仍可能保存：VA 0x4000 → PFN 100
```

如果不做 TLB 无效化，CPU 仍可能继续使用旧翻译。因此概念流程是：

```text
更新或清除页表项
        ↓
用DSB保证页表写入达到要求的可见性
        ↓
执行TLBI，使目标TLB翻译失效
        ↓
再用DSB等待无效化完成
        ↓
需要时用ISB同步后续指令执行上下文
```

其中：

```text
DSB  = Data Synchronization Barrier，数据同步屏障
TLBI = Translation Lookaside Buffer Invalidate，TLB无效化操作
ISB  = Instruction Synchronization Barrier，指令同步屏障
```

本地 `local_flush_tlb_all()` 展示了一种完整的本 CPU 清理序列：

```c
static inline void local_flush_tlb_all(void)
{
    dsb(nshst);
    __tlbi(vmalle1);
    dsb(nsh);
    isb();
}
```

Linux 还提供不同粒度的操作：

```text
flush_tlb_page()  → 清理一个页面相关翻译
flush_tlb_range() → 清理一段范围
flush_tlb_mm()    → 清理一个mm/ASID的翻译
flush_tlb_all()   → 清理更广范围的翻译
```

多核情况下，同一进程的不同线程可以同时运行在不同 CPU 上。它们共享同一个 `mm_struct` 和 ASID，但每个 CPU 都可能在自己的 TLB 中缓存该地址空间的翻译。TLB 并不保存 `mm_struct` 指针；这里所说的“同一个 `mm_struct` 的翻译”，是指根据同一套页表得到的 `ASID + VA → PFN` 记录。

沿用前面的例子，修改 PTE 之前可能是：

```text
内存中的页表：
VA 0x4000 → PFN 100

CPU0的TLB：
ASID 10 + VA 0x4000 → PFN 100

CPU1的TLB：
ASID 10 + VA 0x4000 → PFN 100
```

CPU0 把内存中的 PTE 改为 `VA 0x4000 → PFN 900` 后，两个 CPU 的 TLB 不会仅因为这次内存写入而自动更新：

```text
内存中的页表：VA 0x4000 → PFN 900（新）

CPU0的TLB：   ASID 10 + VA 0x4000 → PFN 100（旧）
CPU1的TLB：   ASID 10 + VA 0x4000 → PFN 100（旧）
```

如果 CPU1 此时命中旧 TLB 记录，它不会重新遍历页表，仍可能访问 PFN 100。因此，修改 PTE 的 CPU 还必须让其他可能缓存旧翻译的 CPU 删除相应 TLB 记录。这个跨 CPU 的 TLB 无效化过程通常称为 TLB shootdown。

传统实现可以向其他 CPU 发送 IPI（Inter-Processor Interrupt，处理器间中断），让它们分别执行本地 TLB 无效化。ARM64 还可以使用带 `is` 后缀的 TLBI，在 Inner Shareable 范围内由硬件广播无效化请求，不一定需要其他 CPU 进入软件 IPI 处理程序：

广播 TLBI 并不表示多个 CPU 共用一个 TLB。各 CPU 仍然可以拥有各自的 TLB，只是无效化请求由硬件发送到广播范围内的其他 CPU。

```c
dsb(ishst);
asid = __TLBI_VADDR(0, ASID(mm));
__tlbi(aside1is, asid);
__tlbi_sync_s1ish(mm);
```

这几步分别表示：

1. `dsb(ishst)`：保证前面的 PTE 写入已经达到其他 CPU 可以观察到的状态。
2. `ASID(mm)`：取得该地址空间的 ASID，并整理成 TLBI 指令需要的参数。
3. `aside1is`：按 ASID 广播 TLB 无效化，让 Inner Shareable 范围内的 CPU 删除该地址空间的旧翻译。
4. `__tlbi_sync_s1ish(mm)`：等待并保证无效化操作已经完成。

完成后，CPU 再次访问该地址时会发生 TLB Miss，重新遍历页表并读取指向 PFN 900 的新 PTE：

```text
CPU0修改PTE
      ↓
保证新PTE对其他CPU可见
      ↓
广播删除旧TLB记录
      ↓
等待无效化完成
      ↓
下次访问重新读取新PTE
```

> **[BOUNDARY]** 具体选择哪条 TLBI，以及是否还需要清理页表遍历缓存，取决于修改的地址范围和页表层级，本章不展开。

本章需要掌握的结论是：

```text
更新PTE ≠ CPU已经开始使用新PTE

页表修改 + 必要的TLB维护
才构成完整的映射更新
```

> **[SOURCE]** 本地 Linux `248951ddc14d`：[arch/arm64/include/asm/tlbflush.h](./2.源码/linux/arch/arm64/include/asm/tlbflush.h) 第 280～358 行说明接口语义，第 360～385 行实现全局、本地和按 `mm` 清理，第 623～649 行实现范围与页面清理。

### 2.10 CPU VA、物理地址、DMA 地址与 GPU VA 的连续性

“连续”只描述某一种地址空间中的地址依次相邻。讨论一段内存是否连续时，必须先说明观察者是谁、使用的是哪一种地址：

```text
CPU程序使用CPU虚拟地址
CPU页表最终给出系统物理地址
DMA设备使用驱动提供的DMA地址
GPU指令使用GPU虚拟地址
```

不同地址空间之间存在转换关系，因此某一层连续，并不要求下一层也连续。

#### 2.10.1 `mmap()`、`brk()` 与 `malloc()` 得到的是什么

这三个接口所处的层次不同：

| 接口         | 主要作用                                                                                                        |
| ------------ | --------------------------------------------------------------------------------------------------------------- |
| `mmap()`   | 请求内核建立一段用户虚拟地址映射，成功后得到连续的 VA 范围                                                      |
| `brk()`    | 调整进程的 program break，从而扩展或收缩堆的 VA 范围                                                            |
| `malloc()` | 用户态分配器返回一段连续的 CPU VA；可能复用已有空闲块，也可能通过`brk()` 或 `mmap()` 向内核取得更多地址空间 |

所以一次 `malloc()` 不一定创建新 VMA，也不一定使 `total_vm` 增加。无论分配器内部采用哪条路径，程序获得的对象都表现为一段连续的 CPU 虚拟地址。

假设进程获得了一段尚未访问的、页对齐的 16 KiB 匿名虚拟地址范围：

```text
[0x900000, 0x904000)

0x900000～0x900FFF → 第1个4 KiB虚拟页
0x901000～0x901FFF → 第2个4 KiB虚拟页
0x902000～0x902FFF → 第3个4 KiB虚拟页
0x903000～0x903FFF → 第4个4 KiB虚拟页
```

此时 VMA 可以已经覆盖整个范围，但尚未访问的页面可能还没有有效 PTE，也可能还没有对应 PFN。随后逐页访问并完成缺页处理后，页表可能形成：

```text
连续CPU VA：

VA页0x900000  VA页0x901000  VA页0x902000  VA页0x903000
      │              │              │              │
      ▼              ▼              ▼              ▼
   PFN 41         PFN 802        PFN 116        PFN 650
```

CPU 依次访问这些 VA 时，MMU 会分别查找四个 PTE，所以程序仍然看到连续的 16 KiB 字节范围。底层 PFN 不相邻并不会破坏 CPU VA 的连续性。

如果四个物理页本身连续，它们的 PFN 应当类似：

```text
PFN 500 → PFN 501 → PFN 502 → PFN 503
```

因此，CPU VA 连续与系统物理页连续是两个不同条件。

#### 2.10.2 同一缓冲区可能具有多种地址

2.10.1 只观察了 CPU VA 和系统物理页之间的关系。当同一缓冲区还要被设备或 GPU 访问时，驱动需要为不同的访问者准备相应的地址。

DMA 地址不是 CPU VA。在一些简单平台中，DMA 地址可能与系统物理地址相同，但一般不能依赖这一点。存在 IOMMU 时，它可以把设备使用的 DMA 地址转换到缓冲区所在的系统物理页。

GPU VA 也不是 CPU VA。驱动可以把缓冲区映射到 GPU 虚拟地址空间，使 GPU 通过自己的页表访问系统内存或 VRAM。即使 CPU 和 GPU 最终访问同一批后端页面，它们使用的虚拟地址也可以完全不同。

下面以系统内存缓冲区为例，假设 CPU、DMA 设备和 GPU 都具有一段连续地址，三种地址分别映射到同一批系统内存页：

```text
CPU程序
  │ 连续CPU VA
  ▼
CPU页表 ───────────────┐
                       │
DMA设备                 ├──→ 同一缓冲区的系统内存页
  │ 连续DMA地址         │
  ▼                     │
DMA映射 / IOMMU ───────┤
                       │
GPU指令                 │
  │ 连续GPU VA          │
  ▼                     │
GPU页表 ────────────────┘
```

图中的三种地址可以分别映射到同一批页面。

> **[BOUNDARY]** IOMMU 如何建立设备地址映射，以及 GEM、TTM 如何创建 GPU VA 映射，将在对应章节展开。本节只建立“连续性属于某一个地址空间”的概念。

> **[SOURCE]** 本地 Linux `248951ddc14d`：[Documentation/core-api/dma-api-howto.rst](./2.源码/linux/Documentation/core-api/dma-api-howto.rst) 第 16～40、75～88 行区分 CPU VA、物理地址和设备 DMA 地址；[Documentation/gpu/amdgpu/amdgpu-glossary.rst](./2.源码/linux/Documentation/gpu/amdgpu/amdgpu-glossary.rst) 第 93～98 行说明 AMDGPU 可以把 VRAM 和系统内存资源映射进 GPU 虚拟地址空间。

### 2.11 本章总结与源码索引

本章建立的完整关系是：

```text
current
   │
   ▼
task_struct
   │ task->mm
   ▼
mm_struct
   │
   ├── mm_mt ──→ VMA
   │             └─ 描述VA范围、权限、来源和缺页规则
   │
   ├── pgd ─────→ 用户根页表
   │                │ virt_to_phys
   │                ▼
   │           TTBR0_EL1.BADDR
   │
   └── context.id ─→ ASID
                      │
                      ▼
                 区分TLB中的地址空间

CPU访问VA
   │
   ├─ TLB命中 → 使用缓存的翻译与权限
   │
   └─ TLB未命中 → MMU硬件遍历页表
                         ├─ 成功 → 填充TLB并继续
                         └─ 失败 → 进入Linux异常处理
```

本章结论如下：

1. `task_struct` 表示任务，`mm_struct` 表示地址空间，二者不是一一对应。
2. VMA 描述“这段 VA 应该怎样使用”，页表描述“这个虚拟页当前映射到哪里”。
3. `mm->pgd` 是内核虚拟地址指针，写入 TTBR 前需要得到根页表物理地址。
4. TLB entry 的真实硬件格式由 CPU 实现决定，只能画出逻辑字段。
5. ASID 标识地址空间而不是 PID，使不同 `mm_struct` 的翻译可以同时留在 TLB。
6. 任务切换包含地址空间切换和内核执行现场切换；共享同一 `mm_struct` 的线程通常可以跳过前者。
7. 修改页表后还必须根据情况执行 TLB 无效化和同步。
8. 连续 CPU VA 可以映射离散 PFN，也不自动等于连续 DMA 地址或连续 GPU VA。

> **[SOURCE]** 本章本地源码索引：
>
> | 主题                        | Linux`248951ddc14d` 源码路径                                                                                                                                                                                                                                                                                           |
> | --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
> | 当前任务与`task_struct`   | [arch/arm64/include/asm/current.h](./2.源码/linux/arch/arm64/include/asm/current.h)、[include/linux/sched.h](./2.源码/linux/include/linux/sched.h)                                                                                                                                                                         |
> | `active_mm`               | `Documentation/mm/active_mm.rst`（当前仍在 Git 对象中）、[kernel/sched/core.c](./2.源码/linux/kernel/sched/core.c)                                                                                                                                                                                                      |
> | `mm_struct` 与 VMA        | [include/linux/mm_types.h](./2.源码/linux/include/linux/mm_types.h)、[include/linux/mm.h](./2.源码/linux/include/linux/mm.h)                                                                                                                                                                                               |
> | 地址空间创建与共享          | [kernel/fork.c](./2.源码/linux/kernel/fork.c)                                                                                                                                                                                                                                                                             |
> | Maple Tree 与 VMA 操作      | [mm/mmap.c](./2.源码/linux/mm/mmap.c)、[mm/vma.c](./2.源码/linux/mm/vma.c)、[mm/mprotect.c](./2.源码/linux/mm/mprotect.c)                                                                                                                                                                                                   |
> | VMA 与缺页路径              | [arch/arm64/mm/fault.c](./2.源码/linux/arch/arm64/mm/fault.c)、[mm/mmap_lock.c](./2.源码/linux/mm/mmap_lock.c)、[mm/memory.c](./2.源码/linux/mm/memory.c)                                                                                                                                                                   |
> | ARM64`mm_context_t`       | [arch/arm64/include/asm/mmu.h](./2.源码/linux/arch/arm64/include/asm/mmu.h)                                                                                                                                                                                                                                               |
> | TTBR 与地址空间切换         | [arch/arm64/include/asm/mmu_context.h](./2.源码/linux/arch/arm64/include/asm/mmu_context.h)、[arch/arm64/mm/context.c](./2.源码/linux/arch/arm64/mm/context.c)、[arch/arm64/mm/proc.S](./2.源码/linux/arch/arm64/mm/proc.S)                                                                                                 |
> | 异常入口与任务现场切换      | [arch/arm64/kernel/entry.S](./2.源码/linux/arch/arm64/kernel/entry.S)、[arch/arm64/kernel/process.c](./2.源码/linux/arch/arm64/kernel/process.c)、[arch/arm64/include/asm/processor.h](./2.源码/linux/arch/arm64/include/asm/processor.h)、[arch/arm64/include/asm/ptrace.h](./2.源码/linux/arch/arm64/include/asm/ptrace.h) |
> | ARM64 页表保护位            | [arch/arm64/include/asm/pgtable-hwdef.h](./2.源码/linux/arch/arm64/include/asm/pgtable-hwdef.h)、[arch/arm64/include/asm/pgtable-prot.h](./2.源码/linux/arch/arm64/include/asm/pgtable-prot.h)                                                                                                                             |
> | TLB 无效化                  | [arch/arm64/include/asm/tlbflush.h](./2.源码/linux/arch/arm64/include/asm/tlbflush.h)                                                                                                                                                                                                                                     |
> | CPU VA、物理地址与 DMA 地址 | [Documentation/core-api/dma-api-howto.rst](./2.源码/linux/Documentation/core-api/dma-api-howto.rst)                                                                                                                                                                                                                       |
> | AMDGPU GPU 虚拟地址空间     | [Documentation/gpu/amdgpu/amdgpu-glossary.rst](./2.源码/linux/Documentation/gpu/amdgpu/amdgpu-glossary.rst)                                                                                                                                                                                                               |

第 3 章将从 `PTE → PFN → 物理页` 继续，说明 Linux 如何用 `struct page` 描述和管理物理页。

## 3. 物理页：从 PTE 中的 PFN 到 `struct page`

前两章已经说明，MMU 可以从叶子 PTE 中取得 PFN，再与原虚拟地址的页内偏移组合成 PA。但是，PFN 只是物理页框的编号；Linux 还需要记录该页当前由谁使用、被多少页表映射以及是否仍有其他使用者。因此，同一个物理页需要同时从两个角度理解：

```text
物理页框
  └─ 保存程序数据、文件内容或页表等实际字节

struct page
  └─ 保存Linux管理该物理页所需的元数据
```

本章只回答“物理页是什么、Linux 怎样描述它”。空闲物理页如何分配，留到第 4 章讨论。

### 3.1 从物理地址 PA 中拆出 PFN 和页内偏移

PA 是以字节为单位的完整物理地址。继续固定使用 4 KiB 基础页面：

```text
PAGE_SIZE  = 4 KiB = 0x1000 = 2^12字节
PAGE_SHIFT = 12
```

一个 4 KiB 页面内部需要 12 位表示字节位置，因此 PA 的低 12 位是页内 offset，其余高位是 PFN。假设 `PA = 0x2234`：

```text
PFN = PA >> PAGE_SHIFT
    = 0x2234 >> 12
    = 0x2 = 十进制2

offset = PA & (PAGE_SIZE - 1)
       = 0x2234 & 0xFFF
       = 0x234

物理页基地址 = PFN << PAGE_SHIFT
             = 0x2 << 12
             = 0x2000

PA           = 0x2000 + 0x234
             = 0x2234
```

一个十六进制数字占 4 位，所以右移 12 位相当于去掉最低三个十六进制数字 `234`。由此可知，`PA 0x2234` 位于 `PFN 2`，该物理页覆盖 `[0x2000, 0x3000)`，页内位置是 `0x234`。

Linux 使用下面两个宏完成相同转换：

```c
#define PFN_PHYS(x) ((phys_addr_t)(x) << PAGE_SHIFT)
#define PHYS_PFN(x) ((unsigned long)((x) >> PAGE_SHIFT))
```

代入上面的数字：

```text
PHYS_PFN(0x2234) = 2       PA → PFN
PFN_PHYS(2)      = 0x2000  PFN → 物理页基地址
```

再回到前文的十进制 `PFN 900`，它等于十六进制 `0x384`：

```text
物理页基地址 = 0x384 << 12 = 0x384000
加上offset 0x234
最终PA       = 0x384234
```

4 KiB 页面只固定了 offset 为低 12 位，并没有把 PFN 限制为 4 位。本章固定使用 48 位 PA，因此完整划分是：

```text
bit 47                                                         bit 12  bit 11             bit 0
   │                                                               │      │                    │
   ▼                                                               ▼      ▼                    ▼
┌───────────────────────────────────────────────────────────────────────┬───────────────────────────┐
│                           PA[47:12]                                	│         PA[11:0]          │
│                           PFN（36位）                              	│        offset（12位）      │
└───────────────────────────────────────────────────────────────────────┴───────────────────────────┘
                              PA >> 12                                    PA & 0xFFF
```

把 `PA 0x2234` 补齐为 48 位后，其值是 `0x000000002234`：

```text
┌────────────────────────────────────────────────────────────────────┬───────────────────────────┐
│ 0000 0000 0000 0000 0000 0000 0000 0000 0010                    	 │ 0010 0011 0100            │
│                         PFN = 0x2                                  │ offset = 0x234            │
└────────────────────────────────────────────────────────────────────┴───────────────────────────┘
```

如果 PFN 变大，它会继续使用左侧 36 位字段；PFN 与 offset 的分界始终位于 bit 12，不会受示例数值大小影响。

PFN 只是物理页框编号，不是以字节为单位的 PA，也不是可以直接解引用的 C 指针。

> **[SOURCE]** 本地 Linux `248951ddc14d`：[include/linux/pfn.h](./2.源码/linux/include/linux/pfn.h) 第 9～13 行定义 PFN 对齐以及 PFN 与物理地址的转换宏。

### 3.2 `struct page` 是物理页的管理档案，不是页面数据

继续观察 `PFN 900（0x384）`。它对应的物理页从 `PA 0x384000` 开始，其中保存的是程序或内核真正使用的数据：

```text
PFN 900对应的物理页

PA 0x384000
┌────────────────────────────┐
│ 程序变量、数组或其他实际字节  │
└────────────────────────────┘
```

Linux 还必须知道这个页面当前由谁使用、能否释放以及映射到了哪些地址空间。这些管理信息不能写进上面的 4 KiB 物理页，否则会破坏页面中的实际数据。因此，Linux 在另外的元数据区域中为可管理页面准备 `struct page`：

```text
PFN 900
├─ 物理页框：保存真正的数据
└─ struct page：保存Linux管理该页所需的信息
```

可以先把 `struct page` 理解成下面这张管理档案，而不是从真实结构体布局开始记忆：

```text
PFN 900 的 struct page
┌────────────────────────────────┐
│ 页面当前是什么类型和状态？       │
│ 页面与匿名内存或文件怎样关联？   │
│ 有多少用户页表正在映射它？       │
│ 内核中是否还有使用者持有它？     │
└────────────────────────────────┘
```

例如，两个进程可以同时映射 `PFN 900`，GPU 驱动也可能暂时持有该页面：

```text
进程A的PTE ───────┐
                  ├──→ PFN 900 → 同一个struct page
进程B的PTE ───────┘                    ▲
                                       │
GPU驱动持有页面 ────────────────────────┘
```

如果进程 A 删除自己的 PTE，页面仍不能因此立即释放，因为进程 B 还在映射它，驱动也可能仍在使用它。这就是 Linux 需要分别跟踪“用户页表映射”和“其他页面引用”的原因。

下面继续假设 `PFN 900` 是一个普通的 4 KiB 匿名页，用同一个例子理解真实源码中的字段。

1. `flags`：记录页面当前处于什么状态

   `flags` 由许多状态位组成。例如，`PG_locked` 表示页面当前被锁定，`PG_dirty` 表示内容已经被修改，`PG_lru` 和 `PG_active` 用于描述页面是否位于回收链表以及是否活跃。

   `flags` 不保存“进程 A 的哪个 VA 映射到 `PFN 900`”，也不保存 PTE。它回答的是页面状态问题。
2. `mapping` 和 `__folio_index`：记录页面与后端管理对象的关系

   对匿名页和文件页，这两个字段的解释不同：

   ```text
   匿名页：
   PFN 900 ──mapping──→ anon_vma
             index ──→ 该页在匿名映射中的位置

   文件页：
   PFN 900 ──mapping──→ 文件的address_space
             index ──→ 该页在文件中的页序号
   ```

   因此，`mapping` 不是 VA→PFN 映射，也不是指向某个 PTE。它把物理页联系到匿名内存或文件的管理体系；文件页还要结合 `index`，才能知道它对应文件中的哪一页。源码在 `struct page` 中将该位置字段命名为 `__folio_index`，后续通常通过 folio 接口使用它。
3. `_mapcount`：记录当前有多少个有效用户页表项映射该页

   对图中的普通 4 KiB 页面，进程 A 和进程 B 各有一个有效 PTE 指向 `PFN 900`：

   ```text
   进程A的有效PTE ──┐
                    ├──→ PFN 900
   进程B的有效PTE ──┘

   folio_mapcount() = 2
   ```

   如果进程 A 删除自己的 PTE，逻辑映射数就从 2 变成 1。已经换出的非 Present PTE 不表示当前驻留的用户页表映射，因此不计入这里的映射数。

   原始 `_mapcount` 使用“实际映射数减 1”的内部编码：零次映射时初始化为 `-1`，两次映射时原始值通常为 `1`。内核代码应通过 `folio_mapcount()` 等辅助函数取得逻辑映射数，而不是直接把 `_mapcount` 当作映射次数。
4. `_refcount`：记录还有多少引用要求该页不能被释放

   引用的范围比用户页表映射更广。可能产生页面引用的使用者包括：

   ```text
   用户页表中的有效映射
   Page Cache或LRU等内核管理关系
   内核代码取得的临时页面引用
   驱动持有或固定的页面引用
   ```

   因此，即使 `folio_mapcount()` 为 2，引用数也可能大于 2，不能用映射数推算引用数。进程 A 解除映射后，只要进程 B 或 GPU 驱动仍在使用该页，相关引用就不会全部消失，页面也不能被重新分配给别人。内核通常通过 `folio_get()`、`folio_put()` 等接口增减引用，而不直接操作 `_refcount`。
5. `lru`：把页面连接到内存回收链表

   当匿名页或文件页由页面回收系统管理时，`lru` 是链表节点。内核借助这些链表组织活跃页、非活跃页等候选页面，决定内存紧张时优先检查哪些页面。它不是映射计数，也不表示页面属于哪个进程。
6. `private`：保存特定页面用途的附加数据

   `private` 没有对所有页面都成立的统一含义。例如，文件系统可以用它联系页面附加数据，交换缓存可以用它保存交换条目，空闲页又可以用这块位置记录伙伴分配器所需的信息。必须结合页面当前的状态和使用者解释，不能把它理解成通用的“页面所有者”。

把这些字段压缩成一句话就是：

```text
flags              → 页面现在处于什么状态
mapping + index    → 页面属于哪套匿名内存或文件管理关系
mapcount           → 多少个有效用户页表项正在映射它
refcount           → 还有多少引用不允许它被释放
lru                → 页面位于哪类回收链表
private            → 当前用途自行解释的附加数据
```

真实 `struct page` 中会看到多个 union。union 的目的只是让不同用途的页面复用同一块元数据空间：

```text
页面处于空闲状态     	→ 这块空间保存空闲链表等信息
页面是匿名页或文件页 		→ 这块空间保存mapping、lru等信息
页面属于特殊设备类型   	→ 这块空间保存设备相关状态
```

这些用途不会在同一时刻全部成立，因此不能认为 union 中列出的所有成员一直同时有效。本章不展开 union 的嵌套布局。

最后还要区分两个地址：

```text
struct page *
→ 指向页面管理档案的内核虚拟地址

PA 0x384000
→ 被这份档案描述的物理页框起点
```

`struct page *` 不是该物理页的 PA，也不是指向页面实际数据的用户地址。内核怎样从 `struct page *` 得到可以访问页面数据的内核地址，将在 3.4 节说明。

> **[SOURCE]** 本地 Linux `248951ddc14d`：[include/linux/mm_types.h](./2.源码/linux/include/linux/mm_types.h) 第 80～202 行定义 `struct page`，第 359～376 行说明 `mapping`、`index`、`_mapcount` 和 `_refcount` 的用途；[include/linux/page-flags.h](./2.源码/linux/include/linux/page-flags.h) 第 51～63、93～112 行说明典型页面状态位，第 692～714 行说明匿名页的 `mapping` 编码；[include/linux/mm.h](./2.源码/linux/include/linux/mm.h) 第 1892～1923 行定义 `folio_mapcount()` 的语义；[include/linux/page_ref.h](./2.源码/linux/include/linux/page_ref.h) 第 65～105 行说明页面引用计数及其典型使用者。

### 3.3 PFN 与 `struct page` 如何互相定位

对于 Linux 内存模型中具有有效页面元数据的物理页，可以使用下面的抽象接口：

```c
struct page *page = pfn_to_page(pfn);
unsigned long pfn = page_to_pfn(page);
phys_addr_t page_pa = page_to_phys(page);
```

它们表达的关系是：

```text
PFN
 │ pfn_to_page()
 ▼
struct page
 │ page_to_pfn()
 └────────────────→ PFN

struct page
 │ page_to_phys()
 ▼
被描述物理页的基地址
```

Linux 支持不同的物理内存模型，所以 `pfn_to_page()` 的底层计算方式并不只有一种。例如，在 `SPARSEMEM_VMEMMAP` 配置下，源码把 `vmemmap` 抽象成按 PFN 定位 `struct page` 的连续虚拟区域：

```c
#define __pfn_to_page(pfn)  (vmemmap + (pfn))
#define __page_to_pfn(page) ((unsigned long)((page) - vmemmap))
```

不同内存模型的具体实现并不相同，但都遵循以下抽象关系：

```text
PFN N
├─ 物理页基地址 = N << PAGE_SHIFT
└─ 页面管理对象 = pfn_to_page(N)
```

ARM64 也直接提供了从 PTE 到 PFN、再到 `struct page` 的组合关系：

```c
#define pte_pfn(pte)  (__pte_to_phys(pte) >> PAGE_SHIFT)
#define pte_page(pte) (pfn_to_page(pte_pfn(pte)))
```

因此，对一个指向普通系统内存页的有效叶子 PTE，可以概念性地写成：

```text
PTE
 │ pte_pfn()
 ▼
PFN
 │ pfn_to_page()
 ▼
struct page
```

这里有一个重要边界：CPU 物理地址空间不只包含 Linux 可正常管理的系统 RAM，还可能包含设备资源和地址空洞。`pfn_valid()` 只判断相应 PFN 是否具有 memory map entry，源码明确说明，这仍不等于该 PFN 一定代表可正常使用的 RAM。因此，不能把任意设备物理地址转换成普通 `struct page` 后使用；必须先确认该 PFN 在具体接口和内存类型下是否合法。

> **[BOUNDARY]** 本章后续都假设示例 PFN 对应 Linux 正常管理的系统内存页。设备内存、`ZONE_DEVICE` 和无普通 `struct page` 的特殊 PFN 映射留到 GPU 内存阶段讨论。

> **[SOURCE]** 本地 Linux `248951ddc14d`：[include/asm-generic/memory_model.h](./2.源码/linux/include/asm-generic/memory_model.h) 第 43～87 行定义 `SPARSEMEM_VMEMMAP` 下的转换以及通用的 `page_to_pfn()`、`pfn_to_page()`、`page_to_phys()`；[arch/arm64/include/asm/pgtable.h](./2.源码/linux/arch/arm64/include/asm/pgtable.h) 第 136～141 行定义 `pte_pfn()`、`pfn_pte()` 和 `pte_page()`；[include/linux/mmzone.h](./2.源码/linux/include/linux/mmzone.h) 第 2247～2253 行说明 `pfn_valid()` 的边界。

### 3.4 内核怎样访问物理页中的实际数据

`pfn_to_page()` 只得到页面元数据。如果内核需要清零、复制或检查该物理页中的实际字节，还需要一个指向页面内容的内核虚拟地址。

ARM64 Linux 在 `TTBR1_EL1` 管理的内核地址空间中建立 linear map（线性映射）：把正常管理的系统物理内存映射到一段连续的内核虚拟地址范围。对处于这段映射中的页面，物理地址和内核虚拟地址之间可以按照架构定义的偏移关系转换。

```text
同一个系统内存页：PFN 900

用户访问路径：
用户VA 0x601000
       │ 用户页表
       ▼
    PFN 900

内核访问路径：
内核linear-map VA
       │ 内核页表
       ▼
    PFN 900
```

这里不是“复制了两份页面”。两个不同虚拟地址可以通过不同页表映射到同一个物理页框：

```text
用户VA ──TTBR0管理的用户页表──┐
                              ├──→ 同一个PFN → 同一份物理页数据
内核VA ──TTBR1管理的内核页表──┘
```

对于能够通过 linear map 直接访问的普通页面，Linux 提供的抽象关系包括：

```c
void *kernel_va = page_to_virt(page);
void *address = page_address(page);
```

`page_to_virt()` 从 `struct page` 得到该物理页在线性映射中的内核虚拟地址；在没有 high memory（高端内存）特殊处理的配置中，`page_address()` 最终也可以返回这个地址。于是三种值必须继续区分：

| 值                     | 指向或表示什么                     |
| ---------------------- | ---------------------------------- |
| `struct page *`      | 页面元数据的内核虚拟地址           |
| `page_to_phys(page)` | 被描述物理页的物理基地址           |
| `page_address(page)` | 内核用于访问该页实际字节的虚拟地址 |

不是所有架构和页面类型都能永久通过 linear map 直接访问。具有 high memory 的架构可能需要 `kmap_local_page()` 建立临时内核映射；设备资源也不能因为具有物理地址就直接套用普通系统 RAM 的 linear-map 转换。

> **[BOUNDARY]** ARM64 本章只使用“普通系统内存页通常具有 linear-map 内核地址”这一主线。linear map 不是 DMA 映射，驱动不能用 `virt_to_phys()` 或 `page_to_virt()` 代替 DMA API 获得设备地址。

> **[SOURCE]** 本地 Linux `248951ddc14d`：[arch/arm64/include/asm/memory.h](./2.源码/linux/arch/arm64/include/asm/memory.h) 第 37～45、334～375、397～425 行定义 linear map 范围以及物理地址、内核虚拟地址和 `struct page` 的转换；[include/linux/mm.h](./2.源码/linux/include/linux/mm.h) 第 119～120、3005～3018 行定义 `page_to_virt()`、`lowmem_page_address()`、`page_address()` 和 `folio_address()`；[include/linux/highmem-internal.h](./2.源码/linux/include/linux/highmem-internal.h) 第 41～50、186～198 行展示 high memory 与普通页面取得内核地址时的分支。

### 3.5 基础页、复合页与 folio

前文始终固定使用 4 KiB 页面。这里的 4 KiB 是本章假设的 base page（基础页），PFN 也按基础页大小编号：

```text
PFN N     → 第N个4 KiB物理页框
PFN N + 1 → 紧邻的下一个4 KiB物理页框
```

但是，Linux 不一定每次都只把一个基础页作为管理单位。多个物理连续、大小和起点都按 2 的幂对齐的基础页，可以作为一个更大的整体管理。现代 Linux 使用 `struct folio` 表达这种管理单位：

```text
一个基础页大小的folio
└─ 1 × 4 KiB

一个较大的folio
└─ 2、4、8……个物理连续的基础页
```

源码对 folio 的定义强调，它表示一段物理、内核虚拟和逻辑上都连续的字节范围，大小至少为 `PAGE_SIZE`，并且是 2 的幂。较大的 folio 会使用多个基础页；相关的 compound page（复合页）机制负责表达“一个首页加若干尾页”的关系。

为了避免混淆，可以先按下面的层次理解：

| 概念            | 本章中的作用                                                  |
| --------------- | ------------------------------------------------------------- |
| 基础页          | CPU 页表和 PFN 计算使用的基础粒度，本章固定为 4 KiB           |
| `struct page` | 与基础物理页框相联系的页面元数据对象                          |
| folio           | Linux 把一个或多个连续基础页作为整体管理时使用的对象          |
| 大页或块映射    | 页表可能用一个叶子 descriptor 覆盖多个基础页，已在 1.7 节说明 |

folio 不会替代 PTE 完成硬件地址翻译。即使多个基础页作为一个 folio 管理，PFN 仍然可以定位其中的基础页，页表仍然按照所选叶子映射粒度完成 VA 到 PA 的翻译。

> **[BOUNDARY]** 本章只建立 `struct page` 与 folio 的关系，避免后续阅读现代 Linux MM 源码时误以为它们是两个互不相关的页面系统。透明大页、HugeTLB、复合页字段以及大 folio 的分配策略留到需要时再学习。

> **[SOURCE]** 本地 Linux `248951ddc14d`：[include/linux/mm_types.h](./2.源码/linux/include/linux/mm_types.h) 第 359～402 行说明 folio 的范围、对齐和连续性，第 402～514 行定义 `struct folio` 并通过 `FOLIO_MATCH` 校验它与 `struct page` 的公共字段布局。

### 3.6 VMA、PTE、PFN、`struct page` 各自记录什么

现在可以把同一个用户页面放回 Linux 地址空间的完整结构中：

```text
mm_struct
   │
   ├─ mm_mt
   │    └─ VMA
   │         └─ 描述VA范围、权限和页面来源等共同规则
   │
   └─ pgd
        └─ 多级页表
             └─ PTE：某个虚拟页当前指向PFN N
                                      │
                                      ▼
                                struct page
                                      │ 描述
                                      ▼
                                物理页框中的字节
```

四个对象回答不同问题：

| 对象            | 回答的问题                                           |
| --------------- | ---------------------------------------------------- |
| VMA             | 这段虚拟地址是否合法，允许怎样访问，页面应来自哪里？ |
| PTE             | 这个虚拟页当前能否翻译；可以翻译时指向哪个 PFN？     |
| PFN             | 目标物理页框在物理地址空间中的编号是多少？           |
| `struct page` | Linux 当前怎样管理这个物理页？                       |

一个物理页框在某一时刻具有当前主要用途：

| 页面用途           | 物理页中保存的内容                     |
| ------------------ | -------------------------------------- |
| 匿名用户页         | 堆、栈或匿名映射中的程序数据           |
| 文件缓存页         | 从文件读入并由 Page Cache 管理的内容   |
| 页表页             | PGD、PUD、PMD 或 PTE 表中的 descriptor |
| 内核分配器的后端页 | 内核对象或内核缓冲区所占用的存储       |

“共享”不是与匿名页、文件页或页表页并列的页面用途，而是物理页与页表之间的映射关系。一张匿名页或文件页都可能同时被多个用户 PTE 指向：

```text
进程A的PTE ──只读────┐
                     ├──→ PFN 900：当前是一张文件缓存页
进程B的PTE ──可读写──┘
```

这里 `PFN 900` 的主要用途仍是“文件缓存页”；两个 PTE 表示它当前有两份用户页表映射。每个 PTE 的读写等访问属性可以不同，页面被多少个有效用户页表项映射则由 mapcount 相关状态跟踪。因此要分开理解：

```text
页面当前用途
→ 匿名数据页、文件缓存页、页表页或内核后端页

页面映射关系
→ 当前被0个、1个或多个用户PTE指向
```

PFN 本身不编码“这是堆页还是页表页”。页面用途由 Linux 的分配关系、页面标志以及 `struct page` 中当前有效的状态共同表达。同一个物理页框释放后可以在另一个时刻被重新分配为其他用途，但不能因为它同时被多个进程映射，就认为它同时具有多个主要用途。

> **[SOURCE]** 本地 Linux `248951ddc14d`：[include/linux/mm_types.h](./2.源码/linux/include/linux/mm_types.h) 第 83～186 行展示 `struct page` 针对 Page Cache、匿名页、空闲页和其他页面类型复用不同字段；[include/linux/mm.h](./2.源码/linux/include/linux/mm.h) 第 1892～1923 行说明 mapcount 表示 folio 被当前有效用户页表项映射的次数；页表页保存 descriptor 的结构已在 1.3 节结合 ARM64 页表源码说明。

### 3.7 正向映射与反向映射

CPU 执行 load/store 时使用的是正向映射：从某个地址空间中的 VA 出发，通过页表找到 PFN。

```text
正向映射

mm_struct
   │ pgd
   ▼
VA → PTE → PFN → 物理页
```

但是，Linux 管理物理页时还会遇到相反的问题：

```text
已经知道这个struct page
        ↓
哪些进程、VMA和PTE正在映射它？
```

这种从页面反查用户映射的机制称为 rmap（Reverse Mapping，反向映射）。它不是让 MMU 反向遍历页表，也不是在每个 `struct page` 中保存一张完整的 PTE 指针数组，而是借助页面后端对象和 VMA 之间的索引关系找到候选 VMA，再检查相应页表。

匿名页和文件页的主要组织入口不同，但找到候选 VMA 之后的步骤相同：

```text
struct page / folio
        │
        ├─ 匿名页：mapping → anon_vma
        │
        └─ 文件页：mapping → address_space->i_mmap
                         │
                         ▼
                 找到0个、1个或多个候选VMA
                         │
                         ├─ vma->vm_mm → 对应mm_struct
                         └─ 页面偏移和VMA → 计算候选VA
                                         │
                                         ▼
                              mm->pgd → 页表 → 检查PTE
```

`struct page` 中没有唯一的 `mm` 指针，因为同一个物理页可以被多个地址空间映射。rmap 每找到一个候选 VMA，就可以通过下面这个成员取得该 VMA 所属的地址空间：

```c
struct mm_struct *mm = vma->vm_mm;
```

例如 `PFN 900` 同时被两个独立进程映射时，反向查找结果可能是：

```text
PFN 900对应的struct page
   ├─→ VMA_A → vm_mm → mm_A → 检查PTE_A
   └─→ VMA_B → vm_mm → mm_B → 检查PTE_B
```

在本章中，`anon_vma_chain` 表示匿名页与相关 VMA 之间的连接，不展开其内部使用链表还是区间树。并非所有 VMA 都挂到同一个 `anon_vma` 上：所有 VMA 原本就由各自 `mm_struct` 的 `mm_mt` 管理；`anon_vma` 和 `address_space->i_mmap` 是为从页面反向寻找 VMA 而建立的额外索引。

通过这些索引找到的仍然只是候选 VMA。页面可能尚未建立 PTE、已经换出，或者经过 COW 后改为指向其他 PFN，因此内核最后必须使用 `vma->vm_mm` 和候选 VA 检查真实页表，确认 PTE 是否仍指向目标页面。

因此，`mm->mm_mt` 和 rmap 的查找方向不同：

| 机制      | 已知条件                | 主要查找目标                 |
| --------- | ----------------------- | ---------------------------- |
| `mm_mt` | 某个`mm_struct` 和 VA | 覆盖该地址的 VMA             |
| 页表遍历  | 某个`mm_struct` 和 VA | 当前 PTE 以及 PFN            |
| rmap      | 某个物理页或 folio      | 候选 VMA、所属 mm 和真实 PTE |

rmap 使 Linux 能够在页面回收、迁移或解除映射时找到受影响的用户页表。例如，源码提供 `try_to_unmap()`、`try_to_migrate()` 和 `folio_referenced()` 等入口。本章只说明查找方向，不展开匿名页红黑树、页表锁和遍历算法。

> **[BOUNDARY]** 这个关系对后续 GPU 学习也有帮助：当后端页面准备迁移或失效时，只知道 PFN 并不够，内核还必须协调仍然引用该页面的 CPU 映射和设备映射。GPU 映射不属于 CPU 用户页表，不能仅靠 CPU rmap 找到；驱动如何跟踪 CPU 映射变化并处理 GPU 映射，留到 HMM 与 SVM 阶段说明。

> **[SOURCE]** 本地 Linux `248951ddc14d`：[include/linux/rmap.h](./2.源码/linux/include/linux/rmap.h) 第 32～88 行定义 `anon_vma` 与 `anon_vma_chain`；[include/linux/fs.h](./2.源码/linux/include/linux/fs.h) 第 457～485 行定义文件 `address_space` 中的 `i_mmap`；[include/linux/mm_types.h](./2.源码/linux/include/linux/mm_types.h) 第 922～983 行定义 VMA 的 `vm_mm`、`anon_vma`、`vm_pgoff` 和 `vm_file`；[mm/rmap.c](./2.源码/linux/mm/rmap.c) 第 2964～3010、3031～3099 行分别从匿名页和文件页查找候选 VMA；[mm/page_vma_mapped.c](./2.源码/linux/mm/page_vma_mapped.c) 第 180～280 行使用 VMA 所属 `mm_struct` 和候选 VA 检查真实页表。

### 3.8 引用、页表映射、设备固定与页面生命周期

页面管理中容易混淆三种状态：

| 状态         | 说明                                                                 |
| ------------ | -------------------------------------------------------------------- |
| 页面引用     | 内核中仍有对象或代码持有该页，页面生命周期尚未结束                   |
| 用户页表映射 | 某个有效用户 PTE 当前指向该页                                        |
| 设备固定     | 驱动准备让设备使用已有页面，需要在设备使用期间维持页面的有效生命周期 |

例如，两个进程可以把不同 VA 映射到同一个物理页：

```text
进程A：VA 0x400000 → PTE ──┐
                           ├──→ PFN 900 → 同一个struct page
进程B：VA 0x700000 → PTE ──┘
```

从逻辑上看，这个页面此时有两处用户页表映射。删除进程 A 的 PTE 只移除其中一处映射；只要进程 B 的映射或其他有效引用仍然存在，就不能仅因 A 解除映射而把页面当成无人使用。源码中的原始 `_mapcount` 采用内部编码，不能把字段的裸数值直接当作上图中的直观数字；本章只使用“逻辑映射数量”这一概念。

设备固定又是另一层约束。以后学习 GPU 访问用户内存时，会看到类似下面的关系：

```text
已经存在的用户页面
        │ pin_user_pages*()
        ▼
驱动取得一组struct page *并建立固定关系
        │
        ▼
后续再建立DMA映射和GPU页表映射
```

固定已有页面不等于申请新页面，也不会自动生成 DMA 地址或 GPU PTE。它首先解决的是生命周期问题：设备仍可能访问页面时，内核和驱动不能提前释放页面，或者在没有完成协调的情况下更换设备正在使用的后端页面。详细接口、固定计数和解除固定流程留到后续 DMA 与 GPU 内存章节。

可以把普通页面的生命周期抽象成下面的关系。它是职责模型，不是 Linux 内核中一条固定的单向状态机：

```text
空闲物理页
    │ 分配器把页面交给某个使用者
    ▼
页面已被占用，并存在有效引用
    │
    ├─ 只由内核使用
    │
    ├─ 建立用户PTE
    │      └─ 逻辑映射数量增加
    │
    └─ 固定后交给设备
           └─ 设备使用期间维持固定关系

解除设备固定、删除用户PTE、释放其他引用
    │
    ▼
所有相关使用者都完成释放
    │
    ▼
普通页面才可能重新回到分配器管理的空闲状态
```

这里需要避免三个错误推论：

```text
没有用户PTE
≠ 页面一定空闲

只有一个用户PTE
≠ 页面引用计数一定等于1

页面已经固定
≠ 页面已经具有DMA地址或GPU VA
```

页面可能没有任何用户映射，却仍被内核、Page Cache 或设备持有；也可能被多个用户 PTE 共享。最终能否释放，必须由拥有该页面的子系统按照引用、映射和固定关系共同判断，而不能只查看其中一个计数。

> **[SOURCE]** 本地 Linux `248951ddc14d`：[include/linux/page_ref.h](./2.源码/linux/include/linux/page_ref.h) 第 65～68 行通过 `_refcount` 取得页面引用计数；[include/linux/mm_types.h](./2.源码/linux/include/linux/mm_types.h) 第 166～185 行说明 `_mapcount` 与 `_refcount` 的职责；[Documentation/core-api/pin_user_pages.rst](./2.源码/linux/Documentation/core-api/pin_user_pages.rst) 第 18～55 行区分普通页面引用与面向 DMA 的页面固定接口。

### 3.9 用 `PFN 900` 串起完整关系

最后继续沿用 2.3.7 节的匿名堆页面。假设程序访问：

```c
*(int *)0x601234 = 10;
```

这个例子讨论的是 PTE 尚未建立时的首次写入。MMU 无法完成翻译并产生异常后，Linux 才通过 VMA 判断访问是否合法：

```text
堆VMA：[0x600000, 0x620000)
访问VA：0x601234
结果：地址位于VMA内，并且VMA允许写
```

缺页处理完成后，PTE 保存逐页映射：

```text
VA页0x601000 → PTE → PFN 900
```

从这时开始，后续正常 load/store 的硬件翻译不再读取 VMA，也不读取 `struct page`。

对于这个示例中的普通系统内存页，Linux 可以从 PFN 找到页面管理对象和物理页基地址：

```c
struct page *page = pfn_to_page(900);
unsigned long pfn = page_to_pfn(page);   /* 900 */
phys_addr_t page_pa = page_to_phys(page); /* 0x384000 */
void *kernel_page_va = page_address(page); /* 内核访问该页数据的VA */
```

`kernel_page_va` 的具体数值取决于 ARM64 内核虚拟地址布局，本章不把它假设成一个固定地址。但是，它覆盖的页面内容与用户 `VA 0x601000` 映射到的是同一个物理页框：

```text
用户写入：VA 0x601234
内核查看：kernel_page_va + 0x234

两条路径最终都访问PFN 900中的offset 0x234
```

原 VA 的页内偏移仍然是 `0x234`，所以最终物理地址为：

```text
物理页基地址 = 900 × 0x1000 = 0x384000
页内offset   = 0x234

最终PA       = 0x384000 + 0x234
             = 0x384234
```

软件管理对象和硬件翻译不是一条连续访问路径，需要分成三个视角。

第一，首次缺页时，Linux 使用软件管理对象准备映射：

```text
MMU发现VA 0x601234对应的PTE无效
                  │
                  ▼
             进入Linux
                  │
                  ▼
           current->mm
             │
             ├─ mm_mt → 查找堆VMA并确认允许写入
             │
             └─ pgd   → 取得根页表
                              │
                              ▼
                       Linux逐级查找页表
                    （缺少中间页表时先创建）
                              │
                              ▼
                 找到VA页0x601000对应的末级PTE槽位
                              │ 写入
                              ▼
                    PFN 900 + 有效位 + 访问属性
                              │
                              ▼
                         返回用户态
```

`pgd` 只是根页表指针，不会主动“安装”PTE。真正执行逐级查找、必要时创建中间页表并写入末级 PTE 的，是 Linux 的缺页处理代码。写入完成后，PTE 才建立了虚拟页 `0x601000` 到 `PFN 900` 的逐页映射。

第二，PTE 已经有效后，CPU 和 MMU 完成正常硬件翻译：

```text
CPU执行load/store，产生VA 0x601234
                  │
                  ▼
                 MMU
                  │
                  ├─ TLB命中 → 直接取得缓存的翻译结果
                  │
                  └─ TLB未命中
                       └─ 根据TTBR0_EL1遍历页表
                              └─ PTE → PFN 900
                  │
                  ▼
物理页基地址0x384000 + offset 0x234
                  │
                  ▼
             PA 0x384234
                  │
                  ▼
               实际数据
```

这条正常硬件路径不读取 `mm_struct`、VMA、`struct page`、folio 或 rmap。MMU 只使用 TLB、TTBR 和页表描述符。

第三，`struct page` 不是另一条地址翻译路径，而是 Linux 管理物理页时使用的元数据。先把物理页中的实际数据和它的管理对象分开：

```text
物理内存中的实际数据                 Linux保存的管理信息

PFN 900对应的物理页                  pfn_to_page(900)
┌────────────────────┐                     │
│      4 KiB数据      │                     ▼
└────────────────────┘               struct page元数据
```

`pfn_to_page(900)` 只表示“根据 PFN 找到对应的 `struct page`”，不是页表遍历。实际内核代码也可能本来就已经持有 `struct page *`，不一定每次都从 PFN 开始转换。

Linux 拿到 `struct page` 后，会根据当前目的选择不同操作；下面三个分支不会依次执行：

```text
struct page
   │
   ├─ 管理页面
   │    └─ 查看页面状态、引用数量以及所属folio等信息
   │
   ├─ 反查用户映射
   │    └─ 借助rmap关系寻找可能映射它的VMA和PTE
   │
   └─ 内核需要读写页面中的实际数据
        └─ page_address(page) → 取得本例中普通系统内存页的内核VA
```

只有最后一个分支涉及内核实际读写页面数据。例如内核要访问该页中偏移 `0x234` 的数据：

```text
page_address(page) + 0x234
             │ 内核代码把它作为VA进行load/store
             ▼
            MMU
             │ 通过内核页表翻译
             ▼
        PA 0x384234
```

因此，PTE 是 MMU 硬件翻译使用的描述符；VMA 帮助 Linux 在缺页等软件处理过程中判断规则；`struct page`、folio 和 rmap 服务于 Linux 的物理页管理。用户程序正常执行 load/store 时，MMU 使用 TLB 和页表，不读取 VMA、`struct page`、folio 或 rmap。

### 3.10 本章总结与源码索引

本章结论如下：

1. PA 是字节地址，PFN 是物理页框编号，页内 offset 在地址翻译前后保持不变。
2. `struct page` 是物理页的管理元数据，不是物理页数据本身。
3. 对具有有效页面元数据的系统内存页，PFN 与 `struct page` 可以互相定位。
4. 普通系统内存页通常具有 linear-map 内核地址；`struct page *` 与指向页面数据的内核地址不是同一个指针。
5. folio 是 Linux 管理一个或多个连续基础页的对象，不替代 PTE 进行硬件翻译。
6. VMA 描述一段 VA 的共同规则，PTE 保存逐页映射，PFN 标识物理页框，`struct page` 保存该页的管理状态。
7. 页表完成 VA 到 PFN 的正向映射；rmap 帮助 Linux 从页面反查可能映射它的 VMA 和 PTE。
8. 页面引用数量和用户页表映射数量不是同一个概念；同一个物理页可以被多个 PTE 指向。
9. 固定已有页面首先解决设备访问期间的页面生命周期问题，不等于申请页面，也不等于建立 DMA 或 GPU 映射。

```text
正常硬件翻译：
CPU产生VA
   │
   ▼
  MMU
   ├─ TLB命中   → 使用缓存的翻译结果 → PA
   └─ TLB未命中 → 遍历页表并读取PTE  → PA

Linux软件管理：
mm_struct
├─ mm_mt中的VMA → 描述地址范围和访问规则
└─ pgd           → Linux管理该地址空间的页表

物理页管理：
PFN → struct page
       ├─ page_address()取得内核访问地址
       ├─ folio表达页面管理单位
       └─ rmap帮助反查用户映射
```

> **[SOURCE]** 本章本地源码索引：
>
> | 主题                       | Linux`248951ddc14d` 源码路径                                                                                                                                                                                               |
> | -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
> | PFN 与物理地址             | [include/linux/pfn.h](./2.源码/linux/include/linux/pfn.h)                                                                                                                                                                     |
> | `struct page` 与 folio   | [include/linux/mm_types.h](./2.源码/linux/include/linux/mm_types.h)                                                                                                                                                           |
> | PFN 与`struct page` 转换 | [include/asm-generic/memory_model.h](./2.源码/linux/include/asm-generic/memory_model.h)                                                                                                                                       |
> | ARM64 PTE、PFN 与页面      | [arch/arm64/include/asm/pgtable.h](./2.源码/linux/arch/arm64/include/asm/pgtable.h)                                                                                                                                           |
> | ARM64 linear map           | [arch/arm64/include/asm/memory.h](./2.源码/linux/arch/arm64/include/asm/memory.h)、[include/linux/mm.h](./2.源码/linux/include/linux/mm.h)、[include/linux/highmem-internal.h](./2.源码/linux/include/linux/highmem-internal.h) |
> | PFN 有效性边界             | [include/linux/mmzone.h](./2.源码/linux/include/linux/mmzone.h)                                                                                                                                                               |
> | 反向映射                   | [include/linux/rmap.h](./2.源码/linux/include/linux/rmap.h)、[include/linux/fs.h](./2.源码/linux/include/linux/fs.h)                                                                                                           |
> | 页面引用                   | [include/linux/page_ref.h](./2.源码/linux/include/linux/page_ref.h)                                                                                                                                                           |
> | 用户页面固定               | [Documentation/core-api/pin_user_pages.rst](./2.源码/linux/Documentation/core-api/pin_user_pages.rst)                                                                                                                         |

## 4. Linux 内存申请接口的职责边界

第 3 章已经说明 PFN、`struct page` 和物理页之间的关系。本章继续回答一个更实际的问题：

> 当程序或驱动说“申请一块内存”时，它到底得到了用户 VA、`struct page *`、内核 VA，还是设备使用的 DMA 地址？

本章只学习接口合同，不展开 buddy allocator、小对象分配器、页面回收等成熟内核机制的内部算法。需要抓住四件事：

1. 接口返回什么。
2. VA 和 PA 是否连续。
3. CPU 与设备分别使用哪个地址。
4. 应该调用哪个接口释放或解除映射。

### 4.1 同样申请 16 KiB，得到的对象可能不同

先从调用者看到的结果建立总框架：

```text
用户程序
   └─ malloc()             → 用户VA

Linux内核
   ├─ alloc_pages()        → struct page *
   ├─ kmalloc()            → 内核VA
   └─ vmalloc()            → 连续内核VA

设备驱动
   ├─ dma_alloc_coherent() → CPU访问地址 + DMA地址
   └─ dma_map_*()          → 为已有内存建立DMA地址
```

这些接口虽然都可能处理 16 KiB，但含义并不相同：

| 接口                        | 主要返回结果                | 底层 PFN 连续性                | 配对操作                 |
| --------------------------- | --------------------------- | ------------------------------ | ------------------------ |
| `malloc(16 KiB)`          | 用户指针，也就是用户 VA     | 不保证；页面还可能尚未按需分配 | `free()`               |
| `alloc_pages(..., 2)`     | 起始`struct page *`       | 4 个基础页物理连续             | `__free_pages(..., 2)` |
| `kmalloc(16 KiB, ...)`    | 可以直接解引用的内核 VA     | 返回的分配范围物理连续         | `kfree()`              |
| `vmalloc(16 KiB)`         | 可以直接解引用的连续内核 VA | 不保证，可以映射离散物理页     | `vfree()`              |
| `dma_alloc_coherent(...)` | CPU 地址和`dma_addr_t`    | 不应由驱动自行假设 PA 布局     | `dma_free_coherent()`  |

`malloc()` 与 `free()` 属于用户态分配器，前文已经介绍它们与 VMA、按需分配的关系。下面重点看 GPU 驱动源码中更常见的内核接口。

### 4.2 `alloc_pages()`：直接申请物理页

`alloc_pages()` 的返回值是起始 `struct page *`，第二个参数 `order` 决定连续基础页的数量：

```text
页面数量 = 2^order
总字节数 = 2^order × PAGE_SIZE
```

继续使用 4 KiB 基础页面：

| order | 页面数量 | 总大小 |
| ----: | -------: | -----: |
|     0 |        1 |  4 KiB |
|     1 |        2 |  8 KiB |
|     2 |        4 | 16 KiB |
|     9 |      512 |  2 MiB |

例如：

```c
struct page *page;

page = alloc_pages(GFP_KERNEL, 2);
if (page == NULL)
    return -ENOMEM;

/* 使用完成后，order必须与申请时一致 */
__free_pages(page, 2);
```

假设返回页面的起始 PFN 是 900，那么这次分配得到：

```text
page → 起始struct page
         │
         └─ 对应4个连续物理页

PFN 900 → [0x384000, 0x385000)
PFN 901 → [0x385000, 0x386000)
PFN 902 → [0x386000, 0x387000)
PFN 903 → [0x387000, 0x388000)
```

这里要注意：

- `struct page *` 是页面管理对象指针，不是返回给用户进程的 VA。
- `alloc_page(gfp)` 等价于 `alloc_pages(gfp, 0)`。
- `GFP_KERNEL` 是分配行为标志；本章不展开完整 GFP 标志体系。
- `__free_pages()` 必须使用与申请时一致的 `order`。

`order = 9` 表示获得 512 个连续 4 KiB 物理页，但这并不自动建立 2 MiB PMD Block 映射。物理页分配和页表描述符安装是两件不同的事。

> **[SOURCE]** 本地 Linux `248951ddc14d`：[include/linux/gfp.h](./2.源码/linux/include/linux/gfp.h) 第 331～396 行定义 `alloc_pages()`、`alloc_page()` 及释放接口；[mm/page_alloc.c](./2.源码/linux/mm/page_alloc.c) 第 5402～5449 行说明 `alloc_pages()` 与 `__free_pages()`、`__get_free_pages()` 与 `free_pages()` 的配对关系。

### 4.3 `kmalloc()` 与 `vmalloc()`：都返回内核 VA，但连续性不同

这两个接口都返回内核可以直接解引用的地址，但它们解决的问题不同。

`kmalloc()` 适合内核对象和相对较小的通用缓冲区：

```c
void *buffer;

buffer = kmalloc(16 * 1024, GFP_KERNEL);
if (buffer == NULL)
    return -ENOMEM;

/* CPU可以直接读写buffer */

kfree(buffer);
```

可以先按下面的关系理解：

```text
kmalloc()返回的连续内核VA

内核VA页0 → PFN 500
内核VA页1 → PFN 501
内核VA页2 → PFN 502
内核VA页3 → PFN 503

VA连续，PFN也连续
```

`vmalloc()` 则用一组物理页组成连续的内核虚拟地址：

```c
void *buffer;

buffer = vmalloc(16 * 1024);
if (buffer == NULL)
    return -ENOMEM;

/* CPU同样可以直接读写buffer */

vfree(buffer);
```

它的页表关系可以是：

```text
vmalloc()返回的连续内核VA

内核VA页0 → PFN 100
内核VA页1 → PFN 900
内核VA页2 → PFN 320
内核VA页3 → PFN 700

VA连续，PFN可以离散
```

因此：

| 接口          | CPU 看到的内核 VA | 底层物理页 | 典型用途                       |
| ------------- | ----------------- | ---------- | ------------------------------ |
| `kmalloc()` | 连续              | 连续       | 内核对象、较小缓冲区           |
| `vmalloc()` | 连续              | 可以离散   | 不要求物理连续的较大内核缓冲区 |

常见变体有三个：

| 接口           | 与基础接口的区别                                    | 释放接口     |
| -------------- | --------------------------------------------------- | ------------ |
| `kzalloc()`  | `kmalloc()` 后保证内容清零                        | `kfree()`  |
| `vzalloc()`  | `vmalloc()` 后保证内容清零                        | `vfree()`  |
| `kvmalloc()` | 先尝试`kmalloc()`，失败后允许回退到 `vmalloc()` | `kvfree()` |

`kmalloc()` 返回的只是 CPU 使用的内核 VA，并不会自动产生设备可用的 DMA 地址。`vmalloc()` 的底层页面可能离散，因此也不能把返回指针当成一段连续 PA。

> **[SOURCE]** 本地 Linux `248951ddc14d`：[Documentation/core-api/memory-allocation.rst](./2.源码/linux/Documentation/core-api/memory-allocation.rst) 第 132～186 行比较 `kmalloc()`、`vmalloc()`、`kvmalloc()` 及释放接口；[mm/vmalloc.c](./2.源码/linux/mm/vmalloc.c) 第 4165～4223 行说明 `vmalloc()`、`vzalloc()` 分配页面并建立连续内核 VA；[include/linux/slab.h](./2.源码/linux/include/linux/slab.h) 第 1288～1400 行定义 `kzalloc()`、`kvmalloc()` 和 `kvfree()`。

### 4.4 DMA 地址是设备视角的地址

CPU 使用 `kmalloc()` 返回的内核 VA 访问缓冲区时，经过的是 CPU MMU：

```text
CPU使用内核VA X
       │
       ▼
CPU页表
       │
       ▼
系统RAM中的PA Y
```

设备发起 DMA 时不会拿着内核 VA X 去遍历 CPU 页表。驱动必须通过 DMA API 得到设备应该使用的地址：

```text
设备使用DMA地址 Z
       │
       ├─ 没有IOMMU：平台可能直接把它路由到目标物理地址
       │
       └─ 存在IOMMU：Z可以是IOVA，再由IOMMU翻译到PA Y
                              │
                              ▼
                       系统RAM中的PA Y
```

因此：

```text
内核VA X、PA Y、DMA地址 Z
可能数值不同，但可以指向同一份缓冲区数据
```

Linux 使用 `dma_addr_t` 保存 DMA API 返回的设备地址。驱动应该把该地址交给设备，而不是自行把 CPU 指针转换成物理地址。

> **[SOURCE]** 本地 Linux `248951ddc14d`：[Documentation/core-api/dma-api-howto.rst](./2.源码/linux/Documentation/core-api/dma-api-howto.rst) 第 40～115 行区分 CPU VA、CPU PA、总线地址和 IOMMU 翻译；[include/linux/dma-mapping.h](./2.源码/linux/include/linux/dma-mapping.h) 第 107～116 行说明 `dma_addr_t` 保存平台有效的 DMA 或总线地址。

### 4.5 `dma_alloc_coherent()`：申请内存并取得 DMA 地址

`dma_alloc_coherent()` 面向这样的需求：驱动希望申请一块缓冲区，并让 CPU 和某个设备在较长时间内反复访问它。这个接口一次完成两件事：

1. 为缓冲区准备实际存储。
2. 按该设备所在平台的 DMA 规则，准备设备可使用的 DMA 地址。

#### 4.5.1 调用前先声明设备的 DMA 寻址能力

设备不一定能产生任意宽度的 DMA 地址。例如，有的设备只能使用 32 位地址，有的设备支持 64 位地址。驱动通常在设备初始化阶段先声明这种能力：

```c
/* 这个例子假设设备确实支持64位DMA地址 */
ret = dma_set_mask_and_coherent(dev, DMA_BIT_MASK(64));
if (ret)
    return ret;
```

`dma_set_mask_and_coherent()` 同时设置普通 streaming DMA 和 coherent DMA 使用的地址掩码。这里不能一律照抄 64 位；驱动必须填写设备实际支持的宽度。

传给 DMA API 的 `dev` 也不只是一个归属标签。DMA 层会根据它确定：

```text
设备可以使用多宽的DMA地址
设备是否位于某个IOMMU域中
平台应该采用哪套DMA分配与映射操作
```

因此，同样调用 `dma_alloc_coherent()`，不同设备和平台可能采用不同的底层实现。

#### 4.5.2 一块缓冲区，两个地址

下面申请 16 KiB coherent DMA 缓冲区：

```c
size_t size = 16 * 1024;
dma_addr_t dma_handle;
void *cpu_addr;

cpu_addr = dma_alloc_coherent(dev, size,
                              &dma_handle, GFP_KERNEL);
if (cpu_addr == NULL)
    return -ENOMEM;
```

一次成功调用返回两个不同地址，但它们对应的是同一块缓冲区：

| 返回值         | 所属地址空间         | 使用者 | 正确用途                         |
| -------------- | -------------------- | ------ | -------------------------------- |
| `cpu_addr`   | CPU 内核虚拟地址空间 | CPU    | 驱动通过普通指针读写缓冲区       |
| `dma_handle` | 设备 DMA 地址空间    | 设备   | 驱动写入设备描述符或设备控制状态 |

可以把两条访问路径画成：

```text
CPU访问：

cpu_addr + offset
        │
        ▼
CPU页表
        │
        └──────────────────┐
                           ▼
                    缓冲区的第offset字节
                           ▲
        ┌──────────────────┘
        │
设备访问：

dma_handle + offset
        │
        ▼
DMA直连转换或IOMMU
```

例如，CPU 通过 `cpu_addr + 0x100` 写入的数据，与设备通过 `dma_handle + 0x100` 访问的数据位置相同。

`dma_handle` 在简单平台上可能接近系统物理地址；存在 IOMMU 时，它可能是 IOVA。无论是哪种情况，驱动都只把它当作设备地址使用：

```text
CPU不能把dma_handle当成指针解引用
设备不能拿cpu_addr去遍历CPU页表
驱动不能用virt_to_phys(cpu_addr)代替DMA API返回值
```

`cpu_addr` 表示一段连续的 CPU 内核 VA，`dma_handle` 表示设备可从该基址访问指定大小的 DMA 区域；这仍然不能推出底层 PFN 一定连续，也不能推出 DMA 地址必然等于 PA。

从 Linux 实现入口看，调用关系可以先简化为：

```text
dma_alloc_coherent()
        │
        ▼
dma_alloc_attrs()
        │
        ├─ 设备专用coherent内存区域
        ├─ direct DMA分配
        ├─ IOMMU DMA分配
        └─ 平台提供的dma_map_ops
                │
                ▼
       返回cpu_addr和dma_handle
```

驱动使用统一 DMA API，不需要根据当前机器是否存在 IOMMU 自己选择这些分支。

#### 4.5.3 coherent 保证可见性，不保证执行顺序

这里的 coherent 主要解决 CPU Cache 与设备访问之间的数据可见性问题。CPU 和设备可以反复访问这块缓冲区，通常不需要像 streaming DMA 映射那样，在每次交接前后调用 `dma_sync_*()` 做显式缓存维护。

但是，“数据能够保持一致”与“各次访问按照正确顺序发生”是两件事：

| 问题                   | coherent 是否自动解决 | 驱动还需要做什么                   |
| ---------------------- | --------------------- | ---------------------------------- |
| CPU 与设备的缓存可见性 | 是                    | 通常不需要逐次调用`dma_sync_*()` |
| 多个字段的读写顺序     | 否                    | 使用适合的 DMA 内存屏障            |
| 缓冲区当前归谁使用     | 否                    | 通过状态字段或驱动协议交接所有权   |
| 设备操作是否已经完成   | 否                    | 等待中断、完成状态或其他完成通知   |
| 内存现在能否释放       | 否                    | 确保设备不会再访问后才能释放       |

例如，CPU 先填写描述符内容，再把描述符所有权交给设备：

```c
desc->buffer_addr = dma_handle;
desc->length = size;

dma_wmb();                 /* 先让前面的内容按顺序对设备可见 */

desc->status = DEVICE_OWN;
```

如果缺少必要的屏障，CPU 可能先让设备看到 `DEVICE_OWN`，设备随后读取描述符时却还看不到完整的地址或长度。coherent 不会替驱动建立这种先后顺序。

#### 4.5.4 从分配到释放的完整生命周期

coherent DMA 缓冲区通常会保持较长时间，而不是每次 DMA 操作都重新分配：

```text
设备初始化阶段设置DMA mask
             │
             ▼
dma_alloc_coherent()
             │
             ├─ CPU保存cpu_addr
             └─ 驱动保存dma_handle
             │
             ▼
CPU填写描述符或控制数据
             │
             ▼
通过屏障和状态字段把所有权交给设备
             │
             ▼
设备使用dma_handle发起DMA访问
             │
             ▼
驱动等待设备完成，再读取或复用缓冲区
             │
             ▼
设备停止且不再访问
             │
             ▼
dma_free_coherent()
```

释放时必须使用与分配时配对的参数：

```c
dma_free_coherent(dev, size, cpu_addr, dma_handle);
```

其中 `dev` 和 `size` 必须与分配时一致，两个地址也必须使用该次分配返回的原值。`dma_free_coherent()` 同时解除相应 DMA 资源并释放缓冲区；这类分配不使用 `dma_unmap_*()` 释放。

使用 `GFP_KERNEL` 表示这次分配允许睡眠，适合普通进程上下文。本章不展开其他 GFP 组合；分配上下文必须与 GFP 选择相符。

#### 4.5.5 适用范围

coherent DMA 内存常用于 CPU 和设备都会频繁访问、并且通常长期存在的控制结构，例如：

```text
DMA描述符
命令环或队列的控制数据
状态区
设备需要读取的固件或小型控制缓冲区
```

`dma_alloc_coherent()` 没有单独的 DMA 方向参数；在 DMA API 中，这类分配按双向访问处理。它也不表示所有设备数据都适合放入 coherent 内存：如果缓冲区已经由其他接口创建，或者只是用于一次数据传输，下一节的 streaming DMA 映射通常更合适。

> **[BOUNDARY]** `dma_alloc_coherent()` 是通用设备 DMA 接口，不代表大型 GPU 缓冲对象都由它分配。GPU 缓冲对象还会组合 system RAM、VRAM、SG 表、GPU VA 和放置策略；本节只建立 coherent DMA 缓冲区的通用使用模型。

> **[SOURCE]** 本地 Linux `248951ddc14d`：[include/linux/dma-mapping.h](./2.源码/linux/include/linux/dma-mapping.h) 第 614～624 行定义 `dma_alloc_coherent()` 和 `dma_free_coherent()`，第 641～646 行定义 `dma_set_mask_and_coherent()`；[kernel/dma/mapping.c](./2.源码/linux/kernel/dma/mapping.c) 第 625～696 行展示 coherent 分配和释放如何选择设备专用区域、direct DMA、IOMMU 或平台 DMA 操作；[Documentation/core-api/dma-api-howto.rst](./2.源码/linux/Documentation/core-api/dma-api-howto.rst) 第 201～235 行说明 DMA mask，第 348～390 行区分 coherent 的可见性与访问顺序，第 420～464 行说明分配、返回值和配对释放，第 511～554 行说明 DMA 方向；[Documentation/memory-barriers.txt](./2.源码/linux/Documentation/memory-barriers.txt) 第 1914～1955 行说明 `dma_rmb()`、`dma_wmb()` 与 CPU—设备共享内存的顺序保证。

### 4.6 `dma_map_*()`：为已有内存建立 DMA 映射

这里的“已有内存”是指：调用 `dma_map_*()` 前，驱动或其他内核子系统已经通过其他接口取得用于存放数据的缓冲区或物理页。例如：

```text
kmalloc()返回的内核缓冲区
alloc_page()返回的struct page
其他子系统交给驱动的一组页面或SG列表
```

这些内存已经可以保存数据，但设备不能使用 CPU 内核指针访问它们。`dma_map_*()` 的主要作用，是根据 `dev` 所代表设备的 DMA 能力，为原来的内存准备设备可使用的 DMA 地址。

它与上一节接口的区别是：

| 接口                     | 调用前是否已有数据内存 | 主要工作                           |
| ------------------------ | ---------------------- | ---------------------------------- |
| `dma_alloc_coherent()` | 否                     | 申请缓冲区并返回 CPU、DMA 两种地址 |
| `dma_map_*()`          | 是                     | 为原有缓冲区或页面准备 DMA 地址    |

三个常见入口分别接收不同形式的已有内存：

| 接口                 | 已有内存的表示方式                       | 主要返回结果              |
| -------------------- | ---------------------------------------- | ------------------------- |
| `dma_map_single()` | `kmalloc()` 等接口得到的连续内核缓冲区 | 一个 DMA 地址             |
| `dma_map_page()`   | `struct page * + 页内offset + size`    | 一个 DMA 地址             |
| `dma_map_sg()`     | 多个内存段组成的 SG 列表                 | 一个或多个设备可用 DMA 段 |

以 `kmalloc()` 得到的 16 KiB 缓冲区为例，完整顺序是：

```c
size_t size = 16 * 1024;
void *buffer;
dma_addr_t dma_addr;

buffer = kmalloc(size, GFP_KERNEL);
if (buffer == NULL)
    return -ENOMEM;

/* CPU通过buffer填写准备交给设备的数据 */

dma_addr = dma_map_single(dev, buffer, size, DMA_TO_DEVICE);
if (dma_mapping_error(dev, dma_addr)) {
    kfree(buffer);
    return -EIO;
}

/* 把dma_addr和size交给设备 */
/* 等待设备完成读取 */

dma_unmap_single(dev, dma_addr, size, DMA_TO_DEVICE);

kfree(buffer);
```

调用 `dma_map_single()` 前，只有 CPU 访问路径：

```text
buffer（CPU内核VA）
       │
       ▼
CPU页表
       │
       ▼
原来的数据页面
```

调用成功后，原来的缓冲区没有被替换，只是增加了设备访问路径：

```text
CPU访问：

buffer（CPU内核VA）
       │
       ▼
CPU页表 ──────────────────┐
                          ▼
                   原来的数据页面
                          ▲
设备访问：                │
                          │
dma_addr（DMA地址）        │
       │                  │
       ▼                  │
DMA直连转换或IOMMU ───────┘
```

因此，`dma_map_single()` 返回的是设备地址，不是新的 CPU 指针。驱动继续通过 `buffer` 访问数据，把 `dma_addr` 交给设备。

示例中的 `DMA_TO_DEVICE` 表示主要数据方向是 CPU 准备数据、设备读取数据。常见方向可以先这样理解：

| 方向                  | 主要数据流向       |
| --------------------- | ------------------ |
| `DMA_TO_DEVICE`     | CPU → 设备        |
| `DMA_FROM_DEVICE`   | 设备 → CPU        |
| `DMA_BIDIRECTIONAL` | 两个方向都可能发生 |

方向会影响 DMA 层执行的缓存维护和访问属性，映射与解除映射时必须使用相同的方向。

如果驱动已经持有单个 `struct page`，可以改用：

```c
dma_addr = dma_map_page(dev, page, offset, size, DMA_TO_DEVICE);
```

它表达的仍然是同一件事：

```text
已有struct page
       │
       └─ dma_map_page()
                │
                ▼
          设备可用DMA地址

页面本身早已存在，dma_map_page()不是物理页分配接口
```

如果缓冲区由多个离散页面组成，可以先组织成 SG 列表，再调用 `dma_map_sg()`。DMA 实现可能通过 IOMMU 映射或合并相邻条目改变设备最终看到的段数，因此驱动必须使用 `dma_map_sg()` 返回的 DMA 段数量和映射后地址。

`dma_map_*()` 通常建立的是 streaming DMA 映射，具有明确的方向和使用期限。必须先等待设备完成访问，再调用配对的 `dma_unmap_*()`，最后才能释放原来的缓冲区。不能因为物理页仍然存在，就省略 DMA 地址空间和缓存一致性相关的解除映射操作。

不是任意内核指针都能直接传给 `dma_map_single()`。本节示例使用 `kmalloc()` 返回的缓冲区；`vmalloc()` 返回的是连续内核 VA，但底层页面可能离散，不能把这个指针直接当作一段普通连续 DMA 缓冲区映射。

> **[BOUNDARY]** DMA 层在实现映射时可能建立 IOMMU 页表、执行缓存维护，或者在受限平台上使用临时转换资源。“`dma_map_*()` 不申请数据内存”指的是它不会为驱动创建一块新的、用来替代原缓冲区的业务数据对象。

> **[SOURCE]** 本地 Linux `248951ddc14d`：[include/linux/dma-mapping.h](./2.源码/linux/include/linux/dma-mapping.h) 第 603～608 行定义 `dma_map_single/page/sg()` 与解除映射接口；[Documentation/core-api/dma-api-howto.rst](./2.源码/linux/Documentation/core-api/dma-api-howto.rst) 第 119～143 行说明可用于 DMA 的普通内核内存及 `vmalloc()` 边界，第 511～554 行定义 DMA 方向，第 565～676 行给出 single、page、SG 映射及配对解除映射规则。

### 4.7 三类看起来像“申请内存”、实际不是的接口

下面三个接口会改变地址可见性或页面生命周期，但它们的主要职责不是从通用分配器创建一块新缓冲区：

| 接口                  | 已有对象                     | 主要作用                                  | 配对或后续操作            |
| --------------------- | ---------------------------- | ----------------------------------------- | ------------------------- |
| `ioremap()`         | 已有设备物理资源或寄存器范围 | 建立内核 MMIO VA                          | `iounmap()`             |
| `pin_user_pages()`  | 已有用户 VA 范围             | 找到并固定对应页面，返回`struct page *` | `unpin_user_pages()` 等 |
| `remap_pfn_range()` | 已有 PFN 范围和用户 VMA      | 向用户页表建立 PFN 映射                   | 随 VMA 解除映射           |

`ioremap()` 的关系是：

```text
已有设备地址范围
       │
       └─ ioremap()
              │
              ▼
       内核可使用的MMIO VA
```

它不是申请一段新的系统 RAM。

`pin_user_pages()` 面向一个已经存在的用户 VA 范围。处理过程中可能需要让相应页面变得可用，但接口目的仍是取得并固定这些页面，而不是创建一个与原用户内存无关的新缓冲区。

`remap_pfn_range()` 则把已有 PFN 暴露到用户 VMA。驱动如何选择它、`vmf_insert_page()` 或 fault 回调，留到 GPU 驱动用户映射阶段。

> **[SOURCE]** 本地 Linux `248951ddc14d`：[arch/arm64/include/asm/io.h](./2.源码/linux/arch/arm64/include/asm/io.h) 第 264～289 行定义 `ioremap()`；[mm/gup.c](./2.源码/linux/mm/gup.c) 第 3359～3388 行说明 `pin_user_pages()` 为设备固定用户页面并要求使用 unpin 接口释放；[include/linux/mm.h](./2.源码/linux/include/linux/mm.h) 第 4532～4534 行声明 `remap_pfn_range()`。

### 4.8 用同一个 16 KiB 需求完成比较

假设不同调用者都说“我需要 16 KiB”，可以得到五种完全不同的结果：

```text
malloc(16 KiB)
   └─ 连续用户VA；PFN不保证连续，页面还可能尚未分配

alloc_pages(GFP_KERNEL, 2)
   └─ 起始struct page *；4个连续PFN

kmalloc(16 KiB, GFP_KERNEL)
   └─ 连续内核VA；返回范围对应连续物理内存

vmalloc(16 KiB)
   └─ 连续内核VA；PFN可以离散

dma_alloc_coherent(dev, 16 KiB, ...)
   ├─ CPU使用cpu_addr
   └─ 设备使用dma_handle
```

统一比较如下：

| 需求                         | 合适的核心接口           | 调用者得到什么      | 不能据此推出什么            |
| ---------------------------- | ------------------------ | ------------------- | --------------------------- |
| 用户程序获得 16 KiB          | `malloc()`             | 用户 VA             | PFN 连续或页面已经驻留      |
| 内核获得 4 个连续物理页      | `alloc_pages(..., 2)`  | `struct page *`   | 用户 VA 或 DMA 地址已经建立 |
| 内核获得普通缓冲区           | `kmalloc()`            | 内核 VA             | 设备可以直接使用该指针      |
| 内核只要求大块连续 VA        | `vmalloc()`            | 连续内核 VA         | PA 连续                     |
| 驱动申请 coherent DMA 缓冲区 | `dma_alloc_coherent()` | CPU 地址和 DMA 地址 | DMA 地址必然等于 CPU PA     |
| 驱动让设备访问已有页面       | `dma_map_page/sg()`    | DMA 地址或 DMA 段   | 新页面被分配                |

选择接口时，应先判断调用者需要哪类对象和哪类地址，不能只看申请的字节数。

### 4.9 从 Linux 内存接口过渡到 GPU 缓冲对象

GPU 缓冲对象通常会同时涉及多个层次：

```text
GPU缓冲对象
   │
   ├─ 管理元数据
   │    └─ 可能来自kmalloc()/kzalloc()
   │
   ├─ 实际backing
   │    ├─ system RAM页面
   │    └─ 或设备VRAM
   │
   ├─ 设备访问地址
   │    └─ DMA地址或IOVA
   │
   ├─ CPU用户态访问
   │    └─ VMA和CPU页表映射
   │
   └─ GPU访问
        └─ GPU VA和GPU页表映射
```

这些层次不是同一个对象：

- 分配一个管理结构，不等于已经获得缓冲区 backing。
- 获得 `struct page`，不等于设备已经拥有 DMA 地址。
- 获得 DMA 地址，不等于 GPU 页表已经建立 GPU VA 映射。
- 建立 GPU VA 映射，也不自动建立 CPU 用户 VA 映射。

[BOUNDARY] 上图只建立进入 GPU 内存管理前的分层关系，不表示所有 GPU 缓冲区都调用同一组 Linux 接口。后续学习 GEM、TTM、VRAM 放置和 GPU 虚拟内存管理时，再追踪具体对象如何组合这些层次。

### 4.10 本章总结与源码索引

本章结论如下：

1. “申请 16 KiB”不能确定返回的是哪类对象，必须先看调用者和接口。
2. `alloc_pages()` 返回 `struct page *`；`order` 决定连续基础页数量。
3. `kmalloc()` 和 `vmalloc()` 都返回内核 VA，但后者不要求 PFN 连续。
4. `GFP_KERNEL` 等 GFP 值描述分配行为，不是地址类型。
5. 设备不能直接使用普通 CPU 指针，驱动应通过 DMA API 得到 `dma_addr_t`。
6. `dma_alloc_coherent()` 为同一缓冲区返回 CPU 地址和 DMA 地址；coherent 解决缓存可见性，不替代内存顺序和设备完成同步；`dma_map_*()` 则映射已有内存。
7. `ioremap()`、`pin_user_pages()` 和 `remap_pfn_range()` 的主要职责不是申请新缓冲区。
8. GPU 缓冲对象的元数据、backing、DMA 地址、CPU 映射和 GPU VA 映射属于不同层次。

| 主题                                           | Linux`248951ddc14d` 本地源码                                                                                                                                                                                                                                     |
| ---------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 物理页申请与释放                               | [include/linux/gfp.h](./2.源码/linux/include/linux/gfp.h)、[mm/page_alloc.c](./2.源码/linux/mm/page_alloc.c)                                                                                                                                                         |
| 内核通用分配接口选择                           | [Documentation/core-api/memory-allocation.rst](./2.源码/linux/Documentation/core-api/memory-allocation.rst)                                                                                                                                                         |
| `kmalloc()`、`kzalloc()` 与 `kvmalloc()` | [include/linux/slab.h](./2.源码/linux/include/linux/slab.h)                                                                                                                                                                                                         |
| `vmalloc()` 与 `vfree()`                   | [mm/vmalloc.c](./2.源码/linux/mm/vmalloc.c)                                                                                                                                                                                                                         |
| DMA 地址、coherent 与映射接口                  | [include/linux/dma-mapping.h](./2.源码/linux/include/linux/dma-mapping.h)、[Documentation/core-api/dma-api-howto.rst](./2.源码/linux/Documentation/core-api/dma-api-howto.rst)、[Documentation/memory-barriers.txt](./2.源码/linux/Documentation/memory-barriers.txt) |
| `ioremap()`                                  | [arch/arm64/include/asm/io.h](./2.源码/linux/arch/arm64/include/asm/io.h)                                                                                                                                                                                           |
| 用户页面固定                                   | [mm/gup.c](./2.源码/linux/mm/gup.c)、[Documentation/core-api/pin_user_pages.rst](./2.源码/linux/Documentation/core-api/pin_user_pages.rst)                                                                                                                           |
| PFN 映射进用户 VMA                             | [include/linux/mm.h](./2.源码/linux/include/linux/mm.h)                                                                                                                                                                                                             |

至此，CPU 侧需要的基础概念已经按学习顺序连接起来：

```text
用户VA和VMA
   ↓
CPU页表和PTE
   ↓
PFN和struct page
   ↓
Linux内存申请接口
   ↓
DMA地址
   ↓
下一阶段：GPU缓冲对象、GPU VA与GPU页表
```

这是一条知识层次关系，不是每次申请或访问内存都会依次执行的调用路径。例如普通 `kmalloc()` 缓冲区只有在设备确实需要访问时，才会继续建立 DMA 映射。
