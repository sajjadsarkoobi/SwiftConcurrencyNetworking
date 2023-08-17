//
//  ProductView.swift
//  SwiftConcurrencyNetworking
//
//  Created by Sajjad Sarkoobi on 16.08.2023.
//

import SwiftUI

struct ProductView: View {
    
    @ObservedObject var viewModel: ProductViewModel = ProductViewModel()
    @State var presentAlert: Bool = false
    @State var newProduct: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    
                    HStack {
                        TextField("Add product", text: $newProduct)
                            .textFieldStyle(.plain)
                        Button("Add") {
                            Task {
                               await viewModel.addProduct(productName: newProduct)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    
                    List(viewModel.products, id: \.self) { product in
                        Label("\(product.title)", systemImage: "rays")
                    }
                }
            }
            .navigationTitle("Products")
        }
        .alert("Product Added", isPresented: $presentAlert, actions: {
            Button("OK", role: .cancel) { }
        }, message: {
            Text("Since we are using Sample server it will not add to their server's list. but if you check the response in the console you can see it is returning 200 with some id.")
        })
        .onChange(of: viewModel.productAdded) { newValue in
                presentAlert.toggle()
        }
        .task {
           await viewModel.getProducts()
        }
    }
}

struct ProductView_Previews: PreviewProvider {
    static var previews: some View {
        ProductView()
    }
}
