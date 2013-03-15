#import "MASPreferencesWindowController.h"
#import <objc/runtime.h>

NSString *const kMASPreferencesWindowControllerDidChangeViewNotification = @"MASPreferencesWindowControllerDidChangeViewNotification";

static NSString *const kMASPreferencesFrameTopLeftKey = @"MASPreferences Frame Top Left";
static NSString *const kMASPreferencesSelectedViewKey = @"MASPreferences Selected Identifier View";

static void * MASPreferencesToolbarItemIdentifierKey = &MASPreferencesToolbarItemIdentifierKey;

static NSString * const MASPreferencesLeadingSpaceItemIdentifier = @"MASPreferencesLeadingSpaceItemIdentifier";

@interface MASPreferencesWindowController () // Private

- (NSViewController <MASPreferencesViewController> *)viewControllerForIdentifier:(NSString *)identifier;

@property (readonly) NSArray *toolbarItemIdentifiers;
@property (nonatomic, retain) NSViewController <MASPreferencesViewController> *selectedViewController;

@end

#pragma mark -

@implementation MASPreferencesWindowController

@synthesize viewControllers = _viewControllers;
@synthesize selectedViewController = _selectedViewController;
@synthesize title = _title;
@synthesize toolbarItemSize = _toolbarItemSize;

#pragma mark -

- (id)initWithViewControllers:(NSArray *)viewControllers
{
    return [self initWithViewControllers:viewControllers title:nil];
}

- (id)initWithViewControllers:(NSArray *)viewControllers title:(NSString *)title
{
    if ((self = [super initWithWindowNibName:@"MASPreferencesWindow"]))
    {
        _viewControllers = [viewControllers retain];
        _minimumViewRects = [[NSMutableDictionary alloc] init];
        _title = [title copy];
        _toolbarItemSize = NSZeroSize;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[self window] setDelegate:nil];
    
    [_viewControllers release];
    [_selectedViewController release];
    [_minimumViewRects release];
    [_title release];
    
    [super dealloc];
}

#pragma mark -

- (void)windowDidLoad
{
    if ([self.title length] > 0)
        [[self window] setTitle:self.title];

    if ([self.viewControllers count])
        self.selectedViewController = [self viewControllerForIdentifier:[[NSUserDefaults standardUserDefaults] stringForKey:kMASPreferencesSelectedViewKey]] ?: [self firstViewController];

    NSString *origin = [[NSUserDefaults standardUserDefaults] stringForKey:kMASPreferencesFrameTopLeftKey];
    if (origin)
        [self.window setFrameTopLeftPoint:NSPointFromString(origin)];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidMove:) name:NSWindowDidMoveNotification object:self.window];
}

- (NSViewController <MASPreferencesViewController> *)firstViewController {
    for (id viewController in self.viewControllers)
        if ([viewController isKindOfClass:[NSViewController class]])
            return viewController;

    return nil;
}

#pragma mark -
#pragma mark NSWindowDelegate

- (BOOL)windowShouldClose:(id)sender
{
    return !self.selectedViewController || [self.selectedViewController commitEditing];
}

- (void)windowDidMove:(NSNotification*)aNotification
{
    [[NSUserDefaults standardUserDefaults] setObject:NSStringFromPoint(NSMakePoint(NSMinX([self.window frame]), NSMaxY([self.window frame]))) forKey:kMASPreferencesFrameTopLeftKey];
}

#pragma mark -
#pragma mark Accessors

- (NSArray *)unpaddedItemIdentifiers
{
    NSMutableArray *identifiers = [NSMutableArray arrayWithCapacity:_viewControllers.count];
    for (id viewController in _viewControllers)
        if (viewController == [NSNull null])
            [identifiers addObject:NSToolbarFlexibleSpaceItemIdentifier];
        else
            [identifiers addObject:[viewController identifier]];
    return identifiers;
}

- (NSArray *)toolbarItemIdentifiers {
    NSMutableArray *paddedIdentifiers = [NSMutableArray arrayWithCapacity:_viewControllers.count*2];
    for (NSString *identifier in self.unpaddedItemIdentifiers) {
        [paddedIdentifiers addObject:MASPreferencesLeadingSpaceItemIdentifier];
        [paddedIdentifiers addObject:identifier];
    }
    return paddedIdentifiers;
}

