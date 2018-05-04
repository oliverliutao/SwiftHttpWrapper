
//
//  HTTPClient.swift
//  SavingsX
//
//  Created by Liu Tao on 27/9/17.
//  Copyright © 2017 TAO. All rights reserved.
//

import Foundation

class HTTPClient {
    
    private static var sharedHttpClient: HTTPClient = {
        
        let httpClientManager = HTTPClient()
        
        return httpClientManager
    }()
    
    private static var shareSessionManager : SessionManager = {
        
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = ASConstants.HTTPRequestTimeOut
            configuration.timeoutIntervalForResource = ASConstants.HTTPRequestTimeOut
    
            return SessionManager(configuration: configuration)
        
    }()
    
    let baseURL: String
    
    private init() {
        
        self.baseURL = ASConfig.getRTUL()
        
    }
    
    class func shared() -> HTTPClient {
        
        return sharedHttpClient
    }
    
    
    
//    func GetRequest(urlstr: String) -> URLRequest? {
//
//        let url : URL = URL.init(string: urlstr)!
//        var urlRequest = URLRequest.init(url: url)
//        urlRequest.timeoutInterval = ASConstants.HTTPRequestTimeOut
//        urlRequest.httpMethod = HTTPMethod.get.rawValue
//
//        return urlRequest
//    }
    
    
    
}

//MARK: Register page
protocol RegisterHttpAPI {
    
    func requestRegister(para: [String : Any], completionHandler: @escaping (_ statusCode: Int, _ json: JSON) -> Void)
    
    func requestCheckEmail(email: String, completionHandler: @escaping (_ statusCode: Int, _ json: JSON) -> Void)
    
    
}

extension HTTPClient : RegisterHttpAPI {
    
    func requestCheckEmail(email: String, completionHandler: @escaping (Int, JSON) -> Void) {
        
        let urlstr = "\(self.baseURL)api/customers?email=\(email)"
        
        HTTPClient.shareSessionManager.request(urlstr, method: .get, parameters: nil, encoding: JSONEncoding.default).responseString { (response) in
            
            //            debugPrint(response)
            
            switch response.result
            {
            case .failure:
                
                completionHandler(-1,JSON.null)
                
            case .success(let value):
                
                let statusCode = (response.response?.statusCode)! as Int
                let json = JSON.init(parseJSON: value)
                
                completionHandler(statusCode,json)
            }
        }
        
    }
    
    func requestRegister(para: [String : Any], completionHandler: @escaping (Int, JSON) -> Void) {
        
        let urlstr = "\(self.baseURL)api/customers"
        
        HTTPClient.shareSessionManager.request(urlstr, method: .post, parameters: para, encoding: JSONEncoding.default)/*.validate(statusCode: 200..<300)*/.responseString { (response) in

//            debugPrint(response)

//            "{\"user_id\":\"18f74cf0-f6a0-11e7-83a4-772ec3a1504d\",\"user_profile\":{\"id\":\"18f9e500-f6a0-11e7-83a4-772ec3a1504d\",\"personalInfo\":false,\"personalData\":{},\"profileImageInfo\":false,\"profileImageData\":{\"type\":\"Buffer\",\"data\":[]},\"kycInfo\":false,\"kycData\":{},\"cardImageInfo\":false,\"cardBackImageData\":{\"type\":\"Buffer\",\"data\":[]},\"cardFrontImageData\":{\"type\":\"Buffer\",\"data\":[]},\"user_id\":\"18f74cf0-f6a0-11e7-83a4-772ec3a1504d\",\"pocket_id\":\"PX384937\",\"email\":\"yl1@test.com\",\"mobilenum\":\"+6598686753\",\"updatedAt\":\"2018-01-11T07:21:53.232Z\",\"createdAt\":\"2018-01-11T07:21:53.232Z\"}}"

            switch response.result
            {
            case .failure:

                completionHandler(-1,JSON.null)

            case .success(let value):

                let statusCode = (response.response?.statusCode)! as Int
                let json = JSON.init(parseJSON: value)

                //cache profileID for OCR
                let profileId : String = json["user_profile"]["id"].stringValue
                UserDefaultToolWrapper.saveProfileId(profileId: profileId)

                completionHandler(statusCode,json)

            }
        }
    }
}


//MARK: Login page
protocol LgoinHttpAPI {
    
    func requestPreLogin(para: [String : Any], completionHandler: @escaping (_ statusCode: Int, _ response: JSON) -> Void)
    
    func requestLogin(para: [String : Any], completionHandler: @escaping (_ statusCode: Int, _ json: ProfileEntity?) -> Void)
    
    func requestLogout(para : [String : Any], completionHandler: @escaping (_ statusCode: Int, _ response: JSON) -> Void)
    
}


