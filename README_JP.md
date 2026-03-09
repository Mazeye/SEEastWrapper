# SEEastWrapper

[中文](README.md) | [English](README_EN.md)

SEEastWrapper は、AR 向けに天体位置を計算する Swift Package です。  
ARKit に直接渡せる地平座標（方位角 / 高度角）を出力します。

## インストール

アプリ側の `Package.swift` に追加:

```swift
dependencies: [
    .package(url: "https://github.com/<your-org>/SEEastWrapper.git", from: "0.1.0")
]
```

target 依存に product を追加:

```swift
.product(
    name: "SEEastWrapper",
    package: "SEEastWrapper"
)
```

`SEEastWrapper` は、メンテナが管理する SwissEphemeris fork（`main`）に依存しています:

```swift
.package(url: "https://github.com/Mazeye/SwissEphemeris.git", branch: "main")
```

## クイックスタート

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

デフォルト出力:

- 二十八宿
- 太陽
- 月
- 天極（`tianji`）
- 五大惑星（水星・金星・火星・木星・土星）

`StarPositionList` の各要素:

- `azimuthDegrees`
- `altitudeDegrees`
- `id` / `displayName` / `category`

## 天体の拡張

設定追加だけで拡張できます:

- 標準名: `.standardName("Spica")`
- または J2000 座標: `.j2000(EquatorialJ2000(raDeg: ..., decDeg: ...))`

その配列を以下へ渡します:

```swift
RealStarPositionProvider(objects:)
```

## CLI デバッグ

任意の日時・経緯度を CLI で確認できます:

```bash
swift run SEEastWrapperDebugCLI --date 2026-03-09T20:00:00+08:00 --lat 39.9042 --lon 116.4074 --visible-only
```

主なオプション:

- `--date`: ISO8601 形式の時刻
- `--lat` / `--lon`: 緯度 / 経度
- `--visible-only`: 地平線より上のみ表示
- `--category`: `sun|moon|planet|star|lunarMansion`
- `--limit`: 上位 N 件のみ表示

## 謝辞とライセンス

- 本プロジェクトは Swiss Ephemeris の Swift wrapper エコシステムに基づいています。Vincent Smithers 氏および貢献者に感謝します。元リポジトリ: [`vsmithers1087/SwissEphemeris`](https://github.com/vsmithers1087/SwissEphemeris)（アーカイブ済み）。
- 依存先は、メンテナ管理の fork: [`Mazeye/SwissEphemeris`](https://github.com/Mazeye/SwissEphemeris) です。
- 上流は GNU General Public License（GPL-2.0 以上）です。本プロジェクトも GPL 互換の形で配布しています。再配布時はライセンス表記の保持と対応ソースコード提供を行ってください。
