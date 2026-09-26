# Section 5 后半 — 练习

覆盖 `09-delayed-evaluation-and-macros.md`。Thunk、promise、stream、memoization、宏与 hygiene。先做题，再看文末 Answer Key。

## Concept Questions

1. `factorial-bad` 的 `if` 写在 `my-if-bad` 里面，为什么参数为 `0` 时仍然不终止？函数体里的 `if` 执行过吗？
2. 为什么 `(lambda () e)`、`e`、`(e)` 是三种不同的求值，而不是同一种表达式的三种括号风格？
3. Thunk 在什么时候比预计算更快，什么时候更慢？Promise 改变的是哪一半？
4. 第一次 `my-force` 之后，promise 的 cdr 为什么不能仍是原来的 thunk？若用不可变 `cons`，这份实现缺哪一步？
5. 本课的 stream 和 list 差在哪里？和 promise 又差在哪里？为什么说他定义的 stream 不 memoize？
6. `ones-really-bad` 在 Racket 里失败，他为什么说同样的形状在 Haskell 里可以工作？这是默认求值策略的差别，还是“Haskell 有一种叫 stream 的类型”？
7. Memo 表为什么必须放在 `f` 外面、又不能放在 top-level？函数有副作用时，memoize 破坏的是哪条前提？
8. 为什么没有任何函数能实现 `(comment-out e1 e2)` 的“`e1` 永不求值”？宏的展开发生在什么之前？
9. `my-delay` 必须是宏，`my-force` 不该是宏。两条理由分别是什么？“用 `let` 把宏参数绑一次”修好了求值次数之后，为什么仍然不必做成宏？
10. Hygiene 的两件事是什么？为什么 C/C++ 程序员会在宏里使用 `__strange_name34`，而 Racket 的 `syntax-rules` 通常不需要？

## Code Reasoning

预测值、打印次数、是否终止、或哪一种错误。不要先跑。`slow-add` 只表示“大约一秒后返回两数之和”。打印用 `print`，按字幕里的副作用来数次数。

### A

```racket
(define (my-if-bad e1 e2 e3)
  (if e1 e2 e3))

(define (factorial-bad x)
  (my-if-bad (= x 0)
             1
             (* x (factorial-bad (- x 1)))))
```

求值 `(factorial-bad 0)` 时，在进入 `my-if-bad` 的函数体之前，三个参数分别发生什么？

### B

```racket
(define (my-delay th) (mcons #f th))
(define (my-force p)
  (if (mcar p)
      (mcdr p)
      (begin
        (set-mcar! p #t)
        (set-mcdr! p ((mcdr p)))
        (mcdr p))))

(define p (my-delay (lambda () (begin (print "hi") 7))))
(define a (my-force p))
(define b (my-force p))
```

`a` 和 `b` 是什么？`print` 发生几次？第二次 `my-force` 时 car 和 cdr 里各是什么？

### C

```racket
(define ones (lambda () (cons 1 ones)))
(define ones-bad (lambda () (cons 1 (ones-bad))))

(car ((cdr (ones))))
(ones-bad)
```

第一个表达式的值是什么？第二个表达式为什么不返回 pair？

### D

```racket
(define fibonacci
  (letrec ([memo null]
           [f (lambda (x)
                (let ([ans (assoc x memo)])
                  (if ans
                      (cdr ans)
                      (let ([new-ans (if (or (= x 1) (= x 2))
                                         1
                                         (+ (f (- x 1)) (f (- x 2))))])
                        (begin
                          (set! memo (cons (cons x new-ans) memo))
                          new-ans)))))])
    f))
```

空表上求 `(fibonacci 3)`。哪些参数被真正算过，哪些后来的调用命中了表？若把 `memo` 的 `null` 移进 `f` 的 `lambda` 体内，指数爆炸为什么会回来？

### E

下面两段按朴素展开（不是 Racket）和按 Racket 的 hygiene 各预测一次。

```racket
(define-syntax double-capture
  (syntax-rules ()
    [(double-capture x)
     (let ([y 1])
       (* 2 y x))]))

(let ([y 7]) (double-capture y))
```

```racket
(define-syntax double-star
  (syntax-rules ()
    [(double-star x) (* 2 x)]))

(let ([* +]) (double-star 42))
```

再回答：`(double-plus (begin (print "hi") 42))` 若展开成 `(+ x x)`，打印几次、结果是多少？这和 hygiene 是同一件事吗？

---

## Answer Key

### Concepts

