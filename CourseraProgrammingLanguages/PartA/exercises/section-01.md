# Section 1 — 练习

覆盖 `01-pieces-of-a-language.md` 与 `02-functions-lists-and-immutability.md`。先做题，再看文末 Answer Key。

## Concept Questions

1. 为什么说 REPL 不是 ML 的一部分？若一个 ML 实现没有 REPL，语言的哪一条语义规则会改变？
2. `val a = 10; val b = a * 2; val a = 5` 之后 `b` 为什么仍是 `20`？请给出两个彼此独立、任何一个都足够的理由。
3. 类型检查通过，是否意味着求值不会失败？举一个 Section 1 里的反例，并说明类型系统为什么不该拒绝所有类似程序。
4. 函数绑定和函数调用各做哪一件事？为什么函数体不能在 `fun` 被处理时求值？
5. `pow (2, 2 + 2)` 的函数体看见的 `y` 是什么？若参数改为惰性求值，函数体需要多看见什么？
6. 为什么 `int * (bool * int)` 和 `int * bool * int` 不是同一个类型？tuple 解决不了哪一种数据？
7. `null` 和 Java 的 `null` 差在哪里？`hd []` 为什么不是类型错误？
8. `let` 为什么是表达式而不是一种新语句？它的三件实际用途里，哪一件是惯用法而不是新语义？
9. `andalso` 为什么必须是关键字？把它做成函数之后，`max1` 的哪一行会在不该失败的时候失败？
10. 在没有 mutation 的语言里，`append` 让结果的尾巴与 `ys` 共享，为什么调用者无法抱怨？同一实现放进 Java 的可变数组，会破坏什么？

## Code Reasoning

预测 value、type、环境或错误。不要先跑。

### A

```sml
val a = 1
val b = a + 1
val a = b + a
val c = a
```

写出每一行之后的动态环境。最后 `c` 是多少？

### B

```sml
fun pow (x : int, y : int) =
    if y = 0 then 1 else x * pow (x, y - 1)

val n = pow (3, 1 + 1)
```

把调用拆成三步。函数体第一次运行时，环境里的 `x` 和 `y` 是什么？最终值是什么？

### C

```sml
fun f (x : int) =
    let
        val x = x + 1
        fun g (y : int) = x + y
    in
        g x
    end

val r = f 3
```

`g` 的函数体里的 `x` 来自哪里？`r` 是多少？若改成动态作用域，调用 `g x` 时 `g` 看见的 `x` 会不会不同？为什么在这个具体程序里两种作用域结果一样或一样？

### D

```sml
fun max1 (xs : int list) =
    if null xs then NONE
    else
        let val tl_ans = max1 (tl xs)
        in
            if isSome tl_ans andalso valOf tl_ans > hd xs
            then tl_ans
            else SOME (hd xs)
        end

val a = max1 [1, 4, 2]
val b = max1 []
val c = valOf b
```

分别给出 `a`、`b` 的值，以及 `c` 发生什么。`a + 1` 为什么不该通过类型检查？

### E

```sml
fun append (xs, ys) =
    if null xs then ys
    else hd xs :: append (tl xs, ys)

val y = [1, 2]
val z = append ([3], y)
```

画出一种允许的共享结构。若在求值之后能把 `z` 的第二个元素改成 `9`，`y` 会怎样？ML 为什么使这个问题无法被问出？

---

## Answer Key

### Concepts

1. REPL 是实现提供的读入-求值-打印循环。`use` 只是把文件里的 binding 逐条送进同一个环境。没有 REPL 时，`val` 的求值规则、`if` 的分支规则、类型规则都不变。变的是工具。
2. 右边在绑定建立时已经求完，`b` 里是 `20` 不是公式。后来的 `val a = 5` 是新绑定，不是对旧 `a` 的赋值。两条各自足够。
3. 不意味着。`x div 0` 类型是 `int`，运行时抛 `Div`。类型系统看不见值。若拒绝一切可能除零的除法，几乎所有除法都会被拒绝。那是放弃 completeness 还不够、连有用的程序都不要了。
4. 绑定把函数值放进环境，不跑函数体。调用求函数、求参数、在定义时环境加参数后跑函数体。定义时没有参数值，递归也需要函数值已经存在。
5. `y` 是 `2`。`1 + 1` 在进入函数体前变成 `2`。惰性则函数体需要看见未求值的参数表达式，以及求它时该用的环境。
6. 前者的第二分量是一个 pair，后者是三个分量。tuple 的宽度写在类型里，表达不了运行时才知道长度的序列。
7. `null` 是函数，消费一个 list，返回 `bool`。Java 的 `null` 是一个可以冒充引用的特殊状态。`hd` 的类型是 `'a list -> 'a`。空与非空不是类型能区分的，所以失败留在运行时。调用者应先用 `null` 或 `case`。
8. 一种表达式就能复用 binding 的类型规则和求值规则，并且可以出现在任何表达式位置。局部变量、嵌套函数、避免重复计算里，前两件是“binding 可以是 `fun`、作用域到 `end`”的直接后果。第三件是惯用法：用局部名字记住已求出的值。
9. 函数调用会先求所有参数。`isSome tl_ans andalso valOf tl_ans > ...` 在 `tl_ans` 为 `NONE` 时不应求右边。做成函数后右边仍会求，`valOf NONE` 抛异常。
10. 客户没有修改 list 内容的操作，因此共享与拷贝观察不到。放进可变数组后，通过结果修改元素会修改 `ys`。那就是 Java 例子里泄漏内部数组的同一类漏洞。

### Code

A.

```text
a → 1
a → 1, b → 2
a → 3, b → 2          （新的 a，旧 a → 1 被遮住）
a → 3, b → 2, c → 3
```

`c` 是 `3`。

B.

```text
1. pow → 函数值
2. 3 已是值；1 + 1 → 2
3. 定义时环境扩展 x → 3, y → 2, pow → 自身
```

第一次函数体运行时 `x = 3`，`y = 2`。然后 `3 * pow(3, 1) = 3 * (3 * pow(3, 0)) = 3 * 3 * 1 = 9`。

C. `g` 的 `x` 来自 `let` 里的 `val x = x + 1`，也就是 `4`。调用 `g x` 时参数 `x` 也是这个 `4`（内层绑定遮住了参数 `3`）。`g 4` 的体是 `x + y = 4 + 4 = 8`。`r` 是 `8`。

动态作用域在这个程序里结果相同：调用 `g` 时，当前环境里的 `x` 也是内层的 `4`。看不出差别，是因为调用发生在定义 `g` 的那个 `let` 里面。若把 `g` 返回出去，到 `x` 被遮蔽之后再调用，两种作用域就会分叉。那是 Section 3 的题目。

D. `a` 是 `SOME 4`。`b` 是 `NONE`。`c` 抛异常 `Option`，没有值。`a + 1` 是 `int option` 与 `int` 相加，类型失败。`SOME 4` 不是 `4`。

E.

```text
z → 3 → 1 → 2
          ↑
          y
```

若能把 `z` 的第二个元素改成 `9`，`y` 会变成 `[9, 2]`，因为第二个单元与 `y` 的头是同一块。ML 没有这个操作，所以“共享还是拷贝”不是客户能问的问题。
