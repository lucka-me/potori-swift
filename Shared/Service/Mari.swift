//
//  Mari.swift
//  Potori
//
//  Created by Lucka on 1/1/2021.
//

import GTMAppAuth
import GoogleAPIClientForREST_Gmail

class Mari {
    
    typealias CompletionHandler = ([ NominationRAW ]) -> Void
    
    static let shared = Mari()
    
    private static let userId = "me"
    
    private let gmailService = GTLRGmailService()
    
    private var nominations: [ NominationRAW ] = []
    private var ignoreMailIds: [ String ] = []
    private var latest: UInt64 = 0
    
    private var progress = MariProgressInspector()
    
    private init() {
        gmailService.shouldFetchNextPages = true
    }
    
    func set(_ auth: GTMFetcherAuthorizationProtocol?) {
        gmailService.authorizer = auth
    }
    
    func start(with nominations: [ NominationRAW ], completionHandler: @escaping CompletionHandler) -> Bool {
        // Check if is processing
        if progress.left {
            return false
        }
        // Check auth
        guard
            let auth = gmailService.authorizer as? GTMAppAuthFetcherAuthorization,
            auth.canAuthorize() && auth.authState.isAuthorized
        else {
            return false
        }
        progress.clear()
        progress.onFinished = {
            progress.onFinished = { }
            completionHandler(self.nominations)
        }
        self.nominations = nominations
        ignoreMailIds.removeAll()
        ignoreMailIds = nominations.flatMap {
            $0.resultMailId.isEmpty ? [$0.confirmationMailId] : [$0.confirmationMailId, $0.resultMailId]
        }
        if Preferences.General.queryAfterLatest {
            latest = nominations.reduce(0) { max($0, $1.confirmedTime, $1.resultTime) }
        } else {
            latest = 0
        }
        for statusPair in Umi.shared.status {
            for queryPair in statusPair.value.queries {
                self.queryList(with: .init(for: statusPair.value, by: queryPair.key))
            }
        }
        return true
    }
    
    private func queryList(with pack: QueryPack, pageToken: String? = nil) {
        progress.addList()
        let query = GTLRGmailQuery_UsersMessagesList.query(withUserId: Self.userId)
        query.q = "\(pack.status.queries[pack.scanner]!.query)\(latest > 0 ? " after:\(latest)" : "")"
        query.pageToken = pageToken
        gmailService.executeQuery(query) { _, response, error in
            guard
                let solidResponse = response as? GTLRGmail_ListMessagesResponse,
                let solidMessages = solidResponse.messages
            else {
                self.queryMessages(with: pack)
                return
            }
            pack.ids.append(contentsOf: solidMessages.compactMap { $0.identifier })
            guard let nextPageToken = solidResponse.nextPageToken else {
                self.queryMessages(with: pack)
                return
            }
            self.queryList(with: pack, pageToken: nextPageToken)
        }
    }
    
    private func queryMessages(with pack: QueryPack) {
        pack.ids.removeAll { ignoreMailIds.contains($0) }
        progress.finishList(pack.ids.count)
        for id in pack.ids {
            let query = GTLRGmailQuery_UsersMessagesGet.query(withUserId: Self.userId, identifier: id)
            gmailService.executeQuery(query) { _, response, _ in
                guard let solidResponse = response as? GTLRGmail_Message else {
                    self.progress.finishMessage()
                    return
                }
                do {
                    let nomination = try Parser.parse(solidResponse, for: pack.status.code, by: pack.scanner)
                    self.nominations.append(nomination)
                } catch Parser.ErrorType.brokenMessage {
                    // Handle broken message
                } catch Parser.ErrorType.invalidFormat {
                    // Handle invalid format
                } catch {
                    // Handle parser error
                }
                self.progress.finishMessage()
            }
        }
    }
}

fileprivate class QueryPack {
    let status: Umi.Status
    let scanner: Umi.Scanner.Code
    var ids: [ String ] = []
    
    init(for status: Umi.Status, by scanner: Umi.Scanner.Code) {
        self.status = status
        self.scanner = scanner
    }
}

