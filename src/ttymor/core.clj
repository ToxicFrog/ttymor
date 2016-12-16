(ns ttymor.core
  (:gen-class)
  (:require [ttymor.gui :as gui])
  )

(defn -main
  [& args]
  (gui/run))
