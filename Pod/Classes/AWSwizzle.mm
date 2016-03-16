//
//  AWSwizzle.mm
//
//  Created by Victor Pavlychko on 3/15/16.
//  Copyright © 2016 address.wtf. All rights reserved.
//

#import "AWSwizzle.h"

#import <objc/runtime.h>
#import <objc/message.h>

#include <map>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Data Layouts and Forwards -

struct _AWSwizzleInfo
{
    SEL                 selector_;
    IMP                 imp_;
    Class               super_;
    bool                exists_;
};

struct _AWSwizzleProxy
{
    Class               isa_;
    IMP                 dispatcher_;
    void               *target_;
    SEL                 selector_;
    struct objc_super   super_;
};

extern "C"  void            _awSwizzleProxy_trampoline(void);
extern "C"  void            _awSwizzleProxy_trampoline_stret(void);
static      Class           _awSwizzleProxy_class();
static      id _Nullable    _awSwizzleProxy_new(_AWSwizzleInfo *swizzleInfo, id target);
extern "C"  id _Nullable    _awSwizzleProxy_find(id self_, SEL selector_, void *pc);

#pragma mark - Swizzle Dispatch Map -

/*!
    Original implementation mapping

    @discussion
        This can't be `static` or initialized in `+load` because of unpredicted
        execution order, so we just lazily initialize on first access.
 
        Note using `std::greater<>` ordering scheme to allow `lower_bound`
        perform efficient lookup for all in-function addresses.
 */
static std::map<uintptr_t, _AWSwizzleInfo, std::greater<uintptr_t>> *_swizzleInfoMap()
{
    static std::map<uintptr_t, _AWSwizzleInfo, std::greater<uintptr_t>> *map = nullptr;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = new std::map<uintptr_t, _AWSwizzleInfo, std::greater<uintptr_t>>();
    });
    
    return map;
}

#pragma mark - Swizzle Proxy Implementation and Lookup -

Class _awSwizzleProxy_class()
{
    static Class cls = Nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cls = objc_allocateClassPair([NSProxy class], "_AWSwizzleProxy", 0);
        class_addIvar(cls, "data_", sizeof(_AWSwizzleProxy), 0, @encode(_AWSwizzleProxy));
        objc_registerClassPair(cls);
    });
    
    return cls;
}

id _Nullable _awSwizzleProxy_new(_AWSwizzleInfo *swizzleInfo, id target)
{
    if (!swizzleInfo->exists_)
    {
        if (!(swizzleInfo->exists_ = !!class_getInstanceMethod(swizzleInfo->super_, swizzleInfo->selector_)))
        {
            return nil;
        }
    }

    id result = [_awSwizzleProxy_class() alloc];
    _AWSwizzleProxy *proxy = (__bridge _AWSwizzleProxy *)result;
    proxy->dispatcher_ = swizzleInfo->imp_;
    proxy->target_ = swizzleInfo->super_ ? (void *)&proxy->super_ : (__bridge void *)target;
    proxy->selector_ = swizzleInfo->selector_;
    proxy->super_.receiver = target;
    proxy->super_.super_class = swizzleInfo->super_;
    return result;
}

id _Nullable _awSwizzleProxy_find(id self_, SEL selector_, void *pc)
{
    auto swizzleInfoMap = _swizzleInfoMap();
    auto swizzleInfoIterator = swizzleInfoMap->lower_bound((uintptr_t)pc);
    if (swizzleInfoIterator == swizzleInfoMap->end())
    {
        return nil;
    }

    auto swizzleInfo = &swizzleInfoIterator->second;
    if (swizzleInfo->selector_ != selector_)
    {
        return nil;
    }

    return _awSwizzleProxy_new(swizzleInfo, self_);
}

#pragma mark - NSObject Swizzling -

@implementation NSObject (AWSwizzle)

