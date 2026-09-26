# Section 6.1 动态语言里的 Datatype

标注见 `00-course-map.md`。本章覆盖 Section 6 的前三讲：不用 struct 的表达式树、`struct`、以及它为什么不是 list 的语法糖。解释器从 `06` 开始。闭包的实现在 `07`。

Section 5 已经允许一个 list 里混放数和字符串，并用 `number?` 分辨。这里要表示的是递归的、有若干种形状的数据：算术表达式。Part A 用 datatype 和模式匹配。Racket 没有那种绑定。课程的问题是：类似的数据仍要写，类型检查器又不在，表示法该长什么样。

---

## 从“混放”到“自己规定的形状”

```text
Data Representation
      │
      ├── 语言已有的值自带标签：number? / string? 够用
      │
      ▼
Tagged Data
      自己规定：list 的第一个元素是符号，说明这是哪一种
      │
      ▼
Manual Datatype Encoding
      构造器、谓词、访问器都是普通函数
      │
      ▼
Structs
      语言替你生成这三套函数，并且造出一种新数据
      │
      ▼
Datatype Abstraction
      不导出构造器时，客户端造不出“看起来像”的假值
```

**【课程】** 不需要 ML 的 datatype binding。要做什么，就用什么惯用法。

| 需求 | ML | Racket |
| --- | --- | --- |
| 一个 list 里既有 int 又有 string | 必须先声明 `IntOrString`，用构造器包起来 | 直接放。`number?`、`string?` 在运行时看语言自带的标签 |
| 递归的表达式树 | `datatype exp = Const of int \| Negate of exp \| ...` 加模式匹配 | 先用手写的带标签 list，再用四个 `struct` |
| “这些就是全部形状” | datatype 绑定本身说出了全部构造器 | 没有这句声明。全部形状只存在于注释、文档和你的脑子里 |
| 字段的类型 | 写在 datatype 里，检查器强制 | `struct` 的字段可以装任何值。你自己保证 `Const` 的字段是数 |

**【讲解】** 动态类型不是“不能做 one-of 数据”。它是“one-of 不再是类型系统里的一个类型，而是一组你约定要一起处理的值”。约定靠函数维持，不靠检查器。

---

## 语言自带的标签：`funny-sum`

**【课程】** ML 里每个 list 的元素只有一个类型。要“数就当数加，字符串就加长度”，必须：

```sml
datatype int_or_string = I of int | S of string
(* sum : int_or_string list -> int *)
```

Racket 里每个值已经带着类似 `I` / `S` 的标签，只是标签属于语言实现，不由你声明。所以不用自定义 datatype：

```racket
(define (funny-sum xs)
  (cond [(null? xs) 0]
        [(number? (car xs))
         (+ (car xs) (funny-sum (cdr xs)))]
        [(string? (car xs))
         (+ (string-length (car xs))
            (funny-sum (cdr xs)))]))
```

这里没有 `#t` 分支。课程说通常最好有，但这样更接近 ML 的两个构造器：第三种值不是这函数要处理的。`string-length` 是标准库。

**【课程】** 直接对应物是：ML 用你写的构造器打标签；Racket 的内置值已经打过标签。`number?` 就是在看那个标签。这和 Section 7 的 “one big datatype” 是同一幅图，那里会讲完。

---

## 算术表达式：为什么 `eval` 要返回表达式

Part A 风格的小语言：

```sml
datatype exp =
    Const of int
  | Negate of exp
  | Add of exp * exp
  | Multiply of exp * exp

(* 旧版本：eval_exp_old : exp -> int *)
```

测试树是 `Multiply(Negate(Add(Const 2, Const 2)), Const 7)`，旧的求值得到 `-28`。

**【课程】** 从现在起，课程把求值函数改成 `exp -> exp`。小语言里结果总是整数，这样写更啰嗦：调用得到的是 `Const (~28)`，不是 `-28`。原因是更大的语言不只有一种结果。结果可能是数、pair、函数、字符串、布尔。解释器应该返回“语言里的值”，而值也是表达式的一种。

模式，ML 版，课程称之为优雅：

```text
递归调用，得到一个 exp
确认它是 Const，取出里面的 int
做运算
用 Const 构造器把结果包回去
```

辅助函数：若是 `Const` 就取出 int，否则抛异常。`Negate` 的一支：

```text
eval(Negate e) =
    let v = eval(e) in
    Const (~ (get_int v))
```

