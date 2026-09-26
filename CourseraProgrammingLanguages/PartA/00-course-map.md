# Programming Languages — 课程地图与问题链

> Dan Grossman, University of Washington / Coursera
> Part A（Standard ML）· Part B（Racket）· Part C（Ruby）
>
> 这不是三门语法课。三门语言只是三把尺子，用来量同一组语言机制在不同设计选择下长什么样。

正文从 [README.md](README.md) 进入。地图回答“为什么是这个顺序”。各章回答“这一环的机制是什么”。

学完这套笔记应能回答：

> 不同编程语言看似语法不同，它们背后实际上由哪些共同的语言机制组成？这些机制为什么存在？它们分别解决什么程序设计问题？不同语言为什么会做出不同设计选择？

Grossman 自己的框架是一张 2×2 的表，本课占了三格，第四格留给你已经见过或即将见到的 Java / C#：

|  | 函数式（Functional） | 面向对象（Object-oriented） |
|---|---|---|
| 静态类型（Static typing） | **SML**（Part A） | Java / C# / Scala 的 OOP 部分（课内对照，不作为主语言） |
| 动态类型（Dynamic typing） | **Racket**（Part B） | **Ruby**（Part C） |

函数式 vs 面向对象，和静态类型 vs 动态类型，是两条正交的轴。把它们缠在一门语言里学，会分不清“这是类型系统的选择”还是“这是程序分解方式的选择”。

课程故意不用“更现代、库更全”的语言来讲这些概念。SML 像一辆可以打开引擎盖的旧车：构造少、组合强、语义能写清楚。流行不等于本质；语法是车座的颜色，不是引擎。

---

## 怎么用这套笔记

按问题链读，不要按视频编号背。每一章都走同一条推理：

```text
Problem → Idea → Mechanism → Example → Trade-off → Connection
```

遇到一个语言特性，用同一套透镜，避免笔记退化成语法卡片：

| 透镜 | 问什么 |
|---|---|
| Syntax | 怎么写？ |
| Semantics | 它是什么意思？ |
| Binding | 名字如何绑定到什么？ |
| Scope | 名字在哪里可见？按哪条规则查找？ |
| Evaluation | 什么时候算？算到什么值？ |
| Type | 哪些用法在运行前就被拒绝？ |
| Lifetime | 值比谁活得久？ |
| Mutation | 状态能不能改？改的是绑定还是盒子里的内容？ |
| Abstraction | 它隐藏了什么实现决定？ |
| Composition | 它如何和其他机制拼成更大的程序？ |

专有名词第一次出现保留英文，之后用英文简称。代码保持 SML / Racket / Ruby，不改写成 Python。

---

## 一、知识地图

下面的树按**问题结构**重组，不按视频播放顺序。括号里是它在课上第一次被正经处理的位置。

