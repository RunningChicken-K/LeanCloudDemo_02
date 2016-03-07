//
//  ConversationCell.h
//  LeanCloudDemo_02
//
//  Created by KongLT on 16/3/3.
//  Copyright © 2016年 KongLT. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <JSBadgeView.h>
#import <AVIMConversation.h>
#import <AVIMConversation+Custom.h>
#import <CDChatManager.h>
#import <UIView+XHRemoteImage.h>
#import <CDMessageHelper.h>
#import <NSDate+DateTools.h>
@interface ConversationCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *timestampLabel;
@property (weak, nonatomic) IBOutlet UIView *litteBadgeView;
@property (nonatomic, strong) JSBadgeView *badgeView;
@property(nonatomic,strong)AVIMConversation * conversation;
@property(nonatomic,strong)NSOperationQueue * operationQueue;
+ (instancetype)cellForRowWithTableView:(UITableView *)tableView;

@end
