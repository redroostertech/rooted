//
//  APIService.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 5/17/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import Alamofire

private let localBaseURL = "https://localhost:3000/"
private let testBaseURL = "https://rooted-test-web.herokuapp.com/"
private let liveURL = "https://rooted.herokuapp.com/"

enum Api_V2 {
  case Analytics
  case Auth

  var bucket: String {
    switch self {
    case .Auth: return "auth/"
    case .Analytics: return "analytics/"
    }
  }
}

final class PathBuilder {
  public static func build(_ path: Api.Service, in service: Api_V2, with endpoint: String) -> String {
    return String(format: "%@%@%@", arguments: [path.url, service.bucket, endpoint])
  }
}

class Api {
  enum Service {
    case Local
    case Test
    case Live
    case Custom(String)

    var url: String {
      switch self {
      case .Local: return localBaseURL + "api/v1/"
      case .Live: return liveURL + "api/v1/"
      case .Test: return testBaseURL + "api/v1/"
      case .Custom(let customUrl):
        return customUrl
      }
    }
  }

  func performRequest(path: String = "",
                      method: HTTPMethod = .get,
                      parameters: Parameters = [:],
                      apiKey api: String = "",
                      andAccessKey access: String = "",
                      headers: HTTPHeaders = [:],
                      completion: @escaping (Any?, Error?) -> Void)
  {
      let urlString = path
      let method = method
      let parameters = parameters
      /*let apiKey = api
      let accessKey = access*/

      var headers = [
          "Accept": "application/json",
          "Agent": kMobileApiAgent
      ]

      for key in headers.keys {
          headers[key] = headers[key]
      }

      buildRequest(urlString: urlString,
                   method: method,
                   parameters: parameters,
                   headers: headers) { (results, error) in

                      completion(results, error)
      }
  }

