# Programming Languages Part C — Course Overview

标签约定：

- `[Course]` 字幕明确讲过。
- `[Supplement]` 为了建立模型而补充，不是老师原话。
- `[Modern Connection]` 现代语言类比。
- `[Inference]` 从课程逻辑推出来，但老师没有明说。

代码若根据课堂口述重建、而不是逐字抄幻灯片，会标明“课堂重建”。不要把补充知识当成 Dan Grossman 的原话。

---

## Part C 到底在研究什么？

Part A / B 已经建立了一套函数式思维：用函数分解计算，用环境解释名字，用闭包把“代码 + 定义时环境”打包，用 datatype + pattern match 按变体分情况。Part C 不是“再学一门语法”，而是用这套模型去对照另一种组织程序的方式。

`[Course]` 老师把三门课收成一张 2×2 表：

```text
                 静态类型              动态类型
函数式           ML (Part A)           Racket (Part B)
面向对象         Java / C#             Ruby (Part C)
                 （本课不系统讲授）
```

Ruby 被选来填右下角：动态类型、并且**纯**面向对象、而且是 **class-based**。选它不是因为 Rails，而是因为“所有值都是对象”让对象模型没有例外，动态类型又让类型系统先不要挡在 dispatch 前面。Mixins、闭包、运行时改 class，都是后面要对照的语言设计点。

Source: Welcome to Part C / 1:09–2:29；Overview of Part C Concepts / 0:05–4:05；Section 8 — Introduction to Ruby / 3:12–6:13。

因此 Part C 的问题主线不是“Ruby 有哪些特性”，而是：

```text
已有模型：函数、词法作用域、闭包、datatype、模式匹配、参数多态
        │
        ▼
Ruby：一切皆对象。class 决定行为，object 持有私有状态。
        │
        ├─ 消息发送 e.m 到底选哪段代码？
        │     receiver → runtime class → method lookup → self = receiver
        │
        ├─ 这和“调用一个 closure”有什么不同？
        │     closure 在定义时关闭；dynamic dispatch 在调用时仍开放
        │
        ▼
同一张“变体 × 操作”的表，可以按列写（FP），也可以按行写（OOP）
        │
        ├─ 以后加操作：FP 自然，OOP 要改每个 class
        ├─ 以后加变体：OOP 自然，FP 要改每个函数
        │
        ▼
二元操作（两个操作数的运行时种类都重要）
        │
        ├─ FP：对 pair 做嵌套模式匹配，九个 case 放在一起
        └─ OOP：单次 dispatch 只看 receiver，所以要 double dispatch
              （multimethods 把这件事做成语言规则，Ruby 没有）
        │
        ▼
一个 class 想复用多份行为，又不想要多重继承的歧义
        │
        ├─ C++ multiple inheritance：能做，但 method / field 语义变复杂
        ├─ Ruby mixin：只复用方法，仍只有一个 superclass
        └─ Java interface：不提供代码，只让静态类型更灵活
        │
        ▼
回到静态类型：什么时候“一种值可以安全地当作另一种值用”？
        │
        ├─ 一条 subsumption 规则 + 一个 subtype 关系
        ├─ record：可以忘掉字段（width）；不能随便改字段类型（depth + mutation）
        ├─ function：返回值协变，参数逆变
        └─ generics 和 subtyping 解决的不是同一种多态
              两者合在一起，才是 bounded polymorphism
```

这门课最后要留下的不是 Ruby 语法，而是这个判断力：面对一个程序组织问题，该用闭包、datatype、subclass、mixin、subtype，还是 type parameter。

Source: Overview of Part C Concepts / 2:28–4:05；Section 9 — OOP vs Functional Decomposition / 0:18–1:37；Section 10 — Subtyping / 0:05–1:12；Course Wrap-up — Summarizing / 0:40–2:02。

---

## Programming Languages Part C Knowledge Map

下面的树按**老师的因果顺序**排，不按视频文件名排。括号里是笔记文件。

