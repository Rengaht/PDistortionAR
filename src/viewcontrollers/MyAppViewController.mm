//
//  MenuViewController.m
//  Created by lukasz karluk on 12/12/11.
//

#import "MyAppViewController.h"

#import "OFAppViewController.h"
#import "ofApp.h"

@interface MyAppViewController()
@property (nonatomic, strong) ARSession *session;
@end

@implementation MyAppViewController


- (void)loadView {
    [super loadView];
  
    ARCore::SFormat format;
    format.enablePlaneTracking().enableLighting();
    self.session = ARCore::generateNewSession(format);
    
    
    OFAppViewController *viewController;
    viewController = [[[OFAppViewController alloc] initWithFrame:[[UIScreen mainScreen] bounds]
                                                                 app:new ofApp(self.session)] autorelease];
    
    UIButton *_reset;
    _reset=[[[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width-50,self.view.frame.size.height-50,50,50)] autorelease];
    [_reset setBackgroundColor:UIColor.whiteColor];
    [_reset setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [_reset setTitle:@"reset" forState:UIControlStateNormal];
    [_reset.titleLabel setFont:[UIFont systemFontOfSize:9]];

    [viewController.view addSubview:_reset];
    [_reset addTarget:self action:@selector(resetButton:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *_shader;
    _shader=[[[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width-100,self.view.frame.size.height-50,50,50)] autorelease];
    [_shader setBackgroundColor:UIColor.whiteColor];
    [_shader setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [_shader setTitle:@"next" forState:UIControlStateNormal];
    [_shader.titleLabel setFont:[UIFont systemFontOfSize:9]];
    
    [viewController.view addSubview:_shader];
    [_shader addTarget:self action:@selector(nextStage:) forControlEvents:UIControlEventTouchUpInside];
    
    
    UIButton *_start;
    _start=[[[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width-150,self.view.frame.size.height-50,50,50)] autorelease];
    [_start setBackgroundColor:UIColor.whiteColor];
    [_start setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    [_start setTitle:@"prev" forState:UIControlStateNormal];
    [_start.titleLabel setFont:[UIFont systemFontOfSize:9]];
    
    [viewController.view addSubview:_start];
    [_start addTarget:self action:@selector(prevStage:) forControlEvents:UIControlEventTouchUpInside];
    
    
    [self.navigationController setNavigationBarHidden:TRUE];
    [self.navigationController pushViewController:viewController animated:NO];
    self.navigationController.navigationBar.topItem.title = @"ofApp";
    
    
}
- (IBAction)resetButton:(id)sender {
    //NSLog(@"myviewcontroller reset!");
    ((ofApp*)ofGetAppPtr())->resetButton();
}

- (IBAction)nextStage:(id)sender {
    ((ofApp*)ofGetAppPtr())->nextStage();
}
- (IBAction)prevStage:(id)sender {
    ((ofApp*)ofGetAppPtr())->prevStage();
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    BOOL bRotate = NO;
    bRotate = bRotate || (toInterfaceOrientation == UIInterfaceOrientationPortrait);
    bRotate = bRotate || (toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
    return bRotate;
}

@end
