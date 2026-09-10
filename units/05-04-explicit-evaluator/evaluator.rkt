#lang sicp
(#%require "../05-02-simulator/machine.rkt" "runtime.rkt")
(#%provide (all-defined))
;; Controller adapted from SICP §5.4.1–5.4.3; CLI entry replaces REPL.

(define evaluator-controller
'(
eval-dispatch
  (test (op self-evaluating?) (reg exp))
  (branch (label ev-self-eval))
  (test (op variable?) (reg exp))
  (branch (label ev-variable))
  (test (op quoted?) (reg exp))
  (branch (label ev-quoted))
  (test (op assignment?) (reg exp))
  (branch (label ev-assignment))
  (test (op definition?) (reg exp))
  (branch (label ev-definition))
  (test (op if?) (reg exp))
  (branch (label ev-if))
  (test (op lambda?) (reg exp))
  (branch (label ev-lambda))
  (test (op begin?) (reg exp))
  (branch (label ev-begin))
  (test (op application?) (reg exp))
  (branch (label ev-application))
  (goto (label unknown-expression-type))
ev-self-eval
  (assign val (reg exp))
  (goto (reg continue))
ev-variable
  (assign val (op lookup-variable-value) (reg exp) (reg env))
  (goto (reg continue))
ev-quoted
  (assign val (op text-of-quotation) (reg exp))
  (goto (reg continue))
ev-lambda
  (assign unev (op lambda-parameters) (reg exp))
  (assign exp (op lambda-body) (reg exp))
  (assign val (op make-procedure)
              (reg unev) (reg exp) (reg env))
  (goto (reg continue))
ev-application
  (save continue)
  (save env)
  (assign unev (op operands) (reg exp))
  (save unev)
  (assign exp (op operator) (reg exp))
  (assign continue (label ev-appl-did-operator))
  (goto (label eval-dispatch))
ev-appl-did-operator
  (restore unev)                  ; the operands
  (restore env)
  (assign argl (op empty-arglist))
  (assign proc (reg val))         ; the operator
  (test (op no-operands?) (reg unev))
  (branch (label apply-dispatch))
  (save proc)
ev-appl-operand-loop
  (save argl)
  (assign exp (op first-operand) (reg unev))
  (test (op last-operand?) (reg unev))
  (branch (label ev-appl-last-arg))
  (save env)
  (save unev)
  (assign continue (label ev-appl-accumulate-arg))
  (goto (label eval-dispatch))
ev-appl-accumulate-arg
  (restore unev)
  (restore env)
  (restore argl)
  (assign argl (op adjoin-arg) (reg val) (reg argl))
  (assign unev (op rest-operands) (reg unev))
  (goto (label ev-appl-operand-loop))
ev-appl-last-arg
  (assign continue (label ev-appl-accum-last-arg))
  (goto (label eval-dispatch))
ev-appl-accum-last-arg
  (restore argl)
  (assign argl (op adjoin-arg) (reg val) (reg argl))
  (restore proc)
  (goto (label apply-dispatch))
apply-dispatch
  (test (op primitive-procedure?) (reg proc))
  (branch (label primitive-apply))
  (test (op compound-procedure?) (reg proc))  
  (branch (label compound-apply))
  (test (op compiled-procedure?) (reg proc))
  (branch (label compiled-apply))
  (goto (label unknown-procedure-type))
primitive-apply
  (assign val (op apply-primitive-procedure)
              (reg proc)
              (reg argl))
  (restore continue)
  (goto (reg continue))
compound-apply
  (assign unev (op procedure-parameters) (reg proc))
  (assign env (op procedure-environment) (reg proc))
  (assign env (op extend-environment)
              (reg unev) (reg argl) (reg env))
  (assign unev (op procedure-body) (reg proc))
  (goto (label ev-sequence))
ev-begin
  (assign unev (op begin-actions) (reg exp))
  (save continue)
  (goto (label ev-sequence))
ev-sequence
  (assign exp (op first-exp) (reg unev))
  (test (op last-exp?) (reg unev))
  (branch (label ev-sequence-last-exp))
  (save unev)
  (save env)
  (assign continue (label ev-sequence-continue))
  (goto (label eval-dispatch))
ev-sequence-continue
  (restore env)
  (restore unev)
  (assign unev (op rest-exps) (reg unev))
  (goto (label ev-sequence))
ev-sequence-last-exp
  (restore continue)
  (goto (label eval-dispatch))
ev-if
  (save exp)                    ; save expression for later
  (save env)
  (save continue)
  (assign continue (label ev-if-decide))
  (assign exp (op if-predicate) (reg exp))
  (goto (label eval-dispatch))  ; evaluate the predicate
ev-if-decide
  (restore continue)
  (restore env)
  (restore exp)
  (test (op true?) (reg val))
  (branch (label ev-if-consequent))
ev-if-alternative
  (assign exp (op if-alternative) (reg exp))
  (goto (label eval-dispatch))
ev-if-consequent
  (assign exp (op if-consequent) (reg exp))
  (goto (label eval-dispatch))
ev-assignment
  (assign unev (op assignment-variable) (reg exp))
  (save unev)                   ; save variable for later
  (assign exp (op assignment-value) (reg exp))
  (save env)
  (save continue)
  (assign continue (label ev-assignment-1))
  (goto (label eval-dispatch))  ; evaluate the assignment value
ev-assignment-1
  (restore continue)
  (restore env)
  (restore unev)
  (perform
   (op set-variable-value!) (reg unev) (reg val) (reg env))
  (assign val (const ok))
  (goto (reg continue))
ev-definition
  (assign unev (op definition-variable) (reg exp))
  (save unev)                   ; save variable for later
  (assign exp (op definition-value) (reg exp))
  (save env)
  (save continue)
  (assign continue (label ev-definition-1))
  (goto (label eval-dispatch))  ; evaluate the definition value
ev-definition-1
  (restore continue)
  (restore env)
  (restore unev)
  (perform
   (op define-variable!) (reg unev) (reg val) (reg env))
  (assign val (const ok))
  (goto (reg continue))
compiled-apply
  (restore continue)
  (assign val (op compiled-procedure-entry) (reg proc))
  (goto (reg val))
unknown-expression-type
  (perform (op fail) (const unknown-expression) (reg exp))
unknown-procedure-type
  (perform (op fail) (const unknown-procedure) (reg proc))
compound-call-bridge
  (save continue)
  (goto (label compound-apply))
evaluator-done
))

(define evaluator-operations
  (list
    (list 'adjoin-arg adjoin-arg)
    (list 'application? application?)
    (list 'apply-primitive-procedure apply-primitive-procedure)
    (list 'assignment-value assignment-value)
    (list 'assignment-variable assignment-variable)
    (list 'assignment? assignment?)
    (list 'begin-actions begin-actions)
    (list 'begin? begin?)
    (list 'compiled-procedure-entry compiled-procedure-entry)
    (list 'compiled-procedure-env compiled-procedure-env)
    (list 'compiled-procedure? compiled-procedure?)
    (list 'compound-procedure? compound-procedure?)
    (list 'cons cons)
    (list 'define-variable! define-variable!)
    (list 'definition-value definition-value)
    (list 'definition-variable definition-variable)
    (list 'definition? definition?)
    (list 'empty-arglist empty-arglist)
    (list 'extend-environment extend-environment)
    (list 'fail fail)
    (list 'false? false?)
    (list 'first-exp first-exp)
    (list 'first-operand first-operand)
    (list 'if-alternative if-alternative)
    (list 'if-consequent if-consequent)
    (list 'if-predicate if-predicate)
    (list 'if? if?)
    (list 'lambda-body lambda-body)
    (list 'lambda-parameters lambda-parameters)
    (list 'lambda? lambda?)
    (list 'last-exp? last-exp?)
    (list 'last-operand? last-operand?)
    (list 'lexical-address-lookup lexical-address-lookup)
    (list 'lexical-address-set! lexical-address-set!)
    (list 'list list)
    (list 'lookup-variable-value lookup-variable-value)
    (list 'make-compiled-procedure make-compiled-procedure)
    (list 'make-procedure make-procedure)
    (list 'no-operands? no-operands?)
    (list 'operands operands)
    (list 'operator operator)
    (list 'primitive-procedure? primitive-procedure?)
    (list 'procedure-body procedure-body)
    (list 'procedure-environment procedure-environment)
    (list 'procedure-parameters procedure-parameters)
    (list 'quoted? quoted?)
    (list 'rest-exps rest-exps)
    (list 'rest-operands rest-operands)
    (list 'self-evaluating? self-evaluating?)
    (list 'set-variable-value! set-variable-value!)
    (list 'text-of-quotation text-of-quotation)
    (list 'true? true?)
    (list 'variable? variable?)))
;; One assembled image contains evaluator and compiled definitions, so entry PCs stay valid.

(define (make-language-machine compiled-statements)
  (let ((machine #f))
    (set! machine
      (make-machine
        (cons (list 'procedure-call-entry
                    (lambda (proc)
                      (cond ((compiled-procedure? proc) (compiled-procedure-entry proc))
                            ((compound-procedure? proc) (machine 'address 'compound-call-bridge))
                            (else (error "not callable" proc)))))
              evaluator-operations)
        (append '(compiled-start) compiled-statements
                '((goto (label evaluator-done))) evaluator-controller)))
    machine))

(define (evaluate-on-machine machine expression environment)
  (machine 'set 'exp expression)
  (machine 'set 'env environment)
  (machine 'set 'continue (machine 'address 'evaluator-done))
  (machine 'run 'eval-dispatch)
  (machine 'get 'val))

(define (execute-compiled machine environment)
  (machine 'set 'env environment)
  (machine 'set 'continue (machine 'address 'evaluator-done))
  (machine 'run 'compiled-start)
  (machine 'get 'val))
