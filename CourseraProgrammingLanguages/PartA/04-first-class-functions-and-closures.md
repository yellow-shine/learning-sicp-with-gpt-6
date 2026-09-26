# 04 — 函数离开定义处之后，自由变量去哪了

> Part A · Section 3 前半
> 视频：`Introduction to First-Class Functions` 到 `Fold and More Closures`，以及 optional 的 Java / C 对照

到 Section 2 结束，函数是被调用的计算。它可以递归，可以嵌套，可以出现在 `let` 里。它还不能出现在其他值能出现的所有位置：做参数、做返回值、放进 tuple、放进 list。一旦它能，一个以前被调用栈藏住的问题就藏不住了。

```sml
fun f y =
    let
        val x = y + 1
    in
        fn z => x + y + z
    end

val g = f 4
val z = g 6
```

`f` 已经返回。按调用栈的旧图像，`x` 和 `y` 应该已经消失。`g 6` 仍然得到 `15`。问题不是“匿名函数怎么写”。问题是：

> 函数值被传到定义它的那次调用之外以后，它的自由变量为什么还在？

答案迫使语言把函数值实现成闭包（closure）：一段代码，加上定义时的词法环境。词法作用域（lexical scope）是规则。闭包是这条规则在“函数比那次调用活得更久”时的实现义务。

---

## 1. 为什么这一章不能放在 Section 1

Section 1 已经规定：调用在**定义时**的环境上扩展参数，再求值函数体。那时函数体里的名字要么是参数，要么是顶层绑定，定义时的环境和“现在的顶层环境”还分不开。所以动态作用域和词法作用域暂时给出同样结果。

必须先让函数成为值，才能把它从定义处搬走。搬走之后，调用处的环境和定义处的环境才成为两个东西。课程把动机视频也放在这一节之后：没有闭包的经验，那些关于“函数式语言超前几十年”的话没有所指。

依赖：函数是值、环境、嵌套函数、不可变绑定。准备：currying、callback、用闭包做抽象数据类型、解释器里的闭包表示、Ruby 的 block，以及 Part C 里“方法查找为什么不是闭包查找”。

---

## Lecture — 一等函数不是闭包

视频：`Introduction to First-Class Functions`。

### 问题

若函数不能出现在其他值能出现的位置，就无法把“变化的那一小段计算”单独传出去。你只能复制整段相似代码，或用一个不可扩展的 flag 区分 increment、double、nth-tail。第四种操作就要改公共函数。

他先拆开被混用的词 functional programming。对他，这是两个本来独立、因历史绑在一起的概念：

1. 避免 mutation。数据不活在可被改写的 location 里。已经学过。后面会看到可变状态有时是合理 idiom。
2. 把函数当值用。这一节的主题。

人们常附带联想到、但不是定义本身的东西：大量递归、list 和树、更数学的写法、Haskell 的惰性。他拒绝的粗定义：不是 OOP、不是 C，就算函数式。

“是不是 functional language”不是 yes/no。它的意思是：函数式写法在这门语言里是容易的、自然的、常规的，库也大体按这个风格写。几乎任何语言都能这么写，只是疼不疼、是不是默认。

### 机制

**Definition.** First-class function：函数可以出现在其他值能出现的位置。作参数，作结果，作 tuple 的分量，绑定到变量，放进 datatype 构造子。不需要新语言特性。只是以前没这样用已有特性。

**Definition.** Higher-order function：接受函数或返回函数的函数。它的用途是把共同的计算骨架抽出来。

**Definition.** Closure：使用了函数定义之外的绑定的函数值。技术上和 first-class 分开。函数式语言两者都有，术语常被混用。他不打算死抠日常误用，但概念区分仍然要紧：一个不捕获外部绑定的函数值，仍然是 first-class 的。

```sml
fun double x = 2 * x
fun increment x = x + 1

val a_tuple = (double, increment, double (increment 7))
val eighteen = (#1 a_tuple) 9
```

```text
a_tuple : (int -> int) * (int -> int) * int
第三分量是调用结果 16，不是函数。
REPL 印 (fn, fn, 16)。它不印函数体。

Expression: (#1 a_tuple) 9
  取出 double 这个函数值
  参数 9
Value: 18
```

#### Function value vs Function call

