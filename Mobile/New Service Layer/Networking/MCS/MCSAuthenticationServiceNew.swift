//
//  MCSAuthenticationServiceNew.swift
//  Networking
//
//  Created by Joseph Erlandson on 11/20/19.
//  Copyright © 2019 Exelon Corp. All rights reserved.
//

//import Foundation
//import Model
//
//// MOVE TO A DIF FILE
//
//
///// The AuthenticationService protocol defines the interface necessary
///// to deal with authentication related service routines such as
///// login/logout.
//protocol AuthenticationService {
//    
//    #if os(iOS)
//    /// Authenticate a user with the supplied credentials.
//    ///
//    /// - Parameters:
//    ///   - username: the username to authenticate with.
//    ///   - password: the password to authenticate with.
//    func login(username: String, password: String, stayLoggedIn: Bool)
//    
//    /// Validate login credentials
//    ///
//    /// - Parameters:
//    ///   - username: the suername to authenticate with.
//    ///   - password: the password to authenticate with.
//    func validateLogin(username: String, password: String)
//    #endif
//    
//    /// Check if the user is authenticated
//    var isAuthenticated: Bool { get }
//    
//    /// Log out the currently logged in user
//    ///
//    /// Note that this operation can and should have the side effect of removing
//    /// any cached information related to the user, either in memory or on disk.
//    func logout()
//    
//}
//
//// THIS FILE
//
//import Model
//
//private enum OAuthQueryParams: String {
//    case username = "username"
//    case password = "password"
//    case encode = "encode"
//}
//
//private enum ChangePasswordParams: String {
//    case oldPassword = "old_password"
//    case newPassword = "new_password"
//}
//
//private enum AnonChangePasswordParams: String {
//    case username = "username"
//    case oldPassword = "old_password"
//    case newPassword = "new_password"
//}
//
//fileprivate extension CharacterSet {
//    static let rfc3986Unreserved = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
//}
//
//struct MCSAuthenticationServiceNew: AuthenticationService {
//    func login(username: String, password: String, stayLoggedIn: Bool) {
//        // Fetch Auth Token
//        let dataString = "username=\("COMED")\\\(username)&password=\(password)" // Environment.shared.opco.rawValue.uppercased()
//        let httpBody = dataString.data(using: .utf8)
//        
//        ServiceLayer.request(router: .fetchToken(httpBody: httpBody)) { (result: Result<Data, Error>) in
//            switch result {
//            case .success(let authToken):
//                print("Success AUTH TOKEN: \(authToken)")
//
//                            let jsonDecoder = JSONDecoder()
//                            jsonDecoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
//
//                            do {
//                                // 6.
//                                let responseObject = try jsonDecoder.decode(AuthToken.self, from: authToken)
//                                print("respo: \(responseObject.data.profileType)")
//                                
//                                print("respo: \(responseObject.data.custProfile.customerProfile.name)")
//                            } catch let error {
//                                print(error.localizedDescription)
//                            }
//            case .failure(let error):
//                print("FAILURE AUTH TOKEN: \(error)")
//            }
//        }
//        
//        // Parse Auth Token
//        
//        // Exchange Auth Token
//        
//        // NOW WE PASS BACK TO MAIN APP if login is successful or if there was a network error or parsing error ect...
//    }
//    
//    private func fetchAuthToken() {
//        
//    }
//    
//    private func parseAuthToken() {
//        
//    }
//    
//    private func exchangeAuthToken() {
//        
//    }
//    
//    
//    func validateLogin(username: String, password: String) {
//        // todo
//    }
//    
//    var isAuthenticated: Bool {
//        // todo
//        
////        if accessToken == nil {
////            #if os(iOS)
////            accessToken = tokenKeychain.string(forKey: TOKEN_KEYCHAIN_KEY)
////            #elseif watchOS
////            accessToken = tokenKeychain["authToken"]
////            #endif
////        }
////        return accessToken != nil
//        
//        return false
//    }
//    
//    func logout() {
//        // todo
//    }
//    
//}
//
//private extension DateFormatter {
//  static let iso8601Full: DateFormatter = {
//    let formatter = DateFormatter()
//    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
////    formatter.calendar = Calendar(identifier: .iso8601)
////    formatter.timeZone = TimeZone(secondsFromGMT: 0)
////    formatter.locale = Locale(identifier: "en_US_POSIX")
//    return formatter
//  }()
//}
