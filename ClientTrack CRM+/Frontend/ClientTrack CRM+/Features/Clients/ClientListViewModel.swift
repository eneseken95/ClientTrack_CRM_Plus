//
//  ClientListViewModel.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Foundation

@MainActor
final class ClientListViewModel: ObservableObject {
    enum LoadState {
        case idle
        case loadingInitial
        case loaded
        case loadingMore
        case error(String)
    }

    @Published private(set) var clients: [ClientDTO] = []
    @Published private(set) var totalClients: Int = 0
    @Published var searchText: String = ""
    @Published private(set) var state: LoadState = .idle
    private var updateNotificationToken: NSObjectProtocol?
    private var deleteNotificationToken: NSObjectProtocol?
    var filteredClients: [ClientDTO] {
        if searchText.isEmpty {
            return clients
        } else {
            return clients.filter { client in
                let companyMatch = client.company?.localizedCaseInsensitiveContains(searchText) ?? false
                let nameMatch = client.name.localizedCaseInsensitiveContains(searchText)
                let surnameMatch = client.surname?.localizedCaseInsensitiveContains(searchText) ?? false
                let emailMatch = client.email?.localizedCaseInsensitiveContains(searchText) ?? false
                return companyMatch || nameMatch || surnameMatch || emailMatch
            }
        }
    }

    init() {
        updateNotificationToken = NotificationCenter.default.addObserver(
            forName: .clientUpdated,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            guard
                let updated = notification.object as? ClientDTO
            else { return }
            Task { @MainActor in
                guard
                    let self,
                    let index = self.clients.firstIndex(where: { $0.id == updated.id })
                else { return }
                self.clients[index] = updated
            }
        }
        deleteNotificationToken = NotificationCenter.default.addObserver(
            forName: .clientDeleted,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            guard let clientId = notification.object as? Int else {
                return
            }
            Task { @MainActor in
                guard let self else { return }
                self.clients.removeAll { $0.id == clientId }
            }
        }
    }

    deinit {
        if let token = updateNotificationToken {
            NotificationCenter.default.removeObserver(token)
        }
        if let token = deleteNotificationToken {
            NotificationCenter.default.removeObserver(token)
        }
    }

    private var page = 1
    private let size = 20
    private var canLoadMore = true
    private var initialRequestDone = false

    func onViewAppear() async {
        guard !initialRequestDone else { return }
        initialRequestDone = true
        await loadInitial()
    }

    func refresh() async {
        initialRequestDone = true
        page = 1
        canLoadMore = true
        clients.removeAll()
        await loadInitial()
    }

    func loadMoreIfNeeded(currentItem: ClientDTO) async {
        guard
            canLoadMore,
            case .loaded = state,
            currentItem.id == clients.last?.id
        else { return }
        await loadMore()
    }

    private func loadInitial() async {
        state = .loadingInitial
        page = 1
        canLoadMore = true
        do {
            let res = try await ClientsService.fetch(page: page, size: size)
            clients = res.items
            totalClients = res.meta.total
            page += 1
            canLoadMore = clients.count < res.meta.total
            state = .loaded
        } catch {
            state = .error("Clients could not be loaded.")
        }
    }

    private func loadMore() async {
        guard case .loaded = state else { return }
        state = .loadingMore
        do {
            let res = try await ClientsService.fetch(page: page, size: size)
            clients.append(contentsOf: res.items)
            totalClients = res.meta.total
            page += 1
            canLoadMore = clients.count < res.meta.total
            state = .loaded
        } catch {
            state = .error("More clients could not be loaded.")
        }
    }

    func addClientToTop(_ client: ClientDTO) {
        clients.insert(client, at: 0)
        totalClients += 1
    }

    func removeClient(byId id: Int) {
        let oldCount = clients.count
        clients.removeAll { $0.id == id }
        if clients.count < oldCount {
            totalClients -= 1
        }
    }
}
