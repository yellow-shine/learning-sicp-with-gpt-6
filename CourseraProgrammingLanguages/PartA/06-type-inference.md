# 06 — 不写类型，为什么仍然是静态类型

> Part A · Section 4 前半
> 视频：`What Is Type Inference`，`ML Type Inference`，`Type Inference Examples`，`Polymorphic Examples`，optional `The Value Restriction`，`Mutual Recursion`
>
> 模块、signature、等价不在这一章。它们回答的是另一个问题：客户被允许看见什么。

从 Section 2 起，ML 程序里几乎不写类型，REPL 却会印出 `int list -> int` 或 `'a list -> int`。若把“没写类型”听成“运行前不检查类型”，后面所有关于闭包、多态和模块的推理都会站错地方。

这一章要钉死的不是推断算法的实现细节。Grossman 不讲完整算法：嵌套函数会让它变长，而人用例子就能手算大多数类型、读懂大多数报错。要钉死的是三个彼此独立的事实：

```text
不写类型 ≠ 动态类型
类型推断 ≠ 参数多态
多态 × 可变状态 会让“先收集约束再尽量泛化”变得 unsound
```

互相递归看起来像语法题。它其实是同一条环境规则的例外：binding 按顺序进入环境。推断也依赖这条规则。没有 `and`，推断器不能“先完全确定前一个，再用它看下一个”，因为两个函数谁都不是前一个。

---

## 1. 这一组讲要解决什么问题？

静态类型检查（static type checking）的承诺是：在任何求值发生之前，拒绝一批程序，使某些错误不可能在运行时发生。动态类型语言几乎不做这件事。你必须真的求值到那个有问题的表达式，错误才出现。ML、Java、C、Scala 在这条轴上站在一起。Racket、JavaScript、Python 站在另一边。利弊要等用过动态语言再比。Section 4 不辩阵营。

已经成立的静态语言还有一条共同规则：每个 binding 在其作用域内有一个类型，并且一直保持那个类型。`string`、`bool`、函数、tuple 被分开。你不能把一个 bool 放进一个 int 绑定。

于是出现一个看起来矛盾的现象。ML 是静态的，却从很早开始就不要求你写下这些类型。问题不是“类型从哪来”，而是：

> 若程序员不写类型，编译器到底在解什么问题？解失败时，它拒绝的是“写得不漂亮”，还是“不存在任何一种类型标注能使类型检查成功”？

答案是后者。这就是类型推断（type inference）问题：

> 给程序里每个 variable、binding、expression 一个类型，使得如果把这些类型都写出来，既有的 type checking 规则会成功。若不存在这样的赋值，推断失败，程序在运行前被拒绝。

原则上可以先推断，再把写满类型的程序交给一个独立的 type checker。SML 的实现通常不分开。推断器和检查器是同一个过程。那是工程选择，不是“推断就是检查”的定义。

推断的难度不随“接受更多程序”单调变化。两个极端都容易：每个程序都通过，总回答 yes；没有程序通过，总回答 no。难的是中间那种既要拒绝 int 加 string、又要让 `length` 对任何元素类型工作的系统。ML 的推断看起来像魔法，是因为多态类型变量（type variable）和约束求解叠在一起。它们是两件事。

它依赖 Section 1 的环境按顺序增长、`if` 两分支同类型、函数调用先有箭头类型。它准备 Section 7 的 soundness：这里会第一次看见，一套“看起来合理”的推断规则可以承诺一件它保证不了的事。它也准备 signature matching：更一般的类型可以当作更特殊的类型来用。那一章不在这里展开。

---

## Lecture — 隐式类型仍是静态类型

视频：`What Is Type Inference`。

### 1. 若没有这个区分

若“不写类型”就等于动态类型，则下面这个函数应当被接受，错误留到某次调用真的走了错误分支：

```sml
fun g x =
  if x          (* 测试必须是 bool；具体谓词口述未给出，失败不依赖谓词 *)
  then true
  else x * 2
```

`then` 分支是 `bool`。`else` 分支是 `int`。ML 的条件表达式规则不关心哪一边会执行。结果可能是任意一边，所以两边必须是同一个类型 `t`，整个 `if` 的类型是 `t`，函数的返回类型也是 `t`。`bool` 与 `int` 对不上。不存在一种类型赋值使检查成功。推断失败。程序不运行。

动态语言可以允许“有时返回 bool、有时返回 int”。那是另一条设计。它不是“ML 还没写类型注解”。

函数体未在这一讲被逐字写出的那个例子，只用来说明绑定已经有类型：`f` 是 `int -> int`，参数 `x` 是 `int`。这些类型与在 Java 或 C 里写出来一样，是运行前的事实。REPL 把类型和值印在一行，不表示两阶段是一件事。

### 2. 核心概念

#### Implicit typing（隐式类型）

**Definition.** 程序员不必在每个 binding 上写下类型，类型仍由静态规则确定。ML 是 statically typed 并且 implicitly typed。

