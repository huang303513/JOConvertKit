//
//  ViewController.m
//  JOBridgePractice
//
//  Created by huangchengdu on 16/7/1.
//  Copyright © 2016年 huangchengdu. All rights reserved.
//

#import "ViewController.h"
#import "JOBBridge.h"
#import "JOBJavaScriptCoreContext.h"
#import "JOBApp.h"

@interface ViewController ()<JOBAppDelegate>
{
    JOBBridge *bridge;
    JOBJavaScriptCoreContext *ctx;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    ctx = [[JOBJavaScriptCoreContext alloc]init];
}

- (IBAction)doInit:(id)sender {
    
    
    [ctx execScript:[NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"bridge" withExtension:@"js"]] sourceURL:[NSURL URLWithString:@"bridge.js"] onComplete:^(NSError *error) {
        NSLog(@"bridge文件是否有错: %@",error);
    }];
}

- (IBAction)doTest:(id)sender {
    
    bridge = [[JOBBridge alloc]initWithContext:ctx];
    
    [ctx execScript:[NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"main" withExtension:@"js"]] sourceURL:[NSURL URLWithString:@"main.js"] onComplete:^(NSError *error) {
        NSLog(@"main文件是否有错 %@", error);
    }];
    
    JOBApp *myApp = [[JOBApp alloc] initWithDelegate:self];
    [bridge mapInstance:myApp moduleName:@"MyApp"];
}


- (void)app:(JOBApp *)app loadRootViewController:(UIViewController *)viewController{
    
}

@end
