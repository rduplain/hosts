(def- os-windows (= (os/which) :windows))

(defmacro with-output
  "Execute command (as string), capture stdout/stderr in unhygienic `output`."
  [command & body]
  (with-syms [fd buf]
    ~(let [output @""]
       (with [,fd (file/popen (string ,command " 2>&1") :r)]
         (var ,buf @"")
         (while ,buf
           (buffer/push-string output ,buf)
           (set ,buf (file/read ,fd 4096)))) # Note: :all never returns nil.
       ,;body)))

(defmacro assert-contains
  "Run command, assert that its output contains the given pattern."
  [command patt]
  ~(with-output ,command
     (unless (string/find ,patt output)
       (print "command: " ,command "\n"
              "output:\n" output "\n"
              "expected to contain:\n" ,patt "\n")
       (error "output does not contain expected content"))))

(defmacro assert-output
  "Run command, assert that its (trimmed) output is as (trimmed) expected."
  [command expected]
  ~(with-output ,command
     (unless (= (string/trim ,expected) (->> output
                                             (string/replace-all "\r" "")
                                             (string/trim)))
       (print "command: " ,command "\n"
              "output:\n" output "\n"
              "expected:\n" ,expected "\n")
       (error "output does not match"))))

(defmacro assert-match
  "Run command, assert that its output matches given grammar."
  [command patt]
  ~(with-output ,command
     (unless (peg/match ,patt output)
       (print "command: " ,command "\n"
              "output:\n" output "\n"
              "expected to match:\n" (string/format "%q" ,patt) "\n")
       (error "output does not match expected pattern"))))

(defn- test-hosts
  "Test hosts invocation with `exe` as prefix to test command-line strings."
  [exe]

  (if (string/has-suffix? "integration" (os/cwd))
    (os/cd ".."))

  (if (string/has-suffix? "test" (os/cwd))
    (os/cd ".."))

  (defmacro hosts [& args] (string/join [exe ;args] " "))

  (assert-contains
   (hosts)
   "input contains no information on hosts")

  (assert-contains
   (hosts "-h")
   "Show this help message.")

  (assert-match
   (hosts "-v")
   '(sequence "hosts" (? ".exe") (? ".janet") " v"))

  (assert-match
   (hosts "--version")
   '(sequence "hosts" (? ".exe") (? ".janet") " v"))

  (assert-contains
   (hosts "--fake")
   "unknown option")

  (assert-output
   (hosts "-s" "\"127.0.0.1 localhost # comment\"")
   "127.0.0.1 localhost # comment")

  (assert-output
   (hosts "-s" "\"::1     ip6-localhost ip6-loopback # comment\"")
   "::1     ip6-localhost ip6-loopback # comment")

  (assert-output
   (hosts "-s" "\"127.0.0.1 localhost # comment\""
            "-s" "\"127.0.0.1  localhost.local\"")
   "127.0.0.1 localhost localhost.local # comment")

  (assert-output
   (hosts "-s" "\"127.0.0.1\tlocalhost\t# comment\""
            "-s" "\"127.0.0.1  localhost.local\""
            "-d" "t")
   "127.0.0.1\tlocalhost\tlocalhost.local\t# comment")

  (assert-contains
   (hosts "-s" "\"127.0.0.1 localhost- # comment\"")
   "invalid name in hostname: localhost-")

  (assert-contains
   (hosts "-s" "\"127.0.0.1 localhost # comment\""
            "-s" "\"  invalid\"")
   "invalid hosts line")

  (let [expected
        (string
         "# Test hosts (/etc/hosts) file.\n"
         "127.0.0.1       localhost # IPv4 localhost\n"
         "127.0.1.1       example example.local # hostname\n"
         "\n"
         "192.168.1.202   server server.local a.server.local b.server.local\n"
         "192.168.1.101   another another.local server.another.local\n"
         "\n"
         "# IPv6\n"
         "::1             ip6-localhost ip6-loopback # IPv6 localhost\n"
         "fe00::0         ip6-localnet\n"
         "ff00::0         ip6-mcastprefix\n"
         "ff02::1         ip6-allnodes\n"
         "ff02::2         ip6-allrouters\n"
         "\n"
         "# More IPv4\n"
         "192.168.1.200   example.com server.example.com www.example.com\n")]

  (assert-output
   (hosts "-f" (if os-windows ".\\test\\etc\\hosts" "./test/etc/hosts")
            "-s" "\"127.0.1.1 example.local\""
            "-s" "\"192.168.1.100 a.server.local # no comment\""
            "-s" "\"192.168.1.200 www.example.com # no comment\""
            "-f" (if os-windows ".\\test\\etc\\sample" "./test/etc/sample")
            "-s" "\"192.168.1.100 a.server.local b.server.local\""
            "-s" "\"192.168.1.202 b.server.local\"")
   expected)

  (assert-output
   (hosts "-f" (if os-windows ".\\test\\etc\\hosts" "./test/etc/hosts")
            "-f" (if os-windows ".\\test\\etc\\sample" "./test/etc/sample")
            "-s" "\"192.168.1.100 a.server.local # no comment\""
            "-s" "\"192.168.1.100 a.server.local b.server.local\""
            "-s" "\"192.168.1.200 www.example.com # no comment\""
            "-s" "\"192.168.1.202 b.server.local\""
            "-s" "\"127.0.1.1 example.local\"")
   expected)))

# Assume `jpm test` includes `jpm build` as prerequisite.
(test-hosts "janet hosts.janet")
(test-hosts (if os-windows ".\\build\\hosts.exe" "./build/hosts"))
