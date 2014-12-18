//
//  PushNotificationViewController.m
//  ChatDemo-UI2.0
//
//  Created by dhcdht on 14-7-21.
//  Copyright (c) 2014年 dhcdht. All rights reserved.
//

#import "PushNotificationViewController.h"

@interface PushNotificationViewController ()
{
    EMPushNotificationDisplayStyle _pushDisplayStyle;
    BOOL _isNoDisturbing;
    NSInteger _noDisturbingStart;
    NSInteger _noDisturbingEnd;
    NSString *_nickName;
}

@property (strong, nonatomic) UISwitch *pushDisplaySwitch;

@end

@implementation PushNotificationViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        _noDisturbingStart = -1;
        _noDisturbingEnd = -1;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"消息推送设置";
    
    UIButton *saveButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 40)];
    [saveButton setTitle:@"保存" forState:UIControlStateNormal];
    [saveButton addTarget:self action:@selector(savePushOptions) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:saveButton];
    
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    [self refreshPushOptions];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - getter

- (UISwitch *)pushDisplaySwitch
{
    if (_pushDisplaySwitch == nil) {
        _pushDisplaySwitch = [[UISwitch alloc] init];
        [_pushDisplaySwitch addTarget:self action:@selector(pushDisplayChanged:) forControlEvents:UIControlEventValueChanged];
    }
    
    return _pushDisplaySwitch;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (section == 0) {
        return 1;
    }
    else if (section == 1)
    {
        return 3;
    }
    
    return 0;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        return YES;
    }
    
    return NO;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1) {
        return @"功能消息免打扰";
    }
    return nil;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"通知显示消息详情";
            
            self.pushDisplaySwitch.frame = CGRectMake(self.tableView.frame.size.width - self.pushDisplaySwitch.frame.size.width - 10, (cell.contentView.frame.size.height - self.pushDisplaySwitch.frame.size.height) / 2, self.pushDisplaySwitch.frame.size.width, self.pushDisplaySwitch.frame.size.height);
            [cell.contentView addSubview:self.pushDisplaySwitch];
        }
    }
    else if (indexPath.section == 1)
    {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"开启";
            
            BOOL isOn = _isNoDisturbing;
            if (_noDisturbingStart == 0 && _noDisturbingEnd == 24) {
                isOn = YES;
            }
            else{
                isOn = NO;
            }
            cell.accessoryType = isOn == YES ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }
        else if (indexPath.row == 1)
        {
            cell.textLabel.text = @"只在夜间开启 (22:00 - 7:00)";
            
            BOOL isOn = _isNoDisturbing;
            if (_noDisturbingStart == 22 && _noDisturbingEnd == 7) {
                isOn = YES;
            }
            else{
                isOn = NO;
            }
            cell.accessoryType = isOn == YES ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }
        else if (indexPath.row == 2)
        {
            cell.textLabel.text = @"关闭";
            cell.accessoryType = _isNoDisturbing == YES ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
        }
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 1)
    {
        return 30;
    }
    
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    BOOL needReload = YES;
    
    if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:
            {
                needReload = NO;
                [WCAlertView showAlertWithTitle:@"设置提醒"
                                        message:@"此设置会导致全天都处于免打扰模式, 不会再收到推送消息. 是否继续?"
                             customizationBlock:^(WCAlertView *alertView) {
                             } completionBlock:^(NSUInteger buttonIndex, WCAlertView *alertView) {
                                 switch (buttonIndex) {
                                     case 0: {
                                     } break;
                                     default: {
                                         self->_noDisturbingStart = 0;
                                         self->_noDisturbingEnd = 24;
                                         self->_isNoDisturbing = YES;
                                         [tableView reloadData];
                                     } break;
                                 }
                             } cancelButtonTitle:@"否" otherButtonTitles:@"是", nil];
            } break;
            case 1:
            {
                _noDisturbingStart = 22;
                _noDisturbingEnd = 7;
                _isNoDisturbing = YES;
            }
                break;
            case 2:
            {
                _noDisturbingStart = -1;
                _noDisturbingEnd = -1;
                _isNoDisturbing = NO;
            }
                break;
                
            default:
                break;
        }
        
        if (needReload) {
            [tableView reloadData];
        }
    }
}

#pragma mark - action

- (void)savePushOptions
{
    BOOL isUpdate = NO;
    EMPushNotificationOptions *options = [[EaseMob sharedInstance].chatManager pushNotificationOptions];
    if (_pushDisplayStyle != options.displayStyle) {
        options.displayStyle = _pushDisplayStyle;
        isUpdate = YES;
    }
    
    if (_nickName && _nickName.length > 0 && ![_nickName isEqualToString:options.nickname])
    {
        options.nickname = _nickName;
        isUpdate = YES;
    }
    if (_isNoDisturbing != options.noDisturbing || options.noDisturbingStartH != _noDisturbingStart || options.noDisturbingEndH != _noDisturbingEnd){
        isUpdate = YES;
        options.noDisturbing = _isNoDisturbing;
        options.noDisturbingStartH = _noDisturbingStart;
        options.noDisturbingEndH = _noDisturbingEnd;
    }
    
    if (isUpdate) {
        [[EaseMob sharedInstance].chatManager asyncUpdatePushOptions:options];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)pushDisplayChanged:(UISwitch *)pushDisplaySwitch
{
    if (pushDisplaySwitch.isOn) {
#warning 此处设置详情显示时的昵称，比如_nickName = @"环信";
        _pushDisplayStyle = ePushNotificationDisplayStyle_messageSummary;
    }
    else{
        _pushDisplayStyle = ePushNotificationDisplayStyle_simpleBanner;
    }
}

- (void)refreshPushOptions
{
    EMPushNotificationOptions *options = [[EaseMob sharedInstance].chatManager pushNotificationOptions];
    _nickName = options.nickname;
    _pushDisplayStyle = options.displayStyle;
    _isNoDisturbing = options.noDisturbing;
    if (_isNoDisturbing) {
        _noDisturbingStart = options.noDisturbingStartH;
        _noDisturbingEnd = options.noDisturbingEndH;
    }
    
    BOOL isDisplayOn = _pushDisplayStyle == ePushNotificationDisplayStyle_simpleBanner ? NO : YES;
    [self.pushDisplaySwitch setOn:isDisplayOn animated:YES];
}

@end
