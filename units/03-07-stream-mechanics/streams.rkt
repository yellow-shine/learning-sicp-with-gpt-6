#lang sicp
;; Stream interface adapted from SICP §3.5.1–3.5.2.
;; cons-stream/delay/force come from #lang sicp (memoized tails).
(#%provide stream-car stream-cdr stream-map stream-filter stream-ref
           stream-enumerate-interval integers-starting-from stream-take
           stream->list list->stream add-streams scale-stream memo-proc)
(define (stream-car s) (car s))
(define (stream-cdr s) (force (cdr s)))
(define (any-empty? streams)
  (cond ((null? streams) #f)
        ((stream-null? (car streams)) #t)
        (else (any-empty? (cdr streams)))))
;; 3.50: shortest-input convention extends the textbook's first-input test.
(define (stream-map proc . argstreams)
  (if (null? argstreams) (error "stream-map needs at least one stream"))
  (if (any-empty? argstreams) the-empty-stream
      (cons-stream (apply proc (map stream-car argstreams))
                   (apply stream-map (cons proc (map stream-cdr argstreams))))))
(define (stream-filter pred s)
  (cond ((stream-null? s) the-empty-stream)
        ((pred (stream-car s))
         (cons-stream (stream-car s) (stream-filter pred (stream-cdr s))))
        (else (stream-filter pred (stream-cdr s)))))
(define (stream-ref s n)
  (if (or (not (integer? n)) (< n 0)) (error "Invalid stream index" n))
  (cond ((stream-null? s) (error "Stream index out of range" n))
        ((= n 0) (stream-car s))
        (else (stream-ref (stream-cdr s) (- n 1)))))
(define (stream-enumerate-interval low high)
  (if (> low high) the-empty-stream
      (cons-stream low (stream-enumerate-interval (+ low 1) high))))
(define (integers-starting-from n)
  (cons-stream n (integers-starting-from (+ n 1))))
(define (stream-take s n)
  (if (or (not (integer? n)) (< n 0)) (error "Invalid prefix length" n))
  (cond ((or (= n 0) (stream-null? s)) '())
        ((= n 1) (list (stream-car s))) ; do not force an unused next cell
        (else (cons (stream-car s) (stream-take (stream-cdr s) (- n 1))))))
(define (stream->list s)
  (if (stream-null? s) '() (cons (stream-car s) (stream->list (stream-cdr s)))))
(define (list->stream xs)
  (if (null? xs) the-empty-stream (cons-stream (car xs) (list->stream (cdr xs)))))
(define (add-streams a b) (stream-map + a b))
(define (scale-stream s factor) (stream-map (lambda (x) (* factor x)) s))
(define (memo-proc thunk)
  (let ((done? #f) (result #f))
    (lambda ()
      (if (not done?) (begin (set! result (thunk)) (set! done? #t)))
      result)))
