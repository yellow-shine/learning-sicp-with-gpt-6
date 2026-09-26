# Section 7 — 练习

覆盖 `11-static-vs-dynamic-typing.md`。先做题，再看文末 Answer Key。不要先选一个阵营再找理由。

## Concept Questions

1. “ML 是 Racket 的子集”和“Racket 是只有一个类型的 ML”为什么可以同时有用，而不是互相否定？one-type 视角在声称什么，不在声称什么？
2. Static checking 和旁路 bug-finder 差在哪里？Racket 会拒绝未定义变量，为什么仍叫 dynamically typed？
3. 类型系统的 approach 和 purpose 各是什么？为什么 then/else 写反、两个都是 `int -> int` 的函数调错了，不在 ML 类型系统的 purpose 里？
4. 把“阻止除以 0”放在五档谱上。浮点除以 `0.0` 得到 infinity，是动态检查，还是比动态检查更晚的设计？
5. Sound 和 complete 各禁止哪一种错误？为什么“过不了类型检查”不等于“这个程序一定会做 X”？
6. 为什么终止、sound、complete 不能对非平凡的 X 兼得？主流类型系统牺牲的是哪一个？Generics 通常是在补哪一边？
7. 用他的定义说明：为什么 Racket 不是 weakly typed，为什么 C 的 `a[10]` 不是动态类型的例子。
8. `"foo" + 3` 得到 `"foo3"` 改变的是检查时机，还是求值规则？和 `(f 1)` 在 Racket 里因参数个数失败，差在哪里？
9. `pow2` 为什么同时打静态方和“有类型就不用测试”？`pow1` 打的又是哪一条？
10. Prototyping 时他为什么允许 wildcard，演化一个已经写完的 datatype 时为什么又怕 wildcard？Typed Racket 把权衡消掉了吗？

## Code Reasoning

### A

```racket
(define (g x) (+ x x))
(define (f y) (+ y (car y)))
(define (h z) (g (cons z 2)))
```

在 ML 里，这三个定义哪些会被拒绝？在 Racket 里，定义本身会不会失败？`(f 0)` 和 `(f (cons 1 2))` 各自死在哪一个原语上？用 one-type 模型写出 `+` 失败时 match 的哪一支。

### B

```sml
fun f2 x = if true then 0 else 4 div "hi"
fun f4 x = if x <= abs x then 0 else 4 div "hi"
```

若检查器接受它们，X = “把 string 送给除法”会不会在某次求值中发生？ML 为什么仍拒绝？要让 `f4` 通过，检查器必须额外懂什么？这是 approach 的失败，还是 sound 系统故意的 false positive？

### C

```racket
(define (f g)
  (cons (g 7) (g #t)))

(f (lambda (x) (cons x x)))
```

值是什么？对应的 ML `fun f g = (g 7, g true)` 为什么不 type-check？这个拒绝是 false positive 还是 false negative？静态方的合法反击是什么，不是什么？

### D

```sml
fun pow2 x y =
    if y = 0 then 1 else x + pow2 x (y - 1)
```

`pow2 3 4` 的值和类型是什么？把 `+` 改成 `*` 之后，类型变不变？这个例子允许你得出“动态类型更好”吗？

### E

```racket
(define foo '(begin (print "hi") (+ 4 2)))
```

在 `eval` 之前，`(car (cdr foo))` 的值是什么？`+` 被调用了吗？`(eval foo)` 的返回值和副作用各是什么？`(eval (car foo))` 为什么没有值？“Racket 有 eval，所以它必须用解释器实现”错在哪一步？

---

## Answer Key

### Concepts

