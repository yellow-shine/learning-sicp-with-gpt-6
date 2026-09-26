# Module 5 — Dynamic Dispatch

## Problem

`x.m` 不该被读成“变量 `x` 有一个函数 `m`”。变量里只有一个对象引用。这个对象运行时可能是 `Point`，也可能是 `PolarPoint`，还可能是某个你写这段调用时不存在的子类。

所以语言必须规定：看到一次方法调用，**哪段代码**会跑。

如果规定“按写下 `x` 时的 class 找”，`PolarPoint` 继承来的 `distFromOrigin2` 就会去调 `Point#x`，读到不存在的 `@x`。如果规定“按 receiver 此刻的 class 找”，同一段父类代码就会调到子类的 `x`。Ruby、以及几乎所有 OOP 语言，选择后者。老师认为这是面向对象相对闭包、相对普通函数**最独特**的一点。

它还有别的名字：late binding、virtual methods。课堂说这些名字指的是同一件事。

Source: Section 8 — Method Lookup Rules / 0:16–1:07；Overriding and Dynamic Dispatch / 4:43–5:11。

## 精确规则

`[Course]` 对调用 `e0.m(e1, ..., en)`：

```text
1. 从左到右，先把 n+1 个表达式都求值完
      e0 → obj0
      e1 → obj1
      ...
      en → objn
   求值本身若又有方法调用，那些调用先结束。这是递归定义。

2. obj0 叫 receiver。令 C = obj0 的 class。

3. 找方法体：
      C 自己定义了 m？用它。
      否则看 C 的 superclass，再上一层，直到 Object / BasicObject。
      第一个找到的就是要执行的代码。
      一层都没有，则按同样规则找 method_missing。
      Object 定义了 method_missing，默认是报 “no such method”。

4. 执行找到的方法体，环境是：
      形参 ← obj1 .. objn
      self ← obj0          ← 这一行实现了 dynamic dispatch
```

Mixin 插入查找链的方式在 `12`。Section 8 这一讲还没有 mixin，规则就是 class 然后 superclass。

Source: Section 8 — Method Lookup Rules / 4:02–6:24。

蓝色那一行为什么就够了：方法体里若再写 `self.m2` 或省略后的 `m2`，新的一次查找从 **obj0 的 class** 开始，不是从“定义了 `m` 的那个 class”开始。obj0 的 class 可以是定义 `m` 的 class 的子类，子类可以已经覆盖了 `m2`。

```text
Dynamic dispatch
= 运行时根据 receiver 决定调用哪个 method
= 执行方法体时把 self 设成 receiver
```

Source: Section 8 — Method Lookup Rules / 6:24–7:17。

## 和三种别的调用比

| 调用 | 选哪段代码 | 数据从哪来 |
| --- | --- | --- |
| 普通函数调用 | 词法作用域里这个名字绑定的函数 | 参数，加上函数自己的环境 |
| closure invocation | **这个函数值**里的代码，定义时已固定 | 参数 + captured environment |
| static dispatch `[Modern Connection]` | 编译期按声明类型选定的函数 | 参数；C++ 非 virtual 成员函数是这种 |
| dynamic dispatch | 调用时从 receiver 的 class 往上找 | 参数 + self 所指数的那块状态 |

`[Course]` 老师的原话比较是：方法查找比闭包调用更复杂。变量用一套环境规则；`self` 是另一套。更复杂不等于更好或更坏。如果你先学的是 OOP，它只是更熟悉，不是更简单。

Java / C# 的方法调用本质上用同一条规则。C++ 取决于方法是不是 virtual，但语言支持这套机制，而且在多数 OOP 语言里它是默认。

多出来的、Ruby 没有的复杂：Java/C#/C++ 允许同一 class 里多个同名方法，靠参数个数或静态类型挑选，叫做 static overloading。挑选规则要用类型检查的结果，可以写很多页，有时平局就报错。动态类型语言里这个设计不成立：没有静态类型可看。Ruby 的规则因此更简单：同名就是替换，一个 class 不会同时有两个同名方法。

Source: Section 8 — Method Lookup Rules / 8:06–11:29。

## 两条查找，不要混

`[Course]` 语言里不同种类的名字有不同的查找规则。ML 的变量查环境，record 字段查那条 record，两者不是一回事。Ruby 也拆开：

| 写出来的东西 | 怎么找 |
| --- | --- |
| 局部变量 | 类似 ML/Racket 的环境。block 有词法作用域。细节与 ML 略有不同 |
| `@x` | 在 **self 这个对象**里找这个实例变量。没有则 `nil`。像 record 字段 |
| `@@x` | 在 **self 的 class** 里找。所以同 class 的实例共享 |
| `e.m` / `m` | 上面的方法查找。这才有 dynamic dispatch |

实例变量查找**不**走 superclass 的“方法表”。它只看对象自己有没有这个 `@` 名。`PolarPoint` 没有 `@x`，父类方法若直接读 `@x`，得到 `nil`，不会 magically 找到子类的 `@r`。

Source: Section 8 — Method Lookup Rules / 1:24–3:54。

## 执行跟踪

### 简单覆盖

```ruby
class A
  def m
    1
  end
end
class B < A
  def m
    2
  end
end
x = B.new
x.m
```

