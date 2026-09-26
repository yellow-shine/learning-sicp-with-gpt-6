# Section 5 前半 — 练习

覆盖 `08-racket-dynamic-typing.md`。先做题，再看文末 Answer Key。延迟求值、流和宏不在这一份里。

## Concept Questions

1. Part B 为什么用 Racket，而不是把 ML 程序逐行翻译一遍？类型系统消失之后，哪几条求值规则没有消失？
2. 为什么说括号不是风格偏好？`(1)` 和 `1` 的语义差在哪一步？
3. `(sum (list 3 "hi"))` 为什么可以 Run？它最终死在哪个操作上？这和 ML 的 `div` 零是同一类事件，还是同一类类型错误？
4. `sum1` 把“不是 number”当成 list，`sum2` 把“不是 number 也不是 list”跳过。这是类型系统的两种模式，还是程序员自己写的契约？`(sum2 "hi")` 为什么仍会失败？
5. Racket 的 `let` 和 ML 的 `let` 是什么关系？为什么 `(let ([x y] [y x]) ...)` 在 Racket 里真的能交换，在 ML 语义下不能？
6. `letrec` 的环境里已经有后面的名字，为什么 `(letrec ([y (+ w 2)] [w (+ x 7)]) ...)` 仍会错？什么样的向后引用是安全的？
7. `(set! b 5)` 之后，闭包 `f` 的自由变量 `b` 还是词法作用域吗？为什么同一次定义的 `f`，两次调用可以得不同结果？`c` 为什么不变？
8. `cons` 和 proper list 差在哪里？点号在打印里表示什么？为什么动态类型语言可以用一套 `cons` 同时充当 ML 的逗号和 `::`？
9. `set!` 和 `set-mcar!` 各改什么？为什么 Racket 不允许 `set-car!`，却仍然提供 `mcons`？
10. `(if null 14 15)` 得到什么？若你从 JavaScript 把“空就是假”译过来，会错在哪条语义上？

## Code Reasoning

预测值、错误发生的时刻，或环境。不要先跑。

### A

```racket
(define (fact n)
  (if (= n 0)
      (1)
      (* n (fact (- n 1)))))
```

`(fact 0)` 和 `(fact 3)` 各发生什么？错误是语法错误、类型检查错误，还是运行时错误？若把递归调用改成一个写对的 `fact-good`，`(fact 3)` 还会失败吗？

### B

```racket
(define (sum1 xs)
  (if (null? xs)
      0
      (if (number? (car xs))
          (+ (car xs) (sum1 (cdr xs)))
          (+ (sum1 (car xs)) (sum1 (cdr xs))))))
```

`(sum1 (list (list 1 2) 3))` 的值是什么？把其中的 `2` 换成 `"no"` 之后，失败发生在哪一次 `car` 或 `+`？

### C

```racket
(define b 3)
(define f (lambda (x) (+ x b)))
(define c (+ b 4))
(set! b 5)
```

求 `(f 4)` 和 `c`。画出 `f` 的闭包指向哪一格。若在定义 `f` 之前先 `(let ([b b]) ...)` 把 `b` 抄进闭包，`(set! b 5)` 之后 `(f 4)` 变成什么？

### D

```racket
(define x 1)
(define y 2)
(define a
  (let ([x y]
        [y x])
    (cons x y)))
(define b
  (let* ([x y]
         [y x])
    (cons x y)))
```

`a` 和 `b` 各是什么 pair？哪一个是交换，哪一个不是？

### E

```racket
(define x (cons 14 null))
(define y x)
(set! x (cons 42 null))
```

`(car x)` 和 `(car y)` 各是什么？若语言允许 `(set-car! y 7)`，`(car x)` 会怎样？Racket 实际用哪一个操作才能让别名互相看见更新？那个操作能作用在这个 `x` 上吗？

---

## Answer Key

### Concepts

