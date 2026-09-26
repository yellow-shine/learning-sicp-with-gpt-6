# Module 3 — Block、Proc、闭包

## Problem

Part A/B 已经有一个工具：把一小段计算交给别人，让别人决定调用几次、传入什么。数组遍历、`map`、`filter`、`reduce` 都是它。Ruby 如果没有等价物，动态 OOP 语言就会退回显式循环，和前面的课程断开。

Ruby 的答案分裂成两层：

```text
block    调用旁边贴一块代码。常见情况极方便。不是对象。
Proc     把那块代码变成对象。少见，但是一等的，才能存进数据结构。
```

这是语言设计题：常见情况要多方便，才值得为不常见情况另造一个概念？

Source: Section 8 — Blocks / 0:05–0:25；Procs / 6:41–7:05。

## Block 是什么

`[Course]` 任何方法调用都可以额外带 **0 个或 1 个** block，不能带两个。它不写在括号里的普通参数中间，而是贴在调用旁边。

```ruby
3.times { puts "hi" }
[4, 6, 8].each { |x| puts x }
```

- `{ ... }` 是体。参数写在 `|x, y|` 里。
- 多行时惯例用 `do ... end`。两者几乎相同，差别主要是优先级。课堂不考这个差别。
- callee 可以忽略你给的 block，也可以在你没给时出错，还可以用 `block_given?` 走不同分支。`any?` / `all?` 不给 block 时，问的是元素本身是否为真。

词法作用域和 ML/Racket 闭包一样：block 体在**定义处**的环境里求值，不是在 `each` 内部的环境里。

```ruby
i = 7
[4, 6, 8].each { |x| puts(x + 1) if i > x }
# 打印 5 和 7；8 不打印。i 来自定义 block 的环境。
```

Source: Section 8 — Blocks / 0:25–3:01，3:01–4:30。

标准库把这件事用到极致，所以 Ruby 程序员几乎不写显式循环。语言里有循环，但 `times`、`each`、`map`、`select`、`inject` 覆盖了常见需求。

| 方法 | 作用 | 你在 ML 里可能叫它 |
| --- | --- | --- |
| `each` | 对每个元素调用 block | 一个迭代器 |
| `map` / `collect` | 收集每次 block 的结果，新数组 | `map` |
| `select` | 留下 block 为真的元素 | `filter` |
| `inject` | 带累加器走一遍；可省略初值，则用首元素 | `fold` / `reduce` |
| `any?` / `all?` | 存在 / 全部 | `exists` / `all` |
| `Array.new(n) { \|i\| ... }` | 用下标计算初值 | — |

`inject(0) { |acc, elt| acc + elt }` 是求和。这不是新概念，是把 Part A 的高阶函数换成“方法 + block”。

Source: Section 8 — Blocks / 4:30–9:00。

## Callee 怎么用 block：`yield`

奇怪之处在 callee 侧：block 没有参数名。要跑它，写 `yield`，要传参就 `yield a, 42`。

```ruby
def silly(a)
  yield(a) + yield(42)
end

# silly(5) { |b| b * 2 }  →  10 + 84 = 94
```

没传 block 就 `yield`，错误是 `no block given`。block 的参数个数不对，课堂说**不报错**：多的丢掉，少的补上相应的值。这和普通方法“参数个数必须对”不同。

递归时不能把“我收到的那个 block”当名字传下去。只能再包一层：

```ruby
count(base + 1) { |i| yield i }
```

老师觉得这像不必要的包装，但在 block 模型里是必要的。

Source: Section 8 — Using Blocks / 0:26–2:08，3:57–4:29。

`count` 的课堂含义：从 `base` 开始，每次加 1，数一数要走几步，block 才返回 true，到 `max` 停。block 在这里是回调。

## Proc：什么叫 first-class

`[Course]` first-class 的意思是：它可以是计算的结果，可以被方法返回，可以存进对象或数组，可以像数字一样传来传去。做不到，就是 second-class。

Block 是 second-class。你对收到的 block 只能 `yield`。不能 return 它，不能放进数组。

把它变成对象的办法之一：`lambda` 是 `Object` 上的方法，所以到处都能调。它接收一个 block，返回 `Proc` 的实例。然后用 `call` 去跑。

```ruby
a = [3, 5, 7, 9]
c = a.map { |x| lambda { |y| x >= y } }
c[1].call(5)    # true，因为 5 >= 5
c.count { |p| p.call(5) }   # 3：5, 7, 9 都 >= 5
```

这里每个 Proc 捕获了当时的 `x`。这就是闭包：代码加上定义时的环境。不是函数指针。函数指针没有那份环境，调用时不知道 `x` 是 3 还是 7。

直接写 `a.map { |x| { |y| x >= y } }` 是语法错误。那个位置要的是表达式，block 不是表达式。

