# Module 1 — Ruby 是一门语言设计案例，不是一门要背完的语法

## Problem

Part A/B 之后，还缺一个位置：动态类型的面向对象语言。为什么不用继续用 Racket？Racket 也能做对象。为什么不用 Java？Java 的类型系统会从第一天起挡住“方法查找到底怎么发生”。

`[Course]` 老师的选择标准很窄：

- 纯面向对象：所有值都是对象，数字也是。没有“除了数字以外”。
- class-based：先定义 class，每个对象有且有一个 class，class 决定行为。JavaScript 那种原型对象模型故意不讲。
- 动态类型：和 Racket 对照，同时让 OOP 的机制先露出来。
- 有 mixins：比 Java interface 多一点代码复用，比 C++ 多重继承少一点麻烦。后面单 unique 讲。
- 有闭包：好和 ML / Racket 接上。
- 脚本语言式的动态：局部变量不用先声明；class 可以在运行时被改。

不讲的东西同样重要：字符串库、Rails、以及“同件事有五十种写法”里的大部分。那些让 Ruby 流行，但不服务于这门课的概念。

Source: Section 8 — Introduction to Ruby / 3:12–6:00。

## 为什么“再学一门 OOP 语言”不够

如果只记 `class`、`def`、`new`，你会以为 Part C 是语法课。老师反复说：语言只是载体，概念才是课程。Ruby 的价值是它把对象模型推到极端，极端之后，几个本来搅在一起的词会分开。

```text
dynamic typing          错误何时被发现
dynamic dispatch        选哪段方法体
dynamic class definition  方法表能不能在运行中变
duck typing             参数契约写成“class 名”还是“能收哪些消息”
```

`[Inference]` 这四行对照表是根据各讲定义整理的，不是一张原幻灯片。依据见 `00-course-overview.md`。

## 最小程序在做什么

课堂第一个程序（重建）：

```ruby
class Hello
  def my_first_method
    puts "Hello, world!"
  end
end

x = Hello.new
x.my_first_method
```

不要把它读成“调用变量 `x` 的函数”。读成：

```text
Hello.new
    造一个对象，它的 class 是 Hello
x.my_first_method
    求值 x，得到 receiver
    在 Hello 里找到 my_first_method
    以 self = 那个对象 执行方法体
puts ...
    也是一次方法调用，不是一个语言外的“打印语句”
```

`puts` 的结果是 `true`。REPL 里 `load "file.rb"` 类似 ML 的 `use`。表达式末尾通常不写分号；换行有语法意义；**缩进没有语义**。

Source: Section 8 — Introduction to Ruby / 8:50–11:08；Classes and Objects / 11:44–12:19。

## “Everything is an object” 到底意味着什么

不是口号。它是一条求值规则：每个表达式的结果都是指向对象的引用。因此：

1. 任何对象都可以尝试向它发消息。没有这个方法，不是“这不是对象”，而是实现去调 `method_missing`。默认的 `method_missing` 打印 undefined method。
2. `3 + 4` 是语法糖，等于 `3.+(4)`。`3.abs`、`(-5).abs` 都是方法调用。
3. `nil` 也是对象。它像 Java 的 `null`、ML 的 `unit` 那样用来表示“没有数据”，但它能收消息，例如 `nil?`。`nil.nil?` 为 true，其他对象的 `nil?` 为 false。
4. Ruby 里只有 `false` 和 `nil` 算假。空字符串也是真。
5. 文件或 REPL 顶层的方法，被加进 `Object`。`Object` 是你定义的 class 的 superclass，所以这些方法每个对象都能调。顶层方法并没有逃出对象模型。
6. class 也是对象。`3.class` 在课堂用的 Ruby 里是 `Fixnum`，`3.class.class` 是 `Class`，`Class.class` 还是 `Class`。老师把“class 的 class 的 class”叫做通往疯狂之路：有趣，但不是你该在程序里依赖的推理。

`[Supplement]` 现代 Ruby 把 `Fixnum`/`Bignum` 合成了 `Integer`。课堂语义不变：整数是某个数值 class 的实例，那个 class 的 class 是 `Class`。

Source: Section 8 — Everything Is an Object / 0:13–5:00，5:02–8:13。

## Class 为什么也是动态的

问题：对象的行为由它的 class 决定。如果 class 本身是对象，程序运行时能不能改这个对象的方法表？

Ruby 的答案是能。重新打开同名 class，就是在已有定义上追加或替换方法：

```ruby
class MyRational
  def double
    self + self
  end
end
```

关键语义问题：对象是在方法被加上**之前**造出来的，它看得到新方法吗？

```text
x = MyRational.new(9, 6)     # 此时还没有 double
class MyRational
  def double; self + self; end
end
x.double                     # 看得到
```

`[Course]` Ruby 选择“看得到”。查找发生在**调用时**，查的是 class **当时**的方法表，不是对象诞生时的快照。老师认为这是更有用的语义。他也明确不喜欢这个特性：程序几乎无法静态分析，任何代码都能拆掉别人的抽象。方便的用法是给 `String` 或数字补一个小方法；危险的用法是改掉 `Fixnum#+`，课堂演示里这直接把用 Ruby 写成的 IRB 搞崩了。

由此得到一个语言设计观察：语言越动态，设计者要回答的语义问题越多。没有“运行时改 class”的语言，根本不会遇到“旧对象看新方法还是旧方法”。实现也可以更简单、更快，因为它不必处理这种情况。

Source: Section 8 — Class Definitions Are Dynamic / 0:03–1:28，3:25–3:52，6:23–7:39。

## 数组、哈希、range：灵活到几乎不报错

