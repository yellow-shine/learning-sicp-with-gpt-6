# Section 5.4 Macros：语法在求值之前被重写

标注见 `00-course-map.md`。本章覆盖 Section 5 的 19–23 讲。19 是后续章节要用的最低限度；20–23 是可选的，但 hygiene 和“展开几次”是理解 Racket macro 为什么不同于 C 预处理器的关键。Homework 4 不要求这些，除非做挑战题。Section 6 会把“Racket 函数生成对象语言语法”称为另一种 macro，那是下一章的事，不要和这里的 `define-syntax` 混成同一个机制。

本章末尾是整个 Section 5 的总总结。

---

## 函数改值，macro 改语法

```text
函数调用                         macro 展开
  输入：已经求值的值               输入：还没求值的语法
  输出：值                         输出：另一段语法
  发生在：求值时                   发生在：类型检查之前、求值之前
  进函数体时，参数表达式已不在     展开结果再被当成程序的一部分
```

**【课程】** 定义一个 macro，就是描述如何把一种新语法变换成源语言里已有的语法。讲师愿意把它想成：程序员自己添加语法糖，从而扩展语言的语法，而不改语言的实现。例如可以做出 ML 的 `andalso` 那种关键字，展开成已经会求值的条件表达式。

Macro system 是用来写这些变换的语言。有人定义 macro，就像有人定义函数，然后别人使用它。使用处被 **expand**：按定义里的规则，把使用处的语法换成脱糖后的语法。

关键的时间点：

> 展开发生在这门课讲过的其他所有事情之前。

程序员写下的程序，先把所有 macro 使用展开完，然后才类型检查（若语言有静态类型），才求值。函数体里要展开，条件分支里也要展开，包括永远不会被执行的分支。它是一个预遍（pre-pass），不是运行时的函数。

在 Racket 里，定义了 macro `m` 之后，`m` 就成为新的特殊形式。使用形状是：

```text
(m ...)
```

这和第一章的语法规则接上：序列的第一项若是特殊形式，就不按函数调用求值。Macro 是程序员往这张特殊形式表里加名字的办法。

### 三个使用例子（定义在可选讲）

```racket
(my-if e1 then e2 else e3)     ; 展开成 (if e1 e2 e3)
                               ; then / else 是语法，不是表达式

(comment-out e1 e2)            ; 展开成 e2。e1 永不求值
                               ; (comment-out (car null) #f) → #f，不报 car 的错

(my-delay e)                   ; 展开时把 e 放进 lambda
                               ; 函数版的 my-delay 做不到这一点
```

**【课程】** 演示：`(my-if #t then (+ 3 4) else 72)` → 7。把两个位置都写成 `else`，错误是 bad syntax，因为 macro 定义不允许那个位置出现 `else`。`(car null)` 单独求值会错；包在 `comment-out` 里不会，因为展开把整段换成 `#f`。

`my-delay` 的对比最能说明“函数进门太晚”：

```racket
(define p (my-delay (begin (print "hi") (* 3 4))))
```

若 `my-delay` 是函数，参数在调用前求值，`hi` 立刻打印。Macro 把这截语法放进 `lambda`，此时不打印。之后仍用原来的 `my-force` **函数**。force 打印一次并返回 12；再 force 同一次 promise，得到 12 但不再打印。Macro 负责推迟，promise 的 mutation 负责只算一次。两层不要并成一个机制。

### 为什么函数有些事做不到

**【课程】** 没有任何 Racket 函数能接受一个参数 `e` 而不求值它。函数的语义就是：进体之前参数已求值。所以：

- 想让调用者写 `e` 而不是 `(lambda () e)`，必须用 macro。
- 想在展开后根本不保留某段语法（`comment-out`），必须在求值前删掉它。函数最多不去看一个已经算完的值，算本身已经发生了。

这就是 `my-if-bad` 那一讲留下的洞。Thunk 是调用者手工推迟。Macro 把推迟写进语法变换，调用者看起来像在用特殊形式。

### 坏名声，以及课程的态度

**【课程】** Macro 在软件开发里名声不好，而且常常活该。它们被过度使用，用在函数更合适的地方。讲师的建议：拿不准就不要定义、不要使用。

但若你喜欢 `my-delay` 的调用写法，函数确实不够。可选讲的目的，是让人理解 macro 为什么难用好，并给出 Racket 比 C/C++ 预处理器更合理的语义。后面几讲因此标成可选：macro 相对独立，课程后面不会在它上面再盖一层，除了 Section 6 那个不同的“用函数生成 AST”的惯用法。

---

## 任何 macro 系统都要回答的三件事

**【课程】** 在写 `define-syntax` 之前，先看三件任何 macro 系统都会碰到的事：切词、括号、以及局部变量是否遮蔽 macro。

### Token，不是字符

