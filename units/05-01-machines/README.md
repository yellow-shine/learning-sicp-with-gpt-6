# 05.01 寄存器机器：把隐含的控制变成数据

[返回全书路线](../../README.md) · [可运行题解](solutions.rkt) · [控制器全集](controllers.rkt)

- **教材**：[§5.1.1–5.1.5][source]，习题 **5.1、5.4(a)(b)**。
- **前置**：01.04 的算法成本、03.03 的可变数据与栈。
- **问题**：Go 的函数调用替你保留局部变量和返回地址。如果只剩几个寄存器、算术部件和跳转，这些工作放在哪里？

## 1. 数据通路与控制器不是同一件事

数据通路说明“哪些值能送到哪个运算部件，再写入哪里”；控制器说明“现在让哪条通路工作”。`(assign n (op -) (reg n) (const 1))` 表示读取旧 n，做减法，再覆盖 n，并非建立一个会自动更新的方程。

机器的状态是寄存器内容、PC（下一条指令位置）、测试标志和栈。操作表提供 `+ - * = >` 等原语；原语的内部实现是本层抽象屏障，不需要把加法继续拆成逻辑门。控制器里的标签只是地址的名字，不是一次可执行计算。

| 指令 | 作用 |
| --- | --- |
| `assign` | 把常量、寄存器值、标签地址或原语结果写入寄存器 |
| `test` / `branch` | 更新标志；为真时跳到标签，否则顺序执行 |
| `goto (label L)` | 固定位置跳转 |
| `goto (reg continue)` | 跳到寄存器中保存的返回位置 |
| `save` / `restore` | 后进先出地保留、取回待完成工作 |
| `perform` | 执行副作用原语，不保存返回值 |

“子程序”不必有专门的 `call` 指令：先把返回地址放进 `continue`，再跳到子程序入口即可。递归时下一次调用也要使用 `continue`，因此需要把旧地址压栈。

## 2. 5.1：迭代阶乘的数据通路与控制图

**题意**：将教材的 `iter(product,counter)` 阶乘改写成机器，并画两类图。输入 n 为非负整数；输出在 product。

```text
数据通路：
  常量1 ──→ product、counter
  counter ─┐                counter ─┐
  product ─┴→ [乘法 *] → product    1 ─┴→ [加法 +] → counter
  counter ─┐
        n ─┴→ [比较 >] → flag

控制图：
  product←1, counter←1
          ↓
  loop: counter>n ? ──是──→ done（答案在 product）
          │否
  product←counter*product
  counter←counter+1
          └──────────────→ loop
```

相应的逐条文本在 `iterative-factorial-controller`，不是由宿主阶乘函数代算。循环入口不变量是 `product=(counter−1)!`。更新乘积后将 counter 加一，维持不变量；离开时 counter=n+1，因此 product=n!。n=0 时第一次测试就结束，给出 0!=1。

n=3 的执行轨迹：

| 到达 loop 的次数 | counter | product | counter>3 |
| --- | ---: | ---: | --- |
| 1 | 1 | 1 | 假 |
| 2 | 2 | 1 | 假 |
| 3 | 3 | 2 | 假 |
| 4 | 4 | 6 | 真 |

三个数据寄存器足够，栈推入次数为 0；按单位算术成本，时间 Θ(n)，额外空间 Θ(1)。不要先增加 counter 再乘，那会错过 1 并多乘 n+1。

## 3. 待完成工作：递归阶乘为什么需要栈

附带的 `factorial-controller` 按教材图 5.11 保留 n 和 continue，返回时先恢复 n，再恢复 continue，然后乘。数据通路是 `n→减1→n`、`n,val→乘法→val`、`n,continue↔栈`、`continue→PC`。基例 n=1，故这个专用递归版本的输入域为正整数，不把 n=0 送给它。

```text
fact(3)：save done，save 3
fact(2)：save after-fact，save 2
fact(1)：val←1
栈底 [done, 3, after-fact, 2] 栈顶
返回 fact(2)：弹2、after-fact；val←2*1=2
返回 fact(3)：弹3、done；val←3*2=6；跳 done
```

不用保存旧 val：调用者需要的是子问题产生的**新结果**。这说明“递归就保存全部寄存器”不是原则；原则是保留以后还需要、且会被子计算破坏的旧值。源程序里一次函数调用对应的状态，在这里成为能直接观察的栈条目。

## 4. 5.4(a)：递归幂

**题意**：实现 `expt(b,n)=1`（n=0），否则 `b*expt(b,n−1)`，并给出通路与控制器。完整控制器为 `recursive-expt-controller`。

```text
数据通路：n,0→[=]→flag；n,1→[-]→n；b,val→[*]→val
          标签→continue→PC；continue↔栈；常量1→val
控制图：expt-loop → n=0 ? → base: val←1 → goto continue
                      否
          save continue；n←n−1；continue←after-expt
          goto expt-loop
          after-expt: restore continue；val←b*val；goto continue
```

与阶乘不同，b 始终不变，旧 n 也不再参与乘法，因此只保存 continue，无需保存 n、b。例如 2³：下降三层，栈深 3；基例 val=1，三次返回得到 2、4、8。需要 n 次乘法和 n 次压栈，时间、最大栈深均 Θ(n)。

## 5. 5.4(b)：迭代幂

**题意**：把 counter 从 n 减到 0，同时累乘 product。`iterative-expt-controller` 的通路为：

```text
n→counter；常量1→product
counter,0→[=]→flag；counter,1→[-]→counter；b,product→[*]→product
控制：初始化 → counter=0? ─是→done
                       └否→乘一次、counter减1→重新测试
```

循环不变量 `product*b^counter=b^n`（右侧 n 是原输入）。2³ 的状态 `(counter,product)` 是 `(3,1)→(2,2)→(1,4)→(0,8)`。结果相同，但没有悬而未决的乘法，栈一直为空。n=0 返回 1；包括 b=0 时也沿用这个幂过程的零次幂约定。负指数不在题目算法输入域，否则 counter 不会到 0。

## 6. 运行、取舍与已回答回顾

```sh
racket units/05-01-machines/solutions.rkt
```

自检覆盖阶乘 0/1/普通输入、两种幂的零指数、负底数、零底数和有理数，以及栈平衡。打印的 12 行有限轨迹是 `(PC 指令 执行前栈深)`；最后为 `05.01: all checks passed`。测试中的宿主阶乘只算独立期望值；待测结果来自模拟器执行控制器。

- **为什么常量数量的寄存器能实现任意深递归？** 控制代码被复用，不固定大小的是栈；真实内存仍有上限。
- **尾递归与循环的联系？** 无待完成工作时只需更新状态再跳转，不需为“返回这里再返回”保留栈帧。
- **图够不够确定执行？** 通路图不够，还需要控制次序。下一单元把控制器文本汇编成真正能逐条运行和监测的对象。

本单元复用下一单元的 `machine.rkt`，是为了实际验证当前设计，不要求先读完模拟器实现。控制器中递归阶乘、Fibonacci 的代码按 Abelson、Sussman、Sussman 的 SICP 第二版图 5.11/5.12 改编，其他图与轨迹为本讲义整理。

[source]: https://mitp-content-server.mit.edu/books/content/sectbyfn/books_pres_0/6515/sicp.zip/full-text/book/book-Z-H-31.html
