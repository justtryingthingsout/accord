//
//  ChannelView+TextField.swift
//  ChannelView+TextField
//
//  Created by evelyn on 2021-08-23.
//

import Foundation
import SwiftUI

extension ChannelView {
    var blurredTextField: some View {
        return VStack(alignment: .leading) {
            HStack {
                if typing.count == 1 && !(typing.isEmpty) {
                    Text(channelID != "@me" ? "\(typing.map{ "\($0)" }.joined(separator: ", ")) is typing..." : "\(channelName) is typing...")
                        .padding(4)
                        .background(VisualEffectView(material: NSVisualEffectView.Material.sidebar, blendingMode: NSVisualEffectView.BlendingMode.withinWindow)) // blurred background
                        .cornerRadius(5)
                } else if !(typing.isEmpty) {
                    Text("\(typing.map{ "\($0)" }.joined(separator: ", ")) are typing...")
                        .lineLimit(0)
                        .padding(4)
                        .background(VisualEffectView(material: NSVisualEffectView.Material.sidebar, blendingMode: NSVisualEffectView.BlendingMode.withinWindow)) // blurred background
                        .cornerRadius(5)
                }
                if let replied = replyingTo {
                    Text("replying to \(replied.author?.username ?? "")")
                        .padding(4)
                        .background(VisualEffectView(material: NSVisualEffectView.Material.sidebar, blendingMode: NSVisualEffectView.BlendingMode.withinWindow)) // blurred background
                        .cornerRadius(5)
                }
            }
            if #available(macOS 12.0, *) {
                ChatControls(guildID: Binding.constant(guildID), channelID: Binding.constant(channelID), chatText: Binding.constant("Message #\(channelName)"), sending: $sending, replyingTo: $replyingTo, editing: $editing, users: Binding.constant(self.viewModel.messages.compactMap { $0.author }))
            } else {
                ChatControls(guildID: Binding.constant(guildID), channelID: Binding.constant(channelID), chatText: Binding.constant("Message #\(channelName)"), sending: $sending, replyingTo: $replyingTo, editing: $editing, users: Binding.constant(self.viewModel.messages.compactMap { $0.author }))
            }
        }
        .padding()
    }
}