# Repository Guidelines

## 学习背景与讲解依据

参考根目录的 [学习背景身份卡](./学习背景身份卡.md)，了解用户已有基础与转型方向。具体学习主题、范围、顺序和讲解方式根据当前问题灵活调整，可按需拓展相关方向，以用户当前需求为准。

## Project Structure & Module Organization

本仓库保存 Linux、AMD GPU、内存管理和命令提交的学习笔记与实验材料。`1.笔记` 目录保存以 `NN_主题.md` 命名的当前学习笔记，例如 `01_Linux 内存管理基础.md` 和 `02_GPU 内存管理基础.md`；配套图片与资源保存在 `1.笔记/assets`，`2.源码` 保存笔记引用的固定源码基线。`3.资料` 保存参考 PDF，`4.experiments` 保存 QEMU 教学设备的实验材料与源码。学习背景身份卡和文档常见问题清单保留在根目录。

笔记部分的后续学习只安排第七章，范围统一放在 `1.笔记` 目录的 [07_AMDGPU 通用内存管理与 DRM 任务提交（大纲）](<./1.笔记/07_AMDGPU 通用内存管理与 DRM 任务提交（大纲）.md>) 中。编写第七章前先阅读该大纲；已有章节的局部缺口补回首次需要它的位置。学习笔记继续采用 `NN_主题.md` 命名。

实验部分按 `4.experiments` 中的 [QEMU GPGPU 四阶段实验大纲](<./4.experiments/QEMU GPGPU 实验大纲.md>) 推进，实验计划统一在该大纲维护。进入当前阶段后再细化近期任务，根据实际代码、运行结果和学习反馈动态调整后续范围与顺序，不在项目开始时预先固定全部目标。学习背景身份卡保留个人基础、转型方向与讲解偏好。

## 硬件环境约束

本仓库的 AMDGPU 知识讲解统一采用 **外部 Host CPU + AMD Instinct MI300X 独立 GPU（CDNA 3）** 的学习模型。Host CPU 运行 Linux、驱动和应用的 CPU 端代码，MI300X 执行 GPU Kernel；主机 system RAM 与设备本地 HBM 分别讲解，两者通过 PCIe 连接。

`4.experiments` 中的自定义 QEMU 教学设备按其实际实现单独说明；实验中的简化设计不作为 MI300X 的硬件结论。以下硬件约束用于 AMDGPU 知识讲解与源码分析。

- 这是用户明确选定的教学基线，不代表已经核验实体设备的型号。文档与日常讲解直接使用该模型；实际实验时再核对设备、分区和软件配置，不因尚未实测而重新展开多型号分支。
- 除非用户主动要求，不引入 MI300A、CPU/GPU 集成封装或其他硬件类型的对比，也不把型号差异作为额外学习内容。图示、案例、数量推导和跨文档引用都应与 MI300X 主线一致。
- 示例需要 IOMMU、分区或缓存配置时，先明确本例取值，再沿该配置解释。必要时可说明同一模型内某个配置变化的影响，避免同时引入多套平台。
- 涉及指令、寄存器、执行模型和内存访问语义时，优先查阅仓库中的 `3.资料/amd-instinct-mi300-cdna3-instruction-set-architecture.pdf`；引用时注明封面日期 `2025-08-05`、章节和原文页码。
- AMDGPU 实现、寄存器定义及读写处理可参考 `2.源码/gem5` 子模块（上游：<https://github.com/gem5/gem5>）中的模拟实现。分析时核对 MI300X 对应的配置与代码路径，引用本仓库固定的子模块 commit、文件路径和真实行号。gem5 的简化、占位处理和未实现部分须明确标注；真实硬件语义仍以适用于 MI300X 的 AMD 规范为依据，驱动与运行时行为仍以各自固定源码基线为依据。
- 引用共有组件资料时，必须核对其对 MI300X 的适用性。只用于其他型号的行为不得改名后当作 MI300X 结论；正文只解释当前模型需要的部分，证据不足时保留明确边界。
- 驱动和运行时实现仍须依据仓库的固定源码基线核对，不能由硬件型号推定软件版本、配置或实现路径。原始资料和源码保留原貌；源码中的其他平台分支只在理解本模型的条件判断确有必要时说明。

## Build, Test, and Development Commands

学习笔记没有独立构建系统或自动化测试。实验构建与测试遵循 `4.experiments` 中的说明；Markdown 文档使用预览和以下轻量检查：

```powershell
rg --files -g '*.md'                 # list the note set
rg -n '^#{1,3} ' -g '*.md'           # review heading hierarchy
rg -n '\]\(' -g '*.md'              # find links to verify after renames
```

## 代码修改约束

修改代码时，尽量缩小影响范围和改动量，沿用现有架构、模块职责、接口和执行模型。只修改完成当前任务必需的内容，不顺手重构、移动代码或改名；必须调整架构或接口时，先说明原因和必要范围。

与用户的交互、代码注释、文档说明以及提交标题和正文均使用中文。技术术语可保留通用英文写法；标识符、路径、命令、协议字段、汇编助记符、机器读取的标记和许可证声明保留原文，不因中文化改变其含义或行为。

## Testing Guidelines

Before submitting, preview edited files to check tables, Mermaid diagrams, code fences, and internal anchors. Test every changed relative link by opening it from the rendered note.

## Writing Style & Naming Conventions

Follow the surrounding Chinese-language prose and retain established technical terms such as GPUVM, KFD, AQL, MQD, and HQD. Give each note one `#` title, then use numbered `##` sections and concise `###` subsections. Prefer short explanatory paragraphs, concrete examples, and relationship or flow diagrams. Tag fenced blocks with a language such as `text` or `mermaid`.

When answering questions about this repository, keep the response concise, clear, and direct. Use a short concrete example when it helps explain an abstract concept.

### 学习说明的展开方式

