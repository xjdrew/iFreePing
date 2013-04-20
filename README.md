iFreePing
=========
IGPing is a full featured ios ping library. iFreePing is based on IGPing.

![iFreePing Demo Screen](http://github.com/xjdrew/iFreePing/doc/iFreePing-screen-2013-4-21.png)

Overview
--------
IGPing is similar with Apple SimplePing, but code is much more clean and support ARC.

Usage
----- 
1. create IGPingOperation object
``` objective-c
self.pingOperation = [IGPingOperation makePingOperation:self.hostField.text delegate:self];
        [self.pingOperation start];
```
2. deal with IGPingOperationDelegate, there are three optional delegate method.
``` objective-c
-(void) operation:(IGPingOperation *)operation start:(IGPingStartResult *) result {
    [self log:[result description]];
}

-(void) operation:(IGPingOperation *)operation pingResult:(IGPingResult *)result {
    [self log:[result description]];
}

-(void) operation:(IGPingOperation *)operation stop:(IGPingStopResult *)result {
    [self log:[result description]];
}
```

3. can stop by hand
```objective-c
[self.pingOperation stop];
```

Copyright & License
-------------------
Copyright 2013 xjdrew
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this work except in compliance with the License. You may obtain a copy of the License in the LICENSE file, or at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
