# Section 4（模块与等价）— 练习

覆盖 `07-modules-and-equivalence.md`。先做题，再看文末 Answer Key。

## Concept Questions

1. 为什么 Grossman 说 namespace 重要但不有趣？`List.map` 与 `Tree.map` 解决了什么，又没有解决什么？
2. `structure MyMathLib = struct ... end` 之后，环境里有没有一个可以当值使用的变量 `MyMathLib`？没有的话，外部如何使用 `fact`？
3. Signature 里省略 `doubler`，和在绑定上标记 private，效果上都能让外部不能调用它。ML 的做法多出来的那一句是什么？为什么“结构里多出来的 binding”不能导致匹配失败？
4. 只把 `gcd` 和 `reduce` 排除在 signature 之外，为什么还不是 ADT？客户的哪一种表达式能让 `toString` 返回 `"9/6"`？
5. Properties 和 invariants 各举一条有理数库里的例子。为什么 `toString` 可以不调用 `reduce`，以及这依赖哪一条不变量？
6. `RATIONAL_A` 下 `Rational1` 与 `Rational2` 为什么不等价？换成 `RATIONAL_B` 之后，客户少了哪种观察，等价才成立？
7. `Rational3` 用 `type rational = int * int`。为什么它匹配 `RATIONAL_B`，却匹配不了 `RATIONAL_A`？`make_frac : rational -> rational` 为什么能 type-check 却使库无法使用？
8. `Rational1` 和 `Rational2` 的 datatype 形状相同。为什么 `Rational1.toString (Rational2.make_frac (9, ~6))` 仍必须类型失败？若类型系统放行，会观察到什么？
9. `fun g (f, x) = (f x) + (f x)` 与 `fun g (f, x) = 2 * (f x)` 在什么条件下等价，在什么条件下不等价？只比较返回值为什么不够？
10. `bad_max` 与 `good_max` 在 PL 等价下是什么关系？为什么把性能写进这个定义，会让“语义保持的优化”这句话说不出来？

## Code Reasoning

预测类型错误、值，或客户能否区分。不要先跑。`gcd` / `reduce` 的函数体按本章的契约理解即可：非负参数，约分，`d = y` 时变成 `Whole`。

### A

```sml
signature MATHLIB =
sig
  val fact : int -> int
end

structure MyMathLib :> MATHLIB =
struct
  fun doubler x = 2 * x
  val half_pi = 3.14
  fun fact x = if x = 0 then 1 else x * doubler (fact (x - 1))  (* 不是标准阶乘；只用于本题 *)
end

val a = MyMathLib.fact 3
val b = MyMathLib.doubler 3
```

`fact` 的函数体能否调用 `doubler`？`a` 求值到什么？`b` 发生什么？

### B

三个结构都归属下面的 signature。实现分别是本章的 `Rational1`（构造时约分，`toString` 不约分）、`Rational2`（只在 `toString` 约分）、`Rational3`（表示是 `int * int`，只在 `toString` 约分）。

```sml
signature RATIONAL_B =
sig
  type rational
  exception BadFrac
  val make_frac : int * int -> rational
  val add : rational * rational -> rational
  val toString : rational -> string
end
```

1. `Rational1.toString (Rational1.make_frac (9, 6))`
2. `Rational2.toString (Rational2.make_frac (9, 6))`
3. `Rational2.toString (Rational2.Frac (9, 6))`
4. `Rational3.toString (Rational1.make_frac (9, 6))`
5. `Rational1.toString (Rational1.Frac (1, 0))` 在这份 signature 下是否合法？

### C

```sml
val y = 14
fun f x = let val y = 3 in x + y end
fun f y = let val y = 3 in y + y end
```

两个 `f` 对参数 `10` 各得到什么？第二个是不是第一个的合法改名？它撞上了哪一种 shadowing？

### D

```sml
fun h () = (print "hi"; fn x => x + 1)
fun g y = h () y
val g2 = h ()
```

按顺序求值 `g 1`、`g 1`、然后假定 `g2` 的绑定发生在这两次调用之前，再求值 `g2 1` 两次。打印发生几次？两个 `g` 是否等价？

### E

```sml
fun bad xs =
  case xs of
      [] => 0
    | x :: [] => x
    | x :: xs' => if x > bad xs' then x else bad xs'

fun good xs =
  case xs of
      [] => 0
    | x :: [] => x
    | x :: xs' => let val y = good xs' in if x > y then x else y end
```

对 `[1, 2, 3]`，两者结果是否相同？在 PL 等价、渐近等价、只测试长度 ≤ 3 的系统视角下，各应怎么说？空表返回 `0` 是糟的规格，本题忽略规格好坏，只比这两个实现。

