# Section 8 — 练习

覆盖对象、状态、可见性、duck typing、块与 Proc、子类化、方法查找、动态派发与闭包的对照。先做题，再看文末 Answer Key。

## Concept Questions

1. 为什么这一节放到闭包和词法作用域之后，而不是课程一开始就讲类？
2. `z = x` 之后 `z.m2(17)` 为什么会改变 `x.foo`？若语言没有 mutation，这个程序还能不能把“共享”和“拷贝”区分开？
3. 实例变量为什么连同类的另一个实例也不能直接读？`MyRational#add!` 为什么因此需要 `protected` 而不是 `private` 或 `public`？
4. `e.foo = 3` 是赋值还是方法调用？`attr_accessor` 有没有把 `@foo` 变成 public？
5. Duck typing 和“用 `is_a?` 分支”各放弃了什么？为什么 `double` 里把 `x + x` 改成 `x * 2` 在数字上等价，在 duck typing 下不是同一契约？
6. 块为什么是二等的？递归方法要把同一块传给下一次调用，为什么必须写 `{ |i| yield(i) }`，而不能像 ML 那样把函数参数原样传下去？
7. `ColorPoint` 内嵌一个 `Point` 再转发，和 `class ColorPoint < Point` 相比，客户能观察到的差别是什么？什么时候他反而认为不该子类化？
8. `PolarPoint` 为什么必须覆盖 `distFromOrigin`，却可以不覆盖 `distFromOrigin2`？若查找规则把 `self` 绑成“定义该方法的类”的实例，第二个方法还会对吗？
9. ML 里后来的 `fun even x = false` 为什么不改变已经定义的 `odd`？Ruby 里 `C#even` 为什么会让 `A#odd` 返回错误答案？这是环境被修改了，还是根本没查那个环境？
10. 用 Racket 编码派发时，为什么覆盖方法必须放在方法表的前面？若 `send` 调用 lambda 时不传入对象，得到的是派发还是词法闭包？

## Code Reasoning

### A

```ruby
class A
  def initialize
    @n = 0
  end
  def inc(x)
    @n += x
  end
  def n
    @n
  end
end

x = A.new
y = A.new
z = x
x.inc(3)
z.inc(4)
y.inc(10)
```

`x.n`、`y.n`、`z.n` 各是多少？若在 `initialize` 之前就调用 `inc`，失败发生在“没有这个字段”，还是发生在向某个值发消息？

### B

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
end

pp = PolarPoint.new(4, 0)
```

`pp.distFromOrigin` 的查找在哪个类停住，结果是多少？`pp.distFromOrigin2` 的方法体来自哪个类，`self.x` 又在哪个类停住？`pp.distFromOrigin` 若删掉 `PolarPoint` 里的定义，求值会怎样？

### C

```sml
fun even x = if x = 0 then true else odd (x - 1)
and odd x = if x = 0 then false else even (x - 1)
val a = odd 3
fun even x = false
val b = odd 3
```

```ruby
class A
  def even(x)
    if x == 0 then true else self.odd(x - 1) end
  end
  def odd(x)
    if x == 0 then false else self.even(x - 1) end
  end
end
class C < A
  def even(x)
    false
  end
end
a = A.new.odd(3)
c = C.new.odd(3)
```

`a`（ML）和 `b`（ML）各是什么？Ruby 的 `a` 和 `c` 各是什么？用环境和 `self` 说明差别出在哪一步。

### D

```ruby
def foo(a)
  a.count { |x| x * x < 50 }
