# 09 — 什么时候才该求值，以及谁有权改语法

> Part B · Section 5 后半
> 视频：`13`–`19`，optional `20`–`23`

Racket 和 ML 一样，函数调用在进入函数体之前把每个参数求值一次。条件表达式不是这样：它只求值测试，再求值被选中的那一枝。这两条规则单独看都已经学过。把它们撞在一起，才会出现这一章的第一个裂缝。

```racket
(define (my-if-bad e1 e2 e3)
  (if e1 e2 e3))

(define (factorial-bad x)
  (my-if-bad (= x 0)
             1
             (* x (factorial-bad (- x 1)))))
```

`factorial-bad` 对任何参数，包括 `0`，都不终止。`if` 的逻辑没有写错。错的是 **when arguments are evaluated**。调用 `my-if-bad` 之前，三个参数都已经在跑。递归那一个参数自己又要调用 `my-if-bad`。函数体里那个真正的 `if` 永远没有机会看见 base case。

所以这一章不是在学一种新的数据类型。它在追问：语言已经规定了“何时求值”。如果这个规定不对你的问题，你能用已有的机制推迟它吗？推迟到什么时候、记住结果吗、能表示一条还没造出来的无限序列吗？以及：有没有一种变换，函数根本做不到，因为它发生在求值之前？

---

## 1. 这一章要解决什么问题？

五件不同的事经常被叫成“惰性”：

1. 不需要的分支不要跑。这是 `if` 已经做的事。函数包一层就会把它弄丢。
2. 可能用到、也可能用不到的昂贵计算：没人要就不算，要了也不要算第二次。
3. 概念上无限的序列：生产者知道怎么做下一个值，但不知道要多少个；消费者知道要多少个，但不知道怎么产生。
4. 无副作用的函数，同一参数再算一遍没有意义。指数递归可以因此变成大约线性。
5. 有些语法变换必须发生在任何求值之前：丢掉一段会报错的表达式，把表达式塞进 `lambda`，加入 `then` / `else` 这种不是值的关键字。

前四件都能用闭包（Closure）加上一点可变状态做出来。第五件不能。没有任何函数能“收到一个参数却不求值它”。那是宏（Macro）存在的理由。

课程把这些放在 Racket 里，不是因为 ML 做不到 thunk。Part A 的函数体同样延迟到调用才跑。换语言是为了在动态类型下重做同一批想法，并让“括号就是调用”这种错误变得可见。Haskell 被点名，是作为默认惰性的对照，不是这一章要切换过去的实现。

依赖：函数调用先求参数、`if` 只求一边、闭包、`let` / `letrec`、`mcons` 与 `set!`。准备：Section 6 会用到“宏是求值前的语法扩展”这个想法；作业里的 stream 是这一章的消费者协议。

---

## Lecture — Thunk：零个参数的函数，唯一的用途是先别算

视频：`Delayed Evaluation and Thunks`。

### 1. 先遇到的困难

每种语言构造的语义都必须规定：子表达式求不求值，何时求值。ML 和 Racket，以及多数你熟悉的语言，函数调用的规定是：参数在调用开始前各求值一次；函数体用参数名去查找那些已经算出的结果。`if` 的规定是：先求测试，再只求选中的一枝。

因此“包一层函数”不是语义等价的，只要那层函数会提前求值调用者本想推迟的表达式。Unnecessary function wrapping 在 Part A 里只是多一次调用。这里它改变程序是否终止。

### 2. 核心概念

#### Thunk

**Definition.** Thunk 是为了延迟求值而使用的零参函数（zero-argument function）。可以当动词：thunk that expression。词源没有定论。它不是一种新的值种类。它就是 0 参函数，用途是推迟。

三个必须分开的东西：

```text
e                    求值 e，得到结果
(lambda () e)        一个函数。现在不求值 e。每次调用都求值 e
(e)                  先求值 e，得到一个 thunk，再调用它。
                     最终结果是 body 的结果
```

`(37)` 报错，因为 `37` 不是过程。`((lambda () 37))` 得到 `37`。在 Racket 里，多一对括号不是分组。它是零参调用。

**Intuition.** 把还没想算的表达式关进函数体。函数体在调用前不跑。这是语言里已经有的求值规则，不是新关键字。

**Why it exists.** 闭包让你在任何表达式位置造出一个“以后再算”的值，并且那个值能记住定义时的环境。没有闭包，推迟求值就得靠语言内置的特殊形式，调用者无法自己制造。

**Problem solved.** 让一个普通函数模拟 `if` 的“另一枝不求值”。这不是好风格。内置 `if` 才是对的。Thunk 是后面 idiom 的工具。

**Example.**

```racket
(define (factorial-normal x)
  (if (= x 0)
      1
      (* x (factorial-normal (- x 1)))))
; (factorial-normal 5)  => 120
; (factorial-normal 500) 能打出很大的数。Racket 的整数没有这种宽度问题。

(define (my-if-strange-but-works e1 e2 e3)
  (if e1 (e2) (e3)))   ; 只调用被选中的 thunk

(define (factorial-okay x)
  (my-if-strange-but-works
   (= x 0)
   (lambda () 1)
   (lambda () (* x (factorial-okay (- x 1))))))
```

```text
factorial-bad，参数 0：

调用 my-if-bad 之前必须先求三个参数
  (= 0 0)                         → #t
  1                               → 1
  (* 0 (factorial-bad -1))        又要调用 my-if-bad
    那个调用又要先求它的递归参数
函数体里的 if 一次都没有执行
Value: 没有。不终止

factorial-okay，参数 0：

三个参数都先变成值，但后两个值是函数，body 不跑
  e1 → #t
  e2 → closure { code: (lambda () 1) ; env: 这个调用的 x }
  e3 → closure { code: (lambda () (* x (factorial-okay ...))) ; env: x → 0 }
进入 my-if-strange-but-works 之后，只调用 e2
Value: 1
e3 从未被调用，所以 (* x (factorial-okay -1)) 不发生
```