extension HTTPClient : LgoinHttpAPI {
    
    
    func requestPreLogin(para: [String : Any], completionHandler: @escaping (Int, JSON) -> Void) {
        
        let urlstr = "\(self.baseURL)api/auth/requests"
        
        
        HTTPClient.shareSessionManager.request(urlstr, method: .post, parameters: para, encoding: JSONEncoding.default).responseString { (response) in
            
            //            debugPrint(response)
            
            switch response.result
            {
            case .failure:
                
                completionHandler(-1,JSON.null)
                
            case .success(let value):
                
                let statusCode = (response.response?.statusCode)! as Int
                let json = JSON.init(parseJSON: value)
                
                completionHandler(statusCode,json)
            }
        }
        
        
    }
    
    
    func requestLogin(para: [String : Any], completionHandler: @escaping (Int, ProfileEntity?) -> Void) {
        
        let urlstr = "\(self.baseURL)api/customers/login"
        
        HTTPClient.shareSessionManager.request(urlstr, method: .post, parameters: para, encoding: JSONEncoding.default).responseString { (response) in

//            debugPrint(response)

            switch response.result
            {
            case .failure:

                completionHandler(-1,nil)

            case .success(let value):

                let statusCode = (response.response?.statusCode)! as Int
            
                let json = ProfileEntity.init(json: JSON.init(parseJSON: value))
                
                if statusCode >= 200, statusCode<300, json.user_id != nil {
                    
                    UserDefaultTool.saveString(value: json.user_id!, key: ASConstants.PocketStoreUserId)
                    
                }
                
                completionHandler(statusCode,json)
            }
        }
    }
    
    //    API for log out: POST /oauth/revoke_token
    //    body: {client_id:"" , token: "" }
    func requestLogout(para : [String : Any], completionHandler: @escaping (_ statusCode: Int, _ response: JSON) -> Void) {
        
        let urlstr = "\(self.baseURL)api/oauth/revoke_token"
        
        HTTPClient.shareSessionManager.request(urlstr, method: .post, parameters: para, encoding: JSONEncoding.default).responseString { (response) in
            
//            debugPrint(response)
            
            switch response.result
            {
            case .failure:
                
                completionHandler(-1,JSON.null)
                
            case .success(let value):
                
                let statusCode = (response.response?.statusCode)! as Int
                let json = JSON.init(parseJSON: value)
                
                completionHandler(statusCode,json)
            }
        }

    }
}

//MARK: personal information page
protocol PersonalInfoHttpAPI {
    
    func updatePersonalDetail(para: [String : Any], completionHandler: @escaping (_ statusCode: Int, _ json: JSON) -> Void)
    
//    func uploadIDCardsImagesForOCR(para: [String : Any], completionHandler: @escaping (_ statusCode: Int, _ json: JSON) -> Void)
    
    func fetchOCRResultForOCR(completionHandler: @escaping (_ statusCode: Int, _ json: JSON?) -> Void)
    
}

extension HTTPClient : PersonalInfoHttpAPI {
    
    
////    {
////    "user_id": "0e3eb770-eba2-11e7-9ada-cf1e2d32ec7c",
////    "personalInfo": 0,
////    "knowYourCustomerInfo" : 0,
////    "profileImageInfo": 0,
////    "cardImageInfo": 1,
////    "cardImageData" :  {"front": "",      "back": ""}
////    }
//    func uploadIDCardsImagesForOCR(para: [String : Any], completionHandler: @escaping (Int, JSON) -> Void) {
//
//        let urlstr = "\(self.baseURL)api/pocketprofile"
//
//        Alamofire.request(urlstr, method: .put, parameters: para, encoding: JSONEncoding.default).responseString { (response) in
//
//            switch response.result
//            {
//            case .failure:
//
//                completionHandler(-1,JSON.null)
//
//            case .success(let value):
//
//                let statusCode = (response.response?.statusCode)! as Int
//                let json = JSON.init(parseJSON: value)
//
//                completionHandler(statusCode,json)
//            }
//
//        }
//
//    }
    
    
    
//    Get http://10.138.184.225:8000/api/pocketprofile/f5743fe0-f681-11e7-ab23-c7403ec80391/ocrrequests
    
    func fetchOCRResultForOCR(completionHandler: @escaping (_ statusCode: Int, _ json: JSON?) -> Void)  {
        
        if let profileId : String = UserDefaultToolWrapper.getProfileId() {
            
            let urlstr = "\(self.baseURL)api/pocketprofile/\(profileId)/ocrrequests"
            
//            debugPrint("ocrtest urlstr= \(urlstr)")
            
            HTTPClient.shareSessionManager.request(urlstr, method: .get, parameters: nil, encoding: JSONEncoding.default).responseString { (response) in
                
                switch response.result
                {
                case .failure:
                    
                    completionHandler(-1,nil)
                    
                case .success(let value):
                    
                    let statusCode = (response.response?.statusCode)! as Int

//                    debugPrint("ocrtest statusCode = \(statusCode) ,   value = \(value)")
                    
                    let ocrJSON : JSON = JSON.init(parseJSON: value)
                    
                    completionHandler(statusCode,ocrJSON)
                }
            }
        }
    }
    

    
    func updatePersonalDetail(para: [String : Any], completionHandler: @escaping (Int, JSON) -> Void) {
        
        let urlstr = "\(self.baseURL)api/pocketprofile"
        
        HTTPClient.shareSessionManager.request(urlstr, method: .put, parameters: para, encoding: JSONEncoding.default).responseString { (response) in
            
            switch response.result
            {
            case .failure:
                
                completionHandler(-1,JSON.null)
                
            case .success(let value):
                
                let statusCode = (response.response?.statusCode)! as Int
                let json = JSON.init(parseJSON: value)
                
                completionHandler(statusCode,json)
            }
            
        }
        
        
//        Alamofire.request(urlstr, method: .put, parameters: para, encoding: JSONEncoding.default).responseString { (response) in
//
//            debugPrint(response)
//
//            switch response.result
//            {
//            case .failure:
//
//                completionHandler(-1,JSON.null)
//
//            case .success(let value):
//
//                let statusCode = (response.response?.statusCode)! as Int
//                let json = JSON.init(parseJSON: value)
//
//                completionHandler(statusCode,json)
//            }
//        }
        
    }
    
}



