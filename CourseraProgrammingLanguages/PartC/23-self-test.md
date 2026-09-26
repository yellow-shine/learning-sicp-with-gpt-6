# Self-Test

先做题。答案在文末，每题两三句，用来核对模型，不是另一份笔记。

## 1 Ruby 语言模型

1. 为什么这门课用 Ruby，而不是继续用 Racket 或直接用 Java？
2. Dynamic typing、dynamic dispatch、dynamic class definition、duck typing，各问的是什么问题？
3. “一切皆对象”排除了哪些例外？`nil` 仍带来什么麻烦？
4. `3.+(4)` 和 `3 + 4` 是什么关系？`puts` 的返回值在 REPL 里为什么会显示出来？
5. 先 `x = MyRational.new(...)`，再重开 class 加上 `double`。`x.double` 该不该成功？为什么这是一个语义选择？
6. 若你要在 C++ 里模仿“运行时给已有对象的类加方法”，缺的是哪一条 Ruby 语义？你会用什么别的机制代替？

## 2 对象、状态、封装

1. Receiver 和 self 在一次调用的哪个时刻变成同一个对象？
2. 为什么不准写 `r.@num`？protected getter 解决的是哪一种跨对象需求？
3. `initialize` 特殊在哪里？特殊点是不是“只有它能创建实例变量”？
4. `x = A.new; z = x; y = A.new; x.m1` 把 `@foo` 设为 0。`z.foo` 和 `y.foo` 各是什么？
5. `q.foo = 19` 在有 `foo=` 方法时发生了几次方法调用相关的事？它一定写入了 `@foo` 吗？
6. 摄氏温度的 setter 内部存开尔文。若改成公开 `@kelvin`，客户代码会怎样变脆？

## 3 Block、Proc、闭包

1. 为什么说 block 是 second-class？
2. `yield` 在这门课里是什么意思？没传 block 时怎样？
3. 闭包比函数指针多了什么？
4. `i = 7; [4,6,8].each { |x| puts x if i > x }` 打印什么？`i` 从哪个环境来？
5. `a.map { |x| lambda { |y| x >= y } }` 为什么不能把内层 `lambda` 换成裸的 block？
6. 若一个 API 需要两个回调，Ruby 的“至多一个 block”逼你做什么设计？

## 4 继承与覆盖

1. Ruby 的 subclass 继承的是什么，不是什么？
2. `is_a?` 和 `instance_of?` 差在哪里？Java 的 `instanceof` 更像哪一个？
3. 什么时候内嵌一个 Point 比 subclass ColorPoint 更合适？ColorPoint 这个具体例子为什么老师仍选 subclass？
4. `ColorPoint#initialize` 里写 `initialize(a, b)` 会怎样？`super` 调用的是哪个对象的哪段代码？
5. `PolarPoint` 为什么必须覆盖直接读 `@x` 的 `distFromOrigin`，却可以不覆盖 `distFromOrigin2`？
6. 给你一个“学生是一个人，又持有一张学生证”的设计，subclass 和内嵌各该用在哪一层？

## 5 Dynamic dispatch

1. 写出 `e0.m(e1)` 的四步求值规则。哪一步使子类覆盖可见？
2. `@x` 的查找为什么不叫 dynamic dispatch？
3. `method_missing` 在链的什么位置被调用？
4. `class A; def m; 1; end; end; class B < A; def m; 2; end; end; B.new.m` 的查找停在哪？
5. `Point#distFromOrigin2` 的源码在 Point 里。对 `PolarPoint` 实例调用它时，`self.x` 的查找从哪个 class 开始？
6. 库作者希望你扩展行为，又不希望你覆盖某个 helper。Ruby 和 Java 各有什么课程里提过的办法？

## 6 闭包 vs 对象

