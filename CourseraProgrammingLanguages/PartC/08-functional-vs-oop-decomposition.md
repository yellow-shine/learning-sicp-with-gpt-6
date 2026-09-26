# Module 8 — 函数式分解与面向对象分解

## Problem

一个小表达式语言有不同种类的数据，也有不同的操作。无论你用什么语言，每个格子的行为都得有人写。问题不是“格子写不写得出”，而是**代码按什么方向摆**，以及以后往哪个方向长会比较疼。

这是课程自己称为 punch line 的地方。它只有在你既精确地学过 FP、又精确地学过 OOP 之后才看得见。

Source: Section 9 — OOP vs Functional Decomposition / 0:18–1:11，10:27–10:39。

## 同一张表

变体是行，操作是列。课堂的第一张表：

|  | eval | toString | hasZero |
| --- | --- | --- | --- |
| Int |  |  |  |
| Negate |  |  |  |
| Add |  |  |  |

`hasZero` 不求值，只在语法里找常量 0。每个格子都要有定义：整数怎么变成字符串，加法表达式怎么求值，等等。

`[Course]` 老师的幻灯片把**行**画成数据种类、**列**画成操作。笔记沿用这个方向。有些人口头说“FP 按行”，那是他们把表转置了。以这一课为准：FP 按列，OOP 按行。

Source: Section 9 — OOP vs Functional Decomposition / 1:39–3:17。

## 函数式：按列

先用 datatype 说出有哪些行。再为每一列写一个函数。函数里用 case，每个分支是这一列的一个格子。

```sml
datatype exp =
    Int of int
  | Negate of exp
  | Add of exp * exp

fun add_values (Int i, Int j) = Int (i + j)
  | add_values _ = raise Bad

fun eval e =
  case e of
      Int i => e                 (* 或 Int i，课堂说返回该表达式 *)
    | Negate e1 =>
        let val Int i = eval e1  (* 静态类型要处理“不是 Int” *)
        in Int (~ i) end
    | Add (e1, e2) => add_values (eval e1, eval e2)

fun toString e = (* Int / Negate / Add 各一枝 *)
fun hasZero e = (* 同样三枝 *)
```

上面是根据口述重建的骨架，不是幻灯片原文。老师把加法的“两个值怎么加”放进 `add_values`，为的是下一讲把它扩成 3×3 的格子。`Negate` 的 eval 在 ML 里必须处理子表达式求值结果不是 `Int` 的情况，所以有异常。这是静态类型的问题，不是分解方向的问题。

多个格子若实现相同，可以用通配模式。但那样以后加变体时，类型检查器不会提醒你这个函数漏了新情况。

Source: Section 9 — OOP vs Functional Decomposition / 3:19–5:31。

## 面向对象：按行

一个 class 一行。Ruby 里甚至可以不写 superclass `Exp`，三个 class 互不继承也能工作。老师仍写了 `Exp`，以及一个 `Value`，因为作业会类似，尽管对这个小例子是多余的。

```ruby
class Int < Value
  attr_reader :i
  def initialize(i); @i = i; end
  def eval; self; end          # 值求值到自己，整个对象
  def toString; i.to_s; end
  def hasZero; i == 0; end
end

class Negate < Exp
  attr_reader :e
  def eval
    Int.new(-e.eval.i)         # 动态类型：直接 .i，不写 ML 那个异常分支
  end
  # toString, hasZero：hasZero 就是 e.hasZero
end

class Add < Exp
  attr_reader :e1, :e2
  def eval
    Int.new(e1.eval.i + e2.eval.i)
  end
end
```

`Int#eval` 返回 `self`，对应 ML 里 `Int` 分支返回整个表达式。`Add#eval` 对子表达式发 `eval` 消息，而不是外部 `case`。格子还是那九个，只是 `Int` 的三格现在相邻，而不是散落在三个函数里。

Java 版（可选）里，superclass 必须声明每个 `Exp` 都有哪些方法，否则静态检查过不了。方法体的组织仍是按行。

Source: Section 9 — OOP vs Functional Decomposition / 5:33–10:22。

## 为什么这是视角，不只是口味

把程序想成必须填满的网格之后，“用函数还是用类”就变成“先把哪一条切出来放在一个文件里”。

老师自己的口味，作为例子而不是规则：

- 写解释器：函数式更自然。我在求值一个表达式，不同种类是不同分支。
- 写 GUI：面向对象更自然。屏幕上每种图形元素是一个东西。它对点击、拖拽、颜色的反应，我想放在一起。

大型程序的联系比二维表多，任何线性的源文件都摆不全。IDE 可以补这一刀：代码按行放着，你仍可以要“所有 `hasZero`”，也就是把一列抽出来看。函数式 IDE 也可以反过来抽行。

Source: Section 9 — OOP vs Functional Decomposition / 10:40–12:47。

## 以后再加一刀

下一讲才是这张表的工程后果。先把结论放在这里，论证放在 `09`。

```text
加一列（新操作，例如 noNegConstants）
    FP：新写一个函数。旧函数不动。
    OOP：每个已有 class 都要加一个方法。

加一行（新变体，例如 Mult）
    OOP：新写一个 class。旧 class 不动。
        旧的 Add#eval 发 eval 消息时，子表达式可以是新 class。
        dynamic dispatch 让这成为可能。
    FP：datatype 多一个构造子，每个旧函数的 case 都要补。
        静态类型若当初没用通配，会列出不穷尽的匹配。
```

若你知道软件会往哪个方向长，分解方向就不只是口味。若你不知道，Yogi Berra：预测很难，尤其是关于未来。

Source: Section 9 — Adding Operations or Variants / 0:50–1:20，6:35–6:57。

## 和 dynamic dispatch 的因果关系

OOP 分解能“加一行而不改旧行”，依赖的不是 class 这个关键字，而是：旧方法向子表达式发消息，查找按 receiver 的 class 走。新 class 定义了 `eval`，旧的 `Add#eval` 不用重编译自己的方法体，就会进新代码。

FP 分解能“加一列而不改旧列”，依赖的是：操作是函数，函数是闭包，新函数不修改旧函数的代码。没有一张开放的方法表要去登记。

所以 Module 5 的语义，就是这张表能按行扩展的原因。Module 6 的“闭包是关闭的”，就是按列扩展时旧列不会被新列搅动的原因。

## Concept cards

### functional decomposition

- Problem: 一组操作要覆盖所有数据变体，怎样摆代码。
- Definition: `[Course]` 一个函数一列。datatype 列出变体。函数内的 case 填这一列的格子。
- Mental model: 先问“这个操作对每种数据做什么”。
- Example: `eval` 一个函数，三个分支。
- Misunderstanding: 不是“函数式就不能加变体”。能加，只是要改每一列，除非你预先留了扩展口。

### OO decomposition

- Problem: 同一种数据上的所有操作，怎样放在一起。
- Definition: `[Course]` 一个 class 一行。每个方法是这一行的一格。
- Mental model: 先问“这种数据会响应哪些消息”。
- Example: `class Int` 里相邻的 `eval`、`toString`、`hasZero`。
- Misunderstanding: 不是“OOP 不能加操作”。能加，只是要打开每一行。

### adding operations / adding variants

- Problem: 表会长大。哪一边不用碰旧代码？
- Definition: 见上面的两列对照。没做预先规划时，FP 白送你新操作，OOP 白送你新变体。
- Why it matters: 这是选择分解方向的工程理由，不只是审美。
- Misunderstanding: “白送”不等于另一种扩展不可能。见 `09` 的 visitor 和 other-case。它们要预先规划，而且让推理变难。
