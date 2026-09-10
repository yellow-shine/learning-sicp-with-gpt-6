# 04.05 逻辑查询：关系、匹配与合一

[返回全书路线](../../README.md) · [题解与自检](solutions.rkt) · [查询核心](query-core.rkt) · [人员事实](personnel.rkt)

- **阅读**：SICP 第二版 [§4.4.1–4.4.3][source]。
- **前置**：02.06 的符号表达式、03.07 的流。
- **代表题**：4.55 a/b/c、4.64。

## 1. 问题：一条关系为什么能朝不同方向使用？

普通过程 `append(x,y)` 把两个输入变成一个输出；关系 `append-to-form(x,y,z)` 表达的是三个对象之间成立的条件。提供 x 和 y 可以求 z，提供 z 也可以枚举 x、y 的分割。不是过程“自动倒着执行”，而是解释器使用匹配、合一与规则搜索来寻找满足关系的绑定。

查询语言也采用 S 表达式，但它**不是 Scheme 的普通过程调用语义**：

```scheme
(supervisor ?person (Bitdiddle Ben))
```

这里 supervisor 是关系名，`?person` 是逻辑变量，`(Bitdiddle Ben)` 是数据名单，不会调用一个名为 Bitdiddle 的过程。宿主代码必须把这条查询引用后传给查询器：

```scheme
(define db (make-query-system #f 1000))
(install-statements! db personnel)
(stream-take (db 'query '(supervisor ?person (Bitdiddle Ben))) 10)
```

输出是实例化后的**完整查询**流，不是只打印 ?person。第二个构造参数是查询步骤预算，耗尽会报错，不当成“关系为假”；本单元关闭去环启发式，以观察教材原始循环行为。

## 2. 三层构造能力

### 事实：给定的关系实例

```scheme
(job (Hacker Alyssa P) (computer programmer))
(supervisor (Hacker Alyssa P) (Bitdiddle Ben))
```

人员库直接采用第二版 Microshaft 示例，完整保存本单元所用 address/job/salary/supervisor 关系，没有虚构一个数据库来替代习题的人员名单。

### 组合：把绑定框架接起来

- `(and q1 q2)`：先用 q1 扩展框架，再把每个结果交给 q2。
- `(or q1 q2)`：两个分支从相同输入框架出发，交错合并答案流。
- `(not q)`：在当前框架中尝试 q；没有任何扩展时保留该框架，否则丢掉它。
- `(lisp-value > ?salary 30000)`：变量已绑定后，使用宿主谓词过滤。

空 and 原样保留输入框架，因此从一个空框架得到一个成功；空 or 没有成功。一个空框架和一个空框架流不是同一件事：前者表示尚无绑定但仍成功，后者表示没有解。

### 规则：关系抽象

```scheme
(rule (outranked-by ?staff ?boss)
      (or (supervisor ?staff ?boss)
          (and (supervisor ?staff ?middle)
               (outranked-by ?middle ?boss))))
```

意思是直接上级，或某个上级的上级。不把 boss 预设成“只能当输出”的参数。每次应用规则先重命名局部变量，再把规则结论与查询合一，然后在所得框架中证明规则体。

## 3. 匹配与合一不是同一个操作

逻辑框架是变量到项的关联表；扩展返回新表头，旧框架仍可被其他搜索分支共享。这和 Scheme 环境的可变变量位置不同：不靠 set! 覆盖逻辑变量来尝试另一个值。

### 单向匹配

把 `(job ?p (computer . ?kind))` 对上事实 `(job (Reasoner Louis) (computer programmer trainee))`：

```text
job = job
?p → (Reasoner Louis)
computer = computer
?kind → (programmer trainee)
```

只有模式侧含变量。重复变量必须一致，所以 `(pair ?x ?x)` 不能匹配 `(pair a b)`。`pattern-match` 真正递归遍历 car/cdr，没有用字符串搜索或预计算结果。

点号不是“匹配一个元素”的记号；reader 已将其后的项放在 cdr 位置。`(computer ?kind)` 只接受一个后续元素，不能涵盖 `(computer programmer trainee)`；`(computer . ?kind)` 才覆盖所有职务尾部。

### 双向合一

规则结论也带变量，因此两侧都要处理变量：把 `(?x 3)` 与 `(?y ?y)` 合一，先绑定 ?x→?y，再绑定 ?y→3，实例化后两边都是 `(3 3)`。`walk` 沿变量链追值；`instantiate` 还递归处理值中的 pair。

不能绑定 ?x→`(f ?x)`，否则有限树的实例化会无限展开。`occurs?` 沿当前框架追踪间接依赖，既拒绝直接自含，也拒绝先 ?x→?y 再 ?y→`(f ?x)`。?x 与自身合一则原样成功，不应误报 occurs。当前项模型是无环的有限 S 表达式，不是 rational-tree 合一。

## 4. 习题 4.55：三条查询与全部结果

**题意概述**：a. Ben 的直接下属；b. 会计部门的姓名和工作；c. Slumerville 居民的姓名和地址。这里“直接下属”不是所有间接下属。

### a. Ben Bitdiddle 直接管理谁？

```scheme
(supervisor ?person (Bitdiddle Ben))
```

