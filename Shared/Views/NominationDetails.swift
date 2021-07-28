//
//  NominationDetails.swift
//  Potori
//
//  Created by Lucka on 29/12/2020.
//

import SwiftUI
import MapKit

struct NominationDetails: View {
    
    private enum Mode {
        case view
        case edit
    }
    
    static private let radius: CGFloat = 12
    
    let nomination: Nomination
    
    @Environment(\.openURL) private var openURL
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    @EnvironmentObject private var alert: AlertInspector
    @EnvironmentObject private var dia: Dia
    @State private var mode: Mode = .view
    @ObservedObject private var editorModel = EditorModel()
    
    var body: some View {
        if nomination.isFault {
            // Prevent crash when delete
            EmptyView()
        } else {
            #if os(macOS)
            content.frame(minWidth: 480)
            #else
            content
            #endif
        }
    }
    
    @ViewBuilder
    private var content: some View {
        Group {
            if mode == .view {
                viewer
            } else {
                editor
            }
        }
        .navigationTitle(nomination.title)
        .animation(.easeInOut, value: mode)
    }
    
    @ViewBuilder
    private var viewer: some View {
        List {
            Group {
                image
                actions
                highlights
                if nomination.statusCode == .rejected {
                    reasons
                }
                if nomination.hasLngLat {
                    FusionMap(nomination)
                        .frame(height: 200)
                        .mask {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                        }
                }
            }
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .toolbar {
            viewerControls
        }
    }
    
    @ViewBuilder
    private var viewerControls: some View {
        ControlGroup {
            Button {
                editorModel.set(from: nomination)
                mode = .edit
            } label: {
                Label("view.details.edit", systemImage: "pencil")
            }
        }
    }
    
    @ViewBuilder
    private var image: some View {
        HStack {
            AsyncImage(url: nomination.imageURL)
                .scaledToFit()
                .mask {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                }
                .frame(idealWidth: .infinity, maxHeight: 300, alignment: .center)
                .contextMenu {
                    if let url = URL(string: nomination.imageURL) {
                        Button {
                            openURL(url)
                        } label: {
                            Label("action.open", systemImage: "safari")
                        }
                        Button(role: nil, action: shareImage) {
                            #if os(macOS)
                            Label("view.details.image.copy", systemImage: "doc.on.doc")
                            #else
                            Label("view.details.image.share", systemImage: "square.and.arrow.up")
                            #endif
                        }
                    }
                }
                .appendSpacers()
        }
    }
    
    @ViewBuilder
    private var actions: some View {
        HStack {
            Spacer(minLength: 0)
            if nomination.hasLngLat {
                Button{
                    openURL(nomination.intelURL)
                } label: {
                    Label("view.details.action.intel", systemImage: "map")
                }
            }
            if !Brainstorming.isBeforeEpoch(when: nomination.resultTime, status: nomination.statusCode) {
                Button {
                    openURL(nomination.brainstormingURL)
                } label: {
                    Label("view.details.action.brainstorming", systemImage: "brain")
                }
            }
            Spacer(minLength: 0)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.bordered)
        .controlSize(.large)
    }
    
    @ViewBuilder
    private var highlights: some View {
        LazyVGrid(
            columns: .init(repeating: .init(.flexible(), alignment: .top), count: highlightsColumns),
            alignment: .center
        ) {
            HighlightCard(
                "view.details.confirmed", "arrow.up.circle", .accentColor,
                Text(nomination.confirmedTime, style: .date)
            )
            let status = nomination.statusData
            HighlightCard(
                status.title, status.icon, status.color,
                status.code == .pending ? Text(status.title) : Text(nomination.resultTime, style: .date)
            )
            HighlightCard(
                "view.details.scanner", "apps.iphone", .purple,
                Text(nomination.scannerData.title)
            )
        }
    }
    
    @ViewBuilder
    private var reasons: some View {
        Text("view.details.reasons")
            .font(.headline)
        LazyVGrid(
            columns: .init(repeating: .init(.flexible(), alignment: .top), count: reasonsColumns),
            alignment: .leading
        ) {
            if nomination.reasons.count > 0 {
                ForEach(nomination.reasonsData) { reason in
                    ReasonCard(reason)
                }
            } else {
                ReasonCard(Umi.shared.reason[Umi.Reason.undeclared]!)
            }
        }
    }
    
    @ViewBuilder
    private var editor: some View {
        Form {
            Section {
                HStack {
                    Label("view.details.confirmed", systemImage: "arrow.up.circle")
                    Spacer()
                    Text(nomination.confirmedTime, style: .date)
                }
                Picker(
                    selection: $editorModel.status,
                    label: Label("view.details.status", systemImage: "pencil.circle")
                ) {
                    ForEach(Umi.shared.statusAll) { status in
                        Text(status.title).tag(status.code)
                    }
                }
                .pickerStyle(.segmented)
                if editorModel.status != .pending {
                    DatePicker(
                        selection: $editorModel.resultTime,
                        in: PartialRangeFrom(nomination.confirmedTime),
                        displayedComponents: [ .date, .hourAndMinute ]
                    ) {
                        Label("view.details.resulted", systemImage: "pencil.circle")
                    }
                    .datePickerStyle(.automatic)
                }
            } header: {
                Text("view.details.hightlights")
            }
            if editorModel.status == .rejected {
                Section {
                    reasonsEditor
                } header: {
                    Text("view.details.reasons")
                }
            }
            Section {
                locationEditor
            } header: {
                Text("view.details.location")
            }
        }
        .toolbar {
            editorControls
        }
    }
    
    @ViewBuilder
    private var editorControls: some View {
        ControlGroup {
            Button {
                editorModel.save(to: nomination)
                dia.save()
                mode = .view
            } label: {
                Label("view.details.save", systemImage: "checkmark")
            }
            Button {
                mode = .view
            } label: {
                Label("view.details.cancel", systemImage: "xmark")
            }
            .keyboardShortcut(.cancelAction)
        }
    }
    
    @ViewBuilder
    private var reasonsEditor: some View {
        ForEach($editorModel.reasons) { $reason in
            Toggle(isOn: $reason.selected) {
                Label(reason.data.title, systemImage: reason.data.icon)
            }
        }
    }
    
    @ViewBuilder
    private var locationEditor: some View {
        TextField(
            value: $editorModel.lngLat,
            formatter: LngLatFormatter(),
            prompt: Text("view.details.location.coordinates.hint")
        ) {
            Label("view.details.location.coordinates", systemImage: "mappin.and.ellipse")
        }
            .textFieldStyle(.roundedBorder)
        Button(action: setLngLatFromPasteboard) {
            Label("view.details.location.paste", systemImage: "doc.on.clipboard")
        }
        if !Brainstorming.isBeforeEpoch(when: editorModel.resultTime, status: editorModel.status) {
            Button(action: queryLngLatFromBrainstorming) {
                Label("view.details.location.brainstorming", systemImage: "brain")
            }
        }
    }
    
    private var highlightsColumns: Int {
        #if os(macOS)
        return 3
        #else
        return horizontalSizeClass == .compact ? 2 : 3
        #endif
    }
    
    private var reasonsColumns: Int {
        #if os(macOS)
        return 4
        #else
        return horizontalSizeClass == .compact ? 2 : 4
        #endif
    }
    
    private func shareImage() {
        guard
            let url = URL(string: nomination.imageURL),
            let data = try? Data(contentsOf: url),
            let image = UNImage(data: data)
        else {
            return
        }
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setData(image.tiffRepresentation, forType: .tiff)
        #else
        let shareSheet = UIActivityViewController(
            activityItems: [ image ], applicationActivities: nil
        )
        DispatchQueue.main.async {
            UIApplication.shared.keyRootViewController?.present(
                shareSheet, animated: true, completion: nil
            )
        }
        #endif
    }
    
    private func setLngLatFromPasteboard() {
        #if os(iOS)
        guard UNPasteboard.general.hasStrings else {
            alert.push(title: "view.details.location.paste.empty")
            return
        }
        #endif
        guard let url = UNPasteboard.general.string else {
            alert.push(title: "view.details.location.paste.empty")
            return
        }
        if !editorModel.setLngLat(from: url) {
            alert.push(
                title: "view.details.location.paste.invalid",
                message: "view.details.location.paste.invalid.desc"
            )
        }
    }
    
    private func queryLngLatFromBrainstorming() {
        Task.init {
            let record: Brainstorming.Record
            do {
                record = try await Brainstorming.shared.query(nomination.id)
                guard mode == .edit else {
                    return
                }
            } catch Brainstorming.ErrorType.notFound {
                alert.push(
                    title: "view.details.location.brainstorming.failed",
                    message: "view.details.location.brainstorming.failed.notFound"
                )
                return
            } catch Brainstorming.ErrorType.unableToDecode {
                alert.push(
                    title: "view.details.location.brainstorming.failed",
                    message: "view.details.location.brainstorming.failed.decode"
                )
                return
            } catch {
                alert.push(
                    title: "view.details.location.brainstorming.failed",
                    message: "view.details.location.brainstorming.failed.other \(error.localizedDescription)"
                )
                return
            }
            editorModel.setLngLat(from: record)
        }
    }
}

#if DEBUG
struct NominationDetails_Previews: PreviewProvider {
    
