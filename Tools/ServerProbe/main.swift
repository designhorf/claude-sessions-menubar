import Foundation

// Scans the live machine, and with --stop <port> stops that server and scans again.
// Lets the scanner and the stopper be checked against real processes without the panel.
func list() {
    let servers = ServerScanner.scan()
    print("servers: \(servers.count)")
    for s in servers { print("  \(s.projectName)  \(s.portList)  \(s.age)  \(s.memory)  pid \(s.pid)") }
}

list()
let args = CommandLine.arguments
if let i = args.firstIndex(of: "--stop"), i + 1 < args.count, let port = Int(args[i + 1]),
   let target = ServerScanner.scan().first(where: { $0.ports.contains(port) }) {
    print("stopping \(target.projectName)")
    ServerStopper.stop(target)
    Thread.sleep(forTimeInterval: 4.5)
    list()
}
