//
//  InternalSchemeHandler.m
//  restoreHistory
//
//  Created by Xiaoxueyuan on 2021/5/5.
//

#import "InternalSchemeHandler.h"
#import <WebKit/WKURLSchemeTask.h>


@implementation InternalSchemeHandler
- (void)webView:(WKWebView *)webView startURLSchemeTask:(id<WKURLSchemeTask>)urlSchemeTask {
    NSURL *url = urlSchemeTask.request.URL;
    NSLog(@"%@", url.path);
    NSLog(@"%@", url.query);
    NSData *data = nil;
    NSURL *rURL = nil;
    if ([url.path isEqualToString:@"/restore"]) {
//        rURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:5555/restore?%@", url.query]];
//        NSString *query = url.query;
        NSString *htmlFilePath = [[NSBundle mainBundle] pathForResource:@"RestoreSession" ofType:@"html"];
        NSString *html = [[NSString stringWithContentsOfFile:htmlFilePath encoding:NSUTF8StringEncoding error:nil] stringByReplacingOccurrencesOfString:@"{{$pageUrl}}" withString:url.absoluteString];
        
        data = [html dataUsingEncoding:NSUTF8StringEncoding];
    } else if ([url.path isEqualToString:@"/history"]) {
        NSString *query = url.query;
        NSString *targetURL = [query stringByReplacingOccurrencesOfString:@"url=" withString:@""];
        rURL = [NSURL URLWithString:targetURL];
        NSString *htmlString = [NSString stringWithFormat:@"<!DOCTYPE html><html><head><script>location.replace('%@');</script></head></html>", targetURL];
        data = [htmlString dataUsingEncoding:NSUTF8StringEncoding];
    }
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:rURL MIMEType:@"text/html" expectedContentLength:-1 textEncodingName:@"utf-8"];
    [urlSchemeTask didReceiveResponse:response];
    [urlSchemeTask didReceiveData:data];
    [urlSchemeTask didFinish];
    
}
    
- (void)webView:(WKWebView *)webView stopURLSchemeTask:(id <WKURLSchemeTask>)urlSchemeTask {

}

@end
