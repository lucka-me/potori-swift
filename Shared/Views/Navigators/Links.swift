//
//  Links.swift
//  Potori
//
//  Created by Lucka on 10/7/2021.
//

import SwiftUI

struct ListLink<Label: View>: View {
    #if os(macOS)
    @EnvironmentObject var listNavigator: ListNavigator
    @EnvironmentObject var panelNavigator: PanelNavigator
    #endif
    private let configuration: ListNavigator.Configuration
    private let label: () -> Label
    
    init(_ configuration: ListNavigator.Configuration, @ViewBuilder label: @escaping () -> Label) {
        self.configuration = configuration
        self.label = label
    }
    
    var body: some View {
        content
            .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var content: some View {
        #if os(macOS)
        Button(action: open, label: label)
        #else
        NavigationLink(destination: destination, label: label)
        #endif
    }
    
    #if os(macOS)
    private func open() {
        listNavigator.set(configuration)
        panelNavigator.actived = .list
    }
    #else
    private func destination() -> NominationList {
        .init(configuration)
    }
    #endif
}

struct DetailsLink<Label: View>: View {
    #if os(macOS)
    @EnvironmentObject var listNavigator: ListNavigator
    @EnvironmentObject var panelNavigator: PanelNavigator
    #endif
    private let configuration: ListNavigator.Configuration
    private let nomination: Nomination
    private let label: () -> Label
    
    init(
        _ configuration: ListNavigator.Configuration,
        _ nomination: Nomination,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.configuration = configuration
        self.nomination = nomination
        self.label = label
    }
    
    var body: some View {
        content
            .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var content: some View {
        #if os(macOS)
        Button(action: open, label: label)
        #else
        NavigationLink(destination: destination, label: label)
        #endif
    }
    
    #if os(macOS)
    private func open() {
        listNavigator.set(configuration)
        panelNavigator.actived = .list
    }
    #else
    private func destination() -> NominationDetails {
        .init(nomination: nomination)
    }
    #endif
}

struct MapLink<Label: View>: View {
    #if os(macOS)
    @EnvironmentObject var listNavigator: ListNavigator
    @EnvironmentObject var panelNavigator: PanelNavigator
    #endif
    private let configuration: ListNavigator.Configuration
    private let label: () -> Label
    
    init(_ configuration: ListNavigator.Configuration, @ViewBuilder label: @escaping () -> Label) {
        self.configuration = configuration
        self.label = label
    }
    
    var body: some View {
        content
            .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var content: some View {
        #if os(macOS)
        Button(action: open, label: label)
        #else
        NavigationLink(destination: destination, label: label)
        #endif
    }
    
    #if os(macOS)
    private func open() {
        listNavigator.set(configuration)
        panelNavigator.actived = .map
    }
    #else
    private func destination() -> NominationMap {
        .init(configuration)
    }
    #endif
}
