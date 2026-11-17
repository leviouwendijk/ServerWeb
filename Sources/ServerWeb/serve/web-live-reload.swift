import Foundation
import HTTP
import Server

/// Poll-based live reload: pages carry the token they were served with and
/// poll `endpoint`; a different token (site replaced, or server restarted)
/// reloads the page. Unreachable server → keep polling, so a restart on the
/// same port reloads too.
public enum WebLiveReload {
    public static let endpoint = "/__serverweb/reload"
    public static let marker = "data-serverweb-live-reload"
    public static let intervalMilliseconds = 500

    public static func script(
        token: String
    ) -> String {
        """
        <script \(marker)>
        (() => {
          const endpoint = "\(endpoint)";
          const served = "\(token)";
          const poll = async () => {
            try {
              const response = await fetch(endpoint, { cache: "no-store" });
              const current = (await response.text()).trim();
              if (current !== served) {
                location.reload();
                return;
              }
            } catch (_) {}
            setTimeout(poll, \(intervalMilliseconds));
          };
          setTimeout(poll, \(intervalMilliseconds));
        })();
        </script>
        """
    }

    /// Inserts the reload script before the last `</body>`, or appends it.
    public static func inject(
        token: String,
        into html: String
    ) -> String {
        let tag = script(token: token)

        guard let range = html.range(
            of: "</body>",
            options: [.caseInsensitive, .backwards]
        ) else {
            return html + "\n" + tag
        }

        var copy = html
        copy.insert(
            contentsOf: tag + "\n",
            at: range.lowerBound
        )
        return copy
    }

    public static func route(
        store: WebSiteStore
    ) -> Route {
        Route(
            method: .get,
            path: endpoint
        ) { _, _ in
            HTTPResponse(
                status: .ok,
                headers: [
                    "Content-Type": "text/plain; charset=utf-8",
                    "Cache-Control": "no-store",
                ],
                body: store.token
            )
        }
    }
}