| | Function value | Function call |
|---|---|---|
| 定义 | 函数本身。`double`、`fn y => y + 1` | 把参数送给函数并求值函数体。`double 9` |
| 解决的问题 | 让计算可以被传递、存放、以后再做 | 现在就把计算做完 |
| 关键区别 | 类型是箭头。REPL 印 `fn` | 类型是箭头的结果类型。得到的是普通值 |
| 典型场景 | 放进 tuple、传给 `map` | `double (increment 7)` |

本例故意 silly。有用的形状是下一讲的抽骨架。

---

## Lecture — 高阶函数是抽象

视频：`Functions as Arguments` 到 `Map and Filter`，`Unnecessary Function Wrapping`。

### 问题

三个函数骨架相同：`n = 0` 就返回第二个参数，否则对递归结果做一件不同的事。

```sml
fun increment_n_times (n, x) =
    if n = 0 then x else 1 + increment_n_times (n - 1, x)

fun double_n_times (n, x) =
    if n = 0 then x else 2 * double_n_times (n - 1, x)

fun nth_tail (n, xs) =
    if n = 0 then xs else tl (nth_tail (n - 1, xs))
```

没有一等函数时，只能复制三份，或用 flag。Flag 不可扩展。他说：the only way we can do this without first class functions is some ugly kluge。

### 机制

```sml
fun n_times (f, n, x) =
    if n = 0
    then x
    else f (n_times (f, n - 1, x))
```

类型是 `('a -> 'a) * int * 'a -> 'a`。

读这行的方法：`f` 吃一个 `'a`、吐一个 `'a`。`x` 是 `'a`。结果也是 `'a`。因为 `f` 的结果会再喂给 `f`，输入和输出必须是同一种类型。`n` 是次数，和 `'a` 无关。

```text
n_times (double, 4, 7)
  'a = int
  Value: 112

n_times (tl, 2, [4, 8, 12, 16])
  'a = int list
  Value: [12, 16]
```

多态和“函数当参数”是两件独立的事。混在一起是因为有用的高阶函数常常两者都有。`times_until_zero` 只处理 `int`，仍然是高阶的：`(int -> int) * int -> int`。`length` 是多态的，不是高阶的：`'a list -> int`。

为什么这是抽象，不是“把函数传来传去”的技巧：

```text
抽象 = 把会变的部分变成参数，把不变的结构留在一个地方
```

`n_times` 不变的结构是“做 n 次”。变的是“做哪一种一次”。调用者用一个小函数描述差异。公共函数不必知道 increment 和 double 的存在。加第三种操作不改 `n_times`。这和 module 的边界是同一种想法的更小版本：客户依赖的是骨架的类型，不是骨架内部的递归。

`map` 和 `filter` 是同一抽象的两个进入公共词汇的名字。若语言有一等函数，你可以自己定义，不必等语言内置。

```sml
fun map (f, xs) =
    case xs of
        [] => []
      | x :: xs' => (f x) :: map (f, xs')

fun filter (f, xs) =
    case xs of
        [] => []
      | x :: xs' => if f x
                    then x :: filter (f, xs')
                    else filter (f, xs')
```

`map` 的类型是 `('a -> 'b) * 'a list -> 'b list`。这里输入和输出可以不同。`n_times` 不能，因为同一种 `f` 要反复用在自己的结果上。`filter` 是 `('a -> bool) * 'a list -> 'a list`。谓词不改变元素类型。

```sml
val x1 = map (fn x => x + 1, [4, 8, 12, 16])
(* [5, 9, 13, 17] *)
```

匿名函数（anonymous function）是表达式，不是绑定：

```text
fn pattern => expression
```

`fun triple x = 3 * x` 等价于 `val triple = fn x => 3 * x`。`fun` 绑定不是表达式，所以不能写在参数位置。`fn` 可以。只在一个地方用一次的函数，不该进入顶层，也不该为了算出一个函数值再立刻返回而写一个 `let`。

刚学会 `fn` 之后会多包一层。`fn y => tl y` 就是 `tl`。多一层更长，多一次调用，掩盖“我们要的就是那个函数”。`val rev = List.rev` 好。`fun rev xs = List.rev xs` 是 unnecessary wrapping。递归函数不能总是这样简化：`fun` 会把名字放进函数体的环境，`val rec` 才是对应物。非递归时，包装没有带来名字，就不要包。

