# Linux 内存管理基础

## 缩写表

| 缩写                  | 英文全称                                                   | 中文含义                          |
| --------------------- | ---------------------------------------------------------- | --------------------------------- |
| AF                    | Access Flag                                                | 访问标志                          |
| AMDGPU                | AMD GPU Linux Kernel Driver                                | AMD GPU Linux 内核驱动            |
| AP                    | Access Permission                                          | 访问权限                          |
| ARM / ARM64           | Arm Architecture / Arm 64-bit Architecture                 | Arm 架构 / 64 位 Arm 架构         |
| ASID                  | Address Space Identifier                                   | 地址空间标识符                    |
| AttrIndx              | Attribute Index                                            | 内存属性索引                      |
| BADDR                 | Base Address                                               | 基地址                            |
| CLONE_VM              | Clone Virtual Memory flag                                  | 创建任务时共享虚拟地址空间的标志  |
| COW                   | Copy-on-Write                                              | 写时复制                          |
| CPU                   | Central Processing Unit                                    | 中央处理器                        |
| DMA                   | Direct Memory Access                                       | 直接内存访问                      |
| DSB                   | Data Synchronization Barrier                               | 数据同步屏障                      |
| EL0 / EL1             | Exception Level 0 / Exception Level 1                      | 异常级别 0 / 异常级别 1           |
| ELR_EL1               | Exception Link Register at Exception Level 1               | 异常级别 1 异常链接寄存器         |
| ERET                  | Exception Return                                           | 异常返回指令                      |
| GEM                   | Graphics Execution Manager                                 | 图形执行管理器                    |
| GPU                   | Graphics Processing Unit                                   | 图形处理器                        |
| HMM                   | Heterogeneous Memory Management                            | 异构内存管理                      |
| IPI                   | Inter-Processor Interrupt                                  | 处理器间中断                      |
| IRQ                   | Interrupt Request                                          | 中断请求                          |
| ISB                   | Instruction Synchronization Barrier                        | 指令同步屏障                      |
| KiB / MiB / GiB       | Kibibyte / Mebibyte / Gibibyte                             | 二进制千字节 / 兆字节 / 吉字节    |
| L0～L3                | Level 0 through Level 3                                    | 第 0 级到第 3 级页表              |
| LR                    | Link Register                                              | 链接寄存器                        |
| MAIR_EL1              | Memory Attribute Indirection Register at Exception Level 1 | 异常级别 1 内存属性间接寄存器     |
| MMU                   | Memory Management Unit                                     | 内存管理单元                      |
| MPU                   | Memory Protection Unit                                     | 内存保护单元                      |
| nG                    | non-Global                                                 | 非全局映射标志                    |
| NS                    | Non-secure                                                 | 非安全属性                        |
| PA                    | Physical Address                                           | 物理地址                          |
| PAN                   | Privileged Access Never                                    | 特权访问禁止                      |
| PC                    | Program Counter                                            | 程序计数器                        |
| PFN                   | Page Frame Number                                          | 物理页框编号                      |
| PID / TGID            | Process Identifier / Thread Group Identifier               | 任务标识符 / 线程组标识符         |
| PGD                   | Page Global Directory                                      | 页全局目录                        |
| PMD                   | Page Middle Directory                                      | 页中间目录                        |
| PSTATE                | Process State                                              | 处理器状态                        |
| PTE                   | Page Table Entry                                           | 页表项                            |
| pt_regs               | Linux structure name; regs means Registers                 | Linux 保存异常现场的寄存器结构体  |
| PUD                   | Page Upper Directory                                       | 页上级目录                        |
| PXN                   | Privileged Execute Never                                   | 特权级禁止执行                    |
| RET                   | Return                                                     | 函数返回指令                      |
| RTOS                  | Real-Time Operating System                                 | 实时操作系统                      |
| SH                    | Shareability                                               | 可共享属性                        |
| SIGSEGV               | Segmentation Violation Signal                              | 段错误信号                        |
| SP                    | Stack Pointer                                              | 栈指针                            |
| SP_EL0 / SP_EL1       | Stack Pointer at Exception Level 0 / 1                     | 异常级别 0 / 1 栈指针寄存器       |
| SPSR_EL1              | Saved Program Status Register at Exception Level 1         | 异常级别 1 保存程序状态寄存器     |
| T0SZ                  | TTBR0 Address Space Size Field                             | TTBR0 地址空间大小字段            |
| TCR_EL1               | Translation Control Register at Exception Level 1          | 异常级别 1 转换控制寄存器         |
| TG0                   | Translation Granule for TTBR0                              | TTBR0 的转换粒度字段              |
| TLB                   | Translation Lookaside Buffer                               | 地址转换后备缓冲器（快表）        |
| TLBI                  | Translation Lookaside Buffer Invalidate                    | TLB 无效化操作                    |
| TTBR0_EL1 / TTBR1_EL1 | Translation Table Base Register 0 / 1 at Exception Level 1 | 异常级别 1 转换表基址寄存器 0 / 1 |
| TTM                   | Translation Table Maps                                     | 转换表映射内存管理器              |
| UXN                   | Unprivileged Execute Never                                 | 非特权级禁止执行                  |
| VA                    | Virtual Address                                            | 虚拟地址                          |
| VM                    | Virtual Memory                                             | 虚拟内存                          |
| VMA                   | Virtual Memory Area                                        | 虚拟内存区域                      |
| VPN                   | Virtual Page Number                                        | 虚拟页号                          |
| VRAM                  | Video Random-Access Memory                                 | 显存                              |

