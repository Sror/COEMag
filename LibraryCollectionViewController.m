//
//  LibraryCollectionViewController.m
//  COEMag
//
//  Created by John Hannan on 5/14/13.
//  Copyright (c) 2013 Penn State University. All rights reserved.
//

#import "LibraryCollectionViewController.h"
#import "Library.h"
#import "IssueCollectionCell.h"
#import <QuartzCore/QuartzCore.h>

#define kLowAlpha 0.4

@interface LibraryCollectionViewController ()
@property (nonatomic,strong) Library *library;

@property (nonatomic,strong) UIBarButtonItem *deleteButton;
@property (nonatomic,strong) NSMutableArray *issuesToDelete;
@end

@implementation LibraryCollectionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.library = [Library sharedInstance];
    _issuesToDelete = [[NSMutableArray alloc] initWithCapacity:10];
    
     self.navigationItem.rightBarButtonItem = self.editButtonItem;
    _deleteButton = [[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStyleBordered target:self action:@selector(deleteIssues)];
    self.deleteButton.enabled = NO;  // gets enabled when issues selected for deletion
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(publisherReady:) name:LibraryDidUpdateNotification object:self.library];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(publisherFailed:) name:LibraryFailedUpdateNotification object:self.library];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assetUpdate:) name:LibraryAssetUpdateNotification object:self.library];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(progressUpdate:) name:LibraryProgressUpdateNotification object:self.library];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    [self.collectionView reloadData];
}


// delete all the issues that have been selected
-(void)deleteIssues {
    for (NSNumber *number in self.issuesToDelete) {
        NSInteger issue = [number integerValue];
        [self.library deleteIssueAtIndex:issue];
        
    }
    [self.issuesToDelete removeAllObjects];
    self.deleteButton.enabled = NO;
    
    [self.collectionView reloadData];
}



#pragma mark - Library interaction

/*
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
*/

-(void)assetUpdate:(NSNotification *)notification {
    
    NSDictionary *dictionary = [notification userInfo];
    NSNumber *number = [dictionary objectForKey:@"Index"];
    NSInteger index = [number intValue];
    
    NSIndexPath *indexPath =  [NSIndexPath indexPathForRow:index inSection:0];
    
    IssueCollectionCell *cell = (IssueCollectionCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    cell.progressView.alpha = 0.0;
    //cell.action.alpha = 1.0;
    
    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    
}

-(void)progressUpdate:(NSNotification *)notification {
    NSDictionary *dictionary = [notification userInfo];
    NSNumber *number = [dictionary objectForKey:@"Index"];
    NSInteger index = [number intValue];
    
    CGFloat progress = [[dictionary objectForKey:@"Progress"] floatValue];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
  
    IssueCollectionCell *cell = (IssueCollectionCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    cell.progressView.progress = progress;
    cell.progressView.alpha = 1.0;
    
    
}


-(void)loadIssues {
    
}

-(void)publisherReady:(NSNotification *)not {
   
    [self showIssues];
}

-(void)showIssues {
    
    [self.collectionView reloadData];
}

-(void)publisherFailed:(NSNotification *)not {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LibraryDidUpdateNotification object:self.library];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LibraryFailedUpdateNotification object:self.library];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"Cannot get issues from Server."
                                                   delegate:nil
                                          cancelButtonTitle:@"Close"
                                          otherButtonTitles:nil];
    [alert show];
}



#pragma mark - Collection View Data Source
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.library numberOfIssues];
}

-(UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    IssueCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"IssueCell" forIndexPath:indexPath];
    
 
    NSInteger issue = indexPath.row;
    BOOL downloaded = [self.library issueDownloadedAtIndex:issue];
    NSString *title = [self.library titleOfIssueAtIndex:issue];
    NSString *action = [self.library issueDownloadedAtIndex:issue] ? @"View" : @"Download";
    UIImage *image = [self.library coverImageOfIssueAtIndex:issue];
    
    cell.coverView.image = image;
    //cell.action.text = action;
    cell.title.text = title;
    
    cell.coverView.alpha = downloaded ? 1.0 : kLowAlpha;
    cell.title.alpha = downloaded ? 1.0 : kLowAlpha;
    //cell.action.alpha = 0.0;
    cell.progressView.alpha = 0.0;
    
    CALayer *coverLayer = cell.coverView.layer;
    if (self.editing && [self.issuesToDelete containsObject:[NSNumber numberWithInt:issue]]) {  // display mark if selected for deletion
       
        coverLayer.borderColor = [[UIColor redColor] CGColor];
        coverLayer.borderWidth = 3.0;
        
    } else {
        coverLayer.borderWidth = 0.0;
    }

    
    return cell;
}

/*- (UICollectionReusableView *)collectionView:
 (UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
 {
 return [[UICollectionReusableView alloc] init];
 }*/


#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
     NSInteger issue = indexPath.row;
    BOOL downloaded = [self.library issueDownloadedAtIndex:issue];
    
    // We're editing and user selected a downloaded issue, mark for deletion or unmark
    if (self.editing) {
        if (downloaded) {
            NSNumber *issueObject = [NSNumber numberWithInt:issue];
            if ([self.issuesToDelete containsObject:issueObject]) {
                [self.issuesToDelete removeObject:issueObject];  // unmark
            } else {
                [self.issuesToDelete addObject:issueObject];
            }
            
            self.deleteButton.enabled  = ([self.issuesToDelete count] > 0);
            
            [self.collectionView reloadData];
        }
        // else if not downloaded do nothing
        return;
    }

    
    // Download or View
    
    if (downloaded) {
        
        
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        
        RootViewController *rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"RootViewController"];
        //[[RootViewController alloc] initWithNibName:nil bundle:nil];
        CGPDFDocumentRef pdf = [self.library PDFForIssueAtIndex:issue];
        rootViewController.pdf = pdf;
        rootViewController.delegate = self;
        rootViewController.modalPresentationStyle = UIModalPresentationFullScreen;
        rootViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self presentModalViewController:rootViewController animated:YES];
        
        
    } else if ([self.library currentlyDownloadingIssue:issue])  {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Currently downloading" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show];
    } else {
        // show cell's progresss bar
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:issue inSection:0];
        IssueCollectionCell *cell = (IssueCollectionCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
        cell.progressView.alpha = 1.0;
        
        [self.library downloadIssueAtIndex:issue];
    }

    
    
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    // TODO: Deselect item
}


#pragma mark – UICollectionViewDelegateFlowLayout

// 1
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
   
    CGSize size = CGSizeMake(170.0, 210.0);
    return size;
}

// 3
- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(50, 20, 50, 20);
}

#pragma  mark - Root Modal Protocol
-(void)dismissModal {
    [self dismissModalViewControllerAnimated:YES];
}

@end
