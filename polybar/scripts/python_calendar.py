#!/usr/bin/env python3
from PySide6.QtWidgets import (QApplication, QMainWindow, QCalendarWidget,
                             QVBoxLayout, QHBoxLayout, QWidget, QPushButton,
                             QLabel, QFrame, QToolTip)
from PySide6.QtCore import Qt, QDate, QTime, QTimer
from PySide6.QtGui import QFont, QTextCharFormat, QColor
import sys
import os
import fcntl
from tempfile import gettempdir
import signal
import requests
from datetime import datetime

def ensure_single_instance():
    """Ensure only one instance of the calendar is running"""
    lock_file = os.path.join(gettempdir(), 'python_calendar.lock')
    try:
        fp = open(lock_file, 'w')
        fcntl.lockf(fp, fcntl.LOCK_EX | fcntl.LOCK_NB)
        return fp
    except IOError:
        sys.exit(0)

def cleanup_handler(signum, frame):
    """Handle cleanup when terminating"""
    sys.exit(0)

class DarkCalendar(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Calendar")
        
        self.holidays = {}
        self.load_country_holidays()
        
        # Colors
        self.colors = {
            'background': '#000000',        # Black background
            'surface': '#ffffff',           # White surface
            'header': '#3498db',           # Blue header
            'surface_alt': '#2c3e50',      # Dark highlight
            'primary': '#3498db',          # Main blue
            'text': '#000000',             # Black text
            'text_dim': '#666666',         # Dimmed text
            'weekend': '#ff0000',          # Red for weekends
            'holiday': '#26a269',          # Green for holidays
            'today_bg': '#3498db',         # Blue background for today
            'today_fg': '#ffffff',         # White text for today
            'selected': '#2c3e50'          # Dark blue for selected
        }
        
        self.setStyleSheet(f"""
            QMainWindow {{
                background-color: {self.colors['background']};
            }}
            QFrame#mainFrame {{
                background-color: {self.colors['surface']};
                border: none;
            }}
            QCalendarWidget {{
                background-color: {self.colors['surface']};
                color: {self.colors['text']};
                selection-background-color: {self.colors['selected']};
                selection-color: {self.colors['surface']};
            }}
            QCalendarWidget QToolButton {{
                color: {self.colors['text']};
                background-color: transparent;
                border: none;
                border-radius: 4px;
                padding: 10px;
                font-size: 14px;
                font-weight: bold;
                margin: 2px;
            }}
            QCalendarWidget QToolButton:hover {{
                background-color: {self.colors['surface_alt']};
            }}
            QCalendarWidget QMenu {{
                background-color: {self.colors['surface']};
                color: {self.colors['text']};
                border: 1px solid {self.colors['surface_alt']};
                padding: 5px;
                border-radius: 4px;
            }}
            QCalendarWidget QSpinBox {{
                background-color: {self.colors['surface']};
                color: {self.colors['text']};
                border: 1px solid {self.colors['surface_alt']};
                padding: 5px;
            }}
            QCalendarWidget QWidget {{ 
                alternate-background-color: {self.colors['surface']};
            }}
            QCalendarWidget QWidget#qt_calendar_navigationbar {{
                background-color: {self.colors['header']};
                padding: 4px;
            }}
            QPushButton {{
                background-color: {self.colors['surface_alt']};
                color: {self.colors['text']};
                border: none;
                border-radius: 8px;
                padding: 10px 20px;
                font-size: 13px;
                font-weight: bold;
                margin: 5px;
            }}
            QPushButton:hover {{
                background-color: {self.colors['primary']};
                color: {self.colors['surface']};
            }}
            QLabel {{
                color: {self.colors['text']};
                font-size: 16px;
                font-weight: bold;
            }}
        """)
        
        # Create main frame
        main_frame = QFrame(self)
        main_frame.setObjectName("mainFrame")
        self.setCentralWidget(main_frame)
        
        # Layout
        layout = QVBoxLayout(main_frame)
        layout.setSpacing(10)
        layout.setContentsMargins(20, 20, 20, 20)
        
        # Header with current date and time
        self.header_label = QLabel()
        self.header_label.setAlignment(Qt.AlignCenter)
        header_font = QFont()
        header_font.setPointSize(16)
        header_font.setBold(True)
        self.header_label.setFont(header_font)
        self.update_header()
        
        # Calendar widget setup
        self.calendar = QCalendarWidget()
        self.calendar.setGridVisible(False)
        self.calendar.setVerticalHeaderFormat(QCalendarWidget.NoVerticalHeader)
        self.calendar.setHorizontalHeaderFormat(QCalendarWidget.SingleLetterDayNames)
        self.calendar.setNavigationBarVisible(True)
        self.calendar.clicked.connect(self.show_date_info)
        
        # Setup date formats
        self.setup_date_formats()
        
        # Navigation
        nav_layout = QHBoxLayout()
        today_btn = QPushButton("Today")
        today_btn.clicked.connect(self.go_to_today)
        today_btn.setCursor(Qt.PointingHandCursor)
        
        # Event label for showing selected date info
        self.event_label = QLabel()
        self.event_label.setAlignment(Qt.AlignCenter)
        self.event_label.setStyleSheet(f"color: {self.colors['text_dim']}; font-size: 12px;")
        
        # Add widgets to layout
        layout.addWidget(self.header_label)
        layout.addWidget(self.calendar)
        layout.addWidget(self.event_label)
        nav_layout.addStretch()
        nav_layout.addWidget(today_btn)
        nav_layout.addStretch()
        layout.addLayout(nav_layout)
        
        # Timer for updating header
        self.timer = QTimer()
        self.timer.timeout.connect(self.update_header)
        self.timer.start(1000)
        
        # Window setup
        self.setMinimumSize(400, 550)
        self.center_window()
        self.setWindowFlags(Qt.FramelessWindowHint)
        self.setAttribute(Qt.WA_TranslucentBackground)
        
        # Initial date formats
        self.update_calendar_formats()
        self.mark_holidays()
        
        # Connect month change signal to refresh holidays
        self.calendar.currentPageChanged.connect(self.refresh_calendar)
    
    def get_location_info(self):
        """Get location info based on IP address"""
        try:
            response = requests.get('https://ipapi.co/json/', timeout=5)
            if response.status_code == 200:
                data = response.json()
                country = data.get('country_name', 'Unknown')
                country_code = data.get('country_code')
                city = data.get('city', 'Unknown')
                if country_code:
                    print(f"Location detected: {city}, {country}")
                    return country_code
        except requests.RequestException as e:
            print(f"Network error getting location: {e}")
        except Exception as e:
            print(f"Error getting location: {e}")
        
        # Get system locale as fallback
        try:
            import locale
            system_locale = locale.getlocale()[0]
            if system_locale:
                country_code = system_locale.split('_')[1]
                print(f"Using system locale country: {country_code}")
                return country_code
        except Exception:
            pass
            
        print("Using default country code: US")
        return 'US'  # Final fallback

    def load_country_holidays(self):
        """Load holidays with special handling for Canada"""
        try:
            country_code = self.get_location_info()
            year = datetime.now().year

            if country_code == 'CA':
                # Canadian holidays
                self.holidays = {
                    f"{year}-01-01": "New Year's Day",
                    f"{year}-02-21": "Family Day",
                    f"{year}-04-07": "Good Friday",
                    f"{year}-05-22": "Victoria Day",
                    f"{year}-07-01": "Canada Day",
                    f"{year}-08-07": "Civic Holiday",
                    f"{year}-09-04": "Labour Day",
                    f"{year}-10-09": "Thanksgiving",
                    f"{year}-11-11": "Remembrance Day",
                    f"{year}-12-25": "Christmas Day",
                    f"{year}-12-26": "Boxing Day"
                }
                print("Loaded Canadian holidays")
            else:
                # Use Nager.Date API for other countries
                response = requests.get(f'https://date.nager.at/api/v3/PublicHolidays/{year}/{country_code}')
                if response.status_code == 200:
                    holidays_data = response.json()
                    self.holidays = {
                        holiday['date']: holiday['name']
                        for holiday in holidays_data
                    }
                    print(f"Loaded holidays for {country_code}")
                else:
                    print(f"Failed to load holidays: {response.status_code}")
        except Exception as e:
            print(f"Error loading holidays: {e}")
            # Fallback to basic universal holidays
            self.holidays = {
                f"{year}-01-01": "New Year's Day",
                f"{year}-12-25": "Christmas Day",
                f"{year}-12-31": "New Year's Eve"
            }

    def mark_holidays(self):
        holiday_format = QTextCharFormat()
        holiday_format.setForeground(QColor(self.colors['holiday']))
        holiday_format.setBackground(QColor(self.colors['surface_alt']))
        holiday_format.setFontWeight(QFont.Bold)
        
        for date_str, name in self.holidays.items():
            holiday_date = QDate.fromString(date_str, Qt.ISODate)
            if holiday_date.isValid():
                format = QTextCharFormat(holiday_format)
                format.setToolTip(name)
                self.calendar.setDateTextFormat(holiday_date, format)
    
    def show_date_info(self, qdate):
        date_str = qdate.toString("yyyy-MM-dd")
        if date_str in self.holidays:
            self.event_label.setText(f"Holiday: {self.holidays[date_str]}")
        else:
            self.event_label.setText("No events for this date")
    
    def setup_date_formats(self):
        # Weekend format
        self.weekend_format = QTextCharFormat()
        self.weekend_format.setForeground(QColor(self.colors['weekend']))
        self.weekend_format.setFontWeight(QFont.Bold)
        
        # Today format
        self.today_format = QTextCharFormat()
        self.today_format.setBackground(QColor(self.colors['today_bg']))
        self.today_format.setForeground(QColor(self.colors['today_fg']))
        self.today_format.setFontWeight(QFont.Bold)
        
        # Header format
        self.header_format = QTextCharFormat()
        header_font = QFont()
        header_font.setPointSize(11)
        header_font.setBold(True)
        self.header_format.setFont(header_font)
        self.header_format.setForeground(QColor(self.colors['text']))
        
        self.calendar.setHeaderTextFormat(self.header_format)
    
    def update_calendar_formats(self):
        # Apply weekend format
        for day in [Qt.Saturday, Qt.Sunday]:
            self.calendar.setWeekdayTextFormat(day, self.weekend_format)
        
        # Apply today's format
        self.calendar.setDateTextFormat(QDate.currentDate(), self.today_format)
    
    def update_header(self):
        current_date = QDate.currentDate()
        current_time = QTime.currentTime()
        self.header_label.setText(
            f"{current_date.toString('dddd, MMMM d')}\n"
            f"{current_time.toString('hh:mm:ss AP')}"
        )
    
    def go_to_today(self):
        self.calendar.setSelectedDate(QDate.currentDate())
        self.refresh_calendar()
    
    def refresh_calendar(self):
        self.update_calendar_formats()
        self.mark_holidays()
    
    def center_window(self):
        screen = QApplication.primaryScreen().geometry()
        size = self.geometry()
        self.move(
            (screen.width() - size.width()) // 2,
            (screen.height() - size.height()) // 2
        )
    
    def mousePressEvent(self, event):
        self.oldPos = event.globalPosition().toPoint()

    def mouseMoveEvent(self, event):
        delta = event.globalPosition().toPoint() - self.oldPos
        self.move(self.x() + delta.x(), self.y() + delta.y())
        self.oldPos = event.globalPosition().toPoint()

def main():
    # Set up signal handlers
    signal.signal(signal.SIGTERM, cleanup_handler)
    signal.signal(signal.SIGINT, cleanup_handler)
    
    # Ensure single instance
    lock = ensure_single_instance()
    
    app = QApplication(sys.argv)
    window = DarkCalendar()
    window.show()
    
    try:
        sys.exit(app.exec())
    finally:
        # Clean up lock file
        try:
            lock.close()
            os.unlink(lock.name)
        except:
            pass

if __name__ == "__main__":
    main()
