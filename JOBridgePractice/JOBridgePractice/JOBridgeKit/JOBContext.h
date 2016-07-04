//
//  JOBContext.h
//  JOBridgePractice
//
//  Created by huangchengdu on 16/7/4.
//  Copyright © 2016年 huangchengdu. All rights reserved.
//

#ifndef JOBContext_h
#define JOBContext_h

#import "JOBExport.h"

typedef void (^JOBContextCompleteBlock)(NSError *error);
typedef void (^JOBContextMethod)(NSString *method, NSArray *args, JOBCallback callback);

@protocol JOBContext <NSObject>
@property(nonatomic, copy)JOBContextMethod receiver;

-(void)execScript:(NSData *)script sourceURL:(NSURL *)sourceURL onComplete:(JOBContextCompleteBlock )onComplete;
-(void)callMethod:(NSString *)method arguments:(NSArray *)args callback:(JOBCallback)onComplete;
@end

#endif /* JOBContext_h */
