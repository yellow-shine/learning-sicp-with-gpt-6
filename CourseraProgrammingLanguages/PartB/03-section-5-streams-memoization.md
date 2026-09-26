# Section 5.3 Streams 与 Memoization

标注见 `00-course-map.md`。本章覆盖 Section 5 的 16–18 讲。Thunk / promise 的前提在 `02`。

---

## 从列表到无限序列

```text
List
  问题：构造时必须把每个元素都算出来，放进有限的 cons 链
        无限长的链在 eager 语言里会在定义时就跑飞
        ↓
Delayed tail
  只放“下一个元素”和“能产生其余部分的 thunk”
        ↓
Stream
  一个 thunk。调用它得到 pair：
      car = 下一个值
      cdr = 其余元素的 stream（又是一个 thunk）
        ↓
Potentially infinite sequence
  1, 2, 3, 4, ... 不是一条已经存在的无限链
  它是一套“再要一个就再算一个”的生产者
```

**【课程】** Stream 在这里的意思是：一条无限的值序列，表现得像无限大的东西。无限的东西做不出来。能做的是：用 thunk 推迟序列的大部分，只生成某个计算真正需要的前缀。

这不是新语言构造。它是 thunk 加上 pair 的编程惯用法。力量在于分工：

| 角色 | 知道什么 | 不知道什么 |
| --- | --- | --- |
| Producer | 如何产生任意多个下一个值 | 对方到底要几个 |
| Consumer | 自己还要不要下一个 | 值是怎么来的 |

**【课程】** 这个分工在很多系统里出现。不熟悉也不影响作业，但它们说明这不是课堂玩具：

- 用户事件（鼠标、键盘）可以看成事件流。课程更早用 callback 做过类似的事；另一种组织方式是：需要下一个事件时再要，到目前为止的事件用来算出结果。别人负责在事件发生时生成它们。
- UNIX shell 的管道：后一条命令在需要时从前一条拉数据。后一条把前一条的输出看成 stream；前一条的输出在生成这个 stream。
- 带反馈的时序电路：输出线上相继出现的值可以看成无限序列；读这些线的电路只读自己关心的那些。

作业里还有更小、更好玩的例子。课程没在视频里展开作业题，这里不编造题目。

---

## 表示：`(head, thunk producing rest)` 还不够精确

讲师的表示比这句口号严一点。Stream **本身**是 thunk，不是 pair。

```text
stream = thunk
调用 stream
    → pair
         car: 这个序列的下一个值（第一个还没被消费的值）
         cdr: 另一个 stream，表示第 2 个到无穷
```

```text
powers-of-two          调用它            再调用 cdr
   [thunk]  ─────────►  (2 . [thunk])  ─────────►  (4 . [thunk])  ──► (8 . ...)
   打印成 procedure      这是 pair              这才是下一个值
```

**【课程】** 在 REPL 里输入 `powers-of-two`，得到的是 procedure，因为 stream 是 thunk。加上括号调用，得到 pair：car 是 2（这个例子从 2 开始，不是从 1），cdr 又是 procedure。

```racket
(car (powers-of-two))                 ; 2
(car ((cdr (powers-of-two))))         ; 4
(car ((cdr ((cdr (powers-of-two)))))) ; 8
```

括号的位置就是“我现在要的是 stream 还是 pair”：

```text
stream  --调用-->  pair  --car-->  值
                      |
                      +--cdr-->  stream   （先不要调用，除非你马上要下一个）
```

不会有人用手写八层 `cdr` 去取第 8 个。递归函数把“剩下的 stream”传下去，在需要时才调用。

### 消费者：`number-until`

**【课程】** 数一数，tester 第一次返回真之前，消费了多少个元素。若永远不真，这个函数自己会无限循环。那不是 stream 坏了，是消费者决定不停。

```racket
(define (number-until stream tester)
  (letrec ([f (lambda (stream ans)
                (let ([pr (stream)])          ; stream 是 thunk，调用得 pair
                  (if (tester (car pr))
                      ans
                      (f (cdr pr)             ; 把 stream 传下去，不要在这里调用
                         (+ ans 1)))))])
    (f stream 1)))
```

