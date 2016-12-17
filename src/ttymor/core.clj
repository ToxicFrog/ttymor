(ns ttymor.core
  (:gen-class)
  (:require [ttymor.gui :as gui])
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

(defn -main [& args]
  (let [game (atom {:terrain terrain :entities entities})]
    (gui/run game)))
