# 10 — 程序是树。闭包是数据

> Part B · Section 6
> 视频：`Datatype Programming in Racket`（无 struct / 有 struct / struct 的好处）、`Implementing Programming Languages`、`What Your Interpreter Can and Cannot Assume`、`Implementing Variables and Environments`、`Implementing Closures`，以及两讲 optional：闭包是否低效、用 Racket 函数充当被解释语言的宏。

Section 3 里闭包是使用中的事实：函数值带走定义时的环境。Section 5 把同一批想法搬进没有类型系统的 Racket。到这里，问题变了。

若函数已经返回，定义它的那次调用已经结束，解释器的递归调用又只收到**当前**环境，定义时的环境从哪来？

答案不是新魔法。答案是把环境做成数据，放进一个值里。实现一次之后，“闭包”不再是讲义上的图，而是一个 struct：代码，加上当时的环境。

在此之前必须先解决一个更土的问题：Racket 没有 datatype binding。表达式树怎么表示，表示会不会被客户伪造，解释器该对哪些错误负责。这三件事没分清，后面的 `eval` 只是在 Racket 的 list 上做递归，不是在实现一门语言。

---

## 1. 这一组讲要解决什么问题？

ML 的 `datatype` 一次列出全部构造子，`case` 同时测试和拆开。Racket 没有这个绑定，也没有静态类型。于是三个不同的困难叠在一起：

- 只是把 number 和 string 放进同一个 list，还需要自己发明 sum type 吗？
- 算术表达式这种递归的 one-of，没有 constructor / tester / extractor，解释器怎么写？
- 结果一旦不只是 int，解释器为什么不能再是 `exp -> int`？

然后是实现本身：

- 程序作为字符串、作为树、作为求值，分别是谁的工作？“C 是编译型语言所以比 Lisp 快”为什么说不通？
- 坏程序有两类。一类是树根本不是这门语言的语法。一类是树合法，但运行时把数和布尔加在一起。若什么都查，解释器在做 parser。若什么都不查，用户看见的是 Racket 的 `car` 错误，语言的语义被实现细节泄露。
- 有了变量，同一棵树在不同环境里必须得到不同的值。环境是参数，不是全局表。
- 有了函数，当前环境这个参数不够。定义时的环境必须被值带走。

课程把这一段放在动态类型和延迟求值之后，是因为 AST 用 Racket 的 struct 表示，比在 ML 里再套一层类型更聚焦在语义上。作业仍是函数式的。依赖的是 Part A 的环境模型、datatype 思维、闭包的使用，以及 Section 5 的 `cond`、list、没有静态拒绝。它准备的是：Part C 用另一个解释器对比函数式分解与面向对象分解；以及“程序是树不是文本”这句话在宏和 `eval` 里的再次出现。

---

## Lecture — 没有 datatype binding 时，one-of 怎么写

视频：`Datatype Programming in Racket without Structs`。

### 困难

动态类型语言里，Grossman 的原话方向是：we don't need datatype bindings；there are different idioms；in some sense every piece of data in Racket already has a tag。

若只是把整数和字符串混在一个序列里求和，ML 必须先造一个新类型，否则 list 的元素类型无法同时是 `int` 和 `string`。Racket 的 list 本来就允许混装。每个值自己带着“我是 number 还是 string”。

```sml
datatype int_or_string = I of int | S of string   (* 类型名口述不清 *)

fun funny_sum xs =
    case xs of
        [] => 0
      | (I i)::xs' => i + funny_sum xs'
      | (S s)::xs' => String.size s + funny_sum xs'
```

```racket
(define (funny-sum xs)
  (cond [(null? xs) 0]
        [(number? (car xs))
         (+ (car xs) (funny-sum (cdr xs)))]
        [(string? (car xs))
         (+ (string-length (car xs))
            (funny-sum (cdr xs)))]))
```

他故意不写 `else`。Racket 里通常写 `else` 更好。省略它，是为了更接近 ML 的 `case`：未知种类走到末尾，运行时失败，而不是被吞掉。

```text
Expression: (funny-sum (list 3 "hi"))
Environment: funny-sum → 上述函数

null? 为假，number? 为真
  → (+ 3 (funny-sum '("hi")))
内层 string? 为真
  → (+ 2 0)
Value: 5
```

这解决的是“已有类型的异构集合”。它不解决“我要一种新的递归形状，而且 Add 和 Multiply 必须是不同的种类”。表达式树没有内建谓词。你得自己做 tag。

### 解释器的结果必须是表达式

旧的 ML 解释器类型是 `exp -> int`。语言只能产出整数时够用。一旦结果可以是 pair、function、string、bool，base case 不能再把 `Const` 拆成裸整数，否则递归的结果没有统一的形状。

新约定：`exp -> exp`。Base case 返回整个 `Const`。递归 case 先得到一个表达式，确认它是 `Const`，取出整数，运算，再用 `Const` 包回去。

```sml
fun get_int e =
    case e of
        Const i => i
      | _ => raise BadResult          (* 异常名他没说 *)

fun eval_exp_new e =
    case e of
        Const _ => e
      | Negate e2 =>
          Const (~ (get_int (eval_exp_new e2)))
      | Add (e1, e2) =>
          Const ((get_int (eval_exp_new e1))
                 + (get_int (eval_exp_new e2)))
      | Multiply (e1, e2) =>
          Const ((get_int (eval_exp_new e1))
                 * (get_int (eval_exp_new e2)))
```

