# Module 15 — Generics 与 Subtyping 是两种多态

这和“函数式分解 vs 面向对象分解”、“静态类型 vs 动态类型”是同一类课程结论：两种工具各有擅长，用错的那个会很别扭，但不是不能硬做。

Source: Section 10 — Generics Versus Subtyping / 0:05–0:26。

## 先分开定义

```text
parametric polymorphism / generics
    代码对“某个类型”工作，这个类型可以是任何类型。
    类型变量出现多次，表示这几处必须是同一个类型。
    ML：'a -> 'a
    Java：<T> T identity(T x)

subtype polymorphism
    代码需要一个像 Foo 的对象。
    你有一个比 Foo 更多的对象，只要它是 Foo 的 subtype，就可以传。
    依赖的是 <: 关系，不是类型变量。
    Java：void f(Animal x) 可以接收 Dog，若 Dog <: Animal
```

`[Course]` 老师有时把 subtyping 叫 subtype polymorphism，说这是更花哨的说法。Generics 的说法是“我对任何类型都工作”。Subtype 的说法是“我需要一个 Foo，subtype 也行”。

Source: Section 10 — Generics Versus Subtyping / 4:39–5:14。

Part A 的 `'a -> 'a` 不是 subtyping。它没有说“这个函数接受 int 的 subtype”。它说“给一个类型，这个函数从该类型到该类型”。`identity` 不能接受 `Dog` 然后返回 `Animal`，除非你把类型变量实例化成一个两边相同的类型。

## Generics 擅长什么

`[Course]` 用 ML 讲，因为我们在 ML 里见过。

组合其他函数：

```text
compose : ('b -> 'c) * ('a -> 'b) -> ('a -> 'c)
```

`'a`、`'b`、`'c` 可以实例化成语言里的任何类型。这个类型精确描述了 compose 在做什么：第二个函数的结果必须是第一个函数的参数。

在通用集合上操作：

```text
length : 'a list -> int
map    : ('a -> 'b) -> 'a list -> 'b list
```

`length` 不关心元素类型。`map` 只关心函数的参数类型和元素类型相同。类型变量重复出现，就是类型相等约束。

一般说：代码对任何类型都一样工作，但某些位置必须是同一类型。这就是 generics 的用途。

Java 和 C# 也有 generics，所以这不是函数式专属。它们用起来往往更笨，因为类型推断少；语义也往往更难，因为是后来加进语言的，还要和对象交互。即便如此，可选讲里用 Java 手工做出闭包，也没那么糟。该用的地方人们会用。

一个最小的 Java `Pair`，带 `swap`，对第一分量和第二分量的任意类型都工作。你不该在这种地方用 subtyping。

Source: Section 10 — Generics Versus Subtyping / 0:27–2:50。

## 用 subtyping 冒充容器，会怎样

没有 generics 时，pair 的字段只能选一个类型。唯一能装下一切的是 `Object`。Java 在有泛型之前就是这么做的。老师认为这是拿错工具，只是当时没有对的工具。

写入时 subtyping 很好用：`String <: Object`，`ColorPoint <: Object`，都能放进去。

读出来时，你只知道它是 `Object`。而 pair 的全部意义就是以后要读出来。于是你 downcast：运行时检查“我相信它是 String”，对了就给你 `String` 类型，错了抛异常。

结果是三输：没有静态保证，检查可能失败；付出运行时检查的代价；代码更难读。相对 generics，这是用错工具的代价。

Source: Section 10 — Generics Versus Subtyping / 2:45–4:39。

对照：

```java
void f(Animal x)          // 我需要 Animal 的行为。Dog 可以，因为 subtype
<T> T identity(T x)       // 我不需要 T 的任何行为。我保证返回的和传入的是同一类型
```

`f` 里可以调用 `Animal` 的方法。`identity` 里不能调用 `T` 的方法，因为 `T` 可能是任何类型。这不是限制得太死，这是类型在说真话。

## Subtyping 擅长什么

需要一个行为像 Foo 的对象，而你手里的对象比 Foo 多一些东西。ColorPoint 传给要 Point 的代码，color 字段谁也不关心。Generics 没有这个想法。

