(import ../../hosts :prefix "")

(let [ipv4 (hosts)]
  (apply :update ipv4 "127.0.0.1" ["localhost" "localhost.local"])

  (assert (deep= (:hosts ipv4 "127.0.0.1") @["localhost" "localhost.local"])
          (string/format "Hosts lookup by IP: %q" ipv4))

  (assert (= (:ip ipv4 "localhost") "127.0.0.1")
          (string/format "IP lookup by host: %q" ipv4))

  (assert (= (:hosts ipv4 "0.0.0.0") nil)
          (string/format "Lookup unknown IP: %q" ipv4))

  (assert (= (:ip ipv4 "unknown") nil)
          (string/format "Lookup unknown host: %q" ipv4))

  (:update ipv4 "192.168.1.100" "hostname")

  (assert (deep= (:hosts ipv4 "192.168.1.100") @["hostname"])
          (string/format "Hosts lookup by IP: %q" ipv4))

  (assert (= (:ip ipv4 "hostname") "192.168.1.100")
          (string/format "IP lookup by host: %q" ipv4))

  (assert (deep= (:hosts ipv4 "127.0.0.1") @["localhost" "localhost.local"])
          (string/format "Hosts lookup by IP, after unrelated host: %q" ipv4))

  (assert (= (:ip ipv4 "localhost") "127.0.0.1")
          (string/format "IP lookup by host, after unrelated host: %q" ipv4))

  (apply :update ipv4 "127.0.1.1" ["hostname" "localhost.local"])

  (assert (deep= (:hosts ipv4 "127.0.1.1")
                 @["hostname" "localhost" "localhost.local"])
          (string/format "Hosts lookup by IP, after alias update: %q" ipv4))

  (assert (= (:ip ipv4 "localhost") "127.0.1.1")
          (string/format "IP lookup by host, after alias update: %q" ipv4))

  (assert (= (:hosts ipv4 "127.0.0.1") nil)
          (string/format "Hosts lookup by old IP, after update: %q" ipv4)))

(let [int-tracker (tracker)]
  (assert (= (:seen? int-tracker 7) false)
          (string/format "Checking a not-yet-seen value: %q" int-tracker))

  (:see int-tracker 7)

  (assert (= (:seen? int-tracker 7) true)
          (string/format "Checking a seen value: %q" int-tracker))

  (assert (= (:seen? int-tracker 42) false)
          (string/format "Checking an unrelated value: %q" int-tracker)))

(let [table-tracker (tracker hash)
      a-table @{7 "seven"}]
  (assert (= (:seen? table-tracker a-table) false)
          (string/format "Checking a not-yet-seen value: %q" table-tracker))

  (:see table-tracker a-table)

  (assert (= (:seen? table-tracker a-table) true)
          (string/format "Checking a seen value: %q" table-tracker))

  (assert (= (:seen? table-tracker @{42 "forty-two" 7 "seven"}) false)
          (string/format "Checking an unrelated value: %q" table-tracker)))

(let [custom-tracker (tracker (fn [xs] (string/join xs "|")))]
  (assert (= (:seen? custom-tracker @["hello" "world"]) false)
          (string/format "Checking a not-yet-seen value: %q" custom-tracker))

  (:see custom-tracker @["hello" "world"])

  (assert (= (:seen? custom-tracker @["hello" "world"]) true)
          (string/format "Checking a seen value: %q" custom-tracker))

  (assert (= (:seen? custom-tracker @["hello"]) false)
          (string/format "Checking an unrelated value: %q" custom-tracker)))
