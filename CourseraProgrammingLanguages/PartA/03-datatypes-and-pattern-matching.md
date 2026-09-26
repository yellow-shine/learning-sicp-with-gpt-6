# 03 — 数据是 each-of、one-of，还是自己包含自己

> Part A · Section 2
> 视频：`Building Compound Types` 到 `Perspective on Tail Recursion`

Section 1 的 list 和 option 能用，但它们看起来像语言魔法：`null` 然后 `hd`，查错 variant 就在运行时爆炸。Tuple 能捆住几块数据，却回答不了“这是一张牌的花色，或一张牌的点数，或一个表达式的几种形状之一”。

任何语言建造复合数据，Grossman 只用三个教学名字，不是标准术语：

```text
each-of        同时有这几块
one-of         是这几种之一
self-reference 自己包含更小的自己
```

语言一旦有这三样，大量数据结构就不再是特殊库，而是同一套构造的用法。布尔是两个不带数据的构造子。List 是空，或一个元素接着一个更短的 list。表达式树是常量、取负、加法或乘法，后三种自己包含表达式。课程末尾的 OOP 分解，是把这张 one-of 表按另一根轴切开。没有这里的表，那里的对照没有落点。

---

## 1. 没有这套分类会怎样

只用 `int` 编码花色（1 表示梅花），类型不阻止你传入 9。只用一个 record，约定 `studentNum = ~1` 时改去读名字字段，不变量活在注释里。访问 one-of 若拆成“先测试、再提取”，你可以忘记一个 variant，也可以对错误 variant 调用提取函数。`hd []` 和 `valOf NONE` 就是这种错误。检查和提取分成两次，类型检查器看不见你是否覆盖了全部可能。

递归遍历若每次调用之后还有工作，调用栈必须记住“回来以后还要加”。函数式语言可以把“除了返回被调用者的结果之外无事可做”的调用实现成复用栈帧。不理解这一点，就会以为递归总是比循环贵，或者看不出两个 `fact` 为什么效率不同。

---

## Lecture — Record，以及 tuple 只是写法

视频：`Records`，`Tuples as Syntactic Sugar`。

### 问题

Tuple 是 each-of，但成员只靠位置。字段到了 6 个、8 个、12 个，记不住第 5 个该用 `#5` 还是 `#7`。需要按名字取的 each-of。同时要看见：by position 和 by name 是语言设计里反复出现的选择，不是 record 独有。

若 tuple 和 record 是两套独立构造，syntax、typing、evaluation、实现都要做两遍。它们几乎一样。问题变成：能否只实现一种 each-of，另一种只是写法？

### 机制

```sml
val x = { bar = (3, true andalso true), foo = 3 + 4, baz = (false, 9) }
val my_niece = { name = "Amelia", id = 411111 }
```

构造时每个字段表达式都求值。取值用 `#id my_niece`。字段名是类型的一部分。`{foo : int, bar : bool}` 和 `{bar : bool, foo : int}` 在 ML 里是同一类型：记录类型按名字匹配，不按书写顺序。这和 tuple 相反。Tuple 的顺序就是含义。

Tuple 是字段名为 `1, 2, ..., n` 且恰好连续的 record 的语法糖。

```sml
(3 + 1, 4 + 2)                    (* (4, 6) : int * int *)
{ 1 = 6, 2 = 5 }                  (* REPL 印成 (6, 5) *)
{ 3 = "hi", 1 = true }            (* 不是 tuple：没有 field 2 *)
{ 3 = "hi", 1 = true, 2 = 3 + 2 } (* (true, 5, "hi") *)
```

这和 `andalso` 是 `if` 的糖是同一类事实：语言表面可以比实现大，只要糖展开之后的语义已经有了。布尔后来也会被说成糖：两个构造子 `true` 和 `false`。Grossman 把这类观察称为关于逻辑如何拼起来的深事实，不是语法 trivia。

**If changed.** 若 tuple 不是糖，`#1` 和记录取值就是两套规则，学生要记两套求值。若记录类型在乎字段顺序，重排字段就会变成类型错误，名字就没有完成它的工作。

---

## Lecture — Datatype：自定义的 one-of

视频：`Datatype Bindings`，`Case Expressions`，`Useful Datatypes`。

### 问题

