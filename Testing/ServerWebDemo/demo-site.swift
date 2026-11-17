import CSS
import Constructors
import Foundation
import HTML
import JS
import Path
import Primitives
import ServerWeb

/// Builds the demo site: HTML/CSS/JS DSL → Constructors render → static
/// materialization (write-free) → `WebSite`, plus the raw data as JSON.
enum DemoSite {
    static func build() throws -> WebSite {
        let projection = try graph()
            .resolve()
            .project(in: .public)

        let rendered = try RenderContext(projection: projection)
            .renderSite(state: DemoState(packages: DemoData.packages)) { page, state, _ in
                output(page: page, state: state)
            }

        let prepared = try StaticSiteMaterializer()
            .prepare(rendered)

        let site = WebSite(artifacts: prepared.artifacts)

        return WebSite(
            assets: site.assets + [
                WebAsset(
                    path: DemoData.jsonPath,
                    contents: try DemoData.json()
                ),
            ],
            index: site.index
        )
    }

    // MARK: - Graph

    static func graph() -> PageGraph<DemoPage> {
        PageGraph(
            roots: [
                DemoPage(
                    identifier: "home",
                    slug: nil,
                    title: "ServerWeb demo",
                    children: [
                        DemoPage(
                            identifier: "layers",
                            slug: PathSegment("layers", .directory),
                            title: "Layers"
                        ),
                    ]
                ),
            ]
        )
    }

    // MARK: - Pages

    static func output(
        page: PageProjection<DemoPage>,
        state: DemoState
    ) -> PageRenderOutput {
        let identifier = page.identifier.rawValue

        let content: [any HTMLNode]
        var scripts: [JSContribution] = [sharedScript]

        switch identifier {
        case "layers":
            content = layersContent(state: state)
        default:
            content = homeContent(state: state)
            scripts.append(filterScript)
        }

        return PageRenderOutput(
            document: HTMLDocument(
                attributes: HTMLDocumentAttributes(html: ["lang": "en"]),
                head: [
                    HTML.meta(["charset": "utf-8"]),
                    HTML.meta([
                        "name": "viewport",
                        "content": "width=device-width, initial-scale=1",
                    ]),
                    HTML.title(page.page.title),
                ],
                body: [
                    HTML.header(["class": "site-header"]) {
                        HTML.nav {
                            HTML.a("/", navAttributes(active: identifier == "home")) {
                                "Overview"
                            }
                            HTML.a("/layers/", navAttributes(active: identifier == "layers")) {
                                "Layers"
                            }
                        }
                    },
                    HTML.main(["class": "content"]) {
                        HTML.h1 {
                            page.page.title
                        }
                        content
                    },
                    HTML.footer(["class": "site-footer"]) {
                        HTML.p(["id": "status"]) {
                            "Loading data…"
                        }
                    },
                ]
            ),
            styles: CSSContributions([stylesheet]),
            scripts: JSContributions(scripts)
        )
    }

    static func navAttributes(
        active: Bool
    ) -> HTMLAttribute {
        active ? ["class": "active", "aria-current": "page"] : [:]
    }

    static func homeContent(
        state: DemoState
    ) -> [any HTMLNode] {
        [
            HTML.p {
                "Rendered from typed Swift data through the HTML, CSS and JS DSLs, materialized by Constructors and served from memory by ServerWeb."
            },
            HTML.input([
                "id": "filter",
                "type": "search",
                "placeholder": "Filter packages",
                "aria-label": "Filter packages",
            ]),
            HTML.table(["class": "packages"]) {
                HTML.thead {
                    HTML.tr {
                        HTML.th { "Package" }
                        HTML.th { "Layer" }
                        HTML.th { "Summary" }
                    }
                }
                HTML.tbody {
                    for package in state.packages {
                        HTML.tr([
                            "data-search": "\(package.name) \(package.layer.rawValue) \(package.summary)".lowercased(),
                        ]) {
                            HTML.td {
                                HTML.code { package.name }
                            }
                            HTML.td {
                                HTML.span(["class": "layer layer-\(package.layer.rawValue)"]) {
                                    package.layer.title
                                }
                            }
                            HTML.td { package.summary }
                        }
                    }
                }
            },
        ]
    }

    static func layersContent(
        state: DemoState
    ) -> [any HTMLNode] {
        DemoLayer.allCases.map { layer in
            HTML.section(["class": "layer-group"]) {
                HTML.h2 {
                    HTML.span(["class": "layer layer-\(layer.rawValue)"]) {
                        layer.title
                    }
                }
                HTML.ul {
                    for package in state.packages where package.layer == layer {
                        HTML.li {
                            HTML.code { package.name }
                            " — \(package.summary)"
                        }
                    }
                }
            }
        }
    }

    // MARK: - CSS

