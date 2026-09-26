# 12 — 对象、方法查找与动态派发

> Part C · Section 8
> 视频：`Introduction to Ruby` 到 optional `Dynamic Dispatch Manually in Racket`

Part A 和 Part B 已经占了课程那张 2×2 表里的两格：静态函数式（SML）和动态函数式（Racket）。若第三门语言仍是 Racket 的 class，数字、`nil`、顶层函数会继续是例外，面向对象（Object-Oriented Programming）的规则讲不清。Ruby 被选来填动态、基于类（class-based）、一切皆对象这一格。JavaScript 是面向对象的，但不是 class-based，本课不讲。Racket 有类，承诺没有这么彻底。

OOP 放到最后，不是因为对象更高级。是因为你现在终于能把两套查找规则对打。

ML 的函数在定义时把自由变量关进闭包（Closure）。之后再 shadow `even`，旧的 `odd` 看不见。Ruby 的方法调用不是查词法环境。它先求接收者（receiver），再从接收者**此刻的类**往上走，并把 `self` 绑成这个接收者。子类重写 `even` 之后，父类里写好的 `odd` 会调用新的 `even`，作者不必改 `odd`，也可能被改坏。

动态派发（Dynamic Dispatch）就是这条多出来的规则。它不是“闭包加一点语法”。Grossman 把它称为面向对象里最不像其他语言的那一件事。

这一节也不是 Ruby 教程，不是 Rails，不是字符串库。作业形态换成读一段已经能跑的程序再扩展，是因为那更像工业里的修改，不是因为 Tk 是语言概念。

---

## 1. 若计算不是“发消息”，对象就没有语义

到现在，求值是：表达式变成值，函数调用是在定义时的环境上扩展参数。若一切值都是对象，这条故事必须改写成：

> 每个表达式的结果都是对某个对象的引用。计算是先求出这个对象，再向它发一条消息。发消息和调用它的方法是同一件事。

类（Class）是方法体居住的地方。它决定对象的行为。对象自己先只被允诺一件事：私有状态。状态下一讲才给。没有类，你无法说“这个对象会做什么”。没有 `self`，方法无法谈论“被调用的那一个对象”。

```ruby
class A
  def m1
    34
  end
  def m2(x, y)
    z = 7
    if x > y
      false
    else
      x + y * z
    end
  end
end

a = A.new
a.m1        # 34
a.m2(3, 4)  # 31
```

```text
Expression: a.m2(3, 4)
Evaluation:
  接收者 a → 类为 A 的对象
  参数先求值：x → 3，y → 4
  方法体里 z = 7
  3 > 4 为假
  else：3 + 4 * 7 → 31
Value: 31
```

零个参数时括号可省。他建议多参数总是写括号。调用错的方法或错的元数，是运行时错误，不是类型错误。这格是动态类型，类型不要挡在派发前面。

方法的结果是最后一个表达式。返回 `self` 不是链式调用的原语。它只是一个对象结果，所以还能再发消息：

```ruby
class C
  def m1
    print "hi"
    self
  end
  def m2
    print "bye"
    self
  end
  def m3
    print "\n"
    self
  end
end
```

`c.m1.m2` 能写，是因为 `m1` 的值仍是那个对象。缩进不影响语义。换行可以代替分号。这和某些语言把缩进当语法不同。

局部变量以字母开头，第一次赋值即创建，作用域是**整个方法体**，不是从赋值那一行往下。这和 ML 的 `let` 相反。`z += 3` 是重新绑定：变量里装的永远是对象引用，赋值换的是指向哪一个对象，不是把一个非对象槽写坏。

裸写 `m` 是 `self.m` 的糖，至少对后面会称为 public 的方法是这样。`self` 是正在执行其方法的那个对象。

```ruby
class B
  def m1
    4
  end
  def m3(x)
    x.abs * 2 + self.m1
  end
end
```

`b.m3(5)`：`self` 是 `b`，`5.abs` 是向数字发消息，再 `self.m1` 得到 `4`，结果 `14`。方法属于类，不属于“这门语言”。`a` 若是类 `A` 的实例，`a.m3` 就是 undefined method。数字是对象，所以 `-5.abs` 合法。

**If changed.** 若 `self.m1` 是在调用者环境里按词法查找名为 `m1` 的函数，`B#m3` 就不能稳定地表示“我的 m1”。这是动态派发的种子，规则要到本段末尾才写全。

---

## 2. 状态是对象的，别名因为 mutation 才重要

一个总返回 34 的方法没有记忆。若状态不是每个对象一份、且只有该对象的方法能碰到，那么要么每次调用从头开始，要么任何持有引用的人都能伸进表示。别名（alias）会变成无界的推理负担。Part A 说过：没有 mutation 时，共享与拷贝客户看不出差别。这里 mutation 回来了，所以别名重新成为语义。

实例变量（instance variable）写成 `@foo`。赋值即创建。读一个从未赋值的实例变量得到 `nil`，不是错误。拼错 `@food` 是另一个变量，静默存在。不同实例可以有不同的实例变量集合。合法，通常是差风格。在 `initialize` 里创建它们是约定，不是语言要求。别的语言常常要求先声明字段。Ruby 不要求。

```ruby
class A
  def m1
    @foo = 0
  end
  def m2(x)
    @foo += x
  end
  def foo
    @foo
  end
end

x = A.new
y = A.new
z = x

x.foo     # nil
x.m2(3)   # 错误：nil 没有 +
x.m1
z.foo     # 0
z.m2(17)
x.m2(14)
z.foo     # 31
```

```text
x = A.new     x → 对象 X，尚无 @foo
y = A.new     y → 对象 Y
z = x         z 与 x 是同一引用，不是拷贝

x.m2(3):
  在 X 上读 @foo → nil
  向 nil 发 +
  错误不是“未定义的实例变量”

x.m1 之后：X 的 @foo → 0
z.m2(17)、x.m2(14) 改的是同一个 @foo → 31
y 仍是另一对象，它的 @foo 仍是 nil，直到 y.m1
```