初始累加器是 1：第一个元素就满足时，答案是 1，不是 0。字幕里“how many stream elements you need to process before tester returns true”与代码 `ans` 从 1 开始、命中就返回，是一致的：命中的那个元素算进去。

```racket
(number-until powers-of-two (lambda (n) (= n 16)))
; 2, 4, 8, 16 → 4

(number-until powers-of-two (lambda (n) (> n 某个很大的数)))
; 讲师演示大约 339 次；数再大一个数量级，次数只增加几个
; 因为 2 的幂涨得极快。具体阈值字幕没保留，不要背 339
```

括号错误的典型症状：

```racket
; 若把 pair 而不是 stream 传给 number-until
; f 的第一件事是 (stream)，于是试图把 pair 当函数调用
; 错误类似：expected procedure, given (2 . <procedure>)
```

**【课程】** 写 stream 程序时大量错误是括号。每次传参前问：这里要的是 thunk，还是调用 thunk 之后的 pair？

### 执行 trace：直到 16

```text
f(powers-of-two, 1)
  pr = (2 . s2)
  tester(2) = #f
  f(s2, 2)
    pr = (4 . s3)
    tester(4) = #f
    f(s3, 3)
      pr = (8 . s4)
      f(s4, 4)
        pr = (16 . s5)
        tester(16) = #t
        返回 4
```

16 之后的 thunk `s5` 从未被调用。无限序列只materialize 了四个 pair。这就是“无限”在有限内存里的意思：未请求的尾巴不存在。

---

## 定义 stream：递归在 thunk 里面，不在定义的右边

**【课程】** 代码短，所以看起来比实际简单。要盯住两件事：递归在哪里，thunk 在哪里。

### 全是 1

```racket
(define ones
  (lambda ()
    (cons 1 ones)))
```

`ones` 绑定到一个 thunk。调用它，得到 pair：car 是 1，cdr 是 `ones` 自己——又是那个 thunk。这和普通递归函数“用自己定义自己”是同一件事，只是递归调用被包在“别人来调用这个 thunk 时”才发生。

```racket
(car (ones))               ; 1
(car ((cdr (ones))))       ; 1
```

等价的多余包装：`(lambda () (ones))` 当 cdr 也行，但 `ones` 已经是零参数 thunk，再包一层没有意义。

### 自然数与 2 的幂

```racket
(define nats
  (letrec ([f (lambda (x)
                (cons x
                      (lambda () (f (+ x 1)))))])
    (lambda () (f 1))))

(define powers-of-two
  (letrec ([f (lambda (x)
                (cons x
                      (lambda () (f (* x 2)))))])
    (lambda () (f 2))))
```

`f` 返回的是 **pair**，不是 stream。Stream 是外面那个 `(lambda () (f 1))`，以及 pair 的 cdr 里那个 thunk。

```text
调用 nats
  → 调用 f(1)
  → pair(1, thunk)
              └── 被调用时才 f(2) → pair(2, thunk → f(3) → ...)
```

`letrec` 是因为 `f` 的体要通过 cdr 里的 thunk 调用 `f`。把 `f` 写成局部函数只是风格：它是辅助函数，不该留在顶层。两份定义除了 `+ 1` 与 `* 2`、起点 1 与 2，是同一形状。讲师因此提到 `stream-maker`：传入组合函数和起点，`nats` 用 `+` 和 1，`powers-of-two` 用 `*` 和 2。视频把细节留在配套代码里。**【讲解】** 形状只能是“把上面的 `+` / `*` 抽象成参数”，不要把某份网上的 `stream-maker` 当成课堂原码。

### 两个必须失败的定义

理解它们为什么失败，比再背一遍 `ones` 有用。

```racket
(define ones-really-bad
  (cons 1 ones-really-bad))
```

这不是 thunk，是 pair。为了求值这个 pair，必须在绑定完成之前查找 `ones-really-bad`。Eager 语言里这是真正的环，定义时就失败。**【课程】** Haskell 里类似的写法可以工作，因为 `cons` 的参数不按 Racket 的方式先求值。Java、ML、Racket 都不行。

