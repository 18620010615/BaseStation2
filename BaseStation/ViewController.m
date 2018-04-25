//
//  ViewController.m
//  BaseStation
//
//  Created by loop on 2018/4/23.
//  Copyright © 2018年 loop. All rights reserved.
//
#define MAS_SHORTHAND
// 定义这个常量，就可以让Masonry帮我们自动把基础数据类型的数据，自动装箱为对象类型。
#define MAS_SHORTHAND_GLOBALS

#import "ViewController.h"
#import "GPSNavigationViewController.h"
#import "MMSideslipDrawer.h"
#import <CoreLocation/CoreLocation.h>
#import "PYSearch.h"
#import "Masonry.h"
@interface ViewController ()<MMSideslipDrawerDelegate,BMKMapViewDelegate, BMKLocationServiceDelegate, BMKGeoCodeSearchDelegate,PYSearchViewControllerDelegate,BMKRouteSearchDelegate>
{
    //侧滑菜单
    MMSideslipDrawer *slipDrawer;
    //地图
    BMKMapView *_mapView;
    //定位服务对象
    BMKLocationService *_locService;
    //声明地理位置搜索对象（地理编码）
    BMKGeoCodeSearch *_geocodesearch;
    //声明路线搜索对象
    BMKRouteSearch *routeSearch;
    //是否检索成功
    BOOL isGeoSearch;
    //出发地坐标点标记
    BMKPointAnnotation *_pointAnnotation;
    //目的地坐标点标记
    BMKPointAnnotation *_desAnnotation;
    //出发地坐标
    CLLocationCoordinate2D departureCoordinate;
    //目的地坐标
    CLLocationCoordinate2D destinationCoordinate;
    //当前定位地址
    NSString *address;
    //目的地按钮标题
    NSString *destinationBtnTitle;
    //用于显示当前定位地址的Label
    UILabel *BeginPosition;
    //目的地按钮
    UIButton *destinationBtn;
    CLGeocoder *geoC;
    int i;
}
@end

@implementation ViewController

static CLLocationCoordinate2D departurePosition;
static CLLocationCoordinate2D destinationPosition;
+ (void)setDeparturPosition:(CLLocationCoordinate2D )startCoordinate{
    
    departurePosition = startCoordinate ;
}
 
+ (CLLocationCoordinate2D )departurePosition{
    return departurePosition;
}

+ (void)setDestinationPosition:(CLLocationCoordinate2D)endCoordinate{
    
    destinationPosition = endCoordinate ;
}
 