`Add` 和 `Multiply` 同样：两次递归，两次 `get_int`，运算，再 `Const`。基线是：已经是 `Const` 就返回整个表达式，不是返回里面的 int。

**【讲解】** 这是后面解释器的返回约定的起点。`eval` 的结果必须是“求值已经结束”的表达式。若还返回一个 `Add`，解释器有 bug。Section 6 的下一讲把这类结果叫做 value。

---

## 不用 struct：带标签的 list

**【课程】** 没有 datatype 绑定。用 list，第一个元素说明种类。符号先当成字符串来想；和字符串的差别放在本节末尾。

```racket
(define (Const i) (list 'Const i))
(define (Negate e) (list 'Negate e))
(define (Add e1 e2) (list 'Add e1 e2))
(define (Multiply e1 e2) (list 'Multiply e1 e2))

(define (Const? e) (eq? (car e) 'Const))
(define (Negate? e) (eq? (car e) 'Negate))
(define (Add? e) (eq? (car e) 'Add))
(define (Multiply? e) (eq? (car e) 'Multiply))

(define (Const-int e) (car (cdr e)))
(define (Negate-e e) (car (cdr e)))
(define (Add-e1 e) (car (cdr e)))
(define (Add-e2 e) (car (cdr (cdr e))))
(define (Multiply-e1 e) (car (cdr e)))
(define (Multiply-e2 e) (car (cdr (cdr e))))
```

`'Const` 是符号。`eq?` 用来比符号。这些函数就是构造器、变体测试、访问器。课程不用 Racket 的模式匹配。有它们就写得出 `eval-exp`。访问器假定你已经用对了构造器，这一版不重复检查种类。讲师说更稳妥的做法是再查一次；下一讲的 struct 会让用错访问器直接报错。

`car` / `cdr` / `cdr` 用多了，标准库有组合函数。课程指向 Racket Guide，不在视频里展开名字。

求值函数和 ML 的新版同构。`cond` 代替模式匹配：

```racket
(define (eval-exp e)
  (cond [(Const? e) e]
        [(Negate? e)
         (Const (- (Const-int (eval-exp (Negate-e e)))))]
        [(Add? e)
         (let ([v1 (Const-int (eval-exp (Add-e1 e)))]
               [v2 (Const-int (eval-exp (Add-e2 e)))])
           (Const (+ v1 v2)))]
        [(Multiply? e)
         (let ([v1 (Const-int (eval-exp (Multiply-e1 e)))]
               [v2 (Const-int (eval-exp (Multiply-e2 e)))])
           (Const (* v1 v2)))]))
```

**【课程】** 递归结构和 ML 相同，只是没有模式匹配。因为没有类型系统，没有任何地方写下“表达式是这四种”。把 `Add` 的访问器用在 `Multiply` 的值上，这一版会静静地成功：两个访问器都是 `(car (cdr e))`。这是 list 编码的洞，下一讲用它对比 struct。

树：

```text
Multiply
├── Negate
│   └── Add
│       ├── Const 2
│       └── Const 2
└── Const 7

eval → Const -28
```

在 list 编码里，这棵树就是 list 的 list。`'Multiply` 在 car，两棵子树在后面。

### 符号不是字符串

**【课程】** 符号写成 `quote` 加一串字符，即 `'foo`。字符串用双引号。差别不大，但是不同的值。符号可以用 `eq?` 做很快的相等测试：`'foo` 等于 `'foo`，不等于 `'bar`。字符串比较要看全部字符，更慢。这一节可以用字符串代替符号。更高层的要点是：只用 list 和辅助函数，就能编码自己的 datatype。

---

## `struct`：语言替你生成构造器、谓词、访问器

```racket
(struct foo (bar baz quux) #:transparent)
```

**【课程】** 求值这个声明后，环境里多出一批函数：

| 函数 | 作用 |
| --- | --- |
| `foo` | 三参数构造器。求值三个参数，返回一个新的 foo，三个字段分别是结果 |
| `foo?` | 任意值。当且仅当它由 `foo` 构造时返回真 |
| `foo-bar`、`foo-baz`、`foo-quux` | 取出对应字段。参数不是 foo 则运行时错误 |

像记录，因为有命名字段。又不止记录，因为同时得到谓词。字段个数就是构造器的参数个数。

表达式语言是四个 struct，不是一个 datatype 绑定：

```racket
(struct const (int) #:transparent)
(struct negate (e) #:transparent)
(struct add (e1 e2) #:transparent)
(struct multiply (e1 e2) #:transparent)
```

