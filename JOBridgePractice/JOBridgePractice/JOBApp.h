//
//  JOBApp.h
//  JOBridgePractice
//
//  Created by huangchengdu on 16/7/11.
//  Copyright © 2016年 huangchengdu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JOBExport.h"
@class JOBApp;

@protocol JOBAppExport <JOBExport>

- (BOOL)load:(id<JOBExport>)module options:(NSDictionary *)options;

@end

@protocol JOBAppDelegate <NSObject>

- (void)app:(JOBApp *)app loadRootViewController:(UIViewController *)viewController;

@end

@interface JOBApp : NSObject<JOBAppExport>
@property (nonatomic, weak, readonly) id<JOBAppDelegate> delegate;

- (id)initWithDelegate:(id<JOBAppDelegate>)delegate;
@end
