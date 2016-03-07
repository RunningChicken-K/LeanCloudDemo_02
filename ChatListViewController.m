//
//  ChatListViewController.m
//  LeanCloudDemo_02
//
//  Created by KongLT on 16/2/23.
//  Copyright © 2016年 KongLT. All rights reserved.
//

#import "ChatListViewController.h"
#import "ChatRoomViewController.h"
#import "LZStatusView.h"
#import "CDChatManager.h"
#import "CDEmotionUtils.h"
#import "CDConversationStore.h"
#import "CDChatManager_Internal.h"
#import "CDMacros.h"
#import "ConversationCell.h"

@interface ChatListViewController ()<CDChatListVCDelegate>
@property(nonatomic,strong)UITextField * textField;
@property (nonatomic, strong) LZStatusView *clientStatusView;

@property (nonatomic, strong) NSMutableArray *conversations;

@property (atomic, assign) BOOL isRefreshing;
@end

@implementation ChatListViewController

- (instancetype)init {
    if ((self = [super init])) {
        _conversations = [[NSMutableArray alloc] init];
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.chatListDelegate = self;
    UIView * headerView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 60)];
    
    self.tableView.tableHeaderView = headerView;
    
    _textField = [[UITextField alloc]initWithFrame:CGRectMake(15, 5, self.view.bounds.size.width - 30, 25)];
    _textField.layer.borderColor = [UIColor lightGrayColor].CGColor;
    _textField.layer.borderWidth = 1;
    [headerView addSubview:_textField];
    
    UIButton * startChat = [UIButton buttonWithType:UIButtonTypeSystem];
    startChat.frame = CGRectMake(60, 35, self.view.bounds.size.width - 120, 20);
    [startChat setTitle:@"开始聊天" forState:UIControlStateNormal];
    [headerView addSubview:startChat];
    [startChat addTarget:self action:@selector(startChatClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    
}
- (void)viewController:(UIViewController *)viewController didSelectConv:(AVIMConversation *)conv
{
    ChatRoomViewController * chatRoom = [[ChatRoomViewController alloc]initWithConv:conv];
    [self.navigationController pushViewController:chatRoom animated:YES];
}
- (void)startChatClicked:(UIButton *)btn
{
    if(_textField.text.length > 0)
    {
        [[CDChatManager manager] fetchConvWithOtherId:_textField.text callback:^(AVIMConversation *conversation, NSError *error) {
            ChatRoomViewController * chatRoom = [[ChatRoomViewController alloc]initWithConv:conversation];
            [self.navigationController pushViewController:chatRoom animated:YES];
        }];
    }
        
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.tabBarController.tabBar.hidden = NO;
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // 刷新 unread badge 和新增的对话
    [self performSelector:@selector(refresh:) withObject:nil afterDelay:0];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kCDNotificationConnectivityUpdated object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kCDNotificationMessageReceived object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kCDNotificationUnreadsUpdated object:nil];
}

#pragma mark - client status view

- (LZStatusView *)clientStatusView {
    if (_clientStatusView == nil) {
        _clientStatusView = [[LZStatusView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), kLZStatusViewHight)];
    }
    return _clientStatusView;
}

- (void)updateStatusView {
    if ([CDChatManager manager].connect) {
        self.tableView.tableHeaderView = nil ;
    }else {
        self.tableView.tableHeaderView = self.clientStatusView;
    }
    
}

