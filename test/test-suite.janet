(defmacro run
  "Run modules by importing them, exiting on failures."
  [& modules]
  (map (fn [module] ~(import ,module :exit true)) modules))

(run ./unit/test-lang
     ./unit/test-host
     ./unit/test-hosts
     ./integration/test-hosts)
