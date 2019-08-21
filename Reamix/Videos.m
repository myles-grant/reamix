//
//  Videos.m
//  Reamix
//
//  Created by myles grant on 2014-11-05.
//  Copyright (c) 2014 Pinecone. All rights reserved.
//

#import "Videos.h"

@interface Videos () {
    
    Connect *connect;
    VideoCustomCell *previewCellImage;
    
    NSArray *videoArray;
    NSManagedObject *cellObject;
    UIActionSheet *videoPopUnderOptions;
    NSInteger videoPopUnderOptionsIndex;
    
    MPMoviePlayerViewController *player;
}

//UI properties
@property (weak, nonatomic) IBOutlet UILabel *novids;
@property (weak, nonatomic) IBOutlet UICollectionView *videoCollectionView;
@property (weak, nonatomic) IBOutlet UINavigationBar *nav;
//@property (weak, nonatomic) IBOutlet UIBarButtonItem *settings;

@end

@implementation Videos
@synthesize novids, videoCollectionView, nav;//settings



- (void)viewDidLoad
{
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    
    //Setup context through connect Class
    connect = [[Connect alloc] init];
    
    // attach long press gesture to collectionView
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 0.5; //seconds
    lpgr.delegate = self;
    lpgr.delaysTouchesBegan = YES;
    [videoCollectionView addGestureRecognizer:lpgr];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //Get device dimensions
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    //CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    //AdMob Setup
    /*
    bannerAd = [[GADBannerView alloc] initWithFrame:CGRectMake(0, screenHeight-50, 320, 50)];
    bannerAd.adUnitID = @"ca-app-pub-6203734760680566/7934616733";
    bannerAd.rootViewController = self;
    [self.view addSubview:bannerAd];
    [bannerAd loadRequest:[GADRequest request]];
     */
    
    //Status bar
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [videoCollectionView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Collection Cell Setup


-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //Get Images for videos
    //NSString *path = [[connect getDoc] stringByAppendingPathComponent:[[videoArray objectAtIndex:indexPath.item] valueForKey:@"videoUrl"]];
    
    //AVURLAsset *asset1 = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:path]];
    
    //AVAssetImageGenerator *generate = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset1];
    //generate.appliesPreferredTrackTransform = YES;

    
    //Set Cell
    VideoCustomCell *cell = (VideoCustomCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"videoCell" forIndexPath:indexPath];
    
    //Set object to populate cells
    cellObject = [videoArray objectAtIndex:indexPath.item];
    
    
    //Write to item
    //[cell.videoPreviewImage setImage:[UIImage imageWithCGImage:[generate copyCGImageAtTime:CMTimeMake(1, 2) actualTime:NULL error:nil]]];
    [cell.time setText:[cellObject valueForKeyPath:@"duration"]];
    
    return cell;
}


-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    videoArray = [connect getContextArray:@"Videos"];
    
    if([videoArray count] > 0)
    {
        novids.hidden = YES;
    }
    else
    {
        novids.hidden = NO;
    }
    
    return [videoArray count];
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}


#pragma mark - Cell Selection

//When cell is tapped
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *path = [[connect getDoc] stringByAppendingPathComponent:[[videoArray objectAtIndex:indexPath.item] valueForKey:@"videoUrl"]];
    player = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:path]];
    
    [self presentMoviePlayerViewControllerAnimated:player];
}


//When cell is held
-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        // get the cell at indexPath
        CGPoint p = [gestureRecognizer locationInView:videoCollectionView];
        NSIndexPath *indexPath = [videoCollectionView indexPathForItemAtPoint:p];
        
        if(indexPath != nil)
        {
            //Get index
            videoPopUnderOptionsIndex = indexPath.item;
            
            //
            videoPopUnderOptions = [[UIActionSheet alloc] initWithTitle:@"Select a Option" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:
                                    //@"Edit",
                                    @"Save to Camera Roll",
                                    nil];
            videoPopUnderOptions.tag = 1;
            [videoPopUnderOptions showInView:self.view];
             
        }
    }
    else if(gestureRecognizer.state == UIGestureRecognizerStateChanged)
    {
        //Collapse previous option set
    }
}


-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *path = [[connect getDoc] stringByAppendingPathComponent:[[videoArray objectAtIndex:videoPopUnderOptionsIndex] valueForKey:@"videoUrl"]];
    if(videoPopUnderOptions.tag == 1)
    {
        switch (buttonIndex)
        {
            case 0:
            {
                //Delete
                NSLog(@"Delete");
                
                //delete file
                NSFileManager *fileManager = [NSFileManager defaultManager];
                NSError *error;
                BOOL success = [fileManager removeItemAtPath:path error:&error];
                if (!success)
                {
                    NSLog(@"Could not delete recorded file -: %@ ",[error localizedDescription]);
                }
                
                //delete context
                [connect deleteObjectIn:@"Videos" atIndex:videoPopUnderOptionsIndex];
                
                [videoCollectionView reloadData];
            }
            break;
             /*
            case 1:
                //Edit
                NSLog(@"Edit");
                break;
               */
            case 1:
            {
                //Save
                NSLog(@"Save");
                
                UISaveVideoAtPathToSavedPhotosAlbum(path,nil,nil,nil);
                switch ([ALAssetsLibrary authorizationStatus])
                {
                    case ALAuthorizationStatusAuthorized:
                        NSLog(@"authorized");
                    break;
                    
                    case ALAuthorizationStatusDenied:
                    {
                        NSLog(@"denied");
                        
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Access Denied" message:@"Your video cannot be saved because access to your photos library was denied. You can allow access within your settings app" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                        [alert show];
                    }
                    break;
                    
                    case ALAuthorizationStatusNotDetermined:
                        NSLog(@"not determined");
                    break;
                    
                    case ALAuthorizationStatusRestricted:
                    {
                        NSLog(@"restricted");
                        
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Access Restricted" message:@"Your video cannot be saved because access to your photos library is restricted." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                        [alert show];
                    }
                    break;
                }
            }
            break;
        }
    }
}


#pragma mark - Navigation

- (IBAction)toCamera:(id)sender
{
    //[self performSegueWithIdentifier:@"videosViewToCameraView" sender:self];
}

- (IBAction)toSettings:(id)sender
{
    [self performSegueWithIdentifier:@"videosViewToSettingsView" sender:self];
}


/*
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
