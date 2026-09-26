# Module 2 — 对象、类、状态、封装

## Problem

函数式里，数据通常是值：构造出来就定了，函数拿它算出新值。对象要解决的是另一件事：有一块数据会活很久，外界不能随便拆开它，只能通过它自己的操作去读、去改。

如果谁都能写 `e.@x`，那“对象”就只是一个带方法的 struct，表示法泄漏给所有客户。Ruby 把这条路堵死。

## 四个词，不要混

```text
class     方法的定义处。决定行为。
instance  ClassName.new 造出来的一个对象。
receiver  一次调用 e.m 里，e 求值得到的那个对象。
self      正在执行的方法所属的那个对象。它就是这次调用的 receiver。
```

`[Course]` 发消息和调用方法是同一件事。`e.m` 的意思是：求值 `e` 得到对象，调用**那个对象**的 `m`。不是“变量 `e` 有一个名叫 `m` 的函数”。

零参数的括号可省略。有参数时老师建议始终写括号。

Source: Section 8 — Classes and Objects / 0:13–1:20，7:35–8:17。

## 状态：实例变量在第一次赋值时出现

`[Course]` 状态是一组实例变量。Java/C#/C++ 叫 fields。Ruby 里你不声明它们，只对 `@foo` 赋值：

```ruby
class A
  def m1
    @foo = 0          # 没有就创建，有就改成 0
  end
  def m2(x)
    @foo += x         # 读到从未写过的 @foo，得到 nil，nil 不能 +
  end
  def foo
    @foo              # 方法返回最后一个表达式
  end
end
```

从未赋值就读，不报错，得到 `nil`。`@foo` 和 `@food` 是两个变量。不同实例可以有不同的实例变量集合；这通常是坏风格，但是合法的。好风格是在 `initialize` 里把要用的都建出来。这只是约定。别的语言常强制你在 class 里列出字段，并在构造器里初始化。

Source: Section 8 — Object State / 0:11–2:01，6:18–9:16。

### `new` 与 `initialize`

```text
q = A.new(19)
        │
        ▼
   分配一个新对象
   它还不别名于任何旧对象
   初始没有实例变量
        │
        ▼
   若 class 定义了 initialize
   把 new 的参数原样传给它
   initialize(19) 执行 @foo = 19
        │
        ▼
   new 返回这个对象
```

几乎不要自己调用 `initialize`。它特殊只是因为 `new` 会在返回前调用它。默认参数（`f = 0`）是一般方法都有的，不专属于构造器。

Source: Section 8 — Object State / 6:24–8:18。

### 别名

有可变状态，别名就重要。这和 Part A 的结论一样。

```text
x = A.new     # 新对象，与以往任何对象都不同
y = A.new     # 另一个新对象
z = x         # z 和 x 持有同一引用
```

`x.m1` 把这份对象的 `@foo` 设为 0 之后，`z.foo` 看到 0，`y.foo` 仍是 `nil`。赋值 `x = y` 改的是变量里的引用，不是把一个对象的状态拷进另一个对象。

Source: Section 8 — Object State / 2:03–6:04。

### 和实例变量容易混的三个东西

`[Course]` 老师拿它们做对照，并说 class 变量其实不特别有用：

| 东西 | 语法 | 谁共享 | 可见性 |
| --- | --- | --- | --- |
| 实例变量 | `@foo` | 每个对象一份 | 仅该对象的方法 |
| class 变量 | `@@foo` | 该 class 的所有实例一份 | 私有 |
| class 常量 | `Foo`，大写开头 | class 范围，外部用 `C::Foo` | 公开；不要改 |
| class 方法 | `def self.m` | 不属于某个实例 | 用 `C.m` 调用，不能碰实例变量 |

class 方法像 Java 的 static method：明确说“我不属于某个 `C` 的实例”。老师在这里叫你先不要把它理解成“class 也是对象所以能发消息”。那个事实在 “everything is an object” 里才展开。两套说法后来是接得上的，但课堂故意拆开。

Source: Section 8 — Object State / 9:16–11:36。