`x = y` 复制引用。`A.new` 造一个不与任何旧对象别名的新对象。`Class.new(args)` 在返回前调用 `initialize`。你几乎不自己调用 `initialize`。默认参数写成 `def initialize(f = 0)`。没有它，每个客户都得记得先 `m1` 再 `m2`。

类变量（class variable）`@@foo` 是每个类一份，该类所有实例共享。不同的类不共享。他称为不特别有用，用来当对照：实例变量不是“类上的那一块”。类常量大写开头，不要改。类外写成 `C::Foo`。类方法 `def self.m` 用类名调用，碰不到实例变量。Java 里相近的名字是 static method。他先说先别把类本身想成对象，下一讲再承认类就是对象。

| | 实例变量 `@` | 类变量 `@@` | 类常量 | 类方法 |
| --- | --- | --- | --- | --- |
| 谁拥有 | 每个对象一份 | 每个类一份，实例共享 | 类上的公开名字 | 不绑在某个实例上 |
| 别名 | 同一对象的两个名字看见同一次更新 | 不同对象也看见同一次更新 | 不要 mutate | `C.m`，不是 `obj.m` |
| 缺了会怎样 | 读到 `nil` | 本讲未把“从未赋值”当例子 | — | undefined method |

**If changed.** 若缺失的实例变量直接报错，`x.foo` 在 `m1` 之前就是错误，不是 `nil`。他标明实际规则令人意外。若 `x = y` 拷贝状态，`z.m2` 不会改变 `x.foo`。Mutation 让引用语义变得可观察。

---

## 3. 可见性是抽象边界，不是访问修饰符清单

若任何持有对象的表达式都能写 `e.@foo`，类就换不了表示。客户会依赖字段，而不是消息。这就是 ML 里 signature 存在的理由：客户看见边界，看不见表示。OOP 需要一条对应的边界。

实例变量总是私有，而且比 Java 的 private-to-the-class 更严：连另一个同类实例也不能读。所以永远是 `@foo`，没有 `e.@foo`。`self.@foo` 不合法，不只是多余。

对外暴露状态，就写方法。约定是 `foo` 和 `foo=`，不是 `get_foo`。`e.foo = expr` 是 `e.foo=(expr)` 的糖。空格无关。这是方法调用，不是对字段的赋值。`attr_reader` / `attr_accessor` 只是在定义这些方法，并不把实例变量变成 public。

公开的名字不必等于存储：

```ruby
def celsius_temp=(x)
  @kelvin_temp = ...   # 换算公式他没有念出来；要点是客户看不见开尔文
end
```

客户依赖的是消息。存储可以是另一套单位。这就是抽象。也是后面 duck typing 的伏笔：你承诺的是能发哪些消息，不是字段布局。

方法可见性作用在随后的定义上，直到下一个关键字：

| | `private` | `protected` | `public` |
| --- | --- | --- | --- |
| 谁能调用 | 同一对象的方法 | 同类或子类的其他实例也可以 | 任何持有该对象的人 |
| 写法 | 只能裸调用 `m`。`self.m` 是语法错误，即使接收者就是自己 | `e.m` 可以，只要可见性允许 | `e.m` 可以 |
| 默认 | 不是 | 不是 | 类开头隐式 public |

Protected 不是“private 加上子类”。它允许别的实例。Private 连显式的 `self.m` 都拒绝。若允许 `self.m`，规则会更符合“同一对象”的直觉。Ruby 拒绝这个语法。

---

## 4. 有理数：同一不变量，换一种打包

Section 4 的有理数 signature 藏起 `num` / `den`，并维持约分、分母为正。OOP 里不能写 `r.@num`。类必须暴露方法。可见性要紧到客户破坏不了不变量，又要松到 `add!` 能读另一个同类实例。

Protected 正好卡在这个缝里。Public 则客户可以在 `initialize` 之后把分母弄成 0。Private 则 `add!` 读不到另一个实例。

```ruby
class MyRational
  def initialize(num, den = 1)
    if den == 0
      raise "denominator is zero"
    elsif den < 0
      @num = -num
      @den = -den
    else
      @num = num
      @den = den
    end
    reduce
  end

  def to_s
    ans = @num.to_s
    if @den != 1
      ans = ans + "/" + @den.to_s
    end
    ans
  end

  def add!(r)
    a = r.num
    b = r.den
    @num = a * @den + b * @num
    @den = b * @den
    reduce
    self
  end

  def +(r)
    ans = MyRational.new(@num, @den)
    ans.add!(r)
    ans
  end

  protected
  def num
    @num
  end
  def den
    @den
  end

  private
  def reduce
    g = gcd(@num.abs, @den)
    @num /= g
    @den /= g
  end
  def gcd(x, y)
    # 与 ML 版本同一逻辑：递归求最大公因子。函数体他没有逐行念。
    # 调用必须写成 gcd，不能写成 self.gcd。
  end
end
```

`raise` 的字符串原文没有被念出，上面的字符串只说明“分母为 0 是错误”。`gcd` 的体同样没有逐行给出。不要把它们当成幻灯片原文。

不变量：约分（`3/2` 不是 `9/6`）；分母为正；分子可以为负。`+` 先拷贝再 `add!`，所以 `r1 + r1` 不改 `r1`。若 `+` 就地修改，第二次加法会看见一个已经被改过的左操作数。`add!` 的叹号是“我会修改接收者”的约定，不是语言规则。返回 `self` 才能 `add!(...).add!(...)`。那仍是上一讲的普通返回值。

`r1 + r1` 是 `r1.+(r1)` 的糖。定义 `def +` 不是 C++ 那种重载一个内建运算符。`+` 本来就是方法。顶层 `def use_rationals` 也不是“对象系统之外”。它被加进类 `Object`。下一讲解释为什么因此每个对象都有它。

| | ML 有理数结构 | `MyRational` |
| --- | --- | --- |
| 操作住在哪 | 值外面的函数 | 分数上的方法 |
| 边界 | signature 藏起 pair | `@num` / `@den` 永远私有；同类用 protected getter |
| 加法 | 返回新值 | `+` 返回新对象；`add!` 修改接收者 |

