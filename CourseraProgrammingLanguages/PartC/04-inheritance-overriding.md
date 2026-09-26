# Module 4 — Subclassing、继承、覆盖

## Problem

两个 class 的方法大部分相同，只有一两处不同。复制方法，bug 会复制。把所有差异都塞进原来的 class，原 class 会被不相关的字段撑大，还会破坏别人依赖的不变量。

Subclassing 是第三种组织：新 class 声明“我先拿到 superclass 的全部方法，再替换若干、再加若干”。

## 语法与规则

`[Course]`

```ruby
class ColorPoint < Point
  # 方法
end
```

省略 `< Super` 时，默认 superclass 是 `Object`。`Object` 的 superclass 是 `BasicObject`，再往上是 `nil`。课堂的反射演示走到这里为止。

**课程没有讲 `Kernel`。** `[Supplement]` Ruby 实现里很多方法实际定义在 `Kernel`，再被 include 进 `Object`。复习 method lookup 时不要把 `Kernel` 写进“老师讲过的链”。课程链是：

```text
你的 class → … → Object → BasicObject → （没有）
```

Subclass 的方法表 = superclass 的方法，加上自己定义的方法；同名则替换，这就是 overriding。老师的说法是 inherit：从父类拿到方法。

实例变量不参与这个故事。Ruby 的 class 定义不列出字段。对象一开始没有实例变量，赋值才出现。所以“子类继承字段”这句话在 Ruby 里没有意义。多数别的 OOP 语言不是这样，字段属于 class 定义。老师特意指出这个差别。

动态类型下，subclassing **与类型系统无关**。它只决定哪些方法被定义。

Source: Section 8 — Subclassing / 0:37–2:41，6:59–7:06。

## 例子：Point 与 ColorPoint

课堂重建，保留老师强调的两个距离方法：

```ruby
class Point
  attr_accessor :x, :y
  def initialize(a, b)
    @x = a
    @y = b
  end
  def distFromOrigin
    Math.sqrt(@x * @x + @y * @y)
  end
  def distFromOrigin2
    Math.sqrt(self.x * self.x + self.y * self.y)
  end
end

class ColorPoint < Point
  attr_accessor :color
  def initialize(a, b, c = "clear")
    super(a, b)       # 不是 initialize(a, b)，那会无限递归
    @color = c
  end
end
```

`super` 的意思：我正在覆盖 superclass 的这个方法，请把 superclass 的版本当 helper 调。参数怎么传，课堂在这个例子里是显式 `super(a, b)`。

```text
cp = ColorPoint.new(0, 0, "red")
cp.x        → 0        继承来的 getter
cp.color    → "red"    自己加的方法
p = Point.new(0, 0)
p.color     → undefined method
```

Source: Section 8 — Subclassing / 2:42–6:31。

## `is_a?` 和 `instance_of?`

```text
cp.is_a? ColorPoint   → true
cp.is_a? Point        → true
cp.is_a? Object       → true
cp.instance_of? Point       → false
cp.instance_of? ColorPoint  → true
```

`is_a?` 沿着 superclass 走。`instance_of?` 只认精确 class。

老师说：在程序里用它们通常不是 OOP 风格，因为你放弃了 duck typing，在按“到底是不是 Point”分支。它们的价值是把语义说清楚：子类的实例也算 superclass 的实例（`is_a?` 意义下）。

术语陷阱：Java 的 `instanceof` 像 Ruby 的 `is_a?`，不像 `instance_of?`。Java 没有内置关键字表示“精确 class”。通常你想要的是 `is_a?` 那种，因为子类实例应该能当 superclass 实例用。这是后面 substitutability 的直观版，但此刻 Ruby 还没有静态类型。

Source: Section 8 — Subclassing / 7:16–10:07。

## Overriding 不只是换掉一个方法

三维点是一个有争议的子类。有人认为 3D 点不是 2D 点，这样继承是滥用；有人认为投影到 xy 平面或代码复用使它合理。老师不裁判风格，只用它说明覆盖：

```text
ThreeDPoint 继承   x x= y y=
ThreeDPoint 覆盖   initialize distFromOrigin distFromOrigin2
ThreeDPoint 新增   z z=
```

`distFromOrigin` 可以用 `super` 拿到 xy 平面上的距离 `d`，再算 `sqrt(d*d + z*z)`。到这里为止，继承看起来还只是少抄代码。对象有点像一个有很多方法的闭包，字段像闭包环境里的变量。

真正不同的例子是 `PolarPoint`。它用 `@r` 和 `@theta` 表示点，甚至没有 `@x`、`@y`。它必须覆盖 `x`、`y`、`x=`、`y=`、`distFromOrigin`。`distFromOrigin` 若不覆盖，父类去读 `@x` 会得到 `nil`，乘法报错。

但 `distFromOrigin2` **不用覆盖**。它的方法体在 `Point` 里，调用的是 `self.x` 和 `self.y`。receiver 若是 `PolarPoint`，这两次调用走到子类的三角函数版本，结果仍然对。

这就是 overriding 从“复制粘贴的替代品”变成另一种语义的地方。完整查找规则在 `05`。这里只先记住现象：

```text
继承来的方法，如果向 self 发消息，
用的是 receiver 的 class，不是写下这段方法的那个 class。
```

Source: Section 8 — Overriding and Dynamic Dispatch / 0:46–8:51。

### 执行跟踪（缩短）

