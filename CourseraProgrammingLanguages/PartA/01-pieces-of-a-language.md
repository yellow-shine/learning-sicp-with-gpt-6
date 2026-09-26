# 01 — 一个程序如何变成一个值

> Part A · Section 1 前半，以及 Section 1 的收束讲「Pieces of a Language」
> 视频：`01`–`04`，`17`

到这一刻，先不要问 ML 像不像 Java，也不要问它像不像 Python。那个类比会把你已经有的盒子模型原样搬过来，而这门课的第一件事就是拆掉那个模型。

今天的程序不是 `main`，不是类，不是方法。它是一串 **binding**。每个 binding 做一件事：在当前环境里增加一个名字，让后面的表达式能看见它。

```sml
(* This is a comment. This is our first program. *)

val x = 34;
val y = 17;
val z = (x + y) + (y + 2);
val abs_of_z = if z < 0 then 0 - z else z;
val abs_of_z_simpler = abs z;
```

如果没有精确的 binding 规则，你无法边读边知道“现在环境里有什么”。如果 binding 可以使用还没出现的名字，实现就不能按顺序维护环境。如果 `if` 把三个子表达式都求值，绝对值这种“只算一边”的表达式就写不出来。

所以第一个问题不是“ML 的语法是什么”。第一个问题是：

> 一个表达式，在一个环境里，如何变成一个值？在变成值之前，什么东西已经必须为真？

---

## 1. 这一组讲要解决什么问题？

命令式语言的默认故事是：程序是一串会修改内存的语句，变量是盒子，循环是重复。这个故事能写软件，但它把三件不同的事焊在一起：

- 名字如何出现（binding）
- 名字指向的内容能否后来被改掉（mutation）
- 一段计算何时发生（evaluation）

ML 在 Section 1 把它们拆开。拆开之后，后面的函数、闭包、类型推断、模块等价才有地方站。若这里把 `val a = 5` 读成赋值，Section 3 的闭包和 Section 4 的程序等价都会从根上错。

课程在这里引入它，是因为后面每一个构造都要回答同一组问题。加法太简单，简单到适合当脚手架：你不是在学加法，你是在学一套递归的语义方法。

它依赖的只有已有的编程经验。它准备的是：函数调用的环境、`let` 的局部环境、词法作用域、以及 Part B 里那个亲手写的 `eval`。解释器不是新思想。它是这些规则的可执行版本。

---

## Lecture — Bindings 与表达式规则

视频：Section 1，`ML Variable Bindings and Expressions`，`Rules for Expressions`。

### 1. 先遇到的困难

表达式可以任意嵌套。`(x + y) + (y + 2)` 的意思不能靠“我知道加法”撑住，因为 `x` 和 `y` 自己也是表达式，`if` 的分支里还可以再放加法。语义必须对子表达式递归定义。否则每加一个构造，都要发明一套新直觉，而直觉之间会对不上。

### 2. 核心概念

#### Syntax（语法）与 Semantics（语义）

**Definition.** Syntax 是某个构造怎么写。Semantics 是它是什么意思。在这门课里，semantics 再分成两段：运行前的 type checking，和运行时的 evaluation。

**Intuition.** 语法是你在文件里看见的形状。语义是你被允许如何推理“它会变成什么”。

**Why it exists.** 全世界的人要能对同一段程序达成一致。这不是口味问题。括号还是花括号，是语法偏好；条件表达式先算测试、再只算一个分支，是语义。软件开发里没有“我觉得条件表达式不该这样工作”的余地。

**Problem solved.** 把“写得出来”和“知道它做什么”分开。只学 syntax，会写出无法推理的程序。

**Example.** `val x = 34;` 的语法是关键字、名字、`=`、表达式、分号。它的语义是：先检查 `34` 的类型，再求值，然后产生一个新环境，其中 `x` 映射到 `34`。

#### Expression（表达式）与 Value（值）

**Definition.** 每个 value 都是 expression。不是每个 expression 都是 value。Value 求值到它自己。

**Intuition.** `34` 已经是终点。`(x + y) + (y + 2)` 还在路上。`true` 和 `false` 是 value。`3 < 0` 是 expression，它的 value 是 `false`。

