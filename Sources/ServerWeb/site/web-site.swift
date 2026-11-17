import Foundation

public struct WebSite: Sendable {
    public let assets: [WebAsset]

    /// Asset served at `/`.
    public let index: String

    public init(
        assets: [WebAsset],
        index: String = "/index.html"
    ) {
        self.assets = assets
        self.index = WebAsset.normalized(
            index
        )
    }

    public func asset(
        at path: String
    ) -> WebAsset? {
        let normalized = WebAsset.normalized(
            path
        )

        return assets.first {
            $0.path == normalized
        }
    }
}

public extension WebSite {
    static let stylesheetPath = "/style.css"
    static let scriptPath = "/app.js"

    /// Serves raw HTML, CSS and JS as `/index.html`, `/style.css` and `/app.js`.
    ///
    /// The stylesheet and script references are injected into the HTML when
    /// it does not reference them already.
    static func page(
        html: String,
        css: String? = nil,
        js: String? = nil
    ) -> WebSite {
        var document = html
        var assets: [WebAsset] = []

        if let css {
            assets.append(
                WebAsset(
                    path: stylesheetPath,
                    contents: css
                )
            )

            if !document.contains(stylesheetPath) {
                document = inject(
                    "<link rel=\"stylesheet\" href=\"\(stylesheetPath)\">",
                    before: "</head>",
                    in: document,
                    prepend: true
                )
            }
        }

        if let js {
            assets.append(
                WebAsset(
                    path: scriptPath,
                    contents: js
                )
            )

            if !document.contains(scriptPath) {
                document = inject(
                    "<script src=\"\(scriptPath)\"></script>",
                    before: "</body>",
                    in: document,
                    prepend: false
                )
            }
        }

        assets.insert(
            WebAsset(
                path: "/index.html",
                contents: document
            ),
            at: 0
        )

        return WebSite(
            assets: assets
        )
    }

    private static func inject(
        _ tag: String,
        before marker: String,
        in document: String,
        prepend: Bool
    ) -> String {
        if let range = document.range(
            of: marker,
            options: .caseInsensitive
        ) {
            var copy = document
            copy.insert(
                contentsOf: tag,
                at: range.lowerBound
            )
            return copy
        }

        return prepend ? tag + "\n" + document : document + "\n" + tag
    }
}
