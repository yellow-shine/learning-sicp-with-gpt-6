# 13 — 同一张表，两种切法

> Part C · Section 9
> 视频：`OOP versus Functional Decomposition` 到 optional `Abstract Methods`
>
> 这一段不需要作业也能上考试的部分是：多重继承、mixin、interface、abstract method。作业要的是前半：把 ML 的表达式解释器按承诺的 OOP 方式搬到 Ruby，加法用 double dispatch，不用 `is_a?`。

到这里，函数式分解和面向对象分解都已经能写。若仍把它们当成两种口味，你会在加一种操作或加一种数据时感到“这种风格真烦”，却说不出烦的是哪一根轴。

Grossman 把这一段称为课程的 punch line。它只能在两种风格都用精确规则学过之后出现。

一个程序若同时有若干种数据、若干种操作，它是一张表。每一格都必须有定义：整数如何变成字符串，加法表达式如何求值，`hasZero` 如何对待每一种 variant。你只学过一种切法时，另一种看起来像另一个问题。它是同一张表，沿另一根轴切开。

```text
                eval          toString        hasZero
Int             格子          格子            格子
Negate          格子          格子            格子
Add             格子          格子            格子
```

函数式按列切：一个函数一种操作，`case` 的每一支是一行。面向对象按行切：一个类一种 variant，类里的每个方法是一列。二者相反，所以比表面更相似。选择不是“谁更先进”。选择是：你以后更常加行，还是更常加列。

静态类型和动态类型是另一根轴。ML 在 `eval` 发现子表达式不是 `Int` 时抛异常，Ruby 直接发 `.i` 然后相信结果。那不是 FP 与 OOP 的分歧。那是 Section 7 已经讨论过的检查发生在何时。

---

## 1. 没有这张表会怎样

没有这张表，“FP vs OOP”停在口味。你无法预测扩展会伤在哪里，也无法解释为什么 binary method 在一种风格里只是嵌套的 `case`，在另一种风格里要么放弃“纯 OOP”，要么做一件他自己也觉得不自然的事。

后面的 mixin 和 interface 也依赖这张表之外的另一条线：复用。一个类想同时拿到两处已有的行为。单继承只给一条父类链。多重继承能表达这个愿望，也制造“哪个方法赢、字段有几份”这些单继承不会问的问题。Ruby 的 mixin、Java 的 interface，是沿“少一点能力、少一点麻烦”往下退的两档。它们不是 ML 的 signature。不要把三个词焊成一个“模块”。

依赖：Part A 的 datatype 与 `case`；Part B 的解释器（程序是树，`eval` 对 variant 递归）；Section 8 的类、方法、动态派发、`super`。准备：作业 7 的几何解释器移植；Section 10 的子类型（`implements` 和 subclassing 都会造出 `<:`）。

---

## Lecture — 按列写，还是按行写

视频：`OOP versus Functional Decomposition`。

### 问题

解释器是他觉得函数式自然的例子：我在求值一个表达式，不同种类各有一支。GUI 是他觉得 OOP 自然的例子：一个图形元素的点击、颜色、拖拽应该放在一起。两种直觉描述的是同一矩阵的两种布局。布局变了，已经填好的格子的可观察行为不必变。

### 机制

**Definition.** 函数式分解（functional decomposition）：datatype 声明行。每个操作是一个函数，也就是一列。`case` 填那一列的格子。面向对象分解（object-oriented decomposition）：每个 variant 一个类，也就是一行。该类的方法填这一行的格子。方法回答的是“这一种数据如何求值 / 如何转成字符串”。

**Intuition.** 列是“一种操作，穿过所有数据”。行是“一种数据，带着它的所有操作”。IDE 里“找出 `Exp` 所有子类的 `hasZero`”是在向按行摆放的代码要一列。函数式的工具也可以做相反的事。大程序的结构比行和列多，没有一种排版能同时露出所有关系。

**Why it exists.** 代码必须放进文件。文件是线性的。表是二维的。切法决定哪一种修改落在一个地方，哪一种修改要打开每一个文件。

**Problem solved.** 把“风格之争”收成“你在组织行还是组织列”。

ML，按列。异常的名字他没说，下面写成 `SomeException` 只是占位。

```sml
datatype exp = Int of int | Negate of exp | Add of exp * exp

fun add_values (v1, v2) =
    case (v1, v2) of
        (Int i, Int j) => Int (i + j)
      | _ => raise SomeException

fun eval e =
    case e of
        Int _ => e
      | Negate e1 =>
          (case eval e1 of
               Int i => Int (~ i)
             | _ => raise SomeException)
      | Add (e1, e2) => add_values (eval e1, eval e2)

fun hasZero e =
    case e of
        Int i => i = 0
      | Negate e1 => hasZero e1
      | Add (e1, e2) => hasZero e1 orelse hasZero e2
```

`toString` 他只说了形状：`Int` 用 `Int.toString`，另外两支递归再拼字符串。拼法没读出来，不要假造。

```text
Expression: eval (Add (e1, e2))
Environment: eval、add_values 在顶层，递归调用能看见它们

1. case 匹配 Add
2. eval e1、eval e2，得到两个 exp
3. add_values：两边都是 Int 则 Int (i + j)；否则异常

eval (Int _) 的值是原来那个表达式，不是新分配的一个整数。
```

Ruby，按行。动态类型里不需要 `Exp`。他仍写一个空的超类，以及一个 `Value` 超类，因为作业会有类似形状。本例里 `Value` 是 overkill：现在唯一的值是整数表达式。

```ruby
class Exp
end

class Value < Exp
end

class Int < Value
  def initialize(i)
    @i = i
  end
  def i
    @i
  end
  def eval
    self
  end
  def toString
    @i.to_s
  end
  def hasZero
    i == 0
  end
end

class Negate < Exp
  def initialize(e)
    @e = e
  end
  def e
    @e
  end
  def eval
    Int.new(- e.eval.i)
  end
  def hasZero
    e.hasZero
  end
end

class Add < Exp
  def initialize(e1, e2)
    @e1 = e1
    @e2 = e2
  end
  def eval
    Int.new(e1.eval.i + e2.eval.i)
  end
end
```

`Negate#eval` 里 `Int.new(...)` 的构造形状是按口述还原的：对子表达式发 `eval`，再发 `i`，造一个新的整数对象。若子表达式的 `eval` 不是 `Int`，`.i` 在运行时失败。这是 ML 那个异常分支的动态类型对应物，不是另一张表。

