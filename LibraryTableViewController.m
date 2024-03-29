//
//  LibraryTableViewController.m
//  COEMag
//
//  Created by John Hannan on 4/24/12.
//  Copyright (c) 2012 Penn State University. All rights reserved.
//

#import "LibraryTableViewController.h"
#import "Library.h"
#import "IssueTableCell.h"
#import "IssueView.h"

#import <QuartzCore/QuartzCore.h>
#define kColumns 3
#define kDeleteAlertViewTag 99

#define kSpacer 90.0
#define kIssueWidth 170


@interface LibraryTableViewController ()
@property (nonatomic,strong) UIToolbar *toolbar;
@property (nonatomic,strong) Library *library;
@property (nonatomic,strong) UILongPressGestureRecognizer  *longPressGestureRecognizer;
@property BOOL deleting;
@property NSInteger issueToDelete;
@property (nonatomic,strong) UITextView *textView;

@property (nonatomic,strong) UIBarButtonItem *deleteButton;
@property (nonatomic,strong) NSMutableArray *issuesToDelete;

-(void)showIssues;
-(void)loadIssues;

@end

@implementation LibraryTableViewController
@synthesize toolbar;
@synthesize library;
@synthesize longPressGestureRecognizer, deleting, issueToDelete;
@synthesize textView;



- (void)viewDidLoad {

    
    [super viewDidLoad];
    library = [Library sharedInstance];
    
    _issuesToDelete = [[NSMutableArray alloc] initWithCapacity:10];
    
 
    
    /*
    // add a toolbar
    CGRect frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, 66.0);
    self.toolbar = [[UIToolbar alloc] initWithFrame:frame];
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshTable)];
    UIBarButtonItem *showingButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(showingTable)];
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 200.0;
    self.toolbar.items = [NSArray arrayWithObjects:fixedSpace, refreshButton, flexSpace, showingButton, fixedSpace, nil];
    self.toolbar.barStyle = UIBarStyleBlackTranslucent;
    self.tableView.tableHeaderView = toolbar;
    */
    

        
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
     self.navigationItem.rightBarButtonItem = self.editButtonItem;
    //self.navigationController.navigationBarHidden = NO;
    
    _deleteButton = [[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStyleBordered target:self action:@selector(deleteIssues)];
    self.deleteButton.enabled = NO;  // gets enabled when issues selected for deletion
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(publisherReady:) name:LibraryDidUpdateNotification object:library];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(publisherFailed:) name:LibraryFailedUpdateNotification object:library];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assetUpdate:) name:LibraryAssetUpdateNotification object:library];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(progressUpdate:) name:LibraryProgressUpdateNotification object:library];
   
    
    
    self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    self.longPressGestureRecognizer.delegate = self;
    self.deleting = NO;
    
    // debug stuff
//    CGRect tframe = CGRectMake(200.0, 200.0, 400.0, 400.0);
//    self.textView = [[UITextView alloc] initWithFrame:tframe];
//    self.textView.userInteractionEnabled = NO;
//    self.textView.alpha=0.70;
//    self.textView.text = @"Initialized";
//    
//    [self.view addSubview:self.textView];
//    [self.library addObserver:self forKeyPath:@"debugText" options:NSKeyValueObservingOptionNew context:NULL];

}


//-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//    self.textView.text = [change objectForKey:NSKeyValueChangeNewKey];
//}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    self.library = nil;
    self.toolbar = nil;
    self.longPressGestureRecognizer = nil;
}

-(void)viewDidAppear:(BOOL)animated {
    //CGRect frame = self.view.frame;
    
    
    //CGRect frame = self.view.frame;
    //CGRect newFrame = CGRectMake(0.0, 0.0, frame.size.width, frame.size.height);
    //self.view.frame = newFrame;
}

#pragma mark - Navbar Actions

-(void)setEditing:(BOOL)editing animated:(BOOL)animated{
    [super setEditing:editing animated:animated];
    if (editing) {
        self.navigationItem.leftBarButtonItem = self.deleteButton;
        [self.issuesToDelete removeAllObjects];  // make sure this is empty to start - shouldn't be necessary
        self.title = @"Select Issues";
    } else {
        self.navigationItem.leftBarButtonItem = nil;
        self.title = @"Library";
    }
    [self.tableView reloadData];
}


