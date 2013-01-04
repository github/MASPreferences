//
// Any controller providing preference pane view must support this protocol
//

@protocol MASPreferencesViewController <NSObject>

@optional

- (void)viewWillAppear;
- (void)viewDidDisappear;
- (NSView *)initialKeyView;

@required

// NSImage to be used for the NSToolbarItem for this view controller.
@property (nonatomic, readonly, strong) NSImage *toolbarItemImage;

// String identifier for this preference pane.
@property (nonatomic, readonly, copy) NSString *identifier;

// Label for this preference pane.
@property (nonatomic, readonly, copy) NSString *toolbarItemLabel;

@end
