//
//  OpenWebRTCNativeHandler.h
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

#import <Foundation/Foundation.h>
#import "OpenWebRTCVideoView.h"
#import "OpenWebRTCSettings.h"

@protocol OpenWebRTCNativeHandlerDelegate <NSObject>

- (void)answerGenerated:(NSDictionary *)answer;
- (void)offerGenerated:(NSDictionary *)offer;
- (void)candidateGenerate:(NSString *)candidate;

/**
 * Format of sources:
 * [{'name':xxx, 'source':xxx, 'mediaType':'audio' or 'video'}, {}, ...]
 */
- (void)gotLocalSources:(NSArray *)sources;
- (void)gotRemoteSource:(NSDictionary *)source;

@end

@interface OpenWebRTCNativeHandler : NSObject

@property (nonatomic, weak) id <OpenWebRTCNativeHandlerDelegate> delegate;
@property (nonatomic, strong) OpenWebRTCSettings *settings;

- (instancetype)initWithDelegate:(id <OpenWebRTCNativeHandlerDelegate>)delegate;

- (void)setSelfView:(OpenWebRTCVideoView *)selfView;
- (void)removeSelfView;
- (void)setRemoteView:(OpenWebRTCVideoView *)remoteView;
- (void)removeRemoteView;
- (void)addSTUNServerWithAddress:(NSString *)address port:(NSInteger)port;
- (void)addTURNServerWithAddress:(NSString *)address port:(NSInteger)port username:(NSString *)username password:(NSString *)password isTCP:(BOOL)isTCP;

- (void)startGetCaptureSourcesForAudio:(BOOL)audio video:(BOOL)video;
- (void)initiateCall;
- (void)terminateCall;
- (void)enableTrickleICE;

- (void)handleOfferReceived:(NSString *)offer;
- (void)handleAnswerReceived:(NSString *)answer;
- (void)handleRemoteCandidateReceived:(NSDictionary *)candidate;

- (void)setVideoCaptureSourceByName:(NSString *)name;
- (void)videoView:(OpenWebRTCVideoView *)videoView setVideoRotation:(NSInteger)degrees;
- (void)videoView:(OpenWebRTCVideoView *)videoView setMirrored:(BOOL)isMirrored;
- (NSInteger)rotationForVideoView:(OpenWebRTCVideoView *)videoView;

@end