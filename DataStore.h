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
};