- 创建、补充、改写文档和回答问题时，尽量避免使用表格对比，尤其不要用职责表或字段对照表代替概念讲解。优先围绕同一个具体例子，用连贯文字、必要的步骤和关系图说明对象如何配合；比较两个对象时，先交代各自在例子中的作用，再解释联系与区别。用户明确要求表格，或需要集中查阅参数、缩写等信息时可以使用，但仍须讲清必要的前提和过程。
- 补充知识点时，不能只在原段落中插入一句结论。应单独展开，用关系图、流程图或带具体数值的例子配合简短解释，让读者看清对象之间的联系。
- 展开一个主题前，先接住具体任务：当前是谁在做什么、已经拿到什么、接下来要得到什么。先给本节所需的完整关系图或执行路径，让读者看到起点、终点和各步作用，再沿图解释概念、字段、数值计算与分支条件。不要先孤立罗列术语，直到末尾才说明这些术语用来完成什么。
- 用于带读者进入问题的关系图应放在正文前部。图中可以出现后面要解释的字段或函数名，但应同时标注它们的中文作用；不能因为含有源码名称，就把整张关系图移到文末的“可选源码”。原始源码摘录仍放在相关概念和过程讲清之后，作为验证。
- 按知识依赖安排章节。概览说明当前需要的角色、输入、输出和主要关系；图中可以出现必要的对象或字段名，并就地标注中文作用。后续章节才讲的具体取值、参数编码和详细配置步骤放到对应章节，概览中只说明用途和后文位置，不让读者依赖这些细节才能读懂当前主线。
- 用户追问暴露缺失前提时，先检查原有关系图和章节顺序，把前提补到第一次需要它的位置，再合并后文解释。不要把所有追问连续追加在当前段落，导致概览膨胀、同一概念多次解释或后续章节的内容提前出现。
- 审阅时逐节检查：读者在看到术语或公式前，是否知道当前问题与目标；能否沿图说出每步的输入、动作和结果；需要的前提是否已经说明。跨节移动内容后同步检查大纲、引用与衔接，并保留用户认可的图示和技术证据。
- 展示硬件架构前，先查阅适用于 MI300X 的实际参考资料、文档和原图。已有图示能够清楚表达当前内容时，直接引用并嵌入原图，不再用 `text` 图或 Mermaid 图重复绘制。
- 原图只需补充中文释义时，在图旁解释术语和阅读顺序。只有原图缺失、表达不清，或无法展示本节需要的字段、对象关系、访问过程与时序时，才补画示意图，并说明补图解决的问题。
- 使用原图时注明出处、版本或日期、页码或图号，并核对 MI300X 的适用性；保留原始标注，不把其他型号的图改名使用。需要截取时标明范围，并保留理解图示所必需的上下文。区分物理布局图、逻辑结构图和流程图，避免把布局或比例示意当作实际访问顺序。
- 补画示意图时，标出对象、保存的值，以及箭头表示的选择、访问或写入动作。图前说明例子条件，图后解释关键关系。
- 补充示意图优先使用 `text` 或 Mermaid；出现对齐、布局或连线问题时，简化图示、拆分步骤，并配合文字解释。除非用户明确要求，不生成新的示意图片并插入文档。
- 用户选中或认可的图示应随讲解写入文档，不能在补充时只保留图中的结论。若相关事实或案例改变，自绘图同步修正，引用原图保持原貌并另配说明或换用适用原图。用户要求“简要”时，压缩重复文字，保留帮助理解的图示和必要步骤。
- 以学习者能否沿图说明“谁保存什么、谁根据什么找到谁、下一步做什么”为检查标准。不要用加粗的一句话或职责罗列表代替这层解释。

### 十六进制数值的写法

- 正文、教学示例、表格、`text` / Mermaid 图和自绘图片中的长十六进制地址，超过 4 位时从右向左每 4 位用下划线分组。例如 `0x40_8000_0000`、`0x40_0000_0000`、`0x8000_0000`；页号、表项值、寄存器值和掩码采用相同规则，4 位及以下不拆分。
- 下划线只帮助阅读。分组时保留原有数字、大小写、前导零和位宽，不补零、不删零，不改变数值；同一案例在正文、推导和图示中保持一致。
- 原始源码、可执行代码或命令、实际日志、规范原文及引用原图保留原貌，旁边的教学解释使用分组写法。修改自绘图片时同步更新可编辑源文件，并检查数字、连线和对齐。

### 标题写法

- 常规概念、对象关系和操作流程的标题，优先直接写出具体对象、动作或结果。例如“Signal、通知槽与等待线程的关联”“中断上半部：读取记录并转交 KFD”。
- 问句标题只用于明确的易混淆点、反直觉现象或推演题，例如“已有完整事件编号，为什么还要写通知槽”。避免连续使用“为什么”“怎样”“如何”“哪些”等问句，也不要把每轮对话中的追问直接变成小标题。
- 一般性的提问可以放在正文开头引出讲解；标题应让读者只看目录就能定位本节内容。同级标题尽量采用一致的表述方式。
- 不要机械地把问句改成“某某机制”“某某原理”等空泛名称。改写后仍须保留具体对象和本节真正解释的动作、关系或条件。
- 调整标题时保留原有章节编号和层级，除非用户要求重构。同步更新大纲、知识点索引及文内、跨文档链接的标题文字和锚点，并检查跳转目标。

### 文档常见问题清单

- 用户要求生成文档时，写作前必须读取 [文档的常见问题](./文档的常见问题.md)，按已有条目避开相应问题；生成后逐条检查并修正，再交付。
- 新增问题或调整已有条目，先展示具体内容并取得用户确认。用户已明确授权的整理或修改，在授权范围内直接执行；用户只要求生成或修改学习文档时，不自行登记问题。
- 每个条目围绕一个可复用的问题，写清它造成的阅读困难及其避免方法。篇幅以讲清楚为准，不限定句数；必要时补充前提、简短例子或图示，通过合并重复问题、删除无关细节来控制篇幅，不为压缩文字省略关键解释。
- 维护清单时，同步检查本文件和清单：重复问题合并，适用场景不同的要求写清条件，互相矛盾的要求统一后再保留。用户已明确更正的旧要求必须同步更新；没有依据决定取舍时，向用户说明具体冲突并确认。

### 中文文档自然化检查