1. ML 里后定义的 `even` 为什么不影响已经创建的 `odd`？
2. `B < A` 只覆盖 `even` 时，`B.new.odd(7)` 为什么可以只打印两次左右就返回？
3. 这个开放是机会还是缺陷？课程给的答案是什么？
4. 手动 Racket 编码里，`send` 的哪一行实现了 dynamic dispatch？`self` 这个名字特殊吗？
5. 若 `C#even` 永远返回 false，`C.new.odd(7)` 的结果是什么？这依赖 `odd` 的哪一个实现细节？
6. 你要在库里留一个“客户填一步”的洞。什么时候传 Proc，什么时候用可覆盖的方法？

## 7 Duck typing

1. `mirror_update` 的最精确契约是什么？为什么老师说这时文档几乎等于方法体？
2. Duck typing 和 dynamic dispatch 能否同时发生在同一次调用上？
3. 为什么 `double` 被当成好例子，`mirror_update` 被当成差风格？
4. `foo(a)` 只调用 `a.count { ... }`。传入 range 为什么能工作？
5. 客户依赖 `x + x`。你把实现改成 `x * 2`。在什么前提下这是错的？
6. 为一个几何库设计公开 API：哪些操作适合写成“任何有这个方法的对象”，哪些必须写明不变量？

## 8 分解方向

1. 课程里的表，行是什么，列是什么？FP 按哪一边组织？
2. 写解释器和写 GUI，老师自己的偏好各是什么？他有没有说这是客观最优？
3. 静态类型在 `Negate#eval` 上强迫 ML 做了哪件 Ruby 不必做的事？这属于分解问题吗？
4. 给 `eval` 的 `Int` 分支和 `Int#eval`。它们填的是同一格吗？
5. `Add#eval` 向子表达式发 `eval`。若子表达式后来可以是 `Mult`，旧的 `Add` 方法体要不要改？
6. 一个编译器前端，今后更可能加 AST 节点，还是更可能加分析遍数？你选哪种分解？若两种都可能呢？

## 9 表达式问题

1. 不预先规划时，哪种扩展对 FP 是局部的，哪种对 OOP 是局部的？
2. ML 的类型检查器何时会在你加构造子之后给出待办清单？
3. Visitor 在课程里被讲到了哪一步？没讲到哪一步？
4. `noNegConstants` 对负整数常量做什么？它是 `exp -> bool` 吗？
5. Java superclass 新增一个抽象操作之后，旧子类会得到什么样的错误？这对应 ML 的什么？
6. 预留 `other` 或 visitor 之后，阅读 `eval` 为什么变难？语言用什么构造主动禁止扩展？

## 10 Double dispatch

1. Binary method 难在哪里？普通的两参数方法都算吗？
2. 为什么 `is_a?` 版本被说成半吊子？作业为什么不许？
3. 九个格子在完整 OOP 版本里是几个方法？
4. `Int` 加 `MyString`：从 `Add#eval` 走到最终拼接，两个 receiver 依次是谁？
5. 在 `addString` 方法体里，self 是左操作数还是右操作数？为什么拼接顺序容易错？
6. 若加法的一种组合可交换，ML 和 Ruby 各有什么课程推荐的减少复制的办法？

## 11 Multimethods

1. Multiple dispatch 比 single dispatch 多看了什么？
2. 为什么老师不建议把 multimethods 加进 Ruby？
3. Static overloading 对九格加法实际帮了什么，没帮什么？
4. Clojure 在这讲里的角色是什么？
5. C# `dynamic` 改变的是选择发生的时间，还是方法的名字？
6. 一种语言若经常写几何碰撞（形状 × 形状），单分派加 double dispatch 和内建 multimethod，各付出什么？

## 12 Mixin、接口、多继承

1. 多继承把 class hierarchy 从什么变成什么？
2. `ColorPt3D` 和 `ArtistCowboy` 对同名字段的需求为什么不能用一条规则同时满足？
3. Mixin 方法为什么比复制粘贴更强？强在 self 的哪一种用法？
4. `include Comparable` 之后，`<` 的方法体在哪里？它调用宿主的什么？
5. Interface 给实现者的是代码还是义务？它让类型系统相对“只有单继承”多了什么，相对 Ruby 仍少什么？
6. 你要复用 `darken`，又要 `StudentAthlete` 同时是两个类。Mixin 够不够？哪一个例子不够？

