(ns ttymor.core {:lang :core.typed}
  (:gen-class)
  ; core.typed provides typed versions of these functions
  (:refer-clojure :exclude [atom doseq let fn defn ref cast dotimes defprotocol loop for])
  (:use clojure.core.typed)
  (:import (com.googlecode.lanterna TerminalSize TextColor)
           (com.googlecode.lanterna.gui2 Panel GridLayout Label TextBox EmptySpace Button BasicWindow
                                         MultiWindowTextGUI DefaultWindowManager)
           (com.googlecode.lanterna.screen Screen TerminalScreen)
           (com.googlecode.lanterna.terminal DefaultTerminalFactory Terminal))
  )

(non-nil-return com.googlecode.lanterna.terminal.DefaultTerminalFactory/createTerminal :all)

(defmacro rn [& forms]
  `(proxy [Runnable] [] (run [] ~@forms)))

(defn -main
  [& args]
  (let [screen :- TerminalScreen (TerminalScreen. (.createTerminal (DefaultTerminalFactory.)))
        panel :- Panel (Panel.)
        window :- BasicWindow (BasicWindow.)]
    (doto panel
      (.setLayoutManager (GridLayout. 2))
      (.addComponent (Label. "Forename"))
      (.addComponent (TextBox.))
      (.addComponent (Label. "Surname♥"))
      (.addComponent (TextBox.))
      (.addComponent (EmptySpace. (TerminalSize. 0 0)))
      (.addComponent (Button. "Submit"
                              (rn (.stopScreen screen) (System/exit 0))))
      )
    (.setComponent window panel)
    (.startScreen screen)
    (doto (MultiWindowTextGUI. screen
                               (DefaultWindowManager.)
                               (EmptySpace.))
      (.addWindowAndWait window))))
