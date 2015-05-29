//
//  BSVideoDetailController.m
//  YouTubeDraggableVideo
//
//  Created by Sandeep Mukherjee on 02/02/15.
//  Copyright (c) 2015 Sandeep Mukherjee. All rights reserved.
//


#import "BSVideoDetailController.h"
#import "QuartzCore/CALayer.h"



@interface BSVideoDetailController ()
@end



@implementation BSVideoDetailController
{
    //local Frame store
    CGRect videoWrapperFrame;
    CGRect minimizedVideoFrame;
    CGRect pageWrapperFrame;

    CGRect wFrame;
    CGRect vFrame;
    
    //local touch location
    CGFloat _touchPositionInHeaderY;
    CGFloat _touchPositionInHeaderX;
    
    //local restriction Offset--- for checking out of bound
    float minimizedOffsetX,minimizedOffsetY;//,restictYaxis;
    
    //detecting Pan gesture Direction
    UIPanGestureRecognizerDirection direction;
    
    
    //Creating a transparent Black layer view
    UIView *transparentBlackSheet;
    
    //Just to Check wether view  is expanded or not
    BOOL isExpandedMode;
    
    
    
    UIView *pageWrapper;
    UIView *videoWrapper;
    UIButton *foldButton;

    UIView *videoView;
    
    UIView *bodyArea;
}

//@synthesize player;





//PLEASE OVERRIDE
//- (void)viewDidLoad {
//    [super viewDidLoad];

//    UIView *vView = [[UIView alloc] init];
//    vView.backgroundColor = [UIColor redColor];
//    
//    [self setupWithVideoView: vView
//            videoWrapperView: self.ibVideoWrapperView
//             pageWrapperView: self.ibWrapperView
//                  foldButton: self.ibFoldBtn];
//}


//PLEASE OVERRIDE
- (BOOL) isFullScreen {
    NSLog(@"isFullScreen");
    NSAssert(NO, @"This is an abstract method and should be overridden!!!!!!!!!");
    return false;
}

//PLEASE OVERRIDE
- (void) goFullScreen {
    NSLog(@"goFullScreen");
    NSAssert(NO, @"This is an abstract method and should be overridden!!!!!!!!!!!");
    //                    self.secondViewController.player.controlStyle =  MPMovieControlStyleDefault;
    //                    self.secondViewController.player.fullscreen = YES;
    //                      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willExitFullscreen:) name:MPMoviePlayerWillExitFullscreenNotification object:nil];
}
//    - (void)willExitFullscreen:(NSNotification*)notification {
//    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]))
//    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger: UIInterfaceOrientationPortrait] forKey:@"orientation"];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerWillExitFullscreenNotification object:nil];
//    }





- (void) setupWithVideoView: (UIView *)vView
           videoWrapperView: (UIView *)ibVideoWrapperView
            pageWrapperView: (UIView *)ibWrapperView
                 foldButton: (UIButton *)ibFoldBtn
{
    videoView = vView;
    videoWrapper = ibVideoWrapperView;
    pageWrapper = ibWrapperView;
    foldButton = ibFoldBtn;
    
    // [[BSUtils sharedInstance] showLoadingMode:self];

    //adding Pan Gesture
    UIPanGestureRecognizer *pan=[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panAction:)];
    pan.delegate=self;
    [videoWrapper addGestureRecognizer:pan];

    //setting view to Expanded state
    isExpandedMode=TRUE;
    
    foldButton.hidden=TRUE;
    [foldButton addTarget:self action:@selector(onTapDownButton) forControlEvents:UIControlEventTouchUpInside];
    
    // orientation behaver
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];

    //adding demo Video -- giving a little delay to store correct frame size
    [self performSelector:@selector(calculateFrames) withObject:nil afterDelay:0.25];

}

