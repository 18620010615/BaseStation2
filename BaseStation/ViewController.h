//
//  ViewController.h
//  BaseStation
//
//  Created by loop on 2018/4/23.
//  Copyright © 2018年 loop. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

+ (UIImage *)imageWithColor:(UIColor *)color;
//将出发点坐标传到导航
+ (void)setDeparturePosition:(CLLocationCoordinate2D ) startCoordinate;
+ (CLLocationCoordinate2D ) departurePosition;
//将目的基站坐标传到导航
+ (void)setDestinationPosition:(CLLocationCoordinate2D ) endCoordinate;
+ (CLLocationCoordinate2D ) destinationPosition;
@end

