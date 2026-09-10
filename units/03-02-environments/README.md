# 03.02 环境模型：名字在哪里，修改落在哪里

[返回全书路线](../../README.md) · [可运行题解](solutions.rkt)

- **阅读**：[§3.2.1–3.2.4][source]；前置：03.01。
- **完整题解**：3.10、3.11。

## 用“绑定位置”替代机械代换

有赋值后，名字不只是一个可替换的值。**框架**保存一组名字到值的绑定；**环境**是框架及其外围环境组成的链。一次名称查找从当前框架往外走，最先找到的绑定胜出。两个框架里同名的 `balance` 是两个位置。

过程对象可以画成“参数、过程体、定义时环境指针”。规则是：

1. 求值 `lambda` 时建立过程，不执行过程体，保存**定义处**环境。
2. 应用复合过程时建立调用框架，把形参绑定到实参值；外围是过程保存的环境，**不是调用者的环境**。
3. `define` 在当前框架建立绑定；`set!` 沿环境链找到已有绑定后更新它。未绑定名字不能靠 `set!` 自动变成全局变量。

词法作用域解释了为什么调用者恰好有一个同名局部变量，也不会接管闭包里的状态。箭头是引用，不是把整条环境链复制一份。

## 3.10：用 let 建立余额，多了哪个框架

**题意**：将 `make-withdraw` 的初始参数命名为 `initial-amount`，再以 `let` 创建 `balance`；分析 `W1`、提款以及 `W2`，与直接用参数 `balance` 的实现比较。

```scheme
(define (make-withdraw initial-amount)
  (let ((balance initial-amount))
    (lambda (amount)
      (if (>= balance amount)
          (begin (set! balance (- balance amount)) balance)
          "Insufficient funds"))))
```

`let` 等价于 `((lambda (balance) ...) initial-amount)`。因此 `(define W1 (make-withdraw 100))` 建立两层，不是一层：

```text
G: make-withdraw → [参数 initial-amount, 过程体, env=G]
   W1 ────────────────────────────────┐
                                     ↓
E1: initial-amount=100 → G       [参数 amount, 提款体, env=E2]
E2: balance=100 → E1                 ↑
                                    │
调用 (W1 50): E3: amount=50 ───────→ E2
```

`E3` 查不到 `balance`，沿箭头在 `E2` 找到 100；写成 50，再返回 50。`E1.initial-amount` 仍是 100。`E3` 不再需要后可回收；`E2` 被 W1 引用，不能回收。

再创建 W2：

```text
W1.env → E2: balance=50  → E1: initial-amount=100 → G
W2.env → E5: balance=100 → E4: initial-amount=100 → G
```

两条私有链共享全局环境，不共享余额。原实现以 `balance` 直接作为 `make-withdraw` 参数，省掉 `let` 的一层框架；两个版本对合法提款请求有相同的可观察行为。新增的初值绑定并不随着余额更新，这正是图比一句“闭包捕获变量”更精确的地方。

## 内部定义不是全局过程

在 `make-account` 的一次调用里执行 `define withdraw`、`define deposit`、`define dispatch`，这些名字进入那次调用的局部框架。三个过程各自保存指向该框架的指针。因此不同操作能共享同一个余额，而不暴露余额绑定给外部。

内部定义允许局部过程相互引用；第四章会用预建绑定/扫描定义精化这种语义。此处不把“源码从上到下”误解成可以随意在变量初始化前读取其值。函数体中引用另一个尚未初始化的名字，只要等初始化完成才执行，和立即读取它不是一回事。

## 3.11：一次账户，三个闭包，一个余额

**题意**：画出 `(make-account 50)`、存 40、取 60 的环境，说明新账户 `acc2` 的独立性和共享部分。完整过程见代码。

```text
G: make-account → [参数 balance, 账户体, env=G]
   acc → dispatch_A                  acc2 → dispatch_B

A: balance=50 →90 →30                B: balance=100
   withdraw  → [amount, ..., env=A]     withdraw → [..., env=B]
   deposit   → [amount, ..., env=A]     deposit  → [..., env=B]
   dispatch  → [m, ..., env=A]          dispatch → [..., env=B]
   outer=G                             outer=G
```

`((acc 'deposit) 40)` 有**两次**应用：

1. 调用 `dispatch_A`，临时框架 D 的 `m='deposit`，外围是 A；返回 `deposit_A`，此时余额未动。
2. 应用返回的过程，框架 P 的 `amount=40`，外围还是 A；查找并更新 A.balance 为 90。

提款同理：消息调用返回 `withdraw_A`，提款调用框架的 `amount=60`，读写 A.balance，最后为 30。调用框架 P 并不挂在 D 下面：调用顺序不是词法外围关系。

`acc2` 创建新框架 B。两个账户共享 G、全局的算术原语，以及可共用的过程**代码**；不共享 A/B 的余额绑定或捕获环境不同的操作闭包。把 `(acc 'deposit)` 保存到另一个名字，仍可访问 A；它不是余额的快照。

## 取舍与边界

环境图是语义模型，不规定解释器一定分配这些物理堆对象；优化可以消掉无用框架，只要可观察行为相同。教材账户为了突出环境，接受数值金额，并没有完整的金融输入规则；本单元保持题目代码，不将其宣称为生产账户。错误消息分派会抛错，自检捕获并确认；提款不足返回教材字符串且余额不变。

## 运行与已回答回顾

```sh
racket units/03-02-environments/solutions.rkt
```

输出 `03.02: all checks passed`。检查题目余额 50/100 与 90/30、保存操作闭包后的共享状态、失败不写入、未知消息报错。环境图的绑定关系是语义推导，测试用可观察读写来印证，并非读取宿主内部堆布局。

- **闭包捕获调用现场吗？** 捕获定义环境；应用时再创建形参框架。
- **两个账户共享什么？** 全局环境与代码可共享，私有余额不共享。
- **下一步**：03.03 把共享从变量位置扩展到 pair 槽，别名便会影响整张数据图。

[source]: https://mitp-content-server.mit.edu/books/content/sectbyfn/books_pres_0/6515/sicp.zip/full-text/book/book-Z-H-21.html