**Intuition.** 注解是给人看的，也是给检查器看的。检查器若能从使用方式把注解算出来，缺少注解不是缺少类型。

**Why it exists.** 手写类型在多态和高阶函数上很吵。`map` 的类型比函数体长。推断让类型规则仍在，而不把规则的结论再抄一遍。

**Problem solved.** 把“要不要写类型”从“有没有类型规则”上拆下来。

**Example.** `g` 的失败发生在求值之前。没有 value。没有“这次参数碰巧使测试为真、所以返回了 `true`”这种运行时运气。

#### Type inference vs Type checking

**Definition.** Type checking 验证已经给出的类型是否满足规则。Type inference 寻找一组类型，使得检查会成功。

**Intuition.** 检查是批改一份填好的答卷。推断是把空着的类型空格填上，并且填完后答卷必须及格。填不上就退卷，不是改规则让它及格。

**Why it exists.** 隐式类型语言必须做推断，否则“不写类型”就无法连上“运行前拒绝”。

**Problem solved.** 你能指出一个报错是“不存在合法类型”，而不是“编译器没猜中你心里的那个类型”。

| | Type checking | Type inference |
| --- | --- | --- |
| 定义 | 给定类型，问规则是否满足 | 寻找使规则满足的类型赋值 |
| 解决的问题 | 验证程序员或前一阶段给出的类型 | 让不写注解的程序仍能被静态拒绝 |
| 关键区别 | 失败意味着给出的类型不对 | 失败意味着不存在任何能通过的类型 |
| 典型场景 | Java 方法签名、ML signature 里写下的 `val f : int -> int` | REPL 印出的 `'a list -> int` |

| | 不写类型（implicit） | 动态类型（dynamic） |
| --- | --- | --- |
| 定义 | 类型在，只是注解省略 | 运行前几乎不拒绝类型错误 |
| 解决的问题 | 少写、仍有静态保证 | 让“有时返回 bool、有时返回 int”这种程序能跑 |
| 关键区别 | `g` 在运行前被拒绝 | `g` 要等到错误分支被求值 |
| 典型场景 | SML、以及后来带局部推断的 Scala / Rust / C# | Racket、Python、JavaScript |

这是概念对照，不是声称这些语言的类型系统相同。

### 3. 若改掉规则

- 若 `if` 允许两分支不同类型：`g` 通过，返回类型取决于参数和测试。错误推迟到使用返回值的地方。那是动态类型，或一种更弱的静态系统。它不再是 ML 的条件规则。
- 若强制每个 binding 手写类型：ML 仍是静态的，只是不再 implicit。`g` 一样被拒绝。拒绝的理由不变。
- 若推断器“理解你想返回 int”：它没有这个能力。它只收集 type-checking facts。下一讲会把这一点说死。

---

## Lecture — 约束从哪来，`'a` 从哪来

视频：`ML Type Inference`。

### 1. 若只有魔法

不看步骤，`'a` 就像编译器心情好时送的礼物。你无法解释为什么 `w` 是 `'a` 而 `z` 是 `int`，也无法在报错时判断编译器是撞上了哪条事实。人需要一套能手算的过程。完整算法（尤其嵌套函数）更长。下面四步够用，直到 value restriction。

### 2. 机制

按这个顺序想，不要跳：

1. **按绑定顺序确定类型。** 没有互相递归时，前一个 binding 的类型完全确定之后，才用它看下一个。Helper 必须写在使用它的函数前面。否则它还不在静态环境里，这是类型错误。这就是 ML 的语义，不是风格指南。
2. **收集约束。** 对每个 `val` / `fun`，从定义里列出必须为真的事实。函数体里出现 `x >= 0`，则 `x : int`。
3. **看这些约束蕴含什么。** 不能同时为真，就是类型错误。`x >= 0` 并且 `x` 与 string 拼接，则 `x` 既要是 `int` 又要是 `string`。
4. **约束不够就引入新的类型变量。** 某个参数在函数体里从未使用，没有任何事实能钉死它。给它一个 fresh type variable，得到多态类型（polymorphic type）。

第 5 步是 value restriction。本讲先假装没有它。后面会看见，没有它，第 4 步太宽。

中心倾向是：只要能，就生成带类型变量的多态类型。这有利于复用，也告诉你某个参数没用过。

**类型推断和类型变量是两个概念。** 可以有推断而没有类型变量。那种系统更难给出有用类型：未使用的参数必须被猜成某个具体类型，猜哪个都没有依据。也可以有类型变量但要求程序员写下所有类型。Java 大多数时候是后者：泛型方法仍要写出参数类型。这是概念类比，不是说 Java generics 等于 ML 的 `'a`。Java 的泛型还和子类型缠在一起，那是 Section 10 的题目。

### 3. 例子：未使用的参数留下 `'a`

```sml
val x = 42

fun f (y, z, w) =
  if y
  then z + x
  else 0
(* f : bool * int * 'a -> int *)
```

