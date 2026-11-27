import Foundation
import Constructors
import Path

public extension WebAsset {
    init(
        artifact: StaticTextArtifact
    ) {
        self.init(
            path: artifact
                .output
                .url(
                    base: URL(fileURLWithPath: "/")
                )
                .path,
            contents: artifact.contents
        )
    }
}

public extension WebSite {
    /// Serves Constructors' serialized output from memory instead of writing it to disk.
    init(
        artifacts: [StaticTextArtifact],
        index: String = "/index.html"
    ) {
        self.init(
            assets: artifacts.map(
                WebAsset.init(artifact:)
            ),
            index: index
        )
    }

    init<Page>(
        materialization: StaticSerializedSiteMaterialization<Page>,
        index: String = "/index.html"
    ) {
        self.init(
            artifacts: materialization.artifacts,
            index: index
        )
    }
}

public extension WebSite {
    /// Serves an `ArtifactTree` from memory: every artifact at its planned
    /// path, as bytes (binary assets included).
    init(
        tree: ArtifactTree,
        index: String = "/index.html"
    ) throws {
        self.init(
            assets: try tree.entries.map { entry in
                WebAsset(
                    path: entry.path.rendered(asRootPath: true),
                    data: try tree.bytes(for: entry.key)
                )
            },
            index: index
        )
    }
}
