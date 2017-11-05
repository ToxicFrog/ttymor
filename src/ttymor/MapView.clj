(ns ttymor.MapView
  (:import (com.googlecode.lanterna TerminalSize TerminalPosition TextCharacter)
           (com.googlecode.lanterna.gui2 AbstractInteractableComponent InteractableRenderer Interactable$Result)
           (com.googlecode.lanterna.graphics BasicTextImage)))

(defn- image-from [terrain entities]
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
    image))

(defn- MapRenderer [game]
  (reify InteractableRenderer
    (getPreferredSize [this component] (TerminalSize. 1 1))
    (getCursorLocation [this component] (TerminalPosition. 1 1))
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
                      (image-from terrain entities)))))
    ))

(defn MapView [game]
  (proxy [AbstractInteractableComponent] []
    (createDefaultRenderer [] (MapRenderer game))
    (handleKeyStroke
      [keystroke]
      (println "HandleKeystroke: " keystroke)
      Interactable$Result/HANDLED)
    ))