**Why it exists.** 求值需要一个停止条件。递归定义若没有“已经是值就停”，会无限展开。

**Problem solved.** 你能指出计算进行到哪一步结束，而不是把整段代码都叫“结果”。

**Example.** `()` 是类型 `unit` 的唯一值。`use` 自己的结果是 `()`。忽略它。它不是你的程序的答案。

#### Environment（环境）：static 与 dynamic

**Definition.** Static environment 在运行前记录名字的类型（以及名字是否已经定义）。Dynamic environment 在运行时记录名字的值。

**Intuition.** REPL 把 `val x = 34 : int` 印在一行里，那是工具在帮你。心智上必须拆成两次：先用静态环境做类型检查，通过之后才用动态环境求值。

**Why it exists.** 有些错误不该依赖“刚好跑到那一行”。名字没定义、加法的两边不是 `int`、`if` 的两个分支类型不同，都可以在任何求值发生之前拒绝。

**Problem solved.** 把“程序不被接受”和“程序跑起来之后出了别的事”分开。后者仍然存在：异常、无限循环、以及一个类型正确但不是你想要的值。

**Example.**

```text
val x = 34;
val y = 17;
val z = (x + y) + (y + 2);
```

```text
Expression: (x + y) + (y + 2)

Static environment:
  x : int
  y : int

Type checking:
  x + y        : int
  y + 2        : int
  两者相加      : int
  所以 z : int

Dynamic environment:
  x → 34
  y → 17

Evaluation:
  x + y  → 51
  y + 2  → 19
  51 + 19 → 70

Value: 70
然后动态环境扩展为 z → 70
```

前面的 binding 可以被后面使用。后面的 binding 不能被前面使用。这不是风格，是环境按顺序增长的后果。

#### Conditional 不是 Addition

**Definition.** `e1 + e2` 的求值是：先求 `e1` 得 `v1`，再求 `e2` 得 `v2`，结果是 `v1 + v2`。类型规则要求两边都是 `int`，结果是 `int`。

`if e1 then e2 else e3` 的求值是：先求 `e1`。它必须是 `bool`。若为 `true`，结果是 `e2` 的值，`e3` 不求值。若为 `false`，只求 `e3`。两个分支可以是任何类型，但必须是同一个类型 `t`。整个 `if` 的类型是 `t`。

**Intuition.** 加法没有理由丢弃一边。条件表达式的全部意义就是丢弃一边。

**Why it exists.** 绝对值和短路都依赖“有一段代码没有跑”。若三个子表达式总是都跑，`if z < 0 then 0 - z else z` 在 `z` 为正时仍会去算 `0 - z`。在这个例子里碰巧无害。等到分支里有异常、无限递归或以后的副作用，差别就是语义差别。

**Problem solved.** 用类型保证结果只有一种类型，用求值规则保证只有一条路径发生。

**Example.**

```text
Expression: if z < 0 then 0 - z else z
Environment: z → 70

Evaluation:
  z < 0 → false
  then 分支不求值
  else 分支 → 70

Value: 70
```

`if` 不能省略 `else`。因为结果可能来自任意一边，语言无法给“没有 else”一个值。有的语言允许没有 else，那是它们选择了另一种语义（通常是“否则什么都不做”，这已经不是表达式，而是语句）。ML 这里的 `if` 是表达式，必须产出一个值。

变量使用和变量绑定也要分开。使用是查找。绑定是扩展环境。`x` 作为表达式：类型是静态环境里 `x` 的类型；求值是动态环境里 `x` 的值。因为只有通过类型检查的程序才会运行，求值时不必再担心“名字不存在”。不存在已经在运行前被拒绝了。

整数常量 `34`：类型 `int`，求值到它自己。`true` / `false` 同理。比较运算 `e1 < e2`（本讲作为练习，规则与用法一致）：两边 `int`，结果 `bool`，两边都求值，然后比较。

每个表达式种类都有自己的三问。细节会变，三问不变：

```text
Syntax        怎么写？
Type checking 什么类型？什么情况下整个表达式类型失败？
Evaluation    如何得到一个值？还是异常？还是不终止？
```

