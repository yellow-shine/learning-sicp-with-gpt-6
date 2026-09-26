# 07 — Signature 是抽象边界，不是函数声明列表

> Part A · Section 4 后半
> 视频：`08`–`18`
>
> 类型推断解释了“不写类型仍是静态的”。这一章解释另一件同样容易被看轻的事：模块系统不是把文件拆开，而是决定客户能观察什么。客户观察不到的差别，才是实现可以替换的差别。

到 Section 3 结束，程序仍是顶层一串 binding。函数内部可以用 `let` 藏一个 helper。那藏不住一整个有理数库：构造、约分、加法、打印必须互相看见，又不能让文件其余部分看见表示。

若没有这条边界，库作者只能在注释里写“请只用 `make_frac`”。注释不是类型规则。客户——包括以后的自己——会直接造出库函数假定不存在的值。一旦那种值存在，`toString` 承诺的“总是最简”就不再为真。

所以这一章的问题不是“怎么给函数加前缀”。问题是：

> 怎样让“表示是什么”成为客户无法询问的问题，从而使两个实现可以互换，而不必逐个审查未知的调用者？

---

## 1. 这一组讲要解决什么问题？

大程序有两个不同的困难，课程故意分开讲。

第一个困难是名字。两个库都想叫 `map`。若只有顶层环境，后一个 binding 遮蔽前一个。这是 namespace。它重要，但 Grossman 说它本身不有趣：`List.map` 与 `Tree.map` 只是把名字分开。分开之后，外部仍能使用模块里的每一个 binding。

第二个困难是依赖。写得正确、可复用的库需要控制客户能依赖什么。客户不应知道、更不应能够破坏某些实现决定。`let` 只能藏住一个函数体里的局部名字，藏不了一串必须互相调用的顶层 binding。

课程把模块放在类型推断之后，是因为 signature 是模块的类型。匹配规则要能说“内部类型可以比导出类型更一般”，也要能说“内部的 `int * int` 在边界上可以只叫 `rational`”。没有“类型不必字面相同”这条，抽象类型无法定义。

它依赖：顶层 binding 的顺序、shadowing、datatype 同时定义类型和构造器、Section 2 的 more-general type、Section 3 的 `ref` 与副作用。它准备的是：换到 Racket 之前，把“抽象边界”说成类型系统能执行的东西，而不是文档。Part C 的 interface / mixin 是另一套边界，不要提前当成同一个机制。

---

## Lecture — 先只把名字分开

视频：`Modules for Namespace Management`。

### 若没有 structure

程序是一串顶层 binding。`fact`、`map`、`doubler` 全在同一个环境里。第二个库若也定义 `map`，不是“两个 map 共存”，而是后一个遮蔽前一个。调用者无法指定要哪一个。给它们改名成 `listMap` / `treeMap` 能工作，但名字的选择变成了全局协议，而不是库自己的事。

### 机制

`structure` 定义一个 module。名字习惯大写开头，不强制。结构体里可以是任何 binding：datatype、exception、`val`、`fun`。它们按顺序求值，后面的可以使用前面的。这和文件顶层是同一套规则，只是环境被装进一个限定名下面。

```sml
structure MyMathLib =
struct
  fun fact x =
    if x = 0 then 1 else x * fact (x - 1)
  val half_pi = Math.pi / 2.0
  fun doubler x = 2 * x
end

val pi = MyMathLib.half_pi + MyMathLib.half_pi
val twentyEight = MyMathLib.doubler 14
```

`fact` 的函数体是按他描述的阶乘还原的，口述没有逐字给出函数体。求值不依赖函数体的具体写法，只依赖“它是结构内部的一个 binding”。

```text
Expression: structure MyMathLib = struct ... end

顶层动态环境增加的不是 fact，也不是一个叫 MyMathLib 的值。
增加的是限定名：

  MyMathLib.fact     → <函数值>
  MyMathLib.half_pi  → π/2
  MyMathLib.doubler  → <函数值>

顶层没有 fact。
MyMathLib 本身不是变量，不能当表达式使用。
不能写一个 binding 把“整个模块”取出来传来传去。

Expression: MyMathLib.doubler 14
  查找限定名 doubler → 函数
  参数 14 已是值
  Value: 28

Expression: MyMathLib.half_pi + 1
  real + int → 类型错误，不求值
```

标准库已经在用这套语法。`String.toUpper` 是 string 模块里的 `toUpper`，不是一种新的方法调用。

`open MyMathLib` 把结构里所有 binding 倒进当前环境。他不喜欢。你往往只想要 `fact`，却把 `doubler` 也开进来。若当前环境已有 `doubler`，旧绑定被遮蔽，不是被修改。REPL 里试模块时有用。不想写长前缀的更好做法是自己绑一个短名字：`val hp = MyMathLib.half_pi`。那是普通的 `val`，不是模块系统的新规则。

模块可以嵌模块。那只是 namespace 的层次。到这里为止，模块系统还没有做任何隐藏。

### 若改掉规则

- 没有 `structure`：两个 `map` 必须改名，否则后定义的遮蔽先定义的。
- 把结构名当成值：模块系统就和语言的其余部分合成一种值。ML 没有这么做。结构名不是一等的。这是模块系统与表达式语言略有不同的地方，不要用“模块也是一个 record”去脑补。

### 对照：限定名与 open

| | `Module.name` | `open Module` |
| --- | --- | --- |
| 定义 | 在模块的环境里查找一个限定名 | 把模块的全部 binding 倒进当前环境 |
| 解决的问题 | 两个库可以都有 `map`，调用处写明是哪一个 | 少写前缀 |
| 关键区别 | 当前环境的其他名字不变 | 同名 binding 被遮蔽。倒进来的通常比你要的多 |
| 典型场景 | `List.map`、`MyMathLib.fact` | REPL 里临时试验。他视为可选，不是核心 |

---

## Lecture — 名字分开之后，外部仍能用一切

视频：`Signatures and Hiding Things`。

### 若 signature 只是一份抄下来的类型清单