---

## 5. 一切皆对象，类定义在运行中还能变

若数字、`nil`、类、顶层过程是例外，那么“调用方法”就不是求值规则，只是特殊情况。更小的语言是：表达式结果都是对象，代码都是某个类的方法。代价是要解释“方法找不到”和“顶层定义算谁的”。

几乎一切都是方法调用。`3 + 4` 就是 `3.+(4)`。找不到方法时，实现改去调用 `method_missing`。`Object` 上的默认版本打印 undefined method。查找失败本身仍是一次方法调用。

`nil` 是一个对象，不是“没有值”。它和 Java / C / C++ / C# 的 null 不是一回事，那些常常不是你能发消息的对象。他把它和 ML 的 `unit` 放在一起只是松散对照：`unit` 是有一个居民的值，不是“缺失”，也不是条件里的假。`nil` 有方法，包括 `nil?`。`nil?` 只对 `nil` 为真，对 `""` 不为真。条件里只有 `false` 和 `nil` 为假。空字符串为真。

顶层方法被加进 `Object`。你定义的类的超类链最终包含 `Object`，除非同名方法被替换。所以顶层方法是每个对象的方法。这是“所有代码都是某个类的方法”得以成立的办法。

类本身是对象。`3.class` 在他运行的版本里是 `Fixnum`。`3.class.class` 是 `Class`。`Class.class` 还是 `Class`。他称为通往疯狂的路：用来在 REPL 里探索，不要在这上面建理论。反射（reflection）——运行时询问程序自身的方法，如 `methods`、`class`——他避免写进程序。REPL 里用它们弄清“我能发什么消息”，然后去读文档。往往有不靠反射的更好设计。

类若在编译后就冻住，“对象的行为是它的类”就是一个静态事实。Ruby 允许类对象在实例已经存在时继续变。方便：可以给 `Fixnum` 加上 `double`。敌视分析：任何代码都能打破任何抽象。把 `Fixnum` 的 `+` 改掉，用 Ruby 写成的 irb 自己会坏。他不喜欢这个特性。

```ruby
class MyRational
  def double
    self + self
  end
end
```

重开 `class MyRational` 不是子类化。是同一个类对象上多一个方法。查找用的是**调用时**的类，不是 `new` 那一刻的类。先造出的 `x` 在 `double` 被加上之后也能调用。若查找在 `new` 时冻住，旧对象会永远没有 `double`。只有类可变，语言才必须回答这个问题。更少动态的语言不必处理类的 mutation，实现可以更简单或更快。

顶层再 `def m` 是在替换 `Object#m`。于是 `nil`、`56` 和顶层都看见新方法。给数字类加方法，看起来像它一直都在。那是脚本方便，不是他对大程序的建议。

**If changed.** 没有 `method_missing`，找不到方法就是原语错误，程序插不进钩子。默认行为仍是那个错误。若顶层方法不在 `Object` 上，“一切代码都是方法”为假。

---

## 6. Duck typing：是不是鸭子，不重要

动态语言的检查器不会拒绝“这不是一个 `Point`”。剩下的问题是方法可以假设什么。若它假设类，它会拒绝能完成工作的对象。若它只假设自己发出的消息，实现就是文档，局部改写不再是等价。

名字来自“走起来像鸭子、叫起来像鸭子，那就是鸭子”。他要的更尖锐版本是：它是不是鸭子，无关。

```ruby
def mirror_update(point)
  point.x = point.x * -1
end

def double(x)
  x + x
end
```

`mirror_update` 的实际契约不是“接收一个 Point”。也不是“有 `@x` 的 getter/setter”。它只发送 `x`，把结果再发送 `*` 且参数为 `-1`，再把那个结果发送给 `x=`。`x=` 是否更新字段是风格约定。一个名叫 `x=` 却不更新的方法是差风格，但没有东西阻止它。他判断：这样不加限制的 duck typing 常常是差风格。你也许想要非 `Point` 的对象，但不是任意刚好有 `x` 和 `x=` 的东西。

`double` 是他认可的例子。数字、字符串（拼接）、定义了 `+` 的 `MyRational` 都能用。把体改成 `x * 2`，数字仍工作，字符串和有理数未必。在 Ruby 里对数字，`x + x` 与 `x * 2` 等价。在 duck typing 下它们不是同一份契约。

这和 Section 4 的等价直接冲突。那里假设你能看见完整契约，并且没有客户观察得到的副作用。这里契约就是方法体发出的那一串消息。调用者可以依赖精确的消息序列。于是你几乎没有隐藏任何东西。两个表达式几乎不能再互相替换。“更 OOP”（只谈消息）会和抽象（客户不该看见你发了哪些内部消息）打架。他不是一边倒。`double` 可以。不受限的 `mirror_update` 不行。

`is_a?` / `instance_of?` 存在。拥抱 duck typing 意味着不用它们来分支。

| | 类测试 | Duck typing |
| --- | --- | --- |
| 问什么 | 你是不是 `Foo`？ | 我能不能发这些消息？ |
| 对一个走起来像的对象 | 拒绝 | 接受 |
| 对等价 | 可以依赖 `Foo` 的表示不变量 | 毁掉“换一串消息仍一样” |
| 文档 | 类名 | 消息序列；否则等于没有文档 |

---

## 7. 数组是可变对象；块几乎是闭包，但不是一等的

没有一种灵活的集合，每个脚本都要重造元组、列表、栈、队列。Ruby 的答案是一个类 `Array`，几乎没有操作算错误。相对 ML 的 list 或 Java 的数组：方便、长度可变、错误发现更差、渐近行为常常更差。小程序里他接受这个交换。

`a[i]` 和 `a[i] = e` 都是方法发送。越界读是 `nil`，不是异常。负数下标从末尾数，`a[-1]` 是最后一个。越界写会把数组撑大，空洞填 `nil`。元素可以异构。没有单独的 tuple 类型。`+` 拼接并返回**新**数组，不修改接收者。`d = a` 是别名。`e = a + []` 是内容相同的新数组。改 `a[0]`，`d` 看见，`e` 看不见。这是 Part A 的别名故事，因为数组可变才再次成为问题。

