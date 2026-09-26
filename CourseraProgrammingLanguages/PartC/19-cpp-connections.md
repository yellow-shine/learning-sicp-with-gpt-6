# C++ Connection

课程提到 C++ 的地方不多，而且都是对照，不是在教 C++。这一篇把那些对照写全，再补上读 C++ 时真正会碰到、但老师没讲的实现词。补的部分一律是 `[Modern Connection]` 或 `[Supplement]`。

课程原话里和 C++ 有关的：

- class-based OOP 与 Java、C# 同类，和 JavaScript 不同。Introduction to Ruby。
- Ruby mixin 有一点像 Java interface，有一点像 C++ 多重继承，并试图避开两者的一些限制。
- 实例变量在别的语言里叫 fields。
- Dynamic dispatch 的别名包括 virtual methods。C++ 是否如此，取决于方法定义的种类，但语言支持它。
- C++ 有 static overloading，没有 multimethods。
- C++ 是最著名的支持多重继承的语言，并且为“一份字段还是两份”提供不同的继承种类。课上不展示语法。
- 抽象方法在 C++ 里叫 pure virtual。因为有多重继承加 pure virtual，C++ 不需要单独的 interface 构造。
- C++ template “kind of” 同时拥有 generics 和 subtyping 的某些效果。Bounded Polymorphism 开头，没有展开。

## Dynamic dispatch ↔ virtual

```text
Ruby                         C++
e.m                          obj.m 或 p->m，若 m 是 virtual
按 receiver 的运行时类查找    按动态类型查找
self = receiver              this = 那个对象
子类同名方法替换              签名匹配的 override
继承的方法里调用 self.x       基类方法里调用 virtual x，会进派生类
```

`[Course]` 老师说多数 OOP 语言里这是默认。C++ 不是。不写 `virtual` 的成员函数按**静态类型**绑定，更接近“定义时就关闭”，也更接近他在 Java 里用 `final` 换来的局部推理：派生类可以有同名函数，但通过基类指针调用不会进派生类。

```cpp
struct Point {
    virtual double dist() const { return std::sqrt(x() * x() + y() * y()); }
    virtual double x() const { return x_; }
    virtual double y() const { return y_; }
    double x_, y_;
};
struct Polar : Point {
    double x() const override { return r_ * std::cos(th_); }
    double y() const override { return r_ * std::sin(th_); }
    double r_, th_;
};
```

`Polar` 没有覆盖 `dist`。通过 `Point*` 指向 `Polar` 时，若 `x`/`y` 是 virtual，`dist` 会进 `Polar` 的版本。这就是 `distFromOrigin2`。若 `x` 不是 virtual，`dist` 永远调用 `Point::x`，polar 的表示就被忽略。Ruby 没有这个开关，方法调用默认是动态的。

`override` 是编译器检查“你确实覆盖了某个 virtual”，不是新的分派规则。写错签名会在 C++ 里变成一个新函数，也就是 hiding，不是 overriding。这和课程说的 Java 规则同一家族：签名不同就不是覆盖。Ruby 没有静态类型，同名就是覆盖。

Source: Section 8 — Method Lookup / 7:17–7:32；Section 10 — Subtyping for OOP / 5:09–5:28。C++ 代码是 `[Modern Connection]`。

### vtable

`[Supplement]` 课堂没讲。C++ 实现 virtual 的常见办法是：每个有 virtual 函数的对象带一个指向 vtable 的指针，vtable 是一张函数指针表。调用 virtual 函数是“从对象取出表，按槽位间接调用”。这就是 dynamic dispatch 的一种实现，不是另一个概念。

它解释了几个课程里的语义事实为什么在 C++ 里要花钱：

- 查找不能在编译期完全擦掉，除非编译器能证明动态类型就是静态类型。
- 对象不是“只有字段”。至少多一个隐藏指针。
- 多继承让表更复杂。老师说多继承让高效实现更难，没有讲具体布局。

Ruby 的方法表是可以在运行时改的。C++ 的 vtable 在编译期生成。所以 Ruby 还有“旧对象看不看得到新方法”这个 C++ 不问的问题。见 `01`。

## Subclassing ↔ inheritance

```text
class ColorPoint < Point     class ColorPoint : public Point
super(a, b)                  Point(a, b) 在初始化列表里
is_a? Point                  dynamic_cast，或依赖公有继承的隐式转换
```

`[Modern Connection]` C++ 的公有继承同时被用来做两件事：复用实现，以及允许把派生类指针隐式转成基类指针。这就是“subclass 被当成 subtype”。私有继承只复用实现，不提供那个转换。课程没有讲 private inheritance。它说明 C++ 试图把课程里拆开的两件事（代码复用、能否替换）用不同的继承方式分开。用得少，但和“subclassing ≠ subtyping”是同一担忧。

三维点当二维点的子类，在 C++ 里同样有风格争议。类型系统只会问你是否公有继承，不会问距离函数的含义是否还是二维的。

字段：C++ 的成员在 class 定义里列出，子类对象里真的包含基类子对象。Ruby 没有这层布局。`PolarPoint` 在 Ruby 里可以根本没有 `@x`。C++ 派生类对象仍有基类的 `x_`，除非你用了别的设计。课程在 subclassing 讲里强调过这个差别。

## Mixin ↔ 多继承，以及 CRTP

课程的判断：C++ 多继承能表达 `ColorPt3D` 那种“两个类都要”，也能表达 `ArtistCowboy` 那种“同名字段要两份”。Ruby mixin 做得到前者的方法复用，做不到“两个都是 class”。

`[Modern Connection]` 想在 C++ 里要 `Enumerable` 的形状，常见有两条路：