```text
先处理 val x = 42
  Expression: 42
  Environment: 先前环境
  Evaluation: 42 是 int 值
  Binding: x → 42，静态类型 x : int

再处理 fun f
  静态环境已有 x : int
  y 是 if 的测试        ⇒ y : bool
  z + x，且 x : int     ⇒ z : int
  else 是 0 : int       ⇒ 函数体 : int
  w 没有出现            ⇒ 没有事实
  所以 w : 'a

函数值的类型：bool * int * 'a -> int
```

`+` 的另一个参数 `x` 也要检查。它确实是 `int`。推断不是只看函数参数。环境里已有的绑定参加约束。

REPL 会印出同样的类型。印出 `'a` 不是说 `w` 在运行时是某种特殊值。`'a` 的意思是：没有理由偏好任何具体类型，并且所有写着同一个 `'a` 的位置必须是同一种类型。

### 4. 若改掉规则

- 没有类型变量：`w` 无法得到“任意类型”。推断器必须挑一个具体类型，函数不再能对 `string` 和 `int` 的第三分量都工作，尽管第三分量根本没用。
- 不按顺序、允许使用更后面的 binding：helper 可以写在后面。这会破坏“先确定前一个”的推断顺序。互相递归不能靠放宽这条规则偷偷得到，要单独的 `and`。否则每个文件都变成“所有绑定同时可见”，shadowing 和向前引用的故事要重写。

---

## Lecture — 约束能钉死时，就钉死

视频：`Type Inference Examples`。

### 1. 若收集漏事实

递归和 pattern 是漏事实的地方。Pattern 不是注释。`(y, z)` 匹配 `x`，意味着 `x` 的类型必须是一个 pair，否则 pattern 本身不 type-check。List 的 `x :: xs'` 意味着存在某个 `t3`，使 `x : t3`、`xs' : t3 list`，被匹配的值是 `t3 list`。漏掉这些，你会以为类型比实际更宽。

推断不理解程序做什么。它不知道 `sum` 是在求和。它只知道 `+` 和 `0` 要求 `int`。

本讲忽略 `+` 也有 `real` 版本。按他的简化，`+` 的两边都是 `int`。这是教学简化，不是 SML 的全部故事。

### 2. 非多态例子

每个 ML 函数只有一个参数。看到 `fun f x = ...`，先写 `f : t1 -> t2`。若参数模式是一个变量，那个变量的类型就是 `t1`。

```sml
fun f x =
  let
    val (y, z) = x
  in
    abs y + z
  end
(* f : int * int -> int *)
```

```text
f : t1 -> t2
x : t1
(y, z) 匹配 x  ⇒  t1 = t3 * t4，y : t3，z : t4
abs : int -> int  ⇒  t3 = int
z 与 int 相加     ⇒  t4 = int
函数体 : int      ⇒  t2 = int

结果：int * int -> int
```

没有未约束的变量，所以没有 `'a`。这不是推断器“决定不要多态”。是事实已经把每个 `t` 都钉死了。

### 3. 递归不自动产生新事实

```sml
fun sum xs =
  case xs of
      [] => 0
    | x::xs' => x + sum xs'
(* sum : int list -> int *)
```

```text
sum : t1 -> t2
xs : t1
x : t3
xs' : t3 list
t1 = t3 list          （被匹配的是 xs）
[] 分支返回 0 : int   ⇒ t2 = int
x 被加                ⇒ t3 = int
于是 t1 = int list

递归调用 sum xs'
  实参 xs' : int list
  形式参数要求 t1，也就是 int list
  结果要求 t2，也就是 int，正好是 + 的参数

没有新的等式。约束一致。
```

把递归调用改成用 head：

```sml
fun sum xs =
  case xs of
      [] => 0
    | x::xs' => x + sum x
(* 不 type-check *)
```

```text
由 pattern 和 +：t1 = int list，x : int
调用 sum x：把 int 传给需要 int list 的函数
这两条不能同时为真
```

不求值。没有 value。

他另外提到：有的改法会 type-check，然后无限循环。具体改法口述没有钉死，多半是递归调用仍传整个 `xs` 而不是 `xs'`。那种程序的类型约束可以一致，因为它传的确实是 list。类型通过不表示算法终止。这和 Section 1 的 `7 - 7` 是同一类教训：静态检查不读你的算法意图。

### 4. 报错位置不是唯一的问题所在

约束收集的顺序任意，最终“是否 type-check”相同。这是一个深的性质。但一遇到矛盾就报错，所以报错的位置和措辞取决于收集顺序。它只报告其中一个不成立的事实。

SML/NJ 可能先处理调用，再处理 pattern。它也许说 case 的规则不一致，也许说 `xs` 因调用点被推成 `int`，却拿去匹配 `int list`。两种信息都对：事实不能同时为真。它只是先撞上了其中一条。

**若改掉“只报告一个矛盾”：** 你可能看到更完整的错误列表，但“哪一行是根”仍然不一定是编译器指出的那一行。Section 1 的语法错误已经教过这一点。类型错误同样。

