;;;; -*- Mode: Lisp -*-
;;;json-parsing.l

;;; json-parse (json)
; -Parses a given json by following its recursive nature
;  (e.g. split an object into members, members into pairs and so on) in
;  order to produce a Lisp friendly list-form.
; -The main idea is to consume the characters one-by-one, starting from
;  the left side until either an error is found or the string is
;  correctly parsed. In order to do so, data is passed through all the
;  functions in the following form: (parse-result (remaining-chars)).

(defun json-parse (json)
   (let ((json-list (funcall 'remove-newlines-whitespaces (coerce json 'list))))
    (cond
     ((equal (first json-list) '#\{) (funcall 'json-parse-object (cdr json-list)))
     ((equal (first json-list) '#\[) (funcall 'json-parse-array (cdr json-list)))
     (T (error "syntax-error-parse"))
    )))

;;; json-parse-array (json)
(defun json-parse-array (json)
(let ((njson (funcall 'remove-newlines-whitespaces json)))
  (cond
   ((and 
     (equal (car njson) '#\])
     (null (remove-newlines-whitespaces (cdr njson)))) '(json-array))
   (T (let ((result (json-parse-elements njson NIL)))
        (if (null (remove-newlines-whitespaces (car (cdr result))))
            (append '(json-array) (car result))
          (error "syntax-error-not-empty")))))))
       

;;; json-parse-object (json)
(defun json-parse-object (json)
(let ((njson (funcall 'remove-newlines-whitespaces json)))
  (cond
   ((and 
     (equal (car njson) '#\})
     (null (remove-newlines-whitespaces (cdr njson)))) '(json-obj))
   (T (let ((result (json-parse-members njson NIL)))
        (if (null (remove-newlines-whitespaces (car (cdr result))))
            (append '(json-obj) (car result))
          (error "syntax-error-not-empty")))))))


;;;json-parse-elements (json obj)
(defun json-parse-elements (json obj)
  (let ((result (json-parse-value json))) 
    (json-delimiter-array result obj)))

;;;json-parse-members (json obj)
(defun json-parse-members (json obj)
  (let ((result (json-parse-pair json)))
  (json-delimiter-object result obj)))

;;;json-parse-pair (json obj)
(defun json-parse-pair (json)
  (let((njson (remove-newlines-whitespaces json)))
    (if (or (equal (car njson) '#\") (equal (car njson) '#\'))
        (let ((result (json-parse-string njson)))
          (json-delimiter-comma result))
      (error "syntax-error-pair"))))

;;;json-delimiter-comma (json)
(defun json-delimiter-comma (json)
    (let((njson (remove-newlines-whitespaces (car (cdr json))))
        (obj (list (car json))))
    (if (equal (car njson) '#\:)
        (let ((result (json-parse-value (remove-newlines-whitespaces (cdr njson)))))
           (append
            (list (append 
                   obj
                   (list (car result))))
            (list (car (cdr result)))))
      (error "syntax-error-comma"))))

;;;json-parse-value (json)
(defun json-parse-value (json)
  (let ((njson (funcall 'remove-newlines-whitespaces json)))
    (cond
     ((or (equal (car njson) '#\") (equal (car njson) '#\')) 
      (json-parse-string njson))
     ((and (char<= '#\0 (car njson)) (char>= '#\9 (car njson))) 
      (json-parse-number njson NIL))
     ((char= '#\- (car njson)) 
      (json-parse-number (cdr njson) '(#\-)))
     ((or (equal (car njson) '#\{) (equal (car njson) '#\[)) 
      (json-parse-nested njson))
     (T (error "syntax-error")))))

;;;json-parse-number (json temp)
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

;;;json-parse-number-float (json temp)
(defun json-parse-number-float (json temp)
  (cond
   ((or (null json)(char= '#\. (car json))) (error "syntax-error"))
   ((and (char<= '#\0 (car json)) (char>= '#\9 (car json))) 
    (funcall 'json-parse-number-float (cdr json) (append temp (list (car json)))))
   (T (append 
       (list (parse-float (coerce temp 'string)))
       (remove-newlines-whitespaces (list json))))
))

;;;json-parse-string (json)
(defun json-parse-string (json)
  (cond 
   ((char= '#\' (car json)) (json-parse-string-sq (cdr json) NIL))
   ((char= '#\" (car json)) (json-parse-string-dq (cdr json) NIL))))

;;;json-parse-string-sq (json temp)
(defun json-parse-string-sq (json temp)
  (cond
   ((null json) (error "quotes-not-closed"))
   ((equal (car json) '#\") (error "dq-inside-sq"))
   ((not (equal (car json) '#\'))
    (funcall 'json-parse-string-sq (cdr json) (append temp (list (car json)))))
   (T (append 
        (list (coerce temp 'string))
        (remove-newlines-whitespaces (list (cdr json)))))
))

;;;json-parse-string-dq (json temp)
(defun json-parse-string-dq (json temp)
  (cond
   ((null json) (error "quotes-not-closed"))
   ((equal (car json) '#\') (error "sq-inside-dq"))
   ((not (equal (car json) '#\"))
    (funcall 'json-parse-string-dq (cdr json) (append temp (list (car json)))))
   (T (append 
        (list (coerce temp 'string))
        (remove-newlines-whitespaces (list (cdr json)))))
))
   
;;;json-parse-nested (json)
(defun json-parse-nested (json)
  (cond
   ((equal (first json) '#\{) (let ((result (json-parse-object-nested (cdr json))))
                                result))
   ((equal (first json) '#\[) (let ((result (json-parse-array-nested (cdr json))))
                                result))
    ))

;;;json-parse-array-nested (json)
(defun json-parse-array-nested (json)
  (let ((njson (funcall 'remove-newlines-whitespaces  json)))
   (cond
   ((equal (car njson) '#\]) (append (list '(json-array)) (list (cdr njson))))
   (T (let ((result (json-parse-elements njson NIL)))
        (append (list (append '(json-array) (car result))) (list (car (cdr result)))))))))

;;;json-parse-object-nested (json)
(defun json-parse-object-nested (json)
  (let ((njson (funcall 'remove-newlines-whitespaces json)))
   (cond
   ((equal (car njson) '#\}) (append (list '(json-obj)) (list (cdr njson))))
   (T (let ((result (json-parse-members njson NIL))) 
        (append (list (append '(json-obj) (car result))) (list (car (cdr result)))))))))

;;;json-delimiter-array (json obj)
(defun json-delimiter-array (json obj)
  (let ((nobj (append obj (list (car json))))
        (njson (remove-newlines-whitespaces (car (cdr json)))))
    (cond
     ((char= (car njson) '#\]) (append (list nobj) (list (remove-first njson))))
     ((char= (car njson) '#\,) (json-parse-elements (remove-first njson) nobj))  
     (T (error "syntax-error-delim-array")))))

;;;json-delimiter-object (json obj)
(defun json-delimiter-object (json obj)
  (let ((nobj (append obj (list (car json))))
        (njson (remove-newlines-whitespaces (car (cdr json)))))
    (cond
     ((char= (car njson) '#\}) (append (list nobj) (list (remove-first njson))))
     ((char= (car njson) '#\,) (json-parse-members (remove-first njson) nobj))  
     (T (error "syntax-error-delim-obj")))))

;;;remove-first (list)
(defun remove-first (list)
  (cdr list))
;;;remove-last (list)
(defun remove-last (list)
  (if (null (cdr list))
      NIL
    (cons (car list) (funcall 'remove-last (cdr list)))))

;;;remove-newlines-whitespaces (list)
(defun remove-newlines-whitespaces (list)
  (if (or (equal (car list) '#\Space)
          (equal (car list) '#\Newline))
      (remove-newlines-whitespaces (cdr list))
    list))

;;; json_get(json, &rest fields)
; -Follows a chain of keys (iff JSON_obj at current level is an object) 
;  or indexes (iff JSON_obj at current level is an array)in order to retrieve 
;  a certain value.
; -The main idea is to simply go through the list as needed.
; -Two different predicates are used since the keyword &rest had a few issues
;  with recursive calls

(defun json-get (json &rest fields)
  (funcall 'json-get-2 json fields))

(defun json-get-2 (json fields)
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
         (eq (car JSON) 'json-obj)) (funcall 'json-get-2
                                               (funcall 'json-search-by-key (cdr json) (car fields))
                                               (cdr fields)
                                               ))
   ((and (> (list-length fields) 1)
         (listp json)
         (numberp (car fields))
         (eq (car JSON) 'json-array)) (funcall 'json-get-2
                                             (funcall 'json-search-by-index (cdr json) (car fields))
                                             (cdr fields)
                                             ))
   (T (error "Syntax-error"))))

;;; json-search-by-key (json key)
(defun json-search-by-key (json key)
  (cond
   ((NULL json) (error "Key not found"))
   ((equal (car (car json)) key) (car (cdr (car json))))
   (T (funcall 'json-search-by-key (cdr json) key))
   ))

;;; json-search-by-index (json index)
(defun json-search-by-index (json index)
  (cond
   ((NULL json) (error "Index not found"))
   ((eq index 0) (car json))
   (T (funcall 'json-search-by-index (cdr json) (1- index)))
   ))

;;; json-load(filename)
; -Loads a json file and returns its equivalent list-form
; -Quite self explanatory...
(defun json-load (filename)
  (with-open-file (stream filename 
                          :direction :input
                          :if-does-not-exist :error)
    (let ((contents (make-string (file-length stream))))
      (read-sequence contents stream)
      (funcall 'json-parse contents))))

;;; json-write(json filename).
; -Loads a json file and returns its equivalent list-form
; -Quite self explanatory...
(defun json-write (JSON filename)
  (with-open-file (stream filename 
                          :direction :output 
                          :if-exists :supersede
                          :if-does-not-exist :create)
  (format stream (funcall 'json-to-string JSON))))

;;; json-to-string (json)
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

;;; json-print-obj (json)
(defun json-print-obj (JSON)
  (cond
   ((NULL JSON) "")
   ((listp (car JSON)) (concatenate 'string 
                                    (funcall 'json-print-pair (car JSON)) 
                                    (funcall 'json-print-obj (cdr JSON))
                                    ))))

;;; json-print-pair (json)
(defun json-print-pair (JSON)
  (concatenate 'string "\""
               (funcall 'car JSON)
               "\"" ":" 
               (funcall 'json-print-value (car (cdr JSON)))
               ","
               ))

;;; json-print-value (json)
(defun json-print-value (JSON)
  (cond
   ((numberp JSON) (write-to-string JSON))
   ((stringp JSON) (concatenate 'string "\"" JSON "\""))
   (T (funcall 'json-to-string JSON))))

;;; json-print-array (json)
(defun json-print-array (JSON)
  (cond
   ((NULL JSON) "")
   (T (concatenate 'string 
      (funcall 'json-print-value (car JSON))
       ","
      (funcall 'json-print-array (cdr JSON))
    ))))

;;; remove-last-comma (json)
(defun remove-last-comma (JSON)
  (cond
    ((string= "" JSON) JSON)
    (T (subseq JSON 0 (- (length JSON) 1)))))

;;; end of file -- json-parsing.l
