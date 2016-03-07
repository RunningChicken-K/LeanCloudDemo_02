//
//  ConversationCell.m
//  LeanCloudDemo_02
//
//  Created by KongLT on 16/3/3.
//  Copyright © 2016年 KongLT. All rights reserved.
//

#import "ConversationCell.h"

@implementation ConversationCell

- (void)awakeFromNib {
    // Initialization code
    self.avatarImageView.layer.cornerRadius = 22.5;
    self.avatarImageView.clipsToBounds = YES;
    self.litteBadgeView.hidden = YES;
    _badgeView = [[JSBadgeView alloc]initWithParentView:self.timestampLabel alignment:JSBadgeViewAlignmentBottomCenter];
    
    _operationQueue = [[NSOperationQueue alloc]init];
}
+ (instancetype)cellForRowWithTableView:(UITableView *)tableView
{
    NSString * className = NSStringFromClass([self class]);
    
    [tableView registerNib:[UINib nibWithNibName:className bundle:nil] forCellReuseIdentifier:className];
    return [tableView dequeueReusableCellWithIdentifier:className];
}

- (void)setConversation:(AVIMConversation *)conversation
{
    if (conversation.type == CDConvTypeSingle) {
        [self.operationQueue addOperationWithBlock:^{
            id <CDUserModel> user = [[CDChatManager manager].userDelegate getUserById:conversation.otherId];
            self.nameLabel.text = user.username;
            [self.avatarImageView setImageWithURL:[NSURL URLWithString:user.avatarUrl]];
        }];

    }
    else {
        [self.avatarImageView setImage:conversation.icon];
        self.nameLabel.text = conversation.displayName;
    }
    if (conversation.lastMessage) {
        self.messageTextLabel.attributedText = [[CDMessageHelper helper] attributedStringWithMessage:conversation.lastMessage conversation:conversation];
        self.timestampLabel.text = [[NSDate dateWithTimeIntervalSince1970:conversation.lastMessage.sendTimestamp / 1000] timeAgoSinceNow];
    }
    if (conversation.unreadCount > 0) {
        if (conversation.muted) {
            self.litteBadgeView.hidden = NO;
        } else {
            self.badgeView.badgeText = [NSString stringWithFormat:@"%ld", conversation.unreadCount];
        }
    }

}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
