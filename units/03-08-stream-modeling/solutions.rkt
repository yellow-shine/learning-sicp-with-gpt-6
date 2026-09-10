#lang sicp
(#%require "../03-07-stream-mechanics/streams.rkt"
           (only racket/base with-handlers exn:fail?))
;; SICP §3.5.3–3.5.5, with 3.60 and 3.77 in full.
(define zeros (cons-stream 0 zeros))
(define integers (integers-starting-from 1))
(define (integrate-series coefficients)
  (stream-map / coefficients integers))
(define exp-series (cons-stream 1 (integrate-series exp-series)))
(define cosine-series
  (cons-stream 1 (scale-stream (integrate-series sine-series) -1)))
(define sine-series (cons-stream 0 (integrate-series cosine-series)))
;; 3.60: A*B = a0*b0 + x*(a0*tail(B) + tail(A)*B).
(define (mul-series a b)
  (cons-stream (* (stream-car a) (stream-car b))
               (add-streams (scale-stream (stream-cdr b) (stream-car a))
                            (mul-series (stream-cdr a) b))))
(define (polynomial->series coefficients)
  (if (null? coefficients) zeros
      (cons-stream (car coefficients) (polynomial->series (cdr coefficients)))))

;; 3.77: BOTH the initial feedback input and each recursive tail stay delayed.
(define (integral delayed-integrand initial-value dt)
  (cons-stream
   initial-value
   (let ((integrand (force delayed-integrand)))
     (if (stream-null? integrand) the-empty-stream
         (integral (delay (stream-cdr integrand))
                   (+ initial-value (* dt (stream-car integrand)))
                   dt)))))