```text
Programming Languages
│
├── 0. 为什么学语言概念，而不是学一门语言
│     （Intro；Section 3 之后的 Course Motivation；Part C wrap-up）
│
├── 1. Language Foundations — 一个程序由什么构成
│   ├── Syntax / Semantics / Typing rules     （S1: pieces of a language）
│   ├── Expressions 与 Values                 （S1）
│   ├── Environments 与 Bindings              （S1）
│   ├── Shadowing ≠ Mutation                  （S1）
│   └── REPL、静态错误、动态错误               （S1）
│
├── 2. Computation without assignment
│   ├── Functions：语法、求值、类型            （S1）
│   ├── Recursion 是默认的重复                 （S1–S2）
│   ├── Tuples / Lists                        （S1）
│   ├── Let：局部绑定，也是避免重复计算        （S1）
│   ├── Options：用类型表达“可能没有”          （S1–S2）
│   └── Immutability 与 local reasoning       （S1；S4 等价；S10 depth subtyping）
│
├── 3. One-of Data 与按情形编程
│   ├── Records = each-of，带名字             （S2）
│   ├── Datatypes = one-of                    （S2）
│   ├── Pattern matching / case               （S2）
│   ├── 递归数据类型（列表、树、表达式）        （S2）
│   ├── Polymorphic datatypes 与 equality types（S2）
│   ├── Exceptions：另一种控制与另一种 one-of  （S2）
│   └── Tail recursion：递归的空间语义         （S2）
│
├── 4. Functions as Values
│   ├── First-class functions                 （S3）
│   ├── Higher-order functions：map/filter/fold（S3）
│   ├── Anonymous functions 与 unnecessary wrapping（S3）
│   ├── Lexical scope vs Dynamic scope        （S3）
│   ├── Closures = code + environment         （S3；S6 实现）
│   ├── Currying vs Partial application       （S3）
│   ├── Mutation via references（受控的盒子）   （S3）
│   ├── Callbacks                             （S3）
│   └── ADT with closures                     （S3）
│
├── 5. Types as a static discipline
│   ├── 每个构造都有 typing rule               （S1 起，S4 系统化）
│   ├── Type inference ≠ 没有类型系统          （S2 初见，S4）
│   ├── Parametric polymorphism / type variables（S2–S4）
│   ├── Value restriction                     （S4）
│   └── Mutual recursion 与类型                （S4）
│
├── 6. Abstraction boundaries
│   ├── Modules as namespaces                 （S4）
│   ├── Signatures = abstraction boundary     （S4）
│   ├── Abstract types / representation hiding（S4）
│   ├── Signature matching                    （S4）
│   └── Equivalence：客户观察不到的实现替换    （S4；依赖 immutability）
│
├── 7. The same ideas, without a type system
│   ├── Racket：动态类型下重做函数、列表、闭包  （S5）
│   ├── Parentheses = 没有歧义的树             （S5）
│   ├── cons 不可变 vs mcons 可变              （S5）
│   ├── Delayed evaluation：thunk / delay / force（S5）
│   ├── Streams：看起来无限的数据结构          （S5）
│   ├── Memoization                           （S5）
│   └── Macros：扩展语法，而不是扩展库         （S5；S6 用来定义被解释语言）
│
├── 8. What a language implementation is
│   ├── 程序是树，不是文本                     （S6）
│   ├── Datatype programming in Racket / structs（S6）
│   ├── Interpreter = recursive eval          （S6）
│   ├── Environments 的具体表示                （S6）
│   └── Closures 的具体表示                    （S6）
│
├── 9. Static checking as a design choice
│   ├── Static checking 的定义                 （S7）
│   ├── Soundness vs Completeness             （S7）
│   ├── Weak typing                           （S7）
│   ├── Static vs Dynamic 的可争论事实         （S7）
│   └── eval / quote：把数据当程序             （S7）
│
├── 10. Objects as another packaging of state + behavior
│   ├── Class / Object / Method               （S8）
│   ├── Object state 与 visibility            （S8）
│   ├── Everything is an object               （S8）
│   ├── Duck typing                           （S8）
│   ├── Blocks / Procs ≈ closures             （S8）
│   ├── Subclassing / Overriding              （S8）
│   ├── Dynamic dispatch 与 method lookup     （S8）
│   └── Dynamic dispatch vs Closure lookup    （S8；可选：用 Racket 手写 dispatch）
│
├── 11. Two decompositions of the same problem
│   ├── Functional decomposition vs OOP decomposition（S9）
│   ├── Expression problem：加操作 vs 加变体   （S9）
│   ├── Binary methods                        （S9）
│   ├── Double dispatch / Multimethods        （S9）
│   ├── Multiple inheritance vs Mixins        （S9）
│   └── Interfaces / Abstract methods         （S9）
│
└── 12. Subtyping is not generics
    ├── Subtype relation                      （S10）
    ├── Depth subtyping 与 mutation           （S10）
    ├── Function subtyping：参数逆变、结果协变（S10）
    ├── Subtyping for OOP                     （S10）
    ├── Generics vs Subtyping                 （S10）
    └── Bounded polymorphism                  （S10）
```

这棵树有一个 Grossman 反复强调的收束：语言不大。ML、Racket、Ruby 各自只有一小撮构造。软件的多样性来自这些构造的组合，不来自构造的数量。

---

## 每个一级主题为什么在这里

### 0. 课程动机（不是第一周就讲透）

1. **解决什么问题：** 防止把课听成“又学一门冷门语法”。要建立的是：语义（semantics）决定程序到底做什么；惯用法（idioms）决定你能不能把常见任务写得短、对、可迁移。
2. **为什么不放在第 1 讲：** 没有共享术语时，动机只是一堆空词。Grossman 把完整动机放到 Section 3 之后：你已经写过没有赋值的递归，也见过 closure，才听得懂“函数式语言常常超前几十年，然后想法被主流语言吸收”。
3. **依赖：** 无。但要听懂，需要 Section 1–3。
4. **准备：** 后面所有“这不是语法差异”的对照。也解释了语言选择：SML 的多态、模式匹配、module；Racket 的动态类型、宏、`eval`、括号即树；Ruby 的纯 OOP、mixin、完整 closure。Haskell 的惰性会打乱他要教的求值规则，所以不选。Prolog 是另一行（逻辑编程），课上没时间。

