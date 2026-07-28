.pragma library

// =============================================================================
// SimulationEngine.js
// -----------------------------------------------------------------------------
// Coeur physique + etat du vehicule simule ("faux bus CAN").
//
// Ce fichier ne connait AUCUN type QML (pas de Timer, pas d'Item, pas de
// binding). C'est un module JS pur : etat + fonctions. C'est volontaire et
// c'est le point cle de la separation des responsabilites demandee :
//
//   - Le jour ou le vrai bus CAN (SocketCAN, cf. firmware pedale) sera
//     disponible, CE fichier est remplace par un module qui lit des trames
//     CAN et les convertit dans les memes unites (km/h, km). Rien d'autre
//     ne bouge : VehicleDataSimulator.qml expose la meme interface, et
//     Main.qml ne sait meme pas que la source a change.
//   - Etant du JS pur sans dependance QML, il est testable unitairement
//     tel quel (node, ou un runner JS quelconque).
//
// "pragma library" : ce module est charge une seule fois par le moteur QML
// et partage par tous les fichiers qui l'importent (semantique singleton).
// C'est voulu ici puisqu'il n'existe qu'un seul vehicule/tableau de bord ;
// si un jour plusieurs instances de tableau de bord devaient exister sans
// partager l'etat, il faudrait retirer ce pragma et instancier l'etat
// autrement (closure/factory).
// =============================================================================

// ---- Constantes vehicule ---------------------------------------------------
// Reprises de l'etude technique du vehicule (voir "Electric vehicle
// project.md", cas critique / cas croisiere) pour que la simulation reste
// coherente avec le dimensionnement reel du bus.
var MASS_KG          = 2200;   // PTAC retenu (cas le plus defavorable)
var ROLLING_RESIST_C = 0.012;  // Crr, pneu route sur bitume
var DRAG_COEFF       = 0.70;   // Cx, carrosserie ouverte type navette
var FRONTAL_AREA_M2  = 3.47;   // A, surface frontale
var AIR_DENSITY      = 1.225;  // rho, kg/m3
var GRAVITY          = 9.81;   // g, m/s2

var MAX_SPEED_MS = 13.89; // 50 km/h, vitesse critique du cahier des charges
var FULL_THROTTLE_ACCEL_TIME_S = 15; // 0 -> 50 km/h en 15s a 100% acc.

// Acceleration delivree a 100% d'accelerateur, calibree pour atteindre
// exactement MAX_SPEED_MS au bout de FULL_THROTTLE_ACCEL_TIME_S secondes
// si l'accelerateur reste a fond tout du long (integration a derivee
// constante => pas d'erreur d'approximation, quel que soit le pas de temps).
var MAX_ACCEL_MS2 = MAX_SPEED_MS / FULL_THROTTLE_ACCEL_TIME_S; // ~0.926 m/s2

// Pas de temps maximal accepte par un seul appel a update(), en secondes.
// Protection contre les "teleportations" : dtSeconds est mesure a partir
// d'un vrai timestamp d'horloge (Date.now(), cf. VehicleDataSimulator.qml),
// donc si le thread GUI est retarde une fois (demarrage/JIT, GC, pic de
// charge sur le Raspberry Pi, fenetre reduite puis restauree...), le
// prochain tick verrait un dt anormalement grand. Sans plafond, ce dt
// serait integre tel quel et ferait sauter la vitesse affichee au lieu de
// la faire evoluer en douceur -- exactement le genre de saccade que
// l'interface doit eviter (cf. test de robustesse "spam" de l'accelerateur).
// 250 ms = 5x l'intervalle nominal du Timer (50 ms) : large marge pour la
// gigue normale, sans permettre de rattraper plusieurs secondes d'un coup.
var MAX_DT_S = 0.25;

// ---- Etat interne (= etat courant du "vehicule") ---------------------------
var _throttlePercent = 0; // 0-100, pilote par la pedale/jauge UI
var _speedMs = 0;
var _odometerM = 0;

// Recoit la position pedale (0-100). Sur le vehicule reel, cette valeur
// arriverait par une trame CAN emise par le firmware de la pedale
// (cf. Groupe III) au lieu d'un slider UI.
function setThrottle(percent) {
    if (percent < 0) percent = 0;
    if (percent > 100) percent = 100;
    _throttlePercent = percent;
}

// Deceleration "roue libre" (accelerateur relache) : uniquement les
// resistances physiques naturelles, pas de freinage actif.
//   - resistance au roulement : quasi constante, independante de v
//   - trainee aerodynamique : croit avec le carre de la vitesse
// Formules issues du "road load equation" (F = Crr*m*g + 0.5*rho*Cx*A*v^2),
// ramenees en deceleration (division par la masse).
function _coastDecelerationMs2(speedMs) {
    var rolling = ROLLING_RESIST_C * GRAVITY;
    var aero = (0.5 * AIR_DENSITY * DRAG_COEFF * FRONTAL_AREA_M2 * speedMs * speedMs) / MASS_KG;
    return rolling + aero; // magnitude positive, s'oppose au mouvement
}

// Avance la simulation de dtSeconds. A appeler a chaque tick de l'horloge
// (Timer) portee par le composant "backend" (VehicleDataSimulator.qml).
function update(dtSeconds) {
    if (!(dtSeconds > 0)) return;
    if (dtSeconds > MAX_DT_S) dtSeconds = MAX_DT_S;

    var accelMs2;
    if (_throttlePercent > 0) {
        // Phase tractee : acceleration proportionnelle a la pedale.
        accelMs2 = (_throttlePercent / 100) * MAX_ACCEL_MS2;
    } else {
        // Pedale relachee : roue libre, deceleration physique realiste.
        accelMs2 = -_coastDecelerationMs2(_speedMs);
    }

    _speedMs += accelMs2 * dtSeconds;

    if (_speedMs < 0) _speedMs = 0;
    if (_speedMs > MAX_SPEED_MS) _speedMs = MAX_SPEED_MS;

    // Odometre cumulatif : distance = vitesse * temps, jamais remis a zero.
    _odometerM += _speedMs * dtSeconds;
}

function speedKmh() {
    return _speedMs * 3.6;
}

function odometerKm() {
    return _odometerM / 1000;
}

// Utilitaire de test/debug uniquement (non utilise par le scaffolding).
function reset() {
    _throttlePercent = 0;
    _speedMs = 0;
    _odometerM = 0;
}
