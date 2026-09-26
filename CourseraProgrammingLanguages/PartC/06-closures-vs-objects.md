# Module 6 — Dynamic Dispatch 与闭包

## Problem

闭包和对象看起来都能说成“一段代码，加上只有它能碰的数据”。如果它们一样，OOP 就只是语法。老师要你看见不一样的那一条规则，以及这条规则带来的软件设计交换。

```text
Closure                         Object
代码 + captured environment      方法们 + 对象状态
调用的是这份函数值               调用的是“向这个 receiver 发 m”
环境在造出闭包时固定             self.m 在调用时才查找
```

Source: Section 8 — Overriding and Dynamic Dispatch / 4:01–5:11；Dynamic Dispatch Versus Closures / 9:21–9:34。

## ML：递归在定义时关闭

课堂例子是两个互相递归的函数，只对非负整数有意义。重建：

```sml
fun even x = (print "in even ";
              if x = 0 then true else odd (x - 1))
and odd x = (print "in odd ";
             if x = 0 then false else even (x - 1))

val a1 = odd 7
(* 打印 8 次，a1 = true *)

fun even x = x mod 2 = 0     (* 遮蔽上面的 even *)
val a2 = odd 7               (* 行为不变 *)

fun even x = false
val a3 = odd 7               (* 仍然不变，仍然 true *)
```

`odd` 被创建时，它体内的 `even` 按词法作用域指向同时定义的那个 `even`。后面的 `fun even` 只是遮蔽名字。调用旧的 `odd`，走的仍是旧环境。闭包是 closed 的：造好之后，外面再绑定同名函数，影响不到它。

这有时令人失望：有人写出了更快的 `even`，旧的 `odd` 不会自动变快，即便新作者根本不知道 `odd` 在用 `even`。

这也是好事：第三个人把 `even` 写成总返回 `false`，旧的 `odd` 不会被破坏。你可以孤立地阅读 `odd` 的定义，知道它的行为。

Source: Section 8 — Dynamic Dispatch Versus Closures / 0:19–3:36。

## Ruby：同名方法在子类里仍开放

```ruby
class A
  def even(x)
    puts "in even"
    if x == 0 then true else odd(x - 1) end
  end
  def odd(x)
    puts "in odd"
    if x == 0 then false else even(x - 1) end
  end
end

class B < A
  def even(x)
    x % 2 == 0          # 更快，而且对
  end
end

class C < A
  def even(x)
    false               # 错
  end
end

A.new.odd(7)   # 8 次打印，true
B.new.odd(7)   # odd 打印一次，even 用 B 的版本，立刻 true
C.new.odd(7)   # 同样动态分派，得到 false
```

`B` 没有重写 `odd`。它继承 `A#odd`。`A#odd` 里的 `even(x-1)` 是向 self 发消息。self 的 class 是 `B` 时，查到 `B#even`。这是机会：改 even 就改了 odd，不用复制 odd，甚至不用原来的作者预料到你会换算法。

`C` 说明同一条规则是危险的。`odd` 的正确性依赖 even 的含义。子类可以在不改 `odd` 源码的情况下让 `odd` 变错。

Source: Section 8 — Dynamic Dispatch Versus Closures / 3:36–6:44。

### 执行跟踪：`B.new.odd(7)`

```text
receiver class = B
B 没有 odd → A#odd
self = 那个 B 对象
打印 "in odd"
调用 even(6)，即 self.even(6)
    从 B 查找 even → B#even
    self 仍是那个 B 对象
    6 % 2 == 0 → true
不再递归
```

`A.new.odd(7)` 的第二次查找从 `A` 开始，找到 `A#even`，然后 even 再调 odd，来回直到 0。

## 设计交换

`[Course]`

若一个方法调用了可能被覆盖的其他方法，则它的行为在子类里可以变。

- 想要：子类不复制代码就能影响父类方法。库作者没改 `odd`，你仍能加速它。
- 代价：不能再只看 `odd` 的源码就知道它做什么。推理要加上“所有子类可能覆盖 even”。
- 更脆：这个技巧依赖 `odd` **确实**调用了 `even`。库作者若改成直接算，你的子类悄悄失效。复用和滥用是同一机制的两种结果，看情境。

想恢复“像闭包那样关闭”：

- Ruby：private。子类不能用那种调用形式去用它。老师说这**可能**有帮助。
- Java：`final` 禁止覆盖。是否好风格，常有争论。更不 OOP，但更好局部推理，某些意义上更模块化。

Source: Section 8 — Dynamic Dispatch Versus Closures / 6:46–9:21。

`[Inference]` private 在 Ruby 里禁止的是“带显式 receiver 的调用”，包括子类里写 `self.even`。它并不能从物理上删除子类覆盖父类 public 方法的能力。老师的建议是方向性的：用可见性缩小可覆盖表面。不要把它读成“private 方法在语义上等于 ML 闭包”。

## 它们仍能表达相似的抽象

两边都能做“缺少的那一块由别人填”。