protocol AddressInfoHttpAPI {
    
    func fetchAddress(para: [String : Any], completionHandler: @escaping (_ statusCode: Int, _ json: JSON) -> Void)
    
}

extension HTTPClient : AddressInfoHttpAPI {
    
    
    func fetchAddress(para: [String : Any], completionHandler: @escaping (Int, JSON) -> Void) {
        
        let urlstr = "\(self.baseURL)api/addressinfo"
        
        HTTPClient.shareSessionManager.request(urlstr, method: .post, parameters: para, encoding: JSONEncoding.default).responseString { (response) in
            
            switch response.result
            {
            case .failure:
                
                completionHandler(-1,JSON.null)
                
            case .success(let value):
                
                let statusCode = (response.response?.statusCode)! as Int
                let json = JSON.init(parseJSON: value)
                
                completionHandler(statusCode,json)
            }
            
        }
        
    }
    
}


//MARK: WithdrawPresenter
protocol WithdrawHttpAPI {
    
    func createPaymentMethod(para : [String : Any], completionHandler: @escaping (_ statusCode: Int, _ json: JSON?) -> Void)
    func getPaymentMethodList(type: String,  completionHandler: @escaping (_ statusCode: Int, _ json: MyPaymentMethodEntity?) -> Void)
    func updateDefaultPaymentMethod(res_id: String, completionHandler: @escaping (_ statusCode: Int, _ json: JSON?) -> Void)
    func deletePaymentMethod(res_id: String, completionHandler: @escaping (_ statusCode: Int, _ json: JSON?) -> Void)
    
    func getIdempotentKeyForWithdraw(completionHandler: @escaping (_ statusCode: Int, _ json: JSON?) -> Void)
    func withdraw(para: [String : Any], completionHandler: @escaping (_ statusCode: Int, _ json: JSON?) -> Void)
    
    
}

extension HTTPClient : WithdrawHttpAPI {
    
    //
    //    +Create withdrawal with Payment Method Bank:+
    //
    //    step 1. get idempotent key: POST /api/paymentmanagement/requestids
    //
    //    body: \{ user_id: uuid, tokenType :  PaymentRequestId}, Response Body: \{ idempotent_key: "randdigits" }
    //
    //    Step 2. POST /api/paymentmanagement/payments'
    //
    //    body:
    //
    //    \{
    //    "user_id":"uuid",
    //
    //    "flowType": "Outflow",
    //    "method_id": "uuid",
    //    "ammount": "100.00",
    //    "currency": "SGD",
    //    "plan": "One-Time",
    //    "idempotent_key": "randdigits"
    //    }
    //
    //    Response Status: 201
    func getIdempotentKeyForWithdraw(completionHandler: @escaping (_ statusCode: Int, _ json: JSON?) -> Void) {
        
        if let userIDStr : String = UserDefaultTool.retrieveString(key: ASConstants.PocketStoreUserId)  {
            
            let urlstr = "\(self.baseURL)api/paymentmanagement/requestids"
            
            var para : [String : Any] = [String : Any]()
            para["user_id"] = userIDStr
            
            //MARK: hard code right now
            para["tokenType"] = "PaymentRequestId"
            
            HTTPClient.shareSessionManager.request(urlstr, method: .post, parameters: para, encoding: JSONEncoding.default).responseString { (response) in
                
                switch response.result
                {
                case .failure:
                    
                    completionHandler(-1,JSON.null)
                    
                case .success(let value):
                    
                    let statusCode = (response.response?.statusCode)! as Int
                    let json = JSON.init(parseJSON: value)
                    
                    completionHandler(statusCode,json)
                }
            }
        }
    }
    
    
    //    \{
    //    "user_id":"uuid",
    //
    //    "flowType": "Outflow",
    //    "method_id": "uuid",
    //    "ammount": "100.00",
    //    "currency": "SGD",
    //    "plan": "One-Time",
    //    "idempotent_key": "randdigits"
    //    }
    
