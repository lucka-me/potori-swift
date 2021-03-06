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
                    card(highlight)
                    if (mode == .view && nomination.statusCode == .rejected)
                        || (mode == .edit && editData.status == .rejected) {
                        card(reasons)
                    }
                }
                .lineLimit(1)
                
                if mode == .view && nomination.hasLngLat {
                    NominationDetailsMap(nomination: nomination)
                        .clipShape(RoundedRectangle(cornerRadius: Self.radius, style: .continuous))
                        .frame(height: 200)
                } else if mode == .edit {
                    card(locationEditor)
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
                nomination.statusCode = editData.status
                if editData.status != .pending {
                    nomination.resultTime = editData.resultTime
                    if editData.status == .rejected {
                        nomination.reasonsCode = editData.reasons
                    }
                }
                if editData.locationString.isEmpty {
                    nomination.hasLngLat = false
                } else if
                    editData.validateLocationString(),
                    let lngLat = editData.lngLat {
                    nomination.hasLngLat = true
                    nomination.longitude = lngLat.lng
                    nomination.latitude = lngLat.lat
                }
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
    private func card<Content: View>(_ content: Content) -> some View {
        ZStack(alignment: .topLeading) {
            CardBackground(radius: Self.radius)
            VStack(alignment: .leading) { content }
                .padding(Self.radius)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
    
    private func dateString(_ from: Date) -> String {
        DateFormatter.localizedString(from: from, dateStyle: .medium, timeStyle: .none)
    }
    
    @ViewBuilder
    private var highlight: some View {
        HStack {
            Label("view.details.confirmed", systemImage: "arrow.up.circle")
                .foregroundColor(.accentColor)
            Spacer()
            Text(dateString(nomination.confirmedTime))
        }
        
        Divider()
        
        if mode == .view {
            HStack {
                let status = nomination.statusData
                Label(status.title, systemImage: status.icon)
                    .foregroundColor(status.color)
                Spacer()
                if (status.code != .pending) {
                    Text(dateString(nomination.resultTime))
                }
            }
        } else {
            HStack {
                Picker(
                    selection: $editData.status,
                    label: Label("view.details.status", systemImage: "pencil.circle")
                ) {
                    ForEach(Umi.shared.statusAll, id: \.code) { status in
                        Text(status.title).tag(status.code)
                    }
                }
            }
            if editData.status != .pending {
                #if os(macOS)
                let datePickerStyle = DefaultDatePickerStyle()
                #else
                let datePickerStyle = GraphicalDatePickerStyle()
                #endif
                Divider()
                DatePicker(
                    selection: $editData.resultTime,
                    in: PartialRangeFrom(nomination.confirmedTime),
                    displayedComponents: [ .date, .hourAndMinute ]
                ) {
                    Label("view.details.resulted", systemImage: "pencil.circle")
                }
                .datePickerStyle(datePickerStyle)
            }
        }
        
        Divider()
        
        HStack {
            Label("view.details.scanner", systemImage: "apps.iphone")
                .foregroundColor(.purple)
            Spacer()
            Text(nomination.scannerData.title)
        }
    }
    
    @ViewBuilder
    private var reasons: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("view.details.rejectedFor")
                .foregroundColor(.red)
                .bold()
            Spacer()
            if mode == .edit {
                Button(editData.showReasons ? "view.details.hide" : "view.details.show") {
                    editData.showReasons.toggle()
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        if mode == .view {
            if nomination.reasons.count > 0 {
                ForEach(nomination.reasonsData, id: \.code) { reason in
                    Divider()
                    Label(reason.title, systemImage: reason.icon)
                        
                }
            } else {
                Divider()
                let undeclared = Umi.shared.reason[Umi.Reason.undeclared]!
                Label(undeclared.title, systemImage: undeclared.icon)
            }
        } else if editData.showReasons {
            #if os(macOS)
            let buttonStyle = PlainButtonStyle()
            #else
            let buttonStyle = BorderlessButtonStyle()
            #endif
            ForEach(Umi.shared.reasonAll, id: \.code) { reason in
                if reason.code != Umi.Reason.undeclared {
                    Divider()
                    Button {
                        if let index = editData.reasons.firstIndex(of: reason.code) {
                            editData.reasons.remove(at: index)
                        } else {
                            editData.reasons.append(reason.code)
                        }
                    } label: {
                        Label(reason.title, systemImage: reason.icon)
                        Spacer()
                        Image(systemName: editData.reasons.contains(reason.code) ? "checkmark.circle.fill" : "circle")
                    }
                    .buttonStyle(buttonStyle)
                }
            }
            .animation(.none)
        }
    }
    
    @ViewBuilder
    private var locationEditor: some View {
        Text("view.details.location")
            .bold()
        Divider()
        HStack {
            let textField = TextField(
                "view.details.location.hint",
                text: $editData.locationString,
                onCommit: { editData.validateLocationString() }
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
        Divider()
        Button {
            #if os(macOS)
            guard let url = NSPasteboard.general.string(forType: .string) else {
                return
            }
            #else
            guard let url = UIPasteboard.general.string else {
                return
            }
            #endif
            editData.setLngLat(from: url)
        } label: {
            Label("view.details.location.paste", systemImage: "doc.on.clipboard")
        }
        .buttonStyle(BorderlessButtonStyle())
    }
}

#if DEBUG
struct NominationDetails_Previews: PreviewProvider {
    
    static var previews: some View {
        NominationDetails(nomination: Dia.preview.nominations[0])
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
    
    func setLngLat(from intelURL: String) {
        guard let range = intelURL.range(of: "ll\\=[\\d\\.\\,]+", options: .regularExpression) else {
            return
        }
        let text = intelURL[range].replacingOccurrences(of: "ll=", with: "")
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
    
    @discardableResult
    func validateLocationString() -> Bool {
        if locationString.isEmpty {
            locationStringValid = true
            return locationStringValid
        }
        guard let _ = locationString.range(of: "^\\d+(\\.\\d+)?,\\d+(\\.\\d+)?$", options: .regularExpression) else {
            locationStringValid = false
            return locationStringValid
        }
        if let _ = lngLat {
            locationStringValid = true
            return locationStringValid
        }
        locationStringValid = false
        return locationStringValid
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
