#lang sicp
(#%require "../04-01-metacircular/evaluator.rkt"
           "../04-05-query-language/query-core.rkt"
           "../04-05-query-language/personnel.rkt")
(define family
  '((parent Ada Bob) (parent Bob Cora) (parent Ada Dan)
    (rule (ancestor ?x ?y)
          (or (parent ?x ?y) (and (parent ?x ?z) (ancestor ?z ?y))))
    (rule (append-to-form () ?y ?y))
    (rule (append-to-form (?u . ?v) ?y (?u . ?z)) (append-to-form ?v ?y ?z))))
(define (self-check)
  (let ((db (make-query-system #t 1000)))
    (install-statements! db family)
    (check 'family-trace (stream-take (db 'query '(ancestor Ada ?child)) 10)
           '((ancestor Ada Dan) (ancestor Ada Cora) (ancestor Ada Bob)))
    (check 'reverse-relation (stream-take (db 'query '(ancestor ?who Cora)) 10)
           '((ancestor Bob Cora) (ancestor Ada Cora)))
    (check 'rule-renaming
           (stream-take (db 'query '(and (ancestor Ada Bob) (ancestor Bob Cora))) 10)
           '((and (ancestor Ada Bob) (ancestor Bob Cora))))
    (check 'history-is-not-global
           (length (stream-take (db 'query '(and (ancestor Ada Bob) (ancestor Ada Bob))) 10)) 1)
    (check 'relational-append
           (stream-take (db 'query '(append-to-form ?left ?right (a b))) 10)
           '((append-to-form (a b) () (a b))
             (append-to-form () (a b) (a b))
             (append-to-form (a) (b) (a b)))))
  (check 'alpha-equivalence
         (canonical-goal '(p ?x ?x ?y) '()) (canonical-goal '(p ?a ?a ?b) '()))
  (check 'aliases-matter
         (equal? (canonical-goal '(p ?x ?x) '()) (canonical-goal '(p ?x ?y) '())) #f)
  (check 'bindings-matter
         (equal? (canonical-goal '(p ?x) '((?x . a)))
                 (canonical-goal '(p ?x) '((?x . b)))) #f)
  (let ((db (make-query-system #t 1000)))
    (install-statements! db personnel) (db 'assert! bad-outranked)
    (check 'exercise-4.67
           (stream-take (db 'query '(outranked-by (Bitdiddle Ben) ?who)) 20)
           '((outranked-by (Bitdiddle Ben) (Warbucks Oliver))))
    (db 'assert! '(rule (same ?x ?y) (same ?y ?x)))
    (check 'symmetric-loop (stream-take (db 'query '(same a b)) 1) '()))
  (let ((db (make-query-system #t 20)))
    (db 'assert! '(rule (grow ?x) (grow (s ?x))))
    (check-error 'growing-goals-evade-variant-check
                 (lambda () (db 'query '(grow z)))))
  ;; A concrete incompleteness witness for ancestor-variant pruning.
  (let ((guarded (make-query-system #t 1000)) (unguarded (make-query-system #f 1000)))
    (for-each (lambda (db)
                (install-statements! db '((nat z) (rule (nat (s ?n)) (nat ?n)))))
              (list guarded unguarded))
    (check 'guard-loses-productive-recursion
           (stream-take (guarded 'query '(nat ?n)) 4) '((nat z)))
    (check 'lazy-infinite-answers
           (stream-take (unguarded 'query '(nat ?n)) 4)
           '((nat z) (nat (s z)) (nat (s (s z))) (nat (s (s (s z))))))
    (unguarded 'assert! '(marker done))
    (let ((answers (stream-take (unguarded 'query '(or (nat ?n) (marker ?m))) 3)))
      (check 'interleaving-fairness (cadr answers) '(or (nat ?n) (marker done)))))
  ;; 4.70: the tail promise reads a variable later; it is NOT a saved value.
  (let ((bad (list->stream '(old))))
    (set! bad (cons-stream 'new bad))
    (check 'exercise-4.70-self-loop (stream-take bad 4) '(new new new new))
    (check 'memoized-self-reference (eq? bad (stream-cdr bad)) #t))
  (let ((bad '()))
    (set! bad (cons-stream 'a bad))
    (let ((saved-a bad))
      (set! bad (cons-stream 'b bad))
      (check 'late-tail-sees-newer-head (stream-take saved-a 4) '(a b b b))))
  (let ((good (list->stream '(old))))
    (let ((old-stream good)) (set! good (cons-stream 'new old-stream)))
    (check 'exercise-4.70-snapshot (stream-take good 4) '(new old)))
  (let ((db (make-query-system #t 100)))
    (db 'assert! '(item old))
    (let ((old-results (db 'query '(item ?x))))
      (db 'assert! '(item new))
      (check 'query-snapshot (stream-take old-results 4) '((item old)))
      (check 'database-new-head (stream-take (db 'query '(item ?x)) 4) '((item new) (item old)))))
  (check 'indirect-occurs (unify '?y '(f ?x) '((?x . ?y))) 'failed)
  (display "04.06: all checks passed") (newline))
(self-check)
