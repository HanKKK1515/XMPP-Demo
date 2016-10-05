//
//  AppDelegate.m
//  WeChat
//
//  Created by 韩露露 on 16/10/1.
//  Copyright © 2016年 HLL. All rights reserved.
//

#import "AppDelegate.h"
#import <XMPPFramework/XMPPFramework.h>

@interface AppDelegate () <XMPPStreamDelegate> {
    HLLoginResult _loginBlock;
    HLLogoutResult _logoutBlock;
}

@property (strong, nonatomic) XMPPStream *stream;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    [self setupSVProgressHUD];
    [self setupNavigationBar];
    [self setupFirstPage];
    return YES;
}

- (void)setupSVProgressHUD {
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
    [SVProgressHUD setDefaultAnimationType:SVProgressHUDAnimationTypeNative];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeGradient];
}

- (void)setupNavigationBar {
    UINavigationBar *appearance = [UINavigationBar appearance];
    [appearance setBackgroundImage:[UIImage imageNamed:@"topbarbg_Nav"] forBarMetrics:UIBarMetricsDefault];
    NSMutableDictionary *fontAttribNav = [NSMutableDictionary dictionary];
    fontAttribNav[NSForegroundColorAttributeName] = [UIColor whiteColor];
    fontAttribNav[NSFontAttributeName] = [UIFont systemFontOfSize:18];
    appearance.titleTextAttributes = fontAttribNav;
    
    UIBarButtonItem *item = [UIBarButtonItem appearance];
    NSMutableDictionary *fontAttribItem = [NSMutableDictionary dictionary];
    fontAttribItem[NSForegroundColorAttributeName] = [UIColor whiteColor];
    fontAttribItem[NSFontAttributeName] = [UIFont systemFontOfSize:16];
    [item setTitleTextAttributes:fontAttribItem forState:UIControlStateNormal];
    [item setTitleTextAttributes:fontAttribItem forState:UIControlStateHighlighted];
}

- (void)setupFirstPage {
    HLUserInfo *userInfo = [HLUserInfo sharedHLUserInfo];
    [userInfo loadUserInfoData];
    if (userInfo.userName.length > 0 && userInfo.pwd.length > 0) {
        __weak typeof(self) selfWeak = self;
        [self userLogin:^(HLLoginResultType result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                switch (result) {
                    case HLLoginResultFailure:
                        [SVProgressHUD showErrorWithStatus:@"登录失败，帐号或者密码错误。"];
                        selfWeak.window.rootViewController = [UIStoryboard storyboardWithName:@"Login" bundle:nil].instantiateInitialViewController;
                        break;
                    case HLLoginResultSuccess: // 跳到主界面
                        selfWeak.window.rootViewController = [UIStoryboard storyboardWithName:@"Main" bundle:nil].instantiateInitialViewController;
                        break;
                    case HLLoginResultNetError:
                        [SVProgressHUD showErrorWithStatus:@"网络连接失败"];
                        selfWeak.window.rootViewController = [UIStoryboard storyboardWithName:@"Login" bundle:nil].instantiateInitialViewController;
                        break;
                }
            });
        }];
    } else if (userInfo.userName > 0) {
        self.window.rootViewController = [UIStoryboard storyboardWithName:@"Login" bundle:nil].instantiateInitialViewController;
    } else {
        UIStoryboard *storybaord = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
        self.window.rootViewController = [storybaord instantiateViewControllerWithIdentifier:@"otherLoginNav"];
    }
}

- (void)userLogin:(HLLoginResult)block {
    [self.stream disconnect];
    _loginBlock = block;
    // 从沙盒中获取用户名和密码。
    NSString *userName = [HLUserInfo sharedHLUserInfo].userName;
    self.stream.myJID = [XMPPJID jidWithUser:userName domain:@"hllmac.local" resource:@"iphone"];
    // 连接至服务器。
    NSError *error = nil;
    if (![self.stream connectWithTimeout:XMPPStreamTimeoutNone error:&error]) {
        HLLog(@"连接服务器出错：%@", error.localizedDescription);
    }
}

#pragma mark - XMPPStreamDelegate

- (void)xmppStreamDidConnect:(XMPPStream *)sender {
    HLLog(@"连接服务器成功\n");
    // 发送密码
    NSString *userPwd = [HLUserInfo sharedHLUserInfo].pwd;
    NSError *error = nil;
    if (![self.stream authenticateWithPassword:userPwd error:&error]) {
        HLLog(@"登录失败\n");
    }
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
    HLLog(@"密码验证成功\n");
    if (_loginBlock) {
        _loginBlock(HLLoginResultSuccess);
    }
    // 发送在线状态
    XMPPPresence *presence = [XMPPPresence presence];
    [self.stream sendElement:presence];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(DDXMLElement *)error {
    HLLog(@"密码验证失败\n");
    if (_loginBlock) {
        _loginBlock(HLLoginResultFailure);
    }
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error {
    HLLog(@"已断开服务器\n");
    if (error) {
        if (_loginBlock) _loginBlock(HLLoginResultNetError);
        if (_logoutBlock) _logoutBlock(HLLogoutResultNetError);
    }
}

- (void)userLogout:(HLLogoutResult)block {
    _logoutBlock = block;
    if ([self.stream isDisconnected]) {
        if (_logoutBlock) _logoutBlock(HLLogoutResultNetError);
    } else {
        // 发送离线状态
        XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
        [self.stream sendElement:presence];
        // 与服务器断开连接
        [self.stream disconnect];
        if (_logoutBlock) return _logoutBlock(HLLogoutResultSuccess);
    }
}

- (XMPPStream *)stream {
    if (!_stream) {
        _stream = [[XMPPStream alloc] init];
        [_stream addDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    }
    return _stream;
}

@end