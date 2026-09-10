SICP（**Structure and Interpretation of Computer Programs**，中文常译《计算机程序的构造和解释》）表面上是一门“编程课”，但它真正讲的不是某个语言，而是：

> **如何构造复杂的软件系统，以及如何用不同抽象层次理解程序。**

它用 Scheme 作为教学语言，核心知识可以分成 5 大块。

### 1. 用过程构造抽象

第一部分主要在训练最基本的“程序思维”。

你会学到：

* 表达式求值
* 函数 / procedure
* 参数与返回值
* 递归
* 迭代
* 高阶函数
* 闭包
* 函数组合
* 抽象边界

非常经典的内容包括：

```scheme
(define (square x)
  (* x x))
```

然后逐渐升级到：

```scheme
(define (sum term a next b)
  ...)
```

也就是把“求和”抽象成一个高阶函数。

这里最重要的思想不是 Scheme 语法，而是：

> **把变化的部分变成参数，把不变的结构抽象出来。**

比如：

* sum
* product
* integral
* fixed-point
* Newton method

都可以通过高阶函数统一表达。

这一章还会讨论一个非常重要的问题：

### Recursive process vs Recursive procedure

例如阶乘：

```text
factorial(n)
= n * factorial(n-1)
```

虽然代码写成递归，但可能产生不同的计算过程：

* linear recursive process
* linear iterative process
* tree recursion

这对理解后面的：

* 时间复杂度
* 空间复杂度
* call stack
* dynamic programming

都非常重要。

---

### 2. 用数据构造抽象

第二部分从：

> “如何抽象计算过程”

转向：

> “如何抽象数据表示”。

这里非常像现代软件工程中的：

* ADT
* interface
* encapsulation
* data abstraction

典型例子是有理数。

你希望用户只知道：

```text
make-rat
numer
denom
```

而不应该关心内部到底是：

```text
(n, d)
```

还是其他表示。

所以 SICP 强调：

> **使用数据和表示数据应该分离。**

也就是 abstraction barrier。

这一部分会涉及：

* pair
* cons / car / cdr
* list
* tree
* sequence
* symbolic data
* generic operations

比如：

```scheme
(cons 1 2)
```

这是 Scheme 中最核心的数据组合机制之一。

通过 pair 可以构造：

```text
pair
 ↓
list
 ↓
tree
 ↓
arbitrary data structures
```

这部分非常经典的思想是：

### Closure property

不是指“函数闭包”，而是：

> 一个组合结构的结果，还能继续被同样的方法组合。

例如：

```text
pair(pair(a,b), pair(c,d))
```

因此可以无限构造复杂结构。

---

第二章还有一个非常重要的主题：

## 数据导向编程 / Generic Programming

假设你要支持：

```text
complex number
    ├── rectangular
    └── polar
```

以及：

```text
add
sub
mul
div
```

SICP 会讨论几种设计：

### 按类型分发

```text
if rectangular
else if polar
```

### Message Passing

对象自己决定如何处理操作。

```text
object(operation)
```

### Data-Directed Programming

维护一张：

```text
(type, operation) → implementation
```

表。

这实际上已经非常接近：

* virtual dispatch
* typeclass
* trait
* plugin architecture
* dependency inversion

---

# 3. 状态、对象与可变性

第三章会发生一个非常大的思想转变。

前两章更多是：

```text
input → function → output
```

纯函数式世界。

第三章开始加入：

```text
state
mutation
identity
time
```

比如银行账户：

```scheme
(define (make-account balance)
  ...)
```

然后：

```text
withdraw
deposit
```

每次调用以后，balance 会变化。

这里会引出非常重要的概念：

* state
* assignment
* local state
* mutable data
* identity
* aliasing
* side effect

SICP 会让你意识到：

> 一旦引入 mutable state，程序推理会突然变难。

例如：

```text
a = account
b = account
```

那么：

```text
a withdraw
```

会影响：

```text
b balance
```

因为：

```text
a and b
```

指向的是同一个 object。

---

## Environment Model

这是 SICP 非常重要的一部分。

前面可以简单认为：

```text
function application
→ substitute parameters
```

但加入：

* closure
* state

之后 substitution model 不够用了。

