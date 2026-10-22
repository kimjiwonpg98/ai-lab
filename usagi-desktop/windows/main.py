"""Windows desktop companion. All media stays local."""
import ctypes
import math
import sys
import time
from pathlib import Path
from PySide6.QtCore import Qt, QTimer, QSettings, QPoint
from PySide6.QtGui import QAction, QActionGroup, QCursor, QIcon, QPainter, QPixmap
from PySide6.QtWidgets import QApplication, QWidget, QMenu, QSystemTrayIcon

ASSETS = Path(getattr(sys, '_MEIPASS', Path(__file__).resolve().parents[1])) / 'Assets'
STYLES = [
    ('우사기춤', 'DanceFrames'), ('치어리더 우사기', None),
    ('모찌 먹는 랏코', 'RakkoFrames'), ('울먹이는 치이카와', 'ChiikawaCryFrames'),
    ('간식 먹는 치이카와', 'ChiikawaSnackFrames'), ('클로버 치이카와', 'ChiikawaCloverFrames'),
    ('춤추는 치이카와', 'ChiikawaDanceFrames'),
]

class Pet(QWidget):
    def __init__(self):
        super().__init__(None, Qt.WindowType.FramelessWindowHint | Qt.WindowType.WindowStaysOnTopHint | Qt.WindowType.Tool)
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)
        self.settings = QSettings('Meonjakgwi', 'Friends')
        self.style = max(0, min(len(STYLES)-1, self.settings.value('style', 0, int)))
        self.size = self.settings.value('size', 210, int)
        if self.size not in (150, 210, 290): self.size = 210
        self.follow = self.settings.value('follow', False, bool)
        self.speed = self.settings.value('speed', 1.0, float)
        self.playing = True
        self.elapsed = 0.0
        self.last_tick = time.monotonic()
        self.press = None
        self.dragged = False
        self.menu_open = False
        self.resize(self.size, round(self.size * 1.2))
        self.load_frames()
        self.reset_position(False)
        position = self.settings.value('position')
        if isinstance(position, QPoint) and any(s.availableGeometry().intersects(self.rect().translated(position)) for s in QApplication.screens()):
            self.move(position)
        self.menu = QMenu()
        self.build_menu()
        self.tray = QSystemTrayIcon(QIcon(str(ASSETS / 'app-icon.png')), self)
        self.tray.setToolTip('먼작귀 칭구들')
        self.tray.setContextMenu(self.menu)
        self.tray.activated.connect(self.tray_clicked)
        self.tray.show()
        self.timer = QTimer(self)
        self.timer.timeout.connect(self.tick)
        self.timer.start(16)

    def load_frames(self):
        folder = STYLES[self.style][1]
        paths = sorted((ASSETS / folder).glob('frame-*.png')) if folder else [ASSETS / 'usagi-dance.png']
        self.frames = [QPixmap(str(p)).scaled(self.width(), self.height()-20, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation) for p in paths]
        if not self.frames or any(p.isNull() for p in self.frames):
            raise RuntimeError('캐릭터 이미지가 없습니다.')
        self.idle = QPixmap(str(ASSETS / 'usagi-idle.png')).scaled(self.width(), self.height()-20, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation)

    def build_menu(self):
        self.menu.addAction('먼작귀 칭구들').setEnabled(False)
        characters = self.menu.addMenu('캐릭터 선택')
        group = QActionGroup(self.menu)
        for i, (name, _) in enumerate(STYLES):
            action = characters.addAction(name)
            action.setCheckable(True)
            action.setChecked(i == self.style)
            group.addAction(action)
            action.triggered.connect(lambda checked=False, index=i: self.select_style(index))
        self.pause_action = self.menu.addAction('일시 정지', self.toggle_play)
        follow = self.menu.addAction('마우스 따라가기')
        follow.setCheckable(True)
        follow.setChecked(self.follow)
        follow.toggled.connect(self.set_follow)
        self.follow_action = follow
        sizes = self.menu.addMenu('크기')
        for label, size in [('작게', 150), ('보통', 210), ('크게', 290)]:
            sizes.addAction(label, lambda n=size: self.set_size(n))
        speeds = self.menu.addMenu('속도')
        for label, speed in [('느리게', .65), ('보통', 1.0), ('빠르게', 1.45)]:
            speeds.addAction(label, lambda n=speed: self.set_speed(n))
        self.visibility_action = self.menu.addAction('숨기기', self.toggle_visible)
        self.menu.addAction('화면 구석으로 데려오기', lambda: self.reset_position())
        self.menu.addSeparator()
        self.menu.addAction('종료', QApplication.instance().quit)
        self.menu.aboutToShow.connect(lambda: setattr(self, 'menu_open', True))
        self.menu.aboutToHide.connect(lambda: setattr(self, 'menu_open', False))

    def select_style(self, index):
        self.style = index
        self.elapsed = 0
        self.load_frames()
        self.settings.setValue('style', index)
        self.update()

    def set_size(self, size):
        self.size = size
        self.resize(size, round(size*1.2))
        self.load_frames()
        self.settings.setValue('size', size)
        self.update()

    def set_speed(self, speed):
        self.speed = speed
        self.settings.setValue('speed', speed)

    def set_follow(self, enabled):
        self.follow = enabled
        self.settings.setValue('follow', enabled)

    def toggle_play(self):
        self.playing = not self.playing
        self.pause_action.setText('일시 정지' if self.playing else '다시 재생')
        self.update()

    def toggle_visible(self):
        self.setVisible(not self.isVisible())
        self.visibility_action.setText('숨기기' if self.isVisible() else '다시 표시')

    def tray_clicked(self, reason):
        if reason == QSystemTrayIcon.ActivationReason.DoubleClick:
            self.toggle_visible()

    def reset_position(self, disable_follow=True):
        if disable_follow:
            self.follow_action.setChecked(False)
        rect = QApplication.primaryScreen().availableGeometry()
        self.move(rect.right()-self.width()-24, rect.bottom()-self.height()-24)

    @staticmethod
    def mouse_is_down():
        if sys.platform == "win32":
            return any(ctypes.windll.user32.GetAsyncKeyState(key) & 0x8000 for key in (1, 2, 4))
        return QApplication.mouseButtons() != Qt.MouseButton.NoButton

    def tick(self):
        now = time.monotonic()
        dt = min(now-self.last_tick, .1)
        self.last_tick = now
        if not self.isVisible(): return
        if self.playing and self.press is None:
            self.elapsed += dt*self.speed
            self.update()
        cursor = QCursor.pos()
        if self.follow and self.press is None and not self.menu_open and not self.mouse_is_down() and not self.geometry().contains(cursor):
            screen = QApplication.screenAt(cursor) or QApplication.primaryScreen()
            r = screen.availableGeometry()
            x = cursor.x()+24
            if x+self.width() > r.right(): x = cursor.x()-self.width()-24
            x = max(r.left(), min(x, r.right()-self.width()+1))
            y = max(r.top(), min(cursor.y()-self.height()//2, r.bottom()-self.height()+1))
            f = 1-math.exp(-7*dt)
            self.move(round(self.x()+(x-self.x())*f), round(self.y()+(y-self.y())*f))

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.SmoothPixmapTransform)
        pixmap = self.frames[int(self.elapsed*30) % len(self.frames)]
        offset = 0
        if self.style == 1:
            if not self.playing: pixmap = self.idle
            else: offset = -abs(math.sin(self.elapsed*7))*12
        painter.drawPixmap((self.width()-pixmap.width())//2, round(self.height()-pixmap.height()-4+offset), pixmap)

    def mousePressEvent(self, event):
        if event.button() == Qt.MouseButton.LeftButton:
            self.press = event.globalPosition().toPoint()
            self.origin = self.pos()
            self.dragged = False

    def mouseMoveEvent(self, event):
        if self.press is not None:
            delta = event.globalPosition().toPoint()-self.press
            if delta.manhattanLength() > QApplication.startDragDistance(): self.dragged = True
            if self.dragged: self.move(self.origin+delta)

    def mouseReleaseEvent(self, event):
        if event.button() == Qt.MouseButton.LeftButton and self.press is not None:
            if not self.dragged: self.toggle_play()
            self.press = None
            self.settings.setValue('position', self.pos())

    def contextMenuEvent(self, event):
        self.menu.popup(event.globalPos())

    def save(self):
        self.settings.setValue('position', self.pos())
        self.settings.sync()
        self.tray.hide()

if __name__ == '__main__':
    app = QApplication(sys.argv)
    app.setQuitOnLastWindowClosed(False)
    app.setApplicationName('먼작귀 칭구들')
    pet = Pet()
    app.aboutToQuit.connect(pet.save)
    pet.show()
    if '--smoke-test' in sys.argv:
        for i in range(len(STYLES)):
            pet.select_style(i)
            pet.grab()
        QTimer.singleShot(500, app.quit)
    sys.exit(app.exec())
