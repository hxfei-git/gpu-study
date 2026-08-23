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

## Review, Commits, and Pull Requests

No local Git history is available, so no repository-specific commit convention can be inferred. Use concise imperative messages with a documentation scope, for example `docs(svm): clarify page-fault ownership`.

Keep each pull request focused. Describe the reader-facing change, identify updated chapters and index links, and state how links/rendering were checked. Link relevant issues or source revisions. Include a screenshot only when a Mermaid diagram, table, or rendered layout materially changed.
