# Section 9 — 练习

先做题，再看文末 Answer Key。标了不确定的算术不要当成唯一标准答案。题目问的是切法、派发和复用。

## Concept Questions

1. 为什么“FP 与 OOP 相反”并不意味着它们在做不同的事？用 `eval` / `toString` / `hasZero` 对 `Int` / `Negate` / `Add` 说明行和列。
2. ML 在子表达式求值结果不是 `Int` 时抛异常，Ruby 对结果发 `.i`。这是分解方式的差别，还是另一根轴？
3. 不事先计划时，哪种扩展在函数式里是局部的，哪种在 OOP 里是局部的？OOP 的那根局部轴依赖什么运行时规则？若 `Add#eval` 改成按类做 `if`，这根轴还在吗？
4. `noNegConstants` 是谓词吗？它的类型是什么？加这个操作时，ML 要改哪些旧函数，Ruby 要改哪些旧类？
5. 为什么把 datatype 藏进 ML module、或把 Java 方法标成 `final`，可以是特性而不是缺陷？可扩展伤害了关于 `eval` 的哪一种推理？
6. 加法在三种值上为什么不是 `eval` 表里的一格？`Mult` 和 `Add` 都是二元运算符，为什么一个可以在非整数上抛异常，另一个被他故意改成不抛？
7. `add_values (Rational _, Int _) = add_values (v2, v1)` 为什么不是无限递归？什么改动会让它打错格子？
8. 为什么作业禁止 `is_a?`，即使九格都算对？`v.add_values(self)` 和 `v.addInt(self)` 差在哪一次派发？
9. 在 `Int#addString` 里，`self` 是左边还是右边？为什么字符串格子会暴露写反，而整数加法不会？
10. Java 里两个都叫 `add` 的方法，为什么不是 multimethod？C# 的 `dynamic` 改变的是哪一半？
11. `ColorPt3D` 和 `ArtistCowboy` 对“祖先字段有几份”要的答案为什么相反？只给 Ruby 加第二个超类槽、不给字段规则，解决了什么，没解决什么？
12. Mixin 和 ML signature 都常被叫成 module。它们各隐藏或复用什么？`Enumerable#count` 为什么可以不读 `@low`？
13. Interface 为什么不该被说成“安全的多重继承”？为什么 Grossman 认为 Ruby 不该加入 interface，C++ 也可以不把 interface 做成单独特性？
14. Abstract method 比“超类里抛异常”多了哪一种能力，没多哪一种？它和高阶函数，谁来提供未知代码？

## Code Reasoning

### A

```sml
datatype exp = Int of int | Negate of exp | Add of exp * exp

fun eval e =
    case e of
        Int _ => e
      | Negate e1 =>
          (case eval e1 of
               Int i => Int (~ i)
             | _ => raise Fail "not an int")
      | Add (e1, e2) =>
          (case (eval e1, eval e2) of
               (Int i, Int j) => Int (i + j)
             | _ => raise Fail "not ints")
```

现有操作还有已经写好的 `toString` 和 `hasZero`。三个函数都对三种构造子穷尽匹配，没有通配。

1. 只增加 `noNegConstants : exp -> exp`，要改几个旧函数？
2. 再增加构造子 `Mult of exp * exp`，重新编译且先不改函数。类型检查器会对哪些函数抱怨？
3. 若当初每个 `case` 都有 `| _ => raise Fail "todo"`，第 2 问的清单还在吗？运行到 `Mult` 时发生什么？

### B

`Int` 有第 1 讲的 `toString`。下面只摘双派发相关的方法。

```ruby
class Int
  def add_values(v)
    v.addInt(self)
  end
  def addInt(v)
    Int.new(v.i + i)
  end
  def addString(v)
    MyString.new(v.s + i.to_s)
  end
end

class MyString
  def add_values(v)
    v.addString(self)
  end
  def addInt(v)
    MyString.new(v.toString + s)
  end
  def addString(v)
    MyString.new(v.s + s)
  end
end

class Add
  def eval
    e1.eval.add_values(e2.eval)
  end
end
```

