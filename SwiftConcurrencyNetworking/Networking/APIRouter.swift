//
//  APIRouter.swift
//  SwiftConcurrencyNetworking
//
//  Created by Sajjad Sarkoobi on 16.08.2023.
//

import Foundation

class APIRouter {
    
    // GET Request
    struct GetProducts: Request {
        var baseServer: APIConstants.ServerBaseURL = .baseURL
        typealias ReturnType = ProductsModel
        var path: String = "/products"
        var method: HTTPMethod = .get
        var queryParams: [String : Any]?
        init(queryParams: APIParameters.ProductParams) {
            self.queryParams = queryParams.asDictionary
        }
    }
    
    // POST Request
    struct AddProduct: Request {
        var baseServer: APIConstants.ServerBaseURL = .baseURL
        typealias ReturnType = AddedProductModel
        var path: String = "/products/add"
        var method: HTTPMethod = .post
        var body: [String : Any]?
        init(body: APIParameters.AddProductParams) {
            self.body = body.asDictionary
        }
    }
}
