//
//  TDKVOControllerCore.h
//  TDKVOController
//
//  Created by jojo on 2020/4/22.
//  Copyright © 2020 jojotov. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Provided in the @c change dictionary of @c TDKVONotificationBlock, and value represents the key-path being observed.
 */
extern NSString *const TDKVONotificationKeyPathKey;

/**
 Block called on key-value chang notification.
 @param observer observer of the change
 @param object object changed
 @param change original change dicionary plus TDKVONotificationKeyPathKey
 */
typedef void (^TDKVONotificationBlock)(id _Nullable observer, id object, NSDictionary<NSKeyValueChangeKey, id> *change);


@interface TDKVOController : NSObject

#pragma mark - Properties
/**
 The observer
 */
@property (nullable, nonatomic, weak, readonly) id observer;

#pragma mark - Initialize
/**
 Creates and returns an initialized KVO controller instance.
 @param observer The object need to be notified on key-value change.
 @return initialized KVO controller instance
 */
+ (instancetype)KVOControllerWithObeserver:(id)observer;

#pragma mark - Observe
/**
 Register observer for key-path change notification of specified object, with default options of `NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld |  NSKeyValueObservingOptionInitial`.

 @param keyPath The key-value to observe.
 @param object The object to observe.
 @param block The callback block of key-path change notification.
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object block:(TDKVONotificationBlock)block;

/**
 Register observer for key-path change notification of specified object, with specified options of `NSKeyValueObservingOptions`.
 
 @param keyPath The key-value to observe.
 @param object The object to observe.
 @param options The observing options.
 @param block The callback block of key-path change notification.
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object options:(NSKeyValueObservingOptions)options block:(TDKVONotificationBlock)block;

/**
 Register observer for a set of key-path change notification of specified object, with default options of `NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld |  NSKeyValueObservingOptionInitial`.
 
 @param keyPaths The key-values to observe.
 @param object The object to observe.
 @param block The callback block of key-path change notification.
 */
- (void)observeValueForKeyPaths:(NSArray<NSString *> *)keyPaths ofObject:(id)object block:(TDKVONotificationBlock)block;

/**
 Register observer for key-path change notification of specified object, with specified options of `NSKeyValueObservingOptions`.
 
 @param keyPaths The key-values to observe.
 @param object The object to observe.
 @param options The observing options.
 @param block The callback block of key-path change notification.
 */
- (void)observeValueForKeyPaths:(NSArray<NSString *> *)keyPaths ofObject:(id)object options:(NSKeyValueObservingOptions)options block:(TDKVONotificationBlock)block;


#pragma mark - Unobserve
/**
 Unobserve key-path change of specified object.
 @param keyPath The key-value to unobserve.
 @param object The object to unobserve.
 */
- (void)unobserveKeyPath:(NSString *)keyPath ofObject:(id)object;

/**
 Unobserve all key-paths change of specified object.
 @param object The object to unobserve.
 */
- (void)unobserveObject:(id)object;

/**
 Unobserve all objects.
 */
- (void)unobserveAll;


@end
NS_ASSUME_NONNULL_END
