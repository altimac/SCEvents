#import "FSEventsTestController.h"

#include <CoreServices/CoreServices.h>
#import "SCFileSystemWatcher.h"
#import "SCEventInterpreter.h"
#import "SCFileSystemOperation.h"
#import "SCEvent.h"

#define LOG_EVERY_EVENTS 0 // set to 1 if you want to see a description of every events (before their possible interpretation)
#define LOG_BATCHED_EVENTS 1
#define WATCH_FILE_EVENTS 0
#define INTERPRET_EVENTS 0

#define WATCHED_PATH @"/Volumes/Data/Users/aure/FSEventsTests/"
#define WATCHED_TRASH_PATH [NSSearchPathForDirectoriesInDomains(NSTrashDirectory, NSUserDomainMask, YES) objectAtIndex:0]

static UInt64 global_operation_counter = 0;

@interface FSEventsTestController () <SCEventListenerProtocol>

@end

@implementation FSEventsTestController

-(void)applicationDidFinishLaunching:(NSNotification*)aNotif
{
	NSString *mypath = WATCHED_PATH;
    NSString *trashPath = WATCHED_TRASH_PATH; // this is because watching Trash helps determining if the file has been deleted *from user point of view*. Trashing a file is in fact a move (to the trash), but most users consider that it's a file deletion...
    
    self.watcher = [[SCFileSystemWatcher alloc] init];
    self.watcher.notificationLatency = 10.0;
    [self.watcher setDelegate:self];

    FSEventStreamCreateFlags flags = kFSEventStreamCreateFlagIgnoreSelf;
#if WATCH_FILE_EVENTS
    flags = flags | kFSEventStreamCreateFlagFileEvents;
#endif

    [self.watcher startWatchingPaths:@[mypath,trashPath] flags:flags since:kFSEventStreamEventIdSinceNow];
    
    self.interpreter = [[SCEventInterpreter alloc] initWithPathes:@[mypath] trashPath:trashPath];
    self.interpreter.ignoreTrashInterpretationErrors = YES;
    
}

#if LOG_EVERY_EVENTS
- (void)pathWatcher:(SCFileSystemWatcher *)pathWatcher eventOccurred:(SCEvent *)event
{
    NSLog(@"SCEvent:%@",event);
}
#endif

- (void)pathWatcher:(SCFileSystemWatcher *)pathWatcher eventsOccurred:(NSArray *)events
{
#if LOG_BATCHED_EVENTS
    NSLog(@"\n====================================\nBatched Events:\n%@",events);
#endif
    
    //    NSError *error;
    //    NSArray *operations = [self.interpreter interpretEvents:events error:&error];
    //    if(!operations)
    //    {
    //        NSLog(@"Error occured during FS events interpretation:%@",error);
    //    }
    //    else
    //    {
    //        for (SCFileSystemOperation *op in operations) {
    //            NSLog(@"Operation %lld:%@",global_operation_counter++,op);
    //        }
    //    }

#if INTERPRET_EVENTS
    [self.interpreter asyncInterpretEvents:(NSArray*)events latency:30.0 completionBlock:^(NSArray *operations, NSError *error) {
        
        if(!operations)
        {
            NSLog(@"Error occured during FS events interpretation:%@",error);
        }
        
        for (SCFileSystemOperation *op in operations) {
            NSLog(@"Operation %lld:%@",global_operation_counter++,op);
        }
        
    }];
    
#endif
}


@end
