//
//  HTKDragAndDropCollectionViewLayout.m
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

#import "HTKDragAndDropCollectionViewLayout.h"
#import "HTKDragAndDropCollectionViewLayoutConstants.h"

@interface HTKDragAndDropCollectionViewLayout ()

/**
 * Our item array that holds the "sorted" items in the collectionView.
 * this array is re-ordered while user is dragging a cell. Our layout
 * uses this to then show the items in that sorted order.
 */
@property (nonatomic, strong) NSMutableArray *itemArray;

/**
 * Our dictionary of layout attributes where the indexPath is the key. Used
 * to retrieve the layout attributes for a particular indexPath since
 * it may be different than the order in itemArray.
 */
@property (nonatomic, strong) NSMutableDictionary *itemDictionary;

/**
 * Returns number of items that will fit per row based on fixed
 * itemSize.
 */
@property (readonly, nonatomic) NSInteger numberOfItemsPerRow;

/**
 * Resets the frames based on new position in the itemArray. Will
 * loop over all items in the new sorted order and lay them out.
 */
- (void)resetLayoutFrames;

/**
 * Applys the dragging attributes to the attributes passed. Will
 * apply dragging state if the attributes are being dragged. If not, will
 * apply default state.
 */
- (void)applyDragAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes;

/**
 * Inserts the dragged item into the indexPath passed. Will reorder
 * the items.
 */
- (void)insertDraggedItemAtIndexPath:(NSIndexPath *)intersectPath;

/**
 * Helper to determine what indexPath of the item is below the point
 * passed. Used to identify what item is below the item being dragged.
 */
- (NSIndexPath *)indexPathBelowDraggedItemAtPoint:(CGPoint)point;

/**
 * Creates and inserts layout attributes for indexPath provided. Used
 * for insertions into the collectionView.
 */
- (void)insertItemAtIndexPath:(NSIndexPath *)indexPath;

@end

@implementation HTKDragAndDropCollectionViewLayout

- (instancetype)init {
    self = [super init];
    if (self) {
        _itemArray = [NSMutableArray array];
        _itemDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)invalidateLayoutWithContext:(UICollectionViewLayoutInvalidationContext *)context {
    [super invalidateLayoutWithContext:context];
    // reset so we re-calc entire layout again
    if (context.invalidateEverything) {
        [self.itemArray removeAllObjects];
    }
}

- (void)prepareLayout {
    [super prepareLayout];

    // Make sure we have item size set.
    if (CGSizeEqualToSize(self.itemSize, CGSizeZero)) {
        return;
    }
    
    // If we already have our model, don't build it.
    if (self.itemArray.count > 0) {
        return;
    }
    
    // Start to build our array and dictionary of items
    self.draggedIndexPath = nil;
    self.finalIndexPath = nil;
    self.draggedCellFrame = CGRectZero;
    [self.itemArray removeAllObjects];
    [self.itemDictionary removeAllObjects];
    
    // setup values
    CGFloat collectionViewWidth = CGRectGetWidth(self.collectionView.bounds) - self.sectionInset.right;
    CGFloat xValue = self.sectionInset.left;
    CGFloat yValue = self.sectionInset.top;
    NSInteger sectionCount = [self.collectionView numberOfSections];
    
    // Now build our items array/dictionary
    for (NSInteger section = 0; section < sectionCount; section ++) {
        NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];
        for (NSInteger item = 0; item < itemCount; item ++) {
            
            // Check our xvalue
            if ((xValue + self.itemSize.width) > collectionViewWidth) {
                // reset our x, increment our y.
                xValue = self.sectionInset.left;
                yValue += self.itemSize.height + self.lineSpacing;
            }
            
            // Create IndexPath
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexPath];
            // Create frame
            attributes.frame = CGRectMake(xValue, yValue, self.itemSize.width, self.itemSize.height);
            
            // add to our dict
            self.itemDictionary[indexPath] = attributes;
            [self.itemArray addObject:attributes];
            
            // Increment our x value
            xValue += self.itemSize.width + self.minimumInteritemSpacing;
        }
    }
}

