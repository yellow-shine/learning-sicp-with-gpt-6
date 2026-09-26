# Module 16 — Bounded Polymorphism

## Problem

上一篇把两种工具分开了。有的函数两样都要，只用一个会类型检查失败，或者失去你关心的类型。

语言可以同时拥有 generics 和 subtyping。Java 有，C# 有，C++ 的 template 算某种程度上有。有趣的不是“有时用这个、有时用那个”，而是**同一次**类型里两者都出现。

这个组合叫 bounded polymorphism：

```text
任意类型 T1，但 T1 <: T2
```

ML 的 `'a` 只说任意类型。Java 的 `extends` 只说一个具体的 subtype 关系。合在一起才是“任意的、但是 Point 的 subtype 的 T”。

Source: Section 10 — Bounded Polymorphism / 0:16–1:16。

## 一个方法，两种失败

`inCircle` 接收一列点、一个圆心、一个半径，返回落在圆内的那些点。Java 签名，若你不熟悉这门语言，老师带读的是形状，不是要你写 Java：

```text
List<Point> inCircle(List<Point> pts, Point center, double radius)
```

实现很短：新建空集合，遍历 `pts`，在圆内就加入结果。它假设 Point 有某些方法。你不必看懂循环，只要看见这是一个简单方法。

现在你有 `List<ColorPoint>`，想得到圆内的那些彩色点，类型仍是 `List<ColorPoint>`。

### 只用 subtyping：被正确地拒绝

`List<ColorPoint>` 不是 `List<Point>` 的 subtype。理由就是 depth subtyping 那一讲，加在可变集合上。

就算这个 `inCircle` 的实现实际上会返回彩色点，类型检查器不知道。它只看见参数类型是 `List<Point>`。函数完全可能 `new` 一个坐标为 (2,4) 的普通 Point 放进结果。那个点没有 color。若因此把结果当成 `List<ColorPoint>`，后面读 color 就不安全。

第二，和 setter 相同的问题：不能信任 `inCircle` 不往**输入**列表里加入普通 Point。那会破坏调用者的 `List<ColorPoint>`。

所以不能靠“列表协变”把旧方法重用到彩色点上。Java 和 C# 拒绝，是对的。

Source: Section 10 — Bounded Polymorphism / 1:13–4:11。

### 只用 generics：方法体写不出来

```text
<T> List<T> inCircle(List<T> pts, Point center, double radius)
```

对彩色点很好：把 `T` 实例化成 `ColorPoint`，进去和出来都是 `List<ColorPoint>`。对 `Point` 也行。

但 `T` 可以是 `Integer`、`String`、`Foo`。方法体需要把元素当 Point，调用点的方法或读点的状态。未知的 `T` 上做不到。方法体不能通过类型检查。

Source: Section 10 — Bounded Polymorphism / 4:11–5:26。

## 两者叠在一起

```text
<T extends Point>  List<T> inCircle(List<T> pts, Point center, double radius)
```

老师在解释时把约束写成 `where T <: Point`，并说明那不是 Java。意思是：

```text
给定 List<T>，返回 List<T>
并且假定 T <: Point
在这个假定下，方法体可以像原来那样把元素当点用
```

调用者不能把 `T` 实例化成任意类型，但可以实例化成 Point 的任何 subtype：`Point`、`ColorPoint`、若 `ThreeDPoint <: Point` 也可以。不能是 `String`、`Foo`、`Int`。

```text
generics     List<T> 进，List<T> 出。彩色点不会被擦成普通点。
subtyping    T 被约束成 Point 的 subtype。方法体可以调用 Point 的操作。
```

这就是 bounded polymorphism。例子要有说服力；同类需求很多。你需要记住的是这个高层组合，不是某一种语法的每个角括号。

Source: Section 10 — Bounded Polymorphism / 5:19–6:48。

## Java 的真实语法，以及它不那么干净的地方

`[Course]` 能编译的形状是在方法左边写类型参数，用 `extends` 表示 subtype 约束：

```java
<T extends Point> List<T> inCircle(List<T> pts, Point center, double radius)
```

