//
//  HLLoginController.m
//  WeChat
//
//  Created by 韩露露 on 16/10/2.
//  Copyright © 2016年 HLL. All rights reserved.
//

#import "HLLoginController.h"

@interface HLLoginController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rightConstraint;
@property (weak, nonatomic) IBOutlet UILabel *userLabel;
@property (weak, nonatomic) IBOutlet UITextField *pwdField;
@property (weak, nonatomic) IBOutlet UIButton *loginBtn;

- (IBAction)clickLogin;
@end

@implementation HLLoginController



- (void)viewDidLoad {
    [super viewDidLoad];
    // 判断设备以及iPad横竖屏，调整登录框的大小。
    [self statusBarOrientationDidChange];
    // 设置输入框和按钮的背景图片。
    [self setupBackground];
    // 设置帐号显示
    [self setupUser];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarOrientationDidChange) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

// 判断设备以及iPad横竖屏，调整登录框的大小。
- (void)statusBarOrientationDidChange {
    UIUserInterfaceIdiom userInterfaceIdiom = [UIDevice currentDevice].userInterfaceIdiom;
    if (userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        self.leftConstraint.constant = loginLeftMarginPhone;
        self.rightConstraint.constant = loginRightMarginPhone;
    } else if (userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
        switch (statusBarOrientation) {
            case UIInterfaceOrientationLandscapeLeft:
            case UIInterfaceOrientationLandscapeRight:
                self.leftConstraint.constant = loginLeftMarginPadH;
                self.rightConstraint.constant = loginRightMarginPadH;
                break;
            default:
                self.leftConstraint.constant = loginLeftMarginPadV;
                self.rightConstraint.constant = loginRightMarginPadV;
                break;
        }
    }
}

// 设置输入框和按钮的背景图片。
- (void)setupBackground {
    self.pwdField.background = [UIImage stretchedImageWithName:@"operationbox_text"];
    [self.loginBtn setStretchedN_BG:@"fts_green_btn" H_BG:@"fts_green_btn_HL"];
}

// 设置帐号显示
- (void)setupUser {
    self.userLabel.text = [HLUserInfo sharedHLUserInfo].userName;
    self.pwdField.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)clickLogin {
    [self.view endEditing:NO];
    
    HLUserInfo *userInfo = [HLUserInfo sharedHLUserInfo];
    userInfo.pwd = self.pwdField.text;
    [userInfo saveUserInfoData];
    
    [SVProgressHUD showWithStatus:@"正在登录。。。"];
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [app userLogin:^(HLLoginResultType result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (result) {
                case HLLoginResultFailure:
                    [self loginFailure];
                    break;
                case HLLoginResultSuccess: // 跳到主界面
                    [self loginSuccess];
                    break;
                case HLLoginResultNetError:
                    [SVProgressHUD showErrorWithStatus:@"网络连接失败"];
                    break;
            }
        });
    }];
}

- (void)loginFailure {
    [SVProgressHUD showErrorWithStatus:@"登录失败，帐号或者密码错误。"];
    HLUserInfo *userInfo = [HLUserInfo sharedHLUserInfo];
    userInfo.pwd = @"";
    [userInfo saveUserInfoData];
}

- (void)loginSuccess {
    self.view.window.rootViewController = [UIStoryboard storyboardWithName:@"Main" bundle:nil].instantiateInitialViewController;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self clickLogin];
    return YES;
}

- (void)dealloc {
    HLLog(@"HLLoginController");
}

@end