于是 SICP 引入：

> **Environment Model of Evaluation**

例如：

```scheme
(define (make-adder x)
  (lambda (y)
    (+ x y)))
```

执行：

```scheme
(define add5
  (make-adder 5))
```

真正发生的是：

```text
closure
 ├── code: lambda(y)
 └── environment
      x = 5
```

这就是现代语言里的：

> closure = function + lexical environment

理解这个之后：

* Go closure
* JavaScript closure
* Python closure
* Rust closure

都会容易很多。

---

# 4. 并发

第三章后半部分会进一步讨论：

> 如果有多个计算同时修改状态怎么办？

例如：

```text
Account balance = 100
```

两个线程：

```text
A: withdraw 10
B: withdraw 20
```

可能产生 race condition。

于是 SICP 引入：

* concurrency
* interleaving
* race condition
* serializer
* mutex-like abstraction
* atomicity

这里很重要的一句话是：

> **并发的核心困难，不是同时执行，而是多个计算共享状态。**

这和现代：

* lock
* transaction
* serializability
* linearizability

实际上有很强联系。

---

# 5. Stream：延迟计算

第三章还有一个非常漂亮的主题：

> **Stream**

普通 list 是：

```text
[1,2,3,4,...]
```

全部立即计算。

stream 则是：

```text
head + delayed tail
```

例如：

```text
integers =
1,2,3,4,5,...
```

理论上可以表示无限序列。

比如：

```text
prime numbers
Fibonacci
integers
```

都可以作为无限 stream。

这里会引入：

* lazy evaluation
* delayed evaluation
* promise
* memoization
* infinite data structure

SICP 会展示一个非常震撼的思想：

> 有时候，与其把计算看作“执行步骤”，不如把它看成“数据流”。

例如：

```text
input stream
   ↓
map
   ↓
filter
   ↓
output stream
```

这个思想今天可以在很多地方看到：

* Reactive programming
* Rx
* Java Stream
* Unix pipes
* Kafka Streams
* Flink
* Spark
* lazy iterator

---

# 6. 元语言抽象：实现一个解释器

第四章通常是很多人认为 SICP 最精彩的一章。

它开始问：

> Scheme 程序到底是怎么执行的？

于是你会自己实现一个：

> Scheme interpreter

核心结构：

```text
eval
apply
```

经典循环：

```text
eval(expression)
    ↓
apply(procedure, arguments)
    ↓
eval(...)
```

也就是著名的：

> **Eval-Apply Cycle**

例如：

```scheme
(+ 1 2)
```

解释器大概做：

```text
eval +
eval 1
eval 2

apply +
  to [1,2]
```

---

## Metacircular Evaluator

最精彩的是：

> 用 Scheme 实现 Scheme。

也就是：

```text
Scheme
 ↓
implements
 ↓
Scheme interpreter
```

这种 interpreter 被称为：

> metacircular evaluator

你会因此理解：

* AST
* parser 后面的求值过程
* lexical scope
* environment
* procedure application
* special form
* evaluation strategy

这对理解：

* 编译器
* JVM
* Python interpreter
* JavaScript engine
* Lisp macro

都很有帮助。

---

# 7. Evaluation Strategy

SICP 还会比较：

### Applicative-order

先算参数：

```text
f(g())
```

变成：

```text
temp = g()
f(temp)
```

也就是大多数现代语言的：

> eager evaluation

---

### Normal-order

先不算参数：

```text
f(g())
```

需要 g 的时候才算。

接近：

> lazy evaluation

SICP 甚至会通过修改 interpreter，实现一个 lazy language。

这非常关键，因为你会发现：

> 语言语义并不是神秘规定，而是 evaluator 的设计决定。

比如你可以自己决定：

```text
if
```

是否立即求值两个分支。

---

# 8. 逻辑编程

第四章后面还有一个非常有意思的系统：

> Logic Programming

类似 Prolog。

不是写：

```text
how to compute answer
```

而是描述：

```text
what relationships hold
```

例如：

```text
parent(A, B)
parent(B, C)
```

然后查询：

```text
grandparent(A, C)?
```

系统自动搜索解。

这里涉及：

