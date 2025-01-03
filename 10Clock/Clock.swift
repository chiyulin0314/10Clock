//
//  Clock.swift
//  SwiftClock
//
//  Created by Joseph Daniels on 01/09/16.
//  Copyright © 2016 Joseph Daniels. All rights reserved.
//

import Foundation
import UIKit

@objc public  protocol TenClockDelegate {
    //Executed for every touch.
    @objc optional func timesUpdated(_ clock:TenClock, startDate:Date, endDate:Date) -> ()
    //Executed after the user lifts their finger from the control.
    @objc optional func timesChanged(_ clock:TenClock, startDate:Date, endDate:Date) -> ()
    
    @objc optional func isGradientPath(_ clock:TenClock) -> Bool
    @objc optional func colorForGradientPath(_ clock:TenClock) -> [UIColor]
    
    @objc optional func imageForHead(_ clock:TenClock) -> UIImage?
    @objc optional func imageSizeForHead(_ clock:TenClock) -> CGSize
    @objc optional func imageForTail(_ clock:TenClock) -> UIImage?
    @objc optional func imageSizeForTail(_ clock:TenClock) -> CGSize
    
    @objc optional func numberOfNumerals(_ clock:TenClock) -> Int
    @objc optional func tenClock(_ clock:TenClock, textForNumeralsAt index: Int) -> String
    @objc optional func numberOfIcons(_ clock:TenClock) -> Int
    @objc optional func tenClock(_ clock:TenClock, imageForIconsAt index: Int) -> UIImage?
}
func medStepFunction(_ val: CGFloat, stepSize:CGFloat) -> CGFloat{
    let dStepSize = Double(stepSize)
    let dval  = Double(val)
    let nsf = floor(dval/dStepSize)
    let rest = dval - dStepSize * nsf
    //print("[CY] medStepFunction => val: \(val), stepSize: \(stepSize), nsf: \(nsf), rest: \(rest)")
    return CGFloat(rest > dStepSize / 2 ? dStepSize * (nsf + 1) : dStepSize * nsf)

}

//XCPlaygroundPage.currentPage.needsIndefiniteExecution = true
//@IBDesignable
open class TenClock : UIControl{
    public enum ClockHourType: Int{
        case _12Hour = 12
        case _24Hour = 24
    }

    open weak var delegate:TenClockDelegate?
    //overall inset. Controls all sizes.
    @IBInspectable var insetAmount: CGFloat = 40
    open var clockHourType: ClockHourType = ._12Hour
    open var clockOffset: Double = Double.zero
    open var internalShift: CGFloat = 5
    open var pathWidth:CGFloat = 54

    var timeStepSize: CGFloat = 5
    let gradientLayer = CAGradientLayer()
    let trackLayer = CAShapeLayer()
    let pathLayer = CAShapeLayer()
    let headLayer = CAShapeLayer()
    let tailLayer = CAShapeLayer()
    let topHeadLayer = CAShapeLayer()
    let topTailLayer = CAShapeLayer()
    let numeralsLayer = CALayer()
    let iconsLayer = CALayer()
    let titleTextLayer = CATextLayer()
    let overallPathLayer = CALayer()
    
    /// 外圓的空白間隔
    open var trackSpace: CGFloat = 0
    /// 外圓的底色
    open var trackColor: UIColor = .black.withAlphaComponent(0.1)
    /// 路徑的顏色
    open var pathColor: UIColor = .white
    
    open var isShowDetailTicks = true
    let repLayer:CAReplicatorLayer = {
        var r = CAReplicatorLayer()
        r.instanceCount = 48
        r.instanceTransform =
            CATransform3DMakeRotation(
                CGFloat(2*Double.pi) / CGFloat(r.instanceCount),
                0,0,1)

        return r
    }()