每次新建、补充、改写或审阅本仓库的中文文档时，包括只修改一个段落，都必须使用 [humanizer-zh](https://github.com/op7418/Humanizer-zh/blob/f4518a8eab97b8bfebc66a89d34320a89bef6930/SKILL.md) 技能完成最终检查和润色。不得只在用户明确要求“去 AI 味”时才使用该技能。

- 修改前完整读取 `humanizer-zh` 的 `SKILL.md`，并按其中的流程执行；
- 先完成事实、结构、源码证据和 Markdown 格式，再对本次新增或改动的自然语言做自然化检查；
- 润色时保留技术事实、数字、结论强度、术语、代码、链接、引用、标题层级和用户指定的固定措辞；
- 局部修改只检查和润色本次改动及必要的上下文，不顺手重写无关章节；
- 交付前再次检查文字是否具体、直接、指代清楚，并删除空泛开场、重复总结和聊天机器人式套话；
- 如果技能缺失或无法读取，应明确告知用户，并按相同原则人工检查，不得无提示地跳过。

Place an abbreviation glossary immediately after each document's `#` title. Use the columns `缩写`, `英文全称`, and `中文含义`, and include the technical abbreviations used in that document. Add a glossary entry whenever a new abbreviation is introduced.

Keep filenames stable. For links to files whose names contain spaces or non-ASCII characters, preserve the repository convention: `[label](<./1.笔记/02_GPU 内存管理基础.md>)`.

Separate facts from analysis with the labels already used in the notes: `[SOURCE]`, `[SPEC]`, `[INFERENCE]`, `[BOUNDARY]`, and `[DESIGN]`. Cite the exact source path, version, or specification section whenever making a source-backed implementation claim.

### 源码摘录与解释规则

源码是结论的证据，不是学习主线。正文应先用连贯解释、具体例子或图示讲懂概念，再按需要提供源码或规范验证；读者不查看源码块也应能理解主线。“最小摘录”指能够独立读懂当前结论的最小完整上下文，不以行数最少为目标。

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
- 源码引用必须支持在 VS Code 的 Markdown 编辑区和预览中点击后直接定位到真实行号。当前 Windows 环境中的本地源码定位使用 VS Code 原生格式 `vscode://file/绝对路径:行:列`，例如 `vscode://file/C:/path/to/amdgpu_discovery.c:2484:1`；路径中的中文和空格使用 URL 编码。不要给本地源码文件 URI 附加 `#L…` 行号片段，避免同一物理文件被当作不同文档打开并触发 C/C++ IntelliSense 的规范化路径冲突。文件名链接定位到当前引用的第一段，每个行号或范围也单独做成链接；范围文字保留完整起止行号，链接定位到起始行，不连续范围分别链接。定位路径按当前仓库位置生成，移动目录后同步更新；普通文档链接继续使用相对路径。已有上游源码链接保留固定 commit 与 `#L起始行-L结束行`。交付前核对文件、行号范围和预览中的链接目标，并区分格式检查与实际打开验证，不能只凭行号解析通过就宣称已验证跳转。
- 源码后先说明“它主要证明什么”和“这段代码处在什么上下文中”，再按连续行号组解释关键输入、判断、状态变化、输出和必要联动。避免机械逐行复述；通常使用少量要点即可。
- 如果源码及其解释比概念本身更长、更难理解，应先重组讲解或将源码放入可选阅读部分；不得以破坏上下文为代价继续裁剪。
- 英文源码注释、错误信息或规范摘录后，应立即提供与当前结论有关的中文翻译。
- 修改后核对源码内容与行号，并检查引用范围、相对链接、非连续摘录和代码围栏。

## 当前章节与第七章大纲的维护

当用户询问某个知识点是否需要补充时，先判断应放入已有章节还是第七章的具体小节，说明理由和范围。仅询问“是否需要补充”不构成修改授权；用户已明确要求“补充”“写入”或“按此执行”时，在授权范围内直接执行，无需重复确认。

- 补入已有章节时，放到概念第一次被需要的位置，并完成缩写、证据、图示和链接检查；不要把零散缺口集中堆入综合章节。
- 属于第七章的知识点，按依赖关系编入大纲对应小节，写清该节要讲通的过程和学习边界；合并重复内容，不另外维护待补充条目。
- 编写或扩写第七章前，先核对大纲与已有章节的衔接。用户只要求大纲时交付大纲；明确要求正文时，沿已授权范围展开。
- 大纲承担章节结构和内容规划，不作为完成后逐条删除的任务清单。正文展开后按实际结构维护大纲，并同步更新跨文档引用。

## Review, Commits, and Pull Requests

现有 Git 历史采用简洁的 `docs(scope): summary` 风格，例如 `docs(gpu-memory): trace allocation and mapping lifecycle`。后续提交继续使用相同格式，并让 summary 直接说明读者可见的文档变化。

Keep each pull request focused. Describe the reader-facing change, identify updated chapters and index links, and state how links/rendering were checked. Link relevant issues or source revisions. Include a screenshot only when a Mermaid diagram, table, or rendered layout materially changed.

### 学习与实验进度

2026-10-29 完成设备、固件、驱动和用户库重构，协议统一为版本 3。2026-10-30 在子模块 `efd22b0` 验证 QTest 11/11、汇编器 7/7；Linux 全栈验收尚未完成，需恢复指定开发环境后运行 GPUVM on/off 两种模式。历史验收只代表其记录的版本。 协议差异见 [PROTOCOL_V3.md](<./4.experiments/gpu-study-qemu/software/gpgpu/PROTOCOL_V3.md>)。

学习部分已完成第 06 阶段上下篇的学习：[06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）](<./1.笔记/06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（上）.md>)与[下篇](<./1.笔记/06_AQL 应用的完整运行流程：驱动初始化、执行与资源释放（下）.md>)。第七章仍是后续学习阶段，按[第七章大纲](<./1.笔记/07_AMDGPU 通用内存管理与 DRM 任务提交（大纲）.md>)继续；已有章节的补充按当前问题就地完成。

根据用户反馈，实验第一阶段已完成，并已搭配 A57、支持 SMMUv3 系统 IOMMU。第二阶段围绕用户 AQL Queue、Doorbell、CP 与 Signal 展开，实验范围见 [QEMU GPGPU 四阶段实验大纲](<./4.experiments/QEMU GPGPU 实验大纲.md>)，已确认约定见 [CP/MEC 第一版规格](<./4.experiments/CP_MEC 第一版规格.md>)。2026-10-11 已完成双进程设备与原生 RISC-V CP 基础接入，2026-10-14 完成 CP Host 访存窗口及回归，2026-10-17 原生 CP 迁移至 RV64，窗口增加对齐的 8 字节读写并通过原有 8 项 CP 回归；裸机物理访存、地址编码和 RV32 计算执行器保持原约定。

2026-10-19 完成第二阶段设备队列入口、RV64 CP 固件、Linux 驱动与 HSAKMT 风格接口库的实现和本轮验收，CP 回归通过 16/16。同日按用户确认，采用宿主机交叉编译生成 `6.18.57-0-gpgpu-virt` 内核，内置 `GPU_BUDDY`；原生构建进度与环境保留。A57 客体上，双进程、`IOMMU=none` 的 Linux 队列验收通过 5/5，卸载检查通过 1/1；单／双进程与 `none`／`smmuv3` 四种同步组合均通过，每种包含装卸载 5/5、17,953 个示例输出值、运行时检查 68/68 和卸载重载 2/2。具体结果见 [大纲进度说明](<./4.experiments/QEMU GPGPU 实验大纲.md#current-progress>)；多 VMID、抢占和运行中复位恢复仍属于后续阶段。

硬件查阅入口为同级独立的 [GPGPU 虚拟加速器硬件手册](<./4.experiments/QEMU_2026_GPGPU_硬件手册.html>)，按硬件模块维护寄存器、位域、访问权限、复位值及必要的硬件行为。地址空间章节集中列映射与查阅链接；CP 控制与访存窗口、HQD 与 Doorbell 分别成章，IH 归入中断控制，GPUVM 上下文、失效和故障归入第 17 章。后续寄存器按功能补入所属模块，独立模块可单独成章；不固定章节数量，也不按实验阶段重复说明。软件接口、对象管理和项目进度留在规格、软件说明及大纲中。2026-10-19 规格复核发现的未知管理结果码问题已在第三阶段修复：结果不属于已定义的 `0～6` 时按协议错误保留资源。修复前证据和本次验证入口见[大纲复核记录](<./4.experiments/QEMU GPGPU 实验大纲.md#stage-two-spec-review>)。

2026-10-19 已按[第三阶段安排](<./4.experiments/QEMU GPGPU 实验大纲.md#stage-three-vmid>)实现[GPUVM 第一版规格](<./4.experiments/GPUVM 第一版规格.md>)：单一 DRM 入口、GEM 固定存储、32 位 GPUVA、三级 4 KiB 页表、两个用户 VMID、每 VM 一条用户 Queue、完整用户存储访问翻译和同步 TLB 失效。按用户确认保留 RV32 控制页 `0x8000_0000～0x8000_0fff`。库封装整对象分配与映射，先准备对象再建 Queue，Queue 存活期间冻结映射；关闭时按队列、事件、映射和存储顺序清理，结果未知则保留。CP 检查 18/18，GPUVM 在 `none/smmuv3` 下各 5/5、卸载各 1/1，异常保留检查 3/3；旧队列和四种同步组合也已回归。固定提交、验收归档、复现命令与日志见[第三阶段验收](<./4.experiments/gpu-study-qemu/software/gpgpu/README.md#stage-three-validation>)。第三阶段可用于项目讲解与求职；TTM、迁移、驱逐、换页、按需补页、异步更新和复杂恢复仍留到后续，强制中止与运行中复位恢复归第四阶段。

以下 2026-10-17、2026-10-18 的段落保留规格确认时的历史记录，其中“尚待实现”“尚未接入”等措辞只描述当时进度；当前代码与验收状态以上述说明和大纲为准。

2026-10-18 按实验子仓库固定提交 `57543dd54b6b046b888277272fa84af81746b1ac` 重新核对：原生 CP 为 RV64，执行裸机固件；计算执行器仍为 RV32，执行应用 Kernel，计算线程的 `a0` 仍为 32 位。文档和讲解必须写清执行主体。CP 的 Host 窗口已实现，计算执行器读取 Host 参数的路径尚未实现，16 字节描述对象及只读参数窗口已在[规格 9.5.2](<./4.experiments/CP_MEC 第一版规格.md#spec-kernel-executor-interface>)确认，尚待接入；CP 分发寄存器和状态接口已按[规格 9.5.3](<./4.experiments/CP_MEC 第一版规格.md#spec-cp-dispatch-interface>)确定，尚待实现。源码依据见[CP 与计算执行器的位宽](<./4.experiments/CP_MEC 软件实现、参考与扩展.md#cp-executor-widths>)。

第二阶段的 VMID 统一固定为 0，管理队列与用户 AQL 队列均使用该值。多 VMID 的数量、分配、传递、复用及设备访问隔离作为第三阶段扩展，进入该阶段后再细化；当前约定见 [规格 9.1.5](<./4.experiments/CP_MEC 第一版规格.md#spec-vmid-scope>)，扩展范围见 [第三阶段大纲](<./4.experiments/QEMU GPGPU 实验大纲.md#stage-three-vmid>)。

2026-10-17 已确认 [规格 9.1.6](<./4.experiments/CP_MEC 第一版规格.md#spec-cp-memory-interface>)：固件保存访存上下文，按 HQD 槽位归属错误；可归属到用户队列的访问错误停止该队列后续取包，KIQ 实际通道故障或固件代码、栈访问异常停止队列调度，范围已按 [9.6.1](<./4.experiments/CP_MEC 第一版规格.md#spec-queue-error-stop-scope>)补齐。Signal 保留 64 位有符号值，Host 提交前置 `1`，提交后只读，由 CP 在任务成功完成后减为 `0`；一次使用中的 Signal 对应一个任务，第二阶段不要求原子读改写接口。队列错误处理和 Signal 流程尚待实现，完整读写与发布顺序仍需验证，Signal 布局、通知槽标记和等待协议已按[9.5.4](<./4.experiments/CP_MEC 第一版规格.md#spec-signal-completion-protocol>)确定。

Host 默认等待采用 [HSA_WAIT_STATE_BLOCKED 对应的流程](<./4.experiments/CP_MEC 第一版规格.md#spec-signal-blocked-wait>)：先读取 Signal，从本次等待开始主动检查约 `200 μs`，仍未完成且未超时则进入内核事件等待，唤醒后复查。`HSA_WAIT_STATE_ACTIVE` 的持续主动等待列为[后续扩展](<./4.experiments/QEMU GPGPU 实验大纲.md#signal-active-wait-extension>)；默认流程中的短暂轮询仍属于第二阶段。

同日确认 [规格 9.1.7](<./4.experiments/CP_MEC 第一版规格.md#spec-firmware-reservation>)：在 64 MiB VRAM 末尾固定保留 4 MiB 给 CP，范围为 `0x03c0_0000～0x03ff_ffff`，入口为 `0x03c0_0000`，最后 64 KiB 用作栈。驱动分配池排除该范围，应用退出、队列销毁和 CP 暂时复位都不释放；固定链接布局、启动初始化及范围检查按[规格 3.1 节](<./4.experiments/CP_MEC 第一版规格.md#spec-firmware-layout>)接入，目前仍为已确认设计。9.1 各项均已确认。

前 60 MiB VRAM（`0x0000_0000～0x03bf_ffff`）由 Linux 内核驱动按设备统一管理，负责实际区间的分配、占用记录与回收；首个页在该管理范围内登记为保留，末尾 4 MiB 固件区不参与普通分配。底层参考 AMD 复用 `gpu_buddy`，目标内核仍提供 `drm_buddy` 时采用对应实现。驱动负责请求校验、并发保护、对象归属与释放时机；接口、配置与导出符号按目标内核核对，选型已确认、接入仍待实现，详见[通用伙伴分配器说明](<./4.experiments/CP_MEC 软件实现、参考与扩展.md#vram-buddy-allocator>)。

同日确认 [规格 9.2.1](<./4.experiments/CP_MEC 第一版规格.md#spec-mqd-layout>)：KIQ、HIQ 和用户队列共用 64 字节 MQD，最低按 8 字节对齐、多字节字段小端，完整布局见[规格 2.6 节](<./4.experiments/CP_MEC 第一版规格.md#spec-mqd-format>)。装载配置并恢复消费位置后最后激活；卸载确认相关访问结束后，只保存 `saved_rptr` 和 `saved_error`。进度已按 9.4.2 确定为 32 位包编号，64 位保存槽零扩展保存该值；错误保存及清理后重建已按 [9.6.1](<./4.experiments/CP_MEC 第一版规格.md#spec-queue-error-policy>)确定，需要强制停止或故障复位的步骤列入[后续异常恢复扩展](<./4.experiments/QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)，MQD 方案尚待实现。

同日确认 [规格 9.2.2](<./4.experiments/CP_MEC 第一版规格.md#spec-register-encoding>)：Ring 控制直接保存字节容量，Doorbell 控制采用以 4 字节为单位的 BAR4 相对偏移和独立使能，完整字段规则见[规格 8.1 节](<./4.experiments/CP_MEC 第一版规格.md#spec-hqd-field-encoding>)。MQD 保持 64 字节、HQD 保持 15 个寄存器位置，RPTR 按 9.4.2 保存 32 位包编号，ERROR 编码已按 [9.6.1](<./4.experiments/CP_MEC 第一版规格.md#spec-queue-error-policy>)确定，寄存器方案仍待实现。

同日确认 [规格 9.2.3](<./4.experiments/CP_MEC 第一版规格.md#spec-register-access>)：设备冷复位或整体复位清零 HQD 与选槽寄存器，CP 单独复位保留 HQD；访问统一为对齐的 32 位小端读写，运行后 Host 对 HQD 只读。非法访问保留目标状态并记录全局错误，完整规则见[规格 8.2 节](<./4.experiments/CP_MEC 第一版规格.md#spec-hqd-access-rules>)；HQD 访问尚待实现。

同日确认 [规格 9.2.4](<./4.experiments/CP_MEC 第一版规格.md#spec-hqd-address-selection>)：Host 用一个选槽窗口访问设备内 4 份 HQD，CP 按 `0xffff_0000 + 槽位编号 × 0x100 + 字段偏移` 访问同一份状态，完整范围见[规格 8.3 节](<./4.experiments/CP_MEC 第一版规格.md#spec-hqd-address-map>)。无效选择拒绝写入、保留原值并报全局错误，CP 的未映射访问进入访存异常。9.2 各项已确认，功能仍待实现。

同日确认 [规格 9.3.1](<./4.experiments/CP_MEC 第一版规格.md#spec-management-command-scope>)：KIQ 建立和卸载 HIQ，HIQ 管理按申请创建的用户队列；两条管理队列均支持映射、卸载和同一 Ring 中后附写完成标记。命令直接保存在 Ring 中，不增加间接命令执行，完整分工见[规格第 4 节](<./4.experiments/CP_MEC 第一版规格.md#spec-management>)。队列功能尚待实现。

同日确认 [规格 9.3.2](<./4.experiments/CP_MEC 第一版规格.md#spec-management-command-layout>)：三种管理命令统一为固定 32 字节、小端、按 32 字节对齐，`MAP_QUEUES`、`UNMAP_QUEUES`、`WRITE_COMPLETION` 的编号依次为 `1`、`2`、`3`。映射、卸载命令的偏移 `0x04` 均保存 32 位 `queue_kind`，编码为 `HIQ = 1`、`USER_AQL = 2`，`0` 和其他值非法；偏移 `0x08` 均保存 64 位 MQD 物理地址，后 16 字节保留并填零。映射 HIQ 使用专留槽位 1，映射用户队列由 CP 从槽位 2、3 中选择空闲槽位；卸载时，CP 在允许范围内用完整 MQD 地址匹配当前绑定。每条存活队列使用独立 MQD，相关管理操作和卸载收尾完成前不释放或复用。MQD 保持 64 字节，HQD 保持 15 个寄存器位置；完成地址保存完整的 64 位 Host 物理字节地址，写入值为 64 位无符号数。完整字段和图示见[规格第 4.1 节](<./4.experiments/CP_MEC 第一版规格.md#spec-management-packet-format>)，本小节已确认，队列功能仍待实现。

同日确认 [规格 9.3.3](<./4.experiments/CP_MEC 第一版规格.md#spec-management-slot-occupancy>)：队列和 MQD 按申请动态创建，[用户队列名额](<./4.experiments/CP_MEC 第一版规格.md#spec-user-queue-capacity>)仍为全设备两个。CP 在固件私有数据中维护每槽占用状态和绑定的 MQD 地址；装载中、已绑定、卸载中及异常未清理均算占用，不能仅凭 `ACTIVE = 0` 认定空闲。按完整地址查重，重复映射返回失败并保留原状态；卸载无当前绑定的地址返回“队列未映射”，不保存历史卸载记录。正常卸载须停止取包、确认访问结束并成功保存状态后，才解除绑定、释放槽位。映射失败须确认尚未激活、访问结束且部分配置已撤销，才归还槽位，否则保留占用。完整图示与规则见[规格 4.2 节](<./4.experiments/CP_MEC 第一版规格.md#spec-management-slot-state>)。本小节已确认，功能尚待实现；请求结果码和返回位置已按 9.3.5 确定，基本错误退出按 9.6 执行，强制停止与故障复位留作后续扩展。

同日确认 [规格 9.4.1](<./4.experiments/CP_MEC 第一版规格.md#spec-ring-capacity-boundaries>)：管理 Ring 每槽 32 字节，AQL Ring 每槽 64 字节，包不跨末尾、不增加填充；末槽之后回到槽 0，继续使用原内存，不整体清空 Ring。AQL Header 初始化为 `INVALID`，Host 根据消费回报复用旧槽，CP 根据新的可消费范围和发布状态读取新包；完整图示见[规格 5.1 节](<./4.experiments/CP_MEC 第一版规格.md#spec-ring-packet-boundaries>)，功能尚待实现。进度表示与回绕规则见[规格 9.4.2](<./4.experiments/CP_MEC 第一版规格.md#spec-ring-progress-values>)。

同日确认 [规格 9.4.2](<./4.experiments/CP_MEC 第一版规格.md#spec-ring-progress-values>)：两类 Ring 均使用 32 位无符号包编号，R 指下一待消费包。用户 AQL 的 W 指下一待预留包，管理 Ring 的 W 标出已发布范围。容量判断按 2026-10-18 确认的 9.4.4 主方案调整：AQL 先原子取号，再按自己的编号 P 等待旧槽可复用；`D = (W - R) mod 2^32` 表示已预留未归还的编号数量，可以大于槽数 N，不能仅凭 `D > N` 报错。按 `P mod N` 定位物理槽，等 `(P - R) mod 2^32 < N` 并完成消费回报同步后才可填包，Header 仍决定包是否发布。管理 Ring 保留按容量限制已发布范围的规则。在途预留不得跨过完整的 32 位编号周期。HQD 和共享进度保存 32 位值，MQD 的 64 位 `saved_rptr` 零扩展保存 R；正常重装恢复 R 并读取保留的 W。完整规则见[规格 5.2.1 节](<./4.experiments/CP_MEC 第一版规格.md#spec-ring-progress>)，功能尚待实现。

同日确认 [规格 9.4.3](<./4.experiments/CP_MEC 第一版规格.md#spec-shared-value-access>)：Signal、管理完成标记和通知槽中的 64 位字段至少按 8 字节对齐，双方每次完整读写 64 位，只能读取完整旧值或完整新值；不采用拆成两个 32 位、反复读取再拼接的协议。W、R 继续按完整的 32 位值访问。Host、CP 与 QEMU 后端共同保证完整访问，具体规则见[规格 2.2.1 节](<./4.experiments/CP_MEC 第一版规格.md#spec-shared-value-integrity>)；队列接入、屏障实现和并发读写验证尚未完成，Signal 仍由 CP 单独更新。

2026-10-18 确认 [9.4.4 用户 AQL 多生产者主方案](<./4.experiments/CP_MEC 第一版规格.md#spec-ring-submitters>)：同一条 Queue 支持多个 Host 线程原子预留编号、并行填包、分别发布 Header。W 保持 32 位，由 Host CPU 原子更新，CP 只读；进度区须正确对齐并支持 CPU 原子访问。线程先取号、再等自己对应的物理槽，保持 `INVALID` 填包，最后发布有效 Header 并通知 Doorbell。CP 不跳过当前 `INVALID` 包，按正常调度检查其他队列，并能在 W 不变时发现 Header 发布。交错图见[规格 5.2.2 节](<./4.experiments/CP_MEC 第一版规格.md#spec-aql-multi-producer>)。

同日补齐并确认 9.4.4 的三项规则：AQL 的 `header + setup` 采用对齐的完整 32 位读写与发布，CP 先恢复 `INVALID` 并保证可见，再回报新 `R`，Host 同步后复用。每条管理 Ring 由驱动串行保护发布，确认两个空槽后写完命令对，一次发布新 `W` 并通知，释放提交锁后分别等待独立结果区。可能失败的资源准备和参数检查放在取号前；正常路径取号后必须发布，不支持取消预留编号或回退 `W`。异常留下空洞时停止继续使用队列并保留资源，补洞和自动恢复留作扩展；在途预留限额随接入落实，防止活跃编号重复。本小节已全部确认，功能及并发同步仍须实现和验证。9.3 的管理命令与结果规则也已确认，功能尚待实现。

2026-10-18 确认 [规格 9.4.5](<./4.experiments/CP_MEC 第一版规格.md#spec-doorbell-rules>)：每条 Queue 使用独立 Doorbell 入口，管理入口由驱动保留，用户入口创建时分配，经 MQD 关联到 HQD。入口按 8 字节对齐，每次写入完整 64 位小端值，低 32 位为已发布包编号、高 32 位为零；W、R 仍按 32 位访问。通知允许 `11 → 10`，包 10 就绪后按序继续处理包 10、11，无需补发包 11 的通知；重复或合并通知不能遗漏工作。CP 每次轮到检查活跃队列时读取共享 W，并从 R 检查 Header，W 未变也会复查；沿用每次执行一个 Dispatch 的既定调度，不要求一次清空 Ring。完整交错图和规则见[规格 5.2.3 节](<./4.experiments/CP_MEC 第一版规格.md#spec-doorbell-notification>)。本项为设计确认，功能尚待实现和验证；9.4.4 的首部访问、并发发布及预留使用约束也已确认。

2026-10-18 确认 [9.5.1 第一版支持的 AQL 包与字段](<./4.experiments/CP_MEC 第一版规格.md#spec-aql-packet-scope>)：仅执行标准 64 字节布局的 Kernel Dispatch，保留位填零；独立 Barrier、Agent Dispatch 和厂商自定义包不支持，`INVALID` 按未发布等待。支持一至三维完整工作组，CP 将各轴线程数除以每组尺寸，换算工作组数量并检查溢出；每组最多 1024 个线程、最多 4096 个工作组、实际启动线程总数最多 65536。描述对象、参数块和完成 Signal 都须有效，组段和私有段大小均为 0，acquire、release scope 均为 `SYSTEM`，Header 的 `barrier` 位允许 0、1。已发布的非法或不支持包停止所属队列后续取包，不写成功 Signal。完整布局、向量加法图和尺寸换算见[规格 6.1 节](<./4.experiments/CP_MEC 第一版规格.md#spec-dispatch-packet>)。本项为设计确认，校验、执行接口和同步验证尚待实现；队列错误编号已按 [9.6.1](<./4.experiments/CP_MEC 第一版规格.md#spec-queue-error-policy>)确定，失败收尾按[规格 7.3 节](<./4.experiments/CP_MEC 第一版规格.md#spec-failure-retirement>)处理。

2026-10-18 确认 [9.5.2 Kernel 描述对象与 RV32 计算执行器参数约定](<./4.experiments/CP_MEC 第一版规格.md#spec-kernel-executor-interface>)：运行时生成 VRAM 中的 16 字节描述对象，至少按 8 字节对齐，四个 32 位小端字段依次保存代码入口、代码长度、参数长度和填零的保留字段。代码从入口开始，入口按 4 字节对齐、长度为非零的 4 字节整数倍，执行器检查取指范围。Host 参数基址至少按 8 字节对齐，长度为 4 字节至 64 KiB 的 4 字节整数倍，无参数时使用 4 字节零占位块。执行器保存完整 64 位 Host 基址和 32 位参数长度，计算线程以 `a0 = 0x9000_0000` 访问只读窗口 `0x9000_0000～0x9000_ffff`，按需直接读取 Host RAM。窗口只接受对齐的 4 字节读取，检查实际长度和地址溢出，写入或访存失败报错；描述对象非法、取指或参数越界也使任务失败并停止所属队列，不发布成功 Signal。Host 保留描述对象、代码和参数的内容及存储，直到任务不再访问。完整布局和向量加法示例见[规格 6.2 节](<./4.experiments/CP_MEC 第一版规格.md#spec-kernel-descriptor>)。本项为设计确认，功能尚待实现和验证；计算交接接口见下述 9.5.3，队列错误编号已按 [9.6.1](<./4.experiments/CP_MEC 第一版规格.md#spec-queue-error-policy>)确定，失败收尾按[规格 7.3 节](<./4.experiments/CP_MEC 第一版规格.md#spec-failure-retirement>)处理，执行器细分错误码仍需补齐。

2026-10-18 确认 [9.5.3 CP 提交计算与读取执行结果](<./4.experiments/CP_MEC 第一版规格.md#spec-cp-dispatch-interface>)：CP 解析描述对象，经 `0xfffd_0000 + BAR0 字节偏移` 访问同一份分发状态，保留原有启动配置和 `DISPATCH`（`0x0330`）。新增 `KERNEL_CODE_SIZE`（`0x032c`）、`KERNEL_ARGS_SIZE`（`0x0334`）用于实际范围检查；新增 `DISPATCH_STATUS`（`0x0338`，空闲、忙、成功、失败分别为 0、1、2、3）、`DISPATCH_ERROR`（`0x033c`）和 `DISPATCH_ACK`（`0x0340`）用于返回和确认结果。寄存器按对齐的 32 位小端值访问；CP 在空闲时填完配置并保证顺序后写 `DISPATCH=1`，设备统一保存配置。忙或结果未确认时拒绝覆盖配置和重复提交；CP 保存终态结果、清理并写确认后回到空闲，确认不能中止执行。

执行器分段推进并保留线程状态和累计预算，CP 仍等待整个 Dispatch 完成，Host 在有空槽时可继续发布。正常路径由 CP 独占提交和确认，旧 Host 直接提交路径单独用于回归；成功写回且相关访问结束后才返回成功，失败也须先结束相关访问。CP 成功收尾后发布 Signal，失败记录并停止所属队列。完整布局及流程见[规格 6.3 节](<./4.experiments/CP_MEC 第一版规格.md#spec-executor-dispatch>)。本项为设计确认，映射、五个新增寄存器和分段执行尚待实现和验证；Signal 与等待协议见下述 9.5.4，队列错误编号已按 [9.6.1](<./4.experiments/CP_MEC 第一版规格.md#spec-queue-error-policy>)确定，失败收尾按[规格 7.3 节](<./4.experiments/CP_MEC 第一版规格.md#spec-failure-retirement>)处理，执行器细分错误码仍需补齐。

2026-10-18 确认 [9.5.4 Signal 的表示与完成操作](<./4.experiments/CP_MEC 第一版规格.md#spec-signal-completion-protocol>)：在已有完成顺序和默认等待方式上，补齐 24 字节 Signal 布局；偏移 `0x00`、`0x08`、`0x0c`、`0x10` 分别保存 64 位有符号完成值、32 位无符号事件编号、填零的 32 位保留字段和 64 位通知槽地址，至少按 8 字节对齐、多字节字段小端。每个使用中的 Signal 独占事件和通知槽，事件编号在所属进程内非零且不与存活事件重复；通知槽占 8 字节、至少按 8 字节对齐，初值为 0，CP 完成时写入零扩展后的事件编号。CP 在发布完成值前取得并保存通知信息；驱动先保存“已通知”状态，再清零通知槽并唤醒等待者。等待登记后复查条件，通知提前到达时直接返回复查 Signal；等待返回不清除事件状态，同一任务可唤醒多个等待者。旧通知和相关处理结束后才可重新初始化。完整布局和交错图见[规格 2.5.2 节](<./4.experiments/CP_MEC 第一版规格.md#spec-signal-layout>)与[2.5.3 节](<./4.experiments/CP_MEC 第一版规格.md#spec-signal-notify-wait>)。本项为设计确认，功能尚待实现和验证；可见性操作见下述 9.5.5，错误处理按 9.6 的已确认范围执行，资源接口已按 9.7 确认。

2026-10-18 确认 [9.5.5 任务数据与完成状态的可见性](<./4.experiments/CP_MEC 第一版规格.md#spec-task-visibility>)：沿用既定提交与收尾顺序，A57 运行时在输入准备完成后、Header 发布后及读到 Signal 完成后，分别执行带编译器内存约束的 `dmb sy`；RV64 CP 使用同样带编译器内存约束的 `fence iorw, iorw`，衔接有效 Header 与输入读取、配置与提交，以及结果确认与完成通知。QEMU 后端完成结果写回和相关访问后发布 `DONE`，跨线程交接使用锁或 release/acquire 同步；CP 保存结果、清理并确认后，依次发布 Signal、通知槽和 IH 通知，每次访问成功后才继续。Host 完整读到 Signal 为 `0` 并同步后读取或复制结果；上传或结果复制采用 DMA 时须等待成功完成。完整流程及依据见[规格 6.4 节](<./4.experiments/CP_MEC 第一版规格.md#spec-dispatch-visibility>)。本项为设计确认，屏障封装、后端同步及变更输入的多轮连续提交验证尚待实现；9.4.4 的首部访问、并发发布及预留使用约束也已确认。9.6.1～9.6.3 已确认；9.6.4、9.6.5 已转为后续扩展，9.7 的 Host 软件接口也已确认，功能尚待实现。

2026-10-18 确认 [规格 9.3.4](<./4.experiments/CP_MEC 第一版规格.md#spec-management-marker-rules>)：每个在途管理请求独占一个至少按 8 字节对齐的结果区，按 9.3.5 补齐为 16 字节，其中完成标记占 8 字节；驱动按请求分配，标记初值为 0，预期值为按设备分配、从 1 开始递增的 64 位无符号序号，不支持回绕复用。整个结果区的初始化先于命令发布，管理命令与 `WRITE_COMPLETION` 在对应的 KIQ Ring 或 HIQ Ring 中按逻辑顺序相邻；CP 先结束管理操作并暂存结果，再由完成命令先写结果码、后写标记。Host 带超时轮询，读到本次预期值后完成同步并检查结果。只有确认 CP 不会再写旧请求的结果区且 Host 已结束等待和结果处理，才可重新初始化并交给新序号请求使用；超时不得直接清零、释放或复用。完整图示与规则见[规格 4.3 节](<./4.experiments/CP_MEC 第一版规格.md#spec-management-marker>)。完整访问沿用 9.4.3，接入、屏障实现和验证仍待完成；管理失败及结果写回故障已按 9.3.5 确定。

2026-10-18 确认 [规格 9.3.5](<./4.experiments/CP_MEC 第一版规格.md#spec-management-failure>)：每个请求独占 16 字节小端结果区，至少按 8 字节对齐；偏移 0、8、12 分别保存 8 字节完成标记、4 字节结果码和 4 字节保留空间，初值依次为 `0`、`0xffff_ffff`、`0`。CP 按 KIQ、HIQ 分别暂存管理结果，后附 `WRITE_COMPLETION` 先写结果码并保证可见，再写完成序号，回报后清除暂存状态；命令仍为 32 字节。普通管理失败也回报，MQD 访问失败须能安全结束本次处理并继续回报。取包、已发布命令配对或结果写回出错时，记录来源管理队列错误并停止该 Ring；Host 可通过管理通道故障或超时退出等待，相关内存继续保留。结果码 `0～6`、完整布局及图示见[规格 4.4 节](<./4.experiments/CP_MEC 第一版规格.md#spec-management-result>)。9.3 各项已确认，固件、驱动与同步验证尚待实现；队列故障编号与停止范围已按 [9.6.1](<./4.experiments/CP_MEC 第一版规格.md#spec-queue-error-policy>)确定，强制恢复列入[后续异常恢复扩展](<./4.experiments/QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)，正常回收继续遵守已确认的对象寿命条件。

2026-10-18 确认 [9.6.1 中的 IH 方案](<./4.experiments/CP_MEC 第一版规格.md#spec-queue-error-notification>)：全设备共用一个 Host RAM IH Ring，默认 4 KiB，每条记录 32 字节；七个管理寄存器包含字节容量 `IH_SIZE`，CP 经 `IH_SUBMIT` 同步提交固件私有 VRAM 中的记录。记录保存类型、槽位、完整 MQD 地址和事件编号或错误值，W、R 使用 32 位记录编号；先写记录、再发布 W、最后中断通知 Host。`IH_STATUS` 分别保存首次通道故障和最近一次 CP 提交结果；IH 故障停止继续取包和调度，经已有 `IRQ_ERROR` 通知。Signal 更新后写通知槽，再提交 `SIGNAL_NOTIFY`，驱动按 MQD 地址找到队列所属进程，再按事件编号唤醒等待者。旧通知及驱动后续处理结束前，不复用 MQD 地址和事件编号。完整布局、寄存器和流程图见[规格 7.1 节](<./4.experiments/CP_MEC 第一版规格.md#spec-ih-notification>)。IH 部分已确认，功能尚待实现；寄存器地址偏移、IH 故障及非零提交结果枚举、复位字段清单接入前补齐。队列错误处理按下述同日确认的 9.6.1 规则执行。

同日确认 [9.6.1 的错误记录、停止范围与清理后重建](<./4.experiments/CP_MEC 第一版规格.md#spec-queue-error-policy>)：`CP_HQD_ERROR` 使用 32 位编号 `0～10`，由 CP 保留首次错误，Host 只读；队列首次进入故障时提交一次 `QUEUE_ERROR`。CP 清除故障队列的 `ACTIVE` 并保留异常占用和 MQD 绑定。用户队列故障只停本队列；HIQ 故障停止 HIQ，KIQ 和正常用户队列继续处理；KIQ 实际通道故障、固件代码或栈异常停止全部新取包和新派发。普通管理失败继续回报，MQD 保存失败能安全回报时返回 `status = 5` 并保留目标槽位，目标尚无错误时记编号 `10`。错误队列清理后重建，未绑定 MQD 的 `saved_error` 非零时映射返回 `status = 4`；槽位用于新队列时由 CP 初始化错误状态，CP 单独复位不清错。不自动重放任务或补写成功 Signal，已发生写入保留。9.6.1 主方案已确认、功能尚待实现；失败包的基本收尾按下述 9.6.2 执行，正常卸载按下述 9.6.3 执行，任务卡住后的强制停止和故障复位列入[后续异常恢复扩展](<./4.experiments/QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)。

2026-10-18 确认 [9.6.2 失败包与部分完成的收尾](<./4.experiments/CP_MEC 第一版规格.md#spec-failure-retirement-rules>)：第一版出错后停止正常收尾，不跳过失败包，不为丢弃它而清除 Header 或推进进度，不补写成功 Signal。已发生的数据、Signal 和进度更新保留，不回退，也不自动重放任务、重发管理命令或重试完成写入；普通管理失败仍按既定协议返回结果。驱动保存故障并唤醒相关等待者，以错误结束尚未完成的等待，资源保留到设备访问及旧通知处理结束。完整流程见[规格 7.3 节](<./4.experiments/CP_MEC 第一版规格.md#spec-failure-retirement>)；逐步故障分析、故障注入、自动重试和原地恢复列为[后续扩展](<./4.experiments/QEMU GPGPU 实验大纲.md#failure-recovery-extension>)，完整读写与发布顺序仍为第一版要求。本小节已确认，功能尚待实现；正常卸载见[9.6.3](<./4.experiments/CP_MEC 第一版规格.md#spec-unmap-rules>)。后续每次确认一个完整小节，先确定第一版必要行为，精细鲁棒性留作扩展。

2026-10-18 确认 [9.6.3 卸载时未消费的任务与 ACTIVE 清零](<./4.experiments/CP_MEC 第一版规格.md#spec-unmap-rules>)：正常卸载前，Host 停止新提交，等待已开始的提交完成发布，再等任务完成及消费回报 `R == W`，随后提交卸载。CP 开始卸载时将槽位标为卸载中，清除 `ACTIVE` 并关闭 Doorbell 使能；确认访问结束、成功保存 MQD 后才解除绑定并归还槽位。Host 确认管理结果成功，处理完旧通知并满足对象寿命条件后回收资源。故障队列清理不要求先排空，沿用 9.6.2 的错误退出规则。正常卸载 HIQ 前，由驱动停止新建用户队列，卸载全部用户队列，确认 HIQ 管理请求及后附完成命令全部处理结束，再经 KIQ 卸载 HIQ；CP 不自动连带卸载用户队列。完整流程见[规格 7.4 节](<./4.experiments/CP_MEC 第一版规格.md#spec-unmap-drain>)；取消未执行任务、保留未执行任务跨卸载续跑列为[后续扩展](<./4.experiments/QEMU GPGPU 实验大纲.md#queue-unmap-extension>)。本小节已确认，功能尚待实现；9.6.4、9.6.5 已转为后续扩展，9.7 的 Host 软件接口也已确认，功能尚待实现。

2026-10-18 调整第二阶段范围：[9.6.4](<./4.experiments/CP_MEC 第一版规格.md#spec-stalled-task-scope>) 中任务长时间不结束时的挂死判断、强制中止、局部复位、设备整体复位恢复及自动恢复，统一移到[后续异常恢复扩展](<./4.experiments/QEMU GPGPU 实验大纲.md#stalled-task-recovery-extension>)，不作为第二阶段必做或验收内容。[9.6.5](<./4.experiments/CP_MEC 第一版规格.md#spec-runtime-reset-scope>) 中运行期间 KIQ 重配、故障 HIQ 重建和复位后重新建立也随此扩展再细化。当前保留首次启动、正常提交与卸载，以及已确认的错误记录和等待退出规则；等待超时只结束本次等待，不自动复位或补写成功 Signal，尚不能确认设备访问结束时继续保留相关资源。Host 软件接口已按下述 9.7 确认，后续按第一版必要流程接入。

2026-10-18 统一确认[规格 9.7.1～9.7.4](<./4.experiments/CP_MEC 第一版规格.md#spec-host-api-scope>)：第二阶段向上实现到满足实验需要的 HSAKMT 风格用户态接口库，封装设备连接与查询、内存、队列和事件管理；ROCr/HSA 运行时、高层 Launch 和自动任务管理暂不设计。同进程共享连接和上下文，用户态返回 HSAKMT 风格状态；内存接口分别返回句柄、CPU 映射资料、Host 物理地址或 VRAM 偏移。调用方先申请 Ring、进度存储，再请求创建队列，驱动准备 MQD，由 CP 选择空闲槽位；正常销毁前由调用方排空。创建事件时登记源队列并返回事件编号、通知槽物理地址，队列故障时驱动据此使尚未完成的相关等待以失败结束；默认约 `200 μs` 主动检查和 Signal 复查仍由调用方执行。事件等待采用 32 位毫秒超时，`0` 为只检查状态，`UINT32_MAX` 为无调用方设定的上限。四组接口行为均已确认，功能尚待实现和验证；正式符号名、ioctl 编号、结构体布局与锁在接入时落实，沿用已有完整读写、可见性、对象寿命及异常恢复扩展边界。

工作组共享存储、组内屏障和可配置寄存器资源列为[后续扩展](<./4.experiments/QEMU GPGPU 实验大纲.md#compute-resource-extension>)。第一版沿用 RV32 执行器固定的线程寄存器，`ax+b` 的只读标量通过参数块传入，不增加 `COMPUTE_PGM_RSRC1/2` 或修改已确认的 64 字节 MQD。扩展时共同处理共享区域、访问边界、同步及 warp 调度，实施阶段随需求确定；概念与已有代码依据见[资源说明](<./4.experiments/CP_MEC 软件实现、参考与扩展.md#kernel-registers-lds>)。

学习进度按用户反馈记录；文档已写入、源码已核对、实验已运行验证和用户已掌握分别判断，不以文件存在替代学习或实验完成记录。
