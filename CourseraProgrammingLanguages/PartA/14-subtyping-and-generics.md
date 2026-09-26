# 14 — 子类型不是泛型

> Part C · Section 10
> 视频：`Subtyping` 到 `Bounded Polymorphism`

Part A 的 `'a` 说：同一段代码对所有类型做同一件事，类型之间没有“谁是谁的子类”。Part C 的类层次说：一个更具体的对象常常应该能用在期望更一般对象的地方。两套“可替换”到最后才并排，是因为缺任何一边，另一边都会被误认成全部。

Grossman 不用再学一门真语言来讲这件事。真语言的 subtyping 总比底层想法更绕。他用记录和函数把规则写清，再说明 Java / C# 那种静态 OOP 如何使用这些规则，以及它们和 ML 的 generics 如何互补。合在一起大于各部分。用错一个，容器退化成 `Object` 加 downcast，或者“我有的比你要的多”在 ML 里根本写不出来。

这和“函数式分解 vs OOP 分解”“静态 vs 动态”是同一级别的对照。三条轴都不要焊死。

---

## 1. 没有一条单独的子类型规则会怎样

函数 `distToOrigin` 只需要 `{x:real, y:real}`。调用点手里是 `{x:real, y:real, color:string}`。按“实参类型必须等于形参类型”，这次调用不类型检查。运行时没有坏事：多出来的 `color` 不会妨碍只读 `x` 和 `y`。

如果类型系统不能忘掉一些字段，所有“我有的比你要的多”的程序都被拒绝。这不是安全。这是过严。

若为了这一种灵活去改每一条旧的 typing rule，又烦又容易改坏。需要一种加灵活性的方式，不改已经有的规则。

---

## Lecture — 子类型关系是唯一的新规则

视频：`Subtyping from the Beginning`，`The Subtype Relation`。

### 问题

旧规则保持“实参类型必须等于形参类型”。新的灵活性全部来自一条 subsumption：

```text
e : t1     t1 <: t2
--------------------
e : t2
```

若 A 是 B 的子类型（subtype），则期望 B 的地方可以给 A。A 的值可以用在 B 的位置，并且不引起类型系统声称要防止的失败。这是可替换（substitutability），不是“A 的语法里出现了 B”。

### Width 与 permutation

记录的宽度子类型（width subtyping）：多字段的记录是少字段记录的子类型。使用处只会读它声明要的字段。多出来的字段被忘掉，不是被删除。

```text
{x:real, y:real, color:string} <: {x:real, y:real}
```

字段顺序不是含义。排列（permutation）也是子类型：

```text
{x:real, y:real} <: {y:real, x:real}
```

传递：丢掉 `color`，再重排，得到

```text
{x:real, y:real, color:string} <: {y:real, x:real}
```

于是 `distToOrigin c` 通过，而不必改函数应用那条旧规则。先用 subsumption 把 `c` 看成更小的记录类型，再按相等规则传进去。

这是结构子类型（structural subtyping）：关系由类型的形状决定，不由名字决定。后面会看见 Java / C# 不这么做。

### 若字段可写，width 已经不够说明危险

```text
fun makePurple (r : {color:string}) =
    r.color = "purple"

makePurple c
```

`c` 有 `color`，这次写没有缺字段。危险不在 width 本身。危险在下一讲：子类型走进字段内部，而那个字段是可变的。

---

## Lecture — Depth subtyping 在可变数据上 unsound

视频：`Depth Subtyping`，optional `Java/C# Arrays`。

### 问题

Width 只能丢掉记录顶层字段，不能走进某个字段的类型里再用子类型。

`circleY` 要 `{center:{x:real, y:real}, r:real}`。手里的球体是 `{center:{x:real, y:real, z:real}, r:real}`。没有类型系统时，`circleY sphere` 能读到 `4.0`。现有规则推不出所需的 `<:`。

看起来只是忘了一条规则。加上深度子类型（depth subtyping）：

```text
ta <: tb
----------------------------------------------
{..., f:ta, ...} <: {..., f:tb, ...}
```

`circleY sphere` 就能过。让类型系统更灵活，若不仍然禁止坏事，就不值得。

### 坏事

```text
fun setToOrigin (c : {center:{x:real, y:real}, r:real}) =
    c.center = {x = 0.0, y = 0.0}

setToOrigin sphere
sphere.center.z
```

若 depth subtyping 允许把球体传给 `setToOrigin`，函数会把 `center` 换成一个没有 `z` 的记录。随后读 `sphere.center.z` 是类型系统允许的，运行时没有这个字段。Soundness 破。

