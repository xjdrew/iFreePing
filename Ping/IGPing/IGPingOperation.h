//
//  IGPingHelper.h
//  Ping
//
//  Created by Zhu Xiaojing on 13-4-19.
//  Copyright (c) 2013年 Igniter. All rights reserved.
//

#import "IGPing.h"

// 
@interface IGPingStartResult : NSObject
@property (readonly, nonatomic) NSError   *error;
@property (readonly, nonatomic) NSString  *hostName;
@property (readonly, nonatomic) NSString  *ipAddr;
@property (readonly, nonatomic) NSInteger payloadLen;
@end

//
@interface IGPingResult : NSObject
@property (readonly, nonatomic) NSInteger      replyPayloadLen;
@property (readonly, nonatomic) NSString       *ipAddr;
@property (readonly, nonatomic) NSInteger      sequence;
@property (readonly, nonatomic) NSInteger      ttl;
@property (readonly, nonatomic) NSTimeInterval time;
@property (readonly, nonatomic) BOOL           isTimeout;
@end

//
@interface IGPingStopResult : NSObject
@property (readonly, nonatomic) NSInteger sendTimes;
@property (readonly, nonatomic) NSInteger receivedTimes;
@property (readonly, nonatomic) NSTimeInterval minRTT;
@property (readonly, nonatomic) NSTimeInterval avgRTT;
@property (readonly, nonatomic) NSTimeInterval maxRTT;
@property (readonly, nonatomic) NSTimeInterval mdevRTT;
@end

@protocol IGPingOperationDelegate;

@interface IGPingOperation : NSObject <IGPingDelegate>
@property (assign, nonatomic) NSInteger      repeatedTimes;
@property (assign, nonatomic) NSTimeInterval timeout;

+ (IGPingOperation*) makePingOperation:(NSString *)hostName delegate:(id<IGPingOperationDelegate>) delegate;
- (void)start;
- (void)stop;
@end

@protocol IGPingOperationDelegate <NSObject>

@optional
// call after [self start], if start failed, stop operation will not trigger
- (void) operation:(IGPingOperation*)operation start:(IGPingStartResult*) result;

// call one time for every ping
- (void) operation:(IGPingOperation*)operation pingResult:(IGPingResult*) result;

// call after stop or finished all pings
- (void) operation:(IGPingOperation*)operation stop:(IGPingStopResult*) result;
@end