### 1. Language Foundations

1. **解决什么问题：** 如果你不能把“这段代码是什么意思”拆成语法、求值规则、类型规则，你就只能靠试 REPL。试出来的不是语义。
2. **为什么在这里引入：** 一切后续机制都是新的构造，每个构造都要能回答：怎么写、怎么算、什么类型合法。先在加法、变量、函数上把这三件套练熟。
3. **依赖：** 已有编程经验（循环、数组、方法）。不依赖 OOP。
4. **准备：** 函数的形式语义、`let` 的环境、后来 interpreter 里的 `eval` 就是这些规则的可执行版本。

### 2. Computation without assignment

1. **解决什么问题：** 命令式默认模型是“盒子里的内容会变”。一旦有 alias，局部推理失败：你看见一个名字，不知道别处是不是正在改同一个盒子。
2. **为什么在这里引入：** 先拿走 mutation，强制用递归、不可变列表、`let` 绑定来写你本来用循环和赋值写的东西。肌肉记忆先于理论。
3. **依赖：** 绑定、表达式、环境。
4. **准备：** 为什么 lexical scope 下 closure 捕获的是绑定而不是“以后会被改掉的盒子”；为什么不可变时两个函数更容易证明等价；为什么不可变时 depth subtyping 是安全的。

### 3. One-of Data 与 pattern matching

1. **解决什么问题：** 元组是 each-of（同时有这几块）。真实数据经常是 one-of（是这种或那种，不能同时是）。用 `int` 编码“形状”、用 `null` 编码“没有”，都会把不变量从类型里漏掉。
2. **为什么在 Section 2：** Section 1 的 list 和 option 已经是 one-of，但你还不知道它们是 datatype 的特例。先用，再揭示一般机制，然后用同一机制定义表达式、树、异常。
3. **依赖：** 元组、列表、递归、类型。
4. **准备：** 函数式分解（按 variant 分 case，每个函数是一种操作）；interpreter 的 AST 就是 datatype；expression problem 的一边。

### 4. Functions as Values

1. **解决什么问题：** 如果函数不能当参数、返回值、绑定、数据结构元素，那么 map / filter / callback / “把比较器传进去”都得靠复制代码或靠语言内置特殊形式。
2. **为什么在 Section 3，而不是 Section 1：** 你需要先会写一等的递归函数，才看得出“把函数本身传进去”是抽象，而不是语法糖。
3. **依赖：** 函数、嵌套函数、环境、不可变绑定。
4. **准备：** closure 是 lexical scope 的实现义务；currying、callback、用 closure 做 ADT；Section 6 要你自己实现 closure；Ruby 的 block 是几乎同一个想法。

### 5. Types as a static discipline

1. **解决什么问题：** 有些错误不该等到某条路径跑到才出现。类型系统是一套在运行前拒绝程序的规则。
2. **为什么类型推断单独成章：** 前面你几乎没写类型，容易误以为 ML 是动态类型。必须把“要不要写类型”和“有没有类型规则”拆开。
3. **依赖：** 每个构造的 typing rule，多态类型（`'a`），函数类型。
4. **准备：** Section 7 的 soundness / completeness；Section 10 的 generics vs subtyping。推断算法本身不是重点，重点是：推断出来的仍是静态类型。

### 6. Abstraction boundaries

1. **解决什么问题：** 名字空间只解决“名字撞车”。它不解决“客户依赖了你没承诺的表示”。一旦客户摸到表示，你就再也换不了实现。
2. **为什么放在 Part A 末尾：** 需要类型（signature 里写类型）、需要函数与 datatype（实现）、需要“等价”这个概念（客户观察不到的差异）。
3. **依赖：** 类型、datatype、函数、不可变（等价在有副作用时脆得多）。
4. **准备：** 概念类比（不是等价）：C++ header / public API、Java interface、Rust trait / module、Go interface。Ruby 的 mixin 和 ML 的 signature 解决的是不同问题，不要混。

### 7. 同一批想法，没有类型系统

1. **解决什么问题：** 如果你只在 ML 里见过 closure 和 list，你会把“有类型”和“函数式”焊死。Racket 把类型系统拿掉，想法还在。
2. **为什么 Part B 才引入：** Part A 先把静态函数式建完整，否则动态类型的自由会被误读成“更简单的 ML”，而不是一项独立设计。
3. **依赖：** 函数、列表、闭包、递归、环境。
4. **准备：** thunk 是“函数体延迟到调用才求值”的极端用法（零参数）；stream；宏（语法扩展）；然后才有资格谈静态 vs 动态。