    //    Response Status: 201
    func withdraw(para: [String : Any], completionHandler: @escaping (_ statusCode: Int, _ json: JSON?) -> Void) {
        
//        if let userIDStr : String = UserDefaultTool.retrive(key: ASConstants.PocketStoreUserId) as? String {
        
            let urlstr = "\(self.baseURL)api/paymentmanagement/payments"
            
            HTTPClient.shareSessionManager.request(urlstr, method: .post, parameters: para, encoding: JSONEncoding.default).responseString { (response) in
                
                switch response.result
                {
                case .failure:
                    
                    completionHandler(-1,JSON.null)
                    
                case .success(let value):
                    
                    let statusCode = (response.response?.statusCode)! as Int
                    let json = JSON.init(parseJSON: value)
                    
                    completionHandler(statusCode,json)
                }
            }
//        }
        
    }
    
    
//    POST /api/paymentmanagement/paymentmethods
//    Body:
//    {
//    "user_id":"uuid",
//    "name": "DBS/OCBC/...",
//    "paymentType": "Bank/CARD/...",
//    "details": { "user_name": "test", "account": "test1239623490" }
//    }
    func createPaymentMethod(para : [String : Any], completionHandler: @escaping (Int, JSON?) -> Void) {
        
        let urlstr = "\(self.baseURL)api/paymentmanagement/paymentmethods"
        
        HTTPClient.shareSessionManager.request(urlstr, method: .post, parameters: para, encoding: JSONEncoding.default).responseString { (response) in
            
            switch response.result
            {
            case .failure:
                
                completionHandler(-1,JSON.null)
                
            case .success(let value):
                
                let statusCode = (response.response?.statusCode)! as Int
                
                let json = JSON.init(parseJSON: value)
                
                completionHandler(statusCode,json)
            }
        }
    
    }
    
//    GET /api/paymentmanagement/mypaymentmethods/:user_id?type=Bank/Card
    func getPaymentMethodList(type: String, completionHandler: @escaping (Int, MyPaymentMethodEntity?) -> Void) {
        
        if let userIDStr : String = UserDefaultTool.retrieveString(key: ASConstants.PocketStoreUserId) {
            
            let urlstr = "\(self.baseURL)api/paymentmanagement/mypaymentmethods/\(userIDStr)?type=\(type)"
            
            HTTPClient.shareSessionManager.request(urlstr, method: .get, parameters: nil, encoding: JSONEncoding.default).responseString { (response) in
                
                switch response.result
                {
                case .failure:
                    
                    completionHandler(-1,nil)
                    
                case .success(let value):
                    
                    let statusCode = (response.response?.statusCode)! as Int
                    
                    //cache
                    if statusCode >= 200 && statusCode < 300 {

                        CoreDataTool.saveString(entityname: ASConstants.PocketCoredataMypaymentMethodListEntity, cacheValue: value)
                    }
                    
                    let json = MyPaymentMethodEntity.init(json: JSON.init(parseJSON: value))
                    
                    completionHandler(statusCode,json)
                }
            }
        }
    }
    
//    Update method: PUT api/paymentmanagement/mypaymentmethods
//
//    Body: { res_id: uuid }
    func updateDefaultPaymentMethod(res_id: String, completionHandler: @escaping (Int, JSON?) -> Void) {
        
        let urlstr = "\(self.baseURL)api/paymentmanagement/mypaymentmethods"
        
        var  para : [String : Any] = [String : Any]()
        para["res_id"] = res_id
        
        HTTPClient.shareSessionManager.request(urlstr, method: .put, parameters: para, encoding: JSONEncoding.default).responseString { (response) in
            
            switch response.result
            {
            case .failure:
                
                completionHandler(-1,JSON.null)
                
            case .success(let value):
                
                let statusCode = (response.response?.statusCode)! as Int
                let json = JSON.init(parseJSON: value)
                
                completionHandler(statusCode,json)
            }
        }
    }
    

//Delete : api/paymentmanagement/mypaymentmethods body: { res_id: uuid}
    func deletePaymentMethod(res_id: String, completionHandler: @escaping (_ statusCode: Int, _ json: JSON?) -> Void) {
        
        let urlstr = "\(self.baseURL)api/paymentmanagement/mypaymentmethods"
        
        var  para : [String : Any] = [String : Any]()
        para["res_id"] = res_id
        
        HTTPClient.shareSessionManager.request(urlstr, method: .delete, parameters: para, encoding: JSONEncoding.default).responseString { (response) in
            
            switch response.result
            {
            case .failure:
                
                completionHandler(-1,JSON.null)
                
            case .success(let value):
                
                let statusCode = (response.response?.statusCode)! as Int
                let json = JSON.init(parseJSON: value)
                
                completionHandler(statusCode,json)
            }
        }
    }

}


//MARK: AccountActivityPresenter
protocol AccountActivityHttpAPI {
    
    func fetchActivity(completionHandler: @escaping (_ statusCode: Int, _ json: ActivityEntity?) -> Void)
}


