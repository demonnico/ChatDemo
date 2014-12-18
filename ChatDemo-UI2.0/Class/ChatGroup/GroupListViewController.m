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

#import "GroupListViewController.h"

#import "EMSearchBar.h"
#import "SRRefreshView.h"
#import "BaseTableViewCell.h"
#import "EMSearchDisplayController.h"
#import "ChatViewController.h"
#import "CreateGroupViewController.h"
#import "PublicGroupListViewController.h"
#import "RealtimeSearchUtil.h"
#import "UIViewController+HUD.h"

@interface GroupListViewController ()<UISearchBarDelegate, UISearchDisplayDelegate, IChatManagerDelegate, SRRefreshDelegate>

@property (strong, nonatomic) NSMutableArray *dataSource;

@property (strong, nonatomic) SRRefreshView *slimeView;
@property (strong, nonatomic) EMSearchBar *searchBar;
@property (strong, nonatomic) EMSearchDisplayController *searchController;

@end

@implementation GroupListViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        _dataSource = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)])
    {
        [self setEdgesForExtendedLayout:UIRectEdgeNone];
    }
    
    self.title = @"群组";
    
#warning 把self注册为SDK的delegate
    [[EaseMob sharedInstance].chatManager removeDelegate:self];
    [[EaseMob sharedInstance].chatManager addDelegate:self delegateQueue:nil];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.tableHeaderView = self.searchBar;
    [self.tableView addSubview:self.slimeView];
    [self searchController];
    
    UIButton *publicButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 44)];
    [publicButton setImage:[UIImage imageNamed:@"nav_createGroup"] forState:UIControlStateNormal];
    [publicButton addTarget:self action:@selector(showPublicGroupList) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *publicItem = [[UIBarButtonItem alloc] initWithCustomView:publicButton];
    
    UIButton *createButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 44)];
    [createButton setImage:[UIImage imageNamed:@"add.png"] forState:UIControlStateNormal];
    [createButton addTarget:self action:@selector(createGroup) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *createGroupItem = [[UIBarButtonItem alloc] initWithCustomView:createButton];
    
    [self.navigationItem setRightBarButtonItems:@[createGroupItem, publicItem]];
    
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    [backButton setImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
    [backButton addTarget:self.navigationController action:@selector(popViewControllerAnimated:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    [self.navigationItem setLeftBarButtonItem:backItem];
    
    [self reloadDataSource];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[EaseMob sharedInstance].chatManager removeDelegate:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - getter

- (SRRefreshView *)slimeView
{
    if (_slimeView == nil) {
        _slimeView = [[SRRefreshView alloc] init];
        _slimeView.delegate = self;
        _slimeView.upInset = 0;
        _slimeView.slimeMissWhenGoingBack = YES;
        _slimeView.slime.bodyColor = [UIColor grayColor];
        _slimeView.slime.skinColor = [UIColor grayColor];
        _slimeView.slime.lineWith = 1;
        _slimeView.slime.shadowBlur = 4;
        _slimeView.slime.shadowColor = [UIColor grayColor];
    }
    
    return _slimeView;
}

- (UISearchBar *)searchBar
{
    if (_searchBar == nil) {
        _searchBar = [[EMSearchBar alloc] initWithFrame: CGRectMake(0, 0, self.view.frame.size.width, 44)];
        _searchBar.delegate = self;
        _searchBar.placeholder = @"搜索";
        _searchBar.backgroundColor = [UIColor colorWithRed:0.747 green:0.756 blue:0.751 alpha:1.000];
    }
    
    return _searchBar;
}

- (EMSearchDisplayController *)searchController
{
    if (_searchController == nil) {
        _searchController = [[EMSearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
        _searchController.delegate = self;
        _searchController.searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        __weak GroupListViewController *weakSelf = self;
        [_searchController setCellForRowAtIndexPathCompletion:^UITableViewCell *(UITableView *tableView, NSIndexPath *indexPath) {
            static NSString *CellIdentifier = @"ContactListCell";
            BaseTableViewCell *cell = (BaseTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            
            // Configure the cell...
            if (cell == nil) {
                cell = [[BaseTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            }
            
            EMGroup *group = [weakSelf.searchController.resultsSource objectAtIndex:indexPath.row];
            NSString *imageName = group.isPublic ? @"groupPublicHeader" : @"groupPrivateHeader";
            cell.imageView.image = [UIImage imageNamed:imageName];
            cell.textLabel.text = group.groupSubject;
            
            return cell;
        }];
        
        [_searchController setHeightForRowAtIndexPathCompletion:^CGFloat(UITableView *tableView, NSIndexPath *indexPath) {
            return 50;
        }];
        
        [_searchController setDidSelectRowAtIndexPathCompletion:^(UITableView *tableView, NSIndexPath *indexPath) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            [weakSelf.searchController.searchBar endEditing:YES];
            
            EMGroup *group = [weakSelf.searchController.resultsSource objectAtIndex:indexPath.row];
            ChatViewController *chatVC = [[ChatViewController alloc] initWithChatter:group.groupId isGroup:YES];
            [weakSelf.navigationController pushViewController:chatVC animated:YES];
        }];
    }
    
    return _searchController;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.dataSource count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"GroupCell";
    BaseTableViewCell *cell = (BaseTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (cell == nil) {
        cell = [[BaseTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    EMGroup *group = [self.dataSource objectAtIndex:indexPath.row];
    NSString *imageName = group.isPublic ? @"groupPublicHeader" : @"groupPrivateHeader";
    cell.imageView.image = [UIImage imageNamed:imageName];
    if (group.groupSubject && group.groupSubject.length > 0) {
        cell.textLabel.text = group.groupSubject;
    }
    else {
        cell.textLabel.text = group.groupId;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    EMGroup *group = [self.dataSource objectAtIndex:indexPath.row];
    ChatViewController *chatController = [[ChatViewController alloc] initWithChatter:group.groupId isGroup:YES];
    chatController.title = group.groupSubject;
    [self.navigationController pushViewController:chatController animated:YES];
}

#pragma mark - UISearchBarDelegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:YES animated:YES];
    
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [[RealtimeSearchUtil currentUtil] realtimeSearchWithSource:self.dataSource searchText:(NSString *)searchText collationStringSelector:@selector(groupSubject) resultBlock:^(NSArray *results) {
        if (results) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.searchController.resultsSource removeAllObjects];
                [self.searchController.resultsSource addObjectsFromArray:results];
                [self.searchController.searchResultsTableView reloadData];
            });
        }
    }];
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    return YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = @"";
    [[RealtimeSearchUtil currentUtil] realtimeSearchStop];
    [searchBar resignFirstResponder];
    [searchBar setShowsCancelButton:NO animated:YES];
}

#pragma mark - SRRefreshDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [_slimeView scrollViewDidScroll];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [_slimeView scrollViewDidEndDraging];
}

- (void)slimeRefreshStartRefresh:(SRRefreshView *)refreshView
{
    [[EaseMob sharedInstance].chatManager asyncFetchMyGroupsListWithCompletion:^(NSArray *groups, EMError *error) {
        if (!error) {
            [self.dataSource removeAllObjects];
            [self.dataSource addObjectsFromArray:groups];
            [self.tableView reloadData];
        }
    } onQueue:nil];
    
//    [[EaseMob sharedInstance].chatManager asyncFetchAllPrivateGroupsWithCompletion:^(NSArray *groups, EMError *error) {
//        
//    } onQueue:nil];
    
    [_slimeView endRefresh];
}

#pragma mark - IChatManagerDelegate

- (void)groupDidUpdateInfo:(EMGroup *)group error:(EMError *)error
{
    if (!error) {
        [self reloadDataSource];
    }
}

- (void)didUpdateGroupList:(NSArray *)allGroups error:(EMError *)error
{
    [self reloadDataSource];
}

#pragma mark - data

- (void)reloadDataSource
{
    [self.dataSource removeAllObjects];
    
    NSArray *rooms = [[EaseMob sharedInstance].chatManager groupList];
    [self.dataSource addObjectsFromArray:rooms];
    
    [self.tableView reloadData];
}

#pragma mark - action

- (void)showPublicGroupList
{
    PublicGroupListViewController *publicController = [[PublicGroupListViewController alloc] initWithStyle:UITableViewStylePlain];
    [self.navigationController pushViewController:publicController animated:YES];
}

- (void)createGroup
{
    CreateGroupViewController *createChatroom = [[CreateGroupViewController alloc] init];
    [self.navigationController pushViewController:createChatroom animated:YES];
}


@end
