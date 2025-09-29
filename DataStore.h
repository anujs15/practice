#pragma once

#include <QObject>
#include <QString>

class DataStore : public QObject {
    Q_OBJECT
public:
    explicit DataStore(QObject *parent = nullptr);

    Q_INVOKABLE QString appDataDir() const;
    Q_INVOKABLE QString defaultProfilePath() const;
    Q_INVOKABLE QString lastProfilePath() const;
    Q_INVOKABLE void setLastProfilePath(const QString &path) const;
    Q_INVOKABLE bool fileExists(const QString &path) const;
    Q_INVOKABLE QString loadProfile(const QString &path) const;
    Q_INVOKABLE bool saveProfile(const QString &path, const QString &content) const;
    Q_INVOKABLE bool removeProfile(const QString &path) const;
    Q_INVOKABLE bool copyProfile(const QString &srcPath, const QString &dstPath) const;
    Q_INVOKABLE bool saveEncryptedProfile(const QString &path, const QString &content, const QString &password) const;
    Q_INVOKABLE QString loadEncryptedProfile(const QString &path, const QString &password) const;
    Q_INVOKABLE bool isEncryptedProfile(const QString &path) const;
    Q_INVOKABLE QString signedInAlias() const;
    Q_INVOKABLE void setSignedInAlias(const QString &alias) const;
    Q_INVOKABLE void appendLog(const QString &message) const;
    Q_INVOKABLE bool exportLogs(const QString &dstPath) const;
    Q_INVOKABLE bool clearLogs() const;
};
