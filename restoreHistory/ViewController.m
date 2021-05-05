//
//  ViewController.m
//  restoreHistory
//
//  Created by Xiaoxueyuan on 2021/5/4.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "InternalSchemeHandler.h"

@interface ViewController () <WKUIDelegate, WKScriptMessageHandler>

@property (weak, nonatomic) IBOutlet UIView *wkContainer;

@property (nonatomic, strong) WKWebView *webView;

@property (nonatomic, strong) WKUserContentController* userContentController;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *goBackButtonItem;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *goForwardButtonItem;

@property (nonatomic, strong) UIProgressView *progressView;

@property (weak, nonatomic) IBOutlet UIToolbar *toolBar;

@property (nonatomic, strong) UIView *loadingView;

@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _progressView = [[UIProgressView alloc] init];
    _progressView.translatesAutoresizingMaskIntoConstraints = NO;
    [_toolBar addSubview:_progressView];
    [NSLayoutConstraint activateConstraints:@[
        [_progressView.leadingAnchor constraintEqualToAnchor:_toolBar.leadingAnchor],
        [_progressView.trailingAnchor constraintEqualToAnchor:_toolBar.trailingAnchor],
        [_progressView.topAnchor constraintEqualToAnchor:_toolBar.topAnchor],
        [_progressView.heightAnchor constraintEqualToConstant:3],
    ]];
    
    _userContentController = [[WKUserContentController alloc] init];
    [_userContentController addScriptMessageHandler:self name:@"sessionRestoreHelper"];
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.userContentController = _userContentController;
    [config setURLSchemeHandler:[[InternalSchemeHandler alloc] init] forURLScheme:@"internal"];
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
    
    [_webView addObserver:self forKeyPath:@"canGoBack" options:NSKeyValueObservingOptionNew context:nil];
    [_webView addObserver:self forKeyPath:@"canGoForward" options:NSKeyValueObservingOptionNew context:nil];
    [_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    [_webView addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionNew context:nil];
    
    NSArray *urls = @[
        @"https://xw.qq.com",
        @"https://m.hupu.com",
        @"https://www.taobao.com",
        @"https://www.bilibili.com/",
        @"https://www.baidu.com",
        @"https://www.github.com"
    ];
    
    NSDictionary *params = @{@"urls": urls, @"currentPage": @(-1)};
    
    NSString *paramsStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:params options:0 error:nil] encoding:NSUTF8StringEncoding];
    NSURLComponents *urlComponents = [[NSURLComponents alloc] init];
    [urlComponents setScheme:@"internal"];
    [urlComponents setHost:@"local"];
    [urlComponents setQuery:[NSString stringWithFormat:@"params=%@", paramsStr]];
    [urlComponents setPath:@"/restore"];
    NSLog(@"%@", urlComponents.URL);
    [_webView loadRequest:[NSURLRequest requestWithURL:urlComponents.URL]];
    
    _loadingView = [[UIView alloc] init];
    _loadingView.backgroundColor = UIColor.blackColor;
    _loadingView.translatesAutoresizingMaskIntoConstraints = NO;
    _loadingView.clipsToBounds = YES;
    _loadingView.layer.cornerRadius = 5;
    
    _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    _indicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    _indicatorView.color = UIColor.whiteColor;
    [_loadingView addSubview:_indicatorView];
    [self.view addSubview:_loadingView];

    _indicatorView.hidesWhenStopped = YES;
    [NSLayoutConstraint activateConstraints:@[
        [_indicatorView.centerXAnchor constraintEqualToAnchor:_loadingView.centerXAnchor],
        [_indicatorView.centerYAnchor constraintEqualToAnchor:_loadingView.centerYAnchor],
        
        [_loadingView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_loadingView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        
        [_loadingView.widthAnchor constraintEqualToConstant:100],
        [_loadingView.heightAnchor constraintEqualToConstant:100],
        
    ]];
    
}

- (IBAction)goBack:(id)sender {
    [_webView goBack];
}

- (IBAction)goForward:(id)sender {
    [_webView goForward];
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

- (IBAction)cancel:(id)sender {
    [_webView stopLoading];
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSDictionary *params = message.body;
    if ([params[@"name"] isEqualToString:@"didRestoreSession"]) {
        // Do something after restored session.
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqual:@"canGoBack"]) {
        _goBackButtonItem.enabled = _webView.canGoBack;
    }

    if ([keyPath isEqual:@"canGoForward"]) {
        _goForwardButtonItem.enabled = _webView.canGoForward;
    }
    
    if ([keyPath isEqual:@"estimatedProgress"]) {
        _progressView.progress = _webView.estimatedProgress;
        _progressView.hidden = _webView.estimatedProgress >= 1;
    }
    
    if ([keyPath isEqual:@"loading"]) {
        if (_webView.isLoading) {
            [_indicatorView startAnimating];
        } else {
            [_indicatorView stopAnimating];
        }
        _loadingView.hidden = !_webView.isLoading;
    }
}

@end
