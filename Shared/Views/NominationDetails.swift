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
    @ObservedObject private var editData: EditData = .init()
    
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
        ScrollView {
            VStack(alignment: .center) {
                if mode == .view {
                    image
                    actions
                }
                
                LazyVGrid(
                    columns: .init(repeating: .init(.flexible(), alignment: .top), count: columns),
                    alignment: .center
                ) {
                    highlights
                    if showReasons {
                        reasons
                    }
                }
                
                if mode == .view && nomination.hasLngLat {
                    FusionMap(nomination)
                        .frame(height: 200)
                        .mask {
                            RoundedRectangle(cornerRadius: CardView.defaultRadius, style: .continuous)
                        }
                } else if mode == .edit {
                    locationEditor
                }
            }
            .padding()
            .animation(.easeInOut, value: mode)
        }
        .navigationTitle(nomination.title)
        .toolbar {
            #if os(iOS)
            /// Prevent back button disappearing when mode changed (as 3rd view)
            /// - References: https://stackoverflow.com/a/64994154
            ToolbarItem(placement: .navigationBarLeading) { Text("") }
            #endif
            ToolbarItemGroup(placement: .primaryAction) {
                editButton
                if mode == .edit {
                    Button { mode = .view } label: { Label("view.details.cancel", systemImage: "xmark") }
                }
            }
        }
    }
    
    @ViewBuilder
    private var editButton: some View {
        Button {
            if mode == .view {
                editData.set(from: nomination)
                mode = .edit
            } else {
                editData.save(to: nomination)
                dia.save()
                mode = .view
            }
        } label: {
            Label(
                mode == .view ? "view.details.edit" : "view.details.save",
                systemImage: mode == .view ? "square.and.pencil" : "checkmark"
            )
        }
    }
    
    @ViewBuilder
    private var image: some View {
        AsyncImage(url: nomination.imageURL)
            .scaledToFit()
            .mask {
                RoundedRectangle(cornerRadius: CardView.defaultRadius, style: .continuous)
            }
            .frame(maxHeight: 300)
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
    }
    
    @ViewBuilder
    private var actions: some View {
        HStack {
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
        }
        .buttonStyle(.bordered)
    }

    @ViewBuilder
    private var highlights: some View {
        CardView.Card {
            CardView.List.header(Text("view.details.hightlights"))
            CardView.List.row(
                Label("view.details.confirmed", systemImage: "arrow.up.circle").foregroundColor(.accentColor),
                Text(nomination.confirmedTime, style: .date)
            )
            if mode == .view {
                let status = nomination.statusData
                CardView.List.row(
                    Label(status.title, systemImage: status.icon).foregroundColor(status.color),
                    status.code == .pending ? Text("") : Text(nomination.resultTime, style: .date)
                )
            } else {
                CardView.List.row {
                    HStack {
                        Picker(
                            selection: $editData.status,
                            label: Label("view.details.status", systemImage: "pencil.circle")
                        ) {
                            ForEach(Umi.shared.statusAll, id: \.code) { status in
                                Text(status.title).tag(status.code)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                if editData.status != .pending {
                    CardView.List.row {
                        HStack {
                            DatePicker(
                                selection: $editData.resultTime,
                                in: PartialRangeFrom(nomination.confirmedTime),
                                displayedComponents: [ .date, .hourAndMinute ]
                            ) {
                                Label("view.details.resulted", systemImage: "pencil.circle")
                            }
                            .datePickerStyle(DefaultDatePickerStyle())
                        }
                    }
                }
            }
            CardView.List.row(
                Label("view.details.scanner", systemImage: "apps.iphone").foregroundColor(.purple),
                Text(nomination.scannerData.title)
            )
        }
    }
    
    @ViewBuilder
    private var reasons: some View {
        CardView.Card {
            if mode == .view {
                CardView.List.header(Text("view.details.rejectedFor"))
                if nomination.reasons.count > 0 {
                    ForEach(nomination.reasonsData) { reason in
                        CardView.List.row(Label(reason.title, systemImage: reason.icon))
                    }
                } else {
                    let reason = Umi.shared.reason[Umi.Reason.undeclared]!
                    CardView.List.row(Label(reason.title, systemImage: reason.icon))
                }
            } else {
                CardView.List.header(
                    Text("view.details.rejectedFor"),
                    Button(editData.showReasons ? "view.details.hide" : "view.details.show") {
                        editData.showReasons.toggle()
                    }
                    .buttonStyle(BorderlessButtonStyle())
                )
                if editData.showReasons {
                    reasonsSelector
                }
            }
        }
    }
    
    @ViewBuilder
    private var reasonsSelector: some View {
        ForEach(Umi.shared.reasonAll) { reason in
            if reason.code != Umi.Reason.undeclared {
                CardView.List.row {
                    if let index = editData.reasons.firstIndex(of: reason.code) {
                        editData.reasons.remove(at: index)
                    } else {
                        editData.reasons.append(reason.code)
                    }
                } label: {
                    Label(reason.title, systemImage: reason.icon)
                    Spacer()
                    if editData.reasons.contains(reason.code) {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var locationEditor: some View {
        CardView.Card {
            CardView.List.header(Text("view.details.location"))
            CardView.List.row {
                let textField = TextField(
                    "view.details.location.hint",
                    value: $editData.lngLat,
                    formatter: LngLatFormatter()
                )
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                #if os(macOS)
                textField
                #else
                textField
                    .keyboardType(.numbersAndPunctuation)
                #endif
            }
            CardView.List.row(setLngLatFromPasteboard) {
                Label("view.details.location.paste", systemImage: "doc.on.clipboard")
            }
            if !Brainstorming.isBeforeEpoch(when: editData.resultTime, status: editData.status) {
                CardView.List.row(queryLngLatFromBrainstorming) {
                    Label("view.details.location.brainstorming", systemImage: "brain")
                }
            }
        }
    }
    
    private var columns: Int {
        if mode == .edit || !showReasons {
            return 1
        } else {
            #if os(macOS)
            return 2
            #else
            return horizontalSizeClass == .compact ? 1 : 2
            #endif
        }
    }
    
    private var showReasons: Bool {
        (mode == .view && nomination.statusCode == .rejected) || (mode == .edit && editData.status == .rejected)
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
            alert.push(.init(title: .init("view.details.location.paste.empty")))
            return
        }
        #endif
        guard let url = UNPasteboard.general.string else {
            alert.push(.init(title: .init("view.details.location.paste.empty")))
            return
        }
        if !editData.setLngLat(from: url) {
            alert.push(
                .init(
                    title: .init("view.details.location.paste.invalid"),
                    message: .init("view.details.location.paste.invalid.desc")
                )
            )
        }
    }
    
    private func queryLngLatFromBrainstorming() {
        async {
            let record = await Brainstorming.shared.query(nomination.id)
            guard mode == .edit else {
                return
            }
            guard let solidRecord = record else {
                alert.push(
                    .init(
                        title: .init("view.details.location.brainstorming.failed"),
                        message: .init("view.details.location.brainstorming.failed.desc")
                    )
                )
                return
            }
            editData.setLngLat(from: solidRecord)
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

fileprivate class EditData: ObservableObject {
    @Published var status: Umi.Status.Code = .pending
    @Published var resultTime: Date = Date()
    @Published var showReasons: Bool = false
    @Published var reasons: [Umi.Reason.Code] = []
    @Published var lngLat: LngLat? = nil
    
    private var id: String = ""
    
    func set(from nomination: Nomination) {
        id = nomination.id
        status = nomination.statusCode
        resultTime = nomination.resultTime
        reasons = nomination.reasonsCode
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
                nomination.reasonsCode = reasons
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