```racket
(define ones-bad
  (lambda ()
    (cons 1 (ones-bad))))
```

这是 thunk，递归也在函数体里，所以**定义**能成功，REPL 会告诉你它是 procedure。一旦调用，cdr 的位置是 `(ones-bad)` 的**结果**，不是 thunk。那个结果的 cdr 又是下一次调用的结果。于是它去建造一条真正无限长的列表，必须按 Stop。Stream 不是无限长的数据结构。Stream 是：你不断地调用 thunk、再取 cdr，就能再得到下一个值。

```text
ones          定义时：一个闭包
              每次调用：一个有限的 pair，尾巴仍是闭包

ones-bad      定义时：一个闭包
              第一次调用：试图把整条无限列表建完

ones-really-bad
              定义时：就要建 pair，而尾巴的变量还不存在
```

**【课程】** 作业会让你定义一个 stream，还会让你写“接受一个 stream、返回一个新 stream”的函数。视频没做第二件。难点仍是：哪里该放 thunk，哪里该调用 thunk。能用消费者测，就说明生产者写对了。

---

## Memoization：带参数时，一个格子不够

**【课程】** 这一惯用法其实不用 thunk。它仍值得放在这里，因为它解决的是同一类问题：不要重复做已经做过的纯计算。词是 memoization，不是 memorization。少一个 r，用了很久了。

前提：函数没有副作用，也不读会变的东西。那么同样的参数没有理由算第二次。7 就是 7，同一张列表就是同一张列表。

做法：留一张 cache，记住“这个参数曾经返回什么”。值得做，当且仅当：

1. 维护和使用 cache 比重算便宜；
2. 调用者确实会用同样的参数再来一次。

否则 cache 浪费空间和时间。

和 promise 的关系：promise 是零参数计算的一个格子。有参数之后，不能只存一个结果，要按参数存一张表。这就是 memoization 更复杂的地方。

### 斐波那契：指数递归，第二次调用几乎免费

数学定义直接翻译过来：

```racket
(define (fibonacci x)
  (if (or (= x 1) (= x 2))
      1
      (+ (fibonacci (- x 1))
         (fibonacci (- x 2)))))
```

**【课程】** `(fibonacci 30)` 得到一个大约 83 万的数。`(fibonacci 40)` 大约慢一千倍，讲师等不及，按了 Stop。两个递归调用造成指数爆炸：每层两支，支上再两支。

存在一个自底向上的算法，用累加器从小数加到大数。讲师承认它存在，说代码不难，但不是这一讲的重点。这里不重建那份没在字幕里给出的代码。

第三版保持原来的递归形状，只加上表。它对 1000 也很快。为什么不是“仍然两支递归，所以仍然指数”？

```text
朴素：
  fib(n) = fib(n-1) + fib(n-2)
  两支都贵，并且彼此大量重复子问题
  时间随 2^n 增长

记忆化：
  第一次递归调用把沿途结果填进表
  第二次递归调用在表里找到需要的东西
  每一层从“两次昂贵调用”变成“一次递归 + 一次命中”
  时间变成随 n 增长；若 assoc 要扫列表，也许是 n^2
  n^2 在 n = 1000 时无关痛痒
  2^1000 比讲师愿意相信的宇宙粒子数还大
```

若第二次调用的是 `x-1` 而不是 `x-2`，它可能还要再做一次递归，然后命中。只有顶层附近如此。再往下，表里已经有了。

### 表必须活在函数外面、模块私有的里面

```racket
(define fibonacci3
  (letrec ([memo null]                 ; 一开始是空表。不能放进 f 的体里
           [f (lambda (x)
                (let ([ans (assoc x memo)])
                  (if ans
                      (cdr ans)        ; 找到的是 pair，cdr 是结果
                      (let ([new-ans
                             (if (or (= x 1) (= x 2))
                                 1
                                 (+ (f (- x 1))
                                    (f (- x 2))))])
                        (set! memo (cons (cons x new-ans) memo))
                        new-ans))))])
    f))
```