```text
对象：一个 Negate，实例变量 @e 指向子表达式

Expression: that_negate.eval
Method lookup: 接收者的类是 Negate，找到 Negate#eval
Evaluation:
  向 @e 发 eval          # 动态派发，不在 Negate 里 case 子表达式的类
  向结果发 i
  用取出的数造一个新的 Int
Value: 那个新 Int 对象
```

调用 getter 还是直接读 `@e`，差一次派发，不差这张表。Java 的可选版本是：超类 `Exp` 声明 `eval`、`toString`、`hasZero`，子类各实现三份。那是静态类型的义务，不是切法变了。

**If changed.** 在 ML 的 `case` 里用通配支：若干格子共享一个实现。下一讲“类型检查器帮你列出没改的函数”就依赖你当初没这么做。

他拒绝宣布赢家。哪种视角更好，很大程度是口味，除非你知道接下来要扩展哪一根轴。那是下一讲。

---

## Lecture — 加一列容易，还是加一行容易

视频：`Adding Operations or Variants`。这就是 expression problem，虽然他用的是表，不是这个术语当标题。

### 问题

表已经填好。后来的人要新的一行（一种 variant，例如乘法），或新的一列（一种操作，例如去掉负常量的预处理器）。若当初的切法对不上你真正得到的扩展，就要重开每一个旧函数，或每一个旧类。

“若你知道自己想让哪一种扩展自然、被支持得最好，这应当严重影响你一开始如何分解。”

不计划的话，每种风格仍白送一根轴。另一根轴可以计划，但那是变通：函数式用一个 `other` 分支加高阶函数；OOP 用 Visitor。他把这段标成 optional，没有展开。

### 机制

| | 加一种操作（新列） | 加一种 variant（新行） |
| --- | --- | --- |
| 函数式，不计划 | 局部。新函数。旧函数不动 | 非局部。每个 `case` 都要长一支。没有通配时，类型检查器列出非穷尽匹配 |
| OOP，不计划 | 非局部。每个类都要长一个方法。Java 若在超类声明了该方法，类型检查器列出还没实现的子类 | 局部。新子类。旧类不改。动态派发让旧代码能调用它 |

静态检查帮助的是难受的那根轴。它不取消编辑。

新列，ML。`noNegConstants` 不是“是否只含非负常量”。他口误后纠正：它是 `exp -> exp` 的预处理器，把负常量改写成对正常量的 `Negate`。

```sml
fun noNegConstants e =
    case e of
        Int i =>
          if i < 0
          then Negate (Int (~ i))
          else e
      | Negate e1 => Negate (noNegConstants e1)
      | Add (e1, e2) => Add (noNegConstants e1, noNegConstants e2)
```

```text
Expression: noNegConstants (Int ~3)
Evaluation: 匹配 Int，i < 0，构造 Negate (Int 3)
Value: 一棵新的语法树，不是求值后的数

Expression: noNegConstants (Int 3)
Value: 原来那个表达式
```

`eval`、`toString`、`hasZero` 不动。这就是“加操作是局部的”。

新行，ML。加上 `Mult of exp * exp` 之后重新编译、先不改函数：`eval`、`toString`、`hasZero`，以及已经写了的 `noNegConstants`，都是非穷尽匹配。待办清单就是难受轴的好处。通配支会让这份清单消失，程序仍类型通过，静默走进通配。所以好处只在“第一版没用通配”时成立。

新行，Ruby。只加一个类。

```ruby
class Mult < Exp
  def initialize(e1, e2)
    @e1 = e1
    @e2 = e2
  end
  def e1; @e1; end
  def e2; @e2; end
  def eval
    Int.new(e1.eval.i * e2.eval.i)
  end
end
```

```text
一个 Add，其 @e1 指向一个 Mult 对象

Add#eval 向 @e1 发 eval
查找按接收者的类走，选中 Mult#eval
Add 的源码不用改
```

“加 variant 是局部的”依赖动态派发。若 `Add#eval` 自己按类做条件判断，新子类不会被旧代码接住。

新列，Ruby。必须改每个已有的类。`Int` 是有趣的一支：有时返回另一个对象，有时返回 `self`。

```ruby
class Int
  def noNegConstants
    if i < 0
      Negate.new(Int.new(-i))
    else
      self
    end
  end
end

class Add
  def noNegConstants
    Add.new(e1.noNegConstants, e2.noNegConstants)
  end
end
```

`Negate` 也要加这个方法。方法体他没读出来。不要把 ML 那一支的镜像写成他的 Ruby。

**Why the free axis is free.** 函数式加操作，是因为操作本来就是函数，新函数不打开旧函数。OOP 加 variant，是因为操作本来就是发给接收者的消息，旧方法已经在发 `eval`，新类只要自己回答这则消息。

计划另一根轴的变通，他只点名：

- FP，提前为新数据留门：datatype 和每个函数都有一个 `other` 分支，类型是某个 `'a`，调用时传入高阶函数说明这一支怎么处理。
- OOP，提前为新操作留门：Visitor。每个类都有接受 visitor 的方法。新操作是新的 visitor 类。

两边都是：先在每一列或每一个类里计划，另一根轴才变成局部的。不是“没计划也能两边都局部”。

可扩展有推理代价。`Mult` 出现之前，`eval` 读完 `Int`、`Add`、`Negate` 就懂了。设计允许未知子类定义自己的 `eval` 之后，局部推理不再足够：也许有一个别的类把 `eval` 写错，调用链会把你绕进去。

所以语言也有专门用来禁止扩展的构造：

- ML：把 datatype 藏进 module。外面的代码不能对它 `case`，也就不能加操作。这是 Section 4 的抽象类型，在这里显出用途。
- Java：`final` 阻止子类化或覆盖。
- Ruby 太动态，没有对应物。

预测很难，尤其是关于未来。你可能两种扩展都要，于是其中一种保持别扭。Scala 试图两边都支持。他承认这一点，不讲设计。即便两根轴都解决了，别的扩展仍不可预测。可扩展不总是值钱，可以走过头，因为原来的代码更难推理。

**If changed.** 隐藏 datatype：客户不能加操作。这是有意的阻止，不是缺功能。把 Ruby 的派发换成对类的条件判断：加 variant 不再局部。

---

## Lecture — 加法不是一个格子

视频：`Binary Methods with Functional Decomposition`。

### 问题

行×列的表比真实操作简单。加法不是一格。语言有了三种值——`Int`、`String`、`Rational`——之后，加法定义在每一对上：整数加整数、整数加有理数是算术；字符串加字符串是拼接；字符串加一个数要先把数转成字符串。这是 `eval` 的 Add 这一行里面的第二张表，3×3。

