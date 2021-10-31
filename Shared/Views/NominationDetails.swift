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
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading) {
                if mode == .view {
                    viewer
                } else {
                    editor
                        .animation(.easeInOut, value: editorModel.status)
                }
            }
            .padding()
        }
        .toolbar {
            if mode == .view {
                viewerControls
            } else {
                editorControls
            }
        }
        .navigationTitle(nomination.isFault ? "" : nomination.title)
        .animation(.easeInOut, value: mode)
    }
    
    @ViewBuilder
    private var viewer: some View {
        image
        actions
        highlights
        if nomination.statusCode == .rejected {
            reasons
        }
        if let annotation = nomination.annotation {
            FusionMap(annotation)
                .frame(height: 200)
                .mask {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                }
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
        AsyncImage(url: nomination.imageURL)
            .scaledToFit()
            .mask {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
            }
            .frame(maxHeight: 300, alignment: .center)
            .contextMenu {
                Button {
                    if let url = URL(string: nomination.imageURL) {
                        openURL(url)
                    }
                } label: {
                    Label("action.open", systemImage: "safari")
                }
                Button(action: shareImage) {
                    #if os(macOS)
                    Label("view.details.image.copy", systemImage: "doc.on.doc")
                    #else
                    Label("view.details.image.share", systemImage: "square.and.arrow.up")
                    #endif
                }
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
            HighlightCard("view.details.confirmed", "arrow.up.circle", .accentColor) {
                Text(nomination.confirmedTime, style: .date)
            }
            let status = nomination.statusData
            HighlightCard(status.title, status.icon, status.color) {
                if status.code == .pending {
                    Text(status.title)
                } else {
                    Text(nomination.resultTime, style: .date)
                }
            }
            HighlightCard("view.details.scanner", "apps.iphone", .purple) {
                Text(nomination.scannerData.title)
            }
        }
    }
    
    @ViewBuilder
    private var reasons: some View {
        header("view.details.reasons")
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
        header("view.details.hightlights")
        VStack(alignment: .leading) {
            HStack {
                Label("view.details.confirmed", systemImage: "arrow.up.circle")
                Spacer()
                Text(nomination.confirmedTime, style: .date)
            }
            Divider()
            Picker("view.details.status", selection: $editorModel.status) {
                ForEach(Umi.shared.statusAll) { status in
                    Text(status.title).tag(status.code)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .labelStyle(.fixedSizeIcon)
        .card()
        
        if editorModel.status != .pending {
            VStack(alignment: .leading) {
                Label("view.details.resulted", systemImage: "pencil.circle")
                    .labelStyle(.fixedSizeIcon)
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    DatePicker(
                        "view.details.resulted",
                        selection: $editorModel.resultTime,
                        in: PartialRangeFrom(nomination.confirmedTime),
                        displayedComponents: [ .date, .hourAndMinute ]
                    )
                        .labelsHidden()
                        .datePickerStyle(.automatic)
                }
            }
            .card()
        }

        if editorModel.status == .rejected {
            reasonsEditor
                .animation(.default, value: editorModel.showReasons)
        }
        
        locationEditor
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
                Label("action.cancel", systemImage: "xmark")
            }
            .keyboardShortcut(.cancelAction)
        }
        .disabled(editorModel.queryingBrainstorming)
    }
    
    @ViewBuilder
    private var reasonsEditor: some View {
        header("view.details.reasons") {
            Button {
                editorModel.showReasons.toggle()
            } label: {
                if editorModel.showReasons {
                    Label("view.details.reasons.collapse", systemImage: "chevron.up")
                } else {
                    Label("view.details.reasons.expand", systemImage: "chevron.down")
                }
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
        }
        if editorModel.showReasons {
            LazyVGrid(
                columns: .init(repeating: .init(.flexible(), alignment: .top), count: reasonsColumns),
                alignment: .leading
            ) {
                ForEach($editorModel.reasons) { $reason in
                    Toggle(isOn: $reason.selected) {
                        ReasonCard(reason.data, selected: reason.selected)
                    }
                    .toggleStyle(.plainButton)
                }
            }
        }
    }
    
    @ViewBuilder
    private var locationEditor: some View {
        header("view.details.location")
        VStack(alignment: .leading) {
            TextField(
                "view.details.location.coordinates",
                value: $editorModel.lngLat,
                formatter: LngLatFormatter(),
                prompt: Text("view.details.location.coordinates.hint")
            )
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
            Divider()
            Button(action: setLngLatFromPasteboard) {
                Label("view.details.location.paste", systemImage: "doc.on.clipboard")
            }
            if !Brainstorming.isBeforeEpoch(when: editorModel.resultTime, status: editorModel.status) {
                Divider()
                Button(action: queryLngLatFromBrainstorming) {
                    Label("view.details.location.brainstorming", systemImage: "brain")
                        .opacity(editorModel.queryingBrainstorming ? 0 : 1)
                        .overlay(alignment: .leading) {
                            if editorModel.queryingBrainstorming {
                                ProgressView()
                            }
                        }
                }
            }
        }
        .disabled(editorModel.queryingBrainstorming)
        .buttonStyle(.borderless)
        .labelStyle(.fixedSizeIcon)
        .card()
    }
    
    @ViewBuilder
    private func header(_ titleKey: LocalizedStringKey) -> some View {
        Text(titleKey)
            .foregroundColor(.secondary)
            .padding(.top, 4)
            .padding(.horizontal)
    }
    
    @ViewBuilder
    private func header<Trailing: View>(
        _ titleKey: LocalizedStringKey,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(titleKey)
            Spacer()
            trailing()
        }
        .foregroundColor(.secondary)
        .padding(.top, 4)
        .padding(.horizontal)
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
            alert.push("view.details.location.paste.empty")
            return
        }
        #endif
        guard let url = UNPasteboard.general.string else {
            alert.push("view.details.location.paste.empty")
            return
        }
        if !editorModel.setLngLat(from: url) {
            alert.push(
                "view.details.location.paste.invalid",
                message: "view.details.location.paste.invalid.desc"
            )
        }
    }
    
    private func queryLngLatFromBrainstorming() {
        Task {
            do {
                try await editorModel.queryLngLatFromBrainstorming()
            } catch Brainstorming.ErrorType.notFound {
                alert.push(
                    "view.details.location.brainstorming.failed",
                    message: "view.details.location.brainstorming.failed.notFound"
                )
                return
            } catch Brainstorming.ErrorType.unableToDecode {
                alert.push(
                    "view.details.location.brainstorming.failed",
                    message: "view.details.location.brainstorming.failed.decode"
                )
                return
            } catch {
                alert.push(
                    "view.details.location.brainstorming.failed",
                    message: "view.details.location.brainstorming.failed.other \(error.localizedDescription)"
                )
                return
            }
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

fileprivate struct HighlightCard<Content: View>: View {
    
    private let title: LocalizedStringKey
    private let systemImage: String
    private let color: Color
    private let content: () -> Content
    
    init(
        _ title: LocalizedStringKey,
        _ systemImage: String,
        _ color: Color,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.color = color
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .center) {
            Label(title, systemImage: systemImage)
                .labelStyle(.iconOnly)
                .imageScale(.large)
                .foregroundColor(color)
                .padding(.bottom, 4)
            content()
                .lineLimit(1)
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .card()
    }
}

fileprivate struct ReasonCard: View {
    
    private let reason: Umi.Reason
    private let selected: Bool
    
    init(_ reason: Umi.Reason, selected: Bool = false) {
        self.reason = reason
        self.selected = selected
    }
    
    var body: some View {
        Label(reason.title, systemImage: reason.icon)
            .foregroundColor(selected ? .primary : .red)
            .labelStyle(.fixedSizeIcon)
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            .card(color: selected ? .red : .clear)
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
    
    private var id: String = ""
    @Published var reasons: [ReasonInspector]
    @Published var status: Umi.Status.Code = .pending
    @Published var resultTime: Date = Date()
    @Published var lngLat: LngLat? = nil
    
    @Published var showReasons = false
    @Published var queryingBrainstorming = false
    
    init() {
        reasons = Umi.shared.reasonAll.compactMap { reason in
            if reason.code == Umi.Reason.undeclared {
                return nil
            }
            return .init(reason)
        }
    }
    
    func set(from nomination: Nomination) {
        queryingBrainstorming = false
        id = nomination.id
        status = nomination.statusCode
        resultTime = nomination.resultTime
        let reasonsCode = nomination.reasonsCode
        for reason in reasons {
            reason.selected = reasonsCode.contains(reason.data.code)
        }
        showReasons = !reasonsCode.isEmpty
        if nomination.hasLngLat {
            lngLat = .init(lng: nomination.longitude, lat: nomination.latitude)
        } else {
            lngLat = nil
        }
    }
    
    func save(to nomination: Nomination) {
        queryingBrainstorming = false
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
    
    func queryLngLatFromBrainstorming() async throws {
        queryingBrainstorming = true
        defer {
            DispatchQueue.main.async { [ weak self ] in
                self?.queryingBrainstorming = false
            }
        }
        let record = try await Brainstorming.shared.query(id)
        if !queryingBrainstorming { return }
        setLngLat(from: record)
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
