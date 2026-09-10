# 02.08 多重表示与分派：类型标记、操作表、消息传递

[返回全书路线](../../README.md) · [可运行题解](solutions.rkt) · [共用分派核心](dispatch-core.rkt)

- **阅读**：SICP 第二版 [§2.4.1–2.4.3][source]。
- **前置**：02.01 表示屏障；02.06 符号表达式与求导。
- **代表题**：2.73(a–d)、2.75。
- **共用范围**：`dispatch-core.rkt` 只供本单元与 02.09 使用；它实现真实操作表及复数两种内层表示，不在加载时运行自检。

## 1. 问题：让两种设计同时存在

02.01 是“换掉一种表示，上层不改”。现在更进一步：Ben 的直角坐标和 Alyssa 的极坐标都已经在用，不能要求所有模块统一重写。

复数 `z=x+iy` 有两种表示：

```text
直角坐标：(x . y)
极坐标：  (r . a)
x=r cos(a)，y=r sin(a)
r=sqrt(x²+y²)，a=atan(y,x)
```

两参数 `atan` 利用 x、y 的符号判断象限，不能简单替换成 `atan(y/x)`，否则 x=0 和第二/第三象限都会出问题。零向量的角度数学上未定；核心选择返回 0 作为直角坐标零的约定。极坐标输入要求半径非负且半径、角度为有限实数，角度用弧度。

加法适合直角坐标：实部分别相加、虚部分别相加；乘法适合极坐标：半径相乘、角度相加。

```scheme
(define (add-complex a b)
  (make-from-real-imag (+ (real-part a) (real-part b))
                       (+ (imag-part a) (imag-part b))))
```

这段代码的输入可以一边直角、一边极坐标，前提是 `real-part`、`imag-part` 已经能正确分派。现实数值库通常偏好直角坐标以控制转换舍入；教材在这里用两种表示主要说明模块组织，不是推荐每乘一次都做三角函数。

## 2. 类型标记让同样的 pair 不再歧义

裸 `(3 . 4)` 到底是 `3+4i`，还是半径 3、角度 4？必须带标签：

```text
(rectangular . (3 . 4))
(polar       . (3 . 4))
```

`attach-tag` 附加标签；`type-tag` 取标签；`contents` 去掉**一层**标签。包内部处理自己的裸数据，跨越包接口时才附加或移除标记。

一种直观写法是在每个选择器里写 `cond`：遇到 rectangular 调 Ben 的过程，遇到 polar 调 Alyssa 的过程。这叫显式类型分派，能工作，但每增加一种表示都要修改所有选择器。

## 3. 操作表：把条件分支变成可安装的条目

概念上有一个二维表：

| 操作 / 类型 | rectangular | polar |
| --- | --- | --- |
| real-part | 取 car | r cos(a) |
| imag-part | 取 cdr | r sin(a) |
| magnitude | sqrt(x²+y²) | 取 car |
| angle | atan(y,x) | 取 cdr |

核心以关联表实现 `put`、`get`，键是 `(操作, 类型签名)`，值是过程。相同键再次 `put` 会更新已有方法。这个小表用赋值安装条目是基础设施细节，不需要提前把第三章的表系统整个引入。

```scheme
(put 'real-part '(rectangular) car)
(put 'real-part '(polar)
     (lambda (z) (* (car z) (cos (cdr z)))))
```

类型签名用列表 `(rectangular)`，因为未来操作可有多个参数，签名可能是 `(rational complex)`。构造器则已知要造什么类型，用如 `('make-from-real-imag,'rectangular)` 的键直接取出，不需要从尚不存在的对象上读取标签。

通用过程做三件事：

```text
取全部参数标签 → 按(操作,签名)查方法 → 去一层标签后 apply
```

文件的 `dispatch` 对应教材此节的 `apply-generic`，另取名字便于下一单元实现有强制转换的新版本。`get` 找不到返回 `#f`，`dispatch` 将它变成明确错误，不试图把 `#f` 当过程应用。

### 追踪一次跨表示加法

```text
r = make-from-real-imag(3,4) → rectangular(3,4)
p = make-from-mag-ang(2,0)   → polar(2,0)
add-complex(r,p)
  real-part(r) → dispatch → get(real-part,(rectangular)) → car(3,4) → 3
  real-part(p) → dispatch → get(real-part,(polar)) → 2 cos 0 → 2
  imag-part(r) → 4；imag-part(p) → 2 sin 0 → 0
  make-from-real-imag(5,4) → rectangular(5,4)
```

上层没有分支检查 polar；表示变化被限制在安装包里。文件也实际验证 `r×p` 的实/虚部分别约为 6、8。三角函数会产生近似数，测试使用 `1e-10` 容差，而不是要求和精确整数逐位相同。

## 4. 习题 2.73：把符号求导改成数据导向

### (a) 改变了什么，为什么原子仍特殊处理？

**题意概述**：用表达式的操作符作为“类型”，将求导过程改为查表调用，并解释数字/变量为何不能直接并入现有分派。

原来的 `sum?`、`product?`、幂分支现在变成 `get('deriv, operator(exp))`。操作符如 `+`、`*`、`**` 是这个代数系统的类型标记；方法接收 `operands(exp)` 和求导变量。

