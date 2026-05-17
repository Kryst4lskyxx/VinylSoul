import Testing
import Foundation
@testable import VinylSoul

struct KeychainManagerTests {
    private let service = "com.vinylsoul.test"
    private let account = "deepseek_api_key"

    @Test func writeReadDeleteCycle() throws {
        let manager = KeychainManager(service: service)

        // Write
        try manager.save(key: "sk-test-12345", account: account)

        // Read
        let key = try manager.read(account: account)
        #expect(key == "sk-test-12345")

        // Delete
        try manager.delete(account: account)

        // Verify deleted
        do {
            _ = try manager.read(account: account)
            Issue.record("Expected error after delete")
        } catch {
            // Expected
        }
    }
}
