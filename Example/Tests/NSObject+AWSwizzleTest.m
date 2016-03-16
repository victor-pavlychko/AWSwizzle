//
//  NSObject+AWSwizzleTest.m
//  AWSwizzle
//
//  Created by Victor Pavlychko on 3/16/16.
//  Copyright © 2016 Victor Pavlychko. All rights reserved.
//

#import "NSObject+AWSwizzleTest.h"

@import AWSwizzle;

@implementation NSObject (AWSwizzleTest)

+ (void)load
{
    [self aw_swizzleWithPrefix:"awSwizzleTest_"];
}

- (NSString *)awSwizzleTest_description
{
    return [NSString stringWithFormat:@"swizzled >>> %@ <<< swizzled", [awSwizzleSuper description]];
}

@end