栈是 `push` / `pop`，队列是 `push` / `shift`。那是库的契约，不是新的语言形式。

高阶模式需要“传一段以后执行的代码”。ML / Racket 的闭包是表达式，可以出现在任何值的位置。Ruby 把最常见的那一种写成特殊语法：一次调用旁边最多一个块（block），不在参数列表里。

```ruby
i = 7
[4, 6, 8].each { |x| print (x + 1) if i > x }
# 打印 5 和 7；8 被跳过，因为 7 > 8 为假
```

自由变量 `i` 在块**写下**的地方解析，不在 `Array#each` 的方法体里解析。这是词法作用域（Lexical Scope）。若块用动态作用域，它会看见 `each` 内部的 `i`，而不是 `7`。

`map` 与 `collect` 是同一方法的两个名字，造新数组。`select` 是他称为 filter 的那个；没有 `filter` 这个方法。`inject` 是 fold。`any?` / `all?` 短路。不带块的 `all?` 问的是每个元素是否为真值，不是“是不是布尔值 `true`”。只有 `false` 和 `nil` 失败。

库如此依赖块，以至于显式循环存在但很少用。`each` 不是 `for` 的语法。它是一个方法，对每个元素 yield 一次。

被调用方不给块一个名字。用关键字 `yield` 调用它。这和 ML / Racket 的函数参数都不一样。

```ruby
class Foo
  def initialize(max)
    @max = max
  end
  def count(base)
    if base > @max
      raise "count past max"
    elsif yield(base)
      1
    else
      1 + count(base + 1) { |i| yield(i) }
    end
  end
end

f = Foo.new(1000)
f.count(10) { |x| x == 34 }
# 从 10 yield 到 34，返回 25
```

`raise` 的字符串原文没有被念出。递归调用**不会**自动带上原来的块。块没有名字，所以必须再包一层 `{ |i| yield(i) }`。Part A 里这种包装通常是多余的。这里是必要的，因为第二类的东西传不走。`yield` 在这里是“调用那一块”，不是他没有在教的生成器返回。缺块时 `yield` 报错。块的元数对不上，不像方法元数那样硬失败。他没有给出精确的填参规则。

块不是表达式。不能作为计算结果，不能返回，不能放进数组。回调和“函数的数组”需要一等值。Ruby 另有一个名字：

```ruby
a = [3, 5, 7, 9]
c = a.map { |x| lambda { |y| x >= y } }
c[0].class    # Proc
```

`lambda` 是 `Object` 的方法，不是 Racket 那种保留形式。它接收一个块，返回类 `Proc` 的对象。用 `call` 调用。每个 proc 的环境里，`x` 是 `map` 建造它时传入的那个元素。这个绑定在 `map` 返回后仍然活着。这才是闭包。块无处可存，就做不成这件事。他给出的下标与“第二个位置是 8”在口述里对不齐，不要把某一个 `c[1].call(7)` 的真假当成幻灯片事实。他确实说的是：对 `5` 有三个 proc 为真，对 `50` 为零个。那一部分不依赖那个下标。

| | Block | Proc |
| --- | --- | --- |
| 是什么 | 调用旁边的特殊语法，不是表达式 | `lambda` 返回的对象 |
| 等次 | 二等（second-class）：不能当计算结果 | 一等（first-class）：可返回、存储、放进数组 |
| 如何调用 | 只有 `yield` | `.call` |
| 作用域 | 词法 | 词法，并且环境被打包带走 |
| 个数 | 每次调用 0 或 1 | 普通对象，想要几个要几个 |

匿名和一等是两件事。一等意味着能成为计算的结果，不是“可以不写名字”。块可以没有名字，仍然不是一等的。“几乎一切皆对象”在这里有一个例外：块不是对象。

设计交换他要你记住：常见情况（给 `map` 传一块）更方便，不常见情况（回调、函数表）要另学 `Proc`。多数语言只有一等闭包，再尽量把那种语法做便宜。什么时候值得为常见情况付“两套构造”的代价，是语言设计问题，不是 Ruby 语法 trivia。

哈希（Hash）和范围（Range）的语言点不是花括号。`count` / `each` / `inject` 是消息。一个只发送 `count` 的方法对数组和范围都工作。数组知道怎么按下标走，范围知道怎么从下界走到上界而不存下每个整数，`foo` 只知道要计算什么。这是 ML 里“迭代器与计算分开”的同一分离，穿上了 OOP 的衣服。不需要子类关系。

```ruby
def foo(a)
  a.count { |x| x * x < 50 }
end
foo([3, 5, 7, 9])   # 3
foo(3..9)           # 5
```

若 `foo` 测试 `instance_of?(Array)`，范围那个调用会失败。这是他认可的 duck typing，和不受限的 `mirror_update` 不同。哈希的 `each` 交出键和值，不是元素。同名不等于同一契约。缺键是 `nil`。范围存的是两个端点。`(1..1_000_000)` 不是一百万格的数组。`to_a` 才是。

---

## 8. 子类化是方法集合的事，不是类型系统的事

`ColorPoint` 需要 `Point` 的每个方法，再加颜色。复制粘贴是他还没拒绝的那条退路。子类化（subclassing）：类有一个超类；它拥有超类的方法，除非同名覆盖（overriding），再加上自己的方法。动态语言里这只关于哪些方法存在。没有类型系统，所以这还不是子类型（subtyping）。子类型是 Section 10 的题目。

```ruby
class Point
  attr_accessor :x, :y
  def initialize(x, y)
    @x = x
    @y = y
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
  def initialize(x, y, c)
    super(x, y)
    @color = c
  end
end
```

省略超类意味着 `< Object`。实例变量不是类定义的一部分。子类化不声明、不继承、也不删除字段。对象开始时没有实例变量，赋值才创建。`super` 调用超类的同名方法。写成 `initialize(x, y)` 会递归到自己。

