(ns ttymor.gui
  (:import (com.googlecode.lanterna TerminalSize TextColor TextColor$Factory TextColor$ANSI SGR)
           (com.googlecode.lanterna.gui2 Panel GridLayout Label TextBox EmptySpace Button BasicWindow
                                         MultiWindowTextGUI DefaultWindowManager Borders
                                         FatWindowDecorationRenderer Panels Component AbstractComponent
                                         LinearLayout Direction GridLayout$Alignment
                                         BorderLayout BorderLayout$Location
                                         EmptyWindowDecorationRenderer AbstractWindow Window$Hint
                                         ComponentRenderer AbstractComponent Separator)
           (com.googlecode.lanterna.screen Screen TerminalScreen)
           (com.googlecode.lanterna.terminal DefaultTerminalFactory Terminal)
           (com.googlecode.lanterna.graphics SimpleTheme)))

(defn colour [s]
  (let [colour (TextColor$Factory/fromString s)]
    (if colour
      colour
      TextColor$ANSI/DEFAULT)))

(defn get-frustrum-1d [map-size view-size focus]
  "Given the size of one dimension of the map, the size of the same dimension of
  the view, and the coordinate that we desire to have centered on screen, return
  the parameters for the corresponding viewing frustrum as
  [map-offset view-offset render-length]."
  (if (>= view-size map-size)
    [0 (-> (- view-size map-size) (/ 2) int) map-size]
    [(-> (- focus (/ view-size 2)) (max 0) (min (- map-size view-size))) 0 view-size]))


(defn get-frustrum [map-size view-size focus]
  "Given the dimensions of the map and the view into it, return the viewing
  frustrum used to actually render the map. This consists of three vectors:
  :origin, the point at which to draw the upper left of the map;
  :start, the [x y] coordinates in the map at which to start drawing;
  :size, the [w h] of the rectangle of map to draw.

  If the map is smaller that the view, :start will always be [0 0] and :size
  will be the size of the map, and :origin will be whatever it takes to center
  the map in the view.

  If the map is larger than the view, it tries to place `center` at the center
  of the view without allowing extra space to either side."
  (apply map vector (map get-frustrum-1d map-size view-size focus)))

(defn map-renderer [game]
  (reify ComponentRenderer
    (getPreferredSize [this map-view] (TerminalSize. 1 1))
    (drawComponent [this graphics map-view]
      (let [terrain (@game :terrain)
            entities (@game :entities)
            h (count terrain)
            w (count (terrain 0))
            gsize (.getSize graphics)
            [map-origin view-origin render-size]
            (get-frustrum [w h] [(.getColumns gsize) (.getRows gsize)] [3 3])]
        (doto graphics
          (.setBackgroundColor (colour "#000000"))
          (.setForegroundColor (colour "#B0FFB0"))
          (.fill \space))
        (dorun
          (for [row (range (render-size 1)) col (range (render-size 0))]
            (.setCharacter graphics
                           (+ col (view-origin 0))
                           (+ row (view-origin 1))
                           ((terrain (+ col (map-origin 1))) (+ row (map-origin 0))))))
      ))))

(defn map-view [game]
  (proxy [AbstractComponent] []
    (createDefaultRenderer [] (map-renderer game))
    ))

(defn placeholder [w h]
  (EmptySpace. (colour "#004000") (TerminalSize. (int w) (int h))))

(defn make-gui [game]
  (doto (Panel.)
    (.setLayoutManager (doto (GridLayout. 3)
                         (.setHorizontalSpacing 0)
                         (.setLeftMarginSize 0)
                         (.setRightMarginSize 0)))
    (.addComponent (placeholder 8 8) (GridLayout/createLayoutData
                                             GridLayout$Alignment/FILL GridLayout$Alignment/FILL
                                             false false 1 3))
    (.addComponent (Separator. Direction/VERTICAL) (GridLayout/createLayoutData
                                                    GridLayout$Alignment/FILL GridLayout$Alignment/FILL
                                                    false false 1 3))
    (.addComponent (map-view game) (GridLayout/createLayoutData
                                             GridLayout$Alignment/FILL GridLayout$Alignment/FILL
                                             true true))
    (.addComponent (Separator. Direction/HORIZONTAL) (GridLayout/createLayoutData
                                                      GridLayout$Alignment/FILL GridLayout$Alignment/FILL))
    (.addComponent (placeholder 8 8) (GridLayout/createLayoutData
                                             GridLayout$Alignment/FILL GridLayout$Alignment/FILL))
    ))

(defn run [game]
  (let [screen (TerminalScreen. (.createTerminal (DefaultTerminalFactory.)))
        window (BasicWindow. "ShockRL")
        theme (SimpleTheme. (colour "#00ff00") (colour "#000000") (into-array SGR []))
        gui (make-gui game)
        ]

    (doto window
      (.setHints [Window$Hint/FULL_SCREEN, Window$Hint/FIT_TERMINAL_WINDOW, Window$Hint/NO_DECORATIONS])
      (.setComponent gui))
    (.startScreen screen)
    (doto (MultiWindowTextGUI. screen (DefaultWindowManager.) (EmptySpace.))
      (.setTheme theme)
      (.addWindow window)
      (.waitForWindowToClose window))))