函数还可以作为返回值，也可以在自定义 datatype 上做遍历。`double_or_triple` 根据 `f 7` 返回 doubling 或 tripling。REPL 把 `(int -> bool) -> (int -> int)` 印成 `(int -> bool) -> int -> int`，因为 `->` 右结合。这不是三个参数。这是“返回一个函数”的类型糖。Currying 要到后面才把这种类型变成 idiom。这里先认出括号可以省。

`true_of_all_constants` 把“对每个常量问一个谓词”从 `eval` 那种递归里抽出来。表达式树的形状写一次。谓词由调用者给。这就是“高阶函数是抽象”在递归数据类型上的样子，不只在 list 上。

---

## Lecture — 词法作用域，然后才是闭包

视频：`Lexical Scope`，`Lexical Scope and Higher-Order Functions`，`Why Lexical Scope`。

### 问题

函数体可以使用参数之外、定义时已经在环境里的名字。这些名字是自由变量（free variables）。一旦函数被传来传去，问题变成：自由变量用哪一个环境？

用调用处的，是动态作用域（dynamic scope）。用定义处的，是词法作用域（lexical scope）。

```sml
val x = 1
fun f y = x + y
val x = 2
val y = 3
val z = f (x + y)
```

词法作用域：`z` 是 `6`。动态作用域：`z` 是 `7`。

```text
定义 f 时的动态环境：x → 1

词法：
  f 的函数值 =
    code: fn y => x + y
    environment: x → 1
  后来的 val x = 2 是遮蔽，不修改这个环境
  调用 f (x + y)：参数先算成 2 + 3 = 5
  函数体在闭包的环境里扩展 y → 5
  x + y = 1 + 5 = 6

动态：
  调用时的环境里 x → 2，y 被参数遮成 5
  自由变量 x 查到 2
  2 + 5 = 7
```

同一个程序，两条规则，两个结果。现代语言几乎都选词法作用域。这不是口味。动态作用域直接破坏三种推理。你可以不在乎这些理由，但不能说它们不存在。

### 为什么几乎所有现代语言选 lexical scope

**1. 函数的含义在定义处就能看完。**

```sml
fun f1 y =
    let val x = y + 1
    in fn z => x + y + z end

fun f2 y =
    let val q = y + 1
    in fn z => q + y + z end

val x = 17
val a1 = (f1 7) 4   (* 19 *)
val a2 = (f2 7) 4   (* 19 *)
```

在词法作用域下，把局部变量从 `x` 改名为 `q` 不改变含义。没有使用处的自由变量叫 `x`。在动态作用域下，`f1` 返回的函数在被调用时会去调用者的环境里找 `x`，而调用者那里有 `x → 17`。改个局部名字会改变结果。局部改名不是等价变换。这使程序无法局部理解。

**2. 类型检查可以在定义处做完。**

```sml
fun f y =
    let val x = y + 1
    in fn z => x + y + z end

val x = "hi"
val g = f 7
val n = g 4   (* 19 *)
```

词法作用域下，返回的函数里的 `x` 是 `int`。后来顶层把 `x` 绑成字符串，与这个函数无关。动态作用域下，调用 `g` 时自由变量 `x` 可能是字符串，加法在运行时才失败。类型系统若要 sound，就不能在定义处给这个函数一个 `int -> int`。动态作用域和静态类型很难共存。这是选择词法作用域的工程理由，不只是可读性。

**3. 闭包可以携带调用者不该看见的数据。**

`filter` 的参数类型是 `'a -> bool`。`greaterThanX` 需要记住阈值，但阈值不应该出现在传给 `filter` 的函数类型里。否则 `filter` 的作者必须知道每个客户的私有数据长什么样，库就写不出来。

```sml
fun greaterThanX x =
    fn y => y > x
(* int -> (int -> bool)
   他口头一度说成 int arrow int。y > x 是 bool。那是口误。 *)

fun allGreater (xs, n) =
    filter (fn x => x > n, xs)
```

`allGreater` 传给 `filter` 的函数类型正好是 `int -> bool`。`n` 在闭包的环境里，不在类型里。动态作用域做不到这一点：调用 `filter` 时，`filter` 自己的局部变量会挡住或冒充客户的 `n`。客户要么把 `n` 做成全局变量，要么改 `filter` 的类型，把环境显式传进去。C 的对照在本章末尾。

### 闭包是什么

**Definition.** Closure = function code + lexical environment。环境里至少要有函数体的自由变量在定义时的绑定。调用时：用这份环境，不是用调用者的环境；再加上这次的参数；再求值代码。

