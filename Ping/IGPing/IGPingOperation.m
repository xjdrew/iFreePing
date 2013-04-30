//
//  IGPingHelper.m
//  Ping
//
//  Created by Zhu Xiaojing on 13-4-19.
//  Copyright (c) 2013年 Igniter. All rights reserved.
//

#import "IGPingOperation.h"
#import "IGPingHeader.h"

#pragma mark - IGPingStartResult
@implementation IGPingStartResult
+(IGPingStartResult*) makePingStartResult:(NSString*) hostName ip:(NSString*)ip payload:(NSInteger)len {
    IGPingStartResult *result = [[IGPingStartResult alloc] init];
    if (result) {
        result->_hostName = hostName;
        result->_ipAddr   = ip;
        result->_payloadLen = len;
    }
    return result;
}

+(IGPingStartResult*) makePingStartResult:(NSString*) hostName error:(NSError*)err {
    IGPingStartResult *result = [[IGPingStartResult alloc] init];
    if (result) {
        result->_hostName = hostName;
        result->_error    = err;
    }
    return result;
}

-(NSString*) description {
    if (self.error) {
        return [NSString stringWithFormat:@"cannot resolve %@: %@", self.hostName, self.error.localizedFailureReason];
    } else {
        return [NSString stringWithFormat:@"PING %@ (%@): %d data bytes", self.hostName, self.ipAddr, self.payloadLen];
    }
}
@end

#pragma mark - IGPingResult
@implementation IGPingResult

+(IGPingResult*) makePingResult:(NSInteger)sequence {
    IGPingResult *result = [[IGPingResult alloc] init];
    if (result) {
        result->_sequence = sequence;
        result->_isTimeout = YES;
    }
    return result;
}

+(IGPingResult*) makePingResult:(NSInteger)sequence ip:(NSString*)ip ttl:(NSInteger)ttl time:(NSTimeInterval)time reply:(NSInteger) payloadLen{
    IGPingResult *result = [[IGPingResult alloc] init];
    if (result) {
        result->_sequence  = sequence;
        result->_ipAddr    = ip;
        result->_ttl       = ttl;
        result->_time      = time;
        result->_replyPayloadLen = payloadLen;
        result->_isTimeout = NO;
    }
    return result;
}

-(NSString*) description {
    if (self->_isTimeout) {
        return [NSString stringWithFormat:@"Request timeout for icmp_seq %d", self->_sequence];
    }
    return [NSString stringWithFormat:@"%d bytes from %@: icmp_seq=%d, ttl=%d, time=%.3f ms",
            self->_replyPayloadLen,
            self->_ipAddr,
            self->_sequence,
            self->_ttl,
            self->_time];
}
@end

#pragma mark - IGPingStopResult
@interface IGPingStopResult()
@property (assign, nonatomic) NSInteger    capacity;
@property (strong, atomic) NSMutableArray* resultArray;
@end

@implementation IGPingStopResult
-(id) init:(NSString*) hostName capacity:(NSInteger) capacity {
    self = [super init];
    if (self) {
        _hostName = hostName;
        _capacity = capacity;
        _resultArray = [NSMutableArray arrayWithCapacity:capacity];
    }
    return self;
}

-(void) addResult:(IGPingResult*) result {
    [self.resultArray addObject:result];
}

-(void) calcResult {
    NSTimeInterval totalRtt = 0;
    NSTimeInterval totalRtt2 = 0;
    for (IGPingResult* result in self.resultArray) {
        ++ self->_sendTimes;
        if (result.isTimeout == NO) {
            ++ self->_receivedTimes;
            totalRtt += result.time;
            totalRtt2 += result.time * result.time;
        
            if (self->_minRTT == 0 || result.time < self->_minRTT) {
                self->_minRTT = result.time;
            }
            if (self->_maxRTT == 0 || result.time > self->_maxRTT) {
                self->_maxRTT = result.time;
            }
        }
    }
    if (!self->_sendTimes) {
        self->_sendTimes = 1;
    }
    
    if (self->_receivedTimes) {
        self->_avgRTT = totalRtt / self->_receivedTimes;
        self->_mdevRTT = sqrt(totalRtt2/self->_receivedTimes - pow(self->_avgRTT,2));
    }
}

-(NSUInteger) isFull {
    return [self.resultArray count] >= self.capacity;
}

-(NSString*) description {
    NSString *desc = [NSString stringWithFormat:@"%d packets transmitted, %d packets received, %.1f%% packet loss",
                       self->_sendTimes, self->_receivedTimes, (self->_receivedTimes*100.0)/self->_sendTimes];
    if (self->_receivedTimes) {
        desc = [NSString stringWithFormat:@"%@\nround-trip min/avg/max/mdev = %.3f/%.3f/%.3f/%.3f ms",
                desc, self->_minRTT, self->_avgRTT, self->_maxRTT, self->_mdevRTT];
    }
    return desc;
}
@end
#pragma declare IGPingProcedure

