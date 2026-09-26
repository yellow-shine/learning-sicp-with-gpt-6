# 08 — 拿掉类型系统之后，什么还在

> Part B · Section 5 前半
> 视频：`01`–`12`（延迟求值、流、宏在下一章）

Part A 结束时，你已经能不用赋值写出递归、闭包和抽象边界。若接下来只是把 `fun` 换成另一套关键字，这门课就变成了换语言练习。Racket 出现，是因为有一个轴还没被单独拧动：

> 若程序在运行前不再被类型系统拒绝，Part A 的那些机制还在不在？错用会在什么时候、以什么样子出现？

Grossman 的原话方向是：Racket 不那么依赖静态类型系统（static type system）。它接受更多程序，把 ML 里的类型错误推迟到某条表达式真正执行。语法极简，是为了让“程序是一棵没有歧义的树”这件事看得见，不是为了教 Lisp 口味。

这一章不教你如何把中缀改写成前缀。它回答三件事：

1. 类型检查器消失之后，绑定、调用、词法闭包、不可变 list 哪些原样留下。
2. “能 Run”为什么不等于“没有用错”。错误被推迟（delayed error），测试变成语义的一部分。
3. 括号为什么不是风格。在这门语言里，多一对括号就是多一次调用。

---

## 1. 这一组讲要解决什么问题？

继续只用 ML，有两类程序你写不出来，或者写出来也看不清原因。

第一类：一个 list 里同时放 number 和 list。ML 会在运行前拒绝，除非你先写 datatype 和 constructor，向类型检查器解释“这是一种 variant”。若问题只是“一棵任意嵌套的 list 和 number，把所有 number 加起来”，那些 constructor 不是算法需要的。它们是类型检查器需要的仪式。

第二类：你无法把“括号即树”和“动态类型”拆开看。中缀、优先级、关键字分支把语法规则撑大之后，程序文本和抽象语法树（abstract syntax tree）之间总有一层你必须记住的绑定规则。Racket 把这层几乎拿掉，是为了后面的宏和解释器：程序在语言内部就是树，不是字符串。

它依赖 Part A 的全部环境模型：binding 不是 assignment，函数是值，调用先求参数，闭包带走定义时的环境，不可变让 alias 不可观察。它准备的是：延迟求值（函数体在调用前不求值，零参数函数因此能推迟计算）、宏（程序员增加 special form）、以及 Section 7 才能公正进行的静态 vs 动态争论。现在先获得经验，不要先站队。

---

## Lecture — 换的是拒绝的时间，不是计算模型

视频：`Introduction to Racket`，`Racket Definitions, Functions, Conditionals`。

### 先遇到的困难

若每个运算符一种写法、`if` 又一套关键字、递归还要一个 `rec`，语法规则会爆炸，而且你会以为“这门语言不同”发生在这些记号上。Racket 把 `+`、`*`、`=` 都当成函数。调用永远是 `(e0 e1 ... en)`。递归不需要新构造：函数体可以直接调用正在定义的名字。

这不是因为前缀更时髦。统一的调用形式让“什么是表达式”只有一种递归定义。特殊的东西被显式标成 special form，而不是藏在中缀里。

### 核心概念

#### 还在的东西

**Definition.** `(define x e)` 先求值 `e`，再把结果绑到 `x`。这是 binding，不是 assignment。和 ML 的 `val x = e` 同一件事。

`(lambda (x) body)` 是匿名函数，对应 ML 的 `fn`。`(define (cube x) body)` 是糖，展开成 `(define cube (lambda (x) body))`。没有新语义。

`(if e1 e2 e3)` 是三个表达式，没有 `then` / `else`。只求值被选中的分支。这和 ML 的 `if` 一样。

调用三步也没变：先求 `e0` 得到过程（procedure），再求所有参数，再在定义时的环境加上参数求函数体。词法作用域（lexical scope）还在。闭包还在。

**Intuition.** 你在用另一套括号重做 Section 1，是为了确认：那些规则不靠类型检查器才成立。

**Why it exists.** 若动态类型语言连调用顺序都换掉，你就无法把“错误何时被发现”单独归因于类型系统。课程每次只拧一个轴。

**Problem solved.** 把语法差异和语义差异分开。`cube` 在 Racket 里仍是一个值。它的函数体在定义时不跑。

```racket
#lang racket
(provide (all-defined-out))

(define (cube x)
  (* x x x))

(define (pow1 x y) ; 只对非负 y 有定义，和 ML 的 pow 一样
  (if (= y 0)
      1
      (* x (pow1 x (- y 1)))))

(define pow2
  (lambda (x)
    (lambda (y)
      (pow1 x y))))
```

```text
Expression: ((pow2 4) 2)

1. 内层 (pow2 4)
   pow2 → 闭包 { code: (lambda (x) (lambda (y) (pow1 x y))) }
   参数 x → 4
   函数体不调用 pow1。它返回另一个闭包。

2. 那个闭包：
   code: (lambda (y) (pow1 x y))
   env:  x → 4

3. 外层用 2 调用它
   y → 2
   求值 (pow1 4 2) → 16
```

少一层括号，`(pow2 4 2)` 不是“更自然的多参数调用”。`pow2` 只接受一个参数。你得到的是“参数个数不对”，不是 `16`。括号在这里是调用次数，不是分组装饰。

`*` 可以接受任意个参数，返回乘积。Grossman 特意说：这不是在骗你，这不是 currying 的语法糖。Racket 的函数真的可以有 0、1、2、… 个参数。ML 的多参数要么是一个 tuple，要么是一串返回函数的闭包。两条设计都合法。不要把 Racket 的 `(f a b)` 读成 ML 的柯里化调用。Racket 没有那种调用糖。柯里化在这里仍只是闭包惯用法，而且不常见，因为多参数函数是真的。

