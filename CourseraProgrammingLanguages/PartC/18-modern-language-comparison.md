# 现代语言对照

这一篇几乎全是 `[Modern Connection]` 或 `[Supplement]`。课程点名过的语言是：Ruby、ML、Racket、Java、C#、C++、JavaScript（作为非 class-based 的例子）、Smalltalk（和 Ruby 相近但更老更小）、Scala（试图同时支持两种扩展）、Clojure（multimethods）、OCaml、F#（给 ML 风格语言加对象）。

没有点名、不要写成老师讲过的：Rust、Go、Kotlin、TypeScript、Python、Julia、Swift。下面用它们，是因为你以后会遇到，而且课程的概念能翻译过去。

判断标准只有一条：是语义接近，还是只是看起来都有“接口”这个词。

## 一张总表

| 课程概念 | 语义上接近 | 只是看起来像 |
| --- | --- | --- |
| Ruby 一切皆对象 | Smalltalk；Python 的多数值也是对象，但不是每样东西都走同一条消息规则 | C++/Java 的 `int` 不是对象。Java 有装箱 |
| class-based | Java、C#、C++、Python class、Kotlin | JavaScript 原型。课程故意不讲 |
| dynamic dispatch | Java 实例方法，C++ virtual，Python 方法，Kotlin 默认同 Java | C++ 非 virtual；Rust 泛型方法默认单态化，不是动态查找 |
| duck typing | Python、Ruby；C++ template 在检查发生前 | Go interface、TypeScript structural type、Rust trait：有静态拒绝 |
| mixin | Ruby module；Scala trait 的 mixin 用法比较接近 | Java interface 的 default method：有代码，但是类型优先，没有 Ruby 那种“只是把方法贴进 class、没有第二个类型义务”的全部故事 |
| interface | Java/C# interface | Go interface 是结构式的，不需要 `implements` |
| abstract method | Java abstract，C++ pure virtual，C# abstract | Rust trait 里没有默认实现的方法：像义务，但是静态分派 |
| multiple inheritance | C++ | Java 没有 class 的多继承。接口多实现不是多继承 |
| multimethod | Clojure multimethod；Julia 的函数 | Java overloading |
| parametric polymorphism | ML、Java/C# generics、Rust 泛型、Kotlin | C++ template 更晚检查，错误形态不同 |
| bounded polymorphism | Java `T extends U`，C# `where`，Rust `T: Trait`，C++ concepts，Go constraints | 无约束的 `Object` 参数 |
| subtype | Java 名义 subtype；Section 10 的 record width 更像结构 subtype | Ruby 的 `is_a?` 是运行时事实，不是类型规则 |

## Ruby mixin 对应谁

`Comparable` 的形状是：宿主提供一个方法 `<=>`，mixin 提供一批用它定义的方法，并且这些方法通过 self 回调宿主。

```text
Ruby Module          运行时 include，方法进入查找链，可用 self
Scala trait          可以有方法体，可以叠加，也是类型。更富，不只是 Ruby mixin
Rust trait           可以有默认方法，默认方法能调用 trait 里其他方法。
                     通常在编译期单态化，没有 Ruby 的运行时方法表。
                     不能把“第二个 class”继承进来。和 mixin 的目的相近，语义不同
Java default method  接口可以带实现，一个类仍只有一个 superclass。
                     目的接近 mixin：在没有多继承的情况下复用方法。
                     它仍然首先是类型。冲突解决规则是 Java 自己的
```

`Enumerable` 对应 Rust 的 `Iterator`、Java 的 `Iterable`/`Stream` 辅助方法、Scala 的集合 trait：你提供“下一个元素怎么来”，库提供 `map`/`filter`。这是课程强调的分离关注点，不是 Ruby 专利。

## Dispatch

