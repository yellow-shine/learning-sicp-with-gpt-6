# Section 6 — 练习

先做题，再看文末 Answer Key。字段名若作业用的是 MUPL 的 `int` / `fun` / `call`，不要和讲义里的 `const` 混用。下面为了可读，讲义例子用 `const`，环境例子用作业里的 `(int n)`。口述没有逐字给出的语法，题干会标明“按讲义语义，不是作业 API”。

## Concept Questions

1. 为什么动态类型语言把 number 和 string 放进同一个 list 时，不必先造一个 datatype？什么时候这个办法不够，必须自己做 tag？
2. 解释器为什么要从 `exp -> int` 改成返回一个表达式？返回 Racket 的 `7` 和返回 `(const 7)` 差在谁看得见？
3. Grossman 为什么说 struct 不是 list 编码的语法糖？请用 `pair?` 和一次错误的 accessor 说明，不要只说“少写了 helper”。
4. “动态类型不能做抽象类型”错在哪里？这和 ML signature 隐藏构造子是 conceptual analogy 还是同一种机制？
5. 为什么 “C 是编译型语言，所以比解释型的 Lisp 快” 说不通？语言有 `eval` 时，这句话的哪一部分才开始有一点关系，关系又为什么仍不成立？
6. `(negate -7)` 和“把 `(const 1)` 与 `(bool #f)` 相加”，解释器的义务有何不同？
7. 为什么 `eq-num` 不能把 Racket 的 `#t` 直接返回给调用方？
8. `let` 的 body 和 `add` 的两个子表达式，传下去的环境有何不同？初始环境为什么必须是空的？
9. 函数表达式为什么不是 value？调用时哪几步用当前环境，从哪一步起必须改用 closure 里的环境？
10. 用 Racket 函数生成 `if-then-else` 树，得到了宏的哪一半，没得到哪一半？

## Code Reasoning

### A

```racket
(define (Add e1 e2) (list 'Add e1 e2))
(define (Multiply e1 e2) (list 'Multiply e1 e2))
(define (Add-e1 e) (car (cdr e)))
(define (Multiply-e1 e) (car (cdr e)))

(define x (Add (list 'Const 3) (list 'Const 4)))
```

`(list? x)` 是什么？`(Multiply-e1 x)` 是什么，它是错误吗？若 `x` 改为 struct 版的 `(add (const 3) (const 4))`，`(multiply-e1 x)` 和 `(pair? x)` 各自怎样？

### B

按讲义语义，不要求你写出作业的完整解释器。

```racket
(define test1
  (multiply (negate (add (const 2) (const 2)))
            (const 7)))
```

一个会检查递归结果种类的 `eval-exp`，结果是什么？一个假定递归结果总是 `const` 的解释器，对 `test1` 的结果是什么？把第二个操作数换成求值后得到 `(bool #t)` 的表达式之后，两个解释器的差别出现在哪里？

### C

```text
外层环境 E0 = 空

求值 (let "x" (int 10) e-body)
e-body 是一个函数定义：参数 "y"，函数体使用 x 和 y
然后在另一个环境里调用这个函数，那个环境把 "x" 绑定到 (int 20)，实参是 (int 1)
```

按词法作用域，函数体里的 `x` 是多少？调用点的环境在哪几步被使用？若实现错把 body 放在调用点的环境里求值，`x` 变成多少？这是哪种作用域？

### D

递归绑定时，函数名指向整个 closure，而不是只指向函数 AST。

若 body 里递归调用自己，而环境里函数名只映射到函数 AST、没有映射到 closure，下一次进入“求值函数表达式”时，新 closure 的环境从哪来？定义时捕获的自由变量还在吗？

### E

```racket
(define (andalso e1 e2)
  (if-then-else e1 e2 (bool #f)))

(define y (andalso (bool #f) (eq-num (const 1) (const 0))))
```

`y` 在调用 `eval-exp` 之前是什么？`(eval-exp y)` 会不会去比较 1 和 0？为什么？若 `andalso` 改成语言 B 的一个新 struct，谁必须负责“第二个表达式不求值”？

---

## Answer Key

### Concepts

