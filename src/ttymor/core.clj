(ns ttymor.core
  (:gen-class)
  ; (:require ;[ttymor.gui :as gui]
  ;           [squidlib-util.squidgrid :as squidgrid])
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

(defn map-grid [f grid]
  (map (fn [slice] (map f slice))
       grid))

(defn terrain-to-vismap [terrain]
  (->> terrain
       (map-grid #(if (= \. %) 0.0 1.0))
       (map double-array)
       into-array))
       ; (to-array-2d)))

; returns an array<float>[w][h] of visibility information
(defn fov-map [terrain x y r]
  (let [fov (FOV.)]
    (.calculateFOV fov
      (terrain-to-vismap terrain) ; resistance map
      x y r Radius/SQUARE)
    )
  )

(defn print-terrain [terrain px py r]
  (let [fov (fov-map terrain px py r)
        w (count terrain)
        h (count (first terrain))]
    (dorun (for [y (range h) x (range w)]
             (do
               (if (= 0 x) (print "\n"))
               (cond
                 (= [x y] [px py]) (print "@")
                 (> (aget fov x y) 0.0) (print (get-in terrain [x y]))
                 :else (print "/"))
             ))))
  (println ""))

(defn -main [& args]
  (println "main")
  (print-terrain terrain 1 1 5)
  (print-terrain terrain 1 2 5)
  (print-terrain terrain 1 3 5)
  (print-terrain terrain 2 3 5)
  )
