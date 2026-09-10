# 01.05 过程作参数：从求和到 accumulate

[返回全书路线](../../README.md) · [可运行题解](solutions.rkt)

- **教材**：SICP 第二版 [§1.3.1–1.3.2][source]。
- **前置**：01.03 的递归/迭代过程与状态不变量。
- **代表题**：[1.30][ex30]、[1.32 a/b][ex32]。

## 1. 重复的不是数字，而是计算模式

整数求和、立方和、某些级数，看起来处理不同公式，却都有同一骨架：取当前项，加上其余项，索引沿某个规则前进，越过上界返回零。若只让参数是数值，就只能复制这个骨架；若参数可以是过程，就可以给“求和”本身命名。

```scheme
(define (sum-recursive term a next b)
  (if (> a b)
      0
      (+ (term a)
         (sum-recursive term (next a) next b))))
```

- `term` 决定某个索引对应的项，例如 `cube`。
- `next` 决定索引如何前进，例如 `inc`，不强制步长为一。
- `a,b` 决定闭区间边界；`a>b` 是空区间。
- `sum` 负责终止与组合，调用者不用再管理循环。

`(sum cube 1 inc 10)` 传的是过程值；写成 `(sum (cube 1) 1 inc 10)` 会把数字 1 放到需要过程的位置，之后 `(term a)` 就无法调用。Go 的函数参数可帮助理解这个接口，但 Scheme 的内建 `+` 本身也能作为过程值传递。

完整代码加了 `advance`，拒绝不递增的 `next`，避免最常见的零步长死循环；契约仍要求索引序列**有限步越过上界**。严格递增本身不保证这一点，例如不断向上界靠近却永不越过的精确有理数序列。教学示例均为有限算术级数，参数过程假定无副作用。

## 2. 习题 1.30：把求和改为迭代

**题意概述**：填完整教材的 `(iter a result)` 骨架，使线性递归求和变为迭代过程。

原题空位依次是终止判断 `(> a b)`、返回 `result`、新索引 `(next a)`、新和 `(+ result (term a))`，初态 `a` 和 `0`：

```scheme
(define (sum-iterative term a next b)
  (define (iter current result)
    (if (> current b)
        result
        (iter (next current)
              (+ result (term current)))))
  (iter a 0))
```

计算立方和 1³+2³+3³：

```text
(current,result)=(1,0)
→ (2,1) → (3,9) → (4,36) → 36。
```

不变量：`result` 等于 current 之前已经经过的全部索引项之和。每次将当前项加入，再移动索引；越界时所有项恰好处理一次。空区间直接返回 0，单项区间也只加一次。

若有 n 项，且 `term/next/+` 各按常量成本算，递归版时间 Θ(n)、控制空间 Θ(n)；迭代版时间 Θ(n)、控制空间 Θ(1)。如果 `term` 本身很贵，总时间还必须加上各项求值成本，不能因外壳叫 sum 就忽略它。

两版在精确整数/有理数上得到相同数学和；浮点加法不严格满足结合律，改变相加顺序可能产生不同舍入结果。“改成迭代不改变答案”必须注明这个层次。

## 3. 习题 1.32a：把加法与零也参数化

**题意概述**：设计 `accumulate`，除了项与区间，再接受二元组合过程和空区间基值；把 sum 和 product 都写成它的特例。

这里明确采用右结合约定：

```scheme
(define (accumulate combiner null-value term a next b)
  (if (> a b)
      null-value
      (combiner (term a)
                (accumulate combiner null-value term (next a) next b))))

(define (sum term a next b)
  (accumulate + 0 term a next b))

(define (product term a next b)
  (accumulate * 1 term a next b))
```

`sum` 使用加法单位元 0；`product` 使用乘法单位元 1。因此空积是 1，不是 0，且 `(product identity 1 inc 5)` 是 120。对一般组合过程，`null-value` 首先只是基值，不保证一定满足某个代数单位元法则。

以项 `t1,t2,t3` 为例，accumulate 展开为：

```text
combine(t1, combine(t2, combine(t3, null-value)))。
```

过程作为参数让“求乘积”不再需要一套独立的范围遍历代码。抽象屏障是：调用者决定项、后继、组合、基值；累积器决定遍历组织。累积器不必检查 term 的公式是立方还是倒数。

## 4. 习题 1.32b：迭代版必须说明组合方向

**题意概述**：再给出另一种计算过程版本。最常见的迭代累积器是左折叠：

```scheme
(define (accumulate-left combiner null-value term a next b)
  (define (iter current result)
    (if (> current b)
        result
        (iter (next current)
              (combiner result (term current)))))
  (iter a null-value))
```

它得到：

```text
combine(combine(combine(null-value,t1),t2),t3)。
```

若 combine 是结合运算，基值是双侧单位元，这和上面的右折叠结果相同；不需要额外假设交换律，因为项顺序没有反转。但对任意二元过程不等价，例如：