递归 thunk 捕获的是这一次调用的 `x`。不调用，就不需要那个 `x` 去参与乘法。捕获和求值是两件事。

### 3. 若改掉规则

- 用 `my-if-bad` 写任何递归：只要递归出现在参数位置，base case 也停不下来。
- 调用 thunk 时忘了括号：得到的是函数，不是 body 的值。
- 多写括号 `(1)`：把值当 0 参函数。这是 Section 5 前半已经见过的括号错误，在这里变成语义错误。
- 若语言的函数参数默认惰性（他下讲点名 Haskell）：`my-if-bad` 就不会在调用前把两个分支都跑掉。Racket 和 ML 不是那样。本课要的求值规则仍然可预测，因为延迟是你写出来的，不是默认的。

把 `e`、`(lambda () e)`、`(e)` 弄混，会让后面的 stream 作业非常难。这不是风格问题。三种写法是三种不同的求值次数。

---

## Lecture — 不算、算一次、算很多次

视频：`Avoiding Unnecessary Computations`，`Delay and Force`。

### 1. 先遇到的困难

Thunk 可以跳过不需要的昂贵计算。但如果多个地方都可能需要同一次计算，每次走需要的分支都重新调用 thunk，就会重复做。预先算好则在完全不需要时也付了成本。要的是：没需要就不算；需要超过一次也只算一次。

`slow-add` 的空转循环没有在字幕里读出来。只知道：它把两个参数相加，额外代码让 `(slow-add 3 4)` 大约一秒后得到 `7`。下面不发明那个循环。

### 2. 两难，用同一个 `my-mult` 看

```racket
(define (my-mult x y-thunk)
  (cond [(= x 0) 0]                 ; 不调用 thunk
        [(= x 1) (y-thunk)]
        [#t (+ (y-thunk)
               (my-mult (- x 1) y-thunk))]))
; x = 7 时，y-thunk 被调用 7 次
```

| 传进去的东西 | 乘 0 | 乘 1 | 乘 2 或 100 |
| --- | --- | --- | --- |
| `(lambda () (slow-add 3 4))` | 很快，不算 | 一次，无法避免 | 每次调用都重算，比预计算差 |
| 先 `(let ([x (slow-add 3 4)]) ...)`，thunk 只 lookup `x` | 也付了那一秒 | 不再额外付 | 不再额外付 |
| 下一节的 promise | 不算 | 一次 | 只 slow-add 一次，其余是读存好的 `7` |

Thunk 不是总是更快。它只在结果可能不用时更快。多次使用会更慢。预计算不是总是更好。它在结果完全不用时浪费。

他说：若计算无 side effect、结果总相同、何时算不影响答案，就可以记住第一次的答案。这叫惰性求值（Lazy Evaluation）。大多数构造、尤其所有函数调用都这样工作的语言叫 lazy language。今天最有名的成功例子是 Haskell。Racket 不是。函数参数在调用点求值，和 ML 一样。但可以用已经学过的两样东西自己实现：thunk，和可变 pair。

### 3. Promise：第一次 force 才算，之后只读

**Definition.** `(my-delay th)` 接收一个已经造好的 thunk，不调用它。返回一个可变 pair：`#f` 和那个 thunk。这个返回值叫 promise。含义是：需要时 force 我，我会给你。`(my-force p)` 若 car 为真，cdr 就是已经算好的结果；否则把 car 设成 `#t`，调用 cdr 里的 thunk，把结果写回 cdr，再返回它。Thunk 被替换掉，不再保存。

```racket
(define (my-delay th)
  (mcons #f th))          ; 这里没有 (th)

(define (my-force p)
  (if (mcar p)
      (mcdr p)
      (begin
        (set-mcar! p #t)
        (set-mcdr! p ((mcdr p)))
        (mcdr p))))
```

函数名加 `my-`，以免和 Racket 标准库的 `delay` / `force` 冲突。标准库有语法略不同的内置支持。他宁肯自己实现，再用自己的版本重做乘法例子。Promise 是一个小的 one-of：car 表示“还要不要算”。理想情况做成抽象数据类型，藏在 module 里。他还没讲 Racket 的 module，所以表示露着。

和 `my-mult` 对接时，`my-mult` 仍要一个 thunk。所以传 `(lambda () (my-force p))`。这个 thunk 被调用多次没关系，因为第二次起 `my-force` 很快。

```racket
(let ([p (my-delay (lambda () (slow-add 3 4)))])
  (my-mult n (lambda () (my-force p))))
```

```text
创建 promise，不发生 slow-add：

p → mcons 单元 A
A.car = #f
A.cdr = closure { code: (lambda () (slow-add 3 4)) }

第一次 my-force：
  car 是 #f，走 else
  set-mcar!  → car = #t
  ((mcdr p)) 跑 slow-add，得到 7
  set-mcdr!  → cdr = 7          ; thunk 没了
  返回 7

第二次 my-force：
  car 不是 #f，直接返回 cdr
  Value: 7
  没有第二次 slow-add

my-mult 的那个 thunk 关闭的是 p，不是 7。
多次调用共享同一个 mcons。共享在这里是语义，不是实现细节。
这是 mutation 值得用的地方：要让后来的调用看见“已经算过”。
```

