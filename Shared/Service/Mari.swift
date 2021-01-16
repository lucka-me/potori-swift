//
//  Mari.swift
//  Potori
//
//  Created by Lucka on 1/1/2021.
//

import Foundation
import GTMAppAuth
import GoogleAPIClientForREST_Gmail

class Mari {
    
    enum ParserError: Error {
        case brokenMessage
    }
    
    typealias OnProgressCallback = (Double) -> Void
    typealias OnFinishedCallback = ([NominationRAW]) -> Void
    
    private static let userId = "me"
    
    private let gmailService = GTLRGmailService()
    private var progress = Progress()
    
    private var nominations: [NominationRAW] = []
    private var ignoreMailIds: [String] = []
    private var mailIds: [Umi.Status.Code : [Umi.Scanner.Code : [String]]] = [:]
    
    init() {
        gmailService.shouldFetchNextPages = true
    }
    
    func onProgress(_ onProgress: @escaping OnProgressCallback) {
        self.progress.onProgress = onProgress
    }
    
    func onFinished(_ onFinish: @escaping OnFinishedCallback) {
        self.progress.onFinished = {
            onFinish(self.nominations)
        }
    }
    
    func updateAuth(_ auth: GTMFetcherAuthorizationProtocol?) {
        gmailService.authorizer = auth
    }
    
    func start(_ withNominations: [NominationRAW]) {
        progress.clear()
        nominations = withNominations
        ignoreMailIds.removeAll()
        mailIds.removeAll()
        ignoreMailIds = self.nominations.flatMap {
            $0.resultMailId.isEmpty ? [$0.confirmationMailId] : [$0.confirmationMailId, $0.resultMailId]
        }
        for typePair in Umi.shared.status {
            self.mailIds[typePair.key] = [:]
            for queryPair in typePair.value.queries {
                self.mailIds[typePair.key]?[queryPair.key] = []
                self.queryList(typePair.key, queryPair.value)
            }
        }
    }
    
    private func queryList(_ forType: Umi.Status.Code, _ by: Umi.Status.Query) {
        progress.addList()
        let query = getListQuery(by.query, nil)
        gmailService.executeQuery(query) { callbackTicket, response, error in
            guard let solidResponse = response as? GTLRGmail_ListMessagesResponse else {
                self.queryMessages(forType, by)
                return
            }
            self.handleListQuery(solidResponse, forType, by)
        }
    }
    
    private func getListQuery(_ q: String, _ pageToken: String?) -> GTLRGmailQuery_UsersMessagesList {
        let query = GTLRGmailQuery_UsersMessagesList.query(withUserId: Mari.userId)
        query.q = q
        query.pageToken = pageToken
        return query
    }
    
    private func handleListQuery(
        _ fromResponse: GTLRGmail_ListMessagesResponse,
        _ forType: Umi.Status.Code,
        _ by: Umi.Status.Query
    ) {
        guard let solidMessages = fromResponse.messages, var list = mailIds[forType]?[by.scanner] else {
            queryMessages(forType, by)
            return
        }
        list.append(contentsOf: solidMessages.compactMap { $0.identifier })
        if let solidNextPageToken = fromResponse.nextPageToken {
            let query = getListQuery(by.query, solidNextPageToken)
            gmailService.executeQuery(query) { callbackTicket, response, error in
                guard let solidResponse = response as? GTLRGmail_ListMessagesResponse else {
                    self.queryMessages(forType, by)
                    return
                }
                self.handleListQuery(solidResponse, forType, by)
            }
        } else {
            mailIds[forType]?[by.scanner] = list.filter { id in
                !ignoreMailIds.contains(id)
            }
            queryMessages(forType, by)
        }
    }
    
    private func queryMessages(_ forType: Umi.Status.Code, _ by: Umi.Status.Query) {
        guard let list = mailIds[forType]?[by.scanner] else {
            progress.finishList(0)
            return
        }
        progress.finishList(list.count)
        for id in list {
            let query = GTLRGmailQuery_UsersMessagesGet.query(withUserId: Mari.userId, identifier: id)
            gmailService.executeQuery(query) { _, response, _ in
                guard let solidResponse = response as? GTLRGmail_Message else {
                    self.progress.finishMessage()
                    return
                }
                do {
                    let nomination = try self.parse(solidResponse, forType, by)
                    self.nominations.append(nomination)
                } catch ParserError.brokenMessage {
                    // Handle broken message
                } catch {
                    // Handle parser error
                }
                self.progress.finishMessage()
            }
        }
    }
    