```text
Expression: eval_exp_new (Multiply (Negate (Add (Const 2, Const 2)), Const 7))

Add → Const 4
Negate → Const (~4)
Multiply → Const (~28)

Value: Const (~28)
不是 ~28。
```

若 base case 返回 int，递归处的 `get_int` 会在“已经是 int”上失败。若结果种类变多仍只认 `Const`，pair 和 function 会被当成错误。这不是风格。这是“值不止一种”逼出来的表示。

### 用 list 和 symbol 伪造构造子

没有 datatype 时，用 list 编码 variant：第一个元素是 tag，后面是字段。自己写 constructor、tester、extractor。这不是模式匹配。“有哪几种表达式”只存在于注释和文档里。动态类型系统不知道什么是 expression，也不知道只有四种。

Symbol 写成 `'foo`，不是 `"foo"`。可以暂时把它想成字符串，但它们是不同的值。`eq?` 比较 symbol 不必扫描字符，所以快。tag 用 symbol 只是方便。他说 we could have done it with strings。

```racket
(define (Const i) (list 'Const i))
(define (Negate e) (list 'Negate e))
(define (Add e1 e2) (list 'Add e1 e2))
(define (Multiply e1 e2) (list 'Multiply e1 e2))

(define (Const? e) (eq? (car e) 'Const))
(define (Add? e) (eq? (car e) 'Add))
(define (Multiply? e) (eq? (car e) 'Multiply))

(define (Const-int e) (car (cdr e)))
(define (Add-e1 e) (car (cdr e)))
(define (Add-e2 e) (car (cdr (cdr e))))
(define (Multiply-e1 e) (car (cdr e)))
(define (Multiply-e2 e) (car (cdr (cdr e))))
```

`Add-e1` 和 `Multiply-e1` 是同一段代码。对一个 Add 列表调用 `Multiply-e1` 不是错误，只是返回第一个子表达式。本讲几乎不检查用错 variant。编程时信任自己用对了 constructor。更稳健的 extractor 会再查 tag。他预告下一讲要修的就是这个静默成功。

**If changed.** 给 `funny-sum` 加 `else`，未知类型被吞掉，不再对应 ML 的穷尽失败。tag 改用 string，语义能做完，比较更慢。

---

## Lecture — `struct` 不是 list 编码的语法糖

视频：`with Structs`，`Advantages of Structs`。

### 困难

手写 constructor / tester / accessor 能跑。若 `struct` 只是少写几行 helper，它就是糖，误用时的行为和 list 一样。问题是：用错 accessor、伪造一个“看起来像 Add”的值、想对客户隐藏表示时，list 为什么挡不住，struct 为什么挡得住？

他要钉死的句子：struct definitions are **not** syntactic sugar for the list approach。

### 一个声明引入的是什么

```racket
(struct foo (bar baz quux) #:transparent)
```

`struct` 是 special form，不是函数调用。求值之后环境里多出一组函数：constructor `foo`（参数先求值，返回一个新的 foo 值）、谓词 `foo?`、accessor `foo-bar`、`foo-baz`、`foo-quux`。对非 foo 调用 accessor 是运行时错误。

它像 record：字段有名字。又多一个谓词。和一个 ML datatype binding **不是一回事**。

| | `struct` | ML datatype binding |
| --- | --- | --- |
| 定义 | 一次声明 ≈ 一个 constructor，外加谓词和 accessor | 一次绑定列出一组 constructor，构成一个类型 |
| 解决的问题 | 在动态类型里造一种新的数据种类 | 在静态类型里封闭一个 one-of |
| 关键区别 | 不声明“全部 variant”，不声明字段类型 | 类型定义就是全部 variant，字段类型写在构造子上 |
| 典型场景 | `const`、`add`、`multiply` 各是一个 struct | `datatype exp = Const of int \| Add of exp * exp \| ...` |

动态类型里没有“这些 struct 合在一起构成唯一的 exp 类型”。`multiply` 的字段应该是表达式、`const` 的字段应该是数，是程序员的责任。Racket 有办法加约束，他点到为止，不走那条路。这也不是 pattern matching。他个人更喜欢 case。tester / extractor 风格能用，而且高效。

`#:transparent` 让 REPL 把值印成 `(const 17)`。去掉它，constructor、谓词、accessor 的语义不变，REPL 不打印字段。不透明不等于取不到字段。`#:mutable` 再给每个字段一个 `set-…!`。可变数据的 alias 问题前面已经讨论过。本 section 的表达式树不用 mutation。

```racket
(struct const (int) #:transparent)
(struct negate (e) #:transparent)
(struct add (e1 e2) #:transparent)
(struct multiply (e1 e2) #:transparent)

(define (eval-exp e)
  (cond [(const? e) e]
        [(negate? e)
         (const (- (const-int (eval-exp (negate-e e)))))]
        [(add? e)
         (let ([v1 (const-int (eval-exp (add-e1 e)))]
               [v2 (const-int (eval-exp (add-e2 e)))])
           (const (+ v1 v2)))]
        [(multiply? e)
         (let ([v1 (const-int (eval-exp (multiply-e1 e)))]
               [v2 (const-int (eval-exp (multiply-e2 e)))])
           (const (* v1 v2)))]))

(define x (add (const 3) (const 4)))
;; (eval-exp x) => (const 7)
```