不可变 `cons` 做不到把 thunk 换成结果。每次 `my-delay` 做一个新 promise，缓存也不共享。必须让多次 force 指向同一个单元。

Promise 不会在你不看的时候自动算好。不算，直到 `my-force`。Lazy evaluation 在这里不等于“语言不求值参数”。它只覆盖你显式 delay 的那些计算。

纯函数式语言也可以做惰性，Haskell 就是。在 eager 语言里，这一份实现依赖 `set-mcar!` / `set-mcdr!`。这是受控的可变性，不是把所有绑定都变回盒子。

---

## Lecture — Stream：无限序列不是无限的 list

视频：`Using Streams`，`Defining Streams`。

### 1. 先遇到的困难

有些序列概念上无限：用户事件、管道的输出、电路随时间的输出。不能真的造一个无限 list。生产者知道怎么做下一个值，但不知道要多少个。消费者知道要多少个，但不知道怎么产生。两边的劳动要分开。

若在绑定完成前就递归构造，eager 语言会在名字还没绑定完时就去求它。若 thunk 的 body 在构造 pair 时就调用自己，一调用就试图展开成无限 list，永不返回。正确的递归必须藏在还没被调用的 thunk 里。

### 2. 核心概念

**Definition.** 本课的 stream 不是新语言构造。它是一个 idiom：stream 就是 thunk。调用它得到一个 pair：car 是下一个值，cdr 是其余值的 stream，也就是另一个还没调用的 thunk。不要把 cdr 里的 stream 提前调用。调用得到 pair；不调用才是 stream。

**Intuition.** 你手里从来没有“整条无限序列”。你手里有一个承诺：再要一个，我就给你一个值和另一个承诺。

**Why it exists.** List 在造出来时长度已经定了，尾巴已经在那里。Stream 把“下一个值如何产生”和“要多少个”拆开。这和 Part A 的 callback 都能处理一串事件，但是方向相反：stream 是消费者来拉，callback 是库在事件发生时来调你。

**Problem solved.** 生产者写一次如何做下一个值。消费者写 `number-until` 这种“要到某个条件为止”的函数，不必知道 2, 4, 8 是怎么来的。

他先使用，再定义。`powers-of-two` 从 2 开始：2, 4, 8, 16, ...

```racket
powers-of-two                              ; 一个过程，不是一个数
(powers-of-two)                            ; pair：car = 2，cdr = 另一个过程
(car (powers-of-two))                      ; 2
(car ((cdr (powers-of-two))))              ; 4
(car ((cdr ((cdr (powers-of-two))))))      ; 8

(define (number-until stream tester)
  (letrec ([f (lambda (stream ans)
                (let ([pr (stream)])
                  (if (tester (car pr))
                      ans
                      (f (cdr pr) (+ ans 1)))))])
    (f stream 1)))

(number-until powers-of-two (lambda (x) (= x 16)))   ; 4
```

`ans` 从 1 开始，所以返回的是从 1 数起的位置，不是“跳过了几个”，也不是最后一个元素。某个很大的阈值要 339 次，大约 10 倍大要 343 次，再 10 倍要 346 次。阈值本身不在字幕里。重点是：你不需要先造出那 346 个元素再去数。

```text
number-until，直到 16，流是 2, 4, 8, 16, ...

(f stream 1)
  (stream) → pair(2, s2)
  tester(2) 为假
  (f s2 2)
    pair(4, s3) → (f s3 3)
      pair(8, s4) → (f s4 4)
        pair(16, s5)，tester 为真
Value: 4

s2、s3 在被调用之前不存在为 pair。
它们是 thunk。环境里 f 通过 letrec 看见自己。
```

多一对括号是这一章最常见的 bug：

```racket
(number-until (powers-of-two) ...)
; 传进去的是 pair，不是 stream
; 下一次 (stream) 试图把 pair 当过程调用
; 错误：expected a procedure, given a pair
; 那个 pair 的 car 是 2，cdr 是某个过程
```

看见一个 procedure，不说明 stream 坏了。Stream 本来就是 procedure，直到你调用它。

### 3. 自己造：递归必须待在还没调用的 lambda 里

```racket
(define ones
  (lambda ()
    (cons 1 ones)))

(car (ones))                 ; 1
(car ((cdr (ones))))         ; 1
```

```text
(ones) → pair(1, ones)
cdr 就是同一个 thunk ones，不是一条新 list
再调用那个 cdr → 又是 pair(1, ones)
没有分配无限结构
```

`(lambda () (ones))` 若 `ones` 已经是 thunk，是 unnecessary function wrapping。`ones` 本身就能当那个 stream。

两个看起来很近、但都是错的版本：

```racket
; Racket / ML / Java 都不能这样写。
; 求值 cons 的参数时，ones-really-bad 还没绑定完。这是真的循环。
(define ones-really-bad (cons 1 ones-really-bad))

; 这是 thunk，绑定成功。一调用就在 cdr 位置调用自己。
; 那个调用又调用自己，试图造无限长的 list，永不返回。
(define ones-bad
  (lambda ()
    (cons 1 (ones-bad))))
```

Haskell 可以写第一种，因为那里 `cons` 的参数不急着求值。Racket、ML、Java，以及一切函数调用 eager 的语言都不行。他明确把这说成调用语义的差别，不是“Haskell 更聪明所以能递归绑定”。

Stream 不是无限 list，只是打印时被截断。错误版本才会试图建造无限 list，并且不终止。正确版本是：不断应用 thunk 和 cdr，就能再要一个值。

自然数和 2 的幂只差“下一个值怎么算”。助手 `f` 返回 pair，stream 本身仍必须是 thunk：