1. Racket 的每个值已经有 tag。`number?` 和 `string?` 就是在读这个 tag。ML 的 list 元素必须同类型，所以要先造 `I` / `S`。这个办法不够的时候，是你需要一种语言里没有的递归形状，例如 Add 和 Multiply。没有人会提供 `add?`。你必须自己做 tag，而且最好让这个 tag 不可伪造。
2. 结果种类一多，裸整数就不是统一的返回值。调用方无法区分“这是数”和“这是函数值”。`(const 7)` 是对象语言的 value，求值到自身。Racket 的 `7` 是元语言的值。漏出去之后，下一步的 `const?` 失败，用户看见的是 Racket 而不是语言 B。
3. Struct 值不是 pair。`pair?` 为假，`cdr` 报错，对 add 调用 `multiply-e1` 报错。List 编码的 Add 是 list，错的 extractor 往往是同一段 `car` of `cdr`，静默返回另一个字段。宏可以少写 helper，但不能制造一种对所有旧谓词都回答假的数据。所以它不是糖。
4. 抽象可以靠不可伪造的构造器加上模块不导出它。客户既不能调用 constructor，也不能用 list 拼出一个通过 `add?` 的值。ML 靠类型检查拒绝错误的构造。Racket 靠根本没有那个函数、并且谓词认不出伪造品。类比，不是同一机制。
5. 语言由语义规则定义。编译或解释是某次实现的策略，而且真实实现经常混合：Java 编译到 bytecode 再解释，热代码再编译，芯片还可能再翻译。有 `eval` 时，实现必须在运行时还在，因为可能要再处理一段同语言程序。这不强迫 `eval` 本身用解释器实现。编译器也可以在运行时被调用。
6. `(negate -7)` 不是合法 AST。`-7` 不是表达式。解释器可以崩溃，可以给出 Racket 的难看信息。数加布尔可以是一棵合法的树：两个子节点都是表达式。错在求值之后的值种类。解释器必须检查，并给出关于语言 B 的信息，而不是 accessor 错误。
7. `#t` 不是语言 B 的 value。调用方的 `bool?` 会失败，或者对象语言的类型规则被元语言的值绕过。比较可以用 `equal?`。返回之前必须 `(bool ...)`。
8. `add` 的两个子表达式用同一份当前环境。`let` 的 body 用扩展后的环境，多一个“变量名 → 刚求出的 value”。初始环境必须为空，否则程序会看见没有绑定过的名字。语义是：程序开始时没有任何变量。
9. 函数表达式求值的结果才是 value，那个 value 是 closure。函数表达式本身还没有环境可带。调用时，当前环境只用于求值被调用者和实参。从求值 body 起，环境换成 closure 里保存的那份，再扩展参数名，并把函数名映射到整个 closure。
10. 得到了“在 `eval-exp` 之前把糖重写成核心构造”。没得到 hygiene。宏引入的对象语言变量可能捕获用户的同名变量。真正的 `define-syntax` 会处理这件事。这套 Racket 函数不会。

### Code

A. `(list? x)` 是 `#t`。`(Multiply-e1 x)` 是 `'(Const 3)`，不是错误。extractor 不看 tag。Struct 版的 `(pair? x)` 是 `#f`。`(multiply-e1 x)` 是运行时错误，因为 `x` 不是 multiply。

B. 会检查的解释器得到 `(const -28)`：左边 negate 得到 `(const -4)`，右边是 `(const 7)`。假定总是 const 的解释器对 `test1` 也得到 `(const -28)`，因为假设成立。第二个操作数变成 `(bool #t)` 之后，会检查的解释器在 `const?` 失败时给出关于非 number 的错误。缺检查的解释器对 bool 调用 `const-int`，错误信息是 Racket 的 accessor，不是语言 B 的动态类型错误。

C. 函数体里的 `x` 是 `(int 10)`。调用点的环境用来求值“这个函数值是哪个 closure”以及实参 `(int 1)`。Body 从 closure 保存的环境开始，那个环境里 `x` 是 10，再扩展 `y → (int 1)`。若 body 用调用点的环境，`x` 是 20。那是动态作用域。

D. 下一次会把函数 AST 再求值一次，用当时的当前环境新建 closure。定义时捕获的自由变量不在这份新环境里，除非调用点碰巧还有同名绑定。即便碰巧有，值也是调用时的值，不是定义时的值。递归因此既可能报未绑定，也可能悄悄变成动态作用域。所以函数名必须指向整个 closure。

E. `y` 是一棵树：`(if-then-else (bool #f) (eq-num (const 1) (const 0)) (bool #f))`。`(eval-exp y)` 不会比较 1 和 0。测试求值得到 `(bool #f)`，`if` 只求值 else 分支，那个分支已经是 `(bool #f)`。`eq-num` 那棵子树在落选分支里，按 `if` 的规则不求值。若 `andalso` 是语言 B 的新 struct，解释器的那个 case 必须自己实现短路。Racket 函数版把短路留给已经写好的 `if-then-else`。
