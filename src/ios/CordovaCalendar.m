#import "CordovaCalendar.h"
#import <Cordova/CDV.h>
#import "AppDelegate.h"

@implementation CordovaCalendar

@synthesize eventStore;
@synthesize interactiveCallbackId;


- (id)init {
    self = [super init];
    return self;
}

- (void) pluginInitialize {
    __block BOOL accessGranted = NO;
    EKEventStore* eventStoreCandidate = [[EKEventStore alloc] init];
    
    if([eventStoreCandidate respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [eventStoreCandidate requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            accessGranted = granted;
            dispatch_semaphore_signal(sema);
        }];
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    } else {
        accessGranted = YES;
    }
    
    if (accessGranted) {
        self.eventStore = eventStoreCandidate;
    }
}


- (void) getCalendars : (CDVInvokedUrlCommand *) command {
    [self.commandDelegate runInBackground: ^{
        NSArray<EKCalendar *> *calendars = [self.eventStore calendarsForEntityType:EKEntityTypeEvent];
        NSMutableArray *mappedCalendars = [[NSMutableArray alloc] initWithCapacity:calendars.count];
        NSArray *types = [NSArray arrayWithObjects:@"Local", @"CalDAV", @"Exchange", @"Subscription", @"Birthday", @"Mail", nil];
        
        for (EKCalendar *calendar in calendars) {
            NSString *type = [types objectAtIndex:calendar.type];
            NSMutableDictionary *entry = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                          calendar.calendarIdentifier, @"id",
                                          calendar.title, @"name",
                                          type, @"type",
                                          nil];
            
            [mappedCalendars addObject:entry];
        }
        
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus: CDVCommandStatus_OK messageAsArray:mappedCalendars];
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}


- (void) addEvent : (CDVInvokedUrlCommand *) command {
    [self.commandDelegate runInBackground: ^{
        CDVPluginResult *pluginResult = nil;
        
        EKEvent *event = [EKEvent eventWithEventStore:self.eventStore];
        
        if(event) {
            NSDictionary *data = [command.arguments objectAtIndex:0];
            NSString *calendarId = [data objectForKey:@"calendarId"];
            EKCalendar *calendar = [self.eventStore calendarWithIdentifier:calendarId];
            
            if([calendarId isEqualToString:@""]) {
                calendar = [self.eventStore defaultCalendarForNewEvents];
            }
            
            if(calendar) {
                NSError *error = nil;
                NSString *allDay = [data objectForKey:@"allDay"];
                NSNumber *startInterval = [data objectForKey:@"startDate"];
                NSNumber *endInterval = [data objectForKey:@"endDate"];
                NSNumber *firstAlert = [data objectForKey:@"firstAlert"];
                NSNumber *secondAlert = [data objectForKey:@"secondAlert"];
                
                if(allDay && [allDay isEqualToString:@"YES"]) {
                    event.allDay = YES;
                } else {
                    event.allDay = NO;
                }
                
                NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:([startInterval doubleValue] / 1000)];
                NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:([endInterval doubleValue] / 1000)];
                
                [event setTitle:[data objectForKey:@"title"]];
                [event setNotes:[data objectForKey:@"notes"]];
                [event setLocation:[data objectForKey:@"location"]];
                [event setStartDate:startDate];
                [event setEndDate:endDate];
                [event setCalendar:calendar];
                
                if(firstAlert.intValue >= 0) {
                    EKAlarm *reminder = [EKAlarm alarmWithRelativeOffset:-1 * firstAlert.intValue * 60];
                    
                    [event addAlarm:reminder];
                }
                
                if(secondAlert.intValue >= 0) {
                    EKAlarm *reminder = [EKAlarm alarmWithRelativeOffset:-1 * secondAlert.intValue * 60];
                    
                    [event addAlarm:reminder];
                }
                
                if([self.eventStore saveEvent:event span:EKSpanThisEvent commit:YES error:&error]) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:event.eventIdentifier];
                } else {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
                }
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Could not find calendar"];
            }
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Unable to create event"];
        }
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}


- (void) updateEvent : (CDVInvokedUrlCommand *) command {
    [self.commandDelegate runInBackground: ^{
        CDVPluginResult *pluginResult = nil;
        
        NSDictionary *data = [command.arguments objectAtIndex:0];
        NSString *eventId = [data objectForKey:@"eventId"];
        EKEvent *event = [self.eventStore eventWithIdentifier:eventId];
        
        if(event) {
            NSNumber *startInterval = [data objectForKey:@"startDate"];
            NSNumber *endInterval = [data objectForKey:@"endDate"];
            
            NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:([startInterval doubleValue] / 1000)];
            NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:([endInterval doubleValue] / 1000)];
            
            [event setTitle:[data objectForKey:@"title"]];
            [event setNotes:[data objectForKey:@"notes"]];
            [event setLocation:[data objectForKey:@"location"]];
            [event setStartDate:startDate];
            [event setEndDate:endDate];
            
            NSError *error = nil;
            
            if([self.eventStore saveEvent:event span:EKSpanThisEvent commit:YES error:&error]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:event.eventIdentifier];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
            }
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Coult not find event"];
        }
        
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (BOOL) commitChanges {
    NSError *error;
    [self.eventStore commit:&error];

    return (error == Nil);
}


- (void) deleteEvent : (CDVInvokedUrlCommand *) command {
    NSError *error;
    CDVPluginResult *pluginResult = nil;
        
    NSDictionary *data = [command.arguments objectAtIndex:0];
    NSString *calendarId = [data objectForKey:@"calendarId"];
    NSString *eventId = [data objectForKey:@"eventId"];
        
    EKEvent *event = [self.eventStore eventWithIdentifier:eventId];
        
    if(event) {
        if([self.eventStore removeEvent:event span:EKSpanThisEvent error:&error]) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Event deleted"];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.description];
        }
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Event does not exists. No need to delete it."];
    }
        
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

@end
