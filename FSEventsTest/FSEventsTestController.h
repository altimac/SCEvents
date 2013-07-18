#import <Cocoa/Cocoa.h>

@class SCFileSystemWatcher;
@class SCEventInterpreter;

@interface FSEventsTestController : NSObject {
    
}

@property(strong,nonatomic) SCFileSystemWatcher *watcher;
@property(strong,nonatomic) SCEventInterpreter *interpreter;

@end