- 多继承一个带实现的基类。得到方法，也得到课程讲过的歧义：两基类都有 `m` 时选谁，字段要几份。虚继承（virtual inheritance）是 C++ 用来合并那一份基类子对象的开关。老师说 C++ 支持不同种类，没说这个关键字。
- CRTP：`template<class T> struct Enumerable { ... static_cast<T*>(this)->each(); }`。派生类把自己当模板参数传上来。这是编译期的“self 回调”，没有运行时方法表。它像 mixin 的目的（我提供 `count`，你提供 `each`），语义是静态多态，不是 Ruby 的 include。只有在你已经理解“动态分派 vs 闭包式关闭”之后，这个对照才有帮助。否则可以忽略 CRTP。

Java default method 是另一条避开多继承的路，课程用 interface 讲了“没有代码的那一端”，没有讲 default method。`[Supplement]`

## Pure virtual ↔ abstract method

```cpp
struct Shape {
    virtual double size() const = 0;   // pure virtual
    void draw() const { /* 可以用 size() */ }
};
```

`[Course]` 这就是抽象方法。`Shape` 不能实例化。派生类不实现 `size` 也不能实例化。`draw` 调用 `size`，靠 dynamic dispatch 进派生类。运行时能力并不比“默认实现抛异常”大。多出来的是编译期拒绝。

C++ 没有 `interface` 关键字，因为你可以多继承一个全是 pure virtual 的类。那个类不提供代码，只提供“你必须实现这些，于是你可以被当成这个基类用”。课程把这说成 interface 存在的原因：单继承语言需要别的办法获得多个类型资格。

Source: Section 9 — Abstract Methods / 3:52–4:00，7:17–8:47。

## Duck typing ↔ template 的历史习惯

```cpp
template<class T>
T twice(T x) { return x + x; }
```

在 concepts 出现之前，`T` 几乎不受约束。实例化时才发现有没有 `operator+`。这和 Ruby 的 `double` 很像：契约是方法体里实际用到的操作，失败偏晚。不同之处是失败通常在编译期，不是运行到某一行。所以它不是 dynamic typing，而是滞后的静态检查。

`[Course]` 老师没有把 template 叫成 duck typing。他只在 bounded polymorphism 开头说 template kind of 同时涉及 generics 和 subtyping。上面的类比是 `[Modern Connection]`，用来记住“薄契约、晚检查”。

C++20 concepts 把约束写出来：

```cpp
template<class T>
requires std::totally_ordered<T>
const T& min(const T& a, const T& b) { return b < a ? b : a; }
```

这更接近 bounded polymorphism：不是任意 `T`，是满足一组操作的 `T`。和 Java `<T extends Comparable<T>>` 同一形状。不同的是 C++ 的约束常常是“有这些运算符”，不是“是某个基类的 subtype”。名义 subtype 和 concept 不是同一个关系。

## Dynamic polymorphism 与 static polymorphism

```text
Dynamic polymorphism
    运行时按 receiver 选代码
    C++ virtual，Ruby 方法调用，Java 实例方法
    一份机器码，通过间接调用服务多种动态类型
    可执行文件不必在编译期看见所有子类

Static polymorphism
    编译期按类型生成代码
    C++ template，Rust generic，某种意义上 ML 的多态也在编译期确定类型
    没有 vtable 那一次间接
    通常要在实例化时看见具体类型

Parametric polymorphism
    类型变量。代码对所有类型（或所有满足约束的类型）一样
    ML 'a，Java generics，C++ template 的泛型用法
    可以是静态实现的，Java 擦除则是另一种实现

Subtype polymorphism
    依赖 <: 
    C++ 公有继承 + virtual，才同时有“能转换”和“会动态分派”
    公有继承但不 virtual：有 subtype 式的转换，调用却可能静态绑定
    所以 subtype polymorphism ≠ virtual dispatch
    两者经常一起用，定义不同

Duck typing
    无静态 <: 
    Ruby/Python
    C++ template 只是晚检查，不要直接等同
```

重叠与不重叠：

- Virtual dispatch 是 dynamic polymorphism 的一种实现机制，也常用来实现 subtype polymorphism。不是所有 dynamic polymorphism 都要有名义继承（Go 的接口也是动态分派，满足关系是结构的）。
- Template 是 static polymorphism，常常提供 parametric polymorphism。它不需要 subtype 关系。
- 有 subtype 关系不一定有动态分派。C++ 非 virtual 就是例子。`[Modern Connection]`
- Duck typing 与上述静态类别都不重合。它缺少类型关系。

## 函数子类型在 C++ 里你看不到幻灯片，但规则还在

`[Modern Connection]` 覆盖 virtual 函数时，C++ 允许返回类型协变（返回指针或引用时，可以改成派生类的指针或引用）。参数类型不能逆变地覆盖；签名变了就不是同一个 virtual。这和课程描述的 Java 选择一致：理论上参数可以逆变，语言选择不允许，以免和 overloading/hiding 搅在一起。

函数指针没有自动的逆变转换。`void (*)(Dog*)` 不能当成 `void (*)(Animal*)` 用。语言在这个位置比 Section 10 的伪代码更严。更严仍然 sound。

## 不该从这门课直接搬进 C++ 的习惯

- 不要假设每个调用都是 virtual。默认不是。
- 不要重开类、在运行时加方法。没有这个语义。
- 不要用多继承模拟每一个 Ruby mixin。先问你要的是代码复用，还是第二个 subtype。要前者，有时一个成员对象（课程的内嵌 Point）更清楚。
- 不要把 `dynamic_cast` 到处当 `is_a?`。课程已经说那不是 OOP 风格，作业还禁止用它来做二元操作。
