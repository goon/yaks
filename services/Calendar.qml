pragma Singleton

import QtQuick

QtObject {
    id: root
    
    property int displayMonth: new Date().getMonth()
    
    property int displayYear: new Date().getFullYear()
    
    property var calendarDays: []
    

    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    
    Component.onCompleted: {
        updateCalendar();
    }
    
    function changeMonth(delta) {
        var newMonth = displayMonth + delta;
        var newYear = displayYear;
        
        while (newMonth < 0) {
            newMonth += 12;
            newYear -= 1;
        }
        while (newMonth > 11) {
            newMonth -= 12;
            newYear += 1;
        }
        
        displayMonth = newMonth;
        displayYear = newYear;
        
        updateCalendar();
    }
    
    function resetToCurrentMonth() {
        var now = new Date();
        displayMonth = now.getMonth();
        displayYear = now.getFullYear();
        updateCalendar();
    }
    
    function getDaysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate();
    }
    
    function isToday(day, month, year) {
        var now = new Date();
        return day === now.getDate() && 
               month === now.getMonth() && 
               year === now.getFullYear();
    }
    

    
    function updateCalendar() {
        var days = [];
        var daysInMonth = getDaysInMonth(displayYear, displayMonth);
        var firstDayOfMonth = new Date(displayYear, displayMonth, 1).getDay();
        
        var prevMonth = displayMonth === 0 ? 11 : displayMonth - 1;
        var prevYear = displayMonth === 0 ? displayYear - 1 : displayYear;
        var daysInPrevMonth = getDaysInMonth(prevYear, prevMonth);
        
        for (var i = firstDayOfMonth - 1; i >= 0; i--) {
            days.push({
                day: daysInPrevMonth - i,
                isCurrentMonth: false,
                isToday: false
            });
        }
        
        for (var day = 1; day <= daysInMonth; day++) {
            days.push({
                day: day,
                isCurrentMonth: true,
                isToday: isToday(day, displayMonth, displayYear)
            });
        }
        
        // 42 days = 6 rows
        var nextMonthDays = 42 - days.length;
        for (var j = 1; j <= nextMonthDays; j++) {
            days.push({
                day: j,
                isCurrentMonth: false,
                isToday: false
            });
        }
        
        calendarDays = days;
    }
}