```text
Expression: (eval-exp (add (const 3) (const 4)))
Environment: add、const、eval-exp 已绑定

add? 为真
  add-e1 → (const 3)，const? 为真，原样返回
  const-int → 3
  同理 v2 = 4
(const (+ 3 4))：constructor 先算 7，再装箱
Value: (const 7)
一个 const struct。不是数 7，也不是 list。
```

`(const (+ 3 4))` 印出来是 `(const 7)`。`const` 是 Racket 函数，参数按 Racket 规则求值。语言 B 的延迟不会自动出现。你存进去的是已经算完的 7，不是一棵尚未相加的树。

### 误用时才看得出它不是糖

```racket
(define x (add (const 3) (const 4)))
;; (pair? x)       => #f
;; (list? x)       => #f
;; (multiply? x)   => #f
;; (add? x)        => #t
;; (multiply-e1 x) => 运行时错误
;; (cdr x)         => 运行时错误

(add 7 19)   ;; 作为 add 值合法，作为我们心目中的表达式非法
```

每个 struct 定义都在给 Racket 增加一种新的原始数据种类，地位类似“pair 是 pair、number 是 number”。对所有旧谓词回答假。函数做不到这一点：函数不能像 `struct` 那样一次引入多个绑定。宏也做不到：宏不能创造一种新的 type tag。若新数据是用已有数据搭出来的，`pair?` 或 `number?` 会为真，因为它本来就是那种数据。

List 方案没有这些性质。`Add` 只是返回三元素 list 的普通函数。结果是 list，也是 pair。`car` / `cdr` 随便用。`Multiply-e1` 对一个 Add 列表不是错误。

```text
Expression: (Multiply-e1 (Add (Const 3) (Const 4)))
Evaluation: 不看 tag，直接 (car (cdr x))
Value: '(Const 3)
看起来像一次成功的字段读取。这是静默错误。
```

正确使用时，两套 helper 差不多一样方便。优势出现在误用时：struct 失败得更早。

动态类型也能做抽象。错觉是：没有静态类型就不能做 ML 那种 type abstraction。事实是：把 struct 放进 module，只 `provide` accessor，不提供 constructor。客户不能自己构造，只能走你导出的、会检查不变量的函数。他们也造不出一个能通过 `add?` 的 list，因为 add 根本不是 list。

List 做不到。任何人都能造一个首元素是 symbol `'Add` 的 list，它会伪装成 Add，即使不满足不变量。Contract 可以挂在这种新种类上，要求“子表达式本身也是表达式”。把同一条 contract 挂到所有 list 上没有意义。

这是和 ML abstract type 的 conceptual analogy，不是同一种机制。ML 靠类型相等性拒绝客户。Racket 靠不导出 constructor，使客户无法满足 `add?`。

**If changed.** 若 struct 只是宏、展开成 list，`pair?` 为真，module 也藏不住伪造的 list。若模块把 constructor 也导出，客户可以 `(add 7 19)` 绕过不变量。抽象边界破了。若 list 版的 extractor 先查 tag，误用 accessor 能报错，伪造 `(list 'Multiply ...)` 仍然可能。检查是约定，不是新的数据种类。

---

## Lecture — 实现一门语言：树，不是文本

视频：`Implementing Programming Languages`。

### 困难

作业要实现一门小语言。在写解释器之前，必须先分清三样东西，否则“我在写 Racket”和“我在实现一门语言”会焊死：

```text
字符串（concrete syntax）
  → parser          失败：括号、关键字位置。这是语法错误
  → AST             仍是语法，但是树
  → type checker    失败：能 parse，但类型不对
  → interpreter 或 compiler 之后的运行
  → 答案
```

本课跳过 parser 和 type checker。程序员用 Racket 的 constructor 直接写抽象语法树（Abstract Syntax Tree）。不合法的树可以让解释器崩溃。下一讲把这条线画精确。跳过 parser 不是跳过语法。跳过的是 concrete syntax。抽象语法还在：哪个构造、怎么嵌套。

他描述的一棵树：调用的第二个孩子是常量 4；函数有参数 `x`，函数体是 `x` 加 `x`。幻灯片上可能画过 negation，口播纠正为 const。字段名他没念，下面的 struct 是重建，不要当成他的作业 API。

```text
call
├── function
│   ├── argument: x
│   └── body: add
│       ├── var x
│       └── var x
└── const 4
```

这棵数据还没被解释。构造它只得到一棵树。求值发生在解释器看见它的时候，不是 Racket 构造它的时候。

### Interpreter 不是语言的属性

实现语言 B 有两条基本路。A 是用来写实现的语言，称为元语言（metalanguage）。

- 解释器（interpreter）：用 A 写一个程序，吃进 B 的树，算出答案。更好的名字是 evaluator 或 executor。大家都叫 interpreter。
- 编译器（compiler）：也用 A 写成，但产出的是语言 C 中一个等价程序，然后靠 C 已有的实现去跑。更好的名字是 translator。若 C 是机器码，硬件就是 C 的实现。

现实不是二选一。多数 Java 实现先编译到 bytecode，不是机器码；再解释 bytecode；解释器里又带一个把热代码编译到硬件的编译器；芯片还可能把 x86 再译成更小的内部指令然后解释。Racket 的实现也是混合。这不是 Java 特有的。

