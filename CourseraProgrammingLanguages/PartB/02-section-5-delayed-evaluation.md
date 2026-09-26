# Section 5.2 延迟求值：Thunk 与 Promise

标注见 `00-course-map.md`。本章覆盖 Section 5 的 13–15 讲。Stream 和 memoization 在 `03`。Macro 如何不用函数就推迟求值，在 `04`。

---

## 问题链

```text
函数调用：参数在进入函数体之前各算一次     （eager / strict）
条件表达式：未选中的分支永远不算
        ↓
若有人把 if 包成普通函数，两个分支都会先算完
        ↓
递归的停机依赖“不算另一支”
        ↓
把“以后才需要的表达式”放进零参数函数
        ↓
Thunk：现在不算，调用时才算，每次调用都重算
        ↓
不算：省了可能用不到的工作
重算：用很多次时比事先算好更差
        ↓
可变 pair 记住“算过没有”和“答案”
        ↓
Promise：第一次 force 才算，之后 force 只读缓存
        ↓
讲师称之为 lazy evaluation 的一种手写实现
Haskell 是“函数参数默认这么干”的语言；Racket 不是
```

**【课程】** 每种语言构造的语义都必须说明：子表达式是否求值、何时求值、求值几次。这不是优化注解，是写对程序的前提。

---

## Eager 与条件：两套规则，缺一不可

**【课程】** ML 和 Racket，以及你可能熟悉的大多数语言，函数调用是：

```text
求值 e0 得到函数
求值 e1 ... en，每个恰好一次
然后求值函数体；体通过参数名查找已经算好的结果
```

条件不是这样：

```text
(if e1 e2 e3)
只求值 e1
再只求值 e2 或 e3 中的一个
另一个永远不求值
```

阶乘能停，是因为第二条，不是因为递归这个词有魔法。

```racket
(define (factorial-normal x)
  (if (= x 0)
      1
      (* x (factorial-normal (- x 1)))))
```

`(factorial-normal 5)` → 120。`(factorial-normal 500)` 也能给出巨大的精确整数。Racket 不在这里溢出截断。trace 的关键步不是乘法，是分支：

```text
factorial-normal(500)
  先求值参数 500（已经是值）
  进入体
  求值 (= 500 0) → #f
  因此不求值 1
  只求值 (* 500 (factorial-normal 499))
      其中递归调用重复同一决定
  直到 x = 0，只求值 1，不求值乘法
```

### 把 if 包成函数，停机就没了

```racket
(define (my-if-bad e1 e2 e3)
  (if e1 e2 e3))

(define (factorial-bad x)
  (my-if-bad (= x 0)
             1
             (* x (factorial-bad (- x 1)))))
```

**【课程】** 对任何参数，包括 0、5、500、负数，`factorial-bad` 都不终止。讲师建议你自己试，录像里不跑它。

原因与 `if` 的好坏无关，与调用约定有关：

```text
进入 factorial-bad 的体
  必须先调用 my-if-bad
  调用前三个参数都求值
    (= x 0)     很快
    1           很快
    (* x (factorial-bad (- x 1)))
        这个递归又要先算它自己的第三个参数
        永远走不到 my-if-bad 体内的 if
```

`if` 是特殊形式，才能“不算另一支”。函数做不到，因为函数的语义就是参数先求值。这是后面 macro 存在的理由之一：有些构造的意义就是控制求值，而函数已经把求值做完了才进门。

---

## Thunk：把“现在算”改成“以后算”

### 定义

**【课程】** 零参数函数，若用途是推迟求值，就叫 thunk。词源没有公认说法，是计算机科学里的一个怪词。也可以当动词：thunk that expression。函数需要一个 thunk，就是它要的不是结果，而是“能产生结果的零参数函数”。

为什么通常是零参数，而不是“把表达式存进某种新数据”？**【讲解】** 因为语言已经有闭包。把表达式放进函数体，求值 `lambda` 只创建闭包，不跑体。调用时才跑。不需要新的语言构造。这也是讲师强调 “we don't need any new language constructs” 的同一杠杆，stream 那讲会再说一次。

```racket
; 三个看起来像、语义完全不同的东西。作业会在这里栽跟头。

e                    ; 求值 e，得到结果。例：(+ 3 4) → 7

(lambda () e)        ; 一个函数。完全不求值 e。
                     ; 每次调用它，才求值 e，得到结果。
                     ; (lambda () (+ 3 4)) 是过程；调用才得 7

(e)                  ; 求值 e，得到的必须是 thunk，再调用它。
                     ; 最终结果是 thunk 体的结果。
                     ; (37) 报错：37 不是 thunk。
                     ; ((lambda () 37)) → 37
```