**【课程】** 在动态类型语言里，没有“一个 datatype 包含这四个构造器”的东西。每个 `struct` 更像 ML datatype **里面的一个构造器**：你得到构造器、测试器、若干提取器。`const` 是构造器，`const?` 是测试器，`const-int` 是提取器。这不是模式匹配。讲师个人没那么喜欢这种写法，但它能用，也有效率。

两件 ML 有、这里没有的事：

1. 没有地方说“表达式只有这几种”。
2. 没有地方说字段的类型。Racket 有办法加，课程不走那条，而是动态类型的做法：字段可以是任何值，由你保证 `multiply` 的字段是表达式、`const` 的字段是数。

`eval-exp` 的逻辑与 list 版、与 ML 相同：

```racket
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
```

```racket
(define x (add (const 3) (const 4)))
; 打印成一棵树，不是 list
(eval-exp x)   ; (const 7)
```

`add`、`add?`、`add-e1` 都是过程。本节剩下的解释器都用 struct，并使用声明自动生成的那些函数。

### `#:transparent` 与 `#:mutable`

**【课程】** `#:transparent` 可以不写，前面说的函数仍在。不写时，REPL 不打印字段，只打印名字，例如 `#<foo>`。字段仍在：`(foo-bar y)` 能取出 7。写了它，`(const 17)` 印成 `const 17`，`(const (+ 3 4))` 印成 `const 7`。它还有课程不讲的其他效果。作业和本节能看见树，所以加上。

`#:mutable` 会为每个字段再生成一个修改器。对 `(struct card (suit rank) #:mutable #:transparent)`，会有 `set-card-suit!`，两个参数：那张 card，和新值。可变数据的利弊 Part A 和 Section 5 已经讨论过。Promise 用过 mutation。本节能用不可变 struct 写好的，就不用这个属性。属性改变的是 `struct` 这个原语的行为。

---

## Struct 不是 list 编码的语法糖

这是本节最重要的语言设计结论。

**【课程】** 调用 `add` 构造器得到的不是 list。

```racket
(define x (add (const 3) (const 4)))
(pair? x)       ; #f
(list? x)       ; #f
(multiply? x)   ; #f
(add? x)        ; #t
```

每个 struct 定义都在给 Racket 增加一种新的原始数据。`cons` 做 pair，数是数，`add` 做 add。实现不检查字段是不是表达式：`(add 7 19)` 也能造出来。它是一个合法的 add 值，只是不符合我们希望的用法。

用错访问器会报错，这是优点，因为不会静静地做错：

```racket
(multiply-e1 x)   ; 错误：x 不是 multiply
(cdr x)           ; 错误：x 不是 pair
```

List 编码没有这些优点。`Add` 只是返回三元素 list 的普通函数。结果是 list，是 pair，于是：

- 你可以直接 `(car (cdr x))`，绕过 `Add-e1`。
- 写错一层 `car` / `cdr`，得到的是符号或者别的字段，而不是立刻的“种类不对”。
- `Multiply-e1` 和 `Add-e1` 做的是同一件事，都是 `(car (cdr e))`。对一个 Add 调用 `Multiply-e1` **不是错误**，得到 `(Const 3)`。

**【课程】** 因此 struct 更好，理由不只是少写几行：

| | List 编码 | Struct |
| --- | --- | --- |
| 写法 | 每个构造器、谓词、访问器自己写 | 一行声明，五个函数白送（三字段则更多） |
| 正确使用时 | 有了辅助函数之后，差不多一样方便 | 一样方便 |
| 用错时 | 常常静默给出另一个 list 的某段 | 更快失败，更容易调试 |
| `list?` / `pair?` | 真 | 假 |
| 能否用别的种类的访问器 | 能，只要 `car` / `cdr` 的深度相同 | 不能 |

“五行函数白送”是第一眼的好处。课程更在意的是失败得更早。

### 模块与契约：动态语言也能做抽象

**【课程】** 有两件视频点到、但不要求你在这里会写的 Racket 特性，使 struct 更强。

第一，Racket 有模块系统，和 ML 一样。ML 用抽象类型把表示藏起来。有人以为动态类型语言不能做这种类型抽象。能。把 struct 放进模块，只向客户端提供访问器，不提供构造器。客户端就造不出值，除非走你的函数；那些函数可以维护不变量。若表示是 list，你拦不住程序里任何人写一个 car 为 `'add` 的 list，它会伪装成 Add 表达式，即便字段不满足不变量。

