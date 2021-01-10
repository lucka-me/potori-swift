//
//  GoogleDriveKit.swift
//  Potori
//
//  Created by Lucka on 9/1/2021.
//

import Foundation
import GTMAppAuth
import GoogleAPIClientForREST_Drive

class GoogleDriveKit {
    
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
        query.spaces = GoogleDriveKit.folder
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
            fileObject.parents = [ GoogleDriveKit.folder ]
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
