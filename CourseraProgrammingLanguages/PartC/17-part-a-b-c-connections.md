# How Part C Connects to Part A and Part B

Part C 的概述讲把前两门收成一张幻灯片：Part A 是函数式基础、ML 的静态类型、模式匹配、一等函数与闭包、类型推断、模块、程序等价。Part B 用 Racket 补上动态类型的函数式，加上延迟求值的惯用法，以及用 `eval_exp` 实现自己的语言。于是你带着函数式、有类型系统和没有类型系统的经验、以及解释器，进入对象。

Source: Overview of Part C Concepts / 0:05–1:21。

下面每条联系都尽量标出是课程明确说过，还是笔记为了复习接上的。

## Closure：三个语言，一个模型

```text
Part A   ML function / fn        代码 + 定义时环境
Part B   Racket lambda           同样。词法作用域，不是动态作用域
Part C   Ruby block / Proc       block 词法作用域；Proc 是一等闭包
```

`[Course]` 老师在介绍 Ruby 时就把 blocks 说成几乎是闭包，并说 Ruby 有我们在 ML 和 Racket 里喜欢上的闭包。Proc 那一讲把“一等”定义清楚：能作为结果、能存储、能传递。Block 做不到，所以是 second-class。

共同模型：

```text
造出函数值的时候，把当时的环境打包
以后调用，用的是那份环境，不是调用点的环境
```

因此 ML 里后定义的 `even` 影响不到已经关闭的 `odd`。Ruby 的 Proc 捕获 `x` 也是这一条。对象看起来像，但 `self.m` 不关闭。那是 Part C 新增的对照，不是闭包规则的例外。见 `06`。

Source: Section 8 — Introduction to Ruby / 4:41–4:46；Blocks / 0:18–0:59；Procs / 1:10–1:44；Dynamic Dispatch Versus Closures / 2:53–3:11。

## 数据怎么拆开

```text
Part A/B
    datatype 列出变体
    一个函数里 pattern match，每个构造子一个分支
    解释器 eval_exp 就是这种函数：一个操作，覆盖所有表达式变体

Part C
    每个变体一个 class
    每个操作一个方法
    选择代码靠 dynamic dispatch，不靠 case
```

`[Course]` Section 9 的表达式例子就是 Part B 解释器的同一类问题，换成两种分解。作业 7 是把这种 ML 代码移植成 Ruby 的行式布局，并且在二元操作上使用 double dispatch。

静态与动态在这里正交：ML 的 `Negate` 分支必须处理“求值结果不是 Int”，所以抛异常。Ruby 直接 `.i`。老师说这是静态类型对动态类型，不是 FP 对 OOP。

Source: Section 9 — OOP vs Functional Decomposition / 1:48–1:56，8:44–8:55。

## 多态的分类

课程明确对比了 parametric 与 subtype，并在可选讲里把 static overloading 从 multimethods 里拆出来。Duck typing 是另一讲的主题。把它们画成一棵树是 `[Inference]`，节点都来自课程，树的形状是笔记的组织。

```text
Polymorphism：一份代码，多种数据
│
├── Parametric
│     ML 'a
│     Java/C# generics
│     C++ templates（老师说 kind of）
│     └── Bounded
│           任意 T，但 T <: U，或 T 满足某个约束
│
├── Subtype
│     record width
│     Java/C#：subclass 蕴含 subtype
│     运行时往往配合 dynamic dispatch（virtual）
│     不是同义词：可以有 subtype 关系而不在这次调用上分派
│
├── Ad-hoc
│     static overloading：同名，按静态类型选，编译期决定
│     multimethods：同名，按多个运行时 class 选
│     两者都叫“同名多个方法”，选择时机不同
│
└── Duck typing
      不在静态关系里
      契约是实际发送的消息
      不要并进 subtype，也不要并进 parametric
```

`[Course]` 支撑这条树的原话分布在：Generics Versus Subtyping；Bounded Polymorphism 开头（含 C++ templates kind of）；Multimethods 里 overloading 与 multiple dispatch 的区分；Duck Typing 整讲。

### 为什么 duck typing 不能算 structural subtyping

Structural subtyping 仍是类型系统里的 `<:`。Section 10 的 width 规则是它的一种。通过检查的程序不会读到没有的字段。

Duck typing 没有这层 `<:`。`double` 接受任何对象，失败发生在 `+` 那一次发送。Go 的 interface 满足更像结构子类型，是静态的。Python/Ruby 的“有这个方法就行”才是 duck typing。`[Modern Connection]` 的细节在 `18`。

### 为什么 overloading 不是 parametric，也不是 subtype