1. 为了单独拧“有没有静态类型”这一轴，并让程序文本几乎就是树。没有消失的是：binding 先求右边、调用先求参数、函数体延迟到调用、词法闭包、`if` 只求一边、cons/list 默认不可变。消失的是运行前的类型拒绝。
2. 每一对括号是树上的一个 sequence 节点。第一个 term 若不是 special form，这个节点就是调用。`(1)` 求值 `1` 得到数字，再用零个参数调用它。`1` 只是数字这个值。
3. 没有类型规则在 Run 之前拒绝它。执行到 `(+ 3 "hi")` 时，`+` 发现第二个参数不是数字。这和 `div` 零同类：求值中的失败。它不是 ML 那种运行前的类型错误；ML 会在运行前拒绝 `string` 出现在 `int list` 里。
4. 是程序员写在函数体里的契约，不是语言的两种类型模式。`(sum2 "hi")` 在判断参数是不是 list 之前就做了 `car`。宽容只覆盖元素，不覆盖参数本身。
5. ML 的 `let` 等于 Racket 的 `let*`。Racket 的 `let` 让所有右边在整个 `let` 之前的环境里求值，所以两个右边看见的都是外层名字，交换成立。ML 顺序求值时，第二个绑定已经看见新的 `x`。
6. 在环境里不等于已经求值。`y` 的初始化立刻读 `w`，而 `w` 还是 undefined。安全的向后引用发生在 `lambda` 函数体里，因为函数体要到调用才求值，那时初始化已经做完。
7. 仍是词法作用域。查找的变量没换。`set!` 改了那一格的内容，所以同一次定义的 `f` 可以先加 `3` 再加 `5`。`c` 存的是已经求出的 `7`，不是对 `b` 的活引用。
8. `cons` 做一个 pair。proper list 是 cdr 链以 `null` 结束的 pair，或就是 `null`。点号表示最后一个 cdr 不是 `null`，所以是 improper list。没有检查器把 pair 和 list 分成两种静态类型，两套构造器换不来编译期分离。
9. `set!` 改变量指向哪个值。`set-mcar!` 改 mcons cell 的字段。不允许 `set-car!`，是为了让普通 list 的 alias 不可观察，并让 `list?` 能在创建时确定。可变字段放到另一套 cell 上，需要它的惯用法仍能写。
10. `14`。`null` 不是 `#f`，所以算真。JavaScript 把 `null` 当假。译过来会走错分支。Racket 唯一的假是 `#f`。

### Code

A. `(fact 0)` 走到基线，求值 `(1)`，运行时错误：不是过程。`(fact 3)` 同样会递归到基线，然后同样的运行时错误。不是语法错误，也没有运行前的类型检查。若递归改调写对的 `fact-good`，`(fact 3)` 可以成功，因为它永远不求值自己的基线；`(fact 0)` 仍失败。测试没覆盖基线，动态类型就会放过这个函数。

B. 值是 `6`。`"no"` 不是 number，`sum1` 把它当 list，对字符串做 `car`（或在进入之后对它做 `null?` / `car`）。失败是运行时，发生在试图把字符串当 list 拆的那一次，不是发生在 `+` 看见 `2` 的时候。`2` 已经被换成字符串，加号未必来得及执行。

C. `(f 4)` 是 `9`。`c` 是 `7`。

```text
b 的格子从 3 被 set! 成 5
f 的闭包指向这一格，不持有快照 3
c 持有数字 7
```

若 `f` 的函数体用的是 `let` 抄下来的内层 `b`，`set!` 外层 `b` 改不到那一格，`(f 4)` 仍是 `7`。

D. `a` 是 `(cons 2 1)`，这是交换。`b` 是 `(cons 2 2)`：`let*` 里第二个 `y` 看见的已经是新的 `x`，而新的 `x` 是外层的 `y`，也就是 `2`。

E. `(car x)` 是 `42`，`(car y)` 是 `14`。`set!` 让 `x` 指向新 cell，`y` 仍指向旧 cell。若允许 `set-car!` 且作用在 `y` 的 cell 上，那时 `x` 已经指向另一格，`(car x)` 仍是 `42`。要让别名互相看见，必须在 `set!` 之前对共享的那一格做字段更新。Racket 的对应操作是 `set-mcar!`，它不能作用在这个 `cons` 出来的 `x` 上。要对 mcons 才行。
