//
//  JOBApp.m
//  JOBridgePractice
//
//  Created by huangchengdu on 16/7/11.
//  Copyright © 2016年 huangchengdu. All rights reserved.
//

#import "JOBApp.h"

@implementation JOBApp
@synthesize bridge = _bridge, delegate = _delegate;

- (id)initWithDelegate:(id<JOBAppDelegate>)delegate{
    if (self = [super init]) {
        _delegate = delegate;
    }
    return self;
}

- (BOOL)load:(id<JOBExport>)module options:(NSDictionary *)options{
    NSLog(@"load %@", module);
    return YES;
}

- (void)dealloc{
    NSLog(@"dealloc app");
}


@end
