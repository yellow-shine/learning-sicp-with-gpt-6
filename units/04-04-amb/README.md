# 04.04 amb：把搜索和回溯放进求值规则

[返回全书路线](../../README.md) · [题解与自检](solutions.rkt) · [CPS 求值器](amb-evaluator.rkt)

- **阅读**：SICP 第二版 [§4.3.1–4.3.3][source]。
- **前置**：04.02 的分析器；词法环境与高阶过程。
- **代表题**：4.35、4.43（保留/去掉 Mary Ann 姓 Moore 的条件）。

## 1. 问题：可以只写候选与约束吗？

普通过程返回一个结果；非确定性表达式可以有零个、一个或多个可能结果：

```scheme
(amb 1 2 3) ; 依次尝试 1、2、3
(amb)       ; 没有选择，本分支失败
```

amb 不是随机抽样，不会并行启动三个线程。此处采用教材的深度优先、从左到右搜索，第一次返回 1，继续搜索时尝试 2。`amb-all` 是无交互驱动：收集一个结果后调用其下一选择续延，直到穷尽；只对有限问题使用它。

在对象语言定义：

```scheme
(define (require p) (if (not p) (amb) 'ok))
```

require 不必成为求值器特殊形式，它利用空 amb 传播失败。宿主侧 `#%require` 则是模块导入，两者只是拼写相关，语义完全不同。

## 2. 成功和失败都要显式交接

04.02 的执行过程接口是 `(environment → value)`；这里变成：

```text
execution(environment, succeed, fail)
succeed(value, next-failure)  接受一个值及它剩余的选择
fail()                       没有值，恢复之前的选择点
```

成功不能只交一个值，因为后续约束失败时必须知道该返回哪个选择点。所谓 continuation，就是“后面剩余工作”的宿主过程表示，不是隐藏的随机状态。

核心机制：

- literal/变量/quote：取得值，调用 succeed，原 fail 原样转交。
- if：先运行谓词，得到 `pred-value, fail2`；选中分支使用 fail2，谓词本身可能还有别的值。
- sequence：第一项成功后继续第二项；第一项留下的 fail2 是第二项的失败出口。
- application：先求操作符，再通过 `amb-args` 从左到右求参数，把各层失败链接起来。
- amb：第一候选失败续延是“尝试下一候选”；候选表空则调用传入 fail。
- 复合应用：扩展闭包保存的词法环境，再调用已分析的 CPS 过程体。

### 轨迹：约束如何把控制送回最近的选择

```scheme
(let ((x (amb 1 2)))
  (let ((y (amb 3 4)))
    (require (= (+ x y) 6))
    (list x y)))
```

```text
x=1，留下 fx: 改试 x=2
  y=3，留下 fy: 改试 y=4
    1+3 ≠ 6 → fy
  y=4，留下 fy-end: y 用完 → fx
    1+4 ≠ 6 → fy-end → fx
x=2
  y=3 → 失败 → y=4
  y=4 → 成功 (2 4)，附带“再找”的续延
再找 → y 用完 → x 用完 → 总失败（穷尽）
```

自检也验证无约束的 `(list (amb 1 2) (amb 3 4))` 顺序为 `(1 3), (1 4), (2 3), (2 4)`。

## 3. 回溯赋值不等于数据库事务

执行 `(set! x new)` 时保存绑定单元及旧值；成功后交出的失败续延先恢复旧值，再调用之前的 fail2。即使当前分支先成功输出，后来要求更多结果，仍会触发撤销。

```text
旧 x=0 → 赋 x=9 → 后续 (amb) 失败
                   ↓
             恢复 x=0 → 试下一个分支
```

测试 `(amb (begin (set! x 9) (amb)) x)` 得 `(0)`；穷尽把 x 分别改成 1、2 的搜索后，外部 x 恢复 0。这里针对的是对象语言 set!，不是宿主 set!。

沿用教材，define 不在回溯时撤销；安装程序定义使用 `amb-install!` 接受第一个成功结果。没有对象 I/O，也没有自动撤销任意宿主 primitive 副作用、磁盘写入或共享 pair 修改。把这种局部撤销叫作完整事务会夸大保证。

## 4. 习题 4.35：闭区间整数选择器与有界勾股数组

**题意概述**：实现 `an-integer-between`，用于在给定上下界内搜索勾股三元组。

完整对象定义在 solutions 中：

```scheme
(define (an-integer-between low high)
  (if (not (and (integer? low) (integer? high)))
      (error "Integer bounds required"))
  (require (<= low high))
  (amb low (an-integer-between (+ low 1) high)))
```

闭区间：low=high 仅有一个值；low>high 没有值；非整数界抛出错误，不伪装成无解。递归候选不会预先全部执行，因为 amb 是特殊形式；若它是严格的普通过程，这个定义就会先递归到底，失去选择含义。

三元组过程按教材依次选择：`i ∈ [low,high]`，`j ∈ [i,high]`，`k ∈ [j,high]`，要求 `i²+j²=k²`，因此次序约束是 `i≤j≤k`。原文 HTML 的小于号带下划线，表示非严格不等式；纯文本提取容易把它误读成 i<j。正整数中 i=j 不产生非零勾股解，但带 0 的区间会产生退化解；自检对 `[0,1]` 明确得到 `(0 0 0)`、`(0 1 1)`，不擅自改掉教材的边界语义。

主示例使用正界 `[1,20]`，返回所有（包括非本原）三元组：

```text
(3 4 5) (5 12 13) (6 8 10)
(8 15 17) (9 12 15) (12 16 20)
```

