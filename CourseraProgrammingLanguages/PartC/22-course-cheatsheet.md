# Part C Cheat Sheet

一句话定义，一个最小例子，一条警告。细节在对应笔记。

## Ruby object model

一切求值结果都是对象引用；对象有一个 class；class 的方法表决定行为。

```ruby
a = A.new
a.m1    # 求值 a，得到 receiver，再查找 m1
```

警告：`3 + 4` 是 `3.+(4)`。`nil` 是对象，并且和 `false` 一样为假。

## State 与封装

`@x` 在赋值时出现，只属于这个对象的方法。外界用 getter/setter。

```ruby
def foo=(x); @kelvin = x + 273.15; end
```

警告：`e.foo = 1` 是方法调用。从未写过的 `@x` 读出来是 `nil`，不是异常。

## Block / Proc / closure

Block 是调用旁边至多一个的代码参数，不是对象。`lambda` 把它变成 `Proc`。闭包是代码加定义时的环境。

```ruby
lambda { |y| x >= y }.call(1)
```

警告：block 不能放进数组。`yield` 在本课就是“现在调用那个 block”，不是生成器。

## Inheritance / overriding

`class B < A` 得到 A 的方法，同名则替换。`super` 调用被替换的版本。

```ruby
def initialize(a, b, c)
  super(a, b)
  @color = c
end
```

警告：Ruby 不继承“字段声明”，因为没有字段声明。`is_a?` 含祖先，`instance_of?` 不含。Subclass 不是 subtype 的定义。

## Dynamic dispatch

调用时从 receiver 的 class 沿 superclass 找方法；执行时 `self` 就是 receiver。

```ruby
pp.distFromOrigin2   # 方法体在 Point，self.x 却进 PolarPoint
```

警告：这不是 dynamic typing。查找 `@x` 不走方法链。找不到方法则 `method_missing`。

课程查找链：class，然后它的 mixins，然后 superclass，然后上一层的 mixins，直到 `Object`、`BasicObject`。不要把 `Kernel` 写进课程答案。

## Duck typing

契约是实际发送的消息，不是 class 名。

```ruby
def double(x); x + x; end
```

警告：因此 `x + x` 与 `x * 2` 不是安全的等价变换。好例子是 `each`/`count`；坏例子是随便对任何有 `x=` 的东西做 `mirror_update`。

## FP vs OOP 分解

同一张表。行是变体，列是操作。FP 一个函数一列。OOP 一个 class 一行。

```text
加列（新操作）：FP 易，OOP 要改每个 class
加行（新变体）：OOP 易，FP 要改每个函数
```

警告：方向很容易记反。Dynamic dispatch 是“加行不用改旧行”的原因。

## Double dispatch

单次分派只看 receiver。二元操作要看两个运行时种类。

```ruby
def add_values(v); v.addInt(self); end   # 写在 Int 里
```

警告：不是随便调两个方法。`v.add_values(self)` 会无限递归。第二次方法里 self 在右边。作业不许用 `is_a?` 代替。

## Multimethod

语言按多个参数的运行时 class 选同名方法。Ruby 没有。Java 的同名方法是按静态类型的 overloading。

警告：overloading 解决不了九格加法，只是允许三个方法都叫 `add`。

## Mixin / interface / abstract

Mixin：一包方法，include 进仍只有一个 superclass 的 class，方法里可以用 self。`<=>` 换来比较运算符，`each` 换来迭代器。

Interface：只有签名的类型。实现它是义务，换来 subtype。不提供代码。

Abstract / pure virtual：父类声明必须被覆盖的签名，class 不能实例化。不增加运行时能力。C++ 用全抽象类加多继承，所以不必另有 interface。

警告：mixin 不是多继承的完全替代。`Artist` 和 `Cowboy` 都该是 class。

## Subtyping

唯一新规则：`e : t1` 且 `t1 <: t2` 则 `e : t2`。合法性是替换，不是口味。

```text
width：可以丢掉字段。多字段 <: 少字段
permutation：字段顺序无关
传递、自反：关系本身需要
depth：走进字段类型。有 setter 时 unsound
```

警告：球不能因为圆心多一个 `z` 就传给会改写 `center` 的函数。三件里只能取两件：setter、depth subtyping、soundness。

## Function subtyping

```text
t3 <: t1  且  t2 <: t4
则 t1 -> t2 <: t3 -> t4
参数逆变，返回协变
```

```text
Animal -> Dog   <:   Dog -> Animal
```

警告：参数方向和“子类型更能用”的直觉相反。函数必须更不挑剔，才能替上一个更挑剔的参数位置。老师认为这是全课最反直觉的一点。

## OOP subtyping

Java/C#：subclass 蕴含 subtype，但是名义的。不声明继承就不是 subtype，即使方法都有。返回类型可协变。改参数类型通常变成 overload，不是逆变覆盖。`self`/`this` 可以协变，因为调用者不能另传。

警告：class 定义行为，type 描述接口。语言故意混用名字。

## Generics vs subtyping

```text
<T> T id(T x)         两端是同一个未知类型。不能调用 T 的方法
void f(Animal x)      可以调用 Animal 的方法。Dog 能传是因为 <:
```

警告：`Object` 字段加 downcast 不是 generics。ML 拒绝额外字段，因为没有 subtyping；绕法是把 getter 当参数传。

## Bounded polymorphism

```text
对所有 T <: Point， List<T> -> List<T>
```

```java
<T extends Point> List<T> inCircle(List<T> pts, ...)
```

警告：`List<ColorPoint>` 不是 `List<Point>`。有界泛型是另一次实例化，不是列表协变。Java 泛型可以被 cast 绕过，没有 ML 那么铁。

## 多态图

```text
                    Polymorphism
                         │
        ┌────────────────┼─────────────────┐
        │                │                 │
   Parametric         Subtype           Ad-hoc
        │                │                 │
   ML 'a, generics    OOP <:          overloading（静态）
   C++ template       virtual 常伴随   multimethod（运行时，多个参数）
        │
        └── bounded：parametric + 约束

   duck typing、structural typing 不在这三支的同一点上
   structural：仍是静态 <:，按结构不按名字
   duck：没有 <:，失败在消息发送时
```

## 闭包 vs 对象

```text
闭包：调用哪个函数在制造时固定
对象：self.m 在调用时按 receiver 查找
```

警告：因此子类可以改变继承方法的行为，也可以破坏它。Private / `final` 用来买回局部推理。