extension HTTPClient : AccountActivityHttpAPI {
    
//    GET /api/events/myactivities/:user_id
    func fetchActivity(completionHandler: @escaping (Int, ActivityEntity?) -> Void) {
        
        if let userIDStr : String = UserDefaultTool.retrieveString(key: ASConstants.PocketStoreUserId)  {
            
            let urlstr = "\(self.baseURL)api/events/myactivities/\(userIDStr)"
            
            HTTPClient.shareSessionManager.request(urlstr, method: .get, parameters: nil, encoding: JSONEncoding.default).responseString { (response) in
                
                switch response.result
                {
                case .failure:
                    
                    completionHandler(-1,nil)
                    
                case .success(let value):
                    
                    let statusCode = (response.response?.statusCode)! as Int
                    let json = ActivityEntity.init(json: JSON.init(parseJSON: value))
                    
                    completionHandler(statusCode,json)
                }
            }
        }
        
    }
}

//MARK: personal information page

protocol ProfileInfoHttpAPI {
    
    func fetchProfile(completionHandler: @escaping (_ statusCode: Int, _ json: PersonalInfoEntity?) -> Void)
    func updateProfile(type : String, para : [String : Any], completionHandler: @escaping (_ statusCode: Int, _ json: JSON) -> Void)
    func verifyPassword(para : [String : Any], completionHandler: @escaping (_ statusCode: Int, _ json: JSON) -> Void)
    
}


extension HTTPClient : ProfileInfoHttpAPI {
    
//    step 1: POST localhost:8000/api/updaterequests
//    body: {
//    "user_id":"4bf3fee0-ef85-11e7-b2ab-35159caf6f7e",
//    "paswd":"testing",
//    "tokenType": options
//    }
//    where options = UpdateEmail, UpdatePassword, UpdateMobileNum
    
    func verifyPassword(para: [String : Any], completionHandler: @escaping (Int, JSON) -> Void) {
        
         let urlstr = "\(self.baseURL)api/updaterequests"
        
        HTTPClient.shareSessionManager.request(urlstr, method: .post, parameters: para, encoding: JSONEncoding.default).responseString { (response) in
            
            switch response.result
            {
            case .failure:
                
                completionHandler(-1,JSON.null)
                
            case .success(let value):
                
                let statusCode = (response.response?.statusCode)! as Int
                let json = JSON.init(parseJSON: value)
                
                completionHandler(statusCode,json)
            }
        }
    }
    
    
    //API get pocket profile: GET /customers/:id?type=option
    //option: personalData, kycData, CradImageData, profileImageData
    //default: personal and kycData
    func fetchProfile(completionHandler: @escaping (Int, PersonalInfoEntity?) -> Void) {
        
        if let userIDStr : String = UserDefaultTool.retrieveString(key: ASConstants.PocketStoreUserId) {
            
            //get personalData
//            let urlstr = "\(self.baseURL)api/pocketprofile/\(userIDStr)?type=personalData"
            let urlstr = "\(self.baseURL)api/pocketprofile/\(userIDStr)"
            
            HTTPClient.shareSessionManager.request(urlstr, method: .get, parameters: nil, encoding: JSONEncoding.default).responseString { (response) in
                
                switch response.result
                {
                case .failure:
                    
                    completionHandler(-1,nil)
                    
                case .success(let value):
                    //cache
                    let statusCode = (response.response?.statusCode)! as Int
                    if statusCode >= 200 && statusCode < 300 {
                        
                        let entityName : String = ASConstants.PocketCoredataProfileEntity
                        CoreDataTool.saveString(entityname: entityName, cacheValue: value)
                    }
                    
                    let json = PersonalInfoEntity.init(json: JSON.init(parseJSON: value))
                    completionHandler(statusCode,json)
                }
            }
        }
    }
    
//    -- API update mobilenum, passwd and email: PUT /customers/:id?type=option
//    option: email, password, mobilenum
    func updateProfile(type : String, para: [String : Any], completionHandler: @escaping (Int, JSON) -> Void) {
        
        let urlstr = "\(self.baseURL)api/customers?type=\(type)"
        
        HTTPClient.shareSessionManager.request(urlstr, method: .put, parameters: para, encoding: JSONEncoding.default).responseString { (response) in
            
            switch response.result
            {
            case .failure:
                
                completionHandler(-1,JSON.null)
                
            case .success/*(let value)*/:
                
                let statusCode = (response.response?.statusCode)! as Int
                //                    let json = PersonalInfoEntity.init(json: JSON.init(parseJSON: value))
                completionHandler(statusCode,JSON.null)
            }
        }
        
    }
    
    //get base6f4 string , then convert image
//    func fetchProfileImage(completionHandler: @escaping (Int, JSON) -> Void) {
//
//        let urlstr = "\(self.baseURL)api/customers/\(para)?query=profileImageData"
//
//        Alamofire.request(urlstr, method: .get, parameters: nil, encoding: JSONEncoding.default).responseString { (response) in
//
//            switch response.result
//            {
//            case .failure:
//
//                completionHandler(-1,JSON.null)
//
//            case .success(let value):
//
//                let statusCode = (response.response?.statusCode)! as Int
//                let json = JSON.init(parseJSON: value)
//
//                completionHandler(statusCode,json)
//            }
//
//        }
//
//    }
    
}