```racket
(define nats
  (letrec ([f (lambda (x)
                (cons x (lambda () (f (+ x 1)))))])
    (lambda () (f 1))))

(define powers-of-two
  (letrec ([f (lambda (x)
                (cons x (lambda () (f (* x 2)))))])
    (lambda () (f 2))))
```

```text
调用 nats 的外层 thunk → (f 1)
  → pair(1, thunk)
    那个 thunk 的环境里有 f，以及 x → 1
以后调用它 → (f 2) → pair(2, ...)

把 (lambda () (f (+ x 1))) 写成 (f (+ x 1))：
  第一次调用 f 时，cdr 位置立刻递归
  tail 被马上算出来，不返回 pair
```

`stream-maker` 的实现留在随讲发布的代码里，字幕没读出来。按他的描述，它抽象掉 `+ 1` 和 `* 2` 的差别：`nats` 用加法函数和 1，`powers-of-two` 用乘法函数和 2。下面是按这句话做的最小重建，不是逐字屏幕代码：

```racket
; [?] 字幕未读出函数体。按“抽象掉 +1 与 *2”重建。
(define (stream-maker fn arg)
  (letrec ([f (lambda (x)
                (cons x (lambda () (f (fn x arg)))))])
    (lambda () (f arg))))
```

他说：这段代码短到让人以为比实际上更简单。短，是因为递归藏在一个还没调用的 lambda 里。把那个 lambda 拿掉，短代码变成不终止。

他的 stream 定义不 memoize 尾巴。每次重新调用同一个 thunk，会再算一次下一个 pair。这和 promise 不同。Promise 记住一个 0 参计算。Stream 在这一课里只推迟尾巴。作业还要写“吃一个 stream、返回一个新 stream”的函数。他没演示。测试方法是使用 stream。

tester 永不返回真，消费就会无限循环。表示是惰性的，消费可以不懒。

---

## Lecture — Memoization：有参数时，一张表，不是一个 promise

视频：`Memoization`。

### 1. 先遇到的困难

Promise 只缓存一个 0 参计算。函数一旦有参数，同一参数再算一遍可能没有意义，但不同参数的结果不能共用一个盒子。递归函数若每次调用都查一张表，指数递归可以变成线性；若把 `assoc` 扫 list 的代价算进去，大约是平方。`1000²` 没事。`2^1000` 比他相信的宇宙粒子数还大。

条件：函数无 side effect，也不读会变的东西。否则同一参数不能假定同一结果。Cache 值得做，当维护和查找比重算便宜，而且调用者确实会用相同参数再调用。否则浪费空间和时间。

Memoization 不是英语单词 memorization。故意不写 r。这是技术术语。

### 2. 同一形状，不同代价

Fibonacci 的数学定义直接写成两次递归，就是低效实现。`(fibonacci 30)` 大约 832040。`(fibonacci 40)` 大约慢 1000 倍，他等不及。

另一种做法是丢掉该算法，改成 bottom-up：局部助手加累加器，从小数加到大数。代码随讲发布，本讲不讲。他只是承认这条算法存在。Memoization 不是这条算法。它保留递归形状，改变每次调用的代价。

```racket
(define fibonacci
  (letrec ([memo null]          ; (cons arg result) 的 list，客户看不见
           [f (lambda (x)
                (let ([ans (assoc x memo)])
                  (if ans
                      (cdr ans)
                      (let ([new-ans
                             (if (or (= x 1) (= x 2))
                                 1
                                 (+ (f (- x 1))
                                    (f (- x 2))))])
                        (begin
                          (set! memo (cons (cons x new-ans) memo))
                          new-ans)))))])
    f))
```

表必须放在函数外面、助手 `f` 能看见的地方，并且跨调用存活。不能放在 `f` 的 body 里：body 每次调用才执行，表会被重建，递归之间也不共享，指数爆炸还在。也不能放 top-level：那是实现细节，不想暴露，而且顶层 `set!` 不是这里要鼓励的。`letrec` 里一个 `memo`，返回 `f`。客户只拿到 `f`，说不出 `memo` 这个名字。

`(assoc key list-of-pairs)` 在 pair 的 **car** 里找与 key 相等的，返回第一个匹配的 pair；没有则 `#f`。不看 cdr。因为非 `#f` 即真，`(if ans (cdr ans) ...)` 可以直接用。

```text
(f 4)，表开始是空：

未命中。需要 (f 3) 和 (f 2)。
(f 3) 未命中，算 (f 2) 和 (f 1)，都是基线 1。
  沿途写入 (1 . 1)、(2 . 1)、(3 . 2)
然后 (f 2) 命中已经写下的 (2 . 1)
写入 (4 . 3)，返回 3

第二次递归不是另一棵指数树。
每一层从两次昂贵调用变成一次昂贵调用加一次查找。
整体从大约 2^x 变成大约 x；挑剔 assoc 的话，也许 x^2。
(fibonacci 1000) 很快，得到一个大数。
```

```text
Environment:

fibonacci → f
f 的闭包环境：
  memo → null          ; 这个绑定被 set! 改写
  f → 它自己

set! 改的是 letrec 里那个绑定的内容。
后来的顶层调用 (fibonacci 100) 看见的是同一张表，
不是函数体里新造的 null。
```

只在最外层查表、递归仍调用未 memo 的函数：缓存帮不上递归树。必须让递归调用的就是 `f`。

这和 Fibonacci 无关。先查表，没有就算，返回前写入。可以套到别的纯函数上。有副作用仍 memoize：第二次调用吞掉副作用，或返回过期结果。前提被破坏。

#### 四种“先别算 / 别再算”

