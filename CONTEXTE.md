# CONTEXTE — Émulateur Quest 3

## Objectif

Créer un environnement Android permettant de tester sur téléphone les jeux Godot/OpenXR destinés au Quest 3 sans devoir remettre le casque à chaque modification.

## Architecture retenue

- Quest 3 réel : OpenXR / Meta XR réels.
- Téléphone : couche de simulation.
- Le gameplay doit progressivement dépendre d'une interface commune `QuestBridge` plutôt que d'appeler directement OpenXR partout.

## v1

La v1 est un banc de test autonome. Elle valide :

1. rendu 3D Android ;
2. gyroscope ;
3. MobileVR stéréoscopique ;
4. déplacement tactile ;
5. contrôleurs virtuels ;
6. hauteur et recentrage ;
7. événements de boutons simulés ;
8. build APK automatique sur GitHub.

## Limites normales de la v1

- pas d'exécution directe d'un APK Quest existant ;
- pas de vrai suivi 6DoF du téléphone ;
- pas encore de passthrough caméra ;
- pas encore de hand tracking simulé ;
- pas encore de Scene API / boundary / anchors simulés ;
- pas encore de chargement direct d'AR Sports ou Tibo Narvalo.

## Suite prévue

- v2 : QuestBridge commun et profil contrôleurs Quest 3 ;
- v3 : caméra téléphone comme faux passthrough ;
- v4 : mains simulées, pinch et gestes ;
- v5 : boundary/guardian et pièce virtuelle ;
- v6 : outils de diagnostic XR et profils Quest 3/Quest 3S ;
- ensuite : intégration jeu par jeu.