语言由写出的语义规则定义。用 compiler、interpreter 还是二者的组合，是实现细节。因此没有 “compiled language” 或 “interpreted language” 这种东西。只有“某次实现用了解释器”或“某次实现用了编译器”。

“C is faster than Lisp because C is a compiled language and Lisp is an interpreted language” 不仅错，而且说不通。他会礼貌地纠正。唯一让这句话“好像有点意思”的情况是语言里有 `eval`：实现必须在运行时还在，因为可能要再实现一段同语言程序。但 `eval` 本身用 compiler 实现也完全可以。

我们已经实现过一门语言。

```text
A = Racket
B = {const, negate, add, multiply}
实现 = eval-exp
(eval-exp (add (const 3) (const 4))) => (const 7)
```

程序的表示是 Racket 数据。语言是这些构造的求值规则。表示载体不是语言。作业要做的只是：在这个框架里实现比加减乘更有意思的构造。

**If changed.** 若作业从字符串开始，语法错误和语义错误会混在一起。他故意拿掉 parser，让学生只面对语义。若把 `eval-exp` 换成“编译成 Racket 函数再调用”，对这门小语言也行，按他的定义那就是 compiler，目标语言是 Racket。这门语言并不会因此变成“编译型语言”。

| | concrete syntax | AST |
| --- | --- | --- |
| 定义 | 程序员写下的字符串 | parser 产出的树；本课由 constructor 直接写出 |
| 解决的问题 | 让人能键入程序 | 让实现按构造递归，而不是扫描字符 |
| 关键区别 | 括号和关键字位置在这里有意义 | 构造和嵌套在这里有意义 |
| 典型场景 | 语法错误 | 类型错误、求值 |

| | interpreter | compiler |
| --- | --- | --- |
| 定义 | 用 A 对 B 的树求值，直接给答案 | 用 A 把 B 译成等价的 C 程序 |
| 解决的问题 | 实现语义 | 同样是实现语义，只是把最后一步交给 C |
| 关键区别 | 实现本身在“跑”B | 实现本身不跑 B |
| 典型场景 | 本课的 `eval-exp` | 译到机器码、bytecode，或甚至译回 Racket |

---

## Lecture — 解释器可以假设什么，必须检查什么

视频：`What Your Interpreter Can and Cannot Assume`。

### 困难

解释器会看到坏程序。若什么都检查，就把“树根本不是 B 的语法”和“树是合法 B 程序，但运行时用错了值”混成一类。若什么都不检查，用户看到的是 Racket 的 accessor 错误。语言 B 的语义被实现细节泄露。

两条义务：

1. **可以假设** 拿到的 AST 合法：作为语法树它说得通。若不合法，崩溃并给出奇怪信息是允许的。
2. **必须检查** 语言 B 里各处数据的种类。特别是：递归求值一个子表达式之后，必须检查得到的是哪一种结果。

不必检测的例子：`(negate -7)`，`-7` 是 Racket 数，不是表达式；`(const #t)`，`const` 的字段按文档应是 number；multiply 的某个子位置上是字符串。这些是建树错误。对 `(negate -7)` 给出难看的底层信息，被允许。作业不要求你做 parser。

必须检测的例子：把 `(const 17)` 和 `(bool #f)` 相加。树可以是合法的：两个子节点都是表达式。错在求值之后的值种类。错误信息必须关于语言 B，例如“把非 number 相加”。不要暴露 “took car” 或 “expects a const struct”。

### Value 求值到自身

解释器每次调用返回的都是 value，不是任意表达式。Value 是一种表达式，而且求值到它自己。若某条路径返回尚未归约的 addition 或 negation，解释器有 bug。

目前这种简单语言，每次调用都应返回 `const`。语言若有多种 value，递归结果就不只是数。作业里还会有：两个分量都已经是 value 的 pair（并非所有 pair 都是 value）、boolean、string、closure。Closure 是 value。函数表达式本身不是。这个区别下一讲才强制，规则在这里已经写上：返回的东西必须是对象语言的值。

Racket 的 `#t` / `#f` 不是解释器可以返回的东西。`eq-num` 可以用 Racket 的 `equal?` 得到 true 或 false，然后必须用 `bool` constructor 包成语言 B 的值。元语言的值和对象语言的值不是同一个世界。

扩展后的构造：`bool`、`eq-num`（两个子表达式，不是两个数；和 add 一样，先求值再比较）、`if-then-else`。

缺检查的解释器对“全是数”的程序仍然正确。它错在假定递归结果一定是 `const`：

```racket
;; 错：假定递归结果一定是 const
[(negate? e)
 (const (- (const-int (eval-exp-wrong (negate-e e)))))]
```

正确的形状是：value 分支原样返回（允许假设 AST 合法）；运算分支把递归结果绑到局部变量，再问种类。

