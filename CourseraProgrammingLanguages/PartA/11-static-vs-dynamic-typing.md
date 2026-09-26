# 11 — 静态检查承诺什么，不承诺什么

> Part B · Section 7
> 视频：`ML versus Racket`，`What Is Static Checking`，`Soundness and Completeness`，`Weak Typing`，`Static versus Dynamic Typing` 两讲，optional `eval and quote`

ML 和 Racket 都写过了。括号、`let`、pattern matching 对 struct，都是真差别。若争论停在皮肤上，就还没碰到这门课要你带走的设计问题：

> 类型系统该不该在程序开始跑之前，扔掉一批程序？

扔掉的里面有永远跑不通的程序，也有没有任何 bug、只是类型规则看不懂的程序。留下来的程序，每个值的类型在运行前就知道，于是不必在每次加法前问 `number?`。Racket 更宽容，把更多错误留到求值发生的那一刻。

Grossman 不宣布赢家。先把 static checking 是什么、sound / complete 相对谁定义、weak typing 不是什么钉死，再谈哪一边更好。没定义就争论，是空吵。

---

## 1. 没有这些区分会怎样

如果只说“Racket 没有类型”，后面会把 C 的越界着火算到 Racket 头上，也会把 ML 拒绝一个死分支里的 `4 div "hi"` 当成类型系统出了事故。如果把“何时检查一个被认定是错误的操作”和“这个操作的求值规则允许多少种输入”焊在一起，`"foo" + 3` 得到 `"foo3"` 会被误读成“更动态”。它不是。它是加法不再把这件事当成错误。

依赖：Part A 的 typing rules、datatype、穷尽匹配、`exn`、currying；Part B 的运行时错误、struct、解释器里“程序是树”。准备：Part C 的 subtyping 与 generics。那里会回到“现代类型系统如何少挡路”。本节能先不展开那两个机制。

---

## Lecture — 两种相反的看法，都有用

视频：`ML versus Racket`。

### 问题

共同的东西先摆开，免得把它们当成类型轴上的差别：两边都有高阶函数，都不鼓励 mutation，函数参数都是 eager 的。语法、模式匹配、某些 `let`、module，他承认不同，本讲只盯类型系统。

最大的差别：ML 有一套精致的类型系统，在程序开始跑之前拒绝很多程序。Racket 更宽容，更大的一类错误发生在求值过程中。

不先给出两种心智模型，后面的 soundness 争论没有共同语言。这两种看法不是逻辑上互相否定。它们是两副有用的眼镜。

### 机制

**看法 1，Racket 程序员看 ML。** ML 不是另一种 Racket。它是 Racket 的一个 subset。类型系统删程序。删掉的有真 bug，也有没有 bug 的程序。留下来的程序里，每个东西的类型到处都静态知道，所以不必在运行时问 `number?`。

**看法 2，ML 程序员看 Racket。** Racket 不是“没有类型”。在这个教学模型里，它像一种奇怪的 ML：一切值都属于同一个 datatype，叫 `theType`。实现自动套 constructor / tag。你写 `42`，实现当成 `Int 42`。函数大致吃一串 `theType`，返回 `theType`。`car`、`pair?`、`+` 在实现里就是对这个 datatype 做 pattern match。这不是 zero types。这是 **one type**。

这是 ML 中心的弯折，他故意要你弯一下。它不是在声称 Racket 的实现里真有一个叫 `theType` 的 ML datatype，也不是声称 Racket 的 `cons` 就是 ML 的 `Pair` 构造子。它是一个解释模型：动态检查从哪来，tag 为什么存在。

```sml
datatype theType =
    Int of int
  | String of string
  | Pair of theType * theType
  (* 再加上 Bool、Symbol、Proc，每种原语一个构造子 *)

fun car v =
    case v of
        Pair (a, _) => a
      | _ => raise SomeError

fun pair_q v =
    case v of
        Pair _ => true
      | _ => false

fun plus (v1, v2) =
    case (v1, v2) of
        (Int i, Int j) => Int (i + j)
      | _ => raise SomeError
```

`+` 必须把结果重新套上 `Int`。否则下一个函数看见的就不再是 `theType`。`pair?` 的教学简写返回了 ML 的 `bool`。严格的 one-type 模型还应再套一个 `Bool` 构造子。他口述的是“返回 true 或 false”，简写足够说明 tag 上的分支。

```text
Racket 源码里的 (+ 3 4)
在这个模型里：

Expression: plus (Int 3, Int 4)
tag 由实现加上，不是程序员写的

Evaluation: 匹配两个 Int，算 7，再套 Int
Value: Int 7
```

拿掉 tag，`car` 无法在 pair 与非 pair 之间分支，`pair?` 无法返回真假。one-type 模型塌掉。这就是动态类型为什么在每次原语操作前都“好像在问这是不是数”：问的是 tag。

**Struct 盖不住。** Racket 的 `struct` 是在程序运行时往这个“一种类型”上动态增加一个新 constructor。ML 的普通 datatype 不允许这么做，因为穷尽匹配会作废：今天穷尽的 `case`，明天多了一个构造子就不再穷尽，而已经编译过的函数不会重新被警告。ML 里唯一接近的是 `exn`：可以不断加新的异常构造子。他称为 obscure 的类比，不是同一机制。

### 例子：被扔掉的，不全是 bug

永远错，ML 运行前拒绝，Racket 留到调用时：