```ruby
pp = PolarPoint.new(4, Math::PI / 4)
pp.distFromOrigin2
```

```text
receiver 的 class = PolarPoint
PolarPoint 自己没有 distFromOrigin2
沿 superclass 找到 Point#distFromOrigin2
执行时 self = pp
方法体调用 self.x
    从 PolarPoint 重新查找 x
    找到 PolarPoint#x = @r * cos(@theta)
self.y 同理
然后做平方和的平方根 → 4.0
```

`distFromOrigin` 则在 `PolarPoint` 自己的方法表里就找到了，直接返回 `@r`。

Source: Section 8 — Overriding and Dynamic Dispatch / 8:51–10:16。

## 什么时候不该 subclass

`[Course]` 老师认为大型 OOP 程序里 subclass 往往用得过多。ColorPoint 这个例子里 subclass 是好风格，但要看见被拒绝的三个替代方案，才知道“好”好在哪里。

1. **重开 `Point`，给所有点加 color。** 动态语言做得到，默认参数还能让旧的 `new` 继续工作。坏处：改了别人的类，可能破坏不变量；每个点都背上 color；别人再加 `z`、再加名字，对象膨胀，方法还可能互相假设对方不存在。不模块化。

2. **复制粘贴出另一个 `ColorPoint`，不继承。** 完全隔离，Point 的后续修改影响不到你。代价是零复用。bug 复制，新功能也要再抄一遍。一般优先复用。

3. **内嵌一个 Point。** `ColorPoint` 的 superclass 仍是 `Object`，`@pt` 持有一个 `Point`。`x` 方法就是 `@pt.x`。好处：表示是封装细节，甚至可以把对外的名字改成 `fu`/`bar`。坏处：每个方法都要手写转发；而且 ColorPoint **不是** Point。`is_a? Point` 为假。静态类型语言里这更严重：它不会具有 Point 那个类型。对“我就是一个点，外加颜色”这个意图，内嵌是较差风格。

但老师紧接着说：很多时候你**应该**内嵌，却因为懒或想不清楚，用了 subclass。Subclass 表达的是“我就是 superclass 那种东西，再加一点、改一点 initialize”。不是“我内部用到了它”。

Source: Section 8 — Why Use Subclassing / 0:51–7:12。

## Subclassing ≠ subtyping

这一节必须先钉死，尽管证明要到 Section 10。

`[Course]` 在 Ruby 这一周，subclassing 只关于方法表。没有类型，就没有 subtype 关系要维护。`is_a?` 为真，是对象模型的事实，不是类型检查器的事实。

`[Course]` 到静态 OOP 时，Java/C# **选择**让 subclass 关系同时成为 subtype 关系。这是语言设计决定，不是逻辑同一。一个 class 可以拥有另一个 class 的全部方法，若没有声明继承，Java 仍不把它当作 subtype。反过来，糟糕的子类（3D 点覆盖了距离的含义）在 Java 里仍是 subtype，类型系统不判断“是不是概念上的 is-a”。

所以：

```text
subclassing   实现关系：方法从哪张表继承，哪张表覆盖
subtyping     类型关系：值能否安全地用在期待超类型的地方
is-a          设计意图：ColorPoint 是一种 Point 吗
```

三者经常一起出现，因为语言和程序员都喜欢让它们重合。它们不是定义上的同义词。

Source: Section 8 — Subclassing / 2:24–2:31；Section 10 — Subtyping for OOP / 0:42–0:52，4:05–4:47。后半句的“类型系统不检查是不是好的 is-a”是 `[Inference]`：课程给出了 3D 点的风格争议，又给出了 Java “subclass 即 subtype”的规则，但没有把这两句连成“因此 Java 接受坏的 is-a”。

## Concept cards

### subclassing

- Problem: 想复用方法表，并让 `is_a?` 意义上的“也是父类实例”成立。
- Definition: `[Course]` `class B < A`。B 拥有 A 的方法，除非同名覆盖或自己新增。
- Mental model: 方法表的增量定义。不是字段布局的继承（在 Ruby 里）。
- Example: `ColorPoint < Point`。
- Misunderstanding: 不等于 subtyping。也不等于“内部有一个 A”。

### inheritance

- Problem: 不复制就能拿到父类方法。
- Definition: `[Course]` 子类得到 superclass 里定义的方法。查找时若自己没有，就去 superclass。
- Example: `cp.x` 用的是 `Point` 的 getter。
- Misunderstanding: 继承来的方法并不因此“冻结”。它向 self 发的消息仍动态查找。见 `05`。

### overriding

- Problem: 子类需要同名操作的不同行为。
- Definition: `[Course]` 子类定义同名方法，替换继承来的版本。Ruby 里同名就是覆盖。不像 Java，不存在“同名但参数类型不同所以只是 overload”。
- Example: `PolarPoint#x` 覆盖 `Point#x`。
- Runtime: 只有查找从子类开始时才选到新版本。父类方法体里的 `self.x` 也会这样。
- Misunderstanding: override ≠ overload。见 `11` 和 `20`。

### super

- Problem: 覆盖之后还想用旧实现当 helper。
- Definition: `[Course]` 调用 superclass 里被你替换的那个方法。写方法自己的名字会递归。
- Example: `ColorPoint#initialize` 里 `super(a, b)` 初始化 `@x`、`@y`。
- Misunderstanding: `super` 不是“父类对象”。没有一个单独的父类实例。是同一对象上的另一段方法体。