```racket
(define (eval-exp e)
  (cond
    [(const? e) e]
    [(negate? e)
     (let ([v (eval-exp (negate-e e))])
       (if (const? v)
           (const (- (const-int v)))
           (error "negate applied to non-number")))]
    [(add? e)
     (let ([v1 (eval-exp (add-e1 e))]
           [v2 (eval-exp (add-e2 e))])
       (if (and (const? v1) (const? v2))
           (const (+ (const-int v1) (const-int v2)))
           (error "add applied to non-number")))]
    [(bool? e) e]
    [(eq-num? e)
     (let ([v1 (eval-exp (eq-num-e1 e))]
           [v2 (eval-exp (eq-num-e2 e))])
       (if (and (const? v1) (const? v2))
           (bool (equal? (const-int v1) (const-int v2)))
           (error "eq-num applied to non-number")))]
    [(if-then-else? e)
     (let ([v1 (eval-exp (if-then-else-e1 e))])
       (if (bool? v1)
           (if (bool-b v1)
               (eval-exp (if-then-else-e2 e))
               (eval-exp (if-then-else-e3 e)))
           (error "if-then-else test not a bool")))]
    ;; multiply 与 add 同样：先 const?，再 const-int
    ))
```

`error` 的字符串除了 “Negate applied to non-number” 之外是重建。要点不是措辞。要点是信息关于 B，而且检查发生在递归之后。

他给的测试，算术结果以他说的 minus 28 为准。后半口述曾滑成 “const 28”。按乘法，值是 `(const -28)`。test2 的条件表达式他没有逐字念出。可以确定的是：`if` 的结果是布尔 true，然后 multiply 收到 number 和 boolean。

```text
test1: (multiply (negate (add (const 2) (const 2))) (const 7))
  正确解释器 → (const -28)
  缺检查的解释器 → 同样成功。假设碰巧成立。

test2: multiply 的一边是 (const -4)，另一边是 if 求出的 (bool #t)
  正确解释器 → 关于非 number 的错误
  缺检查的解释器 → 对 bool 调用 const-int，Racket accessor 错误

(const #t) 或 (negate -7)
  两者都可以给出可怕信息。这不是语言 B 的动态类型错误。
```

| | 可以假设、崩溃即可 | 必须检查并给出 B 的错误 |
| --- | --- | --- |
| 定义 | AST 不合法 | 合法 AST 求值后，构造用错了 value 种类 |
| 解决的问题 | 不让解释器重做 parser | 实现语言 B 的动态类型规则 |
| 关键区别 | 错在建树 | 错在值 |
| 典型场景 | `(negate -7)`、`(const #t)`、字段里是 string | 数加布尔；`if` 的测试求值得到 const |

| | 对象语言的 value | 元语言的值 |
| --- | --- | --- |
| 定义 | `(const n)`、`(bool b)`；求值到自身 | Racket 的 `7`、`#t`、list |
| 解决的问题 | 解释器有统一的返回种类 | 实现解释器时做算术和比较 |
| 关键区别 | 调用方只该看见 B | 漏出去之后，`bool?` 失败，或用户看见 Racket 的错误 |
| 典型场景 | `eq-num` 比较完必须 `(bool ...)` | `equal?` 的结果还不是 B 的值 |

**If changed.** 去掉递归结果检查：全是数的程序仍对，数加布尔变成 accessor 错误。语言 B 的类型规则没有被实现。`eq-num` 若返回 Racket 布尔，元语言的值漏进了对象语言。

---

## Lecture — 变量就是在当前环境里查找

视频：`Implementing Variables and Environments`。

### 困难

没有变量时，`eval-exp` 只看一棵树就够。一旦出现名字，同一棵树在不同位置必须指不同的值。查找发生在哪？谁把绑定放进环境？子表达式继承哪一份环境？

他不展示作业代码。语义用英语说死。这就是课程从 ML 第一节就在教的那一套。实现它，是为了确认自己真的懂。

### 机制

求值一个表达式，总是在一个当前 environment 里求值。环境把变量映射到 **value**。Value 是对象语言里求值可以返回的东西，不是尚未归约的 add。

作业规定的表示可以是别的，但评分用这个：Racket 的 list of pairs。每个 pair 的左边是 **Racket string**（变量名），右边是 MUPL value。MUPL 是作业里的虚构语言（Made Up Programming Language）。常量写成 `(int 17)`，不是讲义里的 `(const 17)`。讲义和作业不要混名。

```racket
;; 形状，不是他给出的完整解释器
;; env 例：(list (cons "x" (int 17)) (cons "y" (bool #t)))

(define (eval-under-env e env)
  (cond
    ;; 变量：按字符串查找；没有则报“没找到这个变量”
    ;; add：两个子表达式都用同一份 env
    ;; let：先用 env 求值绑定表达式得到 value，
    ;;      再求值 body，环境是 (cons (cons var value) env)
    ...))

(define (eval-exp e)
  (eval-under-env e '()))
```

`eval-exp` 从空环境开始。程序开始时没有任何变量被绑定。很多表达式把同一份环境传下去。加法的两个子表达式看见同一组名字。有些表达式传不同的环境。`let` 是最明显的一个：body 的环境比当前环境多一个绑定。

```text
Expression: (let "x" (int 1) (var "x"))
外层环境: 空

1. 绑定表达式在空环境中求值
   (int 1) 是 value，返回自身
2. body 的环境: (("x" → (int 1)))
   变量 case 查到 (int 1)

Value: (int 1)
```

```text
Expression: (add (var "x") (var "y"))
Environment: (("x" → (int 3)), ("y" → (int 4)))

两个子表达式收到同一份 list
查找 "x" → (int 3)
查找 "y" → (int 4)
两者都是 int，相加，包回对象语言的值

Value: (int 7)
```