得到 Tweakit Lem E、Fect Cy D、Hacker Alyssa P。Reasoner Louis 直属 Alyssa，不在此结果中。

### b. 会计部门的所有人及职务

```scheme
(job ?person (accounting . ?job))
```

| 姓名 | 完整 job |
| --- | --- |
| Cratchet Robert | `(accounting scrivener)` |
| Scrooge Eben | `(accounting chief accountant)` |

?job 分别绑定 `(scrivener)` 和 `(chief accountant)`。若写 `(accounting ?job)` 会漏掉 chief accountant，因为它有两个词；也不必另写一个并不存在的 department 关系。

### c. Slumerville 的居民及地址

```scheme
(address ?person (Slumerville . ?address))
```

| 姓名 | 完整 address |
| --- | --- |
| Aull DeWitt | `(Slumerville (Onion Square) 5)` |
| Reasoner Louis | `(Slumerville (Pine Tree Road) 80)` |
| Bitdiddle Ben | `(Slumerville (Ridge Road) 10)` |

?address 是城市之后的整个尾表，不只街道名。solutions 对三条查询的完整实例化结果逐项断言。添加事实使用头插，所以本实现枚举次序与教材叙述人物的次序可能相反；关系答案不应依赖显示次序。

## 5. 逻辑等价不等于执行等价

在数学中 and 的交换律成立；这里却是左到右框架流水线。如下过滤得到 Ben 的非 programmer 下属 Tweakit：

```scheme
(and (supervisor ?p (Bitdiddle Ben))
     (not (job ?p (computer programmer))))
```

颠倒顺序时，?p 尚未绑定。系统能找到某个人是 programmer，于是 not 整体失败，得到空结果，而不是枚举所有“不是 programmer”的人。

这叫**否定即失败**：在当前数据库和搜索机制下找不到证明，不是经典逻辑里证明了补集，更不是对世界所有人的全称断言。数据库不全会影响含义；被否定查询若不终止，也无法判断它没有解。必须先绑定所需变量，再过滤。

lisp-value 更直接：未绑定参数报错。本实现只允许 `>、<、=、equal?` 这张宿主谓词表，使用已实例化值调用宿主 apply，**不使用宿主 eval，也不支持任意宿主代码执行**。这既足够展示筛选机制，也明确了语言边界。

## 6. 习题 4.64：为什么先回答，随后无限循环？

**题意概述**：Louis 把 outranked-by 的递归分支改成先递归找 middle，再检查 staff 的 supervisor：

```scheme
(rule (outranked-by ?staff ?boss)
      (or (supervisor ?staff ?boss)
          (and (outranked-by ?middle ?boss)
               (supervisor ?staff ?middle))))
```

查询 `(outranked-by (Bitdiddle Ben) ?who)`。

1. or 的直接上级分支立即找到 Warbucks Oliver，所以第一条回答正确。
2. 递归分支先调用 `(outranked-by ?middle ?who)`，**?middle 没有被 staff 的 supervisor 限定**。
3. 该调用又产生先递归的 `(outranked-by ?middle-2 ?who)`，变量换了名字，结构上却没有朝有限事实链缩小。
4. 每层本来都打算“递归成功后检查 supervisor”，但后续检查无法约束已经无限深入的搜索前缀。有限公司管理层级不保证这个错误搜索顺序有限。

```text
outranked-by(Ben, ?who)
 ├─ supervisor(Ben, ?who) → Warbucks
 └─ outranked-by(?m1, ?who)
      └─ outranked-by(?m2, ?who)
           └─ outranked-by(?m3, ?who) → ...
```

交错 or 允许先看到有限结果，不代表流尾能证明穷尽。正确规则先执行 `(supervisor ?staff ?middle)`，从当前员工沿实际边前进；在本题无环的有限管理图中递归终于走到无上级的人。如果数据本身带环，正确顺序也不能独自解决所有循环。

自检安装真正的错误规则，先断言第一答案，再向后请求流，直到**内部步骤预算**报错，并捕获这个错误。它没有把“不终止”替换成一条写死的失败分支。80 步预算只保证 CLI 有限；无限循环的结论来自上述语义轨迹，预算耗尽本身不证明任意查询永不终止。

## 7. 运行与已答回顾

```sh
racket units/04-05-query-language/solutions.rkt
```

输出 `04.05: all checks passed`。测试含 4.55 全部结果、4.64 首答案及循环预算、重复模式冲突、变量链、occurs-check、空 and/or、未知事实、否定顺序差异及宿主谓词边界。

**已答回顾**：事实提供数据，规则提供关系抽象，合一产生相容绑定；框架流体现零到多个证明。一个关系有多个证明时可能重复输出同一实例，不默认做集合去重。逻辑变量不是 Scheme 的赋值变量；声明关系不免除对搜索顺序的理解。

下一单元 [04.06](../04-06-query-system/README.md) 沿 `qeval → 框架流 → 重命名 → 合一 → 规则体` 追到实现，并给出能运行但明确不完备的去环启发式。

[source]: https://mitp-content-server.mit.edu/books/content/sectbyfn/books_pres_0/6515/sicp.zip/full-text/book/book-Z-H-29.html
