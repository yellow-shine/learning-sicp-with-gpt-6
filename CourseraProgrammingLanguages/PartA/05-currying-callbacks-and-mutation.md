# 05 — 闭包的惯用法，以及何时才该有一个盒子

> Part A · Section 3 后半
> 视频：`Combining Functions` 到 `ADTs with Closures`

上一章的规则已经够用。这一章不再增加作用域规则。它回答：闭包一旦存在，哪些以前要特殊语法或全局变量的事，变成普通函数值就能做？以及：若问题本身就是“所有人看见同一处更新”，不可变默认该在哪里开口，而不是把每个名字都变回盒子。

---

## Lecture — 组合函数：返回之后，`f` 和 `g` 还在

视频：`Closure Idiom: Combining Functions`。

### 问题

已经会把函数传给迭代器。下一个问题是如何把已有函数组成新函数。组合出来的函数在以后被调用时，仍要找到当时的 `f` 和 `g`。若没有闭包，组合函数返回之后，`f` 和 `g` 只是调用栈上的参数，无法存活。

```sml
fun compose (f, g) = fn x => f (g x)
(* ('b -> 'c) * ('a -> 'b) -> ('a -> 'c) *)
```

```text
Expression: compose (Math.sqrt, someIntToReal)
Value: 一个闭包
  code: fn x => f (g x)
  env:  f → Math.sqrt, g → someIntToReal

以后调用这个闭包，才求 f (g x)。
定义 compose 时不调用 f 和 g。
```

这就是函数组合（function composition）。`o` 是库里的中缀形式。`sqrt_of_abs` 可以写成 `Math.sqrt o Real.fromInt o abs`。最后这个版本去掉了 unnecessary wrapping：组合的结果已经是函数，不必再写 `fun sqrt_of_abs i = ... i`。

管道的方向相反时，他用一个小中缀：

```sml
infix !>
fun x !> f = f x

fun sqrt_of_abs i =
    i !> abs !> Real.fromInt !> Math.sqrt
```

`backup1` 把“`f` 返回 `NONE` 就改调 `g`”收成一个函数。`backup2` 把“`f` 抛任何异常就改调 `g`”收成一个函数。两者都是返回闭包。差别是失败走 option 还是走 `exn`。闭包不关心失败的机制。它只负责把两个函数留下来。

---

## Lecture — Currying 不是多参数的另一种拼写

视频：`Currying`，`Partial Application`，`Currying Wrapup`。

### 问题

ML 每个函数恰好一个参数。以前用 tuple 装 n 个参数。另一种做法：接收第一个参数，返回一个函数去接收下一个。返回的函数仍能用第一个参数，因为它在闭包的环境里。这叫 currying，来自 Haskell Curry 的名字。他曾多年以为这个词描述的是某种加工。它只是人名。

```text
int * int * int -> bool
```

和

```text
int -> int -> int -> bool
```

不是同一类型的两种写法。前者吃一个三元组，返回 `bool`。后者吃一个 `int`，返回一个函数。`->` 右结合，所以它是 `int -> (int -> (int -> bool))`。

```sml
fun sorted3_tupled (x, y, z) =
    z >= y andalso y >= x

val sorted3 = fn x => fn y => fn z => z >= y andalso y >= x

fun sorted3_nicer x y z =
    z >= y andalso y >= x
```

第三种是糖。展开后就是第二种。调用 `sorted3 7 9 11` 是 `((sorted3 7) 9) 11` 的糖。

```text
Expression: sorted3 7
Value: closure
  code: fn y => fn z => z >= y andalso y >= x
  env:  x → 7

Expression: 那个闭包，参数 9
Value: closure
  code: fn z => z >= y andalso y >= x
  env:  x → 7, y → 9

Expression: 那个闭包，参数 11
Evaluation: 11 >= 9 andalso 9 >= 7
Value: true
```

没有新的求值规则。三次调用，每次返回或使用一个闭包。糖只是让定义和调用看起来像多参数函数。

### Partial application 不是第三个特性