| | 它推迟或记住什么 | 存在哪里 | 再要一次会怎样 |
| --- | --- | --- | --- |
| Thunk | 一段 0 参计算 | 闭包的代码 | 再算一遍 |
| Promise | 同一段 0 参计算的结果 | 一个 mcons：car 是标志，cdr 从 thunk 变成值 | 读 cdr |
| Stream（本课的定义） | 序列的尾巴 | cdr 里的 thunk | 再调用同一个 thunk 会再算下一个 pair。他没有给尾巴加 memo |
| Memo table | 一个有参数的纯函数的许多结果 | 闭包捕获的可变 list，按参数的 car 索引 | `assoc` 命中就返回 cdr |

Haskell 的默认惰性是另一件事：几乎所有构造都不急着求值，包括 `cons` 的参数。所以那里可以写 `(cons 1 ones)` 这种真正的循环绑定。不要把本课的 promise 或 stream 说成“Racket 变成了 Haskell”。这是概念类比：都在利用“函数体延迟到调用”。机制、默认值和是否记结果都不一样。

---

## Lecture — 函数收不到“还没求值的语法”

视频：`Macros: The Key Points`。`20`–`23` 是 optional。本节作业不需要宏，除非做 challenge。下一 section 会用到这个想法，所以高层次必须知道。

### 1. 先遇到的困难

有些变换必须发生在求值之前：丢掉一段语法、把表达式塞进 `lambda`、加入 `then` / `else` 这种不是值的关键字。函数做不到。调用的语义就是先求参数。你不能写一个函数，让它的参数位置上的 `(car null)` 不被求值。你也不能让调用者写 `then`，因为 `then` 不是一个表达式，函数的参数位置必须是表达式。

### 2. 核心概念

#### Macro

**Definition.** Macro definition 描述如何把一种新语法变换成源语言里的另一种语法。他喜欢想成：程序员自己加 syntactic sugar，从而扩展语言的语法。Macro system 是用来写这些定义的语言。Use site 被展开（expansion）：按定义把语法换成 desugar 后的版本。

**Intuition.** 函数在求值的世界里工作，收到的是值。宏在求值开始之前工作，收到的是语法树的一块。

**Why it exists.** 语言设计者不可能预见到每一种特殊求值规则。`if`、`andalso`、`cond` 都是特殊形式，因为它们不能是函数。宏让程序员增加 special form，而不改语言实现。

**Problem solved.** `(comment-out e1 e2)` 可以展开成只有 `e2`。`e1` 永不求值，因为展开在一切之前，而且展开结果里没有 `e1`。`(my-delay e)` 可以把 `e` 放进 `lambda`，调用者不必自己写 thunk。函数版的 `my-delay` 做不到这一点。

**Example.** 展开发生在这门课讲过的所有东西之前：在静态类型检查之前（若有），在任何求值之前。函数体里、条件分支里都展开。它是 pre-pass。

```racket
(my-if #t then 7 else 8)          ; 展开成 (if #t 7 8)，得到 7
; 关键字放错位置：bad syntax。定义不允许 else 出现在 then 的位置。

(comment-out (car null) #f)       ; 展开成 #f。没有错误。
; (car null) 单独求值会立刻出错。展开之后，求值器看不见它。

(define p (my-delay (begin (print "hi") (* 3 4))))
; 若 my-delay 是函数，print 立刻发生。
; 宏把它放进 lambda，所以现在不打印。
(my-force p)                      ; 打印 hi，返回 12
(my-force p)                      ; 12，不打印。my-force 仍是第 15 讲的函数，
                                  ; set-mcdr! 已经存了结果
```

```text
(my-delay (begin (print "hi") (* 3 4)))

Expansion，在求值之前：
  (mcons #f (lambda () (begin (print "hi") (* 3 4))))

Evaluation：
  造一个 promise。lambda 是值，body 不跑。没有打印。

第一次 my-force：
  调用 thunk，打印 hi，cdr 变成 12

第二次 my-force：
  car 为真，返回 12。print 不在这条路径上。
```

宏名声差，常常活该：滥用，或该用函数的地方用了宏。拿不准就不要定义、不要使用。但若希望 `my-delay` 的调用者写 `e` 而不是 `(lambda () e)`，必须是宏。没有函数能不求值其参数。

#### Macro vs Function

| | Function | Macro |
| --- | --- | --- |
| 定义 | 一个值。调用时按调用规则求值 | 一条重写规则。`define-syntax`，不是 `define` |
| 解决的问题 | 对值做计算，包括“以后再调用”的 thunk | 在求值前改变语法：丢弃、包裹、加入关键字 |
| 关键区别 | 参数先变成值，函数体看不见表达式 | 代入的是语法。求值次数等于展开结果里那段语法被求值的次数 |
| 典型场景 | `my-force`、`map`、`double` | `my-if`、`comment-out`、让调用者不必写 `lambda` 的 `my-delay` |

这不是“宏更强，所以都用宏”。`my-force` 应该继续是函数。下面会看到为什么。

---

## Lecture — 宏系统必须规定 token、括号和 scope

视频：optional `Tokenization, Parenthesization, and Scope`。

### 1. 先遇到的困难

若宏按字符替换，会改掉变量名的一部分。`head` 换成 `car`，`headt` 会变成 `cart`。若按无括号的文本替换，展开结果的优先级会变。若按 token 盲目替换，会改掉局部变量的绑定和引用，让不知道有这个宏的代码变错。

Macro system 必须知道 token 在哪里结束，展开结果的括号算谁的，以及局部变量能不能遮住一个宏。

### 2. 三件任何宏系统都要面对的事

