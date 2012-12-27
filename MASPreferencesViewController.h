//
// Any controller providing preference pane view must support this protocol
//

@protocol MASPreferencesViewController <NSObject>

@optional

- (void)viewWillAppear;
- (void)viewDidDisappear;
- (NSView *)initialKeyView;

// If this is property is implemented, the returned NSView will be used
// as the NSToolbarItem.customView for this preference pane.
//
// If this property is implemented, toolbarItemImage will be ignored.
// Either this property or toolbarItemImage must be implemented.
@property (nonatomic, readonly, strong) NSView *toolbarItemView;

// NSImage to be used for the NSToolbarItem for this view controller.
//
// If this property is not implemented, then toolbarItemView must be implemented.
@property (nonatomic, readonly, strong) NSImage *toolbarItemImage;

@required

// String identifier for this preference pane.
@property (nonatomic, readonly, copy) NSString *identifier;

// Label for this preference pane.
@property (nonatomic, readonly, copy) NSString *toolbarItemLabel;

@end
