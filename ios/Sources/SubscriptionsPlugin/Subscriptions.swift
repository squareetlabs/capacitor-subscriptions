import Foundation
import StoreKit
import Capacitor
import UIKit

@objc public class Subscriptions: NSObject {
    
    override init() {
        super.init();
        if #available(iOS 15.0.0, *) {
            let transactionListener = listenForTransactions();
            let unfinishedListener = finishTransactions();
        } else {
            // Fallback on earlier versions
        };
    }
    
    // When the subscription renews at the end of the month, a transaction will
    // be queued for when the app is next opened. This listener handles any transactions
    // within the queue and finishes verified purchases to clear the queue and prevent
    // any bugs or performance issues occuring
    @available(iOS 15.0.0, *)
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {

            //Iterate through any transactions that don't come from a direct call to `purchase()`.
            for await verification in Transaction.updates {
                
                guard let transaction: Transaction = self.checkVerified(verification)
                        as? Transaction else {
                    print("checkVerified failed");
                    return
                    
                };
            
                await transaction.finish();
                print("Transaction finished and removed from paymentQueue - Transactions.updates");
            }
            
        }
    }
    
    @available(iOS 15.0.0, *)
    private func finishTransactions() -> Task<Void, Error> {
        return Task.detached {

            //Iterate through any transactions that don't come from a direct call to `purchase()`.
            for await verification in Transaction.unfinished {
                
                guard let transaction: Transaction = self.checkVerified(verification)
                        as? Transaction else {
                    print("checkVerified failed");
                    return
                    
                };
            
                await transaction.finish();
                print("Transaction finished and removed from paymentQueue - transactions.unfinished");
            }
        }
    }

    @available(iOS 15.0.0, *)
    @objc public func getProductDetails(_ productIdentifier: String) async -> PluginCallResultData {
        print("[Subscriptions] getProductDetails llamado para: \(productIdentifier)")

        guard let product: Product = await getProduct(productIdentifier) as? Product else {
            print("[Subscriptions] ERROR: No se pudo obtener el producto '\(productIdentifier)'")
            return [
                "responseCode": 1,
                "responseMessage": "Could not find a product matching the given productIdentifier: \(productIdentifier). Please verify that the product ID is correct in App Store Connect and that the product is approved and active."
            ]
        };
        
        print("[Subscriptions] Producto obtenido exitosamente: \(productIdentifier)")
        
        let displayName = product.displayName;
        let description = product.description;
        let price = product.displayPrice;
        let productType = product.type;

        print("[Subscriptions] Detalles del producto - Nombre: \(displayName), Precio: \(price), Tipo: \(productType)")

        return [
            "responseCode": 0,
            "responseMessage": "Successfully found the product details for given productIdentifier",
            "data": [
                "productIdentifier": productIdentifier,
                "displayName": displayName,
                "description": description,
                "price": price,
                "type": String(describing: productType)
            ]
        ];
    }

    @available(iOS 15.0.0, *)
    @objc public func purchaseProduct(_ productIdentifier: String) async -> PluginCallResultData {
        
        do {

            guard let product: Product = await getProduct(productIdentifier) as? Product else {
                return [
                    "responseCode": 1,
                    "responseMessage": "Could not find a product matching the given productIdentifier"
                ];
            };
            let result: Product.PurchaseResult = try await product.purchase();

            switch result {

                case .success(let verification):

                    guard let transaction: Transaction = checkVerified(verification) as? Transaction else {
                        return [
                            "responseCode": 2,
                            "responseMessage": "Product seems to have been purchased but the transaction failed verification"
                        ];
                    };
            
                    await transaction.finish();
                    return [
                        "responseCode": 0,
                        "responseMessage": "Successfully purchased product"
                    ];

                case .userCancelled:

                    return [
                        "responseCode": 3,
                        "responseMessage": "User closed the native popover before purchasing"
                    ];

                case .pending:

                    return [
                        "responseCode": 4,
                        "responseMessage": "Product request made but is currently pending - likely due to parental restrictions"
                    ];

                default:

                    return [
                        "responseCode": 5,
                        "responseMessage": "An unknown error occurred whilst in the purchasing process",
                    ]
                    
            }
                
        } catch {
            print(error.localizedDescription);
            return [
                "responseCode": 5,
                "responseMessage": "An unknown error occurred whilst in the purchasing process"
            ]
        }

    }
    
    @available(iOS 15.0.0, *)
    @objc public func getCurrentEntitlements() async -> PluginCallResultData {

        do {
            
            var transactionDictionary = [String: [String: Any]]();
            
            //            Loop through each verification result in currentEntitlements, verify the transaction
            //            then add it to the transactionDictionary if verified.
            for await verification in Transaction.currentEntitlements {
                
                let transaction: Transaction? = checkVerified(verification) as? Transaction
                if(transaction != nil) {
                    
                    transactionDictionary[String(transaction!.id)] = [
                        "productIdentifier": transaction!.productID,
                        "originalStartDate": transaction!.originalPurchaseDate,
                        "originalId": transaction!.originalID,
                        "transactionId": transaction!.id,
                        "expiryDate": transaction!.expirationDate!,
                        "purchaseToken": ""
                    ]
                    
                }
                
            }
            
            //            If we have one or more entitlements in transactionDictionary
            //            we want the response to include it in the data property
            if(transactionDictionary.count > 0) {
                
                let response = [
                    "responseCode": 0,
                    "responseMessage": "Successfully found all entitlements across all product types",
                    "data": transactionDictionary
                ] as [String : Any]
                
                return response;
                
                //             Otherwise - no entitlements were found
            } else {
                return [
                    "responseCode": 1,
                    "responseMessage": "No entitlements were found",
                ]
            }
        
        }
    

    }

    @available(iOS 15.0.0, *)
    @objc public func getLatestTransaction(_ productIdentifier: String) async -> PluginCallResultData {

        do {
            guard let product: Product = await getProduct(productIdentifier) as? Product else {
                return [
                    "responseCode": 1,
                    "responseMessage": "Could not find a product matching the given productIdentifier"
                ]

            };
            
            guard let transaction: Transaction = checkVerified(await product.latestTransaction) as? Transaction else {
                // The user hasn't purchased this product.
                return [
                    "responseCode": 2,
                    "responseMessage": "No transaction for given productIdentifier, or it could not be verified"
                ]
            }
            
            print("expiration" + String(decoding: formatDate(transaction.expirationDate)!, as: UTF8.self))
            print("transaction.expirationDate", transaction.expirationDate!)
            print("transaction.originalID", transaction.originalID);
            
            var receiptString = "";
            
            if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
                FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {


                do {
                    let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
                    print("Receipt Data: ", receiptData)


                    receiptString = receiptData.base64EncodedString(options: [Data.Base64EncodingOptions.endLineWithCarriageReturn])
                    print("Receipt String: ", receiptString)


                    // Read receiptData.
                }
                catch { print("Couldn't read receipt data with error: " + error.localizedDescription) }
            }

            
            return [
                "responseCode": 0,
                "responseMessage": "Latest transaction found",
                "data": [
                    "productIdentifier": transaction.productID,
                    "originalStartDate": transaction.originalPurchaseDate,
                    "originalId": transaction.originalID,
                    "transactionId": transaction.id,
                    "expiryDate": transaction.expirationDate!,
                    "purchaseToken": receiptString
                ]
            ];
            
        }

    }

    @available(iOS 15.0.0, *)
    @objc public func manageSubscriptions() async {
        
        let manageTransactions: UIWindowScene
        await UIApplication.shared.open(URL(string: "https://apps.apple.com/account/subscriptions")!)
        
    }
    
    @available(iOS 15.0.0, *)
    @objc private func formatDate(_ date: Date?) -> Data? {
     
        let df = DateFormatter();
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return df.string(for: date)?.data(using: String.Encoding.utf8)!;
        
    }
    
    @available(iOS 15.0.0, *)
    @objc private func updateTrialDate(_ bid: String, _ formattedDate: Data?) {
        
        let keyChainUpdateParams: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: bid
        ]
        
        let keyChainUpdateValue: [String: Any] = [
            kSecValueData as String: formattedDate!
        ];
        
        let updateStatusCode = SecItemUpdate(keyChainUpdateParams as CFDictionary, keyChainUpdateValue as CFDictionary);
        let updateStatusMessage = SecCopyErrorMessageString(updateStatusCode, nil);
        
        print("updateStatusCode in SecItemUpdate", updateStatusCode);
        print("updateStatusMessage in SecItemUpdate", updateStatusMessage!);
        
    }

    @available(iOS 15.0.0, *)
    @objc private func getProduct(_ productIdentifier: String) async -> Any? {
        let maxRetries = 3
        let retryDelay: UInt64 = 500_000_000 // 0.5 segundos en nanosegundos
        
        for attempt in 1...maxRetries {
            do {
                print("[Subscriptions] Intentando obtener producto '\(productIdentifier)' (intento \(attempt)/\(maxRetries))")
                
                let products = try await Product.products(for: [productIdentifier])
                
                print("[Subscriptions] Product.products(for:) devolvió \(products.count) producto(s)")
                
                if products.count > 0 {
                    let product = products[0]
                    
                    // Verificar que el producto sea una suscripción
                    if product.type == .autoRenewable {
                        print("[Subscriptions] Producto encontrado: \(productIdentifier), tipo: autoRenewable, precio: \(product.displayPrice)")
                        return product
                    } else {
                        print("[Subscriptions] ADVERTENCIA: El producto '\(productIdentifier)' no es una suscripción auto-renovable. Tipo: \(product.type)")
                        // Aún así retornamos el producto por compatibilidad
                        return product
                    }
                } else {
                    print("[Subscriptions] ADVERTENCIA: Product.products(for:) devolvió un array vacío para '\(productIdentifier)'")
                    
                    // Si es el último intento, retornar nil
                    if attempt == maxRetries {
                        print("[Subscriptions] ERROR: No se pudo obtener el producto después de \(maxRetries) intentos")
                        return nil
                    }
                    
                    // Esperar antes de reintentar
                    print("[Subscriptions] Esperando \(retryDelay / 1_000_000)ms antes de reintentar...")
                    try await Task.sleep(nanoseconds: retryDelay)
                }
            } catch {
                let errorDescription = error.localizedDescription
                print("[Subscriptions] ERROR al obtener producto '\(productIdentifier)' (intento \(attempt)/\(maxRetries)): \(errorDescription)")
                
                // Si es un error específico de StoreKit, intentar obtener más detalles
                if let storeKitError = error as? StoreKitError {
                    print("[Subscriptions] StoreKitError: \(storeKitError)")
                }
                
                // Si es el último intento, retornar nil
                if attempt == maxRetries {
                    print("[Subscriptions] ERROR: Falló después de \(maxRetries) intentos. Último error: \(errorDescription)")
                    return nil
                }
                
                // Esperar antes de reintentar
                print("[Subscriptions] Esperando \(retryDelay / 1_000_000)ms antes de reintentar...")
                try? await Task.sleep(nanoseconds: retryDelay)
            }
        }
        
        return nil
    }

    @available(iOS 15.0.0, *)
    @objc private func checkVerified(_ vr: Any?) -> Any? {

        switch vr as? VerificationResult<Transaction> {
            case .verified(let safe):
                return safe
            case .unverified:
                return nil;
            default:
                return nil;
        }

    }

}
