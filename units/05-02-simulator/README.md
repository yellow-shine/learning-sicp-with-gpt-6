# 05.02 模拟器与汇编器：让控制器成为可执行对象

[返回全书路线](../../README.md) · [可运行题解](solutions.rkt) · [共用模拟器](machine.rkt)

- **教材**：[§5.2.1–5.2.4][source]，习题 **5.12 全四项、5.13**。
- **前置**：05.01 的机器设计、02.08 的消息传递与操作分派。
- **问题**：手工跟踪只能检查几个例子。怎样让同一个程序执行任意控制器，并且告诉我们它用了什么硬件资源？

## 1. 三层对象与两遍汇编

```text
控制器文本：符号标签 + 指令列表
       ↓ 第一遍 scan
标签→地址表；自动建立寄存器；去掉标签的指令文本
       ↓ 第二遍 assemble-one
执行过程向量（每条指令对应一个宿主闭包）
       ↓ run 循环
按 PC 取执行过程 → 读写寄存器/栈 → 更新 PC
```

第一遍尚不执行用户算法，所以允许 `goto` 指向后面才出现的标签。第二遍把 `(label L)` 解析成数字地址，把 `(op +)` 解析成操作表里的加法过程，把 `(reg n)` 变成运行时读取 n 的过程。若把寄存器**当前值**也在汇编时读出，会错误冻结它，循环就不能工作。

教材把 PC 表示为“剩余指令链表”；本实现改为向量下标，逻辑一样。标签可以指向向量末尾，表示正常终止。`assign`、`test`、`perform`、`save`、`restore` 完成后 PC 加一；`branch` 根据 flag 选择跳转或加一；`goto` 直接改 PC。因此这里既有真正的汇编，也有真正的指令执行，不是扫描文本后调用宿主 `fib`。

机器闭包封装寄存器表、标签表、栈、PC 和统计信息。常用消息如下：

```scheme
(define m (make-machine basic-ops fibonacci-controller))
(m 'set 'n 7)
(m 'run 0)                    ; 可选第二参数是指令预算
(m 'get 'val)                 ; 13
(m 'statistics)               ; (累计push 最大深度 指令数 当前深度)
(m 'analysis)                 ; 5.12 静态报告
(m 'trace-limit 12)            ; 只记录下一次运行最前面的12条
```

`run` 每次重置栈和统计，但不清空数据寄存器；入口前必须设置输入。操作表是受信任的机器原语，宿主 `apply` 只用于应用这些原语，绝不解释用户 Scheme 源码。

## 2. 5.12：四种静态信息的完整实现

**题意**：扩充汇编器，记录去重并按类型排序的全部指令、存入口的寄存器、栈寄存器，以及各寄存器的赋值来源；通过机器消息取得报告，并在教材 Fibonacci 机器上实验。

`analysis` 在汇编保存的文本上做四种投影：

1. **instructions**：先按结构 `equal?` 去重，再按 `assign branch goto perform restore save test` 分组。类型内保留首次出现顺序；题目只要求按类型排序，不要求操作数的字典序。
2. **entry-registers**：只选 `goto (reg r)` 的 r，去重。被赋予标签但从未用于寄存器跳转的寄存器，不属于这个集合。
3. **stack-registers**：选 `save` 或 `restore` 的目标寄存器，合并去重。只扫描 save 会漏掉错误控制器中的“仅 restore”寄存器。
4. **assignment-sources**：为每个已发现的寄存器建立条目，收集以它为目标的 assign，对每条指令的 `cddr` 去重。只读或仅 restore 的寄存器也必须出现，来源表为空，例如 `(input)`；这表示没有控制器 assign 来源，而不是漏报。保留结构而不是字符串，例如 `((op +) (reg val) (reg n))`，这样可以看出一个数据通路的全部输入。

教材图 5.12 的 Fibonacci 控制器实际执行 `fib(7)=13` 后，报告包含：

```text
entry-registers: (continue)
stack-registers: (continue n val)
continue 的来源：((label fib-done)), ((label afterfib-n-1)), ((label afterfib-n-2))
n 的来源：((op -) (reg n) (const 1)),
          ((op -) (reg n) (const 2)), ((reg val))
val 的来源：((op +) (reg val) (reg n)), ((reg n))
```

