#lang sicp
(#%provide (all-defined))
;; Recursive controllers adapted from SICP figures 5.11 and 5.12.
(define factorial-controller '(
   (assign continue (label fact-done))
 fact-loop
   (test (op =) (reg n) (const 1))
   (branch (label base-case))
   (save continue)
   (save n)
   (assign n (op -) (reg n) (const 1))
   (assign continue (label after-fact))
   (goto (label fact-loop))
 after-fact
   (restore n)
   (restore continue)
   (assign val (op *) (reg n) (reg val))
   (goto (reg continue))
 base-case
   (assign val (const 1))
   (goto (reg continue))
 fact-done))

(define fibonacci-controller '(
   (assign continue (label fib-done))
 fib-loop
   (test (op <) (reg n) (const 2))
   (branch (label immediate-answer))
   (save continue)
   (assign continue (label afterfib-n-1))
   (save n)
   (assign n (op -) (reg n) (const 1))
   (goto (label fib-loop))
 afterfib-n-1
   (restore n)
   (restore continue)
   (assign n (op -) (reg n) (const 2))
   (save continue)
   (assign continue (label afterfib-n-2))
   (save val)
   (goto (label fib-loop))
 afterfib-n-2
   (assign n (reg val))
   (restore val)
   (restore continue)
   (assign val
           (op +) (reg val) (reg n))
   (goto (reg continue))
 immediate-answer
   (assign val (reg n))
   (goto (reg continue))
 fib-done))

(define iterative-factorial-controller
  '((assign product (const 1))
    (assign counter (const 1))
    loop
    (test (op >) (reg counter) (reg n))
    (branch (label done))
    (assign product (op *) (reg counter) (reg product))
    (assign counter (op +) (reg counter) (const 1))
    (goto (label loop))
    done))
(define recursive-expt-controller
  '((assign continue (label done))
    expt-loop
    (test (op =) (reg n) (const 0))
    (branch (label base))
    (save continue)
    (assign n (op -) (reg n) (const 1))
    (assign continue (label after-expt))
    (goto (label expt-loop))
    after-expt
    (restore continue)
    (assign val (op *) (reg b) (reg val))
    (goto (reg continue))
    base
    (assign val (const 1))
    (goto (reg continue))
    done))
(define iterative-expt-controller
  '((assign counter (reg n))
    (assign product (const 1))
    loop
    (test (op =) (reg counter) (const 0))
    (branch (label done))
    (assign product (op *) (reg b) (reg product))
    (assign counter (op -) (reg counter) (const 1))
    (goto (label loop))
    done))
