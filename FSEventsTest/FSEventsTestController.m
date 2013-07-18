#import "FSEventsTestController.h"

#include <CoreServices/CoreServices.h>
#import "SCFileSystemWatcher.h"
#import "SCEventInterpreter.h"
#import "SCFileSystemOperation.h"
#import "SCEvent.h"

#define WATCHED_PATH @"/Volumes/Data/Users/aure/FSEventsTests/"
#define WATCHED_TRASH_PATH [NSSearchPathForDirectoriesInDomains(NSTrashDirectory, NSUserDomainMask, YES) objectAtIndex:0]

@interface FSEventsTestController () <SCEventListenerProtocol>

@end

@implementation FSEventsTestController

-(void)applicationDidFinishLaunching:(NSNotification*)aNotif
{
	NSString *mypath = WATCHED_PATH;
    NSString *trashPath = WATCHED_TRASH_PATH; // this is because watching Trash helps determining if the file has been deleted *from user point of view*. Trashing a file is in fact a move (to the trash), but most users consider that it's a file deletion...

    self.watcher = [[SCFileSystemWatcher alloc] init];
    [self.watcher setDelegate:self];    
    [self.watcher startWatchingPaths:@[mypath,trashPath] flags:kFSEventStreamCreateFlagFileEvents];
    
    self.interpreter = [[SCEventInterpreter alloc] initWithPathes:@[mypath] trashPath:trashPath];
    self.interpreter.ignoreTrashInterpretationErrors = YES;
    
}

- (void)pathWatcher:(SCFileSystemWatcher *)pathWatcher eventOccurred:(SCEvent *)event
{
    NSLog(@"SCEvent:%@",event);
}

- (void)pathWatcher:(SCFileSystemWatcher *)pathWatcher eventsOccurred:(NSArray *)events
{
    NSError *error;
    NSArray *operations = [self.interpreter interpretEvents:events error:&error];
    if(!operations)
    {
        NSLog(@"Error occured during FS events interpretation:%@",error);
    }
    else
    {
        NSUInteger i = 0;
        for (SCFileSystemOperation *op in operations) {
            NSLog(@"Operation%ld:%@",i,op);
            i++;
        }
    }
}


@end