REPL 成功时不打印类型。没有类型可印。未绑定的名字是 `reference to an unbound identifier`，不是类型错误。文件第一行必须是 `#lang racket`，因为 DrRacket 能跑多种语言，实现需要你声明用哪一种。`(provide (all-defined-out))` 是模块边界：每个文件默认全私有。这行是为了让测试文件看得见。它不是语言核心，作业会给你。

空 list 不是 Scheme 的 `()`。在 Racket 里它是 `null`。这是和 Scheme 不兼容的点之一。另一个更重要：Racket 的 list 元素不可变，像 ML，不像经典 Scheme。

#### 真正换掉的东西

**Definition.** 动态类型（dynamic typing），在这一讲的用法里，意味着：没有一套在运行前拒绝程序的类型规则。ML 会拒绝的很多程序，这里可以保存、可以 Run。错误推迟到那条表达式执行时。

**Intuition.** 检查器还在，只是它坐在求值规则里面，不坐在运行之前。`+` 仍期望数字。它只是等到被调用才检查。

**Why it exists.** 要讨论静态 vs 动态，必须先在没有类型系统的语言里写过程序。否则争论没有经验。优缺点的清单留到 Section 7。这里先建立习惯：绿的 Run 只说明“还没执行到那条坏表达式”。

**Problem solved.** 你被允许构造类型检查器无法在运行前分类的数据。代价是：错用不再有编译期的一行字，而有一次运行时的失败，且失败点可能在递归深处。

```racket
(define (sum xs)
  (if (null? xs)
      0
      (+ (car xs) (sum (cdr xs)))))

(sum (list 3 4 5 6))          ; 18
; (sum (list 3 "hi"))         ; 可以 Run。执行到 + 才说：
                              ; + expects a number, given "hi"
```

这和 ML 的 `hd []`、`div` 零是同一类事件的扩大版。ML 里，元素类型不对在运行前就死。Racket 里，元素类型不对变成和除零一样：要跑到那一次调用。Arity（参数个数）仍会在调用时检查。动态类型不是“什么都不检查”。它是“不在运行前用一套类型规则拒绝程序”。

### 若改掉规则

- 定义时就求值 `lambda` 的函数体：递归和“函数是值”再次同时崩溃。这条没变。
- 把 `((pow2 4) 2)` 的括号理解成可选分组：你会调用一个只接受一个参数的函数，并传两个参数。
- 若 Racket 在 Run 时做 ML 那种类型检查：异构 list 会被拒绝，这一章的后半就没有例子可写。

---

## Lecture — 括号是树，不是口味

视频：`Syntax and Parentheses`，`Parentheses Matter`。

### 先遇到的困难

在多数语言里，多余的括号只是分组。加错了顶多多余，少了才坏。`1` 和 `(1)` 通常是同一个值。若你带着这个习惯读 Racket，你会把括号当成噪音，然后在递归的基线处爆炸，而且爆炸发生在五次递归之后，报错指向“不是过程”。

中缀造成另一类困难。`x + y * z` 的意思依赖一堆你和语言都必须记住的优先级。少了括号，从文本到树的解析就不平凡，同一个字符串可以对应两棵树。XML 用成对的尖括号消灭这种歧义。Lisp 从 1958 年就用圆括号做同一件事。HTML 更啰嗦，没有人因此否定 HTML。不喜欢括号可以。因为不喜欢括号而否定这门语言在说什么，Grossman 认为那是差的计算机科学家：syntax preference 不是 semantics。

### 核心概念

#### 几乎只有一条语法

**Definition.** 忽略本课不碰的角落，Racket 的语法是一条递归定义。

- atom：不可再分。数字、字符串、`#t`、`#f`、名字。
- 少数 atom 是 special form：`define`、`lambda`、`if`，以及以后你用宏自己加的那些。
- sequence：括号里的一串 term。term 可以是 atom，也可以是另一个 sequence。

语义跟着语法走，不再另记一套优先级：

- 若第一个 term 是 special form，按那个 form 的规则解释其余部分。`(lambda (x) body)` 不是函数调用。`(x)` 是参数列表，不是“调用 x”。
- 否则，这是函数调用。`(e0 e1 ... en)` 求值 `e0`，再求参数，再调用。

`()` 和 `[]` 完全同义，只是书写习惯。DrRacket 会在你敲错匹配的括号时帮你改成对方。这是工具。语义相同。

```racket
(define cube
  (lambda (x)
    (* x x x)))
```

```text
define
├── cube
└── lambda
    ├── (x)
    └── *
        ├── x
        ├── x
        └── x
```

没有“`*` 比 `+` 紧”。树就是你写下来的树。`(+ 3 (car xs))` 是三个 term：`+`、`3`、`(car xs)`。`+` 不是 special form，所以这是调用。

**Why it exists.** 后面要把程序当作数据来改写（宏），并在解释器里递归求值一棵树。若文本和树之间还有一层优先级，那两件事都会先变成解析课。

**Problem solved.** 程序员和实现者对“这段文本是哪棵树”没有歧义。代价是：每个调用都要自己的括号，看起来比中缀密。

#### 多一对括号就是一次调用

**Definition.** `(1)` 不是数字 `1`。它是：求值 `1`，得到数字，然后用零个参数调用它。数字不是过程，所以这是运行时错误：`application: not a procedure; given: 1`。

**Intuition.** 在这门语言里，括号是构造调用节点的语法，不是强调。

**Why it exists.** 因为调用和分组用了同一种括号。这是极简语法的账单，不是粗心。你必须付，才能换来“没有优先级表”。

