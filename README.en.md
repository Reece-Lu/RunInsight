<p align="center">
  <img src="RunInsight/Assets.xcassets/AppIcon.appiconset/RunInsightAppIcon.png" width="112" alt="RunInsight app icon">
</p>

<h1 align="center">RunInsight</h1>

<p align="center">
  <a href="README.md">中文</a> | English
</p>

<p align="center">
  A lightweight iOS running journal that syncs HealthKit workouts, organizes routes, pace, shoes, and performance metrics, and helps you understand each run with AI.
</p>

<p align="center">
  <img alt="SwiftUI" src="https://img.shields.io/badge/SwiftUI-iOS-3B86F6?style=flat-square">
  <img alt="HealthKit" src="https://img.shields.io/badge/HealthKit-Workout-F69A45?style=flat-square">
  <img alt="AI Coach" src="https://img.shields.io/badge/OpenAI%20%2B%20Qwen-AI%20Coach-68C96A?style=flat-square">
</p>

---

## Product

RunInsight is a focused training companion for everyday runners. It turns the runs you already record in Apple Health into a local, readable journal for reviewing, comparing, and understanding your training.

You can inspect distance, duration, pace, route, and performance metrics; assign shoes to runs and track shoe mileage; and ask AI Coach to analyze a selected run from summary data without uploading complete GPS tracks.

## Highlights

- **HealthKit run sync**: Import running workouts from HealthKit and keep a local SwiftData copy.
- **Route and detail review**: View route maps, start and finish markers, indoor/outdoor type, and key workout facts.
- **Shoe tracking**: Assign shoes to runs and automatically track mileage and run counts.
- **Performance metrics**: Review pace, heart rate, cadence, stride length, running power, vertical oscillation, ground contact time, and more.
- **AI Coach**: Use OpenAI or Qwen to generate a run summary, then ask follow-up training questions.
- **Privacy first**: AI receives summary metrics only, not full GPS coordinates or raw workout sample streams.

## Screens

| Runs | Shoes | AI Coach |
| --- | --- | --- |
| Sync HealthKit runs and filter by time range and indoor/outdoor type. | Track mileage, run counts, and photos for each pair of shoes. | Generate analysis from workout summaries and continue the conversation. |

## Privacy

RunInsight stores imported runs and shoe assignments locally. When AI Coach sends a request to OpenAI or Qwen, it sends only a summarized workout context such as distance, duration, pace, calories, shoe name, and aggregate metric ranges.

RunInsight does not send complete GPS tracks, point-by-point coordinates, or full raw sample streams. OpenAI API keys and DashScope API keys are stored separately in the iOS Keychain.

## Localization

RunInsight supports Simplified Chinese and English. The app follows the system language by default. On iOS, users can also override the language per app in Settings after the app declares both localizations.

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
