//
//  JOBTest.h
//  JOBridgePractice
//
//  Created by huangchengdu on 16/7/11.
//  Copyright © 2016年 huangchengdu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JOBExport.h"

@protocol JOBTestExport <JOBExport>


@property (nonatomic, strong) NSDictionary *attrs;


-(id)getAttr:(NSString *)attr;

-(void)getAttrWithCallback:(NSString *)attr onComplete:(JOBCallback)onComplete;

-(void)triggerEvent:(NSString *)name data:(NSDictionary *)data;

+(void)asyncData:(NSString *)data data1:(NSString *)data1 onComplete:(JOBCallback)onComplete;

+(void)log:(NSArray *)data;

@end
@interface JOBTest : NSObject<JOBTestExport>

@end
