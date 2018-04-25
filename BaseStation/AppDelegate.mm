//
//  AppDelegate.m
//  BaseStation
//
//  Created by loop on 2018/4/23.
//  Copyright © 2018年 loop. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "BNCoreServices.h"
#import <BaiduMapAPI_Map/BMKMapComponent.h>

#define NAVI_TEST_BUNDLE_ID @"looper.chinaunicom.-22"  //SDK测试bundle ID
#define NAVI_TEST_APP_KEY   @"AROKW1DRZ6LPyNBb8Pm3jBB1WAyzHOs5"  //SDK测试APP KEY
#define NAVI_TEST_TTS_APP_ID @"11146830" //SDK测试语言播报 APPID

@interface AppDelegate ()
{
    BMKMapManager* _mapManager;
}
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    // 先启动BaiduMapManager
    _mapManager = [[BMKMapManager alloc]init];
    
    /**
     *百度地图SDK所有接口均支持百度坐标（BD09）和国测局坐标（GCJ02），用此方法设置您使用的坐标类型.
     *默认是BD09（BMK_COORDTYPE_BD09LL）坐标.
     *如果需要使用GCJ02坐标，需要设置CoordinateType为：BMK_COORDTYPE_COMMON.
     */
    if ([BMKMapManager setCoordinateTypeUsedInBaiduMapSDK:BMK_COORDTYPE_COMMON]) {
        NSLog(@"经纬度类型设置成功");
    } else {
        NSLog(@"经纬度类型设置失败");
    }
    
    BOOL ret = [_mapManager start:NAVI_TEST_APP_KEY generalDelegate:self];
    if (!ret) {
        NSLog(@"manager start failed!");
    }
    
    ViewController *rootVC = [[ViewController alloc] init];
    
    UINavigationController *rootNav = [[UINavigationController alloc] initWithRootViewController:rootVC];
    [rootNav.navigationBar setBackgroundImage:[UIImage imageNamed:@"default_top_bar"] forBarMetrics:UIBarMetricsDefault];
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = rootNav;
    [self.window makeKeyAndVisible];
    //初始化导航SDK
    [BNCoreServices_Instance initServices:NAVI_TEST_APP_KEY];
    //TTS在线授权
    [BNCoreServices_Instance setTTSAppId:NAVI_TEST_TTS_APP_ID];
    //设置是否自动退出导航
    [BNCoreServices_Instance setAutoExitNavi:NO];
    [BNCoreServices_Instance startServicesAsyn:nil fail:nil];
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