函数式分解处理这张小表相当好。承诺 OOP 的风格要么放弃纯 OOP，要么做更复杂的事。这一讲只给函数式那一侧。

### 机制

**Definition.** Binary method / binary operation：两个参数属于正在定义的那一族类型。二元已经够复杂。n 元是同一个想法。

扩展之后，`eval` 只返回 `Int`、`String`、`Rational`。因此 `Add` 的求值总有定义的格子。`Mult` 不是：它仍要求两个 `Int`，否则抛异常。同一种语法位置（二元运算符），定义域可以不同。不要因为 `Mult` 会抛，就让 `Add` 也在非整数上抛。他故意改了 `Add`。

九格放在一个 helper 里，嵌套模式匹配。写在 `eval` 内部的嵌套 `case` 语义相同。helper 是为了让“我们用一个函数定义这张绿表”更清楚。

类型检查器不知道这两个参数是值。第十支在任一参数不是那三种值时抛异常。这不是类型系统看见了 `eval` 的不变量。它看不见。第十支是程序员把不变量写成运行时检查。

可交换的格子可以交换参数再递归，不必粘贴函数体。这一份 `add_values` 里他只让一格这么做。字符串和有理数的拼接顺序有关，不能交换。

```sml
datatype exp =
    Int of int
  | Negate of exp
  | Add of exp * exp
  | Mult of exp * exp
  | String of string
  | Rational of int * int

fun eval e =
    case e of
        String _ => e
      | Rational _ => e
      | Int _ => e
      | Add (e1, e2) => add_values (eval e1, eval e2)
      | Mult (e1, e2) =>
          (case (eval e1, eval e2) of
               (Int i, Int j) => Int (i * j)
             | _ => raise SomeException)
      | Negate e1 => raise Fail "not re-spoken"

fun add_values (v1, v2) =
    case (v1, v2) of
        (Int i, Int j) => Int (i + j)
      | (Int i, String s) => String ((Int.toString i) ^ s)
      | (Int i, Rational (j, k)) => Rational (i * k + j, k)
      | (String s, Int i) => String (s ^ (Int.toString i))
      | (String s1, String s2) => String (s1 ^ s2)
      | (String s, Rational (j, k)) =>
          String (s ^ "")   (* 有理数如何转成字符串，口述是“以某种方式”，转换本身没读出来 *)
      | (Rational _, Int _) => add_values (v2, v1)
      | (Rational _, String s) =>
          String ("" ^ s)   (* 顺序与上一支相反，不能交换参数。转换没读出来 *)
      | (Rational (a, b), Rational (c, d)) =>
          Rational (a * d + c * b, b * d)
          (* [?] 他只说 basic arithmetic，没有读出公式。这是标准的未约分加法，不要当成逐字幻灯片 *)
      | _ => raise SomeException
```

`^` 是按“拼接”还原的。整数加有理数他确实说了：`i * k + j` 作分子，分母 `k`，不约分。有理数加有理数的公式没有被读出来。

```text
Expression: add_values (Rational (1, 2), Int 3)
Evaluation:
  匹配 (Rational _, Int _)
  不复制 Int+Rational 的函数体
  递归 add_values (Int 3, Rational (1, 2))
  那一支是非递归的格子
Value: Rational (3 * 2 + 1, 2) = Rational (7, 2)，未约分
```

交换不是无限递归。交换后的一对匹配更早的、不递归的格子。前提是那一格不是通配。他在讨论“把函数体粘过去”的替代写法时加了这句假设。同一假设保护这个交换。

加 `String` 和 `Rational` 两个构造子，是上一讲函数式难受轴的税。他已经改过 `eval`、`toString`、`hasZero`、`noNegConstants`。那不是这一讲的题目。题目是加法内部的 3×3。

**If changed.** 把字符串与有理数的拼接当成可交换：语言错了。约分 `i * k + j` over `k`：他承认仍是一个正确的值，但不是这段代码做的事。去掉第十支：非值表达式（`Negate`、`Add`、`Mult`）落入匹配失败。通配会让交换调用打中通配，而不是打中对面那一格。

---

## Lecture — 两次派发，因为语言只看接收者

视频：`Double Dispatch`。

### 问题

同一扩展，现在用 Ruby。类名是 `MyString` 和 `MyRational`，因为 Ruby 已经有 `String` 和 `Rational`。ML 里九格是一次嵌套匹配。承诺 OOP 之后没有 `case`。左边的值必须被要求把自己加到右边的值上。左边的方法接着仍需要知道右边的类。

`is_a?` 能算出这张表。作业禁止。它太容易，不够 OOP：前一半是动态派发，后一半是对类的 `cond`，他称为 Racket 风格。纯 OOP 不许问 `v` 是什么类。它必须给 `v` 发消息。把 `add_values` 发回去是无限循环。Double dispatch（双派发）的把戏是发一则**不同的**消息，消息的名字标出 `self` 的类。这个类，方法自己知道。

他不指望你发明这个把戏。“这不是我期望你自己想出来的，但它确实能工作。”作业是把 ML 代码按这个方式搬到 Ruby。他会给很多提示。

为什么教一个他自己觉得不自然的惯用法：一部分是为了压一压“全面承诺 OOP”。他不觉得这是把一件简单的事写简单的办法。他认为 ML 的代码是简单的。另一部分是逼你用一个精巧的惯用法把方法查找走通，并和下一讲的 multimethod 对照：那里语言构造一步做完同一件事。

### 机制

**Definition.** 单派发（single dispatch）：方法体由接收者的运行时类决定。Ruby、Java、C#、C++ 的普通方法调用都是这样。Double dispatch 不是第二套语言规则。它是两步单派发：第一步的方法名携带左边操作数的类，第二步的接收者是右边操作数。

`Add#eval` 不调用 helper。“OOP 风格里我们不调用 helper。这些东西应当知道如何把自己加起来。”

```ruby
class Add
  def eval
    e1.eval.add_values(e2.eval)
  end
end
```

```text
Expression: e1.eval.add_values(e2.eval)
对象环境：这个 Add 的 @e1、@e2

v1 = e1.eval     # Int | MyString | MyRational
v2 = e2.eval
第一次派发，按 class(v1) 选 add_values：
  Int        的方法体是 v2.addInt(self)       # self 是左边的 Int
  MyString   的方法体是 v2.addString(self)
  MyRational 的方法体是 v2.addRational(self)
第二次派发，按 class(v2) 选 addInt / addString / addRational
在那个方法里，self 是 v2（右边），参数是 v1（左边）
Value: 一个新的 Value
```

