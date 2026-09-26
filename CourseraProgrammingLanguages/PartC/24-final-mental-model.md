# 最终思维模型

Part C 要你带走的不是 Ruby 语法表，而是一套判断：这段代码在选哪一种“行为从哪来”，以及这个选择让以后的修改落在哪一边。

下面每个问题都先给能直接复述的答案，再给不该说错的那一句。来源在各模块笔记里，这里不再重复贴时间戳。

## What is dynamic dispatch?

`x.draw()` 不是“变量 `x` 里有一个函数 `draw`”。先求值 `x`，得到 receiver。从它运行时的 class 开始找 `draw`，没有就沿 superclass 走。找到后执行，并且 `self` 就是这个 receiver。

因此定义在父类里的方法，若向 self 发消息，仍可能执行子类覆盖的版本。`PolarPoint` 继承 `distFromOrigin2` 却算出极坐标距离，就是这条规则，不是父类方法被复制进了子类。

不要把它说成动态类型。Java 的实例方法、C++ 的 virtual，都是静态类型下的 dynamic dispatch。

## Why are closures and objects related?

两者都是代码加上外界不该拆开的数据。闭包的数据在环境里，对象的数据在实例变量里。到这一步，相似是真的。

调用规则不同，相似就停。闭包在制造时按词法作用域固定它会调用的函数。对象的 `self.m` 在调用时才查找。所以 ML 里后写的 `even` 不影响旧的 `odd`；Ruby 里子类的 `even` 会改变继承来的 `odd`。这是不改旧代码就能扩展行为的原因，也是不能孤立阅读一个方法的原因。

Racket 可选编码把差别收成一行：方法就是多一个参数的函数，`send` 把整个对象传进那个参数。没有这个额外绑定，就没有 dynamic dispatch。

## What is the difference between subclassing and subtyping?

Subclassing 是实现关系：方法表从哪继承，哪个同名方法替换它。Ruby 一周只有这个。它不建立类型。

Subtyping 是替换关系：`t1 <: t2` 当且仅当 t1 的值能用于 t2 的值能用于的每一种方式。类型系统只加一条规则：有子类型的表达式也有超类型。

Java/C# 让 subclass 蕴含 subtype，并且要求你声明这个关系。方法再像，不 `extends` 就不是 subtype。这比结构规则更窄，所以仍然 sound。它也不检查 3D 点当 2D 点的子类是否是好的 is-a。三个词——subclass、subtype、is-a——经常被语言和程序员绑在一起，定义不同。

## Why do FP and OOP decompose programs differently?

因为要填的是同一张表，而源文件是线性的。行是数据变体，列是操作。函数式让一个函数拥有一整列，用模式匹配填格子。面向对象让一个 class 拥有一整行，用方法填格子。

它们相反，所以看起来像两种世界观。把表画出来之后，它们是同一次填表的两个方向。写解释器时按列更自然；写 GUI 时按行更自然。这可以是口味。一旦你知道软件会往哪边长，就变成工程选择。

## Why is adding operations easy in FP but harder in OOP?

新操作是新的一列。函数式写一个新函数，旧函数不改。面向对象的代码按行切开，新操作要在每个已有 class 里加一个方法。

静态类型会帮倒忙的那一边：ML 在你加变体时列出非穷尽匹配；Java 在你给父类加抽象方法时列出没实现的子类。帮助出现在困难的那个方向，不是容易的那个方向。

## Why is adding variants easy in OOP but harder in FP?

新变体是新的一行。面向对象新写一个 class。旧 class 若只是向子对象发消息，dynamic dispatch 会在运行时进新 class，旧方法体不用改。

函数式的 datatype 多一个构造子，每一列的 case 都要补。通配模式会让类型检查器不再提醒你。

没有预先留口时，两种容易不能同时拥有。Visitor 和 `other` 分支是预留之后的补丁，课程只点到名字。预留本身让推理变难，所以 ML 模块和 Java `final` 用来禁止扩展。

## Why do we need double dispatch?

一次 dynamic dispatch 只看 receiver。加法的正确格子取决于左值和右值两个运行时种类。问 `v.is_a?` 能算出答案，但后一半已经不是 OOP。作业禁止这条路。

做法是让左边根据自己是谁，向右边发送不同名字的消息，并把 self 传过去。第二次查找按右边的 class 进行。方法名携带第一次分派的结果。`v.add_values(self)` 不行，因为名字没携带“我是谁”，还会无限递归。

若语言按所有参数的运行时 class 选同名方法，这套手工技巧不需要。那是 multimethod。Ruby 没有，因为它不声明参数 class，也不允许同名方法并存。Java 的同名方法是静态重载，帮不上这九格。

## What problem do mixins solve?

一份方法想进入多个 class，而这些 class 已经各有一个 superclass。复制粘贴零复用。多继承做得到，但方法选谁、字段要一份还是两份，会变成语言必须回答的语义题。`ColorPt3D` 要一份坐标；`ArtistCowboy` 要两个 pocket。