**Problem solved.** 一旦你把括号读成树节点，调试就从“哪一行手感不对”变成“这棵树比我想的多了一个调用节点，或少了一个”。

```racket
(define (fact n)
  (if (= n 0)
      1
      (* n (fact (- n 1)))))
; (fact 5) → 120
```

下面每一个都是树错了，不是“风格不好”。

| 写法 | 树实际是什么 | 何时失败 |
| --- | --- | --- |
| 基线写成 `(1)` | 用零个参数调用数字 `1` | 递归走到 `n = 0` 才炸。从 5 开始，已经做了大约五次递归 |
| `(if = n 0 1 ...)` | `if` 后面有五个 term | 语法错误。`=` 没有被调用，它只是一个 term |
| `(define fact3 (n) ...)` | `define` 在名字后面看见了多个表达式 | 语法错误：bad syntax |
| `(* n fact4 (- n 1))` | `*` 的第二个参数是过程 `fact4` 本身 | `(fact4 0)` 仍返回 `1`，因为走不到这一支。`(fact4 5)` 才在 `*` 处失败 |
| `(n * (fact6 ...))` | 把 `n` 当过程调用，`*` 是它的参数 | 参数先求值，递归先跑完。回来时 `n` 是 `1`，错误是 `expected a procedure, given: 1`。和 `(1)` 是同一种错 |

```text
fact1，基线是 (1)，从 5 调用：

Expression: (fact1 5)
  测试 (= 5 0) 为假
  求 (* 5 (fact1 4))
    … 同样下到 (fact1 0)
      测试为真
      求值 (1) → 把 1 当过程调用
Value: 没有。application: not a procedure
```

没有静态类型，这个错不会在你保存文件时出现。`(fact1 0)` 一定炸。`(fact1 5)` 也炸，但栈已经深了五层。DrRacket 会指向出错的代码。它仍是运行时失败，不是类型检查。

还有一个更阴的版本：基线错写成 `(1)`，但递归调用的是正确的 `fact` 而不是 `fact1`。`(fact1 5)` 可以返回 `120`，因为它跳进了写对的函数。`(fact1 0)` 失败。测试没覆盖基线，动态类型语言就会把这个函数当成好的。ML 也会放过一些逻辑错，但“把数字当函数调用”这种形状，ML 的类型规则通常在运行前就拒绝。这就是推迟的意思：不是错消失了，是错搬家了。

### 若改掉规则

- 若 `(1)` 只是分组，等于 `1`：上面一半“调试练习”都不会失败，括号也就不能无歧义地表示调用。
- 若 `*` 按中缀解析：`(* n fact4 (- n 1))` 这种“少一对括号”会变成另一种树，你失去“我写下的括号就是树”这条不变量。
- 若在 Run 之前做静态检查：`(1)` 会在任何调用之前被拒绝。那更安全，也更不灵活。这是权衡，不是 Racket 写错了。

---

## Lecture — 动态类型允许的结构，以及它不替你守的约

视频：`Dynamic Typing`，`cond`。

### 先遇到的困难

ML 里，`int list` 的元素不能是 `int list`。要表达“number 或 list”，你写 datatype，每个值套上 constructor，`case` 时再拆开。类型检查器因此知道每一支的类型。若你的问题只是把一棵嵌套结构里的所有 number 加起来，constructor 不参与算法。它们在向检查器报到。

没有检查器时，可以直接 `cons`。代价立刻出现：函数必须自己说它假设什么。假设破了，失败发生在 `car` 一个字符串的那一刻，而不是在定义这个函数的那一刻。

### 核心概念

#### 异构结构不是新的数据结构

**Definition.** 动态类型下，一个 list 的元素可以是 number、list、`#f`、字符串，或任何别的值。没有类型声明。结构就是你 `cons` 出来的东西。

**Intuition.** ML 的 datatype 把 tag 写进值。Racket 把 tag 留在运行时的值本身里：这个值是不是 number，问 `number?`。谓词是动态类型语言的类型测试。静态语言不需要它们，因为类型规则已经知道。

**Why it exists.** 有些数据的形状是“任意嵌套的混合”，为它发明一个闭世界的 datatype 很笨，尤其当嵌套深度和混合方式不是程序要维护的不变量，只是输入碰巧长这样。

**Problem solved.** `sum` 可以递归进子 list，而不先把每个 number 包进 `Constant`、每个子树包进 `Nested`。你少写的是仪式，不是算法。

```racket
(define (sum1 xs)
  (if (null? xs)
      0
      (if (number? (car xs))
          (+ (car xs) (sum1 (cdr xs)))
          (+ (sum1 (car xs)) (sum1 (cdr xs))))))
; 假设：不是 number 的元素就是 list
```

```text
Expression: (sum1 (list (list 4) 5))
Environment: sum1 → 上述过程

car 是 list，不是 number
  → (+ (sum1 (list 4)) (sum1 (list 5)))
  → (+ 4 5)
Value: 9
```

嵌套一个字符串：最终会对 `"hi"` 做 `car`。运行时错误。函数没有在类型里承诺“元素是 number 或 list”。承诺在注释和测试里。注释不会被执行。

宽容的版本把“不是 number 也不是 list”跳过：

```racket
(define (sum2 xs)
  (if (null? xs)
      0
      (if (number? (car xs))
          (+ (car xs) (sum2 (cdr xs)))
          (if (list? (car xs))
              (+ (sum2 (car xs)) (sum2 (cdr xs)))
              (sum2 (cdr xs))))))
```

这是风格，不是类型系统替你做的选择。`sum1` 把违约当成错误，逼调用者守约。`sum2` 跳过坏元素。两者都是动态类型下的合法函数。ML 里你往往必须先选定 datatype，检查器才让你写下去。

