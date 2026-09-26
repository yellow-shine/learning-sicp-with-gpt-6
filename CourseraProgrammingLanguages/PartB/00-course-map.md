# Programming Languages, Part B — 课程地图

University of Washington / Dan Grossman，Coursera *Programming Languages, Part B*。

这份笔记不是字幕摘要。它把 Part B 重写成一条连续的问题链：换一种语言之后，“程序”是什么、计算何时发生、语言本身如何被实现、类型系统到底保证什么。

读法：先读本文件建立地图，再按编号读各章。每章内部先给连续论证，再按视频补机制、代码和误区。跨章的公式、术语和对照表放在 `09`–`15`。

## 如何读标注

| 标记 | 含义 |
| --- | --- |
| **【课程】** | 字幕里讲师明确讲过的结论、例子或设计选择 |
| **【讲解】** | 为把课程内容连成机制所做的重组，不增加讲师没下的结论 |
| **【扩展】** | 课程没有正式展开、但有助于定位的背景。不能当成考试范围 |

字幕有断句和识别错误。明显错误已按上下文改正，并在该处标注 `[字幕可能有误]`。配套代码若字幕没逐字给出，示例按讲师描述的语义重建，并标明。

---

## Part B 在整门课里的位置

**【课程】** Part B 不是另一门语法课，而是 Part A 的续集。Part A 用 ML 建立了函数式程序的基本语义：函数、递归、环境（Environment）、元组与列表、模式匹配与 datatype、一等函数与闭包（Closure）、类型推导、模块，以及“两个表达式何时等价”。Part B 把这些想法搬到 Racket，然后讲三件新事：

1. 延迟求值（Delayed Evaluation）以及由此得到的 stream、memoization。
2. 自己实现一门有一等函数的小语言。
3. ML 与 Racket 最大的差别：静态类型 vs 动态类型。比较时只列可以争辩的事实，不下“哪个更好”的判决。

**【课程】** 结构（相对 Part A 的编号，Section 5 起）：

| 周次 | 材料 | 考核 | 笔记 |
| --- | --- | --- | --- |
| Week 1 | Section 5：Racket、延迟求值、streams、macros | Homework 4。macros 大部分可选，不考进作业，除非挑战题 | `01`–`04` |
| Week 2 | Section 6：datatype 的动态语言写法、解释器、环境、闭包 | Homework 5。很多人认为是全课最难、也最有收获的作业。语言名叫 MUPL（Made Up Programming Language） | `05`–`07` |
| Week 3 | Section 7：静态检查、soundness / completeness、weak typing、静态 vs 动态 | 只考本节的 quiz，大约占总分 10%。不是 Part A 那种累计考试 | `08` |
| Part C 末 | 会回头比较 Part B | Part B 本身没有累计考试 | wrap-up 在 `08` 末、`15` |

**【课程】** Week 2 和 Week 3 的视频曾经合在一起，后来才拆开，所以这两周视频比 Part A 的一周少。工作量被 Homework 5 补上。

**【课程】** 软件：DrRacket，不沿用 Part A 的 Emacs。安装应能很快完成，不单独占一周。

---

## 三条主线，一句话版本

### 主线 A：换语言，不是换语法

**【讲解】** ML 里，程序在跑之前就被类型系统切掉一大片。Racket 接受更多程序，把 ML 里的 type error 推迟到某次求值真正走到那个表达式。括号不是装饰，而是把源码几乎直接写成语法树。于是“程序”从“一段会被类型检查的文本”变成“一棵马上可以解释的树，树上的值带着运行时标签”。

### 主线 B：求值时机是语言设计的旋钮

**【课程】** 函数体在调用前不求值。零参数函数因此不是无用的：它把“现在算”变成“以后算，或永远不算”。Thunk、promise、stream、memoization、macro，都是在控制**何时、多少次**求值。

### 主线 C：解释器把 Part A 的语义变成数据

**【课程】** 解释器就是 `eval(表达式, 环境) → 值`。变量查找、`let` 扩展环境、函数值必须携带定义时环境，都不再是口头语义，而是你必须写对的代码。闭包从“使用者心里的一对东西”变成“实现者构造出来的 struct”。

---

## 问题链（预览，完整版见 `13-problem-chain.md`）

