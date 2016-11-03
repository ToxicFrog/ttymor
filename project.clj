(defproject ttymor "0.1.0-SNAPSHOT"
  :description "A TTY-based 'demake' of Dungeons of Dredmor"
  :url "https://github.com/toxicfrog/ttymor"
  :license {:name "Apache 2.0"
            :url "https://www.apache.org/licenses/LICENSE-2.0"}
  :dependencies [[org.clojure/clojure "1.8.0"]
                 [org.clojure/core.typed "0.3.26"]
                 [com.googlecode.lanterna/lanterna "3.0.0-beta3"]]
  ; :injections [(require 'clojure.core.typed)
  ;              (clojure.core.typed/install)]
  :core.typed {:check [ttymor.core]}
  :main ^:skip-aot ttymor.core
  :target-path "target/%s"
  :profiles {:uberjar {:aot :all}})
