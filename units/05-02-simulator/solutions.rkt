#lang sicp
(#%require "machine.rkt" "../05-01-machines/controllers.rkt")
(define fib (make-machine basic-ops fibonacci-controller))
(fib 'set 'n 7)
(fib 'run 0)
(check 'fib7 (fib 'get 'val) 13)
(check 'register-discovery (length (fib 'registers)) 3)
(define report (fib 'analysis))
(check 'entry-registers (cdr (assq 'entry-registers report)) '(continue))
(check 'stack-registers (cdr (assq 'stack-registers report)) '(continue n val))
(check 'val-sources (cdr (assq 'val (cdr (assq 'assignment-sources report))))
       '(((op +) (reg val) (reg n)) ((reg n))))
(check 'deduplication
       (length (cdr (assq 'instructions report)))
       (length (unique (cdr (assq 'instructions report)))))
(check 'instruction-type-order
       (map car (cdr (assq 'instructions report)))
       '(assign assign assign assign assign assign assign assign
         branch goto goto restore restore restore save save save test))
(define input-only
  (make-machine basic-ops '((assign result (reg input))
                           (assign literal (const (reg imaginary))))))
(input-only 'set 'input 42)
(input-only 'run 0)
(check 'read-only-input-register (input-only 'get 'result) 42)
(check 'constant-is-data (memq 'imaginary (input-only 'registers)) #f)
(check 'read-only-assignment-sources
       (assq 'input (cdr (assq 'assignment-sources (input-only 'analysis)))) '(input))
(define restore-only (make-machine '() '((restore restored))))
(check 'restore-only-assignment-sources
       (cdr (assq 'assignment-sources (restore-only 'analysis))) '((restored)))
;; These names are legal registers, not syntax when appearing as instruction operands.
(for-each
 (lambda (name)
   (let ((m (make-machine '() `((assign ,name (reg input))
                               (save ,name)
                               (assign ,name (const 0))
                               (restore ,name)
                               (assign result (reg ,name))))))
     (check 'tag-named-register-discovery (m 'registers) (list 'result 'input name))
     (m 'set 'input 42)
     (m 'run 0)
     (check 'tag-named-register-execution (m 'get 'result) 42)
     (check 'tag-named-register-stack (cadddr (m 'statistics)) 0)))
 '(const reg))
(check-error 'unassigned-input
             (lambda () ((make-machine '() '((assign out (reg in)))) 'run 0)))
(for-each (lambda (row) (display row) (newline)) report)
(check-error 'missing-label (lambda () (make-machine '() '((goto (label missing))))))
(check-error 'duplicate-label (lambda () (make-machine '() '(same same))))
(check-error 'unknown-op (lambda () (make-machine '() '((assign x (op unknown))))))
(check-error 'empty-stack (lambda () ((make-machine '() '((restore x))) 'run 0)))
(check-error 'wrong-register
 (lambda () ((make-machine '() '((assign x (const 1)) (save x) (restore y))) 'run 0)))
(check-error 'bounded-loop (lambda () ((make-machine '() '(loop (goto (label loop)))) 'run 0 10)))
(display "05.02: all checks passed\n")