闭包使这件事在任何位置都能做：自由变量在创建 thunk 时按词法被记住，调用时还在。所以“推迟”不要求表达式是闭合的常量。

### 一个能工作的 my-if

**【课程】** 这不是好风格。内置 `if` 才是该用的。它的作用是引出惯用法。

调用者不要传入 `e2`、`e3` 的结果，而要传入“若被调用就产生结果”的 thunk。函数自己决定调用哪一个，另一个的体永不执行。

```racket
(define (my-if-strange-but-works e1 e2 e3)
  (if e1
      (e2)      ; e2 是 thunk
      (e3)))

(define (factorial-okay x)
  (my-if-strange-but-works
   (= x 0)
   (lambda () 1)
   (lambda () (* x (factorial-okay (- x 1))))))
```

三个参数都很快：比较很快；两个 `lambda` 已经是值，只建闭包。然后 `my-if-strange-but-works` 只调用其中一个。`(factorial-okay 500)` 给出同一个大数。

```text
创建 thunk：现在不算
调用 thunk：那时才算
不调用：永远不算
```

### 和邻近概念的边界

| 概念 | 课程里有没有 | 关系 |
| --- | --- | --- |
| Closure | 有，Part A 就有 | Thunk 是闭包的一种用法：代码 + 定义时环境，参数列表为空 |
| Lazy evaluation | 有，下一讲 | 讲师用这个词称呼“需要时才算，并且记住”的整套做法，以及 Haskell 那种语言。Thunk 本身每次调用都重算，还不是那套 |
| Callback | 课程在 stream 讲会提到更早的 callback | 都是“以后调用的函数”。Callback 通常携带事件信息，参数不为零；thunk 的重点是推迟一个已经写好的表达式。**【讲解】** 相似在“控制何时跑”，不同在传什么 |
| Promise | 下一讲的术语 | `my-delay` 的返回值。里面可以有一个 thunk，但 promise 还带“算过没有” |
| Future | **【扩展】** 课程没讲 | 常指可能在别处并发算出的值。Thunk 不隐含线程。不要把 thunk 理解成异步任务 |

**【扩展】Call-by-name。** 课程没有使用这个术语。若一门语言的参数传递是：每次在函数体里用到参数，都重新求值原来的实参表达式，效果接近“调用者传入 thunk，函数体每次使用都调用它”。`my-if-strange-but-works` 和下面会失败的“每次都调用 thunk 的乘法”就是这个形状。正式名字不是课程内容。

---

## 不算 vs 重算：thunk 的收支

**【课程】** 若分支根本不会用到结果，传入 thunk、在用到时才调用，就省下了昂贵计算。骨架：

```text
(define (f th)
  (if (不需要 th 的情况)
      便宜的答案
      ... (th) ...))
```

对比：调用前就把昂贵计算做完，再把结果传进来。不用的那次分支白付了钱。

反过来，若好几个独立的条件都可能需要**同一个**结果，而你不知道有几个会需要：

- 事先算：一次都不用时浪费；用多次时正确且只算一次。
- 每次需要都调用同一个 thunk：一次都不用时最优；用多次时重复付费，可能比事先算更差。

这是权衡，不是 thunk 的道德优势。最好的两边：表达式没有副作用、何时算不影响结果；不需要就不算；需要了就记住，以后不再算。

### 具体的慢乘法

配套语义，按讲师描述重建。`slow-add` 的循环体字幕没逐行给出，只要求它慢到能看出来。下面用一个忙等表示“慢”，不是课程原码：

```racket
; 【讲解】慢只是为了让 REPL 里能看出秒数。课程原码“加了足够多的额外代码”。
(define (slow-add x y)
  (letrec ([waste (lambda (n)
                    (if (= n 0) 0 (waste (- n 1))))])
    (waste 20000000)
    (+ x y)))

(define (my-mult x y-thunk)
  (cond [(= x 0) 0]                          ; 完全不调用 thunk
        [(= x 1) (y-thunk)]
        [#t (+ (y-thunk)
               (my-mult (- x 1) y-thunk))])) ; 传入 thunk 本身，不是结果
```

观察，全部是课程结论：

