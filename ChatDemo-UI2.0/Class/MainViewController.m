/************************************************************
  *  * EaseMob CONFIDENTIAL 
  * __________________ 
  * Copyright (C) 2013-2014 EaseMob Technologies. All rights reserved. 
  *  
  * NOTICE: All information contained herein is, and remains 
  * the property of EaseMob Technologies.
  * Dissemination of this information or reproduction of this material 
  * is strictly forbidden unless prior written permission is obtained
  * from EaseMob Technologies.
  */

#import "MainViewController.h"
#import "ChatListViewController.h"
#import "ContactsViewController.h"
#import "SettingsViewController.h"
#import "ApplyViewController.h"

//两次提示的默认间隔
static const CGFloat kDefaultPlaySoundInterval = 3.0;

@interface MainViewController () <UIAlertViewDelegate, IChatManagerDelegate>
{
    ChatListViewController *_chatListVC;
    ContactsViewController *_contactsVC;
    SettingsViewController *_settingsVC;
    
    UIBarButtonItem *_addFriendItem;
}

@property (strong, nonatomic) NSDate *lastPlaySoundDate;

@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //if 使tabBarController中管理的viewControllers都符合 UIRectEdgeNone
    if ([UIDevice currentDevice].systemVersion.floatValue >= 7) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    self.title = @"会话";
    
    //获取未读消息数，此时并没有把self注册为SDK的delegate，读取出的未读数是上次退出程序时的
    [self didUnreadMessagesCountChanged];
#warning 把self注册为SDK的delegate
    [self registerNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupUntreatedApplyCount) name:@"setupUntreatedApplyCount" object:nil];
    
    [self setupSubviews];
    self.selectedIndex = 0;
    
    UIButton *addButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    [addButton setImage:[UIImage imageNamed:@"add.png"] forState:UIControlStateNormal];
    [addButton addTarget:_contactsVC action:@selector(addFriendAction) forControlEvents:UIControlEventTouchUpInside];
    _addFriendItem = [[UIBarButtonItem alloc] initWithCustomView:addButton];
    
    [self setupUnreadMessageCount];
    [self setupUntreatedApplyCount];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [self unregisterNotifications];
}

#pragma mark - UITabBarDelegate

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    if (item.tag == 0) {
        self.title = @"会话";
        self.navigationItem.rightBarButtonItem = nil;
    }else if (item.tag == 1){
        self.title = @"通讯录";
        self.navigationItem.rightBarButtonItem = _addFriendItem;
    }else if (item.tag == 2){
        self.title = @"设置";
        self.navigationItem.rightBarButtonItem = nil;
        [_settingsVC refreshConfig];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 99) {
        if (buttonIndex != [alertView cancelButtonIndex]) {
            [[EaseMob sharedInstance].chatManager asyncLogoffWithCompletion:^(NSDictionary *info, EMError *error) {
                [[ApplyViewController shareController] clear];
                [[NSNotificationCenter defaultCenter] postNotificationName:KNOTIFICATION_LOGINCHANGE object:@NO];
            } onQueue:nil];
        }
    }
    else if (alertView.tag == 100) {
        [[NSNotificationCenter defaultCenter] postNotificationName:KNOTIFICATION_LOGINCHANGE object:@NO];
    } else if (alertView.tag == 101) {
        [[NSNotificationCenter defaultCenter] postNotificationName:KNOTIFICATION_LOGINCHANGE object:@NO];
    }
}

#pragma mark - private

-(void)registerNotifications
{
    [self unregisterNotifications];
    
    [[EaseMob sharedInstance].chatManager addDelegate:self delegateQueue:nil];
}

-(void)unregisterNotifications
{
    [[EaseMob sharedInstance].chatManager removeDelegate:self];
}