    static var previews: some View {
        NominationDetails(nomination: Dia.preview.nominations()[0])
            .environmentObject(AlertInspector())
            .environmentObject(Dia.preview)
    }
}
#endif

fileprivate struct HighlightCard: View {
    
    private let title: LocalizedStringKey
    private let systemImage: String
    private let color: Color
    private let text: Text
    
    init(
        _ title: LocalizedStringKey,
        _ systemImage: String,
        _ color: Color,
        _ text: Text
    ) {
        self.title = title
        self.systemImage = systemImage
        self.color = color
        self.text = text
    }
    
    var body: some View {
        VStack(alignment: .center) {
            Label(title, systemImage: systemImage)
                .labelStyle(.iconOnly)
                .imageScale(.large)
                .foregroundColor(color)
                .padding(.bottom, 4)
            HStack {
                text
                    .lineLimit(1)
                    .appendSpacers()
            }
        }
        .card()
    }
}

fileprivate struct ReasonCard: View {
    
    private let reason: Umi.Reason
    
    init(_ reason: Umi.Reason) {
        self.reason = reason
    }
    
    var body: some View {
        HStack {
            Label(reason.title, systemImage: reason.icon)
                .foregroundColor(.red)
            Spacer()
        }
        .card()
    }
}

fileprivate class ReasonInspector: ObservableObject, Identifiable {
    let data: Umi.Reason
    @Published var selected = false
    
    init(_ reason: Umi.Reason) {
        data = reason
    }
}

fileprivate class EditorModel: ObservableObject {
    @Published var reasons: [ReasonInspector]
    @Published var status: Umi.Status.Code = .pending
    @Published var resultTime: Date = Date()
    @Published var lngLat: LngLat? = nil
    
    init() {
        reasons = Umi.shared.reasonAll.compactMap { reason in
            if reason.code == Umi.Reason.undeclared {
                return nil
            }
            return .init(reason)
        }
    }
    
    func set(from nomination: Nomination) {
        status = nomination.statusCode
        resultTime = nomination.resultTime
        let reasonsCode = nomination.reasonsCode
        for reason in reasons {
            reason.selected = reasonsCode.contains(reason.data.code)
        }
        if nomination.hasLngLat {
            lngLat = .init(lng: nomination.longitude, lat: nomination.latitude)
        } else {
            lngLat = nil
        }
    }
    
    func save(to nomination: Nomination) {
        nomination.statusCode = status
        if status != .pending {
            nomination.resultTime = resultTime
            if status == .rejected {
                nomination.reasonsCode = reasons.filter { $0.selected }.map { $0.data.code }
            }
        }
        if let solidLngLat = lngLat {
            nomination.hasLngLat = true
            nomination.longitude = solidLngLat.lng
            nomination.latitude = solidLngLat.lat
        } else {
            nomination.hasLngLat = false
        }
    }
    
    func setLngLat(from intelURL: String) -> Bool {
        guard let range = intelURL.range(of: "ll\\=[\\d\\.\\,]+", options: .regularExpression) else {
            return false
        }
        let text = intelURL[range].replacingOccurrences(of: "ll=", with: "")
        let pair = text.split(separator: ",")
        guard
            let latString = pair.first, let lat = Double(latString), abs(lat) < 90,
            let lngString = pair.last , let lng = Double(lngString), abs(lng) < 180
        else {
            return false
        }
        lngLat = .init(lng: lng, lat: lat)
        return true
    }
    
    func setLngLat(from record: Brainstorming.Record) {
        DispatchQueue.main.async {
            self.lngLat = .init(lng: record.lng, lat: record.lat)
        }
    }
}

fileprivate class LngLatFormatter : Formatter {
    override func string(for obj: Any?) -> String? {
        guard let lngLat: LngLat = obj as? LngLat else {
            return nil
        }
        return "\(lngLat.lat),\(lngLat.lng)"
    }
    
    override func getObjectValue(
        _ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?,
        for string: String,
        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?
    ) -> Bool {
        if string.isEmpty {
            obj?.pointee = nil
            return true
        }
        let pair = string.split(separator: ",")
        guard
            let latString = pair.first, let lat = Double(latString), abs(lat) < 90 ,
            let lngString = pair.last , let lng = Double(lngString), abs(lng) < 180
        else {
            obj?.pointee = nil
            return false
        }
        obj?.pointee = LngLat(lng: lng, lat: lat) as AnyObject
        return true
    }
    
    override func isPartialStringValid(
        _ partialString: String,
        newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?,
        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?
    ) -> Bool {
        if partialString.isEmpty {
            return true
        }
        guard let _ = partialString.range(of: "^\\d{1,2}(\\.\\d*)?(,(\\d{1,3}(\\.\\d*)?)?)?$", options: .regularExpression) else {
            // Not valid at all
            return false
        }
        guard let _ = partialString.range(of: "^\\d{1,2}(\\.\\d+)?,\\d{1,3}(\\.\\d+)?$", options: .regularExpression) else {
            // Not completed
            return true
        }
        // Complated, parse and check range
        let pair = partialString.split(separator: ",")
        guard
            let latString = pair.first, let lat = Double(latString), abs(lat) < 90 ,
            let lngString = pair.last , let lng = Double(lngString), abs(lng) < 180
        else {
            return false
        }
        return true
    }
}
