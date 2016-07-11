//
//  JOBBridge.m
//  JOBridgePractice
//
//  Created by huangchengdu on 16/7/4.
//  Copyright © 2016年 huangchengdu. All rights reserved.
//

#import "JOBBridge.h"
#import "objc/runtime.h"


@class JOBModuleMirror;
/**
 *  通过类名字、返回对应的映射类名
 *
 *  @param cls 类
 *
 *  @return 映射类名
 */
NSString *JOBModuleNameForClass(Class cls){
    NSString *name = nil;
    if ([cls respondsToSelector:@selector(moduleName)]) {
        name = [cls moduleName];
    }else{
        name = NSStringFromClass(cls);
    }
    if (name.length == 0) {
        name = NSStringFromClass(cls);
    }
    if ([name hasPrefix:@"JOB"]) {
        name = [name stringByReplacingCharactersInRange:(NSRange){0, @"JOB".length} withString:@""];
    }
    return name;
}

/**
 *  通过一个有参数的方法、返回一个方法名和方法参数等组成的字典
 *
 *  @param name 方法
 *
 *  @return 方法拆解组成的字典
 */
NSDictionary *JOBMapMethod(NSString *name){
    NSArray *args = [name componentsSeparatedByString:@":"];
    return @{[args objectAtIndex:0]: @[@(args.count - 1), name]};
}

/**
 *  通过一个类、返回这个类对应的类方法、属性列表 实例方法等组成的字典
 *
 *  @param cls 类
 *
 *  @return 字典
 */
NSDictionary *JOBMapClass(Class cls){
    Class _cls = cls;
    Protocol *protocol = @protocol(JOBExport);
    NSMutableDictionary *_properties = [NSMutableDictionary dictionary];
    NSMutableDictionary *_instanceMethods = [NSMutableDictionary dictionary];
    NSMutableDictionary *_classMethods = [NSMutableDictionary dictionary];
    //一直迭代、知道迭代到最顶层父类
    for (; cls; [cls superclass]) {
        unsigned int protocolCount = 0;
        //类遵循的协议列表
        Protocol *__unsafe_unretained *protocols = class_copyProtocolList(cls, &protocolCount);
        for (unsigned int i = 0; i < protocolCount; i++) {
            //如果类遵循JOBExport协议
            if (protocol_conformsToProtocol(protocols[i], protocol)) {
                unsigned int propertyCount = 0;
                //获取协议里面的属性的列表
                objc_property_t *properties = protocol_copyPropertyList(protocols[i], &propertyCount);
                unsigned int instanceMethodCount = 0;
                //协议里面的实例方法列表
                struct objc_method_description *instanceMethods = protocol_copyMethodDescriptionList(protocols[i], YES, YES, &instanceMethodCount);
                //协议里面的类方法列表
                unsigned int classMethodCount = 0;
                struct objc_method_description *classMethods = protocol_copyMethodDescriptionList(protocols[i], YES, NO, &classMethodCount);
                
                
                for (unsigned int j = 0; j < propertyCount; j++) {
                    NSString *name = [NSString stringWithUTF8String:property_getName(properties[j])];
                    [_properties setObject:@[name] forKey:name];
                }
                for (unsigned int k = 0; k < instanceMethodCount; k++) {
                    NSString *name = [NSString stringWithUTF8String:sel_getName(instanceMethods[k].name)];
                    if (!_properties[name]) {//如果没有对应的属性，则把这个方法添加到实例方法里面。也就是说如过有对应的属性则去属性值、否则就获取对应的方法值。
                        [_instanceMethods addEntriesFromDictionary:(JOBMapMethod(name))];
                    }
                }
                for (unsigned int m = 0; m < classMethodCount; m++) {
                    NSString *name = [NSString stringWithUTF8String:sel_getName(classMethods[m].name)];
                    //字典合并在一起
                    [_classMethods addEntriesFromDictionary:(JOBMapMethod(name))];
                }
                
                free(properties);
                properties = nil;
                free(instanceMethods);
                instanceMethods = nil;
                free(classMethods);
                classMethods = nil;
            }
        }
        free(protocols);
        protocols = nil;
    }
    return @{
             @"className"       : NSStringFromClass(_cls),
             @"moduleName"      : JOBModuleNameForClass(_cls),
             @"properties"      : _properties,
             @"instanceMethods" : _instanceMethods,
             @"classMethods"    : _classMethods
             };
}

//类名和类的属性方法的映射表
static NSMutableDictionary<NSString *, NSDictionary *> *JOBModuleMap;
/**
 *  注册模型
 *
 *  @param moduleClass 模型的类名
 */