- (CGSize)collectionViewContentSize {
    
    CGFloat collectionViewWidth = CGRectGetWidth(self.collectionView.bounds);
    // Determine number of sections
    NSInteger totalItems = 0;
    for (NSInteger i = 0; i < [self.collectionView numberOfSections]; i++) {
        totalItems += [self.collectionView numberOfItemsInSection:i];
    }
    // When the totalItems % 2 == 1, do this.
    if (totalItems % 2 == 1) {
        totalItems = totalItems + 1;
    }
    // Determine how many rows we will have
    NSInteger rows = ceil((CGFloat)totalItems / self.numberOfItemsPerRow);
    // Determine height of collectionView
    CGFloat height = (rows * (self.itemSize.height + self.lineSpacing)) + self.sectionInset.top + self.sectionInset.bottom;
    
    return CGSizeMake(collectionViewWidth, height);
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *elementArray = [NSMutableArray array];
    
    // Loop over our items and find elements that
    // intersect the rect passed.
    [[self.itemArray copy] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UICollectionViewLayoutAttributes *attribute = (UICollectionViewLayoutAttributes *)obj;
        if (CGRectIntersectsRect(attribute.frame, rect)) {
            [self applyDragAttributes:attribute];
            [elementArray addObject:attribute];
        }
    }];

    return elementArray;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *layoutAttributes = self.itemDictionary[indexPath];
    if (!layoutAttributes) {
        layoutAttributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    }
    [self applyDragAttributes:layoutAttributes];
    
    return layoutAttributes;
}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
    
    UICollectionViewLayoutAttributes *attributes = [self.itemDictionary[itemIndexPath] copy];
    return attributes;
}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
    
    UICollectionViewLayoutAttributes *attributes = [self.itemDictionary[itemIndexPath] copy];
    return attributes;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    if (!CGSizeEqualToSize(self.collectionView.bounds.size, newBounds.size)) {
        // reset so we re-calc entire layout again
        [self.itemArray removeAllObjects];
        return YES;
    }
    return NO;
}

- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems {
    [updateItems enumerateObjectsUsingBlock:^(UICollectionViewUpdateItem *updateItem, NSUInteger idx, BOOL *stop) {
        switch (updateItem.updateAction) {
            case UICollectionUpdateActionInsert: {
                // insert new item
                [self insertItemAtIndexPath:updateItem.indexPathAfterUpdate];
                break;
            }
            case UICollectionUpdateActionDelete:
            case UICollectionUpdateActionMove:
            case UICollectionUpdateActionNone:
            case UICollectionUpdateActionReload:
            default:
                break;
        }
    }];
}

#pragma mark - Getters

- (NSInteger)numberOfItemsPerRow {
    // Determine how many items we can fit per row
    CGFloat collectionViewWidth = CGRectGetWidth(self.collectionView.bounds) - self.sectionInset.right - self.sectionInset.left;
    NSInteger numberOfItems = collectionViewWidth / (self.itemSize.width + _minimumInteritemSpacing);
    return numberOfItems;
}

- (CGFloat)minimumInteritemSpacing {
    // return minimum item spacing
    CGFloat collectionViewWidth = CGRectGetWidth(self.collectionView.bounds) - self.sectionInset.right - self.sectionInset.left;
    CGFloat actualItemSpacing = MAX(_minimumInteritemSpacing, collectionViewWidth - (self.numberOfItemsPerRow * self.itemSize.width));
    return actualItemSpacing / self.numberOfItemsPerRow;
}

#pragma mark - Drag and Drop methods

- (void)resetDragging {
    
    // Set our dragged cell back to it's "home" frame
    UICollectionViewLayoutAttributes *attributes = self.itemDictionary[self.draggedIndexPath];
    attributes.frame = self.draggedCellFrame;

    self.finalIndexPath = nil;
    self.draggedIndexPath = nil;
    self.draggedCellFrame = CGRectZero;

    // Put the cell back animated.
    [UIView animateWithDuration:0.2 animations:^{
        [self invalidateLayout];
    }];
}

- (void)resetLayoutFrames {
    
    // Get width of collectionView and adjust by section insets
    CGFloat collectionViewWidth = CGRectGetWidth(self.collectionView.bounds) - self.sectionInset.right;
    
    CGFloat xValue = self.sectionInset.left;
    CGFloat yValue = self.sectionInset.top;
    for (NSInteger i = 0; i < self.itemArray.count; i++) {
        
        // Get attributes to work with
        UICollectionViewLayoutAttributes *attributes = self.itemArray[i];

        // Check our xvalue
        if ((xValue + self.itemSize.width) > collectionViewWidth) {
            // reset our x, increment our y.
            xValue = self.sectionInset.left;
            yValue += self.itemSize.height + self.lineSpacing;
        }
        
        // Set new frame
        attributes.frame = CGRectMake(xValue, yValue, self.itemSize.width, self.itemSize.height);
        
        // Increment our x value
        xValue += self.itemSize.width + self.minimumInteritemSpacing;
    }
}

- (void)applyDragAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {
    if ([layoutAttributes.indexPath isEqual:self.draggedIndexPath]) {
        // Set dragged attributes
        layoutAttributes.center = self.draggedCellCenter;
        layoutAttributes.zIndex = 1024;
        layoutAttributes.alpha = HTKDraggableCellInitialDragAlphaValue;
    } else {
        // Default attributes
        layoutAttributes.zIndex = 0;
        layoutAttributes.alpha = 1.0;
    }
}