```racket
(define (g x) (+ x x))

(define (f y)
  (+ y (car y)))

(define (h z)
  (g (cons z 2)))
```

`y` 不能既是数又是 pair。任何调用 `f` 都会在 `+` 或 `car` 上失败。`h` 把 pair 送给只做加法的 `g`，同样失败。Subset 视角：这种程序值得在运行前扔掉。

没有 bug，Racket 得到值，ML 仍拒绝。分支的具体 list 元素他没有逐字写出；形状是他说的：有时返回布尔，有时返回 list；list 里装不同种类的数据。

```racket
(define (f x)
  (if x
      #t
      (list 1 2)))

(define xs (list 1 #t))

(f xs)    ; xs 不是 #f，走 then，值是 #t
```

```text
Expression: (f xs)
Environment: xs → 非 #f 的 list
Evaluation: if 的测试为真，else 不求值
Value: #t
```

异构 list、同一函数返回 bool 或 list，在 Racket 不是错。ML 拒绝，因为分支类型必须相同，list 元素类型必须相同。Subset 也扔掉好程序。这是后面 false positive 的第一批具体样子。

### 若改掉规则

- 若 ML 允许运行时往 datatype 加构造子：穷尽检查作废。这是他拒绝把 struct 塞进普通 ML datatype 的原因。
- 若只戴 subset 眼镜：会漏掉“Racket 不是 untyped，是 everything-tagged”。后面 weak typing 就容易和 dynamic typing 搅在一起。

---

## Lecture — Static checking 是定义，不是工具

视频：`What Is Static Checking`。

### 问题

还没定义就争论好不好，会把“类型规则怎么写”和“类型系统想阻止哪一种运行时行为”焊死。焊死之后无法解释：为什么 ML 抓得到“把 string 送给除法”，却抓不到 then/else 写反了。

### 定义

**Static checking（静态检查）**：程序已经成功 parse，在开始运行之前，仍然拒绝其中一部分。哪些程序被拒绝，是语言定义的一部分，决定什么是 legal program。不是可选的旁路 bug-finder。旁路工具他赞成。本讲只谈定义内的检查。

最常见的做法是 type system。拆开两层：

| | Approach | Purpose |
| --- | --- | --- |
| 定义 | 每个变量有类型；用它检查每个表达式；函数可以有 signature。有的程序过，有的不过 | 这套规则试图阻止哪一类运行时行为 |
| 解决的问题 | 检查器怎么走 | 检查器为什么存在 |
| 关键区别 | 换一套实现仍可追求同一个 purpose | purpose 先于“递归遍历 AST 的 type-checker 怎么写” |
| 典型场景 | Hindley–Milner、你在 Section 4 见过的约束 | “加法的两边必须是数”“应用的左边必须是函数” |

**Dynamically typed language**：不做这种 static checking 的语言。线不是绝对的。Racket 在按 Run 时仍会查未定义变量，静态检查极少，所以仍叫 dynamically typed。

ML 类型系统的 purpose，若程序能跑，就永远不会有这些错：

- 原语用在错误种类的值上。`e1 e2` 而 `e1` 的结果不是函数；`if` 的测试不是 `bool`。
- 在环境里查找未定义变量。查找一定找得到。
- 多余的、永远匹配不上的 pattern。
- 破坏 module 的抽象边界。
- 被迫在运行时做 `number?` 这种检查。

它不阻止：

- `hd` 空 list。
- 数组越界。ML 有 array，课上几乎没用。下标必须是 `int`，不保证这个 `int` 落在数组里。
- 除以 0。
- 任何需要知道“程序想做什么”的 bug。没有完整 specification，检查器不能读心。

```sml
fun f x = if x then e_swapped else e_intended
fun g x = ...          (* 与 f 同为 int -> int *)
val wrong = f 3        (* 你想调的是 g *)
```

两个分支都良类型，规格是反的。调错了同类型的函数。类型规则全部满足。所以类型系统不是测试的替代品。

### 报错点是一条谱，不是二选一

以“阻止除以 0”为例，从更早到更晚：

1. 字符还在屏幕上，当前程序就不得能除以 0。比普通编译还早。
2. 习惯的 compile time：写完，跑编译器。
3. 运行前但更懒：单个文件可以过，直到带着某个 `main`、甚至某组参数准备跑，才说不许跑。
4. 运算发生时，像 Racket 的 `(/ 3 0)`。学校里常觉得这已经是最动态的，因为“不许除以 0”。
5. 比运算还晚：不报错，返回一个表示“除过 0”的结果，交给调用者。浮点就是这样：除以 `0.0` 得到 infinity。科学计算认为有用：infinity 可能在别处被消掉，或被条件避开，根本不会被用到。整数除法也可以这么设计，通常不这么做。

经验上，compile time 和 run time 是这条谱上最常见的两个点。何时把一件事变成 error，是语言设计选择。

```text
Expression: (/ 3 0)
Evaluation: 两个子表达式已是值；执行除法；除数是 0
Value: 没有。错误发生在除法被求值的那一刻。
这不是“类型不对”。两个参数都是数。
```

若整数除法采用浮点规则，`(/ 3 0)` 不报错。那不是把检查从静态改成动态。那是把报错点移到比动态检查更晚，甚至不再叫错误。

---

## Lecture — Sound 与 complete 不能兼得

视频：`Soundness and Completeness`。

### 问题

