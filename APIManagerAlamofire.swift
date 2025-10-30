//
//  APIClass.swift
//  APIPractice
//
//  Created by DREAMWORLD on 30/10/25.
//

import Foundation
import Alamofire
import UIKit

public class API_Manager {
    public static let shared: API_Manager = API_Manager()
 
    private var alamofireManager = Alamofire.Session.default
    private var currentDataRequest: DataRequest!
    
    public enum RESPONSE_TYPE {
        case SUCCESS
        case ERROR
    }
    
    public enum ParameterEncodingType {
        case jsonEncoding
        case urlEncoding
    }
    
    public enum HTTPError: Int {
        case badRequest = 400
        case unauthorized = 401
        case forbidden = 403
        case notFound = 404
        case requestTimeout = 408
        case tooManyRequests = 429
        case internalServerError = 500
        case badGateway = 502
        case serviceUnavailable = 503
        case gatewayTimeout = 504
        case unknown = 0
        
        init(statusCode: Int) {
            self = HTTPError(rawValue: statusCode) ?? .unknown
        }
        
        var message: String {
            switch self {
            case .badRequest: return "Bad Request – The server could not understand your request."
            case .unauthorized: return "Unauthorized – Please login again."
            case .forbidden: return "Forbidden – You don’t have permission to access this resource."
            case .notFound: return "Not Found – The requested resource could not be found."
            case .requestTimeout: return "Request Timeout – Please try again later."
            case .tooManyRequests: return "Too Many Requests – Please slow down and try again later."
            case .internalServerError: return "Internal Server Error – Something went wrong on the server."
            case .badGateway: return "Bad Gateway – Invalid response from the upstream server."
            case .serviceUnavailable: return "Service Unavailable – The server is temporarily down."
            case .gatewayTimeout: return "Gateway Timeout – The server didn’t respond in time."
            case .unknown: return "An unexpected error occurred. Please try again."
            }
        }
    }
    
    // METHODS
    init() {
        alamofireManager.session.configuration.timeoutIntervalForRequest = 180
    }
    
    struct APIConfig {
        static let baseURL = "https://api.restful-api.dev/"
    }
}

// Common Method
extension API_Manager {
    private func getRequiredHTTPHeader(arrHeader: [String: String],
                                       encodingType: ParameterEncodingType = .jsonEncoding) -> HTTPHeaders {
        var arrHTTPHeader: HTTPHeaders = [
            HTTPHeader(name: "Accept", value: "application/json")
        ]
        
        // Set Content-Type based on encoding type
        switch encodingType {
        case .jsonEncoding:
            arrHTTPHeader.add(HTTPHeader(name: "Content-Type", value: "application/json"))
        case .urlEncoding:
            arrHTTPHeader.add(HTTPHeader(name: "Content-Type", value: "application/x-www-form-urlencoded"))
        }
        
        // Merge custom headers
        for (key, value) in arrHeader {
            arrHTTPHeader.add(HTTPHeader(name: key, value: value))
        }
        
        return arrHTTPHeader
    }
    
    private func checkInternetConnection() -> Bool {
        let manager = NetworkReachabilityManager()
        let isReachable = manager?.isReachable ?? false
        
        if !isReachable {
            Toast.show(message: "Check your internet connection.", type: .warning)
        }
    
        return isReachable
    }
    