三个位置，课程分别否定了两个：

| 把 `memo` 放在哪 | 为什么不行 / 行 |
| --- | --- |
| 文件顶层 | 这是实现细节，不该暴露给外面。外面不该能 `set!` 或读这张表 |
| `f` 的函数体里面 | 每次调用 `f` 都重新执行体，表被新建，记忆消失 |
| `f` 外面、`fibonacci3` 这个绑定的闭包里 | 表在各次调用之间还在。`fibonacci3` 就是 `f`，调用 `(fibonacci3 1000)` |

`assoc` 是库函数。它要求列表的元素是 pair，只看每个 pair 的 car：

```racket
(define xs (list (cons 1 2) (cons 3 4) (cons 5 6)))
(assoc 3 xs)   ; '(3 . 4)   返回整个 pair
(assoc 1 xs)   ; '(1 . 2)
(assoc 6 xs)   ; #f         6 在 cdr 里，不算找到。没有则 #f
```

因为“不是 `#f` 的都是真”，`(if ans ...)` 可以直接用 pair 当成功。表的约定是：car 是参数，cdr 是 `fibonacci` 的结果。未找到就按原算法算 `new-ans`，在返回前 `(set! memo (cons (cons x new-ans) memo))`。

这和斐波那契无关。机械的模式是：

```text
查表
  命中 → 返回记录的结果
  未命中 → 按原算法算
           返回前把 (参数, 结果) 放进表
           返回结果
```

递归调用走的是同一个 `f`，所以子问题也会先查表、再登记。记忆化因此不是只加速外部的重复调用，而是把递归内部的重复子问题也消掉。这是它能从指数变成线性的原因。只在最外层包一层 cache、内部仍调用朴素 `fibonacci`，指数爆炸还在。课程的代码让递归调用 `f`，不是调用原来的朴素函数。

### Memoization 和普通 cache

**【课程】** 它就是一张 cache。特殊之处不在数据结构，而在使用契约：

- 只对没有副作用、不读可变状态的函数有语义上的正当性。否则第二次调用本来就可能得到不同结果，表会撒谎。
- 键是参数，不是“任意你觉得贵的表达式”。零参数的那个特例已经由 promise 做过了。
- 课程的实现用 `set!` 更新局部表。和 promise 一样，mutation 藏在抽象里面。这里没有模块，所以靠不把 `memo` 放顶层来藏。
- `assoc` 扫列表使单次查找变贵。课程承认也许是 \(n^2\)，并认为对这个例子够用。它没有改用 hash table。那是“cache 的工程实现”，不是这一讲的概念。

**【扩展】** 更一般的 cache 还有容量、淘汰、失效、并发。课程的 memoization 没有这些。它假定函数纯，所以条目永不失效；它也不限制表的大小。表会和 `fibonacci3` 的闭包一样活着，已经算过的参数一直占内存。这是空间上的天花板。若参数域很大且很少重复，这张无限增长的表不值得存在——课程自己把“没有人重复调用”列为不该做 cache 的条件。

---

## 和别的“序列”不是一回事

**【扩展】** 课程没有比较 Python generator、Java Stream、Kotlin Sequence、C++ ranges、Rust Iterator。下面只为了防止名词碰撞。不要把它们写进“课程证明了它们相同”。

| | 本课的 stream | 常见的 iterator / generator |
| --- | --- | --- |
| 课程定义 | thunk，调用得 `(值, 下一个 stream)` | 通常是有内部游标的对象，或协程 |
| 无限 | 可以。尾巴没被调用就不存在 | 也可以懒，但是否无限取决于那个库 |
| 重用 | 同一个 stream 值可以再调用，又从它的下一个元素开始；旧的 pair 若还留着，可以从那里再走 | 很多 iterator 是一次性的，推进后回不去 |
| 记忆 | 本课的 stream **没有**把已经产生的元素缓存进 stream 本身。再走同一条尾巴会再调用生产者 | 有的库缓存，有的不缓存 |
| 副作用 | 课程例子是纯的。若生产者有副作用，每次调用 thunk 都会再发生 | generator 常常靠副作用推进 |