**Tokens, not characters.** Token 是词，不是字母。Racket 的 `head-door` 是一个标识符，因为 `-` 可以是名字的一部分。C 和 Java 里 `-` 是减法，`head-door` 是三个 token：`head`、`-`、`door`。同一个字符序列，宏系统若不懂 token 边界，就会改写不该改的东西。

**Parentheses.** C/C++ 的 `#define ADD(x,y) x+y`，`ADD(1, 2/3)*4` 读者以为 `(1+(2/3))*4`，实际展开是 `1+2/3*4`，乘法只绑在右边。所以 C/C++ 宏定义里堆很多括号。Racket 没有这个事故：宏使用总在左括号后面，像 special form。展开后仍在那个位置。括号在这里不是难看。括号是“展开结果不会滑到运算符外面”的原因。这是概念类比，不是说 Racket 的宏和 C 预处理器是同一种机制。

**Local variables shadow macros.** 朴素地把每个 token `head` 换成 `car`：

```racket
(let ([head 0] [car 1]) head)     ; 应得到 0

; 朴素展开，不是 Racket 做的事：
(let ([car 0] [car 1]) car)
; let：同一 let 不能声明同一变量两次，非法
; let*：body 的 car 看见内层绑定，得到 1，不是 0
```

Racket 不这样做。局部变量 `head` shadow 这个宏。宏在这个 `let` 里不展开。结果是 `0`。不知道有这个宏的局部代码不会被改名。

---

## Lecture — 展开几次，就求值几次

视频：optional `Racket Macros with define-syntax`，`Variables, Macros, and Hygiene`。

### 1. 先遇到的困难

知道宏会展开还不够。要能写出规则：哪些词是关键字，哪些位置是任意表达式，展开成什么。更危险的是：展开若把同一段语法粘贴多次，那段语法就会被求值多次。宏体里若引入局部变量，朴素展开会把 use site 的同名变量捕获进去。宏体里用到的 `*` 若在 use site 被 shadow，朴素展开会用到 use site 的 `+`。

### 2. `syntax-rules`

```racket
(define-syntax my-if
  (syntax-rules (then else)
    [(my-if e1 then e2 else e3)
     (if e1 e2 e3)]))

(define-syntax comment-out
  (syntax-rules ()
    [(comment-out e1 e2)
     e2]))                    ; 不要写成 (e2)，那会去调用 e2

(define-syntax my-delay
  (syntax-rules ()
    [(my-delay e)
     (mcons #f (lambda () e))]))
```

`syntax-rules` 后面的列表是关键字。必须列出，否则系统不知道 `then` 是特殊词还是任意表达式。没有额外关键字也要写 `()`。Pattern 里的 `e1` 绑到那一段语法，template 里的 `e1` 就是那段语法。不匹配任何 case：bad syntax，错误信息知道你在用这个宏。

`(my-delay (lambda () e))` 会变成双层 thunk。宏改变了 client 的使用方式：调用者写表达式，不再写 thunk。函数版做不到不求值 `e`。好不好风格，他说 somewhat debatable。拿不准时，函数仍然是默认。

`my-force` 做成宏是错的。Template 把参数表达式复制进多个求值位置：

```racket
; 不要这样写。演示用。
(define-syntax my-force
  (syntax-rules ()
    [(my-force e)
     (if (mcar e)
         (mcdr e)
         (begin (set-mcar! e #t)
                (set-mcdr! e ((mcdr e)))
                (mcdr e)))]))
```

`(my-force (begin (print "hi") some-promise))` 在他的演示里打印了五次。五次不是一条定律，精确次数取决于哪一枝跑到、template 里有几份拷贝。要点是：超过一次，而且你很难数。函数版的 `my-force` 打印一次。调用规则已经保证参数先变成值。

用 `let` 把 `e` 绑一次，再在后面只用那个名字，行为和函数一样。那就没有理由用宏。宏的推理成本还在。

加倍这件事的好写法是函数。两个函数对客户等价：

```racket
(define (double1 x) (+ x x))
(define (double2 x) (* 2 x))
```

两个宏不等价。展开成 `(+ x x)` 会把有副作用的参数求值两次：打印两次，结果 84。展开成 `(* 2 x)` 只求值一次。既想用加法、又只想打印一次：

```racket
(define-syntax double
  (syntax-rules ()
    [(double x)
     (let ([y x])
       (+ y y))]))
```

`let` 在这里不是风格。它是控制求值次数的技术。不总是想求值一次。`my-delay` 要把表达式放进 thunk，不是求值一次。下一讲的 `for` 有意把 body 求值多次。那时不要用这个 `let` 包住 body。

参数顺序也是语义。若 `(take e1 from e2)` 展开成 `(- e2 e1)`，从左到右的求值会先算 `e2`。读文档的人会惊讶。再用 `let` 先绑 `e1` 再绑 `e2`，可以修好。字幕没给出修好的代码。`take` 这个名字是按口述重建的。

### 3. Hygiene：宏的局部变量不是调用者的局部变量

朴素语义下：

```racket
(define-syntax double-capture
  (syntax-rules ()
    [(double-capture x)
     (let ([y 1])
       (* 2 y x))]))

(let ([y 7]) (double-capture y))
; 用户期望 14。局部 y 应该是宏的实现细节。
; 朴素替换：x 换成 y，得到 (let ([y 1]) (* 2 y y)) → 2
; Racket：14
```

```text
朴素展开：

use site 想要 y → 7，再加倍。
template 把标识符 y 放进一个新的 (let ([y 1]) ...)
被乘的那个 y 是 1。参数位置的 y 也被这个绑定抓住。
(* 2 1 1) = 2

Racket 的 hygienic expansion：

宏定义里的 y 被换成另一个名字，和 use site 的 y 不是同一个变量。
参数仍是用户的 y → 7。
(* 2 1 7) = 14
```