`MyMathLib` 里的 `doubler` 也许只是 `fact` 的实现细节。Namespace 不在乎。模块外写 `MyMathLib.doubler 3` 完全合法。注释“这是私有的”不会让类型检查器拒绝它。

函数体内部的 `let` 已经能藏名字：`double` 写成 `x * 2`、`x + x`，或 `let val y = 2 in x * y end`，调用者无法区分，也看不见 `y`。缺的是把这种“外面不存在”扩展到一串互相可见的 binding 上。

### 机制

Signature 是 module 的 type。结构叫 structure，结构的类型叫 signature。不是两个随便的英文词，是同一关系的两边：值有类型，结构有 signature。

```sml
signature MATHLIB =
sig
  val fact : int -> int
  val half_pi : real
  val doubler : int -> int
end

structure MyMathLib :> MATHLIB =
struct
  fun fact x = if x = 0 then 1 else x * fact (x - 1)
  val half_pi = Math.pi / 2.0
  fun doubler x = 2 * x
end
```

`:>` 是归属（ascription）：这个结构必须匹配这个 signature。缺了 signature 要求的 binding，或类型不合适，结构不通过类型检查。一个 signature 可以被多个结构复用。起步时可以把 REPL 对结构的打印贴进 `sig ... end`。`val fact : int -> int` 只要求有这样一个类型的 binding，不管它是 `fun` 定义的还是 `val` 定义的。

隐藏规则只有一条，而且是省略，不是关键字：

> signature 里没写的 binding，模块外不存在。模块内仍可使用。结构可以有 signature 没列出的东西。多可以，少不行，类型不对不行。

```sml
signature MATHLIB =
sig
  val fact : int -> int
  val half_pi : real
  (* doubler 被省略 *)
end

structure MyMathLib :> MATHLIB =
struct
  fun doubler x = 2 * x
  val eight = doubler 4      (* 模块内环境有 doubler，得到 8 *)
  fun fact x = if x = 0 then 1 else x * fact (x - 1)
  val half_pi = Math.pi / 2.0
end

val _ = MyMathLib.doubler 3
(* unbound: MyMathLib.doubler 不在导出的环境里 *)
```

```text
模块内：
  Expression: doubler 4
  Environment: doubler → <函数>
  Value: 8
  这个 8 可以绑给 eight。eight 若也不在 signature 里，模块外同样看不见。

模块外：
  Expression: MyMathLib.doubler 3
  静态环境里没有这个限定名
  类型检查失败，不求值
```

ML 不在每个 binding 上标 public / private。可见集写成模块的类型。他喜欢这种做法，因为它把“外部能用什么”变成类型检查，而不是定义旁边的一排修饰符。

REPL 在归属之后只报告 `MyMathLib : MATHLIB`，不再展开每个 binding 的类型。打印变短不是收益。收益是：没写进去的名字，类型环境里没有。

### 若改掉规则

- 不写 signature：外部仍能调用 `doubler`。隐藏没有发生。
- Signature 要求 `doubler : int -> int` 而结构里没有，或类型是 `real -> real`：结构不 type-check。
- 把“多出来的 binding”当成匹配失败：就无法在内部保留 helper。隐藏恰好依赖“多可以”。

到这里，signature 已经不只是文档。但它还只是在否认某些 binding 存在。下一组例子说明：否认 `gcd` 存在，挡不住客户自己造出不该存在的值。

---

## Lecture — 客户该相信什么，实现该依赖什么

视频：`A Module Example`。

后面所有讨论用同一个库：有理数。没有这个例子，就无法说明“为什么不能把表示交给客户”。

抽象数据类型（Abstract Data Type）是一个模块，它导出某种新数据的类型，以及对该类型的操作。这里的操作是构造、相加、转成 string。`3/2` 的字符串是 `"3/2"`，不是打印动作。`toString` 返回 string。是 REPL 在打印那个 string。他说 printing 是口误。

```sml
structure Rational1 =
struct
  datatype rational = Whole of int | Frac of int * int
  exception BadFrac

  (* 口述：参数为正的递归算法，欧几里得，课上不证明。函数体未逐字给出。 *)
  fun gcd (x, y) =
    if x = y then x
    else if x < y then gcd (x, y - x)
    else gcd (y, x)

  fun reduce r =
    case r of
        Whole _ => r
      | Frac (x, y) =>
        if x = 0 then Whole 0
        else
          let val d = gcd (abs x, y)   (* 调用前不变量保证 y > 0 *)
          in if d = y                  (* 口述是 “if d divides y”；
                                          与“否则仍是 Frac”一致的读法是 d = y，
                                          因为 gcd 总整除 y。抽取按此还原。 *)
             then Whole (x div d)
             else Frac (x div d, y div d)
          end

  fun make_frac (x, y) =
    if y = 0 then raise BadFrac
    else if y < 0 then reduce (Frac (~x, ~y))
    else reduce (Frac (x, y))

  fun add (r1, r2) =
    case (r1, r2) of
        (Whole i, Whole j) => Whole (i + j)
      | (Whole i, Frac (j, k)) => Frac (j + k * i, k)
      | (Frac (j, k), Whole i) => Frac (j + k * i, k)
      | (Frac (a, b), Frac (c, d)) =>
        reduce (Frac (a * d + b * c, b * d))

  fun toString r =
    case r of
        Whole i => Int.toString i
      | Frac (a, b) => Int.toString a ^ "/" ^ Int.toString b
end
```

`Whole` 与 `Whole` 相加、以及对称的那一支，是按他描述的分支还原的。算术是小学内容，不是这讲的重点。重点是哪些函数安装不变量，哪些函数依赖不变量。

### Properties：客户被允许关心的全部

这些保证不写在 `add` 或 `toString` 的类型里。类型只说“两个 rational 进去，一个 rational 出来”。

- 不允许分母为 0。试图构造则 `raise BadFrac`。客户通过库得到的 rational 永远没有零分母。
- 返回的 string 总是最简：`"4"` 不是 `"4/1"`，`"3/2"` 不是 `"9/6"`。
- 除了分母为 0，函数终止、不 raise、答案正确。