`add(int, int)` 和 `add(string, string)` 是两段代码，编译器按静态类型选一段。不是一段代码对所有类型成立，也不是一段代码只依赖超类型的方法。Ruby 没有这个机制，所以同名就是替换。

## 程序等价，在 Part C 变难了

Part A 讨论过两段程序何时等价。Wrap-up 提醒：若两边都没有副作用，能等价的东西多得多。

Part C 加上两刀：

- 可变状态让别名变得重要。`x = y` 之后，对一个引用的更新另一个看得见。没有更新，就不必问谁是谁的别名。
- Duck typing 让 `x + x` 和 `x * 2` 不再是安全的替换，即便它们对数字等价。客户可以传入把两个消息实现得不同的对象。

`[Course]` 这两点分别在 wrap-up 的 mutation 清单开头，和 duck typing 讲的中段。

Source: Course Wrap-up / 4:32–5:03；Section 8 — Duck Typing / 1:43–2:23。

## 解释器从 Part B 走到 Part C

Part B：一棵抽象语法树，一个递归函数 `eval`，按构造子分支。

Part C：同一棵树可以是对象图。每个节点的 class 是它的变体，`eval` 是方法。加一种表达式是加一个 class，不是给函数加一个分支。

Wrap-up 把两件事都列为课程高潮：你实现过自己的语言；你比较了两种分解。最后一次作业里，简洁的 ML 被移植成更难读的 Ruby，老师说这是否说明问题，允许有不同意见。

他还把“程序是树，不是文件里的文本”单独列出。Part B 写解释器时这是必须的。Part C 的类层次是同一棵树的另一种编码。

Source: Course Wrap-up / 2:16–2:33，6:25–6:53，7:55–8:09。

## 类型系统会偏向一种风格

可选的 Racket 编码讲把这个说透了，虽然不考。

在 Racket 里手动做 dynamic dispatch 是可行的，秘密是多传一个 self。在 ML 里做同样的事，类型系统挡路：缺少 subtyping，polar-point 很难具有 point 函数所期望的类型。不是不可能，是不友好。所以想要对象的 ML 家族语言把对象做成语言内建。

反过来，泛型加入之前的 Java，对 ML 那种带闭包的多态同样不友好。

`[Course]` 结论：类型系统有时阻止你换一种编程风格，同时把某一种风格支持得很好。Part C 的最后一周就是在静态类型内部，把 OOP 需要的 subtyping 和 FP 需要的 generics 都摆出来，再给一个两者都要的有界形式。

Source: Section 8 — Dynamic Dispatch Manually in Racket / 14:14–15:51；Section 10 开场 / 0:49–1:12。

## 模块化：课程说自己讲少了

Wrap-up 里老师说，若有一件希望多强调的事，大概是模块化。ML 的 module 在课程中段重点讲过。Racket 和 Ruby 也有做法，值得学，但没讲够。程序变大之后没有替代品。

和 Part C 能接上的几条，都是 `[Course]` 已经出现过的，只是没被叫成“模块系统”：

- 实例变量永远私有，客户依赖方法而不是表示。
- 不要重开别人的 `Point` 去加 color。那是非模块化的修改。
- 内嵌对象把“我用了一个 Point”藏进表示；subclass 则公开了 is-a。
- ML 把 datatype 藏进 module，可以禁止外部加操作。Java `final` 禁止覆盖。扩展与推理是交换。

Source: Course Wrap-up / 7:26–7:53；Section 8 — Why Use Subclassing / 2:02–2:24；Section 9 — Adding Operations or Variants / 10:11–10:48。

## 一张只含课程语言的对照

| 问题 | ML | Racket | Ruby | Java/C#（对照，非主语言） |
| --- | --- | --- | --- | --- |
| 类型 | 静态，推断 | 动态 | 动态 | 静态 |
| 主要分解 | 函数 + datatype | 函数 + 结构/列表 | class + 方法 | class + 方法 |
| 行为打包 | 闭包 | 闭包 | 闭包，以及对象 | 对象；闭包后来才方便 |
| 按情况选代码 | pattern match | `cond` / `match` | dynamic dispatch | dynamic dispatch + 静态重载 |
| 复用行为 | 高阶函数，模块 | 高阶函数 | subclass，mixin | subclass，interface |
| “多一个字段也行” | 不接受 | 运行时只要访问得到 | duck typing | subtyping，但是名义的 |
| 通用容器 | `'a list` | 动态，元素任意 | 动态 | generics；以前是 Object |

Java 列是课程反复用来对照的语言，不是第四门要你写的语言。
