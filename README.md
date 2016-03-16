# AWSwizzle

[![CI Status](http://img.shields.io/travis/Victor Pavlychko/AWSwizzle.svg?style=flat)](https://travis-ci.org/Victor Pavlychko/AWSwizzle)
[![Version](https://img.shields.io/cocoapods/v/AWSwizzle.svg?style=flat)](http://cocoapods.org/pods/AWSwizzle)
[![License](https://img.shields.io/cocoapods/l/AWSwizzle.svg?style=flat)](http://cocoapods.org/pods/AWSwizzle)
[![Platform](https://img.shields.io/cocoapods/p/AWSwizzle.svg?style=flat)](http://cocoapods.org/pods/AWSwizzle)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

```objc
@import AWSwizzle;

@implementation NSObject (AWSwizzleTest)

+ (void)load
{
    [self aw_swizzleWithPrefix:"awSwizzleTest_"];
}

- (NSString *)awSwizzleTest_description
{
    [NSString stringWithFormat:@"swizzled >>> %@ <<< swizzled", [awSwizzleSuper description]];
}

@end
```

## Requirements

## Installation

AWSwizzle is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "AWSwizzle"
```

## Author

Victor Pavlychko, victor.pavlychko@gmail.com

## License

AWSwizzle is available under the MIT license. See the LICENSE file for more info.
