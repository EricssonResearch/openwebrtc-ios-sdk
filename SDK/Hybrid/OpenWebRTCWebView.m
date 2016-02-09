//
//  OpenWebRTCWebView.m
//
//  Copyright (c) 2014, Ericsson AB.
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

#import "OpenWebRTCWebView.h"

@interface OpenWebRTCWebView ()  <WKUIDelegate>

@end

@implementation OpenWebRTCWebView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        resourceCount = 0;
        resourceCompletedCount = 0;

        [self setUIDelegate:self];
    }
    return self;
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    if ([message rangeOfString:@"owr-message:video-rect"].location == 0) {
        CGFloat sf = 1.0 / ([UIScreen mainScreen].scale);
        NSArray *messageComps = [message componentsSeparatedByString:@","];
        NSString *tag = [messageComps objectAtIndex:2];
        CGFloat x = [[messageComps objectAtIndex:3] floatValue];
        CGFloat y = [[messageComps objectAtIndex:4] floatValue];
        CGFloat width = [[messageComps objectAtIndex:5] floatValue] - x;
        CGFloat height = ([[messageComps objectAtIndex:6] floatValue] - y);
        int rotation = [[messageComps objectAtIndex:7] intValue];
        CGRect newRect = CGRectMake(x * sf, y * sf, width * sf, height * sf);
        [self.owrDelegate newVideoRect:newRect rotation:rotation tag:tag];

        completionHandler();
    } else {
        if ([self.owrDelegate isKindOfClass:[UIViewController class]]) {
            UIViewController *parent = (UIViewController *)self.owrDelegate;
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert!"
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * action) {
                                                        completionHandler();
                                                    }]];
            [parent presentViewController:alert animated:YES completion:nil];
        } else {
            completionHandler();
        }
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:webView.URL.host
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
        completionHandler(YES);
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action) {
        completionHandler(NO);
    }]];

    [self maybePresentAlert:alertController];
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString *))completionHandler {

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt
                                                                             message:webView.URL.host
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = defaultText;
    }];

    [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
        NSString *input = ((UITextField *)alertController.textFields.firstObject).text;
        completionHandler(input);
    }]];

    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action) {
        completionHandler(nil);
    }]];

    [self maybePresentAlert:alertController];
}

- (void)maybePresentAlert:(UIAlertController *)alertController
{
    if ([self.owrDelegate isKindOfClass:[UIViewController class]]) {
        UIViewController *parent = (UIViewController *)self.owrDelegate;
        [parent presentViewController:alertController animated:YES completion:nil];
    }
}

@end