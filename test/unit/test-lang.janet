(import ../../lang :prefix "")

(let [arr @[0 1 2 3]
      head (array/lpop arr)]
  (assert (deep= arr @[1 2 3])
          (string/format "unexpected arr: %q" arr))
  (assert (= head 0)
          (string/format "unexpected head: %q" head)))

(case (os/which)
  :windows
   (let [filepath "C:\\bin\\prog.exe"
         basename (os/basename filepath)]
     (assert (= basename "prog.exe")
             (string "unexpected basename for " filepath ": " basename)))

   (let [filepath "/usr/bin/prog"
         basename (os/basename filepath)]
     (assert (= basename "prog")
             (string "unexpected basename for " filepath ": " basename))))

(def not-empty-cases
  {"string" true
   "" false
   [:a :b :c] true
   [] false
   {:a "ay"} true
   {} false})

(loop [[value not-empty?] :pairs not-empty-cases]
  (if not-empty?
    (assert (= value (not-empty value))
            (string/format "value expected to be not-empty: %q" value))
    (assert (nil? (not-empty value))
            (string/format "value expected to be empty: %q" value))))

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

    (def command-options-result
      (string "command: " command "\n"
              "options: " (string/format "%q" options) "\n"
              "result:\n" result "\n"))

    (when patt
      (assert (peg/match patt result)
              (string "\n" command-options-result
                      "expected pattern:\n" (string/format "%q" patt) "\n"
                      "prefix does not match")))

    (when expected
      (assert (= expected result)
              (string "\n" command-options-result
                      "expected:\n" expected "\n"
                      "output does not match")))

    (when prefix
      (assert (string/has-prefix? prefix result)
              (string "\n" command-options-result
                      "expected prefix:\n" prefix "\n"
                      "prefix does not match")))))

(def string-includes-cases
  {["string" "str"] true
   ["string" "ing"] true
   ["string" "tr"] true
   ["string" "t"] true
   ["string" ""] true
   ["string" "nope"] false})

(loop [[[s substr] included] :pairs string-includes-cases]
  (assert (= included (string/includes? s substr))
          (string/format "expected (string/includes? %q %q) to be %q"
                         s substr
                         included)))