Currying 不只是模拟多参数。故意少传参数，得到的闭包还在等剩余参数。没有新语义：调用一个返回函数的函数，把结果存起来，本来就合法。这叫部分应用（partial application）。

```sml
val isNonNegative = sorted3 0 0
(* 等待 z。计算 z >= 0 andalso 0 >= 0 *)

val hasZero = exists (fn x => x = 0)
(* int list -> bool *)

val incrementAll = List.map (fn x => x + 1)
```

`fun isNonNegative x = sorted3 0 0 x` 更长，等价，是 unnecessary wrapping。

部分应用和 currying 的区别：

| | Currying | Partial application |
|---|---|---|
| 定义 | 把吃一个 tuple 的函数改成一串返回函数的函数。是类型和定义的形状 | 对已经 curried 的函数少传一些参数，把返回的函数留下来用 |
| 解决的问题 | 让“先固定前面的参数”在类型上自然 | 实际写出那个被固定了前几个参数的函数 |
| 关键区别 | 一种函数怎么定义 | 一种调用怎么用。对 tupled 函数不能部分应用，除非先 `curry` |
| 典型场景 | `fun fold f acc xs = ...` | `val sumAll = fold (fn (x, y) => x + y) 0` |

Tupled 函数想部分应用，或 curried 函数想放进期待 tuple 的位置，或想先固定的是后面的参数而不是前面的：不要改原函数。写一次转换器。

```sml
fun curry f x y = f (x, y)
fun uncurry f (x, y) = f x y
fun other_curry f x y = f y x
```

`curry` 的类型是 `('a * 'b -> 'c) -> 'a -> 'b -> 'c`。`uncurry` 相反。`other_curry` 交换参数顺序，因为 curried 调用必须先传第一个参数。这些转换器自己也是返回闭包的高阶函数。

多态的部分应用会撞上 value restriction。`List.map (fn x => (x, 1))` 的类型本应是 `'a list -> ('a * int) list`。写成 `val pairWithOne = ...` 时，ML 警告 type vars not generalized，结果不能再被调用。原因的完整故事在 Section 4：若允许把一个尚未确定的多态类型推广到一个 `val` 绑定上，而右边可以有副作用，类型系统会 unsound。这里先看见现象。绕过的办法是写成 `fun`，或给一个更具体的类型注解。`fn x => x + 1` 不警告，因为从函数体已经知道只能用于 `int`。

Currying 要创建一串闭包。他问这是不是很慢。对课程里的程序，不是你该先担心的代价。闭包是一个小对象。真正贵的是你在闭包里做的计算，不是闭包本身。实现也可以对已知全部参数的调用不分配中间闭包。那是优化，不是语义。

函数式语言喜欢 currying，因为部分应用是组合的默认路径：库函数 curried 之后，客户用一次调用就得到一个能传给别的高阶函数的特化版本。Tuple 版本每次都要把所有参数凑齐。两种都能写完全部程序。方便的是惯用法，不是表达能力。Turing tarpit 再次适用。

---

## Lecture — 可变引用：盒子是显式的

视频：`Mutable References`。

### 问题

课程一直说不需要 mutation，alias 会破坏局部推理，不可变是好默认。但有些问题的模型本身就是共享状态的更新：所有能访问该状态的人都应看到更新。下一讲的 callback 库就是这种模型。若语言把一切都变成可变的，就会在模型不需要变化的地方也担心变化。

ML 的选择：变量、tuple、list 不可变。只有单独的 reference 的内容可更新。

```sml
val x = ref 42
val y = ref 42
val z = x
val _ = x := 43
val n = !y + !z
```

```text
x = ref 42
  x → 盒子 A
  A 的内容是 42

y = ref 42
  y → 盒子 B
  B 的内容是 42
  A 与 B 不是同一个盒子。相等的内容不是相同的身份

z = x
  z → 盒子 A
  x 与 z 是 aliases

x := 43
  A 的内容变成 43
  B 仍是 42

!y + !z = 42 + 43 = 85
```

`ref e` 求值 `e`，分配一个盒子，返回盒子。类型是 `t ref`，若 `e : t`。`!` 读内容。`:=` 写内容，结果是 `()`。`!` 不是布尔否定。前面说过 `not` 才是。

