//
//  JOBBridge.h
//  JOBridgePractice
//
//  Created by huangchengdu on 16/7/4.
//  Copyright © 2016年 huangchengdu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JOBContext.h"

@interface JOBBridge : NSObject
@property(nonatomic, strong, readonly) id<JOBContext> context;
-(instancetype)initWithContext:(id<JOBContext>) context;

@end