    private func parse(_ mail: GTLRGmail_Message, _ forType: Umi.Status.Code, _ by: Umi.Status.Query) throws -> NominationRAW {
        let nomination = NominationRAW(forType, by.scanner)
        if forType == .pending {
            nomination.confirmationMailId = mail.identifier ?? ""
            nomination.confirmedTime = mail.internalDate?.uint64Value ?? 0
        } else {
            nomination.resultMailId = mail.identifier ?? ""
            nomination.resultTime = mail.internalDate?.uint64Value ?? 0
        }

        // Subject -> Title
        guard let headers = mail.payload?.headers else {
            throw ParserError.brokenMessage
        }
        for header in headers {
            guard header.name == "Subject", let subject = header.value else {
                continue
            }
            guard let titleRange = subject.range(of: "[:：].+$", options: .regularExpression) else {
                break
            }
            var title = subject[titleRange]
            title.removeFirst()
            nomination.title = String(title).trimmingCharacters(in: .whitespacesAndNewlines)
            break
        }
        
        // Body -> image, id lngLat and reason
        guard let parts = mail.payload?.parts else {
            throw ParserError.brokenMessage
        }
        for part in parts {
            guard part.partId == "1", let urlEncoded = part.body?.data else {
                continue
            }
            let encoded = urlEncoded
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
            guard let data = Data(base64Encoded: encoded, options: .ignoreUnknownCharacters) else {
                break
            }
            guard let body = String(data: data, encoding: .utf8) else {
                break
            }
            // Image
            if let imageRange = body.range(of: "googleusercontent\\.com\\/[0-9a-zA-Z\\-\\_]+", options: .regularExpression) {
                nomination.image = String(body[imageRange].replacingOccurrences(of: "googleusercontent.com/", with: ""))
                nomination.id = NominationRAW.generateId(nomination.image)
            }
            
            // LngLat
            if forType != .pending && by.scanner == .redacted {
                if let intelRange = body.range(of: "www\\.ingress\\.com/intel\\?ll\\=[\\d\\.\\,]+", options: .regularExpression) {
                    let pair = body[intelRange].replacingOccurrences(of: "www.ingress.com/intel?ll=", with: "").split(separator: ",")
                    if
                        let latString = pair.first,
                        let lat = Double(latString),
                        let lngString = pair.last,
                        let lng = Double(lngString) {
                        nomination.lngLat = LngLat(lng: lng, lat: lat)
                    }
                }
            }
            // Reason
            if forType == .rejected {
                if let reasonRange = body.range(of: "^(.|\n|\r)+\\-NianticOps", options: .regularExpression) {
                    var indexReasons: [String.Index : Int16] = [:]
                    for pair in Umi.shared.reason {
                        // Skip the old codes
                        if pair.key != pair.value.code {
                            continue
                        }
                        guard let keywords = pair.value.keywords[by.scanner] else {
                            continue
                        }
                        for keyword in keywords.keywords {
                            guard let range = body.range(of: keyword, options: .literal, range: reasonRange) else {
                                continue
                            }
                            indexReasons[range.lowerBound] = pair.key
                            break
                        }
                    }
                    nomination.reasons = indexReasons
                        .sorted { a, b in a.key < b.key }
                        .map { $0.value }
                }
            }
            break
        }
        return nomination
    }
}

fileprivate class ProgressItem {
    var total = 0
    var finished = 0
    
    func clear() {
        total = 0
        finished = 0
    }
    
    var left: Bool {
        return finished < total
    }
    
    var percent: Double {
        return total == 0 ? 0.0 : Double(finished) / Double(total)
    }
}

fileprivate class Progress {
    
    var onProgress: Mari.OnProgressCallback = { _ in }
    var onFinished: () -> Void = { }
    
    private var lists = ProgressItem()
    private var messages = ProgressItem()
    
    func clear() {
        lists.clear()
        messages.clear()
    }
    
    func addList() {
        lists.total += 1
        onProgress(percent)
    }
    
    func finishList(_ bringsMessages: Int) {
        lists.finished += 1
        messages.total += bringsMessages
        onProgress(percent)
        if !left {
            onFinished()
        }
    }
    
    func finishMessage() {
        messages.finished += 1
        onProgress(percent)
        if !left {
            onFinished()
        }
    }
    
    private var left: Bool {
        return lists.left || messages.left
    }
    
    private var percent: Double {
        if lists.total == 0 || messages.total == 0 {
            return 0.0
        }
        if lists.left {
            return lists.percent * 0.2
        }
        return 0.2 + messages.percent * 0.8
    }
}
