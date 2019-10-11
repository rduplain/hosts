(import ../../host :prefix "")

(def success-cases
  [{:line "" :record nil :fields nil}
   {:line " " :record nil :fields nil}
   {:line " \t " :record nil :fields nil}

   {:line "127.0.0.1 localhost"
    :record @["127.0.0.1" " " "localhost"]
    :fields @["127.0.0.1" "localhost"]}

   {:line "127.0.0.1  localhost"
    :record @["127.0.0.1" "  " "localhost"]
    :fields @["127.0.0.1" "localhost"]}

   {:line "127.0.0.1\tlocalhost"
    :record @["127.0.0.1" "\t" "localhost"]
    :fields @["127.0.0.1" "localhost"]}

   {:line "127.0.0.1\t\tlocalhost"
    :record @["127.0.0.1" "\t\t" "localhost"]
    :fields @["127.0.0.1" "localhost"]}

   {:line "127.0.0.1 \t localhost"
    :record @["127.0.0.1" " \t " "localhost"]
    :fields @["127.0.0.1" "localhost"]}

   {:line "127.0.0.1  localhost localhost.local # comment"
    :record @["127.0.0.1" "  " "localhost" " " "localhost.local" " # comment"]
    :fields @["127.0.0.1" "localhost" "localhost.local"]}])

(loop [{:line line
        :record expected-record
        :fields expected-record-fields} :in success-cases]

  (let [record (parse line)
        record-fields (fields record)]

    (unless (deep= record expected-record)
      (print) (print "record:") (pp record)
      (print "expected-record:") (pp expected-record) (print)
      (error "unexpected result in parsing"))

    (unless (deep= record-fields expected-record-fields)
      (print) (print "record-fields:") (pp record-fields)
      (print "expected-record-fields:") (pp expected-record-fields) (print)
      (error "unexpected fields result"))))

(defmacro catch-error
  "Return result of body or its error (instead of raising)."
  [& body]
  ~(try
     ,;body
    ([err] err)))

(def failure-cases
  [{:line " foo "
    :error "invalid hosts line:\n foo "}

   {:line "127.0.0.1  localhost-"
    :error "invalid name in hostname: localhost-"}

   {:line "127.0.0.1  localhost localhost-.local # comment"
    :error "invalid name in hostname: localhost-"}

   {:line "127.0.0.1  localhost localhost1234567890.localhost1234567890.localhost1234567890.localhost1234567890.localhost1234567890.localhost1234567890.localhost1234567890.localhost1234567890.localhost1234567890.localhost1234567890.localhost1234567890.localhost1234567890.localhost1234567890.local"
    :error "domain is too long: localhost1234567890.localhost1234567890.localhost1234567890.localhost1234567890.localhost1234567890.localhost1234567890.localhost1234567890.localhost1234567890.localhost1234567890.localhost1234567890.localhost1234567890.localhost1234567890.localhost1234567890.local"}])

(loop [{:line line :error expected} :in failure-cases]
  (let [result (catch-error (parse line))]
    (unless (= result expected)
      (print (string "\nline:\n" line
                     "\nexpected:\n" expected
                     "\nresult:\n" result
                     "\n"))
      (error "expected a specific error"))))

(def add-host-cases
  [{:record @["127.0.0.1" " " "localhost"]
    :host "localhost.local"
    :delimiter nil
    :result @["127.0.0.1" " " "localhost" " " "localhost.local"]}

   {:record @["127.0.0.1" " " "localhost" " # comment"]
    :host "localhost.local"
    :delimiter nil
    :result @["127.0.0.1" " " "localhost" " " "localhost.local" " # comment"]}

   {:record @["127.0.0.1" "\t" "localhost"]
    :host "localhost.local"
    :delimiter "\t"
    :result @["127.0.0.1" "\t" "localhost" "\t" "localhost.local"]}])

(loop [{:record record
        :host host
        :delimiter delimiter
        :result expected} :in add-host-cases]
  (let [result (add-host record host delimiter)]
    (unless (deep= result expected)
      (print) (print "result:") (pp result)
      (print "expected:") (pp expected) (print)
      (error "unexpected result in add-host"))))