规则错在把“读得更少”和“写得更宽”当成同一方向。读一个点时，多一个 `z` 无害。写一个点时，写入者可以不提供 `z`。可变位置不能协变。

不可变记录没有这个问题。你不能把 `center` 换成更小的记录，因为你不能写。Depth subtyping 在不可变数据上可以是安全的。这是 Section 1 的 immutability 在课程最后一次回流：拿掉 mutation，不只是别名不可观察，也是某些子类型规则从 unsound 变成 sound。

### Java 和 C# 的数组

数组在这件事上和可变记录一样。若 `T1 <: T2` 就让 `T1[] <: T2[]`，会遇到和 `setToOrigin` 相同的写入。

```java
void m1(Point[] pt_arr) {
    pt_arr[0] = new Point();
}

ColorPoint[] cpt_arr = new ColorPoint[n];
m1(cpt_arr);
cpt_arr[0].color;   /* 若写入成功，color 不存在 */
```

Java 和 C# **允许** `ColorPoint[] <: Point[]`。按上一讲，它们不该允许。它们没有让缺字段读取静默发生，而是把检查推迟到每次数组写入，抛运行时异常。类型系统因此以一种不寻常的方式“没有真正被静默打破”，但静态保证弱了：写入可能失败，即使静态类型看起来完全匹配。

这不是动态类型。这是静态类型系统在一个它自己知道不安全的规则上，用运行时检查补洞。Rust 和现代的不可变集合不走这条路。概念类比：它们拒绝这个子类型，而不是推迟检查。

---

## Lecture — 函数子类型：参数逆变，结果协变

视频：`Function Subtyping`。

### 问题

调用者把 subtype 传给函数、把返回的带颜色的点当点用，这是普通 subsumption。它和“函数类型本身的子类型”不是一回事。

有高阶函数时必须回答：能不能把 `t3 -> t4` 传给期望 `t1 -> t2` 的位置？完全无关的函数不行。返回类型和参数类型的方向不一样。这是全课最反直觉的结果。搞错方向会破坏 soundness。它也直接决定 OOP 里覆盖方法时怎样改类型才 sound。先用函数讲，比直接讲方法容易。

`distMoved` 接收一个点到点的函数，再接收一个点，返回移动了多远。

能传给它的函数，必须接受调用者会传入的每一个点。调用者按 `{x:real, y:real}` 来传。实际函数不能要求更多字段。它最多要求更少。所以参数类型是逆变的（contravariant）：实际函数的参数类型是期望参数类型的**超类型**。

实际函数的返回值会被调用者当 `{x:real, y:real}` 来读。返回更多字段无害。返回更少会让调用者读到不存在的字段。所以结果类型是协变的（covariant）：实际返回类型是期望返回类型的**子类型**。

```text
t3 <: t1     t2 <: t4
---------------------------
(t1 -> t2) <: (t3 -> t4)
```

读的时候容易把箭头两边看反。记调用者的契约，不要记“子类方法应该更特殊，所以参数也更特殊”。

- `flipGreen` 返回带 `color` 的点。结果更具体。参数和期望相同。可以传。调用者不会去读 `color`，多出来的字段无害。
- `flipIfGreen` 要求参数有 `color`。调用者会传入没有 `color` 的点。不能传。参数更具体，方向反了。
- `flipX_Y0` 只读 `x`，返回有 `x` 和 `y` 的点。参数更一般，结果符合期望。可以传。它不读 `y`，调用者多传的 `y` 被忽略。

方法覆盖是这个规则的特例。覆盖的方法必须能接受父类方法能接受的一切参数，并且返回父类承诺能返回的东西，或更具体的东西。参数改得更具体，就不是子类型，即使语言的语法允许你这么写覆盖。

---

## Lecture — 静态 OOP 如何使用这套理论

视频：`Subtyping for OOP`。

### 问题

若类名也是类型，并且 subclass 关系就是 subtype 关系，就必须服从可替换：子类实例能用在任何出现超类实例的地方，且不会调用不存在的方法，不会访问不存在的字段。

字段在这些语言里属于类定义，因此属于随之而来的类型，而且一般可变。方法一般不可变：你不能在运行时把某个对象的方法槽换成另一个函数，至少在这套模型里不能。所以两者不能用同一条 depth 规则。

- 方法：按函数子类型。覆盖时参数逆变，结果协变。方法集合可以变宽：子类多几个方法，用在只要求父类方法的地方，多出来的方法被忘掉。这像 width。
- 字段：可变，所以不能协变。典型的安全选择是不变（invariant）：子类字段的类型与父类相同。数组那个漏洞就是没遵守这一点。