`sum2` 的宽容只覆盖“list 里面的坏元素”。`(sum2 "hi")` 仍然错：它在知道自己拿到的是 list 之前就做了 `car`。对任何非 list 返回 `0` 的第三版，他留作练习。动态类型不自动让函数对所有输入都有定义。它只是不在运行前替你写那个定义。

他明确说：没有类型错误信息并不更省事。类型错误常常比没有好。缺检查器会让人沮丧。测试更重要。这不是在为动态类型辩护，也不是在攻击它。这是使用它的账单。

#### `cond` 与“非 `#f` 即真”

嵌套 `if` 的 else 又是 `if`，三路测试不在一条线上。`cond` 是 special form，可以看成嵌套 `if` 的糖，也可以反过来把 `if` 看成只有两支的 `cond`。两种看法都可以。它不是新的计算模型。

```racket
(define (sum3 xs)
  (cond [(null? xs) 0]
        [(number? (car xs)) (+ (car xs) (sum3 (cdr xs)))]
        [#t (+ (sum3 (car xs)) (sum3 (cdr xs)))]))
```

从左到右，第一个测试为真的分支求值，后面的不求值。和 `if` 一样，落选分支不跑。

最后一枝的测试应是 `#t`。否则若全部为假，`cond` 不报错，返回一个 void 对象。后面的代码会困惑。它不像 ML 的 `case` 那样给出非穷尽警告。没有静态穷尽性，是因为没有静态类型。

更动态的一点：测试位置不要求布尔。除了 `#f`，一切都算真。`34` 是真。`null` 是真。非空 list 是真。唯一的假是 `#f`。Racket 不把空 list 或空字符串当假。有的动态语言会。那是另一项设计，不是“动态类型”的同义词。

```racket
(if 34 14 15)    ; 14
(if null 14 15)  ; 14
(if #f 14 15)    ; 15

(define (count-falses xs)
  (cond [(null? xs) 0]
        [(car xs) (count-falses (cdr xs))]   ; 不是 #f，就当“不是 false”
        [#t (+ 1 (count-falses (cdr xs)))]))
```

```text
(count-falses (list #f 34))
  car 是 #f，第一支测试失败
  走 #t 支：1 + (count-falses (list 34))
    car 是 34，不是 #f，测试为真
    不计 1，继续空表 → 0
Value: 1
```

静态类型语言里，“让任何值当条件”没有意义：每个值恰好一个类型，测试的类型必须是 `bool`。动态类型把所有值放进同一个运行时世界，于是“哪些值算真”变成一条必须写明的语义，而不是类型规则的推论。

他不是这条约定的粉丝。不用它也能写 Racket。它被留在课里，是为了让你看见动态类型多出来的一种自由，以及这种自由为什么会让同一段 `if` 在两种语言里不能逐字翻译。

### 对照：错误何时发生

| | ML 的静态类型 | Racket 的动态类型 |
| --- | --- | --- |
| 定义 | 运行前按类型规则拒绝一批程序 | 运行到某条表达式时，由那个操作检查自己的参数 |
| 解决的问题 | 没跑到的路径上的一类误用也不会溜进生产 | 不必先向检查器解释数据的 variant，就能写程序 |
| 关键区别 | 拒绝发生在任何求值之前。被接受的程序仍可能除零、`hd []` | 被接受几乎是默认。误用要测试执行到那一行才出现 |
| 典型场景 | `int list` 里放一个 `string`，编译失败 | `(sum (list 3 "hi"))` 可以 Run，死在 `+` |

| | `sum1` 的严格假设 | `sum2` 的跳过 |
| --- | --- | --- |
| 定义 | 不是 number 就当 list 递归进去 | 不是 number 也不是 list 就丢掉 |
| 解决的问题 | 违约立刻失败，调用者必须守约 | 脏数据里仍能加出 number |
| 关键区别 | 错用变成 `car` 字符串 | 错用变成静默忽略。参数本身不是 list 时仍然炸 |
| 典型场景 | 你控制输入的形状 | 输入里夹着你不关心的值 |

### 若改掉规则

- 在 ML 里做 `sum1` 而不写 datatype：程序不被接受。那不是算法需要 constructor，是检查器需要。
- `cond` 不写 `#t` 默认枝，且所有测试都假：得到 void，不报错。
- 把 `null` 当假：`(if null 14 15)` 会得到 `15`。在 Racket 里它得到 `14`。翻译 Python 或 JavaScript 的“空为假”会翻错。

---

## Lecture — 局部绑定的环境，是一项设计，不是惯例

视频：`Local Bindings`，`Top-level Bindings`。

### 先遇到的困难

同一递归结果要用两次时，不局部绑定就会重复计算。这在 ML 的 `bad_max` 里已经见过，是指数爆炸，不是“递归慢”。Racket 的 `max-list` 用同一种 `let` 记住尾部的最大值。

新的困难是：右边的表达式在哪个环境里求值？ML 只给了你一种顺序的 `let`，你可能以为那是唯一合理的定义。它不是。三种定义都说得通，各自方便一种情况。Racket 把三种都做成语法，就是为了让作用域规则变成可见的选择。

### 核心概念

#### 三种 `let`，一种局部 `define`

**Definition.**

```racket
(let ([x1 e1] [x2 e2] ...) body)
```

即使只有一个绑定，也要那一层额外括号。`[]` 只是习惯，`()` 同义。

| 构造 | 右边在哪个环境求值 | 像什么 |
| --- | --- | --- |
| `let` | 整个 `let` 之前的环境。互相看不见 | 同时绑定。可以交换 |
| `let*` | 只看见前面的绑定 | ML 的 `let` |
| `letrec` | 环境里有全部名字，但初始化仍按顺序 | 互递归。ML 的 `and` 那一类 |
| 函数体里的 `define` | 与 `letrec` 相同 | 另一种写法，不是第四种语义 |

