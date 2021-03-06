/*
* Copyright (C) 2016 Sensible Solutions Sweden AB
*
* Cordova plugin supporting the SenseSoft Notifications Comfort app.
*/

#import "SsnComfortSupportPlugin.h"
#import <SystemConfiguration/CaptiveNetwork.h>

// Plugin Name
NSString *const pluginName = @"ssncomfortsupportplugin";

// General variables
bool mDEBUG = true;			// Debug flag, setting to true will show debug message boxes
	
// Object Keys
NSString *const keyStatus = @"status";
NSString *const keyError = @"error";
NSString *const keyMessage = @"message";
NSString *const keySsid = @"ssid";

// Status Types
NSString *const statusSettingsAppOpened = @"settingsAppOpened";
NSString *const statusNotificationSoundPlayed = @"notificationSoundPlayed";
NSString *const statusNotificationSoundNotEnabled = @"notificationSoundNotEnabled";
//NSString *const statusGetWifiName = @"ssid";

// Error Types
NSString *const errorOpenSettingsApp = @"settingsApp";
NSString *const errorGetWifiName = @"wifiName";
NSString *const errorArguments = @"arguments";

// Error Messages
NSString *const logSettingsApp = @"Could not open settings app for application";
NSString *const logGetWifiName = @"Could not get wifi name";
NSString *const logNoArgObj = @"Argument object can not be found";


@implementation SsnComfortSupportPlugin

#pragma mark -
#pragma mark Interface

// Plugin actions
- (void)openSettingsApp:(CDVInvokedUrlCommand *)command
{

	// Save the callback
	//openSettingsAppCallback = command.callbackId;
	// Launch the Settings app and displays the app’s custom settings
	NSURL *appSettings = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
	if ([[UIApplication sharedApplication] openURL:appSettings]) {
		NSDictionary* returnObj = [NSDictionary dictionaryWithObjectsAndKeys: statusSettingsAppOpened, keyStatus, nil];
	        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:returnObj];
		[pluginResult setKeepCallbackAsBool:false];
	        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
	}
	else {
		NSDictionary* returnObj = [NSDictionary dictionaryWithObjectsAndKeys: errorOpenSettingsApp, keyError, logSettingsApp, keyMessage, nil];
        	CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:returnObj];
		[pluginResult setKeepCallbackAsBool:false];
	 	[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
	}
}

- (void)getWifiName:(CDVInvokedUrlCommand *)command
{
	NSArray *interfaceNames = (__bridge_transfer NSArray *)CNCopySupportedInterfaces();
	NSDictionary *wifiInfo;
	for (NSString *interfaceName in interfaceNames) {
		wifiInfo = (__bridge_transfer NSDictionary *)CNCopyCurrentNetworkInfo((__bridge CFStringRef)interfaceName);
        	if (wifiInfo && [wifiInfo count]) { break; }
	}
    
    	NSString *ssid = [wifiInfo objectForKey:(id)kCNNetworkInfoKeySSID];		//@"SSID"
    	if (ssid && [ssid length]) {
    		NSDictionary* returnObj = [NSDictionary dictionaryWithObjectsAndKeys: ssid, keySsid, nil];
    		CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:returnObj];
    		[pluginResult setKeepCallbackAsBool:false];
    		[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    	}
    	else {
    		NSDictionary* returnObj = [NSDictionary dictionaryWithObjectsAndKeys: errorGetWifiName, keyError, logGetWifiName, keyMessage, nil];
        	CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:returnObj];
		[pluginResult setKeepCallbackAsBool:false];
	 	[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    	}
}

- (void)playNotificationSound:(CDVInvokedUrlCommand *)command
{
	//AudioServicesPlayAlertSound(notificationSoundID);	// Also vibrates if possible
	//AudioServicesPlayAlertSound(1315);
	//AudioServicesPlaySystemSound(1315);
	
	if ([[UIApplication sharedApplication] respondsToSelector:@selector(currentUserNotificationSettings)]){		// Check it's iOS 8 and above
		// Check if remote notifications are enabled for the app
		if ([[UIApplication sharedApplication] isRegisteredForRemoteNotifications]){
			UIUserNotificationSettings *grantedSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
			// Check if notification sound is enabled
			if (grantedSettings.types & UIUserNotificationTypeSound){
				AudioServicesPlayAlertSound(notificationSoundID);	// Also vibrates if possible
				NSDictionary* returnObj = [NSDictionary dictionaryWithObjectsAndKeys: statusNotificationSoundPlayed, keyStatus, nil];
				CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:returnObj];
				[pluginResult setKeepCallbackAsBool:false];
				[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
				return;
			}
		}
	}
	
	NSDictionary* returnObj = [NSDictionary dictionaryWithObjectsAndKeys: statusNotificationSoundNotEnabled, keyStatus, nil];
	CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:returnObj];
	[pluginResult setKeepCallbackAsBool:false];
	[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


#pragma mark -
#pragma mark Delegates

// Delegate Methods


#pragma mark -
#pragma mark General helpers

-(NSDictionary*) getArgsObject:(NSArray *)args
{
    if (args == nil)
        return nil;
    if (args.count != 1)
        return nil;

    NSObject* arg = [args objectAtIndex:0];

    if (![arg isKindOfClass:[NSDictionary class]])
        return nil;

    return (NSDictionary *)[args objectAtIndex:0];
}

- (BOOL) isNotArgsObject:(NSDictionary*) obj :(CDVInvokedUrlCommand *)command
{
    if (obj != nil)
        return false;

    NSDictionary* returnObj = [NSDictionary dictionaryWithObjectsAndKeys: errorArguments, keyError, logNoArgObj, keyMessage, nil];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:returnObj];
    [pluginResult setKeepCallbackAsBool:false];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

    return true;
}

- (void) showDebugMsgBox: (NSString *const) msg
{
	if (mDEBUG) {
		UIAlertView *debugAlert = [[UIAlertView alloc] initWithTitle: @"Debug SsnComfortPlugin" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        	[debugAlert show];
        }
}

/*
#pragma mark -
#pragma mark CDVPlugin delegates (see CDVPlugin.m and CDVPlugin.h)

// Called after plugin is initialized
- (void) pluginInitialize
{
	// Not implemented
}

// Called when running low on memory
- (void) onMemoryWarning
{
	// Not implemented
}

// Called before app terminates
- (void) onAppTerminate
{
    	// Not implemeted
}

// Called when plugin resets (navigates to a new page or refreshes)
- (void) onReset
{
	// Override to cancel any long-running requests when the WebView navigates or refreshes
	// Not implemented
}

- (void)handleOpenURL:(NSNotification*)notification
{
    // Override to handle urls sent to your app
    // Also register your url schemes in your App-Info.plist

    NSURL* url = [notification object];

    if ([url isKindOfClass:[NSURL class]]) {
        // Do your thing!
    }
}

// Called when the system is about to start resuming a previous activity
- (void) onPause
{
	// NOTE: if you want to use this, make sure you add the corresponding notification handler in CDVPlugin.m
	// Not implemented
}

// Called when the activity will start interacting with the user
- (void) onResume
{
	// NOTE: if you want to use this, make sure you add the corresponding notification handler in CDVPlugin.m
	// Not implemented
}

- (void) onOrientationWillChange
{
	// NOTE: if you want to use this, make sure you add the corresponding notification handler in CDVPlugin.m
	// Not implemented
}

- (void) onOrientationDidChange
{
	// NOTE: if you want to use this, make sure you add the corresponding notification handler in CDVPlugin.m
	// Not implemented
}
*/

@end
