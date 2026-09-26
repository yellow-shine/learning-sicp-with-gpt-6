# 02 — 没有赋值，计算如何进行

> Part A · Section 1 后半
> 视频：`05`–`16`

上一章的程序只会绑定已经算完的值。那还不是一门语言。你需要把“取参数、算结果、返回”做成可复用的东西，需要一次交出多块数据，需要长度到运行时才知道的数据，需要局部名字，还需要一个办法表达“可能没有”。

这一章仍然没有 assignment。这不是功能缺失。这是把 alias 从推理负担里拿掉。

---

## 1. 这一章要解决什么问题？

如果函数体在 `fun` 被写下时就执行，递归无法定义：那时还没有参数，函数也还不是一个可以调用自己的值。如果调用时不先把参数求成值，函数体就会看见调用点的表达式，环境故事泄漏到被调用者里面。如果空 list 没有定义好的答案，递归没有底座。如果空 list 的最大值返回 `0`，你是在用一个 `int` 假装两种不同的结果。如果 pair 和 list 可以事后改内容，`sort_pair` 返回原 pair 还是返回拷贝就会被调用者观察到。

课程把这些放在 datatype 和一等函数之前，是因为它们是环境模型的第一次非平凡使用。函数调用就是：扩展**定义时**的环境，再求值函数体。`let` 是同一种环境扩展，只是作用域到 `end` 为止。没有 mutation，是为了让“共享尾巴”和“复制一份”对客户不可区分。

依赖：binding、静态/动态环境、表达式的三问、`if` 只求一边。准备：datatype（list 和 option 其实就是 datatype）、高阶函数（函数已经是值）、闭包（调用已经在使用定义时的环境）。

---

## Lecture — 函数：非正式，然后正式

视频：`Functions Informally`，`Functions Formally`。

### 1. 先遇到的困难

只有 `val` 时，幂运算写一次就没了。若函数体不能调用自己，你无法把 `pow(x, y)` 定义成“更小的问题” `pow(x, y - 1)`。这不是循环定义。`y = 0` 时返回 `1`，不再调用自己。递归在这里是重复的默认写法。本课不用 `while` / `for`。循环能做的，递归都能做。在别的语言里循环常常更方便或更高效。那不是这里的 idiom。

函数像方法，但更简单：拿参数，算结果，返回。没有对象。一律叫 function。程序现在是一串变量绑定和函数绑定。

### 2. 核心概念

#### Function binding 与 Function call

**Definition.** 函数绑定

```text
fun x0 (x1 : t1, ..., xn : tn) = e
```

把名字 `x0` 加入动态环境，值是这个函数。函数体 `e` **不**在定义时求值。函数已经是一个 value。

类型检查：在原静态环境加上 `x1 : t1, ..., xn : tn`，再加上 `x0 : t1 * ... * tn -> t`（这样递归调自己才能通过类型检查），检查 `e` 得到 `t`。`t` 不由程序员写出。然后只把 `x0` 的函数类型留在绑定之后的静态环境里。参数名 `x1..xn` 不泄漏到函数外面。

函数调用 `e0 (e1, ..., en)` 分三步：

1. 求值 `e0`，得到一个函数。
2. **先**把每个参数求成值 `v1..vn`。函数体看不见参数表达式，只看见值。
3. 在**函数被定义时**的动态环境上，扩展 `xi → vi`，并把函数名绑定到它自己，然后求值函数体。

恰好一个参数时括号可省略。零个或多个参数时括号必需。

**Intuition.** `fun` 是在造一个值。调用才是在用那个值。调用不是把调用点的源码送进函数，而是把已经算完的值送进一个从定义处接出来的环境。

**Why it exists.** 没有“定义时不求值函数体”，递归和“函数是值”同时崩溃：定义时还没有参数。没有“先求参数”，`pow(2, 2 + 2)` 的函数体会看见加法表达式，而不是 `y = 4`。没有“用定义时的环境”，自由变量的含义要等看到调用者才知道。这个第三步就是词法作用域。名字要到 Section 3 才展开，规则在这里已经写上了。

