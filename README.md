# ShuttleDashboard — Tableau de bord navette électrique 8 places

Livrable **Groupe II — Frontend** du challenge technique navette électrique : composant d'affichage du cadran vitesse / kilométrage et de la jauge d'accélérateur, développé en **Qt/QML**, alimenté par des données simulées variant en temps réel.

## Projet

Ce dépôt contient l'interface de tableau de bord destinée à l'écran 10" du poste de conduite de la navette (Raspberry Pi 4, résolution **1280 × 800**). Elle affiche :

- un **cadran de vitesse** animé (0 à 50 km/h, vitesse critique du cahier des charges) ;
- un **compteur kilométrique** cumulatif ;
- une **jauge d'accélérateur** interactive (0-100 %) pilotant la vitesse affichée, avec un comportement physique cohérent : inertie à l'accélération, décélération en roue libre au relâchement.

Le périmètre de ce livrable est strictement **frontend** : aucune lecture matérielle, aucun backend. Les données du véhicule (vitesse, distance, accélérateur) sont générées par un simulateur interne, conçu pour être remplacé par le flux réel du bus CAN sans modifier l'interface (voir [Architecture](#architecture)).

## Lancement & Dépendances

### Option A — Via Docker (recommandé pour vérifier la portabilité Linux)

Le `Dockerfile` fourni configure, compile et lance un test de démarrage (« smoke test ») headless de l'application sur une image Ubuntu 24.04 :

```bash
docker build -t shuttle-dashboard dashboard/
```

