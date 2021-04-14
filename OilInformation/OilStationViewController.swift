//
//  OilStationViewController.swift
//  OilInformation
//
//  Created by CHIA CHUN LI on 2021/3/20.
//

import UIKit
import GoogleMobileAds
import MapKit
import CoreLocation
import Network

class OilStationViewController: UIViewController,XMLParserDelegate,MKMapViewDelegate,CLLocationManagerDelegate{

    @IBOutlet weak var bannerView: GADBannerView!
    @IBOutlet weak var myMap: MKMapView!
    @IBOutlet weak var coverView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var cityNameLabel: UILabel!
    @IBOutlet weak var navigationBtn: UIButton!
    @IBOutlet weak var userLocationCenterBtn: UIButton!
    
    var locationManager = CLLocationManager()
    var selectAnnotationCoor:CLLocationCoordinate2D!
    var currentLocationCoor:CLLocationCoordinate2D!
    var userLocation:CLLocationCoordinate2D!
    var cityNameArr = ["台北市","新北市","基隆市","宜蘭縣","桃園市","新竹市","新竹縣","苗栗縣","台中市","彰化縣","南投縣","雲林縣","嘉義市","嘉義縣","台南市","高雄市","屏東縣","台東縣","花蓮縣","澎湖縣","連江縣","金門縣"]
    var userLocationCity = ""
    var updateLocationCity = ""
    
    
    var elementString = ""
    var stationClassString = ""
    var stationNameString = ""
    var stationLatString = ""
    var stationLonString = ""
    var stationServiceTimeString = ""
    
    var stationClassBool = false
    var stationNameBool = false
    var stationLatBool = false
    var stationLonBool = false
    var stationServiceTimeBool = false

    var stationClassArr = [String]()
    var stationNameArr = [String]()
    var stationLatArr = [String]()
    var stationLonArr = [String]()
    var stationServiceTimeArr = [String]()
    
