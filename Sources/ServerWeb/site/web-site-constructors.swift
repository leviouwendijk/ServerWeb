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