这不是一份完整规格。它是他要类型系统帮忙守住的那一部分。

### Invariants：实现内部的合同，客户不应看见

- 所有分母为正。客户可以传入 `(~8, ~2)`。库交回去的值没有负分母。
- 所有 rational 值已经约分。库从不把 `9/6` 留在值里，立刻变成 `3/2`。

函数既维持不变量，又依赖它们。一处破坏，另一处会算错。

- `make_frac` 拒绝 0，把负分母翻成正分母并给分子变号，然后立刻 `reduce`。
- `add` 假定参数已约分，所以 `Whole` 加 `Frac` 可以不再 `reduce`。两个 `Frac` 相加必须 `reduce`，否则不变量在这里断掉。
- `gcd` 只在参数非负时正确，所以只能在不变量已经保证这一点时调用。
- `toString` 不检查、不调用 `reduce`。它承诺最简字符串，靠的是其余函数已经维持不变量。

```text
Expression: make_frac (9, 6)
  y > 0 → reduce (Frac (9, 6))
  gcd(9, 6) = 3，3 ≠ 6
  Value: Frac (3, 2)

Expression: make_frac (~8, ~2)
  y < 0 → reduce (Frac (8, 2))
  d = 2 = y
  Value: Whole 4

Expression: toString (add (Frac (3, 2), Whole 4))
  Whole+Frac 分支不 reduce，但 3+2*4 = 11，分母仍是 2
  toString 信任这一点
  Value: "11/2"
```

没有 signature 时，REPL 会暴露 `rational` 的构造器。客户可以不走 `make_frac`。那是下一讲的裂缝。

### 对照：Properties 与 Invariants

| | Properties | Invariants |
| --- | --- | --- |
| 定义 | 客户可以观察到、库必须保持的行为保证 | 实现内部函数之间的约定 |
| 解决的问题 | 客户知道可以依赖什么 | 让每个函数不必重复检查全部条件 |
| 关键区别 | 类型往往写不出它们（“字符串已约分”不是 `string` 能说的） | 客户既不应依赖它们，也不应能够破坏它们 |
| 典型场景 | 无零分母；`toString` 最简 | 分母为正；值已经约分；`gcd` 只见非负参数 |

类型能说的是 `add : rational * rational -> rational`。类型不能说的是“没有零分母”。把后者也做成类型系统能执行的东西，靠的不是把 properties 写进注释，而是让客户无法构造出违反 invariants 的值。

---

## Lecture — 藏住 helper，藏不住表示

视频：`Signatures for Our Example`。

### 若只省略 `gcd` 和 `reduce`

下面这份 signature 他称为 rational A。结构能通过类型检查。外部不能调用 `gcd` 或 `reduce`。看起来像 ADT。它不是。

```sml
signature RATIONAL_A =
sig
  datatype rational = Whole of int | Frac of int * int
  exception BadFrac
  val make_frac : int * int -> rational
  val add : rational * rational -> rational
  val toString : rational -> string
end
```

公开 datatype，就是公开构造器。客户可以写 `Frac (1, 0)`、`Frac (3, ~2)`、`Frac (9, 6)`。这些值是库函数假定不存在的。注释“请只用 `make_frac`”不可靠。他承认自己作为库客户也不总遵守文档。

具体破坏，都来自绕过 `make_frac`：

| 客户做的事 | 发生什么 |
| --- | --- |
| `make_frac (1, 0)` 再拿去 `add` | `BadFrac`。这条路是对的 |
| 直接 `Frac (1, 0)` 再进入使用 `gcd` 的路径 | 不终止。他猜测与 `gcd` 有关。不要去修这个路径，要让这条路径不存在 |
| 负分母进入假定分母为正的算术 | 溢出 |
| `toString (Frac (9, 6))` | `"9/6"`。`toString` 不约分，它假定参数已约分 |

### 机制：抽象类型

只把 datatype 定义从 signature 里删掉、继续写 `rational`，类型检查器会说没听说过这个类型，并怀疑拼写错误。这是对的。不能凭空造类型名。

抽象类型（abstract type）是有意的“知道有这个类型，不知道它怎么定义”：

```sml
signature RATIONAL_B =
sig
  type rational
  exception BadFrac
  val make_frac : int * int -> rational
  val add : rational * rational -> rational
  val toString : rational -> string
end

structure Rational1 :> RATIONAL_B =
struct
  (* 上一讲的实现。datatype 定义了类型 rational，匹配抽象类型是合法的 *)
end
```

`type rational` 没有 `=`，没有构造器。类型存在。外部不知道定义。客户没有任何办法造出第一个 rational，除非调用 `make_frac`。还没有 rational，就不能 `add` 或 `toString`。

因此可以分段检查，而不是审查全世界的客户：

1. 检查 `make_frac`：无零分母、无负分母、已约分。客户得到的每一个值都从这里出来。
2. 检查 `add`：假定输入满足不变量，输出也满足。
3. 检查 `toString`：假定输入满足不变量，字符串是承诺的那种。

客户可以把 rational 放进 list、tuple、传给别的函数。唯一能碰到内部片段的操作是库提供的那些。这就是表示隐藏（representation hiding）。

两种隐藏，他希望分开记：

1. 否认 binding 存在。不写进 signature 的 `val`、`fun`、构造器，对客户就不存在。
2. 更强：告诉客户“有这个类型”，但不告诉定义。这样 `make_frac` 可以返回 `rational`，而不揭示 `rational` 是 `Whole` 还是 `Frac` 还是别的。

还有一份他称为有点 cute 的 `RATIONAL_C`。暴露 `Whole : int -> rational` 是安全的：任何 `int` 包进 `Whole` 都不破坏这份库的 properties 和 invariants。暴露 `Frac` 则不行。

```sml
signature RATIONAL_C =
sig
  type rational
  exception BadFrac
  val Whole : int -> rational
  val make_frac : int * int -> rational
  val add : rational * rational -> rational
  val toString : rational -> string
end
```

