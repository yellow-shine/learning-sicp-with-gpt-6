# Module 7 — Duck Typing

## Problem

动态类型的方法可以写成：

```ruby
def mirror_update(point)
  point.x = point.x * -1
end
```

你写的时候想的是“参数是一个 Point”。可是方法体里没有任何地方检查 class。那这个函数**实际上**要求什么？

如果答案仍是“必须是 Point”，你就是在用文档撒谎。如果答案是“谁有 `x` 和 `x=` 就能传”，复用会变大，抽象会变薄。这就是 duck typing 要你正视的选择。

## 那句英语，收紧一点

`[Course]` “如果它走路像鸭子、叫起来像鸭子，它就是鸭子。”更精确的版本是：若它走得像、叫得像，那么**就我们当下的目的而言**，它是不是生物学上的鸭子不重要。

写方法时，你可能以为自己需要 `Foo` 的实例。你实际做的只是对参数发某些消息。若有个东西走起来像 Foo、叫起来像 Foo，但不是 Foo 的实例，动态类型下代码仍可能工作，客户传它也可能是合理的。

拥抱这个风格，意味着：

- 不假设对象是什么，只假设它有某些方法，并能用某些参数去调。
- 避开 Ruby 其实提供的 `class`、`instance_of?`、`is_a?`。

主张的好处是更多复用，因为你采取了很纯的 OOP 立场：对象的全部意义就是你能向它发什么消息。

Source: Section 8 — Duck Typing / 0:12–1:43。

## 四个词

| | 何时决定 | 依据 | 本课位置 |
| --- | --- | --- | --- |
| nominal typing | 通常编译期 | 类型的**名字**和声明的继承/实现关系 | Java class / interface。`[Course]` 在 interface 与 OOP subtyping 里讲：没声明继承，即使方法都有，也不是 subtype |
| structural typing | 通常编译期 | 类型的**结构**（有哪些字段/方法、什么类型） | Section 10 的 record subtyping 是结构式的。老师故意不用 class 名当类型 |
| duck typing | 运行期，而且常常只存在于程序员脑中 | 这次执行实际发了哪些消息 | Ruby 这一讲 |
| dynamic typing | 运行期 | 语言不做静态拒绝 | Ruby / Racket 的类型纪律 |

`[Inference]` “duck typing ≠ structural static typing” 这句课程没有用 structural typing 这个术语，但两边的机制它都讲了。结构子类型是：**类型系统**允许你忘掉多余字段，并且保证不会读到没有的字段。Duck typing 是：**没有这层保证**。你可以对任何对象发 `x`，错了就在那一行失败。一个接受“多一个 color 字段”的静态规则，仍然会拒绝“根本没有 `x` 方法”的参数。Duck typing 不会提前拒绝。

也不要把它收成 dynamic dispatch。Dispatch 是“有这个方法的多个版本时选谁”。Duck typing 是“我根本不要求你属于某个名义类型”。一次 `point.x` 可以同时是两者：不检查是不是 Point（duck），再按运行时 class 选 `x` 的实现（dispatch）。

## `mirror_update` 的契约一层比一层薄

`[Course]` 老师把同一段代码读了四遍：

1. 太粗：接收 Point，把 x 取负。
2. 仍太粗：接收任何有 `@x` 的 getter/setter 的对象，把 `@x` 换成 `@x * -1`。getter 不一定真的读写 `@x`。那是实现，写 `mirror_update` 的人不该假设。
3. 更精确：接收任何有 `x=` 和 `x` 的对象，调用 `x=`，参数是 `x` 的结果乘 `-1`。`x=` 是否更新了什么，并不被保证。叫 `x=` 却不更新是坏风格，但语言不阻止。
4. 真正的 duck-typing 读法：`x` 的结果还得有一个能接受 `-1` 的 `*` 方法。方法做的事是：把 `x` 的结果发送 `*` 消息和 `-1`，再把那个结果发送给 `x=`。

到第 4 层，文档几乎就是方法体。客户什么都没被隐藏，他们可以自己写这行，不必调用你。这是老师不喜欢的地方。