#pragma mark -

- (NSUInteger)indexOfSelectedController
{
    NSUInteger index = [self.toolbarItemIdentifiers indexOfObject:self.selectedViewController.identifier];
    return index;
}

#pragma mark -
#pragma mark NSToolbarDelegate

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    NSArray *identifiers = self.toolbarItemIdentifiers;
    return identifiers;
}                   
                   
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    NSArray *identifiers = self.toolbarItemIdentifiers;
    return identifiers;
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar
{
    NSArray *identifiers = self.toolbarItemIdentifiers;
    return identifiers;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    
    if ([itemIdentifier isEqualToString:MASPreferencesLeadingSpaceItemIdentifier]) {
        // Use a negative width here to make up for the default padding that NSToolbarItem appears to include.
        NSView *spacerView = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, -4, 0)] autorelease];
        toolbarItem.view = spacerView;
        return [toolbarItem autorelease];
    }

    NSArray *identifiers = self.unpaddedItemIdentifiers;
    NSUInteger controllerIndex = [identifiers indexOfObject:itemIdentifier];
    if (controllerIndex != NSNotFound)
    {
        id <MASPreferencesViewController> controller = [_viewControllers objectAtIndex:controllerIndex];

        // NSToolbarItem target and actions are forwarded to a custom NSView (when present).
        NSRect itemFrame = { .origin = NSZeroPoint, .size = self.toolbarItemSize };

        NSMutableParagraphStyle *paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
        paragraphStyle.alignment = NSCenterTextAlignment;
        NSShadow *whiteShadow = [[[NSShadow alloc] init] autorelease];
        whiteShadow.shadowBlurRadius = 1;
        whiteShadow.shadowOffset = NSMakeSize(0, -0.5);
        whiteShadow.shadowColor = NSColor.whiteColor;

        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]], NSFontAttributeName, [NSColor colorWithCalibratedWhite:0.2 alpha:1.0], NSForegroundColorAttributeName, whiteShadow, NSShadowAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil];

        NSAttributedString *attributedTitle = [[[NSAttributedString alloc] initWithString:controller.toolbarItemLabel attributes:attributes] autorelease];
        
        NSButton *button = [[[NSButton alloc] initWithFrame:itemFrame] autorelease];
        button.image = controller.toolbarItemImage;
        button.imagePosition = NSImageAbove;
        button.buttonType = NSMomentaryChangeButton;
        button.bordered = NO;
        button.attributedTitle = attributedTitle;
        [button sizeToFit];
        
        NSRect buttonFrame = itemFrame;
        buttonFrame.origin.x = 0.0;
        // Move the button closer to the bottom of the toolbar
        buttonFrame.origin.y = -3.0;
        button.frame = buttonFrame;
        
        objc_setAssociatedObject(button, MASPreferencesToolbarItemIdentifierKey, itemIdentifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
        
        button.target = self;
        button.action = @selector(toolbarItemDidClick:);
        
        NSView *containerView = [[[NSView alloc] initWithFrame:itemFrame] autorelease];
        [containerView addSubview:button];
        
        toolbarItem.view = containerView;
    }
    return [toolbarItem autorelease];
}

#pragma mark -
#pragma mark Private methods

- (void)clearResponderChain
{
    // Remove view controller from the responder chain
    NSResponder *chainedController = self.window.nextResponder;
    if ([self.viewControllers indexOfObject:chainedController] == NSNotFound)
        return;
    self.window.nextResponder = chainedController.nextResponder;
    chainedController.nextResponder = nil;
}

- (void)patchResponderChain
{
    [self clearResponderChain];
    
    NSViewController *selectedController = self.selectedViewController;
    if (!selectedController)
        return;
    
    // Add current controller to the responder chain
    NSResponder *nextResponder = self.window.nextResponder;
    self.window.nextResponder = selectedController;
    selectedController.nextResponder = nextResponder;
}

- (NSViewController <MASPreferencesViewController> *)viewControllerForIdentifier:(NSString *)identifier
{
    for (id viewController in self.viewControllers) {
        if (viewController == [NSNull null]) continue;
        if ([[viewController identifier] isEqualToString:identifier])
            return viewController;
    }
    return nil;
}