Macro 系统在 token（词）上找使用处，不在字符上找。变量、关键字、运算符各是一个 token。

若定义“把 `head` 换成 `car`”：

| 源码 | 应否替换 | 为什么 |
| --- | --- | --- |
| `head` | 是 | 这一个 token 就是 macro 名 |
| `headt` | 否 | 另一个变量名。不要变成 `cart` |
| `head-door` | 在 Racket 里否 | 连字符可以是标识符的一部分，这是一个 token |

**【课程】** C 里 `head-door` 是三个 token：`head`、`-`、`door`，因为 C 的标识符不能含连字符，减号是运算符。没有空格不等于一个词。Macro 系统必须知道语言在哪里把字符切成 token。课程假定我们用的系统能做到这一点。

### 括号与优先级：C 的 `ADD` 为何要套很多括号

**【课程】** C/C++ 可以定义：

```c
#define ADD(x, y) x + y
/* ADD(1, 2/3) * 4  看起来像 (1 + 2/3) * 4 */
/* 实际变成 1 + 2/3 * 4，乘号比加号紧 */
```

展开是文本替换，替换结果再和后面的 `*` 抢优先级。所以 C macro 的定义里往往套上多余的括号。Racket 没有这个问题：macro 的使用总是紧跟在左括号后面，自己就是一个特殊形式；展开结果占的是同一个位置。展开出来的要么自带括号，要么是数或变量，不会和外面的运算符重新结合。

**【讲解】** 这是第一章“括号使树没有歧义”的直接后果。Parenthesization 不是审美，是 macro 展开后树的形状还稳不稳。

### 局部变量遮蔽 macro

**【课程】** 假设已经有“`head` 展开成 `car`”。另一段代码可能根本不知道这个 macro，只是用了同名局部变量：

```racket
(let ([head 0]
      [car 1])
  head)          ; 期望 0。let* 在没有互相引用时结果相同
```

天真地替换每一个 token `head`，四次出现都变成 `car`：

- `let` 里两个 `car`，同一 `let` 不能重复绑定，变成错误。
- `let*` 允许遮蔽，但体里的 `head` 被换成内层 `car`，结果从 0 变成 1。

Macro 干扰了甚至可能不知道它存在的代码。**【课程】** Racket 不这么做。局部变量 `head` 遮蔽 macro，这段里不展开，结果是 0。这是更合理的作用域语义，也是讲师愿意用 Racket 讲 macro 的原因之一。C/C++ 和多数 macro 系统在这件事上做得不好。

---

## `define-syntax` 与 `syntax-rules`

**【课程】** 定义语法的语法很多，但可以逐行读。三个例子就是上一讲用过的那三个。

```racket
(define-syntax my-if
  (syntax-rules (then else)          ; 除了 macro 名之外的关键字
    [(my-if e1 then e2 else e3)      ; 唯一的一种用法
     (if e1 e2 e3)]))                ; 展开成这个
```

- `define-syntax` 不是 `define`。它不定义变量或函数。
- `syntax-rules` 后面先是关键字表。必须告诉系统 `then` 和 `else` 是词，不是“任意表达式”。不列在这里的模式变量，匹配任意表达式。
- 即使只有一条规则，也要放在列表里。方括号是风格。
- 模式里的 `e1` 就是使用处那个位置的整段语法，可以有任意深的括号。展开式里的 `e1` 就是那段语法，像模式匹配，但是在定义 macro。

`(my-if #t then (+ 3 4) else 72)` → 7。漏写 `then` / `else`，或把 `then` 放错位置：没有规则匹配，报 bad syntax，并指出你在用 `my-if`。对使用者来说，`my-if` 就像语言的一部分；实现上它先展开成 `if`，再求值。

```racket
(define-syntax comment-out
  (syntax-rules ()                    ; 没有额外关键字，列表仍要写，写成空的
    [(comment-out e1 e2)
     e2]))                            ; 不要写成 (e2)，那会变成调用
```

`(comment-out (car null) (+ 3 4))` → 7。第一段被丢掉，所以 `car` 的错误不会发生。

### `my-delay` 必须是 macro，`my-force` 不该是

函数版（上一章）要求调用者传入 thunk。Macro 版把包 `lambda` 这件事做进展开：

```racket
(define-syntax my-delay
  (syntax-rules ()
    [(my-delay e)
     (mcons #f (lambda () e))]))
```

**(my-delay e) 不求值 e。** 它返回一个 mcons，cdr 是以后调用才求值 `e` 的 thunk。函数做不到。

若调用者仍自己写 `(lambda () e)`，会得到双层 thunk：force 一次得到的是另一个 thunk，不是 `e` 的结果。改成 macro 就是在改变客户端的正确写法。这是风格上可争论的，但机制没有问题。

`my-force` 应保持为函数。下面这个 macro 版本是课程用来展示错误的：

