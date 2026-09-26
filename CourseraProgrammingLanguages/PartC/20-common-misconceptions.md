# Common Misconceptions

每条都是课程里实际分开讲过的两个概念。正确模型用一两句，细节在对应笔记。

## class == type

Class 定义行为：方法体在哪里。Type 描述可替换的接口：有哪些方法、参数和结果是什么类型。Java/C# 让每个 class 名也是一个类型，所以看起来相等。Ruby 没有这个类型。即便在 Java 里，interface 是类型但不是 class；两个拥有相同方法的 class，若没有继承关系，也不是彼此的 subtype。

Source: Section 10 — Subtyping for OOP / 5:49–7:39。

## subclass == subtype

Subclassing 是方法表的继承与覆盖。Subtyping 是“这种值能否用在期待那种值的地方”，标准是 substitutability。Ruby 一周里只有前者。Java 选择让前者蕴含后者，并且比结构上安全的范围更窄。坏的 is-a（有争议的 3D 点）仍可以是 subtype，因为类型系统不判断概念是否合理。

## inheritance == polymorphism

继承是复用和覆盖的机制。多态是“一份代码用于多种数据”的结果。你可以有继承而调用仍静态绑定（C++ 非 virtual，`[Modern Connection]`）。你也可以有多态而没有继承：ML 的 `'a list`，Ruby 的 duck typing，Java 的 generics。

## dynamic typing == dynamic dispatch

前者问错误何时发现。后者问 `e.m` 选哪段方法体。Java 是静态类型加 dynamic dispatch。一段 Ruby 程序可以动态类型，却在方法里用 `instance_of?` 避开 duck typing。运行时改 class 是第三个概念。见 `00`。

## block == Proc

Block 不是对象，不能存储，callee 只能 `yield`。`lambda` 把 block 变成 `Proc`，然后可以 `call`、放进数组、从方法返回。常见情况用 block 更方便；能力更大的是 Proc。

## Proc == method

Proc 是一个值，谁拿到谁调用，环境在制造时捕获。Method 属于 class 的方法表，通过 receiver 查找，执行时 `self` 是这次的 receiver。你可以把方法包成 Proc，`[Supplement]` Ruby 有 `method(:foo).to_proc` 这类办法，课程没讲。概念上它们仍是两种调用。

## duck typing == structural static typing

都是“看有什么，不看名字”。结构子类型仍会在运行前拒绝缺字段的程序，并保证通过的程序不会做那种访问。Duck typing 没有这层保证。文档可以薄到等于方法体。`x + x` 与 `x * 2` 因此不再是安全的程序变换。

## generics == subtyping

`'a -> 'a` 说两端类型相同，不说一端是另一端的 subtype。`f(Animal)` 说可以传 subtype，不说返回的和传入的是同一个具体类型。用 `Object` 加 downcast 做 pair，是拿 subtype 冒充 generics。用不受约束的类型变量做 `inCircle`，方法体无法调用点的方法。

## override == overload

Override：同名，替换继承来的方法，调用时按 receiver 的运行时 class 可能选到新的。Ruby 里同名就是 override。

Overload：多个同名方法并存，Java/C#/C++ 按参数的**静态**类型选。改了参数类型在这些语言里常常根本不是 override。它对课程里的九格加法帮助有限：你仍需 double dispatch，最多让三个方法都叫 `add`。

## double dispatch == calling two methods

随便调两个方法不是 double dispatch。结构是：第一次按左操作数选 `add_values`；该方法根据**自己所在的 class** 向右操作数发送 `addInt` 或 `addString` 或 `addRational`，并把 self 传过去；第二次按右操作数选九格中的一格。方法名携带第一次的结果。`v.add_values(self)` 会无限递归，因为名字没有携带“我是谁”。

## is_a? 分支也是 OOP

课程拒绝这个说法。前一半 dispatch 是 OOP，后一半按 class 做条件分支是函数式的 `cond`。作业不允许用它代替 double dispatch。`is_a?` / `instance_of?` 的合法用途是理解语义，不是业务代码里的类型开关。

## `e.foo = 1` 是字段赋值

