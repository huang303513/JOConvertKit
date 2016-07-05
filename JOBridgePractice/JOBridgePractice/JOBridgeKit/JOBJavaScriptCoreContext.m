//
//  JOBJavaScriptCoreContext.m
//  JOBridgePractice
//
//  Created by huangchengdu on 16/7/4.
//  Copyright © 2016年 huangchengdu. All rights reserved.
//

#import "JOBJavaScriptCoreContext.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <objc/message.h>

/**
 *  把jsvalue转换为string
 *
 *  @param context   上下文
 *  @param value     要转换的值
 *  @param exception 异常
 *
 *  @return 转换后的字符串
 */
static NSString *JOBJSValueToNSString(JSContextRef context, JSValueRef value, JSValueRef *exception){
    JSStringRef JSString = JSValueToStringCopy(context, value, exception);
    if (!JSString) {
        return nil;
    }
    CFStringRef string = JSStringCopyCFString(kCFAllocatorDefault, JSString);
    return (__bridge_transfer NSString *)string;
}

/**
 *  通过一个jsvalue来转换为一个json的字符串
 *
 *  @param context   上下文
 *  @param value     要转换的字符串
 *  @param exception 转换异常
 *  @param indent    空格
 *
 *  @return json字符串
 */
static NSString * JOBJSValueToJSONString(JSContextRef context, JSValueRef value, JSValueRef *exception, unsigned indent){
    JSStringRef JSString = JSValueCreateJSONString(context, value, indent, exception);
    CFStringRef string = JSStringCopyCFString(kCFAllocatorDefault, JSString);
    return (__bridge_transfer NSString *)string;
}

/**
 *  把js格式的错误、转换为OC格式的错误对象返回
 *
 *  @param context 上下文
 *  @param jsError js错误
 *
 *  @return oc错误对象
 */
static NSError *JOBNSErrorFromJSError(JSContextRef context, JSValueRef jsError){
    NSString *errorMessage = jsError ? JOBJSValueToNSString(context, jsError, NULL) : @"未知的JS错误";
    NSString *details = jsError ? JOBJSValueToJSONString(context, jsError, NULL, 2) : @"未知的JS错误详情";
    return [NSError errorWithDomain:@"JavaScriptCore" code:1 userInfo:@{NSLocalizedDescriptionKey:errorMessage, NSLocalizedFailureReasonErrorKey:details}];
}
/**
 *  把一个可以json序列化的对象转换为一个json字符串返回
 *
 *  @param jsonObject json对象
 *  @param error      转换错误
 *
 *  @return json字符串
 */
NSString *JOBJSONStringify(id jsonObject, NSError **error){
    static SEL JSONKitSelector = NULL;
    static NSSet<Class> *collectionTypes;
    static dispatch_once_t onceToken;
    _dispatch_once(&onceToken, ^{
        SEL selector = NSSelectorFromString(@"JSONStringWithOptions:error:");
        if ([NSDictionary instancesRespondToSelector:selector]) {
            JSONKitSelector = selector;
            collectionTypes = [NSSet setWithObjects:[NSArray class],[NSMutableArray class],[NSDictionary class],[NSMutableDictionary class], nil];
        }
    });
    // 如果引入了JSONkit这个框架并且jsonObject是集合的子类。则直接用jsonkit的方法解析。否则用系统原生的解析
    if (JSONKitSelector && [collectionTypes containsObject:[jsonObject classForCoder]]) {
        return ((NSString *(*)(id, SEL, int, NSError **))objc_msgSend)(jsonObject, JSONKitSelector, 0, error);
    }
    //如果上面不成立，用苹果自带的API解析
    NSData *jsonData = [NSJSONSerialization
                        dataWithJSONObject:jsonObject
                        options:(NSJSONWritingOptions)NSJSONReadingAllowFragments
                        error:error];
    return jsonData ? [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] : nil;
}



@interface JOBJavaScriptCoreContext ()
@property(nonatomic, strong, readonly)JSContext * context;
@end

@implementation JOBJavaScriptCoreContext
@synthesize receiver = _receiver;
-(instancetype)init{
    if (self = [super init]) {
        _context = [JSContext new];
        __weak JOBJavaScriptCoreContext *weakSelf = self;
        //设置一个在js中调用的函数
        _context[@"__JOBContextSend"] = ^(NSString * method, NSArray *args, JSValue *callback){
            NSLog(@"receive %@, %@, mainThead %d", method, args, [NSThread isMainThread]);
            if (weakSelf && weakSelf.receiver) {
                    weakSelf.receiver(method, args, (callback ? ^(NSArray *args){
                    [callback callWithArguments:args];
                } : nil));
            }
        };
    }
    return self;
}



/**
 *  执行js文件
 *
 *  @param script     要执行的js文件内容
 *  @param sourceURL
 *  @param onComplete 执行完毕的回调函数
 */
-(void)execScript:(NSData *)script sourceURL:(NSURL *)sourceURL onComplete:(JOBContextCompleteBlock)onComplete{
    NSMutableData * nullTerminatedScript = [NSMutableData dataWithCapacity:script.length + 1];
    [nullTerminatedScript appendData:script];
    [nullTerminatedScript appendBytes:"" length:1];
    JSValueRef exceptionValue = NULL;
    //用一个UTF8字符串创建一个javascript的字符串
    JSStringRef scriptJS = JSStringCreateWithUTF8CString(nullTerminatedScript.bytes);
    JSStringRef sourceURLJS = sourceURL ? JSStringCreateWithCFString((__bridge CFStringRef)[sourceURL absoluteString]):NULL;
    //执行javascript内容
    JSEvaluateScript(_context.JSGlobalContextRef, scriptJS, NULL, sourceURLJS, 0, &exceptionValue);
    //执行JS出错
    if (exceptionValue) {
        onComplete(JOBNSErrorFromJSError(_context.JSGlobalContextRef, exceptionValue));
    }else{
        onComplete(nil);
    }
}
/**
 *  执行具体的js方法、并且通过回调返回执行的结果
 *
 *  @param method     方法名字
 *  @param args       参数
 *  @param onComplete 回调
 */
-(void)callMethod:(NSString *)method arguments:(NSArray *)args callback:(JOBCallback)onComplete{
    NSLog(@"callMethod %@, %@, mainThead %d", method, args, [NSThread isMainThread]);
    //调用对应的JS方法
    [self.context evaluateScript:[NSString stringWithFormat:@"__JOBContextReceiver('%@',%@)",method,JOBJSONStringify(args, nil)]];
}
@end