```racket
(define-syntax my-force-bad
  (syntax-rules ()
    [(my-force-bad e)
     (if (mcar e)
         (mcdr e)
         (begin (set-mcar! e #t)
                (set-mcdr! e ((mcdr e)))
                (mcdr e)))]))
```

模式变量 `e` 被复制进展开结果许多次。每一次出现都会求值那一段语法。讲师用一个会打印的参数演示：函数版的 `my-force` 打印一次并得到 7；这个 macro 版打印五次。到底几次取决于展开式里 `e` 出现的次数和哪些分支会跑，不容易心算。Macro 难推理，就是因为这个。

修好的 macro 用 `let` 把 `e` 求值一次，放进局部变量，后面只用变量：

```racket
(define-syntax my-force-once
  (syntax-rules ()
    [(my-force-once e)
     (let ([x e])
       (if (mcar x)
           (mcdr x)
           (begin (set-mcar! x #t)
                  (set-mcdr! x ((mcdr x)))
                  (mcdr x))))]))
```

它的行为和函数相同。**【课程】** 那就没有理由用 macro。Macro 不是“更高级的函数”。只有当你需要函数给不了的求值控制时才用。

---

## 求值几次、按什么顺序：`let` 是控制钮

**【课程】** 两个都叫 `double` 的 macro 彼此不等价，也都不该替代函数。加倍请用函数。这里用短例子把求值讲透。

```racket
; 不好的风格，仅供对比
(define-syntax double-plus
  (syntax-rules ()
    [(double-plus x) (+ x x)]))      ; x 出现两次 → 求值两次，打印两次

(define-syntax double-times
  (syntax-rules ()
    [(double-times x) (* 2 x)]))     ; x 出现一次 → 打印一次
```

`(double-plus (begin (print "hi") 42))` 得到 84，但打印两次。`double-times` 打印一次。函数版的加倍，无论内部是加还是乘，调用者都只看见参数被求值一次。Macro 把这个抽象泄漏了。

若坚持用 macro 做“加两次”，又只想求值一次：

```racket
(define-syntax double-let
  (syntax-rules ()
    [(double-let x)
     (let ([y x])
       (+ y y))]))
```

`x` 在 `let` 的右边出现一次，所以那段语法求值一次；两个 `y` 只是查找。这是一般技术：**用 `let` 控制 macro 参数求值的次数和顺序。**

不是永远都要一次：

- `my-delay` 要的是零次，直到以后调用 thunk。不要在展开时用 `let` 把 `e` 算掉。
- 下一节的 `for` 要让 body 求值许多次。那一段就该出现在循环的函数体里，而不是 `let` 的右边。

顺序也一样。想要“从 `e2` 里减去 `e1`”，天真展开成 `(- e2 e1)` 会先算 `e2`。Racket 函数参数从左到右求值。调用者只读了文档“take e1 from e2”，会惊讶于书写顺序和求值顺序相反。再用 `let`：先绑定 `e1`，再绑定 `e2`，然后做减法。

---

## Hygiene：macro 引入的变量不能污染使用处

**【课程】** 前面几讲的展开讲解是天真版本：把模式变量换成使用处的语法，其他照抄。真的 Racket 不是这样。更好的语义叫 hygienic macros（卫生宏）。它在变量可能遮蔽 macro、或 macro 可能捕捉使用处变量时，给出你期望的结果。

### 问题 1：macro 自己的局部变量捕捉了使用处的变量

```racket
(define-syntax double
  (syntax-rules ()
    [(double x)
     (let ([y 1])
       (* 2 x y))]))

(let ([y 7])
  (double y))        ; 使用处的人期望 14
```

天真展开把使用处的 `y` 原样填进 macro 体：

```racket
(let ([y 7])
  (let ([y 1])
    (* 2 y y)))      ; 两个 y 都是内层的 1，结果是 2，不是 14
```

使用处的 `y` 被 macro 定义里的 `y` **捕捉**（capture）了。C/C++ 里这会发生，所以那里的人若必须在 macro 里引入局部变量，就起谁都不会用的名字，例如 `__strange_name34`。

**【课程】** Racket 里这段得到 14。Macro 定义里的局部变量和使用处作用域里的变量保持分离。实现方式是在展开时按需要给 macro 引入的局部变量改名。课程不讲改名算法，只要求知道结果不是天真展开。

这就是 hygiene 的第一半：macro 引入的绑定不会捕捉使用处的变量，使用处的变量也不会意外绑到 macro 的局部名字上。

### 问题 2：macro 体里的自由变量该在哪里查找

```racket
(define-syntax double
  (syntax-rules ()
    [(double x) (* 2 x)]))

(let ([* +])          ; 使用处把 * 遮蔽成加法
  (double 42))
```

