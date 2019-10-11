(import ./lang :prefix "")

(def ipv4
  '{:digit (range "09")
    :0-4 (range "04")
    :0-5 (range "05")
    :byte (choice
           (sequence "25" :0-5)
           (sequence "2" :0-4 :digit)
           (sequence "1" :digit :digit)
           (between 1 2 :digit))
    :main (sequence :byte "." :byte "." :byte "." :byte)})

(def ipv6-ish
  '{:hex (range "09" "af" "AF")
    :main (sequence (some (choice :hex ":" ".")))})

(def ws '(set " \t"))

(def comment
  ~{:comment (* "#" (any (if-not (+ "\n" -1) 1)))
    :ws ,ws
    :main (sequence (any :ws) :comment)})

(defn validate-hostname!
  "In context of existing parser, validate hostname or raise an error."
  [hostname]
  (if-not (and (<= (length hostname) 63)
               (peg/match '(range "az" "AZ") hostname)
               (not (string/has-suffix? "-" hostname)))
    (error (string "invalid name in hostname: " hostname))
    hostname))

(def hostname
  ~{:hostname (some (choice (range "az" "AZ" "09") "-"))
    :main (drop (cmt (capture :hostname) ,validate-hostname!))})

(defn validate-domain-length!
  "In context of existing parser, validate domain name or raise an error."
  [domain]
  (if-not (<= (length domain) 253)
    (error (string "domain is too long: " domain))
    domain))

(def domain
  ~{:domain (sequence ,hostname (some (sequence "." ,hostname)))
    :main (drop (cmt (capture :domain) ,validate-domain-length!))})

(def host-line
  ~{:comment ,comment
    :ip (choice ,ipv4 ,ipv6-ish)
    :ws ,ws
    :digit (range "09")
    :letter (range "az" "AZ")
    :hostname ,hostname
    :domain ,domain
    :host (choice :domain :hostname)
    :main (sequence (capture :ip)
                    (some (sequence (capture (some :ws))
                                    (capture :host)))
                    (? (capture :comment)))})

(def comment-grammar (peg/compile comment))
(def host-line-grammar (peg/compile host-line))

(defn parse
  "Parse a hosts (/etc/hosts) line to its components, including whitespace.

  Return nil if a valid non-data (blank/comment) line; raise error if invalid."
  [line]
  (let [record (peg/match host-line-grammar line)]
    (if-not record
      (unless (or (= line "")
                  (peg/match ~(sequence (some ,ws) -1) line)
                  (peg/match comment-grammar line))
        (error (string "invalid hosts line:\n" line)))
      record)))

(defn parse!!
  "Like `parse`, but `os/exit` on error."
  [line]
  (try
    (parse line)
    ([err] (die!! err))))

(defn fields
  "Filter parsed host line to data fields."
  [parsed]
  (when parsed
    (filter (fn [item] (not (peg/match ~(choice ,comment (some ,ws)) item)))
            parsed)))

(defn add-host
  "Append host to record, inserting before the host-line comment (if exists)."
  [record host &opt delimiter]
  (default delimiter " ")
  (let [at (if (peg/match comment-grammar (last record))
             -2
             -1)]
    (array/insert record at delimiter host)))