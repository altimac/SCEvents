//
//  SCFileSystemOperation.h
//  FSEventsTest
//
//  Created by Aurélien Hugelé on 17/07/13.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SCFileSystemOperationType) {
    SCFileSystemOperationUnknown = 0x00000000,
	SCFileSystemOperationCreate  = 0x00000001,
    SCFileSystemOperationDelete  = 0x00000002, // completely deleted from disk
    SCFileSystemOperationCopy    = 0x00000004, // impossible to detect?
    
    SCFileSystemOperationMove              = 0x01000000, // Move acts as a mask for other type of move
	SCFileSystemOperationMoveWithin        = 0x00010000,
    SCFileSystemOperationMoveIncoming      = 0x00020000,
    SCFileSystemOperationMoveOutgoing      = 0x00040000,
    SCFileSystemOperationMoveToTrash       = 0x00080000 , // moved to trash, but not deleted from disk yet
    SCFileSystemOperationResurectFromTrash = 0x00100000 , // in the trash and moved anywhere else! it's a move!
    
    SCFileSystemOperationRename  = 0x00000008,
};

@interface SCFileSystemOperation : NSObject

-(id)initWithOldPath:(NSString*)oldPath path:(NSString*)path operationType:(SCFileSystemOperationType)type;

@property(assign,readonly) SCFileSystemOperationType operationType;

/*
 
 if type is SCFileSystemOperationUnknown @oldPath is nil, and @path is nil
 if type is SCFileSystemOperationCreate @oldPath is nil, @path is the path where the file has been created
 if type is SCFileSystemOperationRename @oldPath is old path of the renamed file, @path is the new path of the file. @oldPath and @path MAY share the same base path, the file MAY have moved. The name of the file changed (last path component is different)
 if type is SCFileSystemOperationMove we know the file parent folder has changed (move). Can be bitwise unioned with: - SCFileSystemOperationRename: it means the file has been renamed while moving!
                                                                                                                      - SCFileSystemOperationMoveWithin: @oldPath is old path of the file, @path is the new path of the file. The file has moved within watched pathes. Compatible with SCFileSystemOperationRename.
                                                                                                                      - SCFileSystemOperationMoveInside: @oldPath is nil because the source file was located in an unknown NON watched path, @path is the new path of the file. Mutually exclusive with SCFileSystemOperationRename: we can't know if the file has been renamed while moving :(
                                                                                                                      - SCFileSystemOperationMoveOutside: @oldPath is old path of the file, @path is nil because the destination is unknown and located in a NON watched path. Mutually exclusive with SCFileSystemOperationRename: we can't know if the file has been renamed while moving :(
 
 if type is SCFileSystemOperationCopy @oldPath is path of the source file, @path is the path of the copy file. @oldPath and @path may not share the same base path, and the name of the file may have changed too!
 if type is SCFileSystemOperationTrash @oldPath is path of the trashed file (moved to trash), @path is the new path of the trashed file. @path may have changed since Apple may rename trashed files to avoid duplicates in the Trash (typically add a ' N' at the end of trashed file name)
 if type is SCFileSystemOperationDelete @oldPath is path of the deleted file (may be in the trash), @path is nil

 */


@property(strong) NSString *oldPath;
@property(strong) NSString *path;

//@property(strong,readonly) basePath;
//@property(strong,readonly) baseURL;
//@property(strong,readonly) pathComponent;
//@property(strong,readonly) fileName;
//@property(strong,readonly) fileExtension; // without "."
@property(assign,readonly) BOOL isDirectory;
//@property(BOOL,readonly) isTrashed; // is the file in trash ?

@end
