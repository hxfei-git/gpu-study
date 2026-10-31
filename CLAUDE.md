# CLAUDE.md

| 缩写 | 英文全称 | 中文含义 |
| --- | --- | --- |
| QEMU | Quick Emulator | 仿真与虚拟化工具 |
| GPGPU / GPU | General-Purpose Computing on Graphics Processing Units / Graphics Processing Unit | GPU 通用计算／图形处理器 |
| CP / MEC | Command Processor / Micro Engine Compute | 命令处理器／计算命令处理微引擎 |
| GPUVM | GPU Virtual Memory | GPU 虚拟内存 |
| WSL | Windows Subsystem for Linux | Windows 的 Linux 子系统 |
| URI / URL | Uniform Resource Identifier / Uniform Resource Locator | 统一资源标识符／统一资源定位符 |
| VS Code | Visual Studio Code | 本项目使用的编辑器 |

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

@AGENTS.md

## 1. AGENTS.md 的导入与子仓库规则

上面一行导入根目录的 `AGENTS.md`。写作规则、MI300X 教学模型、证据标签、脚本与验证的精简原则和提交格式都以它为准；本文件只补充 Claude Code 需要的命令、跨仓库结构和环境差异。规则要改时，改 `AGENTS.md` 或 `文档的常见问题.md`，不在这里另存一份。

学习进度与个人安排记录在根目录的 `学习与实验进度.md`；实验状态与近期任务记录在
`4.experiments/gpu-study-qemu/docs/实验进度.md`。开始相关工作前按需读取，不导入进度正文。

不要删除这行导入。当前 Claude Code 默认只在项目没有 `CLAUDE.md` 时加载 `AGENTS.md`；有了本文件，`AGENTS.md` 只能经导入进入上下文。

子仓库 `4.experiments/gpu-study-qemu` 有自己的 `CLAUDE.md`，它导入子仓库的 `AGENTS.md`，并写有 GPGPU 软件栈结构和构建、测试命令。从根目录启动、要修改实验代码时，先读取这两份文件。C 代码风格、三级注释、“子系统：具体修改”的提交标题，以及 `checkpatch.pl`、`kernel-doc` 检查都在子仓库的 `AGENTS.md` 中。

## 2. 当前环境与 AGENTS.md 的差异

Claude Code 运行在 WSL2，仓库位于 `/home/book/1.project/gpu_study`。`AGENTS.md` 中按 Windows 和 PowerShell 写的 `rg` 检查命令，在 bash 中照常可用。

用户已实测的预览环境为 Windows VS Code 连接 WSL。本地源码使用
`vscode://vscode-remote/wsl+Ubuntu/绝对路径:行:列`，中文和空格做 URL 编码；
路径基于当前仓库生成，不附加本地 `#L…`。固定历史源码使用带 commit 的 GitHub
链接，普通文档使用相对路径。换机器或改变预览环境时再核对，不擅自批量重写链接。

`AGENTS.md` 要求的 humanizer-zh 检查，在本机由用户级技能 `humanizer-zh-docs` 执行，用 Skill 工具调用。`humanizer-zh-docs` 改编自 op7418/Humanizer-zh，内容与 `AGENTS.md` 固定的上游提交 `f4518a8` 不完全相同；需要严格按上游版本检查时，先告知用户。缩写表和自然化检查的适用范围以 `AGENTS.md` 为准。

## 3. 仓库组成与两级提交

父仓库跟踪学习笔记、参考资料和子模块指针；实验代码、自写实验文档、原课程资料与进度统一由实验子仓库维护。

- `2.源码/*` 是笔记引用的固定源码基线，处于 detached HEAD，其中 Linux 为 sparse checkout。这些子模块只读取，不修改文件，也不切换提交；版本清单与核对命令见 `2.源码/README.md`。
- `4.experiments/gpu-study-qemu` 是用户自己的 QEMU 分支（`hxfei-git/gpu-study-qemu`，统一在 `main` 上开发），实验代码都在这里修改。先在子仓库提交代码与实验文档，再回父仓库提交新的子模块指针；只有学习引用确实受影响时才同步修改父仓库文档。临时任务分支完成后按子仓库规则安全快进 `main`，不改写历史。

实验大纲、CP/MEC 与 GPUVM 规格、硬件手册、适配笔记和历史参考都在子仓库
`docs/`。随代码变化的调用结构、命令和验收在 `software/gpgpu/README.md`，
协议差异在 `software/gpgpu/PROTOCOL_V3.md`。规格或手册与代码不一致时，
协议常量以 `software/gpgpu/include/gpgpu/` 为准。历史工作项已并入软件栈说明第 6 节，不再另建工作项或进度文件。

大文件先用锚点或 `rg` 定位，再分段读取：子仓库 `docs/CP_MEC 第一版规格.md`、
`docs/历史/CP_MEC 软件实现、参考与扩展.md`，以及
`docs/课程资料/QEMU_2026_讲义.html`。常用入口从子仓库的实验进度和软件栈说明进入。

## 4. 实验代码的结构与命令

GPGPU 软件栈的五层调用、协议头位置、双进程设备，以及构建、测试和单个 QTest 用例的命令，都写在 `4.experiments/gpu-study-qemu/CLAUDE.md`。这些内容随代码版本变化，只在子仓库维护。