### 8. 语言实现

1. **解决什么问题：** “closure 是什么”如果只停留在使用，仍然像魔法。实现一次：环境是数据结构，closure 是一对（代码，环境），函数调用是扩展环境再求值函数体。
2. **为什么在动态类型语言里做：** interpreter 要表示“任意表达式”，用 Racket 的 struct / 列表比在 ML 里再套一层类型更聚焦在语义上。作业仍是函数式的。
3. **依赖：** datatype 思维、环境模型、closure 的使用、Racket。
4. **准备：** Part C 用另一个 interpreter（几何语言）对比函数式分解与 OOP 分解。也准备“程序是树不是文本”。

### 9. Static vs Dynamic

1. **解决什么问题：** 阵营口号解决不了设计选择。需要一组不会因口味改变的事实：静态检查防止什么、漏掉什么、为什么 sound 与 complete 不能兼得、weak typing 是另一件事。
2. **为什么不在 Section 5 一开始就辩：** 先用动态类型写程序，再对照，否则争论没有经验。
3. **依赖：** ML 的类型系统与 Racket 的运行时失败。
4. **准备：** Part C 末尾回到静态类型，讨论 OOP 若要静态类型，需要 subtyping，而这和 ML 的 parametric polymorphism 不是同一个东西。

### 10. Objects

1. **解决什么问题：** 函数式把操作写在数据外面。另一套打包方式是：数据带着自己的操作，调用时才决定跑哪段代码。
2. **为什么放到最后：** 没有 closure、没有环境模型、没有“实现一种机制来理解它”，dynamic dispatch 看起来只是 `obj.method()` 的语法。有了前面的工具，才能说清 method lookup 比 closure 的变量查找更绕，以及哪些 OOP 能力可以用 closure + 记录模拟。
3. **依赖：** 环境、closure、抽象边界、动态类型。
4. **准备：** 两种分解、double dispatch、subtyping。

### 11. 两种分解

1. **解决什么问题：** expression problem。加一种操作，函数式（按操作组织、对 variant 做 case）容易；加一种数据变体，OOP（按变体组织、对操作做方法）容易。二者相反，所以其实是同一结构的两种投影。
2. **为什么在 Ruby 基础之后：** 需要方法、动态派发、subclassing，也需要你还记得 ML 的 datatype + case。
3. **依赖：** datatype / pattern matching，dynamic dispatch。
4. **准备：** binary method 在 OOP 里别扭，引出 double dispatch；mixin 是另一条复用轴，不是 subtyping 的替代品。

### 12. Subtyping vs Generics

1. **解决什么问题：** “这个值可以用在期望那个类型的地方”有两种完全不同的理由。一种是“它是更具体的一种”（subtyping）。一种是“它对所有类型都一样”（parametric polymorphism / generics）。用错一种，要么不安全，要么表达不了你的不变量。
2. **为什么在最后：** 需要 OOP 的 subclassing 作为 subtype 的直觉来源，也需要 ML 的 `'a` 作为 generics 的参照，还需要 mutation 的教训来理解 depth subtyping 何时 unsound。
3. **依赖：** 类型、多态、对象、继承、mutation。
4. **准备：** 看 Java / C# / Scala / Rust / Go 的类型系统时，先问“这里是 subtype 还是 type parameter”，再问“有没有把可变性算进去”。

---

## 二、Course Problem Chain

每一步都是一个真实问题。下一步由前一步逼出来。标注的是课上把这个问题变成机制的位置，不是这个词第一次被提到的位置。

