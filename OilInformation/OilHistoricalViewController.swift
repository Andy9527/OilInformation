//
//  OilHistoricalViewController.swift
//  OilInformation
//
//  Created by CHIA CHUN LI on 2021/3/22.
//

import UIKit
import Charts
import GoogleMobileAds
import Network

class OilHistoricalViewController: UIViewController,XMLParserDelegate{
    
  
    @IBOutlet weak var oilHistoricalLineChartView: LineChartView!
    @IBOutlet weak var bannerView: GADBannerView!
    @IBOutlet weak var dismissBtn: UIButton!
    @IBOutlet weak var coverView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var updateTimeLabel: UILabel!
    
    
    var ninetyFiveElementString = ""
    var ninetyTwoElementString = ""
    var ninetyEightElementString = ""
    var superDieselElementString = ""
    var updateTimeElementString = ""
    
    var ninetyFivePriceString = ""
    var ninetyTwoPriceString = ""
    var ninetyEightPriceString = ""
    var superDieselPriceString = ""
    var updateTimeString = ""
    
    var ninetyFivePriceBool = false
    var ninetyTwoPriceBool = false
    var ninetyEightPriceBool = false
    var superDieselPriceBool = false
    var updateTimeBool = false
   
    var ninetyFivePriceArr = [String]()
    var ninetyTwoPriceArr = [String]()
    var ninetyEightPriceArr = [String]()
    var superDieselPriceArr = [String]()
    var updateTimeArr = [String]()
    
    var ninetyFiveParser:XMLParser!
    var ninetyTwoParser:XMLParser!
    var ninetyEightParser:XMLParser!
    var superDieselParser:XMLParser!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        coverView.isHidden = false
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        dismissBtn.addTarget(self, action: #selector(dismissBtnClick(_:)), for: .touchUpInside)
        
        //判斷點擊的油價
        switch GlobalData.selectOilPriceString {
        case "95無鉛汽油":
            //該油價歷史資訊XML
            let ninetyFiveURLString = "https://vipmember.tmtd.cpc.com.tw/opendata/ListPriceWebService.asmx/getCPCMainProdListPrice_Historical?prodid=2"
            let ninetyFiveURL = URL(string:ninetyFiveURLString)
            //XML parser
            ninetyFiveParser = XMLParser(contentsOf: ninetyFiveURL!)
            ninetyFiveParser.delegate = self
            ninetyFiveParser.parse()
            //因最新資料在最底下 執行資料反轉排序
            ninetyFivePriceArr.reverse()
            updateTimeArr.reverse()
            //將取得的最新十筆資料顯示折線圖
            oilHistoricalLineChartView.data = priceArrConvertToLineChartData(priceArr: ninetyFivePriceArr, label: "95無鉛汽油")
        case "92無鉛汽油":
            let ninetyTwoURLString = "https://vipmember.tmtd.cpc.com.tw/opendata/ListPriceWebService.asmx/getCPCMainProdListPrice_Historical?prodid=1"
            let ninetyTwoURL = URL(string:ninetyTwoURLString)
            ninetyTwoParser = XMLParser(contentsOf: ninetyTwoURL!)
            ninetyTwoParser.delegate = self
            ninetyTwoParser.parse()
            ninetyTwoPriceArr.reverse()
            updateTimeArr.reverse()
            oilHistoricalLineChartView.data = priceArrConvertToLineChartData(priceArr: ninetyTwoPriceArr, label: "92無鉛汽油")
        case "98無鉛汽油":
            let ninetyEightURLString = "https://vipmember.tmtd.cpc.com.tw/opendata/ListPriceWebService.asmx/getCPCMainProdListPrice_Historical?prodid=3"
            let ninetyEightURL = URL(string:ninetyEightURLString)
            ninetyEightParser = XMLParser(contentsOf: ninetyEightURL!)
            ninetyEightParser.delegate = self
            ninetyEightParser.parse()
            ninetyEightPriceArr.reverse()
            updateTimeArr.reverse()
            oilHistoricalLineChartView.data = priceArrConvertToLineChartData(priceArr: ninetyEightPriceArr, label: "98無鉛汽油")
        case "超級柴油":
            let superDieselURLString = "https://vipmember.tmtd.cpc.com.tw/opendata/ListPriceWebService.asmx/getCPCMainProdListPrice_Historical?prodid=4"
            let superDieselURL = URL(string:superDieselURLString)
            superDieselParser = XMLParser(contentsOf: superDieselURL!)
            superDieselParser.delegate = self
            superDieselParser.parse()
            superDieselPriceArr.reverse()
            updateTimeArr.reverse()
            oilHistoricalLineChartView.data = priceArrConvertToLineChartData(priceArr: superDieselPriceArr, label: "超級柴油")
        default:
            break
        }
        
        //時間格式轉換顯示最新牌價生效時間
        let updateTimeString = updateTimeArr.first
        let dateFMT = DateFormatter()
        dateFMT.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let date = dateFMT.date(from: updateTimeString!)
        
        let dateFMT2 = DateFormatter()
        dateFMT2.dateFormat = "yyyy-MM-dd"
        let newDateString = dateFMT2.string(from: date!)
        updateTimeLabel.text = "牌價生效時間:" + newDateString
        
        //執行廣告
        self.bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        self.bannerView.rootViewController = self
        self.bannerView.load(GADRequest())
        
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        coverView.isHidden = true
       
        //print("ninety five arr=\(ninetyFivePriceArr)")
        //print("ninety two arr=\(ninetyTwoPriceArr)")
        //print("ninety eight arr=\(ninetyEightPriceArr)")
        //print("ninety superDiesel arr=\(superDieselPriceArr)")
        
        
        // Do any additional setup after loading the view.
    }
    //返回上一頁
    @objc func dismissBtnClick(_ sender:UIButton){
        self.dismiss(animated: true, completion: nil)
    }
   
