import Foundation
import SwiftUI
import SwiftData

@Observable
final class HistoryViewModel {
    var records: [InspirationRecord] = []

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
}