```text
程序是什么？
  一段文本，还是一组有意义的构造？
  → Syntax。文本只是写法。
  → 每个构造有三件套：syntax、evaluation rules、typing rules。
  Lecture: Part A §1 “Pieces of a Language”；Part C wrap-up 再次收束。
  为什么在这里：后面每加一个构造，都用同一套三件套，避免“这个关键字大概是这个意思”。

表达式如何变成值？
  → 求值（evaluation）在一个环境（environment）里进行。
  → 值（value）是求值的终点，表达式不是值。
  Lecture: §1 ML Variable Bindings and Expressions；Rules for Expressions。
  为什么接着讲：没有环境和值，函数调用无法定义。

名字绑定意味着什么？
  → binding 把名字固定到一个值（或以后才会求值的表达式，视构造而定）。
  → shadowing 是新绑定遮住旧绑定，不是把旧盒子改写。
  → assignment 才是改盒子里的内容。ML 的 val 不是 assignment。
  Lecture: §1 Shadowing；Benefits of No Mutation；optional Java mutation。
  为什么接着讲：如果你把 val 理解成可变变量，后面的 closure 和等价都会错。

函数到底是什么？
  → 不是“对象上的方法”。是一个构造：参数、函数体、调用时扩展环境。
  → 递归函数的环境里必须能找到它自己。
  Lecture: §1 Functions Informally / Formally；Nested Functions。
  为什么接着讲：函数先作为“被调用的计算”建立，才能升级成“被传递的值”。

数据如何不靠赋值长大？
  → tuple 是 each-of。list 是递归的 one-of（空或 cons）。
  → option 把“没有”变成值，而不是 null 加上一个靠约定维护的检查。
  → 没有 mutation 时，alias 无害：共享结构不会被别人改掉。
  Lecture: §1 Pairs, Lists, Options, Benefits of No Mutation。
  为什么接着讲：list/option 用起来像内置类型，下一步要问它们是不是更一般机制的特例。

如何表达“是这种或那种”？
  → datatype + constructor。
  → case / pattern matching 同时做分支、解构、穷尽性检查。
  → 布尔本身就是两个构造子的 syntactic sugar。这是 Grossman 称为“深的事实”的那种观察。
  Lecture: §2 Datatype Bindings, Case, Lists and Options are Datatypes。
  为什么接着讲：一旦能定义表达式的 datatype，函数就变成“对 variant 的递归遍历”。这是函数式分解的原型。

递归会不会把栈撑爆？
  → 尾调用（tail position）可以复用栈帧。
  → accumulator 是把“还没做完的工作”从栈搬进参数。
  Lecture: §2 Tail Recursion, Accumulators。
  为什么在 datatype 之后：你已经在写递归遍历，效率问题才是真问题，不是预习。

函数能否像普通值一样传递？
  → first-class：作参数、作返回值、作绑定、放进数据结构。
  → 这立刻产生多态函数类型：`('a -> 'b) -> 'a list -> 'b list`。
  → map / filter / fold 不是库魔法，是“计算模式”被抽象成函数。
  Lecture: §3 First-class Functions, Functions as Arguments, Map and Filter, Fold。
  为什么接着讲：函数一旦作为值返回，自由变量的查找时间就变成问题。

如果函数引用外部变量，调用时去哪里找？
  → 自由变量（free variable）不在函数参数里。
  → lexical scope：在函数被定义的环境里找。
  → dynamic scope：在函数被调用的环境里找。
  → 现代语言几乎都选 lexical：含义不依赖“谁调用了我”，局部可推理，可做类型检查。
  Lecture: §3 Lexical Scope；Why Lexical Scope。
  为什么接着讲：lexical scope + “函数值比定义它的那次调用活得更久”无法用调用栈实现。

x 已经离开调用栈，为什么 g 4 还能看到 x = 3？
  fun f x = fn y => x + y
  val g = f 3
  g 4
  → closure = function code + lexical environment（定义时捕获的绑定）。
  → 捕获的是绑定，生命周期被延长到 closure 还被使用。
  Lecture: §3 Closures and Recomputation；§6 Implementing Closures（把同一想法做成数据结构）。
  为什么课程把“使用”和“实现”拆开：Part A 先获得闭包能做什么的经验，Part B 再去掉魔法。

closure 能做什么？
  → 避免重复计算（把已经算好的值关进闭包）。
  → 组合函数。
  → currying：`int -> int -> int` 不是 `int * int -> int` 的另一种拼写。
  → partial application：先吃掉一部分参数，返回等待其余参数的函数。
  → callback：把“以后要调用的行为”当值传出去。
  → 用闭包隐藏状态，做出抽象数据类型（不靠 module）。
  Lecture: §3 Closure Idioms, Currying, Partial Application, Callbacks, ADTs with Closures。
  为什么接着讲：这些惯用法都依赖“环境被打包带走”。没有闭包，它们会退化成显式传递环境（课上用 Java / C 对照过）。

如果偶尔真的需要状态呢？
  → 不要把所有绑定都变回可变变量。
  → reference 是一个显式的盒子：`ref` 创建，`!` 读取，`:=` 写入。
  → 可变性变成类型的一部分（`int ref`），而不是所有名字的默认。
  Lecture: §3 Mutable References。
  为什么放在闭包之后：闭包捕获 ref 时，捕获的是盒子，盒子里的内容仍可变。这是 shadowing 与 mutation 最容易混的地方。

如何在不写类型的情况下仍有类型规则？
  → 类型推断（type inference）从使用方式约束类型变量，再算出最一般的类型。
  → 你不写类型 ≠ 编译器不检查类型。
  → value restriction：有副作用时，不能把“还没确定的多态类型”随便推广，否则类型系统会 unsound。
  Lecture: §2 A Little Type Inference（预告）；§4 ML Type Inference, Polymorphic Examples, Value Restriction。
  为什么不和“动态类型”放在一起讲：推断是静态检查的一种实现方式。动态类型是“运行之前不拒绝”。

如何保证客户不会乱用表示？
  → module 可以只是名字空间。
  → signature 不是“函数声明列表”。它是客户被允许看见的全部。
  → 抽象类型（abstract type）让表示在 signature 之外不可见。于是两种实现可以等价：客户无法观察差异。
  → 有副作用时，等价脆弱得多（打印、发散、修改引用都能被观察到）。
  Lecture: §4 Modules, Signatures, Signature Matching, Equivalent Structures, Equivalence vs Performance。
  为什么在类型推断之后：signature 里的类型可以比实现更具体（少一点多态），匹配规则需要你已经理解类型。

把类型系统拿掉，哪些想法还在？
  → Racket：列表、闭包、词法作用域都在；错误从“编译拒绝”变成“某次求值时契约失败”。
  → 括号不是风格问题。括号把程序写成没有歧义的树。XML 的尖括号是同一个想法，Lisp 从 1958 年就有。
  Lecture: §5 Racket intro, Dynamic Typing, Syntax and Parentheses。
  为什么现在才换语言：你已经有静态版本可对照，不会把动态类型误认为“ML 还没讲类型”。

什么时候才该求值？
  → 函数体在调用前不求值。零参数函数（thunk）因此是延迟计算的最小机制。
  → delay / force、stream、memoization 都是这个事实的惯用法。
  → 这和 Haskell 的默认惰性不同：这里延迟是显式的，所以求值规则仍然可预测。
  Lecture: §5 Delayed Evaluation, Thunks, Streams, Memoization。
  为什么用零参数函数而不是新关键字：先看到“语言里已经有的求值规则足够”，再谈宏这种真正的新机制。

能不能让程序员增加语法，而不改语言实现？
  → macro 在求值前改写语法树。
  → hygiene：宏引入的变量不应意外捕获使用处的变量。
  Lecture: §5 Macros；optional hygiene。
  为什么大部分标成 optional：作业重心是延迟求值，但 Section 6 会用“Racket 函数充当被解释语言的语法”这个相邻想法。

如果我自己实现一门有一等函数的语言，closure 是什么数据结构？
  → 程序先变成 AST（树），不是字符串。
  → 环境是绑定的列表或映射。
  → 函数值是闭包：形参 + 函数体 + 定义时环境。
  → 调用 = 用实参扩展那个环境，再求值函数体。
  Lecture: §6 Implementing Languages, Variables and Environments, Implementing Closures。
  为什么这是 Part B 最难也最值的作业：它把 Part A 的语义从口号变成代码。

静态类型到底承诺什么？它不承诺什么？
  → static checking：运行前拒绝某些程序。
  → soundness：被接受的程序不会在运行时犯类型系统声称要防止的错。
  → completeness：所有不会犯那种错的程序都被接受。有用的静态类型系统选择 sound、放弃 complete。因此它会拒绝一些实际上好好的程序。这是权衡，不是缺陷被否认。
  → weak typing（C 的某些转换、不受检查的强制）是另一轴，不要和动态类型混为一谈。
  Lecture: §7。
  为什么在两种语言都用过之后：事实清单比偏好有用。Grossman 不宣布哪一边赢。

另一套打包：数据带着行为走。
  → 对象有状态和方法。方法调用不是“取出一个函数然后按词法环境调用”这么简单。
  → dynamic dispatch：用接收者的运行时类决定方法体。
  → 查找规则（self、super、继承链）比 closure 的自由变量查找更依赖调用时的对象。
  → Ruby 里一切皆对象，包括数字。类定义本身是动态的。
  → duck typing：不问“你是不是某种类型”，问“你能不能响应这个消息”。
  Lecture: §8。
  为什么即使你写过 Java 也要走一遍：Ruby 比 Java 更彻底地面向对象，又没有静态类型干扰，dispatch 规则可以单独看清。block 则让你认出“这几乎是 closure”。

如何把一个问题拆开？
  → 函数式分解：一个函数一种操作，对每种 variant 一个分支。加操作容易，加 variant 要改所有函数。
  → OOP 分解：一个类一种 variant，每种操作一个方法。加 variant 容易，加操作要改所有类。
  → 二者相反，因此比表面更相似：都是一张表，只是按行切还是按列切。
  Lecture: §9 OOP vs Functional Decomposition；Adding Operations or Variants。
  为什么这是课程的 aha：它解释了你为什么在两种风格里都感到“这种改动很烦”。烦的方向相反。

一个操作需要两个对象的类型时怎么办？
  → binary method。函数式里这只是多一个 case 嵌套。OOP 的单次 dispatch 只看接收者。
  → double dispatch：第一次派发选出第一个对象的方法，方法里再把自身传回另一个对象，第二次派发选出配对。
  → multimethods 把“看多个参数的运行时类型”做成语言机制。Ruby 没有，所以 double dispatch 是惯用法不是语法。
  Lecture: §9 Binary Methods, Double Dispatch, optional Multimethods。

复用一段行为，一定要继承吗？
  → 多重继承有菱形问题。
  → mixin（Ruby 叫 module）是一条可插入的行为，不是一个“是一种”的父类。
  → interface / abstract method 表达“你必须提供这些操作”，不等于继承实现。
  Lecture: §9。
  为什么和 ML signature 对照着记：都是边界，但 mixin 是实现的复用，signature 是实现的隐藏。概念类比，不是同一机制。

“子类的值能用在父类的位置”在类型上意味着什么？
  → subtyping：若 A <: B，则期望 B 的地方可以给 A。
  → 可变记录的 depth subtyping 是 unsound 的。不可变时才安全。这是 immutability 在课程最后一次回流。
  → 函数子类型：参数逆变（contravariant），返回值协变（covariant）。因为函数要能接受调用者给的一切合法参数。
  → 数组在 Java/C# 里的协变是著名的漏洞，靠运行时检查补。
  Lecture: §10 Subtyping, Depth Subtyping, Function Subtyping。

这和 ML 的 `'a` 是一回事吗？
  → 不是。`'a list` 是 parametric polymorphism：同一段代码对所有类型工作，类型之间没有“谁是谁的子类”。
  → subtyping 是“这些类型之间有一个可替换关系”。
  → Java generics 两者都有，所以容易用 subtype 去表达其实该用 type parameter 的事，或反过来。
  → bounded polymorphism（`'a <: Printable` 这类约束）是两者的组合，不是两者的中间模糊态。
  Lecture: §10 Generics versus Subtyping, Bounded Polymorphism。
  为什么这是终点：它把 Part A 的类型变量和 Part C 的对象系统接回同一张设计图。课的 2×2 表因此闭合。