1. 调用 `my-if-bad` 之前，三个参数都求值。第三个参数是 `(* 0 (factorial-bad -1))`，它自己又要调用 `my-if-bad`。函数体里的 `if` 一次都没有执行。问题是求值时机，不是分支写反了。
2. `e` 现在就求值。`(lambda () e)` 造一个函数值，body 不跑。`(e)` 先求值 `e` 得到过程，再零参调用。多一对括号在 Racket 里是调用。`(37)` 因此是错误，不是整数 37。
3. 结果可能完全不用时，thunk 更快，预计算白付。结果要用很多次时，thunk 每次重算，预计算只付一次。Promise 保留“不用就不算”，又让多次 force 只算一次。
4. 写回 cdr 是为了第二次不再调用 thunk。若 cdr 仍是 thunk，`my-force` 无法区分“还没算”和“结果碰巧是个函数”，而且实现也没有别的地方存结果。不可变 `cons` 不能 `set-mcdr!`，除非改用另一个可变绑定来保存结果。本课这份实现依赖那个可变单元被多次 force 共享。
5. List 的尾巴在构造时已经存在，长度有限。Stream 是 thunk，调用才得到 `pair(值, 另一个 thunk)`。Promise 记住一个 0 参计算的结果。他的 stream 每次调用同一个 thunk 都会再构造下一个 pair，没有把尾巴换成已算好的值。
6. Haskell 里 `cons` 的参数不急着求值，所以绑定初始化可以引用自己，而不在绑定完成前就去求那个名字。这是求值策略。不是因为 Haskell 有一个内置的、和本课协议相同的 stream 类型。Racket、ML、Java 的函数调用是 eager 的，所以 `ones-really-bad` 在绑定完成前就需要自己。
7. 放进 `f` 的函数体，每次调用都会执行那次绑定，表是新的 `null`，递归调用之间不共享。放在 top-level 会把实现细节暴露给客户，也鼓励对顶层绑定 `set!`。副作用意味着同一参数不应假定同一结果，第二次调用还会吞掉第一次以后才该发生的效果。
8. 函数调用先求所有参数。`(car null)` 在进入函数体之前就已经错了。宏在类型检查和求值之前展开。`(comment-out (car null) #f)` 展开成 `#f`，求值器看不见 `(car null)`。
9. `my-delay` 必须收到未求值的表达式，把它放进 `lambda`。函数做不到不求值参数。`my-force` 应该把参数求值一次，函数调用规则已经做到；做成宏会把同一段语法粘贴进多个求值位置。用 `let` 绑一次之后，求值次数和函数相同，只剩下宏的推理成本，没有表达能力上的收益。
10. 宏定义里的局部变量被换成不会与 use site 冲突的名字。宏定义里的自由变量按定义处的环境查找，不按 use site。C/C++ 预处理器会捕获调用者的同名变量，所以宏作者用没人会写的名字。卫生宏让普通名字安全。这是概念类比：预处理器不是 `syntax-rules`。

### Code

A. `(= 0 0)` 求成 `#t`。`1` 求成 `1`。`(* 0 (factorial-bad -1))` 开始另一次调用，那次调用又要先求它自己的第三个参数。`my-if-bad` 的函数体不执行。不终止。

B. `a` 和 `b` 都是 `7`。`print` 一次。第二次 force 时 car 是 `#t`，cdr 是 `7`，原来的 thunk 已经被替换掉。

C. 第一个表达式是 `1`。`(ones)` 得到 `pair(1, ones)`，再调用 cdr 里的同一个 thunk，car 仍是 `1`。`(ones-bad)` 要计算 `(cons 1 (ones-bad))`，第二个参数立刻调用 `ones-bad`，那个调用又做同样的事，永不返回 pair。

D. `(f 3)` 未命中，需要 `(f 2)` 和 `(f 1)`。两者都是基线，各写入一次结果 `1`，然后写入 `(3 . 2)`。若实现先算 `(f 2)` 再算 `(f 1)`，`(f 1)` 不会在算 `(f 2)` 时被附带写入；两个基线都是真正算的，不是命中。没有“后来的递归调用命中 `3`”。命中发生在以后再调用 `(fibonacci 2)` 或 `(fibonacci 1)` 或 `(fibonacci 3)` 时。算 `(f 4)` 时，后做的 `(f 2)` 才会命中前面留下的表项。把 `memo` 移进 `f` 的体内后，每次调用有自己的空表，`(f 2)` 看不见 `(f 3)` 刚刚写入的东西，两次递归又都是完整的树。

E. 朴素展开：`(let ([y 1]) (* 2 y y))` 得到 `2`。Racket 得到 `14`，因为宏的 `y` 和用户的 `y` 不是同一个变量，参数仍是 `7`。第二段朴素展开得到 `44`，因为 use site 的 `*` 是 `+`。Racket 得到 `84`，因为 `*` 在宏定义处是乘法。`(double-plus (begin (print "hi") 42))` 打印两次，结果 `84`。这是求值次数，不是 hygiene。没有同名捕获，也没有自由变量在 use site 被 shadow。两件都是宏的语义，但是不同的缝。
