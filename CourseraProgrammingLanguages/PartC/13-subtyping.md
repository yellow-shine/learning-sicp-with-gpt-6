# Module 13 — Subtyping，从零开始

Section 10 回到静态类型。没有新的编程语言，全部是伪代码。真实语言的 subtyping 比这些核心规则更绕，所以老师故意不用 ML、Racket、Ruby 或 Java 的表面语法。目标是：subtyping 是什么，怎样加进类型系统而不改掉已有的那些类型规则，以及怎样不把可靠性做坏。

后面才把这套理论接回 Java/C#（`14`），再和 ML 的泛型比较（`15`、`16`）。

Source: Section 10 — Subtyping / 0:05–1:16。

## Problem

函数 `distToOrigin` 需要一个点：

```text
distToOrigin : {x:real, y:real} -> real
distToOrigin(p) = sqrt(p.x * p.x + p.y * p.y)
```

`pythag = {x = 3.0, y = 4.0}` 的类型正好是 `{x:real, y:real}`，调用合法，结果 5.0。

`c = {x = 3.0, y = 4.0, color = "green"}` 的类型是 `{x:real, y:real, color:string}`。按“参数类型必须**等于**形参类型”这条已经很好的规则，调用不通过。可是没有任何坏事会发生。`distToOrigin` 不读 `color`。多出来的字段不会妨碍它。

还想做的另一件事：把 `c` 传给只需要 `{color:string}` 的 `makePurple`。它把 color 改成 `"purple"`。之后 `c` 不再是绿点，这没问题，因为它本来就有 color 字段。

我们要的是：一个 record 类型可以**忘掉**一些字段，仍被当作较瘦的那个类型用。

Source: Section 10 — Subtyping / 6:21–10:38。

## 语言很小，先把 record 说清

`[Course]` 三个表达式。语法像 ML，但字段用 `e.f`，而且字段可变。ML 的字段不可变，也没有 subtyping，所以这不是能粘贴进 SML 的代码。

```text
{f1 = e1, ..., fn = en}     求值每个 ei，造出带这些字段的 record
e.f                         e 求到有 f 的 record，取出内容
e1.f = e2                   e1 求到有 f 的 record，把该字段改成 e2 的值
```

Record 类型写成 `{f1:t1, ..., fn:tn}`。

类型规则，在加入 subtyping 之前：

- 构造：每个 `ei : ti`，则整个 record 的类型带着这些字段和类型。
- 读取：若 `e` 的类型包含 `f:t`，则 `e.f : t`。没有 `f` 就不通过。这正是要防止的运行时错误。
- 更新：`e1` 的类型包含 `f:t`，且 `e2 : t`。更新之后 record 仍符合原来的类型。

这套规则已经 sound：类型检查通过的程序，不会去读一个 record 里没有的字段。

Source: Section 10 — Subtyping / 1:16–6:21。

## 不要改每一条旧规则

“实参类型必须等于形参类型”清晰、好实现。它恰好是挡住 `c` 的那条。若为了 record 多一个字段，去修改函数调用、赋值、返回等每一条规则，类型系统会变成一团特例。

只加两样东西。

第一，一个与其他规则分开的关系：`t1 <: t2`，读作 t1 是 t2 的 subtype。这不必是程序里的语法。它像整数的 `<`：给定两个类型，要么成立，要么不成立。

第二，**唯一**的新类型规则，老师用蓝色标出：

```text
若 e : t1  且  t1 <: t2
则 e : t2
```

例如若 `{x:real, y:real, color:string} <: {x:real, y:real}`，则任何具有三字段类型的表达式也具有两字段类型，于是能传给期待超类型的函数。旧的“类型必须相等”不用改。相等被这条 subsumption 规则放宽了。

`[Supplement]` subsumption 是文献里这条规则的名字。课堂说的是“若 e 有 t1 且 t1 是 t2 的 subtype，则 e 也有 t2”，没有用这个英文词。

Source: Section 10 — The Subtype Relation / 0:21–2:33。

## 可靠性不是口味

“这是我的语言，规则随便写”是外行误解。动态作用域的闭包是坏主意；subtyping 写错，类型系统就不再完成它的任务。

这里的任务：通过类型检查的程序，运行时不会访问 record 中不存在的字段。原有规则满足这一点。加上 subtyping 之后必须仍然满足。破坏可靠性的关系，就是写错了。

课程里的说法：subtyping is not a matter of opinion。要么规则破坏 soundness，要么不破坏。

判断标准是 substitutability：

```text
若 t1 <: t2
则任何 t1 的值，都必须能被用在任何 t2 的值能被用的方式上
```

