Profile/Backup

- A DataStore backend persists a JSON profile to the OS app data directory (see QStandardPaths::AppDataLocation).
- On first run, a default profile is created at <AppDataLocation>/profile.json and remembered via QSettings.
- A Profile page (utils/Profile.qml) lets you Save Backup and Restore the last profile.
- Pages can pass their learning arrays to Profile page via the 'learning' property for inclusion in backups.

Notes
- Current implementation preserves existing QML style and minimizes UI intrusion.
- For richer restore, wire Profile.apply() to set page-level attemptedKeys.