- (void)setupSubviews
{
    self.tabBar.backgroundImage = [[UIImage imageNamed:@"tabbarBackground"] stretchableImageWithLeftCapWidth:25 topCapHeight:25];
    self.tabBar.selectionIndicatorImage = [[UIImage imageNamed:@"tabbarSelectBg"] stretchableImageWithLeftCapWidth:25 topCapHeight:25];
    
    _chatListVC = [[ChatListViewController alloc] init];
    _chatListVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"会话"
                                                           image:nil
                                                             tag:0];
    [_chatListVC.tabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"tabbar_chatsHL"]
                         withFinishedUnselectedImage:[UIImage imageNamed:@"tabbar_chats"]];
    [self unSelectedTapTabBarItems:_chatListVC.tabBarItem];
    [self selectedTapTabBarItems:_chatListVC.tabBarItem];
    
    _contactsVC = [[ContactsViewController alloc] initWithNibName:nil bundle:nil];
    _contactsVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"通讯录"
                                                           image:nil
                                                             tag:1];
    [_contactsVC.tabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"tabbar_contactsHL"]
                         withFinishedUnselectedImage:[UIImage imageNamed:@"tabbar_contacts"]];
    [self unSelectedTapTabBarItems:_contactsVC.tabBarItem];
    [self selectedTapTabBarItems:_contactsVC.tabBarItem];
    
    _settingsVC = [[SettingsViewController alloc] init];
    _settingsVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"设置"
                                                           image:nil
                                                             tag:2];
    [_settingsVC.tabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"tabbar_settingHL"]
                         withFinishedUnselectedImage:[UIImage imageNamed:@"tabbar_setting"]];
    _settingsVC.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [self unSelectedTapTabBarItems:_settingsVC.tabBarItem];
    [self selectedTapTabBarItems:_settingsVC.tabBarItem];
    
    self.viewControllers = @[_chatListVC, _contactsVC, _settingsVC];
    [self selectedTapTabBarItems:_chatListVC.tabBarItem];
}

-(void)unSelectedTapTabBarItems:(UITabBarItem *)tabBarItem
{
    [tabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                        [UIFont systemFontOfSize:14], UITextAttributeFont,[UIColor whiteColor],UITextAttributeTextColor,
                                        nil] forState:UIControlStateNormal];
}

-(void)selectedTapTabBarItems:(UITabBarItem *)tabBarItem
{
    [tabBarItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                        [UIFont systemFontOfSize:14],
                                        UITextAttributeFont,[UIColor colorWithRed:0.393 green:0.553 blue:1.000 alpha:1.000],UITextAttributeTextColor,
                                        nil] forState:UIControlStateSelected];
}

// 统计未读消息数
-(void)setupUnreadMessageCount
{
    NSArray *conversations = [[[EaseMob sharedInstance] chatManager] conversations];
    NSInteger unreadCount = 0;
    for (EMConversation *conversation in conversations) {
        unreadCount += conversation.unreadMessagesCount;
    }
    if (_chatListVC) {
        if (unreadCount > 0) {
            _chatListVC.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d",unreadCount];
        }else{
            _chatListVC.tabBarItem.badgeValue = nil;
        }
    }
    
    UIApplication *application = [UIApplication sharedApplication];
    [application setApplicationIconBadgeNumber:unreadCount];
}

- (void)setupUntreatedApplyCount
{
    NSInteger unreadCount = [[[ApplyViewController shareController] dataSource] count];
    if (_contactsVC) {
        if (unreadCount > 0) {
            _contactsVC.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d",unreadCount];
        }else{
            _contactsVC.tabBarItem.badgeValue = nil;
        }
    }
}

#pragma mark - IChatManagerDelegate 消息变化

- (void)didUpdateConversationList:(NSArray *)conversationList
{
    [_chatListVC refreshDataSource];
}

// 未读消息数量变化回调
-(void)didUnreadMessagesCountChanged
{
    [self setupUnreadMessageCount];
}

- (void)didFinishedReceiveOfflineMessages:(NSArray *)offlineMessages{
    [self setupUnreadMessageCount];
}

- (BOOL)needShowNotification:(NSString *)fromChatter
{
    BOOL ret = YES;
    NSArray *igGroupIds = [[EaseMob sharedInstance].chatManager ignoredGroupList];
    for (NSString *str in igGroupIds) {
        if ([str isEqualToString:fromChatter]) {
            ret = NO;
            break;
        }
    }
    
    if (ret) {
        EMPushNotificationOptions *options = [[EaseMob sharedInstance].chatManager pushNotificationOptions];
        
        do {
            if (options.noDisturbing) {
                NSDate *now = [NSDate date];
                NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute
                                                                               fromDate:now];
                
                NSInteger hour = [components hour];
                //        NSInteger minute= [components minute];
                
                NSUInteger startH = options.noDisturbingStartH;
                NSUInteger endH = options.noDisturbingEndH;
                if (startH>endH) {
                    endH += 24;
                }
                
                if (hour>=startH && hour<=endH) {
                    ret = NO;
                    break;
                }
            }
        } while (0);
    }
    
    return ret;
}

