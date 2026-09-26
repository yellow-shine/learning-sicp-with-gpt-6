# Module 14 — 函数的 Subtyping，以及 OOP 里它变成什么

老师说这可能是整门课最反直觉的结果，也正是编程语言课该教的东西。先把函数想清楚，再看 Java/C# 为什么对覆盖方法有那些限制。OOP 的版本更绕，函数版本更干净。

Source: Section 10 — Function Subtyping / 0:05–1:53。

## 两个不同的问题

容易的那个，上一篇已经解决，和“函数类型本身的 subtype”无关：

- 调用函数时，可以传参数类型的 subtype。
- 函数返回 ColorPoint 之后，你可以把它当成 Point 用。

难的那个：高阶函数的参数本身是函数。它要 `t1 -> t2`。你能不能传 `t3 -> t4`？两者必须有关系，但不能是任意关系。

这条规则也直接决定：子类覆盖方法时，参数类型和返回类型允许怎么变。

## 返回类型：可以多给

`distMoved` 接收一个函数 `f` 和一个点 `p`，调用 `f(p)`，返回 `p` 与 `f(p)` 之间的距离。

```text
f : {x:real, y:real} -> {x:real, y:real}
p : {x:real, y:real}
```

`flip` 把 x、y 都取负，返回一个点。类型正好匹配，没有 subtyping。

`flipGreen` 同样翻转 x、y，但返回的 record 多一个 `color = "green"`。它的类型是：

```text
{x:real, y:real} -> {x:real, y:real, color:string}
```

`distMoved` 要的是返回两字段点的函数。多返回一个字段没有害：调用者只读 x 和 y。所以允许：

```text
若 ta <: tb
则 t -> ta  <:  t -> tb
```

函数可以返回比需要的更多。术语：函数类型在返回类型上是 **covariant**。协变的意思是 subtype 箭头和外面的箭头同向。老师说不考这个行话，但你以后听到 covariance 指的就是“同向”。

Source: Section 10 — Function Subtyping / 1:53–4:35。

## 参数类型：不能少要，也不能按直觉的方向多要

`flipIfGreen` 要读 `p.color`，所以参数类型是 `{x:real, y:real, color:string}`。`distMoved` 传给 `f` 的点没有 color。若允许把这个函数当作 `{x:real, y:real} -> ...` 来用，运行时会读不存在的字段。因此下面这条**禁止**：

```text
若 ta <: tb
则 ta -> t  <:  tb -> t     （不允许）
```

不能因为“也许函数不需要全部字段”就丢掉参数里的字段。它可能需要。

反方向是合法的，也是反直觉的地方。函数可以比调用者以为的**更不挑剔**。

```text
若 tb <: ta
则 ta -> t  <:  tb -> t
```

`flipX_Y0` 只读 `p.x`，返回 `{x = -p.x, y = 0.0}`。它的参数类型是 `{x:real}`。`distMoved` 会传给它一个还有 y 的点。它不读 y，所以不会坏。我们假装它的参数类型是 `{x:real, y:real}`。而 `{x:real, y:real} <: {x:real}`，内层和外层的 subtype 方向相反。

`flipXMakeGreen` 把两件事叠在一起：参数只要 x，返回值多给 color。仍可传给 `distMoved`。它需要得更少，给得更多。

Source: Section 10 — Function Subtyping / 4:35–9:07。

## 一般规则

```text
若 t3 <: t1    且    t2 <: t4
则 t1 -> t2  <:  t3 -> t4
```

对照：

```text
返回类型 t2、t4：同向，covariant
参数类型 t3、t1：反向，contravariant
```

一句话：函数子类型可以少要求参数、多返回结果。

行话：function subtyping is contravariant in its arguments and covariant in its results.

Source: Section 10 — Function Subtyping / 9:07–9:45。

## 用 Animal 和 Dog 把方向走一遍

`[Supplement]` 课堂的例子是点的字段，不是 Animal/Dog。结构相同，换成你更熟的名字。设 `Dog <: Animal`。问：`Animal -> Dog` 能不能当作 `Dog -> Animal` 用？

按规则，令

```text
t1 = Animal,  t2 = Dog,  t3 = Dog,  t4 = Animal
t3 <: t1      因为 Dog <: Animal
t2 <: t4      因为 Dog <: Animal
所以 Animal -> Dog  <:  Dog -> Animal
```

为什么调用是安全的，不要只背结论。假设某处需要 `f : Dog -> Animal`，实际传入 `g : Animal -> Dog`。

