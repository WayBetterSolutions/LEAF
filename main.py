import sys
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import qmlRegisterType
from PySide6.QtCore import QUrl
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuickControls2 import QQuickStyle 

from backend.main_manager import MainManager


def main():
    app = QGuiApplication(sys.argv)
    QQuickStyle.setStyle("Basic")
    
    engine = QQmlApplicationEngine()
    main_manager = MainManager()
    
    engine.rootContext().setContextProperty("notesManager", main_manager)
    engine.load(QUrl.fromLocalFile("qml/main.qml"))
    
    if not engine.rootObjects():
        return -1
    
    return app.exec()


if __name__ == "__main__":
    sys.exit(main())