Mixin 只加入方法，不成为第二个 superclass。它强在方法体里的 self 可以回调宿主必须提供的那个方法：`<=>` 或 `each`。因此它不是 interface。Interface 不给代码，只给静态类型一个更灵活的名字。Abstract method 不给新的运行时能力，只让“子类必须填这个洞”在编译期被检查。C++ 同时有多继承和 pure virtual，所以不必再发明 interface。

## What is function subtyping?

高阶函数要一个 `t1 -> t2` 时，什么样的函数值可以替上。规则是：参数更宽、结果更窄的函数，可以当作参数更窄、结果更宽的函数用。

```text
t3 <: t1  且  t2 <: t4
则  t1 -> t2  <:  t3 -> t4
```

返回协变：可以多给字段，调用者不用的字段无害。参数逆变：函数必须更不挑剔，因为调用者会传入超类型所允许的任何参数。

## Why are function arguments contravariant?

假设需要 `Dog -> Animal`，你传入 `Animal -> Dog`。调用者拿着 Dog。`Animal -> ...` 只依赖 Animal 的操作，Dog 都有，所以参数安全。它返回 Dog，调用者只按 Animal 使用，所以返回安全。

反过来，`Dog -> Animal` 当作 `Animal -> Dog`：调用者可能传入 Cat，函数却可能调用只有 Dog 才有的方法；返回值只承诺 Animal，调用者却可能按 Dog 使用。`flipIfGreen` 就是参数方向写反的运行时失败：函数要 color，调用者传的点没有。

`self`/`this` 是例外，允许协变。它不是调用者选的参数。执行子类方法时，它一定是子类实例。

## What is the difference between generics and subtyping?

Generics 说：对某个类型工作，而且类型变量出现多次的地方必须是同一类型。函数体不能调用那个类型的方法，除非另加约束。`'a -> 'a` 和 `<T> T identity(T x)` 是这种。

Subtyping 说：我需要 Animal 的行为。你有更多东西没关系，只要 `<:` 成立。函数体可以调用 Animal 的方法。它不保留“你实际传入的是 Dog”这个更精确的类型，除非你用别的机制。

用 `Object` 加 downcast 做 pair，是拿 subtype 冒充 generics：写入方便，读出失去类型。用不受约束的类型变量做“画一个点”，是拿 generics 冒充 subtype：方法体写不出来。ML 拒绝多一个 color 字段，就是因为它有 generics 的相等，没有 subtyping 的忘掉字段。

## What is bounded polymorphism?

同一次签名里两句都要说真：进去和出来是同一个 `T`；`T` 至少是 Point，否则不能判断点是否在圆内。

```text
对所有 T <: Point， List<T> -> List<T>
```

`List<ColorPoint>` 不是 `List<Point>` 的 subtype。可变集合若协变，函数可能往里放入普通 Point，或在结果里造出一个没有 color 的 Point。有界泛型不宣布这个转换合法。它在调用时把 `T` 实例化成 `ColorPoint`，结果类型因此仍是 `List<ColorPoint>`。

Java 的 `extends`、Rust 的 trait bound、C++ 的 concepts、Go 的 constraint，是同一形状的不同约束语言。课程只讲了 Java/C# 这一形，并说 C++ template 算某种程度上有。Java 泛型还能被 cast 绕过，所以没有 ML 那么铁。

## How do ML, Racket, and Ruby expose different language-design ideas?

ML 把静态类型、模式匹配、闭包和参数多态做成默认。它不友好于“自己编码 dynamic dispatch”，也不接受多一个字段的 record。它把一种风格支持得很好。

Racket 保留函数式和闭包，去掉静态类型。于是解释器、延迟求值、以及手动把 dispatch 写成“多传一个 self”都方便。没有类型系统挡路，也没有类型系统帮忙。

Ruby 把对象做成没有例外的模型，方法调用默认动态查找，class 还能在运行时改。它让你看见 dispatch 比函数调用更复杂，也让 `x + x` 和 `x * 2` 不再是安全的等价变换。它不声明参数类型，所以没有 interface，也没有 multimethod。

三门语言一起，才看得出类型系统会偏向一种编程风格。Part C 的最后一周是在静态类型内部把 OOP 需要的 subtyping 和 FP 需要的 generics 都摆上，再给一个两者的乘积。

## How do these ideas appear in C++, Rust, Go, Java, and Python?

- C++：virtual 是 dynamic dispatch，默认却不是。非 virtual 更接近关闭的调用。公有继承同时被用来做复用和 subtype 转换。多继承要回答课程里的字段份数问题。Pure virtual 加多继承代替 interface。Template 是滞后检查的静态多态，历史上接近 duck typing；concepts 才接近有界多态。
- Java：名义 subtype，subclass 即 subtype。实例方法动态分派。同名方法是静态重载。Interface 是单继承之下的额外类型资格。Generics 与 `T extends` 是课程最后两讲的语法。数组协变是 depth 规则的错误实例，用 `ArrayStoreException` 补。
- Python：和 Ruby 同一格的动态 OOP。方法查找在调用时按类发生，父类方法里的 self 会进子类。契约默认是 duck typing。没有课程那种静态 subtype 证明。
- Go：接口满足是结构式的，不必声明 implements。这更接近 Section 10 的 record 规则，不是 Java 的名义继承，也不是 Ruby 的 duck typing。接口方法的调用仍是动态分派。
- Rust：trait bound 是约束，不是 `ColorPoint <: Point`。泛型默认编译期单态化，不是 vtable。`dyn Trait` 才是动态分派。Enum 加 match 更像 ML 的按列分解。它放不进课程那张 2×2 表的一格。老师说过，那张表本来就不是全部语言。