**Intuition.** 函数值把定义时的电话簿抄走了。以后无论在谁的办公室里打电话，自由变量仍查那本电话簿。

**Why it exists.** 词法作用域加上“函数值比定义它的那次调用活得更久”。调用栈存不住那本电话簿。必须把它和代码放在一起，放在堆上。

**Problem solved.** 返回的函数、传给库的回调、部分应用，都能在定义处的绑定已经离开栈之后继续使用那些绑定。

```sml
val x = 1
fun f y =
    let
        val x = y + 1
    in
        fn z => x + y + z
    end
val x = 3
val g = f 4
val y = 5
val z = g 6
```

```text
Expression: f 4
  参数 y → 4
  let 绑定 x → 5          （遮住外层，无论外层 x 是 1 还是后来的 3）
  返回的闭包：
    code: fn z => x + y + z
    env:  x → 5, y → 4

后来的 val y = 5 与这个闭包无关。

Expression: g 6
  在闭包的环境上扩展 z → 6
  5 + 4 + 6
Value: 15
```

再看一个“删掉未使用的局部变量不会改变行为”的例子。这在动态作用域下是假的：

```sml
fun f g =
    let
        val x = 3
    in
        g 2
    end

val x = 4
fun h y = x + y
val z = f h
```

`h` 的闭包环境是 `x → 4`。`f` 里的 `x → 3` 没被使用，删掉它，`z` 仍是 `6`。动态作用域下，`g 2` 发生在 `f` 的 `let` 里面，自由变量 `x` 会查到 `3`，`z` 变成 `5`。于是“这个局部变量没有被函数体提到”不再是可以安全删除的判断。调用者的内部绑定会泄漏进被调用的函数。这是动态作用域最实用的反面教材。

### 闭包也是避免重复计算的地方

传给 `filter` 的函数会对每个元素调用一次。若函数体里有一段只依赖外层参数的计算，每次都重算。

```sml
fun allShorterThan1 (xs, s) =
    filter (fn x => String.size x < String.size s, xs)

fun allShorterThan2 (xs, s) =
    let
        val i = String.size s
    in
        filter (fn x => String.size x < i, xs)
    end
```

在 `String.size s` 旁边打印。长度为 4 的 list，第一个版本打印四次，第二个打印一次。闭包捕获的是已经算完的 `i`，不是“以后再算 size”的表达式。这只有在绑定是 eager 的时候才成立。闭包捕获的是环境里的值，不是捕获一段还会变的源码。

```text
let 之后：s → 那个字符串，i → 3
闭包：
  code: fn x => String.size x < i
  env:  i → 3
每次调用只 lookup i
```

`fold` 把“如何结合元素”和“如何走 list”分开。

```sml
fun fold (f, acc, xs) =
    case xs of
        [] => acc
      | x :: xs' => fold (f, f (acc, x), xs')
(* ('a * 'b -> 'a) * 'a * 'b list -> 'a *)
```

`map` 产生同形 list。`filter` 产生子集。`fold` 把整个 list 收成一个答案。写数据结构的人提供 `fold`。写结合函数的人不知道递归。闭包让结合函数带上 `low`、`high`、字符串长度，而不改 `fold` 的类型。

```sml
fun f3 (xs, low, high) =
    fold (fn (x, y) =>
            x + (if y >= low andalso y <= high then 1 else 0),
          0, xs)
```

这里的 `fn` 捕获 `low` 和 `high`。`fold` 只看见 `('a * int -> 'a)` 这种形状。私有数据不出现在迭代器的类型里。这就是闭包作为抽象边界的最小形式。Module 用 signature 隐藏类型。闭包用函数类型隐藏环境。

---

## 没有闭包时，环境必须变成显式参数

Optional：`Closure Idioms Without Closures`，Java，C。

这些讲不是在教 Java 或 C。它们在回答：若语言不把环境藏进函数值，上一章的 idiom 还在不在？

在。但你要手工构造那本电话簿。

Java（针对当时没有 lambda 的核心；他提到 Java 8 会补上更接近 ML 的东西）用只有一个方法的接口模拟函数，用匿名内部类的字段模拟环境。`countNs` 的 `n` 必须是 `final`，内部类才能捕获它。对象和闭包的共同点：有一部分数据不出现在接口类型里。`Pred<Integer>` 只有 `m`。`n` 是对象的状态，不是接口的一部分。

