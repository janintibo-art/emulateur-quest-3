# Émulateur Quest 3 — v1

Application Android Godot destinée à tester rapidement sur téléphone les mécaniques de jeux conçues pour Meta Quest 3.

## Ce que fait la v1

- mode écran téléphone classique ;
- mode VR téléphone stéréoscopique via `MobileVRInterface` / `Native mobile` ;
- gyroscope et accéléromètre pour l'orientation 3DoF ;
- déplacement avec joystick tactile ;
- regard tactile sur la partie droite de l'écran quand le mode VR est coupé ;
- deux manettes Quest simulées avec A/B/X/Y, Trigger et Grip ;
- réglage manuel de la position des deux manettes ;
- hauteur du joueur réglable ;
- recentrage du joueur ;
- scène 3D de diagnostic ;
- cible de test qui réagit au Trigger droit ;
- compteur FPS ;
- compilation APK automatique avec GitHub Actions.

## Important

Cette application n'exécute pas directement un APK Quest 3 existant. Les jeux Quest utilisent OpenXR et des extensions Meta qui ne sont pas présentes sur un téléphone Android standard.

Le but du projet est de fournir une couche de simulation commune. Les jeux Godot pourront ensuite utiliser le vrai OpenXR sur Quest 3 et le simulateur sur téléphone avec le même gameplay.

## Contrôles v1

- Joystick gauche : déplacement.
- Tourner le téléphone : orientation de la tête si le gyroscope est actif.
- Glisser sur la partie droite : regarder autour de soi en mode téléphone.
- `H-` / `H+` : hauteur du joueur.
- `GYRO ON/OFF` : active ou coupe le gyroscope.
- `RECENTRER` : remet joueur, tête et manettes à zéro.
- `MODE VR` : active l'affichage stéréo MobileVR.
- A/B/X/Y, TRIG, GRIP : événements des contrôleurs simulés.
- Flèches et ±Z : déplacent les manettes virtuelles.

## Prochaine étape

v2 : couche `QuestBridge` à intégrer dans AR Sports et Tibo Narvalo pour remplacer automatiquement les entrées OpenXR par les entrées simulées lorsque le jeu tourne sur téléphone.