这些对照除 Java/C++ 中课程点名的部分外，都是现代语言迁移，不是字幕原话。

---

## Counterintuitive Ideas

### 对象和闭包深相似，调用却相反

相似来自“代码加私有数据”。反直觉在于：子类不改父类方法的源码，也能改变它的行为。闭包做不到。正确模型是查找起点是 receiver，不是写下方法的那个 class。

### Subclassing 不是 subtyping

反直觉是因为 Java 用同一个名字、同一个 `extends` 做两件事。正确模型是：一个关于方法从哪来，一个关于替换是否安全。Ruby 只有前者。名义类型还可以比结构上安全的范围更窄。

### FP 和 OOP 沿相反方向切同一张表

反直觉是因为两种风格的教材像两种宗教。正确模型是网格的行列。加操作和加变体的难易因此对调。记不住时画出 `Int/Add/Negate` 对 `eval/toString/hasZero`，不要背口诀。

### 动态类型不是动态分派

反直觉是因为 Ruby 两样都有，一次 `x.m` 又同时发生。正确模型是四个问题四张表：何时报错，选哪段代码，方法表能不能变，契约是不是 class 名。

### 函数参数的 subtype 方向是反的

反直觉是因为“Dog 更能当 Animal 用”，于是以为任何位置放 Dog 都更安全。参数位置上，更安全的是函数不在乎它收到的是不是 Dog。返回位置才是 Dog 更能用。老师跳起来强调的就是这个。

### Generics 和 subtyping 不能互相代替

反直觉是因为两者都叫多态。正确模型是：一个强制类型相等，一个允许忘掉多余的东西。容器要相等；“彩点当点用”要忘掉。两个都要，才是有界多态。`List<ColorPoint>` 仍然不是 `List<Point>`。

### 更动态不一定更简单

反直觉是因为少了类型声明像是少了规则。方法调用比函数调用多一套 self 的查找。运行时改 class 还会制造“旧对象看新方法吗”这种静态语言没有的语义题。复杂不等于更好或更坏。

---

## Worth Memorizing

这些短，而且方向记反会全盘错。

```text
方法查找：receiver 的 class，再 superclass；self = receiver
实例变量：只在 self 这个对象里找；没有则 nil
FP 按列，OOP 按行
加操作：FP 易。加变体：OOP 易
函数子类型：参数逆变，返回协变
width：字段多的 <: 字段少的
depth + setter + sound：三选二
List<Sub> 不是 List<Super>（可变集合）
有界多态：∀ T <: U.  List<T> -> List<T>
block 不是 Proc；override 不是 overload
Ruby 只有单分派；同名即替换
```

术语对照也值得记：late binding / virtual method 就是 dynamic dispatch。C++ 的 pure virtual 就是 abstract method。`is_a?` 含祖先，Java `instanceof` 像它，不像 `instance_of?`。

## Worth Understanding

这些背下来没有用，要能在一个新例子上走。

- 一次调用的求值顺序，以及为什么 `self = receiver` 就实现了动态分派。
- `PolarPoint` 和 `even`/`odd` 两段跟踪。一个说明继承方法回调覆盖方法，一个说明这和闭包的词法作用域相反。
- 九格加法的两次分派，包括 self 在右边。
- `setToOrigin` 怎样用一次写入破坏 depth subtyping。
- `Animal -> Dog` 为什么能当作 `Dog -> Animal`。把 Dog/Cat 代进去，不要只背箭头。
- `inCircle` 的两种失败签名，以及有界版本为什么不是列表协变。
- 闭包、对象、datatype 分支、子类方法，是四种“把行为放在某处”的办法。选择哪一种，决定了以后改动要打开哪个文件。

Programming Languages 这门课的成绩和以后写程序的差别，都在第二份清单上。Ruby 的 `attr_accessor` 和 `do/end` 可以查文档。逆变方向和分解方向查文档也行，但查的时候如果你没有模型，你会查到一句你以为懂了的行话。

## 读完之后应该能做的一个动作

拿到一段不认识的代码，先问：

```text
1. 行为是函数值、方法表，还是模式匹配的分支？
2. 选择发生在定义时、编译时，还是调用时？
3. 私有数据在环境里、实例变量里，还是构造子的参数里？
4. 以后更可能加一种数据，还是加一种操作？
5. 若有类型：它在强制相等，还是在允许忘掉字段？参数位置的方向有没有反？
```

五问都有课程里的机制对应。答完，语言的关键字只是这五问的表面。
