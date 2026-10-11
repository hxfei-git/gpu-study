# 远端 GPGPU 与 RISC-V CP 验收记录

| 缩写 | 英文全称 | 中文含义 |
| --- | --- | --- |
| QEMU | Quick Emulator | 仿真与虚拟化工具 |
| GPGPU | General-Purpose Computing on Graphics Processing Units | 教学通用计算设备 |
| CP | Command Processor | 命令处理器 |
| CPU | Central Processing Unit | 中央处理器 |
| RV32 | 32-bit RISC-V | 本版原生 CP 的 32 位 RISC-V 模型 |
| TCG | Tiny Code Generator | QEMU 动态代码生成基础设施 |
| BAR | Base Address Register | PCI 基址寄存器 |
| PCI | Peripheral Component Interconnect | 外设互连总线 |
| VRAM | Video RAM | 设备显存 |
| DMA | Direct Memory Access | 直接内存访问 |
| IOMMU | Input/Output Memory Management Unit | 输入输出内存管理单元 |
| IOVA | Input/Output Virtual Address | 设备 DMA 虚拟地址 |
| SMMU | System Memory Management Unit | Arm 系统内存管理单元 |
| IRQ | Interrupt Request | 中断请求 |
| fd | File Descriptor | 文件描述符；用于共享内存后备存储 |
| SMMUv3 | System Memory Management Unit version 3 | Arm 系统内存管理单元第三版 |
| MSI-X | Message Signaled Interrupts Extended | 扩展消息中断 |
| QMP | QEMU Machine Protocol | QEMU 管理协议 |
| ReLU | Rectified Linear Unit | 修正线性单元 |

## 1. 本轮实现与测试环境

2026-10-11 完成双进程设备、消息 DMA、中断转发和原生 RV32 CP 接入。原单进程入口继续通过回归。CP 只接入复位、入口和基本固件运行，第二阶段的队列、Doorbell 事件、Signal 与 CP 派发尚未完成。

```text
A57 Linux（进程 A）
  → vfio-user-pci：转发 BAR，处理消息 DMA，接收中断
  → gpgpu-cp（进程 B）
       ├─ gpu0：原寄存器、VRAM、DMA、中断与计算解释器
       └─ 原生 RV32 CP：默认保持复位，从同一份 VRAM 取指
```

> **[SOURCE]** 测试对象为实验子仓库 `main` 分支提交 `1c41928fbeff4dcb4c9baddf9fd58a50a3d3133a`，其基线为 `b83b51f6b5fc48024c2dab437b38328f2b135ff5`。构建包含 `aarch64-softmmu`、`riscv32-softmmu`、`riscv64-softmmu`，启用 `vfio-user-server`；Host 为 Cortex-A57，设备端 CP 为原生 `rv32`，均使用 TCG。Linux 为 `6.18.55-0-virt`。

单进程与双进程回归共用上述启用服务端的构建；禁用服务端的 fallback 只单独编译并核对符号，未另做完整构建。

本次复制了已有 Alpine 开发环境，并在当前仓库用当前驱动源码重新编译模块。`module-test.json` 保留真实的旧开发环境散列，模块源码散列与当前输入一致。软件栈测试在客体中重新构建运行时和示例；`--skip-prepare` 仅用于复用这个已校验的环境。

`libvfio-user` 保持 wrap 指定的 `0b28d205572c80b568a1003db2c8f37ca333e4d7`。随仓库交付的 [最小补丁](<./gpu-study-qemu/subprojects/packagefiles/libvfio-user/0001-message-dma-window.diff>) 放宽无 fd 消息窗口的大小限制，并修正消息地址遗漏 `sg->offset` 的问题；区域容量仍为 16。Meson 按 wrap 自动应用补丁。

## 2. 原单进程回归

AArch64 与 RISC-V 的既有 GPGPU QTest 分别通过 **21/21**，其中各含 17 项评分用例和 4 项回归。单进程 SMMUv3 DMA 专项通过 **2/2**，均无跳过。

Linux 的 `none`、`smmuv3` 两种配置分别通过：三个示例 **3/3**，运行时检查 **68/68**，装卸载检查 **5/5**，卸载重载 **2/2**。每种配置核对向量加法 17,003 个、矩阵乘 437 个、ReLU 513 个输出，合计 **17,953 个值**。所有命令退出码为 0，无非预期内核或 SMMU fault。

日志见 [AArch64 QTest](<./gpu-study-qemu/build/gpgpu-regression/aarch64-qtest.log>)、[RISC-V QTest](<./gpu-study-qemu/build/gpgpu-regression/riscv64-qtest.log>)、[单进程 IOMMU 专项](<./gpu-study-qemu/build/gpgpu-regression/iommu-qtest.log>)。Linux 软件栈日志见 [none 配置](<./gpu-study-qemu/build/gpgpu-linux-module/none/stack-test.log>) 与 [smmuv3 配置](<./gpu-study-qemu/build/gpgpu-linux-module/smmuv3/stack-test.log>)；结构化结果位于 `build/gpgpu-linux-module/none/` 与 `smmuv3/` 的 `stack-test.json`、`test.json`。

## 3. 双进程原有功能回归

远端 `none`、`smmuv3` 两种配置也分别通过三个示例 **3/3**、输出 **17,953 个值**、运行时检查 **68/68**、装卸载 **5/5**、卸载重载 **2/2**，退出码均为 0。该组测试的驱动没有解除 CP 复位，计算和 DMA 继续使用原同步接口。

