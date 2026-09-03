# Repository Guidelines

## Project Structure & Module Organization

本仓库是关于 Linux、AMD GPU、内存管理和命令提交的 Markdown 知识库。根目录下以 `NN_主题.md` 命名的文件是当前学习主线，例如 `01_Linux 内存管理基础.md` 和 `02_GPU 内存管理基础.md`；`1.笔记` 目录只保存参考学习文档，`2.源码` 保存笔记引用的固定源码基线，`tools` 保存文档自检脚本。

新增学习阶段时，在根目录创建下一个连续编号的 Markdown 文件，例如 `03_主题名称.md`。开始新阶段前，先按下文流程检查 `待补充的知识点.md`；不要把 `1.笔记` 中旧式的 `1. 标题.md` 命名继续用于当前学习主线。

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

### 中文文档自然化检查

每次新建、补充、改写或审阅本仓库的中文文档时，包括只修改一个段落，都必须使用 `humanizer-zh-docs` 技能完成最终检查和润色。不得只在用户明确要求“去 AI 味”时才使用该技能。

- 修改前完整读取 `humanizer-zh-docs` 的 `SKILL.md`，并按其中的流程执行；
- 先完成事实、结构、源码证据和 Markdown 格式，再对本次新增或改动的自然语言做自然化检查；
- 润色时保留技术事实、数字、结论强度、术语、代码、链接、引用、标题层级和用户指定的固定措辞；
- 局部修改只检查和润色本次改动及必要的上下文，不顺手重写无关章节；
- 交付前再次检查文字是否具体、直接、指代清楚，并删除空泛开场、重复总结和聊天机器人式套话；
- 如果技能缺失或无法读取，应明确告知用户，并按相同原则人工检查，不得无提示地跳过。

Place an abbreviation glossary immediately after each document's `#` title. Use the columns `缩写`, `英文全称`, and `中文含义`, and include the technical abbreviations used in that document. Add a glossary entry whenever a new abbreviation is introduced.

Keep filenames stable. For links to files whose names contain spaces or non-ASCII characters, preserve the repository convention: `[label](<./02_GPU 内存管理基础.md>)`.

Separate facts from analysis with the labels already used in the notes: `[SOURCE]`, `[SPEC]`, `[INFERENCE]`, `[BOUNDARY]`, and `[DESIGN]`. Cite the exact source path, version, or specification section whenever making a source-backed implementation claim.

### 源码摘录与解释规则

源码是结论的证据，不是学习主线。正文应先用清晰结论、具体例子、表格或图示讲懂概念，再按需要提供源码或规范验证；读者不查看源码块也应能理解主线。“最小摘录”指能够独立读懂当前结论的最小完整上下文，不以行数最少为目标。

源码和规范证据的引导文字必须使用 Markdown 引用块，与学习主线形成清晰的视觉分隔。`[SOURCE]` 和 `[SPEC]` 都遵守此格式：

```markdown
> **[SOURCE]** 源码路径、固定版本、真实行号和该证据证明的结论。

> **[SPEC]** 规范名称、版本、章节以及与当前结论有关的语义。
```

多条证据索引放在同一个引用块中：

```markdown
> **[SOURCE] 可选源码索引**
>
> - 对象或调用关系：源码路径与行号；
> - 另一条证据：源码路径与行号。
```

引用块只包住证据说明、来源索引和必要的阅读提示。原始源码仍使用普通 fenced code block，不给源码的每一行添加 `>`；源码后的中文解释也回到普通正文。`[BOUNDARY]`、`[INFERENCE]` 和 `[DESIGN]` 按其原有用途排版，不因本规则自动改成引用块。

- 加入源码前先判断必要性。实现流程、对象关系、调用顺序和生命周期保护可以使用源码；概念与硬件语义优先使用规范、例子和图示。与当前结论无关或前文已经证明的源码不要重复加入。
- 摘录既要直接证明当前结论，也要保留读懂它所需的上下文。必要时应包含函数或结构体名称、关键入参、外围 `if/else`、调用者与被调用函数，以及影响结论的返回路径；如果只截取孤立语句会隐藏对象来源、控制流或实际执行顺序，就应扩大到完整相关分支或短函数。无关日志、调试输出、兼容细节和一般性错误路径仍可省略。
- `[SOURCE]`、`[SPEC]` 必须给出准确的文件路径、版本或规范信息以及真实行号。代码行保留原文件行号；不连续片段分成不同代码块，并在正文中说明它们的调用关系或先后顺序。连续展示更容易理解时，不要为了减少行数强行拆开。不得把教学伪代码伪装成原始源码。
- 源码后先说明“它主要证明什么”和“这段代码处在什么上下文中”，再按连续行号组解释关键输入、判断、状态变化、输出和必要联动。避免机械逐行复述；通常使用少量要点即可。
- 如果源码及其解释比概念本身更长、更难理解，应先重组讲解或将源码放入可选阅读部分；不得以破坏上下文为代价继续裁剪。
- 英文源码注释、错误信息或规范摘录后，应立即提供与当前结论有关的中文翻译。
- 修改后核对源码内容与行号，并检查引用范围、相对链接、非连续摘录和代码围栏。

## Current-vs-Deferred Knowledge Workflow

当用户询问某个知识点是否需要补充到当前文档时，必须先明确判断，说明建议放置的位置或后续阶段，然后等待用户明确同意。仅询问“是否需要补充”不构成修改文件的授权；在用户同意前，不得修改当前文档，也不得写入或删除 `待补充的知识点.md`。如果用户在最初请求中已经明确要求“补充”“写入”或“按此执行”，则视为已经授权，无需重复确认。

- 如果确认应当放在当前文档，先说明准备补充到哪个小节以及内容边界；用户明确同意后，再补充到最合适的小节，并完成必要的缩写表、源码引用和 Markdown 检查。
- 如果确认应当留到后续阶段，先说明目标阶段以及准备登记的内容；用户明确同意后，再把该知识点写入仓库根目录的 `待补充的知识点.md`，至少记录“知识点”“目标阶段或目标文档”“届时需要补充的范围”和“当前关联位置”。
- 登记前先检查是否已有相同或重叠条目；有则合并或完善原条目，不要重复登记。
- 开始一个新学习阶段、创建对应章节或扩写对应主题前，必须先读取 `待补充的知识点.md`，向用户汇报目标阶段匹配的条目，并等待用户同意后再补充，不得自动执行。
- 只有在知识点已经写入目标文档并完成基本校验后，才能从 `待补充的知识点.md` 删除对应条目；不要仅标记“已完成”。如果只补充了一部分，应保留并改写尚未完成的范围。
- 删除待办条目时，同时清理该文件缩写表中已不再使用的缩写。`待补充的知识点.md` 只保留尚未完成的知识点。

## Review, Commits, and Pull Requests

现有 Git 历史采用简洁的 `docs(scope): summary` 风格，例如 `docs(gpu-memory): trace allocation and mapping lifecycle`。后续提交继续使用相同格式，并让 summary 直接说明读者可见的文档变化。

Keep each pull request focused. Describe the reader-facing change, identify updated chapters and index links, and state how links/rendering were checked. Link relevant issues or source revisions. Include a screenshot only when a Mermaid diagram, table, or rendered layout materially changed.

### 学习进度

`1.笔记` 目录下的内容仅作为参考学习文档。目前已经完成 `01_Linux 内存管理基础.md` 和 `02_GPU 内存管理基础.md` 的学习，下一阶段尚未确定。
