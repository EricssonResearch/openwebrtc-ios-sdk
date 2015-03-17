//
//  OpenWebRTCUtils.m
//
//  Copyright (c) 2015, Ericsson AB.
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice, this
//  list of conditions and the following disclaimer in the documentation and/or other
//  materials provided with the distribution.

//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
//  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
//  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
//  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
//  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
//  OF SUCH DAMAGE.
//

#import "OpenWebRTCUtils.h"

@import JavaScriptCore;

static JSContext *_context;

@implementation OpenWebRTCUtils

#pragma mark - Internal methods

+ (JSContext *)context
{
    @synchronized (_context) {
        if (_context == nil) {
            _context = [[JSContext alloc] init];

            NSString *path = [[NSBundle mainBundle] pathForResource:@"sdp" ofType:@"js"];
            if (path) {
                NSError *error;
                NSURL *fileURL = [NSURL fileURLWithPath:path];
                NSString *js = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
                if (js && !error) {
                    [_context evaluateScript:js];
                } else {
                    NSLog(@"[OpenWebRTCUtils] WARNING! Could not open sdp.js");
                }
            } else {
                NSLog(@"[OpenWebRTCUtils] WARNING! Could not find sdp.js");
            }

            _context.exceptionHandler = ^(JSContext *context, JSValue *exception) {
                NSLog(@"[OpenWebRTCUtils] JavaScript Error: %@", exception);
            };
        }
    }
    return _context;
}

#pragma mark Public methods

+ (NSDictionary *)parseSDPFromString:(NSString *)sdpString
{
    JSValue *parseFunction = [[[OpenWebRTCUtils context] objectForKeyedSubscript:@"SDP"] objectForKeyedSubscript:@"parse"];
    JSValue *result = [parseFunction callWithArguments:@[sdpString]];
    return [result toDictionary];
}

+ (NSString *)generateSDPFromObject:(NSDictionary *)sdpObject
{
    JSValue *generateFunction = [[[OpenWebRTCUtils context] objectForKeyedSubscript:@"SDP"] objectForKeyedSubscript:@"generate"];
    JSValue *result = [generateFunction callWithArguments:@[sdpObject]];
    return [result toString];
}

@end