(define (solve f y0 dt)
  ;; R5RS internal definitions do not promise letrec* initialization order.
  ;; Allocate both locations first, then initialize them in the required order.
  (let ((y #f) (dy #f))
    (set! y (integral (delay dy) y0 dt))
    (set! dy (stream-map f y))
    y))

;; Successive approximations: the stream separates improvement from stopping.
(define (sqrt-stream x)
  (define guesses
    (cons-stream 1.0
                 (stream-map (lambda (g) (/ (+ g (/ x g)) 2)) guesses)))
  guesses)
(define (stream-limit s tolerance)
  (if (<= tolerance 0) (error "Positive tolerance required"))
  (let ((next (stream-cdr s)))
    (if (< (abs (- (stream-car s) (stream-car next))) tolerance)
        (stream-car next)
        (stream-limit next tolerance))))
(define (partial-sums s)
  (define sums (cons-stream (stream-car s) (add-streams (stream-cdr s) sums)))
  sums)
(define (pi-summands n)
  (cons-stream (/ 1.0 n) (scale-stream (pi-summands (+ n 2)) -1)))
(define pi-stream (scale-stream (partial-sums (pi-summands 1)) 4))
(define (euler-transform s)
  (let* ((s0 (stream-ref s 0)) (s1 (stream-ref s 1)) (s2 (stream-ref s 2))
         (denominator (+ s0 (* -2 s1) s2)))
    (if (= denominator 0) (error "Euler transform has zero denominator"))
    (cons-stream (- s2 (/ (* (- s2 s1) (- s2 s1)) denominator))
                 (euler-transform (stream-cdr s)))))

;; Fair alternation: no infinite first row can monopolize the enumeration.
(define (interleave a b)
  (if (stream-null? a) b
      (cons-stream (stream-car a) (interleave b (stream-cdr a)))))
(define (pairs s t)
  (cons-stream
   (list (stream-car s) (stream-car t))
   (interleave (stream-map (lambda (x) (list (stream-car s) x)) (stream-cdr t))
               (pairs (stream-cdr s) (stream-cdr t)))))

;; Sampled signals: smoothing and zero-crossing detection are separate stages.
(define (smooth s)
  (if (stream-null? s) the-empty-stream
      (stream-map (lambda (a b) (/ (+ a b) 2)) s (stream-cdr s))))
(define (sign-change current previous)
  (cond ((and (< previous 0) (>= current 0)) 1)
        ((and (>= previous 0) (< current 0)) -1)
        (else 0)))
(define (zero-crossings s previous)
  (if (stream-null? s) the-empty-stream
      (cons-stream (sign-change (stream-car s) previous)
                   (zero-crossings (stream-cdr s) (stream-car s)))))
(define (stream-withdraw balance amounts)
  (cons-stream balance
               (if (stream-null? amounts) the-empty-stream
                   (stream-withdraw (- balance (stream-car amounts))
                                    (stream-cdr amounts)))))
(define (random-history seed requests)
  (if (stream-null? requests) the-empty-stream
      (let* ((request (stream-car requests))
             (next (cond ((eq? request 'generate) (modulo (+ (* 5 seed) 1) 16))
                         ((and (pair? request) (eq? (car request) 'reset)
                               (pair? (cdr request)) (null? (cddr request))
                               (integer? (cadr request)))
                          (modulo (cadr request) 16))
                         (else (error "Invalid random request" request)))))
        (cons-stream next (random-history next (stream-cdr requests))))))
(define (check label actual expected)
  (if (not (equal? actual expected)) (error "Check failed" label actual expected)))
(define (check-close label actual expected tolerance)
  (if (> (abs (- actual expected)) tolerance) (error "Check failed" label actual expected)))
(define (self-check)
  (check 'exp-coefficients (stream-take exp-series 6) '(1 1 1/2 1/6 1/24 1/120))
  (check 'sine-coefficients (stream-take sine-series 6) '(0 1 0 -1/6 0 1/120))
  (check 'cosine-coefficients (stream-take cosine-series 6) '(1 0 -1/2 0 1/24 0))
  (check '3.60-polynomial
         (stream-take (mul-series (polynomial->series '(1 2)) (polynomial->series '(3 4))) 5)
         '(3 10 8 0 0))
  (check '3.60-identity
         (stream-take (add-streams (mul-series sine-series sine-series)
                                  (mul-series cosine-series cosine-series)) 12)
         '(1 0 0 0 0 0 0 0 0 0 0 0))
  (check 'empty-integrand (stream->list (integral (delay the-empty-stream) 7 1/2)) '(7))
  (check 'finite-integral
         (stream->list (integral (delay (list->stream '(2 4 6))) 10 1/2)) '(10 11 13 16))
  (check 'zero-step
         (stream->list (integral (delay (list->stream '(2 4))) 10 0)) '(10 10 10))
  (let ((forced 0))
    (let ((s (integral (delay (begin (set! forced (+ forced 1)) (list->stream '(2)))) 10 1)))
      (check 'initial-before-feedback (stream-car s) 10)
      (check 'input-not-forced forced 0)
      (check 'next-feedback (stream-ref s 1) 12)
      (check 'input-forced-once forced 1)))
  ;; If the recursive call evaluates stream-cdr before delaying it, this feedback
  ;; asks for a promise already being forced and fails instead of making progress.
  (check '3.77-feedback-prefix (stream-take (solve (lambda (y) y) 1 1/10) 5)
         '(1 11/10 121/100 1331/1000 14641/10000))
  (let ((approximation (stream-ref (solve (lambda (y) y) 1.0 0.001) 1000)))
    (check-close 'euler-recurrence approximation (expt 1.001 1000) 1e-10)
    (check-close 'euler-approximation approximation (exp 1) 0.002)
    (display "3.77 y(1), dt=0.001: ") (display approximation) (newline))
  (check-close 'sqrt-stream (stream-limit (sqrt-stream 2) 1e-10) (sqrt 2) 1e-10)
  (let ((pi (* 4 (atan 1))))
    (check 'acceleration
           (< (abs (- (stream-ref (euler-transform pi-stream) 5) pi))
              (abs (- (stream-ref pi-stream 7) pi))) #t))
  (check 'fair-pairs (stream-take (pairs integers integers) 8)
         '((1 1) (1 2) (2 2) (1 3) (2 3) (1 4) (3 3) (1 5)))
  (check 'smoothed (stream->list (smooth (list->stream '(2 4 -2 -4 2 4)))) '(3 1 -3 -1 3))
  (check 'crossings
         (stream->list (zero-crossings (smooth (list->stream '(2 4 -2 -4 2 4))) 0))
         '(0 0 -1 0 1))
  (check 'empty-signal (stream->list (smooth the-empty-stream)) '())
  (check 'balance-history (stream->list (stream-withdraw 100 (list->stream '(10 20 5))))
         '(100 90 70 65))
  (check 'random-requests
         (stream->list (random-history 1 (list->stream '(generate generate (reset 1) generate))))
         '(6 15 1 6))
  (for-each
   (lambda (thunk)
     (check 'expected-error
            (with-handlers ((exn:fail? (lambda (e) #t))) (thunk) #f) #t))
   (list (lambda () (stream-limit (sqrt-stream 2) 0))
         (lambda () (euler-transform zeros))
         (lambda () (random-history 1 (list->stream '(bad-request))))))
  (display "03.08: all checks passed") (newline))
(self-check)