each-of 已经能自定义。one-of 到现在只有内建的 option 和 list。无法说“一个值要么是 `int * int`，要么是 `string`，要么什么都不带”。

```sml
datatype mytype = TwoInts of int * int
                | Str of string
                | Pizza
```

这一个绑定增加一个新类型 `mytype`，以及三个构造子。`TwoInts` 和 `Str` 是函数，类型分别是 `int * int -> mytype` 和 `string -> mytype`。`Pizza` 不带数据，它已经是一个值，类型 `mytype`。SML 在这里比 OCaml 多一点优雅：构造子就是函数，可以当函数值传递。课程动机里他把它列为选择 SML 的理由之一。

```sml
val a = Str "hi"              (* Str "hi" : mytype *)
val b = Str                   (* fn : string -> mytype *)
val c = Pizza                 (* Pizza : mytype *)
val d = TwoInts (1 + 2, 3 + 4) (* TwoInts (3, 7) *)
```

```text
Expression: TwoInts (3 + 4, 5 + 4)
Evaluation: 两个子表达式都求值，得到 7 和 9，再套上 tag TwoInts
Value: TwoInts (7, 9) : mytype
```

值是 tag 加数据。只有 tag 还不够用。若访问拆成 `isStr` 再 `getStrData`，你可以忘记某个 variant，也可以对错误 variant 提取。需要一个构造同时完成测试和提取，并让编译器看见全部分支。

```sml
fun f x =
    case x of
        Pizza => 3
      | Str s => 8
      | TwoInts (i1, i2) => i1 + i2

val _ = f Pizza             (* 3 *)
val _ = f (Str "hi")        (* 8 *)
val _ = f (TwoInts (7, 9))  (* 16 *)
```

`case` 按顺序试 pattern。匹配则把 pattern 里的变量绑到对应数据，求值那个分支。不匹配则试下一支。一支都不匹配是运行时异常。编译器对非穷尽匹配给 warning，对多余的、永远不会走到的分支给 error。Pattern 不是表达式。`Str s` 不是在调用 `Str`。它在拆一个已经造好的值。

```text
Expression: f (TwoInts (7, 9))
Environment: f → 上述函数

Pizza 不匹配
Str s 不匹配
TwoInts (i1, i2) 匹配
  新环境：i1 → 7, i2 → 9
  求值 i1 + i2
Value: 16
```

漏掉分支：

```sml
fun g x = case x of Pizza => 3
(* warning: match nonexhaustive *)
val _ = g (Str "hi")
(* 运行时：没有匹配的 pattern *)
```

Warning 不是类型错误。程序仍可运行。跑到没覆盖的值才失败。这是静态检查的一个精确位置：它能看见“你没写出所有构造子”，它不阻止你忽略警告。

### 不要用整数或魔数 record 代替 one-of

```sml
datatype suit = Club | Diamond | Heart | Spade
datatype rank = Jack | Queen | King | Ace | Num of int
```

`Num` 的 `int` 仍可以是 `~7` 或 `142`。他承认限制不到 2..10。这仍比“1 表示 J、14 表示什么”好：错的形状进不了 `suit`，而一个过大的点数至少还是点数，不是花色。

一张牌是 suit 与 rank 的 each-of。身份证件则是 one-of：要么学号，要么名字。

```sml
datatype id = StudentNum of int
            | Name of string * (string option) * string
```

坏风格是一个 record 加注释：`studentNum = ~1` 时忽略学号、改用名字。类型帮不上忙。若每人既有名字又可选学号，那才是 each-of，学号用 `int option`，不要用 `~1`。

选错 each-of / one-of，后面的函数会在错误的轴上分支。这不是语法偏好。它决定模式匹配在检查什么不变量。

### 表达式是递归的 one-of

```sml
datatype exp = Constant of int
             | Negate of exp
             | Add of exp * exp
             | Multiply of exp * exp

val example_exp = Add (Constant (10 + 9), Negate (Constant 4))
```

```text
Add
├── Constant 19
└── Negate
    └── Constant 4
```

`10 + 9` 在构造时已经求成 `19`。树里没有加法表达式。这和函数参数 eager 是同一条规则：构造子是函数，参数先求值。

```sml
fun eval e =
    case e of
        Constant i => i
      | Negate e2 => ~ (eval e2)
      | Add (e1, e2) => (eval e1) + (eval e2)
      | Multiply (e1, e2) => (eval e1) * (eval e2)
```

