//
//  AppDelegate.m
//  JOBridgePractice
//
//  Created by huangchengdu on 16/7/1.
//  Copyright © 2016年 huangchengdu. All rights reserved.
//

#import "AppDelegate.h"
#import "JOBBridge.h"
#import "JOBJavaScriptCoreContext.h"
#import "JOBApp.h"


@interface AppDelegate ()<JOBAppDelegate>
@end

@implementation AppDelegate
{
    JOBBridge *bridge;
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    JOBJavaScriptCoreContext *ctx = [[JOBJavaScriptCoreContext alloc]init];
    [ctx execScript:[NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"bridge" withExtension:@"js"]] sourceURL:[NSURL URLWithString:@"bridge.js"] onComplete:^(NSError *error) {
        NSLog(@"bridge文件执行错误: %@",error);
    }];
    
    bridge = [[JOBBridge alloc]initWithContext:ctx];
    
    [ctx execScript:[NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"main" withExtension:@"js"]] sourceURL:[NSURL URLWithString:@"main.js"] onComplete:^(NSError *error) {
        NSLog(@"main文件执行错误 %@", error);
    }];
    
    JOBApp *myApp = [[JOBApp alloc] initWithDelegate:self];
    [bridge mapInstance:myApp moduleName:@"MyApp"];
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    UIViewController *rootViewController = [UIViewController new];
    self.window.rootViewController = rootViewController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)app:(JOBApp *)app loadRootViewController:(UIViewController *)viewController{
    
}

@end