`distFromOrigin2` 现在看起来只是多绕了四次方法调用。它被种在这里，是为了让后面的极坐标点不必复制这个公式。

`is_a?(Point)` 对子类实例为真。`instance_of?(Point)` 只对精确的类为真。Java 的 `instanceof` 像 Ruby 的 `is_a?`，不像 `instance_of?`。同一对词，在两门语言里几乎相反。用它们来分支，就是放弃 duck typing。风格上，若你问，通常该问 `is_a?`：子类实例应该能当作超类实例用。那是反射版本的承诺。动态派发是语义版本。

链他演示过：`ColorPoint` → `Point` → `Object` → `BasicObject` → `nil`。`nil` 没有 `superclass`。`Object` 不是根。

机制一旦存在就会被用滥。大的 OOP 程序里子类往往比应该有的多。你真正想要的复用可能是：改原来的类、复制一份、藏起一个部件，或真的“是一种”。

| | 子类 | 重开 `Point` 加上 color | 复制方法 | 内嵌一个 `Point` 再转发 |
| --- | --- | --- | --- | --- |
| 复用 | 有 | 只有一个类，所有点都变了 | 没有，会漂移 | 有，但是手工转发 |
| `is_a?(Point)` | 真 | 它就是 `Point` | 假 | 假 |
| 模块性 | `Point` 不必被你拥有 | 差：别人的不变量可能被你打破 | 隔离 | 表示是隐藏的 has-a |
| 对本例 | 意图就是“除了颜色和 initialize，就是点” | 通常不该改别人的类 | 差 | 他称为对本例更差，对很多真实 has-a 却是该写的 |

重开类之所以容易，是因为类定义是动态的。静态类型语言里，若调用点要求 `ColorPoint` 能放进 `Point` 的位置，内嵌那一版过不了类型检查。他称那在 Java 一类语言里是更大的事。在 Ruby 里，若调用者使用 `is_a?`，或者你想免费得到继承来的行为，它仍然重要。组合（composition）不是“没学会继承”。对 `ColorPoint` 它更差。对很多真实情况，人们出于懒或含糊去子类化，其实该内嵌。

`ThreeDPoint < Point` 教学上有用，风格上可争论。他不裁决：它不是二维点；或者它是 xy 平面上的投影；但覆盖后的 `distFromOrigin` 返回的不是投影距离，是三维距离。可以争一天。即使是差风格，它也把方法集合逼得显式：继承 `x`、`x=`、`y`、`y=`；覆盖 `initialize` 和两个距离；新增 `z`、`z=`。`super` 让覆盖复用二维结果，而不是整段替换。不覆盖的话，继承来的方法返回的是二维距离。

---

## 9. 动态派发：继承来的方法看见的是整个接收者

到这里，覆盖看起来像“换掉一个方法，继承其余的”。那接近一个有多个入口、而不是只有一个 `call` 的闭包。这个图景不完整。

继承来的方法可以调用 `self.m`。`self` 可能是子类实例，而 `m` 已被覆盖。于是超类的代码跑到了它没有点名的子类代码。没有这一点，`PolarPoint` 即使“把 getter 平方再开方”这个公式仍然正确，也必须复制 `distFromOrigin2`。

这是面向对象相对非对象语言做得不一样的那件事。

`PolarPoint` 换了表示：`@r` 与 `@theta`，没有 `@x`、`@y`。在超类声明了字段、因而每个实例都有那些字段的语言里，这不合法。Ruby 的字段在赋值时才出现，所以表示差可以被说得很锐。不要把这张图出口到 Java。Setter 用三角把直角坐标换回 `r` 和 `theta`。公式不是考点，口述也没有给出可逐字抄的式子。Getter 才是派发例子需要的部分。

```ruby
class PolarPoint < Point
  def initialize(r, theta)
    @r = r
    @theta = theta
  end
  def x
    @r * Math.cos(@theta)
  end
  def y
    @r * Math.sin(@theta)
  end
  def distFromOrigin
    @r
  end
  # distFromOrigin2 不覆盖
end

pp = PolarPoint.new(4, Math::PI / 4)
pp.distFromOrigin     # 4
pp.distFromOrigin2    # 4.0
```

`distFromOrigin` 必须覆盖。继承版本读 `@x` / `@y`，它们从未赋值，是 `nil`，`nil * nil` 出错。`distFromOrigin2` 为了这个演示不必覆盖。它调用的是 `self.x` 和 `self.y`。

```text
对象 pp
  class: PolarPoint
  @r → 4
  @theta → π/4
  没有 @x，没有 @y

Expression: pp.distFromOrigin2

1. 接收者 pp，类是 PolarPoint
2. PolarPoint 没有定义 distFromOrigin2
3. Point 定义了 → 用那个方法体
4. self 绑成 pp，不是绑成一个 Point
5. 方法体里 self.x：
     从 PolarPoint 重新开始查找
     PolarPoint 定义了 x → @r * cos(@theta) ≈ 2.82
6. self.y 同样 ≈ 2.82
7. sqrt(平方和) → 4.0

Expression: pp.distFromOrigin
  PolarPoint 自己定义了它 → 直接返回 @r → 4
  不调用 self.x
```

`x` 在 `Point#distFromOrigin2` 的体里不是 ML 词法环境里的变量。它是一次方法调用。相关的“环境”是 `self`。

**If changed.** 若 `distFromOrigin2` 读的是 `@x` 和 `@y`，`PolarPoint` 会出错或得到垃圾，除非也覆盖那个方法。派发发生，只因为那是对 `self` 的方法调用。若第 5 步把 `self` 绑成“定义该方法的那个类的实例”，`Point#distFromOrigin2` 会去调 `Point#x`，在错误的对象上读缺失的 `@x`。派发消失。继承来的方法会像函数一样被关上。

| | `distFromOrigin` | `distFromOrigin2` |
| --- | --- | --- |
| 体在做什么 | 读字段 | 对 `self` 调用 getter |
| 对 `PolarPoint` | 不覆盖就错 | 不覆盖也对 |
| 是不是钩子 | 不是 | 是，无论你有没有打算留钩子 |

