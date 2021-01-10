//
//  AuthKit.swift
//  Potori
//
//  Created by Lucka on 1/1/2021.
//

import Foundation

import AppAuth
import GTMAppAuth
import GoogleAPIClientForREST_Drive
import GoogleAPIClientForREST_Gmail

class AuthKit: ObservableObject {
    
    @Published var login: Bool = false
    
    private let clientID = "361295761775-oa7u8sbbldvaq29c5gbg74ep906pqhd8.apps.googleusercontent.com"
    private let redirectURL = "com.googleusercontent.apps.361295761775-oa7u8sbbldvaq29c5gbg74ep906pqhd8:/oauthredirect"
    private let authKeychainName = "auth.google"
    
    private var authorization: GTMAppAuthFetcherAuthorization? = nil
    
    init() {
        loadAuth()
    }
    
    #if os(macOS)
    func logIn() {
        // Listen to HTTP for redirect
        let httpHandler = OIDRedirectHTTPHandler(successURL: URL(string: redirectURL))
        let listenerURL = httpHandler.startHTTPListener(nil)
        httpHandler.currentAuthorizationFlow = OIDAuthState.authState(
            byPresenting: getAuthRequest(redirectURL: listenerURL)
        ) { authState, error in
            httpHandler.cancelHTTPListener()
            self.authStateCallback(authState: authState, error: error)
        }
    }
    #else
    func logIn(appDelegate: AppDelegate) {
        appDelegate.currentAuthorizationFlow = OIDAuthState.authState(
            byPresenting: getAuthRequest(),
            presenting: UIApplication.shared.windows.last!.rootViewController!,
            callback: authStateCallback
        )
    }
    #endif
    
    func logOut() {
        authorization = nil
        saveAuth()
    }
    
    var mail: String {
        return authorization?.userEmail ?? ""
    }
    
    var auth: GTMAppAuthFetcherAuthorization? {
        return authorization
    }
    
    private func getAuthRequest(redirectURL: URL? = nil) -> OIDAuthorizationRequest {
        return OIDAuthorizationRequest.init(
            configuration: GTMAppAuthFetcherAuthorization.configurationForGoogle(),
            clientId: clientID,
            scopes: [
                OIDScopeEmail,
                kGTLRAuthScopeDriveAppdata,
                kGTLRAuthScopeDriveFile,
                kGTLRAuthScopeGmailReadonly
            ],
            redirectURL: redirectURL ?? URL(string: self.redirectURL)!,
            responseType: OIDResponseTypeCode,
            additionalParameters: nil
        )
    }
    
    private func authStateCallback(authState: OIDAuthState?, error: Error?) {
        if let solidAuthState = authState {
            self.authorization = GTMAppAuthFetcherAuthorization(authState: solidAuthState)
            self.saveAuth()
        } else {
            // Handle error
        }
    }
    
    private func saveAuth() {
        if let solidAuth = authorization, solidAuth.canAuthorize() {
            login = solidAuth.authState.isAuthorized
            GTMAppAuthFetcherAuthorization.save(solidAuth, toKeychainForName: authKeychainName)
        } else {
            login = false
            GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: authKeychainName)
        }
    }
    
    private func loadAuth() {
        authorization = GTMAppAuthFetcherAuthorization(fromKeychainForName: authKeychainName)
        saveAuth()
    }
}