`[Supplement]` 这就是 Liskov 替换原则在类型系统里的形态。课堂说的是 substitutability，没有说 Liskov 这个名字。

对“多字段 <: 少字段”：超类型上你只能读写真的还在的那些字段。子类型的值都有这些字段，所以替换是安全的。

Source: Section 10 — The Subtype Relation / 2:33–5:01。

用函数调用说同一件事：

```text
f : Animal -> ...
```

若 `Dog <: Animal`，则 `Dog` 的值能做 `Animal` 的值能做的一切，所以传给 `f` 不会让 `f` 调用一个 `Dog` 没有的操作。`f` 的类型已经承诺它只依赖 `Animal` 的接口。这不是“子类自动安全”。安全来自 subtype 关系被定义成满足替换，而语言又只在这个关系成立时允许替换。Ruby 的 subclass 没有这层证明。

## 四条初步规则

`[Course]`

**Width subtyping.** 较宽的 record 可以是较瘦 record 的 subtype，只要瘦的那些字段名和类型都还在。也就是丢掉一些字段。

```text
{x:real, y:real, color:string} <: {x:real, y:real}
{x:real, y:real, color:string} <: {color:string}
```

**Permutation.** 字段写下的顺序没有意义。

```text
{x:real, y:real} <: {y:real, x:real}
```

不写这条，大量显然该通过的程序会失败。它通过替换测试：能读写的字段集合没变。

**Transitivity.** `t1 <: t2` 且 `t2 <: t3` 则 `t1 <: t3`。由替换原则直接得到。好处是其他规则不用一次说完“又丢字段又重排”。先 width，再 permutation，传递性把它们接起来。

**Reflexivity.** 每个 `t <: t`。到目前为止不太需要。函数的 subtyping 规则会用它来少写特例。

Source: Section 10 — The Subtype Relation / 5:01–8:18。

## Depth subtyping：看起来该加，加上就坏

新例子。圆由圆心和半径表示，圆心是嵌套 record。

```text
circleY : {center:{x:real, y:real}, r:real} -> real
circleY(c) = c.center.y
```

球也有 center 和 r，但 center 多一个 `z`。没有类型系统的话，`circleY(sphere)` 会返回 4.0。有类型系统、但只有 width 的话，不行。Width 只能丢掉**最外层**的字段。它不能走进 `center` 的类型里再丢掉 `z`。

于是有人会加第五条，叫 depth subtyping：

```text
若 ta <: tb
则 {..., f:ta, ...} <: {..., f:tb, ...}
```

可以在某个字段的类型上使用已有的 subtype 关系。配合 width，球的类型就能成为圆的参数类型的 subtype，`circleY(sphere)` 通过。

规则不能只在你喜欢的例子上试验。还要保证你不想允许的程序仍然被拒绝。这条规则 unsound。一个反例就够。

```text
setToOrigin : {center:{x:real, y:real}, r:real} -> unit
setToOrigin(c) =  c.center = {x = 0.0, y = 0.0}
```

若 depth 允许把球传进去，这次赋值把 `center` 换成一个**没有 z** 的 record。球的静态类型仍声称 `center` 里有 `z`。下一行 `sphere.center.z` 类型检查通过，运行时字段不存在。类型系统承诺过不会发生的事发生了。

罪魁就是 depth subtyping。有 getter 和 setter 时，不能让 record 字段的类型变成超类型。老师还说变成子类型也不行。笔记按这句话保留，课堂反例展示的是变成超类型（少了 `z`）这一方向。

Source: Section 10 — Depth Subtyping / 0:14–7:48。

### 可变性又一次是原因

若字段不可变，没有 setter，depth subtyping 是 sound 的。老师说他这次没骗你，但没有在课上证明。

于是对 record，下面三件事只能取两件：

```text
允许 setter
允许 depth subtyping
类型系统 sound
```

想要 sound 又要 depth，就去掉 setter。想要另外的两件组合，是偏好。但“有 setter 且要 sound”就不可能再要课上那条 depth 规则。Subtyping 在这里不是意见。

Source: Section 10 — Depth Subtyping / 7:48–8:48；Course Wrap-up / 5:25–5:43。

### 为什么人会觉得字段该协变

`[Inference]` 直觉是：球的圆心“是一种”带 z 的点，带 z 的点“是一种”点，所以球“是一种”圆。这个直觉只在你**不写入** `center` 时成立。`setToOrigin` 写入的是超类型的值，把子类型的不变量写坏了。Width 安全，是因为超类型的代码根本不知道被丢掉的字段，没法要求它们还在。Depth 不安全，是因为超类型的代码会**替换整个字段**，替换物只满足较瘦的类型。

## Java 和 C# 的数组：同一错误，加上运行时补丁

