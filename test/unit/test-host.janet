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

    (assert (deep= record expected-record)
            (string "\n"
                    (string/format "record:\n%q\n" record)
                    (string/format "expected-record:\n%q\n" expected-record)
                    "unexpected result in parsing"))

    (assert (deep= record-fields expected-record-fields)
            (string "\n"
                    (string/format "record-fields:\n%q\n" record-fields)
                    (string/format "expected-record-fields:\n%q\n"
                                   expected-record-fields)
                    "unexpected fields result"))))

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
    (assert (= result expected)
            (string "\n"
                    "line:\n" line "\n"
                    "expected:\n" expected "\n"
                    "result:\n" result
                    "expected a specific error"))))

(def pred-cases
  [{:value "" :ipv4? false :ipv6? false}
   {:value "localhost" :ipv4? false :ipv6? false}
   {:value "127.0.0.1" :ipv4? true :ipv6? false}
   {:value "127.0.0.1\tlocalhost" :ipv4? false :ipv6? false}
   {:value "::1" :ipv4? false :ipv6? true}
   {:value "::1\tlocalhost" :ipv4? false :ipv6? false}])

(loop [{:value value :ipv4? ipv4-expected :ipv6? ipv6-expected} :in pred-cases]
  (let [ipv4-result (ipv4? value)
        ipv6-result (ipv6? value)]
    (assert (and (= ipv4-result ipv4-expected)
                 (= ipv6-result ipv6-expected))
            (string "\n"
                    "value: " value "\n"
                    "ipv4? " ipv4-result ", expected: " ipv4-expected "\n"
                    "ipv6? " ipv6-result ", expected: " ipv6-expected "\n"
                    "unexpected IPv4/IPv6 predicate result"))))

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
    (assert (deep= result expected)
            (string "\n"
                    (string/format "result:\n%q\n" result)
                    (string/format "expected:\n%q\n" expected)
                    "unexpected result in add-host"))))
