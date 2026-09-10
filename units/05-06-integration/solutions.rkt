#lang sicp
(#%require "../05-02-simulator/machine.rkt" "../05-01-machines/controllers.rkt"
           "../05-04-explicit-evaluator/runtime.rkt" "../05-04-explicit-evaluator/evaluator.rkt"
           "../05-05-compiler/compiler.rkt")
(check '5.41-c (find-variable 'c '((y z) (a b c d e) (x y))) '(1 2))
(check '5.41-x (find-variable 'x '((y z) (a b c d e) (x y))) '(2 0))
(check '5.41-w (find-variable 'w '((y z) (a b c d e) (x y))) 'not-found)
(check 'shadowing (find-variable 'y '((y z) (x y))) '(0 0))
(check 'empty-frame (find-variable 'x '(() (x))) '(1 0))
(check 'empty-environment (find-variable 'x '()) 'not-found)
(define (compiled-value expression lexical?)
  (let* ((seq ((if lexical? compile-lexically compile) expression 'val 'next))
         (m (make-language-machine (statements seq))))
    (execute-compiled m (setup-environment))))
(define nested '(((lambda (x) (lambda (y) (+ x y))) 10) 7))
(check 'lexical-runtime (compiled-value nested #t) 17)
(check 'shadowing-runtime (compiled-value '((lambda (x) ((lambda (x) x) 2)) 1) #t) 2)
(check 'lexical-mutation (compiled-value '((lambda (x) (set! x (+ x 1)) x) 4) #t) 5)
(check 'internal-shadowing
       (compiled-value '((lambda (x) ((lambda () (define x 9) x))) 1) #t) 9)
(check-error 'failed-lexical-compilation (lambda () (compile-lexically '(f) 'proc 'return)))
(check 'compiler-state-restored lexical-mode? #f)
(check 'nonempty-lexical-code
       (not (null? (select (lambda (i)
                            (and (pair? i) (eq? (car i) 'assign)
                                 (equal? (caddr i) '(op lexical-address-lookup))))
                          (statements (compile-lexically nested 'val 'next))))) #t)
(check-error 'unassigned-lexical
             (lambda () (lexical-address-lookup '(0 0) (extend-environment '(x) '(*unassigned*) '()))))
(check-error 'bad-address (lambda () (lexical-address-lookup '(-1 0) '())))
(check-error 'unbound-compiled (lambda () (compiled-value 'missing #t)))
;; Actual two-way calls in ONE assembled image and ONE shared global environment.
(define mixed-source
  '(begin
     (define (compiled-double x) (+ x x))
     (define (compiled-caller x) (+ (interpreted-step x) 100))))
(define mixed (make-language-machine (statements (compile-lexically mixed-source 'val 'next))))
(define mixed-env (setup-environment))
(execute-compiled mixed mixed-env)
(evaluate-on-machine mixed '(define (interpreted-step x) (+ (compiled-double x) 1)) mixed-env)
(check 'interpreted-to-compiled (evaluate-on-machine mixed '(interpreted-step 7) mixed-env) 15)
(check 'compiled-to-interpreted-to-compiled
       (evaluate-on-machine mixed '(compiled-caller 7) mixed-env) 115)
(check 'mixed-balanced (cadddr (mixed 'statistics)) 0)
;; Also test compiled internal definition, parameter addresses, and tail calls.
(check 'compiled-iterative
       (compiled-value (list 'begin iterative-factorial '(factorial 8)) #t) 40320)

(define interpreted (make-language-machine '()))
(define interpreted-env (setup-environment))
(evaluate-on-machine interpreted recursive-factorial interpreted-env)
(define compiled (make-language-machine (statements (compile-lexically recursive-factorial 'val 'next))))
(define compiled-env (setup-environment))
(execute-compiled compiled compiled-env)
(check 'compiled-base-value (evaluate-on-machine compiled '(factorial 1) compiled-env) 1)
(check 'compiled-base-stack
       (list (car (compiled 'statistics)) (cadr (compiled 'statistics))) '(7 3))
(define specialized (make-machine basic-ops factorial-controller))
(for-each
 (lambda (n)
   (let ((a (evaluate-on-machine interpreted (list 'factorial n) interpreted-env))
         (b (evaluate-on-machine compiled (list 'factorial n) compiled-env)))
     (specialized 'set 'n n) (specialized 'run 0)
     (check '5.45-values (list b (specialized 'get 'val)) (list a a))
     (let ((i (interpreted 'statistics)) (c (compiled 'statistics)) (s (specialized 'statistics)))
       (check 'interpreted-formula (list (car i) (cadr i)) (list (- (* 32 n) 16) (+ (* 5 n) 3)))
       (check 'compiled-formula (list (car c) (cadr c)) (list (+ (* 6 n) 1) (- (* 3 n) 1)))
       (check 'specialized-formula (list (car s) (cadr s)) (list (* 2 (- n 1)) (* 2 (- n 1))))
       (display (list '5.45 n 'interpreted i 'compiled c 'specialized s)) (newline))))
 '(2 3 4 5 8 12))
(display "05.06: all checks passed\n")