例如 i=3、j=3 时，各个 k 都未通过平方和约束；j=4 时逐个尝试 k≥4，k=5 满足平方和。继续要求答案后从 k 的剩余候选开始，不必手写三层 for 循环的恢复位置。

有界搜索树有限，最坏候选数量为区间宽度的 Θ(n³)，不算精确整数位运算成本；提前约束减少常数与部分分支。不是最快的勾股数组算法，而是清楚演示 amb 如何封装枚举。若把最内层改成无界整数生成器，深度优先搜索可能永远固定外层 i、j，找不完当前 k，更不会公平枚举所有三元组。有限边界是本题终止保证的重要部分。

负界也可用于整数枚举器；三元组过程仍按 `i≤j≤k` 与平方和筛选，但传统勾股数组取正整数，本讲义的穷尽列表只针对 `[1,20]`。

## 5. 习题 4.43：游艇谜题的两个版本

**题意概述**：五位父亲各有一个女儿、一艘以别人的女儿命名的艇；由已知艇名、Hood 的女儿和 Gabrielle 父亲的条件求 Lorna 的父亲，再去掉 Mary Ann 姓 Moore 的条件重新求解。

先整理确定信息，而不是先生成 5!×5! 个排列：

| 父亲 | 艇名 | 已知女儿 |
| --- | --- | --- |
| Moore | Lorna | Mary Ann（第一版本才固定） |
| Downing | Melissa | 待定 |
| Hall | Rosalind | 待定 |
| Hood | Gabrielle | Melissa |
| Parker | Mary Ann | 待定 |

Parker 的艇名由剩余唯一名字推出。每人的女儿不能同名于自己的艇，五个女儿名互异。“Gabrielle 的父亲拥有的艇，以 Parker 的女儿命名”转为：

```text
yacht(father(Gabrielle)) = daughter(Parker)
```

这不是“Gabrielle 是 Parker 的女儿”，也不是把船主与女儿同名者当同一人。

### 实现与剪枝

`yachts` 是实际运行在 amb 求值器里的对象过程。先固定 Hood=Melissa；每选择一个父亲的女儿，`daughter-except` 当场排除自己的艇名和已用女儿名。全部选择之后才检查需要知道 Parker 女儿的跨人物条件。普通宿主 Scheme 没有替它排序或生成预计算结果。

第一版本固定 Moore=MaryAnn；第二版本让 Moore 与其他人一样从候选里选。`amb-all` 真正穷尽两棵有限搜索树，测试完整分配而不只测试一个结论常量。

### 已知 Mary Ann Moore：唯一解

Gabrielle 的父亲不能是 Moore（女儿已知 Mary Ann），不能是 Hood（女儿 Melissa）。

- 若是 Downing，他的艇是 Melissa，便要求 Parker 的女儿也是 Melissa，与 Hood 冲突。
- 若是 Parker，自己的艇 Mary Ann 就要求自己女儿 Mary Ann，但又假设自己女儿 Gabrielle，矛盾。
- 所以是 Hall，他的艇是 Rosalind，故 Parker 的女儿为 Rosalind。
- 剩余 Lorna 只能是 Downing 的女儿。

| Moore | Downing | Hall | Hood | Parker |
| --- | --- | --- | --- | --- |
| Mary Ann | **Lorna** | Gabrielle | Melissa | Rosalind |

答案：**Lorna 的父亲是 Colonel Downing**。

### 不知道 Mary Ann 姓 Moore：恰好两个解

除上表外，新增：

| Moore | Downing | Hall | Hood | Parker |
| --- | --- | --- | --- | --- |
| Gabrielle | Rosalind | Mary Ann | Melissa | **Lorna** |

此时 Gabrielle 的父亲是 Moore，他的艇是 Lorna，所以 Parker 的女儿就是 Lorna。Downing 不能是 Melissa，Hall 不能是 Rosalind，剩余两名唯一安排为上表。因此放松条件后 **有两个完整解，Lorna 的父亲分别可能是 Downing 或 Parker**；不是同一个解的不同搜索顺序。

## 6. 搜索控制的取舍

约束声明减少了手写控制代码，却没有消灭搜索成本。约束越早掌握足够变量就越早检验，可以避免大量无效后代；但不能在变量未选定前凭空检验依赖它的约束。规则/选择顺序会改变首次答案耗时与是否卡住，不改变这两个有限谜题中被完整枚举的合法赋值集合。

深度优先不是公平搜索；无限左分支会饿死右分支。`amb-all` 会保存所有答案，空间至少与答案总量成正比；不把它用于无限结果。实际交互驱动可每次保留一个下一选择续延，此处为了 CLI 自动结束而用有限收集驱动。

## 7. 运行与已答回顾

```sh
racket units/04-04-amb/solutions.rkt
```

输出六个三元组、放松姓氏条件后的两个分配，最后 `04.04: all checks passed`。另检验空选择、空/单点/负数区间、非整数界、无三元组、选择次序、回溯恢复及调用参数个数错误。

**已答回顾**：success 携带 value 与 next-failure；failure 是可执行的恢复路径；require 利用空 amb 使约束失败；非确定性描述的是可能结果，不是随机性。

下一单元 [04.05](../04-05-query-language/README.md) 把“选出某个值”扩展成“找出使两个符号模式一致的变量绑定”，进入关系、规则与合一。

[source]: https://mitp-content-server.mit.edu/books/content/sectbyfn/books_pres_0/6515/sicp.zip/full-text/book/book-Z-H-28.html