第二件独立的事：宏定义里的自由变量按定义处查找，不按 use site。

```racket
(define-syntax double-star
  (syntax-rules ()
    [(double-star x) (* 2 x)]))

(let ([* +]) (double-star 42))
; 朴素：* 在 use site 是 +，得到 44
; Racket：* 在宏定义处是乘法，得到 84
```

这就是词法作用域（Lexical Scope）用于宏，和用于函数一样。C/C++ 预处理器不做这件事。有人把那种按使用处查找当成特性。他的判断是：绝大多数时候要 Racket 的词法 / 卫生语义。因此 C/C++ 里若必须在宏中放局部变量，会用 `__strange_name34` 这种没人会用的名字。Racket 不需要。Hygiene 不是“宏不能定义局部变量”。相反，正是 hygiene 让普通局部变量安全。

卫生宏（Hygienic Macro）的两件事：

1. 宏定义里的局部变量被悄悄换成别的名字，一致地使用，不能和 use site 冲突。
2. 宏定义里引用的外部变量按定义处的环境解析，不按 use site。

这不是把 template 文本代进去再求值。代进去之前会改名，并按定义处解析自由变量。实现比看上去难。本课不讲怎么改名。Hygiene 不是永远想要的，只是绝大多数时候想要。Racket 有办法在特定位置关掉，要去参考手册看。本课不讲。

#### 朴素替换 vs Hygiene

| | 朴素 token 替换 | Racket 的 hygienic + lexical macro |
| --- | --- | --- |
| 定义 | 把名字换成另一段文本或 token，再按使用处的环境求值 | 展开前区分宏的局部变量和用户的局部变量；自由变量在定义处绑定 |
| 解决的问题 | 能把一种写法换成另一种写法 | 让宏的实现细节不被 use site 的 shadowing 破坏，也不破坏 use site |
| 关键区别 | `(let ([y 7]) (double y))` 可以得到 2；`(* +)` 的地方使用 `(* 2 x)` 可以得到 44 | 前者 14，后者 84。局部变量重新成为实现细节 |
| 典型场景 | C/C++ 预处理器。概念类比，不是同一套算法 | `syntax-rules`。局部变量可以用普通名字 |

---

## Lecture — 一个宏里可以有两种求值政策

视频：optional `More Macro Examples`。

真正的宏往往要：有的参数求值一次，有的求值多次；同一名字多种写法；甚至递归展开，用 `let` 做出 `let*`。错误信息可能针对展开结果，而不是用户写的宏调用。递归宏写错会在程序运行前就试图生成无限大的程序。

`for` 的 template 他没有逐字读出来。下面的循环测试是按他陈述的行为重建的，标了不确定。他陈述的行为本身是清楚的：

```racket
(define (f x) (begin (print "A") x))
(define (g x) (begin (print "B") x))
(define (h x) (begin (print "C") x))

; [?] 循环条件的具体写法字幕未读出。行为是他陈述的。
(define-syntax for
  (syntax-rules (to do)
    [(for lo to hi do body)
     (let ([l lo]
           [h hi])
       (letrec ([loop (lambda (it)
                        (if (> it h)
                            #t
                            (begin
                              body
                              (loop (+ it 1)))))])
         (loop l)))]))
```

`(for 7 to 11 do (print "hi"))` 打印 5 次。他口算“11 minus 7 is 5”。11−7=4，和 5 次不一致。7 到 11 含端点正好 5 次。把算术口误丢掉，把演示结果和含端点区间留下来。

`(for (f 7) to (g 11) do (h 9))` 打印 A 一次、B 一次、C 五次。顺序是用户写的顺序。起点大于终点，C 一次也不打印。

```text
lo 和 hi：let 按书写顺序各求值一次，之后循环只用 l 和 h。
body：粘进 loop 的函数体，每次迭代求值一次。

若把 body 也放进 (let ([b body]) ...)：
  C 只打印一次。循环失去意义。
若 lo 不放进 let、直接放进循环条件：
  每次迭代都重新求值 (f 7)，A 会打印多次。

同一个宏，两种政策。
“总是用 let 把参数包一次”用在 body 上是错的。
```

`let2` 是少括号的糖，三个 case：零个绑定、一个绑定、两个绑定。`(let2 x 1 y 2 (+ x y))` 得到 3。初始值的具体数字是按“结果为 3”重建的。不匹配任何 case：`let2: bad syntax`。匹配了 case 但展开结果非法：`(let2 3 x 4 y body)` 四个项都在，第三 case 匹配，展开后 `let` 的变量位置是数字 `3`。错误是 bad let, expected an identifier。信息用展开后的语言说话，不提 `let2`。匹配了宏规则，不说明用户写对了。

`my-let*` 用递归展开把任意多个顺序绑定做成嵌套 `let`。即使底层语言没给 `let*`，也可以做成 sugar。客户不应看出展开是不是嵌套的 `let`。`...` 是 Racket 宏的重复语法。他把重复说成 one or more；pattern 把第一个绑定分开写之后，其余通常是 zero or more。数量词以参考手册为准，不要只靠这段口述。

递归宏的无限循环不是运行时死循环。它发生在 expansion，试图生成无限大的程序，程序还没跑就崩溃。递归情况必须减少还没展开的绑定。否则展开不终止。

`for` 是他喜欢出的那种作业题。本节只有 challenge 需要写宏。其余作业可以不会 `define-syntax`。但你必须能说清：为什么 `my-delay` 不能是函数，以及为什么 `my-force` 不该是宏。

---

