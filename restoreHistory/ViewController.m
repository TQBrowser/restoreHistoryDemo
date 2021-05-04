//
//  ViewController.m
//  restoreHistory
//
//  Created by Xiaoxueyuan on 2021/5/4.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import <GCDWebServer/GCDWebServer.h>
#import <GCDWebServer/GCDWebServerDataResponse.h>
#import <GCDWebServer/GCDWebServerURLEncodedFormRequest.h>

@interface ViewController () <GCDWebServerDelegate, WKUIDelegate, WKScriptMessageHandler>

@property (weak, nonatomic) IBOutlet UIView *wkContainer;

@property (nonatomic, strong) WKWebView *webView;

@property (nonatomic, strong) GCDWebServer *localServer;

@property (nonatomic, strong) WKUserContentController* userContentController;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self startLocalServer];
    
    _userContentController = [[WKUserContentController alloc] init];
    [_userContentController addScriptMessageHandler:self name:@"sessionRestoreHelper"];
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.userContentController = _userContentController;
    _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    _webView.UIDelegate = self;
    [_wkContainer addSubview:_webView];
    _webView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [_webView.leadingAnchor constraintEqualToAnchor:_wkContainer.leadingAnchor],
        [_webView.topAnchor constraintEqualToAnchor:_wkContainer.topAnchor],
        [_webView.trailingAnchor constraintEqualToAnchor:_wkContainer.trailingAnchor],
        [_webView.bottomAnchor constraintEqualToAnchor:_wkContainer.bottomAnchor],
    ]];
    
    
    
    
    NSArray *urls = @[@"https://xw.qq.com", @"https://m.hupu.com", @"https://www.taobao.com", @"https://www.youtube.com", @"https://www.baidu.com"];
    NSDictionary *params = @{@"urls": urls, @"currentPage": @(0)};
    
    NSString *paramsStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:params options:0 error:nil] encoding:NSUTF8StringEncoding];
    NSURLComponents *urlComponents = [[NSURLComponents alloc] init];
    [urlComponents setScheme:@"http"];
    [urlComponents setHost:@"localhost"];
    [urlComponents setPort:@5555];
    [urlComponents setQuery:[NSString stringWithFormat:@"params=%@", paramsStr]];
    [urlComponents setPath:@"/restore"];
    NSLog(@"%@", urlComponents.URL);
    [_webView loadRequest:[NSURLRequest requestWithURL:urlComponents.URL]];
    
}

- (IBAction)goBack:(id)sender {
    [_webView goBack];
}

- (IBAction)goForward:(id)sender {
    [_webView goForward];
}

- (void)startLocalServer{
    _localServer = [[GCDWebServer alloc] init];
    _localServer.delegate = self;

    [_localServer addHandlerForMethod:@"GET"
                            pathRegex:@"/history"
                         requestClass:[GCDWebServerURLEncodedFormRequest class]
                         processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        NSDictionary *query = request.query;
        GCDWebServerDataResponse *response = [GCDWebServerDataResponse responseWithRedirect:[NSURL URLWithString:query[@"url"]] permanent:NO];
        return response;
    }];
    
    [_localServer addHandlerForMethod:@"GET"
                            pathRegex:@"/restore"
                         requestClass:[GCDWebServerURLEncodedFormRequest class]
                         processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        NSString *htmlFilePath = [[NSBundle mainBundle] pathForResource:@"RestoreSession" ofType:@"html"];
        NSString *html = [NSString stringWithContentsOfFile:htmlFilePath encoding:NSUTF8StringEncoding error:nil];
        NSLog(@"html:%@", html);
        GCDWebServerDataResponse *response = [GCDWebServerDataResponse responseWithHTML:html];
        return response;
    }];
    
    
    //设置监听端口
    [_localServer startWithPort:5555 bonjourName:@"bonjourNNN"];
    NSLog(@"Visit %@ in your web browser", _localServer.serverURL);
}

- (void)webServerDidStart:(GCDWebServer *)server{
    NSLog(@"本地服务启动成功");
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    NSLog(@"Alert: %@", message);
    completionHandler();
}

- (IBAction)buttonAction:(id)sender {
    WKBackForwardList *backForwardList = _webView.backForwardList;
    NSLog(@"back list:");
    for (WKBackForwardListItem *backForwardItem in backForwardList.backList) {
        NSLog(@"title:%@  url:%@", backForwardItem.title, backForwardItem.URL);
    }
    NSLog(@"forward list:");
    for (WKBackForwardListItem *backForwardItem in backForwardList.forwardList) {
        NSLog(@"title:%@  url:%@", backForwardItem.title, backForwardItem.URL);
    }
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSDictionary *params = message.body;
    if ([params[@"name"] isEqualToString:@"didRestoreSession"]) {
//        [_webView reload];
    }
}

@end