---

## 10. 方法查找规则：和变量查找一样，必须写出来

“它会调用子类版本”不是语义。ML 的变量查找有环境规则。方法查找需要同样种类的定义。查找规则常常是一门语言最重要的语义。不同种类的名字可以有不同的查找规则。ML 的记录字段不是变量。Racket 有好几种 `let`。Ruby 的局部变量大致像 ML / Racket 的变量，作用域细节不同。实例变量、类变量、方法都不是变量。它们通过 `self` 查找。

动态派发、后期绑定（late binding）、虚方法（virtual method）是同一个想法的三个名字。C++ 里它取决于方法的种类，但机制在。多数 OOP 语言里，它是所有方法调用的默认。

方法运行时，总有某个对象绑在 `self` 上。

- `@x`：在 `self` 那个对象里查找，像记录字段。找到就返回。没有就是 `nil`。
- `@@x`：在 `self` 的类里查找。所以实例共享它。
- `e0.m(e1, ..., en)`，参数 eager：

```text
1. 先把 n+1 个子表达式都求成对象 obj0 … objn。
   这些求值自己会完成其中的调用。obj0 是接收者。
2. c = obj0 的类。
3. 若 c 定义了 m，用那个体。
   否则试超类，再超类，经 Object 直到 BasicObject。
   第一个定义赢。
4. 都没有，则用同样的搜索去调用 method_missing。
   Object 定义了它：报错，没有这个方法。
5. 在一个环境里求值选中的体：
   形参绑到 obj1 … objn，
   self 绑到 obj0。
```

第 5 步是动态派发的全部实现。`m` 体里再调用 `m2`，从 `obj0` 的类开始找，不是从定义 `m` 的那个类开始找。所以子类对 `m2` 的覆盖会被看见，即使 `m` 是继承来的。

这比闭包应用的规则长。情况更多，而且 `self` 不是词法环境里的普通变量。他说这是事实陈述，不是意见。更复杂不等于更差，也不等于更好。若 OOP 是你的第一门语言，它会觉得更简单，因为你用得更久。ML / Racket 的函数调用没有把 `self` 特殊化。

静态语言的附加机制不要和这件事混在一起。Java / C# 的方法查找也走接收者的类。额外的复杂是静态重载（overloading）：一个类可以有多个同名方法，元数或参数类型不同。只有参数类型匹配时才算覆盖。否则你是加了一个重载，或继承了一些、又定义了另一些。“最佳”方法打成平局就是类型错误。那些规则用的是类型检查器看见的参数类型，在 Ruby 里没有意义。Ruby 里同名就是覆盖，总是。Ruby 和 Java 都有动态派发。只有静态类型的那些语言有这第二套机制。

| | 变量查找 | 方法查找 |
| --- | --- | --- |
| 去哪找 | 词法环境 | 接收者的类，再沿超类走 |
| 闭包 / 方法体捕获了什么 | 定义时的环境 | 不捕获“定义它的那个类”作为调用目标 |
| 后来的同名 | shadowing 遮住绑定 | overriding 只对子类的接收者替换方法 |

| | 动态派发 | 静态重载（Java / C# / C++） |
| --- | --- | --- |
| 何时决定 | 调用时，看接收者的类 | 编译时，看参数类型 |
| Ruby | 有 | 表达不了 |
| 一个类里同名方法 | 一个名字就是覆盖 | 可以有多个 |

---

## 11. 闭包是关上的，派发是打开的

词法闭包在建造之后是关上的。`odd` 造好以后，再 shadow `even`，不改变 `odd` 调用谁。若新的 `even` 是错的，这是好事。若新的 `even` 是作者本来会想要的更快的正确算法，这是坏事。动态派发做相反的交换：子类可以不复制代码就改变继承方法的行为，包括原作者没预料的方式，包括改坏它的方式。若方法调用了可能被覆盖的方法，你不能只读它的体就推理它的行为。

“闭包和对象根本不同。差别就是动态派发。”

```sml
fun even x =
    (print "in even";
     if x = 0 then true else odd (x - 1))
and odd x =
    (print "in odd";
     if x = 0 then false else even (x - 1))

val a1 = odd 7
(* 八行 in odd / in even；结果 true *)

fun even x = (x mod 2) = 0
val a2 = odd 7
(* 同样的打印，同样的 true：闭包仍调用第一个 even *)

fun even x = false
val a3 = odd 7
(* 仍然 true *)
```

```text
odd 的闭包
  code: 若 x = 0 则 false，否则 even (x - 1)
  environment:
    even → 第一个 even（和 odd 互相递归的那一个）
    odd  → 它自己

后来的 fun even 是文件后续环境里的新绑定。
闭包不查那个环境。词法作用域。

调用链：odd 7 → even 6 → odd 5 → even 4 → odd 3 → even 2 → odd 1 → even 0
八次打印。even 0 为 true，所以 odd 1 为 true，所以 odd 7 为 true。
```

`and` 是为了让两个函数处在同一个环境里。两个先后的 `fun` 不会把第一个 `even` 关到第二个 `odd` 上。Ruby 的方法不需要 `and`：两者都在调用时到 `self` 上查找，类里的定义顺序不会把一个关到另一个上。

```ruby
class A
  def even(x)
    puts "in even"
    if x == 0 then true else self.odd(x - 1) end
  end
  def odd(x)
    puts "in odd"
    if x == 0 then false else self.even(x - 1) end
  end
end

class B < A
  def even(x)
    x % 2 == 0
  end
end

class C < A
  def even(x)
    false
  end
end
```

```text
a2 = B.new
a2.odd(7)

接收者的类是 B
odd 在 B 里没有，在 A 里有 → 跑 A#odd
self 仍是那个 B 实例
self.even(6) 从 B 开始找 → B#even
  6 % 2 == 0 → true
A#even 不跑
只打印一次 "in odd"

a3 = C.new
同一条查找。C#even 返回 false。
odd 没有把 A#even 关进去。答案是错的，机制是同一个。
```

