//
//  Navigation.swift
//  Potori (iOS)
//
//  Created by Lucka on 21/1/2021.
//

import Combine
import SwiftUI

class Navigation: ObservableObject {
    
    #if os(iOS)
    typealias LinkIdentifier = Int16
    static let nominationWidgetTarget: LinkIdentifier = 51
    #endif
    
    enum Panel: Hashable {
        case dashboard
        case list
        case map
        #if os(iOS)
        case preference
        #endif
    }
    
    struct OpenNominationsConfiguration {
        let title: LocalizedStringKey
        let predicate: NSPredicate?
        let selection: String?

        #if os(macOS)
        let panel: Panel?
        #endif
        
        init(
            _ title: LocalizedStringKey,
            _ predicate: NSPredicate? = nil,
            _ selection: String? = nil,
            panel: Panel? = nil
        ) {
            self.title = title
            self.predicate = predicate
            self.selection = selection
            #if os(macOS)
            self.panel = panel
            #endif
        }
    }
    
    class PanelLabel {
        static let dashboard = Label("view.dashboard", systemImage: "gauge")
        static let list = Label("view.list", systemImage: "list.bullet")
        static let map = Label("view.map", systemImage: "map")
        #if os(iOS)
        static let preferences = Label("view.preferences", systemImage: "gearshape")
        #endif
    }
    
    #if os(macOS)
    private var openNominationsCancellable: AnyCancellable? = nil
    #endif
    @Published var openNominations: OpenNominationsConfiguration = .init("view.dashboard.highlight.nominations")
    @Published var activePanel: Panel? = .dashboard
    
    #if os(iOS)
    @Published var activeLink: LinkIdentifier? = nil
    #endif
    
    #if os(macOS)
    init() {
        openNominationsCancellable = $openNominations.sink { value in
            if let solidPanel = value.panel {
                self.activePanel = solidPanel
            }
        }
    }
    #endif
}

struct OpenNominationListLink<Label: View>: View {
    #if os(macOS)
    @EnvironmentObject var navigation: Navigation
    #endif
    private let config: Navigation.OpenNominationsConfiguration
    private let label: () -> Label
    
    init(_ config: Navigation.OpenNominationsConfiguration, @ViewBuilder _ label: @escaping () -> Label) {
        self.config = .init(config.title, config.predicate, panel: .list)
        self.label = label
    }
    
    var body: some View {
        #if os(macOS)
        let view = Button(action: { navigation.openNominations = config }, label: label)
        #else
        let view = NavigationLink(destination: NominationList(config), label: label)
            .isDetailLink(false)
        #endif
        view.buttonStyle(PlainButtonStyle())
    }
}

struct OpenNominationDetailsLink<Label: View>: View {
    #if os(macOS)
    @EnvironmentObject var navigation: Navigation
    #endif
    private let config: Navigation.OpenNominationsConfiguration
    private let nomination: Nomination
    private let label: () -> Label
    
    init(_ config: Navigation.OpenNominationsConfiguration, _ nomination: Nomination, @ViewBuilder _ label: @escaping () -> Label) {
        self.config = .init(config.title, config.predicate, nomination.id, panel: .list)
        self.nomination = nomination
        self.label = label
    }
    
    var body: some View {
        #if os(macOS)
        let view = Button(action: { navigation.openNominations = config }, label: label)
        #else
        let view = NavigationLink(destination: NominationDetails(nomination: nomination), label: label)
            .isDetailLink(false)
        #endif
        view.buttonStyle(PlainButtonStyle())
    }
}

struct OpenNominationMapLink<Label: View>: View {
    #if os(macOS)
    @EnvironmentObject var navigation: Navigation
    #endif
    private let config: Navigation.OpenNominationsConfiguration
    private let plain: Bool
    private let label: () -> Label
    
    init(_ config: Navigation.OpenNominationsConfiguration, plain: Bool = true, @ViewBuilder _ label: @escaping () -> Label) {
        self.config = .init(config.title, config.predicate, panel: .map)
        self.plain = plain
        self.label = label
    }
    
    var body: some View {
        #if os(macOS)
        let view = Button(action: { navigation.openNominations = config }, label: label)
        #else
        let view = NavigationLink(destination: NominationMap(config), label: label)
        #endif
        if plain {
            view.buttonStyle(PlainButtonStyle())
        } else {
            view
        }
    }
}
