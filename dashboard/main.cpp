#include <QCoreApplication>
#include <QDebug>
#include <QDirIterator>
#include <QFile>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QUrl>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // --- DIAGNOSTIC TEMPORAIRE (a retirer) : contenu reel des ressources Qt.
    QDirIterator dbgIt(QStringLiteral(":/"), QDirIterator::Subdirectories);
    while (dbgIt.hasNext())
        qDebug() << "[QRC]" << dbgIt.next();

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated,
        &app, [](QObject *object, const QUrl &) {
            if (!object)
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);

    // Qt >= 6.5 permettrait engine.loadFromModule("Dashboard", "Main"), plus
    // concis, mais indisponible sur Qt 6.2-6.4 (meme plancher que
    // CMakeLists.txt) -- ex. Qt 6.4.2, version reellement fournie par Ubuntu
    // 24.04/Raspberry Pi OS. On charge donc Main.qml par son URL qrc, mais ce
    // chemin depend d'une politique CMake (QTP0001) qui ne concerne que
    // Qt >= 6.8 : qt_add_qml_module genere ":/qt/qml/<URI>/" sur Qt >= 6.8,
    // ":/qt-project.org/imports/<URI>/" (chemin interne Qt historique) sur
    // Qt < 6.8. Figer l'un des deux a la compilation a casse le smoke test
    // Docker sur Qt 6.4.2 ("No such file or directory") -- on sonde donc les
    // deux chemins connus au demarrage et on charge celui reellement present
    // dans les ressources embarquees, quelle que soit la version Qt 6.x.
    const char *candidates[] = {
        ":/qt/qml/Dashboard/Main.qml",
        ":/qt-project.org/imports/Dashboard/Main.qml",
    };
    QString mainQml = QLatin1String(candidates[0]);
    for (const char *candidate : candidates) {
        if (QFile::exists(QLatin1String(candidate))) {
            mainQml = QLatin1String(candidate);
            break;
        }
    }
    engine.load(QUrl(QLatin1String("qrc") + mainQml));

    return app.exec();
}
