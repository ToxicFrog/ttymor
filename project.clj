(defproject ttymor "0.1.0-SNAPSHOT"
  :description "A TTY-based 'demake' of Dungeons of Dredmor"
  :url "https://github.com/toxicfrog/ttymor"
  :license {:name "Apache 2.0"
            :url "https://www.apache.org/licenses/LICENSE-2.0"}
  :dependencies [[org.clojure/clojure "1.9.0-alpha14"]
                 [com.squidpony/squidlib-util "3.0.0-b9"]
                 [com.googlecode.lanterna/lanterna "3.0.0"]]
  :core.typed {:check [ttymor.core]}
  :main ^:skip-aot ttymor.core
  :target-path "target/%s"
  :profiles {:uberjar {:aot :all}})
