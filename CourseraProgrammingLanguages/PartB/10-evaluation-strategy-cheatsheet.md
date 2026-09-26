# Evaluation Strategy Cheat Sheet

课程正式讲过的，和只是为了定位而加上的，分开列。名字没在视频里出现的，标了扩展。

## 课程里的两条基本规则

| 构造 | 子表达式何时求值 | 求值几次 |
| --- | --- | --- |
| 函数调用（ML 和 Racket） | 进体之前，每个参数都求值 | 每个恰好一次 |
| `if` / `cond` 的分支 | 只求值被选中的那一支 | 未选中的零次 |
| `lambda` 的体 | 调用时 | 每次调用都算，除非你另外记忆 |
| Macro 展开 | 任何求值之前，包括死分支里 | 展开本身不是求值 |

Eager / strict 在本课就是第一行。讲师没有把 “strict” 当成术语反复用，但 “arguments are evaluated before the call” 就是这个规则。Racket 不是 lazy language。Haskell 是：函数参数默认不先算。

`if` 不是函数。把 `if` 包成函数，两支都会在进体前算完，递归停不下来。这是 macro 存在的理由之一。

## 链

```text
Eager
  参数现在算，算一次
        │
        ▼
不用的计算也付费；包出来的 if 两支都算
        │
        ▼
Thunk = (lambda () e)
  现在不算
  每次调用都算
  不调用就永远不算
        │
        ├── 可能不用：赚
        └── 用多次：亏，比重先算更差
                │
                ▼
Promise = (mcons #f thunk)
  my-force：第一次算，把格子改成结果
  以后 force：只读，不再有副作用
        │
        ▼
讲师所说的 lazy evaluation（显式、局部）
```

Stream 用 thunk 推迟尾巴，不用 promise 的“算完覆盖”。尾巴不是同一个零参数计算，而是下一个不同的计算。

Memoization 用表记住带参数的纯函数。它通常不把原计算包成 thunk：未命中就当场算，返回前 `set!` 表。递归必须走带表的那个函数，否则指数还在。

## 四个名字

| 名字 | 课程地位 | 含义 |
| --- | --- | --- |
| Eager / strict | 课程内容，用行为描述 | 调用前参数各算一次 |
| Thunk | 课程术语 | 为推迟求值而写的零参数函数。每次调用重算 |
| Promise / delay / force | 课程术语 | 带记忆的推迟。第一次 force 算，以后读 |
| Lazy evaluation | 课程用这个词 | 不需要就不算，需要了就记住。Haskell 的函数这样工作。Racket 里要自己写 |
| Call-by-name | **【扩展】** | 每次用到参数都重新求值原来的表达式。裸 thunk、用一次调用一次，是这个形状 |
| Call-by-need | **【扩展】** | Call-by-name 加上最多算一次。课程的 promise 是手写版，但是显式的：调用者写 `my-delay`，使用处写 `my-force` |
| Lazy language | 课程术语 | 函数参数默认按上面那种“需要才算并记住”工作。Haskell。不是“程序里用了 thunk 的 Racket” |

不要把 thunk 理解成线程或 future。课程没有并发。JavaScript 的 `Promise` 通常是异步计算，不是本课这个可变 pair。

## 三种调用，同一道慢乘法

| 传给 `my-mult` 的第二参数 | 乘 0 | 乘 1 | 乘大于 1 |
| --- | --- | --- | --- |
| `(lambda () (slow-add 3 4))` | 不算，最好 | 算一次 | 算很多次，最差 |
| 事先算好，thunk 只查找变量 | 仍付一次 | 算一次 | 只算一次 |
| thunk 里 `force` 同一个 promise | 不算 | 算一次 | 只算一次 |

第三行是前两行的优点合在一起。Mutation 藏在 promise 里。前提是计算没有副作用、不读可变状态；否则“记住第一次”会改变可观察行为。打印在第一次 force 发生，第二次不发生。

## Macro 如何改次数

函数改不了“参数先求值”。Macro 在求值前重写语法，于是可以规定次数：

| 想要 | 做法 |
| --- | --- |
| 零次，直到以后 | 把语法放进 `lambda`，像 macro 版 `my-delay` |
| 恰好一次 | 让它只出现在 `let` 的右边，后面用变量 |
| 许多次 | 让它出现在循环函数的体里，像 `for` 的 body |
| 一次都不要留在程序里 | `comment-out`：展开结果里没有那段语法 |

复制模式变量，就是复制以后的求值。`my-force` 不该做成 macro：用 `let` 收成一次之后，它和函数一样，没有额外的求值控制。

Hygiene 不改变次数。它改变的是生成的变量属于谁。见 `04` 和 `11`。

## Stream 与“无限”

```text
stream = thunk
调用 → pair(下一个值, 下一个 stream)
```

未请求的尾巴不存在。所以 `1, 2, 3, ...` 不必建成无限 list。定义式若在 thunk 外面 `cons` 自己，eager 语言在定义时就失败。Haskell 的 `cons` 不先求值参数，所以那种表面的环可以不是环。那不是无限内存。

本课的 stream 不缓存已经产生的元素。再走同一条尾巴会再调用生产者。这和 promise、memoization 都不同。