**Problem solved.** 把一段带参数的计算变成可复用的值，并且它的含义在定义处就能确定。

**Example.**

```sml
fun pow (x : int, y : int) =
    if y = 0
    then 1
    else x * pow (x, y - 1)
(* 只对 y >= 0 正确。他不为负指数补定义。 *)

fun cube (x : int) =
    pow (x, 3)

val sixtyfour = cube 4;
val fortytwo = pow (2, 2 + 2) + pow (4, 2) + cube 2 + 2;
```

```text
Expression: pow (2, 2 + 2)

1. e0 = pow → 那个函数值
2. 2 已是值；2 + 2 → 4
   函数体看见 y = 4，不是看见加法
3. 在定义时的环境上扩展：
     x → 2
     y → 4
     pow → 它自己
   求值 if y = 0 then 1 else x * pow (x, y - 1)

然后 pow (2, 3)、pow (2, 2)、pow (2, 1)、pow (2, 0)。
y = 0 时返回 1，不再调用。
Value: 16
```

`fortytwo` 是 `16 + 16 + 8 + 2`。调用是表达式，可以相加，可以嵌套。`pow (2, pow (2, 2))` 合法，因为内层调用先变成值，再作为外层的参数。

#### Recursive function 不是 Higher-order function

| | 递归函数 | 高阶函数 |
|---|---|---|
| 定义 | 函数体里调用自己（或一组互相调用的函数） | 参数或返回值是函数 |
| 解决的问题 | 用更小的同类问题定义计算；取代循环 | 把“变化的那一小段计算”从骨架里抽出去 |
| 关键区别 | 调用的是同一个函数值 | 调用的是别人传进来的函数值 |
| 典型场景 | `pow`、`sum_list` | `map`、`n_times`。下一章才是主题 |

`pow` 是递归的，不是高阶的。它的参数是 `int`。高阶要等函数本身能被放进参数位置。

### 3. 若改掉规则

- 定义时就求值函数体：没有参数值，递归也没有一个已经存在的函数值可调用。
- 参数惰性：`pow` 会看见 `2 + 2` 而不是 `4`。ML 的参数是 eager 的。
- 参数名留在绑定之后的环境里：后面的代码能看见 `pow` 的 `x` 和 `y`。它们不能。
- 调用时用调用者的环境而不是定义时的环境：这是动态作用域。`cube` 若在另一个有 `x` 的地方被调用，`pow` 里对自由变量的查找会变。本阶段 `pow` 的函数体没有自由变量，所以两种作用域暂时看不出差别。差别在有嵌套函数和外部绑定时出现。

结果类型不用写。检查器从 `e` 算出来。他说这有一点 magical。Section 4 会把魔法拆开。那不是动态类型。类型规则已经在运行前执行了。

---

## Lecture — Tuple：写程序时就知道有几块

视频：`Pairs and Other Tuples`。

### 1. 先遇到的困难

只有 `int` 和 `bool` 时，函数不能一次交出两块不同类型的数据，也不能接收“这几块绑在一起”的东西。数组和类能装多块，但那不是这里要的基础：它们带来长度、下标和通常还有 mutation。Tuple 解决的是：写程序时就知道有几块，每块类型可以不同。它解决不了“块数要运行才知道”。那是 list，且 list 要求元素同类型。

### 2. 核心概念

**Definition.** Pair 是有两个分量的 value。构造是 `(e1, e2)`：两个子表达式都求值，结果是一个新的 pair 值。类型是 `t1 * t2`。访问暂时用 `#1` 和 `#2`。这是临时的。后面的访问方式是 pattern matching，不是字段名。

多个参数的函数，其参数类型写成 `t1 * t2 * ...`，是因为那一个参数本身是 tuple。`sum_two_pairs` 的类型是 `(int * int) * (int * int) -> int`：两个参数，每个参数又是一个 pair。这看起来像记法事故。Section 2 会说这不是事故：每个 ML 函数恰好接受一个参数。

