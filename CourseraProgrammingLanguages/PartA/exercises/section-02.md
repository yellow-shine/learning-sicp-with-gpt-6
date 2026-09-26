# Section 2 — 练习

## Concept Questions

1. 为什么 tuple 可以是 record 的语法糖，而 datatype 不能同样被说成“只是 tuple”？
2. `Str s` 出现在 `case` 里和出现在 `val a = Str "hi"` 里，构造子各在做什么？
3. 非穷尽匹配为什么是 warning 而不是类型错误？这和“类型系统放弃 completeness”有什么关系？
4. 什么时候该用 one-of，什么时候该用带 `option` 字段的 each-of？用学号和姓名举一个两边各对一次的例子。
5. `fun f (x, y, z) = x` 的参数个数是多少？类型里的 `*` 在说什么？
6. 删掉类型注解后，`#1 triple` 为什么比 pattern `(x, y, z)` 更难推断？
7. `'a` 和 `''a` 差在哪？`real` 为什么通常不能是 `''a` 的实例？
8. 造出一个异常值和 `raise` 它，差在哪一步？
9. `fact` 的递归调用为什么不在 tail position？把工作搬进 accumulator 之后，哪一个调用变成 tail call？
10. 尾递归的 `rev` 若每步仍用 append 把元素放到末尾，省下的是什么，没省下的是什么？

## Code Reasoning

### A

```sml
datatype exp = Constant of int
             | Negate of exp
             | Add of exp * exp
             | Multiply of exp * exp

fun eval e =
    case e of
        Constant i => i
      | Negate e2 => ~ (eval e2)
      | Add (e1, e2) => eval e1 + eval e2
      | Multiply (e1, e2) => eval e1 * eval e2

val e = Add (Constant (10 + 9), Negate (Constant 4))
```

`e` 这个值的树里还有没有“10 + 9”？`eval e` 的值是多少？若增加构造子 `Subtract of exp * exp` 却不改 `eval`，编译器会说什么，运行到 `Subtract` 时会发生什么？

### B

```sml
fun partial (x, y, z) = x + z
val a = partial (3, "hi", 5)
val b = partial (3, 4, "hi")
```

`partial` 的类型是什么？`a` 和 `b` 各自通过还是失败？若通过，值是多少？

### C

```sml
fun sum xs =
    case xs of
        [] => 0
      | x :: xs' => x + sum xs'

fun sum2 xs =
    let
        fun aux (xs, acc) =
            case xs of
                [] => acc
              | x :: xs' => aux (xs', x + acc)
    in
        aux (xs, 0)
    end
```

哪个调用在 tail position？对 `sum2 [1, 2, 3]`，写出 `aux` 每次调用时的 `acc`。两个函数的结果是否相同？对所有 `int list` 都相同吗？

### D

```sml
exception Odd
fun f xs =
    case xs of
        [] => 0
      | x :: xs' => if x mod 2 = 1 then raise Odd else x + f xs'
val a = f [2, 4] handle Odd => 0
val b = f [2, 1, 4] handle Odd => 0
```

`a` 和 `b` 各是多少？`[2, 1, 4]` 里的 `4` 被加进去了吗？为什么？

---

## Answer Key

### Concepts

1. Tuple 和某种 record 表达同一种 each-of，只是字段名是位置。Datatype 是 one-of：一个值不会同时是所有构造子。把它收成 tuple 会丢掉“恰好一种”的不变量。
2. 在 pattern 里，`Str s` 测试 tag 并把携带的 string 绑到 `s`。在表达式里，`Str "hi"` 求值参数并造出一个带 tag 的值。同一名字，拆和造。
3. 类型规则仍接受这个函数：它的类型可以说得通。未覆盖的值要到运行才失败。Sound 的检查可以选择警告而不是拒绝。拒绝所有非穷尽函数会更安全，也会拒绝一些程序员故意留下、并由调用者保证不会碰到的函数。Warning 是这种权衡的弱形式。
4. “要么学号，要么姓名，不会两个都有”是 one-of。`StudentNum of int | Name of ...`。“既有姓名，又可能有学号”是 each-of，学号字段用 `int option`。`~1` 表示没有学号是把 one-of 塞进一个 `int`。
5. 一个参数。那个参数是三元组。`*` 是 tuple 类型的构造，不是“三个参数列表”的分隔符。
6. `#1` 只要求存在字段 `1`，不说出还有没有字段 `2`、`3` 或其他名字。Pattern 把整个 each-of 的形状写全，推断才知道没有别的分量。
7. `'a` 可换成任何类型。`''a` 只能换成允许 `=` 的类型。`real` 的相等在舍入误差下不是你想要的数学相等，ML 不把它放进 equality type。
8. 异常构造子先产生一个 `exn` 值，可以传给函数、放进数据结构。`raise` 才放弃当前求值、沿调用链找 `handle`。传值不等于引发。
9. `n * fact (n - 1)` 的结果是乘法的结果。`fact` 返回后还要乘。`aux (n - 1, acc * n)` 的结果就是 `aux` 的结果，调用之后没有剩余工作。
10. 省下的是栈帧。没省下的是 append 复制整段已反转列表，总时间仍是平方。尾位置不讨论每步工作量。

### Code

A. 树里是 `Constant 19`，不是未求值的 `10 + 9`。构造子的参数先求值。`eval e` 是 `19 + (~4) = 15`。增加 `Subtract` 而不改 `eval`，编译器警告非穷尽。运行到该构造子时没有匹配分支，抛匹配失败异常。

B. 类型 `int * 'a * int -> int`。`a` 通过，值 `8`。`b` 失败，第三分量被加，不能是 `string`。

C. `sum` 里的 `sum xs'` 不在 tail position，返回后还要加 `x`。`sum2` 里的 `aux (xs', x + acc)` 在 tail position。`acc` 依次是 `0, 1, 3, 6`。结果都是 `6`。对所有 `int list` 结果相同，因为加法交换且结合，空表都返回 `0`。若运算不交换，accumulator 从左加会改变结果。这是改写时要检查的条件。

D. `a` 是 `6`。`b` 是 `0`。遇到 `1` 就 `raise`，`4` 不会被看到，`2` 已经算出的加法也随异常丢掉，`handle` 直接给 `0`。异常不是返回一个部分和。