数字 `3`、符号 `x` 并不是 `(operator . operands)` 形式，不能先对它们调用 `car/cdr`；`same-variable?` 又需要比较表达式和求导变量，不是简单按列表首项挑方法。所以保留这两个分支：

```scheme
(cond ((number? exp) 0)
      ((symbol? exp) (if (eq? exp var) 1 0))
      (else ...查表...))
```

这不是说数据导向在原则上不能处理原子。可以改为显式 `number/variable` 标签或合成标签，但那改变了题目现有表示协议；没有先改协议，就不能把 `number?` 塞进 `get` 当作已经存在的类型标记。

### (b) 和与积的方法及安装

和方法收到 `(a b)`，返回 `make-sum(D(a),D(b))`；积方法返回 `make-sum(make-product(a,D(b)),make-product(D(a),b))`。文件 `install-derivatives` 内有这两个完整 lambda，并安装到表里。

```scheme
(put 'deriv '+ sum-method)
(put 'deriv '* product-method)
```

其中 `sum-method`、`product-method` 是上述过程值的说明性名字；可运行文件直接注册 lambda。局部化简构造器仍处理 0、1 与常数运算，这个责任没有移入分派器。

以 `D((* x y),x)` 为例：

```text
operator = *，operands = (x y)
get(deriv,*) → 乘积规则过程
过程递归求 D(x)=1、D(y)=0
构造 x×0 + 1×y → y
```

查表只选择规则，不替规则完成数学工作。

### (c) 安装额外的幂规则

本单元选择 2.56 的常指数幂规则：

```text
D(u^n) = n u^(n-1) D(u)
put(deriv,**, 幂规则过程)
```

实现检查指数不依赖当前变量，接受数字常量和符号常量；`D(x^n,x)` 返回 `(* n (** x (+ n -1)))`，`D((x+1)^3,x)` 返回 `(* 3 (** (+ x 1) 2))`。`x^x` 报错，因为需要新的变指数规则，而不是这个幂规则。添加这一条只增加安装内容，不修改 `deriv-with` 的分派分支。

### (d) 如果把两个索引反过来？

题目改成 `get(operator(exp),'deriv)`，必须同步将所有安装改为：

```scheme
(put '+ 'deriv sum-method)
(put '* 'deriv product-method)
(put '** 'deriv power-method)
```

数学过程体、表达式的操作符/操作数表示不必改变；所有读写同一个表的地方必须遵循同一键顺序。只改 `get` 不改 `put` 会查不到方法。

文件确实提供 `deriv-reversed` 并另行安装反向索引条目，递归调用也使用同一方向的求导器。`install-derivatives` 接收注册过程和递归求导过程，避免复制整套规则；两种方向都执行相同的数值、和、积、幂及错误自检。

## 5. 习题 2.75：消息传递的极坐标构造器

**题意概述**：仿照教材直角坐标版本，返回一个按消息名响应的极坐标复数对象。

```scheme
(define (make-from-mag-ang-message r a)
  (lambda (op)
    (cond ((eq? op 'magnitude) r)
          ((eq? op 'angle) a)
          ((eq? op 'real-part) (* r (cos a)))
          ((eq? op 'imag-part) (* r (sin a)))
          (else (error "unknown message" op)))))
```

文件构造前还检查半径/角度边界。设 `z=(make-from-mag-ang-message 5 (atan 4 3))`：`(z 'magnitude)` 得 5，`(z 'real-part)` 约为 3，`(z 'imag-part)` 约为 4。值 z 本身是捕获 r、a 的过程；通用调用只是 `(z op)`，无需全局操作表，也无需取类型标签。

消息传递并不是网络消息，也不要求异步或可变状态；此对象完全可以只读。教材这个简单组织主要面向一元操作，多参数混合类型运算不能仅凭“让第一个对象处理消息”就自动解决。

## 6. 三种组织的取舍

| 组织 | 添加类型 | 添加操作 |
| --- | --- | --- |
| 显式分派 | 修改各操作中的类型分支 | 新建操作过程，列出各类型分支 |
| 数据导向表 | 安装该类型的一列条目 | 安装该操作的一行条目 |
| 消息传递 | 新建一个对象构造器及消息分支 | 修改所有对象的消息分支 |

表有利于独立添加类型/操作，但仍要定义完整的方法、处理缺失组合与键冲突，不是“任何扩展都零成本”。消息传递适合类型不断增加而消息协议较稳定的情形；显式按操作组织在操作不断增加、类型较稳定时也很直接。不要把组织方式当作必须争出一个永远最优的范式。

## 7. 运行与已回答回顾

```sh
racket units/02-08-multiple-representations/solutions.rkt
```

输出 `02.08: all checks passed`。它通过相对路径加载核心；测试涵盖两种表示、跨表示加乘、2.73 两种索引方向、幂规则、全部四种消息、未知消息/方法与非法半径。

**已回答回顾**：类型标签告诉系统怎样解释内容；数据导向把“操作×类型”关系变成表；消息传递让数据对象自己选择操作。02.09 在同一张操作表上再加一层：不仅两种复数表示共存，还让普通数、有理数、复数与多项式以通用算术协作。

[source]: https://mitp-content-server.mit.edu/books/content/sectbyfn/books_pres_0/6515/sicp.zip/full-text/book/book-Z-H-17.html