Java 的 `Stream` 尤其不是这个结构：它是流水线对象，通常不能重复遍历，也不是 `(head, thunk)`。名字相同不是语义相同。

Haskell 的惰性列表更接近：`cons` 的尾巴默认不求值，所以课程说 `ones-really-bad` 那种环在 Haskell 里可以是合法的无限列表。即便如此，Haskell 列表是语言规则，不是你手写的 thunk 约定。

---

## 逐讲笔记

### 16 Using Streams

1. **问题：** 怎样使用一条“看起来无限”的序列，而不把它造出来？
2. **动机：** 生产者和消费者对“要多少个”的知识是分开的。Callback、管道、电路都是这种分工；作业需要你先会消费。
3. **概念：** stream = 特定形状的 thunk；pair 的 car 是下一个值，cdr 是下一个 stream。
4. **机制：** 调用 thunk 得 pair；要把 stream 传给递归时传 cdr，不要先调用。
5. **代码：** `number-until`。`powers-of-two` 的来源在下一讲，这一讲假定已经定义。
6. **执行：** 调用前是 procedure。`(car (powers-of-two))` 是 2，下一层是 4，再下一层是 8。直到 16 用了 4 步。更大的阈值只多几步。
7. **PL：** 无限是接口上的错觉，由“未请求的计算不存在”支撑。消费者用递归表达“还要下一个”，不需要知道生产者的公式。
8. **误区：** Stream 是 list。Stream 是 pair。多一层括号只是风格问题。`number-until` 在 tester 永不成立时会优雅地停（不会，它会一直要下一个）。
9. **联系：** Thunk 的 `(e)` 就是调用。`cons` 做 pair，这里的 pair 故意不是 proper list：cdr 是过程，不是 `null` 结尾的列表。
10. **一句：** 使用 stream 就是：调用 thunk，取 car，把 cdr 那个 thunk 留给下一次。

### 17 Defining Streams

1. **问题：** 生产者如何写出“再要一个才有下一个”，而不是一条无限列表？
2. **动机：** 先会用再会写，是为了知道目标形状。写的时候代码短，容易把递归放错层。
3. **概念：** 递归可以指向 stream 自己；辅助函数返回 pair，cdr 里才是下一层递归；eager 不允许定义时的环。
4. **机制：** `ones` 的 cdr 就是 `ones`。`nats` 的 cdr 是 `(lambda () (f (+ x 1)))`。`ones-bad` 把调用结果放进 cdr。
5. **代码：** `ones`、`nats`、`powers-of-two`；两个坏定义。`stream-maker` 只保留想法。
6. **执行：** `(car (ones))` 和再下一层都是 1。`ones-bad` 作为值是 procedure，一调用就停不下来。`ones-really-bad` 在定义时失败。
7. **PL：** 在 eager 语言里，无限数据结构的递归必须藏在函数体里，因为函数体推迟求值。Haskell 把这个推迟放进数据构造器，所以表面的环可以不是环。这是求值策略的差别，不是“Haskell 能分配无限内存”。
8. **误区：** 递归出现在定义右边就自动是 stream。Thunk 的体里立刻调用自己，等价于正确的 `ones`。Stream 会在内存里慢慢变成一条无限列表（只有你自己把每个 pair 都留着并不断调用，才会越存越多；表示本身不这么做）。
9. **联系：** `letrec` 用于局部递归函数。上一章的 promise 不适合直接当 stream 的尾巴：尾巴不是“同一个零参数计算”，而是“下一个不同的计算”。
10. **一句：** Stream 的递归藏在尚未调用的 thunk 里；一调用就得到有限的下一个 pair。

### 18 Memoization