闭包捕获 `ref` 时，捕获的是盒子，不是盒子当时的内容。以后 `:=` 对所有 alias 可见，包括藏在闭包环境里的那个名字。这是 shadowing 与 mutation 最容易混的地方：

```sml
val r = ref 0
val f = fn () => !r
val r = ref 1          (* 遮蔽。f 的环境里仍是第一个盒子 *)
val _ = (第一个盒子) := 2
```

`f ()` 看见 `2`，不是 `1`。新的 `r` 是另一个盒子。闭包没有被遮蔽改写。它持有的盒子被赋值改写了。

作业仍禁止用 `ref`。作业里的问题不会因可变引用更容易。这讲插在这里，只因为下一个 idiom 的例子要用。

#### 受控 mutation 不是“函数式禁止状态”

Functional programming 不等于不允许状态。等于：状态不是每个绑定的默认含义。需要共享更新时，类型里出现 `ref`。不需要时，alias 仍不可观察。局部推理在不可变数据上保留，在你显式画出的盒子上放弃。放弃的范围是你写出来的，不是语言偷偷给你的。

---

## Lecture — Callback：库不能知道客户的私有数据

视频：`Closure Idiom: Callbacks`。

### 问题

库需要在以后某个事件发生时执行客户代码：键盘、鼠标、数据到达、轮到某玩家。客户必须把“以后调用的行为”传给库。若只传函数指针而没有闭包，每个客户无法携带自己的私有数据。若私有数据出现在回调类型里，库的实现者就得知道每个客户的数据类型，库无法写。

```sml
val cbs : (int -> unit) list ref = ref []

fun onKeyEvent f =
    cbs := f :: (!cbs)

fun onEvent i =
    let
        fun loop fs =
            case fs of
                [] => ()
              | f :: fs' => (f i; loop fs')
    in
        loop (!cbs)
    end
```

`onKeyEvent` 的类型是 `(int -> unit) -> unit`。库保存一列函数。事件发生时对每个函数调用一次，参数是按键。库不知道、也不该知道这些函数的环境里有什么。

```sml
val timesPressed = ref 0
val _ = onKeyEvent (fn _ => timesPressed := !timesPressed + 1)

fun printIfPressed i =
    onKeyEvent (fn j =>
        if i = j
        then print ("you pressed " ^ Int.toString i ^ "\n")
        else ())
```

```text
printIfPressed 11 创建闭包：
  code: fn j => if i = j then print ... else ()
  env:  i → 11

onKeyEvent 把这个闭包 cons 到 cbs 指向的 list。
以后 onEvent 11：
  j → 11
  比较用捕获的 i，不是库的局部变量
```

`timesPressed` 是另一个闭包捕获的盒子。每次按键，所有注册过的回调都被调用。计数的那个闭包通过 `:=` 更新盒子。打印的那个闭包不共享这个盒子，除非你把同一个 `ref` 传给它。共享是显式的。

回调是闭包的库设计形态：注册时捕获客户状态，触发时库只提供事件数据。GUI、Promise 的 then、浏览器的事件监听，都是这个形状。语法不同。缺少的若是闭包，客户就得把状态放进全局表，并用整数 id 自己查。那能工作。它是把环境从语言里搬回程序员手里。

---

## Lecture — 用闭包做抽象数据类型

视频：optional `Abstract Data Types with Closures`。

### 问题

一个抽象需要多个操作：insert、member、size。这些操作必须共享一份客户看不见的数据。若把表示交给客户，客户可以破坏不变量：插入重复元素，或绕过接口改 list。OOP 会把私有字段和多个方法放进一个对象。这里不用新语言特性。用 record of closures：每个字段是函数，所有函数捕获同一份私有数据。客户只能调用函数。

这是课程里第一次暗示 OOP 与函数式有深层相似。不熟悉 OOP 也没关系。它就是闭包。

