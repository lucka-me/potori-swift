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
    
    @EnvironmentObject private var dia: Dia
    @State private var mode: Mode = .view
    @ObservedObject private var editData: EditData = .init()
    
    var body: some View {
        if nomination.isFault {
            // Prevent crash when delete
            EmptyView()
        } else {
            #if os(macOS)
            content.frame(minWidth: 300)
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
                    RemoteImage(nomination.imageURL, sharable: true)
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: Self.radius, style: .continuous))
                        .frame(maxWidth: 300, maxHeight: 300)
                    Divider()
                }
                
                LazyVGrid(columns: [ .init(.adaptive(minimum: 250), alignment: .top) ], alignment: .center) {
                    highlight
                    if (mode == .view && nomination.statusCode == .rejected)
                        || (mode == .edit && editData.status == .rejected) {
                        reasons
                    }
                }
                
                if mode == .view && nomination.hasLngLat {
                    NominationDetailsMap(nomination: nomination)
                        .clipShape(RoundedRectangle(cornerRadius: Self.radius, style: .continuous))
                        .frame(height: 200)
                } else if mode == .edit {
                    locationEditor
                }
            }
            .padding()
            .animation(.easeInOut)
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
                editData.from(nomination)
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
    private var highlight: some View {
        CardView.Card {
            CardView.List.header(Text("view.details.hightlight"))
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
                    text: $editData.locationString,
                    onCommit: editData.validateLocationString
                )
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                #if os(macOS)
                textField
                #else
                textField
                    .keyboardType(.numbersAndPunctuation)
                #endif
                if !editData.locationStringValid {
                    Label("view.details.location.invalid", systemImage: "exclamationmark.circle")
                        .foregroundColor(.red)
                }
            }
            CardView.List.row(editData.setLngLatFromPastboard) {
                Label("view.details.location.paste", systemImage: "doc.on.clipboard")
            }
            if editData.status == .pending && !Brainstorming.isBeforeEpoch(when: editData.resultTime) {
                CardView.List.row {
                    Brainstorming.shared.query(nomination.id) { record in
                        guard mode == .edit else {
                            return
                        }
                        guard let solidRecord = record else {
                            // Alert
                            return
                        }
                        editData.setLngLatFrom(solidRecord)
                    }
                } label: {
                    Label("view.details.location.brainstorming", systemImage: "hand.point.right")
                }
            }
        }
    }
}

#if DEBUG
struct NominationDetails_Previews: PreviewProvider {
    
    static var previews: some View {
        NominationDetails(nomination: Dia.preview.nominations()[0])
            .environmentObject(Dia.preview)
    }
}
#endif

fileprivate class EditData: ObservableObject {
    @Published var status: Umi.Status.Code = .pending
    @Published var resultTime: Date = Date()
    @Published var showReasons: Bool = false
    @Published var reasons: [Umi.Reason.Code] = []
    @Published var locationString: String = ""
    @Published var locationStringValid: Bool = true
    
    func from(_ nomination: Nomination) {
        status = nomination.statusCode
        resultTime = nomination.resultTime
        reasons = nomination.reasonsCode
        if nomination.hasLngLat {
            locationString = "\(nomination.latitude),\(nomination.longitude)"
        } else {
            locationString = ""
        }
        locationStringValid = true
    }
    
    func save(to nomination: Nomination) {
        nomination.statusCode = status
        if status != .pending {
            nomination.resultTime = resultTime
            if status == .rejected {
                nomination.reasonsCode = reasons
            }
        }
        if locationString.isEmpty {
            nomination.hasLngLat = false
        } else {
            validateLocationString()
            if locationStringValid, let solidLngLat = lngLat {
                nomination.hasLngLat = true
                nomination.longitude = solidLngLat.lng
                nomination.latitude = solidLngLat.lat
            }
        }
    }
    
    func setLngLatFromPastboard() {
        #if os(macOS)
        guard let url = NSPasteboard.general.string(forType: .string) else {
            return
        }
        #else
        guard let url = UIPasteboard.general.string else {
            return
        }
        #endif
        guard let range = url.range(of: "ll\\=[\\d\\.\\,]+", options: .regularExpression) else {
            return
        }
        let text = url[range].replacingOccurrences(of: "ll=", with: "")
        let pair = text.split(separator: ",")
        guard
            let latString = pair.first, let lat = Double(latString), abs(lat) < 90,
            let lngString = pair.last , let lng = Double(lngString), abs(lng) < 180
        else {
            return
        }
        locationString = text
        locationStringValid = true
    }
    
    func setLngLatFrom(_ record: Brainstorming.Record) {
        locationString = "\(record.lat),\(record.lng)"
        locationStringValid = true
    }
    
    func validateLocationString() {
        if locationString.isEmpty {
            locationStringValid = true
            return
        }
        guard let _ = locationString.range(of: "^\\d+(\\.\\d+)?,\\d+(\\.\\d+)?$", options: .regularExpression) else {
            locationStringValid = false
            return
        }
        if let _ = lngLat {
            locationStringValid = true
            return
        }
        locationStringValid = false
        return
    }
    
    var lngLat: LngLat? {
        let pair = locationString.split(separator: ",")
        guard
            let latString = pair.first, let lat = Double(latString),
            let lngString = pair.last , let lng = Double(lngString)
        else {
            return nil
        }
        if abs(lng) < 180 && abs(lat) < 90 {
            return .init(lng: lng, lat: lat)
        }
        return nil
    }
}