> **[BOUNDARY]** 本文是早期的 ARM/MMU 引入草稿，停在问题定义处；完整且带本地 Linux/AMDGPU 源码基线的版本见 [2A. Linux 内存管理基础](<./1.笔记/2A. Linux 内存管理基础：从物理内存、PFN 与 struct page 到 GEM、TTM、HMM.md>)。

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

带操作系统的系统需要同时管理多个进程或任务。即使不使用虚拟地址，操作系统也可以通过 MPU、特权级等机制限制各任务能够访问的物理区域；但是，所有程序仍然共用同一套物理地址编号，程序使用的地址也会与实际物理位置直接绑定，由此带来下面的问题。

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

更准确地说，地址翻译按照页面进行：

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

这就引出了本文接下来需要解释的三个核心对象：

```text
Linux页表：保存VPN到PFN的映射关系
ARM MMU：按照页表完成地址翻译
TTBR（Translation Table Base Register，转换表基址寄存器）：告诉MMU根页表在哪里
  ├─ TTBR0_EL1（Translation Table Base Register 0, EL1）：Linux通常用于用户地址空间
  └─ TTBR1_EL1（Translation Table Base Register 1, EL1）：Linux通常用于内核地址空间
```

接下来的问题是：

> ARM MMU 如何从一个虚拟地址出发，通过 `TTBR` 和多级页表，一步一步找到最终物理地址？

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

特别注意：`0b11` 在不同 Level 的含义不同。

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

在 L3，`bits[1:0]=0b11` 不再表示 Table descriptor，而是表示 Page descriptor。也就是说，相同的类型位编码会根据当前层级产生不同含义。

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

PFN 的编号单位仍然是 4 KiB 基础页。2 MiB 映射不是“一个 PFN 变成了 2 MiB”，而是一个 Block descriptor 一次覆盖 512 个连续 PFN。

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

