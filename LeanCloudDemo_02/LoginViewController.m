//
//  LoginViewController.m
//  LeanCloudDemo_02
//
//  Created by KongLT on 16/2/22.
//  Copyright © 2016年 KongLT. All rights reserved.
//

#import "LoginViewController.h"
#import <CDChatManager.h>
#import "ChatListViewController.h"
@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *textField;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view.
}
- (IBAction)loginBtnClicked:(id)sender {
    [[CDChatManager manager]closeWithCallback:^(BOOL succeeded, NSError *error) {
        [[CDChatManager manager]openWithClientId:_textField.text callback:^(BOOL succeeded, NSError *error) {
            ChatListViewController * chatList = [[ChatListViewController alloc]init];
            [self.navigationController pushViewController:chatList animated:YES];
        }];
        
     }];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