**Intuition.** Tuple 是 each-of。值同时具有这几块，不是“这几块之一”。

**Why it exists.** 需要一种没有 mutation、宽度固定、分量类型可以不同的积类型。

**Problem solved.** 一次返回商和余数，一次接收两个 pair，而不必发明一个类。

```sml
fun swap (pr : int * bool) =
    (#2 pr, #1 pr)
(* int * bool -> bool * int *)

fun div_mod (x : int, y : int) =
    (x div y, x mod y)
(* int * int -> int * int *)

fun sort_pair (pr : int * int) =
    if #1 pr < #2 pr
    then pr
    else (#2 pr, #1 pr)

val x1 = (7, (true, 9));   (* int * (bool * int) *)
val x2 = #1 (#2 x1);       (* true *)
val x3 = (#2 x1);          (* (true, 9) *)
```

```text
Expression: sort_pair (4, 3)
Environment: sort_pair → 上述函数

1. 函数值就是 sort_pair
2. 参数 (4, 3) 已是值
3. 函数体里 #1 pr = 4，#2 pr = 3，测试 4 < 3 为假
   else 分支构造新 pair

Value: (3, 4)
```

嵌套 pair 的类型括号不能省。`int * bool * int` 是三元组，不是 `int * (bool * int)`。

### Tuple vs List

| | Tuple | List |
|---|---|---|
| 定义 | 固定数量的分量，类型可以不同 | 任意长度，元素必须同类型 |
| 解决的问题 | 写程序时已知的 each-of | 运行时才知道长度的序列 |
| 关键区别 | 宽度在类型里。没有“长度为 n 的 tuple 类型”，因为 n 不是写程序时的常数时，类型写不出来 | 长度不在类型里。空与非空要到运行时才知道，所以 `hd []` 是运行时失败 |
| 典型场景 | 函数的多个参数、`div_mod` 的结果 | `sum_list`、`append`、任何遍历 |

---

## Lecture — List，以及处理任意长度的唯一办法

视频：`Introducing Lists`，`List Functions`。

### 1. 先遇到的困难

Tuple 的宽度必须在写程序时定死。没有一种类型可以写成“长度为 n 的 tuple”，因为 n 要运行才知道。List 允许任意长度，代价是元素同类型。若对空 list 取 head 或 tail，没有元素可给，所以那必须是运行时错误，因此需要一个先测试空不空的办法。

有了 `null` / `hd` / `tl` 还不会处理任意长度。唯一能碰到每个元素的办法是对 tail 递归。若空 list 没有定义好的答案，递归没有底座。

### 2. 核心概念

**Definition.** `[]` 是空 list，类型 `'a list`。`[e1, e2, ..., en]` 是语法糖，元素都求值，类型必须相同。`e1 :: e2` 把一个元素接到一个 list 前面，结果是新 list。`null` 测试空。`hd` 取第一个元素。`tl` 取剩下的 list。`hd` / `tl` 用于空 list 时类型检查通过，运行时抛异常。

`'a` 是类型变量。`[]`、`null`、`hd`、`tl` 对任何元素类型工作。这是课程里第一次见到的参数多态（parametric polymorphism）。完整的故事在 Section 2 和 Section 4。这里只要看见：`null` 不是 Java 或 C++ 的 null。它是一个函数。

**Intuition.** List 是递归的 one-of：要么空，要么一个元素接着一个更短的 list。你现在还没有 datatype 这个词。用法已经是那个形状。

**Why it exists.** 长度不能进类型时，仍需要一种序列。同类型限制是为了让 `hd` 的结果类型在运行前就知道。绕过这个限制的办法以后才有（one-of，或动态类型语言里的异构 list）。

**Problem solved.** 写出长度依赖输入的计算，而不用可变数组和下标。