第二，contract 系统可以把“必须成立的性质”加在函数和 struct 上，从而更早报错。性质可以是你定义的，例如 Add 的子字段本身必须是表达式。课程没演示写法。对所有 list 加这种契约没有意义：你只想约束这一种新数据。

### 为什么函数和 macro 都造不出 struct

**【课程】** Struct 是加进语言的新东西，不能用已有特性编码出来。

- 一个函数不能像 `struct` 那样一次引入多个绑定（构造器、谓词、每个字段的访问器）。
- Macro 也不能创造一种新数据。Macro 重写语法。它造不出“对程序里所有其他类型的谓词都回答假”的值。

Struct 特殊就在这里：由它造出的值，不是数，不是 pair，不是任何已有种类。`number?` 为假，`pair?` 为假。只有内置构造能给出这种保证。若新数据总是用旧种类搭出来，那么那种旧种类的谓词就会为真，因为你确实用那种数据搭的。

**【讲解】** 这把 Section 5 的 macro 边界说死了。Macro 能增加特殊形式，不能增加一种运行时标签。Datatype 的“新构造器”是求值世界里的事，不是展开世界里的事。动态语言若要有真正的新变体，需要一个内置的定义形式，而不是约定 car 里放哪个符号。

---

## 和 ML 的对照

| ML | Racket struct | 差别里最要紧的一句 |
| --- | --- | --- |
| `datatype exp = ...` | 没有对应物。四个 struct 只是四个构造器 | 动态语言不把“全部变体”写成一个类型 |
| 构造器 `Const` | 构造器 `const` | 都用来造值 |
| 模式匹配 | `const?` 加 `const-int`，或你自己不用的 `match` | 课程选择谓词和访问器。匹配错误在 ML 里常是静态的；用错访问器在 Racket 里是运行时的 |
| 字段类型、穷尽性 | 不检查 | 静态保证换成了你的纪律，加上用错时的运行时错误 |
| 抽象类型 | 模块里不导出构造器 | 动态语言仍能隐藏谁有权构造值 |

**【课程】** 最重要的设计差别不是“有没有模式匹配”这一句。是：ML 的 datatype 同时给出新类型、全部构造器、字段类型和穷尽性；Racket 的 `struct` 只给出一种新数据及其函数。其余的保证，要么你不要，要么你用模块和契约另加。

---

## 逐讲笔记

### 01 Datatype Programming without Structs

1. **问题：** 没有 datatype 绑定，递归的多种表达式怎么表示，求值函数怎么写？
2. **动机：** 解释器马上要用这种数据。先证明 list 和符号就够把 ML 的 `eval` 搬过来，再谈为什么不够好。
3. **概念：** 内置标签；`funny-sum`；`exp -> exp`；符号；构造器 / 谓词 / 访问器都是函数。
4. **机制：** list 的 car 是种类。求值：递归，取出 int，运算，用 `Const` 包回。
5. **代码：** `funny-sum`；四个构造函数和访问器；`eval-exp`。
6. **执行：** `Multiply(Negate(Add(Const 2, Const 2)), Const 7)` 得到 `Const -28`。新版返回的是表达式，不是裸 int。
7. **PL：** “表达式有四种”在动态语言里是约定，不是类型。约定用函数表达之后，程序可以绕过函数，直接拆 list。
8. **误区：** 动态语言无法表示 one-of。`eval` 应该返回 Racket 的数，因为小语言的结果是数（课程故意改成返回 `Const`，为多种值做准备）。符号只是带引号的字符串。
9. **联系：** Section 5 的 `number?` 和异构 list。Part A 的 datatype 与模式匹配。Promise 那个“car 是布尔”的 one-of，是同一手法的更小例子。
10. **一句：** 带标签的 list 能模拟构造器，但模拟出来的东西仍是 list。

### 02 Datatype Programming with Structs

1. **问题：** 语言怎样替你生成构造器、谓词和访问器？
2. **动机：** 手写 `car` / `cdr` 容易写对递归，也容易让两种访问器变成同一个函数。
3. **概念：** `struct`；`foo?`；`foo-bar`；`#:transparent`；`#:mutable`。
4. **机制：** 一个声明引入多组函数。求值 `eval-exp` 时用这些函数，不再用 `car`。
5. **代码：** `foo` 的一般形式；四个表达式 struct；`eval-exp`。
6. **执行：** `(add (const 3) (const 4))` 印成树。`eval-exp` 得到 `(const 7)`。没有 `#:transparent` 时，REPL 只印名字，字段仍可取出。
7. **PL：** Struct 像构造器，不像 datatype 绑定。动态类型把“有哪些变体、字段是什么类型”留在语言外面。
8. **误区：** 四个 struct 等于一个 ML datatype。`#:transparent` 改变字段是否存在。本课的表达式 struct 应该是 mutable 的。
9. **联系：** 上一讲的辅助函数被声明取代。`#:mutable` 连接到 Section 5 的 `set-mcar!`，但是课程选择这里不用。
10. **一句：** `struct` 一次给你构造、测试和取出；它不给你“这就是全部变体”的静态清单。

