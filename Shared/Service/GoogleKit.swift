//
//  GoogleDriveKit.swift
//  Potori
//
//  Created by Lucka on 9/1/2021.
//

import Combine
import Foundation

import AppAuth
import GTMAppAuth
import GoogleAPIClientForREST_Drive
import GoogleAPIClientForREST_Gmail

final class GoogleKit: ObservableObject {
    
    final class Auth: ObservableObject {
        
        @Published var login: Bool = false
        
        private static let clientID = "361295761775-oa7u8sbbldvaq29c5gbg74ep906pqhd8.apps.googleusercontent.com"
        private static let redirectURL = "com.googleusercontent.apps.361295761775-oa7u8sbbldvaq29c5gbg74ep906pqhd8:/oauthredirect"
        private static let authKeychainName = "auth.google"
        
        private var authorization: GTMAppAuthFetcherAuthorization? = nil
        private var currentAuthorizationFlow: OIDExternalUserAgentSession? = nil
        
        init() {
            loadAuth()
        }
        
       
        func logIn() {
            #if os(macOS)
            currentAuthorizationFlow = OIDAuthState.authState(
                byPresenting: getAuthRequest(),
                callback: authStateCallback
            )
            #else
            currentAuthorizationFlow = OIDAuthState.authState(
                byPresenting: getAuthRequest(),
                presenting: UIApplication.shared.windows.first!.rootViewController!,
                callback: authStateCallback
            )
            #endif
        }
        
        #if os(macOS)
        func onOpenURL(_ url: URL) {
            currentAuthorizationFlow?.resumeExternalUserAgentFlow(with: url)
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
        
        private func getAuthRequest() -> OIDAuthorizationRequest {
            return OIDAuthorizationRequest.init(
                configuration: GTMAppAuthFetcherAuthorization.configurationForGoogle(),
                clientId: Self.clientID,
                scopes: [
                    OIDScopeEmail,
                    kGTLRAuthScopeDriveAppdata,
                    kGTLRAuthScopeDriveFile,
                    kGTLRAuthScopeGmailReadonly
                ],
                redirectURL: URL(string: Self.redirectURL)!,
                responseType: OIDResponseTypeCode,
                additionalParameters: nil
            )
        }
        
        private func authStateCallback(authState: OIDAuthState?, error: Error?) {
            if let solidAuthState = authState {
                #if os(iOS)
                self.currentAuthorizationFlow = nil
                #endif
                self.authorization = GTMAppAuthFetcherAuthorization(authState: solidAuthState)
                self.saveAuth()
            } else {
                // Handle error
            }
        }
        
        private func saveAuth() {
            if let solidAuth = authorization, solidAuth.canAuthorize() {
                login = solidAuth.authState.isAuthorized
                GTMAppAuthFetcherAuthorization.save(solidAuth, toKeychainForName: Self.authKeychainName)
            } else {
                login = false
                GTMAppAuthFetcherAuthorization.removeFromKeychain(forName: Self.authKeychainName)
            }
        }
        
        private func loadAuth() {
            authorization = GTMAppAuthFetcherAuthorization(fromKeychainForName: Self.authKeychainName)
            saveAuth()
        }
    }
    
    final class Drive {
        
        typealias DownloadCallback = (Data?) -> Bool
        typealias UploadCallback = () -> Void
        
        private let driveService = GTLRDriveService()
        private var fileID: [String : String] = [:]
        
        private static let folder = "appDataFolder"
        
        init() {
            driveService.shouldFetchNextPages = true
        }
        
        func updateAuth(_ auth: GTMFetcherAuthorizationProtocol?) {
            driveService.authorizer = auth
        }
        
        func download(_ file: String, _ callback: @escaping DownloadCallback) {
            let listQuery = getListQuery(file)
            driveService.executeQuery(listQuery) { callbackTicket, response, error in
                guard let solidList = response as? GTLRDrive_FileList else {
                    let _ = callback(nil)
                    return
                }
                self.handleListQuery(solidList, file, callback)
            }
        }
        
        private func getListQuery(_ file: String) -> GTLRDriveQuery_FilesList {
            let query = GTLRDriveQuery_FilesList.query()
            query.q = "name = '\(file)'"
            query.spaces = Drive.folder
            query.fields = "files(id)"
            return query
        }
        
        private func handleListQuery(_ list: GTLRDrive_FileList, _ file: String, _ callback: @escaping DownloadCallback) {
            guard
                let solidFiles = list.files,
                !solidFiles.isEmpty,
                let id = solidFiles[0].identifier
            else {
                let _ = callback(nil)
                return
            }
            let query = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: id)
            driveService.executeQuery(query) { callbackTicket, response, error in
                var shouldContinue = false
                if let solidData = response as? GTLRDataObject {
                    shouldContinue = callback(solidData.data)
                } else {
                    shouldContinue = true
                }
                if shouldContinue {
                    self.delete(id)
                    let shifted = list
                    shifted.files = Array(solidFiles.suffix(from: 1))
                    self.handleListQuery(shifted, file, callback)
                }
            }
        }
        
        func upload(_ data: Data, _ mimeType: String, _ file: String, _ callback: @escaping UploadCallback) {
            let fileObject = GTLRDrive_File()
            fileObject.name = file
            let parameters = GTLRUploadParameters(data: data, mimeType: mimeType)
            let query: GTLRDriveQuery
            if let id = fileID[file], !id.isEmpty {
                query = GTLRDriveQuery_FilesUpdate.query(withObject: fileObject, fileId: id, uploadParameters: parameters)
            } else {
                fileObject.parents = [ Drive.folder ]
                query = GTLRDriveQuery_FilesCreate.query(withObject: fileObject, uploadParameters: parameters)
            }
            driveService.executeQuery(query) { callbackTicket, response, error in
                if
                    let solidFile = response as? GTLRDrive_File,
                    let solidId = solidFile.identifier {
                    self.fileID[file] = solidId
                } else {
                    self.fileID[file] = nil
                }
                callback()
            }
        }
        
        private func delete(_ id: String) {
            driveService.executeQuery(GTLRDriveQuery_FilesDelete.query(withFileId: id))
        }
    }
    
    let auth = Auth()
    let drive = Drive()
    
    private var authAnyCancellable: AnyCancellable? = nil
    
    init() {
        authAnyCancellable = auth.objectWillChange.sink {
            self.drive.updateAuth(self.auth.auth)
            self.objectWillChange.send()
        }
    }
}
