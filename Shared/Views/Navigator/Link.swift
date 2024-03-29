//
//  Links.swift
//  Potori
//
//  Created by Lucka on 10/7/2021.
//

import SwiftUI

struct ListLink<Label: View>: View {
    #if os(macOS)
    @EnvironmentObject var navigator: Navigator
    #endif
    private let configuration: Navigator.Configuration
    private let label: () -> Label
    
    init(_ configuration: Navigator.Configuration, @ViewBuilder label: @escaping () -> Label) {
        self.configuration = configuration
        self.label = label
    }
    
    var body: some View {
        #if os(macOS)
        Button(action: { navigator.open(.list, with: configuration) }, label: label)
            .buttonStyle(.plain)
        #else
        NavigationLink(destination: { NominationList(configuration) }, label: label)
        #endif
    }
}

struct DetailsLink<Label: View>: View {

    #if os(macOS)
    @Environment(\.openURL) private var openURL
    #endif
    
    private let nomination: Nomination
    private let label: () -> Label
    
    init(_ nomination: Nomination, @ViewBuilder label: @escaping () -> Label) {
        self.nomination = nomination
        self.label = label
    }
    
    var body: some View {
        #if os(macOS)
        Button(
            action: {
                if let url = URL(string: "potori://details/\(nomination.id)") {
                    openURL(url)
                }
            },
            label: label
        )
            .contentShape(Rectangle())
            .buttonStyle(.plain)
        #else
        NavigationLink(destination: { NominationDetails(nomination: nomination) }, label: label)
        #endif
    }
}

struct MapLink<Label: View>: View {
    #if os(macOS)
    @EnvironmentObject var navigator: Navigator
    #endif
    private let configuration: Navigator.Configuration
    private let label: () -> Label
    
    init(_ configuration: Navigator.Configuration, @ViewBuilder label: @escaping () -> Label) {
        self.configuration = configuration
        self.label = label
    }
    
    var body: some View {
        #if os(macOS)
        Button(action: { navigator.open(.map, with: configuration) }, label: label)
            .buttonStyle(.plain)
        #else
        NavigationLink(destination: { NominationMap(configuration) }, label: label)
        #endif
    }
}
