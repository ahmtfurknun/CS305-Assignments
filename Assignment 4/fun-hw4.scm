(define twoOperatorCalculator
  (lambda (lst)
    (let ((firstOperand (car lst)))
      (cond
        ((null? (cdr lst)) firstOperand)
        (else
         (let ((firstOperator (cadr lst))
               (secondOperand (caddr lst))
               (rest (cdddr lst)))
           (cond
             ((eq? '+ firstOperator)
              (let* ((result (+ firstOperand secondOperand))
                     (newlst (cons result rest)))
                (twoOperatorCalculator newlst)))
             (else
              (let* ((result (- firstOperand secondOperand))
                     (newlst (cons result rest)))
                (twoOperatorCalculator newlst))))))))))

(define fourOperatorCalculator
  (lambda (lst)
    (cond
      ((null? (cdr lst)) lst)
      ((eq? '* (cadr lst))
       (let* ((result (* (car lst) (caddr lst)))
              (newLst (cons result (cdddr lst))))
         (fourOperatorCalculator newLst)))
      ((eq? '/ (cadr lst))
       (let* ((result (/ (car lst) (caddr lst)))
              (newLst (cons result (cdddr lst))))
         (fourOperatorCalculator newLst)))
      (else
       (cons (car lst) (fourOperatorCalculator (cdr lst)))))))

(define calculatorNested
  (lambda (lst)
    (cond
      ((list? (car lst))
       (calculatorNested
        (cons (twoOperatorCalculator (fourOperatorCalculator (calculatorNested (car lst))))
              (cdr lst))))
      ((null? (cdr lst)) (cons (car lst) '()))
      (else (cons (car lst) (calculatorNested (cdr lst)))))))

(define (checkOperators lst)
  (cond
    ((or (null? lst) (not (list? lst))) #f)
    ((and (number? (car lst)) (null? (cdr lst))) #t)
    ((and (list? (car lst)) (null? (cdr lst)))
     (checkOperators (car lst)))
    ((and (number? (car lst))
          (or (eq? '+ (cadr lst)) (eq? '- (cadr lst)) (eq? '* (cadr lst)) (eq? '/ (cadr lst))))
     (let ((remaining (cddr lst)))
       (checkOperators remaining)))
    ((and (list? (car lst))
          (or (eq? '+ (cadr lst)) (eq? '- (cadr lst)) (eq? '* (cadr lst)) (eq? '/ (cadr lst))))
     (let ((checkFirst (checkOperators (car lst)))
           (checkRest (checkOperators (cddr lst))))
       (and checkFirst checkRest)))
    (else #f)))

(define calculator
  (lambda (lst)
    (cond
      ((checkOperators lst)
       (let ((nestedResult (calculatorNested lst))
             (fourResult (fourOperatorCalculator (calculatorNested lst)))
             (finalResult (twoOperatorCalculator (fourOperatorCalculator (calculatorNested lst)))))
         finalResult))
      (else #f))))