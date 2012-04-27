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


@interface LibraryTableViewController ()
@property (nonatomic,retain) Library *library;

-(void)showIssues;
-(void)loadIssues;

@end

@implementation LibraryTableViewController
@synthesize library;


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        library = [[Library alloc] init];
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    library = [[Library alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(publisherReady:) name:LibraryDidUpdateNotification object:library];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(publisherFailed:) name:LibraryFailedUpdateNotification object:library];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assetUpdate:) name:LibraryAssetUpdateNotification object:library];
    
//    if([library isReady]) {
//        [self showIssues];
//    } else {
//        [self loadIssues];
//    }

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}


#pragma mark - Library interaction

-(void)assetUpdate:(NSNotification *)notification {
    NSDictionary *dictionary = [notification userInfo];
    NSNumber *number = [dictionary objectForKey:@"Index"];
    NSInteger index = [number intValue];
    NSUInteger indexArr[] = {0,index};
    
    NSIndexPath *indexPath = [NSIndexPath indexPathWithIndexes:indexArr length:2];
    NSArray *indexPathArray = [NSArray arrayWithObject:indexPath];
    [self.tableView reloadRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationAutomatic];
}

-(void)loadIssues {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(publisherReady:) name:LibraryDidUpdateNotification object:library];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(publisherFailed:) name:LibraryFailedUpdateNotification object:library];
    [library getIssuesList];    
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
    NSLog(@"%@",not);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"Cannot get issues from Server."
                                                   delegate:nil
                                          cancelButtonTitle:@"Close"
                                          otherButtonTitles:nil];
    [alert show];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [library numberOfIssues];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"IssueCell";
    IssueTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    NSInteger index = indexPath.row;
    cell.title.text = [library titleOfIssueAtIndex:index];
    cell.tap.text = @"Download";
    cell.coverImageView.image = [library coverImageOfIssueAtIndex:index];
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    
    RootViewController *rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"RootViewController"];
        //[[RootViewController alloc] initWithNibName:nil bundle:nil];
    rootViewController.delegate = self;
    rootViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    rootViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentModalViewController:rootViewController animated:YES];
     
     
}

#pragma  mark - Root Modal Protocol
-(void)dismissModal {
    [self dismissModalViewControllerAnimated:YES];
}

@end
