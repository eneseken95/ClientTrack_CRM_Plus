//
//  SearchViewModel.swift
//  ClientTrack CRM+
//
//  Created by Enes Eken on 29.12.2025.
//

import Combine
import Foundation

@MainActor
class SearchViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var searchResults: [ClientDTO] = []
    @Published var allClients: [ClientDTO] = []
    @Published var isSearching: Bool = false
    @Published var isLoadingAll: Bool = false
    @Published var errorMessage: String? = nil
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    init() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }

    func loadAllClients() async {
        guard allClients.isEmpty else { return }
        isLoadingAll = true
        do {
            let response = try await ClientsService.fetch(page: 1, size: 100)
            allClients = response.items
        } catch {}
        isLoadingAll = false
    }

    private func performSearch(query: String) {
        searchTask?.cancel()
        guard !query.isEmpty else {
            searchResults = []
            errorMessage = nil
            return
        }
        searchTask = Task {
            isSearching = true
            errorMessage = nil
            do {
                let results = try await SearchService.searchClients(query: query)
                guard !Task.isCancelled else { return }
                searchResults = results
                isSearching = false
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = "Failed to search: \(error.localizedDescription)"
                searchResults = []
                isSearching = false
            }
        }
    }

    func retry() {
        performSearch(query: searchQuery)
    }
}