`eval` 和 `number_of_adds` 类型都是 `exp -> int`，但一个在跑表达式，一个在数 `Add` 节点。同一个数据类型，两种操作。这就是函数式分解的原型：操作是函数，variant 是 case 的分支。加一种操作，写一个新函数。加一种 variant，每个函数都要加一支。Section 9 会把这句话倒过来。

```text
Expression: eval (Negate (Constant 4))
Constant 4 → 4
Negate 的分支：~ 4
Value: ~4
```

`max_constant` 没有新机制。它演示的是：正确的递归可以写得很糟。对 `Add` 和 `Multiply` 各写一遍“递归两次再比较”，既重复计算，又复制粘贴。`let` 去掉重复计算。局部函数去掉复制。`Int.max` 去掉局部函数，因为参数先求值，不必再用 `let` 记住两次递归的结果：

```sml
fun max_constant e =
    case e of
        Constant i => i
      | Negate e2 => max_constant e2
      | Add (e1, e2) => Int.max (max_constant e1, max_constant e2)
      | Multiply (e1, e2) => Int.max (max_constant e1, max_constant e2)
```

测试先于实现。例子的最大常量是 `19`。能跑的解和用对构造的解不是一回事。

---

## Lecture — List 和 option 不是另一套语言

视频：`Lists and Options are Datatypes`，optional `Polymorphic Datatypes`。

### 问题

若 `[]`、`::`、`hd`、`tl`、`NONE`、`SOME` 真是另一套机制，语言比必要的大，访问风格也和 datatype 分裂。真相是：它们就是 datatype。更好的用法是 `case`。

```sml
datatype my_int_list = Empty
                     | Cons of int * my_int_list

fun append_my_list (xs, ys) =
    case xs of
        Empty => ys
      | Cons (x, xs') => Cons (x, append_my_list (xs', ys))
```

内建 list 只是构造子的名字特殊：`[]` 和 `::`，并且可以写在模式里。`hd` / `tl` / `null` 是可以用 `case` 写出来的函数。`isSome` / `valOf` 同样。

```sml
fun sum_list xs =
    case xs of
        [] => 0
      | x :: xs' => x + sum_list xs'

fun inc_or_zero opt =
    case opt of
        NONE => 0
      | SOME i => i + 1
```

`case` 比 `null` 然后 `hd` 好，不是因为短，而是因为空与非空被同一次匹配覆盖。忘记空分支，编译器能警告。`hd` 版本要到运行才炸。

自定义 datatype 若不能带类型参数，而内建 list 能，语言就不一致。`list` 不是类型。`int list`、`string list` 才是。

```sml
datatype 'a option = NONE | SOME of 'a

datatype 'a mylist = Empty
                   | Cons of 'a * 'a mylist

datatype ('a, 'b) tree =
    Leaf of 'b
  | Node of 'a * ('a, 'b) tree * ('a, 'b) tree
```

`sum_tree` 强迫两个参数都是 `int`。`sum_leaves` 不用节点上的 `'a`，所以 `'a` 保持任意，`'b` 必须是 `int`。`num_leaves` 两者都不用，类型是 `('a, 'b) tree -> int`。类型变量不是你声明“我想多态”。它是你没约束它。

这讲是 optional。作业不要求写多态 datatype。目的是把“list 毫无特殊之处”讲完。

---

## Lecture — 每个函数只接受一个参数

视频：`Each-of Pattern Matching`，`A Little Type Inference`，`Polymorphic and Equality Types`。

### 问题

one-of 不得不用 pattern，因为那是取出 tag 下数据的方式。each-of 一直用 `#1`、`#foo`。两套访问。更刺眼的是：`fun f (x, y, z) = ...` 看起来像三个参数。若每个函数其实只接受一个参数，多参数就不必是独立概念。他称这段为全课最喜欢的段落之一。

三步是同一个语义，越来越糖：

```sml
fun sum_triple1 triple =
    case triple of
        (x, y, z) => x + y + z

fun sum_triple2 triple =
    let val (x, y, z) = triple
    in x + y + z end

fun sum_triple3 (x, y, z) =
    x + y + z
```

