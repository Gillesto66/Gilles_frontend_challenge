# syntax=docker/dockerfile:1

# =============================================================================
# Dockerfile
# -----------------------------------------------------------------------------
# Objectif : verifier que ShuttleDashboard configure, compile ET demarre sur
# un systeme de fichiers Linux, independamment de toute machine de
# developpement Windows (chemins relatifs, forward slashes, pas de
# dependance a un outil Windows-only).
#
# Base Ubuntu LTS choisie arbitrairement ; Debian "bookworm-slim" convient
# tout aussi bien (memes paquets Qt6, noms identiques ou tres proches).
#
# Limite assumee : ceci tourne en x86_64 (ou l'archi de la machine qui build
# l'image), pas en ARM64 comme un vrai Raspberry Pi 4, et sans GPU reel
# (rendu "offscreen"). Ca valide la portabilite du CODE (CMakeLists, version
# Qt minimale, chemins, absence de dependance Windows) -- pas les
# performances materielles reelles du Pi, qui restent a mesurer sur la
# cible physique.
# =============================================================================
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# ---- Chaine de compilation + Qt6/QML --------------------------------------
# Les paquets "-dev" fournissent les en-tetes necessaires a la compilation ;
# les paquets "qml6-module-*" fournissent les plugins QML necessaires au
# DEMARRAGE (QQmlApplicationEngine doit pouvoir resoudre "import QtQuick",
# "import QtQuick.Controls", "import QtQuick.Window" a l'execution). Les
# noms exacts de paquets peuvent varier legerement selon la version
# Ubuntu/Debian : en cas d'echec d'installation, chercher le paquet
# equivalent avec `apt-cache search qml6-module` / `apt-cache search qt6`
# a l'interieur du conteneur.
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        ninja-build \
        pkg-config \
        qt6-base-dev \
        qt6-declarative-dev \
        qml6-module-qtquick \
        qml6-module-qtquick-controls \
        qml6-module-qtquick-templates \
        qml6-module-qtquick-window \
        qml6-module-qtqml-workerscript \
        libgl1-mesa-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

# Ne copie que le projet Qt/QML (voir .dockerignore) : uniquement des
# chemins relatifs dans l'image, aucune arborescence Windows.
COPY . .

# ---- Configuration + compilation ------------------------------------------
RUN cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build

# ---- Verification "ca demarre" (smoke test, sans serveur d'affichage) -----
# QT_QPA_PLATFORM=offscreen : rend l'application sans ecran (obligatoire en
# conteneur, aucun serveur graphique disponible). "timeout" laisse tourner
# l'appli 3 secondes puis l'arrete : code de sortie 124 = timeout atteint =
# l'appli tournait toujours = succes. Tout autre code (crash, erreur QML au
# chargement...) fait echouer le build de l'image, donc echouer la
# verification.
ENV QT_QPA_PLATFORM=offscreen
RUN set -e; \
    timeout 3 ./build/ShuttleDashboard; code=$?; \
    if [ "$code" -eq 124 ] || [ "$code" -eq 0 ]; then \
        echo "Smoke test OK (code $code)"; \
    else \
        echo "Smoke test ECHEC (code $code)"; \
        exit 1; \
    fi

CMD ["./build/ShuttleDashboard"]