// delete all the issues that have been selected
-(void)deleteIssues {
    for (NSNumber *number in self.issuesToDelete) {
        NSInteger issue = [number integerValue];
        [library deleteIssueAtIndex:issue];
       
    }
    [self.issuesToDelete removeAllObjects];
    self.deleteButton.enabled = NO;
    
    [self.tableView reloadData];
}


#pragma mark - Toolbar Actions

-(void)refreshTable {
    [library checkForIssues];
}

// toggle datasource - show all issues or just downloaded ones
-(void)showingTable {
    [library toggleIssuesToShow];
    [self.tableView reloadData];
}

#pragma  mark - Autorotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    //[self.tableView reloadData];
    return YES;
//	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.tableView reloadData];
}


#pragma mark - Library interaction


-(IssueView*)issueView:(NSInteger)i inCell:(IssueTableCell*)cell {
    IssueView *issueView = (i%3==0) ? cell.issueView1 :
    ((i%3 == 1) ? cell.issueView2 : cell.issueView3);
    return issueView;
}

-(NSIndexPath*) indexPathForIssue:(NSInteger)issue {
    NSUInteger indexArr[] = {0,issue/kColumns};
    NSIndexPath *indexPath = [NSIndexPath indexPathWithIndexes:indexArr length:2];
    return indexPath;
}


-(void)assetUpdate:(NSNotification *)notification {
    
    NSDictionary *dictionary = [notification userInfo];
    NSNumber *number = [dictionary objectForKey:@"Index"];
    NSInteger index = [number intValue];
    
    NSIndexPath *indexPath = [self indexPathForIssue:index];
    
    IssueTableCell *cell = (IssueTableCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    IssueView *issueView = [self issueView:index inCell:cell];
    issueView.progressView.alpha = 0.0;
    issueView.tapButton.alpha = 1.0;

    NSArray *indexPathArray = [NSArray arrayWithObject:indexPath];
    [self.tableView reloadRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationAutomatic];
    //[self.tableView reloadData];
}

-(void)progressUpdate:(NSNotification *)notification {
    NSDictionary *dictionary = [notification userInfo];
    NSNumber *number = [dictionary objectForKey:@"Index"];
    NSInteger index = [number intValue];
    
    CGFloat progress = [[dictionary objectForKey:@"Progress"] floatValue];
    
    NSIndexPath *indexPath = [self indexPathForIssue:index];
    //NSArray *indexPathArray = [NSArray arrayWithObject:indexPath];
    
    IssueTableCell *cell = (IssueTableCell*)[self.tableView cellForRowAtIndexPath:indexPath];
    IssueView *issueView = [self issueView:index inCell:cell];
    issueView.progressView.progress = progress;
    issueView.progressView.alpha = 1.0;
    //[self.tableView reloadRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationAutomatic];
}


-(void)loadIssues {
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(publisherReady:) name:LibraryDidUpdateNotification object:library];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(publisherFailed:) name:LibraryFailedUpdateNotification object:library];
//    [library getIssuesList];    
}

-(void)publisherReady:(NSNotification *)not {
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:LibraryDidUpdateNotification object:library];
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:LibraryFailedUpdateNotification object:library];
    [self showIssues];
}

-(void)showIssues {
    
    [self.tableView reloadData];
}

-(void)publisherFailed:(NSNotification *)not {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LibraryDidUpdateNotification object:library];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LibraryFailedUpdateNotification object:library];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"Cannot get issues from Server."
                                                   delegate:nil
                                          cancelButtonTitle:@"Close"
                                          otherButtonTitles:nil];
    [alert show];
}

#pragma mark - Gestures

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
  //  NSLog(@"Simultaneous");
    return NO;
}

// toggle the giggling of issues, show/hide delete button
-(void)toggleGiggle {
        NSArray *cells = [self.tableView visibleCells];
    CGFloat theAlpha = self.deleting ? 1.0 : 0.0;
    //BOOL interact = self.deleting ? NO : YES;

    for (IssueTableCell *cell in cells) {
        cell.issueView1.deleteImage.alpha = theAlpha;
        //cell.issueView1.coverButton.enabled = interact;
        cell.issueView2.deleteImage.alpha = theAlpha;
        //cell.issueView2.coverButton.enabled = interact;
        cell.issueView3.deleteImage.alpha = theAlpha;
        //cell.issueView3.coverButton.enabled = interact;
        
    }
    
}