第三种的 `(x, y, z)` 是 pattern，不是三份参数列表。调用 `sum_triple3 (rotate_left (3, 4, 5))` 能工作，因为 `rotate_left` 返回一个 triple，而函数只吃一个值。两次左旋就是一次右旋，因为中间结果是一个值，不是三份要重新打包的秘密参数。

```sml
fun rotate_left (x, y, z) = (y, z, x)
fun rotate_right t = rotate_left (rotate_left t)
```

Record 同样：

```sml
fun full_name {first = x, middle = y, last = z} =
    x ^ " " ^ y ^ " " ^ z
```

`^` 是字符串连接，所以三个字段都是 `string`。类型来自使用，不是来自你写出来的注解。

### 一点点推断，以及为什么作业禁止 `#`

```sml
fun sum_triple (x, y, z) = x + y + z
(* int * int * int -> int
   三元来自 pattern；int 来自 + *)

fun partial_sum (x, y, z) = x + z
(* int * 'a * int -> int *)

fun sum_triple2 (triple : int * int * int) =
    #1 triple + #2 triple + #3 triple
```

删掉 `sum_triple2` 的注解，类型检查器说 unresolved flex record。`#1` 没有告诉它这是三元组还是一个恰好有字段 `1` 的记录，后面还有没有别的字段。Pattern `(x, y, z)` 把形状写全了。所以作业禁止 `#` 不是风格警察。它是让推断看见完整的 each-of。

`partial_sum (3, "hi", 5)` 类型通过，结果 `8`。中间分量没被用，类型是 `'a`。这比作业规格更一般，仍然满足规格：更一般的类型可以替换成更不一般的。`append` 的实际类型 `'a list * 'a list -> 'a list` 比“只要求 string list”更一般。它不比 `int list * string list -> int list` 更一般，因为三次 `'a` 必须换成同一种类型。

`=` 产生 equality type：

```sml
fun same (x, y) =
    if x = y then "yes" else "no"
(* ''a * ''a -> string *)
```

两个引号不是打字错误。`''a` 只能换成允许相等比较的类型。`real` 不行。`int` 行。函数类型不行。他不准备深究实现，只要求见到 `polyEqual` 警告时不慌。`is_three` 里 `x = 3` 把 `x` 钉成 `int`，表面上看不到 `''a`。

#### Type synonym 不是新类型

```sml
type card = suit * rank
```

`type` 是另一个名字，同一类型。`card` 和 `suit * rank` 可以互换。REPL 可能印成其中一种，不要当成类型错误。`datatype` 才会造新类型和新构造子。需要隐藏表示时用 datatype 或以后的 abstract type，不要用 `type`。`type` 不隐藏任何东西。

---

## Lecture — 嵌套 pattern 的精确含义

视频：`Nested Patterns` 三讲，optional function patterns。

### 问题

pattern 里只能放变量时，要看“三个 list 是否都空”就必须嵌套 `case`，或者退回 `null` / `hd` / `andalso`。前者是空与非空全部组合的迷宫。数据本身是嵌套的。pattern 若不能嵌套，就不能一次说出值的形状。

```sml
fun zip3 list_triple =
    case list_triple of
        ([], [], []) => []
      | (h1 :: t1, h2 :: t2, h3 :: t3) =>
          (h1, h2, h3) :: zip3 (t1, t2, t3)
      | _ => raise ListLengthMismatch
```

`_` 匹配任何值，不绑定名字。顺序就是语义。先写的分支先试。`multsign` 用 `(Z, _)` 和 `(_, Z)` 吃掉所有含零的情况，后面不必再写零。最后一支若写成 `_ => N`，穷尽性更容易满足，漏掉的组合也被收成负号。检查更弱。他两个版本都给，是为了让你看见穷尽性和精确性的交换，不是为了宣布短的那个总是更好。

匹配的定义必须递归，因为 pattern 和 value 都嵌套：

- `a :: b :: c :: d` 匹配长度至少 3 的 list。`d` 绑到剩余 list，可以是空。
- `a :: b :: c :: []` 匹配长度恰好 3。太长时，最后的 `[]` pattern 对上非空 list，失败，试下一支。
- `((a, b), (c, d)) :: e` 只匹配非空 list，且头是 pair of pairs。引入五个绑定。

函数头上的多支定义不是新语义：

```sml
fun eval (Constant i) = i
  | eval (Negate e2) = ~ (eval e2)
  | eval (Add (e1, e2)) = eval e1 + eval e2
  | eval (Multiply (e1, e2)) = eval e1 * eval e2
```

