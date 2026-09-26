# Language Comparison

ML 和 Racket 两列是课程内容。Python 列里，课程点过动态类型、字符串版 `eval`、以及“有的语言把更多值当成合法”。Java / C / C++ 列里，课程点过字节码与 JIT、weak typing、宏、数组越界、generics 要到 Part C 才讲。其余格子是**【扩展】**，用来定位，不是 quiz 范围。

| Concept | ML | Racket | Python 【扩展，除注明处】 | Java / C / C++ / Rust |
| --- | --- | --- | --- | --- |
| Typing | 静态。Sound 于它列出的 X，不 complete。不防 `hd []`、越界、除零 | 动态，不是 weak。值有标签。点 Run 时查未绑定变量。可看成一个大 datatype | 动态。原语往往比 Racket 更宽容，空容器常为假。课程把“原语规则更宽”和“检查更晚”分开了 | Java：静态，失败仍报错，不是着火。C/C++：有静态检查，但是 weak，越界可以做任何事。Rust【扩展】：安全子集试图对更多 X sound，因而不 complete |
| Function | 一等函数。多参数常靠柯里化，是语法糖 | 真多参数，不是柯里化糖。调用写成 `(f e1 e2)`。特殊形式不是调用 | 一等函数。调用是 `f(e1, e2)`，括号的意义和 Racket 不同 | Java 在课程年代主要是方法；后来的 lambda【扩展】才接近一等函数。C 函数指针没有闭包环境 |
| Closure | 有。词法作用域。Part A 作为使用者理解 | 有。Part B 要你在解释器里造出来：代码 + 定义环境 | 有，词法作用域【扩展】 | C：没有。C++ lambda、Java lambda、Rust 闭包【扩展】都要处理外层绑定，规则比本课多 |
| Mutation | 有，但课程劝你少用。列表和元组不可变，别名因此看不出来 | 默认函数式。`set!` 改绑定。cons 不可变。`mcons` 是另一类型。顶层赋值受“定义文件没改过别人也不能改”的限制 | 赋值改绑定；对象字段默认可变【扩展】 | Java 对象字段默认可变。C 内存可写，且写错不必报错。Rust 默认不可变【扩展】 |
| Lazy evaluation | 函数参数 eager | 函数参数 eager。Thunk 和 promise 是你写的局部惯用法。标准库有 `delay` / `force`，课程自己实现 | eager【扩展】。生成器是另一机制 | Java / C / C++ eager。Haskell 才是课程点名的 lazy language |
| Stream | 课程没在 ML 里做。可以用 thunk 做同样的惯用法 | thunk，调用得 `(值, 下一个 thunk)`。无限是未请求的尾巴不存在 | generator 用挂起的帧，常常一次性、带副作用【扩展】 | Java `Stream` 是流水线对象，通常不能当本课的 stream 重走【扩展】。C++ ranges / Rust iterator 同样只是名字邻近 |
| Macro | 课程不讲 ML 的宏 | `define-syntax`，按树展开，hygienic。解释器旁的 Racket 函数也能生成对象语言 AST，但不卫生 | 无这套特殊形式【扩展】。`eval` 吃字符串 | C 预处理器是课程的反面：按 token 做文本替换，不卫生，会和优先级打架。Java 没有这种 macro |
| Datatype | `datatype` 给出全部构造器、字段类型、穷尽性。模式匹配 | 没有一个绑定收齐全部变体。`struct` 造一种新数据，`pair?` 为假。List 加符号只是约定，访问器可以混用 | class / 字典约定，伪造字段容易【扩展】 | Java 类不是 ML datatype。C 的 struct 不带来新的受检查种类，写错可以着火。代数数据类型在 Rust / 现代 Java【扩展】里更接近 ML |

## 不要从这张表推出的结论

- 静态不等于强，动态不等于弱。Racket 动态且必须在检查会失败时表现成错误。C 静态且可以着火。
- 有解释器的实现不等于解释型语言。课程否认这个词。Java 是编译到字节码、再解释、再 JIT 的混合。
- Stream 这个英文词在各语言里不是同一结构。
- Part C 才会比较 ML 的 `'a`、Java/C# 的 generics 和子类型。这张表故意不把那一讲提前写完。
