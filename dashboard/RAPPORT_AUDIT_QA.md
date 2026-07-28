# Rapport d'audit — Portabilité Linux, physique embarquée, performance de rendu

**Périmètre** : `dashboard/` (Groupe II — Frontend, tableau de bord Qt/QML de la navette électrique)
**Rôle de l'audit** : durcissement de l'existant. Aucune fonctionnalité visuelle ajoutée ; uniquement des corrections de portabilité, de physique et de performance.

## Méthodologie et limites assumées

Cet audit a été fait par **relecture statique complète** (les 9 fichiers de `dashboard/`) et par **vérification mathématique** des formules physiques contre `Electric vehicle project.md` (étude technique source). Point important par honnêteté : cette session tourne sur une machine Windows sans environnement Linux fonctionnel (Docker Desktop présent mais son moteur ne démarre pas ici ; WSL2 indisponible faute de virtualisation activée). **Le Dockerfile fourni n'a donc pas pu être compilé de bout en bout dans cette session** — il est construit sur des paquets Ubuntu/Debian standards et bien connus, mais je recommande de le lancer (`docker build`) avant soumission pour avoir la confirmation finale. Tout le reste (audit de chemins, de fins de ligne, calculs physiques) a été vérifié directement sur les fichiers.

---

## 1. Audit de portabilité Linux/POSIX

| # | Constat | Gravité | Statut |
|---|---|---|---|
| 1.1 | Aucun chemin absolu Windows (`C:\...`), aucun backslash, aucune dépendance à un outil Windows-only dans le code source. | — | ✅ Rien à corriger (déjà propre) |
| 1.2 | **Tous les fichiers sources (`.qml`, `.js`, `.cpp`, `CMakeLists.txt`) étaient encodés en CRLF** (fins de ligne Windows), confirmé octet par octet. Sans garde-fou, un futur commit depuis Windows peut réintroduire du CRLF ; si un script shell venait à être ajouté (ex. dans le Dockerfile), le CRLF y casse l'exécution sous Linux (`/bin/sh^M: bad interpreter`). | Moyenne | ✅ Corrigé |
| 1.3 | `main.cpp` utilise `QQmlApplicationEngine::loadFromModule(...)`, une API introduite en **Qt 6.5**. Les dépôts Debian/Raspberry Pi OS livrent souvent une version Qt6 plus ancienne que la dernière disponible : un Qt6 < 6.5 sur le Pi ferait échouer la compilation avec ce code. | Haute | ✅ Corrigé |
| 1.4 | `CMakeLists.txt` ne fixait aucune version minimale de Qt6, alors que le projet dépend déjà implicitement de l'API CMake moderne (`qt_add_qml_module`, `qt_standard_project_setup`, disponible depuis Qt 6.2). Sans plancher explicite, un Qt trop ancien sur la cible produit une erreur de compilation tardive et confuse plutôt qu'un échec de configuration clair. | Moyenne | ✅ Corrigé |
| 1.5 | Les polices **"Inter" / "JetBrains Mono"** (design system, `maquette/DESIGN.md`) sont référencées uniquement par nom (`font.family`), sans repli. Ce ne sont pas des paquets standard Debian/Raspberry Pi OS — la maquette HTML les charge depuis Google Fonts en ligne (`maquette/code.html`), donc rien ne garantit leur présence sur l'image Pi hors-ligne. Si absentes, Qt substitue silencieusement une police système quelconque, ce qui casse en particulier l'alignement tabulaire des chiffres qui changent en temps réel (vitesse, odomètre, PWR) — exactement ce que la police mono est censée garantir selon `DESIGN.md`. | Moyenne | ✅ Atténué (voir note) |

### Détail des corrections

**1.2 — Fins de ligne.** Ajout d'un `.gitattributes` à la racine (`* text=auto eol=lf` + règles explicites par extension) et normalisation de tous les fichiers existants en LF. Vérifié octet par octet (0 caractère `\r` restant dans chaque fichier).