`smmuv3` 的设备 domain 类型为 `DMA`。正常软件栈没有非预期 SMMU fault；计算完成、DMA 完成及执行错误经 MSI-X 交给 Linux 驱动，运行时检查包含错误恢复和并发调用。结果分别保存在 [远端 none 日志](<./gpu-study-qemu/build/gpgpu-linux-module/remote/none/stack-test.log>) 与 [远端 smmuv3 日志](<./gpu-study-qemu/build/gpgpu-linux-module/remote/smmuv3/stack-test.log>)。

远端 SMMUv3 DMA 专项通过 **2/2**：非恒等映射的双向搬运成功；未映射写入产生 18 条预期翻译 fault、错误 MSI-X，并且没有 DMA 完成通知；清除错误后，原合法映射继续可用，没有新增 fault。该专项保留原测试断言，只适配远端设备与完成事件等待。日志见 [远端 IOMMU QTest](<./gpu-study-qemu/build/gpgpu-remote-iommu-qtest.log>)。

## 4. 原生 CP 验收

三项正式 QTest 验收通过 **3/3**，退出码为 0，无跳过：

1. A57 经代理枚举设备，读取 BAR0 标识并读写 BAR2。
2. B 的 CPU 查询返回一个 `riscv32` CPU；装载固件后保持复位，等待 100 ms，结果仍为 0。
3. 代码位于 VRAM 偏移 `0x4000`，结果位于 `0x6000`；设置入口并解除复位后得到 `0x123`。重新保持复位，在相同入口替换指令，再启动得到 `0x456`，验证共享存储和指令翻译失效。

日志见 [CP QTest](<./gpu-study-qemu/build/gpgpu-cp-qtest.log>)。以上测试与软件栈测试分别运行，没有永久保留固件分区。

另外在实际 A57 Linux 客体中，分别以远端 `none`、`smmuv3` 配置重复上述三步，两种配置均通过 **3/3**。验收程序直接映射 BAR0、BAR2，确认默认保持复位时结果为 0、启动后结果为 `0x123`、同地址替换固件后结果为 `0x456`；随后保持 CP 复位并卸载驱动。程序准备、执行和卸载的退出码均为 0，无内核或 SMMU fault。日志见 [Linux none 验收](<./gpu-study-qemu/build/gpgpu-regression/linux-cp-none.log>)、[Linux smmuv3 验收](<./gpu-study-qemu/build/gpgpu-regression/linux-cp-smmuv3.log>)，详细结果见 [Linux CP 结果](<./gpu-study-qemu/build/gpgpu-regression/linux-cp-results.json>)。

这两次独立 Linux 验收临时追加 `iomem=relaxed`，允许用户态映射已被驱动占用的 BAR；正式启动入口、内核和驱动均未因此修改。该参数只影响本次用户态 BAR 映射检查，`smmuv3` 配置仍使用 `DMA` domain。

另做一项临时烟雾检查，验证复位前遗留 pending IRQ、QMP `stop/cont`、设备软复位与冷复位。检查通过：保持复位期间不执行固件；软复位保留 VRAM、恢复 CP 默认值；冷复位清零 VRAM，并在重新配置 PCI BAR 后可访问。日志见 [CP 复位烟雾检查](<./gpu-study-qemu/build/gpgpu-cp-reset-smoke.log>)。它未增加正式边界验收用例。

## 5. 复现入口与交付范围

以下命令从 `gpu-study-qemu` 根目录运行；首次使用先按 [源码规格的构建说明](<./gpu-study-qemu/docs/specs/gpgpu.rst>) 构建远端服务端并准备 Linux 环境。

```sh
make -f Makefile.camp test-gpgpu-cp JOBS=4
make -f Makefile.camp test-gpgpu-remote-iommu JOBS=4
make -f Makefile.camp test-gpgpu-stack REMOTE=1 IOMMU=none
make -f Makefile.camp test-gpgpu-stack REMOTE=1 IOMMU=smmuv3
make -C software/gpgpu/linux run REMOTE=1 IOMMU=smmuv3
```

本次四配置软件栈的实际命令为 `python3 software/gpgpu/linux/module-test.py stack-test --skip-prepare`，分别追加 `--iommu none` 或 `--iommu smmuv3`，双进程配置再追加 `--remote`。装卸载检查把 `stack-test` 替换为 `test`。测试数量与退出码另存于 `build/gpgpu-regression/module-checks.json`。

启动器为 [gpgpu_remote.py](<./gpu-study-qemu/scripts/gpgpu_remote.py>)，处理设备先启动、socket 就绪超时、两端日志和退出清理。启动器烟雾检查与既有汇编器 **4/4** 检查均通过。

代码 checkpatch 为 0 errors，保留新增文件的维护者提示 1 条；库补丁从原始归档重新应用后，与构建使用的源码一致。Markdown 与 RST 已渲染检查，浏览器实际打开了改动文档中的相对链接，核对硬件手册 15 个目录目标，并检查新增流程图与寄存器说明。新增源码 URI 的文件和真实行号已核对，VS Code 编辑器中的实际跳转未实测。中文改动已按仓库指定的自然化技能复核。

硬件手册的 3.4、4.2、6.5、9.5 节和源码规格已同步，冲突的旧 CP 启停寄存器草案已替换；第一版规格和大纲保留此前已确认的队列分工及待复审内容。本轮实现及此前文档修改一并提交，验收日志保留在本地 `build` 目录，未随源码提交。

**[BOUNDARY]** 本版不支持断线重连、迁移或 CP 异步 Host DMA。通过本轮验收只表示远端设备和 CP 基础已可运行，不表示第二阶段队列功能已完成或用户已掌握相应知识。
