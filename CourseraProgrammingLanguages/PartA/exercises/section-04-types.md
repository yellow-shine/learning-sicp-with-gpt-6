# Section 4（类型推断）— 练习

覆盖 `06-type-inference.md`。不含模块。先做题，再看文末 Answer Key。

## Concept Questions

1. 为什么“ML 程序里可以不写类型”不能推出“ML 是动态类型”？请用一个会在运行前被拒绝、而许多动态语言会接受的程序说明。
2. 类型推断和类型检查差在哪一步？SML 实现把它们做成同一个过程，改变的是定义还是工程？
3. 类型推断和参数多态为什么是两件事？没有类型变量时，`length` 的推断会卡在哪里？
4. 约束收集的顺序不影响“是否 type-check”，为什么错误信息的位置仍然不能当成唯一的问题所在？
5. `val r = ref NONE` 若得到 `'a option ref`，后面哪两次使用合起来破坏了 soundness？为什么不能只对名为 `ref` 的表达式加特殊规则？
6. 互相递归为什么不能靠“把 helper 写在前面”解决？`and` 改变的是环境规则的哪一条？高阶函数绕道为什么不是常规风格？

## Code Reasoning

预测类型、类型错误，或求值结果。不要先跑。涉及 `[?]` 的口述细节时，按笔记里已经钉死的规则推理。

### A

```sml
fun f (x, y, z) =
  if true
  then (x, y, z)
  else (y, x, z)
```

`f` 的类型是什么？若类型规则因为测试是字面 `true` 而忽略 else，类型会变成什么？为什么 ML 不那么做？

### B

```sml
fun sum xs =
  case xs of
      [] => 0
    | x::xs' => x + sum x
```

列出两条不能同时为真的事实。程序会不会开始求值？若编译器报错指向 case 而不是递归调用，是否说明 case 才是根？

### C

```sml
val pairWithOne = List.map (fn x => (x, 1))

fun pairWithOne xs = List.map (fn x => (x, 1)) xs

fun s_need_one xs =
  case xs of
      [] => true
    | 1::xs' => s_need_two xs'
    | _ => false

fun s_need_two xs =
  case xs of
      [] => false
    | 2::xs' => s_need_one xs'
    | _ => false
```

第一行为什么不能获得 `'a list -> ('a * int) list`，尽管它没有 mutation？第二行为什么可以？最后两个 `fun` 为什么不能互相调用，而把第二个 `fun` 改成 `and` 之后可以？`match [1, 2]` 若从 `s_need_one` 开始，结果是什么？

---

## Answer Key

### Concepts

1. 不写类型只说明类型是隐式的。静态类型的定义是运行前拒绝某些程序。`fun g x = if x then true else x * 2` 的两分支是 `bool` 和 `int`。不存在使检查成功的类型赋值，所以定义被拒绝，函数体不会等到某次调用才暴露错误。动态语言可以接受“有时 bool、有时 int”。那是另一条设计。
2. 检查是验证已给出的类型。推断是寻找一组类型，使得检查会成功。实现合成一个过程，不改变这个定义。原则上仍可以先填类型，再交给独立检查器。
3. 推断是填类型的过程。多态是填完之后仍有未约束变量，于是用 `'a` 表示“对所有类型”。Java 可以有类型变量，同时仍要求写下大部分类型。没有类型变量时，`length` 的元素类型没有任何事实，推断器不知道该挑 `int` 还是 `string`，函数也不能对所有 list 工作。
4. 是否存在一组一致的约束，与先收集哪一条无关。报错发生在第一条被发现的矛盾上。编译器可能先看见调用，也可能先看见 pattern。两条信息可以都对。Section 1 的语法错误已经是同一现象：指出的行常常在真正的洞之后。
5. `r := SOME "hi"` 把 `'a` 实例化成 `string` 并写入。`valOf (!r) + 1` 把同一个盒子的 `'a` 实例化成 `int` 并当作 int 使用。运行时是 string 加 int。类型系统声称这不会发生，所以那套泛化规则 unsound。只禁 `ref` 挡不住 `type 'a foo = 'a ref`，也挡不住 module 把 reference 藏在签名后面。检查使用处的人看不见定义。
6. 两个函数谁的函数体都要看见对方。先写哪一个，另一个都不在环境里。普通递归只能看见自己，看不见还没绑定的另一个名字。`and` 让这一捆 binding 同时进入环境，顺序规则只在捆外恢复。高阶函数绕道把后定义的函数当参数传，能模拟“向后调用”，但更慢，类型里多一个函数参数。想互相递归时用 `and`。

### Code

A. 类型是 `'a * 'a * 'b -> 'a * 'a * 'b`。then 是 `t1 * t2 * t3`，else 是 `t2 * t1 * t3`，两支都必须等于返回类型，所以 `t1 = t2`，`z` 独立。忽略 else 会得到更宽的 `'a * 'b * 'c -> 'a * 'b * 'c`。ML 不那么做，因为类型规则不知道哪一支会执行。即使求值会跳过 else，类型也不依赖常量折叠。否则同一程序的类型会随编译器有多聪明而变。

B. Pattern 和 `+` 迫使 `x : int`，`xs : int list`。调用 `sum x` 把 `int` 传给需要 `int list` 的函数。两条不能同时为真。程序不求值。报错指向 case 只说明编译器先撞上了那条矛盾，不说明递归调用不是原因。换一个收集顺序，信息会换地方，结论仍是不 type-check。

C. 第一行的右边是 `List.map` 的调用，不是 syntactic value，也不是变量。Value restriction 禁止把 `'a` 泛化，尽管没有副作用、也没有 `ref`。第二行绑定的是函数，函数是 value，所以可以有 `'a list -> ('a * int) list`。最后两个 `fun` 按顺序进入环境：`s_need_one` 的函数体里 `s_need_two` 还不存在。改成 `and` 后两者同时进入 `let` 或顶层的那一捆环境，调用合法。`[1, 2]` 从 `s_need_one` 看到 `1`，进入 `s_need_two` 看到 `2`，回到 `s_need_one` 看到 `[]`，得到 `true`。