| 调用 | 发生了什么 |
| --- | --- |
| `(slow-add 3 4)` | 约一秒，得到 7 |
| `(my-mult 0 (lambda () (slow-add 3 4)))` | 很快。thunk 从未调用 |
| 乘 1 | 必须算一次 3+4，无法再省 |
| 乘 2 | 约两倍时间。thunk 被调用两次 |
| 乘 20 | 不可接受。净亏损 |

事先算好的版本，用 `let` 把结果放进变量，thunk 只做查找：

```racket
(let ([x (slow-add 3 4)])
  (my-mult 0 (lambda () x)))
```

乘 0、2、20 都只慢那一下，因为 `slow-add` 在调用 `my-mult` 之前已经做完。代价：乘 0 也不再快。你放弃了“用不到就不算”。

**【课程】** 这就是引入 lazy evaluation 的动机。若大多数构造、事实上所有函数都这样工作，那种语言叫 lazy language。今天最著名、最成功的例子是 Haskell。Racket 的函数参数仍在调用处求值，和 ML 一样，**不是** lazy language。但可以用已有材料自己写出来。标准库有 `delay` / `force`，语法略有不同；课程选择自己实现，以便看见机制，然后再回到这个乘法例子。

材料只有两样，都已经学过：thunk，和 mutable pair。

---

## delay / force：Promise 是带记忆的 thunk

### 实现

名字加 `my-`，以免遮蔽标准库。**【课程】** 返回的东西叫 promise：你需要时可以强迫它交出来。

```racket
(define (my-delay th)
  (mcons #f th))                 ; 没有 (th)。thunk 没被调用

(define (my-force p)
  (if (mcar p)
      (mcdr p)                   ; 已经算过：cdr 里是结果
      (begin
        (set-mcar! p #t)         ; 先标记，保证不会算第二次
        (set-mcdr! p ((mcdr p))) ; (mcdr p) 取出 thunk，再加一层括号调用它
        (mcdr p))))              ; 此时 cdr 已是结果
```

这是一个小的 one-of 类型，只是用手写标签而不是 ML datatype：

```text
promise = mcons
  car: #f  → 还没算，cdr 是 thunk
  car: #t  → 算过了，cdr 是结果，thunk 已被覆盖，不再保留
```

理想情况是把它藏进模块，做成抽象数据类型。课程这时还没讲 Racket 模块的写法，所以函数就这样裸着。不要依赖“我知道 car 是布尔”之外的表示。

### 第一次 force 和第二次 force

| | 第一次 `my-force` | 第二次及以后 |
| --- | --- | --- |
| `mcar` | `#f` | `#t` |
| 做什么 | 把 car 改成 `#t`，调用 thunk，把结果写进 cdr，返回结果 | 不调用 thunk（thunk 已经不在了），返回 cdr |
| 副作用 | thunk 体里的打印、赋值会发生 | 不再发生 |
| 若 thunk 很慢 | 付出一次 | 只是读一个字段 |

**【讲解】** 因此 “force 两次是否相同” 要拆开说：

- 结果值：若 thunk 没有副作用、不读可变状态，两次返回的值相同。
- 计算：第二次不做。这是和裸 thunk 的差别。裸 thunk 每次 `(th)` 都重跑体。
- 副作用：第一次有，第二次没有。所以 promise **不**等价于“把表达式多写一次”。有打印的表达式会被改变观察行为。讲师在 macro 讲还会用这个事实。

### 用法

函数若可能需要、可能多次需要某计算，参数应该是 promise，不是裸 thunk，也不是已经算好的值。用到的每个地方写 `my-force`。

```racket
; 调用者
(f (my-delay (lambda () expensive)))

; f 的体内，每个需要结果的地方
(my-force p)
```

### 乘法例子的第三种调用方式

`my-mult` 仍期望第二个参数是 thunk（上一讲写的，没改）。promise 外面再包一层 thunk，thunk 的体去做 `force`。多次调用这个 thunk，就是多次 `force` 同一个 promise。

```racket
(define p (my-delay (lambda () (slow-add 3 4))))
(define th (lambda () (my-force p)))

(my-mult 0 th)     ; 很快。从未 force，从未 slow-add
(my-mult 1 th)     ; 约一秒，得到 7。force 一次
(my-mult 100 th)   ; 仍然约一秒，不是 100 秒。
                   ; 第一次 force 把 7 写进 promise，其余 99 次只读 cdr
```

字幕里的 `107` 是口误，后面明确说乘以 100：第一次慢加，其余 99 次查找。

### 三种调用，一张表

**【课程】** 这是两讲合在一起的结论。

