//
//  NoninationCard.swift
//  Potori
//
//  Created by Lucka on 28/12/2020.
//

import SwiftUI

struct NominationItem: View {
    
    var nomination: Nomination
    
    var body: some View {
        let content = HStack(alignment: .center) {
            RemoteImage(nomination.imageURL)
                .scaledToFill()
                .frame(width: 50, height: 50)
                .cornerRadius(5)
            VStack(alignment: .leading) {
                HStack {
                    Text(nomination.title)
                        .font(.title2)
                        .lineLimit(1)
                }
                Text(
                    DateFormatter.localizedString(
                        from: nomination.statusCode == .pending ?
                            nomination.confirmedTime : nomination.resultTime,
                        dateStyle: .medium, timeStyle: .none
                    )
                )
                .font(.subheadline)
                .foregroundColor(.secondary)
            }.frame(height: 50, alignment: .top)
            
            Spacer()
            
            Image(systemName: nomination.statusData.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .foregroundColor(nomination.statusData.color)
        }
        
        #if os(macOS)
        content
        #else
        content.padding(.vertical, 5)
        #endif
    }
}

#if DEBUG
struct NominationItem_Previews: PreviewProvider {
    static var service: Service = Service.preview

    static var previews: some View {
        NominationItem(nomination: service.nominations[0])
    }
}
#endif