若改成词法，`B` 的 `odd` 仍会调用 `A#even`，打八行，忽略更快的方法。那就是 ML 文件里的 `a2`。

正确的覆盖和破坏性的覆盖是同一机制。意图不在语义里。好处：子类改行为，不必复制代码，也不必编辑库。脆性：这取决于 `odd` 真的调用了 `even`。有人改写 `odd`，钩子就消失。是复用还是滥用，看情形。

要孤立地推理，就不要调用可覆盖的方法，或禁止覆盖。他指向两个封条，它们不是同一条规则：Ruby 的 `private`（只能裸调用，同一对象；他把它说成子类也不能拿来用的封条），以及 Java 的 `final`（不能覆盖）。有人争论这不够 OOP。它让局部推理更容易，在某些方面更模块化。概念类比，不是等价。

“对象就是有很多方法的闭包”在没有 `self` 调用的三维点上差不多。这一讲是反例。动态派发也不是“词法作用域加上对环境的 mutation”。ML 的环境没有被更新。Ruby 的查找从来不用那个环境。

| | 词法闭包（`odd` / `even`） | 动态派发（`A#odd` / `B#even`） |
| --- | --- | --- |
| 何时决定被调用者 | 定义时关上 | 每次 `self.m` 打开 |
| 后来的同名 | shadowing 不改变旧闭包 | overriding 改变继承来的调用者 |
| 局部推理 | 读闭包和它的环境就够 | 行为包含可覆盖的调用 |
| 更好的 `even` | 不会让旧 `odd` 变快 | 不必改 `A` 就让 `odd` 变快 |
| 错误的后来者 | 破坏不了旧 `odd` | 可以破坏 `odd` |

---

## 12. 用 Racket 把派发写成数据，它就不再是关键字魔法

可选。作业和考试不需要。若动态派发只是 Ruby 的关键字行为，它仍然是魔法。在默认不给派发的 Racket 里编码一次（Racket 有类，他不用），能看见：这套语义可以用 struct、列表和 lambda 实现，也能看见类型系统在哪里帮你、在哪里挡住一种风格。方向与以前“用 Java / C 模拟闭包”相反。

这个编码里没有类。派发不需要类。Ruby 是 class-based；这是更小的模型。对象是一个 struct，两张表：字段和方法。字段是可变对 `(mcons name value)`，这样 `set` 能 `set-mcdr!`。方法是不可变对：名字，和一个多接收一个参数的 Racket 函数。`send` 把整个对象作为那个参数传进去。参数名叫 `self` 只是提醒。它是普通变量。叫 `s` 也行。不是 Racket 的关键字。

列表比向量或哈希慢。选它是为了让查找可见。找不到字段他选择报错，不是 Ruby 的 `nil`。

```racket
(struct object (fields methods))

(define (send obj msg . args)
  (let ([pr (assoc msg (object-methods obj))])
    (if pr
        (apply (cdr pr) obj args)   ; obj 就是 self
        (error "method not found"))))
```

`assoc-m` 是他自己写的、对可变对工作的查找。标准库里他没有找到现成的。名字和体都不要当成逐字幻灯片。`send` 的这一行是第 17 讲那条蓝色规则：先找到函数，再把对象当作第一个参数。

`make-point` 的 `distToOrigin` 不读字段，它 `(send self 'get-x)`。因此换一张方法表就能换 getter。覆盖就是把替换的对放在列表前面。`assoc` 返回第一个匹配。子类化在这个编码里不是类对象：造一个 point，把你的字段和覆盖方法接到它的表的前面。效果与“子类优先”相同。接到尾巴上，`assoc` 会一直命中 `Point` 的 `get-x`。顺序就是编码。

```text
pp 的 methods 表（前部是极坐标的覆盖）：
  get-x → λ(self) . r * cos(theta)     ← assoc 先命中
  get-y → λ(self) . r * sin(theta)
  ...Point 的 get-x、get-y、distToOrigin 仍在后面

(send pp 'distToOrigin)
  assoc 找到 Point 的 lambda（没有被覆盖）
  调用它，self = pp
  (send pp 'get-x) 再 assoc，命中前面的极坐标 get-x
  那就是动态派发
```

他在相机前跳过了 color-point 构造器。`set-x` 的极坐标版本同样是覆盖，公式不是这一讲的点。

若 `send` 调用 lambda 时不把对象传进去，`distToOrigin` 就没有 `self`，覆盖 `get-x` 影响不了它。那就是把 getter 词法地关上，即第 18 讲的 ML 行为。

ML 会和这种写法打架。没有子类型，polar-point 不容易被传到假定 point 的函数那里，`distToOrigin` 那个 lambda 的类型也别扭。变通存在：一个巨大的 datatype 装下所有对象。他提到并拒绝。要点是摩擦，不是不可能。“ML 做不到”说过了。他说的是：这门课用的那一片 ML 类型系统对它不友好。OCaml、F#、Scala 把对象做成语言特性，而不是在这片 ML 里编码。Java 在泛型之前对 ML 的风格同样不友好：参数多态、闭包。类型系统可以在很好地支持一种风格的同时，把你锁在那种风格里。

| | Ruby | 这个 Racket 编码 |
| --- | --- | --- |
| 方法住在哪 | 类上，实例共享类 | 每个对象自己的方法表 |
| 覆盖 | 在子类里定义 | 接到表前；`assoc` 取第一个 |
| 缺字段 | `nil` | 他选择报错 |
| `self` | 关键字 | `send` 填进去的参数 |

这不是 Racket 希望你写 OOP 的方式。编码是定义，不是惯用法。类不是解释动态派发所必需的。Ruby 的基于类的故事，是加在“查找从接收者开始”之上的一种设计。

---

## 对照

### Binding vs Mutation