**Intuition.** “局部变量”不是一个概念。它是“新绑定”加上“右边何时能看见这些新绑定”。第二句有三种答案。

**Why it exists.** 交换两个名字需要同时绑定。顺序依赖需要 `let*`。两个函数互相调用需要 `letrec`，因为每个 `lambda` 的函数体在定义时不求值，所以可以提到还没初始化完的另一个名字。若语言只给一种，另外两种就要用嵌套或技巧模拟，规则反而更难讲。

**Problem solved.** 你能指出一个局部绑定的右边到底看见了谁。这是词法作用域的精细版，不是新的求值模型。

```racket
(define (silly-double x)
  (let ([x (+ x 3)]
        [y (+ x 2)])
    (+ x y -5)))
; 两个右边都看见参数，不看见彼此
; y = param+2，新 x = param+3，结果 = 2*param

(define (silly-double* x)
  (let* ([x (+ x 3)]
         [y (+ x 2)])
    (+ x y -8)))
; y 看见新的 x。y = param+5。结果仍是 2*param
```

```text
silly-double，参数 x → 10，用 let：

let 之前的环境：x → 10
  (+ x 3) → 13
  (+ x 2) → 12     ; 不是 15。看不见新 x
body 的环境：x → 13, y → 12
Value: 20
```

```text
同一个 10，用 let*：

x 先变成 13
y 在这个新环境里求 (+ x 2) → 15
body：13 + 15 - 8 = 20
```

结果碰巧一样，环境不一样。若 body 返回 `y`，两种 `let` 会分叉。不要用结果碰巧相同来推断规则。

交换是 `let` 而不是 `let*` 的理由：

```racket
(let ([x y]
      [y x])
  body)
```

两个右边都看见外层的 `x` 和 `y`，所以真的互换。若按 ML 的顺序语义，第二个绑定的 `x` 已经是外层的 `y`，两个都会变成外层的 `y`。ML 的 `let` 是 Racket 的 `let*`，不是 Racket 的 `let`。这是本讲最容易记反的一句。

`letrec` 的环境里有后面的名字，不表示那个名字已经求值完。

```racket
(define (silly-triple x)
  (letrec ([y (+ x 2)]
           [f (lambda (z) (+ z y w x))]
           [w (+ x 7)])
    (f -9)))
; (f -9) 时 w 已经初始化。z=-9, y=x+2, w=x+7 → 3x
```

`f` 的函数体在 `lambda` 被求值时不跑，所以那时 `w` 还没有值也没关系。等 `(f -9)` 真的调用，`w` 已经绑定完。若写成 `(letrec ([y (+ w 2)] [w (+ x 7)]) ...)`，`y` 的初始化表达式立刻去读 `w`。`w` 在环境里，但还没求值。你得到 undefined，然后 `+` 报错。

所以 `letrec` 适合互递归函数，不适合“后面那个普通值我先用一下”。局部 `define` 就是 `letrec` 的语法，不是更安全的另一种语义：

```racket
(define (silly-mod2 x)
  (define (even? n) (if (= n 0) #t (odd? (- n 1))))
  (define (odd? n)  (if (= n 0) #f (even? (- n 1))))
  (if (even? x) 0 1))
```

两个函数体互相提到对方。安全，因为提到的地方在函数体里，而函数体要到调用才求值。这和 Part A 里“函数绑定不求值函数体”是同一条规则。名字换了，规则没换。

不用 shadow 时，三种 `let` 结果相同。风格上用 `let`。作业允许 `let` / `let*` / 局部 `define`。

#### 文件顶层是一个 `letrec`，不是 ML 的顺序绑定

只讲局部 `let` 会漏掉文件。若顶层只能看前面，互递归函数就要特殊语法。Racket 让一个文件像一个 `letrec`：可以引用更晚的绑定，初始化仍按顺序。

```racket
(define (f x) (+ x b)) ; 函数体现在不跑，b 可以在下面
(define b 3)
(define c (+ b 4))     ; 7。这是初始化表达式，只能看已经求值完的 b
; (define d (+ e 4))   ; 若打开：reference before definition
(define e 5)
; (define f 17)        ; duplicate definition。文件内不能 shadow
```

```text
求值 (define (f x) (+ x b))：
  造一个闭包，不查找 b
然后 b → 3
然后 (+ b 4) 查找 b，得到 3，c → 7
以后调用 f，才查找 b
```

过早引用在顶层是错误，不是函数内部那种 undefined 值。他说这个细节不必深究。要记住的是方向：初始化表达式里不要用还没定义的名字；函数体里可以，只要调用发生在那个名字求值完成之后。

同一文件不能 shadow。两个同名 `define` 要进同一个环境，不是一层套一层，所以是 `duplicate definition`。这和 `let` 里 shadow 参数不同。`let` 是新的一层。文件是一个大的 `letrec`。

他随后纠正自己的用词：这不是真正的 top-level。每个文件隐式是一个 module。Module 内部是 `letrec`。跨文件不是一个大 `letrec`。你可以 shadow 另一个 module 的名字，甚至 shadow `+`。那种 shadow 是差风格。`+` 只是标准库 module 里的函数。

REPL 既不是 `letrec` 也不是 `let*`，而且并不总是做你以为的事。危险情况是在 REPL 里 shadow 标准库的名字，再定义递归函数。他不展开细节，只说会 very wrong。解决办法：不要在 REPL 里定义自己的递归函数。写进文件再 Run。调用文件里已经定义好的递归函数没问题。

### 若改掉规则

