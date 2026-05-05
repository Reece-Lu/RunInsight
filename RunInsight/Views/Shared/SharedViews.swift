import SwiftUI

struct RunFilterControls: View {
    @Binding var selectedSummaryRange: SummaryRange
    @Binding var selectedLocationFilter: RunLocationFilter

    var body: some View {
        HStack(spacing: 10) {
            Menu {
                ForEach(SummaryRange.allCases, id: \.self) { range in
                    Button {
                        selectedSummaryRange = range
                    } label: {
                        Label(range.label, systemImage: selectedSummaryRange == range ? "checkmark" : "calendar")
                    }
                }
            } label: {
                FilterMenuLabel(title: "范围", value: selectedSummaryRange.label, systemImage: "calendar")
            }

            Menu {
                ForEach(RunLocationFilter.allCases, id: \.self) { filter in
                    Button {
                        selectedLocationFilter = filter
                    } label: {
                        Label(filter.label, systemImage: selectedLocationFilter == filter ? "checkmark" : filter.systemImage)
                    }
                }
            } label: {
                FilterMenuLabel(title: "类型", value: selectedLocationFilter.label, systemImage: selectedLocationFilter.systemImage)
            }

            Spacer(minLength: 0)
        }
    }
}

struct FilterMenuLabel: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))

            Text("\(title)：\(value)")
                .font(.footnote.weight(.semibold))
                .lineLimit(1)

            Image(systemName: "chevron.down")
                .font(.caption2.weight(.bold))
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.background, in: Capsule())
        .overlay {
            Capsule()
                .stroke(.separator.opacity(0.35), lineWidth: 1)
        }
    }
}

struct SummaryMetricTile: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(minHeight: 64)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct MetricView: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.footnote.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AppBackground: View {
    var body: some View {
        Color(red: 0.96, green: 0.97, blue: 0.98)
            .ignoresSafeArea()
    }
}

extension View {
    func cardStyle() -> some View {
        background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.separator.opacity(0.35), lineWidth: 1)
            }
    }
}