```text
Programming Languages Part C
│
├── 0. 这门课在填哪一格
│   ├── ML = 静态 + 函数式
│   ├── Racket = 动态 + 函数式
│   ├── Ruby = 动态 + 面向对象
│   └── Java/C# = 静态 + 面向对象（对照，不系统讲授）
│       └── 01-ruby-language-model.md
│
├── 1. Ruby 的对象模型
│   ├── 一切求值结果都是对象引用
│   ├── class 定义方法；ClassName.new 造对象
│   ├── 消息发送 = 方法调用
│   ├── self = 当前正在执行其方法的对象
│   ├── 实例变量 @ 是对象私有状态（不是 class 声明的字段表）
│   ├── initialize 由 new 调用；别名在赋值时产生
│   ├── 可见性：实例变量永远 private；方法 public / protected / private
│   ├── getter / setter 是方法，不是字段访问
│   ├── nil、数字、top-level 方法、class 本身，都是对象
│   ├── class 定义在运行时可被重新打开
│   └── 数组 / 哈希 / range：动态、灵活、靠方法而不是靠“是不是 Array”
│       └── 02-objects-classes-state.md
│       └── 01-ruby-language-model.md
│
├── 2. 行为也可以被传来传去
│   ├── block：方法调用旁边的 0 或 1 个匿名代码块，不是对象
│   ├── yield：callee 调用那个没有名字的 block
│   ├── Proc：用 lambda 把 block 变成一等对象
│   └── 闭包 = 代码 + 定义时的词法环境
│       └── 03-blocks-procs-closures.md
│
├── 3. 复用与覆盖
│   ├── subclass 继承 superclass 的方法
│   ├── override = 同名方法替换
│   ├── super = 调用被替换的那个版本
│   ├── 实例变量仍不是 class 定义的一部分
│   ├── is_a? 含祖先；instance_of? 只看精确 class
│   └── 何时该 subclass，何时该复制、内嵌、或直接改原 class
│       └── 04-inheritance-overriding.md
│
├── 4. Dynamic dispatch（本课最独特的语义）
│   ├── 先求值 receiver 和参数
│   ├── 从 receiver 的 class 开始找方法，再沿 superclass 走
│   ├── 找不到则 method_missing
│   ├── 执行方法体时 self 绑定为 receiver
│   └── 因此继承来的方法可以调用子类覆盖过的方法
│       └── 05-dynamic-dispatch.md
│
├── 5. 闭包 vs 对象
│   ├── 闭包：调用哪个函数在造出 closure 时已经固定（词法作用域）
│   ├── 对象：self.m 在运行时仍可能进子类
│   ├── 这是机会（不改旧代码就能改行为）也是代价（不能孤立地读一段方法）
│   └── 可选：在 Racket 里用“多传一个 self”手动做出 dispatch
│       └── 06-closures-vs-objects.md
│
├── 6. Duck typing
│   ├── 代码要求的是“能响应这些消息”，不是“是某个 class 的实例”
│   ├── 和 dynamic typing、dynamic dispatch、structural typing 不是同一个词
│   └── 复用增加，可替换性证明和抽象边界变弱
│       └── 07-duck-typing.md
│
├── 7. 同一张表的两种切法
│   ├── 行 = 数据变体（Int / Add / Negate）
│   ├── 列 = 操作（eval / toString / hasZero）
│   ├── FP 按列组织；OOP 按行组织
│   ├── 加列：FP 易，OOP 难
│   ├── 加行：OOP 易，FP 难
│   └── 预先规划的补救：FP 的 other case；OOP 的 visitor（点到为止）
│       └── 08-functional-vs-oop-decomposition.md
│       └── 09-expression-problem.md
│
├── 8. 两个操作数都重要时
│   ├── binary method：行为依赖两个值的种类
│   ├── FP：嵌套模式匹配，可把可交换的 case 递归到对面
│   ├── OOP 半吊子：dispatch 一次，再 is_a? 分支（作业不允许）
│   ├── double dispatch：第二次消息的名字编码“我是谁”
│   └── multimethods：语言按所有参数的运行时 class 选方法
│       └── 10-double-dispatch.md
│       └── 11-multimethods.md
│
├── 9. 多份行为怎么组合
│   ├── multiple inheritance：class hierarchy 从树变成 DAG
│   ├── 歧义：同名方法选谁；同名字段要一份还是两份
│   ├── mixin：一包方法，include 进 class，方法里可以用 self
│   ├── Comparable 靠 <=>；Enumerable 靠 each
│   ├── interface：只有方法签名，用来做 subtype，不提供代码
│   └── abstract method：父类要求子类覆盖，编译期检查
│       └── 12-mixins-interfaces.md
│
├── 10. Subtyping
│   ├── 问题：多一个 color 字段的 record，能否传给只要 x,y 的函数
│   ├── 只加一条规则：e : T1 且 T1 <: T2 ⇒ e : T2
│   ├── 关系：width、permutation、传递、自反
│   ├── 合法性标准是 substitutability，不是口味
│   ├── depth subtyping + setter + soundness，三者只能取二
│   ├── Java/C# 数组协变是这个错误的实例，用 ArrayStoreException 补
│   └── 13-subtyping.md
│
├── 11. 函数与方法的 subtype
│   ├── 返回类型：协变（可以多给）
│   ├── 参数类型：逆变（可以少要）
│   ├── 方向反了就会读到不存在的字段
│   ├── Java/C#：subclass 关系被当作 subtype 关系
│   ├── class 定义行为，type 描述可替换的接口；两者被语言故意混用
│   └── self/this 是特殊的，允许协变，因为调用者不能另传一个 self
│       └── 14-function-subtyping.md
│
├── 12. 两种多态，以及它们的乘积
│   ├── parametric：这段代码对任何类型都一样，类型变量出现多次表示“必须相同”
│   ├── subtype：我需要 Foo，你有 Foo 的 subtype 也可以
│   ├── 用 Object + downcast 冒充 generics，是用错工具
│   ├── 用 generics 冒充“多一个字段也行”，ML 做不到，因为没有 subtyping
│   └── bounded polymorphism：任意 T，但 T <: Point
│       └── 15-generics-vs-subtyping.md
│       └── 16-bounded-polymorphism.md
│
└── 贯穿比较
    ├── Part A/B/C 怎么接上          17-part-a-b-c-connections.md
    ├── 现代语言对照                 18-modern-language-comparison.md
    ├── C++                          19-cpp-connections.md
    ├── 常见误解                     20-common-misconceptions.md
    ├── Homework 6 / 7               21-homework-guide.md
    ├── 速查                         22-course-cheatsheet.md
    ├── 自测                         23-self-test.md
    └── 最终模型                     24-final-mental-model.md
```