在 Ruby 里这是对方法 `foo=` 的调用，空格是糖。因此 setter 可以写入另一个实例变量，例如摄氏接口、开尔文表示。封装依赖这一点。

## 实例变量会随 subclass 继承

在 Java/C++ 里字段属于 class 布局，子类对象包含它们。在 Ruby 里 class 不声明字段。没有赋值过的 `@x` 就是没有，读到 `nil`。`PolarPoint` 可以没有 `@x`。

## 继承来的方法会调用父类版本的 self.x

不。执行时 `self` 是 receiver。查找从 receiver 的 class 开始。`Point#distFromOrigin2` 在 `PolarPoint` 上会调用 `PolarPoint#x`。直接读 `@x` 才会停在对象自己的状态上，那不是方法查找。

## 遮蔽一个函数会更新已经造好的闭包

ML 的后一个 `even` 不影响旧的 `odd`。闭包用定义时的环境。Ruby 子类覆盖 `even` 会影响继承来的 `odd`。这是对照，不是闭包规则的漏洞。

## 加操作对 OOP 容易，因为“类里写方法很自然”

自然的是把一种数据的操作放在一起，也就是加变体。加操作要打开每一个已有的 class。方向反了是这门课最常见的记忆错误。表的方向以课程为准：行是变体，列是操作；FP 按列，OOP 按行。

## Visitor 已经让 OOP 在两个方向都容易

Visitor 要求每个 class 预先留接受 visitor 的方法。那是规划之后的补丁，不是默认布局。而且新变体通常要改所有 visitor。课程只点了名字，说讲完太长。它也不取消“预留扩展让推理变难”。

## Depth subtyping 显然该有，因为球的圆心是一种点

只在不写入该字段时成立。`setToOrigin` 会把 center 换成没有 `z` 的 record，静态类型却还承诺有 `z`。有 setter、要 sound，就不能要那条 depth 规则。Java 数组协变是这个错误；补救是每次存储可能抛 `ArrayStoreException`，不是类型系统真的证明了写入安全。

## 函数参数也协变，因为“子类型更能用”

位置反了。调用者会传入超类型所允许的任何参数。函数若比这更挑剔，就会看到自己没有准备的值。安全的方向是函数更不挑剔，也就是参数逆变。返回值才是协变：可以多给。

## `self` 若是参数，也必须逆变

它不是普通参数。调用者不能另选一个对象传进来。子类方法执行时，self 一定是子类实例，所以这里协变是 sound 的。Racket 编码里那个多出来的参数由 `send` 绑定为整个对象，表达的是同一事实。

## `List<ColorPoint>` 是 `List<Point>` 的 subtype，因为元素是

对可变列表，课程说明这不安全：函数可能往里放入普通 Point，或在结果里造出一个没有 color 的 Point。有界泛型是绕开这个事实，不是宣布列表协变。`T extends Point` 的实例化不是一次 subtyping 强制转换。

## Mixin 是没有方法体的接口，或是完整的多继承

Mixin 有方法体，所以不是 interface。它不是 class，不能 `new`，也做不到“Artist 和 Cowboy 都是 class 时同时继承”。`Comparable` 靠你提供 `<=>`，`Enumerable` 靠你提供 `each`。字幕后段把后者说成 Comparable，是口误。

## Ruby 的同名方法就是 multimethod

一个 class 不能同时有两个同名方法，再定义就是替换。方法定义也不声明参数 class。Multimethods 需要这两件事。Clojure 有。Java 的同名方法是 static overloading。

## 一切皆对象意味着没有 nil 问题

`nil` 是对象，这让语言更统一。它仍然在条件里算假，仍然会在你对它调用 `+` 时失败。统一的是对象模型，不是“空引用消失了”。Java 的 `null` 更糟的一点是它在类型上被当成一切的 subtype，于是每次调用都可能空指针。那是另一门语言的设计，课程在数组可选讲里批评过。

## 动态语言更简单，所以方法调用的语义更简单

老师把这说成事实而不是口味：Ruby 的方法调用规则比 ML/Racket 的函数调用更复杂，因为 `self` 要用另一套查找。动态改 class 还会引入静态语言根本不存在的问题，例如旧对象看新方法还是旧方法。复杂不等于劣，也不等于优。