```text
Part A 的函数、环境、闭包、datatype、类型推导，换一种语言还在吗？
        ↓
Racket：同样的抽象，不同的语法，没有静态类型系统
        ↓
括号为什么这么多？它在表示什么树？
        ↓
没有类型检查器，数据怎么混放？错误何时出现？
        ↓
绑定可以事后改吗？set! 改的是变量还是 cons cell？
        ↓
计算必须现在做吗？
        ↓
Thunk → Promise（delay/force）→ Stream → Memoization
        ↓
函数改不了“参数先求值”，谁能改语法？
        ↓
Macro：展开发生在一切求值之前；hygiene 让变量不串味
        ↓
没有 ML datatype，递归数据怎么表示？
        ↓
带标签的 list → struct（新的一种数据，不是 list 的语法糖）
        ↓
一门语言如何被另一门语言执行？
        ↓
跳过 parser：用宿主语言的构造器直接写 AST
        ↓
解释器可以假设语法合法，不能假设递归结果的值种类合法
        ↓
变量的值在环境里。函数值必须记住定义时的环境
        ↓
Closure = 代码 + 定义时环境
        ↓
静态检查到底拒绝什么？Sound 与 complete 为什么不能兼得？
        ↓
Weak typing 不是 dynamic typing
        ↓
静态 vs 动态是工程权衡，不是信仰
```

---

## 概念依赖（预览，完整版见 `15`）

```text
Part A: 环境、词法作用域、闭包（作为使用者）
        │
        ▼
Racket 的 define / let / let* / letrec     动态类型与运行时标签
        │                                      │
        ▼                                      ▼
set! 改变绑定的当前内容                    用 list / struct 手写 datatype
        │                                      │
        ▼                                      ▼
Thunk（零参数函数，推迟求值）              AST = struct 树
        │                                      │
        ├── delay/force（promise，最多算一次）  ▼
        ├── Stream（无限序列的有限表示）     eval(expr, env) → value
        └── Memoization（按参数缓存）            │
                                                 ▼
Macro：语法 → 语法，先于求值              Closure(代码, 定义环境)
        │                                      │
        └──────────────┬───────────────────────┘
                       ▼
              宿主语言函数可充当对象语言的 macro
                       │
                       ▼
              Soundness / Completeness / Weak typing
                       │
                       ▼
              静态检查 vs 动态检查的七组对照
```

---

## 文件索引

| 文件 | 内容 | 对应视频 |
| --- | --- | --- |
| `00-course-map.md` | 地图、导论三讲、阅读顺序 | Welcome, Overview, Structure |
| `01-section-5-racket.md` | 从 ML 到 Racket 的编程模型 | S5 01–12 |
| `02-section-5-delayed-evaluation.md` | Thunk、delay/force | S5 13–15 |
| `03-section-5-streams-memoization.md` | Stream、memoization | S5 16–18 |
| `04-section-5-macros.md` | Macro、hygiene；Section 5 总总结 | S5 19–23 |
| `05-section-6-datatypes.md` | 无 struct / 有 struct 的 datatype | S6 01–03 |
| `06-section-6-interpreter.md` | 语言实现、AST、解释器能假设什么 | S6 04–05 |
| `07-section-6-environments-closures.md` | 环境、闭包、效率、宿主函数当 macro | S6 06–09 |
| `08-section-7-static-vs-dynamic.md` | 类型争论的精确版本；Part B wrap-up | S7 01–07, wrap-up |
| `09-interpreter-cheatsheet.md` | 解释器公式 | 综合 |
| `10-evaluation-strategy-cheatsheet.md` | 求值策略对照 | 综合 |
| `11-pl-concept-dictionary.md` | 术语：定义 + 直觉 + 最小例子 | 综合 |
| `12-language-comparison.md` | ML / Racket / 其他语言 | 综合；现代语言多为扩展 |
| `13-problem-chain.md` | 整门 Part B 的问题链 | 综合 |
| `14-study-questions.md` | 检查题汇编 | 综合 |
| `15-final-mental-model.md` | 不再按视频顺序的心智模型 | 综合 |

建议阅读顺序就是文件编号。时间紧：`00` → `02` → `06` → `07` → `08` → `09` → `15`。这五块是 Part B 相对 Part A 的增量。

---

## 导论三讲

这三讲不教 Racket。它们规定后面每一讲在回答哪一个问题。

### Welcome to Part B

#### 1. 这节要解决什么问题？

确认这是 Part A 的续集，以及后面三周真正要学的不是“再学一门函数式语言的语法”。

#### 2. 为什么值得解决？

**【课程】** 学编程语言需要耐心和开放：要接受新的程序观。语言只是载体。若没看过 Part A，后面的环境、闭包、datatype 会缺少前提。

#### 3. 核心概念

- 概念迁移：ML 里的想法可以在语法很不同的语言里重现。
- 新概念优先于重放：Part B 的主体是延迟求值、语言实现、静态/动态类型。
- 课程看起来更短，是因为安装周被拿掉了，不是因为材料变轻。

#### 4. 逐步机制

无新机制。讲师点名三块：delaying evaluation（第一周）、implementing your own programming language、ML 与 Racket 最大差别是静态类型还是动态类型。

#### 5. 代码

无。

#### 6. 执行过程

无。

#### 7. Programming Languages 视角

> 更换语言是为了看见哪些想法与具体语法无关，哪些想法才是新的。