+ (void)aw_swizzleWithPrefix:(const char *)prefix
{
    NSParameterAssert(prefix && *prefix);

    size_t prefixLength = strlen(prefix);

    unsigned int methodCount = 0;
    Method *methodList = class_copyMethodList(self, &methodCount);
    if (!methodList)
    {
        return;
    }

    for (int i = 0; i < methodCount; ++i)
    {
        SEL replacementSelector = method_getName(methodList[i]);
        const char *replacementSelectorName = sel_getName(replacementSelector);

        if (strncmp(replacementSelectorName, prefix, prefixLength))
        {
            continue;
        }
        
        const char *originalSelectorName = replacementSelectorName + prefixLength;
        SEL originalSelector = sel_getUid(originalSelectorName);

        [self aw_swizzleSelector:originalSelector
                    withSelector:replacementSelector];
    }

    free(methodList);
}

+ (void *)aw_swizzleSelector:(SEL)originalSelector
                withSelector:(SEL)replacementSelector
{
    NSParameterAssert(originalSelector);
    NSParameterAssert(replacementSelector);
    
    Method replacementMethod = class_getInstanceMethod(self, replacementSelector);
    NSParameterAssert(replacementMethod);

    const char *typeEncoding = method_getTypeEncoding(replacementMethod);
    NSParameterAssert(typeEncoding);

    IMP replacementImp = method_getImplementation(replacementMethod);
    NSParameterAssert(replacementImp);
    
    return [self aw_swizzleSelector:originalSelector
              suggestedTypeEncoding:typeEncoding
                       withFunction:replacementImp];
}

+ (void *)aw_swizzleSelector:(SEL)originalSelector
                fromProtocol:(Protocol *)protocol
                withFunction:(IMP)replacementImp
{
    NSParameterAssert(originalSelector);
    NSParameterAssert(protocol);
    NSParameterAssert(replacementImp);

    // retrieve method type encoding from protocol,
    // start with more probable options first
    const char *typeEncoding = NULL
        ?: protocol_getMethodDescription(protocol, originalSelector,  NO, YES).types    // optional instance method
        ?: protocol_getMethodDescription(protocol, originalSelector, YES, YES).types    // required instance method
        ?: protocol_getMethodDescription(protocol, originalSelector,  NO,  NO).types    // optional class method
        ?: protocol_getMethodDescription(protocol, originalSelector, YES,  NO).types    // required class method
    ;

    NSParameterAssert(typeEncoding);

    return [self aw_swizzleSelector:originalSelector
              suggestedTypeEncoding:typeEncoding
                       withFunction:replacementImp];
}

+ (void *)aw_swizzleSelector:(SEL)originalSelector
       suggestedTypeEncoding:(nullable const char *)suggestedTypeEncoding
                withFunction:(IMP)replacementImp
{
    NSParameterAssert(originalSelector);
    NSParameterAssert(replacementImp);

    _AWSwizzleInfo result;
    result.selector_ = originalSelector;

    Method originalMethod = class_getInstanceMethod(self, originalSelector);
    NSParameterAssert(suggestedTypeEncoding || originalMethod);

    const char *typeEncoding = suggestedTypeEncoding ?: method_getTypeEncoding(originalMethod);
    NSParameterAssert(typeEncoding);

    bool isStret;
    switch (*typeEncoding)
    {
        case '{': // structs
        case '(': // unions
            isStret = true;

        default:
            isStret = false;
    }

    // add method to _AWSwizzleProxy class
    class_addMethod(_awSwizzleProxy_class(),
                    originalSelector,
                    isStret ? (IMP)_awSwizzleProxy_trampoline_stret : (IMP)_awSwizzleProxy_trampoline,
                    typeEncoding);

    // first try adding method and use super call for next implementation
    if (class_addMethod(self, originalSelector, replacementImp, typeEncoding))
    {
        result.imp_ = isStret ? (IMP)objc_msgSendSuper_stret : (IMP)objc_msgSendSuper;
        result.super_ = class_getSuperclass(self);
        result.exists_ = !!originalMethod;
    }
    // hook original method if add fails, use saved implementation for next call
    else
    {
        result.imp_ = method_setImplementation(originalMethod, replacementImp);
        result.super_ = Nil;
        result.exists_ = true;
    }

    _swizzleInfoMap()->emplace((uintptr_t)replacementImp, result);

    return (void*)replacementImp;
}

@end

NS_ASSUME_NONNULL_END