C 更干净地露出缺口。函数指针是 first-class 的：可以传递、放进数据结构。它只有 code，没有定义处的环境。函数只能用自己的参数和全局变量。`double` 可以做。`countNs` 做不了，因为 `n` 无法回到比较函数里。惯例是额外传一个 `void *env`，由客户自己转换成真正的数据。函数指针类型因此必须提到 `env`。ML 的 `int -> bool` 不必提到 `n` 的类型。这个差别就是闭包。

他不是说 Java 和 C 写不了这些程序。Turing tarpit：凡是图灵完备的语言都能写。痛、容易错、类型擦成 `void *`，就是没有这个机制时的代价。

---

## 对照

### Lexical scope vs Dynamic scope

| | Lexical scope | Dynamic scope |
|---|---|---|
| 定义 | 自由变量在函数定义处的环境里查找 | 自由变量在函数调用处的环境里查找 |
| 解决的问题 | 让函数的含义不依赖谁调用了它 | 让调用者的绑定自动对被调用者可见。早期实现也更简单 |
| 关键区别 | 局部改名、删除未使用变量、定义处的类型检查，都站得住 | 调用者的局部变量会泄漏进被调用函数。类型常常要留到运行时 |
| 典型场景 | ML、Racket、Ruby、Java、JavaScript、几乎所有现代语言 | 早期 Lisp 的一种实现；今天只在极少数特殊机制里残留（例如某些 shell、Emacs 的动态变量） |

### Closure vs Anonymous function

| | Closure | Anonymous function |
|---|---|---|
| 定义 | 代码加上它的词法环境 | 没有顶层名字的函数表达式。`fn x => ...` |
| 解决的问题 | 自由变量在定义处的绑定比调用栈活得更久 | 避免为只用一次的函数发明名字 |
| 关键区别 | 有名的 `fun f y = x + y` 同样是闭包，只要它使用了外部的 `x`。不使用外部绑定的 `fn x => x + 1` 不必捕获任何东西 | 匿名只是语法。它不决定环境 |
| 典型场景 | 返回的函数、回调、部分应用 | 传给 `map` 的一次性函数 |

### First-class function vs Higher-order function

| | First-class | Higher-order |
|---|---|---|
| 定义 | 函数可以出现在值能出现的位置 | 一个函数的参数或结果是函数 |
| 解决的问题 | 函数成为普通值 | 把计算骨架和变化的步骤分开 |
| 关键区别 | 说的是值的地位 | 说的是某个函数的类型形状 |
| 典型场景 | 放进 tuple | `map`、`filter`、`fold`、`n_times` |

---

## Connection to Modern Languages

概念类比。

- JavaScript 的函数闭包、Python 的嵌套函数、Go 的 closure、Rust 的 closure、C++ lambda、Java lambda，都是“代码 + 定义处环境”。差别在捕获的是值还是盒子，以及默认是否可改。
- JavaScript 的 `var` 捕获的是可变绑定。循环里造闭包会都看见最后一次赋值。ML 的 `val` 捕获的是不会被赋值改掉的绑定。这是 shadowing 与 mutation 的区别在闭包上的后果，不是闭包“在 JS 里是坏的”。
- C++ lambda 的 `[=]` 按值捕获，`[&]` 按引用捕获。按引用捕获而引用的对象已销毁，是 ML 不会有的生命周期问题。ML 的环境由垃圾回收保住。Rust 把这件事放进类型系统。
- Python 的闭包默认不能给外层变量赋值，除非 `nonlocal`。这接近“捕获的不是默认可变盒子”。但捕获的对象若是 list，对象内容仍可变。
- Java 8 之后的 lambda 使 `map` / `filter` 不再需要手写接口。Grossman 在 optional 讲里预告的就是这件事。机制补上了，语义问题没有消失：lambda 捕获的变量是否可变，仍然要单独问。

---

## 这一章的不变量

```text
first-class ≠ closure
closure = code + lexical environment
自由变量在定义处查找，不在调用处查找
调用仍是三步：求函数值（得到闭包），求参数，在闭包的环境上扩展参数再求值函数体
闭包捕获的是绑定。不可变绑定时，捕获的是值
高阶函数是抽象：不变的骨架留在一处，变化的步骤变成函数参数
函数类型不提到环境里的数据。这就是闭包提供的隐藏
```

Currying、callback、用 record of closures 做集合，是同一语义的惯用法，不是新规则。下一章只加惯用法，以及一个显式的可变盒子。
