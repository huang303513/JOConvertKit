//
//  JOBExport.h
//  JOBridgePractice
//
//  Created by huangchengdu on 16/7/4.
//  Copyright © 2016年 huangchengdu. All rights reserved.
//

#ifndef JOBExport_h
#define JOBExport_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class JOBBridge;
//回调函数
typedef void (^JOBCallback)(NSArray *args);

@protocol JOBExport <NSObject>
@optional
+(NSString *)moduleName;
@property(nonatomic, weak, readonly)JOBBridge *bridge;
-(BOOL)load:(id<JOBExport>)module options:(NSDictionary *)options;
@end


#endif /* JOBExport_h */