    private func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    private func convertToJSON(text: String) -> Any? {
        guard let data = text.data(using: .utf8) else { return nil }
        do {
            return try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            print("JSON parsing error: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func getMimeType(fileExt: String) -> String {
        var mime = ""
        
        switch fileExt {
        case "jpeg":
            mime = "image/jpeg"
            break
        case "jpg":
            mime = "image/jpg"
            break
        case "png":
            mime = "image/png"
            break
        case "gif":
            mime = "image/gif"
            break
        case "3gpp":
            mime = "video/3gpp"
            break
        case "3gp":
            mime = "video/3gpp"
            break
        case "ts":
            mime = "video/mp2t"
            break
        case "mp4":
            mime = "video/mp4"
            break
        case "mpeg":
            mime = "video/mpeg"
            break
        case "mpg":
            mime = "video/mpg"
            break
        case "mov":
            mime = "video/quicktime"
            break
        case "webm":
            mime = "video/webm"
            break
        case "flv":
            mime = "video/x-flv"
            break
        case "m4v":
            mime = "video/x-m4v"
            break
        case "mng":
            mime = "video/x-mng"
            break
        case "asx":
            mime = "video/x-ms-asf"
            break
        case "asf":
            mime = "video/x-ms-asf"
            break
        case "wmv":
            mime = "video/x-ms-wmv"
            break
        case "avi":
            mime = "video/x-msvideo"
            break
        case "docx":
            mime = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "xlsx":
            mime = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case "pptx":
            mime = "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        case "doc":
            mime = "application/msword"
        case "pdf":
            mime = "application/pdf"
        case "txt":
            mime = "text/plain"
        default:
            break
        }
        
        return mime
    }
    
//    private func COMMON_METHOD(requestURL: String,
//                               method: HTTPMethod,
//                               param: [String: Any],
//                               header: [String: String],
//                               encodingType: ParameterEncodingType = .jsonEncoding,
//                               isShowLoader: Bool,
//                               responseData: @escaping(_ responseType: RESPONSE_TYPE,
//                                                      _ error: Error?,
//                                                      _ responseDict: [String: Any]?) -> Void) {
//        if checkInternetConnection() {
//            if isShowLoader { Loader.shared.show() }
//
//            let finalURL: String
//            if requestURL.lowercased().hasPrefix("http") {
//                finalURL = requestURL
//            } else {
//                finalURL = "\(APIConfig.baseURL)\(requestURL)"
//            }
//            
//            let encoding: ParameterEncoding = (encodingType == .jsonEncoding)
//                    ? JSONEncoding.default
//                    : URLEncoding.default
//            
//            if method == .put || method == .post {
//                
//                currentDataRequest = alamofireManager.request(finalURL,
//                                                              method: method,
//                                                              parameters: param,
//                                                              encoding: encoding,
//                                                              headers: getRequiredHTTPHeader(arrHeader: header, encodingType: encodingType))
//            } else {
//                currentDataRequest = alamofireManager.request(finalURL,
//                                                              method: method,
//                                                              parameters: param,
//                                                              encoding: (method == .get || encodingType == .urlEncoding) ? URLEncoding.default : JSONEncoding.default,
//                                                              headers: getRequiredHTTPHeader(arrHeader: header, encodingType: encodingType))
//            }
//            
//            currentDataRequest.responseString(completionHandler: { (responseString) in
//                if isShowLoader { Loader.shared.hide() }
//
//                let httpStatusCode = responseString.response?.statusCode ?? 0
//                   let strResponse = responseString.value ?? ""
//                   let httpError = HTTPError(statusCode: httpStatusCode)
//                   
//                   #if DEBUG
//                   print("🌐 [API] URL: \(finalURL)")
//                   print("➡️ Request: \(param)")
//                   print("⬅️ Response: \(strResponse)")
//                   print("🔢 Status Code: \(httpStatusCode)")
//                   #endif
//
//                   if let error = responseString.error {
//                       Toast.show(message: httpError.message, type: .error)
//                       responseData(.ERROR, error, self.convertToDictionary(text: strResponse))
//                       return
//                   }
//                   
//                   guard (200...299).contains(httpStatusCode) else {
//                       Toast.show(message: httpError.message, type: .error)
//                       responseData(.ERROR, nil, self.convertToDictionary(text: strResponse))
//                       return
//                   }
//
////                if let dict = self.convertToDictionary(text: strResponse) {
////                       responseData(.SUCCESS, nil, dict)
////                   } else {
////                       Toast.show(message: "Invalid server response.", type: .error)
////                       responseData(.ERROR, nil, nil)
////                   }
//                
//                if let dict = self.convertToDictionary(text: strResponse) {
//                    responseData(.SUCCESS, nil, dict) // Old behavior
//                } else if let json = self.convertToJSON(text: strResponse) {
//                    // If top-level array or primitive
//                    if let array = json as? [Any] {
//                        responseData(.SUCCESS, nil, ["data": array])
//                    } else {
//                        responseData(.SUCCESS, nil, ["value": json])
//                    }
//                } else {
//                    Toast.show(message: "Invalid server response.", type: .error)
//                    responseData(.ERROR, nil, nil)
//                }
//            })
//        }
//    }
    
    private func COMMON_METHOD<T: Decodable>(
        requestURL: String,
        method: HTTPMethod,
        param: [String: Any],
        header: [String: String],
        encodingType: ParameterEncodingType = .jsonEncoding,
        isShowLoader: Bool,
        responseType: T.Type? = nil,
        responseData: @escaping (_ responseType: RESPONSE_TYPE,
                                 _ error: Error?,
                                 _ responseDict: [String: Any]?,
                                 _ model: T?) -> Void
    ) {
        guard checkInternetConnection() else { return }
        if isShowLoader { Loader.shared.show() }

        let finalURL = requestURL.lowercased().hasPrefix("http") ?
        requestURL : "\(APIConfig.baseURL)\(requestURL)"

        let encoding: ParameterEncoding = (encodingType == .jsonEncoding)
        ? JSONEncoding.default : URLEncoding.default

        currentDataRequest = alamofireManager.request(
            finalURL,
            method: method,
            parameters: param,
            encoding: encoding,
            headers: getRequiredHTTPHeader(arrHeader: header, encodingType: encodingType)
        )

        currentDataRequest.responseString { responseString in
            if isShowLoader { Loader.shared.hide() }

            let httpStatusCode = responseString.response?.statusCode ?? 0
            let strResponse = responseString.value ?? ""
            let httpError = HTTPError(statusCode: httpStatusCode)

            #if DEBUG
            print("🌐 [API] URL: \(finalURL)")
            print("➡️ Request Params: \(param)")
            print("⬅️ Response: \(strResponse)")
            print("🔢 Status Code: \(httpStatusCode)")
            #endif

            // MARK: - Error from Alamofire
            if let error = responseString.error {
                Toast.show(message: httpError.message, type: .error)
                responseData(.ERROR, error, self.convertToDictionary(text: strResponse), nil)
                return
            }

            // MARK: - Invalid Status Code
            guard (200...299).contains(httpStatusCode) else {
                Toast.show(message: httpError.message, type: .error)
                responseData(.ERROR, nil, self.convertToDictionary(text: strResponse), nil)
                return
            }

            // MARK: - Decode Response
            guard let data = strResponse.data(using: .utf8) else {
                Toast.show(message: "Invalid response format.", type: .error)
                responseData(.ERROR, nil, nil, nil)
                return
            }

            // ✅ Decode Model
            if let type = responseType {
                do {
                    let model = try JSONDecoder().decode(type, from: data)

                    // Try to convert to [String: Any] for easier debug
                    var jsonDict: [String: Any]? = nil
                    if let dict = self.convertToDictionary(text: strResponse) {
                        jsonDict = dict
                    } else if let arr = self.convertToJSON(text: strResponse) as? [Any] {
                        jsonDict = ["data": arr]
                    }

                    responseData(.SUCCESS, nil, jsonDict, model)

                } catch let DecodingError.dataCorrupted(context) {
                    print("❌ Decoding error: data corrupted - \(context.debugDescription)")
                    print("   Coding Path: \(context.codingPath)")
                    responseData(.SUCCESS, nil, nil, nil)
                } catch let DecodingError.keyNotFound(key, context) {
                    print("❌ Decoding error: key '\(key)' not found: \(context.debugDescription)")
                    print("   Coding Path: \(context.codingPath)")
                    responseData(.SUCCESS, nil, nil, nil)
                } catch let DecodingError.valueNotFound(value, context) {
                    print("❌ Decoding error: value '\(value)' not found: \(context.debugDescription)")
                    print("   Coding Path: \(context.codingPath)")
                    responseData(.SUCCESS, nil, nil, nil)
                } catch let DecodingError.typeMismatch(type, context) {
                    print("❌ Decoding error: type '\(type)' mismatch: \(context.debugDescription)")
                    print("   Coding Path: \(context.codingPath)")
                    responseData(.SUCCESS, nil, nil, nil)
                } catch {
                    print("❌ Decoding error: \(error.localizedDescription)")
                    responseData(.SUCCESS, nil, nil, nil)
                }
            } else {
                // If no model specified, return raw JSON
                if let dict = self.convertToDictionary(text: strResponse) {
                    responseData(.SUCCESS, nil, dict, nil)
                } else if let array = self.convertToJSON(text: strResponse) as? [Any] {
                    responseData(.SUCCESS, nil, ["data": array], nil)
                } else {
                    Toast.show(message: "Invalid server response.", type: .error)
                    responseData(.ERROR, nil, nil, nil)
                }
            }
        }
    }
}

// GET Method
extension API_Manager {
    
//    public func GET_METHOD(requestURL: String,
//                           param: [String: Any] = [:],
//                           header: [String: String] = [:],
//                           encodingType: ParameterEncodingType = .urlEncoding,
//                           isShowLoader: Bool = true,
//                           responseData: @escaping(_ responseType: RESPONSE_TYPE,
//                                                  _ error: Error?,
//                                                  _ responseDict: [String: Any]?) -> Void) {
//        
//        COMMON_METHOD(requestURL: requestURL,
//                      method: .get,
//                      param: param,
//                      header: header,
//                      encodingType: encodingType,
//                      isShowLoader: isShowLoader) { responseType, error, responseDict in
//            responseData(responseType, error, responseDict)
//        }
//    }
    
    public func GET_METHOD<T: Decodable>(
        requestURL: String,
        param: [String: Any] = [:],
        header: [String: String] = [:],
        encodingType: ParameterEncodingType = .urlEncoding,
        isShowLoader: Bool = true,
        responseType: T.Type? = nil,
        responseData: @escaping (_ responseType: RESPONSE_TYPE,
                                 _ error: Error?,
                                 _ responseDict: [String: Any]?,
                                 _ model: T?) -> Void) {
        
        COMMON_METHOD(requestURL: requestURL,
                      method: .get,
                      param: param,
                      header: header,
                      encodingType: encodingType,
                      isShowLoader: isShowLoader,
                      responseType: responseType,
                      responseData: responseData)
    }

}

// POST/PUT Method
extension API_Manager {
//    public func POST_METHOD(requestURL:String,
//                           param: [String: Any] = [:],
//                           header: [String: String] = [:],
//                           encodingType: ParameterEncodingType = .jsonEncoding,
//                           isShowLoader: Bool = true,
//                           responseData: @escaping(_ responseType: RESPONSE_TYPE,
//                                                  _ error: Error?,
//                                                  _ responseDict: [String: Any]?) -> Void) {
//        
//        COMMON_METHOD(requestURL: requestURL,
//                      method: .post,
//                      param: param,
//                      header: header,
//                      encodingType: encodingType,
//                      isShowLoader: isShowLoader) { responseType, error, responseDict in
//            responseData(responseType,error,responseDict)
//        }
//    }
//    
//    public func PUT_METHOD(requestURL: String,
//                           param: [String: Any] = [:],
//                           header: [String: String] = [:],
//                           encodingType: ParameterEncodingType = .jsonEncoding,
//                           isShowLoader: Bool = true,
//                           responseData: @escaping(_ responseType: RESPONSE_TYPE,
//                                                  _ error: Error?,
//                                                  _ responseDict: [String: Any]?) -> Void) {
//        
//        COMMON_METHOD(requestURL: requestURL,
//                      method: .put,
//                      param: param,
//                      header: header,
//                      encodingType: encodingType,
//                      isShowLoader: isShowLoader) { responseType, error, responseDict in
//            responseData(responseType,error,responseDict)
//        }
//    }
    
    
    // 🔹 POST Method
       public func POST_METHOD<T: Decodable>(
           requestURL: String,
           param: [String: Any] = [:],
           header: [String: String] = [:],
           encodingType: ParameterEncodingType = .jsonEncoding,
           isShowLoader: Bool = true,
           responseType: T.Type? = nil,
           responseData: @escaping(_ responseType: RESPONSE_TYPE,
                                   _ error: Error?,
                                   _ responseDict: [String: Any]?,
                                   _ model: T?) -> Void) {
           
           COMMON_METHOD(requestURL: requestURL,
                         method: .post,
                         param: param,
                         header: header,
                         encodingType: encodingType,
                         isShowLoader: isShowLoader,
                         responseType: responseType,
                         responseData: responseData)
       }
       
       // 🔹 PUT Method
       public func PUT_METHOD<T: Decodable>(
           requestURL: String,
           param: [String: Any] = [:],
           header: [String: String] = [:],
           encodingType: ParameterEncodingType = .jsonEncoding,
           isShowLoader: Bool = true,
           responseType: T.Type? = nil,
           responseData: @escaping(_ responseType: RESPONSE_TYPE,
                                   _ error: Error?,
                                   _ responseDict: [String: Any]?,
                                   _ model: T?) -> Void) {
           
           COMMON_METHOD(requestURL: requestURL,
                         method: .put,
                         param: param,
                         header: header,
                         encodingType: encodingType,
                         isShowLoader: isShowLoader,
                         responseType: responseType,
                         responseData: responseData)
       }
}

// MULTIPART Method
extension API_Manager {
//    public func MULTIPART_METHOD(requestURL: String,
//                                 param: [String: Any] = [:],
//                                 header: [String: String] = [:],
//                                 isShowLoader: Bool = true,
//                                 uploadProgress: ((CGFloat) -> Void)? = nil,
//                                 responseData: @escaping (_ responseType: RESPONSE_TYPE,
//                                                          _ error: Error?,
//                                                          _ responseDict: [String: Any]?) -> Void) {
//        
//        if checkInternetConnection() {
//            if isShowLoader { Loader.shared.show() }
//            
//            let finalURL: String
//            if requestURL.lowercased().hasPrefix("http") {
//                finalURL = requestURL
//            } else {
//                finalURL = "\(APIConfig.baseURL)\(requestURL)"
//            }
//            
//            alamofireManager.upload(multipartFormData: { multipartFormData in
//                for (key, value) in param {
//                    
//                    if let imgVal = value as? UIImage {
//                        multipartFormData.append(imgVal.jpegData(compressionQuality: 0.1)!,
//                                                 withName: key,
//                                                 fileName: "\(Date().timeIntervalSince1970).jpeg",
//                                                 mimeType: self.getMimeType(fileExt: "jpeg"))
//                        
//                    } else if let dataVal = value as? Data {
//                        multipartFormData.append(dataVal,
//                                                 withName: key,
//                                                 fileName: "\(Date().timeIntervalSince1970).jpeg",
//                                                 mimeType: self.getMimeType(fileExt: "jpeg"))
//                        
//                    } else if let urlVal = value as? URL {
//                        let fileExt = (urlVal.lastPathComponent.components(separatedBy: ".").last!).lowercased()
//                        do {
//                            let fileData = try Data(contentsOf: urlVal)
//                            multipartFormData.append(fileData,
//                                                     withName: key,
//                                                     fileName: "\(Date().timeIntervalSince1970).\(fileExt)",
//                                                     mimeType: self.getMimeType(fileExt: fileExt))
//                        } catch let error {
//                            print("Multipart file read error: \(error.localizedDescription)")
//                        }
//                        
//                    } else if let strVal = value as? String {
//                        multipartFormData.append(strVal.data(using: .utf8)!, withName: key)
//                    }
//                }
//            }, to: finalURL, method: .post, headers: getRequiredHTTPHeader(arrHeader: header))
//            .uploadProgress(queue: .main) { progress in
//                uploadProgress?(progress.fractionCompleted)
//            }
//            .responseString { responseString in
//                
//                if isShowLoader { Loader.shared.hide() }
//                
//                let httpStatusCode = responseString.response?.statusCode ?? 0
//                let strResponse = responseString.value ?? ""
//                let httpError = HTTPError(statusCode: httpStatusCode)
//                
//#if DEBUG
//                print("🌐 [MULTIPART] URL: \(finalURL)")
//                print("➡️ Request Params: \(param)")
//                print("⬅️ Response: \(strResponse)")
//                print("🔢 Status Code: \(httpStatusCode)")
//#endif
//                
//                // Handle network or Alamofire error
//                if let error = responseString.error {
//                    Toast.show(message: httpError.message, type: .error)
//                    responseData(.ERROR, error, self.convertToDictionary(text: strResponse))
//                    return
//                }
//                
//                // Handle non-success HTTP status codes
//                guard (200...299).contains(httpStatusCode) else {
//                    Toast.show(message: httpError.message, type: .error)
//                    responseData(.ERROR, nil, self.convertToDictionary(text: strResponse))
//                    return
//                }
//                
//                // Success
////                if let dict = self.convertToDictionary(text: strResponse) {
////                    responseData(.SUCCESS, nil, dict)
////                } else {
////                    Toast.show(message: "Invalid server response.", type: .error)
////                    responseData(.ERROR, nil, nil)
////                }
//                
//                // Success: try convertToDictionary first
//                if let dict = self.convertToDictionary(text: strResponse) {
//                    responseData(.SUCCESS, nil, dict)
//                }
//                // Fallback to convertToJSON for array or primitive values
//                else if let json = self.convertToJSON(text: strResponse) {
//                    if let array = json as? [Any] {
//                        responseData(.SUCCESS, nil, ["data": array])
//                    } else {
//                        responseData(.SUCCESS, nil, ["value": json])
//                    }
//                } else {
//                    Toast.show(message: "Invalid server response.", type: .error)
//                    responseData(.ERROR, nil, nil)
//                }
//            }
//        }
//    }
    
    public func MULTIPART_METHOD<T: Decodable>(
        requestURL: String,
        param: [String: Any] = [:],
        header: [String: String] = [:],
        isShowLoader: Bool = true,
        uploadProgress: ((CGFloat) -> Void)? = nil,
        responseType: T.Type? = nil,
        responseData: @escaping (_ responseType: RESPONSE_TYPE,
                                 _ error: Error?,
                                 _ responseDict: [String: Any]?,
                                 _ model: T?) -> Void) {
        
        if checkInternetConnection() {
            if isShowLoader { Loader.shared.show() }
            
            // ✅ Use BASE_URL fallback
            let finalURL: String
            if requestURL.lowercased().hasPrefix("http") {
                finalURL = requestURL
            } else {
                finalURL = "\(APIConfig.baseURL)\(requestURL)"
            }
            
            alamofireManager.upload(multipartFormData: { multipartFormData in
                for (key, value) in param {
                    
                    if let imgVal = value as? UIImage {
                        if let data = imgVal.jpegData(compressionQuality: 0.8) {
                            multipartFormData.append(data,
                                                     withName: key,
                                                     fileName: "\(Date().timeIntervalSince1970).jpeg",
                                                     mimeType: self.getMimeType(fileExt: "jpeg"))
                        }
                    } else if let dataVal = value as? Data {
                        multipartFormData.append(dataVal,
                                                 withName: key,
                                                 fileName: "\(Date().timeIntervalSince1970).jpeg",
                                                 mimeType: self.getMimeType(fileExt: "jpeg"))
                    } else if let urlVal = value as? URL {
                        let fileExt = (urlVal.pathExtension).lowercased()
                        do {
                            let fileData = try Data(contentsOf: urlVal)
                            multipartFormData.append(fileData,
                                                     withName: key,
                                                     fileName: "\(Date().timeIntervalSince1970).\(fileExt)",
                                                     mimeType: self.getMimeType(fileExt: fileExt))
                        } catch {
                            print("📄 Multipart file read error: \(error.localizedDescription)")
                        }
                    } else if let strVal = value as? String {
                        multipartFormData.append(Data(strVal.utf8), withName: key)
                    }
                }
            }, to: finalURL, method: .post, headers: getRequiredHTTPHeader(arrHeader: header))
            .uploadProgress(queue: .main) { progress in
                uploadProgress?(progress.fractionCompleted)
            }
            .responseString { responseString in
                
                if isShowLoader { Loader.shared.hide() }
                
                let httpStatusCode = responseString.response?.statusCode ?? 0
                let strResponse = responseString.value ?? ""
                let httpError = HTTPError(statusCode: httpStatusCode)
                
                #if DEBUG
                print("🌐 [MULTIPART] URL: \(finalURL)")
                print("➡️ Request Params: \(param)")
                print("⬅️ Response: \(strResponse)")
                print("🔢 Status Code: \(httpStatusCode)")
                #endif
                
                // ❌ Alamofire/network error
                if let error = responseString.error {
                    Toast.show(message: httpError.message, type: .error)
                    responseData(.ERROR, error, self.convertToDictionary(text: strResponse), nil)
                    return
                }
                
                // ❌ Non-2xx HTTP status
                guard (200...299).contains(httpStatusCode) else {
                    Toast.show(message: httpError.message, type: .error)
                    responseData(.ERROR, nil, self.convertToDictionary(text: strResponse), nil)
                    return
                }
                
                // ✅ Parse JSON response
                if let dict = self.convertToDictionary(text: strResponse) {
                    // If Decodable type expected, decode it
                    if let responseType = responseType {
                        if let data = strResponse.data(using: .utf8) {
                            do {
                                let model = try JSONDecoder().decode(responseType, from: data)
                                responseData(.SUCCESS, nil, dict, model)
                                return
                            } catch {
                                print("⚠️ Decoding error: \(error.localizedDescription)")
                            }
                        }
                    }
                    responseData(.SUCCESS, nil, dict, nil)
                }
                // If top-level array or primitive
                else if let json = self.convertToJSON(text: strResponse) {
                    if let array = json as? [Any] {
                        responseData(.SUCCESS, nil, ["data": array], nil)
                    } else {
                        responseData(.SUCCESS, nil, ["value": json], nil)
                    }
                } else {
                    Toast.show(message: "Invalid server response.", type: .error)
                    responseData(.ERROR, nil, nil, nil)
                }
            }
        }
    }
    
}

// DELETE Method
extension API_Manager {
//    public func DELETE_METHOD(requestURL: String,
//                              param: [String: Any] = [:],
//                              header: [String: String] = [:],
//                              encodingType: ParameterEncodingType = .urlEncoding,
//                              isShowLoader: Bool = true,
//                              responseData: @escaping(_ responseType: RESPONSE_TYPE,
//                                                     _ error: Error?,
//                                                     _ responseDict: [String: Any]?) -> Void) {
//        COMMON_METHOD(requestURL: requestURL,
//                      method: .delete,
//                      param: param,
//                      header: header,
//                      encodingType: encodingType,
//                      isShowLoader: isShowLoader) { responseType, error, responseDict in
//            responseData(responseType,error,responseDict)
//        }
//    }
    
    public func DELETE_METHOD<T: Decodable>(
        requestURL: String,
        param: [String: Any] = [:],
        header: [String: String] = [:],
        encodingType: ParameterEncodingType = .urlEncoding,
        isShowLoader: Bool = true,
        responseType: T.Type? = nil,
        responseData: @escaping(_ responseType: RESPONSE_TYPE,
                                _ error: Error?,
                                _ responseDict: [String: Any]?,
                                _ model: T?) -> Void) {
        
        COMMON_METHOD(requestURL: requestURL,
                      method: .delete,
                      param: param,
                      header: header,
                      encodingType: encodingType,
                      isShowLoader: isShowLoader,
                      responseType: responseType,
                      responseData: responseData)
    }
}

// PATCH Method
extension API_Manager {
//    public func PATCH_METHOD(requestURL: String,
//                             param: [String: Any] = [:],
//                             header: [String: String] = [:],
//                             encodingType: ParameterEncodingType = .jsonEncoding,
//                             isShowLoader: Bool = true,
//                             responseData: @escaping (_ responseType: RESPONSE_TYPE,
//                                                     _ error: Error?,
//                                                     _ responseDict: [String: Any]?) -> Void) {
//        
//        COMMON_METHOD(requestURL: requestURL,
//                      method: .patch,
//                      param: param,
//                      header: header,
//                      encodingType: encodingType,
//                      isShowLoader: isShowLoader) { responseType, error, responseDict in
//            responseData(responseType, error, responseDict)
//        }
//    }
    
    public func PATCH_METHOD<T: Decodable>(
           requestURL: String,
           param: [String: Any] = [:],
           header: [String: String] = [:],
           encodingType: ParameterEncodingType = .jsonEncoding,
           isShowLoader: Bool = true,
           responseType: T.Type? = nil,
           responseData: @escaping(_ responseType: RESPONSE_TYPE,
                                   _ error: Error?,
                                   _ responseDict: [String: Any]?,
                                   _ model: T?) -> Void) {
           
           COMMON_METHOD(requestURL: requestURL,
                         method: .patch,
                         param: param,
                         header: header,
                         encodingType: encodingType,
                         isShowLoader: isShowLoader,
                         responseType: responseType,
                         responseData: responseData)
       }
}

// Cancel Running Request Method
extension API_Manager {
    public func cancelAllAlamofireRequests(responseData: @escaping (_ status: Bool?) -> Void) {
        alamofireManager.session.getTasksWithCompletionHandler {
            dataTasks, uploadTasks, downloadTasks in
            dataTasks.forEach { $0.cancel() }
            uploadTasks.forEach { $0.cancel() }
            downloadTasks.forEach { $0.cancel() }
            responseData(true)
        }
    }
    
    public func cancelCurrentAlamofireRequests() {
        if let req = currentDataRequest {
            req.cancel()
            currentDataRequest = nil
        }
    }
}

class Toast {
    static func show(message: String, duration: Double = 2.0) {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }

        // Toast label setup
        let toastLabel = UILabel()
        toastLabel.text = message
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.numberOfLines = 0
        toastLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toastLabel.alpha = 0.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true

        // Size and position
        let padding: CGFloat = 16
        let maxWidth: CGFloat = window.frame.width - (padding * 2)
        let size = toastLabel.sizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
        toastLabel.frame = CGRect(
            x: padding,
            y: window.safeAreaInsets.top + 20,
            width: maxWidth,
            height: size.height + 20
        )

        // Add to window
        window.addSubview(toastLabel)

        // Animate show / hide
        UIView.animate(withDuration: 0.4, animations: {
            toastLabel.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.4, delay: duration, options: .curveEaseInOut, animations: {
                toastLabel.alpha = 0.0
            }) { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }
}

enum ToastType {
    case success
    case error
    case warning
}

extension Toast {
    static func show(message: String, type: ToastType = .success, duration: Double = 2.0) {
        var bgColor: UIColor
        switch type {
        case .success: bgColor = UIColor.systemGreen.withAlphaComponent(0.9)
        case .error: bgColor = UIColor.systemRed.withAlphaComponent(0.9)
        case .warning: bgColor = UIColor.systemOrange.withAlphaComponent(0.9)
        }
        
        showToast(message: message, bgColor: bgColor, duration: duration)
    }
    
    private static func showToast(message: String, bgColor: UIColor, duration: Double) {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }

        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.backgroundColor = bgColor
        label.alpha = 0
        label.layer.cornerRadius = 10
        label.clipsToBounds = true

        let padding: CGFloat = 16
        let maxWidth: CGFloat = window.frame.width - (padding * 2)
        let size = label.sizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
        label.frame = CGRect(x: padding,
                             y: window.safeAreaInsets.top + 20,
                             width: maxWidth,
                             height: size.height + 20)

        window.addSubview(label)

        UIView.animate(withDuration: 0.3) {
            label.alpha = 1
        } completion: { _ in
            UIView.animate(withDuration: 0.3, delay: duration, options: .curveEaseInOut) {
                label.alpha = 0
            } completion: { _ in
                label.removeFromSuperview()
            }
        }
    }
}

// MARK: - API Loader

final class Loader {
    static let shared = Loader()
    
    private var spinner: UIActivityIndicatorView?
    private var backgroundView: UIView?
    
    private init() {}
    
    func show() {
        DispatchQueue.main.async {
            guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }
            
            // Prevent duplicate loader
            if self.backgroundView != nil { return }
            
            let bgView = UIView(frame: window.bounds)
            bgView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            
            let spinner = UIActivityIndicatorView(style: .large)
            spinner.center = bgView.center
            spinner.color = .gray
            spinner.startAnimating()
            
            bgView.addSubview(spinner)
            window.addSubview(bgView)
            
            self.backgroundView = bgView
            self.spinner = spinner
        }
    }
    
    func hide() {
        DispatchQueue.main.async {
            self.spinner?.stopAnimating()
            self.backgroundView?.removeFromSuperview()
            self.spinner = nil
            self.backgroundView = nil
        }
    }
}
