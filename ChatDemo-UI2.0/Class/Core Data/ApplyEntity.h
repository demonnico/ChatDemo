//
//  ApplyEntity.h
//  ChatDemo-UI2.0
//
//  Created by dhcdht on 14-7-14.
//  Copyright (c) 2014年 dhcdht. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ApplyEntity : NSManagedObject

@property (nonatomic, retain) NSString * applicantUsername;
@property (nonatomic, retain) NSString * applicantNick;
@property (nonatomic, retain) NSString * reason;
@property (nonatomic, retain) NSString * receiverUsername;
@property (nonatomic, retain) NSString * receiverNick;
@property (nonatomic, retain) NSNumber * style;
@property (nonatomic, retain) NSString * groupId;
@property (nonatomic, retain) NSString * groupSubject;

@end