---

## Answer Key

### Concepts

1. Namespace 让两个库都有 `map` 而不互相遮蔽。它不决定客户能否依赖表示、能否调用 helper、能否自己构造违反不变量的值。那些才是可替换实现的条件。
2. 没有。结构名不是值，不能当表达式。外部使用限定名 `MyMathLib.fact`。环境里有的是这个限定名，不是顶层的 `fact`。
3. 可见集写成模块的类型，由类型检查器执行，而不是定义上的修饰符。匹配只要求 signature 的每一项都有。内部 helper 必须被允许多出来，否则无法隐藏。
4. 公开 datatype 就公开了 `Frac`。`toString (Frac (9, 6))` 不经过 `reduce`，得到 `"9/6"`。文档挡不住这个表达式。
5. Property 例如：返回的 string 总是最简；或分母为 0 则 raise。Invariant 例如：所有存放着的分母为正，且值已经约分。`toString` 不约分，是因为它依赖“值已经约分”。这条不变量若被客户破坏，property 就假。
6. A 导出 `Frac`。`Rational1.toString (Frac (9, 6))` 是 `"9/6"`，`Rational2` 的同形调用是 `"3/2"`。B 不导出构造器。客户只能 `make_frac` 和 `add`。这两条路上两者的可观察结果相同，包括字符串已约分、零分母会 raise。
7. A 要求完整的 datatype 定义，`int * int` 不是那个 datatype。B 只要求类型存在，synonym 合法。`make_frac : rational -> rational` 在边界上类型正确，但客户没有任何 `rational` 可以传进去，三个操作都启动不了。
8. 每个结构的抽象类型是新类型。`Rational2.rational` 不是 `Rational1.rational`。类型身份按结构划分，不按表示划分。若放行，未约分的值会进入不约分的 `toString`，得到 `"~9/6"`，property 失败。
9. `f` 纯、相同参数总返回相同值、且 `2 * (f x)` 用的那个 `2` 确实是调用次数时，结果相同。本题右边是 `2 * (f x)`，与左边在纯函数下结果相同。不等价的条件是 `f` 打印、改 ref、不终止或抛异常：左边做两次，右边做一次，客户能看见。返回值相同不记录调用次数。
10. 两者 PL 等价：相同结果、都终止、无副作用。性能不在定义里，所以慢换快可以说没有破坏客户。若性能算进等价，这次替换就不是等价替换，优化无法被说成语义保持。定义也允许快换慢，所以要用它辩护好事，而不是辩护把 `good_max` 换成 `bad_max`。

### Code

A. 可以。`doubler` 在结构内部的环境里，`fact` 的函数体在那个环境里求值。Signature 只删掉外部的名字。

`fact 3` = `doubler (fact 2)` = `doubler (doubler (fact 1))` = `doubler (doubler (doubler (fact 0)))` = `doubler (doubler (doubler 1))` = `8`。这不是阶乘。题目只问求值。

`b` 类型错误：`MyMathLib.doubler` 不在导出环境里。不求值。

B.

1. `"3/2"`。`make_frac` 约成 `Frac (3, 2)`，`toString` 不再约分。
2. `"3/2"`。内部可以是未约分的 `Frac (9, 6)`，`toString` 先约分。客户看见的字符串与 1 相同。
3. 类型错误。`RATIONAL_B` 不导出 `Frac`。
4. 类型错误。`Rational1.rational` 不是 `Rational3.rational`。即使放行，也是把 datatype 值传到期待 `int * int` 的实现里。
5. 不合法。`Frac` 不在这份 signature 里。零分母只能通过 `make_frac (1, 0)` 碰到，那会 raise `BadFrac`。

C. 第一个 `f 10` 是 `13`。第二个 `f 10` 是 `6`。不是合法改名。参数名 `y` 撞上了外层的自由变量 `y`，又被 `let val y = 3` 再遮蔽，函数体里不再有参数。

D. 若先绑定 `val g2 = h ()`，此时打印一次，`g2` 是 `fn x => x + 1`。之后两次 `g2 1` 不再打印，值都是 `2`。两次 `g 1` 各打印一次，值都是 `2`。一共打印三次。`g` 与 `g2` 不等价：一个每次调用都打印，一个在绑定时打印且只打印一次。

E. 对 `[1, 2, 3]` 两者都得到 `3`。PL 等价：对所有 list，结果相同，都终止，无副作用，所以等价。渐近不等价：`bad` 对某些 list 指数次递归，`good` 与长度成正比。只测长度 ≤ 3 的系统视角可能看不出差别，因此会漏掉更长输入上的差别。空表都返回 `0`，所以这一条糟规格也相同，不影响三者的比较。