- `max-list` 对 `cdr` 递归两次：又是指数爆炸。递归不是 bug，重复计算才是。这条从 ML 原样搬过来。
- 用 `let` 写“`y` 依赖新的 `x`”：`y` 看见的是外层 `x`。
- 文件内第二次 `define` 同一个名字：直接错误，不是 shadowing。
- 在初始化表达式里引用更下面的变量：Run 就失败，不是调用时才失败。

---

## Lecture — `set!` 不破坏词法作用域，它改变格子里的内容

视频：`Mutation with set!`。

### 先遇到的困难

后面的 promise 和 memoization 需要更新某个已经存在的绑定。语言因此有 assignment。若你以为“我们在函数式语言里，闭包捕获的 `b` 永远是定义时的 `3`”，这个假设在 `set!` 之后是错的。词法上仍是同一个 `b`。变的是那个 `b` 的当前内容。

这不是动态作用域。动态作用域会换一个变量来查找。这里查找的变量没换，格子被写了。

### 核心概念

**Definition.** `(set! x e)` 读作 set-bang。`x` 必须已经在环境里。求值 `e`，然后修改 `x` 当前绑定的那个位置。之后任何查找这个 `x` 的地方看到新值。已经查找过、把结果放进别的变量的，看不到。

**Intuition.** `define` 往环境里加一行。`set!` 改某一行的内容。闭包记住的是哪一行，不是那一行当时的快照，除非你自己抄一份。

**Why it exists.** 有些模型就是共享状态：所有能访问这块状态的人都应看到更新。回调库、记忆化表，是这种模型。若因此把所有绑定都变成可变的，你就在不需要变化的地方也担心变化。

**Problem solved.** 需要更新时有 assignment。不需要时，仍用 `define` 和不可变 cons。作业不要 `set!` 顶层变量。假设没人会这么做。

```racket
(define b 3)
(define f (lambda (x) (* 1 (+ x b))))
(define c (+ b 4)) ; 7
(set! b 5)
(define z (f 4))   ; 9
(define w c)       ; 7
```

```text
b 的格子：  [ 3 ]

f → 闭包
    code: (* 1 (+ x b))
    env:  指向包含这个 b 的环境，不是把 3 抄进闭包

c → 7          ; 数字 7，不是“以后再算 b+4”的公式

set! b 5
b 的格子：  [ 5 ]
f 仍指向同一格

(f 4) 查找 b，看见 5，结果 9
w 查找 c，看见 7。b 后来怎么变，与 c 无关
```

ML 里同一个 `f` 永远加 `3`，因为没有任何操作能改 `b`。Racket 里它可以加 `3`，也可以在某次 `set!` 之后加 `5`。同一闭包，两次调用，结果不同。这是 mutation 的定义，不是作用域规则变了。

若 `f` 必须永远使用定义时的 `b`，就在 `set!` 发生之前抄一份。抄到一个外界碰不到的绑定上：

```racket
(define f
  (let ([b b])
    (lambda (x) (* 1 (+ x b)))))
```

内层 `b` shadow 外层 `b`。闭包捕获的是内层那一格。外界 `set!` 外层 `b`，改不到它。内层名字不必也叫 `b`。原则：担心某物会变，就在它变之前拷一份。

若 `+` 和 `*` 也可能被 `set!`，语义上还得拷它们。没人这样写。在 Scheme 里 `set!` `+` 会让所有假设它仍是加法的代码坏掉。Racket 的妥协：定义某个变量的那个文件若自己没有 `set!` 它，别人也不能 `set!` 它。`+` 的定义文件没有 `set!`，所以没人能改 `+`。这是语言在帮你守“别对大量代码依赖的顶层赋值”。他的教训更强：任何语言都不要这么做。不 mutate，语义更简单。语言是否该允许顶层 mutation，本身可疑。

`(begin e1 ... en)` 按顺序求值，结果是最后一个。前面的表达式只为副作用才有意义。这一讲先给出来，还不用。

| | Binding（`define` / `let`） | Assignment（`set!`） |
| --- | --- | --- |
| 定义 | 新环境里的新映射，或一层新绑定 | 改已有格子的内容 |
| 解决的问题 | 引入名字，而不追溯修改已完成的计算 | 让所有还能查到这一格的闭包看见更新 |
| 关键区别 | `c` 存的是已经求出的 `7` | `f` 下次查找 `b` 看见新内容 |
| 典型场景 | 参数、局部名字、文件级定义 | memo 表、promise 的“已经算过”标志。顶层的 `b` 不是好场景 |

### 若改掉规则

- 没有 `set!`：`f` 永远加 `3`，`z` 也是 `7`。语义更简单。Part A 就是这个世界。
- 在 `set!` 之前调用 `f`：看见 `3`。之后：看见 `5`。
- 允许 `set!` `+`：所有没拷贝 `+` 的闭包行为改变。Racket 禁止这种 `set!`。这是概念上的语言设计选择，不是“Racket 没有赋值”。

---

## Lecture — `cons` 做的是 pair。List 是约定

视频：`The Truth about cons`，`mcons`。

### 先遇到的困难

动态语言没有类型检查器把 list 和 pair 分成两种类型。再提供两套构造器（ML 的逗号和 `::`）是多余的。于是 `cons` 只做一件事：做一个 pair，也叫 cons cell。List 是一种约定：一串 cons，每个 cdr 仍是 cons，直到 `null`。

若你仍把 `cons` 理解成“list 专用的 `::`”，点号打印会看起来像噪音，`length` 对一个明明全是 cons 的值报错会看起来像 bug。两者都不是。

另一层困难：不可变让 alias 无关紧要。这是 Racket 相对 Scheme/Lisp 最大的改动，也是它从 ML 搬来的好处。但 promise 真的要改 pair 的字段。`set!` 改的是变量指哪，不改 cell 里面。需要另一种 cell。若因此把所有 cons 都变成可变的，Section 1 的推理就丢了，`list?` 也不能在创建时缓存“这是不是 proper list”。

