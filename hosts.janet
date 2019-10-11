(import argparse)

(import ./host :as host)
(import ./lang :prefix "")

(def usage
  ["Build a hosts (/etc/hosts) file from multiple sources."

   "delimiter"
   {:kind :option
    :short "d"
    :help "Whitespace to append hostname to line."
    :default "' '"} # Quoted for visibility in help text.

   "file"
   {:kind :accumulate
    :short "f"
    :help "A hosts file as input."}

   "static"
   {:kind :accumulate
    :short "s"
    :help "A static hosts entry."}])

(defn parse-and-merge
  "Parse lines in combined hosts file, merging entries as appropriate."
  [lines &opt delimiter]
  (default delimiter (or (dyn :delimiter) " "))

  (def parsed @[])

  (def host-ip @{})
  (def host-aliases @{})
  (def ip-aliases @{})

  # Parse each line, index IP address by host, normalize aliases.
  (loop [line :in lines]
    (let [record (host/parse!! line)]

      (array/push parsed record)

      (when record
        (let [hosts (host/fields record) # (first hosts) => ip
              ip (array/lpop hosts)
              aliases (or (get host-aliases (first hosts)) @{})]

          (loop [host :in hosts]
            (unless (= (get host-aliases host) aliases)
              (loop [alias :in (keys (or (get host-aliases host) @{}))]
                (put aliases alias true))
              (put host-aliases host aliases))
            (put aliases host true))

          (unless (= (get ip-aliases ip) aliases)
            (loop [alias :in (keys (or (get ip-aliases ip) @{}))]
              (put aliases alias true)
              (put host-aliases alias aliases))
            (put ip-aliases ip aliases))

          (loop [host :in (keys aliases)]
            (put host-ip host ip))))))

  (def processed @[])

  (def aliases-visit @{})
  (defn aliases/visit [aliases] (put aliases-visit (hash aliases) true))
  (defn aliases/visited? [aliases] (get aliases-visit (hash aliases)))

  # Update IP field, merge aliases, skip duplicate lines/records.
  (loop [i :range [0 (length lines)]]
    (let [line (lines i)
          record (parsed i)]
      (if record
        (let [hosts (host/fields record) # (first hosts) => ip
              ip (do
                   (array/lpop hosts)
                   (get host-ip (first hosts)))
              aliases (or (get host-aliases (first hosts)) @{})]

          (array/remove record 0) (array/insert record 0 ip)

          (when (not (aliases/visited? aliases))
            (def host-visit @{})
            (defn host/visit [host] (put host-visit host true))
            (defn host/visited? [host] (get host-visit host))
            (map (fn [host] (host/visit host)) hosts)
            (loop [host :in (sorted (keys aliases) order<)]
              (unless (host/visited? host)
                (host/add-host record host delimiter)
                (host/visit host)))
            (array/push processed (string/join record))
            (aliases/visit aliases)))

        (array/push processed line))))

  processed)

(defn main
  "Command-Line Interface."
  [&]

  (let [args (dyn :args)
        options (argparse/argparse ;usage)]
    (setdyn :prog (os/basename (first args)))

    (unless options
      (os/exit 2))

    (setdyn :delimiter (->> (get options "delimiter")
                            (string/replace "' '" " ")
                            (string/replace "t" "\t")
                            (string/replace "\\t" "\t")))

    (def lines @[])

    # Process sources in order.
    (loop [arg :in args]
      (cond
        (or (= arg "-f")
            (string/has-prefix? "--file" arg))
        (let [filepath (array/lpop (get options "file"))]
          (->> (slurp!! filepath)
               (string/trim)
               (string/split "\n")
               (array/concat lines)))

        (or (= arg "-s")
            (string/has-prefix? "--static" arg))
        (let [static (array/lpop (get options "static"))]
          (array/concat lines (string/split "\n" static)))))

    (when (empty? lines)
      (die!! "input contains no information on hosts."))

    (-> lines
        (parse-and-merge)
        (string/join "\n")
        (print))))

(if-main (main))