```sml
datatype set = S of {
    insert : int -> set,
    member : int -> bool,
    size : unit -> int
}

fun make_set xs =
    let
        fun contains i =
            List.exists (fn j => i = j) xs
    in
        S {
            insert = fn i =>
                if contains i then make_set xs
                else make_set (i :: xs),
            member = contains,
            size = fn () => length xs
        }
    end

val empty_set = make_set []
```

`xs` 不在 `set` 的类型里。客户拿到 `S s1` 之后只能用三个函数。`insert` 返回一个新的 `set`，不是修改旧的。不可变仍然在：更新是造一个捕获了新 list 的新闭包记录。`member` 直接就是 `contains`，不必再包一层。

```text
empty_set 的闭包们共享 xs → []

#insert s1 34
  34 不在 xs 里
  make_set (34 :: [])
  新的三个闭包共享另一份 list

再 insert 34
  contains 为真
  返回捕获原 list 的 set，不增长

size () 读的是它自己闭包里的 xs 的长度
```

`use_sets` 的结果是 `18`：`19` 在集合里，所以走 `17 + size`。`s3` 在插入 `19` 之前，大小是 `1`。

这个表示和对象的差别，Part C 会钉死：对象的方法查找发生在调用时，`self` 绑定到接收者，子类可以覆盖被继承方法调用的另一个方法。这里的闭包在构造时就已经抓住了 `contains` 和 `xs`。没有“以后换一个 insert 的实现，旧的 member 会跟着走”的动态派发。相似的是打包和隐藏。不同的是查找时间。

---

## 用透镜看 curried 调用和 `ref`

| 透镜 | `sorted3 7` | `x := 43` |
|---|---|---|
| Syntax | 函数应用，看起来像少传了参数 | 中缀赋值，结果是 `unit` |
| Semantics | 一次普通调用，返回闭包 | 修改盒子内容，不产生新绑定 |
| Binding | 闭包环境里新增 `x → 7` | 不新绑定。`x` 仍指向同一个盒子 |
| Scope | 返回的函数按词法环境找 `x` | `!` 和 `:=` 通过盒子身份看见内容，不通过名字的历史 |
| Evaluation | 立即返回函数，不看后面的参数 | 立即写 |
| Type | `int -> int -> bool`，若 `sorted3 : int -> int -> int -> bool` | `int ref * int -> unit` 这一类 |
| Lifetime | 闭包保住 `7`，即使调用 `sorted3` 的栈帧结束 | 盒子活到没有引用指向它 |
| Mutation | 无 | 这就是 mutation |
| Abstraction | 部分应用隐藏已固定的参数 | 类型 `t ref` 把可变性写在边界上 |
| Composition | 结果可再应用、可传入 `map` | 多个名字 alias 同一个盒子，更新对所有 alias 可见 |

---

## Section 3 Review

Section 3 解决的是：函数成为值之后，自由变量必须有一条不依赖调用者的查找规则；这条规则的实现是闭包；闭包然后成为抽象的载体。`map`、`filter`、`fold` 抽走遍历。组合函数、currying、部分应用、回调、record of closures，都是“代码加上定义时的环境”的用法，不是新语义。`ref` 是在这个模型上开的一个显式口子，给那些真正需要共享更新的问题。

### 不变量

```text
closure = code + lexical environment
currying ≠ partial application
int * int -> int  ≠  int -> int -> int
部分应用没有新的求值规则
ref 捕获的是盒子，遮蔽捕获的是另一个绑定
回调的类型不提到客户的私有数据
用闭包做的 set 没有动态派发
函数式 ≠ 禁止状态
```

### 能力检查

- 给同一个小程序分别算出词法作用域和动态作用域的结果，并指出自由变量在哪一步被查找。
- 画出 `f 4` 返回的闭包，标出环境里有什么、后来的同名 `val` 为什么改不了它。
- 把一个 tupled 函数 partial-apply 失败的原因说成类型形状，而不是“ML 不让少传参数”。
- 说明 `x` 和 `z` 指向同一盒子时，`z := 1` 为什么改变 `!x`，以及一个只捕获了另一个 `ref` 的闭包为什么不变。
- 解释回调类型里为什么不能出现客户的计数器类型。

练习：`exercises/section-03.md`。
