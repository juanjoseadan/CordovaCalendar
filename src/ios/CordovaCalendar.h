#import <Foundation/Foundation.h>
#import <EventKit/EventKit.h>
#import <Cordova/CDVPlugin.h>
#import <EventKitUI/EventKitUI.h>


@interface CordovaCalendar : CDVPlugin <EKEventEditViewDelegate>

@property (nonatomic, retain) EKEventStore* eventStore;
@property (nonatomic, copy) NSString *interactiveCallbackId;


- (void) getCalendars : (CDVInvokedUrlCommand *) command;
- (void) addEvent : (CDVInvokedUrlCommand *) command;
- (void) updateEvent : (CDVInvokedUrlCommand *) command;
- (BOOL) commitChanges;
- (void) deleteEvent : (CDVInvokedUrlCommand *) command;

@end
