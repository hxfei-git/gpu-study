# Repository Guidelines

## Project Structure & Module Organization

This repository is a Markdown knowledge base about Linux, AMD GPUs, memory management, and command submission. Every canonical document currently lives at the repository root; there are no separate `src/`, `test/`, or asset directories. The numbered files form a reading sequence: `1. 总索引：一个进程的 GPU 完整旅程.md` is the navigation hub, followed by focused chapters such as `2. 常规内存机制…md`, `5. AMD 队列提交…md`, and `9. AMD SVM…md`.

Add a new topic as a numbered root-level Markdown file using the existing pattern, for example `12. GPU 中断与故障恢复.md`. Update the index when the new topic changes the recommended reading path or a topic table.

## Build, Test, and Development Commands

There is no build system, package manifest, or automated test suite in this checkout. Work in a Markdown preview and use these lightweight checks:

```powershell
rg --files -g '*.md'                 # list the note set
rg -n '^#{1,3} ' -g '*.md'           # review heading hierarchy
rg -n '\]\(' -g '*.md'              # find links to verify after renames
```

## Testing Guidelines

Before submitting, preview edited files to check tables, Mermaid diagrams, code fences, and internal anchors. Test every changed relative link by opening it from the rendered note.

## Writing Style & Naming Conventions

Follow the surrounding Chinese-language prose and retain established technical terms such as GPUVM, KFD, AQL, MQD, and HQD. Give each note one `#` title, then use numbered `##` sections and concise `###` subsections. Prefer short explanatory paragraphs, tables for comparisons, and fenced blocks tagged with a language such as `text` or `mermaid`.

When answering questions about this repository, keep the response concise, clear, and direct. Use a short concrete example when it helps explain an abstract concept.

Place an abbreviation glossary immediately after each document's `#` title. Use the columns `缩写`, `英文全称`, and `中文含义`, and include the technical abbreviations used in that document. Add a glossary entry whenever a new abbreviation is introduced.

Keep filenames stable. For links to files whose names contain spaces or non-ASCII characters, preserve the repository convention: `[label](<./2. 常规内存机制：GPU 内存分配与 CPU↔GPU 访问.md>)`.

Separate facts from analysis with the labels already used in the notes: `[SOURCE]`, `[SPEC]`, `[INFERENCE]`, `[BOUNDARY]`, and `[DESIGN]`. Cite the exact source path, version, or specification section whenever making a source-backed implementation claim.

## Current-vs-Deferred Knowledge Workflow

当用户询问某个知识点是否需要补充到当前文档时，必须先明确判断，说明建议放置的位置或后续阶段，然后等待用户明确同意。仅询问“是否需要补充”不构成修改文件的授权；在用户同意前，不得修改当前文档，也不得写入或删除 `待补充的知识点.md`。如果用户在最初请求中已经明确要求“补充”“写入”或“按此执行”，则视为已经授权，无需重复确认。

- 如果确认应当放在当前文档，先说明准备补充到哪个小节以及内容边界；用户明确同意后，再补充到最合适的小节，并完成必要的缩写表、源码引用和 Markdown 检查。
- 如果确认应当留到后续阶段，先说明目标阶段以及准备登记的内容；用户明确同意后，再把该知识点写入仓库根目录的 `待补充的知识点.md`，至少记录“知识点”“目标阶段或目标文档”“届时需要补充的范围”和“当前关联位置”。
- 登记前先检查是否已有相同或重叠条目；有则合并或完善原条目，不要重复登记。
- 开始一个新学习阶段、创建对应章节或扩写对应主题前，必须先读取 `待补充的知识点.md`，向用户汇报目标阶段匹配的条目，并等待用户同意后再补充，不得自动执行。
- 只有在知识点已经写入目标文档并完成基本校验后，才能从 `待补充的知识点.md` 删除对应条目；不要仅标记“已完成”。如果只补充了一部分，应保留并改写尚未完成的范围。
- 删除待办条目时，同时清理该文件缩写表中已不再使用的缩写。`待补充的知识点.md` 只保留尚未完成的知识点。

## Review, Commits, and Pull Requests

No local Git history is available, so no repository-specific commit convention can be inferred. Use concise imperative messages with a documentation scope, for example `docs(svm): clarify page-fault ownership`.

Keep each pull request focused. Describe the reader-facing change, identify updated chapters and index links, and state how links/rendering were checked. Link relevant issues or source revisions. Include a screenshot only when a Mermaid diagram, table, or rendered layout materially changed.