### 3. 代码逐步执行

```sml
val x = 34;
val y = 17;
val z = (x + y) + (y + 2);
val w = z + 1;
val abs_of_z = if z < 0 then 0 - z else z;
val abs_of_z_simpler = abs z;
```

```text
绑定之后的动态环境：

x → 34
y → 17
z → 70
w → 71
abs_of_z → 70
abs_of_z_simpler → 70
```

`abs z` 和 `abs(z)` 是同一次调用。一个参数时，括号不是语义的一部分。这和“函数调用要先求参数”不矛盾：`z` 先被查成 `70`，然后 `abs` 的函数体才跑。括号只是分组。

REPL 不是语言。`use "first.sml";` 的意思是：把文件里的 binding 当作你在提示符上逐条打进去。它打印类型和值，是因为它同时做了类型检查和求值，然后把两阶段的结果摆在一起。文件里的分号可以不写。REPL 里需要分号，是因为工具要知道你的输入结束了。那是工具的语法，不是 `val` 的语义。

---

## Lecture — REPL 与三类错误

视频：`The REPL and Errors`。

### 1. 先遇到的困难

如果把 REPL 当成神秘编译器，你不知道 `use` 只是把 binding 打进**同一个**还活着的环境。同一 session 里对同一文件 `use` 两次，旧 binding 还在。你在文件里删掉的名字，会话里可能还在。错误会被后面的 shadowing 盖住，你以为修好了。

如果相信类型检查器懂你的英文意图，逻辑错误会在“跑通了”之后活下来。`val fourteen = 7 - 7` 类型正确，求值得到 `0`。没有工具知道你想要 `14`。

### 2. 核心概念

#### 三类失败

**Definition.**

1. Syntax error：不是这门语言的写法。
2. Type error：写法合法，类型规则失败。程序不运行。
3. 运行之后仍可能：抛异常、不终止、或得到一个不是你想要的值。

**Intuition.** 绿的运行结果只说明“产生了一个值”。它不说明那个值是对的。

**Why it exists.** 不同失败发生在不同时间，修法不同。把它们叫成同一种“报错”，会去改不该改的行。

**Problem solved.** 你知道该看语法、看类型规则，还是看求值结果。

**Example.** ML 的类型错误信息经常很差。信息是编译器的最佳猜测，不是事实。它经常指向真正错误**之后**的那一行。

本讲里他实际撞上的，按因果而不是按报错行号：

| 你看见的 | 实际原因 |
|---|---|
| 第 14 行 `syntax error inserting ELSE`，那一行只是 `val a = ~5` | 更早的 `if` 没有 `else`。解析器在后面才发现句子没结束 |
| `replacing FUN with WILD` | `fun` 是关键字，不能当变量名 |
| `unbound variable x`，看起来像类型错误 | 上一行漏了 `val`，这一行被当成上一个表达式的延续。`x` 的 binding 根本没结束，所以静态环境里还没有它 |
| `test expression in if is not of type bool` | 这条是准的：`y` 是 `int`，测试必须是 `bool` |
| `types of if branches do not agree` | 一边 `int`，一边 `bool`。结果类型无法确定 |
| `expression begins with infix identifier minus` | `-5` 不是负五。`-` 只是中缀减法。负号是 `~`，或写成 `0 - 5` |
| `operator and operand don't agree`，`/` 期望 `real * real` | `/` 是浮点除法。整数除法是 `div` |
| 类型通过，然后 `uncaught exception Div` | `w → 0`。除零不是类型错误 |
| 跑完，`fourteen` 是 `0` | `7 - 7`。类型系统不读注释里的英文 |

```text
Expression: x div w
Environment: w → 0
Evaluation: 查到 0，做整数除法
Value: 没有。未捕获异常 Div
```

除零必须是运行时事件。类型系统看不见 `w` 的值，只看见 `w : int`。若它拒绝所有“可能除零”的程序，它会拒绝几乎所有除法。这是后面 soundness / completeness 的第一次具体预告，虽然那两个词要到 Section 7 才定义。

### 3. 若改掉规则