- (void) beforeApperAnimation {

    CGFloat videoHeight = videoWrapper.frame.size.height;
    
    bodyArea = [[UIView alloc] init];
    bodyArea.frame = CGRectMake(0,
                                videoHeight,
                                self.parentViewFrame.size.width,
                                self.parentViewFrame.size.height - videoHeight);
    [pageWrapper addSubview:bodyArea];

    bodyArea.backgroundColor = [[UIColor orangeColor] colorWithAlphaComponent:0.1f];
    bodyArea.layer.borderColor = [[[UIColor cyanColor] colorWithAlphaComponent:0.2f] CGColor];
    bodyArea.layer.borderWidth = 1.0f;
}



#pragma mark- Calculate Frames and Store Frame Size

-(void)calculateFrames
{
    
    
    [videoView setFrame:videoWrapper.frame];
    [videoWrapper addSubview:videoView];
    
    videoWrapperFrame = videoWrapper.frame;
    pageWrapperFrame = pageWrapper.frame;
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    
    // disable AutoLayout
    videoWrapper.translatesAutoresizingMaskIntoConstraints = YES;
    pageWrapper.translatesAutoresizingMaskIntoConstraints = YES;
    
    videoWrapper.frame = videoWrapperFrame;
    pageWrapper.frame = pageWrapperFrame;
    
    wFrame = pageWrapper.frame;
    vFrame = videoWrapper.frame;
    
    minimizedOffsetX = self.parentViewFrame.size.width - 200;
    minimizedOffsetY = self.parentViewFrame.size.height - 180;
    
    
    //self.videoView.layer.shouldRasterize=YES;
    //self.viewYouTube.layer.shouldRasterize=YES;
    //self.viewTable.layer.shouldRasterize=YES;
    
    
    videoView.backgroundColor = videoWrapper.backgroundColor = [UIColor clearColor];

    //[[BSUtils sharedInstance] hideLoadingMode:self];
    self.view.hidden = TRUE;
    
    
    
    transparentBlackSheet = [[UIView alloc] initWithFrame:self.parentViewFrame];
    transparentBlackSheet.backgroundColor = [UIColor blackColor];
    transparentBlackSheet.alpha = 0.9;
    
    [self.onView addSubview:transparentBlackSheet];
    [self.onView addSubview:pageWrapper];
    [self.onView addSubview:videoWrapper];
    
    
    [videoView addSubview:foldButton];
    [NSTimer scheduledTimerWithTimeInterval:0.4f
                                     target:self
                                   selector:@selector(showFoldButton)
                                   userInfo:nil
                                    repeats:NO];
}






#pragma mark - Button Action

- (void) onTapDownButton {
    [self minimizeViewOnPan];
    NSLog(@"onTapButons");
}

//- (IBAction)btnDownTapAction:(id)sender {
//    NSLog(@"btnDownTapAction");
//    [self minimizeViewOnPan];
//}



#pragma mark - Orientation

- (void)orientationChanged:(NSNotification *)notification{
    [self adjustViewsForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
}



- (void) adjustViewsForOrientation:(UIInterfaceOrientation) orientation {
    
    NSLog(@"adjust for orientation:%ld", (long)orientation);
    
    switch (orientation)
    {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
        {
            NSLog(@"portrait called;");
            //load the portrait view
                // FIX: rewrite after
            if([self isFullScreen])
            {
                if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]))
                {
                    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger: UIInterfaceOrientationPortrait] forKey:@"orientation"];
                }
            }
            
        }
        break;

        //　横だったら、フルスクリーンにする
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
        {
            NSLog(@"landscape called;");
            
//            if(self.secondViewController!=nil)
//            {
            
            
                 if(![self isFullScreen])// && wrapperView.alpha >= 1)
                {
                
                    // FIX: rewrite after
                    [self goFullScreen];
                }
                /* else if( self.secondViewController.viewTable.alpha<=0)
                 {
                 if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]))
                 [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger: UIInterfaceOrientationPortrait] forKey:@"orientation"];
                 } */
//            }
        }
        break;
        
        case UIInterfaceOrientationUnknown:break;
    }
}