Datatype 绑定实际定义了多件东西：类型 `rational`；函数 `Whole : int -> rational`；函数 `Frac : int * int -> rational`；以及 pattern 里可用的这两个构造器。Signature 可以选择只暴露其中一部分。结构对 `RATIONAL_C` 能通过，因为 datatype 提供了 `Whole` 这个函数。客户可以 `Whole n`，不必 `make_frac (n, 1)`。这是 ML 的特性，不是最重要的语言特征。它说明 signature 是一份选择过的可见集，不是实现的复印件。

```text
RATIONAL_A 下：
  Expression: toString (Frac (9, 6))
  构造器在导出环境里
  toString 不 reduce
  Value: "9/6"          ← property 已假

RATIONAL_B 下：
  Expression: Rational1.Frac (9, 6)
  构造器不在导出环境
  类型检查失败，无 value

  Expression: toString (make_frac (9, 6))
  只能走 make_frac
  Value: "3/2"
```

### 若改掉规则

- 把 `type rational` 换成公开的 datatype：回到 A。不变量可被客户破坏。
- 把 `Whole` 也藏起来（B）：仍然正确，只是少一条无害的构造途径。
- 允许客户对 `Frac` 做 pattern match：表示同样泄漏。能拆开，就能依赖字段顺序和构造器名字。

### 对照：省略 binding 与抽象类型

| | 省略 binding | 抽象类型 `type t` |
| --- | --- | --- |
| 定义 | signature 不列出某个名字，外部没有这个名字 | 外部知道类型存在，不知道它的定义 |
| 解决的问题 | 藏 helper、藏不该调用的函数 | 藏表示，使“必须经过你的构造函数”成为类型规则 |
| 关键区别 | 挡的是名字。公开的构造器仍是一条路 | 挡的是造值和拆值。客户拿着 `t`，但造不出违反不变量的 `t` |
| 典型场景 | 不导出 `gcd`、`reduce`、`doubler` | `RATIONAL_B` 的 `rational` |

藏起 `gcd` 不等于实现了 ADT。构造器仍是绕过不变量的路。

---

## Lecture — 匹配不是“类型字符串相同”

视频：`Signature Matching`。

“结构必须有 signature 说的一切”太模糊，类型检查器无法执行。精确规则是：遍历 signature 的每一项，检查结构是否以合适方式提供。结构多出来的 binding 没问题。这条不必另写，它是“只检查 signature 里有的项”的推论。

- Signature 给出完整类型定义（datatype，或 type synonym，不是抽象类型）：结构必须提供该定义，构造器齐全。
- Signature 只有抽象类型：结构只要定义了这个类型。Datatype 可以。Type synonym 也可以。后者是 `Rational3` 能存在的原因。
- Signature 有 `val`：结构必须提供该名字，`val` 或 `fun` 均可。类型必须合适，不必相同。合适的方向是：告诉客户更少、更受限的用法，但告诉客户的每一条都必须为真。
  - 内部可以更一般。`'a -> 'a` 可以导出成 `string -> string`，因为后者是前者的一个实例。客户按 `string -> string` 使用是安全的。
  - 内部可以更具体，边界上是抽象的。模块里 `rational = int * int`，signature 里只写 `type rational`。
- Signature 声明某 exception：结构必须声明该 exception。

```sml
(* 结构内部 *)
val id = fn x => x          (* 'a -> 'a *)

(* signature 里这样写，匹配合法 *)
(* val id : string -> string *)
```

这是类型检查，不产生运行时的值。若要求内外类型文本相等，就不能把多态实现收成单态导出，也不能把 `int * int` 导出成抽象的 `rational`。抽象边界依赖的就是“不必相等”。

---

## Lecture — 暴露得越少，两个实现越可能是同一个库

视频：`An Equivalent Structure`，`Another Equivalent Structure`。

抽象的目的之一是替换。更快的实现、多一个不影响旧行为的操作、或推迟选择表示，都不该要求审查未知客户。定义先放在这里，精确清单在后面：没有客户能分辨用的是哪一个实现，两个结构就等价（equivalent）。

揭示得越少，等价越可能。揭示得越多，越不可能。能匹配同一个 signature，不等于等价。还要看这个 signature 暴露了什么。

### Rational2：同一 datatype，不同的维护时机

`Rational1` 在构造时约分，`toString` 不约分。`Rational2` 反过来：`make_frac` 和 `add` 不约分，只有 `toString` 在返回字符串之前 `reduce`。因此 `gcd` 和 `reduce` 可以是 `toString` 的局部 helper，不必是模块级 binding。

```sml
structure Rational2 =
struct
  datatype rational = Whole of int | Frac of int * int
  exception BadFrac

  fun make_frac (x, y) =
    if y = 0 then raise BadFrac
    else if y < 0 then Frac (~x, ~y)
    else Frac (x, y)

  fun add (r1, r2) =
    case (r1, r2) of
        (Whole i, Whole j) => Whole (i + j)
      | (Whole i, Frac (j, k)) => Frac (j + k * i, k)
      | (Frac (j, k), Whole i) => Frac (j + k * i, k)
      | (Frac (a, b), Frac (c, d)) =>
        Frac (a * d + b * c, b * d)
        (* 2/3 + 1/3 得到 9/9，留着不约 *)

  fun toString r =
    let
      fun gcd (x, y) = (* 与 Rational1 同一算法；函数体未逐字给出 *) x
      fun reduce r = (* 与 Rational1.reduce 同一算法 *) r
    in
      case reduce r of
          Whole i => Int.toString i
        | Frac (a, b) => Int.toString a ^ "/" ^ Int.toString b
    end
end
```

它仍满足那份规格：不允许分母 0；返回的 string 总是最简。它能匹配 A、B、C。有 A 的一切就有 B 的一切。C 还要 `Whole : int -> rational`，同一个 datatype 提供了它。

在 `RATIONAL_A` 下，它与 `Rational1` **不等价**。A 允许客户直接用 `Frac`。

```text
Expression: Rational1.toString (Rational1.Frac (9, 6))
  toString 不 reduce
  Value: "9/6"

Expression: Rational2.toString (Rational2.Frac (9, 6))
  toString 先 reduce
  Value: "3/2"
```