```text
调用者拿着一只 Dog，把它传给 f。
g 的参数类型是 Animal。Dog 是 Animal 的 subtype，g 只依赖 Animal 的操作。
传 Dog 进去，g 不会调用 Dog 没有的东西。     ← 参数必须逆变的原因

g 返回 Dog。
调用者以为自己拿到 Animal，于是只做 Animal 能做的事。
Dog 都能做。                                 ← 返回必须协变的原因
```

反方向 `Dog -> Animal` 当作 `Animal -> Dog` 会坏两次：

```text
调用者可能传入一只不是 Dog 的 Animal，例如 Cat。
g 若是 Dog -> ...，它可能调用只有 Dog 才有的方法。

就算参数碰巧安全，g 只承诺返回 Animal。
调用者按 Dog 去用返回值，可能调用只有 Dog 才有的方法。
```

老师的原例子里，`flipIfGreen` 就是参数方向写反的失败：函数要 color，调用者传的点没有 color。`flipX_Y0` 是参数方向写对的成功：函数要的比调用者提供的更少。

## 老师的警告

很多人，包括很聪明的人，会把参数方向写反。你、你的朋友、你的老板，以后都可能写反。至少记住这里有一件怪事，可以回来重看。他的说法是：他有编程语言的 PhD，他可以跳起来坚持，函数和方法的 subtyping 在参数上必须逆变，方向不是你通常想的那个。视频里他真的把椅子挪开跳了。

Source: Section 10 — Function Subtyping / 9:58–11:11。

## OOP：用 record 和函数的理论去理解 class

`[Course]` Java/C# 的核心类型检查可以用这套理论看。声明 class `C` 就得到类型 `C`。若 `C` 是 `D` 的子类，则类型 `C` 是类型 `D` 的 subtype。因为传递性，你是层次里所有祖先的 subtype，一直到 `Object`。

替换原则因此变成：子类实例必须能用在任何出现 superclass 实例的地方，而不能让人调用不存在的方法或访问不存在的字段。这些语言里字段属于 class 定义，所以属于类型。

把对象想成 record：

- 字段名和方法名都是 record 的槽。
- 字段通常可变，所以字段类型上的 depth subtyping 不安全。覆盖时不能把字段类型改成别的。
- 方法通常不可变：你不能把一个方法槽更新成另一个函数。因此方法槽上可以有函数 subtyping。

于是一个 sound 的设计可以是：

- 子类可以**加**字段和方法。这就是 width，安全。超类型的代码不会在意多出来的东西。
- 覆盖方法时，新方法必须能用在旧方法能用的地方。参数类型逆变，返回类型协变。

Java/C# 大体如此，又做了更严的选择。更严是可以的：比 sound 所允许的更窄，不会破坏 soundness。

它们不用 `{x:real, y:real}` 这种结构类型，而用 class 名或 interface 名。这**限制**了 subtyping。你可以把 `ColorPoint` 的方法全部照 `Point` 重写一遍，但不声明继承。从可靠性看，它当 Point 用是安全的。在 Java/C# 里它不是 Point 的 subtype。名义类型要求继承或 implements 关系，不是“碰巧有那些方法”。

子类加字段、加方法：允许，和 width 一致。

覆盖方法时把返回类型改成 subtype：允许，协变，这些语言支持。

覆盖时改变参数类型，只要逆变，理论上可以。这些语言选择不做。你改了参数类型，就**不是覆盖**，而是另一个同名方法，即 static overloading。加方法总是允许的，所以这不破坏可靠性。Overloading 的挑选规则很复杂，老师不讲细节。

Source: Section 10 — Subtyping for OOP / 0:10–5:49。

### class 不是 type

若只改一个术语：class 和 type 不是一回事。Java/C# 故意混淆它们，因为每个 class 也是一个类型。仍要拆开。

```text
class   定义对象的行为。方法体，会返回东西的代码。
        Ruby 里我们定义的就是这个。每个对象有一个 class。

type    描述对象有哪些方法、参数类型和结果类型。
        “有一个 foo，接收 string，返回 object”。
        Subtype 说的是按这些方法及其类型能否替换。
```

可以有两个不对应任何 class 的类型，也可以有两个 class 没有类型上的关系。静态的、基于 class 的语言为了方便，复用 class 名当类型名：去 class 定义里把方法的参数类型和结果类型读出来，那就是这个名字代表的类型。方便，但是术语上，class 关于行为，type 关于接口。

Source: Section 10 — Subtyping for OOP / 5:49–7:39。

