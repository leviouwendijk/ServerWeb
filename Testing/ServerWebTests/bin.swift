import Foundation
import Testing

@main
struct ServerWebTestMain {
    static func main() async {
        var failed = false
        for suite in [
            ServerWebSiteTestSuite.testSuite,
            ServerWebServeTestSuite.testSuite,
            ServerWebLiveTestSuite.testSuite,
        ] {
            let reporter = PlainTextTestReporter()
            let result = await TestRunner.run(suite, sink: reporter)
            let rendered = await reporter.rendered()
            if !rendered.isEmpty {
                print(rendered)
            }
            failed = failed || result.isFailure
        }
        if failed {
            exit(1)
        }
    }
}