- (void)setDraggedCellCenter:(CGPoint)draggedCellCenter {
    _draggedCellCenter = draggedCellCenter;
    [self invalidateLayout];
}

- (void)insertDraggedItemAtIndexPath:(NSIndexPath *)intersectPath {
    // Get attributes to work with
    UICollectionViewLayoutAttributes *draggedAttributes = self.itemDictionary[self.draggedIndexPath];
    UICollectionViewLayoutAttributes *intersectAttributes = self.itemDictionary[intersectPath];
    
    // get index of items
    NSUInteger draggedIndex = [self.itemArray indexOfObject:draggedAttributes];
    NSUInteger intersectIndex = [self.itemArray indexOfObject:intersectAttributes];
    
    // Move item in our array
    [self.itemArray removeObjectAtIndex:draggedIndex];
    [self.itemArray insertObject:draggedAttributes atIndex:intersectIndex];
    
    // Set our new final indexPath
    self.finalIndexPath = intersectPath;
    self.draggedCellFrame = intersectAttributes.frame;
    
    // relayout frames for items
    [self resetLayoutFrames];
    
    // Animate change
    [UIView animateWithDuration:0.10 animations:^{
        [self invalidateLayout];
    }];
}

- (void)exchangeItemsIfNeeded {
    // Exchange objects if we're touching.
    NSIndexPath *intersectPath = [self indexPathBelowDraggedItemAtPoint:self.draggedCellCenter];
    UICollectionViewLayoutAttributes *attributes = self.itemDictionary[intersectPath];
    
    // Create a "hit area" that's 20 pt over the center of the intersected cell center
    CGRect centerBox = CGRectMake(attributes.center.x - HTKDragAndDropCenterTriggerOffset, attributes.center.y - HTKDragAndDropCenterTriggerOffset, HTKDragAndDropCenterTriggerOffset * 2, HTKDragAndDropCenterTriggerOffset * 2);
    // Determine if we need to move items around
    if (intersectPath != nil && ![intersectPath isEqual:self.draggedIndexPath] && CGRectContainsPoint(centerBox, self.draggedCellCenter)) {
        [self insertDraggedItemAtIndexPath:intersectPath];
    }
}

- (BOOL)isDraggingCell {
    return self.draggedIndexPath != nil;
}

#pragma mark - Helper Methods

- (NSIndexPath *)indexPathBelowDraggedItemAtPoint:(CGPoint)point {
        
    __block NSIndexPath *indexPathBelow = nil;
    __weak HTKDragAndDropCollectionViewLayout *weakSelf = self;
    
    [self.collectionView.indexPathsForVisibleItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSIndexPath *indexPath = (NSIndexPath *)obj;
        
        // Skip our dragged cell
        if ([self.draggedIndexPath isEqual:indexPath]) {
            return;
        }
        UICollectionViewLayoutAttributes *attribute = weakSelf.itemDictionary[indexPath];
        
        // Create a "hit area" that's 20 pt over the center of the testing cell
        CGRect centerBox = CGRectMake(attribute.center.x - HTKDragAndDropCenterTriggerOffset, attribute.center.y - HTKDragAndDropCenterTriggerOffset, HTKDragAndDropCenterTriggerOffset * 2, HTKDragAndDropCenterTriggerOffset * 2);
        if (CGRectContainsPoint(centerBox, weakSelf.draggedCellCenter)) {
            indexPathBelow = indexPath;
            *stop = YES;
        }
    }];

    return indexPathBelow;
}

- (void)insertItemAtIndexPath:(NSIndexPath *)indexPath {
    // get attributes of item before this inserted one
    UICollectionViewLayoutAttributes *prevAttributes = self.itemArray[indexPath.row - 1];
    
    // Check our values
    CGFloat xValue = CGRectGetMaxX(prevAttributes.frame) + self.minimumInteritemSpacing;
    CGFloat yValue = CGRectGetMinY(prevAttributes.frame);
    CGFloat collectionViewWidth = CGRectGetWidth(self.collectionView.bounds) - self.sectionInset.right;
    if ((xValue + self.itemSize.width) > collectionViewWidth) {
        // reset our x, increment our y.
        xValue = self.sectionInset.left;
        yValue += self.itemSize.height + self.lineSpacing;
    }
    
    // create attributes
    UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexPath];
    // Create frame
    attributes.frame = CGRectMake(xValue, yValue, self.itemSize.width, self.itemSize.height);
    
    // add to our dict
    self.itemDictionary[indexPath] = attributes;
    [self.itemArray addObject:attributes];
}

@end