“类型系统正确”如果不相对某个要阻止的性质 X 来定义，就无法判断。若再要求检查器永远终止，非平凡的 X 上不能又 sound 又 complete。不把这个说清，就会把 false positive 当成事故，而不是选定的设计。

### 定义

设 X 是类型系统声称要阻止的性质。例如把 string 送给除法，或查找未定义变量，或一组这样的性质。

**Sound（可靠）**：从不接受一个程序，使得存在某输入，运行时会做 X。无 false negatives。接受了，就可以信“不会做 X”。

**Complete（完备）**：从不拒绝一个实际上不会做 X 的程序。无 false positives。

医学类比：type checker 是检验，program 是病人，检验的是“会不会得 X 这种病”。False negative：报告不会得，其实会。False positive：报告有病，其实没有。

实用类型系统按 sound 设计。语言设计者花大量时间证明这一点，这样“过了检查”才可信。Generics 等更花哨的特性，常常是为了减少 false positives，不是为了补 soundness。允许更多不会做 X 的程序通过。不是为了放行会做 X 的程序。

ML 对“number divided by a string”是 sound 的。没有 false negative 的例子可举。False positive 很多：

```sml
fun f1 x = 4 div "hi"
(* 从未调用。整个程序仍被拒绝 *)

fun f2 x = if true then 0 else 4 div "hi"
(* else 是死代码。仍被拒绝 *)

fun f3 x = if x then 0 else 4 div "hi"
(* 若每次调用都传 true，else 永不跑。检查器看不见所有调用点 *)

fun f4 x = if x <= abs x then 0 else 4 div "hi"
(* 对 int x，测试恒真。检查器要不要懂 abs？ *)

fun f5 x = 4 div x
val _ = f5 (if true then 1 else "hi")
(* 实参的 else 是死的，除数总会是数。仍被拒绝 *)
```

```text
若这些程序被允许跑，且 f3 只收到 true：

f2 的测试为 true，else 不求值，div 不发生，值是 0
f5 的实参求值得 1，4 div 1 = 4
X 没有发生
类型系统仍然拒绝
```

`f1` 若从未调用，这次运行里 X 也不会发生。ML 仍认为整个程序有这病。它不看“有没有人调用”。`f4` 是他最想让你停一下的例子：要避免这个 false positive，检查器得懂 `abs`，也就是去证明一条算术定理。Purpose 没变，how 已经超出类型规则。他不期望类型检查器做这件事。

### 为什么必须有 false positive

对很多非平凡性质 X，静态检查器不能同时做到三件事：永远终止、sound、complete。程序员希望检查器终止。所以必须有 false positives，或 false negatives，或两者都有。主流选择：不要 false negatives，接受一些 false positives。这个数学事实不会变。他不在本课证明。他认为这是不可判定性对日常软件开发最重要的后果。

阻止不终止、把 string 当函数、除以 0，都落在这个三难里。可以想象一个试图阻止除以 0 的类型系统。它若终止且 sound，就会拒绝一些实际上永不除以 0 的程序。

### 若系统 unsound，语言可以怎么做

从轻到重：

1. 承认设计错误，收紧类型系统，拒绝更多程序，消掉 false negatives。
2. 保留动态检查当 fallback。静态检查只是尽力。这是 Racket 那种“跑到了再查”的方向，不是补丁名字。
3. 允许 X 发生，并给出默认行为。变量不在环境里就返回 0。脚本语言常这样。他说 Ruby 通常没走到这么远。
4. 最差：X 发生时程序可以做任何事。删文件、发病毒、毁掉数据。这是 C/C++ 的选择。下一讲的名字叫 weak typing。它不是动态类型。

---

## Lecture — Weak typing 不是动态类型

视频：`Weak Typing`。

### 问题

把 weak typing 当成“静态 vs 动态”的同义词，会让 Racket 背上 C 的锅，或让 C 的 catch-fire 看起来像一种动态检查。

### 定义

**Weak typing**，他用来描述 C/C++ 那种情形：存在一些程序，语言定义要求它们必须通过 static checking；运行时却被允许做任何事。本应在闯祸前抓住这些无意义操作的动态检查是 optional，实现实际上不做。

“Set the computer on fire” = 崩溃、损坏数据、变成病毒、删除文件。不是修辞。是语言定义允许的行为集合。

这不是类型系统的数学性质，所以 “weak typing” 是个坏名字。它是：有一个坏性质 X，静态不查，动态也不查，X 发生则计算机可以着火。

```c
/* 概念例子，不是本课的语言 */
int a[5];
int x = a[10];   /* 类型检查通过。越界不被查。不是动态类型 */
```

```text
Expression: a[10]
Type: 在 C 的类型系统里，下标是 int 就算类型正确
Evaluation: 无确定的值
语言定义允许任意行为
```

数组越界是 C/C++ 里无法解释的行为的最大来源之一。多数人不把 bounds 算进这些语言的 type system。所以更不该把这件事叫成 typing。名字是坏的，现象是真的。

他列出别人要这种语言的理由，不是他的偏好：更容易在各种平台上实现，检查留给程序员；省下检查的时间，也不必为 tag、长度等字段付空间；程序员要控制数据表示，动态检查需要程序员控制不了的额外字段。

旧口号：strong types for weak minds。含义是计算机不比人聪明，静态检查永不完美，人应该能说 trust me，关掉不必要的检查；错了就允许任何事。他认为常规智慧已经变了。人很不擅长避免 bug。检查器和应用程序作者应该分工。类型系统更灵活了（polymorphism、subtyping），强类型不再那么挡路。操作系统里有三千万到五千万行 C。一千行也许还能盯。三千万行里任意一行都能让整个程序任意行为，再指望人是荒唐的。

