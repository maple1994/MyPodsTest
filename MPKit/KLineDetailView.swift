
//  KLineDetailView.swift
//  kLineDemo
//
//  Created by Maple on 2017/4/11.
//  Copyright © 2017年 Maple. All rights reserved.
//

import UIKit

class KLineDetailView: UIView, KLineToolsViewDelegate, DrawViewDelegate{

    /// 缩放的增量
    private var scaleIncrement: CGFloat = 0.05
    /// 当前在展示的模型数组
    private var displayKLineModelArr: [KLineModel]!
    /// 记录当前展示的模型数组的start
    private var start: Int!
    /// 记录当前展示的模型数组的end
    private var end: Int!
    /// 展示的range
    private var displayRange: NSRange!
    /// 记录选中的k线模型
    private var selectedKLineModel: KLineModel? {
        didSet {
            kLineContainer.selectedKLineModel = selectedKLineModel
        }
    }
    /// 是否在移动
    private var isMove:Bool = false
    /// x轴间距
    private var stepX: CGFloat!
        {
        didSet {
            resetData()
        }
    }
    /// k线模型数组
    var kLineModelArr: [KLineModel]! {
        didSet {
            // 默认显示数组中最后一个元素
            if kLineModelArr.count > 1 {
                end = kLineModelArr.count - 1
            }else {
                end = 0
            }
            kLineContainer.selectedKLineModel = kLineModelArr.last
        }
    }
    /// 资金净额模型数组
    var zjjeModelArr: [ZJJEModel]!
    /// 对倒金额模型数组
    var ddjeModelArr: [DDJEModel]!
    /// 托压金额模型数组
    var tyjeModelArr: [TYJEModel]!
    /// 主力活跃度模型数组
    var zlhyModelArr: [ZLHYModel]!
    
    /// K线图区域
    lazy var kLineContainer: KLineViewContainer = {
        let view = KLineViewContainer()
        return view
    }()
    /// 画板
    lazy var drawView: DrawView = DrawView()
    /// 柱状图
    lazy var barView: KLineBarView = {
        let view = KLineBarView()
        return view
    }()
    /// 指标视图容器
    lazy var indicatorContainer: IndicatorViewContianer = IndicatorViewContianer()
    init() {
        super.init(frame:CGRectZero)
        self.backgroundColor = UIColor.whiteColor()
        setupUI()
        stepX = defaultStepX
        kLineContainer.stepX = defaultStepX
        
        kLineContainer.lineView.toolViewDelegate = self
        drawView.barView = barView
        drawView.indicatorContainer = indicatorContainer
        drawView.toolView = kLineContainer.lineView.toolView
        drawView.delegate = self
    }

    /// 布局
    private func setupUI() {
        self.addSubview(kLineContainer)
        self.addSubview(barView)
        self.addSubview(indicatorContainer)
        self.addSubview(drawView)
        kLineContainer.translatesAutoresizingMaskIntoConstraints = false
        barView.translatesAutoresizingMaskIntoConstraints = false
        indicatorContainer.translatesAutoresizingMaskIntoConstraints = false
        drawView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addConstraint(NSLayoutConstraint(item: drawView, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: drawView, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: drawView, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: drawView, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: 0))
        
        // 上左右0，高0.6
        self.addConstraint(NSLayoutConstraint(item: kLineContainer, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: kLineContainer, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: kLineContainer, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: kLineContainer, attribute: .Height, relatedBy: .Equal, toItem: self, attribute: .Height, multiplier: 0.6, constant: 0))
        
        // top = timeRegionView.bottomm, 左右0, 高0.2
        self.addConstraint(NSLayoutConstraint(item: barView, attribute: .Top, relatedBy: .Equal, toItem: kLineContainer, attribute: .Bottom, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: barView, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: barView, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: barView, attribute: .Height, relatedBy: .Equal, toItem: self, attribute: .Height, multiplier: 0.2, constant: 0))
        
        // 底，左右0, 高0.2
        self.addConstraint(NSLayoutConstraint(item: indicatorContainer, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: indicatorContainer, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: indicatorContainer, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1, constant: 0))
        self.addConstraint(NSLayoutConstraint(item: indicatorContainer, attribute: .Height, relatedBy: .Equal, toItem: self, attribute: .Height, multiplier: 0.2, constant: -3))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        resetData()
    }
    