它就是 `fun eval e = case e of ...`。他个人不喜欢。别人喜欢。可选。

---

## Lecture — 异常：构造子，但挂在 `exn` 上

视频：`Exceptions`。

### 问题

有些运行时情况应当是错误：空 list 的 head、除零、zip 长度不同。需要创建可携带信息的错误、引发它、在某处接住它。若异常是完全外来的机制，又和 datatype 的构造子故事重复。

ML 的做法：异常很像 datatype constructor，但是独立概念，挂在内建类型 `exn` 上。你可以不断加新的异常构造子。普通 datatype 不能在定义之后再加构造子，否则已写的穷尽匹配会沉默地变成不穷尽。`exn` 是唯一被允许生长的 one-of。Part B 会把这一点拿来类比 Racket 的 `struct`：动态增加一种新 tag。类比，不是同一机制。

```sml
exception MyUndesirableCondition
exception MyOtherException of int * int

fun mydiv (x, y) =
    if y = 0
    then raise MyUndesirableCondition
    else x div y

fun maxlist (xs, ex) =
    case xs of
        [] => raise ex
      | x :: [] => x
      | x :: xs' => Int.max (x, maxlist (xs', ex))
```

造出一个异常值和引发它不是一回事。`maxlist ([3, 4, 5], MyUndesirableCondition)` 把异常值当参数传进去，list 非空，不 `raise`，结果 `5`。`handle` 是对 `exn` 的 pattern matching。没抛，`handle` 不运行。空 list 抛了传入的那种异常，对应的 `handle` 分支才产出 `42`。

```text
Expression: maxlist ([], MyUndesirableCondition)
            handle MyUndesirableCondition => 42

求值 maxlist：xs 匹配 []，raise 那个异常值
该异常不在 maxlist 内部被接住
回到 handle，pattern 匹配
Value: 42
```

没有 `handle` 的 `raise` 不返回。后面的绑定不会建立。这和 `Div`、`Empty`、`Option` 是同一类运行时失败，只是现在你可以自己造。

异常不是“没有最大值”的唯一设计。Option 把失败变成值。异常把失败变成另一条控制路径。选择取决于调用者是否被期望处理它，以及失败是否稀少到不该出现在每个返回类型里。本课不宣布唯一正确答案。它要求你看见这是两种 one-of：一种在你的数据类型里，一种在 `exn` 里。

---

## Lecture — 尾递归：栈不是递归的定义

视频：`Tail Recursion`，`Accumulators`，`Perspective`。

### 问题

递归已经能代替循环，处理树时比循环自然，也不需要可变局部变量。没回答的是：调用栈会不会随深度增长？

```sml
fun fact n =
    if n = 0 then 1 else n * fact (n - 1)
```

`fact (n - 1)` 返回之后还要乘以 `n`。调用者必须活着。深度为 n 的调用链就有 n 个栈帧。

```sml
fun fact n =
    let
        fun aux (n, acc) =
            if n = 0 then acc
            else aux (n - 1, acc * n)
    in
        aux (n, 1)
    end
```

`aux` 的递归调用就是函数体的结果。调用者除了返回这个结果之外无事可做。实现可以复用当前栈帧。这不是新的语言特性。这是对已有求值规则的一种允许的优化，以及一种你要会看出来的习惯。

Accumulator 是可重复的改写，不是每次凭空想 `aux`。把“还没做完的工作”从栈搬进参数。`sum` 的未完成工作是“还要加上头元素”。加法可交换，所以可以先加进 `acc` 再递归。`rev` 的坏版本在递归之后 `append` 一个元素到末尾。即使把递归改成尾调用，若每步 `append`，总工作量仍是平方。只盯着“是不是 tail call”会漏掉更大的代价。好的 `rev` 用 `::` 把元素接到累加器前面，一步是常数时间。

尾位置按表达式结构定义，不按直觉：

- 函数体在 tail position。
- `if` 的两个分支在 tail position。测试不在。
- `let` 的 body 在 tail position。绑定的右边不在。
- `n * fact (n - 1)` 整体若在 tail position，乘法的子表达式不在。所以那个 `fact` 调用不是 tail call。
- `f x = g (h x)` 里，`g (...)` 是 tail call，`h x` 不是。