**Racket 不是 weakly typed。** 它是 dynamically typed。不会把 number 当 procedure 用：运行时检查，语言定义说这些错误会在特定点被发现并 raise。实现可以在证明检查永不失败时删掉检查。定义仍要求：若检查会失败，必须表现为异常或错误。这和 catch-fire 相反。

```racket
(+ "foo" 3)                 ; 运行时错误，不是着火

(define (g x) (+ x x))
;; 定义说 + 检查两个参数
;; 实现可以只查 x 一次，因为两个位置是同一个变量
;; 若这次检查会失败，实现仍必须报错
```

### 第三条轴：求值规则变了，就不再是那个错误

常被搅进来、但既不是 weak typing 也不是 dynamic typing 的事：原语的求值规则允许多少种输入。

| 操作 | 一种语言 | 另一种语言 |
| --- | --- | --- |
| `+` 碰到 string | ML：类型错误。Racket：运行时错误 | 拼接；或把 number 转成 string，`"foo" + 3` 得到 `"foo3"` |
| 取只有 5 个元素的数组的第 10 个 | 报错 | 返回 null 或空 list |
| 对越界位置赋值 | 报错 | 把数组变大 |
| 参数个数不对 | Racket：错误 | 丢掉多余参数；或给缺的参数填一个默认值 |

这些选择改的是 **evaluation rules**。Legal programs 变多。程序员大概不是这个意思的事，更晚才暴露，甚至不再暴露。比动态检查更迟地宣布出错。不是 static checking，也不是 dynamic checking。

```racket
(define (f x y) (+ x y))
(f 1)    ; Racket：参数个数错误。错误被定义，不是着火
```

### 对照

| | Weak typing | Dynamic typing |
| --- | --- | --- |
| 定义 | 静态放行，动态也不查，X 发生则可做任何事 | 静态基本不查，但 X 在运行时必须被发现并报错 |
| 解决的问题 | 实现简单、表示可控、检查可省 | 不在运行前拒绝程序，同时仍给无意义操作一个确定的失败 |
| 关键区别 | 失败没有定义，或定义是任意行为 | 失败有定义：异常或错误。实现只能删证明不会失败的检查 |
| 典型场景 | C/C++ 数组越界 | Racket `(+ "foo" 3)`、参数个数不对 |

| | 改变检查时机 | 改变求值规则 |
| --- | --- | --- |
| 定义 | 同一件被认定是错误的事，更早或更晚发现 | 这件事不再是错误，或变成另一种值 |
| 解决的问题 | 何时付出检查、何时看见失败 | 原语接受什么输入 |
| 关键区别 | static vs dynamic 是这条轴 | `"foo3"`、数组长大、忽略多余参数是这条轴 |
| 典型场景 | ML 拒绝 `div` string；Racket 在除法发生时报错 | 别的语言里 `+` 就是拼接 |

**If changed.** 若 C 的定义改成“越界必须抛异常”，它就不再是他定义的 weak typing，即使仍然没有 ML 那种静态类型。若 Racket 的 `+` 改成自动把 number 转成 string，Racket 不变成 weakly typed，也不变“更动态”。只是 `+` 的求值规则变了。

---

## Lecture — 前三组论据，两边都站得住

视频：`Static versus Dynamic Typing`，part one。

### 问题

“静态更好还是动态更好”如果期待一个赢家，问题本身就问错了。大多数语言两种检查都做。要对每一项你打算查的东西，比较“何时查”的代价。他开头就说：抱歉让你失望，我不会给出firm conclusion。

争论的单位不是“整个语言必须全静态或全动态”。Racket 有 contract system，可以更统一地写运行时检查。本讲不展示。点名是为了反驳“动态语言只能手写 `number?`”。Contract 不改变“失败在运行时”。

### 论据 1：方便

动态方：list 装不同类型、函数返回不同类型，直接写。不必建 datatype，不必记得套 constructor。调用者用语言自带的 `number?` 区分结果。这正是“有时返回数、有时返回 string”的自然用法。

条件的具体写法他没有逐字说出。下面用 `y > 0`，只为了让两个分支都可达。若测试就是 `y` 本身，非 `#f` 的数永远走 then，和他的 “sometimes” 不合。

```racket
(define (f y)
  (if (> y 0)
      (+ y y)
      "hi"))

(number? (f 3))    ; #t
(number? (f 0))    ; #f
```

```sml
datatype int_or_string = Int of int | String of string

fun f y =
    if y > 0
    then Int (y + y)
    else String "hi"
(* 调用者自己 pattern-match。没有语言提供的 number? *)
```

静态方：更方便的是调用者已经不能传错类型。

```sml
fun cube x = x * x * x
(* 每个调用者传入 int，否则程序在运行前被拒绝 *)
```

Racket 若要对外部调用负责，得自己查，而且要到运行时才失败。他只说“某种检查”，没有给出唯一写法。Contract 把这种检查写得更标准，失败点仍在运行时。

### 论据 2：有用的程序被拒绝

动态方：总有人想写的、完全说得通的程序被静态系统拒绝。

```sml
fun f g = (g 7, g true)
(* 不 type-check。即便你唯一想传的 g 是 fn x => (x, x) *)
```