| 方式 | 乘 0 | 乘 1 | 乘大于 1 |
| --- | --- | --- | --- |
| 传入 `(lambda () (slow-add 3 4))` | 最好，完全不算 | 算一次，无法再好 | 最差，算很多次 |
| 事先 `let` 绑定结果，thunk 只查找 | 仍付一次，不该付 | 算一次 | 只算一次，好 |
| promise：thunk 里 `force` | 最好，不算 | 算一次 | 只算一次，好 |

Promise 拿到了前两行各自的优点。使用的材料是 mutation + thunking。Mutation 写在 promise 内部，调用 `my-mult` 的人看不见 `set-mcar!`。这是上一章所说“受控的局部状态”，不是顶层 `set!`。

### Promise、Thunk、Memoized computation

| | Thunk | Promise（本讲） | Memoization（下一章） |
| --- | --- | --- | --- |
| 推迟什么 | 一个表达式 | 一个表达式，且记住结果 | 一个**带参数**的函数的各次结果 |
| 存储 | 不存储结果 | 一个格子：未算 / 结果 | 一张表：参数 → 结果 |
| 第二次 | 重算 | 命中格子 | 查表命中才跳过；不同参数仍要算 |
| 课程用的词 | thunk | promise，`my-delay` / `my-force` | memoization，明确说不是英语单词，拼写不带 r |

**【扩展】Call-by-need。** 课程把“不需要就不算，需要了就记住、以后不再算”叫做 lazy evaluation，并指出 Haskell 的函数就是这样。它没有使用 call-by-need 这个名字。Call-by-need 就是 call-by-name 加上 memoization：实参表达式最多求值一次，后续使用共享结果。本讲的 promise 是这个策略的手写版，但是**显式**的：调用者要写 `my-delay`，使用处要写 `my-force`。Haskell 把这件事放进语言的函数调用规则里，程序员不在每个参数上动手写。Racket 标准库的 `delay` / `force` 是语言提供的同类库，课程说语法略有不同，选择不依赖它，以便看见 `mcons`。

**【扩展】** JavaScript 的 `Promise`、Java 的 `CompletableFuture` 名字相近，语义不同：它们通常表示可能失败、可能在别的线程完成的异步计算，不是“纯表达式的按需求值 + 记忆”。不要用本讲的 promise 去理解 async/await。

---

## 逐讲笔记

### 13 Delayed Evaluation and Thunks

1. **问题：** 语言语义里，子表达式何时被求值？为什么这决定递归能不能停？
2. **动机：** 后面的惯用法全部依赖“可以不算”。不先把 eager 和条件的差别说死，那些惯用法像魔法。
3. **概念：** 函数参数先求值、恰好一次；`if` 只算一支；thunk；三个易混写法 `e` / `(lambda () e)` / `(e)`。
4. **机制：** `my-if-bad` 在进 `if` 之前把递归参数算完。`my-if-strange-but-works` 只对选中的 thunk 加括号调用。
5. **代码：** `factorial-normal`、`factorial-bad`、`factorial-okay`。
6. **执行：** normal 与 okay 对 500 给出大整数。bad 对任何输入不终止。`(37)` 报错；`((lambda () 37))` 得 37。
7. **PL：** 求值时机是构造的语义的一部分。函数无法模拟 `if`，因为函数的语义已经把参数求值掉了。特殊形式（以及后面的 macro）存在，就是为了表达函数表达不了的求值规则。
8. **误区：** 零参数函数没有意义。Thunk 是线程。`(lambda () e)` 会立刻算 `e`。把 `if` 包一层函数语义不变。
9. **联系：** 上一章：`lambda` 不求值体；`if` 不是函数；闭包记住定义环境，所以 thunk 可以引用自由变量。
10. **一句：** 不想现在算，就放进零参数函数，并且先不要调用它。

### 14 Avoiding Unnecessary Computations