三个类各实现这三个方法，一共九个定义。九格在这里。`addInt` 的唯一调用点在 `Int#add_values` 里，所以参数一定是 `Int`。这是调用点的不变量，不是方法内部的检查。`addString`、`addRational` 同理。

```ruby
class Int
  def add_values(v)
    v.addInt(self)
  end
  def addInt(v)
    Int.new(v.i + i)
  end
  def addString(v)
    # v 是左边的 MyString，self 是右边的 Int
    # 口述的拼接是 v.s + i.to_s。顺序不能反。包装成 MyString 是还原，不是逐字
    MyString.new(v.s + i.to_s)
  end
end

class MyString
  def add_values(v)
    v.addString(self)
  end
end

class MyRational
  def add_values(v)
    v.addRational(self)
  end
end
```

其余六支他描述了意图，没有读出方法体：字符串与字符串拼接；整数在右边、字符串在左边时，把整数转成字符串再拼到自己身上；有理数用两边的分子分母做算术。不要把没读出来的算术写成他的代码。

字符串让左右翻转变得可见。算术若可交换，写反了也看不出来。这是最容易写错的地方。

被禁止的混合写法，只示意 `Int`：

```ruby
class Int
  def add_values(v)
    if v.is_a?(Int)
      Int.new(i + v.i)
    elsif v.is_a?(MyRational)
      # 口述：自己乘分母，再做正确的算术。表达式没读出来
      MyRational.new(i * v.denominator + v.numerator, v.denominator)
    else
      # 他假设剩下只可能是 MyString，不再问第三次
      MyString.new(i.to_s + v.s)
    end
  end
end
```

九格都在，第二刀是条件而不是派发。他不讨厌这种编程风格。他拒绝把它叫成面向对象。作业要的是派发惯用法，不是和。

**If changed.**

- `add_values` 写成 `v.add_values(self)`：左边调用右边，右边用同一个名字调用回来，无限递归。
- 只有左边的类实现 `addInt`：右边是另一个类时，第二次发送方法缺失。三个值类都要有这三个方法。
- 忽略字符串格子里的左右翻转：拼接顺序错。可交换的算术格子藏住这个 bug。
- 作业用 `is_a?`：表算对了，作业仍错。错在风格承诺，不在算术。

Java 的可选版本把同一惯用法加上类型。`Value` 声明 `add_values`、`addInt`、`addString`、`addRational`。后三个的参数类型比 `Value` 更具体。他觉得类型让惯用法更清楚。在 Java 文件里有理数类可以就叫 `Rational`，没有和标准库撞名的问题。这是概念类比下的同一种查找，不是声称 Java 的重载就是 double dispatch。重载是下一讲要拆开的东西。

---

## Lecture — 语言可以一次看两个运行时类

视频：optional `Multimethods`。

### 问题

Double dispatch 是手工的、别扭的。若语言对每个参数的运行时类都派发，不只看接收者，惯用法就不需要。他用这一段把话说得公平一点：上一讲的痛是 Ruby 的单派发，不是 OOP 的定律。同时挡住一个假等价：Java / C# / C++ 里同名方法不是这个特性。

**Definition.** Multimethods，也叫 multiple dispatch（多重派发）：若干同名方法，由接收者和参数的类区分。调用用这些操作数的运行时类在它们之间选择。

假想的、不是 Ruby 的语言：

```text
class Int
  add_values(Int other)
  add_values(MyString other)
  add_values(MyRational other)
class MyString
  同样三个 add_values
class MyRational
  同样三个 add_values

调用 e1.eval.add_values(e2.eval)
  接收者的运行时类 ∈ {Int, MyString, MyRational}
  参数的运行时类   ∈ {Int, MyString, MyRational}
  语言选出九个之一
```

九个方法体还在。程序员不再手写第二次跳跃。子类化可能让多个方法都适用。语言必须定义哪一个最好，否则调用者会在期望一个方法时跑到另一个。他不给出决胜规则。

若“动态派发”是 OOP 与函数调用的差别，多重派发就是更多的 OOP：派发不限于点左边的那个东西。

Ruby 不适合加上它，他给两个理由：

1. Ruby 的方法不声明参数的类。任何对象都能传给任何方法。多重派发的选择依赖那些声明。
2. Ruby 的规则很简单：一个类从不同时有两个同名方法。重复定义是替换。子类的同名方法是覆盖。多重派发需要同名方法共存。

| | 调用时检查什么 | 同名方法意味着 | 帮得上这张 3×3 吗 |
| --- | --- | --- | --- |
| Ruby 单派发 | 只看接收者的运行时类 | 覆盖，或在同一个类里替换 | 只有手工 double dispatch |
| Multimethods | 接收者和参数的运行时类 | 同名方法共存，按运行时类选择 | 一次调用即可 |
| Java / C# / C++ 静态重载 | 接收者运行时类；其他参数的静态类型 | 编译期按静态类型决议的 overload | 不能。最多把第二次跳跃的方法都命名为 `add` |
| C# 4.0 `dynamic` | 可以把参数的选择推到运行时 | 重载加上一次动态转换 | 对这种例子“够用” |

静态重载不是多重派发。接收者仍按运行时类选方法体。其他参数按静态类型在编译期选中重载。参数的静态类型是 `Value`、运行时类是 `MyRational` 时，重载看不见运行时类。所以它实现不了这个解释器的加法。你仍要手写 double dispatch。唯一的便利是第二次跳跃可以都叫 `add`。他个人觉得这更混乱，不是更有帮助。那是那些语言里的惯例。

C# 4.0 把参数转成 `dynamic`，可以得到多重派发的效果。这是叠在静态重载上的足够解法，不是“方法调用的含义从一开始就是多重派发”。Clojure 是他点名的现代例子：多重派发就是方法调用的工作方式。这个想法有几十年，没有在 OOP 里变成主流。没变成主流，和“没人试过”，是两句不同的话。

**If changed.** 给 Ruby 加多重派发但不加参数类声明：没有东西可用来区分。把静态重载当成 double dispatch 的替代：对这个例子不行。两个适用的 multimethod 又没有决胜规则：程序员会在跑错方法时感到惊讶。

---

## Lecture — 两个父类，字段是一份还是两份

视频：`Multiple Inheritance`。作业用不上。考试可以考。

