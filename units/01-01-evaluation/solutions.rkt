#lang sicp

;; SICP 第二版 §1.1.1–1.1.6，习题 1.1 / 1.3 / 1.4 / 1.5。
;; 从项目根目录运行：racket units/01-01-evaluation/solutions.rkt

;; 1.1：后续表达式使用这两个定义。
(define a 3)
(define b (+ a 1))

;; 1.3：排除一个最小值，不是排除最小的平方。
;; 输入范围：可按大小比较的普通实数，不包含 NaN 或复数。
(define (square x)
  (* x x))

(define (sum-of-squares x y)
  (+ (square x) (square y)))

(define (sum-square-largest-two x y z)
  (cond ((and (<= x y) (<= x z)) (sum-of-squares y z))
        ((and (<= y x) (<= y z)) (sum-of-squares x z))
        (else (sum-of-squares x y))))

;; 1.4：内层 if 取得过程值，外层才调用该过程。
(define (a-plus-abs-b a b)
  ((if (> b 0) + -) a b))

;; 1.5：定义 p 不会循环；应用序下调用 (test 0 (p)) 才会不终止。
;; 不把这个无限调用放进自检，完整论证见讲义。
(define (p) (p))

(define (test x y)
  (if (= x 0) 0 y))

(define (argument-probe)
  (display "argument evaluated")
  (newline)
  42)

;; 以下仅为自检工具，无需本单元掌握 list / for-each。
(define (check-equal label actual expected)
  (if (not (equal? actual expected))
      (error "Check failed" label actual expected)
      #t))

(define (self-check)
  (check-equal
   'exercise-1.1
   (list 10
         (+ 5 3 4)
         (- 9 1)
         (/ 6 2)
         (+ (* 2 4) (- 4 6))
         a
         b
         (+ a b (* a b))
         (= a b)
         (if (and (> b a) (< b (* a b))) b a)
         (cond ((= a 4) 6)
               ((= b 4) (+ 6 7 a))
               (else 25))
         (+ 2 (if (> b a) b a))
         (* (cond ((> a b) a)
                  ((< a b) b)
                  (else -1))
            (+ a 1)))
   '(10 12 8 3 6 3 4 19 #f 4 16 6 16))

  ;; 每行是 (x y z 预期结果)，包含排列、并列、负数、零和分数。
  (for-each
   (lambda (example)
     (check-equal
      example
      (sum-square-largest-two (car example)
                              (cadr example)
                              (caddr example))
      (cadddr example)))
   '((1 2 3 13) (1 3 2 13) (2 1 3 13)
     (2 3 1 13) (3 1 2 13) (3 2 1 13)
     (2 2 1 8) (2 1 2 8) (1 2 2 8)
     (1 1 2 5) (1 2 1 5) (2 1 1 5)
     (2 2 2 8) (-3 -2 -1 5) (0 0 0 0)
     (-5 0 2 4) (1/2 1/3 1/4 13/36)))

  (check-equal 'exercise-1.4
               (list (a-plus-abs-b 10 3)
                     (a-plus-abs-b 10 -3)
                     (a-plus-abs-b 10 0)
                     (a-plus-abs-b -10 -3))
               '(13 13 10 -7))

  (check-equal 'test-zero (test 0 42) 0)
  (check-equal 'test-nonzero (test 1 42) 42)
  (check-equal 'eager-argument (test 0 (argument-probe)) 0)
  (check-equal 'if-short-circuit (if #t 0 (p)) 0)
  (display "01.01: all checks passed")
  (newline))

(self-check)