#pragma mark- Status Bar Hidden function

- (BOOL)prefersStatusBarHidden {
    return YES;
}
- (NSUInteger) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}
- (BOOL)shouldAutorotate
{
    return NO;
}





- (void) showFoldButton {
    NSLog(@"show downButton");
//    [videoWrapperView bringSubviewToFront:foldButton];
    foldButton.hidden = FALSE;
}













#pragma mark- Pan Animation

- (void)expandViewOnTap:(UITapGestureRecognizer*)sender {
    NSLog(@"expandViewOnTap");
    [self expandViewOnPan];
    for (UIGestureRecognizer *recognizer in videoWrapper.gestureRecognizers) {
        
        if([recognizer isKindOfClass:[UITapGestureRecognizer class]]) {
            [videoWrapper removeGestureRecognizer:recognizer];
        }
    }
}


-(void)expandViewOnPan
{
    NSLog(@"expandViewOnPan");
    //        [self.txtViewGrowing resignFirstResponder];
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^ {
                         pageWrapper.frame = pageWrapperFrame;
                         videoWrapper.frame=videoWrapperFrame;
                         videoWrapper.alpha=1;
                         videoView.frame=videoWrapperFrame;
                         pageWrapper.alpha=1.0;
                         transparentBlackSheet.alpha=1.0;
                         
                         bodyArea.frame = CGRectMake(
                                                     0,
                                                     videoView.frame.size.height,// keep stay on bottom of videoView
                                                     bodyArea.frame.size.width,
                                                     bodyArea.frame.size.height
                                                     );
                     }
                     completion:^(BOOL finished) {
                         //                         player.controlStyle = MPMovieControlStyleDefault;
                         [self.delegate onExpanded];
                         isExpandedMode=TRUE;
                         foldButton.hidden=FALSE;
                     }];
}



-(void)minimizeViewOnPan
{
    foldButton.hidden = TRUE;
    //    [self.txtViewGrowing resignFirstResponder];
    CGFloat trueOffset = self.parentViewFrame.size.height - 100;
    CGFloat xOffset = self.parentViewFrame.size.width - 160;
    
    //Use this offset to adjust the position of your view accordingly
    wFrame.origin.y = trueOffset;
    wFrame.origin.x = xOffset;
    wFrame.size.width=self.parentViewFrame.size.width - xOffset;
    //menuFrame.size.height=200-xOffset*0.5;
    
    // viewFrame.origin.y = trueOffset;
    //viewFrame.origin.x = xOffset;
    vFrame.size.width = self.view.bounds.size.width - xOffset;
    vFrame.size.height = 200 - xOffset * 0.5;
    vFrame.origin.y = trueOffset;
    vFrame.origin.x = xOffset;
    
    
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^ {
                         pageWrapper.frame = wFrame;
                         videoWrapper.frame = vFrame;
                         videoView.frame=CGRectMake( videoView.frame.origin.x,  videoView.frame.origin.x, vFrame.size.width, vFrame.size.height);
                         pageWrapper.alpha=0;
                         transparentBlackSheet.alpha=0.0;
                     }
                     completion:^(BOOL finished) {
                         //add tap gesture
                         self.tapRecognizer=nil;
                         if(self.tapRecognizer==nil)
                         {
                             self.tapRecognizer= [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(expandViewOnTap:)];
                             self.tapRecognizer.numberOfTapsRequired=1;
                             self.tapRecognizer.delegate=self;
                             [videoWrapper addGestureRecognizer:self.tapRecognizer];
                         }
                         
                         isExpandedMode=FALSE;
                         minimizedVideoFrame=videoWrapper.frame;
                         
                         if(direction==UIPanGestureRecognizerDirectionDown)
                         {
                             [self.onView bringSubviewToFront:self.view];
                         }
                     }];
}




-(void)removeView
{
    [self.delegate onRemoveView];
//    [self.player stop];
    [videoWrapper removeFromSuperview];
    [pageWrapper removeFromSuperview];
    [transparentBlackSheet removeFromSuperview];
}