### 问题

一个超类有用，为什么不能有几个？`ColorPt3D` 想要 `ColorPoint` 的每个方法和 `ThreeDPoint` 的每个方法。`StudentAthlete` 想要 `Student` 和 `Athlete`。Ruby 只给一个超类，不写就是 `Object`。你只能复制。多重继承（multiple inheritance）拿掉这份复制，它有用。它也制造单继承不问的问题：我继承的是哪个方法？这个字段有几份？

C++ 是最著名的支持多重继承的语言。他不展示 C++。多重继承还让静态类型检查和 OOP 的高效实现变复杂。这里只问几个语义问题。

他摆出一条谱：多重继承（有用，有问题）→ Ruby mixin（能力少一些，问题少一些）→ Java / C# interface（能力更少，问题更少）。三者不同，适用场合不同。

### 机制

直接子类：`A` 把 `B` 写成超类。传递子类：沿链走上去。`A` 是 `C` 的子类，不必是直接子类。两个词不分开，后面的图会说乱。

单继承的子类关系是树。多重继承的层次是有向无环图。从 `Y` 到 `X` 可以有两条路。

```text
        X
       / \
      V   W
      |   |
      |   Z
       \ /
        Y
```

他不替任何语言选定规则，只把问题摆出来：

- `V` 和 `Z` 都定义 `m`。`Y` 继承哪一个？它们以不同方式覆盖 `X` 的 `m` 时，问题相同。`Y` 要 `super`，哪个 super？
- `X` 定义 `m`，`Z` 覆盖它，`V` 没有。`Y` 的 `m` 是什么？他怀疑：从 `Y` 看来，重要的是 `V` 有这个方法，至于 `V` 是自己定义的还是继承来的，也许不该有区别。他不确定这一情况和“两个父类都自己定义了 `m`”该不该用同一条规则。
- `X` 里的字段，`Y` 有一份还是两份？两种答案在真实设计里都出现。C++ 用不同种类的继承区分。他不展示语法。

没有一般解。这就是一些语言干脆不支持多重继承的原因。

```text
        Point
        /   \
 ColorPoint  ThreeDPoint
        \   /
      ColorPt3D          想要一份 x、一份 y，不是两套坐标系

        Person
        /    \
   Artist    Cowboy
        \    /
     ArtistCowboy        想要两个 draw、两个 pocket
                         Artist 从口袋拿画笔作画
                         Cowboy 从口袋拔枪
```

总是一份字段：`ColorPt3D` 对了，`ArtistCowboy` 的画笔和枪在同一个口袋里。总是两份：`ArtistCowboy` 对了，`ColorPt3D` 有两套坐标。`super` 若不要求指出哪个父类，两个父类时有歧义。

Ruby 写不出 `class ColorPt3D < ColorPoint, ThreeDPoint`。变通是子类化其中一边，把另一边的方法和字段抄过来。抄短的那边。那不是原则，是缺了特性之后的残渣。`ThreeDPoint < Point` 是不是合理的 is-a，他标成有争议，仍拿来当例子。

**If changed.** 只加第二个超类槽、不给查找和字段份数的规则：语法不是特性。`ColorPt3D` 仍不知道 `distToOrigin` 来自哪一边（`ThreeDPoint` 覆盖了，`ColorPoint` 没有），也不知道 `x` 有一份还是两份。

---

## Lecture — Mixin：方法的袋子，不是第二个父类

视频：`Mixins`。

### 问题

多重继承既能表达 `ColorPt3D`，也能表达 `ArtistCowboy`，并且无法决定字段份数和哪个方法赢。Ruby 的回答是 mixin：一袋方法，不是类。include 进一个仍然只有一个超类的类。Include 是把那些定义粘贴进去，所以你不必自己维护两份抄本，也不继承第二条字段链。

能力在于：被 include 的方法作为宿主类的方法运行。它们可以向 `self` 发消息，包括宿主定义而 mixin 没有定义的方法。这够做 `Comparable` 和 `Enumerable`。他说这是大家真正喜欢它们的原因。它不够用来同时继承 `Artist` 和 `Cowboy`，若二者都必须是类。“我绝不会说它们是多重继承的完整替代。”

Ruby 把 mixin 拼成 `module`。`module` 也做名字空间。同一关键字，两件不同的事。这一讲只用 mixin 那一件。他说 mixin 与某些语言里的 trait 非常相似。他不点那些语言的名。概念类比，到此为止。

### 机制

**Definition.** Mixin 只有方法。不能 `new`。一个类有一个超类，可以 `include` 任意多个 mixin。Include 把方法定义加进类，可以覆盖超类的方法。收益是不必重打那些方法。

查找 `m`，在 Section 8 的规则上延伸：

```text
obj 的类
然后该类 include 的 mixin（后 include 的遮住先 include 的；顺序他不考）
然后超类
然后超类 include 的 mixin
然后继续向上
```

超类槽仍是一个。Include 不是第二个父类。

Mixin 方法可以读写实例变量。变量属于宿主对象，不属于 mixin。两个 mixin 用同一个实例变量会互相干扰。许多人认为 mixin 方法碰实例变量是差风格。有时你就是需要。他不裁决风格。语义是：允许。

```ruby
module Doubler
  def double
    self + self
  end
end

class Point
  def +(other)
    # 新点，坐标是两点 x、y 之和。方法体没读出来
  end
  include Doubler
end
```

```text
对象 p：x = 3, y = 4，类是 Point，Point include 了 Doubler

Expression: p.double
Lookup: Point 自己没有 double，在 include 的 Doubler 里找到
Evaluation: 向 self 发 +，参数是 self
  self 的类是 Point，Point#+ 运行
Value: 一个 x = 6、y = 8 的点。它自己也有 double

"hello".double
  同一个 double 方法体
  String#+ 是拼接
Value: "hellohello"
```

同一段 mixin 代码，两个宿主的 `+`。Mixin 在 `include` 时不检查宿主有没有 `+`。没有，就在发送时方法缺失。

改一个已经存在的类（给 `String` include `Doubler`）能工作，风格可质疑。

`Comparable`：宿主定义 `<=>`（spaceship）。Mixin 定义 `<`、`>`、`==`、`!=`、`>=`、`<=`。`<=>` 返回负、零、正，分别表示左边较小、相等、右边较小。数已经这样做：`3 <=> 4` 是 `-1`，`3 <=> 3` 是 `0`，`3 <=> 2` 是 `1`。他用“结果是否小于 1”描述数上的 `<` 如何用 spaceship 实现。这和通常的“小于 0”对不上，当口误，不要记成规则。