有些递归做不到尾调用，除非另造一个和调用栈一样贵的数据结构。树的两个子树都要递归时，至少有一个调用之后还有另一棵子树要处理。不要把一切都改成 tail recursive。先看未完成的工作是不是必须留在栈上。

---

## 对照

### Each-of vs One-of

| | Each-of | One-of |
|---|---|---|
| 定义 | 值同时具有所有分量。Tuple、record | 值是若干构造子之一。Datatype |
| 解决的问题 | 把必须一起存在的数据捆住 | 把互斥的可能收成一个类型 |
| 关键区别 | 访问是投影，不需要分支。宽度或字段集在类型里 | 访问必须分支。漏分支是可警告的错误 |
| 典型场景 | 一张牌 = 花色与点数；函数的那一个参数 | 花色、表达式、option、list、`exn` |

### Pattern vs Expression

| | Pattern | Expression |
|---|---|---|
| 定义 | 描述值的形状，匹配时绑定变量 | 求值产生值 |
| 解决的问题 | 同时测试 variant 并取出数据 | 计算 |
| 关键区别 | `Str s` 在 pattern 里是拆。`Str "hi"` 在表达式里是造 | 构造子在两种位置含义相反 |
| 典型场景 | `case`、`fun` 参数、`val` 左边 | 函数体、构造子的参数 |

### Exception vs Option

| | Exception | Option |
|---|---|---|
| 定义 | `raise` 一个 `exn` 值，可用 `handle` 接住 | 返回 `NONE` 或 `SOME v` |
| 解决的问题 | 稀少的失败、不必出现在每个类型里的控制转移 | 失败是普通结果，调用者被类型强迫处理 |
| 关键区别 | 不接住就不返回，后面的绑定不发生 | 总是返回一个值。误用要显式 `valOf` |
| 典型场景 | 除零、长度不匹配、`hd []` | `max` of empty list |

---

## Connection to Modern Languages

概念类比，不是等价。

- Rust `enum` + `match`、Scala `sealed trait` + `match`、Haskell 代数数据类型，是这里的 datatype + case。Rust 的穷尽检查比 ML 的 warning 更硬：不匹配通常不能编译。
- TypeScript 的判别联合和 `switch` 是较弱的版本。没有语言强制的构造子，穷尽性依赖控制流分析。
- Java 的 `switch` on enum 接近不带数据的 datatype。带数据的 one-of 在没有代数数据类型的 Java 里通常变成类层次。那就是 Section 9 的另一轴。
- Python 3.10 的 `match` 有嵌套模式，但没有 ML 那种与类型定义绑在一起的穷尽检查。惯用法可以搬，静态保证搬不走。
- 尾调用：Scheme 和 Racket 保证 proper tail calls。SML 的实现普遍做，语言标准的保证程度不同。JVM 上的 Scala / Kotlin 不能假设尾调用一定被优化。把 ML 的 `aux` 翻译到 Java 时，深递归仍可能栈溢出。那是实现策略，不是你写错了累加器。

---

## Section 2 Review

这一节把复合数据收成三件事：each-of、one-of、self-reference。Record 是带名字的 each-of，tuple 是它的糖。Datatype 是自定义的 one-of，`case` 同时测试和提取。List、option、布尔都是这套机制的实例。每个函数只吃一个参数，多参数是 tuple pattern。异常是长在 `exn` 上的构造子。尾递归是求值结构上的事实，不是新关键字。

### 不变量

```text
值 = tag + data
pattern 拆开构造，表达式造出构造
漏掉的 case 是警告，跑到才失败
type 不创造新类型，datatype 创造
更一般的多态类型仍然满足更不一般的规格
''a 是 equality type，不是打字错误
每个函数恰好一个参数
raise 的是值；造出异常值不等于引发它
tail call = 调用者除了返回这个结果之外无事可做
```

### 能力检查

- 给一个用 `~1` 编码的 record，改成 one-of 或 `option`，并说明哪一个才是 each-of。
- 给 `eval` 加一个 `Subtract`，指出要改哪些函数，哪些不用改。这是 expression problem 的前半。
- 判断一个调用在不在 tail position，并说明判断依据是表达式结构不是“看起来在最后”。
- 解释 `fun f (x, y) = ...` 为什么不是两个参数。

练习：`exercises/section-02.md`。