```text
只看 receiver 的运行时种类
    Ruby, Python, Java（实例方法）, Kotlin, C++ virtual

编译期按静态类型选同名函数
    Java/C++/C# overloading
    不是 multiple dispatch

多个参数的运行时类型一起选
    Julia
    Clojure multimethod（dispatch 函数可以看多个值）
    C# dynamic 是一条旁路
    C++ 没有内建的这套；double dispatch 仍要手写，或用 visitor

静态多态，看起来像“根据类型选代码”，但是编译期生成
    C++ template, Rust generic
    没有运行时 receiver 查找
```

Python 的方法查找还有实例字典、类字典、MRO。`[Supplement]` 那是另一门课。能和本课对应的只有：调用时按对象的类找，子类可以覆盖，父类方法里的 `self.m` 会进子类。

## 类型

```text
名义 subtype，subclass 即 subtype
    Java, C#, Kotlin
    不声明继承，方法再像也不是 subtype
    课程在 Subtyping for OOP 里把这说成比结构规则更窄、因而仍然 sound

结构 subtype / 结构满足
    Section 10 的 record 规则
    Go：实现了接口的方法集合，就满足接口，不必声明
    TypeScript：结构兼容，方向问题（函数参数）仍然在
    OCaml 对象系统有结构子类型；课程只说 OCaml 把对象加进了语言

没有 subtype
    ML，如课程演示的 distToOrigin 拒绝额外字段
    Rust 没有继承式 subtype。trait 是约束，不是 ColorPoint <: Point
```

Kotlin 和 Scala 在名义继承之外还有更细的型变声明（`in`/`out`，`+`/`-`）。那是把本课的协变/逆变写进类型参数。课程没讲，但你在那些语言里看到 `List<out T>` 时，应该想起：只读位置可以协变，写入位置不行。Java 的 `? extends` 是同一问题的另一个语法，课程同样没讲。

## 表达式问题在这些语言里怎么被碰

`[Modern Connection]`

- 默认 OOP（Java/Kotlin/C++）：加变体容易，加操作要用 visitor 或改接口。
- 默认 FP（ML/Haskell/Rust enum + match）：加操作容易，加变体要改旧的 match。Rust 的非穷尽检查类似 ML。
- Haskell type class / Rust trait：可以在类型定义之后为它实现新操作，旧的类型定义不用打开。这靠近“加列”。新变体若是一个新类型，旧的泛型代码不用改；若是一个 enum 里的新构造子，旧的 match 仍要改。
- Scala 被课程点名，是试图两边都好。不要记成“Scala 解决了，所以问题不存在”。老师说问题本质上难，未来的扩展永远预测不全。

## 动态与静态的 2×2，之外还有行

`[Course]` Wrap-up 强调这张表不是全部编程语言。Haskell 也是静态函数式，但几乎一切都延迟求值，因此和 ML 很不同。逻辑语言如 Prolog 是另一行，既不是函数式也不是面向对象，也不是 C 那种过程式。

```text
                静态                 动态
函数式          ML, Haskell, OCaml   Racket, Clojure 的函数式部分
面向对象        Java, C#, Kotlin     Ruby, Python, Smalltalk
其他            Rust（更像静态 FP + trait，不是这格的纯居民）
                Prolog（逻辑）
```

Rust 放不进一格。这符合老师的警告：不要以为每个语言都属于且仅属于一格。

Source: Course Wrap-up / 3:07–4:03。表中 Rust/Python/Kotlin 的位置是 `[Modern Connection]`。

## 迁移时最有用的三问

遇到一个新语言的“接口 / trait / protocol / concept”，先问：

1. 它提供代码，还是只提供义务？Mixin 与 interface 的差别在这里。
2. 满足关系是名义的还是结构的？Java `implements` 与 Go 的差别在这里。
3. 调用是运行时按 receiver 查找，还是编译期单态化？Virtual 与 Rust generic / C++ template 的差别在这里。

这三个问题都是 Part C 的问题，只是换了关键字。
