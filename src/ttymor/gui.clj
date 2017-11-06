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

(defn- colour [s]
  (let [colour (TextColor$Factory/fromString s)]
    (if colour
      colour
      TextColor$ANSI/DEFAULT)))

(defn- placeholder [c w h]
  (EmptySpace. (colour c) (TerminalSize. (int w) (int h))))

(defn- grid-layout
  ([grab-extra] (grid-layout grab-extra 1 1))
  ([grab-extra w h] (GridLayout/createLayoutData
                       GridLayout$Alignment/FILL GridLayout$Alignment/FILL
                       grab-extra grab-extra w h))
  )

(defn make-gui [game]
  (doto (Panel.)
    (.setLayoutManager (doto (GridLayout. 3)
                         (.setHorizontalSpacing 0)
                         (.setLeftMarginSize 0)
                         (.setRightMarginSize 0)))
    (.addComponent (placeholder "#008000" 16 8) (grid-layout false 1 3))
    (.addComponent (Separator. Direction/VERTICAL) (grid-layout false 1 3))
    (.addComponent (MapView/MapView game) (grid-layout true))
    (.addComponent (Separator. Direction/HORIZONTAL) (grid-layout false))
    (.addComponent (placeholder "#800000" 8 2) (grid-layout false))
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