@interface IGPingProcedure : NSObject
@property (strong, nonatomic) NSString  *host;
@property (strong, nonatomic) NSDate    *sendDate;
@property (strong, nonatomic) NSDate    *timeoutDate;
@property (strong, nonatomic) NSData    *receivePacket;
@property (strong, nonatomic) NSDate    *receiveDate;
@property (assign, nonatomic) uint16_t  sequence;

+ (IGPingProcedure *) makePingProcedure:(NSString*)host sequence:(uint16_t)sequence timeout:(NSTimeInterval) timeout;
- (NSTimeInterval)    getRTT; // round trip delay time, unit: millisecond
- (uint16_t)          getTTL; // time to live
- (NSInteger)         getReplyLength; // replay icmp length
- (BOOL)              isTimeout;
- (IGPingResult*)     getPingResult;
@end

#pragma implemention IGPingProcedure
@implementation IGPingProcedure

- (const struct IPHeader*) getReceivePacketIpHeader {
    if (self->_receivePacket) {
        return (const struct IPHeader*)[self->_receivePacket bytes];
    }
    return NULL;
}

- (const struct ICMPHeader*) getReceivePacketIcmpHeader {
    if (self->_receivePacket) {
        return [IGPing icmpInPacket:self.receivePacket];
    }
    return NULL;
}

-(NSInteger) getReplyLength {
    if (self->_receivePacket) {
        return [self->_receivePacket length] - [IGPing icmpHeaderOffsetInPacket:self->_receivePacket];
    }
    return 0;
}

- (NSTimeInterval) getRTT {
    if (self.receiveDate) {
        return [self->_receiveDate timeIntervalSinceDate:self->_sendDate] * 1000;
    }
    return -1;
}

- (uint16_t) getTTL {
    const struct IPHeader* header = [self getReceivePacketIpHeader];
    if (header) {
        return header->timeToLive;
    }
    return 0;
}

- (void) setReceivePacket:(NSData *)receivePacket {
    assert(self->_receivePacket == nil);
    self->_receivePacket = receivePacket;
    self.receiveDate = [NSDate date];
}

- (BOOL) isTimeout {
    if (self.receiveDate) {
        return NO;
    }
    
    if ([self.timeoutDate compare:[NSDate date]] == NSOrderedDescending) {
        return NO;
    }
    return YES;
}

- (IGPingResult*) getPingResult {
    if ([self isTimeout]) {
        return [IGPingResult makePingResult:self.sequence];
    } else {
        return [IGPingResult makePingResult:self.sequence ip:self.host ttl:[self getTTL] time:[self getRTT] reply:[self getReplyLength]];
    }
}

+(IGPingProcedure*) makePingProcedure:(NSString*)host sequence:(uint16_t) sequence  timeout:(NSTimeInterval) timeout {
    IGPingProcedure *obj = [[IGPingProcedure alloc]init];
    if(obj){
        obj.host        = host;
        obj.sendDate    = [NSDate date];
        obj.timeoutDate = [NSDate dateWithTimeInterval:timeout sinceDate:obj.sendDate];
        obj.sequence    = sequence;
    }
    return obj;
}

#pragma mark - description
-(NSString *)description {
    if (self.receivePacket) {
        return [NSString stringWithFormat:@"%d bytes from %@: icmp_seq=%d, ttl=%d, time=%.3f ms",
                [self getReplyLength], self.host, self.sequence, [self getTTL], [self getRTT]];
    } else {
        return [NSString stringWithFormat:@"Request timeout for icmp_seq %d", self.sequence];
    }
}

@end

@interface IGPingOperation()
@property (strong, atomic) NSArray *hostNameArray;
@property (strong, atomic) NSTimer *timer;

@property (strong, atomic) NSMutableDictionary *pingObjDict;
@property (strong, atomic) NSMutableDictionary *pingSummaryDict;
@property (strong, atomic) NSMutableDictionary *resultDict;

@property (weak, atomic)   id<IGPingOperationDelegate> delegate;
@end

@implementation IGPingOperation

#pragma mark - create

+ (IGPingOperation*) makePingOperation:(NSArray *)hostNameArray delegate:(id<IGPingOperationDelegate>) delegate {
    IGPingOperation *obj = [[IGPingOperation alloc] initWithAddress:hostNameArray];
    obj.delegate = delegate;
    return obj;
}

#pragma mark - Init/dealloc

- (id)initWithAddress:(NSArray*)hostNameArray {
	if (self = [self init]) {
        _hostNameArray      = hostNameArray;
        _repeatedTimes      = 4;
        _timeout            = 1;
    }
	return self;
}

#pragma mark - start and stop

- (void)start {
    if (_pingObjDict == nil) {
        _pingObjDict = [NSMutableDictionary dictionaryWithCapacity:_hostNameArray.count];
        _resultDict  = [NSMutableDictionary dictionaryWithCapacity:_hostNameArray.count];
        _pingSummaryDict = [NSMutableDictionary dictionaryWithCapacity:_hostNameArray.count];
        
        for (NSString* hostName in _hostNameArray) {
            IGPing *pingObj = [IGPing pingWithHostName:hostName];
            pingObj.delegate   = self;
            pingObj.payloadLen = 56;
            _pingObjDict[hostName] = pingObj;
            _resultDict[hostName] = [[IGPingStopResult alloc] init:hostName capacity:_repeatedTimes];
            _pingSummaryDict[hostName] = [NSMutableDictionary dictionary];
        }
        
        for (NSString* hostName in _pingObjDict) {
            IGPing *pingObj = _pingObjDict[hostName];
            if (pingObj) {
                [pingObj start];
            }
        }
    }
}