天真展开得到 `(* 2 42)`，而这里的 `*` 是加法，结果 44 而不是 84。`*` 只是一个变量，换成 `foo` 是同一个问题。

**【课程】** Racket 做对了：macro 定义里、定义在 macro 之外的变量，在 **macro 定义处** 的环境查找，不在使用处查找。这就是词法作用域，用在 macro 上，和用在函数上一样。C/C++ 预处理器不做这件事。有人把那种动态查找当成特性；讲师认为经验表明，绝大多数时候你要的是 Racket 的词法作用域和 hygienic 语义。

Hygiene 的两半：

| 问题 | 天真展开 | Hygienic |
| --- | --- | --- |
| macro 引入 `y`，使用处也有 `y` | 使用处的 `y` 被内层 `y` 捕捉，14 变成 2 | 改名，仍得 14 |
| macro 体使用 `*`，使用处遮蔽了 `*` | 按使用处的绑定，84 变成 44 | 按定义处的绑定，仍是乘法，得 84 |

**【课程】** 因此实现一个 hygienic 系统比天真替换难得多。字幕有一处把 macro system 说成 module system，是口误；上下文是 macro 的实现难度。Racket 的设计者做成了，并因此受益。

Hygiene 不是永远想要的规则，只是绝大多数时候想要。Racket 还有办法在特定位置退出这些规则，要去参考手册看。课程不讲那些形式。字幕同样把这里的“macro system”有一处说成 “module system”，不要据此以为 hygiene 属于模块讲。

---

## 更长的例子：次数、多规则、递归展开

### `for`：有的参数一次，有的参数多次

**【课程】** 这个例子最接近讲师喜欢布置的作业题。先看使用，再看为什么展开必须区别对待。

```racket
(for 7 to 11 do (print "hi"))
; 打印 5 次，因为 11 - 7 = 5。区间是左闭右开的行为，字幕用这个例子说明

(define (f x) (begin (print "A") x))
(define (g x) (begin (print "B") x))
(define (h x) (begin (print "C") x))
(for (f 7) to (g 11) do (h 9))
; A 一次，B 一次，C 五次
```

起点大于终点则 C 一次都不打印。这是使用者会期望的。

展开的形状（关键字是 `to` 和 `do`；精确的辅助函数写法以配套代码为准，下面按讲师描述的语义重建）：

```racket
(define-syntax for
  (syntax-rules (to do)
    [(for lo to hi do body)
     (let ([l lo]                 ; lo 求值一次，并且在 hi 之前
           [h hi])                ; hi 求值一次
       (letrec ([loop (lambda (i)
                        (if (< i h)
                            (begin
                              body           ; 每次调用 loop 都求值一次
                              (loop (+ i 1)))
                            (void)))])
         (loop l)))]))
```

`body` 被放进 `lambda` 的体，所以不是在展开时求值，也不是只求值一次，而是每次递归调用求值一次。`lo` 和 `hi` 在 `let` 右边，各一次，顺序就是书写顺序。这是上一节那条技术的正反两用。

**【讲解】** 比较符用 `<` 才能让 7 到 11 跑 5 次（7、8、9、10、11 若是 `<=` 则是 5 次，7 到 11 含两端也是 5 次）。字幕说 “11 minus 7 is 5”，两种区间都能凑出 5。不要把 `<` 或 `<=` 当成字幕逐字给出的代码。行为要点是：端点表达式各算一次，body 算“次数”次，起点大于终点则 body 零次。

### `let2`：多条规则，错误可能报在展开之后

```racket
(define-syntax let2
  (syntax-rules ()
    [(let2 () body)
     body]
    [(let2 x e body)
     (let ([x e]) body)]
    [(let2 x1 e1 x2 e2 body)
     (let ([x1 e1])
       (let ([x2 e2])
         body))]))
```

**(let2 x 1 y 2 (+ x y))** 得到 3。它去掉了普通 `let` 绑定列表的那层括号，并允许零个或一个绑定。零个绑定时 body 可以是不引用那些变量的表达式，例如只写一个常量计算。

没有匹配的规则：参数太多，或三个中间项而不是四个，错误是 `let2: bad syntax`，说的是 macro 没有匹配。这是好的，错误用 macro 的名字说话。

更讨厌的一种：

```racket
(let2 3 x 4 y body)
```

这 **匹配** 第三条：四个表达式加一个 body。展开之后才变成一个不合法的 `let`，因为变量的位置上是数字。报错说的是 bad `let`，期望 identifier，看到了 `3`。**【课程】** 这是 macro 的固有困难：错误消息可能针对展开结果，而不是使用者写下的 macro 调用。Racket 有办法改善错误消息，课程就此打住。

### `my-let*`：递归 macro