### 三个容易以为“类型系统坏了”的细节

都不考，但能阻止你误判。

1. 若不使用显式 downcast（课上不讲），Java/C# 在“非 null 的 receiver 一定有方法 m”这件事上是 sound 的。
2. 子类可以再声明一个同名字段，类型完全无关，仍能通过编译。看起来像 depth 被违反。实际是对象里有**两个**都叫 `foo` 的字段。superclass 的代码说 `foo` 时指 superclass 声明的那个，子类的代码指子类声明的那个。不是把一个可变字段的类型改了。感到困惑时该读语言手册，而不是继续试到以为设计者破坏了 soundness。
3. `self` / `this` 若被看成方法的一个额外参数，它是特殊的：在子类里它的类型可以是子类，这是**协变**，而普通参数必须逆变。

```text
class A
  def m; ... end          # 这里只知道 self 是 A

class B < A
  def m
    # 这里知道 self 是 B，可以读只有 B 才有的字段 x，甚至返回它
  end
```

这没有 unsound。普通参数的调用者可以传入任何符合类型的值，所以参数位置不能协变。`self` 不是调用者选的。调用 `m` 时传进去的必须是整个 receiver。执行子类的 `m` 时，self 一定是 `B` 的实例。superclass 的方法体仍然只知道它是 `A`。两段方法体对 self 的假设不同，是因为它们只在各自保证成立的 receiver 上执行。

这和 Part C 早先在 Racket 里手动编码 dispatch 是同一件事：方法比表面多一个参数，那个参数被实现绑定为整个对象，客户不能另传一个。

Source: Section 10 — Subtyping for OOP / 7:39–11:41；Section 8 — Racket encoding / 2:30–2:56。

## 三个词，再钉一次

```text
inheritance / subclassing
    方法体从哪来，覆盖哪一个，self 的查找从哪个 class 开始
    Ruby 里只有这个

subtyping
    一个类型的值能否安全地用在期待另一类型的地方
    由替换原则约束，不是由 class 关键字定义

Java/C# 的设计选择
    让 subclass 关系蕴含 subtype 关系
    并且比“结构上安全”更窄：不声明继承就不是 subtype
    参数类型的逆变覆盖被拒绝，改成 overloading
```

Go 的接口满足是结构式的，不需要声明 implements。`[Modern Connection]` 那更接近 Section 10 前半的 record 类型，而不是 Java 的名义 subtype。Rust 的 trait bound 是“必须实现这些方法”的约束，默认静态分派，不是 Java 式的 subclass 即 subtype。对照表在 `18`。

## Concept cards

### function subtyping

- Problem: 高阶函数要一个函数参数时，什么样的函数值可以替上。
- Definition: `[Course]` `t3 <: t1` 且 `t2 <: t4` 时，`t1 -> t2 <: t3 -> t4`。
- Mental model: 少要求，多返回。
- Example: `{x:real} -> {x,y,color}` 可以当作 `{x,y} -> {x,y}`。
- Misunderstanding: 参数方向和返回方向相反。只记“子类型可以替换超类型”而不看位置，一定会写反。

### covariance

- Problem: 需要一个词表示“subtype 关系在这个位置同向传递”。
- Definition: `[Course]` 返回类型是协变的。`ta <: tb` 推出 `t -> ta <: t -> tb`。
- Example: `flipGreen` 多返回 color。
- Misunderstanding: 不是所有位置都协变。数组协变是著名的错误协变。

### contravariance

- Problem: 参数位置若同向，会把太挑的函数用在太宽的输入上。
- Definition: `[Course]` 参数逆变。外层要成为 subtype，内层参数类型要成为超类型。
- Example: 只需要 x 的函数，可以装成需要 x 和 y 的函数。
- Misunderstanding: “逆变就是不能变”。不是。是必须反着变。不变（invariant）才是“必须相同”，Java 对覆盖方法的参数类型实际上选择了不变，然后把不同签名当成另一个方法。

### OOP subtyping

- Problem: class 层次怎样变成一个 sound 的 subtype 关系。
- Definition: `[Course]` 在 Java/C# 里，subclass 蕴含 subtype。允许加成员；返回类型可协变；参数类型不按逆变去覆盖。class 名同时当类型名，所以比结构 subtyping 更窄。
- Example: 不声明 `extends Point` 的彩色点，不是 `Point` 的 subtype。
- Misunderstanding: inheritance = subtyping = polymorphism。三个词在 `20` 拆开。