#pragma mark- Pan Gesture Delagate

- (BOOL)gestureRecognizerShould:(UIGestureRecognizer *)gestureRecognizer {
    if(gestureRecognizer.view.frame.origin.y<0)
    {
        return NO;
    }
    else {
        return YES;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}











#pragma mark- Pan Gesture Selector Action

-(void)panAction:(UIPanGestureRecognizer *)recognizer
{
    CGFloat touchPosInViewY = [recognizer locationInView:self.view].y;
    
    if(recognizer.state == UIGestureRecognizerStateBegan) {

        direction = UIPanGestureRecognizerDirectionUndefined;
        //storing direction
        CGPoint velocity = [recognizer velocityInView:recognizer.view];
        [self detectPanDirection:velocity];
        
        //Snag the Y position of the touch when panning begins
        _touchPositionInHeaderY = [recognizer locationInView:videoWrapper].y;
        _touchPositionInHeaderX = [recognizer locationInView:videoWrapper].x;
        if(direction==UIPanGestureRecognizerDirectionDown) {
            // player.controlStyle = MPMovieControlStyleNone;
            [self.delegate onDownGesture];
        }
        
    }
    else if(recognizer.state == UIGestureRecognizerStateChanged){
        if(direction==UIPanGestureRecognizerDirectionDown || direction==UIPanGestureRecognizerDirectionUp) {
            CGFloat viewOffsetY = touchPosInViewY - _touchPositionInHeaderY;
            CGFloat xOffset = viewOffsetY * 0.35;
            [self adjustViewOnVerticalPan:viewOffsetY :xOffset recognizer:recognizer];
        }
        else if (direction==UIPanGestureRecognizerDirectionRight || direction==UIPanGestureRecognizerDirectionLeft) {
            [self adjustViewOnHorizontalPan:recognizer];
        }
    }
    else if(recognizer.state == UIGestureRecognizerStateEnded){
        
        if(direction==UIPanGestureRecognizerDirectionDown || direction==UIPanGestureRecognizerDirectionUp)
        {
            
            if(recognizer.view.frame.origin.y<0)
            {
                [self expandViewOnPan];
                
                [recognizer setTranslation:CGPointZero inView:recognizer.view];
                
                return;
                
            }
            else if(recognizer.view.frame.origin.y>(self.parentViewFrame.size.width/2))
            {
                
                [self minimizeViewOnPan];
                [recognizer setTranslation:CGPointZero inView:recognizer.view];
                return;
                
                
            }
            else if(recognizer.view.frame.origin.y<(self.parentViewFrame.size.width/2))
            {
                [self expandViewOnPan];
                [recognizer setTranslation:CGPointZero inView:recognizer.view];
                return;
                
            }
        }
        
        else if (direction==UIPanGestureRecognizerDirectionLeft)
        {
            if(pageWrapper.alpha<=0)
            {
                
                if(recognizer.view.frame.origin.x<0)
                {
                    [self.view removeFromSuperview];
                    [self removeView];
                    [self.delegate removeController];
                    
                }
                else
                {
                    [self animateViewToRight:recognizer];
                    
                }
            }
        }
        
        else if (direction==UIPanGestureRecognizerDirectionRight)
        {
            if(pageWrapper.alpha<=0)
            {
                
                
                if(recognizer.view.frame.origin.x>self.parentViewFrame.size.width-50)
                {
                    [self.view removeFromSuperview];
                    [self removeView];
                    [self.delegate removeController];
                    
                }
                else
                {
                    [self animateViewToLeft:recognizer];
                    
                }
            }
        }
    }
}




-(void)adjustViewOnVerticalPan:(CGFloat)viewOffsetY :(CGFloat)xOffset recognizer:(UIPanGestureRecognizer *)recognizer
{
    //    [self.txtViewGrowing resignFirstResponder];
    CGFloat touchPosInViewY = [recognizer locationInView:self.view].y;
    
    // final minimization
    if(viewOffsetY >= minimizedOffsetY+60 || xOffset >= minimizedOffsetX+60)
    {
        CGFloat finalOffsetY = self.parentViewFrame.size.height - 100;
        CGFloat finalOffsetX = self.parentViewFrame.size.width-160;
        //Use this offset to adjust the position of your view accordingly
        wFrame.origin.y = finalOffsetY;
        wFrame.origin.x = finalOffsetX;
        wFrame.size.width = self.parentViewFrame.size.width - finalOffsetX;
        
        vFrame.size.width = self.view.bounds.size.width - finalOffsetX;
        vFrame.size.height = 200 - finalOffsetX * 0.5;
        vFrame.origin.y = finalOffsetY;
        vFrame.origin.x = finalOffsetX;
        
        [UIView animateWithDuration:0.05
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^ {
                             pageWrapper.frame = wFrame;
                             videoWrapper.frame=vFrame;
                             videoView.frame=CGRectMake( videoView.frame.origin.x,  videoView.frame.origin.x, vFrame.size.width, vFrame.size.height);
                             pageWrapper.alpha=0;
                         }
                         completion:^(BOOL finished) {
                             minimizedVideoFrame=videoWrapper.frame;
                             isExpandedMode=FALSE;
                         }];
        [recognizer setTranslation:CGPointZero inView:recognizer.view];
    }
    // normal pan animation
    else {
        
        //Use this offset to adjust the position of your view accordingly
        wFrame.origin.y = viewOffsetY;
        wFrame.origin.x = xOffset;
        wFrame.size.width = self.parentViewFrame.size.width - xOffset;

        vFrame.origin.y = viewOffsetY;
        vFrame.origin.x = xOffset;
        vFrame.size.width = self.view.bounds.size.width - xOffset;
        vFrame.size.height = 200 - xOffset * 0.5;

        float restrictY = self.parentViewFrame.size.height - videoWrapper.frame.size.height - 10;
        
        if (pageWrapper.frame.origin.y < restrictY && pageWrapper.frame.origin.y > 0) {
            [UIView animateWithDuration:0.09
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^ {
                                 pageWrapper.frame = wFrame;
                                 videoWrapper.frame = vFrame;
                                 videoView.frame = CGRectMake(
                                                              videoView.frame.origin.x,  videoView.frame.origin.x,
                                                              vFrame.size.width, vFrame.size.height
                                                              );
                                 bodyArea.frame = CGRectMake(
                                                             0,
                                                             videoView.frame.size.height,// keep stay on bottom of videoView
                                                             bodyArea.frame.size.width,
                                                             bodyArea.frame.size.height
                                                             );
                                 
                                 CGFloat percentage = touchPosInViewY / self.parentViewFrame.size.height;
                                 pageWrapper.alpha= transparentBlackSheet.alpha = 1.0 - percentage;
                             }
                             completion:^(BOOL finished) {
                                 if(direction==UIPanGestureRecognizerDirectionDown)
                                 {
                                     [self.onView bringSubviewToFront:self.view];
                                 }
                             }];
        }
        else if (wFrame.origin.y < restrictY && wFrame.origin.y > 0)
        {
            NSLog(@"aaaaaaaaaaaaaaa");
            [UIView animateWithDuration:0.09
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^ {
                                 pageWrapper.frame = wFrame;
                                 videoWrapper.frame = vFrame;
                                 videoView.frame=CGRectMake( videoView.frame.origin.x,  videoView.frame.origin.x, vFrame.size.width, vFrame.size.height);
                                 
                                 bodyArea.frame = CGRectMake(
                                                             0,
                                                             videoView.frame.size.height,// keep stay on bottom of videoView
                                                             bodyArea.frame.size.width,
                                                             bodyArea.frame.size.height
                                                             );

                             }completion:nil];
        }
        [recognizer setTranslation:CGPointZero inView:recognizer.view];
    }
}




-(void)adjustViewOnHorizontalPan:(UIPanGestureRecognizer *)recognizer {
    //    [self.txtViewGrowing resignFirstResponder];
    CGFloat x = [recognizer locationInView:self.view].x;
    
    if (direction==UIPanGestureRecognizerDirectionLeft)
    {
        if(pageWrapper.alpha<=0)
        {
            
            NSLog(@"recognizer x=%f",recognizer.view.frame.origin.x);
            CGPoint velocity = [recognizer velocityInView:recognizer.view];
            
            BOOL isVerticalGesture = fabs(velocity.y) > fabs(velocity.x);
            
            
            
            CGPoint translation = [recognizer translationInView:recognizer.view];
            
            recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                                 recognizer.view.center.y );
            
            
            if (!isVerticalGesture) {
                
                CGFloat percentage = (x/self.parentViewFrame.size.width);
                
                recognizer.view.alpha = percentage;
                
            }
            
            [recognizer setTranslation:CGPointZero inView:recognizer.view];
        }
    }
    else if (direction==UIPanGestureRecognizerDirectionRight)
    {
        if(pageWrapper.alpha<=0)
        {
            
            NSLog(@"recognizer x=%f",recognizer.view.frame.origin.x);
            CGPoint velocity = [recognizer velocityInView:recognizer.view];
            
            BOOL isVerticalGesture = fabs(velocity.y) > fabs(velocity.x);
            
            CGPoint translation = [recognizer translationInView:recognizer.view];
            
            recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                                 recognizer.view.center.y );
            
            if (!isVerticalGesture) {
                
                if(velocity.x > 0)
                {
                    
                    CGFloat percentage = (x/self.parentViewFrame.size.width);
                    recognizer.view.alpha =1.0- percentage;                }
                else
                {
                    CGFloat percentage = (x/self.parentViewFrame.size.width);
                    recognizer.view.alpha =percentage;
                    
                    
                }
                
            }
            
            [recognizer setTranslation:CGPointZero inView:recognizer.view];
        }
    }
}





