#lang sicp
;; SICP 第二版 §1.3.1–1.3.2，1.30 / 1.32。
;; sum / accumulate 依据教材模式实现，折叠方向和进展检查为课程说明。
(#%require (only racket/base with-handlers exn:fail?))
(define (identity x) x)
(define (cube x) (* x x x))
(define (advance next a)
  (let ((following (next a)))
    (if (> following a) following
        (error "next must increase the index" a following))))

(define (sum-recursive term a next b)
  (if (> a b) 0
      (+ (term a) (sum-recursive term (advance next a) next b))))

;; 1.30：result 是已处理项之和。
(define (sum-iterative term a next b)
  (define (iter current result)
    (if (> current b) result
        (iter (advance next current) (+ result (term current)))))
  (iter a 0))

;; 1.32a：右结合，combiner 的第一个参数是当前项。
(define (accumulate combiner null-value term a next b)
  (if (> a b) null-value
      (combiner (term a)
                (accumulate combiner null-value term (advance next a) next b))))
(define (sum term a next b)
  (accumulate + 0 term a next b))
(define (product term a next b)
  (accumulate * 1 term a next b))

;; 1.32b：常见的左折叠迭代版；对任意 combiner 不保证等同于右折叠。
(define (accumulate-left combiner null-value term a next b)
  (define (iter current result)
    (if (> current b) result
        (iter (advance next current) (combiner result (term current)))))
  (iter a null-value))

;; 保持 accumulate 的一般右折叠语义，但用显式待处理表代替控制栈。
;; Θ(n) 临时表、Θ(1) 控制栈；并非任意右折叠都能常量总空间化。
(define (accumulate-iterative combiner null-value term a next b)
  (define (collect current reversed-terms)
    (if (> current b) (combine reversed-terms null-value)
        (collect (advance next current) (cons (term current) reversed-terms))))
  (define (combine reversed-terms result)
    (if (null? reversed-terms) result
        (combine (cdr reversed-terms) (combiner (car reversed-terms) result))))
  (collect a '()))

(define (pi-sum a b)
  (sum-iterative (lambda (x) (/ 1.0 (* x (+ x 2))))
                 a (lambda (x) (+ x 4)) b))
(define (integral f a b dx)
  (if (<= dx 0) (error "dx must be positive" dx))
  (* dx (sum-iterative f (+ a (/ dx 2)) (lambda (x) (+ x dx)) b)))

(define (check-equal label actual expected)
  (if (not (equal? actual expected))
      (error "Check failed" label actual expected) #t))
(define (raises? thunk)
  (with-handlers ((exn:fail? (lambda (e) #t))) (thunk) #f))
(define (self-check)
  (check-equal 'sum-1.30 (sum-iterative identity 1 inc 10) 55)
  (check-equal 'cubes (sum cube 1 inc 10) 3025)
  (check-equal 'recursive (sum-recursive cube 1 inc 10) 3025)
  (check-equal 'product (product identity 1 inc 5) 120)
  (check-equal 'empty-sum (sum identity 2 inc 1) 0)
  (check-equal 'empty-product (product identity 2 inc 1) 1)
  (check-equal 'singleton (sum-iterative cube 2 inc 2) 8)
  (check-equal 'stride (sum-iterative identity 1 (lambda (x) (+ x 2)) 5) 9)
  (check-equal 'empty-never-calls
               (accumulate + 0 (lambda (x) (error "unexpected term"))
                           2 (lambda (x) (error "unexpected next")) 1) 0)
  (check-equal 'right-subtraction (accumulate - 0 identity 1 inc 3) 2)
  (check-equal 'left-subtraction (accumulate-left - 0 identity 1 inc 3) -6)
  (check-equal 'right-iterative (accumulate-iterative - 0 identity 1 inc 3) 2)
  (check-equal 'right-list (accumulate cons '() identity 1 inc 3) '(1 2 3))
  (check-equal 'right-list-iterative
               (accumulate-iterative cons '() identity 1 inc 3) '(1 2 3))
  (check-equal 'empty-right-iterative
               (accumulate-iterative cons '() identity 2 inc 1) '())
  (check-equal 'left-sum (accumulate-left + 0 identity 1 inc 100) 5050)
  (check-equal 'lambda-call ((lambda (x y) (+ (* x x) y)) 3 4) 13)
  (check-equal 'let-parallel
               (let ((x 5)) (let ((x 3) (y (+ x 2))) (* x y))) 21)
  (check-equal 'let-nested
               (let ((x 5)) (let ((x 3)) (let ((y (+ x 2))) (* x y)))) 15)
  (check-equal 'pi-approx (< (abs (- (* 8 (pi-sum 1 10000)) 3.141592653589793))
                            0.001) #t)
  (check-equal 'midpoint-integral (integral cube 0 1 1/100) 19999/80000)
  (check-equal 'bad-next
               (raises? (lambda () (sum-iterative identity 1 identity 3))) #t)
  (check-equal 'bad-dx (raises? (lambda () (integral cube 0 1 0))) #t)
  (display "01.05: all checks passed") (newline))
(self-check)