**1.3 — `main.cpp`.** Remplacé `engine.loadFromModule("Dashboard", "Main")` par la forme portable :
```cpp
engine.load(QUrl(QStringLiteral("qrc:/qt/qml/Dashboard/Main.qml")));
```
combinée à `objectCreated` (au lieu de `objectCreationFailed`, lui aussi plus récent) pour détecter un échec de chargement QML. Cette forme fonctionne dès Qt 6.2 tout en restant valide sur les versions plus récentes — elle ne dépend donc pas de la version exacte de Qt6 disponible via `apt` sur la cible.

**1.4 — `CMakeLists.txt`.** `find_package(Qt6 6.2 REQUIRED COMPONENTS ...)` : échec de configuration immédiat et explicite si le Qt6 installé est trop ancien, au lieu d'un échec de compilation à un endroit arbitraire.

**1.5 — Polices.** Note honnête : je n'ai fabriqué ni téléchargé aucun fichier de police binaire (aucune source locale de ces polices n'existe dans ce dépôt — je ne voulais pas introduire un binaire non vérifiable). La mesure appliquée est un **repli logiciel** : `Theme.qml` expose désormais `fontUiStack` / `fontMonoStack` (listes), consommées via `font.families` (et non plus `font.family`) partout dans `Main.qml`, `SpeedometerGauge.qml`, `ThrottleGauge.qml`. Le premier choix reste "Inter"/"JetBrains Mono" ; en repli, une police **de la même famille (proportionnelle vs. monospace)** est choisie en priorité, pour préserver l'absence de "saut" des chiffres même si la police d'intention manque. **Recommandation pour une fidélité pixel-parfaite** : installer réellement "Inter" et "JetBrains Mono" sur l'image Raspberry Pi (ce sont des polices Open Font License, librement redistribuables — copier les `.ttf` dans `/usr/share/fonts/truetype/` de l'image finale). Ceci reste une action d'intégration matérielle, hors du périmètre "code" de cet audit.

---

## 2. Vérification physique

Les constantes du moteur de simulation (`SimulationEngine.js`) ont été confrontées à `Electric vehicle project.md` (étude "cas critique" / "cas croisière") : masse 2200 kg (PTAC), Crr 0,012, Cx 0,70, surface frontale 3,47 m², vitesse critique 13,89 m/s (50 km/h) — **tout est cohérent avec l'étude source**, ce ne sont pas des valeurs inventées pour le prototype.

### Vérification 1 — Accélération 0 → 50 km/h en 15 s ✅ Conforme, aucune correction nécessaire

`MAX_ACCEL_MS2 = MAX_SPEED_MS / FULL_THROTTLE_ACCEL_TIME_S`. À accélérateur maintenu à 100 %, l'accélération est **constante** (indépendante de la vitesse) : l'intégration d'Euler (`_speedMs += accelMs2 * dtSeconds`) est alors **mathématiquement exacte quel que soit le pas de temps**, sans erreur d'approximation cumulée — ce n'est pas juste une approximation qui "passe" à 20 Hz, c'est exact à n'importe quelle fréquence de tick. À t = 15 s, la vitesse atteint donc exactement la cible. Vérifié également que `VehicleDataSimulator.qml` mesure le `dt` réel via `Date.now()` (et non l'intervalle nominal du Timer), ce qui rend le calcul robuste à la gigue d'ordonnancement du Raspberry Pi.

*Note mineure, sans impact* : `MAX_SPEED_MS = 13.89` est un arrondi (valeur exacte : 50/3,6 = 13,888...), mais c'est **l'arrondi documenté dans l'étude source elle-même**, et l'affichage vitesse (`toFixed(0)`) est arrondi à l'entier — l'écart (50,004 km/h au lieu de 50,000) est invisible à l'écran. Je n'ai donc pas touché à cette constante : la « corriger » aurait dévié de la valeur tracée dans l'étude technique pour un gain nul.

### Vérification 2 — Décélération / roue libre ✅ Conforme, robustesse renforcée