```racket
(define (f g)
  (cons (g 7) (g #t)))

(f (lambda (x) (cons x x)))
;; '((7 . 7) . (#t . #t))
```

```text
Expression: (f (lambda (x) (cons x x)))
Evaluation:
  (g 7)  → (cons 7 7)
  (g #t) → (cons #t #t)
  再 cons 在一起
Value: ((7 . 7) . (#t . #t))
```

本课的 Hindley–Milner 给不了 `g` 一个既吃 `int` 又吃 `bool` 的类型。传 `fn x => (x, x)` 时没有 bug。这是 lecture 03 的 false positive，放进便利性争论里。拒绝它不等于这个程序会做 X。

静态方的反击不是改写这个例子让它通过。Racket 能这么做，是因为所有数据都带 tag，每次当 pair 用、每次做某些原语之前都查。ML 里程序员控制在哪里 tag、哪里可能动态失败。极端情况下可以在 ML 里造一个 `theType`，自己做全部 tag 和 pattern match。那就是看法 2 的模型，由你选择何时付这个代价。Racket 强迫所有程序始终带 tag 并检查。

这是概念上的“你可以自己实现动态类型”，不是声称几行 ML 就得到了 Racket。你得不到 Racket 的 `struct` 动态加构造子，也得不到它的错误信息。Turing tarpit 的警告仍然有效：能做，不等于做得不痛。

### 论据 3：更早抓住 bug

静态方：还没写测试、还没被人误用，一 `use` 文件就报错。Currying 和 pair 调用混用，盯代码不好找。

```sml
fun pow1 x y =
    if y = 0
    then 1
    else x * pow1 (x, y - 1)
(* curried：int -> int -> int
   递归调用传了一个 pair。运行前的类型错误 *)
```

```racket
(define (pow1 x)
  (lambda (y)
    (if (= y 0)
        1
        (* x (pow1 x (- y 1))))))
;; 定义被接受
;; ((pow1 3) 4) 在递归调用处才发现参数个数不对
;; 即便初始调用写对了，也要跑到递归才看见
```

动态方：抓到的多半是测试也会抓到的简单 bug。不要说静态类型好到不用测试。

```sml
fun pow2 x y =
    if y = 0
    then 1
    else x + pow2 x (y - 1)

val wrong = pow2 3 4     (* 13，不是 81 *)
```

```racket
(define (pow2 x)
  (lambda (y)
    (if (= y 0)
        1
        (+ x ((pow2 x) (- y 1))))))

((pow2 3) 4)             ; 13，不是 81
```

```text
pow2 3 0 = 1
pow2 3 1 = 3 + 1 = 4
pow2 3 2 = 3 + 4 = 7
pow2 3 3 = 3 + 7 = 10
pow2 3 4 = 3 + 10 = 13
```

`+` 和 `*` 类型相同。类型系统永远抓不到。他在 SML 里现场得到 13，用来堵住“有静态类型就不用测试”。Racket 侧同一段算术也得到 13。

| | 静态在这项上的方便 | 动态在这项上的方便 |
| --- | --- | --- |
| 定义 | 调用者已被检查。`cube` 不写 `number?` | 直接返回数或字符串，用 `number?` 区分 |
| 解决的问题 | 误用在运行前失败 | 不必为“有时是这种、有时是那种”发明 tag |
| 关键区别 | 方便在调用边界 | 方便在数据本身是异构的时候 |
| 典型场景 | `cube` | `(f 0)` 得到 `"hi"` |

---

## Lecture — 作业交了以后，软件还有两段生活

视频：`Static versus Dynamic Typing`，part two。

前三组还是“按 spec 写完、测试、算完成”的作业视角。软件还有 prototyping，以及发布之后的修改。性能和复用若只听一边的口号，会把“定义要求检查”误当成“实现必须每次都查”。

### 论据 4：性能

静态方：可以更快，同时仍阻止该阻止的错误。省的不只是 `+` 之前问“是不是数”的时间，还有 tag 的空间。ML 可以把真正的 number 传给加法。Racket 的值要有一个“这是 number”的字段，再加一个放数字的字段。源码里也不写 `number?`。

动态方：定义要求这些测试，但性能通常只取决于一小部分代码。语言定义没有说实现必须执行每一次检查。

```racket
(define (f x)
  (* (+ x x) 4))
;; 定义上：+ 查两个参数，* 再查两个，大约四次
;; 编译器看见 + 的两边都是 x，可以只查 x 一次
;; 4 是字面量；+ 若成功，x 已是数
;; 他的计数：大约四次，可以削到一次
```

```text
Expression: (f 3)
Environment: x → 3
Evaluation: (+ 3 3) → 6；(* 6 4) → 24
Value: 24
优化不改变这个值。它只删掉证明不会失败的检查。
这和 weak typing 相反：删的是冗余检查，不是“失败了也可以着火”。
```

### 论据 5：复用

动态方：没有限制性类型系统，同一个函数能被调用得更勤。处理 cons cell 的库函数，不管内容类型是否相同，都能复用。静态语言里 list、tree、array、hash table 的类型变得很复杂，有时仍不允许你想要的全部复用。

静态方：现代类型系统已经够复用。list、set、tree、table 写一次。类型可以复杂，用起来不该复杂。什么都用 cons，很难记住哪个值其实是哪种逻辑类型。传错顺序只得到奇怪的运行时错误。类型错误信息让库更好用，因为复用错了会在运行前指出来。

