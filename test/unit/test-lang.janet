(import ../../lang :prefix "")

(let [arr @[0 1 2 3]
      head (array/lpop arr)]
  (unless (deep= arr @[1 2 3])
    (error (string "unexpected arr: @["
                   (string/join (map string arr) " ") "]")))
  (unless (= head 0) (error (string "unexpected head: " head))))

(case (os/which)
  :windows
   (let [filepath "C:\\bin\\prog.exe"
         basename (os/basename filepath)]
     (unless (= basename "prog.exe")
       (error (string "unexpected basename for " filepath ": " basename))))

   (let [filepath "/usr/bin/prog"
         basename (os/basename filepath)]
     (unless (= basename "prog")
       (error (string "unexpected basename for " filepath ": " basename)))))