| 你想延迟决定的东西 | 函数式做法 | 面向对象做法 |
| --- | --- | --- |
| 遍历时对每个元素做什么 | 传一个函数 / block | 传一个懂 `each` 或实现某方法的对象 |
| 公共算法里的一步 | 高阶函数的参数 `g` | 父类调用 `self.m2`，子类覆盖 `m2` |
| 一种数据的一种操作 | datatype 的一个分支 | 子类的一个方法 |

`[Course]` 抽象方法那一讲把最后一行说得很直：superclass 的 `m1` 调用 `m2`，但自己不定义 `m2`，子类提供代码。函数 `f` 调用参数 `g`，调用者提供代码。公共部分在 `m1` / `f`，变化的部分由子类或调用者填。见 `12`。

所以“闭包和对象都能打包行为”是对的。不对的是因此以为调用规则相同。

## 三个语言的小例子

同一意图：一个点，问它到原点的距离。变化的是表示法。

### Ruby `[Course]`

```ruby
class Point
  def distFromOrigin2
    Math.sqrt(x * x + y * y)   # 动态查找 x、y
  end
end
class PolarPoint < Point
  def x; @r * Math.cos(@theta); end
  def y; @r * Math.sin(@theta); end
end
```

### Racket：手动把 dispatch 写出来 `[Course]` 可选讲

不用 Racket 自带的 class。对象是一个 struct：字段列表 + 方法列表。方法是 Racket 函数，但**多一个参数**，实现者把它叫 `self`。这个名字不特殊，叫 `foo` 也行。

`send` 的关键一行：找到 lambda 之后，把**整个对象**作为第一个参数传进去。

```racket
;; 概念重建，不是课堂源文件的逐字拷贝
(define (send obj msg . args)
  (let ([pr (assoc msg (object-methods obj))])
    (if pr
        (apply (cdr pr) obj args)   ; obj 成为 self
        (error "no method"))))
```

`distToOrigin` 的 lambda 写 `(send self 'get-x)`。若这个对象的方法表前面放着 polar 版本的 `get-x`（`assoc` 从前往后，先找到的赢，这就是覆盖），父类那份 lambda 就会调到新的 getter。dynamic dispatch 的全部秘密，在这个编码里就是“多传的那个参数被绑成整个对象”。

没有 class 也能做出 dispatch。class 是组织方法表的一种办法，不是 dispatch 的定义。

ML 不适合做这个练习。缺 subtyping，`distToOrigin` 想要的那个“self 可以是 point 也可以是 polar-point”的类型不好写。不是不可能（例如所有对象都用一个大 datatype），而是类型系统不友好。所以 OCaml、F# 把对象做成语言自己的东西。Scala 也是。

对称的历史事实：Java 在泛型加入之前，对 ML 那种带函数闭包的多态代码同样不友好。类型系统会偏向某一种编程风格，同时把那种风格支持得很好。

Source: Section 8 — Dynamic Dispatch Manually in Racket / 0:15–3:18，6:32–7:45，12:02–15:28。

### ML：用闭包模拟“一个点” `[Supplement]`

课程没有要求这个方向的编码（老师在 Part A 可选材料里做过“用 Java/C 模拟闭包”，这里是反过来）。最短的对应是：

```sml
fun make_point x y =
  let
    fun dist () = Math.sqrt (x * x + y * y)
  in
    { dist = dist }
  end
```

`dist` 捕获 `x`、`y`。你不能事后把 `x` 的含义换成“由 r 和 theta 计算”，除非你在造闭包时就把那种计算传进去。没有一张开放的方法表。这不是课堂例子，只是为了把对照做完。

## 结构对应，语义不同

| FP | OOP | 对应到哪一步就停 |
| --- | --- | --- |
| closure | object | 都是代码加私有数据 |
| captured env | instance fields | 都是外界不该直接拆的状态 |
| function call | method call | **停。** 一个按函数值，一个按 receiver |
| datatype 变体 | subclass | 都是“一种数据的一种情况” |
| pattern match | dynamic dispatch | 都是按情况选代码；一个看构造子，一个看 class 链 |

老师在分解方式那一周会说这两种切法相反到几乎相同。那是关于**代码怎么摆**。这一讲是关于**调用怎么发生**。两件事都要记住，不要合成一句“所以 FP 就是 OOP”。

## Concept card

### closure dispatch vs dynamic method dispatch

- Problem: 两种“打包的行为”被调用时，谁来决定代码？
- Definition: 闭包调用执行函数值里的代码，环境是定义时的。动态分派执行查找结果，`self` 是这次的 receiver。
- Mental model: 闭包关闭；对象的方法调用保持开放。
- Example: ML 里遮蔽 `even` 不影响旧 `odd`；Ruby 里子类 `even` 影响继承来的 `odd`。
- Why it matters: 开放带来不改旧码的扩展，也带来不能局部推理。
- Misunderstanding: “对象就是闭包”只在你不用 self 回调可覆盖方法时近似成立。`PolarPoint` 和 `B#even` 就是近似失败的地方。
