//
//  JOBTest.m
//  JOBridgePractice
//
//  Created by huangchengdu on 16/7/11.
//  Copyright © 2016年 huangchengdu. All rights reserved.
//

#import "JOBTest.h"

@implementation JOBTest
@synthesize attrs;

+(void)asyncData:(NSString *)data data1:(NSString *)data1 onComplete:(JOBCallback)onComplete{
    NSLog(@"asyncData %@", data);
    NSLog(@"asyncData %@", data1);
    NSLog(@"asyncData %@", onComplete);
    //    onComplete(@[]);
    // Invoke the method.
    double delayInSeconds = 5.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(),
                   ^{
                       onComplete(@[data ?: [NSNull null], data1 ?: [NSNull null]]);
                   });
}

-(void)triggerEvent:(NSString *)name data:(NSDictionary *)data{


}

+(void)log:(NSArray *)data{
    NSLog(@"logTest %@, mainThead %d", data, [NSThread isMainThread]);
}

-(void)getAttrWithCallback:(NSString *)attr onComplete:(JOBCallback)onComplete{
    double delayInSeconds = 5.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(),
                   ^{
                       onComplete(@[attr ?: [NSNull null], attr ?: [NSNull null]]);
                   });
}

-(id)getAttr:(NSString *)attr{
    return @"Test attr";
}

- (void)dealloc{
    NSLog(@"dealloc Test");
}

@end