这些不是本课的概念核心，但它们是 block 和 duck typing 的载体。`[Course]`

数组是“数字下标 → 对象”的可变映射，不是 C 数组：

- 越界读返回 `nil`，不抛 bounds error。负下标从末尾数。
- 越界写会把中间填成 `nil`，数组变长。
- 元素可以是任何对象。
- `+` 连接并返回**新**数组；`|` 是去重并集。
- `push`/`pop` 当栈，`push`/`shift` 当队列。于是小脚本里往往不为 tuple、list、stack、queue 另造类型。
- 别名规则和普通对象一样：`d = a` 是别名；`e = a + []` 是新数组。

哈希是任意对象当键的映射，没有自然顺序。常用来当“字段名不固定的 record”，或把一堆配置塞进一个参数。`[]` / `[]=` 和数组一样。不存在的键得到 `nil`。`each` 交给 block 的是键和值一对。

range 表现得像一段连续整数，但只存上下界。`1..1_000_000` 不是一百万个元素的数组。它仍有 `inject`、`count` 等方法。

风格建议来自课堂：能用 range 就用 range，更省、也更说出意图；数字下标会让代码难读时用哈希。

分离关注点（和 Part A 的高阶函数是同一件事）：`foo` 只知道“对每个元素问一个 block”，`Array#count` 和 `Range#count` 各自知道怎么遍历。调用方不关心对方是数组还是 range。这就是 duck typing 在标准库里的正常形态，见 `07-duck-typing.md`。

Source: Section 8 — Arrays / 0:02–4:36，6:06–8:57；Hashes and Ranges / 0:16–8:49。

## Trade-offs

| 设计 | 得到 | 付出 |
| --- | --- | --- |
| 一切皆对象 | 语言更小、更规则；`+` 和 `abs` 没有特殊通道 | 数字也走方法调用；`nil` 混进条件里 |
| 动态类型 | 学 OOP 时类型不挡路；duck typing 成为自然风格 | 很多错误要跑到那一行 |
| 可重开 class | 能给旧类补方法；已有对象立刻看到 | 抽象可被任意代码拆掉；语义问题变多 |
| 数组几乎不报错 | 一种结构当 tuple/栈/队列 | 下标写错得到 `nil`，错误推迟 |

## 和后面的关系

- class 决定行为、object 持有状态：`02`。
- “调用时才查方法表”是 dynamic dispatch 的前提：`05`。
- “不检查 class，只发消息”是 duck typing：`07`。
- 运行时改 class，和“子类覆盖方法”不是一回事。前者改的是这个 class 自己的方法表；后者是另一个 class 的方法表。两者都会让同一次查找看到不同代码。

## Concept cards

### object

- Problem: 程序里的值，除了“数据”还要带上“能对它做什么”。
- Definition: `[Course]` 每个表达式的结果都是一个对象的引用。对象有私有状态、有一个 class、通过方法与外界通信。
- Mental model: 引用指向一块“状态 + class 指针”。你拿不到状态本身，只能发消息。
- Minimal example: `a = A.new; a.m1`。
- Why it matters: 后面所有机制都建立在“没有非对象的值”上。
- Misunderstanding: 对象不是 class。class 是对象的行为说明书，本身也是对象。
- Related: class, receiver, self。
- Modern: Java 的对象引用；C++ 对象可以有值语义，不完全一样。`[Modern Connection]`

### class

- Problem: 许多对象行为相同，不能每个对象抄一份方法体。
- Definition: `[Course]` class 定义方法。对象的 class 决定调用方法时执行哪段代码。`ClassName.new` 造出一个 class 为 `ClassName` 的对象。
- Mental model: 方法表。实例不各自存一份方法体。
- Minimal example: `class A; def m1; 34; end; end`。
- Why it matters: method lookup 从这里开始。Ruby 是 class-based，不是 JavaScript 那种原型模型。
- Misunderstanding: class 不是 type。Ruby 这里还没有类型系统。见 `14`。
- Related: instance, dynamic class definition。

### dynamic typing

- Problem: 要不要在运行前拒绝“这对象没有这个方法”。
- Definition: `[Course]` Ruby 像 Racket，不在编译期做这件检查。参数可以是任何对象。
- Mental model: 契约在调用发生时才被执行。
- Minimal example: `a.m2` 在 `A` 没有 `m2` 时，运行时报 undefined method。
- Why it matters: 它让 duck typing 成为默认，也让 Section 10 的静态 subtyping 成为对照而不是 Ruby 的机制。
- Misunderstanding: 不等于 dynamic dispatch。Java 是静态类型 + dynamic dispatch。

### dynamic class definition

- Problem: 行为说明书能不能在程序跑起来之后改？
- Definition: `[Course]` 任何代码都可以给已有 class 加、改、替换方法。已存在的实例在下次调用时看到新定义。
- Mental model: 方法表是活的。查找不拍照。
- Minimal example: 先造 `x`，再重开 class 加 `double`，`x.double` 成功。
- Why it matters: 动态语言会制造静态语言根本不问的语义题。
- Misunderstanding: 这不是 subclassing，也不是 duck typing。

## C++ 对照（先留一个钩子）

`[Modern Connection]` C++ 不是纯面向对象：`int` 不是对象，`operator+` 可以是函数也可以是方法。C++ class 定义在编译期固定，不存在课堂这种“重开 class、旧对象立刻换方法”的语义。所以 C++ 实现可以把方法地址更早定下来；Ruby 必须准备着方法表会变。virtual 函数对应的是 dispatch，不是这个动态改类。详见 `19-cpp-connections.md`。