同一调用形状，不同答案。不能随意替换。

在 `RATIONAL_B` 或 `RATIONAL_C` 下等价。客户没有 `Frac`。`make_frac (9, 6)` 在 1 的内部是 `Frac (3, 2)`，在 2 的内部是 `Frac (9, 6)`。客户能做的观察只有 `toString` 和 `add` 的结果。那些结果相同。内部多出来的未约分表示不是观察。

即使 `Rational2.toString` 会约分，也不能因此暴露 `Frac`。零分母和负分母仍在。`Rational2` 只是偶然把“未约分”这一条在打印时补上了。另外两条破坏照旧。

### Rational3：类型本身换掉

若抽象类型只允许“同一个 datatype 的不同维护策略”，抽象还不够强。`RATIONAL_B` 只要求类型存在。另一个结构可以用完全不同的表示，并且仍然等价。

```sml
structure Rational3 :> RATIONAL_B =
struct
  type rational = int * int
  exception BadFrac

  fun make_frac (x, y) =
    if y = 0 then raise BadFrac
    else if y < 0 then (~x, ~y)
    else (x, y)

  fun add ((a, b), (c, d)) =
    (a * d + c * b, b * d)

  fun toString (x, y) =
    if x = 0 then "0"
    else
      let
        fun gcd (p, q) = p     (* 函数体未逐字给出；契约仍是非负参数上的 gcd *)
        val d = gcd (abs x, y)
        val num = x div d
        val den = y div d
      in
        Int.toString num ^
        (if den = 1 then "" else "/" ^ Int.toString den)
      end
end
```

没有 `Whole` / `Frac`。原来的整数也是一对 int，分母为 1 并不特殊存储。`gcd` 的函数体同样未逐字给出。匹配和等价不依赖那几行算术，依赖的是：零分母被拒绝，字符串在边界上被约成承诺的形式。

- 不匹配 `RATIONAL_A`。A 要求那个 datatype。类型检查器拒绝。
- 匹配 `RATIONAL_B`。Type synonym 是抽象类型的合法实现。模块内把 `rational` 当 `int * int`。外部不知道二者相等。
- 要匹配 `RATIONAL_C`，没有 datatype 自动提供 `Whole`，就自己写。函数可以以大写字母开头：

```sml
fun Whole i = (i, 1)
(* 模块内推断：'a -> 'a * int
   归属之后：int -> rational *)
```

两个匹配细节值得单独看，因为它们就是“类型不必字面相同”。

第一，模块内 `make_frac : int * int -> int * int`，导出 `int * int -> rational` 合法，因为模块内 `rational = int * int`。客户看不出参数类型和结果类型是同一个。若把 signature 改成：

```sml
signature RATIONAL_USELESS =
sig
  type rational
  val make_frac : rational -> rational
  val add : rational * rational -> rational
  val toString : rational -> string
end
```

结构能匹配。类型检查器接受。结构无用：客户永远得不到第一个 rational，三个函数都调不了。能 type-check 的 signature 不是好 API。必须导出一条从 `int` 进入 `rational` 的路，客户才启动得了。

第二，`Whole` 在模块内是 `'a -> 'a * int`。`RATIONAL_C` 要 `int -> rational`。匹配允许把多态类型实例化成非多态类型：所有 `'a` 一致换成 `int`，得到 `int -> int * int`，再因模块内 `rational = int * int`，看成 `int -> rational`。不能只替换一部分 `'a`。它不是 `'a -> int * int`，也不是 `int -> 'a * int`。传 string 不会得到 `int * int`。模块内部可以 `Whole "..."`，因为内部的 `'a` 还在。模块外部 signature 只允许 `int`，返回的是抽象的 rational。

在 B 或 C 下，`Rational3` 与前两个结构等价，尽管类型的实现完全不同。

```text
Expression: Rational3.make_frac (9, 6)
  模块内 Value: (9, 6)
  模块外的类型: Rational3.rational
  不是 int * int。客户不能把这个值的第一分量取出来。

Expression: Rational3.toString (那个值)
  约分发生在 toString 内部
  Value: "3/2"
```

### 边界长什么样

```text
Client
   │  只能写 signature 列出的名字
   │  只能看见 signature 给出的类型
   ▼
Signature          ← 抽象边界（abstraction boundary）
   │  匹配：每一项都有，类型可以更一般或在边界上变抽象
   ▼
Structure / Module
   │  内部环境有 helper、构造器、真正的表示
   ▼
Implementation     ← invariants 在这里安装，也在这里被依赖
```

Signature 不是“函数声明列表”。声明列表可以是文档，文档挡不住 `Frac (9, 6)`。Signature 是客户的整个静态环境里，这个模块被允许贡献的全部。没出现在里面的，不是私有，是不存在。

---

## Lecture — 同签名不是同类型

视频：`Different Modules Define Different Types`。

多个结构可以有同一个 signature，signature 可以含抽象类型。常见误解：那它们的 `rational` 就是同一个类型，可以混用。

若允许混用，抽象会被打破。即使两个结构内部表示碰巧相同，也要打破。

每个结构实现该 signature 时，引入的是一个新类型，与其他结构的类型不同。三个结构都归属 `RATIONAL_C` 时，各自使用是可以的。等价结构给出相同结果：

```sml
val s1 = Rational1.toString (Rational1.make_frac (9, ~6))
(* "~3/2" *)

val s3 = Rational3.toString (Rational3.make_frac (9, ~6))
(* 同样 "~3/2"。等价。 *)

val bad = Rational3.toString (Rational1.make_frac (9, ~6))
(* 不 type-check。否则是把 datatype 值传到期待 int * int 的地方 *)

val bad2 = Rational1.toString (Rational2.make_frac (9, ~6))
(* 也不 type-check。
   两者的 datatype 形状相同也没用。
   若放行：Rational2 不约分，Rational1.toString 不约分，
   会得到 "~9/6"，不是承诺的字符串。 *)
```

