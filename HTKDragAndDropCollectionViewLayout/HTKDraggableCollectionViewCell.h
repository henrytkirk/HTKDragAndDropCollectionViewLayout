//
//  HTKDraggableCollectionViewCell.h
//  HTKDragAndDropCollectionView
//
//  Created by Henry T Kirk on 11/9/14.
//  Copyright (c) 2014 Henry T. Kirk (http://www.henrytkirk.info)
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <UIKit/UIKit.h>

/**
 * Cell identifier for the cell.
 */
static NSString *HTKDraggableCollectionViewCellIdentifier = @"HTKDraggableCollectionViewCellIdentifier";

/**
 * Delegate for dragging the cell.
 */
@protocol HTKDraggableCollectionViewCellDelegate <NSObject>

/**
 * Called when user starts to drag
 */
- (void)userDidBeginDraggingCell:(UICollectionViewCell *)cell;

/**
 * Called when user ends dragging.
 */
- (void)userDidEndDraggingCell:(UICollectionViewCell *)cell;

/**
 * Called while user is dragging the cell
 */
- (void)userDidDragCell:(UICollectionViewCell *)cell withGestureRecognizer:(UIPanGestureRecognizer *)recognizer;

@optional

/**
 * Determines if dragging can begin for cell. Defaults to YES.
 */
- (BOOL)userCanDragCell:(UICollectionViewCell *)cell;

@end

/**
 * UICollectionViewCell that provides dragging and delegates for the different
 * dragging states. Subclass this along with the custom drag and drop layout
 * to provide drag and drop functionality.
 */
@interface HTKDraggableCollectionViewCell : UICollectionViewCell

/**
 * Delegate for dragging the cell.
 */
@property (nonatomic, weak) id<HTKDraggableCollectionViewCellDelegate> draggingDelegate;

@end