- 允许没有 `else` 的 `if`：它就不再是总能产出值的表达式。
- 同一 session 里 `use` 两次：合法，但旧 binding 还在。他因此要求重启 REPL。原因在下一讲才完全说清：第二次 `use` 是 shadowing，不是“重新加载替换”。
- 只信第一条错误信息：对。后面的信息常常是第一条没修好之前的噪声。

---

## Lecture — Shadowing 不是赋值

视频：`Shadowing`。

### 1. 先遇到的困难

```sml
val a = 10;
val b = a * 2;
val a = 5;
val c = b;
val d = a;
val a = a + 1;
```

如果把第二次 `val a = 5` 读成赋值，你会预测 `b` 也变成 `10`。环境若只记“当前的 `a`”，就解释不了 `b` 仍是 `20`。没有这条区分，函数参数、`let`、闭包都会被想成可变盒子。

这讲没有新语法。它是环境模型的探针。同一文件里反复绑定同一个名字通常是差风格。它被留下来，是因为没有它你测不到环境。

### 2. 核心概念

#### Binding 与 Assignment

**Definition.** `val x = e` 在**当前**动态环境里求值 `e`，然后产生一个**新**环境，其中 `x` 映射到那个值。若旧环境里已有 `x`，新绑定遮住旧绑定。这叫 shadowing（遮蔽）。旧映射没有被改写。ML 里没有办法把“刚才那个 `a` 映射到 `10`”这件事改掉。

Assignment（赋值）是另一件事：同一个盒子，内容变了。所有指向那个盒子的名字都看见新内容。

**Intuition.** Shadowing 是新的一行电话簿盖住旧的一行。旧的一行还在，只是后面的查找不再翻到它。赋值是把同一行的号码擦掉重写。

**Why it exists.** 局部名字、函数参数、REPL 里的重新试验，都需要“再绑定一次”而不追溯修改已经算完的值。若每次同名绑定都改历史，`b = a * 2` 就不是一个完成了的计算。

**Problem solved.** 已求出的值是值。它不记住自己是怎么来的。后面的环境变化不能爬回去改它。

**Example.**

```text
val a = 10
  环境 E1: a → 10

val b = a * 2
  在 E1 里求 a * 2 → 20
  环境 E2: a → 10, b → 20

val a = 5
  在 E2 里求 5 → 5
  环境 E3: a → 5, b → 20
  E1 和 E2 里的 a → 10 仍在，只是后续代码看不见

val c = b
  在 E3 里查 b → 20
  环境 E4: a → 5, b → 20, c → 20

val a = a + 1
  在 E4 里查 a → 5，加 1 → 6
  环境 E5: a → 6, b → 20, c → 20
```

REPL 为了帮忙，会把被遮住的旧值印成 `hidden value`，而不是把旧映射印出来。那是打印策略。旧映射在语义上还存在，直到没有任何东西指向那个环境。

有两个独立的理由，后来的重绑定不会改变先前的使用。任何一个都够：

1. 右边的表达式在绑定建立时就求值完了（eager）。`b` 里存的是 `20`，不是“以后再去算 `a * 2`”的公式。
2. 后来的 `val a = ...` 不是赋值。它是第二个变量，碰巧同名。

向前引用同样失败：名字还不在静态环境里，类型检查拒绝。这和“不能使用更后面的 binding”是同一条规则。

```sml
val a = 1;
val b = a;   (* b → 1 *)
val a = 2;   (* a → 2；b 仍是 1 *)
```

#### Variable 与 Value

| | Variable / Name | Value |
|---|---|---|
| 定义 | 环境里的一个绑定。名字指向一个值 | 求值的终点。`34`、`true`、一个函数、一个 pair |
| 解决的问题 | 让后面的表达式不必重复写子表达式 | 让计算有结果，并能被绑定、传递、返回 |
| 关键区别 | 名字可以遮蔽。同一个名字在不同环境里可以指向不同值 | 值本身不被“改名”改变。`20` 不会因为后来有了另一个 `a` 而变成别的数 |
| 典型场景 | `val`、函数参数、`let` | 整数、布尔、`()`、以及后面会看到的函数值、list、datatype 值 |