`e1.eval` 是 `Int`，`i` 为 `3`。`e2.eval` 是 `MyString`，`s` 为 `"x"`。

1. `Add#eval` 的两次发送，接收者的类和方法名各是什么？
2. 结果是什么对象，里面的字符串是什么？
3. `Int#addString` 会不会在这个输入上运行？什么输入会运行它？
4. 若把 `Int#add_values` 改成 `v.add_values(self)`，求值会怎样？

### C

```ruby
module Enumerable
  def count
    n = 0
    each { |x| n += 1 if yield x }
    n
  end
end

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

r = MyRange.new(3, 7)
```

`r.count { |x| x.odd? }` 的值是多少？`count` 查找时来自哪里？它读 `@low` 吗？若 `MyRange` 没有 `each`，失败发生在 `include` 时还是调用 `count` 时？

### D

```java
interface Example {
  void m1(int a, int b);
}
class A implements Example {
  public void m1(int a, int b) { }
}
class B implements Example {
  public void m1(int a, int b) { }
}
void f(Example e) { e.m1(1, 2); }
```

`f(new A())` 为什么在静态类型上合法？`f` 的方法体知道运行时类吗？若 `B` 漏写 `m1`，失败在何时？这和 Ruby mixin 的宿主漏了被回调的方法，失败时间有何不同？

---

## Answer Key

### Concepts

1. 三种操作是三列，三种表达式是三行。函数式一个函数填一列。OOP 一个类填一行。格子可以相同。排版相反，所以扩展时痛的方向相反。这是课程后半的 punch line，不是口味口号。
2. 另一根轴：检查发生在运行前还是运行时。行切还是列切是分解轴。ML 的异常分支对 Ruby 的 `.i`，是静态对动态，不是 FP 对 OOP。
3. 函数式白送新操作。OOP 白送新 variant，因为旧方法向子表达式发消息，动态派发选中新类。若 `Add#eval` 按类做 `if`，新类不会被旧代码接住，这根轴不再白送。
4. 不是谓词。他口误后纠正：类型是 `exp -> exp`，把负常量重写成 `Negate` 包一个正常量。ML 不改旧函数。Ruby 要在每个已有类上加方法。
5. 它们禁止客户在你没承诺的轴上扩展，从而保住局部推理。一旦未知子类都能定义 `eval`，只读 `Int` / `Add` / `Negate` 不再足以理解求值。Ruby 没有对应的阻止手段。
6. 三种值两两相加是 9 格，嵌在 `eval` 的 Add 这一行里面。`Mult` 仍只在两个 `Int` 上有定义。`Add` 被故意改成在三种值上都有格子。同一种二元语法不强迫同一种定义域。
7. 交换后的一对匹配 `Int + Rational` 那一支，那一支不递归，所以不是循环。若那一支改成通配，交换调用会打中通配，而不是对面的算术格子。字符串与有理数的拼接不能用这一招，因为顺序是语义的一部分。
8. `is_a?` 的第二刀是条件，不是消息。他可以接受这是一种编程风格，拒绝把它叫成这一课承诺的 OOP。`add_values` 发回自己：左边调用右边，右边用同一个名字调用回来。`addInt` 是另一个名字，第二次派发按右边的类选择，左边的类编码在名字里。
9. `self` 是右边。`addString` 只有从 `MyString#add_values` 发出，接收者才是右边那个值，参数才是左边的 `MyString`。拼接不可交换，顺序写反会得到不同字符串。整数加法可交换，同一类 bug 被藏住。
10. 重载用参数的静态类型在编译期选择。非接收者的运行时类不参与。接收者仍是普通动态派发。`dynamic` 把参数一侧的选择推到运行时，从而模拟多重派发。它不是“这些语言的重载本来就是 multimethod”。Clojure 那一类语言才是调用规则本身看所有运行时类。
11. 三维彩色点只要一套坐标。艺术家牛仔要两个口袋，否则画笔和枪混在一起。没有一般解。第二个超类槽只让你写下愿望。哪份 `distToOrigin` 赢、`x` 有几份，仍没有规则。C++ 用不同种类的继承区分份数。他不展示那种语法。
12. Signature 是客户可见边界，用来隐藏表示。Mixin 把方法体加进宿主，并可以回调宿主还没写在 mixin 里的方法。`count` 向 `self` 发 `each`，由 `MyRange#each` 读端点并 `yield`。Mixin 只看见 yield 出来的元素。Ruby 的 `module` 还可以做名字空间，那才靠近 ML module 的弱用法。三件事不要并成一个词。
13. Interface 不提供方法和字段，所以避开菱形问题，也没有提供多重继承要的实现复用。Ruby 没有需要被放松的静态类型系统，动态类型已经更灵活。C++ 可以把第二个超类做成全部 pure virtual：不继承代码，只为了成为子类型并被迫实现那些方法。Interface 作为单独特性，是单继承加上静态类型时的绕行。
14. 多了编译期拒绝：不能实例化缺少该方法的具体类，也给读者写下义务。运行时派发能力与“定义成抛异常”相同。语言没有变得更能表达。Abstract method 由子类提供代码，靠对 `self` 的动态派发接上。高阶函数由调用者提供代码，靠参数绑定接上。

