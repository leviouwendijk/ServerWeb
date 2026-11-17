import Foundation
import ServerWeb

struct WebServeCommand {
    var directory: String?
    var host = "127.0.0.1"
    var port: UInt16?
    var open = false

    static let usage = """
    USAGE: webserve [<directory>] [--port <port>] [--host <host>] [--open]

      <directory>   Serve textual files (html, css, js, svg, json, ...) from this directory.
                    Without it, a built-in demo page is served.
      --port, -p    Port to bind (default: a free port).
      --host        Host to bind (default: 127.0.0.1).
      --open, -o    Open the served URL in the default browser.
    """

    static func parse(
        _ arguments: [String]
    ) throws -> WebServeCommand {
        var command = WebServeCommand()
        var iterator = arguments.makeIterator()

        while let argument = iterator.next() {
            switch argument {
            case "--help", "-h":
                throw WebServeCommandError.helpRequested

            case "--open", "-o":
                command.open = true

            case "--port", "-p":
                guard let value = iterator.next(),
                      let port = UInt16(value) else {
                    throw WebServeCommandError.invalid("--port expects a number between 0 and 65535")
                }
                command.port = port

            case "--host":
                guard let value = iterator.next() else {
                    throw WebServeCommandError.invalid("--host expects a value")
                }
                command.host = value

            default:
                guard !argument.hasPrefix("-"),
                      command.directory == nil else {
                    throw WebServeCommandError.invalid("Unexpected argument: \(argument)")
                }
                command.directory = argument
            }
        }

        return command
    }
}

enum WebServeCommandError: Error, LocalizedError {
    case helpRequested
    case invalid(String)

    var errorDescription: String? {
        switch self {
        case .helpRequested:
            return WebServeCommand.usage
        case .invalid(let message):
            return "\(message)\n\n\(WebServeCommand.usage)"
        }
    }
}

enum WebServeDemo {
    static let site = WebSite.page(
        html: """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>webserve</title>
        </head>
        <body>
          <main>
            <h1>webserve</h1>
            <p>ServerWeb is serving this page from memory.</p>
            <p id="clock"></p>
          </main>
        </body>
        </html>
        """,
        css: """
        :root { color-scheme: light dark; font-family: -apple-system, system-ui, sans-serif; }
        body { margin: 0; min-height: 100vh; display: grid; place-items: center; }
        main { max-width: 32rem; padding: 0 16px; }
        #clock { font-variant-numeric: tabular-nums; opacity: 0.7; }
        """,
        js: """
        const clock = document.getElementById("clock");
        const tick = () => { clock.textContent = new Date().toLocaleTimeString(); };
        tick();
        setInterval(tick, 1000);
        """
    )
}

@main
struct App {
    static func main() async {
        do {
            let command = try WebServeCommand.parse(
                Array(CommandLine.arguments.dropFirst())
            )

            let site: WebSite

            if let directory = command.directory {
                let load = try WebSite.directory(
                    at: URL(fileURLWithPath: directory)
                )

                for path in load.skipped {
                    printError("skipped (not textual): \(path)")
                }

                site = load.site
            } else {
                site = WebServeDemo.site
            }

            let server = try WebServer(
                site: site,
                host: command.host,
                port: command.port
            )

            let url = command.open
                ? try await server.startAndOpen()
                : try await server.start()

            print("webserve serving \(site.assets.count) assets on \(url.absoluteString)")

            switch try await server.waitForTermination() {
            case .stopped:
                Foundation.exit(0)
            case .failed(let message):
                printError(message)
                Foundation.exit(1)
            }
        } catch WebServeCommandError.helpRequested {
            print(WebServeCommand.usage)
            Foundation.exit(0)
        } catch {
            printError(error.localizedDescription)
            Foundation.exit(2)
        }
    }

    private static func printError(
        _ message: String
    ) {
        let text = message.hasSuffix("\n") ? message : "\(message)\n"

        FileHandle.standardError.write(
            Data(text.utf8)
        )
    }
}