## 用透镜看 thunk 和 macro

| 透镜 | Thunk `(lambda () e)` | Macro use site |
| --- | --- | --- |
| Syntax | 普通函数表达式 | 左括号后的新 special form |
| Semantics | 现在不求值 `e`；调用时在闭包环境里求值 | 求值开始前被换成别的语法 |
| Binding | 捕获定义时的词法环境 | 卫生宏的局部变量与 use site 分开；自由变量在定义处绑定 |
| Scope | 词法作用域。和任何闭包一样 | 局部变量可以 shadow 宏的名字 |
| Evaluation | 每次调用求值一次 body | 求值次数等于展开结果里那段语法出现在求值位置的次数 |
| Type | Racket 不在运行前拒绝。传错“pair 而不是 thunk”是运行时错误 | 不匹配 pattern 是展开期的 bad syntax，程序不运行 |
| Lifetime | 闭包可以比造它的那次调用活得更久。promise 的 mcons 也是 | 展开结束后，宏本身不留在运行时的环境里 |
| Mutation | Promise 和 memo 用 mutation 记住结果。Thunk 本身不需要 | 宏不靠 mutation 推迟求值。它靠“那段语法不在展开结果里”或“被放进 lambda” |
| Abstraction | 调用者可以不看 body。但调用者必须知道自己拿到的是 thunk 还是 pair | 客户可以不看展开。错误信息有时会看穿这层，用展开后的构造说话 |
| Composition | Stream 的 cdr 是另一个 thunk。`my-mult` 可以接收 `(lambda () (my-force p))` | `my-let*` 的展开结果里还有 `my-let*`。糖可以递归地定义 |

---

## Connection to Modern Languages

这些是概念类比，不是等价。

- JavaScript 的 `() => expr`、Java 的 lambda、Rust 的闭包，都能当 thunk 用。它们推迟求值，是因为函数体在调用前不跑。它们不是 promise：再调用会再算，除非你自己存结果。
- Rust 的 `Once`、Kotlin 的 `lazy`、Scala 的 `lazy val`，接近 promise：第一次使用才算，之后读存储。它们通常还有线程语义。本课的 `mcons` 没有。
- Haskell 的惰性是默认的求值策略，不是库。所以循环的 `ones = 1 : ones` 在那里是合法绑定。在 Racket 里同样的形状是 `ones-really-bad`。Scheme/Racket 的 `delay`/`force` 是显式编码，不是把语言改成 Haskell。
- Java `Stream`、Python 生成器、JavaScript 生成器，都是“按需产生下一个值”的生产者/消费者分离。它们通常是可变迭代器，不是“调用 thunk 得到 pair”。协议不同，分工相同。
- C 预处理器是宏的负面教材：字符/token 替换、优先级、捕获。不要因此认为“宏”都是 `#define`。Racket 的 `syntax-rules` 在卫生和词法作用域上做了预处理器不做的事。C++ 模板也不是这个宏系统。模板在类型上实例化，不改写“这段表达式求值几次”这种语法位置。
- `memoize` 装饰器在 Python 和 JavaScript 里很常见。前提仍然是：纯函数，而且重复参数真的会发生。闭包加一张可变表，就是本课的结构。

---

## Section 5（后半）Review

这一段解决的是：函数调用的求值时机不够用时，如何用零参函数推迟计算；如何用一次 mutation 把“可能重算”变成“至多算一次”；如何用同一个协议表示还没造出来的尾巴；以及为什么有些语法变换必须发生在求值之前，并且展开次数就是求值次数。

### 核心概念

thunk、`e` / `(lambda () e)` / `(e)`、promise、`my-delay` / `my-force`、stream、`number-until`、memoization、`assoc`、macro、expansion、`syntax-rules`、hygiene、求值次数。

### 必须掌握的不变量

```text
函数先求所有参数。if 不。所以 my-if 不能是函数，除非分支是 thunk。
Thunk 不是新类型。它是 0 参函数。
(e) 是调用，不是分组。
Promise 在 force 之前不算。第一次 force 之后，cdr 是结果，不是 thunk。
本课的 stream 是返回 pair 的 thunk。尾巴在调用前不存在。
递归构造 stream 时，递归必须待在还没调用的 lambda 里。
Stream（他的定义）不 memoize。Memo 表是另一张缓存，按参数索引。
宏在求值之前展开。函数做不到不求值参数。
语法被粘贴几次，就可能被求值几次。想恰好一次，用 let，或干脆用函数。
Hygiene：宏的局部变量不捕获 use site；宏的自由变量在定义处查找。
递归宏的死循环发生在展开期，程序还没跑。
```

### 能力检查

真正理解这一节，应该能：

- 解释 `factorial-bad` 为什么在参数为 0 时也不终止，并指出函数体里的 `if` 为什么没机会执行。
- 对同一个 `slow-add`，说出 thunk、预计算、promise 在乘 0 和乘 100 时各付几次代价。
- 画出第一次和第二次 `my-force` 之后 mcons 单元里 car 和 cdr 各是什么。
- 区分 `ones`、`ones-bad`、`ones-really-bad`，并说明哪一个在 Haskell 里会因为 `cons` 的求值规则而不同。
- 说明为什么 `memo` 不能放在 `f` 的函数体里，以及第二次递归调用为什么不是另一棵指数树。
- 说明 `my-delay` 必须是宏、`my-force` 不该是宏。
- 预测朴素展开下 `(let ([y 7]) (double-capture y))` 和 `(let ([* +]) (double-star 42))` 的结果，以及 Racket 的结果，并指出这两条是 hygiene 的两件独立的事。

概念题和代码题见 `exercises/section-05-delay.md`。