```

### 为什么是这个顺序，而不是“先 OOP 再函数式”或“先动态再静态”

Grossman 的顺序是教学上的依赖，不是历史顺序。

1. **先静态函数式，再动态函数式，再动态面向对象。** 每一步只换一个轴。若一开始就上 Ruby，类型、派发、可变状态、类定义动态性会同时砸下来，你无法知道哪个机制在起作用。
2. **动机后置。** 第 1 周的不舒服（没有赋值、递归、REPL）是刻意的，类似《空手道小孩》里先擦车：肌肉记忆先于解释。解释放在你已经有 closure 之后。
3. **先使用 closure，再实现 closure。** 使用产生“它为什么还能看见 x”的问题；实现回答这个问题。顺序反了，实现就是无目的的解释器作业。
4. **类型推断晚于“你已经在享受不写类型”。** 这样“推断 ≠ 动态”才是一个纠正，而不是一条预习。
5. **等价放在 module 旁边。** 抽象类型的意义就是：表示换了，客户观察不到。没有等价概念，signature 就退化成头文件清单。
6. **OOP 放在最后，并且故意在某些题上显得笨拙。** 不是反 OOP。是用对照让函数式分解的好处变得可见，同时承认有些问题 OOP 更自然。课程不宣称一种分解总是更好。
7. **Subtyping 回到静态类型。** Part B 没有考试；最终的类型对照需要 A 的多态和 C 的对象都在场。

---

## 三、依赖图

读的时候如果卡住，回到箭头起点，而不是在当前术语里打转。

```text
表达式与值
    ↓
