# Module 10 — Binary Methods 与 Double Dispatch

## Problem

`eval` 对 `Add` 只做一件事：求出两个子表达式，再把两个**值**加起来。值现在有三种：`Int`、`String`、`Rational`。加法的定义依赖两个操作数的种类：

```text
              Int          String         Rational
Int           数值加       数字转字符串   整数加进有理数
String        拼接         拼接           有理数转字符串再拼
Rational      与 Int+Rat 交换  拼接，顺序不同   分数加法
```

九个格子都要有代码。这叫 binary method / binary operation：参数里有两个“我们正在定义的那种数据”。两个已经够难。

`[Course]` 函数式分解处理这张小表很自然。面向对象要么放弃纯 OOP，要么用一个更绕的惯用法。作业要求后者，并明确禁止前者。

Source: Section 9 — Binary Methods / 0:05–2:05；Double Dispatch / 3:48–4:09。

## 函数式：九个 case 放在一起

`add` 的 eval 递归求值两个子表达式，然后调用 helper `add_values`。`mult` 仍可以在不是两个 `Int` 时抛异常。加法不允许再抛，因为三种值的任意组合都有定义。

```sml
fun add_values (v1, v2) =
  case (v1, v2) of
      (Int i, Int j) => Int (i + j)
    | (Int i, String s) => String (Int.toString i ^ s)
    | (Int i, Rational (j, k)) => Rational (i * k + j, k)  (* 课堂不要求约分 *)
    | (String s, Int i) => (* 拼接，顺序与上一格不同 *)
    | (String s1, String s2) => (* 拼接 *)
    | (String s, Rational _) => (* 先把有理数变成字符串 *)
    | (Rational _, Int _) => add_values (v2, v1)  (* 可交换，不要复制 *)
    | (Rational _, String _) => (* 不能复用 String+Rational，顺序不同 *)
    | (Rational _, Rational _) => (* a/b + c/d *)
    | _ => raise Bad   (* 类型系统不知道 v 一定是这三种值 *)
```

对 pair 做模式匹配，九格排在一个函数里，读得见。可交换的格子递归到对面，减少复制。老师说作业里这种可交换的情况可能更多。`Rational + String` 不可交换，不能这么做。

他明确说：这段比下一讲的 OOP 分解更自然、更不别扭。

Source: Section 9 — Binary Methods / 3:16–7:13。

## 面向对象的第一反应是半吊子

`Add#eval` 不调用外部函数。OOP 风格是让值自己知道怎么加：

```ruby
def eval
  e1.eval.add_values(e2.eval)
end
```

第一次分派是真的 OOP：`e1.eval` 是 `Int`、`MyString` 还是 `MyRational`，决定进哪个 `add_values`。Ruby 的标准库已经有 `String` 和 `Rational`，所以课程把自己的类叫 `MyString`、`MyRational`。

然后 `Int#add_values` 拿到 `v`，却发现下一步取决于 `v` 是哪一种。你当然可以写：

```ruby
def add_values(v)
  if v.is_a? Int
    Int.new(v.i + i)
  elsif v.is_a? MyRational
    # ...
  else
    # 假定是 MyString
  end
end
```

三个 class 各三个分支，九格还在。老师说作为编程风格他不见得讨厌它。他拒绝的是把它叫做面向对象：前一半用 dynamic dispatch 选 `add_values`，后一半用 `cond` 问另一个对象的 class，那是 Racket 式分支。要么九格像 ML 那样放在一起，要么做完整的 OOP。作业不许用 `is_a?` 这条路，理由是太容易，也不够 OOP。

Source: Section 9 — Double Dispatch / 2:22–5:52。

## 为什么不能 `v.add_values(self)`

OOP 的纪律是：不要问 `v` 是什么，向 `v` 发消息，让不同种类实现得不同。

若 `add_values` 里再调用 `v.add_values(self)`，对方也会这样做。无限递归。

你需要发的消息能够告诉 `v`：“我是 Int”或“我是 MyString”。这个信息在写 `Int#add_values` 时是知道的，因为 self 的 class 就是 Int。于是不同的 class 调用**不同名字**的方法。这就是 double dispatch。老师说他不期望你自己发明它，但它能工作。

Source: Section 9 — Double Dispatch / 6:00–7:22。

## 调用链

三个值类都实现 `add_values`，以及 `addInt`、`addString`、`addRational`。3 × 3 = 9，九格各是一个方法。