**【课程】** 若语言只有 `let` 没有 `let*`，可以用递归 macro 自己做。模式里的 `...` 是 Racket macro 的特殊语法，表示前面那一组可以重复，并在展开式里整组引用。讲师明确说：看这一段不足以让你独立写出递归 macro，要查参考手册。这里保留的是可能性，不是语法教程。

形状是：

```text
(my-let* () body)                         → body
(my-let* ([var0 val0] 更多绑定 ...) body)
    → (let ([var0 val0])
        (my-let* (更多绑定 ...) body))
```

最外层绑定先变成一个普通 `let`，其余绑定交给同名 macro 再展开。展开发生在运行之前，所以这是“生成一段更大的程序”，不是运行时递归。

若 macro 展开自己写成了无限循环，那就是 bug：程序还没开始跑，就试图生成一个无限大的程序，最终在运行前崩溃。递归 macro 是强功能，用错的方式和写错递归函数一样真实，只是失败发生得更早。

有了它，即使底层语言没给你 `let*`，你也可以加上。这是“扩展语法而不改实现”的完整小例子。

---

## Macro 与语法树

**【讲解】** 课程在这一节没有画 macro 的 AST，但第一章已经把括号程序定义成树。`syntax-rules` 匹配的就是这棵树的形状，不是字符串。

```text
(my-if (> x 0) then x else (- x))

        my-if
       /  |  |  \
    (> x 0) then  x  else  (- x)
       匹配 e1         匹配 e2    匹配 e3

展开后的树：

        if
      /  |  \
 (> x 0)  x   (- x)
```

所以：

- Macro 的输入是使用处的语法树（外加定义处的作用域信息，hygiene 需要它）。
- Macro 的输出是另一棵语法树。
- 输出树再进入后续的展开、然后求值。
- 它不返回值。`(comment-out (car null) #f)` 的结果 `#f` 是展开后再求值得到的，不是 macro 函数的返回值。

**【扩展】** 有的 macro 系统（Racket 的更底层 API，以及一些其他语言）让你显式拿语法对象做变换，而不只是 `syntax-rules` 的模式。课程停在 `syntax-rules`。不要把 `syntax-rules` 当成 Racket macro 的全部。

---

## 逐讲笔记

### 19 Macros: The Key Points

1. **问题：** 什么机制能在求值开始前，把新语法变成旧语法？
2. **动机：** 下一节需要“扩展语法”这个想法。作业本体不依赖这一节。
3. **概念：** macro = 语法糖的定义；展开先于类型检查和求值；在 Racket 里成为特殊形式。
4. **机制：** 使用处整段被替换。未执行的分支里的 macro 也会展开。
5. **代码：** `my-if`、`comment-out`、`my-delay` 的使用，不是定义。
6. **执行：** `comment-out` 使 `(car null)` 不求值。`my-delay` 不立刻打印；`my-force` 第一次打印并得 12，第二次不打印。
7. **PL：** 函数变换值，macro 变换语法。求值时机因此可以成为语法的一部分，而不是每个调用者的手工 thunk。
8. **误区：** Macro 就是“运行时生成代码的函数”。拿不准时应该用 macro，因为它更强。
9. **联系：** `my-if-bad` 证明函数包不住 `if`。特殊形式表是第一章的语法规则。
10. **一句：** 展开是求值前的重写；函数永远来不及阻止参数被求值。

### 20 Tokenization, Parenthesization, and Scope（可选）

1. **问题：** Macro 系统怎样才不会在字符、优先级和局部变量上做错？
2. **动机：** 不先说这些，`define-syntax` 会看起来像字符串替换。
3. **概念：** token；Racket 标识符可含连字符；C 的优先级洞；局部变量遮蔽 macro。
4. **机制：** 按 token 替换 `head`，不替换 `headt` 或 `head-door`。Racket 的使用处总在左括号后，展开不重新抢优先级。局部 `head` 遮蔽 macro，不展开。
5. **代码：** C 的 `ADD` 是反例。Racket 的 `let` / `head` / `car` 是正例。
6. **执行：** 天真替换使 `let` 报重复绑定，或使 `let*` 从 0 变成 1。Racket 得到 0。
7. **PL：** Macro 的语义必须知道宿主语言的词法、具体语法和作用域。它不是与语言无关的文本工具。C 预处理器接近文本工具，所以有这些坑。
8. **误区：** 宏展开就是查找替换字符串。Racket 和 C 的 macro 只是括号多少的差别。
9. **联系：** 第一章：括号使树无歧义，所以展开后不用再学优先级。
10. **一句：** 可靠的 macro 系统操作的是 token 和树，并且尊重局部作用域。

### 21 Defining Macros with define-syntax（可选）

