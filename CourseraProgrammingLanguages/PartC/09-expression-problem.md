# Module 9 — 表达式问题，以及“两种扩展都要容易”

## 名字

`[Supplement]` 课程没有使用 Expression Problem 这个名字。Philip Wadler 用它指：怎样在静态类型下，既不加改旧代码，又能加新变体，又能加新操作，同时保持类型安全。

`[Course]` 老师讲的是这件事的核心，不讲这个专名，也不展开解法的细节。他说后半张幻灯片是可选的，因为讲完会太长。笔记必须把“老师讲了什么”和“这个名字背后通常还有什么”分开。

Source: Section 9 — Adding Operations or Variants / 6:35–8:30。

## Problem

蓝色的表已经填完。后来有人要加一行 `Mult`，或加一列 `noNegConstants`。`noNegConstants` 在课堂里不是布尔函数，老师口误后纠正了：它是 `exp -> exp`，把负的整型常量预处理成“取负的正常量”。

```text
Int i    若 i < 0 则变成 Negate(Int (-i))，否则不动
Negate   递归处理子表达式
Add      两个子表达式都处理，再装回去
```

Source: Section 9 — Adding Operations or Variants / 1:55–2:54。

## 不预先规划时，疼痛是不对称的

### 函数式

加列：在 datatype 定义之后写一个新函数。旧函数一个字不用改。

加行：给 datatype 加 `Mult`。重新编译，`eval`、`toString`、`hasZero` 全部变成非穷尽匹配。若 `noNegConstants` 已经写了，它也要补。类型检查器给你一份待办清单，前提是你当初没用通配把新情况吞掉。

### 面向对象

加行：新写 `class Mult < Exp`，实现 `eval`、`toString`、`hasZero`。旧 class 不动。`Add#eval` 对子表达式发 `eval`，子表达式现在可以是 `Mult` 的实例。dynamic dispatch 让旧代码调用新代码。

加列：回到 `Int`、`Add`、`Negate`，各加一个 `noNegConstants`。`Int` 的有趣分支是：`i < 0` 时返回 `Negate.new(Int.new(-i))`，否则返回 `self`。

Java（可选）里，若 superclass 增加“人人都要有 `noNegConstants`”，没实现的子类过不了编译。这和 ML 的非穷尽匹配是同一种帮助，只是待办清单出现在行上而不是列上。

Source: Section 9 — Adding Operations or Variants / 1:50–6:35。

## 预先规划：两边都有笨办法

`[Course]` 只给了草图，说喜欢这些风格的人会说“我有办法”。不要把草图当成可以交作业的模式。

函数式，若你知道以后会有新变体：datatype 和每个函数都留一个 `other`，类型是某个 `'a`。调用者以后实例化这一种新可能，并且给每个操作传入“遇到 other 怎么办”的高阶函数。所有列都要预先留这个口。

面向对象，若你知道以后会有新操作：每个 class 预先准备接受 visitor 的方法。想加操作的人定义一个 visitor。所有行都要预先留这个口。这个惯用法叫 Visitor Pattern。老师没有展开 visitor 的方法怎么命名、怎么回调。

`[Supplement]` 常见的 visitor 实现就是 double dispatch：元素的 `accept` 按元素的 class 分派，然后回调 `visitor.visit_int(self)`，再按 visitor 的 class 分派。课程把 visitor 和 double dispatch 放在相邻的主题里，但没有把这句话说出来。需要二元操作的作业用的是 double dispatch，不是 visitor。不要在作业里混用两套名字，除非作业文本这么要求。

Source: Section 9 — Adding Operations or Variants / 6:57–8:27。

## 现代语言想两头都要

`[Course]` Scala（字幕听成了 scholar）试图把两种扩展都支持好。老师给它记一笔，同时说问题本质上很难，设计交换很细，课上不展开。

`[Modern Connection]` 后来常被拿来讨论同一问题的还有：

| 机制 | 更靠近哪一边 | 注意 |
| --- | --- | --- |
| ML / Haskell 模式匹配 | 加操作容易 | 加变体要改旧函数，除非用其他扩展机制 |
| 经典 OOP | 加变体容易 | 加操作要改旧类或用 visitor |
| Visitor | 在 OOP 里补“加操作” | 要预先在每个类留 `accept`；新变体又要改所有 visitor |
| Multimethods | 操作可以写在类外面，按多个参数分派 | Ruby 没有。见 `11` |
| Haskell type class / Rust trait | 操作按类型分开定义，可以在类型定义之后加 | 不是本课内容。和“加一列”更像，和 subclass 不是一回事 |
| Scala 的某些组合（trait、family polymorphism 等） | 老师点名说它在尝试两边 | 课上没有代码，不要凭记忆声称某段 Scala 就是课程例子 |

这些行里除了 visitor 的名字和 Scala 的点名，都是 `[Modern Connection]`，不是 `[Course]`。

## 可扩展不是免费的，有时还不该要

`[Course]` 预测会失败。你可能两种扩展都要，于是其中一种会别扭。即便变体和操作都解决了，软件还有别的长法，不可能全部预留。

更重要的是：预留扩展让推理变难。在 `Mult` 出现之前，你看 `Int`、`Add`、`Negate` 就知道 `eval` 的全部行为。一旦设计允许别的 class 也有 `eval`，你必须在脑子里留一个位置：也许还有一个类，它的 `eval` 会把这三个类的假设打破。

所以语言提供**禁止**扩展的构造：

- ML：把 datatype 藏进 module。模块外不能给它加操作。这里老师说的是“不想要更多操作时藏起来”。`[Course]` 原文是：若不希望有更多 over your data type 的操作，就藏进模块，模块外的代码不能添加。
- Java：`final` 禁止子类或禁止覆盖。Ruby 太动态，没有对应的停止按钮。

可扩展性有价值，也可以走过头。原代码若支持太多潜在扩展，就更难推理。

Source: Section 9 — Adding Operations or Variants / 8:30–11:05。

## 和二元方法的交界

到这里，表还是“一个变体 × 一个操作”。下一讲的加法要看**两个**值的种类。那不是再加一列那么简单，而是列的内部又出现一张 3×3 的表。函数式仍能把九格放在一个函数里。面向对象的单次 dispatch 只选行，选不了列。那是 `10` 的问题，不要在 visitor 里提前混掉。

## Concept card

### expression problem

- Problem: 能否同时让“新变体”和“新操作”都不修改旧代码，并保持静态安全？
- Definition: `[Supplement]` 这是文献里的名字。`[Course]` 的内容是：不预先规划时，两种分解各让一个方向容易、另一个方向要改旧代码；预先规划的口子存在，但要在所有行或所有列上先留，并且伤害局部推理。
- Mental model: 二维表没有一种线性源码布局能让两个方向都局部。
- Example: `Mult` 对 OOP 局部，对 ML 是三处非穷尽匹配。`noNegConstants` 相反。
- Why it matters: 它把“FP 还是 OOP”从信仰变成对未来修改方向的赌注。
- Misunderstanding: 不是“OOP 不能加操作”。是默认布局下加操作不局部。Visitor 是预留后的补丁，不是免费的第三种布局。
- Related: functional decomposition, OO decomposition, visitor, double dispatch, final, ML module。
