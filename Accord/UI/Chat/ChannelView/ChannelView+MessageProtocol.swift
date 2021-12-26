//
//  ChannelView+MessageProtocol.swift
//  ChannelView+MessageProtocol
//
//  Created by evelyn on 2021-08-23.
//

import Foundation
import SwiftUI

extension ChannelView: MessageControllerDelegate {
    func sendMessage(msg: Data, channelID: String?, isMe: Bool = false) {
        // Received a message from backend
        guard let channelID = channelID else { return }
        guard channelID == self.channelID else { return }
        webSocketQueue.async { [weak viewModel] in
            // sending = false
            guard let gatewayMessage = try? JSONDecoder().decode(GatewayMessage.self, from: msg) else { return }
            guard let message = gatewayMessage.d else { return }
            if viewModel?.guildID != "@me" && !(viewModel?.roles.keys.contains(message.author?.id ?? "") ?? false) {
                viewModel?.loadUser(for: message.author?.id)
            }
            for user in message.mentions.compactMap { $0?.id }.filter({ !(viewModel?.roles.keys.contains($0) ?? false) }) {
                viewModel?.loadUser(for: user)
            }
            if let firstMessage = viewModel?.messages.last {
                message.lastMessage = firstMessage
            }
            DispatchQueue.main.async {
                if let count = viewModel?.messages.count, count == 50 {
                    viewModel?.messages.removeFirst()
                }
                viewModel?.messages.append(message)
                if let view = viewModel?.scrollView?.documentView {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak view] in
                        if let floatValue = viewModel?.scrollView?.verticalScroller?.floatValue, floatValue >= 0.8 && floatValue != 1.0, let height = view?.bounds.size.height {
                            withAnimation(Animation.linear) {
                                view?.scroll(NSPoint(x: 0, y: height))
                            }
                        }
                    }
                }
            }
        }
    }
    func editMessage(msg: Data, channelID: String?) {
        // Received a message from backend
        guard let channelID = channelID else { return }
        guard channelID == self.channelID else { return }
        webSocketQueue.async {
            guard let gatewayMessage = try? JSONDecoder().decode(GatewayMessage.self, from: msg) else { return }
            guard let message = gatewayMessage.d else { return }
            guard let index = messageMap[message.id] as? Int else { return }
            DispatchQueue.main.async {
                viewModel.messages[index].content = message.content
            }
        }
    }
    func deleteMessage(msg: Data, channelID: String?) {
        guard let channelID = channelID else { return }
        guard channelID == self.channelID else { return }
        webSocketQueue.async { [weak viewModel] in
            let messageMap = viewModel?.messages.enumerated().compactMap { (index, element) in
                return [element.id:index]
            }.reduce(into: [:]) { (result, next) in
                result.merge(next) { (_, rhs) in rhs }
            }
            guard let gatewayMessage = try? JSONDecoder().decode(GatewayDeletedMessage.self, from: msg) else { return }
            guard let message = gatewayMessage.d else { return }
            guard let index = messageMap?[message.id] else { return }
            DispatchQueue.main.async { [weak viewModel] in
                withAnimation {
                    let i: Int = index
                    viewModel?.messages.remove(at: i)
                }
            }
        }
    }
    func typing(msg: [String: Any], channelID: String?) {
        guard let channelID = channelID else { return }
        guard channelID == self.channelID else { return }
        webSocketQueue.async { [weak viewModel] in
            if !(typing.contains(msg["user_id"] as? String ?? "")) {
                guard let memberData = try? JSONSerialization.data(withJSONObject: msg, options: []) else { return }
                guard let memberDecodable = try? JSONDecoder().decode(TypingEvent.self, from: memberData) else { return }
                guard let nick_fake = viewModel?.nicks[memberDecodable.user_id ?? ""] else {
                    guard let nick = memberDecodable.member?.nick else {
                        withAnimation {
                            typing.append(memberDecodable.member?.user.username ?? "")
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
                            guard !(typing.isEmpty) else { return }
                            _ = withAnimation {
                                typing.removeLast()
                            }
                        })
                        return
                    }
                    if !(typing.contains(nick)) {
                        withAnimation {
                            typing.append(nick)
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
                        guard !(typing.isEmpty) else { return }
                        _ = withAnimation {
                            typing.removeLast()
                        }
                    })
                    return
                }
                if !(typing.contains(nick_fake)) {
                    withAnimation {
                        typing.append(nick_fake)
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
                    guard !(typing.isEmpty) else { return }
                    _ = withAnimation {
                        typing.removeLast()
                    }
                })
            }

        }
    }
    func sendMemberList(msg: MemberListUpdate) {
        
    }
    func sendMemberChunk(msg: Data) {
        webSocketQueue.async { [weak viewModel] in
            guard let chunk = try? JSONDecoder().decode(GuildMemberChunkResponse.self, from: msg), let users = chunk.d?.members else { print(error as Any); return }
            let cache = Dictionary(uniqueKeysWithValues: zip(users.compactMap { $0?.user.id }, users.compactMap { $0?.nick ?? $0?.user.username }))
            print("received")
            ChannelMembers.shared.channelMembers[self.channelID] = cache
            let allUsers: [GuildMember] = users.compactMap { $0 }
            for person in allUsers {
                wss.cachedMemberRequest["\(guildID)$\(person.user.id)"] = person
                let nickname = person.nick ?? person.user.username
                DispatchQueue.main.async {
                    viewModel?.nicks[(person.user.id)] = nickname
                }
                if let roles = person.roles {
                    var rolesTemp: [String?] = Array.init(repeating: nil, count: 100)
                    for role in roles {
                        if let roleColor = roleColors[role]?.1 {
                            rolesTemp[roleColor] = role
                        }
                    }
                    let temp: [String] = (rolesTemp.compactMap { $0 }).reversed()
                    if !(temp.isEmpty) {
                        DispatchQueue.main.async {
                            viewModel?.roles[(person.user.id)] = temp[0]
                        }
                    }
                }
            }
        }
    }
    func sendWSError(msg: String) {
        error = msg
    }
}
