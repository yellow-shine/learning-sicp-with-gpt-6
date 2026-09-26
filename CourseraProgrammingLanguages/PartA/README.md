# Programming Languages 学习笔记

Dan Grossman，华盛顿大学 / Coursera。Part A（Standard ML）、Part B（Racket）、Part C（Ruby）。

这不是三门语法教程。三门语言用来对照同一组机制在不同设计选择下长什么样。读的时候走 Problem → Idea → Mechanism → Example → Trade-off → Connection。

从 [00-course-map.md](00-course-map.md) 的问题链进入。专有名词第一次出现保留英文。代码保持 SML / Racket / Ruby。

## 正文

| 文件 | 内容 | 课程位置 |
|---|---|---|
| [00-course-map.md](00-course-map.md) | 知识地图、问题链、依赖图 | 全课 |
| [01-pieces-of-a-language.md](01-pieces-of-a-language.md) | 绑定、环境、表达式规则、shadowing、语言的五块 | Part A §1 |
| [02-functions-lists-and-immutability.md](02-functions-lists-and-immutability.md) | 函数语义、tuple、list、let、option、不可变 | Part A §1 |
| [03-datatypes-and-pattern-matching.md](03-datatypes-and-pattern-matching.md) | each-of / one-of、case、异常、尾递归 | Part A §2 |
| [04-first-class-functions-and-closures.md](04-first-class-functions-and-closures.md) | 一等函数、词法作用域、闭包 | Part A §3 |
| [05-currying-callbacks-and-mutation.md](05-currying-callbacks-and-mutation.md) | 柯里化、部分应用、`ref`、回调、用闭包做 ADT | Part A §3 |
| [06-type-inference.md](06-type-inference.md) | 类型推断、多态、value restriction、相互递归 | Part A §4 |
| [07-modules-and-equivalence.md](07-modules-and-equivalence.md) | signature、抽象类型、等价与性能 | Part A §4 |
| [08-racket-dynamic-typing.md](08-racket-dynamic-typing.md) | 拿掉类型系统之后什么还在；括号是树 | Part B §5 |
| [09-delayed-evaluation-and-macros.md](09-delayed-evaluation-and-macros.md) | thunk、stream、宏与卫生 | Part B §5 |
| [10-interpreters.md](10-interpreters.md) | 程序是树；环境与闭包的实现 | Part B §6 |
| [11-static-vs-dynamic-typing.md](11-static-vs-dynamic-typing.md) | soundness、completeness、weak typing | Part B §7 |
| [12-objects-and-dynamic-dispatch.md](12-objects-and-dynamic-dispatch.md) | 对象、方法查找、动态派发 vs 闭包 | Part C §8 |
| [13-decomposition-double-dispatch-mixins.md](13-decomposition-double-dispatch-mixins.md) | 两种分解、double dispatch、mixin | Part C §9 |
| [14-subtyping-and-generics.md](14-subtyping-and-generics.md) | 子类型、函数逆变、有界多态 | Part C §10 |
| [16-language-comparison.md](16-language-comparison.md) | 同一概念在三门语言里的规则差异 | 全课 |
| [17-design-principles.md](17-design-principles.md) | 从例子里抽出的设计原则 | 全课 |
| [18-common-misconceptions.md](18-common-misconceptions.md) | 四十个容易推错的地方 | 全课 |
| [19-final-mental-model.md](19-final-mental-model.md) | 最终心智模型；看陌生语言的检查表 | 全课 |

没有第 15 章。编号跟着问题链，不为了凑目录硬拆。

## 练习

答案在各文件末尾。

| 文件 | 对应 |
|---|---|
| [exercises/section-01.md](exercises/section-01.md) | 01–02 |
| [exercises/section-02.md](exercises/section-02.md) | 03 |
| [exercises/section-03.md](exercises/section-03.md) | 04–05 |
| [exercises/section-04-types.md](exercises/section-04-types.md) | 06 |
| [exercises/section-04-modules.md](exercises/section-04-modules.md) | 07 |
| [exercises/section-05-racket.md](exercises/section-05-racket.md) | 08 |
| [exercises/section-05-delay.md](exercises/section-05-delay.md) | 09 |
| [exercises/section-06.md](exercises/section-06.md) | 10 |
| [exercises/section-07.md](exercises/section-07.md) | 11 |
| [exercises/section-08.md](exercises/section-08.md) | 12 |
| [exercises/section-09.md](exercises/section-09.md) | 13 |
| [exercises/section-10.md](exercises/section-10.md) | 14 |

字幕是口语，代码是按讲义重建的。抽取里标了 `[?]` 的记号，正文没有当成 Grossman 的逐字源码。若和你记得的幻灯片差一个名字，以规则为准，不以那个名字为准。