```text
x
 ↓
B 的实例 obj
 ↓
查找 m：B 自己定义了 m → B#m
 ↓
self = obj
形参：无
 ↓
返回 2
```

若 `x` 是 `A.new`，查找在 `A` 就停，返回 1。变量名不参与选择。

### 继承的方法回调被覆盖的方法

这是课程要你能独立走完的跟踪。`Point#distFromOrigin2` 的体是 `self.x` 和 `self.y` 的运算。`PolarPoint` 覆盖了 `x` 和 `y`，没有覆盖 `distFromOrigin2`。

```text
pp.distFromOrigin2
    求值 pp → obj，class = PolarPoint
    PolarPoint 无 distFromOrigin2
    Point 有 → 选 Point#distFromOrigin2
    self = obj
    执行到 self.x：
        receiver 仍是 obj，class 仍是 PolarPoint
        PolarPoint 有 x → PolarPoint#x
        self = obj，读 @r、@theta
    self.y 同理
    用这两个数做几何运算
```

`Point#distFromOrigin`（直接读 `@x`）若被 `PolarPoint` 调用且没有覆盖，查找会找到 `Point#distFromOrigin`，然后实例变量查找在 obj 上找不到 `@x`，得到 `nil`，乘法失败。所以那个方法必须覆盖。区别完全来自方法体写的是 `@x` 还是 `self.x`。

Source: Section 8 — Method Lookup Rules / 7:32–8:06；Overriding / 7:48–8:08，8:51–10:16。

### 子类里的 even 被父类的 odd 调用

见 `06` 的完整对照。规则是同一条：`A#odd` 的体写着 `self.even(...)`。receiver 的 class 是 `B` 时，`even` 从 `B` 开始找。

## 为什么这比闭包难推理

`[Course]` 一段方法的可观察行为，包括它调用了哪些**可能被覆盖**的方法。你看着 `odd` 的源码，不能像看 ML 函数那样说“它调用的 even 就是上面那个”。子类可以换掉 even，于是 odd 的行为变了。可能是你想要的加速，也可能是一个永远返回 false 的 even，odd 就错了。

想孤立推理，就要限制覆盖：Ruby 可以把方法标 private（子类也不能用那种调用形式）；Java 有 `final` 禁止覆盖。禁止覆盖更不“面向对象”，但更模块化，也更好局部推理。这是风格争论，老师不判胜负，只要求你看见交换。

Source: Section 8 — Dynamic Dispatch Versus Closures / 6:48–8:32。细节在 `06`。这里先把语义钉住。

## Method lookup 链（课程版 vs 补充）

### 课程内容

没有 mixin 时：

```text
receiver.class
    → superclass
    → … 
    → Object
    → BasicObject
    → 没有则 method_missing（同样从 receiver.class 往上找）
         Object 提供默认实现：报错
```

有 mixin 时，老师在 Section 9 补了一条，并说 include 的先后顺序他不考：

```text
obj 的 class 自己定义的方法
    → 该 class include 的 mixins
    → superclass
    → superclass include 的 mixins
    → 再往上
```

后 include 的 mixin 遮蔽先 include 的。不考。

Source: Section 9 — Mixins / 3:49–4:46。

### 补充知识

`[Supplement]` 真实 Ruby 还会经过 singleton class（对象自己的方法）、prepend、`Kernel`。本课没有建立这些。做作业和考试按上面的课程链即可。若 IRB 里 `nil.methods` 比你预期多，多出来的常常来自这些层，不是课堂规则写错了。

## Concept cards

### dynamic dispatch

- Problem: 同一段源码 `self.x`，对不同 class 的 receiver 应执行不同方法体。
- Definition: `[Course]` 调用时按 receiver 的运行时 class 查找方法；执行时 `self` 绑定为该 receiver。
- Mental model: 方法体不把“下一步调用谁”在定义时关闭。它关闭的是“向 self 发消息”这个动作。
- Example: `PolarPoint` 继承 `distFromOrigin2`。
- Runtime: 见上面的四步规则。
- Why it matters: 这是 OOP 相对函数闭包新增的语义，也是后面“加一个变体不用改旧类”的机制基础。
- Misunderstanding: 不是 dynamic typing。静态语言的 virtual 调用同样是 dynamic dispatch。
- Modern: C++ `virtual`，Java 实例方法默认如此，Go 接口方法，Rust `dyn Trait`。`[Modern Connection]`

### method lookup

- Problem: 名字 `m` 在多张方法表里都出现时选哪一张。
- Definition: `[Course]` 从 receiver 的 class 开始，沿 superclass 找第一个定义。Mixin 插在 class 与其 superclass 之间。
- Mental model: 一张链，不是“把所有方法复制进子类对象”。覆盖是链上更近的定义赢。
- Misunderstanding: 查找方法 ≠ 查找 `@x`。后者只看对象自己的状态。

### late binding / virtual method

- Problem: 需要一个词说出“不在编译期绑死方法体”。
- Definition: `[Course]` dynamic dispatch 的别名。
- Misunderstanding: virtual 不是“这个方法跑得慢”的同义词。慢是某些实现的代价，不是定义。`[Supplement]` vtable 是 C++ 的一种实现技术，课堂没讲。
