//
//  SCFileSystemOperation.h
//  FSEventsTest
//
//  Created by Aurélien Hugelé on 17/07/13.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SCFileSystemOperationType) {
    SCFileSystemOperationUnknown      = 0x00000000,
	SCFileSystemOperationCreate       = 0x00000001,
    SCFileSystemOperationDelete       = 0x00000002, // effectively deleted from disk
    SCFileSystemOperationModification = 0x00000004, // edited in place
    SCFileSystemOperationCopy         = 0x00000008, // impossible to detect? Copy with Finder could probably be detected with kFSEventStreamEventFlagItemInodeMetaMod+kFSEventStreamEventFlagItemCreated, but this is a side effect of the finder. Copying via Terminal does not set kFSEventStreamEventFlagItemInodeMetaMod... NOT USED AT THIS TIME
    
    SCFileSystemOperationMove              = 0x01000000, // Move acts as a mask for other type of move
	SCFileSystemOperationMoveWithin        = 0x00010000,
    SCFileSystemOperationMoveIncoming      = 0x00020000,
    SCFileSystemOperationMoveOutgoing      = 0x00040000,
    SCFileSystemOperationMoveToTrash       = 0x00080000 , // moved to trash, but not deleted from disk yet
    SCFileSystemOperationResurectFromTrash = 0x00100000 , // in the trash and moved anywhere else! it's a move!
    
    SCFileSystemOperationRename  = 0x00000010,
};

@interface SCFileSystemOperation : NSObject <NSCoding>

-(id)initWithOldPath:(NSString*)oldPath path:(NSString*)path operationType:(SCFileSystemOperationType)type;

/*
 
 if type is SCFileSystemOperationUnknown @parameter oldPath is nil, and @parameter path is nil
 if type is SCFileSystemOperationCreate @parameter oldPath is nil, @parameter path is the path where the file has been created
 if type is SCFileSystemOperationRename @parameter oldPath is old path of the renamed file, @parameter path is the new path of the file. @parameter oldPath and @parameter path MAY share the same base path, the file MAY have moved. The name of the file changed (last path component is different)
 if type is SCFileSystemOperationMove we know the file parent folder has changed (move). Can be bitwise unioned with: - SCFileSystemOperationRename: it means the file has been renamed while moving!
 - SCFileSystemOperationMoveWithin: @parameter oldPath is old path of the file, @parameter path is the new path of the file. The file has moved within watched pathes. Compatible with SCFileSystemOperationRename.
 - SCFileSystemOperationMoveInside: @parameter oldPath is nil because the source file was located in an unknown NON watched path, @path is the new path of the file. Mutually exclusive with SCFileSystemOperationRename: we can't know if the file has been renamed while moving :(
 - SCFileSystemOperationMoveOutside: @parameter oldPath is old path of the file, @parameter path is nil because the destination is unknown and located in a NON watched path. Mutually exclusive with SCFileSystemOperationRename: we can't know if the file has been renamed while moving :(
 
 CURRENTLY UNUSED !!! if type is SCFileSystemOperationCopy @parameter oldPath is path of the source file, @parameter path is the path of the copy file. @parameter oldPath and @parameter path may not share the same base path, and the name of the file may have changed too! !!!!
 if type is SCFileSystemOperationTrash @parameter oldPath is path of the trashed file (moved to trash), @parameter path is the new path of the trashed file. @parameter path may have changed since Apple may rename trashed files to avoid duplicates in the Trash (typically add a ' N' at the end of trashed file name)
 if type is SCFileSystemOperationDelete @parameter oldPath is path of the deleted file (may be in the trash), @parameter path is nil
 
 */

@property(assign,readonly) SCFileSystemOperationType operationType;
@property(strong) NSString *oldPath;
@property(strong) NSString *path;

@property(assign,readonly) BOOL isDirectory;

-(NSDictionary*)dictionaryRepresentation;

@end