// 收到消息回调
-(void)didReceiveMessage:(EMMessage *)message
{
    BOOL needShowNotification = message.isGroup ? [self needShowNotification:message.conversation.chatter] : YES;
    if (needShowNotification) {
#if !TARGET_IPHONE_SIMULATOR
        [self playSoundAndVibration];
        
        BOOL isAppActivity = [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive;
        if (!isAppActivity) {
            [self showNotificationWithMessage:message];
        }
#endif
    }
}

- (void)playSoundAndVibration{
    NSTimeInterval timeInterval = [[NSDate date]
                                   timeIntervalSinceDate:self.lastPlaySoundDate];
    if (timeInterval < kDefaultPlaySoundInterval) {
        //如果距离上次响铃和震动时间太短, 则跳过响铃
        NSLog(@"skip ringing & vibration %@, %@", [NSDate date], self.lastPlaySoundDate);
        return;
    }
    
    //保存最后一次响铃时间
    self.lastPlaySoundDate = [NSDate date];
    
    // 收到消息时，播放音频
    [[EaseMob sharedInstance].deviceManager asyncPlayNewMessageSound];
    // 收到消息时，震动
    [[EaseMob sharedInstance].deviceManager asyncPlayVibration];
}

- (void)showNotificationWithMessage:(EMMessage *)message
{
    EMPushNotificationOptions *options = [[EaseMob sharedInstance].chatManager pushNotificationOptions];
    //发送本地推送
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.fireDate = [NSDate date]; //触发通知的时间
    
    if (options.displayStyle == ePushNotificationDisplayStyle_messageSummary) {
        id<IEMMessageBody> messageBody = [message.messageBodies firstObject];
        NSString *messageStr = nil;
        switch (messageBody.messageBodyType) {
            case eMessageBodyType_Text:
            {
                messageStr = ((EMTextMessageBody *)messageBody).text;
            }
                break;
            case eMessageBodyType_Image:
            {
                messageStr = @"[图片]";
            }
                break;
            case eMessageBodyType_Location:
            {
                messageStr = @"[位置]";
            }
                break;
            case eMessageBodyType_Voice:
            {
                messageStr = @"[音频]";
            }
                break;
            case eMessageBodyType_Video:{
                messageStr = @"[视频]";
            }
                break;
            default:
                break;
        }
        
        NSString *title = message.from;
        if (message.isGroup) {
            NSArray *groupArray = [[EaseMob sharedInstance].chatManager groupList];
            for (EMGroup *group in groupArray) {
                if ([group.groupId isEqualToString:message.conversation.chatter]) {
                    title = [NSString stringWithFormat:@"%@(%@)", message.groupSenderName, group.groupSubject];
                    break;
                }
            }
        }
        
        notification.alertBody = [NSString stringWithFormat:@"%@:%@", title, messageStr];
    }
    else{
        notification.alertBody = @"您有一条新消息";
    }
    
#warning 去掉注释会显示[本地]开头, 方便在开发中区分是否为本地推送
    //notification.alertBody = [[NSString alloc] initWithFormat:@"[本地]%@", notification.alertBody];
    
    notification.alertAction = @"打开";
    notification.timeZone = [NSTimeZone defaultTimeZone];
    //发送通知
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
//    UIApplication *application = [UIApplication sharedApplication];
//    application.applicationIconBadgeNumber += 1;
}

#pragma mark - IChatManagerDelegate 登陆回调（主要用于监听自动登录是否成功）

- (void)didLoginWithInfo:(NSDictionary *)loginInfo error:(EMError *)error
{
    if (error) {
        /*NSString *hintText = @"";
        if (error.errorCode != EMErrorServerMaxRetryCountExceeded) {
            if (![[[EaseMob sharedInstance] chatManager] isAutoLoginEnabled]) {
                hintText = @"你的账号登录失败，请重新登陆";
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示"
                                                                    message:hintText
                                                                   delegate:self
                                                          cancelButtonTitle:@"确定"
                                                          otherButtonTitles:nil,
                                          nil];
                alertView.tag = 99;
                [alertView show];
            }
        } else {
            hintText = @"已达到最大登陆重试次数，请重新登陆";
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示"
                                                                message:hintText
                                                               delegate:self
                                                      cancelButtonTitle:@"确定"
                                                      otherButtonTitles:nil,
                                      nil];
            alertView.tag = 99;
            [alertView show];
        }*/
        NSString *hintText = @"你的账号登录失败，正在重试中... \n点击 '登出' 按钮跳转到登录页面 \n点击 '继续等待' 按钮等待重连成功";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示"
                                                            message:hintText
                                                           delegate:self
                                                  cancelButtonTitle:@"继续等待"
                                                  otherButtonTitles:@"登出",
                                  nil];
        alertView.tag = 99;
        [alertView show];
        [_chatListVC isConnect:NO];
    }
}

#pragma mark - IChatManagerDelegate 好友变化