    /// 重置数据
    private func resetData() {
        kLineContainer.stepX = stepX
        barView.stepX = stepX
        indicatorContainer.stepX = stepX
        drawView.stepX = stepX
        let modelArr = self.getDisplayModelArr()
        // 赋值
        // 提前给k线图的frame赋值，为了提前给drawView赋值，这里写的很恶心。。。
        kLineContainer.lineView.priceLineRect = CGRect(x: spaceX, y: spaceY, width: kLineContainer.frame.width - spaceX * 2, height: (self.frame.height - 2 * spaceY))
        kLineContainer.lineView.height = kLineContainer.frame.height - 20
        kLineContainer.kLineModelArr = modelArr
        displayKLineModelArr = modelArr
        barView.kLineModelArr = modelArr
        indicatorContainer.kLineModelArr = modelArr
        drawView.kLineModelArr = kLineContainer.lineView.kLineModelArr
        drawView.maxPrice = kLineContainer.lineView.maxY
        drawView.minPrice = kLineContainer.lineView.minY
        
        indicatorContainer.zjjeModelArr = getDisplayZJJEModelArr()
        indicatorContainer.ddjeModelArr = getDisplayDDJEModelArr()
        indicatorContainer.tyjeModelArr = getDisplayTYJEModelArr()
        indicatorContainer.zlhyModelArr = getDisplayZLHYModelArr()
    }
    
    /// 展示主力活跃度数组
    private func getDisplayZLHYModelArr() -> [ZLHYModel]! {
        let tmpArr = zlhyModelArr as NSArray
        var currentArr = tmpArr
        currentArr = tmpArr.subarrayWithRange(displayRange)
        return currentArr as! [ZLHYModel]
    }
    
    /// 展示托压金额数组
    private func getDisplayTYJEModelArr() -> [TYJEModel]! {
        let tmpArr = tyjeModelArr as NSArray
        var currentArr = tmpArr
        currentArr = tmpArr.subarrayWithRange(displayRange)
        return currentArr as! [TYJEModel]
    }
    
    /// 展示对倒金额数组
    private func getDisplayDDJEModelArr() -> [DDJEModel]! {
        let tmpArr = ddjeModelArr as NSArray
        var currentArr = tmpArr
        currentArr = tmpArr.subarrayWithRange(displayRange)
        return currentArr as! [DDJEModel]
    }

    /// 展示资金金额数组
    private func getDisplayZJJEModelArr() -> [ZJJEModel]! {
        let tmpArr = zjjeModelArr as NSArray
        var currentArr = tmpArr
        currentArr = tmpArr.subarrayWithRange(displayRange)
        return currentArr as! [ZJJEModel]
    }
    
    /// 获得展示的区间模型
    private func getDisplayModelArr() -> [KLineModel]! {
        // 显示区间的选择
        let wid = kLineContainer.frame.width - 2 * kLineContainer.lineView.spaceX
        let lenght = Int(wid / stepX)
        let tmpArr = kLineModelArr as NSArray
        var currentArr = tmpArr
        if end > kLineModelArr.count - 1{
            end = kLineModelArr.count - 1
        }
        start = end - lenght + 1
        if start >= 0 {
            currentArr = tmpArr.subarrayWithRange(NSMakeRange(start, lenght))
        }
        displayRange = NSMakeRange(start, lenght)
        // 缩放时需要考虑十字线的位置，移动时不需要考虑
        if !isMove {
            if let date = selectedKLineModel?.dateStr {
                let firstModel = currentArr.firstObject as! KLineModel
                // 选中日期已经超出左边界，这时以选中的日期作为起点，向右扩展
                if  isBigger(firstModel.dateStr!, biggerThan: date) {
                    start = kLineModelArr.indexOf(selectedKLineModel!)
                    currentArr = tmpArr.subarrayWithRange(NSMakeRange(start, lenght))
                    end = start + lenght - 1
                    displayRange = NSMakeRange(start, lenght)
                }
            }
        }
        isMove = false
        return currentArr as! [KLineModel]
    }
    