```text
同结构：
  make_frac 安装这个实现的不变量
  toString 按这个实现观察
  Value: "~3/2"

跨结构：
  Rational1.rational ≠ Rational2.rational ≠ Rational3.rational
  尽管三者都“有 signature RATIONAL_C”
  类型检查失败，无 evaluation，无 value
```

`Rational1.toString : Rational1.rational -> string`。`Rational2.toString : Rational2.rational -> string`。类型系统不知道这两个抽象类型是否相同。它们可以不同。不允许混淆。

同一 signature 不是同一类型。每个库只接受自己造出的值，因为另一个库可能执行不同的 properties 或 invariants。等价说的是整模块替换之后，客户观察不变。不是把两个模块的操作拆开混搭。

内部表示相同就应该是同一类型，这个想法会让隐藏表示失去意义。类型身份按结构划分，不按表示划分。

### 若改掉规则

若同一 signature 的抽象类型被当成同一类型：`Rational2.make_frac` 的结果可以传给 `Rational1.toString`，类型通过，打印未约分字符串。两套不变量互相踩踏。替换实现必须换整个模块，不是按函数挑拣。

---

## Lecture — “看不出来”是一份清单，不是一种感觉

视频：`Equivalent Functions`，`Standard Equivalences`。

维护、向后兼容、优化、替换模块，问的是同一件事：换掉之后，有没有人能看出来？库可能放到网上。调用者未知。不是只对你见过的客户。

没有新的语言构造。这是前面三个 rational 结构为什么能互换的一般定义。

### 可观察行为

两个函数等价，当且仅当对所有可能的调用，可观察行为（observable behavior）全部相同：

1. 总是返回相同答案。一个对 3 返回 7，另一个返回 8，不行。
2. 相同的不终止。一个对 9 不终止，另一个也必须对 9 不终止。
3. 在所有相同参数上终止。
4. 对其他程序能看见的 mutable reference 的效果相同。调用结束后，别的代码不能因替换而看到不同的 reference 值。
5. 相同的输入/输出。一个打印、另一个不打印同样的东西，不行。
6. 相同的异常。一个 raise、另一个在同样情况下不 raise，不行。

他承认可能漏了项。这份清单已经够用。同一输入总得到同一输出，不够。

调用点越少，等价越容易证明。静态类型保证只接受 `string * string` 之类，就不必考虑“若有人传入 int”。那种调用不会 type-check。这是类型系统对等价的帮助，不是等价的定义本身。

副作用越少，等价越多。调用次数和调用顺序，只在它们能被看见时才是差别。

```sml
val y = 2
fun f x = x + x
fun f x = y * x
(* 等价：都是加倍，总终止，无效果 *)
```

```sml
val y = 2
fun g (f, x) = (f x) + (f x)
fun g (f, x) = y * (f x)
(* 若 f 纯、且相同参数总返回相同值：结果相同
   若 f 有副作用：左边调用两次，右边一次。不等价 *)

fun printHi x = (print "hi"; x)
(* g (printHi, 3)：左边输出 "hihi"，右边 "hi" *)
```

```text
设 f 每次把某个 ref 加 1。

左边 g：
  调用 f 两次
  调用结束后，别的代码看见 ref 多了 2

右边 g：
  调用 f 一次
  ref 多了 1

返回的 int 可能相同。ref 的内容不同。客户能分辨。
```

Haskell 被他点名，是因为纯函数式语言里，能传给其他函数的大多数函数不能 `print`。对应的两个 `g` 在那里等价。这是概念对照，不是说 ML 的 `g` 因此也等价。ML 允许副作用，所以这两个 `g` 不等价。

```sml
fun f x = (g x, h x)
fun f x = (h x, g x)
```

两边都调用 `g` 一次、`h` 一次。没有次数问题。顺序仍可观察。

- `g` 和 `h` 纯：等价。不必关心顺序。
- 它们打印：输出顺序不同，不等价。
- `g` 写一个 ref，`h` 读它：左边 `h` 看见新值，右边 `h` 先跑，看见旧值。不等价。
- 两者都 raise，且异常不同：左边和右边 raise 的不是同一个。不等价。

避免副作用的又一好处在这里：纯函数风格下，这两种顺序都可。有 mutation 或打印，就必须关心顺序。

### 五条语言故意维持的等价

这些不是 ML 专有的。任何有变量和函数的语言都应让它们成立。理解它们在哪里失败，就是在基本层面上理解变量和函数。

**1. Syntactic sugar 按定义等价。** `e1 andalso e2` 是 `if e1 then e2 else false` 的 sugar。实现可以只实现 `if`。反过来把右边写成左边，是好风格。

```sml
fun f x = x andalso g x
fun f x = if x then g x else false
```

总是先调用 `g x` 的版本不等价。Sugar 成立的前提是短路方向不变：先求 `x`，仅当 `x` 为 true 才求 `g x`。口述里有一处把方向说成了 false。按 `andalso` 的定义，是 true 才继续。

**2. 参数改名应当不可观察。** 清理别人代码时改参数名，调用者不能因此看出变化。失败条件是改出来的名字撞上已有的绑定，从而制造原先没有的 shadowing。

```sml
val y = 14
fun f x = x + y + x          (* 2 * 参数 + 14 *)
fun f z = z + y + z          (* 等价的改名 *)

fun f y = y + y + y          (* 不等价。参数遮住了外层的 y，变成参数的 3 倍 *)

fun f x = let val y = 3 in x + y end   (* 参数 + 3 *)
fun f y = let val y = 3 in y + y end   (* 总是 6。参数被局部 y 遮住 *)
```

```text
左边 f 10：
  参数 x → 10
  let 扩展 y → 3
  Value: 13

右边把参数改名为 y 之后 f 10：
  参数 y → 10
  let 再绑定 y → 3，遮住参数
  函数体里两个 y 都是 3
  Value: 6
```

系统地把形参名字替换成任何别的名字，不保持等价。不能撞上自由变量，也不能撞上局部变量。

**3. 是否使用 helper 应当不可观察。** 把函数体的一部分抽成正确使用的 helper，调用者不能分辨。失败条件是 helper 的自由变量按它的定义位置解析，而不是按你心里那个调用点解析。这是词法作用域（lexical scope），不是新规则。