---

## Lecture — 该相同的地方相同，该独立的地方独立

视频：`Polymorphic Examples`。

### 1. 若事实太少却不许留变量

`length` 不用元素。若必须挑一个元素类型，推断器没有依据挑 `int` 而不是 `string`。挑了，函数就不再是你写的那个函数。多态类型是“没有依据”的诚实记录，不是额外送的灵活性。

### 2. 替换规则

收集事实的方法和上一讲相同。结束后仍有未约束的 `T`：把每个大写 `T` **一致地**换成类型变量。同一个 `T1` 必须换成同一个变量。没有等式把它们连起来的不同 `T`，换成不同变量。

读作：对所有类型 `'a`，这个函数都工作。`'a` 不是运行时的一种值。

#### `length`：元素类型没有事实

```sml
fun length xs =
  case xs of
      [] => 0
    | x::xs' => 1 + length xs'
(* 'a list -> int *)
```

```text
length : t1 -> t2
x : t3
xs' : t3 list
t1 = t3 list
t2 = int          （返回 0；1 是 int，可做 + 的参数）
递归 length xs' 要求实参是 t1，xs' 正是 t3 list = t1
x 从未被使用

t3 无约束 → 'a
length : 'a list -> int
```

和 `sum` 的唯一差别是：`sum` 对元素做了 `+`，`t3` 被钉成 `int`。`length` 可以写成 `_ :: xs'`。Wildcard 就是“这里有一个值，我不制造使用它的约束”。

#### 常量 `true` 扔不掉 else

```sml
fun f (x, y, z) =
  if true
  then (x, y, z)
  else (y, x, z)
(* 'a * 'a * 'b -> 'a * 'a * 'b *)
```

他把参数模式直接写成 triple，所以函数类型先写成 `t1 * t2 * t3 -> t4`，`x : t1`，`y : t2`，`z : t3`。

```text
then 分支：(x,y,z) : t1 * t2 * t3
else 分支：(y,x,z) : t2 * t1 * t3
两分支都可能成为结果 ⇒ 两个 tuple 类型相等
  ⇒ t1 = t2
  ⇒ t4 = t1 * t1 * t3

t1 → 'a
t3 → 'b
结果：'a * 'a * 'b -> 'a * 'a * 'b
```

`true : bool` 只满足 `if` 的测试类型。它不参与选择哪一支的类型。类型规则不知道哪一支会执行，即使测试是字面量。

**若改成“`if true` 只检查 then”：** else 不再强制 `t1 = t2`，类型变成 `'a * 'b * 'c -> 'a * 'b * 'c`。这更宽，也是错的。规则说结果可能是任意一支。求值规则确实会跳过 else。类型规则故意不使用这条求值信息。否则类型会依赖“编译器有多聪明地做常量折叠”，同一程序在两个实现里类型不同。

#### `compose`：数据流把三个变量连起来

```sml
fun compose (f, g) = fn x => f (g x)
(* ('a -> 'b) * ('c -> 'a) -> 'c -> 'b *)
```

REPL 可能少印一些括号。箭头右结合，所以 `'c -> 'b` 写不写括号，说的是同一个类型。

```text
compose : t1 * t2 -> t3
f : t1
g : t2

body 是 fn x => ...
  x : t4
  匿名函数 : t4 -> t5
  ⇒ t3 = t4 -> t5

g x
  ⇒ t2 = t4 -> t6     （g 必须是函数，参数是 x 的类型）

f (g x)
  ⇒ t1 = t6 -> t7     （f 的参数是 g 的结果）
  body 的类型是 f 的结果 ⇒ t7 = t5

合起来：
  t1 = t6 -> t5
  t2 = t4 -> t6
  t3 = t4 -> t5

(t6 -> t5) * (t4 -> t6) -> (t4 -> t5)

从左到右第一次遇见：t6 → 'a，t5 → 'b，t4 → 'c
再遇见的 t6、t4、t5 必须重用 'a、'c、'b
不能把两个 t6 换成两个不同的字母
```

`g` 的结果必须是 `f` 的参数。这不是风格，是函数应用的类型规则。三个变量里，`'a` 是中间类型。它在 `g` 的结果和 `f` 的参数上是同一个变量。`'c` 是输入，`'b` 是输出。它们没有被等式连起来，所以是不同的字母。

求值时，`compose (f, g)` 返回一个闭包：代码是 `fn x => f (g x)`，环境捕获 `f` 和 `g`。本讲不画这个闭包。类型讨论不需要它。但要记住：多态类型描述的是这个函数值可以被怎样调用，不是闭包在运行时携带了一个叫 `'a` 的东西。

