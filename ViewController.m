//
//  ViewController.m
//  Amap_Demo
//
//  Created by mac book on 16/3/24.
//  Copyright © 2016年 mac book. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()<MAMapViewDelegate,AMapLocationManagerDelegate,AMapSearchDelegate,UITableViewDelegate,UITableViewDataSource>
@property (nonatomic, strong) MAMapView *mapView;
@property (nonatomic, strong) AMapLocationManager *locationManager;
@property (nonatomic, strong) AMapSearchAPI *search;
@property (nonatomic, strong) UITableView *mapItemsTableView;
@property (nonatomic, strong) NSArray *mapItems;
@property (nonatomic, strong) UIView *pointView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [self setUpMap];
    [self getlocationManager];
    [self getSearchAPI:@"紫金"];
    
}
- (void)setUpMap{
    
    [MAMapServices sharedServices].apiKey = AMAP_KEY;
    _mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, 64, SCREEN_WIDTH,SCREEN_HEIGHT * 0.4)];
    _mapView.delegate = self;
    _mapView.showsUserLocation = YES;
    [self.view addSubview:_mapView];
    
    _pointView = [[UIView alloc] initWithFrame:CGRectMake(_mapView.frame.size.width * 0.5 - 5, _mapView.frame.size.height * 0.5 - 2.5, 5, 5)];
    _pointView.backgroundColor = [UIColor redColor];
    [_mapView addSubview:_pointView];
    
    
    
    
    
    
    //配置用户Key
    [AMapSearchServices sharedServices].apiKey = AMAP_KEY;
    //初始化检索对象
    _search = [[AMapSearchAPI alloc] init];
    _search.delegate = self;
    
    
    
    
    
    
    
    _mapItemsTableView = [[UITableView alloc] init];
    //        _mapItemsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _mapItemsTableView.frame = CGRectMake(0, CGRectGetMaxY(_mapView.frame), SCREEN_WIDTH, SCREEN_HEIGHT - CGRectGetMaxY(_mapView.frame));
    _mapItemsTableView.delegate = self;
    _mapItemsTableView.dataSource = self;
    [self.view addSubview:_mapItemsTableView];
    
}
#pragma mark - self
- (void)getlocationManager{
    [AMapLocationServices sharedServices].apiKey =AMAP_KEY;
    self.locationManager = [[AMapLocationManager alloc] init];
    self.locationManager.delegate = self;
    // 带逆地理信息的一次定位（返回坐标和地址信息）
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyHundredMeters];
    //   定位超时时间，可修改，最小2s
//        self.locationManager.locationTimeout = 3;
    //    //   逆地理请求超时时间，可修改，最小2s
