# 02.04 序列作为接口：枚举、过滤、映射与折叠

[返回全书路线](../../README.md) · [可运行题解](solutions.rkt)

- **阅读**：SICP 第二版 [§2.2.3][source]。
- **前置**：02.03 列表/树；01.05 高阶过程与累积。
- **代表题**：2.33 全部三个过程；2.38 全部四个表达式与运算性质。

## 1. 问题：递归细节会掩盖数据流

“把树里的奇数叶子平方后求和”，可以写成同时做遍历、判断、平方、求和的一段递归。程序不长，但换成“偶数叶子的乘积”又要改同一片控制逻辑。

序列接口把它组织成可重排的阶段：

```text
树 (1 (2 (3 4)) 5)
→ enumerate-tree → (1 2 3 4 5)
→ filter odd?    → (1 3 5)
→ map square     → (1 9 25)
→ accumulate + 0 → 35
```

每一阶段只约定输入/输出的形状。列表是这里的**常规连接接口**，不等于所有应用都必须先物化整个数据集。Go 的循环也能算出相同答案；SICP 关心的是代码是否显露了“枚举—变换—汇总”的结构。

- `map`：每项变成一项，保留项数和位置。
- `filter`：按谓词保留部分项，保持原有相对顺序。
- `accumulate`：用一个二元过程和初值，把整个序列合成一个值；结果不一定是数。
- 枚举：把原问题转成可供这些组件处理的序列。

## 2. 右折叠的接口约定

教材的 `accumulate` 是 `fold-right`：

```scheme
(define (accumulate op initial sequence)
  (if (null? sequence)
      initial
      (op (car sequence)
          (accumulate op initial (cdr sequence)))))
```

对 `(a b c)`，结构是 `(op a (op b (op c initial)))`。`op` 的第二个参数已经是后缀的处理结果，不能把它当作下一个原始元素。列表本身不变。

## 3. 习题 2.33：三个填空的完整答案

**题意概述**：仅用累积表达 `map`、`append`、`length`。

```scheme
(define (map-acc p sequence)
  (accumulate (lambda (x y) (cons (p x) y)) '() sequence))

(define (append-acc seq1 seq2)
  (accumulate cons seq2 seq1))

(define (length-acc sequence)
  (accumulate (lambda (x y) (+ 1 y)) 0 sequence))
```

加 `-acc` 后缀只是避免遮盖宿主过程，不改变题目语义。

- **map**：空表映射后仍为空；已知后缀映射结果 `y`，把当前项的变换 `(p x)` 接到前面。
- **append**：初值不是空表而是第二个列表；从右向左把第一个列表各项接上去。只复制第一个列表的 pair，第二个列表共享。
- **length**：不关心 `x` 是什么，每剥下一项只把后缀长度加一。子列表作为一项，不递归数叶子。

展开 `append-acc '(1 2) '(3 4)`：

```text
cons 1 (cons 2 '(3 4))
→ (1 2 3 4)
```

分别以输入长度计，三个过程都是线性时间；右折叠保留 Θ(n) 待完成调用。`map` 分配 n 个结果 pair，`append` 分配第一表长度的 pair，`length` 只返回计数，但仍有递归控制空间。

## 4. 习题 2.38：左右折叠真正改变的是括号和初值位置

左折叠用一个逐步更新的累积值：

```scheme
(define (fold-left op initial sequence)
  (define (iter result rest)
    (if (null? rest)
        result
        (iter (op result (car rest)) (cdr rest))))
  (iter initial sequence))
```

它生成 `(op (op (op initial a) b) c)`，可以用尾调用只保留当前累积状态。这里没有声称累积结果本身也恒定大小：若 `op` 建立列表，答案仍会增长。

**题意中的四个表达式**：

| 表达式 | 展开 | 结果 |
| --- | --- | --- |
| `(fold-right / 1 '(1 2 3))` | `1 / (2 / (3 / 1))` | `3/2` |
| `(fold-left / 1 '(1 2 3))` | `((1 / 1) / 2) / 3` | `1/6` |
| `(fold-right list '() '(1 2 3))` | `(list 1 (list 2 (list 3 '())))` | `(1 (2 (3 ())))` |
| `(fold-left list '() '(1 2 3))` | `(list (list (list '() 1) 2) 3)` | `(((() 1) 2) 3)` |

除法不满足结合律；`list` 则明确保存了分组结构，所以它们都不应期望左右相同。

### 要保证相同，op 应满足什么？

一个常见且足够的条件：`op` 在同一结果域上满足**结合律和交换律**。结合律允许改括号，交换律允许把初值从最右移到最左，因此即使初值是任意域内元素也一致。

更精确地说，若 `initial` 是 `op` 的**双侧单位元**，只要结合律就够，**不需要交换律**。例如列表连接满足结合律但不交换，用空表作初值时左右折叠 `((1) (2) (3))` 都得到 `(1 2 3)`。

如果初值改成 `(z)`，只说结合律就不够：

```text
fold-right append '(z) '((a) (b)) → (a b z)
fold-left  append '(z) '((a) (b)) → (z a b)
```

这也解释了为什么“左右折叠相同当且仅当交换”不是正确概括。条件要连同初值、输入域一起说明。浮点加法由于舍入不严格满足结合律，即使数学实数加法满足，也不能推出所有机器计算逐位相同。

## 5. 嵌套映射：把双层循环变成候选空间

给定 `n=4`，枚举 `1≤j<i≤n`：

```text
i=1 → ()
i=2 → ((2 1))
i=3 → ((3 1) (3 2))
i=4 → ((4 1) (4 2) (4 3))
map 的结果是“列表的列表”
flatmap 再连接一层 → 六个 pair 候选
```

```scheme
(define (flatmap p seq)
  (accumulate append-acc '() (map-acc p seq)))
```

这里的 `flatmap` 只压平一层，不是 02.03 的 `fringe`：一个 `(i j)` 必须保留为一条记录，而不能拆成两个叶子。再过滤 `i+j` 为素数的候选，最后映射成 `(i j sum)`。文件实际实现试除素性检测与全部候选枚举，不借宿主排序或预设结果代替算法。`n=6` 的答案有七条，包含 `(6 5 11)`。

候选个数为 `n(n-1)/2`，所以“高阶组合写得短”没有消除 Θ(n²) 的枚举量。分阶段容易读、容易换组件，但会分配中间列表；极大输入可融合循环，第三章的流还能改变物化时机。先把结构讲清楚，不把抽象误认为免费加速。

## 6. 运行与已回答回顾

```sh
racket units/02-04-sequence-interfaces/solutions.rkt
```

输出 `02.04: all checks passed`。自检覆盖三个累积版本、空表、2.38 四个精确结果、非交换但有单位元的连接、非单位初值的反例、树数据流和素数和嵌套映射。

- **map 和 flatmap 区别？** 后者把各次生成的序列再连接一层。
- **左折叠总能替代右折叠吗？** 不能，参数位置、结合方式和初值角色都会影响结果。
- **这里的“接口”是什么？** 各阶段共享序列协议，不是 Go 的 `interface` 关键字。

下一单元 02.05 把“同类输入、同类输出”的组合推向图形语言：painter 组合后仍是 painter，而变换本身也能被高阶过程组合。

[source]: https://mitp-content-server.mit.edu/books/content/sectbyfn/books_pres_0/6515/sicp.zip/full-text/book/book-Z-H-15.html
