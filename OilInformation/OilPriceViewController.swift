//
//  OilPriceViewController.swift
//  OilInformation
//
//  Created by CHIA CHUN LI on 2021/3/20.
//

import UIKit
import GoogleMobileAds
import Network

class OilPriceViewController: UIViewController,XMLParserDelegate {

    @IBOutlet weak var reloadBtn: UIButton!
    @IBOutlet weak var ninetyFiveOilLabel: UILabel!
    @IBOutlet weak var ninetyTwoOilLabel: UILabel!
    @IBOutlet weak var ninetyEightOilLabel: UILabel!
    @IBOutlet weak var superDieselLabel: UILabel!
    @IBOutlet weak var updateTimeLabel: UILabel!
    @IBOutlet weak var bannerView: GADBannerView!
    @IBOutlet weak var coverView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var ninetyFiveOilBtn: UIButton!
    @IBOutlet weak var ninetyTwoOilBtn: UIButton!
    @IBOutlet weak var ninetyEightOilBtn: UIButton!
    @IBOutlet weak var superDieselBtn: UIButton!
    
    var elementString = ""
    var priceEffectiveTimeString = ""
    var priceString = ""

    var priceEffectiveTimeBool = false
    var priceBool = false
   
    var oilPriceArr = [String]()
    var oilPriceEffetiveTimeArr = [String]()
    
    
    
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        coverView.isHidden = false
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        
        ninetyFiveOilBtn.addTarget(self, action: #selector(ninetyFiveOilBtnClick(_:)), for: .touchUpInside)
        ninetyTwoOilBtn.addTarget(self, action: #selector(ninetyTwoOilBtnClick(_:)), for: .touchUpInside)
        ninetyEightOilBtn.addTarget(self, action: #selector(ninetyEightOilBtnClick(_:)), for: .touchUpInside)
        superDieselBtn.addTarget(self, action: #selector(superDieselBtnClick(_:)), for: .touchUpInside)
        
        //判斷有無網路
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            
            switch path.status {
            case .satisfied:
                
                DispatchQueue.main.async {
                    //油價XML
                    self.connectXMLURL(urlString: "https://vipmember.tmtd.cpc.com.tw/OpenData/ListPriceWebService.asmx/getCPCMainProdListPrice")
                    
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    self.coverView.isHidden = true
                     
                }
                
            case .unsatisfied:
                DispatchQueue.main.async {
                    let alert = self.createErrorAlert(alertControllerTitle: "", alertActionTitle: "確定", message: "網路連線品質不佳", alertControllerStyle: .alert, alertActionStyle: .default, viewController: self)
                    self.present(alert, animated: true, completion: nil)

                }
            case .requiresConnection:
                DispatchQueue.main.async {
                    let alert = self.createErrorAlert(alertControllerTitle: "無網路", alertActionTitle: "確定", message: "請連上網路", alertControllerStyle: .alert, alertActionStyle: .default, viewController: self)
                    self.present(alert, animated: true, completion: nil)

                }
            default:
                break
            }
            
            
        }
        monitor.start(queue: DispatchQueue.global())
        
        //執行廣告
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        
        
        
    }
    //95無鉛汽油
    @objc func ninetyFiveOilBtnClick(_ sender:UIButton){
        
        coverView.isHidden = false
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        
        GlobalData.selectOilPriceString = "95無鉛汽油"
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "oilHistorical") as! OilHistoricalViewController
        self.present(vc, animated: true, completion: nil)
        
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        coverView.isHidden = true
        
        
    }
    //92無鉛汽油
    @objc func ninetyTwoOilBtnClick(_ sender:UIButton){
        
        coverView.isHidden = false
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        
        
        GlobalData.selectOilPriceString = "92無鉛汽油"
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "oilHistorical") as! OilHistoricalViewController
        self.present(vc, animated: true, completion: nil)
        
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        coverView.isHidden = true
        
    }
    //98無鉛汽油
    @objc func ninetyEightOilBtnClick(_ sender:UIButton){
        
        coverView.isHidden = false
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        
        GlobalData.selectOilPriceString = "98無鉛汽油"
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "oilHistorical") as! OilHistoricalViewController
        self.present(vc, animated: true, completion: nil)
        
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        coverView.isHidden = true
        
    }
    //超級柴油
    @objc func superDieselBtnClick(_ sender:UIButton){
        
        coverView.isHidden = false
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        
        GlobalData.selectOilPriceString = "超級柴油"
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "oilHistorical") as! OilHistoricalViewController
        self.present(vc, animated: true, completion: nil)
        
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        coverView.isHidden = true
        
    }
    //標籤開始時
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {

        elementString = elementName

        if elementString == "參考牌價"{
            priceBool = true
        }
        if elementString == "牌價生效時間"{
            priceEffectiveTimeBool = true
        }


    }
    //取得XML標籤內的內容
    func parser(_ parser: XMLParser, foundCharacters string: String) {

        let newString = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
      
        if priceBool == true{

            priceString = newString
          
        }
        if priceEffectiveTimeBool == true{

            priceEffectiveTimeString = newString
            
        }

    }
    //標籤結束
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {



        elementString = elementName

        if elementString == "參考牌價"{
            oilPriceArr.append(priceString)
            priceBool = false
        }
        if elementString == "牌價生效時間"{
            oilPriceEffetiveTimeArr.append(priceEffectiveTimeString)
            priceEffectiveTimeBool = false
        }
        //print("oil price arr=\(oilPriceArr)")
        //print("oil price effetive time arr=\(oilPriceEffetiveTimeArr)")


    }
    
    //錯誤警告視窗
    func createErrorAlert(alertControllerTitle:String, alertActionTitle:String,message:String,alertControllerStyle:UIAlertController.Style, alertActionStyle:UIAlertAction.Style,viewController:UIViewController) -> UIAlertController{

        let alert = UIAlertController(title: alertControllerTitle, message: message, preferredStyle: alertControllerStyle)
        let action = UIAlertAction(title: alertActionTitle, style: alertActionStyle) { (action) in
           
            let monitor = NWPathMonitor()
            monitor.pathUpdateHandler = { [self] path in
                
                switch path.status {
                case .satisfied:
                    DispatchQueue.main.async {
                        if self.coverView.isHidden == true && self.activityIndicator.isHidden == true{
                            
                           
                                self.coverView.isHidden = false
                                self.activityIndicator.isHidden = false
                                self.activityIndicator.startAnimating()
                                
                                self.connectXMLURL(urlString: "https://vipmember.tmtd.cpc.com.tw/OpenData/ListPriceWebService.asmx/getCPCMainProdListPrice")

                                self.activityIndicator.stopAnimating()
                                self.activityIndicator.isHidden = true
                                self.coverView.isHidden = true
                            
                            
                        }
                    }
                case .unsatisfied:
                    DispatchQueue.main.async {
                        let alert = self.createErrorAlert(alertControllerTitle: "無網路", alertActionTitle: "確定", message: "請連上網路", alertControllerStyle: .alert, alertActionStyle: .default, viewController: self)
                        self.present(alert, animated: true, completion: nil)

                    }
                case .requiresConnection:
                    DispatchQueue.main.async {
                        let alert = self.createErrorAlert(alertControllerTitle: "無網路", alertActionTitle: "確定", message: "請連上網路", alertControllerStyle: .alert, alertActionStyle: .default, viewController: self)
                        self.present(alert, animated: true, completion: nil)

                    }
                default:
                    break
                }
                
                
            }
            monitor.start(queue: DispatchQueue.global())
           
        }
        alert.addAction(action)
        
        return alert

    }
    
    @objc func relodBtnClick(_ sender:UIButton){
        //print("click")
        
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in

            switch path.status {
            case .satisfied:
                DispatchQueue.main.async {
                    if self.coverView.isHidden == true && self.activityIndicator.isHidden == true{
                  
                            self.coverView.isHidden = false
                            self.activityIndicator.isHidden = false
                            self.activityIndicator.startAnimating()
                           
                            self.connectXMLURL(urlString: "https://vipmember.tmtd.cpc.com.tw/OpenData/ListPriceWebService.asmx/getCPCMainProdListPrice")

                            self.activityIndicator.stopAnimating()
                            self.activityIndicator.isHidden = true
                            self.coverView.isHidden = true
                        
                        
                    }
                }
            case .unsatisfied:
                DispatchQueue.main.async {
                    let alert = self.createErrorAlert(alertControllerTitle: "無網路", alertActionTitle: "確定", message: "請連上網路", alertControllerStyle: .alert, alertActionStyle: .default, viewController: self)
                    self.present(alert, animated: true, completion: nil)

                }
            case .requiresConnection:
                DispatchQueue.main.async {
                    let alert = self.createErrorAlert(alertControllerTitle: "無網路", alertActionTitle: "確定", message: "請連上網路", alertControllerStyle: .alert, alertActionStyle: .default, viewController: self)
                    self.present(alert, animated: true, completion: nil)

                }
            default:
                break
            }


        }
        monitor.start(queue: DispatchQueue.global())

        
    }
    
    func connectXMLURL(urlString:String){
        
        let url = URL(string: urlString)

        if let parser = XMLParser(contentsOf: url!){

                   parser.delegate = self
                   parser.parse()

        }
        
        //print("油價=\(oilPriceArr)")
        
        //油價顯示
        DispatchQueue.main.async {
            self.ninetyFiveOilLabel.text = "95無鉛汽油:"+" "+self.oilPriceArr[1]+"(元/公升)"
            self.ninetyTwoOilLabel.text = "92無鉛汽油:"+" "+self.oilPriceArr[2]+"(元/公升)"
            self.ninetyEightOilLabel.text = "98無鉛汽油:"+" "+self.oilPriceArr[0]+"(元/公升)"
            self.superDieselLabel.text = "超級柴油:"+" "+self.oilPriceArr[4]+"(元/公升)"
        }
                
        //時間格式轉換
        DispatchQueue.main.async {
            let dateFMT = DateFormatter()
            dateFMT.dateFormat = "yyyy-MM-dd'T'HH:mm:ss+HH:mm"
            let date = dateFMT.date(from:self.oilPriceEffetiveTimeArr[0])
            
            let dateFMT2 = DateFormatter()
            dateFMT2.dateFormat = "yyyy-MM-dd"
            let dateString = dateFMT2.string(from: date!)
            self.updateTimeLabel.text = "發布時間:" + " " + dateString
        }
        
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
