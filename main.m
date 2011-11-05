#import <substrate.h>
#import <UIKit/UIkit.h>
#import <SpringBoard/SBUIController.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBApplicationIcon.h>
#import <SpringBoard/SBAppSwitcherController.h>
#import <SpringBoard/SBAppSwitcherBarView.h>
#import <SpringBoard/SBIconView.h>

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
    float isFirmware = [[[UIDevice currentDevice] systemVersion] floatValue];

    NSMutableArray *apps = [[NSMutableArray alloc] init];
    CFPropertyListRef propList = CFPreferencesCopyAppValue(CFSTR("apps"), CFSTR("jp.rono23.removebackgroundapp"));
    if (propList) {
        if (CFGetTypeID(propList) == CFArrayGetTypeID())
            for (id item in (NSArray *)propList)
                [apps addObject:item];

        CFRelease(propList);
    }
    int count = [apps count];

    SBUIController *uiCont = [objc_getClass("SBUIController") sharedInstance];
    [uiCont _toggleSwitcher];

    SBAppSwitcherController *switchCont = [objc_getClass("SBAppSwitcherController") sharedInstance];
    SBAppSwitcherBarView  *_bottomBar;
    object_getInstanceVariable(switchCont, "_bottomBar", &_bottomBar);
    NSString *identifier = nil;

    if (isFirmware >= 5.0) {
        NSArray *_appIcons;
        object_getInstanceVariable(_bottomBar, "_appIcons", &_appIcons);
        NSArray *iconViews = [_appIcons copy];

        for (id iconView in iconViews) {
            SBIcon *icon;
            object_getInstanceVariable(iconView, "_icon", &icon);
            object_getInstanceVariable(icon, "_displayIdentifier", &identifier);

            if (![icon isFolderIcon] && identifier == nil)
                continue;

            if (count > 0 && [apps containsObject:identifier])
                continue;

            [(SBIconView *)iconView closeBoxTapped];
        }
        [uiCont dismissSwitcherAnimated:0.0];
        [iconViews release];

    } else {
        NSArray *icons = [_bottomBar.appIcons copy];
        for (SBApplicationIcon *icon in icons) {
            if (count > 0) {

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
        [uiCont _dismissSwitcher:0.0];

        if (isFirmware >= 4.2f) {
            [uiCont createFakeSpringBoardStatusBar];
            [uiCont setFakeSpringBoardStatusBarVisible:YES];
        }
        [icons release];
    }

    UIWindow *window = getAppWindow();
    if([window isKeyWindow] == YES)
        [window closeButtonPressed];

    [apps release];
}