1. **问题：** 怎样把上一讲的三个使用写成真正的定义？
2. **动机：** 使用而不定义，会把 macro 当成黑箱关键字。
3. **概念：** `define-syntax`、`syntax-rules`、关键字表、模式变量、展开式。
4. **机制：** 模式匹配使用处的树；关键字必须精确出现；其余位置整段搬进展开式。
5. **代码：** `my-if`、`comment-out`、`my-delay`，以及故意写错的 `my-force` macro。
6. **执行：** 匹配失败是 bad syntax。`my-force` macro 把带打印的参数求值多次；`let` 版只求值一次，但此时函数同样好。
7. **PL：** Macro 的输出是语法。把同一段语法复制到多个求值位置，就是把求值次数乘上去。
8. **误区：** 展开式写成 `(e2)` 只是多一层无害括号。`my-force` 用 macro 更“一致”。调用者已经会写 thunk 时，再 macro 一层 `my-delay` 不会改变层数。
9. **联系：** Promise 的表示没变。变的只是谁负责包 `lambda`。
10. **一句：** `syntax-rules` 是对语法树的模式匹配；复制模式变量就是复制以后的求值。

### 22 Variables, Macros, and Hygiene（可选）

1. **问题：** Macro 引入的变量，为什么不应该碰使用处的同名变量？
2. **动机：** 上一讲建议用 `let` 控制求值次数。在 C 里这正好是危险动作。必须解释 Racket 为什么允许你这么做。
3. **概念：** 求值一次的 `let`；求值顺序；variable capture；hygiene；macro 的词法作用域。
4. **机制：** 天真展开把使用处的 `y` 填进 macro 的 `(let ([y 1]) ...)`，14 变 2。Racket 改名，仍为 14。自由的 `*` 在定义处查找，遮蔽不影响，84 不变成 44。
5. **代码：** `double-plus`、`double-times`、`double-let`、带 `y` 的 `double`、使用处把 `*` 改成 `+`。
6. **执行：** 打印两次 vs 一次。捕捉时得 2。词法查找时得 84。
7. **PL：** Hygiene 是把词法作用域贯彻到语法变换。函数早就这么做了：函数体的自由变量不随调用处的遮蔽而变。Macro 若做文本替换，就退回了动态作用域。
8. **误区：** Hygiene 意味着 macro 不能有局部变量。Racket 的结果等于把源码粘贴进使用处。为了安全必须把局部变量命名成 `__strange_name34`（那是缺少 hygiene 的系统的习惯）。
9. **联系：** Part A 的词法作用域与闭包。定义处决定自由变量，使用处只提供参数。Macro 的“参数”是语法，自由变量仍在定义处解析。
10. **一句：** Hygienic macro 给自己的局部变量改名，并在定义处解析自己的自由变量。

### 23 More Macro Examples（可选）

1. **问题：** 多参数、多规则、递归展开，还会出现什么新的失败方式？
2. **动机：** 短例子看不出“有的表达式要算多次”。错误消息报在展开后，也要亲眼看见。
3. **概念：** `for` 的次数控制；`let2` 的多 case；展开后的语法错误；`...`；递归 macro；展开期无限循环。
4. **机制：** `let` 固定 `lo`/`hi`；`body` 放进循环函数。规则不匹配则 macro 自己报 bad syntax。规则匹配但展开非法，则内层构造报错。
5. **代码：** `for`、`let2`、`my-let*`。`...` 的精确语法去查手册。
6. **执行：** `(f 7)` 到 `(g 11)` 再 `(h 9)`：A 一次，B 一次，C 五次。起点更大则 C 零次。`(let2 3 x 4 y ...)` 匹配成功，随后 `let` 拒绝数字当标识符。
7. **PL：** Macro 是程序生成程序。生成器可以不终止，失败发生在对象程序开始运行之前。错误的抽象层次（报在展开后）是这种生成的代价。
8. **误区：** 递归 macro 是运行时递归。多一条规则就能保证所有误用都得到以 macro 命名的错误。`for` 的 body 会在展开时执行。
9. **联系：** `let` / `let*` 的语义差别，现在可以看成一条 macro 能定义的差别。求值次数的控制钮仍是“语法出现在 `let` 右边，还是出现在函数体里”。
10. **一句：** Macro 能规定一段语法求值零次、一次或多次；它也能在运行前就生成一个永远展开不完的程序。

---

# Section 5 Summary

## 这一 Section 的核心问题

在一门没有静态类型系统、语法几乎就是树的函数式语言里，计算何时发生，以及程序员能否规定它何时发生？

Section 5 的前半是把 Part A 的程序观搬进 Racket，并看类型检查器退出后还剩下什么。后半是一条求值控制的链：thunk、promise、stream、memoization、macro。它们不是五个技巧，是同一个问题的五种答案。

## 知识地图