### Code

A.

1. 零个。新函数自己对三种构造子做 `case`。`eval`、`toString`、`hasZero` 不动。这是函数式白送的那根轴。
2. 四个都非穷尽：原来的三个，加上刚写的 `noNegConstants`。清单就是难受轴。Java 在超类声明新方法后列出未实现的子类，是同一份清单换了轴。
3. 清单消失，类型仍通过。运行到 `Mult` 时走进通配，抛 `Fail "todo"`。静态待办清单依赖第一版没有通配。

B.

1. 第一次：接收者的类是 `Int`，方法是 `add_values`，参数是右边的 `MyString`。方法体发送的是 `addInt`，不是 `addString`。第二次：接收者的类是 `MyString`，方法是 `addInt`，参数是左边那个 `Int`（当时的 `self`）。
2. `MyString`，字符串 `"3x"`。`MyString#addInt` 做 `v.toString + s`。`v` 是 `Int` 3，`s` 是右边的 `"x"`。
3. 不会。`Int#addString` 的调用点只在 `MyString#add_values` 里：`v.addString(self)`。那要求左边是 `MyString`，右边是 `Int`。那时 `self` 是右边的 `Int`，参数是左边的 `MyString`，拼接是 `v.s + i.to_s`。左右一换，字符串顺序不同。这就是翻转必须可见的原因。
4. `Int#add_values` 向右边的 `MyString` 发 `add_values`。`MyString#add_values` 再向左边的 `Int` 发 `add_values`。同一个方法名左右互调，不终止。Double dispatch 换名字，就是为了切断这个循环。

C. 值是 `3`：3、5、7。区间含端点，4 和 6 被 block 丢掉。`count` 不在 `MyRange` 里，查找落到 include 的 `Enumerable`。它不读 `@low`。`each` 读。宿主若没有 `each`，`include` 不检查。失败发生在 `count` 向 `self` 发 `each` 的时候，方法缺失。Mixin 的假设是调用时的假设，不是 include 时的类型义务。

D. `A implements Example` 使类型 `A` 成为类型 `Example` 的子类型，不必有共同的实现超类。所以 `new A()` 可以传给需要 `Example` 的参数。`f` 只知道 `e` 有 `m1(int, int)`。运行时类可以是 `A`、`B` 或别的实现者。`e.m1(1, 2)` 在运行时按对象的类派发。`B` 漏写 `m1`，Java 在编译 `B` 时拒绝。Ruby 的 `include` 不在 include 时检查宿主有没有 `+` 或 `each`。缺了，要到 mixin 方法发送那则消息时才失败。Interface 加的是编译期义务。Mixin 加的是方法体。