好处：也许某个你没预料到的 class 能复用 `mirror_update`，因为你没写 `instance_of? Point`。坏处：一旦有人依赖了 `*` 或 `x=` 的具体含义，你就不能把 `point.x * -1` 改成 `-point.x`。对数字这两者等价；对一个把 `*` 和一元负号实现得不同的对象，改完行为就乱了。调用者假设了太多实现，抽象优势就没了。

对 `mirror_update` 这种例子，老师认为 duck typing 常常是差风格。也许有些“不完全是 Point”的东西适合传进来，但不该是任意刚好有 `x` 和 `x=` 的东西。

Source: Section 8 — Duck Typing / 1:43–6:35。

## 老师承认的好例子

```ruby
def double(x)
  x + x
end
```

太小，不够有说服力，但是干净。数字有 `+`，字符串的 `+` 是拼接，`MyRational` 若定义了 `+` 也能传。原作者也许只想过数字，或者只想过“任何有 `+` 的东西”。客户的复用是真的。

另一个好例子在标准库，不在一个玩具函数里：`foo` 对参数调用 `count` 并传入 block。数组和 range 都有行为相同的 `count`。这是迭代器的分离关注点，和 ML 里“一个函数负责遍历，一个函数负责对元素做什么”是同一结构。见 `03`。

Source: Section 8 — Duck Typing / 6:35–7:27；Hashes and Ranges / 6:10–8:49。

## `print_size` 真正要求什么

用户例子，同一原则。`[Supplement]` 课堂没有 `print_size`，但规则就是 `double` / `mirror_update` 的规则。

```ruby
def print_size(x)
  puts x.size
end
```

它不要求 `x` 是 `Array`。它要求 `x` 响应 `size`，并且 `puts` 能处理 `size` 的结果（实践中会再调 `to_s`）。`String`、`Hash`、`Range`、你自己的类，都可以。

| | |
| --- | --- |
| flexibility | 新的集合不用继承 `Array` 就能传进来 |
| reuse | 一个函数服务所有“有尺寸”的东西 |
| error timing | 没有 `size` 时，错误在 `x.size` 那一行，不在调用边界 |
| tooling | 编辑器很难列出合法参数类型；重构 `size` 的含义会悄悄破坏远处的调用者 |

## Trade-off 一句话

Duck typing 用“晚失败、薄抽象”换“不用预先声明谁和谁兼容”。当你的兼容性本来就是“有这一个方法”，像 `double` 或 `each`，这笔交易划算。当你的兼容性其实是一整套不变量（点的 `x` 是数字，`x=` 真的更新坐标），只看方法名会把不变量漏掉。

`[Course]` 和等价性的关系要单独记住：在数字上 `x + x` 与 `x * 2` 等价。在 duck typing 的世界里，它们不是等价的程序变换，因为客户可以传入把这两个消息实现得不同的对象。动态 OOP 让“程序等价”这件 Part A 的事变得更难。

Source: Section 8 — Duck Typing / 1:43–2:23。

## Concept card

### duck typing

- Problem: 动态语言里，参数的契约该写成 class 名，还是写成实际发送的消息？
- Definition: `[Course]` 只假设对象能响应某些消息。不使用 `is_a?` / `instance_of?` / `class` 来分支。
- Mental model: 契约约等于方法体里的消息发送序列。隐藏得越少，复用越多，抽象越弱。
- Example: `double` 接受数字、字符串、定义了 `+` 的有理数。
- Why it matters: 它是“对象 = 可发的消息”这句话的极端形式，也解释了为什么 Ruby 标准库里 Array 和 Range 能传给同一个函数。
- Misunderstanding: 不是结构化静态类型。静态结构类型仍会在运行前拒绝缺方法的参数。也不是 dynamic dispatch。
- Modern: Python 的协议、TypeScript 的 structural type 看起来像，但是后者有静态检查。Go 的 interface 是静态的结构满足，更接近 structural typing，不是 duck typing。C++ template 在实例化前不检查方法是否存在，历史上更接近 duck typing。见 `18`、`19`。`[Modern Connection]`
