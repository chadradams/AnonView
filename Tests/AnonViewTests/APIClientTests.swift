import Foundation
import Testing
@testable import AnonView

@Test func apiEndpointsMatchExpectedFormat() {
    let client = APIClient()

    #expect(client.boardsURL()?.absoluteString == "https://a.4cdn.org/boards.json")
    #expect(client.catalogURL(boardID: "g")?.absoluteString == "https://a.4cdn.org/g/catalog.json")
    #expect(client.threadURL(boardID: "g", threadID: 12345)?.absoluteString == "https://a.4cdn.org/g/thread/12345.json")
}