- (void)didReceiveBuddyRequest:(NSString *)username
                       message:(NSString *)message
{
#if !TARGET_IPHONE_SIMULATOR
    [self playSoundAndVibration];
    
    BOOL isAppActivity = [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive;
    if (!isAppActivity) {
        //发送本地推送
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.fireDate = [NSDate date]; //触发通知的时间
        notification.alertBody = [NSString stringWithFormat:@"%@ %@", username, @"添加你为好友"];
        notification.alertAction = @"打开";
        notification.timeZone = [NSTimeZone defaultTimeZone];
    }
#endif
    
    [_contactsVC reloadApplyView];
}

- (void)didUpdateBuddyList:(NSArray *)buddyList
            changedBuddies:(NSArray *)changedBuddies
                     isAdd:(BOOL)isAdd
{
    [_contactsVC reloadDataSource];
}

- (void)didRemovedByBuddy:(NSString *)username
{
    [[EaseMob sharedInstance].chatManager removeConversationByChatter:username deleteMessages:YES];
    [_chatListVC refreshDataSource];
    [_contactsVC reloadDataSource];
}

- (void)didAcceptedByBuddy:(NSString *)username
{
    [_contactsVC reloadDataSource];
}

- (void)didRejectedByBuddy:(NSString *)username
{
    NSString *message = [NSString stringWithFormat:@"你被'%@'无耻的拒绝了", username];
    TTAlertNoTitle(message);
}

- (void)didAcceptBuddySucceed:(NSString *)username{
    [_contactsVC reloadDataSource];
}

#pragma mark - IChatManagerDelegate 群组变化

- (void)didReceiveGroupInvitationFrom:(NSString *)groupId
                              inviter:(NSString *)username
                              message:(NSString *)message
{
#if !TARGET_IPHONE_SIMULATOR
    [self playSoundAndVibration];
#endif
    
    [_contactsVC reloadGroupView];
}

//接收到入群申请
- (void)didReceiveApplyToJoinGroup:(NSString *)groupId
                         groupname:(NSString *)groupname
                     applyUsername:(NSString *)username
                            reason:(NSString *)reason
                             error:(EMError *)error
{
    if (!error) {
#if !TARGET_IPHONE_SIMULATOR
        [self playSoundAndVibration];
#endif
        
        [_contactsVC reloadGroupView];
    }
}

- (void)didReceiveGroupRejectFrom:(NSString *)groupId
                          invitee:(NSString *)username
                           reason:(NSString *)reason
{
    NSString *message = [NSString stringWithFormat:@"你被'%@'无耻的拒绝了", username];
    TTAlertNoTitle(message);
}


- (void)didReceiveAcceptApplyToJoinGroup:(NSString *)groupId
                               groupname:(NSString *)groupname
{
    NSString *message = [NSString stringWithFormat:@"同意加入群组\'%@\'", groupname];
    [self showHint:message];
}

#pragma mark - IChatManagerDelegate 登录状态变化

- (void)didLoginFromOtherDevice
{
    [[EaseMob sharedInstance].chatManager asyncLogoffWithCompletion:^(NSDictionary *info, EMError *error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示"
                                                            message:@"你的账号已在其他地方登录"
                                                           delegate:self
                                                  cancelButtonTitle:@"确定"
                                                  otherButtonTitles:nil,
                                  nil];
        alertView.tag = 100;
        [alertView show];
    } onQueue:nil];
}

- (void)didRemovedFromServer {
    [[EaseMob sharedInstance].chatManager asyncLogoffWithCompletion:^(NSDictionary *info, EMError *error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示"
                                                            message:@"你的账号已被从服务器端移除"
                                                           delegate:self
                                                  cancelButtonTitle:@"确定"
                                                  otherButtonTitles:nil,
                                  nil];
        alertView.tag = 101;
        [alertView show];
    } onQueue:nil];
}

- (void)didConnectionStateChanged:(EMConnectionState)connectionState
{
    [_chatListVC networkChanged:connectionState];
}

#pragma mark - 自动登录回调

- (void)willAutoReconnect{
    [self hideHud];
    [self showHudInView:self.view hint:@"正在重连中..."];
}

- (void)didAutoReconnectFinishedWithError:(NSError *)error{
    [self hideHud];
    if (error) {
        [self showHint:@"重连失败，稍候将继续重连"];
    }else{
        [self showHint:@"重连成功！"];
    }
}

#pragma mark - public

- (void)jumpToChatList
{
    if(_chatListVC)
    {
        [self.navigationController popToViewController:self animated:NO];
        [self setSelectedViewController:_chatListVC];
    }
}

@end