## 13 Subtyping

1. 为什么不直接改“实参类型必须等于形参类型”这条规则？
2. Substitutability 怎样判定 width 合法、depth 在有 setter 时不合法？
3. 四条初步规则里，哪两条不增加“忘掉字段”的能力，但没有它们关系不好用？
4. `{x:real, y:real, color:string}` 是 `{y:real, x:real}` 的 subtype 吗？用哪几条规则？
5. `setToOrigin(sphere)` 之后，哪一行会在运行时失败？类型检查器为什么没拦住？
6. 你在设计一种 record。用户强烈要求嵌套字段也能 subtype。你必须放弃哪两件事中的一件？

## 14 函数与 OOP 的 subtyping

1. 协变和逆变各对应函数类型的哪个位置？
2. 为什么 `flipIfGreen` 不能传给 `distMoved`，`flipX_Y0` 可以？
3. `Animal -> Dog` 当作 `Dog -> Animal` 时，参数那一步和返回那一步各靠什么替换？
4. Java 允许覆盖时怎样改变返回类型？参数类型变了通常算什么？
5. 一个类拥有 Point 的全部方法，但没有 `extends Point`。它是 Point 的 subtype 吗？在 Section 10 的 record 规则下呢？
6. 若把 `this` 当成普通参数并要求逆变，子类方法还能否访问子类自己的字段？课程怎样说明这并不 unsound？

## 15 Generics 与 subtyping

1. `'a -> 'a` 重复出现的 `'a` 在强制什么？它有没有说 `'a` 是某类型的 subtype？
2. 泛型出现之前，Java 的 pair 读出元素时必须做什么？三笔代价是什么？
3. ML 的 `distToOrigin` 为什么拒绝带 color 的 record？绕法把什么责任推给调用者？
4. `identity` 的方法体能不能调用 `x.speak`？`f(Animal x)` 能不能不经 downcast 调用 `x.speak`？
5. GUI 超类型只有 `resize` 和 `onClick`。传入带菜单栏的对象，靠的是 generics 还是 subtyping？
6. 一个容器库要同时提供 `map` 和“把彩色点当点画出来”。两种多态各适合哪一个 API？

## 16 Bounded polymorphism

1. `List<ColorPoint>` 为什么不是 `List<Point>` 的 subtype？给出课程的两个理由。
2. 不受约束的 `<T> List<T> inCircle(List<T>)` 为什么方法体过不了检查？
3. `T extends Point` 同时保留了哪两句真话？
4. 调用 `inCircle` 于 `List<ColorPoint>` 时，发生的是 subtyping 转换还是泛型实例化？结果类型是什么？
5. Java 泛型相比 ML 多态，课程承认的漏洞是什么？
6. 若集合不可变，课程是否因此宣布 `List<ColorPoint> <: List<Point>`？你该如何区分课程结论和这个推论？

---

# Answer Key

## 1

1. Ruby 是纯的、class-based 的、动态类型的 OOP，用来填 2×2 表的右下角。Racket 能做对象，但不是一切皆对象。Java 的类型系统会挡住对 dispatch 本身的学习。
2. 错误何时发现；选哪段方法体；方法表能否在运行中变；契约是 class 名还是消息。
3. 数字、`nil`、class、顶层方法都在对象模型里。`nil` 仍为假，对它发不支持的消息仍失败。
4. 前者是后者的去糖。REPL 打印表达式结果，`puts` 返回 `true`。
5. 该成功。Ruby 在调用时查当前方法表。这是设计选择；静态语言可以不问这个问题。
6. 缺的是运行时修改 class 且旧对象可见。代替物是新子类、函数对象，或重新编译。不是把非 virtual 调用说成一样。

## 2