//MARK: get terms&condition
protocol TAndCHttpAPI {
    
    func getIDAndVersionForTC(completionHandler: @escaping (_ statusCode: Int, _ json: JSON) -> Void)
    
    func agreeTermsAndConditions(para: [String: Any], completionHandler: @escaping (_ statusCode: Int, _ json: JSON) -> Void)
}

extension HTTPClient : TAndCHttpAPI {
    
//    {
//    "termandcondition": {
//    "id": "aa55dbf9-95ee-4070-ba71-301a05c48855",
//    "version": "v3"
//    }
//    }
    func getIDAndVersionForTC(completionHandler: @escaping (Int, JSON) -> Void) {
        
        let urlstr = "\(self.baseURL)api/pocketprofile/tnc/latest"
        
        
        HTTPClient.shareSessionManager.request(urlstr, method: .get, parameters: nil, encoding: JSONEncoding.default).responseString { (response) in

            //            debugPrint(response)

            switch response.result
            {
            case .failure:

                completionHandler(-1, JSON.null)

            case .success(let value):

                let statusCode = (response.response?.statusCode)! as Int

                let json = JSON.init(parseJSON: value)

                completionHandler(statusCode,json)
            }
        }
    }
    
    
    func agreeTermsAndConditions(para: [String: Any], completionHandler: @escaping (_ statusCode: Int, _ json: JSON) -> Void) {
        
//        PUT /api/pocketprofile/tnc
        
        let urlstr = "\(self.baseURL)api/pocketprofile/tnc"
        
        HTTPClient.shareSessionManager.request(urlstr, method: .put, parameters: para, encoding: JSONEncoding.default).responseString { (response) in
            
            //            debugPrint(response)
            
            switch response.result
            {
            case .failure:
                
                completionHandler(-1, JSON.null)
                
            case .success(let value):
                
                let statusCode = (response.response?.statusCode)! as Int
                
                let json = JSON.init(parseJSON: value)
                
                completionHandler(statusCode,json)
            }
        }
 
    }
    
    
    
}

//MARK: Reset Password page
protocol ResetPasswordHttpAPI {
    
    func ResetPasswordForForgetPassword(para: [String : Any], completionHandler: @escaping (_ statusCode: Int, _ result: JSON) -> Void)

    
}


extension HTTPClient : ResetPasswordHttpAPI {


    func ResetPasswordForForgetPassword(para: [String : Any], completionHandler: @escaping (Int, JSON) -> Void) {
        
        let urlstr = "\(self.baseURL)api/auth/requests"
        
        HTTPClient.shareSessionManager.request(urlstr, method: .post, parameters: para, encoding: JSONEncoding.default).responseString { (response) in
            
            //            debugPrint(response)
            
            switch response.result
            {
            case .failure:
                
                completionHandler(-1, JSON.null)
                
            case .success(let value):
                
                let statusCode = (response.response?.statusCode)! as Int
            
                let json = JSON.init(parseJSON: value)

                completionHandler(statusCode,json)
            }
        }
    }
}


//MARK:

protocol RiskLevelHttpAPI {
    
    func RegisterProtfolioAccount(para: [String : Any], completionHandler: @escaping (_ statusCode: Int, _ json: JSON) -> Void)
    func UpdateProtfolioAccount(para: [String : Any], completionHandler: @escaping (_ statusCode: Int, _ json: JSON) -> Void)
    func GetPortfolios(completionHandler: @escaping (_ statusCode: Int, _ json: PortfoliosEntity?) -> Void)
    func GetMyPortfolios(completionHandler: @escaping (_ statusCode: Int, _ json: MyPortfolioAccountEntity?) -> Void)
}


