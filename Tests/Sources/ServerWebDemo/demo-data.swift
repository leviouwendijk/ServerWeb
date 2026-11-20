import Foundation

/// Typed source data the demo pages are rendered from.
struct DemoPackage: Codable, Sendable {
    let name: String
    let layer: DemoLayer
    let summary: String
}

enum DemoLayer: String, Codable, Sendable, CaseIterable {
    case wire
    case runtime
    case authoring
    case delivery

    var title: String {
        switch self {
        case .wire:
            return "Wire"
        case .runtime:
            return "Runtime"
        case .authoring:
            return "Authoring"
        case .delivery:
            return "Delivery"
        }
    }
}

enum DemoData {
    static let packages: [DemoPackage] = [
        DemoPackage(
            name: "HTTP",
            layer: .wire,
            summary: "Request, response, headers, status and grammar."
        ),
        DemoPackage(
            name: "Server",
            layer: .runtime,
            summary: "Engine, router, ServerProcess and client."
        ),
        DemoPackage(
            name: "HTML",
            layer: .authoring,
            summary: "Typed HTML nodes and the HTMLBuilder DSL."
        ),
        DemoPackage(
            name: "CSS",
            layer: .authoring,
            summary: "Typed rules, declarations and media queries."
        ),
        DemoPackage(
            name: "JS",
            layer: .authoring,
            summary: "Script sources and contributions."
        ),
        DemoPackage(
            name: "Constructors",
            layer: .authoring,
            summary: "Page graphs, rendering and static materialization."
        ),
        DemoPackage(
            name: "ServerWeb",
            layer: .delivery,
            summary: "Serves materialized artifacts on a port and opens the browser."
        ),
    ]

    static let jsonPath = "/data/packages.json"

    static func json() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        return String(
            decoding: try encoder.encode(packages),
            as: UTF8.self
        )
    }
}