1. 方法体开始执行时。查找选定方法之后，`self` 被绑成 receiver。
2. 实例变量只属于该对象。另一个有理数要读你的分子，必须通过你提供的方法；protected 允许同类或子类的其他对象调用，同时拒绝外人。
3. `new` 在返回前调用它，并把参数传给它。实例变量在任何方法里第一次赋值都会出现。在 `initialize` 里创建只是好风格。
4. `z.foo` 是 0，因为别名。`y.foo` 是 `nil`。
5. 这是一次对 `foo=` 的调用。不必然写入 `@foo`。setter 可以写别的表示。
6. 客户会依赖字段名和单位。改表示就要改所有客户。方法接口可以把单位转换藏起来。

## 3

1. 它不是表达式的结果，不能返回、不能放进数组，收到它的方法只能 `yield`。
2. 立刻调用当前方法收到的那个 block，并可传参。没传则 `no block given`。
3. 定义时的环境。否则返回后 `n` 或 `x` 就没了。
4. 打印 4 和 6。8 不打印，因为 `7 > 8` 为假。`i` 来自 block 定义处，不是 `each` 内部。课堂原例打印的是 `x + 1`，所以是 5 和 7；本题打印的是 `x` 本身。
5. `map` 的 block 体要一个表达式。裸 block 不是表达式。`lambda` 的调用结果才是。
6. 一个用 block，另一个用 Proc 参数。或者两个都用 Proc。语言不让你贴两个 block。

## 4

1. 继承方法。不继承一份字段声明。不自动建立 subtype 关系；那是别的语言的选择。
2. `is_a?` 包括 superclass。`instance_of?` 只要精确 class。Java `instanceof` 像 `is_a?`。
3. 当 Point 只是实现细节，对外不该是 Point，或方法名不该相同。ColorPoint 的意图是“就是点，外加颜色”，所以 subclass 更合适，内嵌会让 `is_a? Point` 为假。
4. 无限递归。`super` 在同一个对象上执行 superclass 的那段方法体，没有单独的父类实例。
5. 前者读 `@x`，polar 对象上没有，得到 `nil`。后者发 `self.x`，查找从 `PolarPoint` 开始，用 r 和 theta 计算。
6. 学生 subclass 人，若你真的要 is-a 和继承来的方法。学生证是持有的另一对象，该是字段，不该是第二个 superclass。

## 5

1. 先求值 receiver 和参数；取 receiver 的 class；沿 superclass 找第一个 `m`，没有则同样找 `method_missing`；执行时形参绑定参数，`self` 绑定 receiver。最后一步让方法体里的再调用从子类开始。
2. 它只在 self 这个对象的状态里找名字，不选代码。
3. 整条类链都没有 `m` 之后，从 receiver 的 class 重新开始找 `method_missing`。`Object` 提供默认报错实现。
4. `B`。`B` 自己定义了 `m`。
5. `PolarPoint`。方法体定义在哪不决定这次查找的起点。
6. Ruby：private，限制调用形式。Java：`final`，禁止覆盖。两者都在用“更不 OOP”换局部推理。

## 6

1. `odd` 的闭包按词法作用域捕获同时定义的那个 `even`。后面的绑定只是遮蔽名字。
2. 继承的 `odd` 向 self 发 `even`。self 的 class 是 `B`，于是用常数时间的 `B#even`，不再来回递归。
3. 两者都是。可以不改旧代码改变行为；也不能再孤立地相信 `odd` 的源码。
4. 调用 lambda 时把整个对象当作第一个参数传进去。名字不特殊。
5. `false`。依赖 `odd` 确实调用了可覆盖的 `even`。库若改掉这个调用，子类的技巧失效。
6. 填入者是调用点的一段计算，用 Proc/block。填入者是一种对象的变体，并且旧代码要通过 self 回调到它，用可覆盖方法。

## 7

