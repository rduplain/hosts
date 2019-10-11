# Extend the language core API.
#
# Style:
#
# * Add ! to functions that convert nil/other cases to raised errors.
# * Add !! to functions that `os/exit` on errors.

(defn array/lpop
  "Like `array/pop`, but remove first (left) value from the array."
  [arr]
  (let [value (0 arr)]
    (array/remove arr 0)
    value))

(defn os/basename
  "Return basename of filepath."
  [filepath]
  (last (string/split (case (os/which) :windows "\\" "/") filepath)))

(defn die!!
  "Print to stderr then `os/exit`."
  [message &opt error-code]
  (default error-code 1)
  (with-dyns [:out stderr]
    (if (dyn :prog)
      (print (dyn :prog) ": " message)
      (print message))
    (os/exit error-code)))

(defmacro if-main
  "Evaluate body if Janet is running current .janet file as a script."
  [& body]
  ~(when (and (dyn :args) (first (dyn :args)) (dyn :current-file)
              (= (os/basename (first (dyn :args)))
                 (os/basename (dyn :current-file))))
     (do ,;body)))

(defn slurp!!
  "Like `slurp`, but print to stderr then `os/exit` if file is missing."
  [path &opt message error-code]
  (try
    (slurp path)
    ([err] (die!! (if message (string message ": " path) err) error-code))))
