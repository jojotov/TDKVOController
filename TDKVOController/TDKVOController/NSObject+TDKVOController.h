//
//  NSObject+TDKVOController.h
//  TDKVOController
//
//  Created by jojo on 2017/11/14.
//  Copyright © 2017年 jojo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TDKVOController/TDKVOControllerCore.h>

@interface NSObject (TDKVOController)

/**
 TDKVOController instance for use with any object.
 @discussion This will dealloc when the observer dealloc.
 */
@property (nonatomic, strong) TDKVOController *td_KVOController;


@end