若环境里没有 `"y"`，变量 case 报没找到。不是 Racket 对空 list 做 `car`。那又是把实现细节漏给语言 B 的用户。

`eval-under-env` 一般不应被用户直接调用。作业却要求它在文件顶层，不要写成 `eval-exp` 内部的局部函数。评分脚本要用特定环境直接调用它。局部 helper 风格更好。他明确选可测试性，并承认这一点。

变量名若用 symbol 而作业用 string，查找永远失败。初始环境若不是空的，程序会看见没绑定过的名字。add 的两个子表达式若用了不同的环境，加法不再是“当前环境里的绑定”。这些都还不是词法作用域和动态作用域的差别。这里还没有嵌套函数。差别在下一讲。

对象语言的变量和 Racket 的变量不是同一个环境。对象语言的环境是你显式传递的那个 list。解释器闭包捕获的 Racket 变量，不会自动变成 MUPL 的绑定。

---

## Lecture — 闭包：把定义时的环境存进值

视频：`Implementing Closures`。

### 困难

词法作用域（Lexical Scope）要求：求值函数体时，用的是函数被定义处的环境，再扩展成“参数名 → 实际参数值”。解释器的递归调用只收到当前环境。没有一个参数叫“定义时的环境”。

函数已经作为值返回，定义它的那次调用已经结束之后，那份环境若只活在调用栈上，就没了。高阶函数、`map`、`filter`、函数体里没有定义的变量，全部依赖它还在。

要实现的是词法作用域，不是动态作用域（Dynamic Scope）。

### 没有魔法的那一招

定义函数时，创建一个包含当时环境的 closure。以后使用这个 closure 时，环境已经在里面。

程序员用来写程序的那些 struct 之外，再加一个他们不该在源程序里使用的 struct。测试可以拿来用。字段名按口述重建：函数（参数名和函数体），以及 environment。

```racket
;; 源程序不该写这个。测试可以。
(struct closure (fun env) #:transparent)
```

规则：

- Closure 是 value。遇到就返回它自己。
- 口语里常说 functions are values。严格地说，**closure 才是 value**。函数表达式不是 value。
- 解释一个函数表达式：不求值函数体。用当前环境和这个函数做一个 closure，返回它。
- 调用 `e1` 和 `e2`：
  1. 用**当前**环境求值 `e1`，必须得到 closure。否则是错误，例如把数当函数用。
  2. 用**当前**环境求值 `e2`，得到一个 value。
  3. 求值 closure 里的函数体。使用的不是当前环境，而是 **closure 里存的那份环境**。
  4. 在那份环境上扩展：参数名 → `e2` 的值。
  5. 再扩展一次，为了递归：函数的名字 → **整个 closure**，不是只映射到函数 AST。

第 5 步是他称为 little workaround for recursion 的那条。递归调用需要同一个 closure，因为还需要那份环境。若名字只映射到函数 AST，再次进入“函数表达式”的 case 会用当时的环境重新做 closure。定义时的环境就丢了，或被调用环境替换。

```text
closure = code + environment

创建：求值函数定义时，把当前环境存进去。不求值 body。
使用：用存进去的那份环境求值 body，不用调用点的环境。
每次求值函数定义：新 closure，环境是那一次的当前环境。
同一个 closure：其 body 永远只用它自己的那一份环境。
```

```text
定义处
  Environment env1: "x" → (int 10)
  Expression: 函数，参数 "y"，body 使用 y 和 x
  Evaluation: 不求值 body
  Value c:
    closure
      fun:  参数 y，body ...
      env:  "x" → (int 10)

调用处
  Environment: "x" → (int 20)，"f" → c
  Expression: (call (var "f") (int 1))

  1. e1 在调用处环境查到 c。c 是 closure。
  2. e2 得到 (int 1)。
  3. body 的环境从 c 的 env 扩展，不是从调用处环境扩展：
       "x" → (int 10)          ; 定义时的
       "y" → (int 1)           ; 这次的参数
       函数名 → c              ; 整个 closure，为了递归
  4. 自由变量 x 是 10，不是 20。
```

若改成动态作用域：body 从调用处环境开始，`x` 是 20。调用点的环境只应该用来求值 `e1` 和 `e2`。这就是词法作用域的实现，也是 Section 3 那张图的可执行版本。

当时说过 closure 是一个 pair。现在 struct 有两个字段，就是这个 pair。实现之后，语言的用户才能写高阶函数，并使用前面学过的那些 closure 惯用法。所谓魔法，是创建时存环境、使用时取出环境。

**If changed.** 调用时用当前环境求值 body：这是动态作用域。函数的含义依赖谁调用了它，Section 3 给出的三条推理全部失败。不把函数名映射到整个 closure：递归的自由变量从错误的环境开始查。在源程序里手写 `closure` struct：你在伪造 value，绕过“函数表达式求值时才捕获环境”。测试可以这么做。语言的用户不该这么做。

---

## Lecture — 朴素闭包慢在空间，不慢在语义

视频：optional `Are Closures Efficient?`。

### 困难

若“支持 closure 的语言必然慢”，前面把 closure 当核心特性就是不负责任的。要分开：时间成本、空间成本，以及真正的实现会改哪两件事。作业里的实现不必做这些优化。语义不变。

朴素实现把整个当前环境存进 closure。建 closure 是把一个指针放进 struct，时间便宜。空间浪费：环境里可能有函数体永远不会查的绑定，而这个 closure 让那些绑定活得更久。