    open var isShowHourTicks = true
    let repLayer2:CAReplicatorLayer = {
        var r = CAReplicatorLayer()
        r.instanceCount = 24 //12
        r.instanceTransform =
            CATransform3DMakeRotation(
                CGFloat(2*Double.pi) / CGFloat(r.instanceCount),
                0,0,1)

        return r
    }()
    let twoPi =  CGFloat(2 * Double.pi)
    let fourPi =  CGFloat(4 * Double.pi)
    var headAngle: CGFloat = 0{
        didSet{
            if (headAngle > fourPi  +  CGFloat(Double.pi / 2)){
                headAngle -= fourPi
            }
            if (headAngle <  CGFloat(Double.pi / 2) ){
                headAngle += fourPi
            }
        }
    }

    var tailAngle: CGFloat = 0.7 * CGFloat(Double.pi) {
        didSet{
            if (tailAngle  > headAngle + fourPi){
                tailAngle -= fourPi
            } else if (tailAngle  < headAngle ){
                tailAngle += fourPi
            }

        }
    }

    open var shouldMoveHead = true
    open var shouldMoveTail = true
    
    /// 數字字型
    open var numeralsFont: UIFont? = nil
    open var numeralsColor:UIColor? = UIColor.darkGray
    open var minorTicksColor:UIColor? = UIColor.lightGray
    open var majorTicksColor:UIColor? = UIColor.blue
    open var centerTextFont: UIFont? = nil
    open var centerTextColor:UIColor? = UIColor.darkGray

    open var titleColor = UIColor.lightGray
    open var titleGradientMask = false

    //disable scrol on closest superview for duration of a valid touch.
    var disableSuperviewScroll = false

    open var headBackgroundColor = UIColor.white.withAlphaComponent(0.8)
    open var tailBackgroundColor = UIColor.white.withAlphaComponent(0.8)

    open var headBgColor = UIColor.white //MARK: 目前無效
    open var tailBgColor = UIColor.white //MARK: 目前無效
    open var headText: String = "Start"
    open var tailText: String = "End"
    open var headTextColor = UIColor.black
    open var tailTextColor = UIColor.black
    /// 是否反向繪製路徑
    open var isReversePathDraw: Bool = false
    /// 時刻文字內距Padding值
    open var numeralInsetPadding: CGFloat = 10
    /// 時刻圖示內距Padding值
    open var iconInsetPadding: CGFloat = 25
    /// 自定時刻圖示大小
    open var customIconSize: CGSize? = nil
    /// 是否顯示正中間文字(預設為時間差)
    open var isShowCenterTitle: Bool = true
    /// 是否讓使用者可以旋轉路徑
    open var isUserRotatePathEnabled: Bool = true
    
    var touchHead: Bool = true
    /// 是否觸碰到Head
    open var isTouchHead: Bool{
        return touchHead
    }
    
    var touchTail: Bool = true
    /// 是否觸碰到Tail
    open var isTouchTail: Bool{
        return touchTail
    }
    
    var touchPath: Bool = true
    /// 是否觸碰到Path
    open var isTouchPath: Bool{
        return touchPath
    }
    
    open var minorTicksEnabled:Bool = true
    open var majorTicksEnabled:Bool = true
    @objc open var disabled:Bool = false {
        didSet{
            update()
        }
    }
    
    open var buttonInset:CGFloat = 2
    func disabledFormattedColor(_ color:UIColor) -> UIColor{
        return disabled ? color.greyscale : color
    }




    var trackWidth: CGFloat { return pathWidth + trackSpace }
    func proj(_ theta:Angle) -> CGPoint{
        let center = self.layer.center
        return CGPoint(x: center.x + trackRadius * cos(theta) ,
                           y: center.y - trackRadius * sin(theta) )
    }

    var headPoint: CGPoint{
        return proj(headAngle)
    }
    var tailPoint: CGPoint{
        return proj(tailAngle)
    }