GUI 是老师认为 OOP 非常成功的例子。某个超类型表示“能出现在屏幕上、能响应点击、能被改变大小”。一段代码只依赖这个类型。实际传进去的对象还有颜色、默认字体、菜单栏。Subtype 让这段代码不用知道那些多余的东西。

在 ML 里做点与彩点会令人沮丧。ML 没有 subtyping。

```sml
fun distToOrigin {x, y} = Math.sqrt (x * x + y * y)
(* 类型是 {x:real, y:real} -> real *)
```

多一个字段的 record，类型不相等，调用不通过。ML 选择不要 subtyping，部分原因是它会让类型推断更复杂。

绕法存在，就像泛型出现前 Java 仍能做集合，只是笨。把 `distToOrigin` 改成不接收点，而接收任意 `'a`，外加两个 getter：`'a -> real` 和 `'a -> real`。调用者负责说明怎么取出 x 和 y。彩点也能用，只要传入合适的 getter。多数代码若只是想对普通点调用，就得为点专门准备 getter。而且因为没有 subtyping，点和彩点的 getter **不能复用**。对这个任务，subtyping 才是对的工具，而 ML 没有它。

Source: Section 10 — Generics Versus Subtyping / 4:39–8:11。

## 一张对照

| 你想说的话 | 用 | 不要用 |
| --- | --- | --- |
| 这段代码不关心 T 是什么，但输入和输出是同一个 T | generics | `Object` + downcast |
| 我要调用 Point 的方法，彩点也可以 | subtyping | 一个完全不受约束的 `'a`，除非你把方法也当参数传进来 |
| 列表元素都是 T，T 至少是 Point，返回的也是 T | 两者一起，见 `16` | `List<Point>` 假装接受 `List<ColorPoint>` |

## 和 duck typing 的距离

`[Inference]` 三者都是“一份代码用于多种数据”，但约束的时机不同。

```text
generics         静态。对所有类型都成立，类型变量强制若干位置相等。
subtyping        静态。只对 <: 关系里的类型成立，可以调用超类型的方法。
duck typing      没有静态约束。运行到消息发送才知道行不行。
```

Ruby 的 `double(x)` 既不是 `'a -> 'a`（它要求有 `+`，而且返回类型未必是参数类型），也不是 `Animal -> ...`（没有一个名义超类型）。它是 duck typing。不要为了术语整齐，把它塞进 subtype 那一栏。结构化的静态接口（Go，或 Section 10 的 record 类型）才更接近“静态版的像鸭子”。

## Polymorphism 在这门课里的位置

完整的图在 `17` 和 `22`。这一篇只贡献两条边：parametric 与 subtype 互补；ad-hoc overloading 是另一件事（`11`）；duck typing 不要并进 subtype。

## Concept cards

### parametric polymorphism

- Problem: 同一段代码要用于 int list 和 string list，又不想失去“元素类型是什么”的信息。
- Definition: `[Course]` 类型变量可以被任何类型实例化。变量出现多次表示这些位置类型相等。ML 的 `'a`，Java/C# 的 generics。
- Mental model: “对所有 T”。函数体不能依赖 T 的方法，除非另有约束（那是 `16`）。
- Example: `compose`，`map`，`identity`。
- Misunderstanding: 不是 subtyping。`'a -> 'a` 不允许参数和结果是不同的类型，即使其中一个是另一个的 subtype。

### subtype polymorphism

- Problem: 已经有一个要求 Point 的函数，不想为 ColorPoint 再写一个。
- Definition: `[Course]` 期待超类型的地方可以使用 subtype。依赖 `<:`，不依赖类型变量。
- Example: `distToOrigin` 接受带额外字段的点；GUI 代码接受任何屏幕元素的 subtype。
- Misunderstanding: 不是“泛型的一种写法”。用 `Object` 模拟泛型会在读出时丢失类型。用泛型模拟“多一个字段也行”，在没有 subtyping 的 ML 里做不到，除非把访问器当成参数传入。
