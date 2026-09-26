# 16 — 同一概念，三种表达

对照的不是语法。是同一个编程语言概念在 SML、Racket、Ruby 里落在哪条规则上。第四列偶尔出现 Java / C#，因为课程的 2×2 表把那一格留给它们，而不是因为它们被讲成第四门主语言。

“像”都是概念类比。表后面写明不像的地方。

## 总表

| Concept | ML | Racket | Ruby |
|---|---|---|---|
| Typing | 静态。可省略注解，推断仍在运行前拒绝程序 | 动态。错误留到那条表达式求值。教学模型：一个带 tag 的大类型，不是零个类型 | 动态。Duck typing：问能不能响应消息，不问是不是某个类 |
| Scope | 词法。函数值因此是闭包 | 词法。`set!` 改的是闭包已捕获的格子，不改成动态作用域 | 词法用于 block / Proc 的自由变量。方法体里的 `self` 不按词法捕获 |
| Mutation | 默认没有。`ref` 是显式盒子。list / tuple 不可变 | `cons` 不可变。`set!` 改绑定的格子。`mcons` 才是可变 pair | 对象字段默认可变。别名可观察。赋值不是 rebinding |
| Functions | 一等闭包。每个函数恰好一个参数。多参数是 tuple 或 currying | 一等闭包。调用是 `(f e1 e2 ...)`，括号是树节点 | 方法不是一等的。Block 是 second-class 闭包。Proc 才是一等闭包 |
| Closures | 代码 + 定义时环境。类型不提到环境 | 同左。解释器里就是一个 struct：代码、参数、环境 | Block / Proc 捕获词法环境。方法不是这种闭包 |
| Data | each-of：tuple / record。one-of：datatype。list 和 option 是 datatype | 没有 datatype binding。异构 list 靠运行时 tag。`struct` 造新 tag，不是 list 的糖 | 类是数据加方法。one-of 用类层次，没有穷尽检查 |
| Abstraction | signature 可把类型变成抽象类型。客户不能造表示 | 闭包隐藏环境。模块默认私有，`provide` 才公开。struct 的新 tag 使错用 accessor 失败 | `@` 字段总是私有。公开的是方法。不公开类则客户依赖消息 |
| Modules | `structure` 是实现，`signature` 是边界。同签名的抽象类型是不同类型 | 一个文件一个 module。本课不深入 Racket 的契约 | `module` 是 mixin，不是 ML 的 signature。同名不同机制 |
| Objects | 没有。可用 record of closures 模拟打包，没有动态派发 | 可用闭包编码对象。`send` 把对象当额外参数传入，才有派发 | 一切皆对象，包括数和类。类可重开 |
| Dispatch | 闭包在创建时已选定代码。后来的遮蔽看不见 | 同左。解释器调用闭包时用保存的环境，不用调用点的环境 | 调用时从接收者的类向上查找。`self` 绑成接收者。覆盖对继承方法可见 |

## Typing

ML 不写类型，仍然静态。Racket 写注释，仍然动态。Ruby 的 duck typing 使 `x + x` 和 `x * 2` 不再是等价变换：方法体就是契约，另一个对象可以让两者行为不同。

Weak typing 不在这三列里。C 可以静态却弱：检查通过之后仍可能把位模式当成别的类型用。Racket 动态却会在 tag 不对时失败，不是静默重解释。见 `11-static-vs-dynamic-typing.md`。

## Scope 与 Closure

三门语言的自由变量都按定义处查找。分歧在“调用时还会不会再选一次代码”。

- ML / Racket：不会。`odd` 闭包里的 `even` 是定义时那一个。
- Ruby：方法调用会。父类的 `odd` 调用 `even` 时，按接收者的类再找。子类覆盖 `even`，父类代码的行为变了。

所以“Ruby 也有闭包”是真的，指的是 block 和 Proc。它不意味着方法查找是闭包查找。见 `04` 和 `12`。

## Mutation

| 观察 | ML | Racket | Ruby |
|---|---|---|---|
| 共享 list 尾巴 | 客户不可见 | 普通 `cons` 同样不可见 | 数组和字段默认可写，共享就是语义 |
| 需要共享更新时 | `ref`，类型里看得见 | `set!` 或 `mcons` | 直接改 `@` 字段 |
| 闭包捕获之后再赋值 | 只有捕获的是 `ref` 才看得见写 | `set!` 改的就是那个格子，闭包看得见 | block 捕获的变量可写，别的引用也看得见 |

