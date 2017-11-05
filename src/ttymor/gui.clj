(ns ttymor.gui
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

(defn image-from [terrain entities]
  (let [w (count terrain)
        h (count (first terrain))
        image (BasicTextImage. w h)]
    (dorun
      (for [x (range w) y (range h)]
        (.setCharacterAt image x y (TextCharacter. (get-in terrain [x y])))))
    (dorun (map (fn [[id entity]]
                  (.setCharacterAt image
                                   (get-in entity [:position 0])
                                   (get-in entity [:position 1])
                                   (TextCharacter. (:face entity))))
                entities))
    (println "TextImage created:" image)
    image))

(defn map-renderer [game]
  (reify ComponentRenderer
    (getPreferredSize [this map-view] (TerminalSize. 1 1))
    (drawComponent [this graphics map-view]
      (let [terrain (@game :terrain)
            entities (@game :entities)
            [x y] (get-in entities [0 :position])
            gsize (.getSize graphics)
            [w h] [(.getColumns gsize) (.getRows gsize)]
            ]
        (doto graphics
          (.fill \space)
          (.drawImage (TerminalPosition.
                        (- (/ w 2) x)
                        (- (/ h 2) y))
                      (image-from terrain entities)))
      ))))

(defn MapView [game]
  (proxy [AbstractComponent] []
    (createDefaultRenderer [] (map-renderer game))
    ))

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
    (.addComponent (MapView game) (GridLayout/createLayoutData
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

; plan: we have the MapView as a borderless component that displays the map centered
; on the current player location (which will have to be stored in an atom, so we
; probably pass it the entire game state and let it deref and extract stuff like
; the map grid and player coordinates).
; problem: if we have an asymmetric HUD this results in the player being off center
; in the map view. Booo. We may need to make the map view a window in its own right
; after all.
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
