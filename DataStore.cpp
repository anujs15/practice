#include "DataStore.h"

#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QTextStream>
#include <QSettings>

static const char *ORG = "practice";
static const char *APP = "practice";

DataStore::DataStore(QObject *parent) : QObject(parent) {}

QString DataStore::appDataDir() const {
    const QString base = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(base);
    return base;
}

QString DataStore::defaultProfilePath() const {
    return appDataDir() + "/profile.json";
}

QString DataStore::lastProfilePath() const {
    QSettings s(ORG, APP);
    return s.value("lastProfile", defaultProfilePath()).toString();
}

void DataStore::setLastProfilePath(const QString &path) const {
    QSettings s(ORG, APP);
    s.setValue("lastProfile", path);
}

bool DataStore::fileExists(const QString &path) const {
    QFile f(path);
    return f.exists();
}

QString DataStore::loadProfile(const QString &path) const {
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) return QString();
    QTextStream in(&f);
    const QString data = in.readAll();
    f.close();
    return data;
}

bool DataStore::saveProfile(const QString &path, const QString &content) const {
    QFile f(path);
    QDir().mkpath(QFileInfo(path).absolutePath());
    if (!f.open(QIODevice::WriteOnly | QIODevice::Text)) return false;
    QTextStream out(&f);
    out << content;
    f.flush();
    f.close();
    return true;
}