-(void)longPress:(id)sender {
    UIGestureRecognizer *gesture = (UILongPressGestureRecognizer*)sender;
        if (gesture.state == UIGestureRecognizerStateBegan) {
        self.deleting = !self.deleting;
        //[self toggleGiggle];
        [self.tableView reloadData];
    }
    
}

-(void)tapToDelete:(id)sender {
   
    UIGestureRecognizer *gesture = (UITapGestureRecognizer*)sender;
    UIView *buttonView = [gesture.view superview];  // the Button View contains the tag we want
    NSInteger issue = buttonView.tag;
    
    
    if ([library issueDownloadedAtIndex:issue]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"OK to delete issue?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        alertView.tag = kDeleteAlertViewTag;
        [alertView show];
        self.issueToDelete = issue;
        
    }
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    //NSLog(@"Button Index: %d", buttonIndex);
    if (alertView.tag == kDeleteAlertViewTag) {
        [library deleteIssueAtIndex:self.issueToDelete];
    }
}


#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = [library numberOfIssues];
    NSInteger rowCount = (count + (kColumns -1)) / kColumns;
    return rowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   
    static NSString *CellIdentifier = @"IssueCell";
    IssueTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
   
    cell.contentView.autoresizingMask=UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin; 
    cell.contentView.autoresizesSubviews=YES;
    
    
    
    // Configure the cell...
    NSInteger index = indexPath.row;
    
    // adjust spacing of issues in cell
    CGFloat centerX = self.tableView.bounds.size.width/2.0;
    CGRect frame1 = cell.issueView1.frame;
    frame1.origin.x = centerX - kSpacer - 1.5*kIssueWidth;
    cell.issueView1.frame = frame1;
    
    CGRect frame2 = cell.issueView2.frame;
    frame2.origin.x = centerX - 0.5*kIssueWidth;
    cell.issueView2.frame = frame2;

    CGRect frame3 = cell.issueView3.frame;
    frame3.origin.x = centerX + kSpacer + 0.5*kIssueWidth;
    cell.issueView3.frame = frame3;

    
    
    NSInteger numberOfIssues = [library numberOfIssues];
    // three issues per row (cell)
    for (int i=3*index; i<3*(index+1) && i<numberOfIssues; i++) {
        NSString *title = [library titleOfIssueAtIndex:i];
        NSString *tap = [library issueDownloadedAtIndex:i] ? @"View" : @"Download";
        UIImage *image = [library coverImageOfIssueAtIndex:i];
        
        IssueView *issueView = [self issueView:i inCell:cell];
        [issueView setIssue:i withImage:image title:title andTap:tap];
        [issueView.coverButton addTarget:self action:@selector(issueSelected:) forControlEvents:UIControlEventTouchUpInside];
        [issueView.tapButton addTarget:self action:@selector(issueSelected:) forControlEvents:UIControlEventTouchUpInside];
        issueView.tapButton.alpha = 1.0;
        
        if ([[issueView gestureRecognizers] count] == 0) {  // new cell
            UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
            lp.delegate = self;
            [issueView addGestureRecognizer:lp];
            
            [issueView.coverButton addSubview:issueView.deleteImage];
            
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToDelete:)];
            [issueView.deleteImage addGestureRecognizer:tapGesture];
            
            issueView.tapButton.showsTouchWhenHighlighted = YES;
            CALayer *tapLayer = issueView.tapButton.layer;
            tapLayer.cornerRadius = 7.0;
            tapLayer.borderColor = [[UIColor whiteColor] CGColor];
            tapLayer.borderWidth = 1.0;
            
        }
        
        CALayer *tapLayer = issueView.tapButton.layer;
        BOOL issueDownloaded = [library issueDownloadedAtIndex:i];
        if (issueDownloaded) {
            issueView.alpha = 1.0;
            tapLayer.backgroundColor =  [[UIColor blueColor] CGColor];
        } else {
            issueView.alpha = 0.6;
            tapLayer.backgroundColor =  [[UIColor grayColor] CGColor];
        }
         
        
        CALayer *coverLayer = issueView.coverButton.layer;
        if (self.editing && [self.issuesToDelete containsObject:[NSNumber numberWithInt:i]]) {  // display mark if selected for deletion
            issueView.deleteImage.alpha = 0.0;
            coverLayer.borderColor = [[UIColor redColor] CGColor];
            coverLayer.borderWidth = 3.0;
            
            // giggle
//            [UIView animateWithDuration:0.1 delay:0.0 options:(UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse |UIViewAnimationOptionAllowUserInteraction)
//                             animations:^{issueView.coverButton.transform = CGAffineTransformMakeRotation(0.1);} 
//                             completion:nil];
            //issueView.coverButton.enabled = NO;
            //issueView.coverButton.adjustsImageWhenHighlighted = NO;
            //issueView.deleteImage.userInteractionEnabled = YES;
        } else {
            issueView.deleteImage.alpha = 0.0;
           
            coverLayer.borderWidth = 0.0;
            
            //issueView.coverButton.transform = CGAffineTransformIdentity;
            
            //issueView.coverButton.enabled = YES;
            //issueView.coverButton.adjustsImageWhenHighlighted = YES;
        }
    }
        
    return cell;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate


