//
//  Mari.swift
//  Potori
//
//  Created by Lucka on 1/1/2021.
//

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
    
    func start(with nominations: [ NominationRAW ], completionHandler: @escaping CompletionHandler) -> Bool {
        // Check if is processing
        if progress.left {
            return false
        }
        // Check auth
        if !GoogleKit.Auth.shared.authorized {
            return false
        }
        gmailService.authorizer = GoogleKit.Auth.shared.authorizer

        progress.clear()
        progress.onFinished = {
            self.progress.onFinished = { }
            completionHandler(self.nominations)
        }
        self.nominations = nominations
        ignoreMailIds.removeAll()
        ignoreMailIds = nominations.flatMap {
            $0.resultMailId.isEmpty ? [$0.confirmationMailId] : [$0.confirmationMailId, $0.resultMailId]
        }
        if UserDefaults.General.queryAfterLatest {
            latest = nominations.reduce(0) { max($0, $1.confirmedTime, $1.resultTime) }
        } else {
            latest = 0
        }
        for status in Umi.shared.statusAll {
            for queryPair in status.queries {
                self.queryList(with: .init(for: status, by: queryPair.value))
            }
        }
        return true
    }
    
    private func queryList(with pack: QueryPack, pageToken: String? = nil) {
        progress.addList()
        let query = GTLRGmailQuery_UsersMessagesList.query(withUserId: Self.userId)
        query.q = "\(pack.query.query)\(latest > 0 ? " after:\(latest)" : "")"
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
                    let nomination = try Parser.parse(solidResponse, for: pack.status.code, by: pack.query.scanner)
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
    let query: Umi.Status.Query
    var ids: [ String ] = []
    
    init(for status: Umi.Status, by query: Umi.Status.Query) {
        self.status = status
        self.query = query
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
        ProgressInspector.shared.clear()
        lists.clear()
        messages.clear()
    }
    
    func addList() {
        lists.total += 1
        ProgressInspector.shared.set(total: lists.total)
    }
    
    func finishList(_ bringsMessages: Int) {
        lists.done += 1
        messages.total += bringsMessages
        ProgressInspector.shared.set(done: lists.done, total: lists.total)
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
    
    private static let titleInSubjectRegex = try! NSRegularExpression(pattern: "[:：](.+)")
    private static let titleInBodyRegex = try! NSRegularExpression(pattern: "\\– (?:The )?Pokémon GO.+(?:\\n|\\r|<\\/p>| )+<p>(.+?)<\\/p>(?:\\n|\\r)")
    private static let imageRegex = try! NSRegularExpression(pattern: "(?:googleusercontent|ggpht)\\.com\\/([0-9a-zA-Z\\-\\_]+)")
    private static let lngLatRegex = try! NSRegularExpression(pattern: "www\\.ingress\\.com/intel\\?ll\\=([\\.\\d]+),([\\.\\d]+)")
    private static let mainBodyRegex = try! NSRegularExpression(pattern: "^(:?\\n|\\r|.)+?\\-(:?NianticOps| Pokémon GO)")
    
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
        
        let nomination = NominationRAW(status, scanner)
        if status == .pending {
            nomination.confirmationMailId = id
            nomination.confirmedTime = date / 1000
            nomination.resultTime = nomination.confirmedTime
        } else {
            nomination.resultMailId = id
            nomination.resultTime = date / 1000
        }
        
        // Subject / Body -> Title
        if let title = subject.first(matches: Self.titleInSubjectRegex, at: 1)?.trimmingCharacters(in: .whitespacesAndNewlines) {
            nomination.title = title
        } else if scanner == .go, let title = body.first(matches: Self.titleInBodyRegex, at: 1) {
            nomination.title = .init(title)
        }
        
        // Body -> image, id lngLat and reason
        // Image and ID
        if let image = body.first(matches: Self.imageRegex, at: 1) {
            nomination.image = .init(image)
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
            let pair = body.first(matches: Self.lngLatRegex),
            pair.count > 2,
            let latString = pair[1],
            let lngString = pair[2],
            let lat = Double(latString),
            let lng = Double(lngString)
        else {
            return nil
        }
        return .init(lng: lng, lat: lat)
    }
    
    private static func reasons(from body: String, by scanner: Umi.Scanner.Code) -> [ Umi.Reason.Code ] {
        guard let main = body.first(matches: Self.mainBodyRegex, at: 0) else {
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