这里的“现代类型系统”指 polymorphism，以及他点到但本讲不展开的 subtyping。概念类比，不是声称 Java generics 等于 ML 的 `'a`。Section 10 会把这两条拆开。

### 论据 6：prototyping

动态方：还不知道数据怎么表示、one-of 有几个 constructor。静态类型不让你跑，除非所有 case 都写完。动态允许先跑已写的那部分。静态迫使过早承诺，写出稍后会扔掉的代码，只为了让另一部分能跑。

静态方：想法正在变的时候，最需要类型系统充当被检查的文档。这时最容易把 string 当成 int 传。为了能跑而补的代码，实践中可以很小。永远抛异常的函数可以有上下文要求的任何类型。还没写的 case 可以是 wildcard 加 `raise`。

```sml
fun not_ready x = raise Fail "todo"

fun partial_cases x =
    case x of
        KnownConstructor y => y
      | _ => raise Fail "todo"
```

调用 `not_ready` 没有正常值，只有异常。他承认 wildcard 可能易错，但说不比动态语言的隐含失败更易错。动态只是隐含地替你做了这件事。静态把“还没写”写成显式的 `raise`。

### 论据 7：发布之后

动态方更顺的例子：函数原来只加倍，现在也接受 string 并拼接。旧调用者完全不用改。

```racket
;; version 1
(define (f x) (+ x x))

;; version 2
(define (f x)
  (if (number? x)
      (+ x x)
      (string-append x x)))

(f 3)       ; 6，旧调用者仍工作
(f "ab")    ; "abab"
```

```sml
(* version 1 *)
fun f x = x + x          (* int -> int *)

(* version 2：不 backwards compatible *)
datatype t = Int of int | String of string
fun f (Int x) = Int (x + x)
  | f (String s) = String (s ^ s)
(* 每个旧调用点都要套 Int，还要匹配结果 *)
```

字符串拼接的 Racket 函数名按库是 `string-append`。他口述的是 append。语义是拼接，不是 `+`。

静态方更想要的例子：只改某个函数的返回类型。ML 打印每一个不再 type-check 的调用点。那份清单就是 to-do list。再次通过，就知道改全了。Racket 仍然能加载。对结果的错误假设变成运行时错误，而且只有测试走到那里才被发现。

给 datatype 加构造子时，如果各处都用 pattern match、最后一档没用 wildcard，inexhaustive-match 警告正好出现在该改的地方。

```sml
datatype exp = Const of int | Add of exp * exp
(* 加上 Neg of exp。
   若没有 wildcard，警告标出每一个该更新的函数。 *)
```

注意两个建议的时刻不同。Prototyping 时他推荐 wildcard，先跑。演化一个已经写完的 one-of 时，wildcard 会藏住你该改的地方。同一个构造，两种软件生命阶段，建议相反。

动态方的回击：这份 to-do list 是强制的。你不能改一半、跑测试、再改另一半。ML 要整个程序先 type-check。至少清单是你迟早要做完的。有效反击不是“清单无用”，而是“清单不允许分批”。

### 收束：问题要改写

“静态永远更好 / 动态永远更好”太粗。更好的问题是：

> 对这个软件，哪些东西我愿意用静态查，并接受不可避免的 false positives？哪些我愿意交给测试和真的运行？

两边都有合法 tradeoff。这两讲给的是基于概念的理由和例子，不是无精确论证的意见。

也许理想是一种语言两边都支持，不必在 ML 与 Racket 之间二选一。他点名 Racket 在用 Typed Racket 试：有的文件带类型，有的不带。口述里的 “invariant variant” 是识别噪声，指的是这种混合，不是另一种类型系统。提供两边，仍是 open research problem。设计上有不容易做的事。就算两边都有，问题也不显然变容易。写库或用库的人仍要决定：这里要不要类型检查器边写边抓错，还是故意推迟。谁来决定、用什么设计标准，不清楚。所以他把它留成经典权衡。

| | 动态方在这项上站得住 | 静态方在这项上站得住 |
| --- | --- | --- |
| 性能 | 热点上编译器可把大约四次检查削到一次。定义 ≠ 实现 | 没有 tag 字段，加法直接收到 number |
| 复用 | cons 库函数无视内容类型 | 多态库写一次；传错不会只得到奇怪的运行时错误 |
| Prototyping | 没写完的 case 也能跑已写的部分 | `raise` 可以有任何类型；类型是变动规格的被检查文档 |
| 演化 | 扩大合法输入时，旧调用可以不改写法 | 类型一改，to-do list 完整。代价是不能改一半就测试 |

---

## Lecture — `eval` 不是“必须解释执行”

视频：optional `eval and quote`。

### 问题

如果程序只能是运行前就写死的文本，你就无法在运行时造一段 Racket 再跑它。解释器作业用 constructor 造另一门语言的 AST。`eval` 问的是：造出来的如果就是 Racket 自己的语法数据，谁来跑？不把这件事讲清，人们会把“有 `eval`”误当成“必须是解释执行的语言”。

本讲 optional。他不辩护 `eval` 的惯用法，并认为它常被滥用。目的只是去掉神秘感。本课不用 `eval` 做有用的事。

### 机制

有 `eval` 的语言：运行时随便造数据，然后把这份数据当作程序跑。Racket 里这份数据是 list：number、symbol、嵌套 list。不是字符串。

和解释器的关系：作业里用 constructor 表示另一门语言的树。这里用 list 和 symbol，而且这门语言就是 Racket。运行中的 Racket 程序造出另一段 Racket 语法，`eval` 跑它。

