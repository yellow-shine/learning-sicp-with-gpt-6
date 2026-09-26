# Module 12 — 多重继承、Mixin、Interface、抽象方法

Section 9 后半不服务作业，但老师说考试可能问，也值得知道。四样东西都在回答：一个类想拿到**多于一处**的复用或类型资格时，语言愿意承担多少语义麻烦。

```text
multiple inheritance   能力最大，歧义最多     C++ 最著名
Ruby mixin             少一些能力，少一些问题
Java/C# interface      更少能力，问题也更少
abstract method        不是第四种复用，是“子类必须填这个洞”的静态检查
```

Source: Section 9 — Multiple Inheritance / 0:15–1:01。

## Multiple inheritance

### Problem

一个 superclass 这么有用，为什么只能有一个？`ColorPoint` 给点加颜色和 `darken`，`Pt3D` 给点加 `z` 并覆盖距离。`ColorPt3D` 想两者都要。Ruby 没有语法。你只能 subclass 其中一个，再把另一个的方法抄进来。抄哪边，往往看哪边更短。两种抄法都没有说出“我要两个 superclass 的全部”。

`StudentAthlete` 继承 `Student` 和 `Athlete`，两者又继承 `Person`，是同一形状。

Source: Section 9 — Multiple Inheritance / 1:01–4:12。

### 树变成有向无环图

先分清用词，否则讨论会吵错对象：

- immediate subclass：A 的 superclass 列表里直接写了 B。
- transitive subclass：中间还隔着别的类。A 是 B 的子类，B 是 C 的子类，则 A 是 C 的传递子类，但不是直接子类。

单继承时，这些关系是一棵树，叫 class hierarchy。父节点是唯一的 immediate superclass。

多继承让层次变成 DAG。一个类可以有多个父节点。`Y` 到 `X` 可以有两条路：`Y → V → X` 和 `Y → Z → W → X`。

### 语义问题（课程只展开这几个）

老师还提到、但不讨论：静态类型检查会更复杂，高效实现 OOP 也会更难。

1. `V` 和 `Z` 都定义了 `m`。`Y` 继承哪一个？
2. `Y` 自己覆盖 `m` 时，`super` 指哪一个 super？
3. `X` 定义了 `m`，`Z` 覆盖了，`V` 没有。`Y` 该看到谁？从 `Y` 的角度看，也许只该问“`V` 有没有 `m`”，至于 `V` 是自己定义的还是继承的，不该有区别。
4. 字段更麻烦。`X` 有一个实例变量，`Y` 该有一份还是两份？

两种需求都真实存在，所以 C++ 提供不同种类的继承，有时得到两份同名字段，有时得到一份。课上不展示 C++ 语法。

- `ColorPt3D` 想要**一份** `x`、一份 `y`。不想要两套坐标系。
- `Artist` 和 `Cowboy` 都有 `draw`，一个画画，一个拔枪。`ArtistCowboy` 两种都要，这合理。若两个 `draw` 都使用名为 pocket 的字段（画笔和枪都从口袋掏），这个人需要**两个** pocket，否则两个方法会互相破坏。没有一种字段复制策略能同时满足 3D 彩点和艺术家牛仔。

这些麻烦是许多语言干脆不提供多重继承的原因。

Source: Section 9 — Multiple Inheritance / 4:12–10:15。

## Mixin

### Problem

想复用一包方法，又不想要第二个 superclass，也不想复制粘贴。

`[Course]` Mixin 是一堆方法，而且只有方法。不是 class。不能 `new`。class 仍有一个 superclass，另外可以 include 任意多个 mixin。效果像把那些方法定义打进这个 class：可以覆盖 superclass 的方法，也可以被 class 自己的定义覆盖。

关键能力：mixin 里的方法可以使用 `self`。它们如此属于这个 class，以至于能调用 class 里定义的其他方法。

Ruby 用 `module` 定义 mixin。`module` 也管名字空间，一个关键字两用。课上只把它当 mixin。

```ruby
module Doubler
  def double
    self + self     # 假定 include 我的 class 定义了 +
  end
end

class Point
  def +(other)
    # 新点，坐标相加
  end
  include Doubler
end
```

`p.double` 调用 `Point#+`。给 `String` include 同一个 mixin 之后，`"hello".double` 得到 `"hellohello"`，因为字符串的 `+` 是拼接。改标准库的 class 是可疑风格，但能工作。

Source: Section 9 — Mixins / 0:05–3:42。

### 查找规则

