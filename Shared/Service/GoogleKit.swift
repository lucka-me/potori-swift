//
//  GoogleDriveKit.swift
//  Potori
//
//  Created by Lucka on 9/1/2021.
//

import AppAuth
import GTMAppAuth
import GoogleAPIClientForREST_Drive
import GoogleAPIClientForREST_Gmail

final class GoogleKit {
    
    final class Auth: ObservableObject {
        
        static let redirectURL = "com.googleusercontent.apps.361295761775-oa7u8sbbldvaq29c5gbg74ep906pqhd8:/oauthredirect"
        
        static let shared = Auth()
        
        private static let clientID = "361295761775-oa7u8sbbldvaq29c5gbg74ep906pqhd8.apps.googleusercontent.com"
        private static let authKeychainName = "auth.google"
        
        @Published var authorized: Bool = false
        
        private var authorization: GTMAppAuthFetcherAuthorization? = nil
        private var currentAuthorizationFlow: OIDExternalUserAgentSession? = nil
        
        private init() {
            loadAuth()
        }
        
        var mail: String {
            return authorization?.userEmail ?? ""
        }
        
        var authorizer: GTMAppAuthFetcherAuthorization? {
            return authorization
        }
        
        func link() {
            #if os(macOS)
            currentAuthorizationFlow = OIDAuthState.authState(
                byPresenting: getAuthRequest(),
                callback: authStateCallback
            )
            #elseif !EXTENSION
            currentAuthorizationFlow = OIDAuthState.authState(
                byPresenting: getAuthRequest(),
                presenting: UIApplication.shared.keyRootViewController!,
                callback: authStateCallback
            )
            #endif
        }
        
        #if os(macOS)
        func onOpenURL(_ url: URL) {
            currentAuthorizationFlow?.resumeExternalUserAgentFlow(with: url)
        }
        #endif
        
        func unlink() {
            authorization = nil
            saveAuth()
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
                authorized = solidAuth.authState.isAuthorized
                GTMAppAuthFetcherAuthorization.save(solidAuth, toSharedKeychainForName: Self.authKeychainName)
            } else {
                authorized = false
                GTMAppAuthFetcherAuthorization.removeFromSharedKeychain(forName: Self.authKeychainName)
            }
        }
        
        private func loadAuth() {
            authorization = GTMAppAuthFetcherAuthorization.fromSharedKeychain(forName: Self.authKeychainName)
            saveAuth()
        }
    }
    
    final class Drive {
        
        typealias DownloadCompletionHandler<Content: Decodable> = (Content?) -> Void
        
        static let shared = Drive()
        
        private let service = GTLRDriveService()
        private var fileID: [String : String] = [:]
        
        private static let folder = "appDataFolder"
        
        private init() {
            service.shouldFetchNextPages = true
        }
        
        func updateAuth(_ auth: GTMFetcherAuthorizationProtocol?) {
            service.authorizer = auth
        }
        
        func download<Content: Decodable>(
            _ filename: String,
            completionHandler: @escaping DownloadCompletionHandler<Content>
        ) {
            if !Auth.shared.authorized {
                completionHandler(nil)
                return
            }
            service.authorizer = Auth.shared.authorizer
            queryList(with: .init(filename: filename, completionHandler: completionHandler))
        }
        
        func upload(_ data: Data, to filename: String, of mimeType: String) async throws {
            guard Auth.shared.authorized else {
                return
            }
            service.authorizer = Auth.shared.authorizer
            let fileObject = GTLRDrive_File()
            fileObject.name = filename
            let parameters = GTLRUploadParameters(data: data, mimeType: mimeType)
            let query: GTLRDriveQuery
            if let id = fileID[filename], !id.isEmpty {
                query = GTLRDriveQuery_FilesUpdate.query(withObject: fileObject, fileId: id, uploadParameters: parameters)
            } else {
                fileObject.parents = [ Drive.folder ]
                query = GTLRDriveQuery_FilesCreate.query(withObject: fileObject, uploadParameters: parameters)
            }
            let response = try await service.execute(query)
            fileID[filename] = (response as? GTLRDrive_File)?.identifier
        }
        
        private func queryList<Content: Decodable>(with pack: DownloadQueryPack<Content>, pageToken: String? = nil) {
            let query = GTLRDriveQuery_FilesList.query()
            query.q = "name = '\(pack.filename)'"
            query.spaces = Self.folder
            query.fields = "files(id)"
            service.executeQuery(query) { _, response, error in
                guard
                    let solidResponse = response as? GTLRDrive_FileList,
                    let solidFiles = solidResponse.files
                else {
                    self.queryFiles(with: pack)
                    return
                }
                pack.ids.append(contentsOf: solidFiles.compactMap { $0.identifier })
                guard let nextPageToken = solidResponse.nextPageToken else {
                    self.queryFiles(with: pack)
                    return
                }
                self.queryList(with: pack, pageToken: nextPageToken)
            }
        }
        
        private func queryFiles<Content: Decodable>(with pack: DownloadQueryPack<Content>) {
            guard let id = pack.ids.popFirst() else {
                pack.completionHandler(nil)
                return;
            }
            let query = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: id)
            service.executeQuery(query) { _, response, error in
                let decoder = JSONDecoder()
                guard
                    let solidData = response as? GTLRDataObject,
                    let content = try? decoder.decode(Content.self, from: solidData.data)
                else {
                    self.service.executeQuery(GTLRDriveQuery_FilesDelete.query(withFileId: id))
                    self.queryFiles(with: pack)
                    return
                }
                self.fileID[pack.filename] = id
                pack.completionHandler(content)
            }
        }
    }
    
    private init() {
        
    }
}

private class DownloadQueryPack<Content: Decodable> {
    
    var ids: [ String ] = []
    let filename: String
    let completionHandler: GoogleKit.Drive.DownloadCompletionHandler<Content>
    
    init(
        filename: String,
        completionHandler: @escaping GoogleKit.Drive.DownloadCompletionHandler<Content>
    ) {
        self.filename = filename
        self.completionHandler = completionHandler
    }
}
