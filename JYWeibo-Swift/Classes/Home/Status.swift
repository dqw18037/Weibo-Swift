//
//  Status.swift
//  JYWeibo-Swift
//
//  Created by 张建宇 on 16/2/1.
//  Copyright © 2016年 张建宇. All rights reserved.
//

import UIKit
import Alamofire
import Kingfisher

class Status: NSObject {
    /// 微博创建时间
    var created_at: String?
        {
        didSet{
            let createdDate = NSDate.dateWithStr(created_at!)
            created_at = createdDate.descDate
        }
    }
    /// 微博ID
    var id: Int = 0
    /// 微博内容
    var text: String?
    /// 微博来源
    var source: String?
        {
        didSet{
            // 1.截取字符串
            if let str = source
            {
                if str == ""
                {
                    return
                }
                
                // 1.1获取开始截取的位置
                let startLocation = (str as NSString).rangeOfString(">").location + 1
                // 1.2获取截取的长度
                let length = (str as NSString).rangeOfString("<", options: NSStringCompareOptions.BackwardsSearch).location - startLocation
                // 1.3截取字符串
                source = "来自:" + (str as NSString).substringWithRange(NSMakeRange(startLocation, length))
            }
        }
    }
    /// 配图数组
    var pic_urls: [[String: AnyObject]]?
        {
        didSet{
            storedPicURLS = [NSURL]()
            for dict in pic_urls!
            {
                if let urlStr = dict["thumbnail_pic"]
                {
                    storedPicURLS?.append(NSURL(string: urlStr as! String)!)
                }
            }
        }
    }
    /// 保存当前微博所有配图的URL
    var storedPicURLS: [NSURL]?
    
    /// 用户信息
    var user: User?
    
    class func loadStatuses(finished: (models:[Status]?, error:NSError?)->()){
        let params = ["access_token": UserAccount.loadAccount()!.access_token!]
        
        
        Alamofire.request(.GET, "https://api.weibo.com/2/statuses/home_timeline.json", parameters:params, encoding: .URL, headers: nil).responseJSON { (
            Response
            ) -> Void in
            if (Response.result.value != nil){
                let resultDic = Response.result.value as! [String:AnyObject]
                
                let models = dictToModel(resultDic["statuses"] as! [[String: AnyObject]])
                cacheStatusImages(models, finished:finished )
            }
        }
        
    }
    /// 缓存配图
    class func cacheStatusImages(list: [Status], finished: (models:[Status]?, error:NSError?)->()) {
        
        let group = dispatch_group_create()
        
        for status in list
        {
            guard let _ = status.storedPicURLS else
            {
                continue
            }
            
            for url in status.storedPicURLS!
            {
                dispatch_group_enter(group)
                
                let downloader = KingfisherManager.sharedManager.downloader

                downloader.downloadImageWithURL(url, progressBlock: nil, completionHandler: { (image, error, imageURL, originalData) -> () in
                    if let image = image,imageURL = imageURL{
                        ImageCache.defaultCache.storeImage(image, forKey: imageURL.absoluteString)
                    }
                    
                    dispatch_group_leave(group)
                })
            }
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue()) { () -> Void in
            finished(models: list, error: nil)
        }
    }
    
    class func dictToModel(list: [[String: AnyObject]]) -> [Status] {
        var models = [Status]()
        for dict in list
        {
            models.append(Status(dict: dict))
        }
        return models
    }
    
    init(dict: [String: AnyObject])
    {
        super.init()
        setValuesForKeysWithDictionary(dict)
    }
    
    override func setValue(value: AnyObject?, forKey key: String) {
        
        if "user" == key
        {
            user = User(dict: value as! [String : AnyObject])
            return
        }
        
        super.setValue(value, forKey: key)
    }
    
    override func setValue(value: AnyObject?, forUndefinedKey key: String) {
        
    }
    
    var properties = ["created_at", "id", "text", "source", "pic_urls"]
    override var description: String {
        let dict = dictionaryWithValuesForKeys(properties)
        return "\(dict)"
    }
}