La décélération relâchée (`_coastDecelerationMs2`) applique la « road load equation » (roulement + traînée aérodynamique), formule reprise telle quelle de l'étude technique. Calcul vérifié : à 50 km/h, décélération ≈ 0,25 m/s² (0,118 roulement + 0,13 aéro), décroissant avec le carré de la vitesse — un roulage libre réaliste, ni un arrêt instantané ni un ralentissement artificiel. **Aucune correction de fond nécessaire**, mais un vrai risque de robustesse identifié et corrigé :

**Correctif appliqué — plafond sur `dt`.** `update(dtSeconds)` intègre un pas de temps mesuré en temps réel (`Date.now()`), sans aucune limite haute. Si le thread GUI est retardé une fois (montée en charge du Pi, pause GC, fenêtre minimisée/restaurée...), le tick suivant verrait un `dt` anormalement grand, intégré tel quel : la vitesse affichée "téléporterait" au lieu d'évoluer en douceur — exactement la classe de bug attendue par le test de robustesse (Vérification 3). Ajout de `MAX_DT_S = 0.25` (5× l'intervalle nominal de 50 ms, large marge pour la gigue normale) en clamp au tout début de `update()`.

### Vérification 3 — Spam de l'accélérateur ✅ Pas de crash identifié ; deux durcissements de robustesse appliqués

Analyse du chemin de données : `Slider.onValueChanged` → `vehicleData.throttlePercent` → `Sim.setThrottle()` est une écriture de propriété + un appel de fonction O(1) à chaque micro-mouvement du slider — aucun risque de gel ou de fuite mémoire, quelle que soit la fréquence de sollicitation humainement atteignable (souris/tactile). **Le vrai risque n'était pas dans les données, mais dans le rendu** (voir section 3) : `SpeedometerGauge` redessinait un `Canvas` avec un flou logiciel (`ctx.shadowBlur`) sur le thread principal — celui-là même qui doit aussi traiter les événements du slider. Un repaint coûteux exécuté en boucle pendant qu'on sollicite l'UI est précisément ce qui peut produire gel/saccade perçus par l'utilisateur, même sans "crash" au sens strict. Corrigé (section 3).

Par ailleurs, les deux jauges (`SpeedometerGauge`, `ThrottleGauge`) utilisaient un `Behavior` + `NumberAnimation` à durée fixe pour lisser leur valeur : correct pour une transition ponctuelle, mais pas conçu pour être re-ciblé en boucle très rapidement (léger risque d'à-coup si la cible change de sens avant la fin de la transition). Remplacé par `SmoothedAnimation` dans les deux cas (voir section 3) — type prévu justement pour suivre une cible qui bouge en continu ou change de sens brusquement, sans discontinuité de vitesse.

---

## 3. Optimisation du rendu Qt (objectif 60 FPS, cible Raspberry Pi 4 / VideoCore VI)

| Composant | Avant | Après | Justification |
|---|---|---|---|
| `SpeedometerGauge._animatedSpeed` | `Behavior` + `NumberAnimation(duration: 350, OutCubic)` | `Behavior` + `SmoothedAnimation(velocity: 150)` | Source = `vehicleData.speedKmh`, mise à jour en continu à 20 Hz : cas d'usage canonique de `SmoothedAnimation` (suivi en continu d'une valeur "live"), plus robuste qu'une easing à durée fixe re-ciblée sans cesse. |
| `ThrottleGauge._animatedPercent` | `Behavior` + `NumberAnimation(duration: 180, OutCubic)` | `Behavior` + `SmoothedAnimation(velocity: 400)` | Source = slider glissé en direct, y compris inversions rapides (spam) : même raisonnement, comportement plus prévisible sur inversion de sens. |
| `SpeedometerGauge` — halo de l'anneau de progression | `ctx.shadowBlur = 18` dans le `Canvas.onPaint` | Halo simulé par un second trait, plus large et translucide (`globalAlpha = 0.25`), sans `shadowBlur` | `shadowBlur` est un flou logiciel (convolution par pixel), ré-exécuté à **chaque frame** de l'animation (donc potentiellement 60×/s) : c'est l'opération la plus coûteuse du fichier, sur un CPU/GPU d'entrée de gamme (Pi 4). Le remplacement reprend la technique **déjà utilisée dans `ThrottleGauge`** (halo = calque translucide, pas de flou) — même rendu perçu, cohérence entre les deux jauges, coût constant et bien moindre. |

