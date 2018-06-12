var exec = require('cordova/exec');

exports.getCalendars = function(successCallback, errorCallback) {
    exec(successCallback, errorCallback, 'CordovaCalendar', 'getCalendars');
};

exports.addEvent = function(data, successCallback, errorCallback) {
    if(data.startDate instanceof Date && data.endDate instanceof Date) {
        let allDay = 'NO';

        if(data && data.allDay) {
            allDay = 'YES';
        }

        exec(successCallback, errorCallback, 'CordovaCalendar', 'addEvent', [{
            "calendarId": data.calendarId,
            "title": data.title,
            "notes": data.notes,
            "location": data.location,
            "allDay": allDay,
            "startDate": data.startDate.getTime(),
            "endDate": data.endDate.getTime(),
            "firstAlert": data.firstAlert || -1,
            "secondAlert": data.secondAlert || -1,
        }]);
    } else {
        errorCallback('Please provide a valid date');
    }
}

exports.updateEvent = function(data, successCallback, errorCallback) {
    if(data.startDate instanceof Date && data.endDate instanceof Date) {
        exec(successCallback, errorCallback, 'CordovaCalendar', 'updateEvent', [{
            "eventId": data.eventId,
            "title": data.title,
            "notes": data.notes,
            "location": data.location,
            "startDate": data.startDate.getTime(),
            "endDate": data.endDate.getTime(),
        }]);
    } else {
        errorCallback('Please provide a valid date');
    }
};

exports.deleteEvent = function(data, successCallback, errorCallback) {
    exec(successCallback, errorCallback, 'CordovaCalendar', 'deleteEvent', [{
        "calendarId": data.calendarId,
        "eventId": data.eventId,
    }]);
};