1. 对参数发 `x`，对其结果发 `*` 和 `-1`，再把结果发给 `x=`。因为没有任何 class 或表示被隐藏，客户等于看到了整段实现。
2. 能。不检查是不是 Point 是 duck typing；若 `x` 在子类里被覆盖，选中哪段 `x` 是 dispatch。
3. `double` 的全部含义就是 `+`。`mirror_update` 其实依赖点的不变量，只看方法名会接受不该接受的对象，并阻止以后改实现。
4. Range 也有接受 block 的 `count`。函数要求的是这个消息，不是 Array。
5. 在客户可能传入把 `+` 和 `*` 实现得不同的对象时。对数字两者等价，不足以让程序变换合法。
6. `move_to` 这类依赖坐标不变量的操作应文档化类型或协议，不要接受任意 `x=`。`double` 或 `each` 这种单消息迭代适合薄契约。

## 8

1. 行是变体，列是操作。FP 按列，一个函数配一组 case。
2. 解释器偏 FP，GUI 偏 OOP。他说这可以是口味；若你知道扩展方向，就不再只是口味。
3. 必须处理求值结果不是 `Int` 的情况。这是静态对动态，不是行对列。
4. 是。同一格，一个在 `eval` 的分支里，一个在 `Int` 的方法里。
5. 不用。查找按子表达式的 class 走，新 class 的 `eval` 会被选中。
6. 更常加节点就偏 OOP；更常加分析就偏 FP。两种都可能时，其中一种会别扭，或者预先留扩展口并接受更难推理。没有免费的双向局部扩展。

## 9

1. FP 局部加操作。OOP 局部加变体。
2. 旧的模式匹配没有用通配吞掉未知构造子时。
3. 讲了：它是 OOP 侧预先让每个类接受 visitor、从而以后能加操作的惯用法名字。没讲 visitor 的方法怎么写。
4. 负的 `Int i` 变成对 `-i` 的 `Negate`。它是 `exp -> exp`，不是布尔函数。老师先口误过。
5. 子类缺少该方法，编译失败。对应 ML 的非穷尽匹配警告或错误。
6. 因为可能还有没放在眼前的变体或操作，其行为仍会被动态分派或高阶函数叫到。ML 模块可以藏起 datatype；Java `final` 可以禁止覆盖。Ruby 没有对应的停止按钮。

## 10

1. 正确代码依赖两个“我们正在定义的数据”的种类，形成方格。仅仅有两个参数、第二个是整数，不是这个难题。
2. 只对左操作数分派，然后用条件问另一个对象的 class。作业要训练的是纯 OOP 的两次查找。
3. 每个值类一个 `add_values`，再加每个值类三个 `addInt`/`addString`/`addRational`。若三种值，就是 3 + 9 个方法；九格本身是那九个带种类名的方法。
4. 先是左边的 `Int`（`add_values`），再是右边的 `MyString`（`addInt`）。
5. 右边。因为第一次消息发给了左边，左边把自己当作参数传给右边。
6. ML：`add_values(v2, v1)`。Ruby：在对应的那一格里把参数对调后再发一次合适的消息，或者共享一个 helper。不要用 `is_a?`。对调时必须确认操作可交换。

## 11

1. 其余参数的运行时 class，不只是 receiver。
2. 方法不声明参数 class；一个 class 不能并存两个同名方法。
3. 帮了：三个方法可以都叫 `add`。没帮：仍须按运行时种类手写 double dispatch，因为其余参数看的是静态类型。
4. 一个把 multimethods 做进语言、而不是版本 4 才用 `dynamic` 拼出来的现代例子。想法本身很老。
5. 选择发生的时间变成运行时。可以因此得到 multimethods 的效果。
6. 单分派要维护 `n²` 个转发方法，顺序容易写反，但是规则简单。Multimethod 调用写法自然，语言必须定义重叠时选谁，否则程序员会进错方法。

## 12