+ (CLLocationCoordinate2D )destinationPosition{
    return destinationPosition;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    //添加地图
    [self addBaiduMap];
    i = 0;
    _geocodesearch = [[BMKGeoCodeSearch alloc] init];
    // _geocodesearch.delegate = self;
    
    //开始定位
    [self startLocation];
    
    // 创建routeSearch服务对象
    routeSearch = [[BMKRouteSearch alloc] init];
    // 设置代理
    routeSearch.delegate = self;
    
    //侧滑栏控件属性设置
    self.navigationItem.title = @"DEMO";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu_left"] style:UIBarButtonItemStylePlain target:self action:@selector(leftDrawerButtonPress:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu_right"] style:UIBarButtonItemStylePlain target:self action:@selector(rightDrawerButtonPress:)];
    
    //起始点输入
    UIView *startPoint = [[UIView alloc]initWithFrame:CGRectMake(50, 20, 250, 30)];
    startPoint.backgroundColor = [UIColor groupTableViewBackgroundColor];
    startPoint.layer.shadowOpacity = 0.5f;
    startPoint.layer.shadowOffset = CGSizeMake(5.0f, -2.0f);
    startPoint.layer.shadowRadius = 35.0f;
    [self.view addSubview:startPoint];
    //约束
    [startPoint mas_makeConstraints:^(MASConstraintMaker *make){
        
        make.left.equalTo(self.view).with.offset(20);
        make.top.equalTo(self.view).with.offset(50);
        make.right.equalTo(self.view).with.offset(-20);
        make.height.equalTo(self.view).multipliedBy(0.1);
    }];
    
    //终点输入
    destinationBtn = [[UIButton alloc]initWithFrame:CGRectMake(50, 50, 250, 30)];
    [destinationBtn setTitle:@"请选择目的基站" forState:UIControlStateNormal];
    [destinationBtn setBackgroundColor:[UIColor whiteColor]];
    [destinationBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [destinationBtn setBackgroundImage:[self imageWithColor:[UIColor groupTableViewBackgroundColor]] forState:UIControlStateHighlighted];
    [destinationBtn addTarget:self action:@selector(searchDestiBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:destinationBtn];
    //约束
    [destinationBtn mas_makeConstraints:^(MASConstraintMaker *make){
        
        make.left.equalTo(self.view).with.offset(20);
        make.top.equalTo(startPoint.mas_bottom).with.offset(0);
        make.right.equalTo(self.view).with.offset(-20);
        make.height.equalTo(self.view).multipliedBy(0.1);
    }];
    
    //当前定位位置label显示
    BeginPosition = [[UILabel alloc]initWithFrame:CGRectMake(50, 24,200, 20)];
    BeginPosition.font = [UIFont systemFontOfSize:12];
    BeginPosition.backgroundColor = [UIColor whiteColor];
    BeginPosition.textAlignment = NSTextAlignmentCenter;
    BeginPosition.textColor = [UIColor blackColor];
    BeginPosition.numberOfLines = 2 ;
    [startPoint addSubview:BeginPosition];
    //约束
    [BeginPosition mas_makeConstraints:^(MASConstraintMaker *make){
        
        make.left.equalTo(startPoint).with.offset(1);
        make.top.equalTo(startPoint).with.offset(1);
        make.right.equalTo(startPoint).with.offset(-1);
        make.bottom.equalTo(startPoint).with.offset(-1);
    }];
    
    //定位按钮
    UIButton *locationBtn = [[UIButton alloc] initWithFrame:CGRectMake(15, 500, 40, 40)];//定位按钮
    [locationBtn setImage:[UIImage imageNamed:@"定位"] forState:UIControlStateNormal];
    [locationBtn setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:1.0]];
    locationBtn.layer.cornerRadius = 4.0;//2.0是圆角的弧度，根据需求自己更改
    locationBtn.layer.shadowOpacity = 0.5f;
    locationBtn.layer.shadowOffset = CGSizeMake(3.0f, -3.0f);
    locationBtn.layer.shadowRadius = 5.0f;
    [locationBtn addTarget:self action:@selector(centerBtn:) forControlEvents:UIControlEventTouchUpInside];//点击，标记移到地图中心点
    [self.view addSubview:locationBtn];
    //约束
    [locationBtn mas_makeConstraints:^(MASConstraintMaker *make){
        make.left.equalTo(self.view).with.offset(20);
        make.bottom.equalTo(self.view).with.offset(-50);
        make.width.mas_equalTo(35);
        make.height.mas_equalTo(35);
    }];
    
    //调用按钮
    UIButton *callBaiduMapBtn = [[UIButton alloc] initWithFrame:CGRectMake(245, 500, 40, 40)];//定位按钮
    [callBaiduMapBtn setImage:[UIImage imageNamed:@"调用"] forState:UIControlStateNormal];
    [callBaiduMapBtn setBackgroundColor:[UIColor colorWithRed:0.99 green:0.99 blue:0.99 alpha:1.0]];
    callBaiduMapBtn.layer.cornerRadius = 4.0;//2.0是圆角的弧度，根据需求自己更改
    callBaiduMapBtn.layer.shadowOpacity = 0.5f;
    callBaiduMapBtn.layer.shadowOffset = CGSizeMake(2.0f, -2.0f);
    callBaiduMapBtn.layer.shadowRadius = 5.0f;
    [callBaiduMapBtn addTarget:self action:@selector(CallBaiduMap:) forControlEvents:UIControlEventTouchUpInside];//点击，标记移到地图中心点
    [self.view addSubview:callBaiduMapBtn];
    //约束
    [callBaiduMapBtn mas_makeConstraints:^(MASConstraintMaker *make){
        make.left.equalTo(self.view).with.offset(245);
        make.bottom.equalTo(self.view).with.offset(-50);
        make.width.mas_equalTo(36);
        make.height.mas_equalTo(36);
    }];
    
}