| | Binding / Shadowing | Assignment |
|---|---|---|
| 定义 | 产生新环境，新名字映射到新值。旧映射保留但被遮住 | 改同一个盒子里的内容 |
| 解决的问题 | 引入局部名字，而不追溯修改已完成的计算 | 表达“世界里的这个位置变了” |
| 关键区别 | 已经用旧值算出的 `b` 不变 | 所有 alias 都看见新内容 |
| 典型场景 | ML 的 `val`、函数参数、`let` | Java 字段赋值、数组元素赋值。ML 要到 Section 3 的 `ref` 才显式提供盒子 |

### 3. 若改掉规则

- 若 `val` 是赋值：`val b = a * 2` 之后再 `val a = 5`，`b` 是否变化取决于 `b` 存的是值还是对 `a` 的引用。语言会被迫引入 identity 和 alias 分析。Section 1 后半会说明，这正是 ML 选择拿掉的负担。
- 若右边是惰性的、等到使用才算：`val b = a * 2` 再 `val a = 5` 之后使用 `b`，结果会依赖 `a` 的新绑定。那是另一门语言（Haskell 的方向）。本课要的求值规则是：binding 建立时，右边已经是值。
- 若允许向前引用：环境不能按顺序构造，shadowing 的“哪一个 `a`”也会变得无法局部判断。相互递归以后会用专门的构造处理，不是靠放宽这条规则。

---

## Lecture — 语言的五块，不要焊在一起

视频：`Pieces of a Language`。它在 Section 1 的最后，但概念上属于这一章：它规定整门课看什么、不看什么。

### 1. 先遇到的困难

只学 syntax，会写出无法推理的程序。只背库和工具，换一个实现就以为语言变了。把 REPL 说成“ML 的优点”，是把工具和语言焊死。这门课若把时间花在括号口味或文件 I/O 上，就教不会“一个构造是什么意思、通常怎么用”。

Grossman 的 pet peeve：`I like ML because it has a REPL.` 关于 ML **这门语言**，没有任何东西是 REPL。REPL 是某个实现提供的工具。

### 2. 五块

| 块 | 是什么 | 不学它会怎样 | 本课的态度 |
|---|---|---|---|
| Syntax | 构造怎么写 | 写不出程序 | 必要，通常无趣。他不评判哪种语法更好。内战结束于 1865 是史实，不是历史学 |
| Semantics | 类型规则 + 求值规则 | 只能试到撞见一个答案 | **课程中心**。正确推理靠这个 |
| Idioms | 一个构造通常该怎么用 | 语义懂了，仍写出能跑但别扭的程序 | **课程中心**。嵌套 helper 是惯用法，不是 `let` 的语义本身 |
| Libraries | 你写不了的（文件系统）或不必重写的（树、哈希表、列表） | 每个程序从零开始 | 要重学。列表后来会看到“其实我们能自己定义” |
| Tools | REPL、格式化、调试器 | 使用体验变差 | 实现的一部分，不是语言的一部分 |

Semantics 和 idiom 会迁移。库和工具总要重学。所以“换一门语言”的成本，主要不在 `val` 写成 `let` 还是 `def`。

小例子（`append`、`max`）看起来可笑。用同样的教学法去讲 Java、Python 或 JavaScript，那些语言也会看起来可笑。不要用本课的例子尺寸判断语言。Racket 能写桌面软件，Ruby 能写 Web。那不是这里的焦点。

他指回的 idiom，语义和惯用法要分开看：

```sml
fun countup_from1 (x : int) =
    let
        fun count (from : int) =
            if from = x then x :: [] else from :: count (from + 1)
    in
        count 1
    end
```

语义：`let` 引入 binding，`fun` 是一种 binding，作用域到 `end` 结束。惯用法：把 helper 嵌进去，使文件其余部分不能误用它，也不必把外层已经有的 `x` 再传一遍。

### 3. 用统一透镜看 `val` 和 `if`