```ruby
class Name
  def initialize(first, last, middle)
    @first = first
    @middle = middle
    @last = last
  end
  def <=>(other)
    # 姓不等，用 String#<=> 比姓
    # 否则名不等，比名
    # 否则比中间名
  end
  include Comparable
end
```

他在 REPL 里把姓名的位置说拧了。比较的键顺序是姓、名、中间名。`n1 <=> n2` 得到 `1`，反过来 `-1`，自己和自己 `0`。`==` 和 `!=` 能工作，只因为 `include Comparable` 用 `<=>` 定义了它们。不 include，`<=>` 还在，`==` 不是 mixin 给的。

```text
Expression: n1 == n2
Lookup: Name 没有 ==，Comparable 有
Evaluation: Comparable 的 == 向 self 发 <=>
  派发到 Name#<=>
  用 String#<=> 比姓、名、中间名
  == 把那个整数结果变成布尔
```

`Enumerable`：宿主只定义 `each`。Mixin 用 `each` 定义一批带 block 的迭代器。Mixin 不知道表示。他两次把 `Enumerable` 说成 `Comparable`。`Name` include 的是 `Comparable`。Range 例子 include 的、以及“用 `each` 定义”的，是 `Enumerable`。

```ruby
class MyRange
  def initialize(low, high)
    @low = low
    @high = high
  end
  def each
    i = @low
    while i <= @high
      yield i
      i = i + 1
    end
  end
  include Enumerable
end
```

区间含端点。3 到 7 打出 3、4、5、6、7。真程序不会自己写这个，Ruby 有 range。`r2` 从 5 到 12，`count` 奇数得到 4，即 5、7、9、11。`r1` 的奇数是 3、5、7，他预期 3。`map`、`any?` 也在，由 mixin 用 `each` 定义。

```text
Expression: r2.count { |x| x.odd? }
Lookup: count 在 Enumerable，不在 MyRange
Evaluation: Enumerable#count 向 self 发 each，并传入 block
  MyRange#each 依次 yield 5, 6, ..., 12
  mixin 数那些使 block 为真的 yield
Value: 4
Mixin 不读 @low、@high
```

颜色作为 mixin，能做 `ColorPt3D`，且不会得到第二份 `x`：`x` 只从唯一一条通向 `Point` 的链来。

```ruby
module Color
  def color; @color; end
  def color=(c); @color = c; end
  def darken
    # 与上一讲 ColorPoint#darken 同一想法：灰、深灰、深深灰
  end
end

class ColorPoint < Point
  include Color
end

class ColorPoint3D < Point3D
  include Color
end
```

`Color` 碰 `@color`，违反他自己转述的风格建议。他仍用它，并标明有争议。`Artist` 和 `Cowboy` 都应该是类，mixin 表达不了 `ArtistCowboy`。把其中一个降成 mixin，就不再是那个例子想要的类。

| | 多重继承 | Ruby mixin |
| --- | --- | --- |
| 定义 | 第二个超类，带着它自己的超类、字段和查找路径 | 方法粘进仍只有一个超类的类 |
| 解决的问题 | 从两个类复用实现 | 复用一袋方法，并让它们回调宿主 |
| 关键区别 | 字段份数是开放问题 | 实例变量在宿主对象上。同名会撞，但不是两份继承来的槽 |
| 典型场景 | `ArtistCowboy`，两边都是类。C++ | `Comparable`、`Enumerable`、`Color`。不是 ML signature |

Mixin 不是 ML 的 signature。Signature 是客户被允许看见的边界，用来隐藏表示。Mixin 是实现的复用，而且被 include 之后那些方法就是宿主的方法。Ruby 的 `module` 还可以做名字空间，那才和 ML module 的弱用法相近。同一关键字，不要并成一个概念。

---

## Lecture — Interface：类型，不是行为

视频：`Interfaces`。

### 问题

Mixin 加入方法体。多重继承加入方法体、字段，以及查找问题。静态类型的 OOP 仍需要一种办法：两个没有共同超类的类，能被传给同一个方法。Interface 是这个装置。它是类型，不是类。列出方法名和类型，没有方法体，没有字段。它给实现类增加义务，给类型系统增加灵活性。它不增加行为。

Ruby 不会长出 interface。Ruby 没有一个正想变灵活的静态类型系统。动态类型已经比“带 interface 的 Java”更灵活。Interface 在 Ruby 里没有意义。他用 Java 讲，因为概念可以在一门没有该特性的语言课上讲。不要求你以前写过 Java。

### 机制

静态 OOP 在这里的义务：防止方法缺失。只传递这样的对象：每个方法调用都能找到方法。

每个类引入一个类型，类比 ML 的 datatype 绑定引入一个类型。不是同一机制。方法有参数类型和结果类型，类比函数类型。Java 把结果类型写在左边。子类化蕴含子类型，包括传递子类化。子类型可以用在需要超类型的地方。

**Definition.** Interface 是类型，不是类。和 mixin 一样，没有实例。和 mixin 不同，没有方法体。内容是：方法存在，参数类型，结果类型。分号代替方法体，是语法上的那一点。

Java 和 C#：一个超类，可以实现任意多个 interface。形状平行于 Ruby 的一个超类加任意多个 mixin。载荷从方法体换成了义务。

```java
interface Example {
  void m1(int a, int b);
  Object m2(Example e, String s);
}

class A implements Example {
  public void m1(int a, int b) { }
  public Object m2(Example e, String s) { return s; }
}

class B implements Example {
  public void m1(int a, int b) { }
  public Object m2(Example e, String s) { return e; }
}
```

方法体在这一讲无关。`implements` 被检查：类必须自己写出或继承到每一个所要求的方法，类型正确。多个 interface 只是义务的并，所以没有菱形问题。它们什么行为都不给你，lecture 06 的麻烦与此无关。

若 `A implements Example`，类型 `A` 是类型 `Example` 的子类型。需要 `Example` 的调用者可以拿到 `A`，也可以拿到 `B`。方法体知道 interface 承诺的方法存在、类型如声明。它不知道运行时是 `A` 还是 `B`。

```text
调用某方法，参数位置要求 Example，实参是一个 A 的实例
静态：A <: Example，因为 implements，不是因为共同的实现超类
方法体里 e.m1(1, 2) 类型通过，因为 Example 承诺了这个方法
运行时：动态派发按对象的类选择 A#m1 或 B#m1
他没有跑这个例子。要点是静态承诺，不是某个值
```

