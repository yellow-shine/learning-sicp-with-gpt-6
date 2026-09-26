# Homework Guide

没有答案，也没有作业源码。字幕只描述了两份作业的形态和学习目的。下面所有具体类名，若不是讲座里的 `Int` / `Add` / `MyRational`，就不要假定作业里一定叫这个。讲座说作业与讲座例子相似，并会给你很多提示。

Source: Part C Course Structure / 0:28–2:37；Section 8 — Introduction to Ruby / 7:17–8:23；Section 9 — Double Dispatch / 3:57–4:09，12:51–13:07；Binary Methods / 6:27–6:35。

## Homework 6

### What it tests

读已经能跑的 Ruby，在不改给定代码的前提下扩展它。这和前两门课“我们给一点骨架，你写整个程序”相反。老师认为这更接近真实开发：增强已有程序，也是学新语言的好办法。

概念上它落在 Section 8：对象、类、实例变量、方法调用、可见性、block、以及你在给定代码里会看到的 subclass / dynamic dispatch。图形和 Tk 只是安装前提。你几乎不需要懂 Tk。

### Architecture of the problem

`[Course]` 已知的只有这些：

- 给你大约几百行已经能工作的 Ruby。
- 程序是图形的，安装说明里包括让 Ruby 能用 Tk。
- 你添加代码，不修改他们给的代码。
- 自动评分器要和你使用的 Ruby 版本一致。版本不影响课程概念。提交时会看到版本选择。

`[Inference]` 因此给定代码就是规格的一部分。你要扩展的行为，多半通过子类、新方法、或给定代码已经在调用的钩子接进去。如果给定代码调用了 `self.something`，你的扩展会通过 dynamic dispatch 被调用，而不必改调用点。这是推断，以作业说明为准。

### Concepts required

- 消息发送不是“变量的函数槽”。
- `@` 只属于对象自己的方法。需要跨对象的信息，就找他们已经提供的方法，不要试图读别人的实例变量。
- 覆盖一个方法之前，先看父类方法有没有向 self 发消息。你覆盖的可能是那些消息，而不是你以为的那个入口。
- Block 是库和给定代码遍历东西的方式。先找 `each` / `times` / `yield`，再考虑自己写循环。
- 不改给定代码，意味着不能靠重开他们的 class 去“修好”一段你不喜欢的逻辑，除非作业明确允许。重开 class 在语言里合法，在这份作业的规则里通常越界。这是 `[Inference]`，来自“without modifying the code that's already there”。

### Common mistakes

- 改了发放的文件，自动评分仍用原文件，于是你的修改消失。
- 把 `e.foo =` 当成字段赋值，在 setter 不存在时困惑。
- 在 private 方法上写 `self.helper`。
- 读到未初始化的 `@` 得到 `nil`，然后对 nil 发消息，错误看起来像算法错了。
- 用 `instance_of?` 区分给定代码里的子类，把以后的扩展挡在外面。给定代码若已经用动态分派设计过，你再问精确 class，就是在对抗它。
- Tk 装不好就去改图形逻辑。先让发放的程序在你机器上跑起来。

### Recommended order

```text
1. 让发放的程序未修改地跑起来。版本与评分器一致。
2. 从入口方法往下读，画出“谁 new 了谁、谁向 self 发了哪些消息”。
3. 只给一个最小扩展，确认你的代码被调用到了。
4. 再实现行为。状态放在你自己的对象里，通过已有方法与给定代码交换信息。
5. 用边界情况看动态分派：子类实例走到的是不是你覆盖的方法。
```

## Homework 7

### What it tests

把一段 ML 移植成 Ruby，并且移植成面向对象的分解，而不是在 Ruby 里写一个大 `case`。同时提交 ML 和 Ruby。同伴互评只看 Ruby。

讲座点名的难点是 double dispatch。表达式类的组织会和课堂上的 `Exp` / `Value` / `Int` / `Add` / `Negate` 相似，但作业可以有更多变体和操作。二元操作里，可交换的格子也许可以递归到对面，讲座说你在作业里可能看到更多这种情况。

