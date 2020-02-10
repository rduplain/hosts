(import ../../hosts :prefix "")

(let [ipv4 (hosts)]
  (apply :update ipv4 "127.0.0.1" ["localhost" "localhost.local"])

  (assert (deep= (:hosts ipv4 "127.0.0.1") @["localhost" "localhost.local"])
          "Hosts lookup by IP.")

  (assert (= (:ip ipv4 "localhost") "127.0.0.1")
          "IP lookup by host.")

  (assert (= (:hosts ipv4 "0.0.0.0") nil)
          "Lookup unknown IP.")

  (assert (= (:ip ipv4 "unknown") nil)
          "Lookup unknown host.")

  (:update ipv4 "192.168.1.100" "hostname")

  (assert (deep= (:hosts ipv4 "192.168.1.100") @["hostname"])
          "Hosts lookup by IP.")

  (assert (= (:ip ipv4 "hostname") "192.168.1.100")
          "IP lookup by host.")

  (assert (deep= (:hosts ipv4 "127.0.0.1") @["localhost" "localhost.local"])
          "Hosts lookup by IP, after updating unrelated host.")

  (assert (= (:ip ipv4 "localhost") "127.0.0.1")
          "IP lookup by host, after updating unrelated host.")

  (apply :update ipv4 "127.0.1.1" ["hostname" "localhost.local"])

  (assert (deep= (:hosts ipv4 "127.0.1.1")
                 @["hostname" "localhost" "localhost.local"])
          "Hosts lookup by IP, after updating via alias.")

  (assert (= (:ip ipv4 "localhost") "127.0.1.1")
          "IP lookup by host, after updating via alias.")

  (assert (= (:hosts ipv4 "127.0.0.1") nil)
          "Hosts lookup by original IP, after updating via alias."))

(let [int-tracker (tracker)]
  (assert (= (:seen? int-tracker 7) false)
          "Checking a not-yet-seen value.")

  (:see int-tracker 7)

  (assert (= (:seen? int-tracker 7) true)
          "Checking a seen value.")

  (assert (= (:seen? int-tracker 42) false)
          "Checking an unrelated value."))

(let [table-tracker (tracker hash)
      a-table @{7 "seven"}]
  (assert (= (:seen? table-tracker a-table) false)
          "Checking a not-yet-seen value.")

  (:see table-tracker a-table)

  (assert (= (:seen? table-tracker a-table) true)
          "Checking a seen value.")

  (assert (= (:seen? table-tracker @{42 "forty-two" 7 "seven"}) false)
          "Checking an unrelated value."))

(let [custom-tracker (tracker (fn [xs] (string/join xs "|")))]
  (assert (= (:seen? custom-tracker @["hello" "world"]) false)
          "Checking a not-yet-seen value.")

  (:see custom-tracker @["hello" "world"])

  (assert (= (:seen? custom-tracker @["hello" "world"]) true)
          "Checking a seen value.")

  (assert (= (:seen? custom-tracker @["hello"]) false)
          "Checking an unrelated value."))
