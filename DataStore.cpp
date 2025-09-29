#include "DataStore.h"

#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QTextStream>
#include <QSettings>
#include <QCryptographicHash>
#include <QFileInfo>
#include <QDateTime>

static const char *ORG = "practice";
static const char *APP = "practice";

DataStore::DataStore(QObject *parent) : QObject(parent) {}

QString DataStore::appDataDir() const {
    const QString base = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (!QDir().mkpath(base)) {
        qDebug() << "Warning: failed to mkpath for appDataDir:" << base;
    }
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

QString DataStore::signedInAlias() const {
    QSettings s(ORG, APP);
    return s.value("signedInAlias", "").toString();
}

void DataStore::setSignedInAlias(const QString &alias) const {
    QSettings s(ORG, APP);
    s.setValue("signedInAlias", alias);
}

bool DataStore::fileExists(const QString &path) const {
    QFile f(path);
    return f.exists();
}

QString DataStore::loadProfile(const QString &path) const {
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qDebug() << "loadProfile: failed to open file for reading:" << path << f.errorString();
        return QString();
    }
    QTextStream in(&f);
    const QString data = in.readAll();
    f.close();
    return data;
}

bool DataStore::saveProfile(const QString &path, const QString &content) const {
    QFile f(path);
    QString dir = QFileInfo(path).absolutePath();
    if (!QDir().mkpath(dir)) {
        qDebug() << "saveProfile: failed to create directory:" << dir;
        return false;
    }
    if (!f.open(QIODevice::WriteOnly | QIODevice::Text)) {
        qDebug() << "saveProfile: failed to open file for writing:" << path << f.errorString();
        return false;
    }
    QTextStream out(&f);
    out << content;
    f.flush();
    f.close();
    return true;
}

bool DataStore::copyProfile(const QString &srcPath, const QString &dstPath) const {
    QFile src(srcPath);
    if (!src.exists()) return false;
    QString dstDir = QFileInfo(dstPath).absolutePath();
    if (!QDir().mkpath(dstDir)) {
        qDebug() << "copyProfile: failed to create destination directory:" << dstDir;
        return false;
    }
    // If QFile::copy fails (e.g. dest exists), fall back to manual copy
    if (QFile::copy(srcPath, dstPath)) return true;
    QFile dst(dstPath);
    if (!src.open(QIODevice::ReadOnly)) {
        qDebug() << "copyProfile: failed to open source for reading:" << srcPath << src.errorString();
        return false;
    }
    if (!dst.open(QIODevice::WriteOnly)) {
        qDebug() << "copyProfile: failed to open destination for writing:" << dstPath << dst.errorString();
        src.close();
        return false;
    }
    QByteArray data = src.readAll();
    dst.write(data);
    dst.flush();
    dst.close();
    src.close();
    return true;
}

static const QByteArray ENC_HEADER = QByteArray("ENCRYPTEDv1\n");
static const int ENC_TAG_SIZE = 32; // SHA-256 tag size

bool DataStore::saveEncryptedProfile(const QString &path, const QString &content, const QString &password) const {
    if (password.isEmpty()) return false; // require a password
    QByteArray key = QCryptographicHash::hash(password.toUtf8(), QCryptographicHash::Sha256);
    QByteArray data = content.toUtf8();
    // authentication tag over plaintext + key
    QByteArray tag = QCryptographicHash::hash(data + key, QCryptographicHash::Sha256);

    QByteArray enc;
    enc.reserve(data.size());
    for (int i = 0; i < data.size(); ++i) {
        enc.append(data[i] ^ key.at(i % key.size()));
    }

    QByteArray out;
    out.reserve(ENC_HEADER.size() + tag.size() + enc.size());
    out.append(ENC_HEADER);
    out.append(tag);
    out.append(enc);

    QFile f(path);
    QString dir = QFileInfo(path).absolutePath();
    if (!QDir().mkpath(dir)) {
        qDebug() << "saveEncryptedProfile: failed to create directory:" << dir;
        return false;
    }
    if (!f.open(QIODevice::WriteOnly)) {
        qDebug() << "saveEncryptedProfile: failed to open file for writing:" << path << f.errorString();
        return false;
    }
    qint64 written = f.write(out);
    f.flush();
    f.close();
    if (written != out.size()) {
        qDebug() << "saveEncryptedProfile: incomplete write to" << path << "wrote" << written << "expected" << out.size();
        return false;
    }
    return true;
}