因为开始运行时不知道将会 `eval` 什么，运行时身边得还有一整份 Racket 实现。用解释器实现 Racket 时，`eval` 调用解释器，容易。用编译器实现时，每个可能用到 `eval` 的程序得带上足够完成编译、然后再运行的东西。不容易，但不是不可能。

因此人们常把有 `eval` 的语言叫 interpreted languages。有一点道理。技术上不正确。`eval` 是可以不用的特性，也不必用解释器实现。Racket 有时被这么叫，是因为它有 `eval`，不是因为它只能被解释。

他假定 DrRacket 的 REPL 用 Racket 实现，其中用了 `eval`。REPL 的 E 就是 Evaluate。少数很强的用途在这里。多数使用不合适。

`quote` 是 special form。后面的东西都变成嵌套 list 和 symbol，number 仍是 number，不按普通表达式求值。`(+ 4 2)` 在 quote 下不是加法，是三元素 list：symbol `+`、`4`、`2`。

他的说法：quote 与 eval 在这个意义上是 inverses。操作上：quote 造出 eval 愿意接受的数据；eval 跑这段数据。不是“eval 后再 quote 会得到原来的值”。

`quote` 下面不能做计算，否则那段计算也变成正在建造的程序的一部分。`quasiquote` / `unquote`：标出“这部分现在就求值，把结果放进正在建造的语法”。他让你自己查，不讲。

Python、Perl 等的 `eval` 接收 string，即 concrete syntax，先 parse 再跑。打字更方便，组合更痛，靠字符串拼接。那些语言里也常有“字符串中间求值再塞回去”的东西，名字不同。Lisp/Scheme 几十年来叫 quasiquote 和 unquote。Racket 的括号让 concrete syntax 和 abstract syntax 如此接近，所以 `eval` 能吃 list 而不是 string。这是方便，不是历史负担。

假分支的 list 他没有说出来。下面只保留他说过的真分支。完整 `#lang racket` 里 `eval` 通常还要 namespace。他的演示像是直接 `(eval foo)` 就跑了。抽取不把 namespace 参数写进他的例子。

```racket
(define (make-some-code1 y)
  (if y
      (list 'begin
            (list 'print "hi")
            (list '+ 4 2))
      other-list))

(define foo (make-some-code1 #t))
;; foo 是数据，还不是正在跑的代码
;; '(begin (print "hi") (+ 4 2))
;; REPL 不把内部 symbol 再印成带引号，容易看成已经是代码

(car (cdr foo))          ; '(print "hi")
(car (car (cdr foo)))    ; 'print

(eval foo)               ; 打印 hi，值是 6
(eval (car (cdr foo)))   ; 只跑 (print "hi")
(eval (car foo))         ; 错误：单独的 symbol begin 不是合法程序
```

```text
在 eval 之前：
foo → list
      ├── symbol begin
      ├── list (symbol print, "hi")
      └── list (symbol +, 4, 2)

(car (cdr foo)) 拆的是数据。+ 没有被调用。

Expression: (eval foo)
Evaluation: 把 list 当 Racket 语法。
  begin 先求值 (print "hi")，副作用是打印 hi
  再求值 (+ 4 2)
Value: 6
打印不是返回值。
```

```racket
'(begin (print "hi") (+ 4 2))
;; 与上面的 list / quote 噪音等价
;; quote 下的 (+ 4 2) 不是加法
```

```text
Expression: '(+ 4 2)
Evaluation: 不查找 +，不调用加法
Value: 三元素 list，symbol +，4，2
```

宏在求值前改写语法。`eval` 是求值中把数据当语法再求值。时机不同。他没有在本讲做正式对照，只把 `eval` 接到“在一种语言里实现另一种语言”。这里被实现的语言就是宿主自己。

### 若改掉规则

- 若 `eval` 吃字符串：Racket 就得在 `eval` 里再 parse 一次。组合程序变成拼接字符串。
- 若在 `quote` 下面写一个想先算出来的表达式：它不会算，会变成程序数据的一部分。要现在算，必须换 quasiquote / unquote。
- 若实现用编译器而且程序可能调用 `eval`：不能在编译完就丢掉编译器。这不迫使语言改用解释器，只迫使发行物里带上编译能力。

| | 解释器作业 | `eval` |
| --- | --- | --- |
| 定义 | constructor 造另一门语言的 AST | list / symbol 造 Racket 自己的语法，再跑 |
| 解决的问题 | 理解环境、闭包、求值规则 | 运行时建造宿主语言的程序 |
| 关键区别 | 树的构造子是你定义的 | 树的形状就是 Racket 的括号 |
| 典型场景 | Homework 5 | REPL 的 E；他不推荐当作默认元编程工具 |

| | Racket `eval` | Python / Perl `eval` |
| --- | --- | --- |
| 定义 | 吃 list，已经是抽象语法 | 吃字符串，具体语法，先 parse |
| 解决的问题 | 程序即数据，不必再解析 | 用字符串表示代码 |
| 关键区别 | 组合是造 list | 组合是字符串拼接 |
| 典型场景 | `'(+ 4 2)` | `eval("1 + 2")`。这是他的对照，不是本课要写的代码 |

---

## 用透镜看“类型检查”

