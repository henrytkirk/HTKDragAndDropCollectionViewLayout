HTKDragAndDropCollectionViewLayout
======================

Custom UICollectionViewLayout that works together with a custom UICollectionViewCell to provide drag and drop for a UICollectionView. Works just like UITableView drag and drop. What's unique about this approach is that it does not need to create a "ghost" or "dummy" cell to provide the drag and drop functionality. I believe this method is simpler and less complex for the majority of use cases.

## Adding to your project:
### Cocoapods

[CocoaPods](http://cocoapods.org) is the recommended way to add HTKDragAndDropCollectionViewLayout to your project.

1. Add a pod entry for HTKDragAndDropCollectionViewLayout to your Podfile `pod 'HTKDragAndDropCollectionViewLayout', '~> 0.0.1'`
2. Install the pod(s) by running `pod install`.
3. Subclass `HTKDragAndDropCollectionViewController`.
4. Setup `HTKDragAndDropCollectionViewLayout` properties (itemSize, lineSpacing, etc).
5. Subclass and use `HTKDraggableCollectionViewCell` which implements the gestures for dragging.
6. Implement `- (void)userDidEndDraggingCell:(UICollectionViewCell *)cell` and if the  `HTKDragAndDropCollectionViewLayout` finalIndexPath is not nil, insert the draggedIndexPath into the finalIndexPath's position. See example in project.

## Sample video:

[![YouTube Sample Video](http://img.youtube.com/vi/tJ5NN5RlSOk/0.jpg)](http://www.youtube.com/watch?v=tJ5NN5RlSOk)

## Screen shot:

![Sample Screenshot](http://htk-github.s3.amazonaws.com/HTKDragAndDropCollectionViewLayoutSS-1.png)

## Change log:
v0.0.1: Initial project commit

Questions? Email: henrytkirk@gmail.com or Web: http://www.henrytkirk.info