自由变量（free variable）是出现在函数体中、且不在函数体内定义的变量。它是“任何可能被查到的变量”，不是“每次调用一定用到的变量”。一个条件只在一个分支用 `y`、另一个分支用 `z`，自由变量仍是 `{y, z}`。没有自由变量相当常见。但文件前面的顶层绑定若被函数体使用，它们也是自由变量，也必须放进求值该函数时创建的 closure。Shadowing 只取消被局部绑定挡住的那些出现。局部绑定之前使用过一次的名字，那一次仍然算自由出现。

实践中的两步，作业不做：

1. 求值前对每个函数算一次自由变量。建 closure 时只在当前环境里查找这些名字，存一份小环境。
2. 闭包转换（closure conversion）：每个函数变成多一个环境参数；每个 call site 多传一个环境；自由变量改到这个额外参数里查找。产生函数值时，仍然是“当前这份环境参数 + 函数体”。

作业用 list of pairs，查找是线性扫描。实践用平衡树或哈希表。改的是数据结构，不是“环境是变量到值的映射”这个语义。

慢的是你选择的表示，不是词法作用域这条规则。

---

## Lecture — 用 Racket 函数充当宏，但不获得 hygiene

视频：`Racket Functions as Macros for the Interpreted Language`。

### 困难

作业语言很小。若每个语法糖都要加一个 struct、再给解释器加一个 case，实现会被糖淹没。宏（macro）的本意是：在程序运行前，按定义把语法重写成更小的核心语言。

在“B 的程序就是 A 的数据结构”这个设定里，怎样得到同样的效果，而不改解释器？把两件已有的事接起来：用 A 的 constructor 写 B 的 AST；宏在运行前扩展语法。一个吃语法、吐语法的 Racket 函数，在调用 `eval-exp` 之前就完成了展开。它不是语言 B 的 struct，解释器看不见 `andalso`。

```racket
(define (andalso e1 e2)
  (if-then-else e1 e2 (bool #f)))

(define y (andalso (bool #t) (eq-num (const 3) (const 4))))
;; y 已经是展开后的树，不是求值结果：
;; (if-then-else (bool #t)
;;               (eq-num (const 3) (const 4))
;;               (bool #f))
;; (eval-exp y) => (bool #f)
```

```text
Expression: (andalso (bool #t) (eq-num (const 3) (const 4)))
这是 Racket 函数调用，不是语言 B 的求值。

参数先求值，得到两棵树。
andalso 返回一棵 if-then-else 树。
此时还没有解释。

(eval-exp y)：
  测试 (bool #t) 求值到自身，bool-b 为真
  走第二个参数那棵树
  eq-num：3 与 4 不相等
Value: (bool #f)
```

`double` 是 `(multiply e (const 2))`。`list-product` 在 Racket 里递归，把一列表达式树收成一棵嵌套的 `multiply`，空列变成 `(const 1)`。这些函数在 Racket 求值时就跑完了。`eval-exp` 看见的只有核心构造。

他描述的组合例子：`andalso` 的测试是 `eq-num`，左边 `double` of `(const 4)` 变成乘 2，右边 `list-product` 变成嵌套乘法，then 分支是 `(bool #t)`，else 分支是 `andalso` 写死的 `(bool #f)`。`4*2 = 8`，`2*2*1*2 = 8`，相等，第二个参数为真。`(eval-exp test)` 得到 `(bool #t)`。`test` 这个绑定在解释之前只是语法。

### 代价

这种“Racket 函数生成 B 语法”的宏不处理对象语言的变量遮蔽。若宏引入的变量名和用户程序里的变量名相同，语义会让人惊讶。规避办法是宏里用奇怪的、用户不太会写的名字。真正的 Racket `define-syntax` 会处理 hygiene。这套惯用法没有那个性质。Section 5 的 optional 材料讲过 hygiene。这里是同一件事的反面：你得到了“运行前重写语法树”，没有得到“宏引入的绑定不会捕获用户的绑定”。

**If changed.** 若 `andalso` 是语言 B 的 struct，解释器必须加一个 case，而且短路必须在那个 case 里实现：第二个表达式不能在测试为假时求值。用 Racket 函数展开成 `if-then-else`，短路是解释器里已经有的规则，糖本身不求值 `e2`。它只是把 `e2` 这棵树放进 then 分支。这和 ML 里 `andalso` 不能是普通函数，是同一类原因：要控制哪个子表达式会跑，必须在求值前决定形状。

---

## 对照

### Function vs Closure

| | 函数表达式 | Closure |
| --- | --- | --- |
| 定义 | AST 节点：参数名、函数体，也许还有函数名 | 值：那份代码，加上定义时的环境 |
| 解决的问题 | 让程序员写下函数 | 让函数被调用时仍找得到自由变量 |
| 关键区别 | 不是 value。求值它才产生 closure | 是 value。遇到就返回自身 |
| 典型场景 | 源程序里的 `fun` | 解释器内部的 `closure` struct；测试可以构造，用户不该写 |

### 调用点的环境 vs 闭包里的环境