-(void)animateViewToRight:(UIPanGestureRecognizer *)recognizer{
//    [self.txtViewGrowing resignFirstResponder];
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^ {
                         pageWrapper.frame = wFrame;
                         videoWrapper.frame=vFrame;
                         videoView.frame=CGRectMake( videoView.frame.origin.x,  videoView.frame.origin.x, vFrame.size.width, vFrame.size.height);
                         pageWrapper.alpha=0;
                         videoWrapper.alpha=1;
                     }
                     completion:^(BOOL finished) {
                         
                     }];
    [recognizer setTranslation:CGPointZero inView:recognizer.view];
    
}

-(void)animateViewToLeft:(UIPanGestureRecognizer *)recognizer{
//    [self.txtViewGrowing resignFirstResponder];
    
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^ {
                         pageWrapper.frame = wFrame;
                         videoWrapper.frame=vFrame;
                         videoView.frame=CGRectMake( videoView.frame.origin.x,  videoView.frame.origin.x, vFrame.size.width, vFrame.size.height);
                         pageWrapper.alpha=0;
                         videoWrapper.alpha=1;
                         
                         
                         
                     }
                     completion:^(BOOL finished) {
                         
                     }];
    
    [recognizer setTranslation:CGPointZero inView:recognizer.view];
    
}