* declarative programming
* query language
* rule
* inference
* pattern matching
* unification
* backtracking

这部分可以帮助你理解：

* Prolog
* Datalog
* SQL query
* rule engine
* logic engine

---

# 9. 寄存器机器

第五章从：

```text
高层语言
```

一路向下进入：

```text
机器执行模型
```

SICP 会设计一种：

> Register Machine

例如计算 GCD：

```text
register a
register b
register t
```

然后：

```text
test
branch
assign
goto
```

类似一种抽象汇编语言。

你会理解：

```text
program
 ↓
controller
 ↓
register
 ↓
stack
```

也就是 CPU 执行模型的基本思想。

---

# 10. 编译器

然后 SICP 会把 Scheme：

```text
Scheme source
```

编译成：

```text
register-machine instructions
```

你会看到一个完整 compiler 的核心结构：

```text
source program
     ↓
parser
     ↓
expression
     ↓
compiler
     ↓
instruction sequence
     ↓
register machine
```

这里会涉及：

* code generation
* stack
* register allocation
* procedure calling
* environment
* compiled procedure
* interpreter vs compiler

非常漂亮的一点是：

SICP 会同时展示：

```text
Interpreter
Compiler
Virtual Machine
```

三层之间的关系。

---

# 11. SICP 真正想教你的 5 个核心思想

如果把整本书压缩，我认为是这 5 个。

### 第一：Abstraction

不要一直想：

```text
代码怎么写？
```

而要问：

```text
正确的 abstraction 是什么？
```

例如：

```text
sum
map
filter
fold
```

---

### 第二：Composition

复杂系统不是一次写出来的，而是：

```text
small abstraction
      ↓
composition
      ↓
larger abstraction
```

这其实就是软件工程最基本的思想。

---

### 第三：Representation Independence

例如：

```text
ComplexNumber
```

外部只应该看到：

```text
real-part
imag-part
```

内部可以随时换：

```text
rectangular
↓
polar
```

而不用改调用者。

这就是今天：

* interface
* encapsulation
* abstraction boundary

---

### 第四：Programs are interpretable structures

SICP 会让你意识到：

```text
program
```

本身也是：

```text
data
```

例如 Lisp：

```scheme
(+ 1 2)
```

本质是：

```text
list
```

所以：

```text
program
↓
data
↓
transform
↓
execute
```

这就是 Lisp 特别强大的地方。

也是：

* macro
* AST
* compiler
* DSL

背后的思想。

---

### 第五：语言本身也是 abstraction

这是 SICP 最深的一层。

通常我们认为：

> “语言已经存在，我们用它写程序。”

SICP 最后会告诉你：

> **如果现有语言不适合解决问题，可以构造一个新的语言。**

也就是：

```text
problem
 ↓
design abstraction
 ↓
design DSL
 ↓
write interpreter
```

所以书名里的：

> Structure and **Interpretation**

就是这个意思。

---

## 如果按照“知识地图”来看

可以把 SICP 看成这样：

```text
SICP
│
├── 1. Procedure Abstraction
│   ├── recursion
│   ├── iteration
│   ├── higher-order functions
│   └── computational complexity
│
├── 2. Data Abstraction
│   ├── pair/list/tree
│   ├── symbolic data
│   ├── generic operations
│   └── data-directed programming
│
├── 3. State & Time
│   ├── assignment
│   ├── mutable state
│   ├── environment model
│   ├── concurrency
│   └── streams / lazy evaluation
│
├── 4. Interpreters
│   ├── eval/apply
│   ├── metacircular evaluator
│   ├── lazy evaluation
│   └── logic programming
│
└── 5. Machines & Compiler
    ├── register machine
    ├── evaluator machine
    ├── compiler
    └── interpreter/compiler integration
```

如果你最近在学 **6.5840、CMU 15-445、EPFL CS-451**，SICP 的定位其实很不一样：这些课程更多是在学“分布式系统/数据库具体怎么工作”，而 SICP 更像是在训练你最底层的**程序设计抽象能力**。学完之后，你会更容易理解为什么 `Raft`、数据库执行器、解释器、控制器、状态机这些系统常常都可以被拆成“状态 + 转换 + 抽象边界 + 组合”。