    func priceArrConvertToLineChartData(priceArr:[String],label:String) -> LineChartData{
        
        //反轉排序後取得前十筆最新資料
        var newPriceArr = priceArr[0...9]
        //print("new price arr=\(newPriceArr)")
        //再反轉排序資料一次 折線圖上顯示由左至右呈現
        newPriceArr.reverse()
        //建立 chartDataEntry物件
        var dataEntries = [ChartDataEntry]()
        for i in 0..<newPriceArr.count{
            let entry = ChartDataEntry(x: Double(i), y: Double(newPriceArr[i])!)
            dataEntries.append(entry)
        }
        //建立chartDataSet物件
        let chartDataSet = LineChartDataSet(entries: dataEntries, label: label)
        //建立chartData物件
        let chartData = LineChartData(dataSet: chartDataSet)
        
        return chartData
      
    }
    //標籤開始時
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {

        switch parser {
        case ninetyFiveParser:
            
            ninetyFiveElementString = elementName
            if ninetyFiveElementString == "參考牌價"{
                ninetyFivePriceBool = true
            }
            if ninetyFiveElementString == "牌價生效時間"{
                updateTimeBool = true
            }
            
        case ninetyTwoParser:
            
            ninetyTwoElementString = elementName
            if ninetyTwoElementString == "參考牌價"{
                ninetyTwoPriceBool = true
            }
            if ninetyTwoElementString == "牌價生效時間"{
                updateTimeBool = true
            }
        case ninetyEightParser:
            
            ninetyEightElementString = elementName
            if ninetyEightElementString == "參考牌價"{
                ninetyEightPriceBool = true
            }
            if ninetyEightElementString == "牌價生效時間"{
                updateTimeBool = true
            }
        case superDieselParser:
            
            superDieselElementString = elementName
            if superDieselElementString == "參考牌價"{
                superDieselPriceBool = true
            }
            if superDieselElementString == "牌價生效時間"{
                updateTimeBool = true
            }
            
        default:
            break
        }
        
       
        
        
        
    }
    //取得XML標籤內的內容
    func parser(_ parser: XMLParser, foundCharacters string: String) {

        let newString = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
     
        switch parser {
        case ninetyFiveParser:
            
            if ninetyFivePriceBool == true{
                ninetyFivePriceString = newString
                ninetyFivePriceArr.append(ninetyFivePriceString)
            }
            if updateTimeBool == true{
                updateTimeString = newString
                updateTimeArr.append(updateTimeString)
            }
            
        case ninetyTwoParser:
            
            if ninetyTwoPriceBool == true{
                ninetyTwoPriceString = newString
                ninetyTwoPriceArr.append(ninetyTwoPriceString)
            }
            if updateTimeBool == true{
                updateTimeString = newString
                updateTimeArr.append(updateTimeString)
            }
        case ninetyEightParser:
            
            if ninetyEightPriceBool == true{
                ninetyEightPriceString = newString
                ninetyEightPriceArr.append(ninetyEightPriceString)
            }
            if updateTimeBool == true{
                updateTimeString = newString
                updateTimeArr.append(updateTimeString)
            }
        case superDieselParser:
            
            if superDieselPriceBool == true{
                superDieselPriceString = newString
                superDieselPriceArr.append(superDieselPriceString)
            }
            if updateTimeBool == true{
                updateTimeString = newString
                updateTimeArr.append(updateTimeString)
            }
        default:
            break
        }
      
        
    }
    //標籤結束
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {

        
        switch parser {
        case ninetyFiveParser:
            
            ninetyFiveElementString = elementName
            if ninetyFiveElementString == "參考牌價"{
                ninetyFivePriceBool = false
            }
            if ninetyFiveElementString == "牌價生效時間"{
                updateTimeBool = false
            }
            
        case ninetyTwoParser:
            
            ninetyTwoElementString = elementName
            if ninetyTwoElementString == "參考牌價"{
                ninetyTwoPriceBool = false
            }
            if ninetyTwoElementString == "牌價生效時間"{
                updateTimeBool = false
            }
        case ninetyEightParser:
            
            ninetyEightElementString = elementName
            if ninetyEightElementString == "參考牌價"{
                ninetyEightPriceBool = false
            }
            if ninetyEightElementString == "牌價生效時間"{
                updateTimeBool = false
            }
        case superDieselParser:
            
            superDieselElementString = elementName
            if superDieselElementString == "參考牌價"{
                superDieselPriceBool = false
            }
            if superDieselElementString == "牌價生效時間"{
                updateTimeBool = false
            }
        default:
            break
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