| 透镜 | 静态类型检查（ML） | 动态检查（Racket 的原语） |
| --- | --- | --- |
| Syntax | 类型注解可选。推断仍是静态的 | 源码里通常没有类型 |
| Semantics | 运行前拒绝一批程序。接受则不会做 X | 跑到坏操作时失败，失败有定义 |
| Binding | 未定义名字在运行前拒绝 | 未定义名字仍有一点静态检查；其余 tag 在运行时看 |
| Evaluation | 检查不产生值。它决定程序能否开始求值 | 检查是求值的一部分。`+` 先看 tag |
| Type | 每个子表达式一个类型。`'a` 是对所有类型同一段代码 | one-type 视角：一个 tag 上的 datatype。不是 ML 真有这个定义 |
| Lifetime | 与本轴无关 | tag 跟着值走，直到实现证明可以删 |
| Mutation | 不在这条轴上。可变性是另一项设计 | 同左 |
| Abstraction | module signature 是 purpose 的一部分：破坏边界在运行前被拒绝 | 约定和契约。失败通常在运行时 |
| Composition | 函数类型让组合在运行前被检查，也制造 false positive | 组合更自由，错误更晚 |

---

## Connection to Modern Languages

概念类比，不是等价。

- Java / C# 的静态类型是 ML 那一格的邻居，再加上 subtyping。它们仍不阻止除以 0 和数组越界；越界在 Java 里是运行时异常，不是 C 的 catch-fire。所以 Java 不是 weakly typed，尽管它是静态类型的。Weak 与 static 是两条轴。
- C / C++ 的未定义行为是他定义的 weak typing 的所在。不要把“C 是静态类型”读成“C 的类型系统 sound 地阻止了内存错误”。它对很多内存性质既不静态查、也不动态查。
- TypeScript 的类型检查更接近旁路工具加一个可关的子集：它不是语言运行时定义的全部 legal program。Grossman 把定义内的检查和旁路 bug-finder 分开。TypeScript 主要落在后者，再加一层擦除。不要把它说成 ML。
- Typed Racket 是他点名的“有的文件带类型、有的不带”。这是进行中的尝试，不是已经解决的权衡。决定从“选一门语言”挪到“这个模块要不要类型”。谁来挪，仍在。
- Python 的 `eval("1 + 2")` 是字符串上的具体语法。和 Racket 的 list-`eval` 只在“运行时把数据当程序”这一点上同类。组合方式不同。
- Rust 的 `unsafe` 不是 weak typing 的同义词。它是一块显式标出的区域，里面的某些证明改由程序员承担。越出那块区域，语言仍试图给确定的失败或拒绝。和“整个语言在越界时可以做任何事”不是同一个设计。类比到“trust me”这句旧口号可以，等价不行。

---

## Section 7 Review

这一节先拒绝把 ML 与 Racket 的差别收成括号。类型系统在运行前删程序。删掉的有永远错的，也有没有 bug 的。Racket 可以用“只有一个带 tag 的类型、原语是看不见的 pattern match”来理解，这是视角，不是 Racket 语言里的 ML datatype。Static checking 是定义的一部分，purpose 与 approach 分开，报错点是一条谱。Sound 的系统拒绝一些好程序，因为终止、sound、complete 不能对非平凡的 X 兼得。Weak typing 是静态放行、动态也不查、失败可以是任意行为。它不是动态类型。改变求值规则是第三条轴。七组论据两边都站得住。他不选赢家。`eval` 让运行时的数据成为 Racket 程序，有它不等于必须用解释器实现。

### 核心概念

subset 视角、one-type 视角、static checking、approach、purpose、soundness、completeness、false positive、false negative、undecidability、weak typing、evaluation rule、contract、backwards compatible change、to-do list、Typed Racket、`eval`、`quote`。

### 不变量

```text
静态检查 = parse 之后、运行之前拒绝。它是 legal program 的定义，不是旁路工具。
Sound ≠ complete。Sound 的系统会拒绝不会做 X 的程序。
终止 + sound + complete，对非平凡 X 不可兼得。主流选择 sound，接受 false positives。
Weak typing ≠ dynamic typing。Racket 失败必须可见。C 的越界可以着火。
定义要求检查 ≠ 实现必须执行每一次检查。只能删证明不会失败的检查。
"+ 接受 string" 可以是类型错误、运行时错误、或根本不是错误。第三者是求值规则。
类型抓不到同类型的错误运算符。pow2 3 4 = 13，不是 81。两边都要测试。
有 eval ≠ 必须是解释执行。
quote 下的 (+ 4 2) 不是加法。
```

### 能力检查

- 用 subset 和 one-type 各解释一遍 `(define (f y) (+ y (car y)))`，并指出哪个视角在说“这是 bug”，哪个视角在说“tag 上的 case 会失败”。
- 给一个你希望阻止的 X，说出一个 sound 的检查必然会拒绝的、实际上不会做 X 的程序。`f2` 那种死代码算数。
- 区分三句话：`(+ "foo" 3)` 在 Racket 里报错；在别的语言里得到 `"foo3"`；`a[10]` 在 C 里可以做任何事。它们分别落在哪条轴上。
- 解释为什么 `fun f g = (g 7, g true)` 被拒绝不是因为它有 bug，以及静态方为什么仍认为强制 tag 是代价。
- 说明加一个 datatype 构造子时，wildcard 在 prototyping 和在维护阶段为什么建议相反。
- 说明 `(eval '(+ 4 2))` 和 `'(+ 4 2)` 各是什么，以及“有 eval 所以 Racket 是解释器”错在哪里。

练习：`exercises/section-07.md`。
