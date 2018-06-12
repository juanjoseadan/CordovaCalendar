package cordovacalendar;

import org.apache.cordova.PluginResult;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.PermissionHelper;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.Date;


public class CordovaCalendar extends CordovaPlugin {

    // write permissions
  private static final int PERMISSION_REQCODE_CREATE_CALENDAR = 100;
  private static final int PERMISSION_REQCODE_DELETE_CALENDAR = 101;
  private static final int PERMISSION_REQCODE_CREATE_EVENT = 102;
  private static final int PERMISSION_REQCODE_DELETE_EVENT = 103;

  // read permissions
  private static final int PERMISSION_REQCODE_FIND_EVENTS = 200;
  private static final int PERMISSION_REQCODE_LIST_CALENDARS = 201;
  private static final int PERMISSION_REQCODE_LIST_EVENTS_IN_RANGE = 202;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        // final boolean hasLimitedSupport = Build.VERSION.SDK_INT < Build.VERSION_CODES.ICE_CREAM_SANDWICH;

        if(action.equals("getCalendars")) {
            this.getCalendars(callbackContext);

            return true;
        } else if(action.equals("addEvent")) {
            this.addEvent(args, callbackContext);

            return true;
        } else if(action.equals("updateEvent")) {
            this.updateEvent(args, callbackContext);

            return true;
        } else if(action.equals("removeEvent")) {
            this.removeEvent(args, callbackContext);
            
            return true;
        }

        return false;
    }



    private void getCalendars(CallbackContext callback) {
        if (!calendarPermissionGranted(Manifest.permission.READ_CALENDAR)) {
            requestReadPermission(PERMISSION_REQCODE_LIST_CALENDARS);

            return;
        }

        cordova.getThreadPool().execute(new Runnable() {
            @Override
            public void run() {
                try {
                    JSONArray calendars = Calendar.this.getCalendarAccessor();

                    if(calendars == null) {
                        calendars = new JSONArray();
                    }

                    callback.sendPluginResult(new PluginResult(PluginResult.Status.OK, calendars));
                } catch (JSONException e) {
                    System.err.println("Exception: " + e.getMessage());
                    callback.error(e.getMessage());
                }
            }
        });
    }

    private void addEvent(JSONArray args, CallbackContext callback) {

    }

    private void updateEvent(JSONArray args, CallbackContext callback) {

    }

    private void removeEvent(JSONArray args, CallbackContext callback) {

    }
}