可选。数组在 depth 这件事上就像 record。若 `T1 <: T2`，人会想要 `T1[] <: T2[]`。Java 和 C# 允许了，但不该允许。

```text
Point 有 x, y
ColorPoint extends Point，加 color
cpt_arr : ColorPoint[]，每个槽都放着 ColorPoint
m1(arr : Point[]) 做  arr[0] = new Point()
m1(cpt_arr)          类型检查通过，因为数组协变
cpt_arr[0].color     类型检查也通过
                     运行时那个槽里是 Point，没有 color
```

它们没有让类型系统彻底坏掉，而是让**数组写入**可能失败。即便 `e1` 的静态类型是 `T[]`，`e3` 的静态类型是 `T`，下标也在界内，`e1[e2] = e3` 仍可能抛 `ArrayStoreException`。运行时再看 `e1` 实际元素的 class，和 `e3` 的运行时 class，检查后者是不是前者的 subtype。静态类型在这次写入上没有帮你。反例会在 `m1` 的赋值那一行爆炸，而不是在后来读 `color` 的那一行。若 `m1` 返回了，你才知道它没做这种写入，后面的读取安全。

为什么当初要这个规则：在 Java 有泛型之前，没有它就很难写一个对任何对象数组都能用的排序例程。有了泛型之后，老师认为这个设计更可疑，但是否保留仍可争论。代价是每次数组存储都要检查。

`null` 是另一个声名没那么差、但方向同样反了的决定。从 subtyping 看，没有任何字段和方法的东西应该像空 record，是**超类型**。Java/C# 却让 `null` 具有任何对象类型，像一个一切的 subtype。于是每次读字段、调方法都要检查 receiver 是不是 null，否则抛空指针。静态检查从不阻止这个错误。把“可能是 null”和“一定不是 null”分成两种类型，是很多人试过的设计。ML 没有 null，用 `option`。没那么方便，但你知道其他值不可能是 null。

Source: Section 10 — Java/C# Arrays / 0:05–9:07。

## 到这里还没有函数

Width 让“多字段的值用在少字段的地方”成为合法替换。函数类型自己何时是另一个函数类型的 subtype，是下一篇。OOP 里方法的覆盖为什么对返回类型和参数类型方向不同，就是那条规则的应用。

## Concept cards

### subtyping

- Problem: 类型相等太严，会拒绝实际上读不到坏字段的程序。
- Definition: `[Course]` 类型上的二元关系 `t1 <: t2`，加上一条规则：有子类型的表达式也有超类型。
- Mental model: 不是改写所有类型规则。是先给表达式一个更精确的类型，再允许把它看成更粗的类型。
- Example: 带 color 的点传给 `distToOrigin`。
- Why it matters: 静态 OOP 的“子类实例能传给要父类的地方”应该是这个关系的一个实例，而不是一个额外的魔法。
- Misunderstanding: 不是 subclassing。也不是“我想让它是就是”。关系写错，soundness 就没了。

### substitutability

- Problem: 怎样判断一条 subtype 规则该不该存在？
- Definition: `[Course]` 子类型的值必须能用于超类型的值能用于的每一种方式。
- Example: 多字段 record 仍能读写保留下来的字段。
- Misunderstanding: 不是代码风格指南。它是类型规则的正确性条件。Liskov 这个名字是补充。

### width subtyping

- Problem: 多余字段不该妨碍使用。
- Definition: `[Course]` 丢掉字段之后，宽 record 类型是瘦 record 类型的 subtype。字段的类型必须还对得上。
- Example: 三字段 `<:` 两字段，也 `<:` 只剩 color 的那个。
- Misunderstanding: 方向不要反。字段少的不是字段多的 subtype。少的那个被用在“会读 color”的地方会失败。

### depth subtyping

- Problem: 嵌套字段里也有多余的 `z`，width 走不进去。
- Definition: `[Course]` “若 `ta <: tb` 则字段类型 `ta` 可换成 `tb`”这条规则。在有 setter 时 unsound。
- Example: `setToOrigin` 把球的 center 写成没有 `z` 的点。
- Why it matters: 可变性限制了子类型能有多结构。不可变 record 可以要回这条规则。
- Misunderstanding: Java 数组协变就是这条不该有的规则。它没有恢复 soundness，只是把失败从“读字段”挪到了“写数组”并加上运行时检查。

### permutation / transitivity / reflexivity

- Definition: `[Course]` 字段顺序无关；关系可传递；每个类型是自己的 subtype。
- Why it matters: 传递性让规则可以分步写。自反在函数规则里避免特例。
- Misunderstanding: 这三条不产生新的“忘掉字段”能力。它们让关系是一个可用的数学关系。