Un build réussi confirme que le projet compile et démarre correctement sur un environnement Linux propre. **Limite assumée** : ce conteneur tourne en x86_64 et en rendu *offscreen* (`QT_QPA_PLATFORM=offscreen`, pas d'affichage réel) — il valide la portabilité du code, pas les performances graphiques réelles du Raspberry Pi 4. Pour voir l'interface s'afficher, utiliser l'option B sur une machine Linux avec serveur graphique, ou directement sur la cible.

### Option B — Build natif (Linux / Raspberry Pi OS, Debian, Ubuntu)

**Dépendances (Qt6 ≥ 6.2)** :

```bash
sudo apt-get update && sudo apt-get install -y \
    build-essential cmake ninja-build pkg-config \
    qt6-base-dev qt6-declarative-dev \
    qml6-module-qtquick \
    qml6-module-qtquick-controls \
    qml6-module-qtquick-templates2 \
    qml6-module-qtquick-window \
    qml6-module-qtqml-workerscript
```

**Configuration, compilation et lancement** :

```bash
cmake -S dashboard -B dashboard/build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build dashboard/build
./dashboard/build/ShuttleDashboard
```

L'application s'ouvre dans une fenêtre fixe de 1280 × 800 px (résolution cible de l'écran embarqué). La jauge d'accélérateur se pilote avec le curseur affiché sous la jauge « PWR » — ce curseur est le substitut de test de la pédale physique pour ce prototype (voir [Groupe III — Firmware](#architecture)).

## Architecture

Le projet applique une règle de découplage stricte, exigée par le cahier des charges : **la génération des données simulées est isolée dans un unique composant dédié**, afin que son remplacement par le flux CAN réel ne nécessite aucune modification du code d'affichage.

```
Main.qml                      → rendu / mise en page uniquement
 └─ VehicleDataSimulator.qml   → SEUL fichier qui "sait" que les données sont simulées
     └─ SimulationEngine.js    → module JS pur : physique + état du véhicule
SpeedometerGauge.qml           → composant de rendu pur (cadran vitesse)
ThrottleGauge.qml               → composant de rendu pur (jauge accélérateur)
Theme.qml                      → jetons de design centralisés (design system "Lumina Transit")
Translations.js                → i18n minimaliste (fr/en)
```

**Comment les données simulées sont générées.** `SimulationEngine.js` est un module JavaScript pur (`.pragma library`) : aucune dépendance à un type QML (pas de `Timer`, pas de binding). Il ne contient que l'état du véhicule (vitesse, odomètre, position pédale) et les fonctions physiques qui le font évoluer. Cette absence totale de dépendance QML le rend testable unitairement de façon isolée (ex. avec `node`).

`VehicleDataSimulator.qml` est le composant dédié imposé par la contrainte d'architecture : il embarque un `Timer` cadencé à 20 Hz (50 ms) qui, à chaque tick, mesure le temps réellement écoulé (`Date.now()`, plus robuste à la gigue d'un Raspberry Pi qu'un intervalle nominal), appelle `SimulationEngine.js`, puis republie l'état sous forme de propriétés QML *bindables* : `throttlePercent` (entrée), `speedKmh` et `odometerKm` (sorties).

**Comment QML consomme ces données.** `Main.qml` ne connaît que cette interface à trois propriétés. Il ne contient aucun calcul physique et ignore tout du fait que la source est simulée. Il transmet simplement `vehicleData.speedKmh` et `vehicleData.odometerKm` aux composants de rendu (`SpeedometerGauge`, affichage odomètre), et répercute la position du curseur de test vers `vehicleData.throttlePercent`. `SpeedometerGauge.qml` et `ThrottleGauge.qml` sont eux-mêmes de purs composants de rendu : ils reçoivent des nombres et les affichent, sans jamais savoir d'où ils viennent.

**Bascule vers le bus CAN réel.** Le jour où le firmware pédale (Groupe III) expose le bus CAN réel, il suffit de remplacer `VehicleDataSimulator.qml` par un composant équivalent (ex. `VehicleCanBusReader.qml`) qui ouvre un socket SocketCAN, décode les trames et alimente les mêmes trois propriétés (`throttlePercent`, `speedKmh`, `odometerKm`). Aucun autre fichier du projet n'a besoin d'être modifié.

Pour le détail des choix de durcissement (portabilité Linux, cohérence physique, performance de rendu à 60 FPS), voir [`dashboard/RAPPORT_AUDIT_QA.md`](dashboard/RAPPORT_AUDIT_QA.md).

## Structure des données simulées

Le contrat de données exposé par `VehicleDataSimulator.qml` — celui qu'un futur flux CAN réel devra respecter à l'identique — comprend trois variables :

| Variable | Sens | Unité | Plage | Rôle |
|---|---|---|---|---|
| `throttlePercent` | Entrée (écrite par l'UI) | % | 0 – 100 | Position de la pédale/jauge d'accélérateur |
| `speedKmh` | Sortie | km/h | 0 – 50 | Vitesse courante du véhicule |
| `odometerKm` | Sortie | km | ≥ 0, cumulatif | Distance totale parcourue, jamais remise à zéro |

**Mise à jour.** À chaque tick du `Timer` (50 ms, 20 Hz), `SimulationEngine.js` intègre l'état sur le pas de temps réellement écoulé (`dt`) :

- **Accélérateur enfoncé** (`throttlePercent > 0`) : accélération **constante**, proportionnelle à la position pédale, calibrée pour atteindre exactement 50 km/h après 15 secondes à pédale à fond — conformément au cahier des charges. L'accélération étant constante durant cette phase, l'intégration reste exacte quel que soit le pas de temps.
- **Accélérateur relâché** (`throttlePercent == 0`) : décélération « roue libre », calculée à partir de l'équation de résistance au roulement (« road load ») du véhicule réel — résistance au roulement quasi constante + traînée aérodynamique croissant avec le carré de la vitesse — et non d'une décroissance arbitraire. Les constantes utilisées (masse 2 200 kg, Crr 0,012, Cx 0,70, surface frontale 3,47 m²) sont reprises de l'étude technique du véhicule.
- La vitesse est bornée à `[0, 50]` km/h et le pas de temps `dt` est plafonné à 250 ms, pour éviter qu'un éventuel ralentissement ponctuel du thread graphique (charge CPU, pause du ramasse-miettes) ne fasse « téléporter » la vitesse affichée au lieu de l'animer en douceur.
- L'odomètre s'incrémente de `vitesse × dt` à chaque tick, sans jamais être remis à zéro.