end
```

`foo([3, 5, 7, 9])` 和 `foo(3..9)` 各是多少？若 `foo` 开头写成“不是 Array 就拒绝”，第二个调用怎样？这是子类化在起作用，还是 duck typing？

### E

```ruby
i = 7
[4, 6, 8].each { |x| print (x + 1) if i > x }
```

打印什么？自由变量 `i` 在哪里查找？若块是动态作用域，而 `each` 的实现里碰巧有另一个 `i`，结果还能否只靠调用点确定？

---

## Answer Key

### Concepts

1. 没有词法闭包作为对照，方法调用只是 `obj.method()` 的语法。放在后面，才能看见派发比闭包多出来的那条规则：`self` 是接收者，查找在每次调用时从接收者的类开始。OOP 不是更高级的函数式，是另一套查找。
2. `z = x` 复制的是引用，两个名字指向同一对象。`m2` 修改的是对象上的 `@foo`。没有 mutation 时，共享和拷贝对客户不可区分，这个实验问不出。
3. 字段若能被任何持有者或任何同类实例读到，表示就藏不住，ML signature 那条边界就没有了。`add!` 要读另一个有理数的分子分母，所以不能是 private。Public 则外部客户能破坏“分母非 0、已约分”。Protected 允许同类的其他实例，不允许外部客户。
4. 是对 `foo=` 的方法调用，是糖。`attr_accessor` 定义 getter 和 setter 方法，不把实例变量公开。外面仍然不能写 `e.@foo`。
5. 类测试放弃“能完成工作的非 Point”。Duck typing 放弃“可以换一串消息而不改变客户可见行为”的等价，因为客户可以依赖你实际发送的消息。`+` 和 `*` 对数字一样，对只定义了 `+` 的字符串或 `MyRational` 不一样。
6. 块不是表达式，不能作为计算结果，也不能被命名后传走。递归调用不会自动带上当前块。唯一能做的是新写一块，在其中 `yield` 到原来的块。ML 的函数参数是值，原样传递即可。
7. 子类版本 `is_a?(Point)` 为真，并免费得到未覆盖的方法，包括那些通过 `self` 派发的方法。内嵌版本是 has-a，`is_a?(Point)` 为假，转发要手写。当关系不是“是一种”，或你需要隐藏、重命名、避免继承钩子时，他要你内嵌，而不是出于方便去子类化。重开别人的 `Point` 则破坏模块边界。
8. `distFromOrigin` 读 `@x` / `@y`。极坐标对象没有这些字段，读到 `nil`，乘法失败，所以必须覆盖。`distFromOrigin2` 调用 `self.x` / `self.y`，查找从 `PolarPoint` 开始，命中计算直角坐标的 getter。若 `self` 被绑成 Point 的实例，会去调 `Point#x`，读缺失字段，派发消失，结果不再正确。
9. ML 的 `a` 和 `b` 都是 `true`。`odd` 的闭包里 `even` 指向互递归环境中的第一个函数。后来的 `fun even` 是新绑定，旧闭包不查它。Ruby 的 `a` 是 `true`（`A#even`）。`c` 是 `false`：`A#odd` 运行时 `self` 是 `C` 的实例，`self.even` 找到 `C#even`。不是 ML 环境被修改，而是方法查找从未使用那个词法环境。
10. `assoc` 取第一个匹配。覆盖放在前面才遮住 `Point` 的 `get-x`。放在尾巴上，继承来的 `distToOrigin` 仍会找到旧 getter。不传入对象，lambda 没有接收者可再 `send`，getter 若被词法地关进 `make-point`，覆盖就影响不了它。那就是关上的闭包。

### Code

A. `x.n` 是 `7`，`z.n` 是 `7`，`y.n` 是 `10`。`x` 与 `z` 别名。没有 `initialize` 就 `inc`：`@n` 读出来是 `nil`，失败发生在向 `nil` 发送 `+`，不是“未定义字段”这一条独立错误。

B. `pp.distFromOrigin` 在 `PolarPoint` 停住，结果 `4`。`pp.distFromOrigin2` 的体来自 `Point`（子类没定义），`self` 仍是 `pp`，`self.x` 在 `PolarPoint` 停住，算出 `4 * cos(0) = 4`，`y` 为 `0`，距离 `4.0`。删掉子类的 `distFromOrigin` 后，使用 `Point` 的体，读 `@x` / `@y` 得到 `nil`，向 `nil` 发 `*`，运行时错误。

C. 见概念题 9。ML 两次都是 `true`。Ruby 的 `A.new.odd(3)` 为 `true`，`C.new.odd(3)` 为 `false`。差别在 `self.even(2)` 那一步：ML 使用闭包环境里的 `even`；Ruby 从接收者的类重新查找。

D. 数组：`9, 25, 49` 小于 `50`，`81` 不是，结果 `3`。范围 `3..9`：`3` 到 `7` 的平方小于 `50`，`8` 和 `9` 不是，结果 `5`。拒绝非 Array 则第二个调用失败。这里没有人让 Range 成为 Array 的子类。起作用的是两者都有 `count` 并能接受一块。那是 duck typing。

E. 打印 `5` 和 `7`。`8` 不打印，因为块里的 `i` 是调用点的 `7`。查找在块写下的词法环境，不在 `each` 的方法体。动态作用域下，结果取决于 `each` 实现里有没有同名 `i`，不能只靠调用点确定。这就是他明确要求块使用词法作用域的原因。
