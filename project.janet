(declare-project
 :name "hosts"
 :description "Build a hosts (/etc/hosts) file from multiple sources."
 :license "BSD"
 :url "https://github.com/rduplain/hosts"
 :dependencies
 [{:repo "https://github.com/janet-lang/argparse.git" :tag "30acacf"}])

(declare-executable
 :name "hosts"
 :entry "hosts.janet"
 :no-core true)

(defn os/join
  "Join filepath parts according to current OS."
  [& parts]
  (case (os/which)
    :windows (string/join parts "\\")
    (string/join parts "/")))

(defn janet
  "Execute Janet file."
  [filepath]
  (os/execute [(dyn :executable "janet") filepath] :p))

(defn janet!!
  "Execute Janet file and `os/exit` if it fails."
  [filepath]
  (let [result (janet filepath)]
    (when (not= 0 result)
      (os/exit result))))

# Remove `jpm test` built-in rule.
(put (dyn :rules) "test" nil)

# Define `jpm test` to run tests in order via test-suite.janet.
(phony "test" ["build"]
       (let [suite (os/join (os/cwd) "test" "test-suite.janet")]
         (unless (os/stat suite)
           (print "test: suite file is missing: " suite)
           (os/exit 1))
         (janet!! suite)
         (print "All tests passed.")))
