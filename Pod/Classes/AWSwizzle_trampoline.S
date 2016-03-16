//
//  AWSwizzle_trampoline.S
//
//  Created by Victor Pavlychko on 3/15/16.
//  Copyright © 2016 address.wtf. All rights reserved.
//

.text
.align 4
.globl __awSwizzleProxy_trampoline
.globl __awSwizzleProxy_trampoline_stret

// struct _AWSwizzleProxy
// {                                        //             32bit |  64bit
//     Class               isa_;            // self + 0 |      0 |      0
//     IMP                 dispatcher_;     // self + 1 |      4 |      8
//     void               *target_;         // self + 2 |      8 |     16
//     SEL                 selector_;       // self + 3 |     12 |     24
//     struct objc_super   super_;          // self + 4 |     16 |     32
// };

#if defined(__arm__)

// argument order:  [stret],    self,    _cmd, ...
// regular layout:      N/A,      r0,      r1, ...
//   stret layout:       r0,      r1,      r2, ...

__awSwizzleProxy_trampoline:
    mov     r12,        r0                  // save original `self` in scratch register `r12`
    ldr     r0,         [r12, #8]           // load target `self`
    ldr     r1,         [r12, #12]          // load target `_cmd`
    ldr     r12,        [r12, #4]           // load target function
    bx      r12                             // jump to destination

__awSwizzleProxy_trampoline_stret:
    mov     r12,        r1                  // save original `self` in scratch register `r12`
    ldr     r1,         [r12, #8]           // load target `self`
    ldr     r2,         [r12, #12]          // load target `_cmd`
    ldr     r12,        [r12, #4]           // load target function
    bx      r12                             // jump to destination

#elif defined(__arm64__)

// argument order:  [stret],    self,    _cmd, ...
// regular layout:      N/A,      x0,      x1, ...
//   stret layout:       x0,      x1,      x2, ...

__awSwizzleProxy_trampoline:
    mov     x12,        x0                  // save original `self` in scratch register `x12`
    ldr     x0,         [x12, #16]          // load target `self`
    ldr     x1,         [x12, #24]          // load target `_cmd`
    ldr     x12,        [x12, #8]           // load target function
    br      x12                             // jump to destination

__awSwizzleProxy_trampoline_stret:
    mov     x12,        x1                  // save original `self` in scratch register `x12`
    ldr     x1,         [x12, #16]          // load target `self`
    ldr     x2,         [x12, #24]          // load target `_cmd`
    ldr     x12,        [x12, #8]           // load target function
    br      x12                             // jump to destination

#elif defined(__i386__)

// argument order:  [stret],    self,    _cmd, ...
// regular layout:      N/A,   esp+4,   esp+8, ...
//   stret layout:    esp+4,   esp+8,  esp+12, ...

__awSwizzleProxy_trampoline:
    movl    4(%esp),    %eax                // save original `self` in scratch register `eax`
    movl    8(%eax),    %ebx                // load target `self` in scratch register `ebx`
    movl    %ebx,       4(%esp)             // store target `self`
    movl    12(%eax),   %ebx                // load target `_cmd` in scratch register `ebx`
    movl    %ebx,       8(%esp)             // store target `_cmd`
    jmpl    *4(%eax)                        // jump to destination

__awSwizzleProxy_trampoline_stret:
    movl    8(%esp),    %eax                // save original `self` in scratch register `eax`
    movl    8(%eax),    %ebx                // load target `self` in scratch register `ebx`
    movl    %ebx,       8(%esp)             // store target `self`
    movl    12(%eax),   %ebx                // load target `_cmd` in scratch register `ebx`
    movl    %ebx,       12(%esp)            // store target `_cmd`
    jmpl    *4(%eax)                        // jump to destination

#elif defined(__x86_64__)

// argument order:  [stret],    self,    _cmd, ...
// regular layout:      N/A,     rdi,     rsi, ...
//   stret layout:      rdi,     rsi,     rdx, ...

__awSwizzleProxy_trampoline:
    movq    %rdi,       %r10                // save original `self` in scratch register `r10`
    movq    16(%r10),   %rdi                // load target `self`
    movq    24(%r10),   %rsi                // load target `_cmd`
    jmpq    *8(%r10)                        // jump to destination

__awSwizzleProxy_trampoline_stret:
    movq    %rsi,       %r10                // save original `self` in scratch register `r10`
    movq    16(%r10),   %rsi                // load target `self`
    movq    24(%r10),   %rdx                // load target `_cmd`
    jmpq    *8(%r10)                        // jump to destination

#else

#error Unsupported architecture

#endif
