(defun json-parse (json)
   (let ((json-list (funcall 'remove-newlines-whitespaces (coerce json 'list))))
    (cond
     ((equal (first json-list) '#\{) (funcall 'json-parse-object json-list))
     ((equal (first json-list) '#\[) (funcall 'json-parse-array (cdr json-list)))
     (T (error "syntax-error-parse"))
    )))

(defun json-parse-array (json)
  (cond
   ((and 
     (equal (car json) '#\])
     (null (remove-newlines-whitespaces (car (cdr json))))) '(json-array))
   (T (append
       '(json-array)
       (car (json-parse-elements json NIL))))))


(defun json-parse-elements (json obj)
  (let ((result (json-parse-value json)))
  (json-delimiter-array result obj)))

;;;returns (list parsed-elem (list restList))
(defun json-parse-value (json)
  (let ((njson (funcall 'remove-newlines-whitespaces json)))
    (cond
     ((equal (car njson) '#\") (json-parse-string (remove-newlines-whitespaces (cdr njson)) NIL))
     ((and (char<= '#\0 (car njson)) (char>= '#\9 (car njson))) (json-parse-number njson NIL))
     ((or (equal (car njson) '#\{) (equal (car njson) '#\[)) (json-parse-nested njson))
     (T (error "syntax-error")))))

(defun json-parse-number (json temp)
  (cond
   ((null json) (error "syntax-error"))
   ((and (char<= '#\0 (car json)) (char>= '#\9 (car json))) 
    (funcall 'json-parse-number (cdr json) (append temp (list (car json)))))
   ((char= '#\. (car json)) 
    (funcall 'json-parse-number-float (cdr json) (append temp (list (car json)))))
   (T (append 
       (list (parse-integer (coerce temp 'string)))
       (remove-newlines-whitespaces (list json))))
))

(defun json-parse-number-float (json temp)
  (cond
   ((or (null json)(char= '#\. (car json))) (error "syntax-error"))
   ((and (char<= '#\0 (car json)) (char>= '#\9 (car json))) 
    (funcall 'json-parse-number-float (cdr json) (append temp (list (car json)))))
   (T (append 
       (list (parse-float (coerce temp 'string)))
       (remove-newlines-whitespaces (list json))))
))

(defun json-parse-string (json temp)
  (cond
   ((null json) (error "quotes-not-closed"))
   ((not (equal (car json) '#\"))
    (funcall 'json-parse-string (cdr json) (append temp (list (car json)))))
   (T (append 
        (list (coerce temp 'string))
        (remove-newlines-whitespaces (list (cdr json)))))
))
   

(defun json-parse-nested (json)
  (cond
   ((equal (first json) '#\{) (funcall 'json-parse-object json))
   ((equal (first json) '#\[) (let ((result (json-parse-array-nested (cdr json))))
                                result))
    ))

(defun json-parse-array-nested (json)
  (let ((result (json-parse-elements json NIL)))
   (cond
   ((equal (car json) '#\]) (append '(json-array) (list (cdr json))))
   (T (append (list (append '(json-array) (car result))) (list (car (cdr result))))))))

(defun json-delimiter-array (json obj)
  (let ((nobj (append obj (list (car json))))
        (njson (remove-newlines-whitespaces (car (cdr json)))))
    (cond
     ((char= (car njson) '#\]) (append (list nobj) (list (remove-first njson))))
     ((char= (car njson) '#\,) (json-parse-elements (remove-first njson) nobj))  
     (T (error "syntax-error-delim")))))



(defun remove-first (list)
  (cdr list))
(defun remove-last (list)
  (if (null (cdr list))
      NIL
    (cons (car list) (funcall 'remove-last (cdr list)))))

;;;newline?
(defun remove-newlines-whitespaces (list)
  (if (or (equal (car list) '#\Space)
          (equal (car list) '#\Newline))
      (remove-newlines-whitespaces (cdr list))
    list))