extension HTTPClient : RiskLevelHttpAPI {

//    GET /portfolioservice/myaccount/($id)
//    GET /portfolioservice/myaccount/($id)?verbose=true
//    Verbose=true provide all the information about the account that includes account values, inflows, and dashboard.
    func GetMyPortfolios(completionHandler: @escaping (Int, MyPortfolioAccountEntity?) -> Void) {
        
        if let userIDStr : String = UserDefaultTool.retrieveString(key: ASConstants.PocketStoreUserId) {
            
            let urlstr = "\(self.baseURL)api/portfolioservice/myaccount/\(userIDStr)?verbose=true"
            
            HTTPClient.shareSessionManager.request(urlstr, method: .get, parameters: nil, encoding: JSONEncoding.default).responseString { (response) in
                
//                debugPrint(response)
                
                switch response.result
                {
                case .failure:
                    
                    completionHandler(-1, nil)
                    
                case .success(let value):
                    //cache
                    let statusCode = (response.response?.statusCode)! as Int
                    if statusCode >= 200 && statusCode < 300 {
                        
                        CoreDataTool.saveString(entityname: ASConstants.PocketCoredataMyPortfolioEntity, cacheValue: value)
                    }

                    let json = MyPortfolioAccountEntity.init(json: JSON.init(parseJSON: value))
                    
                    completionHandler(statusCode, json)
                }
            }
            
        }else {
            
            debugPrint("no userId found")
            completionHandler(-1,nil)
            
        }
    }
    
    
//    GET portfolioservice/portfolios
    func GetPortfolios(completionHandler: @escaping (Int, PortfoliosEntity?) -> Void) {
        
        let urlstr = "\(self.baseURL)api/portfolioservice/portfolios"
        
        HTTPClient.shareSessionManager.request(urlstr, method: .get, parameters: nil, encoding: JSONEncoding.default).responseString { (response) in
            
//            debugPrint(response)
            
            switch response.result
            {
            case .failure:
                
                completionHandler(-1, nil)
                
            case .success(let value):

                //cache
                let statusCode = (response.response?.statusCode)! as Int
                if statusCode >= 200 && statusCode < 300 {
                    
                    CoreDataTool.saveString(entityname: ASConstants.PocketCoredataGlobalPortfolioEntity, cacheValue: value)
                }
                
                let json = PortfoliosEntity.init(json: JSON.init(parseJSON: value))

                completionHandler(statusCode, json)
            }
        }
    }
    
    
    
    
    //POST /portfolioservice/myaccount
    func RegisterProtfolioAccount(para: [String : Any], completionHandler: @escaping (Int, JSON) -> Void) {
        
        let urlstr = "\(self.baseURL)api/portfolioservice/myaccount"
        
        HTTPClient.shareSessionManager.request(urlstr, method: .post, parameters: para, encoding: JSONEncoding.default).responseString { (response) in
            
//            debugPrint(response)
            
            switch response.result
            {
            case .failure:
                
                completionHandler(-1, JSON.null)
                
            case .success(let value):
                
                let statusCode = (response.response?.statusCode)! as Int
                let json = JSON.init(parseJSON: value)
                
                completionHandler(statusCode, json)
            }
        }
    }
    
    func UpdateProtfolioAccount(para: [String : Any], completionHandler: @escaping (Int, JSON) -> Void) {
            
            let urlstr = "\(self.baseURL)api/portfolioservice/myaccount"
            
            HTTPClient.shareSessionManager.request(urlstr, method: .put, parameters: para, encoding: JSONEncoding.default).responseString { (response) in
                
//                debugPrint(response)
                
                switch response.result
                {
                case .failure:
                    
                    completionHandler(-1, JSON.null)
                    
                case .success(let value):
                    
                    let statusCode = (response.response?.statusCode)! as Int
                    let json = JSON.init(parseJSON: value)
                    
                    completionHandler(statusCode, json)
                }
            }
    }
}


//MARK : dashboard
protocol DashboardHttpAPI {
    
//    func getDashboardDetails(completionHandler: @escaping (_ statusCode: Int, _ json: DashboardEntity?) -> Void)
    
}


extension HTTPClient : DashboardHttpAPI {
    

//    func getDashboardDetails(completionHandler: @escaping (Int, DashboardEntity?) -> Void) {
//        
//        if let userIDStr : String = UserDefaultTool.retrieveString(key: ASConstants.PocketStoreUserId)  {
//            
//            let urlstr = "\(self.baseURL)api/portfolioservice/myaccount/\(userIDStr)/myweekly"
//            
//            Alamofire.request(urlstr, method: .get, parameters: nil, encoding: JSONEncoding.default).responseString { (response) in
//                
//                debugPrint(response)
//                
//                switch response.result
//                {
//                case .failure:
//                    
//                    completionHandler(-1, nil)
//                    
//                case .success(let value):
//                    
//                    let statusCode = (response.response?.statusCode)! as Int
//                    let json = DashboardEntity.init(json: JSON.init(parseJSON: value))
//                    
//                    completionHandler(statusCode,json)
//                }
//            }
//        }else {
//            
//            debugPrint("no userId found")
//            completionHandler(-1,nil)
//        }
//    }
}



//MARK: Inflow

protocol InflowHttpAPI {
    
    func addMyInflow(para: [String : Any], completionHandler: @escaping (_ statusCode: Int, _ json: AddInflowEntity?) -> Void)
    func getMyInflow(completionHandler: @escaping (_ statusCode: Int, _ json: MyInflowsEntity?) -> Void)
    
}