```text
Add#eval
    e1.eval.add_values(e2.eval)
            │
            │  第一次分派：看左边的值的 class
            ▼
    Int#add_values(v)          →  v.addInt(self)
    MyString#add_values(v)     →  v.addString(self)
    MyRational#add_values(v)   →  v.addRational(self)
            │
            │  第二次分派：看右边的值的 class
            │  方法名已经编码了左边是谁
            ▼
    九个方法中的一个
    例如 Int 收到 addString：我是 Int，对方是 String
         拼接时 self 在右边，因为第一次是对左操作数发的 add_values
```

顺序容易反。`Add` 对**左**操作数调用 `add_values`，左操作数再对**右**操作数调用 `addInt` / `addString` / `addRational`，并把 self 传过去。所以在 `addString` 的方法体里，self 是右边那个。字符串拼接不可交换，顺序写反就错。

```text
x.add_values(y)                 # x 是 Int，y 是 MyString
      ↓
dispatch on x → Int#add_values
      ↓
y.addInt(x)
      ↓
dispatch on y → MyString#addInt
      ↓
结果字符串 = x 转成的字符串 + y 的字符串
```

课堂用的名字是 `addInt` 而不是 `intersectCircle`。几何里的 Circle × Rectangle 是同一结构，`[Supplement]` 不是这一讲的例子：

```text
circle.intersect(other)
    → other.intersectCircle(circle)
    → 按 other 的 class 选 Rectangle#intersectCircle 或 Circle#intersectCircle
```

Source: Section 9 — Double Dispatch / 7:22–12:41。

## Java 版为什么更好读（可选）

`[Course]` Java 里 `Value` 必须声明这些方法。`add_values` 的参数类型是 `Value`。`addInt` 的参数类型是 `Int`。类型把“这个方法只会被 Int 调用”写在签名上。Ruby 里这只是约定：只有 `Int#add_values` 会调用 `addInt`。懂 Java 的话，先看类型再看方法体，惯用法会清楚一些。逻辑和 Ruby 相同。

Source: Section 9 — Double Dispatch / 13:48–14:44。

## 老师为什么要你写这么别扭的代码

三句话，都是 `[Course]`：

1. 有点是为了给“必须全用 OOP”降温。他觉得九个放在一起的 ML case 更简单。若你坚持 OOP，这就是 OOP 的代价。
2. 为了逼你真的理解 dynamic dispatch 和方法查找。这个惯用法里，你必须想清楚两次查找各从谁的 class 开始。
3. 下一讲（可选）会给你看：语言若有 multimethods，就不用手写这个技巧。

Source: Section 9 — Double Dispatch / 13:03–13:48。

## Visitor 只在这里提一句

`[Supplement]` Visitor 常被实现成 double dispatch，但是课程里的 visitor 解决的是“给所有行加一个新操作”，double dispatch 解决的是“一个操作的两个参数都要参与选择”。目的不同。都用了“再发一次消息，让另一个对象按自己的 class 选代码”。不要记成同义词。

## Concept cards

### binary method

- Problem: 操作的正确代码依赖两个参数各自的运行时种类，不是一个。
- Definition: `[Course]` 取两个“我们正在定义的数据”的操作。Int/String/Rational 的加法有九种组合。
- Mental model: 表里的一列内部又有一张方表。
- Example: `add_values`。
- Misunderstanding: 不是“方法有两个参数”就叫 binary method。`eval` 的 helper 若第二个参数只是整数，没有这张方表。

### double dispatch

- Problem: 单次 dynamic dispatch 只看 receiver。第二个对象的种类仍要用 `is_a?` 去问，那就退出了 OOP。
- Definition: `[Course]` receiver 根据**自己是谁**，向另一个对象发送不同名字的消息，并把自己传回去。第二次查找按另一个对象的 class 进行。两次查找合起来选定九格中的一格。
- Mental model: 方法名携带第一次分派的结果。
- Example: `Int#add_values` 只做 `v.addInt(self)`。
- Runtime: 见上面的调用链。self 在第二次方法里位于右边。
- Why it matters: 它是“Ruby 只有单分派”这一事实的直接后果，也是作业要你演示你理解了查找规则。
- Misunderstanding: 不是随便调用两个方法。两次调用有固定方向：第二次的方法名编码第一次的 receiver 种类，参数是第一次的 receiver。也不是 multimethod：语言没有按两个参数自动选一个 `add_values`。
- Related: dynamic dispatch, binary method, multimethod, visitor。