方法 `m` 的查找变成：

```text
obj 的 class
    → 它 include 的 mixins（后 include 的遮蔽先 include 的；这条顺序不考）
    → superclass
    → superclass 的 mixins
    → 再往上
```

Mixin 方法可以读写实例变量，那些变量就是普通对象的实例变量。两个 mixin 若用了同一个 `@` 名字，会互相踩。因此不少人认为 mixin 碰实例变量是差风格。另一些场合你就是需要。语义上允许，风格上老师不裁决。

Source: Section 9 — Mixins / 3:49–5:18。

### 人人喜欢的两个标准 mixin

`Comparable`：你定义 `<=>`（飞船运算符）。它接收另一个对象，左边较小返回负数，相等返回 0，右边较小返回正数。Mixin 用它定义 `<`、`>`、`==`、`!=`、`<=`、`>=`。数字自己就是这样实现的：`3 <=> 4` 为 `-1`。`Name` 按姓、名、中间名依次比较，include 一行，六个运算符都出现。

`Enumerable`：你定义 `each`。Mixin 用 `each` 定义 `map`、`any?`、`count` 等一大批迭代器。课堂的 `MyRange` 用 while 从 low 到 high `yield`。之后 `r.count { |x| x.odd? }` 能用，是因为 count 的实现在 mixin 里，它只知道调用 `each`。

字幕在讲 `MyRange` 时有一处口误，把 `Enumerable` 说成了 `Comparable`。前面他已经正确命名了 `Enumerable`，并且说“你只要实现 `each`”。笔记按这个更一致的说法。`[Inference]` 口误不影响规则。

Source: Section 9 — Mixins / 5:28–10:21。

### 它替代不了多重继承

`Color` 做成 mixin（getter、setter、`darken`，用 `@color`）之后，`ColorPoint` 和 `ColorPt3D` 都可以 include 它，同时各自只有一个 superclass。3D 彩点这个例子 mixin 够用。

`Artist` 和 `Cowboy` 不适合做成 mixin。它们都应该是 class。两个都是 class，就不能同时继承。所以 mixin 很好，老师不会建议它是多重继承的完全替代。

Source: Section 9 — Mixins / 10:21–11:47。

## Interface

### Problem

静态 OOP 要阻止 method-missing：调用某方法时，对象必须真有这个方法。Java/C# 里每个 class 同时引入一个类型。方法有参数类型和结果类型。若 `C` 是 `D` 的子类（传递也算），则类型 `C` 是类型 `D` 的 subtype。需要 `A` 的地方可以传 `A` 的 subtype。

这还不够灵活。两个不在一条继承线上的 class，可能都有 `m1`、`m2`。调用方只需要这两个方法。

`[Course]` Interface 是类型，不是 class。和 mixin 一样不能造实例。和 mixin 不同，里面不能放方法体。只放：有这样一个方法，参数类型是这些，结果类型是这个。

```java
interface Example {
    void m1(int a, int b);
    Object m2(Example e, String s);
}
```

class 仍只有一个 superclass，但可以实现任意多个 interface。声称实现，就必须自己写出或继承到每一个要求的方法，类型还得对。做到了，这个 class 的类型就是该 interface 类型的 subtype。于是 `m2` 的参数可以是任何实现了 `Example` 的 class 的实例。方法体知道 `e` 有那些方法，不知道具体是哪个 class。

Interface 不提供方法，不提供字段，多重继承的那些歧义都不出现。它给你的全是义务。换来的是更灵活的类型系统：字段的类型、参数的类型都可以是 interface。Java 有 interface 比没有时灵活得多；仍远不如 Ruby 这种动态类型灵活。动态与静态的交换，Part B 已经讨论过。动态语言不会去加 interface，因为没有一个类型系统等着被放宽。

Source: Section 9 — Interfaces / 0:41–7:27。

## Abstract method

可选。没学过静态 OOP 可以跳。学过 Java/C#/C++ 的话老师强烈建议看。

### Problem

Superclass 写了大量子类都要用的代码，但有的步骤没有合理的默认值。GUI 里，移动和放置可以共享，`size` 不该默认成 10×10 或 0×0。Superclass 希望每个真正被实例化的子类都覆盖某个方法。

Ruby 里这只能写在注释里，并且你不该 `new` 那个 superclass。

```ruby
class A
  def m1
    m2          # A 自己没有 m2
  end
end
```

对 `A` 的实例调用 `m1` 会 method-missing。若只实例化定义了 `m2` 的子类，dynamic dispatch 让这完全合理。