名义子类型（nominal subtyping）和结构子类型不同。一个类可以重新实现 `Point` 的全部方法和字段，但不 `extends Point`。按结构，soundness 会允许它是 `Point` 的子类型。Java 和 C# 不允许：没有子类关系，就没有子类型关系。名字是关系的一部分。这不是更安全的唯一办法。它是这些语言的选择，用来让“是一种”成为程序员显式写下的事实，而不是形状碰巧相同。

`self` 的类型在子类方法里更具体。父类方法里，`self` 只被当成父类。子类覆盖的方法里，`self` 可以当子类用，因此可以访问子类字段。这和动态派发一致：运行时 `self` 就是接收者。类型规则必须保证，无论接收者是哪个子类，父类方法里对 `self` 的使用仍然合法。所以父类方法不能假设子类字段存在。子类方法可以。

---

## Lecture — Generics 与 subtyping 各管一类事

视频：`Generics versus Subtyping`，`Bounded Polymorphism`。

### 问题

用子类型表达 `map`，会把元素类型收成一个最大的 `Object`，取出来再 downcast。转换可能在运行时失败。用无界类型参数表达“这个点比函数要求的多一个字段”，在没有子类型的 ML 里写不出来：`distToOrigin` 的参数类型是恰好那些字段，多一个 `color` 就不是同一个记录类型。

两套工具：

| | Parametric polymorphism / Generics | Subtyping |
|---|---|---|
| 定义 | 同一段代码对所有类型工作。`'a` 没有“更具体”的方向 | 若 `A <: B`，期望 `B` 的地方可以给 `A` |
| 解决的问题 | 容器、`map`、`length` 与元素类型无关 | “我有的比你要的多”，或子类可替换父类 |
| 关键区别 | 类型之间不必有包含关系。替换必须一致 | 有一个可替换偏序。不是所有“能复用的代码”都是子类型 |
| 典型场景 | ML 的 `'a list`，Java 的 `List<T>` 若 T 在两边同进同出 | `ColorPoint` 用在期望 `Point` 的地方 |

`length` 不关心元素类型。这是泛型，不是子类型。`List<ColorPoint>` 不是 `List<Point>` 的子类型，即使 `ColorPoint <: Point`。原因就是数组那一讲：若 list 可变，协变会允许把 `Point` 写进 `ColorPoint` 的 list。即使 list 不可变，许多语言仍把 `List<T>` 做成不变，以免规则随可变性改变。ML 没有子类型，所以这个问题不出现。`'a list` 不是“某种 list 的子类”。它是一个类型构造器。

没有泛型时的 Java 风格是 `Object` 字段加 downcast：

```java
class Pair {
    Object x;
    Object y;
}
String s = (String) pair.x;   /* 运行时检查；错了就抛 */
```

写入时 `String` 和 `ColorPoint` 都是 `Object`，类型通过。读出时静态类型只剩下 `Object`。不变量从类型里漏进了注释和转换。这就是用子类型冒充参数多态的代价。

没有子类型时的 ML，多一个字段就不是那个记录类型。绕路是不把记录传进去，而把取值函数传进去：

```sml
fun distToOrigin (getx, gety, v) =
    let
        val x = getx v
        val y = gety v
    in
        Math.sqrt (x * x + y * y)
    end
(* ('a -> real) * ('a -> real) * 'a -> real *)
```

任何有办法取出两个 `real` 的 `'a` 都能用。这是用高阶函数和多态模拟“我不关心其余字段”。它能工作。它不是子类型。客户必须把投影函数交出来。

### 有时必须一起用

`inCircle` 收一个点的列表和一个圆，返回落在圆内的那些点。想拿 `List<ColorPoint>` 调用，并拿回 `List<ColorPoint>`，而不是 `List<Point>`。

只靠子类型不行：`List<ColorPoint>` 不是 `List<Point>`。只靠无界泛型不行：`T` 可以是 `Integer`，方法体无法把元素当点用。

需要的句子是：任意类型 `T`，并且 `T <: Point`。这是有界多态（bounded polymorphism）。

```text
inCircle : List<T> -> ... -> List<T>    where  T <: Point
```

Java 的写法是 `<T extends Point>`。这里的 `extends` 是界，不是“再继承一层”的方法体。ML 的 `'a` 只说任意类型。它没有 subtype 关系，所以说不出这个界。C++ template 在某种意义上两者都碰得到，他点名 Java 和 C# 是真有这套静态规则的语言。

