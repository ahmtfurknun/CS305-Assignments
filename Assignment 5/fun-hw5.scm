(define s7 (lambda (e env)
  (if (expr? e)
      (cond
        ((number? e) e)
        ((and (symbol? e) (symbol-in-env? e env)) (get-value e env env))
        ((and (not (procedure? e)) (not (list? e))) (display "cs305: ERROR \n\n") (repl env))
        ((null? e) e)
        ((procedure? e) e)
        ((if? e) (let ((val 
                      (if (not (= (s7 (cadr e) env) 0))
                          (s7 (caddr e) env)
                          (s7 (cadddr e) env)))) val)
         )
        ((let? e) (let-func e env))
        ((lambda? e) e)
        ((lambda? (car e)) (lambda-func e env))
        ((operator? e) (operation-func e env))
        (else (s7 (cons (get-value (car e) env env) (cdr e)) env))
      )
      ((display "cs305: ERROR \n\n") (repl env))
  )
))

(define define?
  (lambda (e)
    (and (list? e)
         (= (length e) 3)
         (eq? (car e) 'define)
         (symbol? (cadr e))
         (expr? (caddr e))
    )
  )
)

(define expr? 
  (lambda (e)
    (or 
      (number? e)
      (symbol? e)
      (and 
        (list? e) 
        (or 
          (if? e) 
          (let? e) 
          (lambda? e) 
          (lambda? (car e))
          (symbol? (car e)) 
          (operator? e) 
        )
      )
    )
  )
)

(define if? 
  (lambda (e)
    (and
      (list? e)
      (= (length e) 4)
      (eq? (car e) 'if)
    )
  )
)  

(define let? 
  (lambda (e)
    (and
      (list? e)
      (= (length e) 3)
      (eq? (car e) 'let)
      (var-binding-list? (cadr e))
    )
  )
)

(define var-binding-list? 
  (lambda (e)
    (or 
      (eq? e '()) 
      (and 
        (= (length (car e)) 2)
        (symbol? (caar e))
        (if (> (length e) 1) (var-binding-list? (cdr e)))
      )
    )
  )
)

(define lambda? 
  (lambda (e)
    (and 
      (list? e) 
      (and 
        (eq? 'lambda (car e)) 
        (formal-list? (cadr e)) 
        (expr? (caddr e)) 
        (not (define? (caddr e)))
      ) 
    )
  )
)

(define operator?
  (lambda (e)
    (and 
      (list? e)
      (> (length e) 2)
      (member (car e) '(+ - * /))
    )
  )
)

(define formal-list? 
  (lambda (e)
    (and
      (symbol? (car e)) 
      (list? e)
      (or 
        (null? (cdr e)) 
        (formal-list? (cdr e))
      )
    )
  )
)

(define procedure?
  (lambda (e)
    (member e '(+ - * /))
  )
)

(define get-operator 
  (lambda (op)
    (cond
      ((eq? op '+) +) 
      ((eq? op '*) *) 
      ((eq? op '/) /) 
      ((eq? op '-) -) 
      (else ((display "cs305: ERROR \n\n") (repl env)))
    )
  )
)

(define get-value 
  (lambda (var old-env new-env)
    (cond
      ((null? new-env) (display "cs305: ERROR \n\n") (repl old-env))
      ((equal? (caar new-env) var) (cdar new-env))
      (else (get-value var old-env (cdr new-env)))
    )
  )
)

(define extend-env 
  (lambda (var val old-env)
    (cons (cons var val) old-env)
  )
)

(define symbol-in-env?
  (lambda (e env)
    (cond
      ((null? env) #f)
      ((eq? (caar env) e) #t)
      (else (symbol-in-env? e (cdr env)))
    )
  )
)
    
(define operation-func
  (lambda (e env)
    (let ((operands (map s7 (cdr e) (make-list (length (cdr e)) env)))
        (operator (get-operator (car e))))
        (apply operator operands)
    )
  )
)

(define let-func
  (lambda (e env)
    (let* ((bindings (cadr e))
           (vars (map car bindings))
           (vals (map (lambda (val) (s7 val env)) (map cadr bindings))))
      (if (has-duplicate? vars)
          "ERROR"
          (s7 (caddr e) (append (map cons vars vals) env))
      )
    )
  )
)

(define has-duplicate?
  (lambda (lst)
    (let loop ((lst lst))
      (cond
        ((null? lst) #f)
        ((member (car lst) (cdr lst)) #t)
        (else (loop (cdr lst)))
      )
    )
  )
)


(define lambda-func
  (lambda (e env)
    (if (= (length (cadar e)) (length (cdr e)))
      (let* (
        (parameters (map s7 (cdr e) (make-list (length (cdr e)) env))) 
        (new-env (append (map cons (cadar e) parameters) env)))
        (s7 (caddar e) new-env))
      ((display "cs305: ERROR \n\n") (repl env))
    )
  )
)

(define repl 
  (lambda (env)
    (let* (
      (dummy1 (display "cs305> "))
      (expr (read))  
      (new-env 
        (if (define? expr) 
          (extend-env (cadr expr) (s7 (caddr expr) env) env) 
          env
        )
      ) 
      (val 
        (if (define? expr)
          (cadr expr)
          (let ((result (s7 expr env)))
            (if 
              (or 
                (lambda? result) 
                (procedure? result)
              ) 
              "[PROCEDURE]" 
              result
            )
          )
        )
      )
      (dummy2 (display "cs305: "))
      (dummy3 (display val))
      (dummy4 (newline))
      (dummy4 (newline)))
      (repl new-env)
    )
  )
)

(define cs305 (lambda () (repl '())))







