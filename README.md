<p align="center">
  <img src="RunInsight/Assets.xcassets/AppIcon.appiconset/RunInsightAppIcon.png" width="112" alt="RunInsight app icon">
</p>

<h1 align="center">RunInsight</h1>

<p align="center">
  中文 | <a href="README.en.md">English</a>
</p>

<p align="center">
  一个更懂跑步记录的 iOS 跑步日志。同步 HealthKit 跑步数据，整理路线、配速、跑鞋与训练表现，并用 AI 帮你读懂每一次有氧跑。
</p>

<p align="center">
  <img alt="SwiftUI" src="https://img.shields.io/badge/SwiftUI-iOS-3B86F6?style=flat-square">
  <img alt="HealthKit" src="https://img.shields.io/badge/HealthKit-Workout-F69A45?style=flat-square">
  <img alt="AI Coach" src="https://img.shields.io/badge/OpenAI%20%2B%20Qwen-AI%20Coach-68C96A?style=flat-square">
</p>

---

## Product

RunInsight 是一个为日常跑者设计的轻量训练伙伴。它不是复杂的竞技仪表盘，而是把你已经记录在 Apple Health 里的跑步，变成更容易回顾、比较和理解的训练记录。

你可以查看每次跑步的距离、时长、配速、路线和表现指标；给跑步绑定跑鞋，自动累计鞋子的使用里程；也可以让 AI Coach 使用 OpenAI 或通义千问基于摘要数据分析一次训练，而不上传完整 GPS 轨迹。

## Highlights

- **跑步记录同步**：从 HealthKit 导入跑步训练，保留本地 SwiftData 副本。
- **路线与详情回顾**：查看路线地图、起终点、室内/户外类型和关键训练指标。
- **跑鞋管理**：为每次跑步绑定跑鞋，自动累计里程和使用次数。
- **表现指标**：支持配速、心率、步频、步幅、跑步功率、垂直振幅、触地时间等数据展示。
- **AI 教练**：支持 OpenAI 和通义千问，选择一次跑步生成摘要分析，并继续提问训练建议。
- **隐私优先**：AI 只接收统计摘要，不发送完整 GPS 坐标或逐点原始样本。

## Screens

| 跑步记录 | 跑鞋 | AI 教练 |
| --- | --- | --- |
| 同步 HealthKit 跑步，按时间范围和室内/户外筛选。 | 记录每双跑鞋的累计里程、次数和照片。 | 基于训练摘要生成分析，并支持继续追问。 |

## Privacy

RunInsight 的跑步记录和跑鞋数据保存在本机。AI Coach 请求 OpenAI 或通义千问时，只发送整理后的训练摘要，例如距离、时长、配速、消耗、跑鞋名称和聚合指标范围。

不会发送完整 GPS 轨迹、逐点坐标或完整原始采样流。OpenAI API Key 和 DashScope API Key 分别存储在 iOS Keychain 中。

## Localization

RunInsight 支持简体中文和英文。App 默认跟随 iOS 系统语言；当 app 声明了这两种本地化后，用户也可以在 iOS 设置中为单个 app 单独选择语言。

## Tech Stack

- SwiftUI
- SwiftData
- HealthKit
- MapKit
- PhotosUI
- Keychain Services
- OpenAI Responses API
- Alibaba Cloud Model Studio OpenAI-compatible Chat Completions API

## Requirements

- Xcode with iOS SDK support
- iOS device or simulator
- HealthKit capability enabled
- Health data access granted by the user
- OpenAI API key or DashScope API key for AI Coach features

Some HealthKit metrics, such as running power, vertical oscillation, ground contact time, and stride length, depend on the device and workout source. Runs without those samples will show unavailable metric cards.

## Setup

1. Open `RunInsight.xcodeproj` in Xcode.
2. Select the `RunInsight` scheme.
3. Confirm the HealthKit capability is enabled.
4. Build and run the app.
5. Sync running workouts from HealthKit.
6. Open the AI Coach tab and add an OpenAI API key or DashScope API key if you want AI analysis.

## Project Structure

```text
RunInsight/
  Models/        Domain models and SwiftData models
  Services/      HealthKit, AI provider, and Keychain services
  ViewModels/    Observable view state and async loading
  Views/         SwiftUI screens and shared components
```

## Roadmap

- Save AI analysis history per workout
- Add trend analysis across recent weeks
- Improve route-derived split pace calculations
- Add shoe retirement mileage alerts
- Add richer HealthKit metric summaries
- Improve empty states and onboarding
- Add unit tests for metric summarization and formatting