    lazy internal var calendar = Calendar(identifier:Calendar.Identifier.gregorian)
    func toDate(_ val:CGFloat)-> Date {
//        var comps = DateComponents()
//        comps.minute = Int(val)
        return calendar.date(byAdding: Calendar.Component.minute , value: Int(val), to: Date().startOfDay as Date)!
//        return calendar.dateByAddingComponents(comps, toDate: Date().startOfDay as Date, options: .init(rawValue:0))!
    }
    open var startDate: Date{
        get{return angleToTime(tailAngle) }
        set{ tailAngle = timeToAngle(newValue) }
    }
    open var endDate: Date{
        get{return angleToTime(headAngle) }
        set{ headAngle = timeToAngle(newValue) }
    }

    var internalRadius:CGFloat {
        return internalInset.height
    }
    var inset:CGRect{
        return self.layer.bounds.insetBy(dx: insetAmount, dy: insetAmount)
    }
    var internalInset:CGRect{
        let reInsetAmount = trackWidth / 2 + internalShift
        return self.inset.insetBy(dx: reInsetAmount, dy: reInsetAmount)
    }
    var numeralInset:CGRect{
        let reInsetAmount = trackWidth / 2 + numeralInsetPadding
        return self.inset.insetBy(dx: reInsetAmount, dy: reInsetAmount)
    }
    var iconInset:CGRect{
        let reInsetAmount = trackWidth / 2 + iconInsetPadding
        return self.inset.insetBy(dx: reInsetAmount, dy: reInsetAmount)
    }
    var titleTextInset:CGRect{
        let reInsetAmount = trackWidth.checked / 2 + 4 * internalShift
        return (self.inset).insetBy(dx: reInsetAmount, dy: reInsetAmount)
    }
    var trackRadius:CGFloat { return inset.height / 2}
    var buttonRadius:CGFloat { return /*44*/ pathWidth / 2 }
    var iButtonRadius:CGFloat { return /*44*/ buttonRadius - buttonInset }
    /*
    var strokeColor: UIColor {
        get {
            return UIColor(cgColor: trackLayer.strokeColor!)
        }
        set(strokeColor) {
            trackLayer.strokeColor = strokeColor.withAlphaComponent(0.1).cgColor
            pathLayer.strokeColor = strokeColor.cgColor
        }
    }*/


    // input a date, output: 0 to 4pi
    func timeToAngle(_ date: Date) -> Angle{
        let units : Set<Calendar.Component> = [.hour, .minute]
        let components = self.calendar.dateComponents(units, from: date)
        let min = Double(  60 * components.hour! + components.minute! )

        //print("[CY] timeToAngle => min: \(min), hour: \(components.hour!), minute: \(components.minute!)")
        if clockHourType == ._24Hour{
            //return medStepFunction(CGFloat(Double.pi / 2 - ( min / (24 * 60)) * 2 * Double.pi), stepSize: CGFloat( 2 * Double.pi / (24 * 60 / 5)))
            return medStepFunction(CGFloat(Double.pi / 2 + clockOffset - ( min / (24 * 60)) * 2 * Double.pi), stepSize: CGFloat( 2 * Double.pi / (24 * 60 / 5)))
        }else{
            return medStepFunction(CGFloat(Double.pi / 2 + clockOffset - ( min / (12 * 60)) * 2 * Double.pi), stepSize: CGFloat( 2 * Double.pi / (12 * 60 / 5)))
        }
    }