环境与绑定（shadowing ≠ mutation）
    ↓
函数（调用 = 扩展环境 + 求值函数体）
    ↓
嵌套函数与自由变量
    ↓
词法作用域（lexical scope）
    ↓
闭包（code + environment，生命周期延长）
    ↓
高阶函数 / 回调 / 柯里化 / 用闭包做 ADT
    ↓
解释器里的闭包表示（Section 6）
    ↓
动态派发 vs 闭包查找（Section 8）
```

```text
不可变绑定
    ↓
alias 无害、局部推理、更强的程序等价
    ↓
显式的 ref 盒子（需要状态时才引入 mutation）
    ↓
闭包捕获盒子 vs 捕获值
    ↓
depth subtyping 在可变数据上 unsound（Section 10）
```

```text
each-of（tuple / record）
    ↓
one-of（datatype）
    ↓
pattern matching
    ↓
递归数据类型 = AST
    ↓
函数式分解（一个操作一个函数）
    ↓
expression problem
    ↓
OOP 分解（一个变体一个类）
    ↓
binary method → double dispatch
```

```text
值
    ↓
类型与 typing rules
    ↓
类型变量与参数多态
    ↓
类型推断（仍是静态检查）
    ↓
value restriction（多态 × 副作用）
    ↓
soundness（保 sound，弃 complete）
    ↓