- (UIRefreshControl *)getRefreshControl {
    UIRefreshControl *refreshConrol = [[UIRefreshControl alloc] init];
    [refreshConrol addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    return refreshConrol;
}

#pragma mark - refresh

- (void)refresh {
    [self refresh:nil];
}

- (void)refresh:(UIRefreshControl *)refreshControl {
    if (self.isRefreshing) {
        return;
    }
    self.isRefreshing = YES;
    [[CDChatManager manager] findRecentConversationsWithBlock:^(NSArray *conversations, NSInteger totalUnreadCount, NSError *error) {
        dispatch_block_t finishBlock = ^{
            [self stopRefreshControl:refreshControl];
            if ([self filterError:error]) {
                NSMutableArray * array = [[NSMutableArray alloc]initWithArray:conversations];
                //将id为"79"或"78"的用户聊天从最近聊天移除
                for (AVIMConversation * conver in conversations) {
                    for (id member in conver.members) {
                        if ([member isEqual:@"78"] || [member isEqual:@"79"]) {

                            [array removeObject:conver];
                        }
                    }
                }
                self.conversations = array;
                [self.tableView reloadData];
                if ([self.chatListDelegate respondsToSelector:@selector(setBadgeWithTotalUnreadCount:)]) {
                    [self.chatListDelegate setBadgeWithTotalUnreadCount:totalUnreadCount];
                }
                [self selectConversationIfHasRemoteNotificatoinConvid];
            }
            self.isRefreshing = NO;
        };
        
        if ([self.chatListDelegate respondsToSelector:@selector(prepareConversationsWhenLoad:completion:)]) {
            [self.chatListDelegate prepareConversationsWhenLoad:conversations completion:^(BOOL succeeded, NSError *error) {
                if ([self filterError:error]) {
                    finishBlock();
                } else {
                    [self stopRefreshControl:refreshControl];
                    self.isRefreshing = NO;
                }
            }];
        } else {
            finishBlock();
        }
    }];
}
- (void)setBadgeWithTotalUnreadCount:(NSInteger)totalUnreadCount
{
    if (totalUnreadCount == 0) {
        [self.navigationController.tabBarItem setBadgeValue:nil];
    }
    else
    {
        [self.navigationController.tabBarItem setBadgeValue:[NSString stringWithFormat:@"%ld",(long)totalUnreadCount]];
    }
}
- (void)selectConversationIfHasRemoteNotificatoinConvid {
    if ([CDChatManager manager].remoteNotificationConvid) {
        // 进入之前推送弹框点击的对话
        BOOL found = NO;
        for (AVIMConversation *conversation in self.conversations) {
            if ([conversation.conversationId isEqualToString:[CDChatManager manager].remoteNotificationConvid]) {
                if ([self.chatListDelegate respondsToSelector:@selector(viewController:didSelectConv:)]) {
                    [self.chatListDelegate viewController:self didSelectConv:conversation];
                    found = YES;
                }
            }
        }
        if (!found) {
            DLog(@"not found remoteNofitciaonID");
        }
        [CDChatManager manager].remoteNotificationConvid = nil;
    }
}

#pragma mark - utils

- (void)stopRefreshControl:(UIRefreshControl *)refreshControl {
    if (refreshControl != nil && [[refreshControl class] isSubclassOfClass:[UIRefreshControl class]]) {
        [refreshControl endRefreshing];
    }
}

- (BOOL)filterError:(NSError *)error {
    if (error) {
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:@"%@", error]  preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:alert animated:YES completion:nil];
        return NO;
    }
    return YES;
}

#pragma mark - table view

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.conversations count];

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ConversationCell *cell = [ConversationCell cellForRowWithTableView:tableView];
    AVIMConversation *conversation = [self.conversations objectAtIndex:indexPath.row];
    cell.conversation = conversation;
       if ([self.chatListDelegate respondsToSelector:@selector(configureCell:atIndexPath:withConversation:)]) {
        [self.chatListDelegate configureCell:cell atIndexPath:indexPath withConversation:conversation];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        AVIMConversation *conversation = [self.conversations objectAtIndex:indexPath.row];
        [[CDConversationStore store] deleteConversation:conversation];
        [self refresh];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return true;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    AVIMConversation *conversation = [self.conversations objectAtIndex:indexPath.row];
    if ([self.chatListDelegate respondsToSelector:@selector(viewController:didSelectConv:)]) {
        [self.chatListDelegate viewController:self didSelectConv:conversation];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [LZConversationCell heightOfCell];
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