    override func viewDidAppear(_ animated: Bool) {
        
        //檢查是否有網路
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            
            //有網路
            switch path.status {
            case .satisfied:
                
                if CLLocationManager.locationServicesEnabled(){

                    // 首次使用 向使用者詢問定位自身位置權限
                    if self.locationManager.authorizationStatus
                        == .notDetermined {
                        // 取得定位服務授權
                        self.locationManager.requestWhenInUseAuthorization()
                        // 開始定位自身位置
                        self.locationManager.startUpdatingLocation()
                    }
                    // 使用者已經拒絕定位自身位置權限
                    else if self.locationManager.authorizationStatus
                                == .denied {
                        // 提示可至[設定]中開啟權限
                        DispatchQueue.main.async {
                            let errorAlert = self.createErrorAlert(alertControllerTitle: "定位權限已關閉", alertActionTitle: "確定", message: "如要變更權限，請至 設定 > 隱私權 > 定位服務 開啟", alertControllerStyle: .alert, alertActionStyle: UIAlertAction.Style.default, viewController: self)
                            self.present(errorAlert, animated: true, completion: nil)
                        }
                        
                    }
                    // 使用者已經同意定位自身位置權限
                    else if self.locationManager.authorizationStatus
                                == .authorizedWhenInUse {
                        // 開始定位自身位置
                        self.locationManager.startUpdatingLocation()
                    }

                }else{
                    
                    DispatchQueue.main.async {
                        let errorAlert = self.createErrorAlert(alertControllerTitle: "定位權限已關閉", alertActionTitle: "確定", message: "如要變更權限，請至 設定 > 隱私權 > 定位服務 開啟", alertControllerStyle: .alert, alertActionStyle: UIAlertAction.Style.default, viewController: self)
                        self.present(errorAlert, animated: true, completion: nil)
                    }
                    

                }
            //網路連線品質不佳
            case .unsatisfied:
                DispatchQueue.main.async {
                    let alert = self.createErrorAlert(alertControllerTitle: "", alertActionTitle: "確定", message: "網路連線品質不佳", alertControllerStyle: .alert, alertActionStyle: .default, viewController: self)
                    self.present(alert, animated: true, completion: nil)

                }
            //無網路
            case .requiresConnection:
                DispatchQueue.main.async {
                    let alert = self.createErrorAlert(alertControllerTitle: "無網路", alertActionTitle: "確定", message: "請連上網路", alertControllerStyle: .alert, alertActionStyle: .default, viewController: self)
                    self.present(alert, animated: true, completion: nil)

                }
            default:
                break
            }
            
            
        }
        //偵測網路
        monitor.start(queue: DispatchQueue.global())
        
    }
  
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        coverView.isHidden = true
        activityIndicator.isHidden = true
       
        
        navigationBtn.addTarget(self, action: #selector(navigationBtnClick(_:)), for: .touchUpInside)
        userLocationCenterBtn.addTarget(self, action: #selector(userLocationCenterBtnClick(_:)), for: .touchUpInside)
        
        //設定定位精準度
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //設定代理
        locationManager.delegate = self
        locationManager.showsBackgroundLocationIndicator = true
        //取得使用者座標
        userLocation = locationManager.location?.coordinate
        //print("user location lat=\(userLocation.latitude)")
        //print("user location lon=\(userLocation.longitude)")
        
        //顯示使用者位置
        myMap.showsUserLocation = true
        //可縮放
        myMap.isZoomEnabled = true
        //顯示指北針
        myMap.showsCompass = true
        //設定region
        let region = regionWithUserLocation(latitudeDelta: 0.01, longitudeDelta: 0.01, userLocation: userLocation)
        myMap.setRegion(region, animated: true)
        //設定代理器
        myMap.delegate = self
        
        //設定GADBannerView properties
        self.bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        self.bannerView.rootViewController = self
        self.bannerView.load(GADRequest())
        
        
        self.coverView.isHidden = false
        self.activityIndicator.isHidden = false
        self.activityIndicator.startAnimating()
        
                //利用Google Geocoding API用使用者座標取得所在縣市
                let urlString = "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(self.userLocation.latitude),\(self.userLocation.longitude)&key=AIzaSyB-NGdK96BFH5Vc0pmiEUGDk4hovYeuUd0"
                let url = URL(string: urlString)
                URLSession.shared.dataTask(with: url!) { (data, response, error) in
                    
                    let urlResponse = response as! HTTPURLResponse
                    let statusCode = urlResponse.statusCode
                    
                    if statusCode == 200 {
                        
                        do{
                            let jsonData = try JSONSerialization.jsonObject(with: data!, options: []) as! [String:AnyObject]
                            //print("json data=\(jsonData)")
                            let results = jsonData["results"] as! [[String:AnyObject]]
                            let address_components = results[0]["address_components"] as! [[String:AnyObject]]
                            //print("results=\(results)")
                            //print("address_components=\(address_components)")
                            self.userLocationCity = address_components[4]["long_name"] as! String
                            
                            DispatchQueue.main.async {
                                self.cityNameLabel.text = self.userLocationCity
                            }
                            
                            print("city=\(address_components[4]["long_name"] as! String)")
                            
                            //利用使用者所在縣市取得該縣市的加油站資料
                            let urlString = "https://vipmember.tmtd.cpc.com.tw/CPCSTN/STNWebService.asmx/getCityStation?City=\(self.userLocationCity)&Village=&Types="
                            
                            let newUrlString = urlString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
                            
                            let url = URL(string:newUrlString!)
                            
                            if let parser = XMLParser(contentsOf: url!){
            
                                parser.delegate = self
                                parser.parse()
                                
                                for i in 0..<self.stationClassArr.count{
                                    
                                    let stationClassString = self.stationClassArr[i]
                                    let stationNameString = self.stationNameArr[i]
                                    let title = stationClassString + ":" + stationNameString
                                    let stationLat = Double(self.stationLatArr[i])
                                    let stationLon = Double(self.stationLonArr[i])
                                    let serviceTime = self.stationServiceTimeArr[i]
                                   
                                    DispatchQueue.main.async {
                                        //將加油站座標位置建立在地圖上
                                        let annotation = self.createAnnotation(latitude: stationLat!, longitude: stationLon!, title: title, subtitle: serviceTime)
                                        self.myMap.addAnnotation(annotation)
                                   
                                    }
                                    
                                }
                                
                                DispatchQueue.main.async {
                                    self.activityIndicator.stopAnimating()
                                    self.activityIndicator.isHidden = true
                                    self.coverView.isHidden = true
                                }
                                
            
                            }
                            
                        }catch{
                            
                        }
        
                    }else{
                        
                    }
                    
                }.resume()
                
               
               
//                let location:CLLocation = CLLocation(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude)
//                CLGeocoder().reverseGeocodeLocation(location) { (placemark, error) in
//                    guard let placemark = placemark, error == nil else {return}
//                    print("user location city=\(placemark[0].postalCode)")
//                }

    }
   
    //執行導航
    @objc func navigationBtnClick(_ sender:UIButton){
        
        DispatchQueue.main.async {
            MKMapItem.openMaps(with: self.mapNavigation(startCoordinate: self.currentLocationCoor, endCoordinate: self.selectAnnotationCoor), launchOptions: [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving])
        }
            
    }

    
    //標籤開始時
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {

        elementString = elementName
        
        if elementString == "類別"{
            stationClassBool = true
        }
        if elementString == "站名"{
            stationNameBool = true
        }
        if elementString == "經度"{
            stationLonBool = true
        }
        if elementString == "緯度"{
            stationLatBool = true
        }
        if elementString == "營業時間"{
            stationServiceTimeBool = true
        }
        
    }
    
    //取得XML標籤內的內容
    func parser(_ parser: XMLParser, foundCharacters string: String) {

        let newString = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
     
        if stationClassBool == true{

            stationClassString = newString
            stationClassArr.append(stationClassString)
          
        }
        if stationNameBool == true{

            stationNameString = newString
            stationNameArr.append(stationNameString)
        }
        if stationLatBool == true{

            stationLatString = newString
            stationLatArr.append(stationLatString)
          
        }
        if stationLonBool == true{

            stationLonString = newString
            stationLonArr.append(stationLonString)
            
        }
        if stationServiceTimeBool == true{

            stationServiceTimeString = newString
            stationServiceTimeArr.append(stationServiceTimeString)
            
        }
        
//        let title = self.stationClassString + ":" + self.stationNameString
//
//        DispatchQueue.main.async {
//
//            let annotation = self.createAnnotation(latitude: Double(self.stationLatString) ?? 0.0, longitude: Double(self.stationLonString) ?? 0.0, title: title, subtitle: self.stationServiceTimeString)
//            self.myMap.addAnnotation(annotation)
//
//        }
        

    }
    //標籤結束
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {



        elementString = elementName

        if elementString == "類別"{
            stationClassBool = false
        }
        if elementString == "站名"{
            stationNameBool = false
        }
        if elementString == "經度"{
            stationLonBool = false
        }
        if elementString == "緯度"{
            stationLatBool = false
        }
        if elementString == "營業時間"{
            stationServiceTimeBool = false
        }
//        DispatchQueue.main.async {
//            self.activityIndicator.stopAnimating()
//            self.activityIndicator.isHidden = true
//            self.coverView.isHidden = true
//        }
     
    }
    
    
    //顯示annotation view
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation{
            return nil
        }
       
        let pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        pin.canShowCallout = true
        let pinImage = UIImage(named: "gas-station.png")
        pin.image = pinImage
        return pin
        
    }
    
    //定位更新以及取得使用者所在位置座標
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // 印出目前所在位置座標
        let currentLocation :CLLocation =
            locations[0] as CLLocation
        currentLocationCoor = currentLocation.coordinate
        
        //print("user location coor=\(currentLocation.coordinate)")
        
    }
    
    //錯誤警告視窗
    func createErrorAlert(alertControllerTitle:String, alertActionTitle:String,message:String,alertControllerStyle:UIAlertController.Style, alertActionStyle:UIAlertAction.Style,viewController:UIViewController) -> UIAlertController{

        let alert = UIAlertController(title: alertControllerTitle, message: message, preferredStyle: alertControllerStyle)
        let action = UIAlertAction(title: alertActionTitle, style: alertActionStyle) { (action) in
            viewController.dismiss(animated: true, completion: nil)
        }
        alert.addAction(action)
        
        return alert

    }
    
    //導航
    func mapNavigation(startCoordinate:CLLocationCoordinate2D,endCoordinate:CLLocationCoordinate2D) -> [MKMapItem]{
        
        //初始化目的地MKPlacmark
        let endPlaceMark = MKPlacemark(coordinate:endCoordinate)
        //透過placeMark初始化一個MKMapItem
        let endMapItem = MKMapItem(placemark:endPlaceMark)
        //初始化使用者MKPlacemark
        let startPlaceMark = MKPlacemark(coordinate:startCoordinate)
        //透過placeMark初始化一個MKMapItem
        let startMapItem = MKMapItem(placemark:startPlaceMark)
        //建立導航路線起點與終點
        let routes = [startMapItem,endMapItem]
        
        return routes
            
    }
    
    //將地圖顯示區域以使用者定位中心為準
    func regionWithUserLocation(latitudeDelta:CLLocationDegrees,longitudeDelta:CLLocationDegrees,userLocation:CLLocationCoordinate2D) -> MKCoordinateRegion{
        
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        let region = MKCoordinateRegion(center: userLocation, span: span)
        
        return region
        
    }
    
    //輸入經緯度顯示位置
   func createAnnotation(latitude:Double,longitude:Double,title:String,subtitle:String) -> MKPointAnnotation{
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2DMake(latitude,longitude)
        annotation.title = title
        annotation.subtitle = subtitle
        
        return annotation
        
    }
    
    //回到使用者中心點位置
    @objc func userLocationCenterBtnClick(_ sender:UIButton){
        
        //取得使用者座標
        let userLocation = locationManager.location?.coordinate
        //設定region
        let region = regionWithUserLocation(latitudeDelta: 0.03, longitudeDelta: 0.03, userLocation: userLocation!)
        myMap.setRegion(region, animated: true)
        
    }
    
    
    
    //當定位點被點擊時
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        //取得被點擊Annotation的Coordinate
        selectAnnotationCoor = view.annotation?.coordinate
        
        //print("click")
      
        print("select annotation coordinate=\(String(describing: selectAnnotationCoor))")
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
