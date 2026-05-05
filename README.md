# RunInsight

RunInsight is an iOS running journal built with SwiftUI. It reads running workouts from HealthKit, keeps a local SwiftData copy, visualizes route and performance metrics, tracks shoe mileage, and includes an OpenAI-powered running coach for workout summaries and follow-up questions.

## Features

- HealthKit running workout import
- Local workout history with SwiftData
- Indoor/outdoor classification from HealthKit metadata and route availability
- Route map with start and finish markers
- Running start-location map linked to filters
- Summary filters by time range and run type
- Running shoe cabinet with mileage and run counts
- Unassigned shoe mileage summary
- Add and edit shoe names and photos
- Workout detail metrics for distance, duration, pace, calories, route status, and shoes
- Performance charts for elevation, pace, speed, heart rate, running power, cadence, vertical oscillation, ground contact time, and stride length
- Interactive chart scrubbing to inspect values
- AI Coach tab backed by the OpenAI Responses API
- OpenAI API key storage in Keychain
- AI analysis based on summarized workout metrics rather than raw GPS tracks

## Screens

- **Run Dashboard**: recent mileage summary, filters, new-run sync banner, and start-location map.
- **Records**: synced workout list with shoe assignment and detail navigation.
- **Shoes**: shoe mileage cabinet, unassigned mileage, shoe photo/name editing.
- **Workout Detail**: route map, workout facts, HealthKit metadata, and performance charts.
- **AI Coach**: choose a run, generate a summary, and ask follow-up training questions.

## Tech Stack

- SwiftUI
- SwiftData
- HealthKit
- MapKit
- PhotosUI
- Keychain Services
- OpenAI Responses API

## Privacy

RunInsight stores imported workouts and shoe assignments locally with SwiftData.

The AI Coach sends only a summarized workout context to OpenAI, such as distance, duration, pace, calories, shoe name, and aggregate metrics like average heart rate, cadence, stride length, power, and metric ranges. It does not send full raw GPS coordinates or complete per-sample workout streams.

The OpenAI API key is stored locally in the iOS Keychain.

## Requirements

- Xcode with iOS SDK support
- iOS device or simulator
- HealthKit capability enabled
- Health data access granted by the user
- OpenAI API key for AI Coach features

Some HealthKit metrics, such as running power, vertical oscillation, ground contact time, and stride length, depend on the device and workout source. Runs that do not contain these samples will show unavailable metric cards.

## Setup

1. Open `RunInsight.xcodeproj` in Xcode.
2. Select the `RunInsight` scheme.
3. Confirm the HealthKit capability is enabled.
4. Build and run the app.
5. In the app, sync running workouts from HealthKit.
6. Open the AI Coach tab and add an OpenAI API key if you want AI analysis.

## Project Structure

```text
RunInsight/
  Models/        Domain models and SwiftData models
  Services/      HealthKit, OpenAI, and Keychain services
  ViewModels/    Observable view state and async loading
  Views/         SwiftUI screens and shared components
```

## Current Status

This is an early personal project. The app already supports local workout tracking, route visualization, shoe mileage, performance metrics, and a first version of AI coaching. Areas still evolving include deeper training insights, saved AI analysis history, richer charts, and test coverage.

## Roadmap

- Save AI analysis history per workout
- Add trend analysis across recent weeks
- Improve route-derived split pace calculations
- Add shoe retirement mileage alerts
- Add richer HealthKit metric summaries
- Improve empty states and onboarding
- Add unit tests for metric summarization and formatting