- (void)stop {    
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    if (_resultDict) {
        for (NSString *hostName in [_resultDict allKeys]) {
            [self finish:hostName];
        }
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(operationStop:)]) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self.delegate operationStop:self];
        });
    }
    _resultDict = nil;
    _pingSummaryDict = nil;
    _pingObjDict = nil;
}

-(void) finish:(NSString*) hostName {
    IGPing *pingObj  = _pingObjDict[hostName];
    if (!pingObj) {
        return;
    }
    
    [pingObj stop];
    [_pingObjDict removeObjectForKey:hostName];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(operation:finish:)]) {
        IGPingStopResult *result = _resultDict[hostName];
        if (result) {
            [result calcResult];
            [_resultDict removeObjectForKey:hostName];
            [_pingSummaryDict removeObjectForKey:hostName];
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self.delegate operation:self finish:result];
            });
        }
    }
    
    if (_resultDict.count == 0) {
        [self stop];
    }
}

- (void) finish:(NSString*)hostName procedure:(IGPingProcedure*) procedure {
    IGPingResult *result = [procedure getPingResult];
    if (self.delegate && [self.delegate respondsToSelector:@selector(operation:pingResult:)]) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self.delegate operation:self pingResult:result];
        });
    }
    IGPingStopResult *finiResult = _resultDict[hostName];
    [finiResult addResult:result];
    if ([finiResult isFull]) {
        [self finish:hostName];
    }
}

#pragma mark - check ping timeout

- (void) timerFireMethod:(NSTimer*)theTimer {
    for (NSString* hostName in [_pingSummaryDict allKeys]) {
        NSMutableDictionary *dict = _pingSummaryDict[hostName];
        for (NSNumber *key in [dict allKeys]) {
            IGPingProcedure *obj = dict[key];
            if (obj && [obj isTimeout] == YES) {
                [dict removeObjectForKey:key];
                [self finish:hostName procedure:obj];
            }
        }
    }
    // NSLog(@"in timer FileMethod");
}
#pragma mark - Pinger delegate

// When the pinger starts, send the ping immediately
- (void)ping:(IGPing *)pinger onStartup:(NSError *)error {
    IGPingStartResult *result;
    if (error) {
        result = [IGPingStartResult makePingStartResult:pinger.hostName error:error];
        NSLog(@"ping: %@", error);
    } else {
        __weak IGPing* pingObj = pinger;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            IGPing* strongPingObj = pingObj;
            for (NSInteger i=0; i<self.repeatedTimes; ++i) {
                if (strongPingObj) {
                    [strongPingObj sendPacket];
                    [NSThread sleepForTimeInterval:self.timeout/2];
                }
            }
        });
        
        if (!_timer) {
            _timer = [NSTimer scheduledTimerWithTimeInterval:self.timeout/4 target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:YES];
        }
        
        result = [IGPingStartResult makePingStartResult:pinger.hostName ip:[pinger getIpAddr] payload:pinger.payloadLen];
    }
    
    // call delegate
    if (self.delegate && [self.delegate respondsToSelector:@selector(operation:start:)]) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self.delegate operation:self start:result];
        });
    }
    
    // if error, finish
    if (error) {
        [self finish:pinger.hostName];
    }
}

- (void)ping:(IGPing *)pinger didFailWithError:(NSError *)error {
    NSLog(@"ping: %@", error);
    [self finish:pinger.hostName];
}

-(void)ping:(IGPing *)pinger didSendPacket:(uint16_t)sequence packet:(NSData *)packet {
    assert(sequence < _repeatedTimes);
    NSMutableDictionary *dict = _pingSummaryDict[pinger.hostName];
    if (dict) {
        NSNumber *key = [NSNumber numberWithInt:sequence];
        assert(dict[key] == nil);
        dict[key] = [IGPingProcedure makePingProcedure:[pinger getIpAddr] sequence:sequence timeout:self.timeout];
    }
}

- (void)ping:(IGPing *)pinger didFailToSendPacket:(uint16_t)sequence packet:(NSData *)packet error:(NSError *)error {
	// Eg they're not connected to any network
    [self ping:pinger didSendPacket:sequence packet:packet];
    NSLog(@"ping: %@", error);
}

- (void)ping:(IGPing *)pinger didReceivePacket:(uint16_t)sequence packet:(NSData *)packet {
    NSMutableDictionary *dict = _pingSummaryDict[pinger.hostName];
    if (dict) {
        NSNumber *key = [NSNumber numberWithInt:sequence];
        IGPingProcedure *obj = dict[key];
        if (obj && [obj isTimeout] == NO) {
            [dict removeObjectForKey:key];
            obj.receivePacket = packet;
            [self finish:pinger.hostName procedure:obj];
        }
    }
}

@end
