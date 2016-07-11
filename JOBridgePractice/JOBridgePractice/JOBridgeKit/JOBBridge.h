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
-(void)mapInstance:(id<JOBExport>)instance moduleName:(NSString *)moduleName;
-(void)triggerEvent:(id<JOBExport>)instance name:(NSString *)name data:(id)data;
@end


@interface JOBModuleMirror : NSObject
+(instancetype)moduleMirrorFromInstance:(id<JOBExport>)instance;
@property (nonatomic, assign, readonly) long long tag;
//要转换的实例
@property (nonatomic, weak, readonly) id<JOBExport> instance;
@property (nonatomic, weak, readonly) JOBBridge *bridge;
-(id)initWithTag:(long long)tag instance:(id<JOBExport>) instance bridge:(JOBBridge *)bridge;
@end