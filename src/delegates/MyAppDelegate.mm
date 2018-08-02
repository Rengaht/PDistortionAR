//
//  MyAppDelegate.m
//  Created by lukasz karluk on 12/12/11.
//

#import "MyAppDelegate.h"
#import "MyAppViewController.h"

@implementation MyAppDelegate

@synthesize navigationController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [NSThread sleepForTimeInterval:5.0];
    
    [super applicationDidFinishLaunching:application];
    
    /**
     *
     *  Below is where you insert your own UIViewController and take control of the App.
     *  In this example im creating a UINavigationController and adding it as my RootViewController to the window. (this is essential)
     *  UINavigationController is handy for managing the navigation between multiple view controllers, more info here,
     *  http://developer.apple.com/library/ios/#documentation/uikit/reference/UINavigationController_Class/Reference/Reference.html
     *
     *  I then push MyAppViewController onto the UINavigationController stack.
     *  MyAppViewController is a custom view controller with a 3 button menu.
     *
     **/
    
    self.navigationController = [[[UINavigationController alloc] init] autorelease];
    [self.window setRootViewController:self.navigationController];
    
    [self.navigationController pushViewController:[[[MyAppViewController alloc] init] autorelease]
                                         animated:YES];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled: YES];
    
    //--- style the UINavigationController
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    self.navigationController.navigationBar.topItem.title = @"Home";
    

    
    return YES;
}

- (void) dealloc {
    self.navigationController = nil;
    [super dealloc];
}
- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window{
    NSUInteger orientations = UIInterfaceOrientationMaskPortrait;


    if(self.window.rootViewController){
        UIViewController *presentedViewController = [self topViewControllerWithRootViewController:self.window.rootViewController];
        orientations = [presentedViewController supportedInterfaceOrientations];
    }

    return orientations;
}

- (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)rootViewController {
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController*)rootViewController;
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
    } else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navigationController = (UINavigationController*)rootViewController;
        return [self topViewControllerWithRootViewController:navigationController.visibleViewController];
    } else if (rootViewController.presentedViewController) {
        UIViewController* presentedViewController = rootViewController.presentedViewController;
        return [self topViewControllerWithRootViewController:presentedViewController];
    } else {
        return rootViewController;
    }
}

@end
