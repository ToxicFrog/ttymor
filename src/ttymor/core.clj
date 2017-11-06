(ns ttymor.core
  (:gen-class)
  (:require [ttymor.gui :as gui])
  (:import [squidpony.squidgrid FOV Radius])
  )

(def terrain
  [
   [\▒ \▒ \▒ \▒ \▒ \▒ \▒]
   [\▒ \. \. \. \. \. \▒]
   [\▒ \. \. \. \. \. \▒]
   [\▒ \. \. \▒ \. \. \▒]
   [\▒ \. \. \. \. \. \▒]
   [\▒ \. \. \. \. \. \▒]
   [\▒ \▒ \▒ \▒ \▒ \▒ \▒]
   ])

(def entities
  {0 {:position [1 1] :face \@}
   })

; (defn print-terrain [terrain px py r]
;   (let [fov (fov-map terrain px py r)
;         w (count terrain)
;         h (count (first terrain))]
;     (dorun (for [y (range h) x (range w)]
;              (do
;                (if (= 0 x) (print "\n"))
;                (cond
;                  (= [x y] [px py]) (print "@")
;                  (> (aget fov x y) 0.0) (print (get-in terrain [x y]))
;                  :else (print "/"))
;              ))))
;   (println ""))

(defn -main [& args]
  ; (println "main")
  ; (print-terrain terrain 1 1 5)
  ; (print-terrain terrain 1 2 5)
  ; (print-terrain terrain 1 3 5)
  ; (print-terrain terrain 2 3 5)
  (let [game (atom {:terrain terrain :entities entities})]
    (gui/run game))
  )