### 核心概念

#### Proper list 是以 `null` 结束的 pair 链

**Definition.** `(cons a d)` 做一个 pair。`car` 取第一分量，`cdr` 取第二分量。对 pair 和 list 是同一套，因为 list 就是 pair。

Proper list：`null`，或者 car 是元素、cdr 是 proper list。不以 `null` 结尾的 cons 结构是 improper list。REPL 用点号表示：`'(1 #t . "hi")`。点号不是打印噪声。它说“这不是 proper list”。

**Intuition.** ML 用类型把“两个东西”和“一列东西”分开，所以需要两种语法。Racket 用约定分开，所以一种构造器就够。程序员自己跟踪哪些是 proper list。`list?` 和 `length` 在运行时执行这个约定。

**Why it exists.** 动态类型下，pair 和 list 的区别不是类型检查器能看见的静态事实。硬做两套构造器，不会换来 ML 那种编译期分离，只会多一套名字。

**Problem solved.** 两个或三个临时的值，用嵌套 cons 即可。Racket 没有内置 triple。未知长度的集合用 proper list。更好的风格是下一节的 struct：自定义 each-of，而不是靠记住 cons 的哪一层放什么。嵌套 cons 能工作，不代表它是大型程序的边界。

```racket
(define pr (cons 1 (cons #t "hi")))
; '(1 #t . "hi")
; list? → #f    pair? → #t
; (length pr) 报错：不是 proper list

(define lst (cons 1 (cons #t (cons "hi" null))))
; proper list，因为链以 null 结束
; list? → #t    pair? → #t
; null 自己：list? 为真，pair? 为假

(cdr (cdr pr))         ; "hi"
(cdr (cdr lst))        ; '("hi")  仍是 list，不是字符串
(car (cdr (cdr lst)))  ; "hi"
(caddr lst)            ; 同一个 "hi"。caddr 只是 car/cdr 的组合函数
```

```text
pr:
  cons
  ├── 1
  └── cons
      ├── #t
      └── "hi"          ; 第二层 cdr 不是 pair，也不是 null

lst:
  cons
  ├── 1
  └── cons
      ├── #t
      └── cons
          ├── "hi"
          └── null      ; 约定完成，这才是 list
```

`(cdr (cdr lst))` 是一个元素的 list。差一个 `car` 才是字符串。这个错在 ML 里常常是类型错误：`tl (tl lst)` 的类型仍是 list。在 Racket 里它是一个值，你要到下一张 `car` 或下一张 `+` 才发现自己拿错了层。又是推迟。

#### 不可变 cell 与可变 cell 是两种类型，在运行时分开

**Definition.** Racket 不能修改 cons cell 的 car 或 cdr。没有 Scheme 的 `set-car!`。这是优点。

`set!` 只作用于 identifier。它不查找一个 cell 然后改字段。

```racket
(define x (cons 14 null))
(define y x)               ; y 与 x 指向同一格
(set! x (cons 42 null))    ; x 改指向新格。旧格不动
; x 是 '(42)
; y 是 '(14)
```

```text
一开始：
  x ──┐
  y ──┴─→ cell A: cons(14, null)

set! x 之后：
  x ──→ cell B: cons(42, null)
  y ──→ cell A: cons(14, null)
```

没有别名能观察到“格子内容变了”，因为格子内容没变。变的是 `x` 这个名字指向哪。这就是 Section 1 的 alias 故事在动态语言里仍然成立的原因。共享与拷贝，对 cons 来说客户仍不可区分，只要没人能改 cell。

额外的实现好处：创建 cons 的那一刻就知道它是不是 proper list，而且永远不会变。`list?` 不必每次走到链尾。可变 cell 做不到这件事。

需要改字段时，用另一套：

```racket
(define mpr (mcons 1 (mcons #t "hi")))
(mcar mpr)                 ; 1
(set-mcdr! mpr 47)         ; 这一格的 cdr 变成 47
(set-mcar! (mcdr mpr) 14)  ; 在重新接回内层 mcons 之后，内层的 car 变成 14
```

`mcar` / `mcdr` 不能换成 `car` / `cdr`。`set-mcar!` 不能用于普通 cons。`length` 只接受 proper list，即使 `(mcons 1 null)` 看起来像以空结束。两套函数故意不通用。运行时的“类型错误”在这里就是：你把 mpair 交给了只接受 pair 的操作。

任何别的变量若指向被 `set-mcar!` 的那一格，都会看见新内容。Aliasing 重新变得可观察。所以：不要可变性时用 `cons`。需要“几块内容而且内容会变”时用 `mcons`。不要用 `set!` 假装自己改了 list 节点。那只是造了一个新结构，旧别名仍看旧结构。

| | `cons` | `mcons` |
| --- | --- | --- |
| 定义 | 不可变 pair。list 是它的一种约定 | 可变 pair。不是 list |
| 解决的问题 | 共享尾巴而不必分析 alias | 一块会被更新的、有两个字段的状态 |
| 关键区别 | `set!` 只改名字的指向，cell 不动 | `set-mcar!` / `set-mcdr!` 改 cell，所有别名看见 |
| 典型场景 | `sum`、`my-append`、`my-map` | 以后的 promise：“算过了吗，结果是什么” |

| | ML 的 pair / list | Racket 的 `cons` |
| --- | --- | --- |
| 定义 | 两种构造，两种类型 | 一种构造，list 是约定 |
| 解决的问题 | 检查器在运行前区分 `#1` 和 `hd` | 不必为了检查器维护两套构造器 |
| 关键区别 | 拿错是类型错误 | 拿错是 `list?` 为假，或 `length` 运行时失败，或你多取了一层 `cdr` |
| 典型场景 | `int * int` 与 `int list` 不能混 | `'(1 #t . "hi")` 与 `'(1 #t "hi")` 都是 cons，只有后者是 proper list |