    // input an angle, output: 0 to 4pi
    func angleToTime(_ angle: Angle) -> Date{
        let dAngle = Double(angle)
        var minutes: CGFloat = 12 * 60
        if clockHourType == ._24Hour{
            minutes = 24 * 60
        }
        let min = CGFloat(((Double.pi / 2 - clockOffset - dAngle) / (2 * Double.pi)) * (minutes))
        let startOfToday = Calendar.current.startOfDay(for: Date())
        
        //print("[CY] angleToTime => angle: \(angle), min: \(min), startOfToday: \(startOfToday)")
        return self.calendar.date(byAdding: .minute, value: Int(medStepFunction(min, stepSize: 5/* minute steps*/)), to: startOfToday)!
    }
    override open func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        update()
    }
    open func update() {
        let mm = min(self.layer.bounds.size.height, self.layer.bounds.size.width)
        CATransaction.begin()
        self.layer.size = CGSize(width: mm, height: mm)

        //strokeColor = disabledFormattedColor(tintColor)
        trackLayer.strokeColor = trackColor.resolvedColor(with: self.traitCollection).cgColor
        pathLayer.strokeColor = pathColor.resolvedColor(with: self.traitCollection).cgColor
        overallPathLayer.occupation = layer.occupation
        gradientLayer.occupation = layer.occupation

        trackLayer.occupation = (inset.size, layer.center)

        pathLayer.occupation = (inset.size, overallPathLayer.center)
        repLayer.occupation = (internalInset.size, overallPathLayer.center)
        repLayer2.occupation  =  (internalInset.size, overallPathLayer.center)
        numeralsLayer.occupation = (numeralInset.size, layer.center)
        iconsLayer.occupation = (iconInset.size, layer.center)

        trackLayer.fillColor = UIColor.clear.cgColor
        pathLayer.fillColor = UIColor.clear.cgColor


        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        updateGradientLayer()   //兩端內漸層
        updateTrackLayerPath()  //外圓底
        updatePathLayerPath()   //兩端之間的路徑繪製
        updateHeadTailLayers()  //兩端的圓型(文字、圖片)
        updateWatchFaceTicks()  //內圈的時刻線
        updateWatchFaceNumerals()   //內圈的時刻文字
        updateWatchFaceIcons()  //內圈的時刻圖示
        updateWatchFaceTitle()  //正中間的時間差
        CATransaction.commit()
    }
    func updateGradientLayer() {
        let isGradientPath = delegate?.isGradientPath?(self) ?? true
        if isGradientPath{
            let colors = delegate?.colorForGradientPath?(self) ?? [tintColor, tintColor.modified(withAdditionalHue: -0.08, additionalSaturation: 0.15, additionalBrightness: 0.2)].map(disabledFormattedColor)
            gradientLayer.colors = colors.map({ $0.resolvedColor(with: self.traitCollection).cgColor })
            /*
            gradientLayer.colors =
            [tintColor,
             tintColor.modified(withAdditionalHue: -0.08, additionalSaturation: 0.15, additionalBrightness: 0.2)]
                .map(disabledFormattedColor)
                .map{$0.cgColor}
            */
            gradientLayer.mask = overallPathLayer
            gradientLayer.startPoint = CGPoint(x:0,y:0)
        }else{
            //FIXME: 看情況修正isGradientPath=false時的寫法，取消CAGradientLayer被修改的內容
            gradientLayer.colors = [pathColor.resolvedColor(with: self.traitCollection).cgColor, pathColor.resolvedColor(with: self.traitCollection).cgColor]
            gradientLayer.mask = overallPathLayer
            gradientLayer.startPoint = CGPoint(x:0,y:0)
        }
    }

    func updateTrackLayerPath() {
        let circle = UIBezierPath(
            ovalIn: CGRect(
                origin:CGPoint(x: 0, y: 00),
                size: CGSize(width:trackLayer.size.width,
                    height: trackLayer.size.width)))
        trackLayer.lineWidth = trackWidth
        trackLayer.path = circle.cgPath

    }
    override open func layoutSubviews() {
        update()
    }

    func updatePathLayerPath() {
        let arcCenter = pathLayer.center
        pathLayer.fillColor = UIColor.clear.cgColor
        pathLayer.lineWidth = pathWidth
        //print("[CY] headAngle: \(headAngle), tailAngle: \(tailAngle), start = \(headAngle / CGFloat(Double.pi)), end = \(tailAngle / CGFloat(Double.pi))")
        if isReversePathDraw{
            pathLayer.path = UIBezierPath(
                arcCenter: arcCenter,
                radius: trackRadius,
                startAngle: (twoPi) - headAngle,
                endAngle: (twoPi) - ((tailAngle - headAngle) >= twoPi ? tailAngle - twoPi : tailAngle),
                clockwise: true).cgPath
        }else{
            pathLayer.path = UIBezierPath(
                arcCenter: arcCenter,
                radius: trackRadius,
                startAngle: (twoPi) - ((tailAngle - headAngle) >= twoPi ? tailAngle - twoPi : tailAngle),
                endAngle: (twoPi) - headAngle,
                clockwise: true).cgPath
        }
    }

    func tlabel(_ str:String, color:UIColor? = nil) -> CATextLayer{
        let f = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.caption2)
        let cgFont = CTFontCreateWithName(f.fontName as CFString, f.pointSize/2,nil)
        let l = CATextLayer()
        l.bounds.size = CGSize(width: 30, height: 15)
        l.fontSize = f.pointSize
        l.foregroundColor =  disabledFormattedColor(color ?? tintColor).resolvedColor(with: self.traitCollection).cgColor
        l.alignmentMode = CATextLayerAlignmentMode.center
        l.contentsScale = UIScreen.main.scale
        l.font = cgFont
        l.string = str

        return l
    }
    func updateHeadTailLayers() {
        let size = CGSize(width: 2 * buttonRadius, height: 2 * buttonRadius)
        let iSize = CGSize(width: 2 * iButtonRadius, height: 2 * iButtonRadius)
        let circle = UIBezierPath(ovalIn: CGRect(origin: CGPoint(x: 0, y:0), size: size)).cgPath
        let iCircle = UIBezierPath(ovalIn: CGRect(origin: CGPoint(x: 0, y:0), size: iSize)).cgPath
        tailLayer.path = circle
        headLayer.path = circle
        tailLayer.size = size
        headLayer.size = size
        tailLayer.position = tailPoint
        headLayer.position = headPoint
        topTailLayer.position = tailPoint
        topHeadLayer.position = headPoint
        headLayer.fillColor = tailBgColor.resolvedColor(with: self.traitCollection).cgColor
        tailLayer.fillColor = headBgColor.resolvedColor(with: self.traitCollection).cgColor
        topTailLayer.path = iCircle
        topHeadLayer.path = iCircle
        topTailLayer.size = iSize
        topHeadLayer.size = iSize
        topHeadLayer.fillColor = disabledFormattedColor(headBackgroundColor).resolvedColor(with: self.traitCollection).cgColor
        topTailLayer.fillColor = disabledFormattedColor(tailBackgroundColor).resolvedColor(with: self.traitCollection).cgColor
        topHeadLayer.sublayers?.forEach({$0.removeFromSuperlayer()})
        topTailLayer.sublayers?.forEach({$0.removeFromSuperlayer()})
        
        //use head image or text
        if let headImage = delegate?.imageForHead?(self){
            let autoSize: CGSize = CGSize(width: min(headImage.size.width, iSize.width), height: min(headImage.size.height, iSize.height))
            let imgSize = delegate?.imageSizeForHead?(self) ?? autoSize
            let startImg = CALayer()
            startImg.backgroundColor = UIColor.clear.cgColor
            startImg.bounds = CGRect(x: 0, y: 0 , width: imgSize.width, height: imgSize.height)
            startImg.position = topTailLayer.center
            startImg.contents = headImage.imageAsset?.image(with: self.traitCollection).cgImage ?? headImage.cgImage
            topTailLayer.addSublayer(startImg)
        }else{
            let stText = tlabel(headText, color: disabledFormattedColor(headTextColor))
            stText.position = topTailLayer.center
            topTailLayer.addSublayer(stText)
        }
        
        //use tail image or text
        if let tailImage = delegate?.imageForTail?(self){
            let autoSize: CGSize = CGSize(width: min(tailImage.size.width, iSize.width), height: min(tailImage.size.height, iSize.height))
            let imgSize = delegate?.imageSizeForTail?(self) ?? autoSize
            let endImg = CALayer()
            endImg.backgroundColor = UIColor.clear.cgColor
            endImg.bounds = CGRect(x: 0, y: 0 , width: imgSize.width, height: imgSize.height)
            endImg.position = topHeadLayer.center
            endImg.contents = tailImage.imageAsset?.image(with: self.traitCollection).cgImage ?? tailImage.cgImage
            topHeadLayer.addSublayer(endImg)
        }else{
            let endText = tlabel(tailText, color: disabledFormattedColor(tailTextColor))
            endText.position = topHeadLayer.center
            topHeadLayer.addSublayer(endText)
        }
    }


    func updateWatchFaceNumerals() {
        numeralsLayer.sublayers?.forEach({$0.removeFromSuperlayer()})
        let f = numeralsFont ?? UIFont.preferredFont(forTextStyle: UIFont.TextStyle.caption2)
        let cgFont = CTFontCreateWithName(f.fontName as CFString, f.pointSize/2,nil)
        let startPos = CGPoint(x: numeralsLayer.bounds.midX, y: 15)
        let origin = numeralsLayer.center
        
        let count: Int = delegate?.numberOfNumerals?(self) ?? clockHourType.rawValue
        guard count > 0 else { return }
        
        let step = (2 * Double.pi) / Double(count)
        for i in (1 ... count){
            let l = CATextLayer()
            l.fontSize = f.pointSize
            l.alignmentMode = CATextLayerAlignmentMode.center
            l.contentsScale = UIScreen.main.scale
            //            l.foregroundColor
            l.font = cgFont
            l.string = delegate?.tenClock?(self, textForNumeralsAt: i-1) ?? "\(i)"
            l.foregroundColor = disabledFormattedColor(numeralsColor ?? tintColor).resolvedColor(with: self.traitCollection).cgColor
            l.bounds.size = l.preferredFrameSize()
            l.position = CGVector(from:origin, to:startPos).rotate( CGFloat(Double(i) * step)).add(origin.vector).point.checked
            numeralsLayer.addSublayer(l)
        }
    }
    
    func updateWatchFaceIcons(){
        iconsLayer.sublayers?.forEach({$0.removeFromSuperlayer()})
        let startPos = CGPoint(x: iconsLayer.bounds.midX, y: 15)
        let origin = iconsLayer.center
        
        let count: Int = delegate?.numberOfIcons?(self) ?? 0
        guard count > 0 else { return }
        
        let step = (2 * Double.pi) / Double(count)
        for i in (1 ... count){
            if let icon = delegate?.tenClock?(self, imageForIconsAt: i-1){
                let iconLayer = CALayer()
                iconLayer.backgroundColor = UIColor.clear.cgColor
                iconLayer.bounds = CGRect(x: 0, y: 0 , width: customIconSize?.width ?? icon.size.width, height: customIconSize?.height ?? icon.size.height)
                iconLayer.contents = icon.imageAsset?.image(with: self.traitCollection).cgImage ?? icon.cgImage
                iconLayer.position = CGVector(from:origin, to:startPos).rotate( CGFloat(Double(i) * step)).add(origin.vector).point.checked
                iconsLayer.addSublayer(iconLayer)
            }
        }
    }
    
    func updateWatchFaceTitle(){
        if isShowCenterTitle{
            titleTextLayer.isHidden = false
            let f = centerTextFont ?? UIFont.preferredFont(forTextStyle: UIFont.TextStyle.title1)
            let cgFont = CTFontCreateWithName(f.fontName as CFString, f.pointSize/2,nil)
            //        let titleTextLayer = CATextLayer()
            titleTextLayer.bounds.size = CGSize( width: titleTextInset.size.width, height: 50)
            titleTextLayer.fontSize = f.pointSize
            titleTextLayer.alignmentMode = CATextLayerAlignmentMode.center
            titleTextLayer.foregroundColor = disabledFormattedColor(centerTextColor ?? tintColor).resolvedColor(with: self.traitCollection).cgColor
            titleTextLayer.contentsScale = UIScreen.main.scale
            titleTextLayer.font = cgFont
            //var computedTailAngle = tailAngle //+ (headAngle > tailAngle ? twoPi : 0)
            //computedTailAngle +=  (headAngle > computedTailAngle ? twoPi : 0)
            var fiveMinIncrements = Int( ((tailAngle - headAngle) / twoPi) * 12 /*hrs*/ * 12 /*5min increments*/)
            if fiveMinIncrements < 0 {
                print("tenClock:Err: is negative")
                fiveMinIncrements += (24 * (60/5))
            }
            
            titleTextLayer.string = "\(fiveMinIncrements / 12)hr \((fiveMinIncrements % 12) * 5)min"
            titleTextLayer.position = gradientLayer.center
        }else{
            titleTextLayer.isHidden = true
        }
    }
    func tick() -> CAShapeLayer{
        let tick = CAShapeLayer()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0,y: -3))
        path.addLine(to: CGPoint(x: 0,y: 3))
        tick.path  = path.cgPath
        tick.bounds.size = CGSize(width: 6, height: 6)
        return tick
    }

    func updateWatchFaceTicks() {
        repLayer.sublayers?.forEach({$0.removeFromSuperlayer()})
        if isShowDetailTicks{
            let t = tick()
            t.strokeColor = disabledFormattedColor(minorTicksColor ?? tintColor).resolvedColor(with: self.traitCollection).cgColor
            t.position = CGPoint(x: repLayer.bounds.midX, y: 10)
            repLayer.addSublayer(t)
            repLayer.position = self.bounds.center
            repLayer.bounds.size = self.internalInset.size
        }
        
        repLayer2.sublayers?.forEach({$0.removeFromSuperlayer()})
        if isShowHourTicks{
            let t2 = tick()
            t2.strokeColor = disabledFormattedColor(majorTicksColor ?? tintColor).resolvedColor(with: self.traitCollection).cgColor
            t2.lineWidth = 0.5
            t2.position = CGPoint(x: repLayer2.bounds.midX, y: 10)
            repLayer2.addSublayer(t2)
            repLayer2.position = self.bounds.center
            repLayer2.bounds.size = self.internalInset.size
        }
    }
    var pointerLength:CGFloat = 0.0

    func createSublayers() {
        layer.addSublayer(repLayer2)
        layer.addSublayer(repLayer)
        layer.addSublayer(numeralsLayer)
        layer.addSublayer(iconsLayer)
        layer.addSublayer(trackLayer)

        overallPathLayer.addSublayer(pathLayer)
        overallPathLayer.addSublayer(headLayer)
        overallPathLayer.addSublayer(tailLayer)
        overallPathLayer.addSublayer(titleTextLayer)
        layer.addSublayer(overallPathLayer)
        layer.addSublayer(gradientLayer)
        gradientLayer.addSublayer(topHeadLayer)
        gradientLayer.addSublayer(topTailLayer)
        update()
        //strokeColor = disabledFormattedColor(tintColor)
        trackLayer.strokeColor = trackColor.resolvedColor(with: self.traitCollection).cgColor
        pathLayer.strokeColor = pathColor.resolvedColor(with: self.traitCollection).cgColor
    }
    override public init(frame: CGRect) {
        super.init(frame:frame)
//        self.addConstraint(NSLayoutConstraint(item: self, attribute: .Width, relatedBy: .Equal, toItem: self    , attribute: .Height, multiplier: 1, constant: 0))
       // tintColor = UIColor ( red: 0.755, green: 0.0, blue: 1.0, alpha: 1.0 )
        backgroundColor = UIColor ( red: 0.1149, green: 0.115, blue: 0.1149, alpha: 0.0 )
        createSublayers()
    }


    required public init?(coder: NSCoder) {
        super.init(coder: coder)

        //tintColor = UIColor ( red: 0.755, green: 0.0, blue: 1.0, alpha: 1.0 )
        backgroundColor = UIColor ( red: 0.1149, green: 0.115, blue: 0.1149, alpha: 0.0 )
        createSublayers()
    }


    fileprivate var backingValue: Float = 0.0

    /** Contains the receiver’s current value. */
    var value: Float {
        get { return backingValue }
        set { setValue(newValue, animated: false) }
    }

    /** Sets the receiver’s current value, allowing you to animate the change visually. */
    func setValue(_ value: Float, animated: Bool) {
        if value != backingValue {
            backingValue = min(maximumValue, max(minimumValue, value))
        }
    }

    /** Contains the minimum value of the receiver. */
    var minimumValue: Float = 0.0

    /** Contains the maximum value of the receiver. */
    var maximumValue: Float = 1.0

    /** Contains a Boolean value indicating whether changes
     in the sliders value generate continuous update events. */
    var continuous = true
    var valueChanged = false


    var pointMover:((CGPoint) ->())?
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !disabled  else {
            pointMover = nil
            return
        }
        
        //        touches.forEach { (touch) in
        let touch = touches.first!
        let pointOfTouch = touch.location(in: self)
        guard let layer = self.overallPathLayer.hitTest( pointOfTouch ) else { return }