//        self.locationManager.reGeocodeTimeout = 3;
    [self.locationManager startUpdatingLocation];
}
//限定范围搜索
- (void)getSearchAPI:(NSString *)keywords{
    
    

    AMapInputTipsSearchRequest *tips;
    if (!tips) {
        tips = [[AMapInputTipsSearchRequest alloc] init];
    }
    
    tips.keywords = keywords;
    tips.city     = @"北京";
    //    tips.cityLimit = YES; 是否限制城市
    
    [self.search AMapInputTipsSearch:tips];
    
}
//正向地理编码
- (void)encodeAddressByAddress:(NSString *)address{
    //构造AMapGeocodeSearchRequest对象，address为必选项，city为可选项
    AMapGeocodeSearchRequest *geo;
    if (!geo) {
        geo = [[AMapGeocodeSearchRequest alloc] init];
    }
    geo.address = address;
    
    //发起正向地理编码
    [_search AMapGeocodeSearch: geo];
}
//逆向地理编码
- (void)decodeAddressbyCoordinate:(CLLocationCoordinate2D)coor{
    
    //构造AMapReGeocodeSearchRequest对象
    AMapReGeocodeSearchRequest *regeo;
    if (!regeo) {
        regeo = [[AMapReGeocodeSearchRequest alloc] init];
    }
    regeo.location = [AMapGeoPoint locationWithLatitude:coor.latitude     longitude:coor.longitude];
    regeo.radius = 10000;
    regeo.requireExtension = YES;
    
    //发起逆地理编码
    [_search AMapReGoecodeSearch: regeo];
}
#pragma mark - table回调
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _mapItems.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *ident = @"nicai";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ident];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ident];
    }
    AMapPOI *poi = _mapItems[indexPath.row];
    NSString *name = [poi.name stringByAppendingString:@"--"];
    name = [name stringByAppendingString:poi.businessArea];
    cell.textLabel.text = name;
    cell.detailTextLabel.text = poi.address;
    return cell;
}
#pragma mark - 代理回调
- (void)mapView:(MAMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    CLLocationCoordinate2D coor = mapView.centerCoordinate;
    [self decodeAddressbyCoordinate:coor];
}
//实现逆地理编码的回调函数
- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response
{
    if(response.regeocode != nil)
    {
        //通过AMapReGeocodeSearchResponse对象处理搜索结果
        AMapReGeocode *result = (AMapReGeocode *)response.regeocode;
        NSLog(@"\n基础信息formattedAddress: %@\n地址addressComponent:%@\n道路信息 AMapRoad 数组:%@\n兴趣点信息 AMapPOI 数组:%@\n兴趣区域信息 AMapAOI 数组:%@", result.formattedAddress,result.addressComponent,result.roads,result.pois,result.aois);
        _mapItems = result.pois;
        [_mapItemsTableView reloadData];
    }
}
/* 输入提示回调. */
- (void)onInputTipsSearchDone:(AMapInputTipsSearchRequest *)request response:(AMapInputTipsSearchResponse *)response
{
//    [self.tips setArray:response.tips];
//    
//    [self.displayController.searchResultsTableView reloadData];
}

//实现正向地理编码的回调函数
- (void)onGeocodeSearchDone:(AMapGeocodeSearchRequest *)request response:(AMapGeocodeSearchResponse *)response
{
    if(response.geocodes.count == 0)
    {
        return;
    }
    
    //通过AMapGeocodeSearchResponse对象处理搜索结果
    NSString *strCount = [NSString stringWithFormat:@"count: %ld", response.count];
    NSString *strGeocodes = @"";
    for (AMapTip *p in response.geocodes) {
        strGeocodes = [NSString stringWithFormat:@"%@\ngeocode: %@", strGeocodes, p.description];
    }
    NSString *result = [NSString stringWithFormat:@"%@ \n %@", strCount, strGeocodes];
    NSLog(@"Geocode: %@", result);
}
// 地理定位回调
- (void)amapLocationManager:(AMapLocationManager *)manager didUpdateLocation:(CLLocation *)location
{
    NSLog(@"location:{lat:%f; lon:%f; accuracy:%f}==%@", location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy,manager.monitoredRegions.allObjects);
    _mapView.region = MACoordinateRegionMake(location.coordinate, MACoordinateSpanMake(0.0045, 0.0045));
    
    
    
    // 带逆地理（返回坐标和地址信息）
    [self.locationManager requestLocationWithReGeocode:YES completionBlock:^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error) {
        
        if (error)
        {
            NSLog(@"locError:{%ld - %@};", (long)error.code, error.localizedDescription);
            
            //            if (error.code == AMapLocatingErrorLocateFailed)
            //            {
            //                return;
            //            }
        }
        
        NSLog(@"location:%@", location);
        
        if (regeocode)
        {
            NSLog(@"reGeocode:%@", regeocode);
        }
    }];
    
}
//- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation{
//    CLLocationCoordinate2D coor = userLocation.location.coordinate;
////    coor = [WGS84TOGCJ02 transformFromWGSToGCJ:coor];
//    mapView.centerCoordinate = coor;
//}

@end
