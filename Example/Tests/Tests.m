//
//  AWSwizzleTests.m
//  AWSwizzleTests
//
//  Created by Victor Pavlychko on 03/16/2016.
//  Copyright (c) 2016 Victor Pavlychko. All rights reserved.
//

@import AWSwizzle;

// https://github.com/Specta/Specta

SpecBegin(InitialSpecs)

describe(@"static swizzling with category", ^{
    
    it(@"can swizzle description", ^{
        NSObject *obj = [[NSObject alloc] init];
        NSString *str = [obj description];
        expect(str).to.beginWith(@"swizzled >>> ");
        expect(str).to.endWith(@" <<< swizzled");
    });

});

SpecEnd
