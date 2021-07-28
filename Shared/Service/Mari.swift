//
//  Mari.swift
//  Potori
//
//  Created by Lucka on 1/1/2021.
//

import GoogleAPIClientForREST_Gmail

class Mari {
    
    enum ErrorType: Error {
        case processing
    }
    
    static let shared = Mari()
    
    private static let userId = "me"
    
    private let service = GTLRGmailService()
    
    private var ignoreMailIds: [ String ] = []
    private var latest: UInt64 = 0
    
    private var data = DataContainer()
    private var progress = MariProgressInspector()
    
    private init() {
        service.shouldFetchNextPages = true
    }
    
    func start(with existings: [ NominationRAW ]) async throws -> [ NominationRAW ] {
        guard await !progress.left else {
            throw ErrorType.processing
        }
        guard GoogleKit.Auth.shared.authorized else {
            throw GTLRService.ErrorType.notAuthorized
        }
        service.authorizer = GoogleKit.Auth.shared.authorizer
        await progress.clear()
        await data.clear()
        ignoreMailIds = existings.flatMap {
            $0.resultMailId.isEmpty ? [$0.confirmationMailId] : [$0.confirmationMailId, $0.resultMailId]
        }
        if UserDefaults.General.queryAfterLatest {
            latest = existings.reduce(0) { max($0, $1.confirmedTime, $1.resultTime) }
        } else {
            latest = 0
        }
        await withTaskGroup(of: Void.self) { taskGroup in
            for status in Umi.shared.statusAll {
                for queryPair in status.queries {
                    taskGroup.addTask { [ self ] in
                        // TODO: Catch error
                        try? await query(for: status, by: queryPair.value)
                    }
                }
            }
        }
        return await data.read()
    }
    
    private func query(for status: Umi.Status, by queryData: Umi.Status.Query) async throws {
        await progress.addList()
        var ids: [ String ] = []
        var pageToken: String? = nil
        repeat {
            let query = GTLRGmailQuery_UsersMessagesList.query(withUserId: Self.userId)
            query.q = "\(queryData.query)\(latest > 0 ? " after:\(latest)" : "")"
            query.pageToken = pageToken
            let response: GTLRGmail_ListMessagesResponse = try await service.execute(query)
            guard let messages = response.messages else {
                break
            }
            let filtered = messages
                .compactMap { $0.identifier }
                .filter { !ignoreMailIds.contains($0) }
            ids.append(contentsOf: filtered)
            pageToken = response.nextPageToken
        } while pageToken != nil
        await progress.finishList(brings: ids.count)
        await withTaskGroup(of: Void.self) { taskGroup in
            for id in ids {
                taskGroup.addTask { [ self ] in
                    do {
                        let query = GTLRGmailQuery_UsersMessagesGet.query(withUserId: Self.userId, identifier: id)
                        let response: GTLRGmail_Message = try await service.execute(query)
                        let raw = try Parser.parse(response, for: status.code, by: queryData.scanner)
                        await data.add(raw)
                    } catch Parser.ErrorType.brokenMessage {
                        // Handle broken message
                    } catch Parser.ErrorType.invalidFormat {
                        // Handle invalid format
                    } catch {
                        // Handle parser error
                    }
                    await progress.finishMessage()
                }
            }
        }
    }
}

fileprivate actor DataContainer {
    private var raws: [ NominationRAW ] = []
    
    func clear() {
        raws.removeAll()
    }
    
    func read() -> [ NominationRAW ] {
        raws
    }
    
    func add(_ raw: NominationRAW) {
        raws.append(raw)
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

fileprivate actor MariProgressInspector {
    
    private let lists = ProgressItem()
    private let messages = ProgressItem()
    
    func clear() {
        ProgressInspector.shared.clear()
        lists.clear()
        messages.clear()
    }
    
    func addList() {
        lists.total += 1
        ProgressInspector.shared.set(total: lists.total)
    }
    
    func finishList(brings messages: Int) {
        lists.done += 1
        self.messages.total += messages
        ProgressInspector.shared.set(done: lists.done, total: lists.total)
    }
    
    func finishMessage() {
        messages.done += 1
        if !lists.left {
            ProgressInspector.shared.set(done: messages.done, total: messages.total)
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
