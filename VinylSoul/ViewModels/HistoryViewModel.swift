import Foundation
import SwiftUI
import SwiftData

@Observable
final class HistoryViewModel {
    var records: [InspirationRecord] = []
    var searchText: String = ""
    var selectedMoodFilters: Set<String> = []
    var selectedStyleFilters: Set<String> = []
    var filterMode: FilterMode = .all

    enum FilterMode: String, CaseIterable {
        case all = "全部"
        case favorites = "收藏"
        case recent = "最近"
    }

    var filteredRecords: [InspirationRecord] {
        var result = records

        if filterMode == .favorites {
            result = result.filter { $0.isFavorite }
        }

        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.albumTitle.lowercased().contains(query)
                || $0.lyrics.lowercased().contains(query)
            }
        }

        if !selectedMoodFilters.isEmpty {
            result = result.filter { selectedMoodFilters.contains($0.moodRaw) }
        }

        if !selectedStyleFilters.isEmpty {
            result = result.filter { selectedStyleFilters.contains($0.styleTagRaw) }
        }

        if filterMode == .recent {
            result.sort { $0.timestamp > $1.timestamp }
        }

        return result
    }

    var moodFilterOptions: [String] { Mood.allCases.map(\.rawValue) }
    var styleFilterOptions: [String] { StyleTag.allCases.map(\.rawValue) }

    func fetch(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<InspirationRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        do {
            records = try modelContext.fetch(descriptor)
        } catch {
            print("Fetch failed: \(error)")
        }
    }

    func delete(_ record: InspirationRecord, modelContext: ModelContext) {
        modelContext.delete(record)
        fetch(modelContext: modelContext)
    }

    func toggleFavorite(_ record: InspirationRecord, modelContext: ModelContext) {
        record.isFavorite.toggle()
        do {
            try modelContext.save()
        } catch {
            record.isFavorite.toggle()
        }
    }

    var hasActiveFilters: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
        || !selectedMoodFilters.isEmpty
        || !selectedStyleFilters.isEmpty
        || filterMode != .all
    }

    func clearAllFilters() {
        searchText = ""
        selectedMoodFilters = []
        selectedStyleFilters = []
        filterMode = .all
    }

    func statsOverview() -> StatsOverview {
        StatsOverview.from(records)
    }

    func toggleMoodFilter(_ rawValue: String) {
        if selectedMoodFilters.contains(rawValue) {
            selectedMoodFilters.remove(rawValue)
        } else {
            selectedMoodFilters.insert(rawValue)
        }
    }

    func toggleStyleFilter(_ rawValue: String) {
        if selectedStyleFilters.contains(rawValue) {
            selectedStyleFilters.remove(rawValue)
        } else {
            selectedStyleFilters.insert(rawValue)
        }
    }
}