Section 10 的回流：可变则 depth subtyping unsound。ML 的默认使这条规则可以安全。Ruby 没有静态子类型，所以不在编译期犯这个错，也不在编译期防止它。Java 数组两者都沾：允许协变，写入时再检查。

## Functions

`int * int -> int` 在 ML 里是一个吃 pair 的函数。`int -> int -> int` 是吃一个 `int`、返回函数。Racket 的 `(define (f x y) ...)` 看起来像两个参数，语义仍是一个闭包，调用时两个参数都先求值。Ruby 的方法有参数列表，另外还有一个可选的 block。Block 不是多出来的那个普通参数。`yield` 调用它。要把它存下来，得变成 Proc。

部分应用在 ML 里是少写参数。在 Racket 里可以手写 `(lambda (y) (f 1 y))`。在 Ruby 里更常写成闭包或 Proc，语言不把方法默认 currying。方便程度不同。能编码，不表示惯用法相同。

## Data 与 one-of

ML 的 datatype 把 variant 收进一个类型，`case` 能警告没覆盖的构造子。Racket 的 `struct` 给值一个新 tag，错用 accessor 会失败，但没有穷尽检查：你没写的分支就是你没写。Ruby 的类层次把 variant 收成子类。没覆盖的操作要到有人向那个对象发消息才失败。

这就是 expression problem 的数据一面。加 variant：Ruby 加一个类，旧方法若只发消息则不用改。加操作：ML 加一个函数。见 `13`。

## Abstraction

三道边界藏的东西不同。

- ML signature 可以藏类型本身。客户有 `rational`，没有 `int * int`。两种实现因此可以等价。
- Racket 闭包藏环境。函数类型是 `int -> bool`，阈值不出现在类型里。`provide` 藏的是名字，不是一个由类型系统强制的表示。
- Ruby 的 `@` 字段对任何其他对象都不可见，包括子类以外的代码。公开方法是边界。Mixin 把实现插进来，不是把表示藏起来。

C++ 的 public header、Java interface、Rust 的 `pub`、Go interface，各自只覆盖这张表的一部分。不要因为都叫“接口”就当成 ML signature。多数不隐藏表示类型，也不禁止客户依赖具体类。

## Dispatch

```text
ML/Racket 调用闭包：
  代码已经在闭包里
  环境是定义时的环境加参数

Ruby 调用方法：
  求出接收者
  从接收者的类向上找方法名
  self 绑成这个接收者
  方法体里再发的消息再次查找
```

用 Racket 手写对象时，不把对象当作额外参数传进去，得到的是闭包，不是派发。这个对照是 optional 讲的全部目的。

## 一张 2×2，不要再加第三根轴进去

|  | 函数式分解 | 对象分解 |
|---|---|---|
| 静态 | SML。也是 OCaml / F# / Haskell 的大致格子，Haskell 另有惰性 | Java / C#。子类型和泛型都有，所以有第 14 章的问题 |
| 动态 | Racket | Ruby |

静态 vs 动态，不是函数式 vs 对象。SML 和 Racket 分解轴相同，类型轴不同。Racket 和 Ruby 类型轴相同，分解轴不同。把“Ruby 动态，所以和 Racket 一样”说成结论，会漏掉派发。把“Java 有类，所以和 Ruby 一样”说成结论，会漏掉子类型规则和名义类型。

## 现代语言对照时先问哪一格

- Scala、Kotlin、Rust、Swift 常常两格都占：有代数数据类型和模式匹配，也有对象或 trait，也有子类型或另一套界。不要问“它是 ML 还是 Java”。问它的某个构造在用哪一条规则。
- TypeScript 是结构子类型加逐渐补上的静态检查。它不是 Ruby，也不是 Java。
- Go 的 interface 是结构匹配，方法调用仍是动态派发的一种。泛型是后加的。空 interface 曾经扮演 `Object`。
- JavaScript 是动态的、基于原型的对象，加上一等闭包。课程故意不讲原型。不要把 Ruby 的类继承讲成 JS 的原型链。

换语言时用 `19-final-mental-model.md` 的十二问，不要用这张表的某一行当全部。表只说明这门课已经把哪些让步摆开过。