extension HTTPClient : InflowHttpAPI {


//    PUT localhost:8000/api/portfolioservice/myaccount/{user id}/inflows
    func addMyInflow(para: [String : Any], completionHandler: @escaping (Int, AddInflowEntity?) -> Void) {
        
        if let userIDStr : String = UserDefaultTool.retrieveString(key: ASConstants.PocketStoreUserId){
            
            let urlstr = "\(self.baseURL)api/portfolioservice/myaccount/\(userIDStr)/inflows"
            
            HTTPClient.shareSessionManager.request(urlstr, method: .put, parameters: para, encoding: JSONEncoding.default).responseString { (response) in
                
//                debugPrint(response)
                
                switch response.result
                {
                case .failure:
                    
                    completionHandler(-1, nil)
                    
                case .success(let value):
                    
                    let statusCode = (response.response?.statusCode)! as Int
                    let json = AddInflowEntity.init(json: JSON.init(parseJSON: value))
                    
                    completionHandler(statusCode,json)
                }
            }
        }else {
            
            debugPrint("no userId found")
            completionHandler(-1,nil)
        }

    }
    
//    GET localhost:8000/api/portfolioservice/myaccount/{user id}/inflows ------- by default is 3 months
//    GET localhost:8000/api/portfolioservice/myaccount/{user id}/inflows?months=n
    func getMyInflow(completionHandler: @escaping (Int, MyInflowsEntity?) -> Void) {
        
        if let userIDStr : String = UserDefaultTool.retrieveString(key: ASConstants.PocketStoreUserId){
            
            let urlstr = "\(self.baseURL)api/portfolioservice/myaccount/\(userIDStr)/inflows"
            
            HTTPClient.shareSessionManager.request(urlstr, method: .get, parameters: nil, encoding: JSONEncoding.default).responseString { (response) in
                
//                debugPrint(response)
                
                switch response.result
                {
                case .failure:
                    
                    completionHandler(-1, nil)
                    
                case .success(let value):
                    
                    //cache
                    let statusCode = (response.response?.statusCode)! as Int
                    if statusCode >= 200 && statusCode < 300 {
                        
                        CoreDataTool.saveString(entityname: ASConstants.PocketCoredataInflowsEntity, cacheValue: value)
                    }
                    
                    let json = MyInflowsEntity.init(json: JSON.init(parseJSON: value))
                    
                    completionHandler(statusCode, json)
                }
            }
        }else {
            
            debugPrint("no userId found")
            completionHandler(-1,nil)
        }
    }
}



//MARK: CustomProfileHttpAPI
protocol CustomProfileHttpAPI {
    
    func checkCompletion(completionHandler: @escaping (_ statusCode: Int, _ json: JSON) -> Void)
    
}

extension HTTPClient : CustomProfileHttpAPI {
    
    func checkCompletion(completionHandler: @escaping (Int, JSON) -> Void) {
        
        //        /pocketprofile/{id}?{querystring}
        
        if let userIDStr : String = UserDefaultTool.retrieveString(key: ASConstants.PocketStoreUserId){
            
            let urlstr = "\(self.baseURL)api/pocketprofile/\(userIDStr)?type=completionCheck"
            
            HTTPClient.shareSessionManager.request(urlstr, method: .get, parameters: nil, encoding: JSONEncoding.default).responseString { (response) in
                
//                debugPrint(response)
                
                switch response.result
                {
                case .failure:
                    
                    completionHandler(-1,JSON.null)
                    
                case .success(let value):
                    
                    let statusCode = (response.response?.statusCode)! as Int
                    let json = JSON.init(parseJSON: value)
                    
                    completionHandler(statusCode,json)
                }
            }
        }else {
            
            debugPrint("no userId found")
            completionHandler(-1,JSON.null)
        }
    }
}


//protocol UploadImageHttpAPI {
//
//    func uploadImage(token: String,para: [String : Any], completionHandler: @escaping (_ result: Bool) -> Void)
//
//}


//extension HTTPClient : UploadImageHttpAPI {
//
//
//    func uploadImage(token: String, para: [String : Any], completionHandler: @escaping (Bool) -> Void) {
//
//        Alamofire.upload(multipartFormData: { (multipartFormData:MultipartFormData) in
//            for (key, value) in para {
//                if key == "imageName" {
//                    multipartFormData.append(
//                        value as! Data,
//                        withName: key,
//                        fileName: "swift_file.jpg",
//                        mimeType: "image/jpg"
//                    )
//                } else {
//                    //Data other than image
//                    multipartFormData.append((value as! String).data(using: .utf8)!, withName: key)
//                }
//            }
//        }, usingThreshold: 1, to: "http://www.aviva.com", method: .post) { (encodingResult:SessionManager.MultipartFormDataEncodingResult) in
//
//            switch encodingResult {
//            case .success(let upload, _, _):
//                upload.responseString { response in
//                    if response.result.error != nil {
//
//                        completionHandler(true)
//
//                        return
//                    }
//                     print(response.result.value!)
////                    if let data = response.result.value {
////                        let json = JSON(data)
////                        completionHandler(false)
////                    }
//                }
//                break
//
//            case .failure(let encodingError):
//                print(encodingError)
//                completionHandler(false)
//                break
//                }
//            }
//    }
//}







protocol TwoFAHttpAPI {
    
    func verifyCode(token: String,para: [String : Any], completionHandler: @escaping (_ result: Bool) -> Void)
    
    func resendCode(para: [String : Any], completionHandler: @escaping (_ result: Bool) -> Void)
    
}

extension HTTPClient : TwoFAHttpAPI {
    
    func verifyCode(token: String, para: [String : Any], completionHandler: @escaping (Bool) -> Void) {
        
    }
    
    func resendCode(para: [String : Any], completionHandler: @escaping (Bool) -> Void) {
        
    }
    
}










