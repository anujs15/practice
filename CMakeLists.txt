cmake_minimum_required(VERSION 3.16)

project(practice VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTORCC ON)

# Enable generation of QML type information for editor tooling and QML import resolution
# This helps tools (and some IDEs) resolve QML imports like QtQuick.Controls and QtQuick.Layouts.
set(QT_QML_GENERATE_QMLLS_INI ON CACHE BOOL "Generate qmltypes/qmlls ini files for QML modules")

# Find Qt modules required by the application. Include QtQuick and Qt Quick Controls 2
find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(apppractice
    main.cpp
    DataStore.cpp
)

# List QML and JS files passed to the QML module in a clean way
qt_add_qml_module(apppractice
    URI practice
    VERSION 1.0
    QML_FILES
        Main.qml
        utils/Login.qml
        utils/ShortcutView.qml
        utils/CategoryView.qml
        utils/AppsView.qml
        utils/Testground.qml
        utils/Result.qml
        utils/KeyAnalysis.qml
        utils/Profile.qml
        profile.js
        keydata.js
        learningState.js
        vstestdata.js
        Logging.js
    RESOURCES
        Resource.qrc
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(apppractice PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.apppractice
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(apppractice
    PRIVATE Qt6::Quick Qt6::QuickControls2
)

include(GNUInstallDirs)
install(TARGETS apppractice
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
