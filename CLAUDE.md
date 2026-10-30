# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

@AGENTS.md

## 1. AGENTS.md 的导入与子仓库规则

上面一行导入根目录的 `AGENTS.md`。写作规则、MI300X 教学模型、证据标签和提交格式都以它为准；本文件只补充 Claude Code 需要的命令、跨仓库结构和环境差异。规则要改时，改 `AGENTS.md` 或 `文档的常见问题.md`，不在这里另存一份。

学习与实验的当前阶段、验收状态和规格确认历史记录在根目录的 `学习与实验进度.md`。本文件不导入这份文件，开始相关工作前再读取。

不要删除这行导入。当前 Claude Code 默认只在项目没有 `CLAUDE.md` 时加载 `AGENTS.md`；有了本文件，`AGENTS.md` 只能经导入进入上下文。

子仓库 `4.experiments/gpu-study-qemu` 有自己的 `CLAUDE.md`，它导入子仓库的 `AGENTS.md`，并写有 GPGPU 软件栈结构和构建、测试命令。从根目录启动、要修改实验代码时，先读取这两份文件。C 代码风格、三级注释、“子系统：具体修改”的提交标题，以及 `checkpatch.pl`、`kernel-doc` 检查都在子仓库的 `AGENTS.md` 中。

## 2. 当前环境与 AGENTS.md 的差异

Claude Code 运行在 WSL2，仓库位于 `/home/book/1.project/gpu_study`。`AGENTS.md` 中按 Windows 和 PowerShell 写的 `rg` 检查命令，在 bash 中照常可用。

`AGENTS.md` 要求源码定位链接按当前仓库位置生成，但已有文档混用了三种路径前缀：

- 06 上下篇：`C:/Users/28431/Desktop/GPU学习资料/gpu_study/`，中文经 URL 编码；
- `4.experiments` 下的规格与软件说明：`/home/book/1.project/gpu_study/`；
- 06 上篇另有少量链接：`/home/book/2.study/gpu-study/`，该目录已不存在。

新增链接前，先确认用户在哪个环境中打开预览；未经授权，不批量改写已有链接。

`AGENTS.md` 要求的 humanizer-zh 检查，在本机由用户级技能 `humanizer-zh-docs` 执行，用 Skill 工具调用。这个技能改编自 op7418/Humanizer-zh，内容与 `AGENTS.md` 固定的上游提交 `f4518a8` 不完全相同；需要严格按上游版本检查时，先告知用户。

## 3. 仓库组成与两级提交

父仓库跟踪笔记、参考资料、实验文档和 9 个子模块的指针。

- `2.源码/*` 是笔记引用的固定源码基线，处于 detached HEAD，其中 Linux 为 sparse checkout。这些子模块只读取，不修改文件，也不切换提交；版本清单与核对命令见 `2.源码/README.md`。
- `4.experiments/gpu-study-qemu` 是用户自己的 QEMU 分支（`hxfei-git/gpu-study-qemu`，统一在 `main` 上开发），实验代码都在这里修改。先在子仓库提交代码，再回父仓库提交新的子模块指针和同步后的文档；父仓库最近的 `chore(实验)`、`docs(实验)` 提交就是这类同步。

实验文档分在两处。规格、四阶段大纲、软件实现说明和 HTML 硬件手册在父仓库的 `4.experiments/`，子仓库 `AGENTS.md` 用 `../` 引用它们；随代码版本变化的 `README.md`、`WORK_ITEMS.md` 和 `PROTOCOL_V3.md` 在子仓库的 `software/gpgpu/`。`PROTOCOL_V3.md` 列出协议从版本 2 到版本 3 的差异，用来逐条更新父仓库的规格和手册。规格或手册与代码不一致时，协议常量以 `software/gpgpu/include/gpgpu/` 为准。

以下大文件先用锚点或 `rg` 定位，再分段读取：`CP_MEC 第一版规格.md`（约 270 KB）、`CP_MEC 软件实现、参考与扩展.md`（约 320 KB）和 `QEMU_2026_讲义.html`（约 15 MB）。`学习与实验进度.md` 第 3、4 节的链接给出了常用锚点。

## 4. 实验代码的结构与命令

GPGPU 软件栈的五层调用、协议头位置、双进程设备，以及构建、测试和单个 QTest 用例的命令，都写在 `4.experiments/gpu-study-qemu/CLAUDE.md`。这些内容随代码版本变化，只在子仓库维护。