void JOBRegisterModule(Class moduleClass){
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        JOBModuleMap = [NSMutableDictionary new];
    });
    //注册模型
    NSString *name = JOBModuleNameForClass(moduleClass);
    //如果没有添加到映射列表、则手动添加
    if (name && ![JOBModuleMap objectForKey:name]) {
        [JOBModuleMap setObject:JOBMapClass(moduleClass) forKey:name];
    }
}

@interface JOBBridge ()
@property(nonatomic,strong, readonly)NSMapTable *instances;
-(void)triggerEventWithTag:(long long)tag name:(NSString *)name data:(id)data;
@end

@implementation JOBBridge
/**
 *  这里会把所有的实现JOBExport协议的模型都放入JOBModuleMap对象中。已提供给后面使用。
 */
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

-(instancetype)initWithContext:(id<JOBContext>)context{
    if (self = [super init]) {
        _context = context;
        __weak JOBBridge *weakSelf = self;
        //这里本质上就是给字典
        _instances = [NSMapTable mapTableWithKeyOptions:NSMapTableCopyIn valueOptions:NSMapTableWeakMemory];
        [_context setReceiver:^(NSString *method, NSArray * args, JOBCallback callback){
            if ([method isEqualToString:@"callClassMethod"]) {
                //通过JS调用OC的类方法
                [weakSelf callClass:args[0] method:args[1] args:args[2]];
            }else if([method isEqualToString:@"callInstanceMethod"]){
                [weakSelf callInstance:args[0] method:args[1] args:args[2]];
            }
        }];
        [self registerModules];
    }
    return self;
}

/**
 *  通过JS传入的模型、方法、参数、通过消息转发机制让对应的OC类调用这个方法
 *
 *  @param moduleName 模型名字
 *  @param method     方法名字
 *  @param args       参数列表
 */
- (void)callClass:(NSString*)moduleName method:(NSString *)method args:(NSArray *)args{
    NSString *className = JOBModuleMap[moduleName][@"className"];
    NSArray *ar = JOBModuleMap[moduleName][@"classMethods"][method];
    if (ar && [ar isKindOfClass:[NSArray class]] && [ar count] > 1) {
        SEL selector = NSSelectorFromString(ar[1]);
        Class cls = NSClassFromString(className);
        NSInvocation *anInvocation = [NSInvocation invocationWithMethodSignature:[cls methodSignatureForSelector:selector]];
        [anInvocation setSelector:selector];
        [anInvocation setTarget:[cls class]];
        [self invokeMethod:anInvocation args:args];
    }
}


/**
 *  调用实例方法
 *
 *  @param tag    方法对应的ID
 *  @param method 方法名字
 *  @param args   参数列表
 */
- (void)callInstance:(NSNumber *)tag method:(NSString *)method args:(NSArray *)args{
    JOBModuleMirror *mirror = [self.instances objectForKey:tag];
    id instance = mirror.instance;
    //TODO: check instance
    if (mirror) {
        Class cls = [instance class];
        
        NSString *moduleName = JOBModuleNameForClass(cls);
        NSArray *ar = JOBModuleMap[moduleName][@"instanceMethods"][method];
        if (ar && [ar isKindOfClass:[NSArray class]] && [ar count] > 1) {
            SEL selector = NSSelectorFromString(ar[1]);
            NSInvocation *anInvocation = [NSInvocation
                                          invocationWithMethodSignature:
                                          [cls instanceMethodSignatureForSelector:selector]];
            [anInvocation setSelector:selector];
            [anInvocation setTarget:instance];
            
            [self invokeMethod:anInvocation args:args];
        }
    }

}

/**
 *  通过消息转发来实现JS调用转换为对应的OC调用。
 *
 *  @param anInvocation 转发封装对象
 *  @param args         参数列表
 */
- (void)invokeMethod:(NSInvocation *)anInvocation args:(NSArray *)args{
    NSMethodSignature *sig = anInvocation.methodSignature;
    NSUInteger len = sig.numberOfArguments - 2;
    len = MIN(len, [args count]);
    if (len && [args count]) {
        //把参数从JS类型转换为OC类型
        for (int i = 0; i < len; i++) {
            JOBCallback val = [self convertValue:[args objectAtIndex:i]];
            [anInvocation setArgument:&val atIndex:i + 2];
        }
    }
    //转发触发
    [anInvocation invoke];
    
    if ([args count] > len && [args[len][0] intValue] == 1) {
        //Return callback
        const char* retType = [sig methodReturnType];
        JOBCallback cb = [self convertValue:args[len]];
        if (retType[0] == _C_ID) {
            id result;
            [anInvocation getReturnValue:&result];
            if (result){
                cb(@[result]);
            }
        } else {
            //TODO: check only number
            void *num = malloc(sig.methodReturnLength);
            [anInvocation getReturnValue:num];
            cb(@[@(1)]);
            free(num);
        }
    }
    
    for (int i = 0; i < len; i++) {
        if ([sig getArgumentTypeAtIndex:i+2][0] == _C_ID) {
            __unsafe_unretained id value;
            [anInvocation getArgument:&value atIndex:i+2];
            if (value) {
                CFRelease((__bridge CFTypeRef)value);
            }
        }
    }
}