    /// 判断date1字符串是否大于date2字符串
    private func isBigger(dateStr1: String, biggerThan dateStr2:String) -> Bool {
        let df = NSDateFormatter()
        df.dateFormat = "yyyyMMdd"
        let date1 = df.dateFromString(dateStr1)
        let date2 = df.dateFromString(dateStr2)
        let result = date1!.compare(date2!)
        if result == .OrderedAscending {
            return false
        }else {
            return true
        }
    }
    
    // MARK: - 常量
    static let m5LineColor = UIColor.colorWithHexString("#333333")
    static let m10LineColor = UIColor.colorWithHexString("#dcab01")
    static let m20LineColor = UIColor.colorWithHexString("#d6417d")
    static let m30LineColor = UIColor.colorWithHexString("#389a7c")
    static let downColor = UIColor.colorWithHexString("#306612")
    static let upColor = UIColor.colorWithHexString("#e93030")
    static let dotLineColor = UIColor.colorWithHexString("#E9E8E9")
    /// k线x轴的最小，最小间距，用于缩放
    let maxStepX: CGFloat = 50
    let minStepX: CGFloat = 4
    /// k线缩放增量
    let increment: CGFloat = 1
    /// step的默认值
    let defaultStepX: CGFloat = 8
    let spaceX: CGFloat = 5
    let spaceY: CGFloat = 15
}

extension KLineDetailView {
    /// 右移
    func KLineToolsView(DidClickRightButton btn:UIButton) {
        if start + 1 + displayKLineModelArr.count <= kLineModelArr.count{
            isMove = true
            end = end + 1
            resetData()
        }else {
            if !drawView.moveRight() {
                print("不能再右移动了")
            }
        }
    }
    /// 左移
    func KLineToolsView(DidClickLeftButton btn:UIButton) {
        if start - 1 >= 0 {
            isMove = true
            end = end - 1
            resetData()
        }else {
            if !drawView.moveLeft() {
                print("不能再向左移动了")
            }
        }
    }
    /// 缩小
    func KLineToolsView(DidClickShrinkButton btn:UIButton) {
        if stepX - increment >= minStepX {
            stepX = stepX - increment
        }else {
            print("不能再缩小了")
        }
    }
    /// 放大
    func KLineToolsView(DidClickExpandButton btn:UIButton) {
        if stepX + increment <= maxStepX {
            stepX = stepX + increment
        }else {
            print("不能再放大了")
        }
    }
    /// 全屏
    func KLineToolsView(DidClickFullScreenButton btn:UIButton) {
        print("full")
    }
}

// MARK: - DrawViewDelegate
extension KLineDetailView {
    func drawViewDidPinch(scale: CGFloat) {
        if(scale > 1) {
            scaleIncrement = scaleIncrement + scaleIncrement * scale
            if scaleIncrement > increment && stepX + increment <= maxStepX {
                stepX = stepX + increment
                scaleIncrement = 0.025
            }
        }else if scale < 1 && stepX - increment >= minStepX {
            scaleIncrement = scaleIncrement + scaleIncrement / scale
            if(scaleIncrement > increment) {
                stepX = stepX - increment
                scaleIncrement = 0.025
            }
        }
    }
    
    func drawViewDidSelectModel(model: KLineModel) {
        selectedKLineModel = model
    }
    
    func drawViewDeselectModel() {
        selectedKLineModel = nil
    }
}