-(void)detectPanDirection:(CGPoint )velocity
{
    foldButton.hidden=TRUE;
    BOOL isVerticalGesture = fabs(velocity.y) > fabs(velocity.x);
    
    if (isVerticalGesture) {
        if (velocity.y > 0) {
            direction = UIPanGestureRecognizerDirectionDown;
            
        } else {
            direction = UIPanGestureRecognizerDirectionUp;
        }
    }
    else
        
    {
        if(velocity.x > 0)
        {
            direction = UIPanGestureRecognizerDirectionRight;
        }
        else
        {
            direction = UIPanGestureRecognizerDirectionLeft;
        }
        
    }
}








//#pragma mark - UITableViewDataSource
//
//// number of section(s), now I assume there is only 1 section
//- (NSInteger)numberOfSectionsInTableView:(UITableView *)theTableView
//{
//    return 1;
//}
//
//// number of row in the section, I assume there is only 1 row
//- (NSInteger)tableView:(UITableView *)theTableView numberOfRowsInSection:(NSInteger)section
//{
//    return 10;
//}
//
//// the cell will be returned to the tableView
//- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    static NSString *cellIdentifier = @"videoCommentCell";
//    UITableViewCell *cell;
//    cell = (UITableViewCell *)[theTableView dequeueReusableCellWithIdentifier:cellIdentifier];
//    if (cell == nil) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
//    }
//    cell.backgroundColor = [UIColor clearColor];
//    cell.contentView.backgroundColor = [UIColor clearColor];
//    cell.selectionStyle=UITableViewCellSelectionStyleNone;
//    return cell;
//}
//
//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return 88.0;
//}
//
//
//
//#pragma mark - UITableViewDelegate
//
//// when user tap the row, what action you want to perform
//- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    NSLog(@"selected %ld row", (long)indexPath.row);
//}
//- (void)didReceiveMemoryWarning {
//    [super didReceiveMemoryWarning];
//    // Dispose of any resources that can be recreated.
//}