| | `sum` | `length` | `f (x,y,z)` | `compose` |
| --- | --- | --- | --- | --- |
| 约束做了什么 | `+` 把元素钉成 `int` | 元素无事实 | 两分支迫使 `x` 与 `y` 同类型，`z` 独立 | `g` 的结果必须是 `f` 的参数 |
| 类型变量 | 无 | 一个 `'a` | `'a` 共享，`'b` 独立 | 三个，中间类型共享 |
| 若替换不一致 | — | 两个元素位置变成不同类型，`::` 失败 | `x` 和 `y` 在 then/else 里对不上 | `g x` 的结果喂不进 `f` |

---

## Lecture — 推断太宽时，类型系统会说谎

视频：optional `The Value Restriction and Other Type Inference Challenges`。

他声明：更进阶，不够优雅，不考，后面没有 ML 作业。可以当 optional。但若不讲，前面的四步会被当成 ML 的完整类型系统。那是错的。

### 1. 若按前面的规则继续泛化

Soundness（可靠性）在这里的意思很窄：类型系统声称要阻止的事，不应当在运行时发生。例如 int 加 string。Section 7 会把 sound / complete 定义完整。这里只需要看见一个反例。

```sml
val r = ref NONE
(* 按前几讲的规则：r : 'a option ref *)

val _ = r := SOME "hi"
(* 把 'a 实例化成 string *)

val _ = valOf (!r) + 1
(* 把同一个 r 的 'a 实例化成 int *)
```

`NONE` 没有携带数据，约束收集钉不死 option 的参数。`ref` 的类型是 `'a -> 'a ref`。于是 `ref NONE` 得到 `'a option ref`。

`:=` 的类型是 `'a ref * 'a -> unit`。`!` 的类型是 `'a ref -> 'a`。多态意味着每次使用可以把 `'a` 换成一个具体类型。前几讲的替换规则允许这两次使用换成不同的具体类型。

```text
ref NONE
  分配一个盒子，内容是 NONE
  旧规则给这个盒子类型 'a option ref

r := SOME "hi"
  这次使用把 'a 换成 string
  盒子里现在是 SOME "hi"

!r
  另一次使用把 'a 换成 int
  类型系统说取出的是 int option
  实际值是 string option
  valOf 得到 string
  string + 1

这是类型系统承诺不会发生的事。
按前几讲的规则，三行都 type-check。
所以那套规则 unsound。
```

修复至少要拒绝这三行里的一行。自然的想法是：`ref` 不能持有多态类型，必须是 `int option ref` 这种已经定死的类型。

**做不到。** 只对名为 `ref` 的构造写特殊规则，挡不住把 `ref` 藏起来的类型。

```sml
type 'a foo = 'a ref
(* 名字 foo 来自口述“上面有一个 type synonym”。具体拼写未逐字确认。 *)

fun f x = ref x
val r = f NONE
```

`'a foo` 就是 `'a ref`，但类型检查器若只巡逻名字 `ref`，它看见的是 `foo`。Module 更能把定义藏到签名后面。检查使用处的人看不见里面有没有 reference。所以不能只给 `ref` 打补丁。限制必须加在所有人身上。

### 2. Value restriction（值限制）

**Definition.** 一个 `val` binding 若要给引入的变量多态类型，右边的表达式必须是 syntactic value，或是一个变量。函数调用不算。算出一个结果的表达式不算。

**Intuition.** 多态的“每次使用换成不同具体类型”只对一种东西安全：一个还没被求值出“里面已经装了某种具体东西”的值。`fn` 是值。函数调用不是。`ref NONE` 是调用。它已经分配了一个盒子。盒子里不能同时是所有类型。

**Why it exists.** 恢复 soundness，同时不去识别“这个类型的定义里藏没藏 `ref`”。识别不了。

**Problem solved.** `val r = ref NONE` 不能得到 `'a option ref`。SML/NJ 警告，给一个 dummy 类型，形如 `?.X1 option ref`。`r` 基本不能用。后面的 `:=` 和 `!` 都不 type-check。int 加 string 那条路被堵上。

**代价。** 限制不是“右边有副作用才拒绝”。任何看起来像调用的右边都不能获得多态类型，包括没有 mutation 的部分应用：

```sml
val pairWithOne = List.map (fn x => (x, 1))
(* 想要的类型：'a list -> ('a * int) list
   口述是 alpha list arrow alpha star int list
   右边是调用，不是 value
   'a 变成 dummy，结果几乎不能用 *)

fun pairWithOne xs = List.map (fn x => (x, 1)) xs
(* 绑定的是函数。函数是 value。多态恢复。 *)
```

平时把函数再包一层叫 unnecessary function wrapping。这里那一层是必要的。不是因为语义变了，是因为 value restriction 看的是语法形状：`val` 的右边是不是 value。

函数体里的 `fn` 一般没问题。违规的是某些 `val` 的右边。他提到文件里有三处这类警告。第三处的具体表达式口述没有展开，这里不编。