静态 vs 动态是设计权衡
    ↓
subtyping（另一套“可替换”）
    ↓
generics ≠ subtyping；bounded polymorphism 才是二者的组合
```

```text
绑定的集合
    ↓
名字空间（module 的弱用法）
    ↓
signature = 客户可见边界
    ↓
抽象类型
    ↓
实现可替换（等价）
    ↓
副作用使等价变弱
```

---

## 四、十个 Section 在问题链上的位置

| Section | 语言 | 这一段把哪一环钉死 | 作业在练什么（概念，不是分数） |
|---|---|---|---|
| 1 | SML | 绑定、求值、函数、列表、不可变 | 用递归和不可变数据取代循环和赋值 |
| 2 | SML | one-of、模式匹配、尾递归 | 用 datatype 建模，并让递归在空间上可行 |
| 3 | SML | 一等函数、词法作用域、闭包 | 把计算模式抽象成高阶函数 |
| 4 | SML | 推断、module、等价 | 画出抽象边界；理解“不写类型”仍是静态的 |
| 5 | Racket | 动态类型下的同一批想法；延迟求值；宏 | stream：用 thunk 做出看起来无限的数据 |
| 6 | Racket | 解释器、环境、闭包的实现 | 实现一门有一等函数的小语言 |
| 7 | — | sound / complete、静态 vs 动态、weak typing | 用事实而不是阵营做设计判断 |
| 8 | Ruby | 对象、动态派发、block | 在已有程序上改行为，观察 lookup |
| 9 | Ruby | 两种分解、double dispatch、mixin | 把 ML 风格的解释/几何代码改写成承诺 OOP 的结构 |
| 10 | — | subtyping vs generics | 把整门课的类型轴收回来 |

Part B 比看起来短，但 Homework 5（解释器）通常是最难也最值的一次。Part C 的 Homework 7 是同一种难度：再写一个解释器，但用 OOP 分解，并处理 double dispatch。两次作业是同一主题的两次投影。

---

## 五、读完全课之后，看一门陌生语言时看什么

完整检查表在最后一章。这里先放 Grossman 收束时真正强调的东西，避免地图本身又变成大纲：

1. 每个构造的语法、求值规则、（若有）类型规则是什么？
2. 绑定默认可变吗？可变性是默认、禁止，还是显式盒子？
3. 自由变量按定义处还是调用处查找？函数值是否因此必须是闭包？
4. 函数是一等的吗？延迟求值是显式 thunk、默认惰性，还是没有？
5. one-of 数据有语言支持（datatype / match / 代数数据类型）吗？没有的话，惯用法是什么，别掉进 Turing tarpit？
6. 有没有在运行前拒绝程序的规则？它 sound 吗？它故意不 complete 吗？
7. “可替换”靠 subtype，还是靠 type parameter，还是靠 duck typing？
8. 操作和变体，语言让哪一个更容易后加？
9. 抽象边界是 signature、interface、模块私有、还是仅仅靠约定？
10. 程序在语言内部被看成文本，还是树？能不能宏、能不能 `eval`？

下一章从第一个不能跳过的问题开始：一个表达式在一个环境里如何变成一个值。