```sml
val y = 14
fun g x = 3 * x + 14
fun g x = let fun f z = z + y + z in f x end
(* y 仍是外层的 14 时，两边都是 3 * 参数 + 14。helper 体是按这个计算还原的。 *)

fun g x = let val y = 7 in 3 * x + y end          (* 3 * 参数 + 7 *)
fun g x =
  let
    fun f z = z + y + z    (* 这个 y 不是上一行的 y *)
  in f x end
(* f 的自由变量 y 解析到外层的 14。REPL 里两个 g 不同。 *)
```

抽出 helper 不自动保持语义。自由变量的环境是定义 helper 时的环境。局部 `val y = 7` 若写在 helper 之后，或写在另一个 `let` 里，helper 看不见它。

**4. Unnecessary function wrapping。** 被调用的是变量 `f` 时，`fun g y = f y` 与 `val g = f` 等价。两者都是单参数函数，返回 `f` 的函数体会返回的东西。

```sml
fun f x = 2 * x
fun g y = f y
val g = f                 (* 等价 *)

fun h () = (print "hi"; f)
fun g y = h () y          (* 每次调用 g 都打印 *)
val g = h ()              (* 绑定 g 时打印一次，以后不再打印 *)
```

```text
左边，调用 g 3 两次：
  每次都求 h ()
  打印 "hi"，得到 f，再 f 3 → 6
  两次调用，打印两次

右边：
  求 val g = h () 时打印一次
  环境里 g 与 f 是同一个函数值
  之后 g 3 不再打印，Value 6

两边都加倍。打印的次数和时机不同。不等价。
```

若要先求值一个表达式才得到函数，wrapping 与否影响该表达式执行几次。有 `print` 或写 `ref` 时，不要删掉那层包装，也不要随意加上。

**5. `let` 与函数应用是同一求值序列。**

```sml
let val x = e1 in e2 end
(* 与下面求值步骤相同 *)
(fn x => e2) e1
```

左边：求 `e1` 到值，扩展环境使 `x` 映射到该值，求 `e2`。右边：`fn x => e2` 已是 value；求 `e1` 到值；在 `x` 绑定到该值的环境里求 `e2`。步骤相同。可以看成互为 syntactic sugar。

ML 的类型系统有一处差别：左边可以给 `x` polymorphic type；右边永远不给 `x` polymorphic type。存在左边 type-check、右边不 type-check 的程序。两者都 type-check 时，总是产生相同结果。这和 value restriction 是同一家族的事实：函数应用的结果不当成 polymorphic value。求值等价，多态性不等价。

### 对照：返回值相同，与可观察行为相同

| | 只看返回值 | 可观察行为 |
| --- | --- | --- |
| 定义 | 相同参数得到相同结果 | 结果、终止、异常、I/O、可见的 reference 更新、参数函数被调用的次数和顺序都相同 |
| 解决的问题 | 判断纯计算是否算对 | 判断能否在未知客户面前替换实现 |
| 关键区别 | `g` 的两个版本对纯 `f` 返回值相同 | 一旦 `f` 打印或改 ref，调用两次和调用一次就被看见 |
| 典型场景 | `x + x` 与 `2 * x` | 模块替换、删掉 unnecessary wrapping、交换 `g` 和 `h` 的顺序 |

---

## Lecture — 等价故意不谈快慢

视频：`Equivalence versus Performance`。

上一讲的定义不谈性能。从编程语言的视角，这是定义本身。既是优点，也是限制。

Section 1 讲 `let` 的效率时，还没有 pattern matching。代码长得不完全像下面，想法相同。左边的 list max 对某些 list 指数慢。长度 50 可以花几个世纪。右边总是与长度成正比。

```sml
fun bad_max xs =
  if null xs then raise List.Empty
  else if null (tl xs) then hd xs
  else if hd xs > bad_max (tl xs)
  then hd xs
  else bad_max (tl xs)

fun good_max xs =
  if null xs then raise List.Empty
  else if null (tl xs) then hd xs
  else
    let val y = good_max (tl xs)
    in if hd xs > y then hd xs else y
    end
```

空表分支他没有在这讲逐字重述。`List.Empty` 是与 `hd []` 同一类的失败。Pattern matching 版是同一想法，不是当时幻灯片上的代码：

```sml
fun good_max xs =
  case xs of
      [] => raise List.Empty
    | x :: [] => x
    | x :: xs' =>
      let val y = good_max xs'
      in if x > y then x else y end
```

```text
bad_max 在长 list 上：
  对同一个 tl 求值两次
  每次再分裂
  调用次数关于长度指数增长

good_max：
  Expression: let val y = good_max xs' in ...
  Environment 扩展 y → <递归结果>
  比较一次
  Value: 较大者
```

按定义，两者等价：相同副作用（都没有）、相同终止行为（左边只要愿意等，会终止）、任何参数相同结果。他承认现实中它们不等价：一个在很多场合有用，另一个没有。定义仍说它们等价。

这是好事，因为计算机科学里有多种等价，用对层次就行。他常用三种：

| | PL equivalence | Asymptotic equivalence | Systems / practical equivalence |
| --- | --- | --- | --- |
| 定义 | 相同输入，相同输出和效果。不谈快慢 | 运行时间或空间相对输入规模的增长。忽略小输入和常数因子 | 代表性负载上的性能。也许 10% 偏差可以，行为不能根本不同 |
| 解决的问题 | 替换实现时，能否说没有破坏任何客户 | 解释哪个算法在输入变大时更好 | 决定要不要为真实负载调优 |
| 关键区别 | 允许把慢的纯实现换成快的纯实现，也允许反过来 | 快 4 倍或 9 倍仍算相同 | 盯住测过的输入。长度 ≤ 20 时，两个 max 可能看起来一样 |
| 典型场景 | `Rational1` 换成 `Rational3`；`bad_max` 换成 `good_max` | 指数递归 vs 线性递归 | 在你的数据分布上确认长度 50 的差别不是纸面产物 |

