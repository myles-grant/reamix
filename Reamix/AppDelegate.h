//
//  AppDelegate.h
//  Reamix
//
//  Created by myles grant on 2014-11-04.
//  Copyright (c) 2014 Pinecone. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Camera.h"

@class Camera;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

//Class properties
@property (strong, nonatomic) Camera *camera;

//
@property (strong, nonatomic) UIWindow *window;

//Core Data properties
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

//
- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
