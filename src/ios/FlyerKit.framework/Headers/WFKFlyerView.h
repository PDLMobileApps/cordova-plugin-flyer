// Copyright (c) 2016 Flipp, Inc. All rights reserved.

#import <UIKit/UIKit.h>

@class WFKFlyerView;
@protocol WFKFlyerViewTapAnnotation;
@protocol WFKFlyerViewBadgeAnnotation;

/**
 Protocol definition for a callback handler to be invoked on flyer events.
 */
@protocol WFKFlyerViewDelegate <NSObject>
@optional
/**
 * Called when an annotation in a flyer view's tapAnnotations is single
 * tapped.
 *
 * @param flyerView The view that was single tapped.
 * @param annotation The tap annotation that was single tapped.
 * @param point The flyer coordinate of the single tap.
 */
- (void)flyerView:(WFKFlyerView * _Nonnull)flyerView
     gotSingleTap:(id<WFKFlyerViewTapAnnotation> _Nullable)annotation
          atPoint:(CGPoint)point;

/**
 * Called when an annotation in a flyer view's tapAnnotations is double
 * tapped.
 *
 * @param flyerView The view that was double tapped.
 * @param annotation The tap annotation that was double tapped.
 * @param point The flyer coordinate of the double tap.
 */
- (void)flyerView:(WFKFlyerView * _Nonnull)flyerView
     gotDoubleTap:(id<WFKFlyerViewTapAnnotation> _Nullable)annotation
          atPoint:(CGPoint)point;

/**
 * Called when an annotation in a flyer view's tapAnnotations is long
 * pressed.
 *
 * @param flyerView The view that was long pressed.
 * @param annotation The tap annotation that was long pressed.
 * @param point The flyer coordinate of the long press.
 */
- (void)flyerView:(WFKFlyerView * _Nonnull)flyerView
     gotLongPress:(id<WFKFlyerViewTapAnnotation> _Nullable)annotation
          atPoint:(CGPoint)point;

/**
 * Called when the flyer view's visible rectangle has changed.
 *
 * @param flyerView The view that scrolled.
 */
- (void)flyerViewDidScroll:(WFKFlyerView * _Nonnull)flyerView;

/**
 * Called when the flyer view successfully loads the flyer id set by
 * setFlyerId:.
 *
 * @param flyerView The view that began loading.
 */
- (void)flyerViewWillBeginLoading:(WFKFlyerView * _Nonnull)flyerView;

/**
 * Called when the flyer view successfully loads the flyer id set by 
 * setFlyerId:.
 *
 * @param flyerView The view that successfully finished loading.
 */
- (void)flyerViewDidFinishLoading:(WFKFlyerView * _Nonnull)flyerView;

/**
 * Called when the flyer view fails to load the flyer id set by setFlyerId:.
 *
 * @param flyerView The view that failed to load.
 * @param error The error that occurred while loading, or nil.
 */
- (void)flyerViewDidFailLoading:(WFKFlyerView * _Nonnull)flyerView
                      withError:(NSError * _Nullable)error;

@end

/**
 * A protocol implemented for tap annotations.
 */
@protocol WFKFlyerViewTapAnnotation <NSObject>
@required
/**
 * The rectangle in flyer coordinates that should respond to tap and press
 * events.
 */
@property (nonatomic,assign,readonly) CGRect frame;
@end

/**
 * A protocol implemented for annotations.
 */
@protocol WFKFlyerViewBadgeAnnotation <NSObject>
@required
/**
 * The rectangle in flyer coordinates that should respond to tap and press
 * events.
 */
@property (nonatomic,assign,readonly) CGRect frame;

/**
 * The image to display on the flyer.
 */
@property (nonatomic,strong,readonly) UIImage * _Nullable image;
@end

/**
 * A view that displays a scrollable, zoomable flyer.
 */
@interface WFKFlyerView : UIView
/**
 * The set of rectangles to highlight on the flyer, or nil when highlights are
 * disabled.
 */
@property (nonatomic,copy) NSArray * _Nullable highlightAnnotations;