#### 8. 常见误区

“Part B = 用另一种语法把 Part A 再做一遍。”导论明确否定这一点。

#### 9. 与前面内容的联系

前提是 Part A 的函数式基础。Racket 仍是 mostly functional，所以那些基础会继续能用。

#### 10. 一句话总结

Part B 用 Racket 承载三件新事：推迟求值、实现语言、比较类型纪律。

---

### Overview of Part B Concepts

#### 1. 这节要解决什么问题？

在术语还不熟悉时，先给出各块如何咬合，避免后面把 macro、stream、解释器当成互不相关的技巧。

#### 2. 为什么值得解决？

**【课程】** 这些材料无法简短讲清，但需要一条期待：每一块都在补上一块留下的洞。

#### 3. 核心概念

- 动态类型：没有类型系统、没有类型推导；ML 会拒绝的程序可以先跑。
- 零参数函数：函数体直到调用才求值。这是高级惯用法的杠杆。
- Stream：表现得像无限大的数据结构。
- Macro：程序员扩展语法，而不改语言实现。
- 动态语言里 ML 式 datatype “不太说得通”，但有类似物，然后用它实现语言。
- 程序表示：不是字符序列，而是树。
- 闭包会被实现出来。作业语言强到可以自己写 `map` / `filter`。
- Soundness、completeness，以及为何通常不能两者兼得。

#### 4. 逐步机制

**【课程】** 顺序是故意的：

```text
用动态类型重做 ML 已会的东西（快）
    → 延迟求值 / streams（作业重点）
    → macro 的基本想法（大多可选，但下一节要用）
    → Racket 里的 “datatype”
    → 解释器，直到闭包
    → 退一步比较静态类型与动态类型
```

Macro 放在这里有两个理由：Racket 的 macro 系统设计得好；下一节需要“扩展语法”这个想法。

#### 5. 代码

无。导论只点名，不给实现。

#### 6. 执行过程

无。

#### 7. Programming Languages 视角

讲师拒绝在静态/动态之间站队。他要的是不可争辩的事实，权重由你在具体项目里自己加。

#### 8. 常见误区

把导论里的 jargon 当成已经定义过的术语。这些词要到后面的讲才有精确定义。

#### 9. 与前面内容的联系

Part A 的清单被明确重述：函数、递归、环境、元组、列表、模式匹配、datatype、一等函数、闭包、类型推导、模块、表达式等价。Part B 的升级是把其中几件从“会用”变成“会实现 / 会比较”。

#### 10. 一句话总结

先在无类型检查的语言里重做函数式程序，再用函数推迟计算，然后实现一门有闭包的语言，最后才有资格争论类型。

---

### Part B Course Structure

#### 1. 这节要解决什么问题？

知道每一周的考核形状，从而知道哪些视频是作业关键路径，哪些是可选加深。

#### 2. 为什么值得解决？

可选 macro 讲与 Homework 5 的难度分布，决定你该把时间花在哪里。

#### 3. 核心概念

- Homework 4、Homework 5：风格同 Part A 的编程作业，含 peer assessment。
- Section 7 用 quiz 代替编程作业，因为材料是概念性的。
- Quiz 只覆盖 Section 7，不累计复习 Part B 全部。
- Part C 末的考试会比较 Part C 与 Part B。字幕里有一处口误，先说 “end of Part B” 再更正为 Part C。

#### 4. 逐步机制

无新语言机制。结构本身是课程设计：概念周不适合编程作业，所以改成小比重测验。

#### 5. 代码

无。

#### 6. 执行过程

无。

#### 7. Programming Languages 视角

有些 PL 问题（soundness、权衡）不适合用“再写一个函数”来巩固。考核形式跟着问题的性质走。

#### 8. 常见误区

把 Week 3 视频少理解成材料不重要。讲师的原话是 Week 3 是回头比较，Week 2 的难度在作业里。

#### 9. 与前面内容的联系

Part A 有三份编程作业加一次累计考试。Part B 是两份编程作业加一次分节 quiz。

#### 10. 一句话总结

Part B 的成绩来自两份作业和一次只考类型比较的 quiz；真正的综合留到 Part C。

---

## 读每一章时要追问的五句话

Dan Grossman 把一个概念放在这里，通常是因为前面刚留下一个具体的做不到：

1. 没有这个机制，哪一种程序写不出来，或哪一种推理会失效？
2. 它改变的是语法、求值时机、绑定，还是值的表示？
3. 它在宿主语言 Racket 里，还是在被解释的语言里？
4. 它把哪一类错误从运行前挪到运行时，或反过来？
5. 它和 Part A 的哪一条语义是同一件事的另一种说法？

下一章从第一个具体问题开始：如果类型检查器不再挡路，列表、函数和括号还剩下什么？
