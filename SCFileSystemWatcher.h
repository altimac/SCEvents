/*
 *  $Id: SCEvents.h 205 2011-06-18 15:16:08Z stuart $
 *
 *  SCEvents
 *  http://stuconnolly.com/projects/code/
 *
 *  Copyright (c) 2011 Stuart Connolly. All rights reserved.
 *
 *  Permission is hereby granted, free of charge, to any person
 *  obtaining a copy of this software and associated documentation
 *  files (the "Software"), to deal in the Software without
 *  restriction, including without limitation the rights to use,
 *  copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the
 *  Software is furnished to do so, subject to the following
 *  conditions:
 *
 *  The above copyright notice and this permission notice shall be
 *  included in all copies or substantial portions of the Software.
 * 
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 *  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 *  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 *  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 *  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 *  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 *  OTHER DEALINGS IN THE SOFTWARE.
 */

#import <Foundation/Foundation.h>
#if TARGET_OS_EMBEDDED || TARGET_OS_IPHONE || TARGET_OS_WIN32
#import <CFNetwork/CFNetwork.h>
#else
#import <CoreServices/CoreServices.h>
#endif


#import "SCEventListenerProtocol.h"

@class SCEvent;

/**
 * @class SCEvents SCEvents.h
 *
 * @author Stuart Connolly http://stuconnolly.com/
 *
 * An Objective-C wrapper for the FSEvents C API.
 */
@interface SCFileSystemWatcher : NSObject 
{
    __weak id <SCEventListenerProtocol> _delegate;
    
    BOOL                 _isWatchingPaths;
    BOOL                 _ignoreEventsFromSubDirs;
    FSEventStreamCreateFlags _createFlags;
	CFRunLoopRef         _runLoop;
    FSEventStreamRef     _eventStream;
    
    CFTimeInterval       _notificationLatency;
	FSEventStreamEventId _resumeFromEventId;
      
    SCEvent              *_lastEvent;
    NSArray              *_watchedPaths;
    NSSet              *_excludedPaths;
	
    dispatch_queue_t     _eventsQueue;
}

/**
 * @property _delegate The delegate that SCEvents is to notify when events occur
 */
@property (readwrite, weak, getter=delegate, setter=setDelegate:) id <SCEventListenerProtocol> _delegate;

/**
 * @property _isWatchingPaths Indicates whether the events stream is currently running
 */
@property (readonly, getter=isWatchingPaths) BOOL _isWatchingPaths;

/**
 * @property _ignoreEventsFromSubDirs Indicates whether events from sub-directories of the excluded paths are ignored. Defaults to NO. This 
 */
@property (readwrite, assign, getter=ignoreEventsFromSubDirs, setter=setIgnoreEventsFromSubDirs:) BOOL _ignoreEventsFromSubDirs;

/**
 * @property _createFags Indicates flags that were used to create the stream. Defaults to kFSEventStreamCreateFlagNone. Not available until the stream is created internally!
 */
@property (readonly, assign, getter=createFlags) FSEventStreamCreateFlags _createFlags;

/**
 * @property _lastEvent The last event that occurred and that was delivered to the delegate.
 */
@property (readwrite, strong, getter=lastEvent, setter=setLastEvent:) SCEvent *_lastEvent;

/**
 * @property _notificationLatency The latency time of which SCEvents is notified by FSEvents of events. Defaults to 3 seconds.
 */
@property (readwrite, assign, getter=notificationLatency, setter=setNotificationLatency:) CFTimeInterval _notificationLatency;

/**
 * @property _watchedPaths The paths that are to be watched for events.
 */
@property (readwrite, strong, getter=watchedPaths, setter=setWatchedPaths:) NSArray *_watchedPaths;

/**
 * @property _excludedPaths The paths that SCEvents should ignore events from and not deliver to the delegate.
 */
@property (readwrite, strong, getter=excludedPaths, setter=setExcludedPaths:) NSSet *_excludedPaths;

- (BOOL)flushEventStreamSync;
- (BOOL)flushEventStreamAsync;

/**
 * Starts watching the supplied array of paths for events on the current run loop.
 *
 * @param paths An array of paths to watch
 * @param flags a bitwise union of flags to pass to the stream. Typically kFSEventStreamCreateFlagIgnoreSelf|kFSEventStreamCreateFlagFileEvents
 * @param sinceWhen 0 means from the begining of time... Typically pass the last eventEvent eventId value or kFSEventStreamEventIdSinceNow
 *
 * @return A BOOL indicating the success or failure
 */

- (BOOL)startWatchingPaths:(NSArray *)paths flags:(FSEventStreamCreateFlags)createFlags since:(FSEventStreamEventId)sinceWhen;

/**
 * Starts watching the supplied array of paths for events on the supplied run loop.
 * A boolean value is returned to indicate the success of starting the stream. If
 * there are no paths to watch or the stream is already running then false is
 * returned.
 *
 * @param paths   An array of paths to watch
 * @param flags a bitwise union of flags to pass to the stream. Typically kFSEventStreamCreateFlagIgnoreSelf|kFSEventStreamCreateFlagFileEvents
 * @param sinceWhen 0 means from the begining of time... Typically pass the last eventEvent eventId value or kFSEventStreamEventIdSinceNow
 * @param runLoop The runloop the events stream is to be scheduled on
 *
 * @return A BOOL indicating the success or failure
 */

- (BOOL)startWatchingPaths:(NSArray *)paths flags:(FSEventStreamCreateFlags)createFlags since:(FSEventStreamEventId)sinceWhe onRunLoop:(NSRunLoop *)runLoop;

- (BOOL)stopWatchingPaths;

- (NSString *)streamDescription;

@end
