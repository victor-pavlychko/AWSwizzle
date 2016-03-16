//
//  AWSwizzle.h
//
//  Created by Victor Pavlychko on 3/15/16.
//  Copyright © 2016 address.wtf. All rights reserved.
//

#import <Foundation/Foundation.h>

__BEGIN_DECLS

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Accessing original implementation -

/*!
 * Autodetect proxy to invoke next implementation
 */
#define awSwizzleSuper \
    ((__typeof(self))_awSwizzleProxy_find(self, _cmd, ({ __AW_ ## __LINE__: ; &&__AW_ ## __LINE__; })))

#pragma mark - Hooking API -

@interface NSObject (AWSwizzle)

/*!
    @abstract Automatically hook all methods with specified prefix

    Automatically hook all methods with specified prefix,
    original methods are chosen by discarding prefix.
 
    Original methods are not required to be implemented when installing
    hook. Next implementation proxy will remain `nil` until implementaion
    appears in parent class.
 
    @param prefix
        common prefix to find methods, for example "aw_"
 */
+ (void)aw_swizzleWithPrefix:(const char *)prefix;

/*!
    Hook `originalSelector` method with a replacement from `replacementSelector` method.

    @param originalSelector
        method selector to install hook for, mathod may be not implemented

    @param replacementSelector
        method selector to use as a hook, must be implemented
 */
+ (void *)aw_swizzleSelector:(SEL)originalSelector
                withSelector:(SEL)replacementSelector;

/*!
    Hook `originalSelector` method defined in `protocol` with `replacementImp` function code.

    @param originalSelector
        method selector to install hook for, mathod may be not implemented

    @param protocol
        protocol defining method

    @param replacementImp
        method implementation to use as a hook
 */
+ (void *)aw_swizzleSelector:(SEL)originalSelector
                fromProtocol:(Protocol *)protocol
                withFunction:(IMP)replacementImp;

/*!
    Hook `originalSelector` method with `replacementImp` function code.

    @param originalSelector
        method selector to install hook for, mathod may be not implemented

    @param suggestedTypeEncoding
        type encoding to user for method, optional

    @param replacementImp
        method implementation to use as a hook
 */
+ (void *)aw_swizzleSelector:(SEL)originalSelector
       suggestedTypeEncoding:(nullable const char *)suggestedTypeEncoding
                withFunction:(IMP)replacementImp;

@end

#pragma mark - Retrieving original accessor proxy -

/*!
    Retrieves proxy to call next implementation
 
    @param self_
        object instance

    @param selector_
        original selector, i.e. _cmd

    @param pc
        hook implementation address
 */
id _Nullable _awSwizzleProxy_find(id self_, SEL selector_, void *pc);

NS_ASSUME_NONNULL_END

__END_DECLS
