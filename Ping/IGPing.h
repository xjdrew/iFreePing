//
//  IGPing.h
//  Ping
//
//  Created by Zhu Xiaojing on 13-4-19.
//  Copyright (c) 2013年 Igniter. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_EMBEDDED || TARGET_IPHONE_SIMULATOR
    #import <CFNetwork/CFNetwork.h>
#else
    #import <CoreServices/CoreServices.h>
#endif


#pragma mark * IGPing

@protocol IGPingDelegate;

@interface IGPing : NSObject
@property (weak, nonatomic)   id<IGPingDelegate> delegate;
@property (strong, nonatomic) NSString           *hostName;
@property (strong, nonatomic) NSData             *hostAddress;
@property (assign, atomic)    CFSocketRef        socket;
@property (assign, nonatomic) CFHostRef          host;

@property (assign, nonatomic) uint16_t           nextSequenceNumber;
@property (assign, nonatomic) uint8_t            payloadLen;

+ (IGPing *)pingWithHostName:(NSString *)hostName;
+ (IGPing *)pingWithHostAddress:(NSData *)hostAddress;

- (void)start;
- (void)sendPacket;
- (void)stop;

- (NSString*) getIpAddr;

+ (const struct ICMPHeader *)icmpInPacket:(NSData *)packet;
+ (NSUInteger)icmpHeaderOffsetInPacket:(NSData *)packet;
@end

@protocol IGPingDelegate <NSObject>

@optional

- (void)ping:(IGPing *)pinger onStartup:(NSError *)error;
- (void)ping:(IGPing *)pinger didFailWithError:(NSError *)error;
- (void)ping:(IGPing *)pinger didSendPacket:(uint16_t)sequence packet:(NSData *)packet;
- (void)ping:(IGPing *)pinger didFailToSendPacket:(uint16_t)sequence packet:(NSData *)packet error:(NSError *)error;
- (void)ping:(IGPing *)pinger didReceivePacket:(uint16_t)sequence packet:(NSData *)packet;
- (void)ping:(IGPing *)pinger didReceiveUnexpectedPacket: (NSData*)packet;
@end