“带 interface 的 Java 比不带 interface 的 Java 类型系统灵活得多。”这就是全部特性。仍不如 Ruby 的动态类型灵活。那笔账是 Section 7 的，他不重复。

**If changed.** Interface 允许有方法体：它开始变成 mixin，“没有字段、没有继承来的代码、没有菱形问题”需要重新证明。他定义的 Java 特性就是那个分号。类声称 `implements` 却漏了方法或类型写错：类型检查器拒绝。义务就是特性。给 Ruby 加 interface：没有东西要检查，也没有东西要放松。

| | Ruby mixin | Java / C# interface | 多重继承 |
| --- | --- | --- | --- |
| 定义 | 方法，无实例。`include` 加入行为 | 方法类型，无方法体，无字段，无实例。`implements` 加入义务和子类型 | 方法、字段、超类链、查找歧义 |
| 解决的问题 | 复用行为，回调宿主 | 让无共同超类的类在静态类型里可替换 | 从两个类复用实现 |
| 关键区别 | 没有类型系统也说得通 | 存在就是为了让静态 OOP 的类型系统更灵活 | 存在就是为了实现复用 |
| 典型场景 | `Enumerable` | 一个方法的参数类型是 interface，`A` 和 `B` 都能传 | `ArtistCowboy` |

Interface 不是“变得安全的多重继承”。它靠不提供方法和字段避开那些问题。它也不提供多重继承要的那种复用。

---

## Lecture — 缺的那段代码，谁来提供

视频：optional `Abstract Methods`。见过一点 Java、C# 或 C++ 就该看。没见过静态 OOP 可以当可选。

### 问题

超类有时是共享代码的地方，而这段代码要调用一个它不知道怎么写的方法。图形对象的 `size` 没有合理的默认，不是 10×10，也不是 0×0。子类必须覆盖。Ruby 里一条注释就够，动态派发让 `self.m2` 在实例的类定义了 `m2` 时工作。静态 OOP 的类型检查器拒绝这一点，因为它的工作是让方法缺失不可能发生。

把 `m2` 定义成抛异常，加一条注释，能骗过检查器。子类忘记覆盖，仍在运行时失败。Abstract method（Java、C#）/ pure virtual method（C++）把失败挪到编译期。它们不增加运行时能力。

这一讲还有两件事。Abstract method 和高阶函数都是“把代码交给另一段代码”。C++ 没有 interface 这种单独特性，因为多重继承加上 pure virtual 可以编码它。

### 机制

Ruby：超类注释“子类必须覆盖，不要实例化超类”。`A#m1` 调用 `self.m2`。`A` 不定义 `m2`。

```ruby
class A
  def m1
    self.m2
  end
end
```

```text
A.new.m1
  A 没有 m2
  方法缺失

Sub < A，Sub 定义了 m2
Sub.new.m1
  A#m1 运行
  self.m2 按实例的类派发
  Sub#m2
```

这就是 Section 8 的动态派发。有的类存在只是为了被子类化。通常我们定义类是为了造实例。这次不是。

静态检查器不会接受 `A` 调用一个 `A` 没有的 `m2`。弱的变通：

```java
class A {
  Object m1() { return m2(); }
  Object m2() { throw new RuntimeException("override m2"); }
}
```

异常类名没被读出来。类型检查器满意。忘记覆盖，运行时异常，不是编译错误。

```java
abstract class A {
  Object m1() { return m2(); }
  abstract Object m2();
}
class Sub extends A {
  Object m2() { return null; }
}
```

`m1` 的方法体是 Ruby 那张图，Java 片段里他没有逐字重打。语义是：拒绝 `new` 超类的程序；子类要么也不可实例化，要么按声明的类型实现该方法。这在编译期抓住错误，也给读者写下覆盖义务。语言没有因此更强。抛异常的版本已经有运行时行为。Abstract method 不是多于额外静态检查的东西。

和高阶函数的平行，他希望被记住：

```sml
fun f g =
    g
```

`f` 是 `m1`，`g` 是 `m2`。调用 `f` 的人传入 OOP 里会放进子类的那个函数。他没写完整的 `f`。相似处是谁提供未知的代码，不是把 GUI 的 `size` 翻译成 SML。

| | Abstract method | 高阶函数 |
| --- | --- | --- |
| 定义 | 超类声明方法的类型，没有方法体。子类提供方法体 | 函数把另一个函数当参数，调用它 |
| 解决的问题 | 共享代码要调用一段它写不出的操作，并在编译期强迫子类提供 | 共享代码要调用一段它写不出的操作，由调用者提供 |
| 关键区别 | 未知代码由子类提供，靠对 `self` 的动态派发接上 | 未知代码由调用者提供，靠参数绑定接上 |
| 典型场景 | 没有合理默认的 `size` | Part A 的 `map`、`n_times`，以及这里的 `f g` |

二者是互补的打包，出奇地相似。不是一个是另一个的 bug。

C++ 没有单独的 interface，因为他的论证：有多重继承和 abstract method 的语言不需要。子类化一个所有方法都是 pure virtual 的类，不继承任何代码。你这么做，是为了成为子类型，并被迫实现那些方法。这正是 interface 的用途。Interface 存在，是为了绕开“只能有一个超类”。若允许多个超类，就没有这个限制。

因此只在既静态类型、又没有多重继承的语言里期望看到 interface。不是 Ruby。不是 C++。是 Java 和 C#。

```text
class Example {
  // 每个方法都是 pure virtual：类型，没有代码
};
class A : public Example { /* 实现那些方法；没有继承到代码 */ };
// A 是 Example 的子类型，因为是子类
// 第二个“interface”= 第二个全 abstract 的超类
// 合法，因为有多重继承
```

**If changed.** 静态语言接受 `A#m1` 调用未定义的 `m2`：检查器不再防止方法缺失。他把这看成违反静态 OOP 的目标，不是他要探索的设计。Abstract method 有了默认方法体：它就是普通的可覆盖方法。`size` 没有合理默认，所以他要方法体缺席。把缺的 GUI 操作当成函数参数传入，而不是 abstract method：高阶版本能工作。提供者从子类变成调用者。

---

## 对照（这一节不要并掉的）

### 函数式分解 vs 面向对象分解

