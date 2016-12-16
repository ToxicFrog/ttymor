(ns ttymor.gui
  (:import (com.googlecode.lanterna TerminalSize TextColor TextColor$Factory TextColor$ANSI SGR)
           (com.googlecode.lanterna.gui2 Panel GridLayout Label TextBox EmptySpace Button BasicWindow
                                         MultiWindowTextGUI DefaultWindowManager Borders
                                         FatWindowDecorationRenderer Panels Component AbstractComponent
                                         LinearLayout Direction GridLayout$Alignment
                                         BorderLayout BorderLayout$Location
                                         EmptyWindowDecorationRenderer AbstractWindow Window$Hint
                                         ComponentRenderer AbstractComponent)
           (com.googlecode.lanterna.screen Screen TerminalScreen)
           (com.googlecode.lanterna.terminal DefaultTerminalFactory Terminal)
           (com.googlecode.lanterna.graphics SimpleTheme)))

(defn colour [s]
  (let [colour (TextColor$Factory/fromString s)]
    (if colour
      colour
      TextColor$ANSI/DEFAULT)))

; So, to implement a new component type CT
; We need to subclass AbstractComponent<CT>
; implement createDefaultRenderer [] :-> ComponentRenderer<CT>
; and implement the DefaultCTRenderer (impl of ComponentRenderer<CT>)
; which is responsible for rendering the component.
; ComponentRenderer needs to implement getPreferredSize [CT]
; and drawComponent [TextGuiGraphics, CT]
(defn map-renderer []
  (reify ComponentRenderer
    (getPreferredSize [this map-view] (TerminalSize. 1 1))
    (drawComponent [this graphics map-view]
      (println "DefaultMapRenderer/drawComponent" graphics map-view)
      (doto graphics
        (.setBackgroundColor (colour "#800080"))
        (.setForegroundColor (colour "#B0B0B0"))
        (.fill \#)))
    ))

(defn map-view []
  (proxy [AbstractComponent] []
    (createDefaultRenderer [] (map-renderer))
    ))

(def sgrs (into-array SGR []))

(defn placeholder [title w h]
  (doto (Borders/singleLine title)
    (.setComponent (EmptySpace. (colour "#004000") (TerminalSize. (int (- w 2)) (int (- h 2)))))))

(defn label [text bg]
  (doto (Label. text)
    (.setBackgroundColor (colour bg))))

(defn make-map-view []
  (doto (Panel.)
    (.setLayoutManager (GridLayout. 2))
    (.addComponent (placeholder "HUD" 8 8) (GridLayout/createLayoutData
                                             GridLayout$Alignment/FILL GridLayout$Alignment/FILL
                                             false false 1 2))
    ; (.addComponent (placeholder "Map" 8 8) (GridLayout/createLayoutData
    ;                                          GridLayout$Alignment/FILL GridLayout$Alignment/FILL
    ;                                          true true))
    (.addComponent (map-view) (GridLayout/createLayoutData
                                             GridLayout$Alignment/FILL GridLayout$Alignment/FILL
                                             true true))
    (.addComponent (placeholder "Log" 8 8) (GridLayout/createLayoutData
                                             GridLayout$Alignment/FILL GridLayout$Alignment/FILL))
    ))

; (defn make-map-view []
;   (doto (Panel.)
;     (.setLayoutManager (BorderLayout.))
;     (.addComponent (placeholder "Log" 40 24) BorderLayout$Location/LEFT)
;     (.addComponent (placeholder "HUD" 4 10) BorderLayout$Location/BOTTOM)
;     (.addComponent (label "map" "#000080") BorderLayout$Location/CENTER)))

(defn run []
  (let [screen (TerminalScreen. (.createTerminal (DefaultTerminalFactory.)))
        window (BasicWindow. "ShockRL")
        theme (SimpleTheme. (colour "#00ff00") (colour "#000000") (into-array SGR []))
        map-view (make-map-view)
        ]

    (doto window
      (.setHints [Window$Hint/FULL_SCREEN, Window$Hint/FIT_TERMINAL_WINDOW, Window$Hint/NO_DECORATIONS])
      (.setComponent map-view))
    (.startScreen screen)
    (doto (MultiWindowTextGUI. screen (DefaultWindowManager.) (EmptySpace.))
      (.setTheme theme)
      (.addWindow window)
      (.waitForWindowToClose window))))
