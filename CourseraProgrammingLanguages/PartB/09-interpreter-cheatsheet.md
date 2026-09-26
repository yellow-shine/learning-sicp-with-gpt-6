# Interpreter Cheat Sheet

来源是 Section 6。教学语言用 `const` / `fun` / `call`。作业语言 MUPL 用 `int` 等名字，还有这里没列的构造。这是语义卡片，不是作业解答。

## 词

| 词 | 是什么 | 不是什么 |
| --- | --- | --- |
| Expression | 一棵 AST。还没求值 | 不是值，除非它本来就是 value |
| Value | 求值到自身的表达式。算术语言里是 `const`；扩大后还有 `bool`、值为值的 pair、closure | 不是宿主语言的裸 `7` 或 `#t` |
| AST | 用 struct 构造器写成的树。作业跳过 parser，人直接写树 | 不是源码字符串，也不是解释器 |
| Environment | 变量名（Racket string）到对象语言 value 的表。建议是 pair 的 list | 不是调用栈，不是对象语言的 list 值 |
| Closure | 函数代码 + 定义时的环境。这才是函数值 | 不是函数 AST，不是函数指针 |
| Evaluation | `eval(expr, env) → value` | 不是 parsing，不是 macro 展开 |
| Function application | 先得到闭包和参数值，再在闭包环境上求值体 | 不是在调用者环境里求值体 |

宿主语言是 Racket。对象语言是你在实现的 B。`(+ 3 4)` 若出现在建树阶段，做的是 Racket 加法；对象语言的加法只发生在 `eval` 看见 `add` 节点时。

## 总公式

```text
eval(expr, env) → value

eval-exp(program) = eval(program, empty)
empty = 没有任何绑定的表
```

合法 AST 可以假设。不是合法 AST（`(negate -7)`、`(const #t)`）可以崩溃。递归返回的值种类必须检查。解释器的每次返回都必须是 value。返回还没算完的 `add`，是解释器的 bug。

## 算术与条件

```text
eval(Const n, env) = Const n

eval(Negate e, env) =
    let v = eval(e, env) in
    if v 是 Const then Const(- n)
    else error "negate applied to non-number"

eval(Add e1 e2, env) =
    let v1 = eval(e1, env)
        v2 = eval(e2, env) in
    if 两者都是 Const then Const(n1 + n2)
    else error "add applied to non-number"

eval(Bool b, env) = Bool b

eval(EqNum e1 e2, env) =
    同 Add 的检查
    然后 Bool(n1 与 n2 是否相等)
    不要返回宿主语言的 #t

eval(If e1 e2 e3, env) =
    let v = eval(e1, env) in
    if v 不是 Bool then error
    else if 取出的布尔为真 then eval(e2, env) else eval(e3, env)
```

宿主语言的 `+` 和 `if` 是实现工具。它们的结果要包回对象语言的构造器，才算 `eval` 的返回值。

## 变量

```text
eval(Var x, env) =
    lookup(env, x)  或  error "unbound variable"

eval(Let x e1 e2, env) =
    let v = eval(e1, env) in
    eval(e2, extend(env, x, v))
```

加法、条件的子表达式传递同一个 `env`。`let` 的初始化用旧环境，体用多了一对的环境。视频把“体需要更大的环境”讲死了；多个绑定各自看见谁，以作业说明为准。

`eval-under-env` 留在文件顶层，是评分脚本要直接调用它，不是语义要求。

## 函数

```text
eval(Fun, env) → Closure(Fun, env)

eval(Closure c, env) → c
```

函数 AST 不是值。闭包才是。源程序不该写 `closure` 构造器；解释器在求值 `fun` 时造它。测试可以手写闭包。

```text
eval(Call(e1, e2), env) =
    1. c = eval(e1, env)          用调用者环境
       c 不是 Closure → error
    2. v = eval(e2, env)          仍用调用者环境
    3. env_body = c.env           从这里起不再用调用者环境
                 + 参数名 ↦ v
                 + 函数名 ↦ c      整个闭包，不是函数 AST
    4. eval(c.body, env_body)
```

三条不变量：

```text
查找必须用这次传入的环境。
函数值必须携带定义时环境。
调用必须基于闭包环境，而不是 caller environment。
```

用调用者环境求值体，得到的是动态作用域。那是 bug。

```text
定义时 x → 10 的 λy. x+y，在 x → 20 的环境里用 3 调用
词法：13
误用调用者环境：23
```

## 可选的空间优化

闭包不必保存整个环境。保存自由变量的绑定就够：体里出现、又不是参数或函数内局部变量的名字。两个分支各用一个外层变量时，两个都要留，因为都可能被查找。

不要在每次造闭包时扫描函数体。求值前的预遍算一次，存在函数上或侧表里。环境的 list 可以换成平衡树或哈希表，规则不变。作业可以用 list。

编译到没有闭包的语言时：每个函数多一个环境参数，每个调用多传一个，自由变量的使用变成在这个参数里查找。函数值仍是闭包。

## 旁边的 macro

Racket 函数若把对象语言的树变成树，它在 `eval-exp` 之前就已经跑完。解释器看不到它的名字，也不需要新 struct。

```text
(andalso e1 e2)  →  if-then-else 树，不是 andalso 节点
(list-product es) 造嵌套 multiply，不在这时做乘法
```

这种 macro 不卫生。对象语言有变量时，生成的名字要自己避开。不要在造树函数里调用 `eval-exp`，否则就不是展开，而是提前运行。

## 一张图

```text
        源程序里的 fun 节点
                │ eval(fun, env_def)
                ▼
        Closure(code, env_def)     ← 这是值，可以传给别的函数
                │
        某处 call(这个闭包, arg)
                │ eval arg 用 env_caller
                ▼
        env_body = env_def + arg + name↦closure
                │
                ▼
        eval(body, env_body) → value
```