```text
Expression: val pairWithOne = List.map (fn x => (x, 1))
右边：函数调用，不是 fn，不是变量
推断想给 'a list -> ('a * int) list
Value restriction：不许
结果：警告 + dummy type，不能再当多态函数调用

Expression: fun pairWithOne xs = ...
绑定的值是函数，语法上是 value
允许泛化
类型：'a list -> ('a * int) list
```

### 3. 更严或更宽，推断都可能更难

若 ML 没有多态：类型系统更简单、更严。推断反而更难。`length` 必须挑一个具体的元素类型。没有依据。函数也不再有用。

若加入子类型（subtyping）——本课后面才讲，这里是假想，不是 ML 的规则——例如允许 `int * int * int` 用在期望 `int * int` 的地方，丢掉第三字段。更多程序会通过。推断更难。`val (y, z) = x` 不再能说 `x` 一定是恰好 `t1 * t2`。只能说至少两个字段，也许更多。可以处理，但类型更难推，错误信息更难懂。

所以“接受更多程序”不使推断更容易。Section 4 开头的两个极端，在这里有了具体的中间点。

尽管有 value restriction，基本想法仍然干净：可以有静态类型，而程序里一个类型都不写。ML 不是唯一这样做的语言。细节因语言而异。

| | 只限制 `ref` | Value restriction |
| --- | --- | --- |
| 定义 | 名为 `ref` 的表达式不能得到多态类型 | 任何非 value 的 `val` 右边都不能得到多态类型 |
| 解决的问题 | 堵住 `ref NONE` 这个例子 | 堵住所有“看起来不是 ref、实际藏着可变盒子”的例子 |
| 关键区别 | 类型同义词和 module 能把 `ref` 改名藏起来 | 不需要看见定义。看使用处的语法形状 |
| 典型场景 | 挡不住 `type 'a foo = 'a ref` | 也误伤 `List.map` 的部分应用 |

| | 多态类型变量 | 类型推断 |
| --- | --- | --- |
| 定义 | `'a` 表示“对所有类型同一段代码” | 从使用方式填上类型 |
| 解决的问题 | 复用，而不为每种元素类型复制 `length` | 不必手写那些类型 |
| 关键区别 | Java 可以有前者而通常没有后者 | 没有前者时，后者往往不知道该填哪个具体类型 |
| 典型场景 | `'a list -> int` | 从 `+` 推出 `int`，从“没用过”留下 `'a` |

### 4. 若改掉 value restriction

去掉它：`ref NONE` 回到 `'a option ref`，随后 int 与 string 混淆，unsound。保留它：良性的部分应用也失去多态，除非包一层函数。没有中间规则能只看表达式“有没有副作用”就做对。`List.map` 的部分应用没有副作用，仍然被拒。副作用不是这条规则的判断标准。语法上是不是 value，才是。

---

## Lecture — 互相递归：顺序规则的一个洞

视频：`Mutual Recursion`。

### 1. 若没有同时进入环境的机制

`f` 有时要调用 `g`，`g` 有时要调用 `f`。ML 的 binding 按顺序进入环境。函数体里能看见的，是更早的绑定，加上递归函数自己。没有“两个名字同时出现”的机制，互相调用在类型检查阶段就是 unbound。Datatype 同样：`t1` 的构造器要持有 `t2`，`t2` 的构造器要持有 `t1`。先定义哪一个，另一个都不在环境里。

推断也依赖顺序：没有互相递归时，先完全确定前一个，再用它的类型看下一个。互相递归使这一步不成立。两个函数的类型必须一起看。

### 2. `and` 是什么

**Definition.** 连续的函数绑定，第一个用 `fun`，后面用 `and` 而不是 `fun`，是一捆 mutually recursive functions。它们彼此都在对方的环境里，作为一包被 type-check，也作为一包被 evaluate。

```sml
fun f1 ... = ...
and f2 ... = ...
and f3 ... = ...
```

Datatype 是另一个构造，同一想法：第二个及以后用 `and` 替换 `datatype`。

**Intuition.** `and` 不是“并且”的英语。它是一个声明：这些 binding 同时进入环境。顺序规则在这一捆内部暂停。

**Why it exists.** 有限状态机、互相引用的树、以及任何“没有合理的先后顺序”的递归，都需要它。Workaround 存在，但更慢，不该成为常规风格。

**Problem solved.** 较早写下的函数可以调用较晚写下的函数，而不把整个文件的向前引用都放开。

整数常量可以出现在 pattern 里。他声明这是正交问题，不是本讲重点。下面例子用了 `1` 和 `2`，类型因此能被钉成 `int list`。那是 pattern 的类型事实，不是 `and` 的类型事实。

### 3. 状态机：两个函数谁也不是 helper

有限状态机处理未知长度的输入。处理过程中总处于有限个已知状态之一。读下一个元素，决定下一状态。输入结束时，某些状态接受，某些拒绝。每个状态写成一个函数。函数接收剩余输入，看第一个元素，调用代表下一状态的函数。

任何“一次看一个元素、状态只需有限种”的 list 处理都能写成这样。甚至可以把状态机描述自动译成一组互相递归函数。下面不是该问题的最简实现。它是一个特别简单的状态机。