## 局部变量与 `self`

方法里的局部变量：以字母开头，在方法体任何地方赋值就会存在，作用域是整个方法体。没有 `let`，也不声明。它们可变。变量里永远是对象引用。

`self` 是关键字式的名字，指“当前对象，就是正在执行其方法的那个”。`self.m1` 是向自己发消息。零参数、且不是在表达“我要这个对象本身”时，可以省略 `self.`，默认就是 self。

只写 `self`、不加点，得到的是整个当前对象。课堂用它做链式调用：方法打印一点东西，然后 `return self`，于是 `c.m1.m2.m3` 能串起来。这不是新语言特性，只是“方法返回了对象，所以还能再发消息”。

Source: Section 8 — Classes and Objects / 8:23–11:40。

执行一条 `b.m3(5)`，其中 `m3` 的体是 `x.abs * 2 + self.m1`：

```text
求值 b            → 一个 class 为 B 的对象，称为 obj
查找 B#m3
self 绑定为 obj
x 绑定为 5
5.abs             → 5          （数字也是对象）
* 2               → 10
self.m1           → 在 obj 上查找 m1，得到 4
结果              → 14
```

## 封装：状态私有，方法分三级

`[Course]` Ruby 有一条老师喜欢的硬规则：实例变量**永远**只属于那个对象的方法。即使另一个对象和你是同一个 class，也不能碰你的 `@foo`。所以语法上不准写 `e.@foo`。`self.` 也是多余的，因为只能是 self。

要让外界看到或修改状态，必须自己写方法：

```ruby
def foo          # getter，惯例不叫 get_foo
  @foo
end
def foo=(x)      # setter，方法名可以以 = 结尾
  @foo = x
end
```

`e.foo = expr` 中间可以有空格，它仍是对 `foo=` 的调用，不是字段赋值。`attr_reader :foo, :bar` 和 `attr_accessor :foo` 只是少写这几行的糖。冒号的含义课堂不解释。

为什么值得强制私有：客户依赖的是方法接口，不是表示。以后 class 可以改掉实例变量，客户不用改。课堂例子：客户以为自己在设摄氏温度，setter 实际写入开尔文。不同 class 可以用完全不同的表示实现同一组方法。这和后面的 duck typing 是同一条抽象原则。

Source: Section 8 — Visibility / 0:40–5:35。

方法可见性有三档，默认 public：

| 级别 | 谁能调用 |
| --- | --- |
| public | 任何拿得到这个对象的代码 |
| protected | 同一 class 或 subclass 的对象（不必是 self） |
| private | 只能是同一个对象，而且必须写成 `m` 或 `m(args)`，不能写 `self.m` |

在 class 体里写 `protected` / `private` / `public`，后面的方法定义跟着变，直到下一个关键字。class 开头相当于隐式 `public`。

private 连 `self.m` 都不许，是一个容易踩的语法规则。`MyRational` 的 `reduce` 是 private，`initialize` 里只能写 `reduce`，不能写 `self.reduce`。

Source: Section 8 — Visibility / 5:35–8:35；A Longer Example / 2:46–3:04。

protected 的用途在分数例子里很具体：`add!` 需要对方的分子分母，但不能读 `r.@num`。于是 `num` / `den` 做成 protected getter。同一个 class 的另一个对象可以调，完全的外人不能调。

Source: Section 8 — A Longer Example / 6:26–7:16。

## 一个稍长的对象：分数知道怎么加自己

`MyRational` 是 Part A 里 rational 模块的面向对象重写。表示上的不变量：约分，分母为正。对象自己负责维持不变量，客户不碰 `@num`。

值得带走的设计，而不是每一行语法：