Source: Section 8 — Procs / 0:08–1:44，3:26–5:13。

### 和 ML / Racket 闭包的共同点

```text
closure = 代码 + captured environment

定义 lambda / fn / block→Proc 的时候
    把当时可见的变量打包进去
以后在别的地方 call
    用的仍是那份环境，不是调用点的环境
```

`n_times` 不是课堂例子，而是同一模型的最短形式。`[Supplement]`

```ruby
def n_times(n)
  lambda { |x| n * x }
end
double = n_times(2)
double.call(10)   # 20；n 仍是定义时的 2
```

如果它只是函数指针，`n` 在 `n_times` 返回后就没了。闭包的全部意义就是环境还在。

课堂自己的捕获例子是 `each` 的 block 读外面的 `i`，以及上面数组里每个 Proc 捕获不同的 `x`。

## 为什么 Ruby 要拆成两个

`[Course]` Proc 更强：回调、存进数据结构、返回，都要它。Block 在 `map` / `each` / `select` 这些常见调用上更省。大多数语言只提供一等闭包，并尽量让那个写法短。Ruby 选择让常见情况更方便，于是不常见情况要学第二套东西。这是便利和概念数量的交换，不是表达能力上“block 能做 Proc 不能做的事”。能力是 Proc 更大。

Source: Section 8 — Procs / 5:41–7:05。

## 和对象、dispatch 的边界

Block / Proc 的调用是 **closure invocation**：你手里有一个函数值，`call` 或 `yield` 跑的就是它。环境在造它时定了。

`obj.m` 是 **dynamic dispatch**：你手里有一个对象，跑哪段代码要到调用时按 class 查。见 `06`。

两者都可以用来“把行为传给别人”：

- 传一个 Proc：行为是这份闭包。
- 传一个对象：行为是它能响应的消息，而且子类还可以换实现。

`[Course]` 在 range / array 那一讲，老师把这件事说成 Part A 的分离关注点：一段代码负责遍历（`count`），另一段代码负责“对元素做什么”（block）。Mixin `Enumerable` 后来把这个模式固定下来：你只实现 `each`，其余迭代器由 mixin 用 `each` 定义。见 `12`。

## Trade-offs

- 每次调用最多一个 block：语法轻；两个回调就得把其中一个做成 Proc。
- `yield` 没有名字：调用处好看；递归传递别扭。
- 参数个数不匹配不报错：脚本灵活；错误更晚、更怪。
- 闭包捕获变量：强大；和对象别名一样，你必须知道捕获的是哪份环境。Ruby 局部变量可变，所以捕获的是变量，不是调用当时的一个不可变拷贝。`[Supplement]` 课堂强调的是词法作用域，没有单独展开“捕获的是变量格还是值”。可变局部变量是 Section 8 讲过的，所以后续赋值能被已造出的 Proc 看到，是合理推论，标成 `[Inference]`。

## Concept cards

### block

- Problem: 把一小段代码交给 `each` / `map`，又不想为此造一个对象。
- Definition: `[Course]` 方法调用旁可选的至多一个代码参数。不是对象，不是表达式。
- Mental model: 语法上的第二通道。普通参数在括号里，block 在旁边。
- Example: `[1,2,3].map { |x| x * 2 }`。
- Runtime: callee `yield` 时，在 block 定义处的环境下执行体。
- Misunderstanding: block ≠ Proc。不能把 block 放进数组。

### Proc

- Problem: 有时行为必须存起来、返回、放进集合。
- Definition: `[Course]` `lambda { ... }` 返回的对象，class 为 `Proc`，用 `call` 调用。一等闭包。
- Mental model: block 的对象形态。
- Example: `c[1].call(5)`。
- Misunderstanding: Proc 不是 method。方法属于 class，通过 receiver 查找；Proc 是一个值，谁拿到谁 `call`。

### closure

- Problem: 函数返回之后，它用过的局部变量不该消失。
- Definition: 代码加上定义时的环境。ML、Racket、Ruby Proc 是同一个模型。`[Course]` 老师说 blocks/closures 几乎一样，并明确 Proc 有闭包的全部能力。
- Mental model: 不是函数指针。指针没有环境。
- Example: `lambda { |y| x >= y }` 记住造它时的 `x`。
- Misunderstanding: “闭包就是匿名函数”。匿名只是语法。有名的 ML 函数同样是闭包。

### yield

- Problem: callee 没有 block 的名字，怎么调用它？
- Definition: `[Course]` 调用当前方法收到的那个 block，并可传参。
- Example: `yield(a) + yield(42)`。
- Misunderstanding: 不是“返回并在以后恢复”的 Python/JavaScript generator 语义。本课的 `yield` 就是“现在跑那个 block”。`[Supplement]` 其他语言的 yield 常是协程，不要套过来。