//- (IBAction)btnSendAction:(id)sender {
//    [self.txtViewGrowing resignFirstResponder];
//    self.txtViewGrowing.text=@"";
//    [UIView animateWithDuration:0.2f
//                          delay:0.0f
//                        options:UIViewAnimationOptionCurveEaseIn
//                     animations:^{
//                         
//                         self.viewGrowingTextView.frame=growingTextViewFrame;
//                     }completion:^(BOOL finished) {
//                         
//                     }];
//}



//
//#pragma mark - Keyboard events
//
////Handling the keyboard appear and disappering events
//- (void)keyboardWasShown:(NSNotification*)aNotification
//{
//    //__weak typeof(self) weakSelf = self;
//    NSDictionary* info = [aNotification userInfo];
////    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
//    [UIView animateWithDuration:0.3f
//                          delay:0.0f
//                        options:UIViewAnimationOptionCurveEaseIn
//                     animations:^{
////                         float yPosition=self.view.frame.size.height- kbSize.height- self.viewGrowingTextView.frame.size.height;
////                         self.viewGrowingTextView.frame=CGRectMake(0, yPosition, self.viewGrowingTextView.frame.size.width, self.viewGrowingTextView.frame.size.height);
//
//                         //                         [weakSelf.registerScrView setContentOffset:CGPointMake(0, (weakSelf.userNameTxtfld.frame.origin.y+weakSelf.userNameTxtfld.frame.size.height)-kbSize.height) animated:YES];
//
//                     }
//                     completion:^(BOOL finished) {
//                     }];
//}
//
//
//- (void)keyboardWillBeHidden:(NSNotification*)aNotification
//{
//    // __weak typeof(self) weakSelf = self;
//    //NSDictionary* info = [aNotification userInfo];
//    [UIView animateWithDuration:0.3f
//                          delay:0.0f
//                        options:UIViewAnimationOptionCurveEaseIn
//                     animations:^{
//                         float yPosition=self.view.frame.size.height-self.viewGrowingTextView.frame.size.height;
//                         self.viewGrowingTextView.frame=CGRectMake(0, yPosition, self.viewGrowingTextView.frame.size.width, self.viewGrowingTextView.frame.size.height);
//                     }
//                     completion:^(BOOL finished) {
//                     }];
//}
//
//



//#pragma mark - Text View delegate -
//
//#pragma mark- View Function Methods
//
//-(void)stGrowingTextViewProperty
//{
//    [[NSNotificationCenter defaultCenter] removeObserver:self
//                                                    name:UIContentSizeCategoryDidChangeNotification
//                                                  object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
//
//
//
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardWillShowNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
//
//}
//

@end