```sml
val x = [7, 8, 9];
5 :: x;                 (* [5, 7, 8, 9]，x 本身不变 *)
6 :: 5 :: x;            (* 不需要额外括号 *)
[6] :: x;               (* 类型错误：int list 不能 :: 到 int list *)
null x;                 (* false *)
hd (tl x);              (* 8 *)
hd (tl (tl (tl x)));    (* 异常。和 hd [] 一样 *)
```

```sml
fun sum_list (xs : int list) =
    if null xs
    then 0
    else hd xs + sum_list (tl xs)

fun countdown (x : int) =
    if x = 0
    then []
    else x :: countdown (x - 1)
(* countdown 7 = [7, 6, 5, 4, 3, 2, 1] *)

fun append (xs : int list, ys : int list) =
    if null xs
    then ys
    else hd xs :: append (tl xs, ys)
```

`sum_list` 的两问：空 list 的和是 `0`。非空时，答案是头元素加上尾 list 的和。`append` 的两问：空的第一段就是第二段本身。非空时，把头接到“尾和 ys 拼好的 list”前面。课程 logo 的前半就是这个 `append`。

```text
Expression: sum_list [3, 4, 5]
Environment: sum_list → 上述函数

[3, 4, 5] 非空
  hd = 3
  tl = [4, 5]
  3 + sum_list [4, 5]
    4 + sum_list [5]
      5 + sum_list []
        [] 为空 → 0
Value: 12
```

`countdown 700` 是对的。REPL 可能用 `...` 藏起中间。那是打印，不是值缺了一截。

`xs` 以 s 结尾只是约定：它是一个 list。不是语言规则。

---

## Lecture — `let`：一种表达式，三种用途

视频：`Let Expressions`，`Nested Functions`，`Let and Efficiency`。

### 1. 先遇到的困难

到目前为止 binding 只在文件顶层。函数内部的中间名字要么污染整个文件，要么只能重算。若为此增加一种新的“语句”，语言会多出一套规则。他的设计是只加一种表达式，复用已有 binding 的类型规则和求值规则。

Helper 若放在顶层，后面所有代码都能调用它。若它只对某一个函数有意义，或调用方式必须满足不变量，顶层暴露让误用无法在局部检查。若 helper 的某个参数在每次递归里都是外层已经有的那个值，再传一遍是多余参数，也容易在递归调用处漏改。

`bad_max` 在最大值靠近表尾时对同一个 tail 递归两次。每次调用又对更短的表递归两次。不是慢两倍，是每深入一层翻倍。30 个元素已经肉眼可见。没有 `let`，就没有地方记住“tail 的 max 已经算过”。把递归当成问题是错的。重复计算才是问题。

### 2. 核心概念

**Definition.**

```text
let b1 b2 ... bn in e end
```

`b1..bn` 是 binding，不是表达式。`e` 是唯一的 body，是一个表达式。这些 binding 只进入这个 `let` 内部的环境。外面看不见。类型和求值复用 `val` / `fun` 的规则：按顺序扩展环境，然后在扩展后的环境里求值 `e`。`let` 表达式的值就是 `e` 的值。

**Intuition.** `let` 是一个带私有电话簿的表达式。电话簿在 `end` 处合上。

**Why it exists.** 局部变量、嵌套函数、避免重复计算，是同一构造的三种用法。多一种语句就不会让这三件事更清楚，只会让“哪里可以出现绑定”变成两套规则。

**Problem solved.** 中间名字不泄漏；helper 不进入顶层；指数级的重复递归变成线性。

```sml
fun silly2 () =
    let
        val x = 1
    in
        (let val x = 2 in x + 1 end) +
        (let val y = x + 2 in y + 1 end)
    end
(* silly2 () = 7 *)
```

```text
外层 x → 1

第一个内层 let：新环境 x → 2，求 x + 1 → 3。这个 x 不漏出。
第二个内层 let：在外层环境里求 x + 2。这里的 x 仍是 1，所以 y → 3，y + 1 → 4。

3 + 4 = 7
```

