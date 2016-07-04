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



@interface AppDelegate ()
@end

@implementation AppDelegate
{
    JOBBridge *bridge;
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    JOBJavaScriptCoreContext *ctx = [[JOBJavaScriptCoreContext alloc]init];
    [ctx execScript:[NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"bridge" withExtension:@"js"]] sourceURL:[NSURL URLWithString:@"bridge.js"] onComplete:^(NSError *error) {
        NSLog(@"javascript文件执行错误: %@",error);
    }];
    
    
    return YES;
}


@end
