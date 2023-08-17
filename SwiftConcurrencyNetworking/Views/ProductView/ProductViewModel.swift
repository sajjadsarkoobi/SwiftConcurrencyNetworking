//
//  ProductViewModel.swift
//  SwiftConcurrencyNetworking
//
//  Created by Sajjad Sarkoobi on 16.08.2023.
//

import Foundation

final class ProductViewModel: ObservableObject {
    
    @Published var products: [ProductModel] = []
    @Published var productAdded: Bool = false
    
    //GET Method
    @MainActor
    func getProducts() async {
        let data = await APIClient.dispatch(
            APIRouter.GetProducts(queryParams:
                                    APIParameters.ProductParams(skip: 1, limit: 10)))
        
        //Simply we can check http status code here to do any action needed
        guard ((200..<300) ~= data._httpStatusCode) else {
            Log.error("Server response error")
            return
        }
        
        switch data._result {
        case .success(let product):
            self.products = product.products
        case .failure(let error):
            Log.error(error.localizedDescription)
        }
    }
    
    //Post Method
    @MainActor
    func addProduct(productName: String) async {
        if productName.isEmpty { return }
        let data = await APIClient.dispatch(
            APIRouter.AddProduct(body:
                                    APIParameters.AddProductParams(title: productName)))
        
        //Simply we can check http status code here to do any action needed
        guard ((200..<300) ~= data._httpStatusCode) else {
            Log.error("Server response error")
            return
        }
        
        switch data._result {
        case .success(let product):
            Log.info("Added product-> \(product.id)")
            self.productAdded.toggle()
            
        case .failure(let error):
            Log.error(error.localizedDescription)
        }
            
        
    }
}
