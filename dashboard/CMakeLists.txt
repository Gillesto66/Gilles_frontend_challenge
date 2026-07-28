cmake_minimum_required(VERSION 3.16)
project(ShuttleDashboard LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Version explicite : le projet utilise deja l'API CMake moderne de Qt
# (qt_add_qml_module, qt_standard_project_setup), qui requiert Qt >= 6.2.
# La rendre explicite ici transforme un Qt trop ancien sur la cible Linux
# (paquets de distribution en retrait par rapport a la derniere version Qt)
# en une erreur de configuration CMake claire et immediate, plutot qu'en
# echec de compilation confus plus loin dans le build.
find_package(Qt6 6.2 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2)

qt_standard_project_setup()

qt_add_executable(ShuttleDashboard main.cpp)

qt_add_qml_module(ShuttleDashboard
    URI Dashboard
    VERSION 1.0
    QML_FILES
        Main.qml
        VehicleDataSimulator.qml
        SimulationEngine.js
        SpeedometerGauge.qml
        ThrottleGauge.qml
        Translations.js
        Theme.qml
)

target_link_libraries(ShuttleDashboard PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
)