还要承认：generics 在别的语言里那些好性质——“不管 T 是什么，方法行为相同”——在 Java 里并不完全成立。为了向后兼容，也为了沿用 Java 一贯的实现方式，总有办法用 cast 绕过泛型的静态检查，得到更常规的泛型处理下不该出现的奇怪结果。

这可以接受。Java 的设计约束很多。用得规矩时，generics、以及和 subtyping 组合成的 bounded polymorphism，仍能守住很好的不变量，例如这里的 `inCircle`。

Source: Section 10 — Bounded Polymorphism / 6:48–7:58。

`[Supplement]` 老师说的实现方式就是类型擦除：运行时 `List<T>` 大体上是原始的 `List`，cast 可以骗过编译器。课程没有讲擦除的机制，考试不需要。需要的是“Java 的泛型可以被 cast 绕开，所以没有 ML 那么铁”。

## 和别的语言里类似的约束

都是 `[Modern Connection]`，不是课堂代码。

| 写法 | 在说什么 |
| --- | --- |
| Java `<T extends Point>` | 任意 T，且 T 是 Point 的 subtype。名义关系 |
| C# `where T : Point` | 同上。老师说 C# 也有这个组合，没写语法 |
| Rust `T: Trait` | 任意 T，且 T 实现 Trait。通常静态分派。约束的是行为，不一定有继承 |
| C++20 `requires` / concepts；更早是 `enable_if` 和文档 | template 直到实例化才检查。concepts 把“T 必须能这样用”写成可诊断的约束。老师只说 C++ template “kind of” 同时有 generics 和 subtyping，没有讲 concepts |
| Go type parameter + constraint | 任意 T，且 T 满足某个接口或类型集合 |

共同点是 parametric polymorphism 加上一个约束，使函数体可以调用约束所承诺的操作，同时返回类型里仍保留 T，而不是擦成约束的上界。

若只写 `List<Point>`，彩色点的颜色在类型里消失。若只写不受约束的 `T`，圆的计算写不出来。界的作用就是同时留下这两句真话。

## 为什么 `List<ColorPoint>` 仍然不是 `List<Point>`

Bounded polymorphism 没有取消这个事实，而是绕开它。

```text
inCircle 的类型不是
    List<Point> -> List<Point>
而是
    对所有 T <: Point， List<T> -> List<T>
```

调用 `List<ColorPoint>` 时，实例化 `T = ColorPoint`，这是一次泛型实例化，不是一次把 `List<ColorPoint>` 看成 `List<Point>` 的 subtyping。结果类型因此仍是 `List<ColorPoint>`。

`[Inference]` 若列表不可变、且语言只有读取，有的类型系统会允许 `List<ColorPoint> <: List<Point>`（协变）。课程的结论绑定在 Java/C# 这种可变集合上：协变不安全，所以用有界类型变量，而不是放宽 `List` 的 subtyping。不要把“不可变列表可以协变”写成老师的原话。他只证明了可变时 depth 不安全，并说不可变 record 的 depth 是 sound 的。

## Concept card

### bounded polymorphism

- Problem: 既要“进来出去是同一个元素类型”，又要“元素至少是 Point，否则方法体不能算圆”。
- Definition: `[Course]` generics 加 subtype 约束。任意 `T`，但 `T <: Point`。
- Mental model: `∀ T <: Point. List<T> -> List<T>`。全称量词来自泛型，界来自 subtyping。
- Example: `inCircle`。`List<ColorPoint>` 能用，返回类型仍是 `List<ColorPoint>`。`List<String>` 不能用。
- Why it matters: 它大于两部分之和。分开用，要么拒绝合法的彩色点列表，要么无法在方法体里使用点的操作。
- Misunderstanding: 不是“`List` 变成了协变”。也不是普通的 `Point` 参数。`void f(Point x)` 接受一个彩色点，但不能表达“一列彩色点返回一列彩色点”。
- Modern: Java `extends`，Rust trait bound，C++ concepts，Go constraints。见上表。约束的是 subtype、trait 还是 concept，语言各不同，组合的形状相同。