/*
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Download or View
    NSInteger index = indexPath.row;
    if ([library issueDownloadedAtIndex:index]) {
        
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        
        RootViewController *rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"RootViewController"];
        //[[RootViewController alloc] initWithNibName:nil bundle:nil];
        CGPDFDocumentRef pdf = [library PDFForIssueAtIndex:index];
        rootViewController.pdf = pdf;
        rootViewController.delegate = self;
        rootViewController.modalPresentationStyle = UIModalPresentationFullScreen;
        rootViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self presentModalViewController:rootViewController animated:YES];
    } else {
        // show cell's progresss bar
        IssueTableCell *cell = (IssueTableCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        cell.progressView.alpha = 1.0;
        [library downloadIssueAtIndex:index];
    }
     
}
*/

//user selects an issue (button) from the table View
// three options: open for reading, download, or select for deletion
-(void)issueSelected:(id)sender {
    
    
    UIButton *button = (UIButton*)sender;
    NSInteger issueNumber = button.tag;
    
    BOOL downloaded = [library issueDownloadedAtIndex:issueNumber];
    // We're editing and user selected a downloaded issue, mark for deletion or unmark
    if (self.editing) {
        if (downloaded) {
            NSNumber *issueObject = [NSNumber numberWithInt:issueNumber];
            if ([self.issuesToDelete containsObject:issueObject]) {
                [self.issuesToDelete removeObject:issueObject];  // unmark
            } else {
                [self.issuesToDelete addObject:issueObject];
            }
            
            self.deleteButton.enabled  = ([self.issuesToDelete count] > 0);
            
            [self.tableView reloadData];
        }
        // else if not downloaded do nothing
        return;
    }
    

    
    // Download or View
    
    if (downloaded) {
        
        
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        
        RootViewController *rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"RootViewController"];
        //[[RootViewController alloc] initWithNibName:nil bundle:nil];
        CGPDFDocumentRef pdf = [library PDFForIssueAtIndex:issueNumber];
        rootViewController.pdf = pdf;
        rootViewController.delegate = self;
        rootViewController.modalPresentationStyle = UIModalPresentationFullScreen;
        rootViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self presentViewController:rootViewController animated:YES completion:NULL];
        
        
    } else if ([library currentlyDownloadingIssue:issueNumber])  {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Currently downloading" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show];
        } else {
        // show cell's progresss bar
        NSIndexPath *indexPath = [self indexPathForIssue:issueNumber];
        IssueTableCell *cell = (IssueTableCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        IssueView *issueView = [self issueView:issueNumber inCell:cell];
        issueView.progressView.alpha = 1.0;
        issueView.tapButton.alpha = 0.0;
        [library downloadIssueAtIndex:issueNumber];
    }

}

#pragma  mark - Root Modal Protocol
-(void)dismissModal {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