没有哪一个更好。面对抽象、允许不同实现时，用 PL 等价。面对一般且处处高效的算法时，用渐近等价。面对实际负载上要不要调优时，用系统视角。定义的限制要认：PL 定义允许把好的换成坏的，所以要用它来辩护好事，而不是辩护坏事。渐近定义忽略常数因子。系统定义忽略没见过的输入，也忽略没见过的库客户。

把性能写进 PL 等价，就不能说“用 `let` 版替换指数版是语义保持的优化”。模块替换是同一件事的实例：客户观察不到，性能可以变。`Rational2` 把约分推迟到 `toString`，可能更快或更慢。在 B/C 下，这不构成客户能看见的差别。

---

## 用透镜看 signature ascription

| 透镜 | `structure Foo :> BAR = struct ... end` |
| --- | --- |
| Syntax | 结构名、`:>`、signature 名、`struct` 里的 binding |
| Semantics | 类型检查：signature 的每一项都被合适地提供。通过后，外部的静态环境只有 signature 列出的名字和类型 |
| Binding | 结构内部的 binding 按顺序进入模块环境。外部得到的是限定名，不是那些名字本身 |
| Scope | 未导出的名字只在 `struct ... end` 内可见。抽象类型的构造器不进入客户的模式匹配 |
| Evaluation | 结构体在定义时按顺序求值。Ascription 本身不求值，它改变的是之后哪些名字能被求值 |
| Type | Signature 是结构的类型。导出类型可以比内部类型更不一般，也可以把具体类型收成抽象类型 |
| Lifetime | 未导出的 helper 仍活在模块的闭包式环境里，供导出函数调用。客户没有指向它们的名字 |
| Mutation | 无新规则。若导出函数写了 ref 或打印，替换实现时这些效果必须相同，否则不等价 |
| Abstraction | 这就是边界。客户的类型环境里没有表示 |
| Composition | 一个 signature，多个 structure。客户代码对着 signature 写，实现可以整模块替换。不能把两个结构的操作混用 |

---

## Connection to Modern Languages

这些是概念类比，不是等价。

- C++ 的头文件和 class 的 public 区，在“客户能写哪些名字”这一点上像 signature 的省略规则。不像的地方：头文件通常暴露类的字段布局；不完整类型加 pimpl 才接近 `type rational`。公开继承和模板实例化也不是 ML 的 signature matching。
- Java 的 `interface` 像“一份可被多个实现匹配的合同”。不像的地方：interface 不生成一个客户无法拆开的新表示；实现类的字段通常仍可被同一包看见；子类型允许把实现的值放进接口类型之后再按另一条路径观察。ML 的每个结构有自己的抽象类型，禁止这种混用。
- Rust 的 `pub` 省略接近“不写进 signature”。`struct` 字段默认私有，接近表示隐藏。`trait` 接近“多个实现匹配同一份操作清单”，但 trait 方法的 `Self` 与 ML 的 generative abstract type 不是同一个类型身份规则。不要把 `impl Trait` 讲成 signature ascription。
- Go 的 interface 是结构化的：只要方法集够，就匹配，不必声明归属。ML 的 `:>` 是显式归属。Go 接口也不隐藏具体类型的表示，除非你只把接口值交出去、并且没有类型断言。类型断言是一条 ML 抽象类型故意不提供的路。

共同的想法只有一句：边界是客户被允许依赖的全部，不是实现的目录。每种语言把这句话执行到什么程度，要看它是否阻止客户命名表示、构造违反不变量的值、以及把一个实现的值传给另一个实现。

---

## Section Review

这一段把“模块”从文件组织纠正成抽象边界。Namespace 只解决名字冲突。Signature 决定外部的静态环境里有哪些名字、哪些类型。省略 binding 能藏 helper。只有抽象类型能藏表示，从而使 properties 不靠注释维持。暴露得越少，`Rational1`、`Rational2`、`Rational3` 越可能等价。每个结构的抽象类型是不同类型，所以等价的实现也不能拆开混用。函数等价是可观察行为相同，不是返回值碰巧相同。这份等价故意不含性能，以便把慢的纯实现换成快的纯实现，而不算破坏客户。

### 核心概念

structure、signature、ascription、namespace、abstract type、representation hiding、properties、invariants、signature matching、more-general type、generative type（每个结构一个新类型）、observable behavior、syntactic sugar、PL / asymptotic / systems equivalence。

### 必须掌握的不变量

```text
结构名不是值。
Signature 里没有的名字，模块外不存在。多可以，少不行。
藏 helper ≠ 藏表示。公开构造器就是公开一条绕过不变量的路。
type t 没有等号：客户知道类型存在，不知道定义。
匹配不要求类型字符串相同。方向是：告诉客户的每一条都必须为真，可以告诉得更少。
同一 signature ≠ 同一类型。替换的是整个模块，不是单个操作。
等价 = 结果、终止、异常、I/O、可见 mutation、调用次数与顺序都无法区分。
副作用越少，等价越多。
PL 等价不谈快慢。谈快慢用另外两个定义。
```

### 能力检查

真正理解这一节，应该能：

- 说明 `open` 为什么不是隐藏，以及它和 shadowing 的关系。
- 给一个 ADT 分开写出 properties 和 invariants，并指出哪个导出函数依赖不变量却不检查它。
- 解释为什么 `RATIONAL_A` 下 `Rational1` 与 `Rational2` 不等价，而 `RATIONAL_B` 下等价。
- 说明 `Rational3` 为什么匹配不了 A，却匹配得了 B，以及 `Whole : 'a -> 'a * int` 如何收成 `int -> rational`。
- 说明为什么 `Rational1.toString (Rational2.make_frac ...)` 必须是类型错误，即使两边的 datatype 形状相同。
- 举出一个返回值相同但不等价的函数对，并指出客户看见的是调用次数、顺序、打印还是 ref。
- 说明把 `bad_max` 换成 `good_max` 在哪种等价下是“没有破坏客户”，在哪种等价下是“一个更好”。

概念题和代码题见 `exercises/section-04-modules.md`。
