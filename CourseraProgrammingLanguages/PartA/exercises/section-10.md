# Section 10 — 练习

## Concept Questions

1. 为什么子类型被设计成一条新规则，而不是去改每一条旧的函数应用规则？
2. Width subtyping 为什么在只读字段时安全？它忘掉字段，还是删掉字段？
3. 构造一个 depth subtyping 加赋值后，类型通过但随后读字段失败的例子。不可变为什么使同一条规则变成安全？
4. Java 数组允许 `ColorPoint[]` 用在 `Point[]` 的位置。它如何避免静默读到不存在的字段？静态保证失去了什么？
5. 函数子类型为什么参数逆变、结果协变？用调用者的契约说明，不要用“子类更特殊”这句口号。
6. 一个类重新实现了 `Point` 的全部方法，但没有 `extends Point`。按结构它能替换吗？Java 允许吗？这叫什么选择？
7. 为什么 `List<ColorPoint>` 通常不是 `List<Point>`，即使 `ColorPoint <: Point`？
8. `Object` 加 downcast 在冒充哪一个机制？漏掉的不变量是什么？
9. 无界的 `<T> List<T> inCircle(List<T> ...)` 为什么方法体类型检查失败？只有 `List<Point>` 的版本为什么丢颜色？
10. 有界多态是两者的模糊平均，还是两者的组合？

## Code Reasoning

以下用课程里的伪记录，不是可运行的 SML。

### A

```text
fun distToOrigin (p : {x:real, y:real}) : real = ...
val c = {x = 3.0, y = 4.0, color = "green"}
```

`distToOrigin c` 在没有子类型时失败在哪条规则？加上 width 和 subsumption 之后，旧的函数应用规则改了没有？

### B

判断能否传给期望参数类型为 `{x:real, y:real} -> {x:real, y:real}` 的位置：

1. `{x:real, y:real} -> {x:real, y:real, color:string}`
2. `{x:real, y:real, color:string} -> {x:real, y:real}`
3. `{x:real} -> {x:real, y:real}`

### C

```java
<T extends Point> List<T> inCircle(List<T> pts, Point center, double radius)
```

调用者传入 `List<ColorPoint>` 时，返回类型是什么？若把返回类型写成 `List<Point>`，调用者失去什么？

---

## Answer Key

### Concepts

1. 旧规则数量已经很多。只加 subsumption，应用规则仍要求类型相等。灵活发生在“先把表达式看成超类型”这一步。改每一条规则容易改漏，也容易改坏 soundness。
2. 使用处只读它声明的字段，多出来的字段不会被碰到。忘掉是类型观点上的忘记，值上的字段还在。所以随后用更宽的类型仍能看见它们，只要中间没有人把整个记录换成一个更窄的值。
3. `setToOrigin` 把 `center` 写成没有 `z` 的记录，然后 `sphere.center.z` 失败。不可变时没有这个写，读路径上多字段仍然是少字段的安全替换。
4. 每次写入数组都做运行时检查，类型不对就抛异常。静态类型不再保证写入一定成功。
5. 调用者会传入任何声明过的参数类型的值，所以实际函数必须接受更一般的参数。调用者只按声明的结果类型使用返回值，所以实际返回更具体的值无害。方向反了，调用者会传入实际函数不接受的值，或读到实际函数没返回的字段。
6. 按结构，若方法集和字段的可变性都满足子类型规则，替换可以是 sound 的。Java 不允许，因为没有声明子类关系。这是名义子类型。
7. 若 list 可变，协变会允许写入 `Point`。许多语言因此把 `List<T>` 做成不变。子类型关系不自动提升到类型构造器上。
8. 冒充参数多态。读出时只知道 `Object`，元素种类要靠运行时转换。转错就抛。类型不再保证取出来的是放进去的那一种。
9. `T` 可以是 `Integer`，方法体不能向它要点的坐标。返回 `List<Point>` 时，放进去的 `ColorPoint` 取出来只是 `Point`，颜色在类型里丢了。调用者不能再当 `ColorPoint` 用，除非 downcast。
10. 组合。类型参数保证进出是同一个 `T`。界保证 `T` 可以用在期望 `Point` 的地方。缺一不可。

### Code

A. 失败在实参类型必须等于形参类型。`c` 的类型多一个字段，不相等。加上子类型后，先用 subsumption 把 `c` 看成 `{x:real, y:real}`，再按相等规则应用。应用规则本身不改。

B. 1 可以。参数相同，结果协变。2 不可以。参数更具体，调用者会传入没有 `color` 的点。3 可以。参数更一般，调用者多传的 `y` 被忽略；结果符合期望。

C. 返回 `List<ColorPoint>`。若返回 `List<Point>`，调用者失去“表里每个元素仍是 `ColorPoint`”这个类型事实。