    static let stylesheet = CSSContribution(
        identifier: "demo-style",
        content: CSSContributionSet {
            CSS.rule(
                ":root",
                CSS.decl("--bg", "#f7f7f5"),
                CSS.decl("--fg", "#1d1d1b"),
                CSS.decl("--muted", "#6b6b66"),
                CSS.decl("--line", "#deded8"),
                CSS.decl("--accent", "#2a6f6a"),
                CSS.decl("color-scheme", "light dark")
            )
            CSS.media(
                "(prefers-color-scheme: dark)",
                CSS.rule(
                    ":root",
                    CSS.decl("--bg", "#161615"),
                    CSS.decl("--fg", "#ecece8"),
                    CSS.decl("--muted", "#9a9a94"),
                    CSS.decl("--line", "#2e2e2b"),
                    CSS.decl("--accent", "#6cc3bb")
                )
            )
            CSS.rule(
                "body",
                CSS.decl("margin", "0"),
                CSS.decl("background", "var(--bg)"),
                CSS.decl("color", "var(--fg)"),
                CSS.decl("font", "16px/1.5 -apple-system, system-ui, sans-serif")
            )
            CSS.rule(
                ".site-header, .content, .site-footer",
                CSS.decl("max-width", "56rem"),
                CSS.decl("margin", "0 auto"),
                CSS.decl("padding", "0 16px")
            )
            CSS.rule(
                ".site-header nav",
                CSS.decl("display", "flex"),
                CSS.decl("gap", "1rem"),
                CSS.decl("padding", "1rem 0"),
                CSS.decl("border-bottom", "1px solid var(--line)")
            )
            CSS.rule(
                "a",
                CSS.decl("color", "var(--accent)"),
                CSS.decl("text-decoration", "none")
            )
            CSS.rule(
                "a.active",
                CSS.decl("font-weight", "600"),
                CSS.decl("text-decoration", "underline")
            )
            CSS.rule(
                "#filter",
                CSS.decl("width", "100%"),
                CSS.decl("box-sizing", "border-box"),
                CSS.decl("padding", "0.5rem 0.75rem"),
                CSS.decl("margin", "0.5rem 0 1rem"),
                CSS.decl("border", "1px solid var(--line)"),
                CSS.decl("border-radius", "6px"),
                CSS.decl("background", "transparent"),
                CSS.decl("color", "inherit"),
                CSS.decl("font", "inherit")
            )
            CSS.rule(
                "table.packages",
                CSS.decl("width", "100%"),
                CSS.decl("border-collapse", "collapse")
            )
            CSS.rule(
                "table.packages th, table.packages td",
                CSS.decl("text-align", "left"),
                CSS.decl("padding", "0.5rem"),
                CSS.decl("border-bottom", "1px solid var(--line)"),
                CSS.decl("vertical-align", "top")
            )
            CSS.rule(
                ".layer",
                CSS.decl("display", "inline-block"),
                CSS.decl("padding", "0 0.5rem"),
                CSS.decl("border", "1px solid currentColor"),
                CSS.decl("border-radius", "999px"),
                CSS.decl("font-size", "0.85em"),
                CSS.decl("color", "var(--accent)")
            )
            CSS.rule(
                ".site-footer",
                CSS.decl("color", "var(--muted)"),
                CSS.decl("font-size", "0.9em"),
                CSS.decl("padding-top", "2rem")
            )
        }
    )

    // MARK: - JS

    static let sharedScript = JSContribution(
        identifier: "demo-status",
        script: .inline(
            JSSource(
                """
                (() => {
                  const status = document.getElementById("status");
                  if (!status) return;
                  fetch("\(DemoData.jsonPath)")
                    .then((response) => response.json())
                    .then((packages) => {
                      status.textContent = `${packages.length} packages loaded from \(DemoData.jsonPath) at ${new Date().toLocaleTimeString()}`;
                    })
                    .catch((error) => {
                      status.textContent = `Data fetch failed: ${error}`;
                    });
                })();
                """
            )
        )
    )

    static let filterScript = JSContribution(
        identifier: "demo-filter",
        script: .inline(
            JSSource(
                """
                (() => {
                  const input = document.getElementById("filter");
                  if (!input) return;
                  input.addEventListener("input", () => {
                    const query = input.value.trim().toLowerCase();
                    document.querySelectorAll("tr[data-search]").forEach((row) => {
                      row.hidden = query.length > 0 && !row.dataset.search.includes(query);
                    });
                  });
                })();
                """
            )
        )
    )
}

// MARK: - Graph types

struct DemoState: Sendable {
    let packages: [DemoPackage]
}

struct DemoPageIdentifier: StringIdentifier {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }
}

struct DemoPage: PageGraphNode {
    let identifier: DemoPageIdentifier
    let slug: PathSegment?
    let title: String
    let visibility: Set<BuildEnvironment>
    let children: [DemoPage]

    init(
        identifier: DemoPageIdentifier,
        slug: PathSegment?,
        title: String,
        visibility: Set<BuildEnvironment> = [.local, .test, .public],
        children: [DemoPage] = []
    ) {
        self.identifier = identifier
        self.slug = slug
        self.title = title
        self.visibility = visibility
        self.children = children
    }
}