零个参数写成 `silly2 ()`：传递的是 unit 值 `()`。括号在这里不是可选装饰。零参数必须有括号。

嵌套函数没有新构造。函数是 binding，`let` 能放任何 binding。

```sml
fun countup_from1 (x : int) =
    let
        fun count (from : int) =
            if from = x
            then x :: []
            else from :: count (from + 1)
    in
        count 1
    end
```

`count` 不在顶层。它直接使用外层的 `x`，而不是再接收一个 `to`。他说：已经在环境里的变量就该用，不要再传。多传一个用不到的参数是差风格，也是以后改签名时的漏改点。

`bad_max` 与 `good_max`：

```sml
fun bad_max (xs : int list) =
    if null xs
    then 0
    else if null (tl xs)
    then hd xs
    else if hd xs > bad_max (tl xs)
    then hd xs
    else bad_max (tl xs)

fun good_max (xs : int list) =
    if null xs
    then 0
    else if null (tl xs)
    then hd xs
    else
        let
            val tl_ans = good_max (tl xs)
        in
            if hd xs > tl_ans then hd xs else tl_ans
        end
```

空 list 返回 `0` 是糟风格，不是这讲的重点。下一讲用 option 修。`null` / `hd` / `tl` 本身便宜。贵的是对同一个 tail 的第二次递归。计算机变快不修复指数爆炸。

```text
bad_max 对长度为 n 的非空表（最大值在最后）：
  两次递归到 n - 1
  每次又两次到 n - 2
  调用次数关于 n 指数增长

good_max：
  Expression: let val tl_ans = good_max (tl xs) in ...
  对每个尾只递归一次
  tl_ans 是已经算完的 int
  然后只做一次比较
```

他拒绝把 `good_max` 叫成真正好。空 list 的答案仍然是假的。

### 3. 若改掉规则

- `let` 的 binding 泄漏到后面：局部名字重新变成全局污染。嵌套 helper 的全部意义消失。
- `count` 不捕获 `x`，而要求调用者每次传入：能工作，但递归调用处多一个必须保持不变的参数。这是动态作用域语言里常见的变通，也是词法作用域要消灭的笨拙。
- 没有 `let` 只有重复调用：语义仍对，`bad_max` 仍返回最大值（非空时）。效率不是语义等价的一部分。Section 4 会把“客户能否观察到差别”和“快慢”分开。这里先看到：重复计算是可以被局部名字消灭的。

---

## Lecture — Option：零个或一个

视频：`Options`。

### 1. 先遇到的困难

空 list 没有最大元素。返回 `0` 或一个很小的负数是回避，不是答案。抛异常可以（`hd []` 和除零已经是这种），但这里他想把“没有”交回调用者，让调用者决定。用 `int list` 表示“没有，或恰好一个 int”能跑，却是差风格：调用者看不出你承诺的是 0 或 1 个元素，而不是任意长度。0-或-1 足够常见，语言应有专门的类型。

### 2. 核心概念

**Definition.** `t option` 的值要么是 `NONE`，要么是 `SOME v`，其中 `v : t`。`isSome` 对 `SOME` 为真，像反过来的 `null`。`valOf` 取出 `SOME` 里的值。`valOf NONE` 抛异常，像 `hd []`。

**Intuition.** Option 不是短 list。类比只用于教学。类型承诺的是“没有，或恰好一个”，不是“一段序列”。

**Why it exists.** 把部分函数的失败变成一个普通值，而不是一个魔数，也不是必须立刻抛掉的异常。调用者若无视 `NONE` 去 `valOf`，失败仍然在，但是失败点是调用者的选择。

**Problem solved.** `max` 的类型从 `int list -> int` 变成 `int list -> int option`。空输入不再假装有一个整数答案。

