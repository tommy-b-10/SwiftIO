//
//  SwiftIOSupport.h
//  SwiftIO
//
//  Created by Jonathan Wight on 9/28/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

#ifndef SwiftIOSupport_h
#define SwiftIOSupport_h

// Generally contains code that cannot be represented as pure Swift for whatever reasons.

extern NSDictionary *getAddressesForInterfaces();
extern int setNonblocking(int socket, BOOL flag);
extern void fdZero(fd_set* fdSet);
extern void fdSet(int fd, fd_set* fdset);
extern int fdIsSet(int fd, fd_set* fdset);

#endif /* SwiftIOSupport_h */