  private func buildRequest(urlString: String,
                            method: HTTPMethod,
                            parameters: Parameters,
                            headers: HTTPHeaders,
                            completion: @escaping (Any?, Error?) -> Void)
  {
      Alamofire.request(urlString,
                        method: method,
                        parameters: parameters,
                        encoding: URLEncoding.httpBody,
                        headers: headers)
          .responseJSON { response in
              switch response.result {
              case .success:
                  if let json = response.result.value {
                      completion(json, nil)
                  } else {
                      completion(nil,
                                 NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : RError.generalError.localizedDescription]))
                  }
              case .failure(let error):
                  print(error)
                  completion(nil, error)
              }
      }
  }

  func performMultiPartRequest(path: String = "",
                               method: HTTPMethod = .post,
                               parameters: Parameters = [:],
                               data: Data,
                               fileName: String,
                               apiKey api: String = "",
                               andAccessKey access: String = "",
                               headers: HTTPHeaders = [:],
                               completion: @escaping (Any?, Error?) -> Void)
  {
      let urlString = path
      let method = method
      let parameters = parameters

      var headers = [
          "content-type": "multipart/form-data"
      ]

      for key in headers.keys {
          headers[key] = headers[key]
      }

      buildMultipartRequest(urlString: urlString,
                            method: method,
                            parameters: parameters,
                            data: data,
                            fileName: fileName,
                            headers: headers) { (results, error) in

                              completion(results, error)
      }
  }

  private func buildMultipartRequest(urlString: String,
                                     method: HTTPMethod,
                                     parameters: Parameters,
                                     data: Data,
                                     fileName: String,
                                     headers: HTTPHeaders,
                                     completion: @escaping (Any?, Error?) -> Void)
  {
      Alamofire.upload(multipartFormData: { (multipartFormData) in
          for (key, value) in parameters {
              multipartFormData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key as String)
          }
          multipartFormData.append(data, withName: fileName)

          //            if let data = imageData{
          //                multipartFormData.append(data, withName: "image", fileName: "image.png", mimeType: "image/png")
          //            }

      }, usingThreshold: UInt64.init(), to: urlString, method: .post, headers: headers) { (result) in
          switch result{
          case .success(let upload, _, _):
              upload.responseJSON { response in
                  print("Succesfully uploaded")
                  //if let err = response.error{
                  //onError?(err)
                  //    return
                  //}
                  //completion(nil)
                  print("\(response)")
                  completion(response.value, nil)

                  return
              }
          case .failure(let error):
              print("Error in upload: \(error.localizedDescription)")
              //onError?(error)
          }
      }
  }

  /*func getToken(paramsForTokenRetrieval params: [String:Any], completion:
      @escaping (_ result: [String:String]?, _ error: Error?) -> Void) {

      guard let requestBodyData = try? JSONSerialization.data(withJSONObject: params,
                                                              options: []) else {
          completion(nil,
                     NSError(domain: "There was an error.",
                             code: 500,
                             userInfo:nil))
          return
      }

      let urlString: String = Api.Endpoint.authToken

      if let urlFromString = URL(string: urlString) {

          var urlRequest: URLRequest = URLRequest(url: urlFromString)
          urlRequest.httpMethod = "POST"
          urlRequest.addValue("application/json",
                              forHTTPHeaderField: "Content-Type")
          urlRequest.httpBody = requestBodyData
          let dataTask = URLSession.shared.dataTask(with: urlRequest,
                                                    completionHandler: { (data, response, error) in
              guard error == nil else {
                  completion(nil, NSError(domain: "There was an error. \(String(describing: error?.localizedDescription))", code: 500, userInfo:nil))
                  return
              }

              print("Token fetch is running on = \(Thread.isMainThread ? "Main Thread" : "Background Thread")")

              guard let responseData = data else {
                  completion(nil, NSError(domain: "No Data", code: 500, userInfo:nil))
                  return
              }
              do {
                  guard let rawJSONArray = try JSONSerialization.jsonObject(with: responseData, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary else {
                      completion(nil, NSError(domain: "Error with JSON", code: 500, userInfo:nil))
                      return
                  }
                  guard let status = rawJSONArray["response"] as? Int, status == 200 else {
                      completion(nil, NSError(domain: "Error with connection", code: 500, userInfo:nil))
                      return
                  }
                  guard let json = rawJSONArray["data"] as? NSDictionary else {
                      completion(nil, NSError(domain: "Error with JSON", code: 500, userInfo:nil))
                      return
                  }
                  guard let token = json["auth_token"] as? String else {
                      completion(nil, NSError(domain: "Error getting token string", code: 500, userInfo:nil))
                      return
                  }
                  let urlString: String = Api.Endpoint.retrieveKeys
                  if let urlFromString = URL(string: urlString) {
                      var urlRequest: URLRequest = URLRequest(url: urlFromString)
                      urlRequest.httpMethod = "GET"
                      urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                      urlRequest.addValue(token, forHTTPHeaderField: "x-access-token")
                      let dataTask = URLSession.shared.dataTask(with: urlRequest, completionHandler: {
                          (data, response, error) in
                          guard error == nil else {
                              completion(nil, NSError(domain: "There was an error. \(String(describing: error?.localizedDescription))", code: 500, userInfo:nil))
                              return
                          }
                          print("Retrieve Key fetch is running on = \(Thread.isMainThread ? "Main Thread" : "Background Thread")")
                          guard let responseData = data else {
                              completion(nil, NSError(domain:"There was no data", code: 500, userInfo:nil))
                              return
                          }
                          do {
                              guard let rawJSONArray = try JSONSerialization.jsonObject(with: responseData, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary else {
                                  completion(nil, NSError(domain:"Error with JSON", code: 500, userInfo:nil))
                                  return
                              }
                              guard let json = rawJSONArray["data"] as? NSDictionary else {
                                  completion(nil, NSError(domain:"Error with JSON", code: 500, userInfo:nil))
                                  return
                              }
                              completion(json as? [String : String], nil)
                          } catch {
                              completion(nil, NSError(domain:"Error converting Data", code: 500, userInfo:nil))
                          }
                      })
                      dataTask.resume()
                  } else {
                      completion(nil, NSError(domain:"Can't create URL", code: 500, userInfo:nil))
                  }
              } catch {
                  completion(nil, NSError(domain:"Error converting Data", code: 500, userInfo:nil))
              }
          })
          dataTask.resume()
      } else {
          completion(nil, NSError(domain:"Can't create URL", code: 500, userInfo:nil))
      }
  }*/
}