```sml
fun max1 (xs : int list) =
    if null xs
    then NONE
    else
        let
            val tl_ans = max1 (tl xs)
        in
            if isSome tl_ans andalso valOf tl_ans > hd xs
            then tl_ans
            else SOME (hd xs)
        end

fun max2 (xs : int list) =
    if null xs
    then NONE
    else
        let
            fun max_nonempty (xs : int list) =
                if null (tl xs)
                then hd xs
                else
                    let val tl_ans = max_nonempty (tl xs)
                    in if hd xs > tl_ans then hd xs else tl_ans
                    end
        in
            SOME (max_nonempty xs)
        end
```

`max2` 更好。内部函数假设表非空，返回 `int`，不在每一层携带 option。外层只在入口处理空表。这是嵌套函数的惯用法：把不变量关在 helper 的契约里，不暴露给文件其余部分。

```text
max1 [3, 7, 5] → SOME 7
max1 []        → NONE
max1 [3, 7, 5] + 1          类型错误：int option 不是 int
(valOf (max1 [3, 7, 5])) + 1 → 8
valOf (max1 [])              异常 Option
hd []                        异常 Empty
```

`SOME 7` 不是 `7`。类型系统拒绝把它们相加。这就是 option 相对魔数的全部优势：误用在运行前被看见。

#### Option vs Null

| | `t option` | 很多语言里的 null |
|---|---|---|
| 定义 | 一个普通的 one-of 值：`NONE` 或 `SOME v` | 一个可以冒充任何引用的特殊状态 |
| 解决的问题 | 把“没有”放进类型 | 表示引用不指向对象 |
| 关键区别 | `NONE` 不是 `t`。必须先拆开才能当 `t` 用 | `null` 往往和 `T` 混在同一类型里，忘记检查是运行时失败 |
| 典型场景 | `max`、以后所有部分函数 | Java 引用、未初始化指针 |

这是概念类比，不是实现等价。Java 后来的 `Optional<T>`、Kotlin 的 `T?`、Swift 的 `Optional`、Rust 的 `Option<T>` 都是这条线。Rust 的 `Option` 最接近：不匹配就无法取出 `T`。

---

## Lecture — 短路不是函数能表达的

视频：`Booleans and Comparison Operations`。

### 1. 先遇到的困难

`max1` 已经用了 `andalso`。若把它做成普通函数，两个参数会在调用前都求值。`isSome tl_ans andalso valOf tl_ans > hd xs` 在 `tl_ans` 为 `NONE` 时，右边的 `valOf` 仍会跑，然后爆炸。短路不是函数能表达的，只要语言规定“调用前先求所有参数”。

### 2. 核心概念

**Definition.** `andalso` 和 `orelse` 是关键字，不是函数。

```text
e1 andalso e2    ≡    if e1 then e2 else false
e1 orelse  e2    ≡    if e1 then true else e2
```

`not` 可以是函数，因为否定必须看它唯一的参数。`&&`、`||`、`!` 不是 ML 的与或非。`!` 以后是另一件事，和 mutation 有关。

`if e then true else false` 就是 `e`。不要包这一层。

比较：`>` 要求两边同为 `int` 或同为 `real`，不混用。`=` 不能用于 `real`。`real` 不是 equality type。浮点相等在舍入误差下几乎总是错的问题，类型系统选择不让你写出 `3.0 = 3.0`。`Real.fromInt` 做显式转换。

**Why it exists.** 求值顺序是语义。若所有“看起来像函数”的东西都按函数调用求值，`valOf NONE` 就无法被左边的测试保护。语言因此保留少量特殊形式。这和后面“宏可以增加特殊形式”是同一类问题：有些东西必须在求值前就决定哪些子表达式会跑。

**If changed.** 若 `andalso` 是函数：`max1` 的那一行在空尾上抛 `Option`，即使表非空、只是尾没有最大值。逻辑上右边不该被问。

---

## Lecture — 没有 mutation，alias 就不可观察

视频：`Benefits of No Mutation`，optional `Java Mutation`。

### 1. 先遇到的困难