1. Subset 眼镜看的是“哪些程序在运行前被删”。One-type 眼镜看的是“留下来的动态检查从哪来”：每个值带 tag，原语是看不见的 case。两者解释同一门语言的两侧。One-type 不声称 Racket 源码里有一个 ML `datatype theType`，也不声称 `struct` 就是 ML 构造子。`struct` 会在运行时增加构造子，普通 ML datatype 为了穷尽检查不能这么做。`exn` 只是类比。
2. Static checking 决定什么是 legal program，是语言定义的一部分。旁路工具可以警告，不改变“程序能否按定义运行”。Racket 的未定义变量检查很少，绝大多数类型错误留到求值。名称按“不做 ML 那种静态拒绝”成立，线不是绝对的。
3. Approach 是变量有类型、表达式如何被检查。Purpose 是要阻止的运行时行为，例如原语用错种类的值、查找未定义变量、破坏 module 边界。写反的分支和调错同类型函数需要知道程序员想要什么。没有完整规格，检查器不能读心。所以类型系统不是测试的替代品。
4. 从打字时、编译时、带着 main 准备跑、运算发生时、运算之后仍返回一个值。Racket 的 `(/ 3 0)` 在第四档。浮点 infinity 在第五档：不报错，把结果交给调用者。那不是把检查改成动态，而是把这件事移出“错误”。
5. Sound 禁止 false negatives：接受的程序，任何输入都不会做 X。Complete 禁止 false positives：不会做 X 的程序都不拒绝。`if true then 0 else 4 div "hi"` 不会做 X，仍被拒绝。拒绝的是 false positive。
6. 非平凡性质上，检查器不能既总是终止，又 sound，又 complete。程序员要求终止。主流不要 false negatives，于是接受 false positives。Generics 一类机制常常是为了少拒绝好程序，不是为了允许会做 X 的程序通过。
7. Racket 的无意义操作在语言定义里必须在特定点变成错误。实现只能删证明不会失败的检查。C 的越界可以通过类型检查，动态也不查，语言允许任意行为。那是 weak typing。Dynamic typing 要求失败可见。
8. `"foo3"` 改变的是 `+` 的求值规则：这件事不再是错误。Racket 的 `(f 1)` 仍把参数个数不对当成错误，只是在应用时发现。一个是规则变宽，一个是检查时机。
9. `pow1` 的递归调用把 curried 函数当成传了一个 pair，或在 Racket 里传了两个参数。ML 在 `use` 时拒绝；Racket 要跑到递归才失败。这是“更早抓住调用约定 bug”。`pow2` 用 `+` 代替 `*`，类型是 `int -> int -> int`，结果是 13 不是 81。类型抓不到同类型的错误运算符。两边都要测试。它不允许得出“动态更好”，只划出静态优势的硬边界。
10. Prototyping 时 wildcard 加 `raise` 让没写完的 case 也能跑，相当于把动态语言的隐含失败写成显式的。维护阶段若一直有 wildcard，加构造子不会得到非穷尽警告，to-do list 消失。Typed Racket 把选择从“哪一门语言”挪到“这个文件要不要类型”。谁来决定、按什么标准，他标成开放问题。权衡没有消失。

### Code

A. ML 接受 `g`，类型 `int -> int`。`f` 和 `h` 被拒绝：`f` 的参数不能既送给 `+` 又送给 `car`；`h` 把 pair 送给 `g`。Racket 三个定义都接受。`(f 0)` 死在 `car`：数不是 pair。`(f (cons 1 2))` 死在 `+`：pair 不是数。One-type 模型里，`plus` 的 match 走不到 `(Int i, Int j)`，落到 `_ => raise`。没有值。

B. 不会。`f2` 的 else 不求值。对 `int x`，`x <= abs x` 恒真，`f4` 的 else 也不求值。ML 仍拒绝，因为它 sound 地阻止“程序文本里存在把 string 送给除法”，并且不证明测试恒真。要放过 `f4`，检查器必须懂 `abs` 的算术性质。这不是 approach 写错了。这是 sound 且终止的检查器故意留下的 false positive。

C. 值是 `((7 . 7) . (#t . #t))`。ML 给不了 `g` 一个在同一次检查里既接受 `int` 又接受 `bool` 的类型。传 `fn x => (x, x)` 时程序不会做“原语用错种类的值”这件事，所以拒绝是 false positive，不是 false negative。静态方的合法反击是：Racket 为所有值强制 tag 和检查；ML 让你选择在哪里自己建 one-of。不是“这个 Racket 程序有 bug”，也不是“几行 ML 就无痛得到了 Racket”。

D. 值是 `13`，类型是 `int -> int -> int`。改成 `*` 之后类型不变，值变成 `81`。这个例子只说明类型系统不读“你想要幂还是想要累加”。它不支持“因此动态类型更好”：Racket 同样得到 13，同样要靠测试。

E. `(car (cdr foo))` 是 list `(print "hi")`，也就是 symbol `print` 和字符串 `"hi"`。`+` 没被调用。quote 改变了求值规则。`(eval foo)` 的副作用是打印 `hi`，返回值是 `6`，因为 `begin` 的值是最后一个子表达式。`(eval (car foo))` 是在求值单独的 symbol `begin`，按他的演示那不是合法程序，所以没有值。错在把“运行时必须还能实现 Racket”推成“必须用解释器实现”。编译器实现也可以，只要可能调用 `eval` 的程序还带得上编译能力。`eval` 也可以不用。