Section 9 视频少，是因为概念要在这次作业里合在一起用。多重继承、mixin、interface 不需要用于这份作业。手动在 Racket 里写 dispatch 的那一讲也不考、也不用于作业。

Source: Section 9 — Multiple Inheritance / 0:02–0:07；Racket encoding / 0:04–0:09；OOP vs FP / 6:57–7:01；Double Dispatch / 12:51–13:48。

### Architecture of the problem

讲座给出的骨架就是你该认识的架构，不是可以照抄的作业答案：

```text
ML
    datatype 列出变体
    每个操作一个函数，函数里 case
    二元操作用 helper，对一对值做嵌套模式匹配
    可交换的格子可以 add_values(v2, v1)

Ruby
    每个变体一个 class，挂在 Exp 或 Value 下面
    每个操作一个方法
    值的 eval 返回 self
    复合表达式的 eval 向子表达式发消息
    二元操作不要 is_a?
        左值.add_values(右值)
        左值的 add_values 向右值发送带有“我是谁”的消息
        九格（或 n² 格）各自是一个方法
```

`[Course]` 静态类型里不得不写的“结果不是 Int 就抛异常”，在 Ruby 里常常变成直接调用 `.i`。这是动态类型，不是你漏写了检查。若作业要求你检测错误，以说明为准。

Java 可选代码把 `addInt` 的参数类型写成 `Int`，会帮助你看清每个方法只该被谁调用。Ruby 里这只是约定。

### Concepts required

```text
datatype            →  class 层次
pattern match       →  dynamic dispatch
一列一个函数         →  一行一个 class
加变体要改所有函数   →  加 class，旧 class 可以不动
二元操作的方格       →  两次分派，不是一次分派加 is_a?
```

还要能解释为什么 `v.add_values(self)` 不是解法。见 `10`。

### Common mistakes

- 在 Ruby 里写一个 `eval` 函数，里面 `is_a?` 或 `case` 扫所有类。程序能算对，但不是这次作业要的分解。讲座把这种混合称为不够 OOP。
- `add_values` 里再调用 `add_values`，无限递归。
- 字符串或别的不可交换操作把 self 放错边。记住：第一次对左操作数发消息，第二次的 self 是右操作数。
- 可交换的数值格子复制了一大段，而不是转到对面。不是错，但是讲座认为对面递归是合理风格，并且作业里可能更有用。
- 覆盖了 `eval`，忘了作业要求的其他操作。OOP 布局下，漏的是某个 class 里的方法，不会像 ML 那样集中在一个函数末尾。
- ML 一侧用了通配模式，于是加构造子时编译器不再列出待办。讲座在扩展性那一讲警告过。
- 只交了一种语言。自动评分要 ML 文件和 Ruby 文件。

### Recommended order

```text
1. 在 ML 里把变体和操作读成一张表。行是什么，列是什么，哪一列内部还有方格。
2. 先移植没有二元方格的操作。每个变体一个 class，每个操作一个方法。
   用讲座的 Int#eval 返回 self 作为检查：值是否求值到自己。
3. 再写复合变体的递归：向子对象发消息，不要 case。
4. 最后做二元操作。先写每个值类的 add_values，让它只转发到带种类名字的方法。
   然后一次填一格，并用一个可交换格试验“转到对面”。
5. 用九种（或 n² 种）组合各跑一次。顺序敏感的格对调操作数再跑一次。
6. 不要用 is_a? 让测试变绿。那会通过一些测试，同时错过作业要训练的查找规则。
```

## 考试

`[Course]` 第三周没有编程作业。考试覆盖 Part B 和 Part C，不只是 subtyping。Part B 的解释器、延迟求值、动态类型，和 Part C 的 dispatch、分解、subtyping 可能出现在同一张卷子上。练习考试以课程页面为准，字幕没有收录题目。

Mixin、多继承、interface 不在作业里，但老师说可能考。Racket 手动 dispatch 不考。抽象方法那一讲可选；学过 Java/C++ 的话他建议看，因为考试可能碰到 pure virtual / abstract 与 interface 为何在 C++ 里多余。

Source: Part C Course Structure / 2:40–3:14；Section 9 — Multiple Inheritance / 0:02–0:12；Abstract Methods / 0:15–0:30。
