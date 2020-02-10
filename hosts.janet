(import argparse)

(import ./host :as host)
(import ./lang :prefix "")

(def version (-> (sh "git describe --tags --dirty") (string/trim) (not-empty)))

(def usage
  ["Build a hosts (/etc/hosts) file from multiple sources."

   "delimiter"
   {:kind :option
    :short "d"
    :help "Whitespace to append hostname."
    :default "' '"} # Quoted for visibility in help text.

   "file"
   {:kind :accumulate
    :short "f"
    :help "A hosts file as input."}

   "static"
   {:kind :accumulate
    :short "s"
    :help "A static hosts entry."}

   "version"
   {:kind :flag
    :short "v"
    :help "Output version, then exit."}])

(def Hosts
  "Model of IP mapped to collection of hostnames, create with `(hosts)`."

  @{:init (fn [self]
            (-> self
                (put :ip-hosts @{})
                (put :host-ip @{})))

    # Public lookup API.
    :hosts (fn [self ip] (-> (keys (:get-hosts self ip)) (sorted) (not-empty)))
    :ip (fn [self host] (:get-ip self host))

    # Public update API.
    :update (fn [self ip & hosts]
              (let [ip-host-set (:get-hosts self ip)
                    host-set @{}]
                (loop [host :in hosts]
                  (put host-set host true))
                (:set-hosts self ip (merge ip-host-set host-set)))
              (:propagate self ip)
              self)

    # "Private" methods follow.
    :propagate (fn [self ip]
                 (loop [host :in (keys (:get-hosts self ip))]
                   (let [host-ip (:get-ip self host)]
                     (:set-ip self host ip)
                     (when (and host-ip (not= host-ip ip))
                       (when-let [ip-host-set (:get-hosts self host-ip)]
                         (:set-hosts self host-ip nil)
                         (apply :update self ip (keys ip-host-set)))))))

    :get-hosts (fn [self ip] (get (self :ip-hosts) ip @{}))
    :set-hosts (fn [self ip hosts] (put (self :ip-hosts) ip hosts))
    :get-ip (fn [self host] (get (self :host-ip) host))
    :set-ip (fn [self host ip] (put (self :host-ip) host ip))})

(defn hosts
  "Create an instance of `Hosts` for IP-to-hostname(s) relationships."
  []
  (:init (table/setproto @{} Hosts)))

(defn parse-and-merge
  "Parse lines in combined hosts file, merging entries as appropriate."
  [lines &opt delimiter]
  (default delimiter (or (dyn :delimiter) " "))

  (def parsed @[])

  (def ipv4 (hosts))
  (def ipv6 (hosts))

  # Parse each line, index IP address by host, normalize aliases.
  (loop [line :in lines]
    (let [record (host/parse!! line)]

      (array/push parsed record)

      (when record
        (let [hosts (host/fields record) # (first hosts) => ip
              ip (array/lpop hosts)]
          (apply :update (if (host/ipv4? ip) ipv4 ipv6) ip hosts)))))

  (def processed @[])

  (def ip-visit @{})
  (defn ip/visit [ip] (put ip-visit ip true))
  (defn ip/visited? [ip] (get ip-visit ip))

  # Update parsed IP field, merge aliases, skip duplicate lines/records.
  (loop [i :range [0 (length lines)]]
    (let [line (lines i)
          record (parsed i)]
      (if record
        (let [hosts (host/fields record) # (first hosts) => ip
              record-ip (array/lpop hosts)
              ip (:ip (if (host/ipv4? record-ip) ipv4 ipv6) (first hosts))
              aliases (:hosts (if (host/ipv4? record-ip) ipv4 ipv6) ip)]

          (array/remove record 0) (array/insert record 0 ip)

          (when (not (ip/visited? ip))
            (def host-visit @{})
            (defn host/visit [host] (put host-visit host true))
            (defn host/visited? [host] (get host-visit host))
            (map (fn [host] (host/visit host)) hosts)
            (loop [host :in aliases]
              (unless (host/visited? host)
                (host/add-host record host delimiter)
                (host/visit host)))
            (array/push processed (string/join record))
            (ip/visit ip)))

        (array/push processed line))))

  processed)

(defn main
  "Command-Line Interface."
  [&]

  (setdyn :version version)

  (let [args (dyn :args)
        options (argparse/argparse ;usage)]
    (setdyn :prog (os/basename (first args)))

    (unless options
      (os/exit 2))

    (when (get options "version")
      (print (dyn :prog) " " (or (dyn :version) "vUNKNOWN"))
      (os/exit 0))

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