- `initialize(num, den = 1)`：一个参数就当整数。分母 0 则 `raise`。
- `to_s`：约定俗成的“把自己变成字符串”。数字也有 `to_s`。课堂还展示了 `e1 if e2` 和 `"#{...}"` 插值，说这些是脚本语言的便利，不是本课重点。
- `add!` 改自己；Ruby 里带 `!` 常表示 mutation。最后 `return self`，方便链式改。
- `+` 不改自己：先 `MyRational.new(@num, @den)` 做一份拷贝，再对拷贝 `add!`。定义名为 `+` 的方法之后，`r1 + r2` 就是 `r1.+(r2)`。运算符不是语言外的东西。
- `gcd` 就是普通递归，`self.gcd` 因为 private 必须写成 `gcd`。

这是 OOP 风格的一句定义：数据带着“对自己做什么”的方法，而不是外部函数拆开数据。

Source: Section 8 — A Longer Example / 0:55–12:15。

## Trade-offs

- 不声明字段：少仪式，打错一个字母就变成另一个字段，或读到 `nil`。
- 状态永远私有：表示可换；简单数据也要写 getter。糖（`attr_reader`）就是为了这个麻烦准备的。
- 方法默认公开：对象的目的就是被发消息；真正的内部步骤再标 private。
- 返回 `self`：调用链好看；也让“这个方法有没有副作用”更不容易从类型上看出来。Ruby 没有类型帮你。

## Concept cards

### receiver

- Problem: `e.m(a)` 里，方法体应该在哪个对象上跑？
- Definition: `[Course]` `e` 的结果。方法查找从它的 class 开始，`self` 在方法体里就是它。
- Mental model: 调用不是“函数 + 参数”，而是“对象收到一条消息，参数是其余表达式”。
- Example: `b.m3(5)` 的 receiver 是 `b` 指向的对象，不是 `5`。
- Misunderstanding: receiver 不是 `self` 这个单词的同义词，直到调用开始。调用之前没有当前 self；调用之中 self 就是 receiver。

### self

- Problem: 方法需要指“我自己”，以便再发消息或把自己交出去。
- Definition: `[Course]` 当前正在执行其方法的对象。
- Mental model: 每次方法调用都重新绑定，不是 class 里的一个全局。
- Example: `self.m1`，或省略点的 `m1`；单独的 `self` 是整个对象。
- Misunderstanding: 在 private 方法上写 `self.m` 不合法。`self` 也不是 Java 里可以随便当普通参数传的那个 `this` 的全部故事；特殊之处到 `14` 才讲。

### instance state

- Problem: 同 class 的两个对象必须能记住不同的数据，并且跨方法调用保留。
- Definition: `[Course]` 该对象的实例变量集合。只在它自己的方法里用 `@` 读写。
- Mental model: 对象 = 一块可变的名字到引用的表 + 一个 class。
- Example: `x` 与 `z` 别名，所以共享 `@foo`；`y` 是另一块表。
- Misunderstanding: 实例变量不是 class 定义的一部分。subclass 不会“继承字段声明”，因为没有字段声明。见 `04`。

### encapsulation

- Problem: 客户如果依赖表示，表示就不能改。
- Definition: `[Course]` 实例变量对对象私有；外界只通过方法间接接触。setter 可以不对应同名实例变量（摄氏写入开尔文）。
- Mental model: 对象的接口是消息集合，不是字段布局。
- Example: `attr_accessor` 只是生成方法。
- Misunderstanding: `e.foo = 1` 看起来像赋值，语义是方法调用。封装因此可以在 setter 里做转换。

## 执行跟踪：别名 + initialize

```ruby
class C
  def initialize(f = 0)
    @foo = f
  end
  def m2(x)
    @foo += x
  end
  def foo
    @foo
  end
end

c1 = C.new(7)   # initialize 把 @foo 设为 7；new 的参数传进去
c2 = C.new      # 默认参数，@foo = 0
c1.m2(1)
c2.m2(1)
```

```text
c1 与 c2 不是别名
c1.foo == 8
c2.foo == 1
```

若 `m2` 改的是 `@@bar`，则两次调用累加在同一份 class 变量上。那不是对象私有状态。

Source: Section 8 — Object State / 11:42–13:10。课堂用的是 `@@bar` 与两个 `C` 实例；上面的 `@foo` 例子是同一规则的缩短重建。