/**
 *  回调类型和实例类型需要手动转换
 *
 *  @param ar 参数
 *
 *  @return 返回转换后的类型
 */
- (id)convertValue:(NSArray *)ar{
    int type = [ar[0] intValue];
    id val = ar[1];
    if (type == 1) {
        __weak JOBBridge *weakSelf  = self;
        val = ^(NSArray *args){
            [weakSelf callback:val args:args];
        };
        val = [val copy];
        CFBridgingRetain(val);
    }else if(type == 2){
        //模型实例
        NSString *className = JOBModuleMap[val[@"moduleName"]][@"className"];
        Class cls = NSClassFromString(className);
        id<JOBExport> instance = [[cls alloc]init];
        CFBridgingRetain(instance);
        return instance;
    }else{
        CFBridgingRetain(val);
    }
    return val;
}

/**
 *  通过调用JS的registerModules方法把所有的需要注册的模型注册到JS的运行上下文环境
 */
- (void)registerModules{
    [self.context callMethod:@"registerModules" arguments:@[JOBModuleMap] callback:nil];
}
/**
 *  JS回调
 *
 *  @param cbId 回调ID
 *  @param args 参数
 */
- (void)callback:(NSNumber *)cbId args:(NSArray *)args{
    [self.context callMethod:@"callback" arguments:@[cbId, args ?: [NSNull null]] callback:nil];
}

/**
 *  调用JS的mapInstance方法
 *
 *  @param instance   实例对象
 *  @param moduleName 模型名字
 */
-(void)mapInstance:(id <JOBExport>)instance moduleName:(NSString *)moduleName{
    if ([JOBModuleMirror moduleMirrorFromInstance:instance]) {
        //TODO: throw error when repeat mapping
    }
    JOBModuleMirror *mirror = [[JOBModuleMirror alloc] initWithTag:0 instance:instance bridge:self];
    [self.context callMethod:@"mapInstance" arguments:@[@(mirror.tag), moduleName] callback:nil];
}

/**
 *  通过triggerEvent方法来调用对应的JS方法
 *
 *  @param instance 实例对象
 *  @param name     实例对应的方法名字
 *  @param data     数据
 */
- (void)triggerEvent:(id <JOBExport>)instance name:(NSString *)name data:(id)data{
    //TODO: Check name and data
    JOBModuleMirror *mirror = [JOBModuleMirror moduleMirrorFromInstance:instance];
    if (mirror) {
        [self triggerEventWithTag:mirror.tag name:name data:data];
    } else {
        //TODO: Error
    }
}
- (void)triggerEventWithTag:(long long)tag name:(NSString *)name data:(id)data{
    //调用JS方法
    [self.context callMethod:@"triggerEvent" arguments:@[@(tag), name, data ?: [NSNull null]] callback:nil];
}

- (void)dealloc{
    NSLog(@"dealloc bridge");
}

@end



static long long POCModuleInstanceTag = -1;
static char POCModuleMirrorKey;
@implementation JOBModuleMirror{
}

@synthesize bridge = _bridge, instance = _instance;

+(instancetype)moduleMirrorFromInstance:(id<JOBExport>)instance{
    return objc_getAssociatedObject(instance, &POCModuleMirrorKey);
}
/**
 *  通过关联对象把实例对象和对应的Key关联起来
 *
 *  @param tag      对应的tag
 *  @param instance 实例对象
 *  @param bridge   桥接对象
 *
 *  @return
 */
-(id)initWithTag:(long long)tag instance:(id<JOBExport>)instance bridge:(JOBBridge *)bridge{
    if (self = [super init]) {
        _bridge = bridge;
        if (tag == 0) {
            tag = POCModuleInstanceTag --;
        }
        _tag = tag;
        _instance = instance;
        objc_setAssociatedObject(instance, &POCModuleMirrorKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        //把实例对象加入instances里面
        [self.bridge.instances setObject:self forKey:@(self.tag)];
        if (tag > 0) {
            [self.bridge triggerEventWithTag:self.tag name:@"load" data:nil];
        }
    }
    return self;
}

- (void)dealloc{
    [self.bridge triggerEventWithTag:self.tag name:@"unload" data:nil];
    [self.bridge.instances removeObjectForKey:@(self.tag)];
    NSLog(@"dealloc module %@", @(self.tag));
}

@end

