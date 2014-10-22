//
//  BBTRosterCDTVC.m
//  Blabbit
//
//  Created by Nnoduka Eruchalu on 5/14/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "BBTRosterCDTVC.h"
#import "BBTXMPPManager.h"
#import "BBTRosterTableViewCell.h"
#import "BBTRosterTVCHelper.h"

@interface BBTRosterCDTVC ()

@end

@implementation BBTRosterCDTVC

#pragma mark - UITableView Data Source (Customize Cell and Section Headers)
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = [self cellIdentifier]; // get the cell
    // Observe that I'm dequeing from self.tableView as opposed to just tableView.
    //   and I'm also not specifying an indexPath
    //   This way there won't be exceptions thrown when tableView is a searchResultsTableView
    BBTRosterTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // get user to populate cell with
    id user = [self userAtIndexPath:indexPath ofTableView:tableView];
    
    // configure the cell
    [BBTRosterTVCHelper configureCell:cell withUser:user];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[self.fetchedResultsController sections] count] > 0 ) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        int sectionIntRepresentation = [sectionInfo.name intValue];
        return [BBTRosterTVCHelper userSectionNumToStatus:sectionIntRepresentation];
    } else {
        return @"";
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    // don't want section index titles
    return nil;
}

#pragma mark - Instance methods (public)
#pragma mark Abstract
- (NSString *)cellIdentifier
{
    return nil;
}

- (id)userAtIndexPath:(NSIndexPath *)indexPath ofTableView:(UITableView *)tableView
{
    return nil;
}




@end
