//
//  OpenWebRTC.m
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

#import "OpenWebRTC.h"

static gpointer owr_run(GMainLoop *main_loop)
{
    g_return_val_if_fail(main_loop, NULL);
    NSLog(@"[OpenWebRTC] initialized");
    g_main_loop_run(main_loop);
    return NULL;
}

@implementation OpenWebRTC

- (instancetype)init
{
    // This class should not be instantiated.
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

+ (void)initialize
{
    if (self == [OpenWebRTC class]) {
        static BOOL isInitialized = NO;
        if (!isInitialized) {
            GMainContext *main_context;
            GMainLoop *main_loop;

            main_context = g_main_context_default();
            owr_init_with_main_context(main_context);
            main_loop = g_main_loop_new(NULL, FALSE);
            g_thread_new("owr_main_loop", (GThreadFunc) owr_run, main_loop);
        }
        isInitialized = YES;
    }
}

@end