```text
右折叠减法：1-(2-(3-0)) = 2
左折叠减法：((0-1)-2)-3 = -6。
```

若把迭代更新改为 `(combiner (term current) result)`，结果又变成 `3-(2-(1-0))`，不能靠换一个参数顺序就恢复原先一般右折叠。

为使 **1.32 的一般 combiner 接口也有语义一致的迭代答案**，代码还提供 `accumulate-iterative`：先尾递归收集项为逆序表，再尾递归组合：

```text
收集：() → (1) → (2 1) → (3 2 1)
组合：result=0
      → 3-0=3 → 2-3=-1 → 1-(-1)=2。
```

两个循环都没有待返回后完成的工作，所以控制栈 Θ(1)，但显式表占 Θ(n) 额外空间，时间仍 Θ(n)。这不是伪装成“常量总空间”的右折叠；它把隐藏的待完成工作改成显式数据。对 sum/product 这种具备结合性和单位元的精确运算，优先用不存表的 `accumulate-left` 即可。

这两个版本一起回答了习题，也说明一般抽象不可忽略组合规则。后面的序列单元会正式称它们为 fold-right 与 fold-left。本单元的列表只承担展示次序的角色，暂不要求掌握列表处理体系。

## 5. lambda 与 let：建立过程和建立局部名字

`lambda` 创建过程值，不立即执行过程体：

```scheme
(lambda (x) (+ x 4))
((lambda (x) (+ x 4)) 6) ; 10
```

`(define (plus4 x) (+ x 4))` 可以理解为 `(define plus4 (lambda (x) (+ x 4)))`。临时的小过程可以直接出现在参数位置：

```scheme
(sum-iterative (lambda (x) (/ 1.0 (* x (+ x 2))))
               1
               (lambda (x) (+ x 4))
               1000)
```

这计算 `1/(1·3)+1/(5·7)+1/(9·11)+…` 的部分和，乘 8 近似 π。改动的是项和索引，不是求和引擎。

`let` 是建立局部变量的方便语法：

```scheme
(let ((a expression-a) (b expression-b)) body)
```

相当于：

```scheme
((lambda (a b) body) expression-a expression-b)
```

因此初始化表达式在外层作用域求值，不会看到同一个 let 刚建立的其他绑定：

```scheme
(let ((x 5))
  (let ((x 3) (y (+ x 2)))
    (* x y))) ; y=7，body 中 x=3，所以 21
```

若要 y 使用新的 x，嵌套 let（或后续可用 `let*`）：结果是 `3×5=15`。这不是“初始化一定从左到右执行”；名字的可见范围与参数的求值先后是两个不同问题。一致改名还必须避免捕获自由变量，延续 01.02 的词法作用域原则。

## 6. 从求和再提炼一个用法：数值积分

中点矩形法把区间切成宽度 dx 的小段，在每段中点取函数值：

```text
∫ₐᵇ f(x)dx ≈ dx × Σ f(a+dx/2+k·dx)。
```

`integral` 用 lambda 捕获 dx，作为后继过程传给 sum。对 `[0,1]` 与 `dx=1/100`，区间恰好分成 100 段；积分 `x³` 得精确数 `19999/80000=0.2499875`，接近真值 1/4。误差来自离散近似，这个例子使用精确有理数，不是浮点舍入造成的误差。

本实现沿用教材的等宽中点规则，要求正 dx；若区间长度不是 dx 的整数倍，不额外处理最后不完整小段，也不声称提供通用高精度积分器。抽象去掉的是重复的程序组织，不会自动消除数学近似的前提。

## 7. 运行与已答复述

```sh
racket units/01-05-higher-order-sums/solutions.rkt
```

成功输出 `01.05: all checks passed`。自检覆盖整数和/立方和/乘积、空与单项范围、非单位步长、空范围不调用参数过程、左右折叠的减法反例、保序构表、let 作用域、π 近似、精确中点积分，以及坏 next/dx 的预期错误。

**已答复述**：高阶过程不是更玄的语法，而是把计算模式中变化的过程变成参数；基值与组合方向属于接口；let 的初始化使用外层绑定。下一单元把方向反过来：不仅接收过程，还生成新的过程，用来描述求解方法本身。

[source]: https://mitp-content-server.mit.edu/books/content/sectbyfn/books_pres_0/6515/sicp.zip/full-text/book/book-Z-H-12.html
[ex30]: https://mitp-content-server.mit.edu/books/content/sectbyfn/books_pres_0/6515/sicp.zip/full-text/book/book-Z-H-12.html#%_thm_1.30
[ex32]: https://mitp-content-server.mit.edu/books/content/sectbyfn/books_pres_0/6515/sicp.zip/full-text/book/book-Z-H-12.html#%_thm_1.32
