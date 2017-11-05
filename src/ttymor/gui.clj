(ns ttymor.gui
  (:require [ttymor.MapView :as MapView])
  (:import (com.googlecode.lanterna TerminalSize TerminalPosition TextColor TextCharacter TextColor$Factory TextColor$ANSI SGR)
           (com.googlecode.lanterna.gui2 Panel GridLayout Label TextBox EmptySpace Button BasicWindow
                                         MultiWindowTextGUI DefaultWindowManager Borders
                                         FatWindowDecorationRenderer Panels Component AbstractComponent
                                         LinearLayout Direction GridLayout$Alignment
                                         BorderLayout BorderLayout$Location
                                         EmptyWindowDecorationRenderer AbstractWindow Window$Hint
                                         ComponentRenderer AbstractComponent Separator TextBox)
           (com.googlecode.lanterna.screen Screen TerminalScreen)
           (com.googlecode.lanterna.terminal DefaultTerminalFactory Terminal)
           (com.googlecode.lanterna.graphics SimpleTheme BasicTextImage)))

(defn colour [s]
  (let [colour (TextColor$Factory/fromString s)]
    (if colour
      colour
      TextColor$ANSI/DEFAULT)))

(defn placeholder [w h]
  (EmptySpace. (colour "#004000") (TerminalSize. (int w) (int h))))

(defn make-gui [game]
  (doto (Panel.)
    (.setLayoutManager (doto (GridLayout. 1)
                         (.setHorizontalSpacing 0)
                         (.setLeftMarginSize 0)
                         (.setRightMarginSize 0)))
    ; (.addComponent (placeholder 8 8) (GridLayout/createLayoutData
    ;                                          GridLayout$Alignment/FILL GridLayout$Alignment/FILL
    ;                                          false false 1 3))
    ; (.addComponent (Separator. Direction/VERTICAL) (GridLayout/createLayoutData
    ;                                                 GridLayout$Alignment/FILL GridLayout$Alignment/FILL
    ;                                                 false false 1 3))
    (.addComponent (MapView/MapView game) (GridLayout/createLayoutData
                                             GridLayout$Alignment/FILL GridLayout$Alignment/FILL
                                             true true))
    ; (.addComponent (Separator. Direction/HORIZONTAL) (GridLayout/createLayoutData
    ;                                                   GridLayout$Alignment/FILL GridLayout$Alignment/CENTER))
    ; (.addComponent
    ;   (doto (TextBox. (TerminalSize. 8 8)
    ;                   "Welcome to TTYmor!")
    ;     (.setReadOnly true)
    ;     (.addLine "waffles")
    ;     (.addLine "kittens")
    ;     (.addLine "eeeeeee"))
    ;   (GridLayout/createLayoutData GridLayout$Alignment/FILL GridLayout$Alignment/FILL))
    ))

(defn run [game]
  (let [screen (TerminalScreen. (doto (.createTerminal (DefaultTerminalFactory.))
                                  (.setTitle "TTYmor")))
        window (BasicWindow. "Map View")
        theme (SimpleTheme. (colour "#80ff80") (colour "#000000") (into-array SGR []))
        gui (make-gui game)
        ]
    (println "Initializing window...")
    (doto window
      (.setHints [Window$Hint/FULL_SCREEN, Window$Hint/FIT_TERMINAL_WINDOW, Window$Hint/NO_DECORATIONS])
      (.setComponent gui))
    (println "Initializing screen...")
    (.startScreen screen)
    (println "Initializing GUI...")
    (doto (MultiWindowTextGUI. screen (DefaultWindowManager.) (EmptySpace.))
      (.setTheme theme)
      (.addWindow window)
      (.waitForWindowToClose window))))