静态类型不允许“可能 method-missing”的程序。笨办法：`m2` 的默认实现抛异常，注释说请覆盖。能通过类型检查，错误仍在运行时。

更好的是让类型检查器拒绝：superclass 只写签名，标记 abstract（C++ 叫 pure virtual），并且禁止 `new` 这个 class。子类要么也是抽象的，要么按那个签名提供方法体。这在编译期抓错，也向读者表明这个方法就是该被覆盖的。它不增加运行时能力。抛异常的版本已经有同样的运行行为。多出来的只是编译期检查。

Source: Section 9 — Abstract Methods / 0:35–5:35。

### 和高阶函数是同一形状

两者都是把代码传给代码。

```text
OOP：A#m1 调用 m2，但不知道 m2 是什么。子类提供定义。
     公共代码在 m1，变化的代码由子类通过 dynamic dispatch 填入。

FP：f 调用参数 g，但不知道 g 是什么。调用者传入一个函数。
    公共代码在 f，变化的代码由调用者填入。
```

Source: Section 9 — Abstract Methods / 5:35–7:17。

### 为什么 C++ 可以没有 interface

若语言同时有多重继承和抽象方法，interface 是多余的。你 subclass 一个**全部方法都是 pure virtual** 的 class。你没有从它得到代码，你得到的是“我是它的 subtype，因为我实现了这些方法”。Interface 存在，是为了绕过“只能有一个 superclass”。C++ 没有这个限制，所以用全抽象的 class 做 interface 风格的编程。因此你会在“静态类型且没有多重继承”的语言里看到 interface，而不会在 Ruby 或 C++ 里看到同样的构造。

Source: Section 9 — Abstract Methods / 7:17–8:47。

## 设计目的，不是语法对照

| 机制 | 主要目的 | 给了你什么 | 没给你什么 |
| --- | --- | --- | --- |
| 多继承 | 两套实现都要，并且两个都是 class | 方法、以及（取决于语言）字段 | 无歧义的查找 |
| mixin | 复用一包方法，尤其是用 self 调用宿主必须提供的那一个方法 | 方法，可访问 self | 第二个 superclass；两份同名字段的故事也没有好好解决 |
| interface | 让静态类型按“有这些方法”来写，而不是按唯一的 class 继承线 | subtype 资格 | 代码 |
| abstract method | 强迫子类填洞，并让父类方法能通过类型检查 | 编译期义务 | 新的运行时能力 |

`[Modern Connection]` 见 `18`：Rust trait 更接近“带默认方法的 interface + 静态分派”，Go interface 是结构式的名义无关满足，Scala trait 同时有 mixin 和类型的味道。它们都不是 Ruby mixin 的别名。

## Concept cards

### mixin

- Problem: 想要第二份方法复用，但不想要第二个 superclass。
- Definition: `[Course]` 一包方法。include 进 class。不能实例化。方法里可以用 self，因此能调用宿主的 `+` 或 `each`。
- Example: `Doubler`、`Comparable`、`Enumerable`。
- Misunderstanding: 不是 interface。Mixin 有方法体。也不是多重继承的完全替代。

### interface

- Problem: 静态类型里，两个无关的 class 都要能传给“只需要某几个方法”的代码。
- Definition: `[Course]` 只有方法签名的类型。实现它是义务。做到了就产生 subtype 关系。
- Example: 参数类型写成 interface，调用方不知道具体 class。
- Misunderstanding: 动态语言不需要它来“更灵活”。动态类型已经更灵活。Interface 是在静态世界内部放宽。

### abstract method

- Problem: 父类的代码要调用一个只有子类才知道的方法，类型检查器又不许 method-missing。
- Definition: `[Course]` 只有签名、没有方法体。class 因此不能被实例化，除非子类补上。C++ 称 pure virtual。
- Example: `m1` 调用抽象的 `m2`。
- Misunderstanding: 不增加表达能力，只增加编译期检查。和传一个函数参数是对偶：谁提供那块代码，一个是子类，一个是调用者。

### multiple inheritance

- Problem: 一个类在概念上同时是两种已有的类。
- Definition: `[Course]` class hierarchy 从树变成 DAG。一个类有多个 immediate superclass。
- Example: `ColorPt3D` 想要一份坐标；`ArtistCowboy` 想要两个 pocket。
- Misunderstanding: “支持多继承”不是一个开关。字段复制策略至少有两种，语言得选，或像 C++ 那样都提供。