语言少一个功能为什么是优点？因为写代码时你知道调用者也不能用那个功能。若 pair / list 可以事后改内容，`sort_pair` 返回原来的 pair 还是返回拷贝，就会被调用者观察到：改 `x` 会不会改 `y`，取决于它们是不是 alias。没有 mutation，alias 和 copy 不可区分。实现可以选更省空间的那个。调用者也不必问 identity。

### 2. 核心概念

**Definition.** 在 ML 里，pair 或 list 一旦造出，没有办法改变它的内容。你造一块新数据。别名随时发生，而且你不必想它。

**Intuition.** 不可变数据上，共享是实现细节。可变数据上，共享是语义。

**Why it exists.** Java 和类似语言里，程序员必须纠缠于对象身份：这是拷贝还是别名，该用引用相等还是 `equals`。不是他们喜欢这样。赋值会影响所有别名，所以他们不得不这样。ML 通过拿掉赋值避开这件事。

**Problem solved.** 局部推理。看见一个 list，不需要问“还有谁拿着它，会不会在我遍历时改掉它”。`tl` 可以返回尾巴的别名而不是拷贝。若 `tl` 必须拷贝，ML 程序会慢一个数量级，而且慢在每次递归上。

```sml
fun sort_pair (pr : int * int) =
    if #1 pr < #2 pr
    then pr                       (* 返回同一个 pair *)
    else (#2 pr, #1 pr)           (* 构造一个新 pair *)

(* 另一个实现总是构造新 pair。
   在 ML 里，调用者无法区分这两个实现。 *)

fun append (xs, ys) =
    if null xs
    then ys                       (* 别名，不是拷贝 *)
    else hd xs :: append (tl xs, ys)
```

```text
val x = [2, 4]
val y = [5, 3, 0]
val z = append (x, y)

实际结构（允许的实现）：
  z → 2 → 4 → 5 → 3 → 0
                ↑
                y 的头

若 z 是一份完整拷贝，调用者也看不出来。
若语言允许改 z 的元素，上面这张图会同时改掉 y。
所以在那种语言里，append 必须拷贝，或者必须在文档里声明“返回的尾巴与 ys 共享”。
```

他不是在批评 Java 程序员。他们有一个 ML 程序员没有的问题。

可选的 Java 例子把同一件事做成安全漏洞。错误不在检查权限的方法。那个方法做对了。错误是把内部数组的别名交出去：

```java
public String[] getAllowedUsers() {
    return allowedUsers;   /* 泄漏别名 */
}
```

调用者写 `a[0] = currentUser()`，再调用 `useTheResource()`，检查就会通过。修法是返回拷贝。`final` 或封装库能帮忙，语言不强迫你这么做。在一个不能修改数组元素的语言里，返回别名是合理实现。Java 不是那种语言。

### 3. 不可变到底换来了什么

这些在课程后面还会回来。这里先记下因果，避免把“没有赋值”听成风格宣言。

| 后果 | 为什么 |
|---|---|
| 局部推理 | 没有别人正在改你手里的数据 |
| alias 不必分析 | 共享与拷贝客户不可见 |
| `tl` / `append` 可以共享尾巴 | 效率来自不可变，不是尽管不可变 |
| 更多程序等价 | Section 4：副作用让“两个函数一样”变得脆弱 |
| depth subtyping 可以是安全的 | Section 10：可变记录的深度子类型是 unsound 的 |

Functional programming 不等于没有状态。Section 3 会给显式的盒子 `ref`。主张是：默认不要 mutation。需要时让可变性出现在类型里（`int ref`），而不是每个名字的默认含义。

#### Mutation vs Rebinding

| | Mutation | Rebinding / Shadowing |
|---|---|---|
| 定义 | 改变已有位置里的内容 | 新环境里的新映射，旧映射还在 |
| 解决的问题 | 建模“这个位置变了” | 引入名字、参数、局部绑定 |
| 关键区别 | 所有 alias 都看见新内容 | 已经算完的值不变 |
| 典型场景 | Java 数组元素、以后的 `ref :=` | `val a = a + 1`、函数参数 |