//         superview:UIView
//        for superview in touch.gestureRecognizers!{
//            guard let superview = superview as? UIPanGestureRecognizer else {  continue }
//            superview.isEnabled = false
//            superview.isEnabled = true
//            break
//        }

        var prev = pointOfTouch
        let pointerMoverProducer: (@escaping (CGPoint) -> Angle, @escaping (Angle)->()) -> (CGPoint) -> () = { g, s in
            return { p in
                let c = self.layer.center
                let computedP = CGPoint(x: p.x, y: self.layer.bounds.height - p.y)
                let v1 = CGVector(from: c, to: computedP)
                let v2 = CGVector(angle:g( p ))

                var steps = 12 * 60 / 5
                if self.clockHourType == ._24Hour{
                    steps = 24 * 60 / 5
                }
                s(clockDescretization(CGVector.signedTheta(v1, vec2: v2), steps: steps))
                self.update()
            }

        }

        //注意: head、tail是相反
        //reset to false
        touchTail = false
        touchHead = false
        touchPath = false
        
        switch(layer){
        case headLayer:
            touchTail = true
            if (shouldMoveHead) {
            pointMover = pointerMoverProducer({ _ in self.headAngle}, {self.headAngle += $0; self.tailAngle += 0})
            } else {
                pointMover = nil
            }
        case tailLayer:
            touchHead = true
            if (shouldMoveHead) {
            pointMover = pointerMoverProducer({_ in self.tailAngle}, {self.headAngle += 0;self.tailAngle += $0})
                } else {
                    pointMover = nil
            }
        case pathLayer:
            touchPath = true
            if (shouldMoveHead && isUserRotatePathEnabled) {
                    pointMover = pointerMoverProducer({ pt in
                        let x = CGVector(from: self.bounds.center,
                                         to:CGPoint(x: prev.x, y: self.layer.bounds.height - prev.y)).theta;
                    prev = pt;
                    return x
                    }, {self.headAngle += $0; self.tailAngle += $0 })
            } else {
                    pointMover = nil
            }
        default: break
        }



    }
    override open  func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
//        while var superview = self.superview{
//            guard let superview = superview as? UIScrollView else {  continue }
//            superview.scrollEnabled = true
//            break
//        }
    }
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        pointMover = nil
//        while var superview = self.superview{
//            guard let superview = superview as? UIScrollView else {  continue }
//            superview.scrollEnabled = true
//            break
//        }
//        do something
//        valueChanged = false
        delegate?.timesChanged?(self, startDate: self.startDate, endDate: endDate)
    }
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let pointMover = pointMover else { return }
//        print(touch.locationInView(self))
        pointMover(touch.location(in: self))
        
        delegate?.timesUpdated?(self, startDate: self.startDate, endDate: endDate)
        

    }

}
