//
//  JOBBridge.m
//  JOBridgePractice
//
//  Created by huangchengdu on 16/7/4.
//  Copyright © 2016年 huangchengdu. All rights reserved.
//

#import "JOBBridge.h"
#import "objc/runtime.h"

void JOBRegisterModule(Class moduleClass){

}

@interface JOBBridge ()
@property(nonatomic,strong, readonly)NSMapTable *instances;
-(void)triggerEventWithTag:(long long)tag name:(NSString *)name data:(id)data;
@end

@implementation JOBBridge
+(void)initialize{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        static unsigned int classCount;
        //获取当前加入运行时的所有类
        Class *classes = objc_copyClassList(&classCount);
        Protocol *protocol = @protocol(JOBExport);
        for(unsigned int i = 0; i < classCount;i++) {
            Class cls = classes[i];
            if (class_conformsToProtocol(cls, protocol)) {
                JOBRegisterModule(cls);
            }
        }
        free(classes);
    });
}
@end