/**
 *按钮方法
 *点击左下角按钮，使标记点移动到地图正中心
 */
- (void)centerBtn:(UIButton *)sender{
    
    NSLog(@"点击");
    [_mapView removeAnnotation:_pointAnnotation];
    _pointAnnotation = [[BMKPointAnnotation alloc] init];
    _pointAnnotation.coordinate = departureCoordinate;
    [_mapView setCenterCoordinate:departureCoordinate animated:true];
    [_mapView addAnnotation:_pointAnnotation];
    
}

/**
 *按钮方法
 *点击右下角按钮，调用百度地图
 */
- (void)CallBaiduMap:(UIButton *)sender{
    //    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"baidumap://"]]) {
    //            // CLLocationCoordinate2D testCoordinate;
    //            // testCoordinate = CLLocationCoordinate2DMake(22.533369, 113.73896);//目的地坐标点测试
    //
    //            NSMutableDictionary *baiduMapDic = [NSMutableDictionary dictionary];
    //            baiduMapDic[@"title"] = @"百度地图";
    //            NSString *urlString = [[NSString stringWithFormat:@"baidumap://map/direction?origin=%f,%f&destination=%f,%f&mode=driving&mode=driving&coord_type=gcj02",departureCoordinate.latitude,departureCoordinate.longitude,
    //                           destinationCoordinate.latitude,destinationCoordinate.longitude] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    //
    //           [[UIApplication sharedApplication]openURL:[NSURL URLWithString:urlString]];
    //     }
    
    [self.navigationController pushViewController:[[GPSNavigationViewController alloc] initWithNibName:nil bundle:nil] animated:YES];
}

/**
 *按钮方法
 *点击顶部第二行“请选择目的基站”按钮，进入搜索界面
 */
- (void)searchDestiBtn:(UIButton *)sender{
    
    // NSArray *hotSeaches = @[@"Java", @"Python", @"Objective-C", @"Swift", @"C", @"C++", @"PHP", @"C#", @"Perl", @"Go", @"JavaScript", @"R", @"Ruby", @"MATLAB"];
    
    //创建搜索控制器
    PYSearchViewController *searchViewController = [PYSearchViewController searchViewControllerWithHotSearches:nil searchBarPlaceholder:@"搜索目的基站" didSearchBlock:^(PYSearchViewController *searchViewController, UISearchBar *searchBar, NSString *searchText) {
        destinationBtnTitle = searchBar.text;//将搜索栏的输入值赋给按钮title
        [searchViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];//点击搜索后回到地图页
        [destinationBtn setTitle:searchBar.text forState:UIControlStateNormal];
        [destinationBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }];
    searchViewController.delegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:searchViewController];
    [self presentViewController:nav animated:YES completion:nil];
}

/**
 *加载地图方法
 *地图初始化，并将地图加载到主视图中
 */
