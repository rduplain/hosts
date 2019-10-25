(import ../../lang :prefix "")

(let [arr @[0 1 2 3]
      head (array/lpop arr)]
  (unless (deep= arr @[1 2 3])
    (error (string/format "unexpected arr: %q" arr)))
  (unless (= head 0) (error (string/format "unexpected head: %q" head))))

(case (os/which)
  :windows
   (let [filepath "C:\\bin\\prog.exe"
         basename (os/basename filepath)]
     (unless (= basename "prog.exe")
       (error (string "unexpected basename for " filepath ": " basename))))

   (let [filepath "/usr/bin/prog"
         basename (os/basename filepath)]
     (unless (= basename "prog")
       (error (string "unexpected basename for " filepath ": " basename)))))

(def not-empty-cases
  {"string" true
   "" false
   [:a :b :c] true
   [] false
   {:a "ay"} true
   {} false})

(loop [[value not-empty?] :pairs not-empty-cases]
  (if not-empty?
    (unless (= value (not-empty value))
      (error (string/format "value expected to be not-empty: %q" value)))
    (unless (nil? (not-empty value))
      (error (string/format "value expected to be empty: %q" value)))))

(def sh-cases
  [{:command "echo foo"
    :match '(sequence "foo" (? " ") "\n")}

   {:command "echo foo" :out false
    :output ""}

   {:command "echo foo" :out true :err true
    :match '(sequence "foo" (? " ") "\n")}

   {:command "echo foo" :out true :err false
    :match '(sequence "foo" (? " ") "\n")}

   {:command "echo foo" :out false :err true
    :output ""}

   {:command "echo foo" :out false :err false
    :output ""}

   {:command "git rev-parse DOES_NOT_EXIST_456"
    :output "DOES_NOT_EXIST_456\n"}

   {:command "git rev-parse DOES_NOT_EXIST_456" :out false
    :output ""}

   {:command "git rev-parse DOES_NOT_EXIST_456" :err true
    :match '(choice "fatal" "DOES_NOT_EXIST_456")}

   {:command "git rev-parse DOES_NOT_EXIST_456" :out true :err true
    :match '(choice "fatal" "DOES_NOT_EXIST_456")}

   {:command "git rev-parse DOES_NOT_EXIST_456" :out true :err false
    :output "DOES_NOT_EXIST_456\n"}

   {:command "git rev-parse DOES_NOT_EXIST_456" :out false :err true
    :prefix "fatal"}

   {:command "git rev-parse DOES_NOT_EXIST_456" :out false :err false
    :output ""}])

(loop [{:command command
        :out out
        :err err
        :match patt
        :output expected
        :prefix prefix} :in sh-cases]

  (def options @[])
  (unless (nil? out) (array/concat options :out out))
  (unless (nil? err) (array/concat options :err err))

  (let [result (->> (apply sh command options)
                    (string/replace-all "\r" ""))]

    (when patt
      (unless (peg/match patt result)
        (print "command: " command "\n"
               "options: " (string/format "%q" options) "\n"
               "result:\n" result "\n"
               "expected pattern:\n" (string/format "%q" patt) "\n")
        (error "prefix does not match")))

    (when expected
      (unless (= expected result)
        (print "command: " command "\n"
               "options: " (string/format "%q" options) "\n"
               "result:\n" result "\n"
               "expected:\n" expected "\n")
        (error "output does not match")))

    (when prefix
      (unless (string/has-prefix? prefix result)
        (print "command: " command "\n"
               "options: " (string/format "%q" options) "\n"
               "result:\n" result "\n"
               "expected prefix:\n" prefix "\n")
        (error "prefix does not match")))))