| | Binding（`x = y`） | Mutation（`@foo =`、`foo=`、数组槽） |
| --- | --- | --- |
| 定义 | 变量改指向另一个对象 | 对象的内容变了 |
| 解决的问题 | 局部名字、把结果存下来 | 同一块状态在多次调用之间活着 |
| 关键区别 | 不改变对象。另一个名字是否看见变化，取决于它是不是同一引用 | 所有 alias 都看见 |
| 典型场景 | `z = x` 之后两边是同一对象；再 `z = A.new` 就不是了 | `z.m2` 改变 `x.foo`；`d[0] = 6` 改变 `a[0]` |

### Shadowing vs Overriding

| | Shadowing（ML 里后来的 `fun even`） | Overriding（`B#even`） |
| --- | --- | --- |
| 定义 | 后一个词法环境里的新绑定遮住名字 | 子类方法替换超类同名方法，对子类接收者生效 |
| 解决的问题 | 局部名字不必改旧计算 | 不复制调用者就改变继承来的行为 |
| 关键区别 | 旧闭包不查新环境 | 继承来的 `self.m` 每次重新查找 |
| 典型场景 | `odd 7` 在两次 `fun even` 之后仍调用第一个 `even` | `B.new.odd(7)` 调用 `B#even`，只打印一次 |

### Function call vs Method call

| | 函数调用 | 方法调用 |
| --- | --- | --- |
| 定义 | 求函数值，求参数，在定义时环境加参数后求体 | 求接收者和参数，沿接收者的类找方法，`self` 绑成接收者 |
| 解决的问题 | 词法上可局部理解的计算 | 行为随接收者的类变化 |
| 关键区别 | 规则更短，没有特殊的 `self` | 规则更长。更长不是优劣判断 |
| 典型场景 | `odd` 里的 `even` | `A#odd` 里的 `self.even` |

### Block vs Closure

| | Block | ML / Racket 闭包，以及 Ruby 的 Proc |
| --- | --- | --- |
| 定义 | 调用旁边最多一块，词法，二等 | 一等函数值，词法环境被打包 |
| 解决的问题 | 让 `map` / `each` 的常见情况短 | 回调、返回函数、放进数据结构 |
| 关键区别 | 没有名字，递归必须再包一层 `yield` | 可以 `call`、存储、返回 |
| 典型场景 | `each { \|x\| ... }` | `lambda { \|y\| x >= y }` 放进数组后仍然记得 `x` |

---

## Connection to Modern Languages

这些是概念类比，不是等价。

- Java / C# 的实例方法默认按接收者的运行时类派发。这和 Ruby 的查找是同一想法。它们另外还有重载，Ruby 没有。不要把“我在子类里又写了一个 `m`”自动读成覆盖。
- C++ 的 virtual 才是动态派发。非 virtual 方法更接近“在静态类型对应的类里定死”，不是 Ruby 的默认。
- Java 的 `final` 禁止覆盖，用来换回局部推理。它不是 Ruby 的 `private`。`private` 限制的是谁能用显式接收者调用。
- Java 的 `instanceof` 对应 Ruby 的 `is_a?`，不是 `instance_of?`。
- Python 的方法调用同样从实例的类找起，子类覆盖会影响父类方法里的 `self.m()`。类体在运行时也是可改的，程度和 Ruby 不同，不要说成同一个特征。
- JavaScript 是面向对象的，但是原型，不是 class-based。本课故意不讲。不要用本节的超类链去套它。
- Rust 的 trait 方法分派可以是静态的，也可以通过 trait object 在运行时选实现。那是另一套“接收者决定实现”的设计，不是 Ruby 的类链，也没有 `self` 这条关键字规则。
- 用闭包记录加几个 lambda 模拟对象，就是第 19 讲的方向，也是 Section 3 用闭包做抽象数据类型的方向。缺的那一块恰好是：继承来的函数是否在每次调用时重新向接收者查找。没有那个参数，你得到的是关上的闭包，不是派发。

---

## Section 8 Review

这一节把课程的第三格填上：动态类型、基于类、一切皆对象。对象是状态加方法。方法调用不是词法查找。它求接收者，沿类链找方法，把 `self` 绑成接收者。因此继承来的代码可以跑到子类覆盖的方法上。这是相对闭包的真正差别，也是 OOP 放到函数式之后才讲的原因。块几乎是闭包，但是二等的；`Proc` 才是一等闭包。Duck typing 用消息代替类测试，同时毁掉很多等价。子类化是一种复用，不是唯一的复用。

### 核心概念

class、object、message、`self`、instance variable、alias、visibility、duck typing、block、`Proc`、subclassing、overriding、`super`、dynamic dispatch、method lookup、`method_missing`。

### 不变量

```text
表达式的结果是对象引用。调用方法 = 发消息。
x = y 复制引用。mutation 才让别名可观察。
@ 字段永远不能写成 e.@foo。e.foo = e 是方法调用。
裸 m 与 self.m 对 public 同义；private 拒绝 self.m。
块是词法的、二等的。Proc 是一等闭包。
子类化不复制字段定义。Ruby 的字段在赋值时出现。
方法查找：接收者的类，然后超类。第一个定义赢。
self 绑的是接收者，不是“定义这个方法的类的一个实例”。
覆盖改变继承来的 self.m。Shadowing 不改变旧闭包。
同名在 Ruby 里就是覆盖。重载是别的语言的第二套规则。
```

### 能力检查

- 画出 `x`、`y`、`z` 三个名字和两个对象，说明哪一次 `m2` 改的是同一块 `@foo`。
- 说明 `protected` 为什么恰好是 `MyRational#add!` 需要的可见性，public 和 private 各破坏什么。
- 给 `pp.distFromOrigin2` 写出查找的五步，并说明为什么 `distFromOrigin` 必须覆盖而 `distFromOrigin2` 不必。
- 解释 ML 的第二次 `fun even` 为什么不改变 `odd 7`，而 `B#even` 为什么改变 `A#odd`。
- 说出块和 `Proc` 哪一个能放进数组，以及递归传递块时为什么必须再包一层。
- 说出 duck typing 毁掉了哪一种 Section 4 的等价，以及什么时候他仍然认为它是对的复用。

练习：`exercises/section-08.md`。
