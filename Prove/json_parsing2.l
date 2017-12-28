(defun json-parse (json)
   (let ((json-list (funcall 'remove-newlines-whitespaces (coerce json 'list))))
    (cond
     ((equal (first json-list) '#\{) (funcall 'json-parse-object json-list NIL))
     ((equal (first json-list) '#\[) (funcall 'json-parse-array json-list NIL))
     (T (error "syntax-error-parse"))
    )))

(defun json-parse-object (json obj)
   (funcall 'json-parse-pairs
            (funcall 'remove-first json)
            (append obj '(json-obj))))

(defun json-parse-array (json obj)
   (funcall 'json-parse-elements
           (funcall 'remove-first json)
           (append obj '(json-array))))

(defun json-parse-pairs (json obj)
  (cond
   ((and (equal (first json) '#\}) (null (cdr json))) obj)
   (T (json-parse-pair json obj))
   ))

(defun json-parse-elements (json obj)
  (cond
   ((and (equal (first json) '#\]) (null (cdr json))) obj)
   (T (json-parse-value json obj))
   ))

(defun json-parse-value (json obj)
  (let ((njson (funcall 'remove-newlines-whitespaces json)))
    (cond
     ((equal (car njson) '#\") (json-parse-string (cdr json) obj NIL))
     ((and (char<= '#\0 (car njson)) (char>= '#\9 (car njson))) (json-parse-number njson obj NIL))
     ((or (equal (car njson) '#\{) (equal (car njson) '#\[)) (json-parse-nested njson obj))
     (T (error "syntax-error")))))

(defun json-parse-number (json obj temp)
  (cond
   ((null json) (error "syntax-error"))
   ((and (char<= '#\0 (car json)) (char>= '#\9 (car json))) 
    (funcall 'json-parse-number (cdr json) obj (append temp (list (car json)))))
   ((char= '#\. (car json)) 
    (funcall 'json-parse-number-float (cdr json) obj (append temp (list (car json)))))
   (T (funcall 'json-delimiter 
               json
               (append obj (list (parse-integer (coerce temp 'string)))))
)))

(defun json-parse-number-float (json obj temp)
  (cond
   ((or (null json)(char= '#\. (car json))) (error "syntax-error"))
   ((and (char<= '#\0 (car json)) (char>= '#\9 (car json))) 
    (funcall 'json-parse-number-float (cdr json) obj (append temp (list (car json)))))
   (T (funcall 'json-delimiter 
               json
               (append obj (list (parse-float (coerce temp 'string)))))
)))

(defun json-parse-string (json obj temp)
  (cond
   ((null json) (error "quotes-not-closed"))
   ((not (equal (car json) '#\"))
    (funcall 'json-parse-string (cdr json) obj (append temp (list (car json)))))
   (T (funcall 'json-delimiter
               (cdr json)
               (append obj (list (coerce temp 'string)))))))
   

(defun json-parse-nested (json obj)
  (cond
   ((equal (first json) '#\{) (funcall 'json-parse-object json obj))
   ((equal (first json) '#\[) (funcall 'json-parse-array json obj))
    ))

(defun json-delimiter-array (json obj)
  (let ((njson (funcall 'remove-newlines-whitespaces json)))
    (cond
     ((char= (car njson) '#\]) obj)
     ((char= (car njson) '#\,) (funcall 'json-parse-elements (cdr json) obj))  
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
  

(defun json-get (json &rest fields)
  (cond
   ((and (eq (list-length fields) 1)
         (listp json)
         (stringp (car fields))
         (eq (car JSON) 'json-obj)) (funcall 'json-search-by-key (cdr json) (car fields)))
   ((and (eq (list-length fields) 1) 
         (listp json)
         (numberp (car fields))
         (eq (car JSON) 'json-array)) (funcall 'json-search-by-index (cdr json) (car fields)))
   ((and (> (list-length fields) 1) 
         (listp json)
         (stringp (car fields))
         (eq (car JSON) 'json-obj)) (funcall 'json-get
                                               (funcall 'json-search-by-key (cdr json) (car fields))
                                               (car (cdr fields))
                                               ))
   ((and (> (list-length fields) 1)
         (listp json)
         (numberp (car fields))
         (eq (car JSON) 'json-array)) (funcall 'json-get
                                             (funcall 'json-search-by-index (cdr json) (car fields))
                                             (car (cdr fields))
                                             ))
   (T (error "Syntax-error"))))

(defun json-search-by-key (json key)
  (cond
   ((NULL json) (error "Key not found"))
   ((equal (car (car json)) key) (car (cdr (car json))))
   (T (funcall 'json-search-by-key (cdr json) key))
   ))

(defun json-search-by-index (json index)
  (cond
   ((NULL json) (error "Index not found"))
   ((eq index 0) (car json))
   (T (funcall 'json-search-by-index (cdr json) (1- index)))
   ))



(defun json-load (filename)
  (with-open-file (stream filename :direction :input)
    (let ((contents (make-string (file-length stream))))
      (read-sequence contents stream)
      (funcall 'json-parse contents))))

(defun json-write (JSON filename)
  (with-open-file (stream filename :direction :output)
  (format stream (funcall 'json-to-string JSON))))

(defun json-to-string (JSON)
  (cond
   ((eq (car JSON) 'json-obj) (concatenate 'string 
                                           "{" 
                                           (funcall 'remove-last-comma
                                                    (json-print-obj (cdr JSON))) 
                                           "}"
                                           ))
   ((eq (car JSON) 'json-array) (concatenate 'string 
                                             "[" 
                                             (funcall 'remove-last-comma
                                                      (json-print-array (cdr JSON)))
                                             "]"
                                             ))
   (T (error "Syntax-error"))))

(defun json-print-obj (JSON)
  (cond
   ((NULL JSON) "")
   ((listp (car JSON)) (concatenate 'string 
                                    (funcall 'json-print-pair (car JSON)) 
                                    (funcall 'json-print-obj (cdr JSON))
                                    ))))

(defun json-print-pair (JSON)
  (concatenate 'string "\""
               (funcall 'car JSON)
               "\"" ":" 
               (funcall 'json-print-value (car (cdr JSON)))
               ","
               ))

(defun json-print-value (JSON)
  (cond
   ((numberp JSON) (write-to-string JSON))
   ((stringp JSON) (concatenate 'string "\"" JSON "\""))
   (T (funcall 'json-to-string JSON))))

(defun json-print-array (JSON)
  (cond
   ((NULL JSON) "")
   (T (concatenate 'string 
      (funcall 'json-print-value (car JSON))
       ","
      (funcall 'json-print-array (cdr JSON))
    ))))

(defun remove-last-comma (JSON)
  (subseq JSON 0 (- (length JSON) 1)))
