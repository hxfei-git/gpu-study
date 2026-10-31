# CLAUDE.md

| 缩写 | 英文全称 | 中文含义 |
| --- | --- | --- |
| WSL | Windows Subsystem for Linux | Windows 的 Linux 子系统 |

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

@AGENTS.md

## 1. AGENTS.md 的导入

上面一行导入根目录的 `AGENTS.md`。写作规则、MI300X 教学模型、证据标签、脚本与验证的精简原则、实验子模块的维护方式和提交格式都以它为准；本文件只补充 Claude Code 需要的环境差异。规则要改时，改 `AGENTS.md` 或 `文档的常见问题.md`，不在这里另存一份。

不要删除这行导入。当前 Claude Code 默认只在项目没有 `CLAUDE.md` 时加载 `AGENTS.md`；有了本文件，`AGENTS.md` 只能经导入进入上下文。

子仓库 `4.experiments/gpu-study-qemu` 有自己的 `CLAUDE.md` 和 `AGENTS.md`。修改实验代码或实验文档前，先读取这两份文件。

## 2. 当前环境与 AGENTS.md 的差异

Claude Code 运行在 WSL2，仓库位于 `/home/book/1.project/gpu_study`。`AGENTS.md` 中按 Windows 和 PowerShell 写的 `rg` 检查命令，在 bash 中照常可用。

`AGENTS.md` 要求的 humanizer-zh 检查，在本机由用户级技能 `humanizer-zh-docs` 执行，用 Skill 工具调用。`humanizer-zh-docs` 改编自 op7418/Humanizer-zh，内容与 `AGENTS.md` 固定的上游提交 `f4518a8` 不完全相同；需要严格按上游版本检查时，先告知用户。

## 3. 固定源码基线

`2.源码/*` 是笔记引用的固定源码基线，处于 detached HEAD，其中 Linux 为 sparse checkout。这些子模块只读取，不修改文件，也不切换提交；版本清单与核对命令见 `2.源码/README.md`。