```sml
fun match xs =
  let
    fun s_need_one xs =
      case xs of
          [] => true
        | 1::xs' => s_need_two xs'
        | _ => false
    and s_need_two xs =
      case xs of
          [] => false
        | 2::xs' => s_need_one xs'
        | _ => false
  in
    s_need_one xs
  end
```

接受空表，以及由 `(1, 2)` 重复、以 `2` 结束的表。其他 `int` 拒绝。类型他没有印出。从 pattern 里的 `1` 和 `2` 可得 `int list -> bool`。

```text
let 的环境里，s_need_one 与 s_need_two 同时存在。
不是先算出 s_need_one 的类型再看见 s_need_two。

match [1, 2, 1, 2]
  s_need_one 看到 1 → s_need_two [2, 1, 2]
  s_need_two 看到 2 → s_need_one [1, 2]
  s_need_one 看到 1 → s_need_two [2]
  s_need_two 看到 2 → s_need_one []
  [] 在 need_one → true

match [1]
  s_need_one 看到 1 → s_need_two []
  [] 在 need_two → false
  刚看过 1，还需要 2

match [1, 2, 3]
  最后在 s_need_one 看到 3 → false
```

空表在两个状态里答案不同。这就是状态。它不是 `null` 一个函数能表达的。

不用 `and`：`s_need_one` 调用 `s_need_two` 时，后者不在环境里。类型错误，或 unbound。不是运行时才发现。

### 4. 互相递归的 datatype 也是同一洞

```sml
datatype t1 = Foo of int | Bar of t2
and t2 = Baz of string | Quux of t1

fun no_zeros_or_empty_strings_t1 x =
  case x of
      Foo i => i <> 0
    | Bar y => no_zeros_or_empty_strings_t2 y
and no_zeros_or_empty_strings_t2 x =
  case x of
      Baz s => size s > 0
    | Quux y => no_zeros_or_empty_strings_t1 y
```

没有合理的先后顺序。`Bar` 持有 `t2`，`Quux` 持有 `t1`。两个函数同样互相调用。类型他没有印出。应为 `t1 -> bool` 与 `t2 -> bool`。

```text
Bar (Baz "")
  t1 函数走到 Bar
  调用 t2 函数
  size "" = 0
  false

Quux (Foo 0)
  t2 函数走到 Quux
  调用 t1 函数
  0 <> 0
  false
```

### 5. 没有 `and` 时的高阶函数绕道

不必须有语言特殊支持。较早的函数可以多接收一个参数：较晚的函数。调用较早的函数时，把较晚的函数传进去。

口述有口误，随后更正的一般模式是：earlier 多一个参数 `f`；调用 earlier 时传入 later。下面的调用形式按这个更正还原。幻灯片上的具体括号他没有逐字读完。

```sml
fun no_zeros_or_empty_strings_t1 (f, x) =
  (* f : t2 -> bool *)
  case x of
      Foo i => i <> 0
    | Bar y => f y

fun no_zeros_or_empty_strings_t2 x =
  case x of
      Baz s => size s > 0
    | Quux y => no_zeros_or_empty_strings_t1 (no_zeros_or_empty_strings_t2, y)
```

```text
t1 函数的环境里没有 t2 函数的名字。
它有参数 f。
调用 t1 时，f 被绑定到 t2 函数的闭包。
Bar y 时调用这个闭包，而不是查找一个还不存在的名字。
```

能工作。更慢。风格上想互相递归就用 `and`。这个绕道的意义是：互相递归不是新的计算能力。它是让两个名字同时进入环境的语法。高阶函数已经能传递“以后要调用的代码”。`and` 只是让这件事不必在每个调用点手工做。

| | `fun` 然后另一个 `fun` | `fun` ... `and` ... |
| --- | --- | --- |
| 定义 | 第二个 binding 进入环境时，第一个已经在；第一个的函数体看不见第二个 | 一捆 binding 同时进入环境 |
| 解决的问题 | 普通 helper 必须写在前面 | 谁也不是谁的 helper |
| 关键区别 | 顺序是语义 | 这一捆内部没有顺序 |
| 典型场景 | `countup_from1` 里的 `count`，或顶层先 helper 后主函数 | 状态机、互相引用的 datatype |

| | `and` | 把后定义的函数当参数传 |
| --- | --- | --- |
| 定义 | 同时绑定 | 较早的函数多一个函数参数 |
| 解决的问题 | 互相调用，且调用处不必每次传递 | 在没有 `and` 时打通“向后调用” |
| 关键区别 | 名字在两函数体里都可见；实现可以直接递归 | 多一次传参，更慢；类型里出现额外的函数参数 |
| 典型场景 | `s_need_one` / `s_need_two` | 上面的 `f` 参数 |

---

## 用透镜看类型推断