---

## 用透镜看函数调用

| 透镜 | 函数调用 `e0 (e1, ..., en)` |
|---|---|
| Syntax | 函数表达式，参数表达式。一个参数时可省括号 |
| Semantics | 三步：求函数，求所有参数，在定义时环境加参数再求函数体 |
| Binding | 参数名只在函数体里。函数名在绑定之后一直可见，直到被遮蔽 |
| Scope | 函数体里的自由变量按定义时的环境查找。这已经是 lexical scope |
| Evaluation | 参数 eager。函数体延迟到调用 |
| Type | `e0` 必须是箭头类型，参数类型匹配，结果类型是箭头的右边 |
| Lifetime | 函数值可以比定义它的那一行活得更久。它带走上一次环境。闭包要到有“返回函数”时才被迫显形 |
| Mutation | 无。参数是值，不是盒子 |
| Abstraction | 调用者看不见函数体用了哪些局部递归 |
| Composition | 调用是表达式，可以做参数、做分支、做别的调用的一部分 |

---

## Connection to Modern Languages

- C++ / Java 的方法调用也先求接收者和参数，再进方法体。差别是方法体里的字段默认是可变盒子，而且 `this` 的方法查找常常发生在调用时（动态派发）。ML 函数体里的自由变量在定义时就定了。Part C 会把这两条查找规则对打。
- JavaScript 的 `const` 绑定接近“不能 rebinding”，但对象内容仍可变。不要把 `const` 当成 ML 的不可变。
- Rust 的 `let` 默认不可变，`mut` 是显式的。这和“可变性不是默认”是同一设计选择，机制不同：Rust 还有所有权，ML 靠垃圾回收和共享不可变结构。
- Python 的 list 可变，所以 `xs[1:]` 必须拷贝。ML 的 `tl` 不必。这是不可变换来的具体效率，不是美学。
- `Option` 的现代对应：Rust `Option<T>`、Swift `Optional`、Kotlin `T?`、Haskell `Maybe`。Java 的 `null` 不是对应物。Java 的 `Optional` 是库，而且历史上可以被设成 null，所以边界比 ML 弱。

---

## Section 1 Review

Section 1 解决的是：在没有赋值的语言里，表达式如何在环境里变成值；函数如何把这种求值变成可复用的值；list 和 option 如何表达“长度未知”和“可能没有”；为什么拿掉 mutation 会让 alias 不可观察。

### 核心概念

binding、static / dynamic environment、expression、value、function value、function call、eager arguments、tuple、list、`'a`、`let`、nested function、option、`andalso`、immutability、alias。

### 必须掌握的不变量

```text
fun 不求值函数体。函数已经是值。
调用 = 求函数 + 求所有参数 + 在定义时环境里求函数体。
shadowing ≠ mutation。
let 的绑定到 end 为止。
空 list 的 hd/tl 类型通过，运行时失败。
SOME v 不是 v。
andalso 不是函数，因为函数会先求所有参数。
没有 mutation 时，共享与拷贝客户不可区分。
递归不是 bad_max 的 bug。重复计算才是。
```

### 能力检查

真正理解这一节，应该能：

- 给一段 `val` 序列画出每一次扩展后的环境，并说明哪些旧映射被遮住但没有被改。
- 把一次函数调用拆成三步，指出参数表达式在哪一步消失。
- 解释为什么 `count` 可以不接收 `x`，以及这依赖哪条作用域规则。
- 说出 `bad_max` 慢在哪里，以及 `let` 改变的是重复计算而不是递归本身。
- 说明 `max` 为什么不该返回 `int`，以及 `valOf` 把检查推回给了谁。
- 说明在 Java 里返回内部数组为什么是漏洞，而在 ML 里 `append` 共享 `ys` 为什么不是。

概念题和代码题见 `exercises/section-01.md`。