---

## 四个“dynamic”不是一个概念

这是读 Section 8 时最容易搅在一起的地方。`[Course]` 老师分别讲了它们，但没有在一张幻灯片上并列定义。下面的区分是 `[Inference]`，依据是各讲的定义。

| 词 | 问的问题 | Ruby 里的答案 |
| --- | --- | --- |
| dynamic typing | 类型错误何时发现？ | 运行到那一次调用才发现没有这个方法，或参数不对 |
| dynamic dispatch | `e.m` 选哪段方法体？ | 按 **receiver 的运行时 class** 查找，不按变量的静态声明 |
| dynamic class definition | class 的方法表能不能在运行时变？ | 能。重新打开 class，已存在的对象也会看到新方法 |
| duck typing | 调用者该假设参数“是什么”？ | 不假设 class，只假设它响应某些消息 |

一个静态语言也可以有 dynamic dispatch（Java `virtual` 方法）。一个动态语言也可以做很差的 duck typing（到处 `instance_of?`）。Ruby 四样都有，所以必须拆开。

Source: Section 8 — Introduction to Ruby / 4:18–4:40；Class Definitions Are Dynamic / 0:03–0:36；Duck Typing / 0:34–1:16；Section 8 — Method Lookup / 0:16–0:58。

---

## 老师真正的“啊哈”

按课程自己的强调，值得单独记住的不是语法，而是这些对照：

1. FP 与 OOP 在填同一张表，只是按列还是按行。它们相反到几乎是同一件事的两个视角。  
   Source: Section 9 — OOP vs Functional Decomposition / 0:55–1:11，10:27–10:52。
2. 闭包和对象都是“代码 + 私有数据”，但 lookup 规则不同。dynamic dispatch 是 OOP 相对闭包**多出来**的那部分语义，也更复杂。  
   Source: Section 8 — Dynamic Dispatch Versus Closures / 0:05–0:19，9:21–9:34；Method Lookup / 8:06–9:19。
3. subclassing 在 Ruby 里只是方法表的继承，不是类型系统。到 Section 10，subclassing 与 subtyping 才被放在一起，并且被说成相关但不是同一个概念。  
   Source: Section 8 — Subclassing / 2:24–2:41；Section 10 — Subtyping for OOP / 5:49–6:08。
4. generics 与 subtyping 各有擅长。用错工具会得到 downcast，或得到“多一个字段就不接受”。合在一起才是 bounded polymorphism。  
   Source: Section 10 — Generics Versus Subtyping / 0:05–0:26；Bounded Polymorphism / 0:35–1:04。
5. 可变性反复破坏漂亮的规则：别名、depth subtyping、`List<ColorPoint>` 不能当作 `List<Point>`。不可变则其中若干规则恢复可靠。  
   Source: Course Wrap-up — Summarizing / 4:06–5:43。

---

## 课程结构（作业与考试，不是知识依赖）

`[Course]`

```text
Section 8   Ruby 对象、block、subclass、dispatch     Homework 6
Section 9   分解方式、double dispatch、mixin 等       Homework 7（交 ML + Ruby）
Section 10  subtyping / generics / bounded polymorphism
            没有新编程作业；考试覆盖 Part B 和 Part C
```

Section 9 视频少、作业重。考试不只考第三周。

Source: Part C Course Structure / 0:14–3:10。

---

## 建议的阅读顺序

先读本文件的主线，然后：

```text
01 → 02 → 03 → 04 → 05 → 06 → 07
        → 08 → 09 → 10 → 11 → 12
        → 13 → 14 → 15 → 16
        → 17 → 24
```

18、19 是迁移，不要在 05 之前读。20 用来抓自己的误解。21 在做题时读，不要先看“答案”——笔记里也没有作业答案。22 是复习卡，23 是自测。

为什么是这个顺序：dispatch 的语义依赖 self 和 class；FP/OOP 对照依赖你已经见过 datatype 和 subclass；double dispatch 是“单次 receiver dispatch 不够”的直接后果；subtyping 的函数规则，是在你理解“方法像函数、对象像 record”之后才推得出的。先背逆变，后看例子，记不住。