| 透镜 | 类型推断 |
| --- | --- |
| Syntax | 程序里可以没有类型注解。`'a` 是结果的写法，不是输入的写法 |
| Semantics | 寻找使既有 typing rules 成功的类型赋值。失败则程序没有求值语义 |
| Binding | 非互相递归时，绑定按顺序获得类型。`and` 使一捆绑定同时获得类型 |
| Scope | 类型在绑定的作用域内不变。遮蔽是新绑定的新类型，不是旧类型变了 |
| Evaluation | 推断在求值之前。它不跑 `if` 的测试，也不因 `if true` 丢掉 else |
| Type | 约束够则具体类型；不够则类型变量；非 value 的 `val` 右边不许泛化 |
| Lifetime | 类型不是运行时的值。`'a` 不活在闭包里 |
| Mutation | 多态地使用一个已经分配的盒子是 unsound 的。Value restriction 是对此的语法限制 |
| Abstraction | 推断不看模块里面藏了什么。所以不能只对 `ref` 特例。这正是下一章 signature 要利用的事实 |
| Composition | 函数应用把结果类型和下一个参数类型连成等式。`compose` 的三个变量就是这样连上的 |

---

## Connection to Modern Languages

这些是概念类比，不是等价。

- Java 在泛型出现之前没有类型变量。有了 generics 之后，多数多态方法仍要写下类型参数或依赖赋值目标的推断。它通常不是“从函数体收集约束，给出最一般类型”。`List.map` 在 Java 里不会因为你没写类型就得到 ML 的 `'a`。局部变量推断（`var`）填的是一个已经具体的类型，不是参数多态。
- C++ 的 template 在实例化时检查。它更像“为每种使用复制一份”，不是 Hindley–Milner 那种先给出一个最一般类型、再在使用处实例化。出错信息因此经常指向模板定义深处。ML 的报错是约束矛盾，而且只报告它先撞上的一条。
- Rust、Haskell、OCaml、Scala 都有某种推断。细节不同。Rust 常常要求函数签名上的类型，函数体内部再推断。这是“推断到哪里为止”的设计选择。ML 的选择是函数签名也可以不写。Value restriction 的具体规则也不要搬到这些语言上。OCaml 有类似的限制。Rust 用另一套所有权和可变性规则处理“多态和可变是否 unsound”。
- TypeScript 的推断常常是局部的，并且结构子类型使“至少有这些字段”成为常态。这正是本讲假想的 subtyping 困难：pattern 不再能说“恰好是这个 pair”。
- 动态语言的“不写类型”不是这一章的机制。Python 的注解是可选文档或给别的工具的。解释器不因为 `then` 是 `bool`、`else` 是 `int` 而拒绝函数定义。

---

## Section Review

不写类型时，ML 仍在运行前拒绝程序。推断要解的问题是：是否存在一组类型，使既有的检查规则成功。约束来自 pattern、运算符、函数应用和分支，不来自对算法的理解。约束够，类型被钉死。不够，未约束的变量一致地变成 `'a`、`'b`。条件表达式即使测试是 `true`，两条分支都参加类型。多态与 mutation 组合后，前面的泛化规则 unsound。因为 module 能藏住 `ref`，修复不能只针对 `ref`，于是任何非 value 的 `val` 右边都不能获得多态类型。互相递归需要 `and`，因为普通绑定按顺序进入环境，推断也按这个顺序工作。

### 核心概念

implicit vs explicit typing、static vs dynamic typing、type inference、type checking、constraint、type variable、parametric polymorphism、value restriction、soundness（此处只作为“阻止它声称要阻止的事”）、mutual recursion、`and`。

### 不变量

```text
不写类型 ≠ 动态类型。
推断失败 = 不存在使检查成功的类型赋值。
推断不理解程序做什么，只收集 type-checking facts。
同一个未约束变量必须换成同一个 'a。没有等式相连的变量必须换成不同字母。
if 的类型规则不使用“哪一支会执行”。
多态 × 已求值的可变盒子 = unsound，除非拒绝泛化。
Value restriction 看的是 val 右边是不是 syntactic value，不是有没有副作用。
没有 and，后定义的函数不在先定义的函数的环境里。
类型通过不表示终止，也不表示结果是你想要的值。
```

### 能力检查

真正理解这一节，应该能：

- 指出一个没写注解的 ML 函数为什么仍是静态类型，并举出一个运行前就被拒绝的 `if`。
- 对 `sum` 和 `length` 列出约束，说明哪一条事实把元素类型钉成 `int`，哪一个程序留下 `'a`。
- 解释 `if true` 为什么仍迫使两个分支类型相等。
- 说出 `ref NONE` 按旧规则如何把 string 读成 int，以及为什么“禁止多态的 `ref`”挡不住 type synonym。
- 说明 `val pairWithOne = List.map ...` 没有副作用却仍被拒，以及包一层 `fun` 改变的是语法形状不是算法。
- 说明两个状态函数为什么不能靠“把 helper 写在前面”解决，`and` 改变的是环境而不是计算能力。