**Vitesses `SmoothedAnimation` choisies** : point de départ raisonnable (plage parcourue en ~0,25–0,33 s à distance maximale, proche du ressenti des durées d'origine), à ajuster librement au goût — ce n'est pas une contrainte physique du cahier des charges, juste un réglage de confort visuel.

**Piste non retenue, par souci de risque** : migrer l'anneau `Canvas` vers `Qt Quick Shapes` (`ShapePath` + `PathAngleArc`), en théorie encore plus efficace (intégré à la scène graphique, accéléré GPU au lieu d'un repaint JS immédiat). Non appliqué ici car cela ajoute une dépendance de module QML supplémentaire (paquet `qml6-module-qtquick-shapes` côté Debian/Raspberry Pi OS) que je ne peux pas vérifier dans cette session sans environnement Linux fonctionnel — un risque de casser la compilation pour un gain marginal par rapport au correctif déjà appliqué (suppression du `shadowBlur`, qui était le vrai poste de coût). À envisager comme amélioration future si le budget de rendu sur le Pi réel s'avère encore serré.

---

## 4. Dockerfile (`dashboard/Dockerfile`)

Image Ubuntu 24.04 : installe la chaîne de compilation + Qt6/QML (paquets `qt6-base-dev`, `qt6-declarative-dev`, `qml6-module-*`), configure et compile le projet (`cmake` + `ninja`), puis exécute un **smoke test** headless (`QT_QPA_PLATFORM=offscreen`, `timeout 3s`) : le binaire doit démarrer et tourner sans planter pendant 3 secondes (code de sortie 124 = succès), sinon le build de l'image échoue. `.dockerignore` associé exclut `build/` et les fichiers spécifiques à l'IDE.

**Limites assumées, écrites dans le Dockerfile** : image x86_64 (pas ARM64 comme le Pi réel), rendu offscreen (pas le vrai GPU VideoCore VI). Cela valide la **portabilité du code** (chemins, CMake, version Qt minimale, absence de dépendance Windows) — pas la performance réelle sur la cible matérielle, qui reste à mesurer sur le Pi physique. Comme indiqué en méthodologie, cette image n'a pas pu être construite dans cette session (pas de moteur Docker/Linux disponible ici) : à valider avec `docker build -t shuttle-dashboard-check dashboard/` avant soumission.

---

## 5. Récapitulatif des fichiers touchés

- **Ajoutés** : `.gitattributes` (racine), `dashboard/Dockerfile`, `dashboard/.dockerignore`, `dashboard/RAPPORT_AUDIT_QA.md` (ce fichier)
- **Modifiés** : `dashboard/main.cpp`, `dashboard/CMakeLists.txt`, `dashboard/SimulationEngine.js`, `dashboard/Theme.qml`, `dashboard/SpeedometerGauge.qml`, `dashboard/ThrottleGauge.qml`, `dashboard/Main.qml`
- **Normalisés en LF sans changement de contenu** : `dashboard/VehicleDataSimulator.qml`, `dashboard/Translations.js`

Aucune fonctionnalité visuelle nouvelle, aucun changement de comportement observable côté utilisateur (même palette, mêmes libellés, même disposition) — uniquement de la portabilité, de la robustesse physique et de la performance de rendu.

## 6. Hors périmètre (rappels, non traités ici)

- `README.md` à la racine est encore un stub (`# Gilles_frontend_challenge`) : le cahier des charges demande un README couvrant lancement, dépendances, architecture et structure des données simulées (livrable obligatoire, non couvert par cette mission de durcissement).
- Police "Inter"/"JetBrains Mono" à installer sur l'image Pi finale pour un rendu pixel-parfait (cf. section 1.5).
- Mesure de FPS réelle sur Raspberry Pi 4 physique (le Dockerfile valide la portabilité du build, pas la performance matérielle réelle).