### 03 Advantages of Structs

1. **问题：** 为什么 struct 不是那套 list 函数的简写？
2. **动机：** 若只是少打字，语言设计上不值得单讲。区别在于新数据回答哪些谓词，以及用错时何时失败。
3. **概念：** 新的原始种类；更快的失败；模块隐藏构造器；contract；函数和 macro 都造不出新种类。
4. **机制：** `add` 的结果 `pair?` 为假。错的访问器报错。List 版的 `Add-e1` 与 `Multiply-e1` 可以互换。
5. **代码：** 对同一个 `x` 调用 `pair?`、`multiply-e1`、`cdr`。List 版则演示静默取错。
6. **执行：** struct 版在种类不对时立刻错。List 版对 Add 调用 `Multiply-e1` 得到 `Const 3`。
7. **PL：** 真正的新变体必须让旧谓词为假。这只能由内置构造提供。抽象也可以在动态语言里做：藏起构造器，客户端就无法伪造表示。
8. **误区：** 动态类型不能做数据抽象。Macro 既然能生成函数，就能实现 `struct`。Struct 的唯一好处是短。
9. **联系：** Section 5 说 macro 扩展语法、不改实现。这里补上边界：实现里“有哪些种类的值”仍要内置形式来增加。
10. **一句：** Struct 的值不是 list；所以旧的 list 操作碰它就会失败，而不是碰巧成功。

---

## 本范围小结

### 核心问题

Part A 的 datatype 把“有哪些变体、字段是什么、漏写一支是错误”放进类型系统。拿掉类型系统之后，这些事要重新分配：哪些交给语言的新数据，哪些交给程序员的约定。

### 知识地图

```text
内置标签（number? / string?）
      │
      ▼
手写标签（'Add 在 list 的 car）
      │  仍是 list，访问器可以混用
      ▼
struct
      ├── 构造器 / 谓词 / 访问器
      ├── 一种新数据，pair? 为假
      ├── 可选：REPL 打印、字段可变
      └── 可选方向：藏起构造器，加上契约
```

### 最重要的代码模式

```racket
(struct add (e1 e2) #:transparent)
(cond [(const? e) e]
      [(add? e) (const (+ (const-int (eval-exp (add-e1 e)))
                          (const-int (eval-exp (add-e2 e)))))])
```

求值函数返回表达式，不返回裸的 Racket 数。基线返回整个 `const`。

### 容易混淆

| 混淆 | 分辨 |
| --- | --- |
| 四个 struct 与一个 datatype | 没有一个类型把它们收成整体，也没有穷尽性检查 |
| Struct 与 list 编码 | 不是语法糖。一个 `pair?` 为假，一个为真 |
| 访问器与模式匹配 | 课程用谓词加访问器。用错是运行时错误，不是“非穷尽匹配”的编译错误 |
| Macro 与 struct | Macro 造语法。Struct 造一种新值 |
| `eval` 的结果 | 是对象语言的值，这里写成 `const`，不是宿主语言的裸整数 |

### 和上一 Section 的关系

Section 5 证明了没有类型检查器也能写列表递归，并用谓词区分值。本节把“区分”从语言自带的种类，推广到你自己的表达式种类。`mcons` 与普通 `cons` 不能混用，已经是“新种类让旧操作失败”的小例子。Struct 把这个想法变成定义形式。

Macro 的边界也在这里收紧：能加特殊形式，不能加一种让 `pair?` 为假的数据。

### 为下一范围准备了什么

解释器的输入就是这些 struct 组成的树。程序员用构造器把树写在 Racket 里，从而跳过“从字符串解析”。`eval-exp` 已经是一个解释器，只是语言里还没有变量和函数。下一讲先把“实现一门语言”的地图画出来，并规定：语法上不合法的树可以随便崩溃；递归得到的值种类不对，必须给出像样的错误。

---