### 若改掉规则

- 若 cons 可以 `set-car!`：`y` 与 `x` 的别名会互相看见更新。Section 1 的局部推理失败。`list?` 也不能在创建时缓存。
- 用 `car` 对 mcons，或 `length` 对 mcons：运行时错误。分离是故意的。
- 在 ML 里用同一个构造器做 pair 和 list：类型检查器不会允许，所以 ML 用逗号和 `::`。那是静态类型的账单，不是 tuple 比 pair 更本质。

---

## 用透镜看一次 Racket 调用

| 透镜 | `(e0 e1 ... en)`，且 `e0` 不是 special form |
| --- | --- |
| Syntax | 一对括号，第一个 term 是被调用者。多一对括号就是多一次调用 |
| Semantics | 与 ML 相同的三步。没有类型规则坐在运行前 |
| Binding | `define` 加绑定。`set!` 不参与调用本身 |
| Scope | 函数体的自由变量按定义时的环境查找。`set!` 不改变找哪一格，只改变格子内容 |
| Evaluation | 参数 eager。`if` / `cond` 的落选分支不求值。`lambda` 的函数体不求值 |
| Type | 没有静态类型。操作在运行时检查自己的参数：`+` 要数字，`car` 要 pair，调用要过程，参数个数要匹配 |
| Lifetime | 闭包把环境带走，和 ML 一样。顶层 `set!` 让这个环境里的格子在闭包活着时仍可变 |
| Mutation | 默认没有。`set!` 改变量。`set-mcar!` 改 mcons 字段。cons 字段改不了 |
| Abstraction | 没有 signature 替你隐藏表示。约定、谓词和文档承担一部分。模块的 `provide` 是另一条边界，这一章只用了“全部公开” |
| Composition | 调用是表达式。`my-map` 接收函数，和 ML 的 `map` 是同一个抽象 |

---

## Connection to Modern Languages

这些是概念类比，不是等价。

- Python、JavaScript、Ruby 也把许多 ML 会拒绝的程序推迟到运行时。它们同样有谓词或异常，而不是“没有类型”。Racket 的特殊点是：语法几乎就是树，而且 list 默认不可变。Python 的 list 可变，所以别名问题从第一天就在。不要把“动态类型”听成“和 Python 一样可变”。
- JavaScript 的 truthiness 比 Racket 宽：`0`、`""`、`null`、`undefined` 都算假。Racket 只有 `#f`。从 JS 译条件到 Racket，空 list 不会走进 else。
- Scheme 的 `set-car!` 是 Racket 故意删掉的操作。若你在别的 Lisp 里见过“改 list 节点”，那是 mcons 的世界，不是 Racket 的 `cons`。
- Rust / ML 的 `enum` 对应这里“你本来要写的 datatype”。Racket 不是不能表达 variant。它是不强迫你在运行前表达。Section 6 会用 struct 把 tag 加回来，那时 tag 是为了你自己的程序，不是为了取悦检查器。
- `let` 与 `let*` 的差别，接近“同时解构”与“顺序 `let`”。JavaScript 的 `let` 更像顺序绑定加暂时性死区，不是 Racket 的 `let`。名字相同不是语义相同。ML 的 `let` 对应的是 `let*`。

---

## Section 5 前半 Review

拿掉静态类型之后，Part A 的计算模型还在：绑定、eager 调用、词法闭包、只求一个分支、不可变 pair。变的是拒绝的时间。ML 的类型错误变成“执行到那条表达式才失败”。括号不是风格，每一对括号都是树上的一个节点，多一对就是一次调用。`cons` 不做 list，它做 pair；list 是以 `null` 结束的约定。`set!` 不把词法作用域改成动态作用域，它让被闭包记住的那一格以后还能被写。可变字段放在另一套 `mcons` 上，这样不可变 list 的 alias 推理不用投降。

### 核心概念

dynamic typing、delayed error、special form、procedure、`lambda`、`null` / `null?`、`car` / `cdr`、truthiness、`cond`、`let` / `let*` / `letrec`、module-as-file、`set!`、proper list、improper list、`mcons`。

### 必须掌握的不变量

```text
能 Run ≠ 这条表达式执行时不会失败。
(1) 是调用，不是分组。
lambda 的函数体在调用前不求值。这条没变。
Racket 的 let 不是 ML 的 let。ML 的 let 是 let*。
文件内的 define 像 letrec，不能 shadow。
闭包查找的是那个变量。set! 改变的是变量的当前内容。
cons 的字段不能改。set! 只改变量指向哪。
proper list 以 null 结束。点号表示约定没完成。
除了 #f，一切都算真。null 算真。
```

### 能力检查

真正理解这一段，应该能：

- 指出一个 ML 类型错误搬到 Racket 之后，会在哪一次调用、由哪个操作报出。
- 把一段括号改写成树，并说明多一对或少一对会让哪个 term 变成调用或变成非过程。
- 对同一个 `let` 表面语法，说出 `let`、`let*`、`letrec` 三种右边各看见谁。
- 画出 `set!` 之后闭包仍指向哪一格，以及为什么 `c` 不跟着变。
- 区分“两个名字指向同一 cons cell”和“`set-mcar!` 改了 cell”。说明为什么前者在 `set!` 之后互不可见，后者的别名互相可见。
- 解释为什么异构嵌套 list 在 ML 里需要 datatype，以及那些 constructor 是在为谁服务。

概念题和代码题见 `exercises/section-05-racket.md`。