#pragma mark -

- (void)setSelectedViewController:(NSViewController <MASPreferencesViewController> *)controller
{
    if (_selectedViewController == controller)
        return;

    if (_selectedViewController)
    {
        // Check if we can commit changes for old controller
        if (![_selectedViewController commitEditing])
        {
            [[self.window toolbar] setSelectedItemIdentifier:_selectedViewController.identifier];
            return;
        }

        [self.window setContentView:[[[NSView alloc] init] autorelease]];
        if ([_selectedViewController respondsToSelector:@selector(viewDidDisappear)])
            [_selectedViewController viewDidDisappear];

        [_selectedViewController release];
        _selectedViewController = nil;
    }

    if (!controller)
        return;

    // Retrieve the new window tile from the controller view
    if ([self.title length] == 0)
    {
        NSString *label = controller.toolbarItemLabel;
        self.window.title = label;
    }

    [[self.window toolbar] setSelectedItemIdentifier:controller.identifier];

    // Record new selected controller in user defaults
    [[NSUserDefaults standardUserDefaults] setObject:controller.identifier forKey:kMASPreferencesSelectedViewKey];
    
    NSView *controllerView = controller.view;
    controllerView.autoresizingMask = NSViewNotSizable;
    controllerView.translatesAutoresizingMaskIntoConstraints = YES;
    [controllerView layoutSubtreeIfNeeded];

    // Calculate new window size and position
    NSRect oldFrame = [self.window frame];
    NSRect newFrame = [self.window frameRectForContentRect:controllerView.bounds];
    newFrame = NSOffsetRect(newFrame, NSMinX(oldFrame), NSMaxY(oldFrame) - NSMaxY(newFrame));

    // Setup min/max sizes and show/hide resize indicator
    [self.window setContentMinSize:newFrame.size];
    [self.window setContentMaxSize:newFrame.size];
    [self.window setShowsResizeIndicator:NO];

    [self.window setFrame:newFrame display:YES animate:[self.window isVisible]];
    
    _selectedViewController = [controller retain];
    if ([controller respondsToSelector:@selector(viewWillAppear)])
        [controller viewWillAppear];
    
    [self.window setContentView:controllerView];
    [self.window recalculateKeyViewLoop];
    if ([self.window firstResponder] == self.window) {
        if ([controller respondsToSelector:@selector(initialKeyView)])
            [self.window makeFirstResponder:[controller initialKeyView]];
        else
            [self.window selectKeyViewFollowingView:controllerView];
    }
    
    // Insert view controller into responder chain
    [self patchResponderChain];

    [[NSNotificationCenter defaultCenter] postNotificationName:kMASPreferencesWindowControllerDidChangeViewNotification object:self];
}

- (void)toolbarItemDidClick:(id)sender
{
    NSString *itemIdentifier = objc_getAssociatedObject(sender, MASPreferencesToolbarItemIdentifierKey);
    if (itemIdentifier == nil) return;

    self.selectedViewController = [self viewControllerForIdentifier:itemIdentifier];
}

#pragma mark -
#pragma mark Public methods

- (void)selectControllerAtIndex:(NSUInteger)controllerIndex
{
    if (NSLocationInRange(controllerIndex, NSMakeRange(0, _viewControllers.count)))
        self.selectedViewController = [self.viewControllers objectAtIndex:controllerIndex];
}

#pragma mark -
#pragma mark Actions

- (IBAction)goNextTab:(id)sender
{
    NSUInteger selectedIndex = self.indexOfSelectedController;
    NSUInteger numberOfControllers = [_viewControllers count];

    do { selectedIndex = (selectedIndex + 1) % numberOfControllers; }
    while ([_viewControllers objectAtIndex:selectedIndex] == [NSNull null]);

    [self selectControllerAtIndex:selectedIndex];
}

- (IBAction)goPreviousTab:(id)sender
{
    NSUInteger selectedIndex = self.indexOfSelectedController;
    NSUInteger numberOfControllers = [_viewControllers count];

    do { selectedIndex = (selectedIndex + numberOfControllers - 1) % numberOfControllers; }
    while ([_viewControllers objectAtIndex:selectedIndex] == [NSNull null]);

    [self selectControllerAtIndex:selectedIndex];
}

@end
