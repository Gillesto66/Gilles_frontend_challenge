#include <QCoreApplication>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QUrl>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated,
        &app, [](QObject *object, const QUrl &) {
            if (!object)
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);

    // Qt >= 6.5 permettrait engine.loadFromModule("Dashboard", "Main"), plus
    // concis. On utilise ici load(QUrl) + objectCreated, disponible des
    // Qt 6.2 (meme plancher que qt_add_qml_module dans CMakeLists.txt) :
    // cela evite un echec de compilation si le Raspberry Pi fournit un Qt6
    // plus ancien que 6.5 (les depots Debian/Raspberry Pi OS sont souvent en
    // retrait par rapport a la derniere version Qt disponible). L'URL suit
    // le schema genere par qt_add_qml_module : qrc:/qt/qml/<URI>/<Fichier>.
    engine.load(QUrl(QStringLiteral("qrc:/qt/qml/Dashboard/Main.qml")));

    return app.exec();
}