指令列表包含 18 条不同文本：8 条 assign、1 条 branch、2 条 goto、3 条 restore、3 条 save、1 条 test。完整列表由脚本打印。`goto fib-loop` 虽然在两个位置出现，只保留一次；两条减法中的常量不同，必须保留两条。

这些信息解释硬件需求：continue 要能接收三个入口地址；val 需要 n 和加法结果两路输入；栈必须连接 continue、n、val。但它们**不能**证明某次运行真的经过每条指令，也不表示各条指令执行次数。后者要动态计数。

## 3. 5.13：从控制器自动发现寄存器

**题意**：调用者不再显式列寄存器名，由汇编器按首次遇见的使用自动分配。

第一遍同时处理两类出现位置：

- `(assign r ...)`、`(save r)`、`(restore r)` 的 r；
- 任意指令表达式内的 `(reg r)`，包括测试参数和 `goto (reg r)`。

扫描到真正的 `(const ...)` 表达式后停止递归：常量里面恰好包含 `(reg imaginary)` 只是数据，不应该分配寄存器。对未带标签的表达式，逐个扫描它的元素，不能把 cdr 尾表重新当作表达式。例如 `(assign const (reg input))` 的尾表看似以 const 开头，但 const 在这里只是合法寄存器名，input 仍须分配；reg 也可以作寄存器名，`(save reg)` 不应被误读成寄存器表达式。自检实际执行了这两种名字的赋值、保存和恢复。每次 `allocate` 先查表，已有名字复用同一格。初值为 `*unassigned*`，第一次读取前必须写入，否则抛错，而不是把缺失输入当成 0。

Fibonacci 只发现 n、val、continue 三个程序寄存器。PC 和 flag 是模拟器内部状态，不计入该消息列表。若只从 assign 左边收集，作为只读输入的寄存器会遗漏，这正是自动分配时常见的错误。

## 4. 一段具体 PC 轨迹

Fibonacci 控制器开头的地址为：

```text
0 assign continue ← fib-done
1 test n<2
2 branch immediate-answer
3 save continue
4 assign continue ← afterfib-n-1
5 save n
6 assign n ← n−1
7 goto fib-loop（地址1）
```

n=2 时先压入最终返回位置和 2，再令 n=1、PC=1。基例令 val=1，`goto (reg continue)` 跳回 `afterfib-n-1`；恢复 n 和 continue 后，机器准备第二次递归，保留第一个子结果。两个子问题共用相同的 val，所以若不保存第一个结果，它会被第二次返回覆盖。

## 5. 栈监测、失败边界与取舍

每次 save 同时执行 `pushes+=1`、`depth+=1`、`maximum=max(maximum,depth)`；restore 令 depth 减一。最大深度是空间峰值，累计 push 更接近控制工作量，二者不能混为“用了多少栈”。此外每执行一条指令 steps 加一，标签不计数。

本实现栈条目为 `(寄存器名 . 值)`，restore 名称必须匹配。这比教材最简单的无类型共享栈多一道检查；不会改变教材正确控制器的计数，但会拒绝故意跨寄存器弹出的程序。重复标签、未知标签、未知操作、空栈、错误 restore 和耗尽指令预算都作为错误测试。默认预算一百万条，避免有缺陷的示例挂住 CLI。

分析采用列表扫描、结构去重，小控制器足够清楚，大代码会有二次扫描成本；这是教学规模的实现，不是工业级汇编器。数值 PC 只在当前汇编镜像有效，不能把另一个机器的入口地址拿来跳转。下一单元的堆指针也有类似“地址属于哪片存储”的约束。

## 6. 运行与已回答回顾

```sh
racket units/05-02-simulator/solutions.rkt
```

输出四行分析报告和 `05.02: all checks passed`，另有自检返回的 `ok`。Fibonacci 答案、三类寄存器信息、赋值来源、去重和预期异常都有失败断言。05.01–05.06 共用本文件，依赖是相对路径，不需要额外包。

- **标签解析为何在执行前完成？** 地址只依赖控制器布局，可一次解析；寄存器值随运行改变，必须延后读取。
- **看到两条 save 是否能推出运行只 push 两次？** 不能，循环可以反复经过它们；动态计数才是执行证据。
- **静态通路报告解决了什么？** 从控制代码反推需要的连接，避免凭几个运行样例误认全部资源需求。

[source]: https://mitp-content-server.mit.edu/books/content/sectbyfn/books_pres_0/6515/sicp.zip/full-text/book/book-Z-H-32.html