fileprivate class ProgressItem {
    var total = 0
    var done = 0
    
    func clear() {
        total = 0
        done = 0
    }
    
    var left: Bool {
        return done < total
    }
}

fileprivate class MariProgressInspector {
    
    var onFinished: () -> Void = { }
    
    private var lists = ProgressItem()
    private var messages = ProgressItem()
    
    func clear() {
        lists.clear()
        messages.clear()
    }
    
    func addList() {
        lists.total += 1
        // Report progress
    }
    
    func finishList(_ bringsMessages: Int) {
        lists.done += 1
        messages.total += bringsMessages
        // Report progress
        if !left {
            onFinished()
        }
    }
    
    func finishMessage() {
        messages.done += 1
        if !lists.left {
            ProgressInspector.shared.set(done: messages.done, total: messages.total)
        }
        if !left {
            onFinished()
        }
    }
    
    var left: Bool {
        return lists.left || messages.left
    }
}

fileprivate class Parser {
    
    enum ErrorType: Error {
        case brokenMessage
        case invalidFormat
    }
    
    static func parse(
        _ mail: GTLRGmail_Message,
        for status: Umi.Status.Code,
        by scanner: Umi.Scanner.Code
    ) throws -> NominationRAW {
        // Check contents
        guard
            let id = mail.identifier,
            let date = mail.internalDate?.uint64Value,
            let subject = mail.payload?.headers?.first(where: { $0.name == "Subject" })?.value,
            let rawBody = mail.payload?.parts?.first(where: { $0.partId == "1" })?.body?.data,
            let body = String(base64Encoded: rawBody)
        else {
            throw ErrorType.brokenMessage
        }
        
        guard
            var title = subject.subString(of: "[:：].+$", options: .regularExpression)
        else {
            throw ErrorType.invalidFormat
        }
        
        let nomination = NominationRAW(status, scanner)
        if status == .pending {
            nomination.confirmationMailId = id
            nomination.confirmedTime = date / 1000
            nomination.resultTime = nomination.confirmedTime
        } else {
            nomination.resultMailId = id
            nomination.resultTime = date / 1000
        }

        // Subject -> Title
        nomination.title = title.removingFirst().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Body -> image, id lngLat and reason
        // Image
        if let imageRange = body.range(of: "(googleusercontent|ggpht)\\.com\\/[0-9a-zA-Z\\-\\_]+", options: .regularExpression) {
            nomination.image = body[imageRange].replacingOccurrences(
                of: "(googleusercontent|ggpht)\\.com\\/", with: "",
                options: .regularExpression
            )
            nomination.id = NominationRAW.generateId(nomination.image)
        }
        
        // LngLat
        if status != .pending && scanner == .redacted {
            nomination.lngLat = Self.lngLat(from: body)
        }
        // Reason
        if status == .rejected {
            nomination.reasons = Self.reasons(from: body, by: scanner)
        }
        return nomination
    }
    
    private static func lngLat(from body: String) -> LngLat? {
        guard
            let pair = body
                .subString(of: "www\\.ingress\\.com/intel\\?ll\\=[\\d\\.\\,]+", options: .regularExpression)?
                .replacingOccurrences(of: "www.ingress.com/intel?ll=", with: "")
                .split(separator: ","),
            let latString = pair.first,
            let lngString = pair.last,
            let lat = Double(latString),
            let lng = Double(lngString)
        else {
            return nil
        }
        return .init(lng: lng, lat: lat)
    }
    
    private static func reasons(from body: String, by scanner: Umi.Scanner.Code) -> [ Umi.Reason.Code ] {
        guard let main = body.subString(of: "^(.|\n|\r)+\\-NianticOps", options: .regularExpression) else {
            return []
        }
        var dictionary: [String.Index : Umi.Reason.Code] = [:]
        for reason in Umi.shared.reasonAll {
            guard let keywords = reason.keywords[scanner] else {
                continue
            }
            for keyword in keywords.keywords {
                guard let range = main.range(of: keyword, options: .literal) else {
                    continue
                }
                dictionary[range.lowerBound] = reason.code
                break
            }
        }
        return dictionary
            .sorted { a, b in a.key < b.key }
            .map { $0.value }
    }
}