1. **问题：** 纯函数对同一参数被调用多次时，如何不做重复计算？递归里的指数重复如何被同一技巧消掉？
2. **动机：** Promise 只覆盖零参数。斐波那契说明：表 + 让递归走同一入口，可以把 \(2^n\) 变成大约 \(n\) 或 \(n^2\)。
3. **概念：** cache；`assoc`；表必须跨调用存活，又不能放顶层；`set!`。
4. **机制：** 查 pair 的 car；命中返回 cdr；未命中则计算、cons 上新 pair、返回。
5. **代码：** 朴素 `fibonacci` 与 `fibonacci3`。自底向上版本只被提及。
6. **执行：** 朴素 30 约 83 万，40 慢约一千倍。`fibonacci3` 对 1000 立刻给出大数。
7. **PL：** 时间复杂度有时不是算法形状的表面问题，而是重复子问题有没有被共享。共享用一块局部可变状态实现，外部仍可把函数当成纯的——前提是你真的没有副作用。
8. **误区：** 拼成 memorization。把表放进 `f` 体内“更局部”。只缓存最外层、内部调用朴素版本，还指望指数消失。对有副作用的函数做 memoization，认为这只是优化。
9. **联系：** Promise 是零参数特例。`set!` 的危险被限制在无人能命名的 `memo` 上。`assoc` 返回 `#f` 或 pair，配合“只有 `#f` 为假”。
10. **一句：** 纯函数的重复调用可以改查表；递归要快，递归调用必须走这张表。

---

## 本范围小结

### 核心问题

有限的列表要求元素事先存在。无限序列只能作为“再要一个”的过程存在。重复的纯计算则不该依赖调用者记得不去重算；表可以替他记得。

### 知识地图

```text
Thunk
  ├── Promise：一个表达式，最多算一次（上一章）
  ├── Stream：thunk → (值, 下一个 thunk)
  │     生产者不知道要几个
  │     消费者不知道怎么产生
  └── Memoization：不靠 thunk
        参数 → 结果 的表
        递归入口必须是带表的那个函数
```

### 最重要的代码模式

```racket
(define ones (lambda () (cons 1 ones)))

(define (number-until stream tester)
  (letrec ([f (lambda (stream ans)
                (let ([pr (stream)])
                  (if (tester (car pr))
                      ans
                      (f (cdr pr) (+ ans 1)))))])
    (f stream 1)))

; 命中 (assoc x memo) 则 (cdr ans)，否则计算后 set! 再返回
```

### 容易混淆

| 混淆 | 分辨 |
| --- | --- |
| Stream 与 list | List 的尾巴是 list 或 `null`。Stream 的“尾巴”在被调用前是 thunk |
| Stream 与 pair | 调用 stream 才得到 pair。把 pair 传给期望 stream 的函数会立刻炸 |
| Stream 与 promise | Promise 记住一个结果。本课的 stream 不记住已经走过的元素 |
| `ones` 与 `ones-bad` | 前者 cdr 是 thunk；后者 cdr 是调用 thunk 的结果，于是无限循环 |
| Memoization 与“我在外面 cache 一下” | 子问题要快，内部递归必须查同一张表 |

### 和上一范围的关系

Stream 使用 thunk 的“先别调用”，不使用 promise 的“算完覆盖”。Memoization 使用 promise 的“记住结果”，但键是参数，结构是表，而且通常不把原计算包成 thunk：未命中时当场算。三样东西共享动机（别做不需要的或已经做过的工作），不共享表示。

### 为下一范围准备了什么

函数改不了调用者那边的求值。`my-delay` 因此要求调用者自己写 `(lambda () e)`。下一范围的 macro 能在展开期把 `e` 放进 `lambda`，让调用者写起来像特殊形式。Stream 本身不用 macro；macro 解决的是另一类“函数进门太晚”的问题。

---

## Engineering Connection

**【课程】** 事件序列可以替代一部分 callback 组织方式。UNIX 管道是拉模式的 stream：消费者决定要多少。电路的输出序列是同一抽象的硬件版本。这些是类比，不是说 shell 的实现就是 `(lambda () (cons v thunk))`。

**【扩展】**

