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
#import <AVFoundation/AVAudioSession.h>

@implementation OpenWebRTC

- (instancetype)init
{
    // This class should not be instantiated.
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

+ (void)initOpenWebRTC
{
    if (self == [OpenWebRTC class]) {
        static BOOL isInitialized = NO;
        if (!isInitialized) {
            owr_init(NULL);
            owr_run_in_background();

            NSError* theError = nil;
            AVAudioSession *myAudioSession = [AVAudioSession sharedInstance];
            BOOL result = [myAudioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&theError];

            if (!result) {
                NSLog(@"[OpenWebRTC] ERROR! AVAudioSession setCategory failed");
            }

            result = [myAudioSession setActive:YES error:&theError];
            if (!result) {
                NSLog(@"[OpenWebRTC] ERROR! AVAudioSession setActive failed");
            }

            NSLog(@"[OpenWebRTC] initialized correctly!");
        }

        isInitialized = YES;
    }
}

@end