- (void)addBaiduMap{
    _mapView = [[BMKMapView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    
    //    [_mapView setCenterCoordinate:CLLocationCoordinate2DMake(23.1256, 113.3719)];
    //    _mapView.mapType = BMKMapTypeStandard;//设置地图为空白类型
    //    _mapView.showsUserLocation = YES;//是否显示定位图层（即我的位置的小圆点）
    //    _mapView.userTrackingMode = BMKUserTrackingModeFollow;
    //    _mapView.centerCoordinate = CLLocationCoordinate2DMake(113.367558,23/Users/loop/Documents/work/BaiduDemo-master/BaiduDemo/BaiduMapAPI/BaiduMapAPI_Map.framework/Headers/BMKMapVersion.h:24:55: This function declaration is not a prototype.14016);
    
    [self.view addSubview:_mapView];
    
    //    去除百度地图定位后的蓝色圆圈和定位蓝点(精度圈)
    //    BMKLocationViewDisplayParam *displayParam = [[BMKLocationViewDisplayParam alloc]init];
    //    displayParam.isAccuracyCircleShow = false;//精度圈是否显示
    //    displayParam.locationViewOffsetX = 0;//定位偏移量(经度)
    //    displayParam.locationViewOffsetY = 0;//定位偏移量（纬度）
    //    displayParam.locationViewImgName= @"icon";//定位图标名称 去除蓝色的圈
    //    [_mapView updateLocationViewWithParam:displayParam];
}

/**
 *定位方法
 *初始化定位服务，并开启定位服务
 */
- (void)startLocation {
    
    //初始化BMKLocationService
    _locService = [[BMKLocationService alloc]init];
    [_locService startUserLocationService];//启动LocationService
}

/**
 *地理编码方法
 *地理编码管理器，将位置转化为坐标
 */
- (CLGeocoder *)geoC
{
    if (!geoC) {
        geoC = [[CLGeocoder alloc] init];
    }
    return geoC;
}

/**
 *视图即将可见时调用的方法
 *此处用来显示用户在目的地搜索界面输入的目的地在地图上的位置
 */
-(void)viewWillAppear:(BOOL)animated
{
    [_mapView viewWillAppear];
    _mapView.delegate = self; // 此处记得不用的时候需要置nil，否则影响内存的释放
    _locService.delegate = self;
    _geocodesearch.delegate = self;
    
    if(destinationBtnTitle != nil){
        geoC = [[CLGeocoder alloc] init];
        NSString *oreillyAddress = destinationBtnTitle;
        [geoC geocodeAddressString:oreillyAddress completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
            if ([placemarks count] > 0 && error == nil) {
                NSLog(@"Found %lu placemark(s).", (unsigned long)[placemarks count]);
                CLPlacemark *firstPlacemark = [placemarks objectAtIndex:0];
                NSLog(@"edg %@",firstPlacemark.name);
                NSLog(@"Longitude = %f", firstPlacemark.location.coordinate.longitude);
                NSLog(@"Latitude = %f", firstPlacemark.location.coordinate.latitude);
                destinationCoordinate.latitude = firstPlacemark.location.coordinate.latitude;
                destinationCoordinate.longitude = firstPlacemark.location.coordinate.longitude;
                destinationPosition = destinationCoordinate;//将目的基站坐标赋给导航终点
            }
            else if ([placemarks count] == 0 && error == nil) {
                NSLog(@"Found no placemarks.");
            } else if (error != nil) {
                NSLog(@"An error occurred = %@", error);
            }
            
            _desAnnotation = [[BMKPointAnnotation alloc] init];
            _desAnnotation.coordinate = destinationCoordinate;
            [_mapView setCenterCoordinate:destinationCoordinate animated:true];
            [_mapView addAnnotation:_desAnnotation];
        }];
        
    }
}

/**
 *视图即将消失时调用的方法
 *代理置空，避免野指针造成Crash
 */
-(void)viewWillDisappear:(BOOL)animated
{
    [_mapView viewWillDisappear];
    _mapView.delegate = nil; // 不用时，置nil
    _locService.delegate = nil;
    _geocodesearch.delegate = nil;
}

/**
 *在地图View将要启动定位时，会调用此函数
 *@param mapView 地图View
 */
- (void)willStartLocatingUser
{
    NSLog(@"start locate");
}


#pragma mark - BMK_LocationDelegate 百度地图 /** *定位失败后，会调用此函数 *@param error 错误号 */
- (void)didFailToLocateUserWithError:(NSError *)error {
    
    NSLog(@"地图定位失败======%@",error);
}

//处理位置坐标更新
- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation
{
    NSLog(@"获取坐标成功");
    NSLog(@"didUpdateUserLocation lat %f,long %f",userLocation.location.coordinate.latitude,userLocation.location.coordinate.longitude);
    //    //更新地图上的位置
    //    [_mapView updateLocationData:userLocation];
    if (userLocation.location != nil) {
        
        [_mapView updateLocationData:userLocation];
        departureCoordinate = userLocation.location.coordinate;
        departureCoordinate.latitude = userLocation.location.coordinate.latitude;
        departureCoordinate.longitude = userLocation.location.coordinate.longitude;
        departurePosition = departureCoordinate;//将定位坐标赋给导航起始点
        [_mapView setZoomLevel:19.0];
        [_mapView setCenterCoordinate:departureCoordinate animated:true];
        
        if (_pointAnnotation == nil){
            
            _pointAnnotation = [[BMKPointAnnotation alloc] init];
            _pointAnnotation.coordinate = departureCoordinate;
        }
        [_mapView addAnnotation:_pointAnnotation];
        NSLog(@"edf %@ ",_pointAnnotation);
        //反编码地理位置
        BMKReverseGeoCodeOption *reverseGeocodeSearchOption = [[BMKReverseGeoCodeOption alloc] init];
        reverseGeocodeSearchOption.reverseGeoPoint = departureCoordinate;
        if ([_geocodesearch reverseGeoCode:reverseGeocodeSearchOption]) {
            [_locService stopUserLocationService];
        }
    }
    
    
}



#pragma mark -------------地理反编码的delegate---------------

-(void)onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKReverseGeoCodeResult *)result errorCode:(BMKSearchErrorCode)error
{
    NSString *addr = result.addressDetail.district;
    NSString *addr0 = result.addressDetail.streetName;
    NSString *addr1 = result.addressDetail.streetNumber;
    NSString *addr2 = result.sematicDescription;
    addr0 = [addr0 stringByAppendingString:addr1];
    addr = [addr stringByAppendingString:addr0];
    addr = [addr stringByAppendingString:@"\n"];
    addr = [addr stringByAppendingString:addr2];
    
    
    BeginPosition.text = addr;
    
    NSLog(@"address:%@----%@-----%@",result.addressDetail, result.address,result.sematicDescription);
    if (error == 0) {
        [_locService stopUserLocationService];
        //        address = result.sematicDescription;
        //        _pointAnnotation.title = result.address;
        //        _pointAnnotation.subtitle = address;
        
        //        //当前位置标注
        //        _pointAnnotation = [[BMKPointAnnotation alloc] init];
        //        _pointAnnotation.coordinate = pt;
        //        [_mapView setCenterCoordinate:pt animated:true];
        //        NSLog(@"nil %@",_pointAnnotation);
        //        [_mapView addAnnotation:_pointAnnotation];
        
    }else{
        NSLog(@"address:定位失败+++++");
    }
    
    
    
    
    //addressDetail:     层次化地址信息
    
    //address:    地址名称
    
    //businessCircle:  商圈名称
    
    // location:  地址坐标
    
    //  poiList:   地址周边POI信息，成员类型为BMKPoiInfo
    
    //    if (error==0) {
    //        BMKPointAnnotation *item=[[BMKPointAnnotation alloc] init];
    //        item.coordinate=result.geoPt;//地理坐标
    //        item.title=result.strAddr;//地理名称
    //        [_mapView addAnnotation:item];
    //        _mapView.centerCoordinate=result.geoPt;
    //
    //        self.lalAddress.text=[result.strAddr stringByReplacingOccurrencesOfString:@"-" withString:@""];
    //        if (![self.lalAddress.text isEqualToString:@""]) {
    //            strProvince=result.addressComponent.province;//省份
    //            strCity=result.addressComponent.city;//城市
    //            strDistrict=result.addressComponent.district;//地区
    //        }
    //    }
    
}