| 透镜 | `val x = e` | `if e1 then e2 else e3` |
|---|---|---|
| Syntax | `val`、名字、`=`、表达式 | `if` / `then` / `else`，三个子表达式 |
| Semantics | 扩展环境 | 先测试，再只求一边 |
| Binding | 新绑定，可能遮蔽 | 本身不绑定名字 |
| Scope | 从这条 binding 之后，直到被遮蔽或环境结束 | 三个子表达式各自在当前环境里求值 |
| Evaluation | 右边立即求值 | 测试立即求值；落选分支不求值 |
| Type | `e` 的类型成为 `x` 的类型 | 测试必须 `bool`；两分支同类型 |
| Lifetime | 值活到还有环境指向它。遮蔽不销毁旧值，只是后续看不见 | 落选分支的值根本不产生 |
| Mutation | 无 | 无 |
| Abstraction | 给子表达式一个名字 | 把“两种可能”收成一个表达式 |
| Composition | binding 序列组成程序 | 分支本身可以是任意表达式，包括另一个 `if` |

---

## 对照

### Syntax vs Semantics

| | Syntax | Semantics |
|---|---|---|
| 定义 | 构造的合法写法 | 类型规则 + 求值规则 |
| 解决的问题 | 让程序能被写出、被解析 | 让所有使用者对“它做什么”达成一致 |
| 关键区别 | 偏好大量存在，他拒绝评判 | 没有偏好空间。用错了就是错 |
| 典型场景 | 分号、括号、`~` 与 `-` | `if` 只求一个分支；`val` 不修改旧环境 |

### Expression vs Value

| | Expression | Value |
|---|---|---|
| 定义 | 可以被求值的语法形式 | 求值到自身的表达式 |
| 解决的问题 | 组合计算 | 作为计算的终点，被绑定或返回 |
| 关键区别 | 可能嵌套、可能失败、可能不终止 | 已经没有下一步 |
| 典型场景 | `x + y`、`if ...`、函数调用 | `34`、`true`、`()`、函数本身（下一章） |

### Static environment vs Dynamic environment

| | Static environment | Dynamic environment |
|---|---|---|
| 定义 | 运行前，名字到类型 | 运行时，名字到值 |
| 解决的问题 | 在运行前拒绝一批程序 | 在运行时查找值 |
| 关键区别 | 失败意味着程序不运行 | 只对已通过类型检查的程序有定义 |
| 典型场景 | `x : int` | `x → 34` |

---

## Connection to Modern Languages

这些是概念类比，不是声称等价。

- Java / C# 的局部变量声明在“引入名字”这一点上像 `val`。但它们的变量默认是盒子：后面的赋值会改变已有映射。ML 的 `val` 不做那件事。
- Python 的 `x = 5` 在函数体内再次执行，通常是 rebinding，不是改盒子。这比 Java 的局部变量更接近 shadowing。但 Python 的对象内容仍可被方法改掉。名字的 rebinding 和对象的 mutation 是两层。本课到 Section 3 的 `ref` 才把第二层显式加回来。
- Rust 的 `let x = 5; let x = x + 1;` 就是 shadowing，官方文档也这么叫。这不是从 ML 抄来的语法糖，而是同一个环境模型。
- `Option` / `Result` 还没出现。但“类型通过仍可能在运行时失败”（`div` 零）已经说明：静态检查不是把所有失败都提前。它只提前它的规则看得见的那些。
- REPL 之于 ML，类似 `node` 的交互壳之于 JavaScript，或 `python` 的交互壳之于 Python。喜欢那个壳，不是喜欢那门语言的语义。

---

## Section checkpoint

这一段钉死的不变量：

```text
程序（到目前）= 一串 binding
每个构造 = syntax + typing rules + evaluation rules
val 扩展环境，不修改旧环境
shadowing ≠ assignment
表达式的语义对子表达式递归
value 求值到自身
if 只求一个分支
类型检查先于求值
REPL 是工具，不是语言
```

若这些还不稳定，不要进入函数。函数的形式规则就是把同一套三问用在一个新构造上。函数体在定义时不求值。那是下一章的第一刀。

概念题和代码推理题在 `exercises/section-01.md`。那份练习覆盖整个 Section 1，包括下一章的函数、列表和不可变。做前半即可检查本章。
