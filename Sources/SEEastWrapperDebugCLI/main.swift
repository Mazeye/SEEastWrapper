import CoreLocation
import Foundation
import SEEastWrapper

struct CLIOptions {
    var date: Date = Date()
    var latitude: Double = 39.9042
    var longitude: Double = 116.4074
    var altitude: Double = 0
    var visibleOnly: Bool = false
    var category: StarARCategory? = nil
    var limit: Int? = nil
}

func printUsage() {
    let text = """
        SEEastWrapperDebugCLI

        用法:
          swift run SEEastWrapperDebugCLI [options]

        选项:
          --date <ISO8601>       查询时间，例如 2026-03-09T20:00:00+08:00
          --lat <Double>         纬度（默认 39.9042）
          --lon <Double>         经度（默认 116.4074）
          --alt <Double>         海拔米（默认 0）
          --visible-only         只显示地平线上方（alt > 0）的目标
          --category <name>      过滤类别: sun|moon|planet|star|lunarMansion
          --limit <Int>          仅显示前 N 个（按高度角降序）
          --help                 显示帮助

        示例:
          swift run SEEastWrapperDebugCLI --date 2026-03-09T20:00:00+08:00 --lat 31.2304 --lon 121.4737 --visible-only
        """
    print(text)
}

func parseISO8601(_ s: String) -> Date? {
    let fmt = ISO8601DateFormatter()
    fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let d = fmt.date(from: s) { return d }
    fmt.formatOptions = [.withInternetDateTime]
    return fmt.date(from: s)
}

func parseCategory(_ s: String) -> StarARCategory? {
    StarARCategory(rawValue: s)
}

func parseArgs() -> CLIOptions? {
    var opt = CLIOptions()
    let args = Array(CommandLine.arguments.dropFirst())
    var i = 0
    while i < args.count {
        let key = args[i]
        switch key {
        case "--help", "-h":
            printUsage()
            return nil
        case "--visible-only":
            opt.visibleOnly = true
        case "--date":
            guard i + 1 < args.count, let d = parseISO8601(args[i + 1]) else {
                print("错误: --date 参数无效")
                return nil
            }
            opt.date = d
            i += 1
        case "--lat":
            guard i + 1 < args.count, let v = Double(args[i + 1]) else {
                print("错误: --lat 参数无效")
                return nil
            }
            opt.latitude = v
            i += 1
        case "--lon":
            guard i + 1 < args.count, let v = Double(args[i + 1]) else {
                print("错误: --lon 参数无效")
                return nil
            }
            opt.longitude = v
            i += 1
        case "--alt":
            guard i + 1 < args.count, let v = Double(args[i + 1]) else {
                print("错误: --alt 参数无效")
                return nil
            }
            opt.altitude = v
            i += 1
        case "--category":
            guard i + 1 < args.count, let c = parseCategory(args[i + 1]) else {
                print("错误: --category 参数无效，可选 sun|moon|planet|star|lunarMansion")
                return nil
            }
            opt.category = c
            i += 1
        case "--limit":
            guard i + 1 < args.count, let n = Int(args[i + 1]), n > 0 else {
                print("错误: --limit 参数无效")
                return nil
            }
            opt.limit = n
            i += 1
        default:
            print("错误: 未知参数 \(key)")
            return nil
        }
        i += 1
    }
    return opt
}

guard let options = parseArgs() else {
    if CommandLine.arguments.count > 1 { exit(1) }
    printUsage()
    exit(0)
}

SwissEphBridge.setEphemerisPath()

let provider = RealStarPositionProvider()
let input = StarObservationInput(
    date: options.date,
    coordinate: CLLocationCoordinate2D(latitude: options.latitude, longitude: options.longitude),
    altitudeMeters: options.altitude
)

var stars = provider.starPositions(input: input)
if let category = options.category {
    stars = stars.filter { $0.category == category }
}
if options.visibleOnly {
    stars = stars.filter { $0.altitudeDegrees > 0 }
}
stars.sort { $0.altitudeDegrees > $1.altitudeDegrees }
if let limit = options.limit {
    stars = Array(stars.prefix(limit))
}

let df = ISO8601DateFormatter()
print("date: \(df.string(from: options.date))")
print("location: lat=\(options.latitude), lon=\(options.longitude), alt=\(options.altitude)m")
print("count: \(stars.count)")
print("--------------------------------------------")
for s in stars {
    let az = String(format: "%.2f", s.azimuthDegrees)
    let alt = String(format: "%.2f", s.altitudeDegrees)
    let cat = s.category?.rawValue ?? "-"
    print("[\(s.id)] \(s.displayName)\taz=\(az)\talt=\(alt)\tcat=\(cat)")
}