1. **问题：** 推迟计算什么时候赚，什么时候亏？
2. **动机：** 只用 thunk，会在“需要多次”时比 eager 更慢。必须看见这个亏损，promise 才不是装饰。
3. **概念：** 可能不用 vs 可能用多次；事先算；lazy evaluation；Haskell；Racket 仍然 eager。
4. **机制：** `my-mult` 在 `x = 0` 时不调用 thunk；否则每层调用一次，并把它原样传给递归。
5. **代码：** `slow-add`、`my-mult`，以及 `let` 预先绑定再包 thunk。
6. **执行：** 乘 0 用 thunk 很快；乘 2 约两倍慢；预先算则 0、2、20 一样慢。
7. **PL：** “懒”不是一种道德，是一条求值规则加上一条记忆规则。语言可以选择让所有函数参数服从它（Haskell），也可以让程序员在需要的地方手写（Racket）。
8. **误区：** Thunk 总是更快。Racket 的函数参数是 lazy 的。Lazy language 意味着“程序更慢”或“程序总是更快”——课程只说那是另一种求值规则，并用乘法例子显示两种极端都可能输。
9. **联系：** 上一讲的 thunk。下一讲用 `mcons` 补上记忆。Memoization 讲会说 promise 是零参数情形的特例。
10. **一句：** 不算是赚；重算多次是亏；要两边都要，就得记住第一次的答案。

### 15 Delay and Force

1. **问题：** 怎样实现“不需要就不算，需要了就只算一次”？
2. **动机：** 标准库有 `delay` / `force`，但看实现才能知道 mutation 放在哪里，以及第二次 force 为什么不再有副作用。
3. **概念：** `my-delay`、`my-force`、promise、one-of 标签、`begin`。
4. **机制：** `#f` + thunk；第一次 force 改成 `#t` + 结果；以后只读。
5. **代码：** 上面的 `my-delay` / `my-force`，以及包一层 `(lambda () (my-force p))` 去喂 `my-mult`。
6. **执行：** 乘 0 很快；乘 1 慢一次得 7；乘 100 仍然只慢一次。
7. **PL：** 一小块受控的可变状态，可以在外部恢复“这个计算只有一个结果”的推理。抽象的边界应该把 `set-mcar!` 藏起来。课程没讲模块，所以边界只存在于约定。
8. **误区：** Promise 和 thunk 是同一个东西。第二次 force 会再打印。`my-delay` 会立刻调用传入的 thunk（不会，没有那层括号）。把 promise 直接传给期望 thunk 的 `my-mult`。
9. **联系：** `mcons` 与 `set-mcar!` / `set-mcdr!`；`begin`；函数体推迟求值。Stream 不用这套记忆，它用 thunk 推迟**序列的尾部**。Memoization 把“一个格子”推广成“一张表”。
10. **一句：** Promise 是会把自己从 thunk 改写成结果的可变 pair；force 是这个改写的唯一入口。

---

## 本范围小结

### 核心问题

计算不必在它被写下来的地方发生。语言必须规定每种子表达式何时、是否、几次被求值。函数规定“先算、算一次”；条件规定“只算一支”。Thunk 把任意表达式放进第二种世界。Promise 再补上“算过就别再算”。

### 知识地图

```text
Eager 函数调用
    │
    ├── 问题：不用的参数也付费；包出来的 if 会把两支都算掉
    │
    ▼
Thunk = (lambda () e)     每次调用都算
    │
    ├── 不用：赚
    └── 用多次：亏
         │
         ▼
Promise = (mcons #f thunk)
    │  my-force：第一次算并覆盖，之后读
    ▼
讲师所说的 lazy evaluation（显式、局部）
    │
    └── 【扩展】call-by-need = call-by-name + 记忆
        Haskell 把它做成默认的函数参数规则
```

### 最重要的代码模式

```racket
(lambda () e)                 ; 推迟
(th)                          ; 强迫一个 thunk
(define p (my-delay th))      ; 推迟并准备记忆
(my-force p)                  ; 最多算一次
```

### 容易混淆

| 混淆 | 分辨 |
| --- | --- |
| Thunk 与线程 | 没有并发。只是零参数闭包 |
| Thunk 与 promise | Promise 有记忆；thunk 没有 |
| 第一次 force 与第二次 | 值可相同，副作用和耗时不同 |
| Racket 与 Haskell | 两者都可以写无限结构和按需计算；Racket 要你显式 thunk，Haskell 的函数参数默认不先算 |
| `delay` 库函数与 `my-delay` | 课程故意自己写。库的语法略有不同，不要混着背 |

### 和上一范围的关系

用了：函数体不立即求值、闭包、`if` 的特殊求值、`mcons`、`set-mcar!`、`begin`、词法作用域。没有用新的语言构造。这是课程反复强调的一点：强大的惯用法可以只是旧语义的组合。

### 为下一范围准备了什么

Stream 需要“尾巴先别算”，否则无限序列会在定义时就跑飞。它用的是 thunk，不是 promise——尾巴的计算依赖于你要第几个元素，不是一个零参数表达式算一次就结束。Memoization 则处理“同一个函数、不同参数”的重复计算，表比一个格子大。