| | 当前环境（调用点） | Closure 里的环境 |
| --- | --- | --- |
| 定义 | `eval-under-env` 这次收到的 env | 求值函数定义时存进去的 env |
| 解决的问题 | 求值 `e1` 和 `e2`：函数是哪个值，参数是什么 | 求值函数体 |
| 关键区别 | 用它求 body 就是动态作用域 | 用它求 body 就是词法作用域 |
| 典型场景 | `(var "f")` 查到 closure；实参算出 `(int 1)` | 自由变量 `x` 仍是定义时的 10，尽管调用处 `x` 已是 20 |

### List 伪造的 variant vs struct

| | list + symbol | struct |
| --- | --- | --- |
| 定义 | 普通 list，第一个元素当 tag | 一种新的数据种类 |
| 解决的问题 | 只用已学过的 list 就能写解释器 | 误用时失败；可以隐藏构造器 |
| 关键区别 | `pair?` 为真；错 accessor 往往静默成功 | 对旧谓词为假；错 accessor 立即错误 |
| 典型场景 | 教学上的第一版 `eval-exp` | 作业的 AST 和值 |

---

## 用透镜看一次函数调用

| 透镜 | 语言 B 的函数调用 |
| --- | --- |
| Syntax | 一棵 `call` 树，两个子表达式。没有 concrete syntax |
| Semantics | `e1` 必须求出 closure；body 在 closure 的环境加参数、加递归绑定之后求值 |
| Binding | 参数名和函数名在 body 的环境里。函数名指向整个 closure |
| Scope | 自由变量按定义时的环境。调用点的环境不参与 body |
| Evaluation | 函数体在调用时才求值。构造 closure 时不求值 body |
| Type | 作业没有静态类型。动态检查：`e1` 的值是不是 closure，递归结果是不是这次运算要的种类 |
| Lifetime | 定义时的环境被 closure 保住，比那次 `let` 或调用活得更久 |
| Mutation | 本课的环境和 struct 不用 mutation。换一份环境是 cons 一个新 pair，不是改旧 list |
| Abstraction | 用户看见的是函数值。环境不出现在“我调用了一个函数”这个表面上 |
| Composition | 语言因此能写 `map` 和 `filter`。糖用 Racket 函数展开成这些核心构造，解释器不必为每个糖加 case |

---

## Connection to Modern Languages

这些是概念类比，不是等价。

- 编译器教材里的 AST、Python 的 `ast` 模块、Rust 的过程宏拿到的 token tree，和这里“程序是树”是同一句话。它们的具体节点类型不同。
- Java 的 bytecode、V8 的混合执行，是他用来拆穿 “interpreted language” 的例子。不要把某门语言的常见实现记成那门语言的定义。
- ML 的 closure 和这里的 `(struct closure (fun env))` 是同一个语义对象。ML 实现把它藏起来。作业把它写成你能打印的值。能打印，不意味着用户应该构造它。
- C 的函数指针只有代码，没有环境。Section 3 的 optional 讲用 `void *` 把环境显式传进去。本讲的 closure 就是那对 `(代码, 环境)` 被语言当成一个值。C 没有这个值，所以类型里必须多一个参数。
- Racket 的 `struct` 隐藏构造器，像 ML signature 不导出 datatype 的构造子。机制不同：一边是类型检查拒绝，一边是客户根本没有那个函数，也造不出能通过谓词的值。
- Hygiene 是宏的变量捕捉问题。这里的 Racket 函数展开没有它。C 预处理器也没有。不要把“能在运行前重写”说成“和 `define-syntax` 一样安全”。

---

## Section 6 Review

这一节把“实现一门有一等函数的语言”拆成几件可以单独做错的事：用不可伪造的 tag 表示语法树；解释器返回对象语言的 value，不返回元语言的裸值；非法的树可以崩溃，求值之后的种类错误必须由解释器报告；变量是在显式传入的环境里查找；函数表达式求值成 closure，调用时用 closure 里的环境而不是调用点的环境。语法糖可以在调用解释器之前由 Racket 函数展开，解释器因此保持很小，但也因此没有宏的 hygiene。

### 核心概念

metalanguage、object language、concrete syntax、AST、interpreter、compiler、struct 作为新的数据种类、value 求值到自身、environment、closure、free variable、hygiene 的缺失。

### 不变量

```text
程序（对实现而言）= 树，不是文本
compiled / interpreted 不是语言的属性
struct ≠ list 编码的语法糖
解释器返回 B 的 value，不返回 Racket 的数或布尔
非法 AST 可以崩溃；value 种类用错必须报 B 的错误
eval-exp 从空环境开始
子表达式收到的环境可以和当前环境不同；let 的 body 就是这样
closure = code + 定义时的环境
调用 body 时不用调用点的环境
递归绑定指向整个 closure，不是指向函数 AST
吃语法、吐语法的 Racket 函数在 eval 之前展开；它不处理对象语言的变量捕捉
```

### 能力检查

- 给一个 list 版的 Add，说明 `Multiply-e1` 为什么会静默成功，以及 struct 版在哪一步失败。
- 指出 `(negate -7)` 和“数加布尔”分别属于哪一类错误，解释器的义务差在哪里。
- 画出一次调用的两份环境：调用点的环境用来做什么，closure 里的环境用来做什么。把自由变量的查找指到其中一份。
- 说明为什么函数名必须映射到整个 closure。只映射到函数 AST 时，下一次会用哪份环境重建 closure。
- 说明 `andalso` 作为 Racket 函数和作为语言 B 的新 struct，谁负责短路，谁会引入 hygiene 问题。