```text
Dynamic Language（Racket）
      │
      ├── 程序 = 树。括号是结构，特殊形式是求值规则的例外
      │
      ├── 值有标签，变量没有静态类型
      │     错误从“拒绝程序”挪到“走到那次原语调用”
      │
      ├── 绑定
      │     let / let* / letrec / 文件级 letrec
      │     set! 改绑定的当前内容，不改 cons cell
      │
      ├── 数据
      │     不可变 cons（列表是以 null 结尾的 pair）
      │     可变 mcons（另一类型）
      │
      ├── Delayed Evaluation
      │       │
      │       ├── Thunk：零参数函数，每次调用都算
      │       ├── Promise：delay/force，最多算一次
      │       ├── Stream：thunk → (值, 下一个 thunk)，可以无限
      │       └── Memoization：按参数记表；递归必须走这张表
      │
      └── Macros
            语法 → 语法，先于求值
            hygiene = 词法作用域用于语法变换
```

## 最重要的 5–10 个概念

1. 特殊形式 vs 函数调用：只有前者能不求值某些子表达式。
2. 动态类型：值有标签；缺少的是运行前的证明，不是标签本身。
3. 三种 `let`：初始化表达式看见的环境不同。
4. `set!` 改的是绑定。字段要改，用 `mcons`。
5. Thunk：`(lambda () e)` 把现在算变成以后算。
6. Promise：用可变 pair 把“以后算”收成“最多一次”。
7. Stream：无限序列的有限表示是推迟的尾巴，不是无限的列表。
8. Memoization：纯函数 + 跨调用存活的表 + 递归走同一入口。
9. Macro：展开在求值前；复制语法就是复制求值。
10. Hygiene：macro 的局部变量不捕捉使用处，自由变量在定义处解析。

## 最重要的代码模式

```racket
(if e1 e2 e3)                         ; 只算一支
(lambda () e)                         ; thunk
(mcons #f th)  /  my-force            ; promise
(lambda () (cons v ones))             ; stream
(assoc x memo) 然后 set!              ; memoization
(define-syntax m (syntax-rules ...))  ; 语法 → 语法
(let ([x e]) ...)                     ; 在 macro 里把 e 收成一次
```

## 容易混淆的概念

| 人们常说 | 课程里的分辨 |
| --- | --- |
| 括号是 Lisp 的怪语法 | 括号是树。多一个就是零参数调用 |
| 动态类型 = 无类型 | 值有标签。`+` 仍会拒绝字符串，只是晚 |
| `set!` 改数据 | `set!` 改变量指向什么。改 pair 字段是 `set-mcar!` |
| Stream = list | Stream 是 thunk。List 在构造时就把尾巴算完 |
| Thunk = 线程 / future | 没有并发。只是闭包 |
| Macro = 函数 | 函数看见值。Macro 看见语法，并且在求值前替换 |
| Racket macro = C `#define` | Token、括号位置、hygiene 都不同 |
| Lazy language = 用了 thunk 的 Racket | Racket 函数参数仍是 eager。Haskell 才把 lazy 放进调用规则 |

## 和上一 Section（Part A）的关系

Part A 把函数、环境、闭包、列表、递归教成使用者的语义。Section 5 证明这些语义不依赖 ML 的类型推导和中缀语法：同一抽象在 Racket 里仍在。新的是：类型错误的时间变了；绑定的初始化环境可以有三种定义；求值时机可以被 thunk 和 macro 拿来当设计材料。

Part A 的闭包在这里被**使用**（thunk 能记住自由变量），还没有被**实现**。那是 Section 6 的升级。

## 为下一 Section 做了什么准备

- 没有 ML datatype 时，课程已经用“带标签的值 + 谓词”写过嵌套数据。Section 6 把这个做法系统化成手写构造器，再用 `struct` 换成真正的新数据类型。
- Macro 的想法——不改实现就扩展语法——会在解释器里以另一种形式出现：Racket 函数生成对象语言的 AST。那不是 `define-syntax`，也不 hygienic。
- “程序是树”会从 Racket 的括号，变成你自己的 struct 树和 `eval`。
- 局部 mutation（promise、memo 表）说明：实现可以用赋值，同时对客户端保持更简单的推理。解释器里的环境更新是另一回事，不要提前混成 `set!`。

---

## Engineering Connection

**【课程】** Macro 名声差，是因为它们经常用在函数够用的地方，并且糟糕的 macro 系统会破坏作用域和优先级。Racket 的设计是反例：hygiene 和“使用处就是一棵子树”去掉了 C 预处理器的两大类事故。仍建议默认用函数。

**【扩展，类比，不是课程结论】**

| 机制 | 像什么 | 不像什么 |
| --- | --- | --- |
| C 预处理器 | 课程拿来当反面教材的文本 macro | 不是 hygienic，也不是按 C 的语法树展开 |
| Rust `macro_rules!` | 也在语法上匹配并生成语法，并处理 hygiene | 课程没讲 Rust。不要用本课细节推断 Rust 的 `macro` / `macro_rules` 差别 |
| Lisp 的非卫生 `defmacro` | 更接近天真展开 | 课程说 Racket 故意不那么做 |
| 模板引擎、JSX 转换 | 都是生成程序或生成树 | 多数没有 Racket 这套词法作用域规则 |
| 编译器的 desugar 遍 | 和时间点一样：先重写，再检查，再求值 | 那是语言实现者的遍，不是每个程序员都能加的特殊形式 |