---

## Engineering Connection

**【课程】** Haskell 是把 lazy evaluation 放进函数调用规则的语言。Racket / ML / Java 不是。数据库或交互系统里“先别把全部数据算出来”的想法，课程放到 stream 讲，用 UNIX pipe 和事件序列说明，不在本讲展开。

**【扩展，类比】**

- 短路的 `&&` / `||` 就是条件求值，不是函数。自己写 `and(e1, e2)` 若按 eager 调用，就会失去短路。这和 `my-if-bad` 是同一个坑。
- 构建系统里“目标的配方先记下来，需要这个目标才跑”像 thunk；“跑过就不再跑，除非输入变了”像 promise，但失效规则是课程没讲的增量计算。
- ORM 的 lazy loading 只是名字相近：它推迟的是 I/O，通常还有缓存，但是有副作用、有失败、有并发。不要用本讲的等式去证明它是 call-by-need。

---

## 检查题

1. 为什么 thunk 通常是零参数函数，而不是“把表达式存进一个新的语言类型”？
2. `factorial-bad` 在参数为 0 时为什么仍然不终止？
3. 写出 `e`、`(lambda () e)`、`(e)` 三者各自求值时发生的事。`(37)` 错在哪？
4. `my-mult` 乘 0、1、7 时，裸 thunk 各调用几次 `slow-add`？事先 `let` 的版本呢？
5. 为什么乘 0 时事先计算是亏损，乘 20 时裸 thunk 是亏损？
6. `my-delay` 的参数为什么必须已经是 thunk？若有人写成 `(my-delay (slow-add 3 4))`，慢加发生在什么时候？
7. 第一次 `my-force` 的三步顺序是什么？为什么要先 `set-mcar!` 为 `#t`，再调用 thunk？课程有没有讨论 thunk 再入地 force 自己？
8. 第二次 force 为什么不会再打印 thunk 里的 `printf`？
9. Promise 和 memoization 都在“记住结果”。课程说它们的差别是什么？
10. 课程有没有说 Racket 是 lazy language？Haskell 在这个对比里扮演什么角色？

## Answers

1. 因为闭包已经能把表达式包进函数体，并且创建函数时不求值体。零参数是因为推迟的是“这个表达式”，不是“等一个新信息再算”。新的语言类型不是必需的。
2. 因为在进入 `my-if-bad`、从而进入里面那个 `if` 之前，调用约定已经要求第三个参数求值。第三个参数是递归调用。`x = 0` 这个事实要到 `if` 的测试里才有意义，而程序永远走不到那个测试。
3. `e` 立刻求值。`(lambda () e)` 得到函数，不求值 `e`；每次调用都求值一次。`(e)` 先求值 `e`，再把结果当零参数函数调用。`(37)` 把 37 当函数调用。
4. 裸 thunk：乘 0 调用 0 次，乘 1 调用 1 次，乘 7 调用 7 次。事先 `let`：无论乘多少，`slow-add` 都在进入 `my-mult` 之前发生 1 次，thunk 体内不再调用它。
5. 乘 0 用不到结果，事先算白做。乘 20 会用 20 次，裸 thunk 把同一次加法做 20 遍，比做一遍再查变量贵。
6. `my-delay` 只是 `(mcons #f th)`，它不负责替你包 `lambda`。若参数位置写 `(slow-add 3 4)`，那是普通参数，在调用 `my-delay` 之前就已经求值，慢加已经发生，传进去的是 7 不是 thunk。后面 macro 讲会用 macro 把“自动包 lambda”做掉；函数做不到。
7. 把 car 设为 `#t`；调用当时的 cdr（thunk），把结果写入 cdr；返回 cdr。课程的代码是这个顺序。它没有讨论“thunk 在自己还没写回结果时又 force 同一个 promise”的再入。不要自行发明这种情况下的保证。
8. 因为第二次 `mcar` 已经是 `#t`，函数直接返回 cdr，不再调用 thunk。而且第一次已经用结果覆盖了 cdr，thunk 本身也不在了。
9. Promise 记住的是一个零参数计算。带参数的函数不能只留一个格子，必须按参数留一张表。那是 memoization，下一章。
10. 没有。课程明确说 Racket 函数参数在调用处求值，和 ML 一样。Haskell 是“函数按 lazy evaluation 工作”的著名语言。Racket 里的 lazy 是你自己用 thunk 和 promise 写出来的局部惯用法。
