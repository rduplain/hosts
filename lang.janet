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

(defn not-empty
  "If xs is empty, nil, else xs."
  [xs]
  (when (not (empty? xs)) xs))

(defn- sh-redirect
  "Return sh redirect syntax to capture out/err as specifed in bool arguments."
  [out err]
  (let [nullpath (if (os/stat "/dev/null") "/dev/null" "nul")]
    (cond
      (and out err) " 2>&1"
      (and out (not err)) (string " 2>" nullpath)
      (and (not out) err) (string " 2>&1 1>" nullpath)
      (and (not out) (not err)) (string " > " nullpath " 2>&1"))))

(defn sh
  "Execute command (as string), return output as string.

  Options:

  :out true|false       # Capture process stdout, default: true.
  :err true|false       # Capture process stderr, default: false.

  Notes:

  * Use :out/:err arguments instead of shell redirect syntax in string command.
  * This does NOT sanitize input to prevent shell injection attacks."
  [command & options]
  (def {:out out :err err} (table ;options))
  (default out true)
  (default err false)
  (with [fd (file/popen (string command (sh-redirect out err)) :r)]
        (file/read fd :all)))

(defn slurp!!
  "Like `slurp`, but print to stderr then `os/exit` if file is missing."
  [path &opt message error-code]
  (try
    (slurp path)
    ([err] (die!! (if message (string message ": " path) err) error-code))))

(defn string/includes?
  "If s includes substr, true, else false."
  [s substr]
  (if (or (= substr "") (string/find substr s))
    true
    false))