[SOURCE] Arm，[《Learn the Architecture: Memory Management》](<https://developer.arm.com/-/media/Arm%20Developer%20Community/PDF/Learn%20the%20Architecture/LearnTheArchitecture-MemoryManagement-101811_0100_00_en.pdf>)，Version 1.0，§7“Translation granule”、§7.1“The starting level of address translation”、§7.2“Registers that control address translation”。

[SOURCE] [Arm Architecture Reference Manual DDI 0487](https://developer.arm.com/documentation/ddi0487/mc/-Part-D-The-AArch64-System-Level-Architecture/-Chapter-D8-The-AArch64-Virtual-Memory-System-Architecture/-D8-2-Translation-process/-D8-2-8-VMSAv8-64-translation-using-the-4KB-granule?lang=en)，D8.2.8.1“VMSAv8-64 Stage 1 address translation using the 4KB translation granule”。

[SOURCE] Linux kernel [`Documentation/arch/arm64/memory.rst`](https://docs.kernel.org/arch/arm64/memory.html)，“Translation table lookup with 4KB pages”。

[SOURCE] Arm，[《Armv8-A Memory Model》](<https://developer.arm.com/-/media/Arm%20Developer%20Community/PDF/Learn%20the%20Architecture/Armv8-A%20memory%20model%20guide.pdf>)，§3“Describing memory in Armv8-A”、§8“Describing the memory type”、§10“Permissions attributes”、§11“Access Flag”。

[SOURCE] Linux kernel [`arch/arm64/include/asm/pgtable-hwdef.h`](https://github.com/torvalds/linux/blob/master/arch/arm64/include/asm/pgtable-hwdef.h)，ARM64 hardware page-table descriptor bit definitions。

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

> [SOURCE] 本章源码基线为本地 `2.源码/linux`，Git commit `248951ddc14de84de3910f9b13f51491a8cd91df`。该提交的根 `Makefile` 标识为 Linux `7.2.0-rc4` 开发阶段。

> [SOURCE] `arch/arm64` 已经展开到本地工作目录。本章引用的 ARM64 文件现在都可以从 `2.源码/linux/arch/arm64` 直接打开，并且属于上述同一提交。

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

[SOURCE] 本地 Linux `248951ddc14d`：[include/linux/sched.h](./2.源码/linux/include/linux/sched.h) 第 845、971～972、1071～1072 行；地址空间是否共享的实际分支见 [kernel/fork.c](./2.源码/linux/kernel/fork.c) 第 1568～1601 行。

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

这里的重点不是把 `SP_EL0` 当成普通内存，而是：ARM64 Linux 在内核执行期间利用这个寄存器快速保存当前任务指针。

[SOURCE] 本地 Linux `248951ddc14d`：[arch/arm64/include/asm/current.h](./2.源码/linux/arch/arm64/include/asm/current.h)，第 15～24 行。

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

[SOURCE] 本地 Linux `248951ddc14d`：`include/linux/sched.h:826` 定义 `task_struct`，`include/linux/sched.h:971-972` 定义 `mm` 与 `active_mm`；`Documentation/mm/active_mm.rst` 解释二者语义。

#### 2.1.4 多个任务可以共享一个地址空间

同一进程中的线程通常共享一个 `mm_struct`：

```text
task_struct A ──┐
task_struct B ──┼──→ 同一个mm_struct ──→ 同一组VMA和用户页表
task_struct C ──┘
```

因此，后面介绍的 ASID 更准确地说是标识地址空间，而不是简单标识某个 PID。

源码中的 `copy_mm()` 清楚地区分了共享与复制：

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

```text
带CLONE_VM创建线程 → 共享oldmm
普通fork创建子进程  → dup_mm()创建新的mm_struct
```

[SOURCE] 本地 Linux `248951ddc14d`：`kernel/fork.c:1518-1566` 的 `dup_mm()`，`kernel/fork.c:1568-1601` 的 `copy_mm()`。

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

从本地源码中抽取与本章相关的成员，可以简化为：

```c
struct mm_struct {
    atomic_t mm_count;
    struct maple_tree mm_mt;
    unsigned long mmap_base;
    unsigned long task_size;
    pgd_t *pgd;
    atomic_t mm_users;
    spinlock_t page_table_lock;
    struct rw_semaphore mmap_lock;
    unsigned long start_code, end_code, start_data, end_data;
    unsigned long start_brk, brk, start_stack;
    mm_context_t context;
    /* 还有大量统计、锁和子系统状态，此处省略 */
};
```

| 成员                       | 本章中的作用                                         |
| -------------------------- | ---------------------------------------------------- |
| `mm_mt`                  | Maple Tree，按虚拟地址管理该地址空间中的 VMA         |
| `mmap_base`              | `mmap()` 区域布局使用的基准地址                    |
| `task_size`              | 用户虚拟地址空间的上限                               |
| `pgd`                    | 根页表的内核虚拟地址指针                             |
| `mmap_lock`              | 保护 VMA 等地址空间结构的主要读写锁                  |
| `page_table_lock`        | 保护部分页表操作和相关计数                           |
| `start_code` 等          | 记录代码、数据、堆和栈等边界                         |
| `context`                | 架构相关的地址空间上下文；ARM64 的 ASID 状态就在这里 |
| `mm_users`、`mm_count` | 管理地址空间和`mm_struct` 自身的生命周期           |

`mm_struct` 很大，并不是每次地址翻译都会逐字段查询它。MMU 真正读取的是页表；`mm_struct` 是 Linux 用来创建、修改、同步和回收这套地址空间的软件管理对象。

[SOURCE] 本地 Linux `248951ddc14d`：`include/linux/mm_types.h:1160-1305`。

#### 2.2.2 `mm_users` 与 `mm_count` 为什么是两个计数

这两个计数管理的层次不同：

```text
mm_users
  └─ 有多少真实用户或临时使用者正在使用这套用户地址空间

mm_count
  └─ mm_struct这个内核对象本身还有多少底层引用
```

需要注意，`mm_users` 整体只占 `mm_count` 中的一个引用，而不是每一个 `mm_users` 都对应一个 `mm_count`：

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

[SOURCE] 本地 Linux `248951ddc14d`：`include/linux/mm_types.h:1168-1177,1200-1208`；`include/linux/sched/mm.h:26-55,115-142`。

#### 2.2.3 新地址空间是如何初始化的

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

[SOURCE] 本地 Linux `248951ddc14d`：`kernel/fork.c:580-590,1085-1132`。

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

[SOURCE] 本地 Linux `248951ddc14d`：`include/linux/mm_types.h:920-984`；`include/linux/mm.h:398-440`。

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
  └─ 修改通常通过COW形成当前地址空间的私有页面

MAP_SHARED
  └─ 多个地址空间可以观察到对共享后端页面的修改
```

例如，同一个可执行文件代码段可以是“文件映射 + Private”，一个进程间共享内存区域可以是“匿名来源 + Shared”。这两组概念不能混为一谈。

COW（Copy-on-Write，写时复制）的基本思路是：

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

本地源码用 `is_cow_mapping()` 判断“可写但非共享”的映射，并在复制页表时将父子双方对应的可写 PTE 改成只读，为后续 COW 做准备。

[SOURCE] 本地 Linux `248951ddc14d`：`include/linux/mm.h:2238-2248`；`mm/memory.c:1097-1112`。

#### 2.3.4 一个 VMA 可以对应很多 PTE

假设进程创建一个 16 KiB 匿名 VMA：

```text
VMA：[0x600000, 0x604000)
权限：可读、可写

0x600000～0x600FFF → 第1个4 KiB虚拟页
0x601000～0x601FFF → 第2个4 KiB虚拟页
0x602000～0x602FFF → 第3个4 KiB虚拟页
0x603000～0x603FFF → 第4个4 KiB虚拟页
```

这一个 VMA 最终可以对应四个叶子 PTE：

```text
一个VMA
  │
  ├─ PTE 0 → PFN 100
  ├─ PTE 1 → PFN 900
  ├─ PTE 2 → PFN 320
  └─ PTE 3 → PFN 700
```

VMA 在虚拟地址上连续，并不要求这些 PTE 指向连续 PFN。

在首次访问以前还可能是：

```text
VMA：已经存在
对应页表：中间页表尚未分配，或者叶子PTE无效
物理页：尚未分配
```

所以必须牢牢记住：

```text
存在VMA ≠ 已经存在有效PTE
存在VMA ≠ 已经分配物理页
```

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

查找和读取地址空间结构通常需要持有 `mmap_lock` 的读锁；创建、删除、拆分或合并 VMA 通常需要写锁。新内核还存在更细粒度的单 VMA 锁优化，但不改变“VMA 是受同步保护的软件对象”这个核心结论。

[SOURCE] 本地 Linux `248951ddc14d`：`include/linux/mm_types.h:1177,1235`；`mm/mmap.c:896-908`。

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

[SOURCE] 本地 Linux `248951ddc14d`：`mm/mmap.c:116-205` 的 `brk`，`mm/mmap.c:280-340` 的 `do_mmap()`，`mm/mmap.c:613-618` 的 `mmap_pgoff`，`mm/mmap.c:1062-1079` 的 `munmap`；`mm/mprotect.c:836-988`；`mm/vma.c:495-600` 的 VMA 拆分实现。

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

因此，Page Fault 不等于程序一定出错。它可能只是“VMA 允许访问，但对应 PTE 和物理页尚未准备好”。完整异常入口、物理页分配和 PTE 更新将在后续 Page Fault 章节展开。

[SOURCE] 本地 Linux `248951ddc14d`：[arch/arm64/mm/fault.c](./2.源码/linux/arch/arm64/mm/fault.c) 第 729～751 行；`mm/mmap_lock.c:496-550`；`mm/memory.c:6417-6425,6651-6716`。

#### 2.3.8 驱动映射为什么也需要 VMA

驱动把内存映射给用户进程时，也是在该进程的 `mm_struct` 中建立 VMA。驱动可以为 VMA 设置：

```text
vm_ops          → 缺页、关闭等回调
vm_private_data → 驱动自己的对象指针
特殊vm_flags    → 说明映射的特殊性质
```

`struct vm_operations_struct` 中包含：

```c
void (*open)(struct vm_area_struct *vma);
void (*close)(struct vm_area_struct *vma);
vm_fault_t (*fault)(struct vm_fault *vmf);
vm_fault_t (*page_mkwrite)(struct vm_fault *vmf);
```

后续学习 GPU 驱动时会看到两类思路：

```text
一次性建立一段PFN映射
        或
访问某页时进入驱动的fault回调，再插入page/PFN
```

本章只建立联系；`remap_pfn_range()`、`vmf_insert_page()`、`vmf_insert_pfn()` 以及 GEM/TTM 的 VMA 处理将在驱动映射章节详细说明。

[SOURCE] 本地 Linux `248951ddc14d`：`include/linux/mm.h:783-833,4541-4565`；`include/linux/mm.h:310-314,414-436` 定义 `VM_PFNMAP`、`VM_IO`、`VM_MIXEDMAP`。

### 2.4 从 `mm->pgd` 到 `TTBR0_EL1`

`mm->pgd` 是 Linux 内核使用的 C 指针，指向当前地址空间的根页表：

```c
mm->pgd = pgd_alloc(mm);
```

它是内核虚拟地址，不能不经处理就直接作为 `TTBR0_EL1.BADDR`。ARM64 的 `cpu_switch_mm()` 会先转换为物理地址：

```c
static inline void cpu_switch_mm(pgd_t *pgd, struct mm_struct *mm)
{
    cpu_do_switch_mm(virt_to_phys(pgd), mm);
}
```

因此主线是：

```text
mm->pgd
  │ 内核虚拟地址
  ▼
virt_to_phys(mm->pgd)
  │ 根页表物理地址
  ▼
构造TTBR0_EL1.BADDR
  │
  ▼
MMU从该物理地址读取根页表
```

[SOURCE] 本地 Linux `248951ddc14d`：`kernel/fork.c:580-585`；[arch/arm64/include/asm/mmu_context.h](./2.源码/linux/arch/arm64/include/asm/mmu_context.h) 第 56～62 行。

#### 2.4.1 这份 Linux 源码中 ASID 实际写在哪里

不能简单认为“用户页表和 ASID 永远都只放在 `TTBR0_EL1`”。Arm 由 `TCR_EL1.A1` 决定使用哪一个 TTBR 中的 ASID 字段。

这份 ARM64 Linux 源码初始化 `TCR_EL1` 时设置了 `TCR_EL1_A1`：

```text
TCR_EL1.A1 = 1
```

所以它的主要关系是：

```text
TTBR0_EL1.BADDR → 当前用户mm的根页表物理地址
TTBR1_EL1.BADDR → Linux内核根页表
TTBR1_EL1.ASID  → 当前地址空间使用的ASID
```

`cpu_do_switch_mm()` 的关键代码正是：

```c
unsigned long ttbr1 = read_sysreg(ttbr1_el1);
unsigned long asid = ASID(mm);
unsigned long ttbr0 = phys_to_ttbr(pgd_phys);

/* Set ASID in TTBR1 since TCR.A1 is set */
ttbr1 &= ~TTBRx_EL1_ASID_MASK;
ttbr1 |= FIELD_PREP(TTBRx_EL1_ASID_MASK, asid);

write_sysreg(ttbr1, ttbr1_el1);
write_sysreg(ttbr0, ttbr0_el1);
isb();
```

可以把一次普通用户地址空间切换画成：

```text
next->mm->pgd
      │ virt_to_phys
      ▼
用户根页表PA ───────────────→ TTBR0_EL1.BADDR

next->mm->context.id
      │ ASID(mm)
      ▼
硬件ASID ──────────────────→ TTBR1_EL1.ASID

共享内核根页表PA ──────────→ TTBR1_EL1.BADDR
```

因此 `TTBR1_EL1` 的内核页表基地址通常保持共享，但它的 ASID 字段仍可能在用户地址空间切换时更新。

> [BOUNDARY] ARM64 的内核隔离和特权访问保护配置会改变保存或写入 `TTBR0_EL1` 的具体时机。本章抓住主关系：`mm->pgd` 提供用户根页表，`mm->context` 提供地址空间标识；不展开各安全配置分支。

[SOURCE] 本地 Linux `248951ddc14d`：[arch/arm64/mm/proc.S](./2.源码/linux/arch/arm64/mm/proc.S) 第 493～503 行设置 `TCR_EL1_A1`；[arch/arm64/mm/context.c](./2.源码/linux/arch/arm64/mm/context.c) 第 349～371 行实现 `cpu_do_switch_mm()`。

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

最重要的区别是：

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

[SOURCE] 本地 Linux `248951ddc14d`：`include/linux/mm_types.h:1302-1305`；[arch/arm64/include/asm/mmu.h](./2.源码/linux/arch/arm64/include/asm/mmu.h) 第 19～28、56 行。

#### 2.7.2 Global 与 non-Global 翻译

叶子描述符中的 `nG` 位决定翻译是否为 non-Global：

```text
nG = 1 → non-Global，TLB匹配时需要考虑ASID
nG = 0 → Global，可以跨地址空间使用，不依赖普通ASID匹配
```

本地 ARM64 定义中：

```c
#define PTE_NG (1 << 11)
```

普通用户页面保护宏包含 `PTE_NG`，因为不同进程的用户映射通常不同；共享的内核映射则通常适合采用 Global 翻译。

[SOURCE] 本地 Linux `248951ddc14d`：[arch/arm64/include/asm/pgtable-hwdef.h](./2.源码/linux/arch/arm64/include/asm/pgtable-hwdef.h) 第 164～176 行；[arch/arm64/include/asm/pgtable-prot.h](./2.源码/linux/arch/arm64/include/asm/pgtable-prot.h) 第 53～65 行。

#### 2.7.3 ASID 数量有限，为什么还需要 generation

ARM64 CPU 可以实现 8 位或 16 位 ASID：

```text
8位ASID  → 256种硬件编号
16位ASID → 65536种硬件编号
```

系统运行期间创建过的地址空间可以远多于这个数量，因此硬件 ASID 必须复用。Linux 在 `mm->context.id` 中同时管理“硬件 ASID + 软件 generation”：

```text
context.id
├── 低位：硬件使用的ASID
└── 高位：Linux管理的generation
```

当当前 generation 的 ASID 用完时：

```text
ASID耗尽
   ↓
增加全局generation
   ↓
保留仍在CPU上活动的ASID信息
   ↓
标记各CPU需要完成TLB清理
   ↓
在后续地址空间切换时安全复用编号
```

所以 ASID 不是永久唯一编号。它只需要在旧 TLB 翻译仍可能存在的时间窗口中保持不会被错误混用。

[SOURCE] 本地 Linux `248951ddc14d`：[arch/arm64/mm/context.c](./2.源码/linux/arch/arm64/mm/context.c) 第 22～56 行检测 8/16 位 ASID，第 101～131 行管理 generation rollover，第 159～212 行分配新上下文。

### 2.8 任务切换时，地址空间和寄存器如何切换

调度器从任务 A 切换到任务 B，不只是把 `current` 改成 B，还需要处理三组状态：

| 状态类别 | 主要对象 | 作用 |
| --- | --- | --- |
| 地址空间 | `mm_struct`、PGD、TTBR、ASID | 决定用户 VA 使用哪套页表和 TLB 记录 |
| 任务身份 | `task_struct`、`SP_EL0`、`__entry_task` | 告诉内核当前正在运行哪个任务 |
| 内核执行现场 | `x19～x29`、SP、LR、内核栈 | 让任务以后能从内核中的原位置继续运行 |

#### 2.8.1 用户现场和内核调度现场不是一份数据

ARM64 Linux 使用两处不同的保存位置：

| 保存位置 | 保存时机 | 主要内容 |
| --- | --- | --- |
| 当前任务内核栈上的 `struct pt_regs` | 用户态发生系统调用、中断或异常，进入内核时 | 用户寄存器 `x0～x30`、用户 SP、用户 PC 和 PSTATE |
| `task->thread.cpu_context` | 任务在内核调度路径中被切走时 | 内核的 `x19～x29`、SP 和 LR |

`pt_regs` 是 Linux 结构体名称，其中 `regs` 是 Registers（寄存器）的缩写；它不是一个 ARM 硬件寄存器。`cpu_context` 中保存的是内核函数恢复执行所需的最小现场，不是第二份完整用户寄存器。

[SOURCE] 本地 Linux `248951ddc14d`：[arch/arm64/include/asm/ptrace.h](<./2.源码/linux/arch/arm64/include/asm/ptrace.h>) 第 152～172 行定义 `pt_regs`；[arch/arm64/include/asm/processor.h](<./2.源码/linux/arch/arm64/include/asm/processor.h>) 第 136～150 行定义 `cpu_context`。

#### 2.8.2 调度器先确定下一个任务使用哪个 `mm_struct`

调度器根据 `next->mm` 区分两种情况：

| `next->mm` | 下一个任务 | 地址空间处理 |
| --- | --- | --- |
| 非 `NULL` | 用户任务 | 调用 `switch_mm_irqs_off()` 切换到 `next->mm` |
| `NULL` | 内核线程 | 不拥有用户地址空间，通过 `active_mm` 临时借用当前地址空间上下文 |

函数名中的 `irqs_off` 表示切换时 IRQ（Interrupt Request，中断请求）已经关闭。这里先完成地址空间处理，随后才由 `switch_to()` 切换内核寄存器和栈。

[SOURCE] 本地 Linux `248951ddc14d`：[kernel/sched/core.c](<./2.源码/linux/kernel/sched/core.c>) 第 5448～5513 行。

#### 2.8.3 同一地址空间与不同地址空间

对于两个普通用户任务：

| 关系 | `mm_struct` | PGD、TTBR 和 ASID |
| --- | --- | --- |
| 同一进程中的线程 | 通常相同 | 通常不需要重新切换 |
| 不同进程 | 通常不同 | 检查或分配 ASID，并安装下一个进程的 PGD |

地址空间不同时，ARM64 主线是：检查下一个 `mm_struct` 的 ASID，准备 `mm->pgd` 的物理地址，更新 TTBR，最后执行 ISB（Instruction Synchronization Barrier，指令同步屏障）。旧进程的 non-Global TLB 记录可以继续保留，因为其中带有旧 ASID，不会被新进程误用。

[SOURCE] 本地 Linux `248951ddc14d`：[arch/arm64/include/asm/mmu_context.h](<./2.源码/linux/arch/arm64/include/asm/mmu_context.h>) 第 236～264 行；[arch/arm64/mm/context.c](<./2.源码/linux/arch/arm64/mm/context.c>) 第 215～270、349～371 行。

#### 2.8.4 按时间顺序看一次完整切换

下面假设 CPU0 因定时器中断，从进程 A 切换到不同地址空间的进程 B。图中的地址只是为了演示。

这里涉及几个寄存器缩写：

- PC：Program Counter，程序计数器。
- SP：Stack Pointer，栈指针。
- LR：Link Register，链接寄存器，内核函数返回位置通常保存在这里。
- `ELR_EL1`：Exception Link Register at Exception Level 1，保存异常返回地址。
- `SPSR_EL1`：Saved Program Status Register at Exception Level 1，保存异常前的处理器状态。
- RET：Return，普通函数返回指令。
- ERET：Exception Return，从异常级别返回的指令。

`task_struct` 地址和内核 SP 在图中都是内核虚拟地址，PGD 写入 TTBR 的地址是物理地址。图只展示普通用户进程之间的主线，省略软件 PAN（Privileged Access Never，特权访问禁止）、内核页表隔离和指针认证等可选机制。

```text
假设：
task_struct A地址 = 0xffff000000100000
task_struct B地址 = 0xffff000000200000
A的用户SP        = 0x0000fffff0008000
B的用户SP        = 0x0000ffffe0007000
A的内核SP        = 0xffff80000100f000
B的内核SP        = 0xffff80000200e000
A的PGD物理地址   = 0x40000000，ASID = 0x12
B的PGD物理地址   = 0x50000000，ASID = 0x34

                              时间向下
                                  │
T0：A在用户态运行                 │
──────────────────────────────────┤
SP_EL0           = A的用户SP      │  SP_EL0此时是用户栈指针
SP_EL1           = 0xffff80000100f000  ← A的内核SP
TTBR0_EL1.BADDR  = A的PGD物理地址 │
TTBR1_EL1.ASID   = 0x12           │
__entry_task[0]  = task_struct A地址
                                  │
                     定时器中断   ▼
                                  │
T1：A进入内核                     │
──────────────────────────────────┤
硬件：                            │
  ELR_EL1  ← A的用户PC            │
  SPSR_EL1 ← A的用户PSTATE        │
  开始使用A的内核栈               │
                                  │
Linux入口代码：                   │
  A的pt_regs ← x0～x30、用户SP、PC、PSTATE
  SP_EL0     ← task_struct A地址   │
  current     → task_struct A      │
                                  │
                     调度器选择B  ▼
                                  │
T2：先切换地址空间                │
──────────────────────────────────┤
prev = task_struct A地址          │
next = task_struct B地址          │
                                  │
TTBR0_EL1：A的PGD                 │
             → 保留页表           │
             → B的PGD             │
TTBR1_EL1.ASID：0x12 → 0x34       │
执行ISB                           │
__entry_task[0] = task_struct B地址
                                  │
                  cpu_switch_to() ▼
                                  │
T3：再切换内核执行现场            │
──────────────────────────────────┤
x0 = task_struct A地址            │  第一个参数prev
x1 = task_struct B地址            │  第二个参数next
                                  │
A->thread.cpu_context             │
  ← 保存A的x19～x29、SP、LR       │
                                  │
B->thread.cpu_context             │
  → 恢复B的x19～x29、SP、LR       │
                                  │
SP     ← 0xffff80000200e000        │  切换到B的内核栈
SP_EL0 ← x1 = task_struct B地址   │
current → task_struct B           │
RET → 回到B以前在内核中被切走的位置
                                  │
                     B返回用户态  ▼
                                  │
T4：恢复B的用户现场               │
──────────────────────────────────┤
x0～x30  ← B的pt_regs             │
ELR_EL1  ← B的用户PC              │
SP_EL0   ← B的用户SP              │  重新变回用户栈指针
执行ERET，回到EL0                 │
                                  ▼
B继续在用户态运行
```

图中的 `__entry_task[0]` 是“CPU0 所属的 per-CPU（Per-CPU，每个 CPU 一份）变量”的概念写法，并不是源码真的通过普通数组下标访问。

如果 A 和 B 是同一进程中的两个线程，它们共享 `mm_struct`，因此 T2 通常不切换 PGD 和 ASID；但 T3 中的 `task_struct`、内核栈和寄存器现场仍然需要切换。

#### 2.8.5 为什么同时需要 `SP_EL0` 和 `__entry_task`

内核态使用 `SP_EL1` 作为内核栈，因此可以暂时把 `SP_EL0` 用来保存 `current` 的 `task_struct` 指针。但用户态会把 `SP_EL0` 当作用户栈指针，所以 Linux 还为每个 CPU 保存一份 `__entry_task` 影子指针：从用户态进入内核时，先从 `__entry_task` 找回当前任务，再把它写入 `SP_EL0`。

任务切换时，`entry_task_switch(next)` 先更新 `__entry_task`，`cpu_switch_to(prev, next)` 随后保存旧任务的内核现场、恢复新任务的内核现场，并执行 `SP_EL0 = next`。关键切换期间中断保持关闭，避免代码观察到“内核栈已经属于 B，但 `current` 仍指向 A”的半切换状态。

[SOURCE] 本地 Linux `248951ddc14d`：[arch/arm64/kernel/process.c](<./2.源码/linux/arch/arm64/kernel/process.c>) 第 567～578、727～777 行；[arch/arm64/kernel/entry.S](<./2.源码/linux/arch/arm64/kernel/entry.S>) 第 197～224、281～304、335～366、813～848 行。

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

多核情况下，其他 CPU 也可能缓存同一个 `mm_struct` 的翻译，这就是通常所说的 TLB shootdown 问题。在 ARM64 上，跨 CPU 无效化常通过带 `is` 后缀的 Inner Shareable 广播 TLBI 完成，并不一定表现为传统的软件 IPI（Inter-Processor Interrupt，处理器间中断）：

```c
dsb(ishst);
asid = __TLBI_VADDR(0, ASID(mm));
__tlbi(aside1is, asid);
__tlbi_sync_s1ish(mm);
```

具体使用哪条 TLBI、是否广播、是否还要清理 walk cache，由修改的映射范围和层级决定。本章需要掌握的结论是：

```text
更新PTE ≠ CPU已经开始使用新PTE

页表修改 + 必要的TLB维护
才构成完整的映射更新
```

[SOURCE] 本地 Linux `248951ddc14d`：[arch/arm64/include/asm/tlbflush.h](./2.源码/linux/arch/arm64/include/asm/tlbflush.h) 第 280～358 行说明接口语义，第 360～385 行实现全局、本地和按 `mm` 清理，第 623～649 行实现范围与页面清理。

### 2.10 地址连续性的边界说明

本章讨论的 `mmap()`、`brk()` 和 `malloc()` 主要作用在进程虚拟地址空间。它们给程序一段连续 VA，并不自动保证底层 PFN 连续：

```text
用户看到的连续16 KiB：

VA 0x600000  VA 0x601000  VA 0x602000  VA 0x603000
     │            │            │            │
     ▼            ▼            ▼            ▼
  PFN 100       PFN 900      PFN 320      PFN 700
```

“连续内存”至少可能表示：

```text
CPU虚拟地址连续
CPU物理地址连续
设备使用的DMA地址连续
GPU虚拟地址连续
```

它们不能互相替代。本章只说明用户 VA 与 VMA，下面这些接口留到物理内存和分配器章节：

| 后续接口                 | 后续重点                              |
| ------------------------ | ------------------------------------- |
| `alloc_pages()`        | 如何申请一个或多个连续物理页框        |
| `kmalloc()`            | 内核小对象分配及其虚拟、物理连续性    |
| `vmalloc()`            | 连续内核 VA 如何映射离散物理页        |
| `dma_alloc_coherent()` | CPU 地址与设备 DMA 地址的关系         |
| GEM、TTM                 | 对象、物理页面、VRAM 与 GPU VA 的组合 |

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

需要记住七个结论：

1. `task_struct` 表示任务，`mm_struct` 表示地址空间，二者不是一一对应。
2. VMA 描述“这段 VA 应该怎样使用”，页表描述“这个虚拟页当前映射到哪里”。
3. `mm->pgd` 是内核虚拟地址指针，写入 TTBR 前需要得到根页表物理地址。
4. TLB entry 的真实硬件格式由 CPU 实现决定，只能画出逻辑字段。
5. ASID 标识地址空间而不是 PID，使不同 `mm_struct` 的翻译可以同时留在 TLB。
6. 任务切换包含地址空间切换和内核执行现场切换；共享同一 `mm_struct` 的线程通常可以跳过前者。
7. 修改页表后还必须根据情况执行 TLB 无效化和同步。

[SOURCE] 本章本地源码索引：

| 主题                      | Linux`248951ddc14d` 源码路径                                                                                                                                                                                           |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 当前任务与`task_struct` | [arch/arm64/include/asm/current.h](./2.源码/linux/arch/arm64/include/asm/current.h)、[include/linux/sched.h](./2.源码/linux/include/linux/sched.h)                                                                         |
| `active_mm`             | `Documentation/mm/active_mm.rst`（当前仍在 Git 对象中）、[kernel/sched/core.c](./2.源码/linux/kernel/sched/core.c)                                                                                                      |
| `mm_struct` 与 VMA      | [include/linux/mm_types.h](./2.源码/linux/include/linux/mm_types.h)、[include/linux/mm.h](./2.源码/linux/include/linux/mm.h)                                                                                               |
| 地址空间创建与共享        | [kernel/fork.c](./2.源码/linux/kernel/fork.c)                                                                                                                                                                             |
| Maple Tree 与 VMA 操作    | [mm/mmap.c](./2.源码/linux/mm/mmap.c)、[mm/vma.c](./2.源码/linux/mm/vma.c)、[mm/mprotect.c](./2.源码/linux/mm/mprotect.c)                                                                                                   |
| VMA 与缺页路径            | [arch/arm64/mm/fault.c](./2.源码/linux/arch/arm64/mm/fault.c)、[mm/mmap_lock.c](./2.源码/linux/mm/mmap_lock.c)、[mm/memory.c](./2.源码/linux/mm/memory.c)                                                                   |
| ARM64`mm_context_t`     | [arch/arm64/include/asm/mmu.h](./2.源码/linux/arch/arm64/include/asm/mmu.h)                                                                                                                                               |
| TTBR 与地址空间切换       | [arch/arm64/include/asm/mmu_context.h](./2.源码/linux/arch/arm64/include/asm/mmu_context.h)、[arch/arm64/mm/context.c](./2.源码/linux/arch/arm64/mm/context.c)、[arch/arm64/mm/proc.S](./2.源码/linux/arch/arm64/mm/proc.S) |
| 异常入口与任务现场切换    | [arch/arm64/kernel/entry.S](<./2.源码/linux/arch/arm64/kernel/entry.S>)、[arch/arm64/kernel/process.c](<./2.源码/linux/arch/arm64/kernel/process.c>)、[arch/arm64/include/asm/processor.h](<./2.源码/linux/arch/arm64/include/asm/processor.h>)、[arch/arm64/include/asm/ptrace.h](<./2.源码/linux/arch/arm64/include/asm/ptrace.h>) |
| ARM64 页表保护位          | [arch/arm64/include/asm/pgtable-hwdef.h](./2.源码/linux/arch/arm64/include/asm/pgtable-hwdef.h)、[arch/arm64/include/asm/pgtable-prot.h](./2.源码/linux/arch/arm64/include/asm/pgtable-prot.h)                             |
| TLB 无效化                | [arch/arm64/include/asm/tlbflush.h](./2.源码/linux/arch/arm64/include/asm/tlbflush.h)                                                                                                                                     |

下一章将从 `PTE → 物理页基地址 → PFN` 继续，说明 Linux 如何通过 PFN 和 `struct page` 管理真实物理页。