有界多态不是两者的模糊中间态。它是组合：类型参数保证输入输出是同一个 `T`，界保证方法体可以发送 `Point` 的消息。缺参数，返回类型退化成 `List<Point>`，颜色丢了。缺界，方法体类型检查失败。

---

## 对照

### Subtyping vs Generics

见上表。再补一条工程判断：

- 代码对元素做的事与元素类型无关，元素类型还要原样回来：类型参数。
- 代码只使用一组共同操作，而且调用者传来的是更具体的对象：子类型，或带界的类型参数。
- 两者都要：有界多态。不要用 downcast 假装你有类型参数。

### Nominal vs Structural

| | Nominal | Structural |
|---|---|---|
| 定义 | 子类型因为声明了 `extends` / `implements` | 子类型因为形状允许安全地替换 |
| 解决的问题 | 让“是一种”成为显式设计，避免偶然同形 | 让多字段记录用在少字段的位置，不必先声明 |
| 关键区别 | 重新实现全部方法仍不是子类型 | 同形即可，即使作者没想过这个关系 |
| 典型场景 | Java、C# 的类 | 本讲的记录子类型；Go 的 interface 在另一端更接近结构匹配。概念类比，不是同一规则 |

### Covariant vs Contravariant

| | 结果 / 读 | 参数 / 写 |
|---|---|---|
| 安全方向 | 协变：实际给得更具体 | 逆变：实际接受得更一般 |
| 搞反会怎样 | 调用者读到不存在的字段或方法 | 实际函数收到它不会处理的参数 |
| 可变位置 | 读想协变，写想逆变，只能不变 | Java 数组选择协变并用运行时写入检查补洞 |

---

## Connection to Modern Languages

概念类比，不是等价。

- Rust 的 `enum` 没有这套子类型。Trait 对象和泛型是另一套：泛型在编译期单态化，trait object 是运行时派发。不要把 trait 说成 Java interface 的同义词。Trait 可以不涉及子类型。
- Kotlin 的 `List<out T>` 和 Java 的 `? extends T` 是在不可变或只读方向上恢复协变。它们是对“可变则不变”的细化，不是对 depth subtyping 漏洞的否认。
- TypeScript 的结构子类型更接近本讲的记录，而不是 Java 的名义类。可选属性、变体字段和函数参数的严格程度经常是 soundness 上的让步。看见它接受一个赋值，先问有没有写操作。
- Go 的 interface 是结构匹配：实现了方法集就是那个 interface，不必声明。这接近“形状即关系”，又不是记录宽度子类型。方法集变宽像 width。没有泛型的那些年，空 interface 扮演过 `Object` 加类型断言的角色。泛型进来之后，本讲的分工才完整。
- C++ template 不是 Java generics。实例化更像宏式的编译期生成，错误发生在实例化时，不是在一个独立的、带界的类型检查阶段。他说 “kind of”。这个 “kind of” 要保留。

---

## Section 10 Review

这一节把“可替换”拆成两套。子类型是一条不改旧规则的新规则：`A <: B` 则期望 B 的地方可以给 A。记录可以变宽、重排。深度子类型在可变字段上 unsound，在不可变数据上可以安全。函数参数逆变，结果协变。静态 OOP 把子类关系名义地当成子类型，字段因可变而保持不变，方法按函数子类型覆盖。泛型是另一套：类型参数没有方向。两者都需要时，用有界多态，而不是 downcast，也不是假装 `List<ColorPoint>` 是 `List<Point>`。

### 不变量

```text
subtyping 是一条 subsumption 规则，不是把每条旧规则都改一遍
width：多字段 <: 少字段，仅当多出来的字段不会被错误地写丢
depth subtyping + mutation = unsound
函数：参数逆变，结果协变
subclass 是名义的；structural 同形不必是 subtype
generics ≠ subtyping
List<Sub> 通常不是 List<Super>
bounded polymorphism = 类型参数 + 子类型界
```

### 能力检查

- 给一个多字段记录传给少字段函数，指出类型推导用了哪一条新规则，旧的函数应用规则改了没有。
- 构造一个 depth subtyping 加赋值的反例，说明读 `z` 如何在类型通过之后失败。
- 判断四个 `flip` 变体哪个能传给 `distMoved`，并说出参数或结果哪一边方向错了。
- 说明为什么 `inCircle` 既不能只有 `List<Point>`，也不能只有无界的 `T`。

练习：`exercises/section-10.md`。