## Engineering Connection

**【课程】** 藏起构造器、只导出操作，是动态语言里的数据抽象。Contract 可以把“子表达式必须是表达式”变成更早的失败。两者都只被点名。

**【扩展】**

- JSON 里用 `"type": "add"` 加一个对象，就是 list 编码的跨语言版本。任何代码都能伪造这个字段。Rust / ML 的 enum 更接近 ML datatype：新种类，并且匹配要穷尽。
- Python `@dataclass` 生成构造器和访问，但结果通常仍是普通实例，`isinstance` 的层次和“是否是 list”不是本节讨论的那条线。不要把 dataclass 当成课程里的 struct。
- 编译器前端的 AST 节点几乎总是“每种语法一个构造器”。本节的四个 struct 就是这个设计的最小样本。下一章会说：作业里的语言 B 程序员写的就是这种树，不是字符串。

---

## 检查题

1. 为什么 `funny-sum` 在 Racket 里不需要 datatype，而 ML 需要？“值已经有标签”指什么？
2. 课程为什么把 `eval_exp` 从 `exp -> int` 改成 `exp -> exp`？小语言的结果明明是整数。
3. `Negate` 一支的四步是什么？为什么基线要返回整个 `Const`，而不是里面的 int？
4. List 编码里，`Add-e1` 和 `Multiply-e1` 为什么可以互换还不报错？
5. 符号相对字符串，课程强调的操作是哪一个？这一节是否必须用符号？
6. `(struct foo (bar baz) #:transparent)` 向环境加入哪些函数？对不是 foo 的值调用 `foo-bar` 会怎样？
7. 为什么四个 struct 更像四个 ML 构造器，而不是一个 datatype 绑定？
8. `#:transparent` 不写时，字段还在吗？`#:mutable` 多给你什么？本课的表达式为什么不用它？
9. 怎样用一次 REPL 实验证明 struct 不是 list 的语法糖？
10. 为什么“只导出访问器、不导出构造器”在动态语言里仍然是抽象？List 编码为什么做不到？
11. Macro 能生成 `foo`、`foo?`、`foo-bar` 三个函数定义吗？即便能，课程说它仍缺哪一种保证？

## Answers

1. ML 的 list 元素必须是同一个类型，所以 int 和 string 要包进新类型的构造器。Racket 的数和字符串在实现里已经带着种类标签，`number?` 和 `string?` 就是在看标签，不必再声明一层。
2. 更大的语言里，求值结果不总是整数，可能是 pair、闭包、布尔或字符串。让 `eval` 返回“语言里的值”，而值也用表达式的构造器表示，以后就不用改这个约定。小语言里因此总是返回 `Const`。
3. 递归求值子表达式；确认结果是 `Const` 并取出 int；取负；用 `Const` 包回去。基线若只返回 int，递归的结果和其他分支的结果类型就不统一，调用者无法再用 `Const-int` 或 `const-int` 处理所有结果。
4. 因为两个函数的实现都是取 list 的第二个元素，它们不检查 car 里的符号是 `'Add` 还是 `'Multiply`。值仍是 list，访问器只是约定。
5. `eq?` 可以快速比较符号是否相同。不是必须。课程说字符串也能做标签，只是比较更慢。
6. 构造器 `foo`、谓词 `foo?`、访问器 `foo-bar` 和 `foo-baz`。不是 foo 则运行时错误。
7. 因为没有任何一个构造把四者收成“exp 的全部可能”，也不声明字段类型。每个 struct 只增加一种造值、测值和取值的办法，像 datatype 定义中的一支构造器。
8. 字段还在，只是 REPL 不打印内容，谓词和访问器仍工作。`#:mutable` 为每个字段增加 `set-...!`。表达式树用不可变数据更好，课程在能不用 mutation 时就不用。
9. `(add (const 3) (const 4))` 的 `pair?` 和 `list?` 都是假，`add?` 是真。若它是三元素 list，前两个谓词会是真。
10. 客户端拿不到构造器，就不能自己做出一个能通过 `add?` 的值，只能走你提供的、会检查不变量的函数。List 编码里，任何人都能 `list` 出一个 car 为 `'add` 的值，你的谓词若只看 car，就会把它当成 Add。
11. 生成多个函数定义也许可以用更强的 macro 做到，课程没有演示。课程强调的缺口是：macro 造不出一种新数据，使得 `number?`、`pair?` 和其他已有谓词都为假。那种“新种类”是 struct 作为内置形式才有的。