| | 函数式分解 | 面向对象分解 |
| --- | --- | --- |
| 定义 | 一个函数一种操作。Datatype 是行。`case` 填一列 | 一个类一种 variant。方法填一行 |
| 解决的问题 | 把“穿过所有数据的一种操作”放在一处。解释器自然落在这里 | 把“一种数据的全部操作”放在一处。一种 GUI 元素自然落在这里 |
| 关键区别 | 加操作局部，加 variant 非局部 | 加 variant 局部，加操作非局部。局部性依赖动态派发 |
| 典型场景 | ML 的 `eval` / `toString` / `hasZero` | Ruby 的 `Int` / `Negate` / `Add`，每个类里三个方法 |

### Double dispatch vs Multimethod vs 静态重载

| | Double dispatch | Multimethod | 静态重载 |
| --- | --- | --- | --- |
| 定义 | 两次单派发。第二次的方法名编码第一次发现的类 | 一次调用，按所有操作数的运行时类选择同名方法 | 接收者运行时派发；其他参数按静态类型在编译期选择重载 |
| 解决的问题 | 在只有单派发的语言里，仍用消息覆盖一张二元表 | 让语言构造代替那个手工跳跃 | 同名方法按静态参数类型区分。方便，但是另一件事 |
| 关键区别 | 惯用法，不是 Ruby 的语法。`self` 在第二跳里是右边 | 需要参数类成为方法身份的一部分。Ruby 没有这个 | 看不见非接收者的运行时类。实现不了这张加法表 |
| 典型场景 | 作业里的 `addInt` / `addString` / `addRational` | Clojure。C# `dynamic` 可以模拟 | Java / C# / C++ 的 `add(Int)` 与 `add(String)` |

### Mixin vs Interface vs ML signature

| | Mixin | Interface | ML signature |
| --- | --- | --- | --- |
| 定义 | 一袋方法体，include 进宿主 | 一列方法类型，无方法体 | 客户可见的名字和类型，可隐藏表示 |
| 解决的问题 | 复用行为，并回调宿主还没有写在 mixin 里的方法 | 在单继承的静态语言里制造子类型，而不共享实现 | 抽象边界。两种实现可以等价 |
| 关键区别 | 加入行为。可以碰宿主的实例变量 | 只加入义务和 `<:`。不加入行为 | 隐藏实现，不是把方法粘进客户 |
| 典型场景 | `Enumerable` 用宿主的 `each` | Java `implements Example` | `signature RATIONAL` 不暴露是 pair 还是记录 |

这三行是概念类比的边界。说出相似点之后必须停。Ruby 的 `module` 同时是 mixin 和名字空间，更不能把整词翻译成 “ML module”。

---

## Connection to Modern Languages

都是概念类比。

- Rust 的 `enum` + `match` 是这张表的列切法。加 variant，编译器列出每个未更新的 `match`，比 ML 的 warning 更硬。加操作是新函数。Trait 可以让你事后给已有类型加操作，那是另一条扩展轴，不是 Grossman 在这一讲讲完的 Visitor。
- Scala 是他点名的“试图两边都支持”的语言。不要在没有读它的设计之前声称它解决了 expression problem 的每一种未来扩展。他明确不这么声称。
- Java 的 Visitor 是他点名的 OOP 变通：每个类事先接受 visitor，新操作是新 visitor。这要求在每个类里先计划。它不是“OOP 加操作本来就局部”。
- Java / C# 的 interface 不是 Rust 的 trait，也不是 Ruby 的 mixin。Interface 没有方法体（就他在 2013 年前后讲的 Java 而言；后来的 default method 会让“只有分号”这条需要重证，他没讲那个扩展）。Rust trait 可以有默认方法，也可以做静态派发。不要并成一个词。
- C++ 多重继承加 pure virtual，按他的论证，可以编码 interface。C++ 还有他不展示的继承种类，用来选择一份字段或两份。没有那些规则，多重继承的语法说明不了 `ColorPt3D` 和 `ArtistCowboy` 哪一个能工作。
- Clojure 的多重派发是他点的现代例子。Java 重载不是。Go 的 interface 在“无共享超类即可满足一组方法”上接近 Java interface 的灵活性，但是结构满足、不是 `implements` 声明。这是类比，作业里的 Ruby 没有这个静态检查。

---

## Section 9 Review

这一节把 FP 和 OOP 收成同一张 variant×操作表的两种切法。加操作在函数式里局部，加 variant 在 OOP 里局部，后者依赖动态派发。二元操作是表中的另一张表：函数式用嵌套模式匹配；单派发的 OOP 要么用被禁止的 `is_a?`，要么用 double dispatch。Multimethod 说明痛来自单派发，不是来自 OOP 本身。然后能力递减：多重继承、mixin、interface。Mixin 复用方法体并回调宿主。Interface 只制造静态义务和子类型。Abstract method 把“子类必须提供这段代码”从运行时失败提前到编译期，和高阶函数是互补的供码方式，不是新的运行时机制。

### 核心概念

variant×operation 矩阵、函数式分解、面向对象分解、expression problem 的两根轴、binary method、double dispatch、multimethod、静态重载、多重继承、字段份数、mixin、`Comparable`、`Enumerable`、interface、abstract method、pure virtual。

### 不变量

```text
两种分解是同一张表的行切和列切，不是两个问题。
静态 vs 动态，正交于行 vs 列。
不计划时：FP 白送新操作，OOP 白送新 variant。
OOP 加 variant 之所以局部，是因为旧代码在发消息，不是在 case 类。
is_a? 能算对九格，仍不是这一课承诺的 OOP。
double dispatch 是两次发送。第二次的名字编码第一次的类。
第二跳里 self 是右边的操作数。
Java 重载不是 multimethod。
Mixin 不是第二个超类，也不是 ML signature。
Interface 不加入行为。Abstract method 不增加运行时能力。
```

### 能力检查

- 给一张 3×3 的表，指出加一行和加一列在 ML 与 Ruby 里各要改哪些定义。
- 对 `Add#eval` 里 `e1.eval.add_values(e2.eval)`，写出两次派发各自的接收者，以及 `addString` 里 `self` 是哪一边。
- 说明 `v.add_values(self)` 为什么循环，而 `add_values (v2, v1)` 在 ML 里为什么不一定循环。
- 用 `ColorPt3D` 和 `ArtistCowboy` 说明“总是一份字段”为什么不是一般解。
- 说明 `Enumerable#count` 如何在不读 `@low` 的情况下数奇数，以及这和闭包回调宿主有什么同构。
- 说明为什么 C++ 可以没有单独的 interface 特性，而 Java 有。不要把这说成 C++ 更不面向对象。

练习：`exercises/section-09.md`。