#pragma mark - 懒加载
- (MMSideslipDrawer *)slipDrawer
{
    if (!slipDrawer)
    {
        MMSideslipItem *item = [[MMSideslipItem alloc] init];
        item.thumbnailPath = [[NSBundle mainBundle] pathForResource:@"menu_head@2x" ofType:@"png"];
        item.userName = @"LEA";
        item.userLevel = @"普通会员";
        item.levelImageName = @"menu_vip";
        item.textArray = @[@"行程",@"钱包",@"客服",@"设置"];
        item.imageNameArray = @[@"menu_0",@"menu_1",@"menu_2",@"menu_3"];
        
        slipDrawer = [[MMSideslipDrawer alloc] initWithDelegate:self slipItem:item];
    }
    return slipDrawer;
}

#pragma mark - 侧滑点击
- (void)leftDrawerButtonPress:(id)sender
{
    [self.slipDrawer openLeftDrawerSide];
}

- (void)rightDrawerButtonPress:(id)sender
{
    NSLog(@"右边点击");
}

#pragma mark - MMSideslipDrawerDelegate
- (void)slipDrawer:(MMSideslipDrawer *)slipDrawer didSelectAtIndex:(NSInteger)index
{
    [slipDrawer colseLeftDrawerSide];
    NSLog(@"点击的index:%ld",(long)index);
}

