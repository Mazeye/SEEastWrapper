# SEEastWrapper

[English](README_EN.md) | [日本語](README_JP.md)

一个可通过 Swift Package Manager 引用的星体位置计算库，面向 AR 场景输出地平坐标（方位角/高度角）。

## 安装

在 App 的 `Package.swift` 中添加：

```swift
dependencies: [
    .package(url: "https://github.com/<your-org>/SEEastWrapper.git", from: "0.1.0")
]
```

并在 target 依赖里加入：

```swift
.product(
    name: "SEEastWrapper",
    package: "SEEastWrapper"
)
```

`SEEastWrapper` 内部依赖维护者的 SwissEphemeris fork（`main` 分支）：

```swift
.package(url: "https://github.com/Mazeye/SwissEphemeris.git", branch: "main")
```

## 快速使用

```swift
import CoreLocation
import SEEastWrapper

let provider = RealStarPositionProvider()
let input = StarObservationInput(
    date: Date(),
    coordinate: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074)
)
let stars = provider.starPositions(input: input)
```

默认输出包含：二十八宿、日、月、天极、五大行星。

`stars` 为 `StarPositionList`，每个元素包含：

- `azimuthDegrees`（方位角）
- `altitudeDegrees`（高度角）
- `id` / `displayName` / `category`

可直接用于 ARKit 渲染。

## 扩展天体

新增天体只需配置：

- 标准名：`.standardName("Spica")`
- 或 J2000 坐标：`.j2000(EquatorialJ2000(raDeg: ..., decDeg: ...))`

然后传入 `RealStarPositionProvider(objects:)` 即可。

## CLI 调试（推荐）

可直接命令行输入时间和经纬度查询：

```bash
swift run SEEastWrapperDebugCLI --date 2026-03-09T20:00:00+08:00 --lat 39.9042 --lon 116.4074 --visible-only
```

常用参数：

- `--date`：ISO8601 时间
- `--lat` / `--lon`：经纬度
- `--visible-only`：只看地平线上方目标
- `--category`：`sun|moon|planet|star|lunarMansion`
- `--limit`：只显示前 N 个

## 致谢与许可证

- 本库基于 Swiss Ephemeris Swift wrapper 生态构建，感谢原作者 Vincent Smithers 及贡献者。原始项目地址：[`vsmithers1087/SwissEphemeris`](https://github.com/vsmithers1087/SwissEphemeris)（已归档）。
- 当前项目依赖并引用了维护者 fork：[`Mazeye/SwissEphemeris`](https://github.com/Mazeye/SwissEphemeris)。
- 原项目采用 GNU General Public License（GPL-2.0 或更高）。本项目以 GPL 兼容方式发布，请在再分发时遵循对应条款（保留版权与许可证声明，并提供对应源码）。
