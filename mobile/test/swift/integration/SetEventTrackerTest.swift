@_spi(YAMLValidation)
import Envoy
import EnvoyEngine
import Foundation
import TestExtensions
import XCTest

final class SetEventTrackerTest: XCTestCase {
  override static func setUp() {
    super.setUp()
    register_test_extensions()
  }

  func testEmitEventWithoutSettingEventTracker() throws {
    let eventExpectation =
      self.expectation(description: "Passed event tracker receives an event")

    let engine = YAMLValidatingEngineBuilder()
      .setEventTracker { event in
        XCTAssertEqual("bar", event["foo"])
        eventExpectation.fulfill()
      }
      .addNativeFilter(
        name: "envoy.filters.http.test_event_tracker",
        // swiftlint:disable:next line_length
        typedConfig: "{\"@type\":\"type.googleapis.com/envoymobile.extensions.filters.http.test_event_tracker.TestEventTracker\",\"attributes\":{\"foo\":\"bar\"}}")
      .build()

    let client = engine.streamClient()

    let requestHeaders = RequestHeadersBuilder(method: .get, scheme: "https",
                                               authority: "example.com", path: "/test")
      .build()

    client
      .newStreamPrototype()
      .start()
      .sendHeaders(requestHeaders, endStream: true)

    XCTAssertEqual(XCTWaiter.wait(for: [eventExpectation], timeout: 10), .completed)

    engine.terminate()
  }
}
