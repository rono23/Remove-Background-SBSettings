#import <substrate.h>
#import <UIKit/UIkit.h>
#import <SpringBoard/SBUIController.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBApplicationIcon.h>
#import <SpringBoard/SBAppSwitcherController.h>
#import <SpringBoard/SBAppSwitcherBarView.h>

@interface SBAppIconQuitButton : UIButton
@property(retain, nonatomic) SBApplicationIcon *appIcon;
@end

@implementation SBAppIconQuitButton
@synthesize appIcon;
@end;

UIWindow *getAppWindow() {
    UIWindow *window = nil;
    UIApplication *app = [UIApplication sharedApplication];
    NSArray *windows = [app windows];
    int i;
    for(i = 0; i < [windows count]; i++) {
        window = [windows objectAtIndex:i];
        if([window respondsToSelector:@selector(getCurrentTheme)])
            break;
    }

    if(i == [windows count])
        window = [app keyWindow];

    return window;
}

BOOL isCapable() {
    return YES;
}

BOOL isEnabled() {
    return YES;
}

BOOL getStateFast() {
    return isEnabled();
}

float getDelayTime() {
    return 0.0f;
}

void setState(BOOL Enable) {
    NSMutableArray *apps = [[NSMutableArray alloc] init];
    CFPropertyListRef propList = CFPreferencesCopyAppValue(CFSTR("apps"), CFSTR("jp.rono23.removebackgroundapp"));
    if (propList) {
        if (CFGetTypeID(propList) == CFArrayGetTypeID())
            for (id item in (NSArray *)propList)
                [apps addObject:item];

        CFRelease(propList);
    }

    // TODO: When we use "_toggleSwitcher", we can get the latest icons.
    // But this is not good. Should fix.
    // Ex) NSArray *icons = [switchCont _applicationIconsExcept:forOrientation:];
    SBUIController *uiCont = [objc_getClass("SBUIController") sharedInstance];
    [uiCont _toggleSwitcher];

    SBAppSwitcherController *switchCont = [objc_getClass("SBAppSwitcherController") sharedInstance];
    SBAppSwitcherBarView  *_bottomBar;
    object_getInstanceVariable(switchCont, "_bottomBar", &_bottomBar);
    NSArray *icons = [_bottomBar.appIcons copy];

    float isFirmware = [[[UIDevice currentDevice] systemVersion] floatValue];
    int count = [apps count];
    for (SBApplicationIcon *icon in icons) {
        if (count > 0) {

            NSString *identifier;
            if (isFirmware >= 4.1f) {
                object_getInstanceVariable(icon, "_displayIdentifier", &identifier);
            } else {
                SBApplication *_app;
                object_getInstanceVariable(icon, "_app", &_app);
                identifier = _app.displayIdentifier;
            }

            if (identifier != nil && [apps containsObject:identifier])
                continue;
        }

        if (isFirmware >= 4.1f) {
            [switchCont iconCloseBoxTapped:icon];
        } else {
            SBAppIconQuitButton *quitBtn = [SBAppIconQuitButton buttonWithType:UIButtonTypeCustom];
            quitBtn.appIcon = icon;
            [switchCont _quitButtonHit:quitBtn];
        }
    }

    [apps release];
    [icons release];
    [uiCont _dismissSwitcher:0.0];

    if (isFirmware >= 4.2f) {
        [uiCont createFakeSpringBoardStatusBar];
        [uiCont setFakeSpringBoardStatusBarVisible:YES];
    }

    UIWindow *window = getAppWindow();
    if([window isKeyWindow] == YES)
        [window closeButtonPressed];
}