- Python generator 用 `yield` 把“下一个值”写成看起来像过程的代码，运行时有一个挂起的帧。那是协程，不是本课这个纯数据结构。可以用来实现类似的生产者，语义工具不同。
- 数据库执行计划里的 iterator 也是“再要一行再算一行”。它通常有副作用（读页、推进游标），并且是一次性的。
- 前端的事件流库（名字里常有 Observable / Stream）加上了订阅、退订、错误、结束。本课的 stream 没有“结束”：它是无限的。有限序列在本课仍用 list。
- 编译器里对纯函数的 memoization 与本讲是同一契约。缓存 HTTP 响应不是：响应会过期，而且读取不是纯计算。

---

## 检查题

1. 为什么 stream 可以表示 `1, 2, 3, ...`，而一条 Racket list 不行？
2. 写出 stream 被调用一次之后，pair 的两个字段分别是什么。cdr 应该传给谁，什么时候才调用它？
3. `(car ((cdr (powers-of-two))))` 里每一层括号在做什么？少一层会发生什么？
4. `number-until` 的累加器为什么从 1 开始？tester 第一次就真，返回值是多少？
5. `ones-really-bad` 在定义时失败，`ones-bad` 在调用时失败。两句代码的差别是什么？
6. 为什么 Haskell 能接受类似 `ones-really-bad` 的定义，而 Racket 不能？这是否表示 Haskell 分配了无限内存？
7. 作业若要求“函数接受 stream 返回 stream”，你至少要决定哪两处放 thunk、哪一处调用 thunk？
8. 为什么 `memo` 不能放在 `f` 体内，也不能放在文件顶层？
9. 若 `fibonacci3` 的递归分支调用的是朴素 `fibonacci` 而不是 `f`，1000 还会快吗？为什么？
10. Memoization 对有 `printf` 或读取 `set!` 过的顶层变量的函数，会破坏什么？

## Answers

1. List 的每个 `cons` 在被求值时都要先算出 car 和 cdr。无限多个 `cons` 停不下来。Stream 每次只物化一个 pair，尾巴是未被调用的 thunk，所以未请求的元素不占用构造。
2. car 是下一个值。cdr 是表示其余元素的 stream，也就是 thunk。把它传给下一次递归或下一次消费；只有当那次消费需要 pair 时才调用。
3. 最外层 `car` 取 pair 的值。中间 `(cdr ...)` 从第一次调用得到的 pair 里取出下一个 stream。最内层 `(powers-of-two)` 把 thunk 调用成 pair。少掉调用那层，就会对 procedure 做 `cdr`，或把 pair 当函数调用。
4. 因为它数的是“直到并包括第一次为真的那个元素”。第一下就真，处理了 1 个元素，返回 1。
5. `ones-really-bad` 的定义式是 `cons`，求值定义就要查找尚未绑定完的自己。`ones-bad` 的定义式是 `lambda`，定义时不跑体；体里的 `(ones-bad)` 在调用时才跑，并且把跑出来的 pair 放进 cdr，于是要建无限列表。
6. 因为 Haskell 的数据构造不先求值参数，尾巴可以先不看，定义时的环不是立刻的查找。它仍然只在你请求下一个元素时才计算。不是无限内存。
7. 返回的新 stream 必须是 thunk（或等价地，调用你的函数得到 thunk）。这个 thunk 被调用时，通常要调用输入 stream 得到 pair，取出 car 做变换，cdr 里再放一个 thunk，那个 thunk 以后才对输入的剩余 stream 递归。具体作业函数可能更多，但这两处是课程强调的形状。
8. 体内：每次调用都新建空表，记忆消失。顶层：表成了公开的实现细节，谁都能改。正确位置是和 `f` 一起被闭包包住、但在 `f` 的形参和体之外。
9. 不会。昂贵的重复发生在递归内部。外层表只能记住完整的 `(fibonacci3 n)`，内部若仍走朴素函数，`fib(n-1)` 和 `fib(n-2)` 的指数树还在。
10. 会把第一次的副作用和第一次读到的可变状态冻结成“以后所有调用的结果”。调用次数变了，打印变少，后来的 `set!` 被忽略。课程的正当性前提是没有副作用、不读会变的东西。