课程要你带走的工程判断只有一句：若问题是“不要太早求值”或“增加一种括号形式”，先问函数加 thunk 够不够。不够时，macro 才是那个语言机制，并且你必须回答求值几次、变量属于谁。

---

## 检查题

1. 为什么 `(my-if e1 e2 e3)` 写成函数就无法成为真正的 `if`？Macro 展开发生在什么时候，为何能绕过这个问题？
2. `(comment-out (car null) #f)` 为什么不报错？若 `comment-out` 是函数，会怎样？
3. 函数版 `my-delay` 和 macro 版 `my-delay`，调用者写的参数有什么不同？双层 thunk 是怎么产生的？
4. 为什么把 `my-force` 定义成 macro，打印次数会变？`let` 如何把次数收回来？收回来之后为什么仍不该用 macro？
5. `head-door` 在 Racket 和在 C 里，macro 替换 `head` 的结果为什么不同？
6. C 的 `#define ADD(x,y) x+y` 再乘 4，错在树的哪一层？为什么 Racket 的括号位置使这个问题不出现？
7. 局部变量 `head` 与 macro `head` 同名时，Racket 展开还是不展开？天真替换会让 `let` 和 `let*` 分别坏成什么样？
8. `(let ([y 7]) (double y))` 在天真展开下为什么是 2？Hygiene 保证的是哪一个数字？
9. 使用处把 `*` 遮蔽成 `+` 时，hygienic macro 里的 `*` 仍是乘法。这和函数的哪条作用域规则是同一条？
10. `for` 的 `lo`、`hi`、`body` 各应求值几次？把 `body` 放进 `let` 的右边会破坏哪一个期望？
11. 为什么有的 macro 误用报 `let2: bad syntax`，有的却报 `let` 期望 identifier？
12. 递归 macro 的无限循环，为什么在程序运行前就失败？

## Answers

1. 函数调用先求值所有参数，两支都会算，递归停不下来。Macro 在求值前把使用处重写成 `if` 的语法，`if` 的规则才有机会只算一支。展开也发生在未执行的分支里，因为它根本不是求值。
2. 展开结果是 `#f`，`(car null)` 不在展开后的程序里。函数会在进体前求值第一个参数，`car` 立刻报错。
3. 函数版要求调用者传入 thunk。Macro 版接受表达式 `e`，展开成 `(lambda () e)`。若调用者按旧习惯再写一层 `lambda`，展开又包一层，force 一次得到的是 thunk 而不是值。
4. 模式变量在展开式里出现几次，那段语法就可能被求值几次（还要看哪些分支执行）。打印因此重复。`let` 让那段语法只在右边出现一次，后面用变量。行为和函数相同，macro 没有带来函数没有的求值控制，所以不该用。
5. Racket 里 `head-door` 是一个标识符 token，替换 `head` 不应碰它。C 里 `-` 是运算符，`head-door` 是三个 token，macro 会换掉其中的 `head`。
6. 展开后的 `+` 和外面的 `*` 在同一层表达式里重新按优先级结合，乘在加之前。Racket 的 macro 使用本身是一对括号里的一棵子树，展开替换的是这棵子树，不会和外面的运算符拼成新的中缀表达式。
7. 不展开，局部变量遮蔽 macro，结果是 0。天真替换后，`let` 对 `car` 重复绑定，是错误；`let*` 允许遮蔽，体变成内层 `car`，结果是 1。
8. 使用处的 `y` 被填进 `(let ([y 1]) (* 2 y y))`，两个运算数都是 1。Hygiene 把 macro 的 `y` 改成不会捕捉的名字，使用处的 `y` 仍是 7，结果是 14。
9. 和词法作用域一样：自由变量在定义处解析，不在使用处解析。函数体里的 `+` 不会因为调用者有局部的 `+` 就变成别的函数。Hygienic macro 把这条规则用到语法变换上。
10. `lo` 和 `hi` 各一次，且 `lo` 在 `hi` 之前；`body` 每次迭代一次；起点不小于终点则 body 零次。放进 `let` 右边会让 body 在循环前只算一次，打印 C 的次数不再是 5。
11. 第一种是没有规则匹配，错误还能用 macro 的名字报告。第二种是规则匹配了，展开出非法的 `let`，检查发生在展开之后，消息说的是 `let`。
12. 展开是运行前的预遍。递归 macro 不停地生成更多 macro 调用，就是在生成无限大的程序，还没进入求值就已经失败。