QString DataStore::loadEncryptedProfile(const QString &path, const QString &password) const {
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) {
        qDebug() << "loadEncryptedProfile: failed to open file:" << path << f.errorString();
        return QString();
    }
    QByteArray all = f.readAll();
    f.close();
    if (!all.startsWith(ENC_HEADER)) {
        qDebug() << "loadEncryptedProfile: file does not have expected header:" << path;
        return QString();
    }
    if (password.isEmpty()) {
        qDebug() << "loadEncryptedProfile: empty password provided for file:" << path;
        return QString();
    }
    if (all.size() < ENC_HEADER.size() + ENC_TAG_SIZE) {
        qDebug() << "loadEncryptedProfile: file too small or corrupted:" << path;
        return QString();
    }
    QByteArray key = QCryptographicHash::hash(password.toUtf8(), QCryptographicHash::Sha256);
    QByteArray tag = all.mid(ENC_HEADER.size(), ENC_TAG_SIZE);
    QByteArray enc = all.mid(ENC_HEADER.size() + ENC_TAG_SIZE);
    QByteArray out;
    out.reserve(enc.size());
    for (int i = 0; i < enc.size(); ++i) {
        out.append(enc[i] ^ key.at(i % key.size()));
    }
    QByteArray check = QCryptographicHash::hash(out + key, QCryptographicHash::Sha256);
    if (check != tag) {
        qDebug() << "loadEncryptedProfile: authentication failed (wrong password or corrupted file):" << path;
        return QString();
    }
    return QString::fromUtf8(out);
}

bool DataStore::isEncryptedProfile(const QString &path) const {
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) {
        qDebug() << "isEncryptedProfile: failed to open file:" << path << f.errorString();
        return false;
    }
    QByteArray head = f.read(ENC_HEADER.size());
    f.close();
    return head == ENC_HEADER;
}

bool DataStore::removeProfile(const QString &path) const {
    QFile f(path);
    if (f.exists()) {
        return f.remove();
    }
    return false;
}

static const qint64 MAX_LOG_SIZE = 1024 * 1024; // 1 MB
static const int MAX_ROTATIONS = 5;

void DataStore::appendLog(const QString &message) const {
    QString dir = appDataDir() + "/logs";
    if (!QDir().mkpath(dir)) {
        qDebug() << "appendLog: failed to create logs directory:" << dir;
    }
    QString path = dir + "/app.log";

    // Rotate if file exceeds limit
    QFileInfo fi(path);
    if (fi.exists() && fi.size() > MAX_LOG_SIZE) {
        // remove oldest
        QString oldest = path + "." + QString::number(MAX_ROTATIONS);
        if (QFile::exists(oldest)) QFile::remove(oldest);
        // shift others up
        for (int i = MAX_ROTATIONS - 1; i >= 1; --i) {
            QString from = path + "." + QString::number(i);
            QString to = path + "." + QString::number(i + 1);
            if (QFile::exists(from)) {
                QFile::rename(from, to);
            }
        }
        // rotate current
        QString rotated = path + ".1";
        QFile::rename(path, rotated);
    }

    QFile f(path);
    if (!f.open(QIODevice::Append | QIODevice::Text)) {
        qDebug() << "Failed to open log file:" << path;
        qDebug() << message;
        return;
    }
    QTextStream out(&f);
    QString entry = QDateTime::currentDateTimeUtc().toString(Qt::ISODate) + " " + message + "\n";
    out << entry;
    out.flush();
    f.close();
    qDebug() << entry;
}

bool DataStore::exportLogs(const QString &dstPath) const {
    QString dir = appDataDir() + "/logs";
    QString base = dir + "/app.log";
    QFile dst(dstPath);
    QDir().mkpath(QFileInfo(dstPath).absolutePath());
    if (!dst.open(QIODevice::WriteOnly | QIODevice::Text)) return false;
    QTextStream out(&dst);
    out << "==== Exported logs: " << QDateTime::currentDateTimeUtc().toString(Qt::ISODate) << " ====\n";
    // write rotated logs oldest first
    for (int i = MAX_ROTATIONS; i >= 1; --i) {
        QString p = base + "." + QString::number(i);
        QFile src(p);
        if (src.exists() && src.open(QIODevice::ReadOnly)) {
            out << "\n---- app.log." << i << " ----\n";
            out << src.readAll();
            src.close();
        }
    }
    // current log
    QFile cur(base);
    if (cur.exists() && cur.open(QIODevice::ReadOnly)) {
        out << "\n---- app.log ----\n";
        out << cur.readAll();
        cur.close();
    }
    out.flush();
    dst.close();
    qDebug() << "Exported logs to" << dstPath;
    return true;
}

bool DataStore::clearLogs() const {
    QString dir = appDataDir() + "/logs";
    QString base = dir + "/app.log";
    bool ok = true;
    // remove rotated
    for (int i = 1; i <= MAX_ROTATIONS; ++i) {
        QString p = base + "." + QString::number(i);
        if (QFile::exists(p)) ok = QFile::remove(p) && ok;
    }
    // remove current
    QString cur = base;
    if (QFile::exists(cur)) ok = QFile::remove(cur) && ok;
    // recreate empty
    QFile f(cur);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Text)) return false;
    f.close();
    qDebug() << "Cleared logs in" << dir;
    return ok;
}