/**
 * The set of annotations to fire callback events on single tap, double tap and
 * long press events, or nil if there are no tap annotations.
 */
@property (nonatomic,copy) NSArray * _Nullable tapAnnotations;

/**
 * The set of annotations to show as images on top of the flyer, or nil if there
 * are no badges.
 */
@property (nonatomic,copy) NSArray * _Nullable badgeAnnotations;

/**
 * The id of the flyer displayed in the flyer view.
 */
@property (nonatomic,assign,readonly) NSInteger flyerId;

/**
 * True if the underlying UIScrollView is tracking user input.
 */
@property (nonatomic,assign,readonly) BOOL isTracking;

/**
 * True if the underlying UIScrollView is decelerating.
 */
@property (nonatomic,assign,readonly) BOOL isDecelerating;

/**
 * Set the id of the flyer to display in the view. This is obtained from the
 * Flipp REST API.
 *
 * @param flyerId The id of the flyer to display.
 * @param rootUrl The rootUrl of the API.
 * @param version The version of the API.
 * @param accessToken The token for accessing the given flyer id.
 */
- (void)setFlyerId:(NSInteger)flyerId
  usingRootUrl:(NSString * _Nullable)rootUrl
  usingVersion:(NSString * _Nullable)version
  usingAccessToken:(NSString * _Nullable)accessToken;

/**
 * The delegate that handles flyer view callbacks.
 */
@property (nonatomic,weak) id<WFKFlyerViewDelegate> _Nullable delegate;

/**
 * Returns the current visible rectangle in flyer coordinates.
 *
 * @return The current visible rectangle in flyer coordinates.
 */
- (CGRect)visibleContent;

/**
 * Returns the size of the flyer coordinate space.
 *
 * @return The size of the flyer coordinate space.
 */
- (CGSize)contentSize;

/**
 * Zoom to the given rectangle in flyer coordinates, optionally animating.
 *
 * @param rect The rectangle to zoom to. The rectangle may be adjusted to keep
 *             it within flyer bounds.
 * @param animated True if the transition should be animated.
 */
- (void)zoomToRect:(CGRect)rect animated:(BOOL)animated;

/**
 * Converts a point in the specified view's coordinate system to a flyer
 * coordinate.
 *
 * @param point The point you want to convert.
 * @param view The view that serves as the reference coordinate system for the
 *        pointer parameter.
 *
 * @return The flyer coordinate at the specified point.
 */
- (CGPoint)convertPoint:(CGPoint)point toFlyerCoordinateFromView:(UIView * _Nonnull)view;

/**
 * Converts a rectangle in the specified view's coordinate system to a flyer
 * region.
 *
 * @param rect The rectangle you want to convert.
 * @param view The view that serves as the reference coordinate system for the
 *        rect parameter.
 *
 * @return The flyer region corresponding to the specified view rectangle.
 */
- (CGRect)convertRect:(CGRect)rect toFlyerRegionFromView:(UIView * _Nonnull)view;

/**
 * Converts a flyer coordinate to a point in the specified view.
 *
 * @param coordinate The flyer coordinate for which you want to find the
 *                   corresponding point.
 * @param view The view in whose coordinate system you want to locate the
 *             specified flyer coordinate. If this parameter is nil, the
 *             returned point is specified in the window's coordinate system.
 *             If view is not nil, it must belong to the same window as the
 *             map view.
 *
 * @return The point (in the appropriate view or window coordinate system)
 *         corresponding to the specified flyer coordinate.
 */
- (CGPoint)convertFlyerCoordinate:(CGPoint)coordinate
                    toPointInView:(UIView * _Nonnull)view;

/**
 * Converts a flyer region to a rectangle in the specified view.
 *
 * @param region The flyer region for which you want to find the corresponding
 *               view rectangle.
 * @param view The view in whose coordinate system you want to locate the
 *             specified flyer region. If this parameter is nil, the returned
 *             rectangle is specified in the window's coordinate system.
 *
 * @return The rectangle corresponding to the specified flyer region.
 */
- (CGRect)convertFlyerRegion:(CGRect)region toRectInView:(UIView * _Nonnull)view;

@end