- (void)didViewUserInformation:(MMSideslipDrawer *)slipDrawer
{
    [slipDrawer colseLeftDrawerSide];
    NSLog(@"点击头像");
}

- (void)didViewUserLevelInformation:(MMSideslipDrawer *)slipDrawer
{
    [slipDrawer colseLeftDrawerSide];
    NSLog(@"点击会员");
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 导航方法
- (NSArray *)getInstalledMapAppWithEndLocation:(CLLocationCoordinate2D)endLocation
{
    NSMutableArray *maps = [NSMutableArray array];
    
    //苹果地图
    NSMutableDictionary *iosMapDic = [NSMutableDictionary dictionary];
    iosMapDic[@"title"] = @"苹果地图";
    [maps addObject:iosMapDic];
    
    //百度地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"baidumap://"]]) {
        NSMutableDictionary *baiduMapDic = [NSMutableDictionary dictionary];
        baiduMapDic[@"title"] = @"百度地图";
        NSString *urlString = [[NSString stringWithFormat:@"baidumap://map/direction?origin={{我的位置}}&destination=latlng:%f,%f|name=北京&mode=driving&coord_type=gcj02",endLocation.latitude,endLocation.longitude] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        baiduMapDic[@"url"] = urlString;
        [maps addObject:baiduMapDic];
    }
    
    //高德地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"iosamap://"]]) {
        NSMutableDictionary *gaodeMapDic = [NSMutableDictionary dictionary];
        gaodeMapDic[@"title"] = @"高德地图";
        NSString *urlString = [[NSString stringWithFormat:@"iosamap://navi?sourceApplication=%@&backScheme=%@&lat=%f&lon=%f&dev=0&style=2",@"导航功能",@"nav123456",endLocation.latitude,endLocation.longitude] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        gaodeMapDic[@"url"] = urlString;
        [maps addObject:gaodeMapDic];
    }
    
    //谷歌地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"comgooglemaps://"]]) {
        NSMutableDictionary *googleMapDic = [NSMutableDictionary dictionary];
        googleMapDic[@"title"] = @"谷歌地图";
        NSString *urlString = [[NSString stringWithFormat:@"comgooglemaps://?x-source=%@&x-success=%@&saddr=&daddr=%f,%f&directionsmode=driving",@"导航测试",@"nav123456",endLocation.latitude, endLocation.longitude] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        googleMapDic[@"url"] = urlString;
        [maps addObject:googleMapDic];
    }
    
    //腾讯地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"qqmap://"]]) {
        NSMutableDictionary *qqMapDic = [NSMutableDictionary dictionary];
        qqMapDic[@"title"] = @"腾讯地图";
        NSString *urlString = [[NSString stringWithFormat:@"qqmap://map/routeplan?from=我的位置&type=drive&tocoord=%f,%f&to=终点&coord_type=1&policy=0",endLocation.latitude, endLocation.longitude] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        qqMapDic[@"url"] = urlString;
        [maps addObject:qqMapDic];
    }
    
    return maps;
}

//  颜色转换为背景图片
- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - PYSearchViewControllerDelegate
- (void)searchViewController:(PYSearchViewController *)searchViewController searchTextDidChange:(UISearchBar *)seachBar searchText:(NSString *)searchText
{
    if (searchText.length) {
        // Simulate a send request to get a search suggestions
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSMutableArray *searchSuggestionsM = [NSMutableArray array];
            for (int i = 0; i < arc4random_uniform(5) + 10; i++) {
                NSString *searchSuggestion = [NSString stringWithFormat:@"Search suggestion %d", i];
                [searchSuggestionsM addObject:searchSuggestion];
            }
            // Refresh and display the search suggustions
            searchViewController.searchSuggestions = searchSuggestionsM;
        });
    }
}




@end