1. 从树变成有向无环图。一个类可以有多个父节点，到祖先可以有多条路。
2. 彩点要一份 x。艺术家牛仔的两个 `draw` 若共用一个 pocket 会互相破坏，需要两份。一种字段复制策略不能满足两者。
3. Include 进来的方法通过 self 调用宿主的 `+` 或 `each`。复制粘贴也能有 self，但 mixin 让一份方法体进入多个 class 的查找链。强在复用，而不是 self 这个关键字本身。
4. 在 `Comparable` 里。它调用宿主的 `<=>`，再看结果是否小于 0。
5. 义务。多个无关的 class 可以成为同一个参数类型的 subtype。仍不如动态类型灵活，因为缺方法会在编译期被拒绝，也不能不声明就满足。
6. `darken` 可以是 mixin。`StudentAthlete` 若两个父都该是 class，mixin 不够，那是多继承的例子。

## 13

1. 那条规则清楚且已有。多字段这种灵活性可以由一条 subsumption 加上一个关系给出，不必改每一条旧规则。
2. 超类型能做的，子类型的值都必须能做。少字段类型只会读写保留的字段，多字段值做得到。Depth 加上 setter 后，超类型的函数会写入一个较瘦的值，子类型的静态类型仍承诺嵌套字段还在，替换失败。
3. 传递和自反。排列只重排，不丢字段。
4. 是。先 width 丢掉 color，再 permutation 交换 x 和 y，或反过来，然后用传递性。
5. `sphere.center.z`。因为 depth 规则让调用类型检查通过，赋值又把 center 换成了没有 z 的 record。
6. 放弃 setter，或放弃 soundness。课程的三选二：setter、depth、sound。想要用户要的 depth 又要 sound，就去掉 setter。

## 14

1. 返回协变，参数逆变。
2. `flipIfGreen` 要读 color，`distMoved` 传的点没有 color。`flipX_Y0` 只读 x，调用者多给的 y 它不看。
3. 传入的 Dog 可当 Animal 用，所以满足 `Animal -> ...` 的参数。返回的 Dog 可当 Animal 用，所以满足调用者对返回类型 `Animal` 的使用。
4. 返回类型可以改成 subtype。参数类型变了通常是另一个同名方法，即 overload，不是覆盖。
5. 在 Java/C# 里不是。在 Section 10 的结构 record 规则里，若字段是超集且类型合适，width 会允许。名义类型更窄，仍然 sound。
6. 不能，因为逆变会让子类里的 self 类型比父类更宽，而不是更窄。课程的理由是调用者不能选择 self，执行子类方法时 self 一定是子类实例，所以这个位置协变仍可替换。

## 15

1. 这几处必须是同一类型。没有 subtype 约束。
2. Downcast。可能运行时失败，有检查代价，代码更难读。
3. 类型必须相等，ML 没有 subtyping。绕法是函数接收任意 `'a` 以及两个 getter，调用者提供取坐标的办法，点和彩点的 getter 还不能复用。
4. 不能。`T` 可能没有任何 `speak`。`f` 可以，若 `speak` 是 `Animal` 的方法。
5. Subtyping。对象比超类型承诺的更多。
6. `map` 用 parametric，保留元素类型。把彩色点当点画，用 subtype，函数类型写成接收 Point。若既要保留彩色点列表的元素类型又要调用点的方法，用有界泛型，那是下一节。

## 16

1. 结果里可能被放进一个新造的普通 Point，读 color 会失败。输入列表也可能被加入普通 Point，破坏调用者的彩色点列表。都是可变性加 depth 的问题。
2. 方法体要把元素当 Point 用。`T` 可以是 String，那些方法不存在，类型检查拒绝方法体。
3. 进去和出来是同一个 `T`；`T` 是 Point 的 subtype，所以可以调用点的操作。
4. 泛型实例化，`T = ColorPoint`。结果是 `List<ColorPoint>`。不是把这个列表看成 `List<Point>`。
5. Cast 可以绕过静态检查，于是“对所有 T 行为相同”在 Java 里并不总是成立。原因包括向后兼容和实现方式。
6. 没有宣布。课程证明的是可变时不安全，并说不可变 record 的 depth 可以 sound。把这个结论推广到不可变列表是推论，不是原话。
