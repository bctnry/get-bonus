#lang racket/base
(require racket/match)

(struct evector (make-base
                 base-ref
                 base-set!
                 [base #:mutable]
                 [actual-len #:mutable]
                 [effective-len #:mutable]))

(define (make-evector make-base base-ref base-set! initial-len)
  (evector make-base base-ref base-set!
           (make-base initial-len)
           initial-len
           0))

(define (evector-length ev)
  (evector-effective-len ev))
(define (set-evector-length! ev new-len)
  (match-define (evector make-base base-ref base-set!
                         base actual-len effective-len)
                ev)
  (cond
    [(< new-len actual-len)
     (set-evector-effective-len! ev new-len)]
    [else
     (define next-len (max (* 2 actual-len) new-len))
     (define new-base (make-base next-len))
     (for ([i (in-range effective-len)])
       (base-set! new-base i (base-ref base i)))
     (set-evector-base! ev new-base)
     (set-evector-actual-len! ev next-len)
     (set-evector-effective-len! ev new-len)]))

(define (ensure-k ev k)
  (unless ((evector-length ev) . > . k)
    (error 'evector "index ~e out of bounds" k)))

(define (evector-ref ev k)
  (ensure-k ev k)
  ((evector-base-ref ev)
   (evector-base ev)
   k))
(define (evector-set! ev k val)
  (ensure-k ev k)
  ((evector-base-set! ev)
   (evector-base ev)
   k
   val))

(module+ test
  (require rackunit)
  (define N 100)
  (define e (make-evector make-bytes bytes-ref bytes-set! 10))
  (for ([i (in-range N)])
    (set-evector-length! e (add1 i))
    (evector-set! e i i)
    (for ([j (in-range N)])
      (if (j . <= . i)
        (check-equal? (evector-ref e j) j
                      (format "~a ~a valid" i j))
        (check-exn exn:fail?
                   (λ () (evector-ref  e j))
                   (format "~a ~a invalid" i j))))))