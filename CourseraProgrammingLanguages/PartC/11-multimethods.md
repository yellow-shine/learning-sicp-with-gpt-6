# Module 11 — Multimethods

可选讲。不考到“请写出 Ruby 的 multimethod 语法”，因为 Ruby 没有。它存在是为了公平：不是 OOP 必然要手写 double dispatch，而是**只有单分派的** OOP 才要。

Source: Section 9 — Multimethods / 0:04–0:23。

## Problem

Double dispatch 用方法名把“左边是 Int”编码进去，因为语言选方法时只看点左边。如果语言愿意看点左边**和**其余参数的运行时 class，九个方法可以同名，调用仍写成：

```text
e1.eval.add_values(e2.eval)
```

语言自己在九个 `add_values` 里挑。

## 规则

`[Course]` 一个有 multimethods（也叫 multiple dispatch）的语言，不是 Ruby，可以让 `Int`、`MyString`、`MyRational` 各定义三个都叫 `add_values` 的方法，分别声明参数是这三种 class。一共九个同名方法。调用时：

```text
左边的运行时 class ∈ {Int, MyString, MyRational}
右边的运行时 class ∈ {Int, MyString, MyRational}
语言选出对应的那一个方法
```

一般化：允许多个同名方法，定义处标明接受哪个 class。运行时不只对 receiver 做 dynamic dispatch，而是用包括 receiver 在内的**全部**参数的运行时 class，选最佳方法。

若 dynamic dispatch 是 OOP 相对其他风格多出来的东西，multimethods 是更多的 dynamic dispatch。点左边不再特殊。从这个角度，它比单分派更“OOP”。

Source: Section 9 — Multimethods / 0:23–2:42。

## 代价：最佳方法可能不唯一

和 subclass 交互时，可能有两个同名方法都说得通，语言必须定义选谁。程序员以为会进 A，实际进了 B，就会非常困惑。这条规则是语言定义的一部分，不是实现细节。

`[Supplement]` 典型歧义：参数类型一个更精确地匹配左边，另一个更精确地匹配右边。不同语言的线性化规则不同。课上没有给出具体的歧义例子，不要背一套虚构的优先级。

Source: Section 9 — Multimethods / 2:42–3:07。

## 为什么不加进 Ruby

`[Course]` 两个结构性原因：

1. Ruby 的方法定义不声明参数的 class。任何对象都能传给任何方法。Multimethods 靠“这个 `add_values` 期望 `MyRational`，那个期望 `MyString`”来挑选。这和 Ruby 的动态风格根本冲突。
2. Ruby 有一条简单规则：一个 class 不会同时拥有两个同名方法。再定义一次就是替换。子类同名就是覆盖。Multimethods 要求同名方法并存。

Source: Section 9 — Multimethods / 3:07–4:11。

## 不要和 static overloading 混

Java、C#、C++ 确实允许同一 class 里多个同名方法。那**不是** multimethods。

```text
static overloading
    receiver：运行时 class（仍是 dynamic dispatch）
    其余参数：编译期静态类型
    挑选发生在类型检查时

multiple dispatch
    receiver 和其余参数：都看运行时 class
    挑选发生在调用时
```

老师觉得这是奇怪的混合，但不展开 overloading 的细节。对这一课的加法例子，static overloading **帮不上忙**。你仍然要手写 double dispatch。它唯一改变的是：三个方法可以都叫 `add`，而不叫 `addInt` / `addString` / `addRational`。老师个人觉得同名更混乱，但在有 overloading 的语言里这是惯例。

C# 4.0 的 `dynamic` 是一个例外通道：参数转成 `dynamic` 之后，可以做出 multimethods 的效果。这是把新特性和旧的 overloading 拼起来，不是语言从一开始就按多参数分派。

Source: Section 9 — Multimethods / 4:11–6:11。

## 谁真的以它为模型

`[Course]` Clojure 是一个现代例子。这个想法不新，几十年前就有，只是没有像别的 OOP 概念那样进入主流。

`[Modern Connection]` Julia 常被称作 multiple-dispatch 语言：函数不属于点左边的对象，调用时按所有参数的运行时类型选方法。这和课堂描述的 multimethods 是同一思想。课程没有提 Julia。Dylan、CLOS 是更早的例子，同样不是课程内容。

| 语言 | 默认的方法选择 |
| --- | --- |
| Ruby | 只看 receiver。同名即替换 |
| Java / C++ | receiver 动态；其余参数静态 overloading |
| C# | 默认同 Java；`dynamic` 可走运行时 |
| Clojure | 有 multimethod，按你提供的 dispatch 值选 |
| Julia `[Modern Connection]` | 多个参数的运行时类型一起参与 |

## 三种分派，一张图

```text
single dispatch     只看 receiver                 Ruby, Java 实例调用
double dispatch     程序员用第二次消息模拟第二维   本课的 addInt 惯用法
multiple dispatch   语言看多个参数的运行时种类     multimethod 语言
static overloading  其余参数看静态类型             Java/C++/C#，不是 multimethod
```

## Concept card

### multimethod

- Problem: 二元操作的九格不想手写成 `addInt` / `addString`。
- Definition: `[Course]` 多个同名方法，按包括 receiver 在内的参数的运行时 class 选择。又称 multiple dispatch。
- Mental model: dynamic dispatch 从“点左边”推广到“所有参数”。
- Example: 九个都叫 `add_values` 的方法，调用写法仍是 `e1.eval.add_values(e2.eval)`。
- Why it matters: 说明 double dispatch 是单分派语言的编码技巧，不是问题本身。
- Misunderstanding: Java 的同名方法是 static overloading。Ruby 不能加入 multimethods 而不破坏“不声明参数 class”和“同名即替换”。
- Related: double dispatch, static overloading, dynamic dispatch。
