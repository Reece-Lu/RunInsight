import PhotosUI
import SwiftData
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

struct ShoesView: View {
    let shoes: [RunningShoe]
    let workouts: [RunWorkout]
    let unassignedDistanceMeters: Double
    let distanceMeters: (RunningShoe, [RunWorkout]) -> Double
    let runCount: (RunningShoe, [RunWorkout]) -> Int
    @State private var isAddingShoe = false
    @State private var editingShoe: RunningShoe?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ShoeCabinetSummary(
                            shoes: shoes,
                            workouts: workouts,
                            unassignedDistanceMeters: unassignedDistanceMeters,
                            distanceMeters: distanceMeters
                        )

                        VStack(alignment: .leading, spacing: 10) {
                            Text("我的跑鞋")
                                .font(.headline)

                            if shoes.isEmpty {
                                EmptyShoeCabinetView {
                                    isAddingShoe = true
                                }
                            }

                            ForEach(shoes) { shoe in
                                ShoeCard(
                                    shoe: shoe,
                                    distanceMeters: distanceMeters(shoe, workouts),
                                    runCount: runCount(shoe, workouts),
                                    edit: {
                                        editingShoe = shoe
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("跑鞋")
            .toolbar {
                Button {
                    isAddingShoe = true
                } label: {
                    Label("添加跑鞋", systemImage: "plus")
                }
            }
            .sheet(isPresented: $isAddingShoe) {
                AddShoeView()
            }
            .sheet(item: $editingShoe) { shoe in
                EditShoeView(shoe: shoe)
            }
        }
    }
}

struct ShoeCabinetSummary: View {
    let shoes: [RunningShoe]
    let workouts: [RunWorkout]
    let unassignedDistanceMeters: Double
    let distanceMeters: (RunningShoe, [RunWorkout]) -> Double

    private var assignedDistanceMeters: Double {
        shoes.reduce(0) { total, shoe in
            total + distanceMeters(shoe, workouts)
        }
    }

    private var totalDistanceMeters: Double {
        assignedDistanceMeters + unassignedDistanceMeters
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("鞋柜总览")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(alignment: .bottom) {
                Text(assignedDistanceMeters.distanceText)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                Text("已绑定里程")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 7)
            }

            Text("\(shoes.count) 双跑鞋 · 给跑步记录选择跑鞋后自动累计")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Divider()

            HStack(spacing: 10) {
                ShoeCabinetSummaryMetric(
                    title: "总历史里程",
                    value: totalDistanceMeters.distanceText,
                    systemImage: "sum",
                    tint: .blue
                )

                ShoeCabinetSummaryMetric(
                    title: "未绑定里程",
                    value: unassignedDistanceMeters.distanceText,
                    systemImage: "exclamationmark.circle.fill",
                    tint: .orange
                )
            }
        }
        .padding(18)
        .cardStyle()
    }
}

struct ShoeCabinetSummaryMetric: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 58)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct ShoeCard: View {
    let shoe: RunningShoe
    let distanceMeters: Double
    let runCount: Int
    let edit: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ShoePhotoView(photoData: shoe.photoData, size: 76)

            VStack(alignment: .leading, spacing: 8) {
                Text(shoe.name)
                    .font(.headline)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    Label(distanceMeters.distanceText, systemImage: "road.lanes")
                    Label("\(runCount) 次", systemImage: "figure.run")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: edit) {
                Image(systemName: "pencil")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.blue)
                    .frame(width: 34, height: 34)
                    .background(.blue.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("编辑 \(shoe.name)")
        }
        .padding(14)
        .cardStyle()
    }
}

struct EmptyShoeCabinetView: View {
    let addShoe: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "shoeprints.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.orange)

            VStack(spacing: 6) {
                Text("还没有跑鞋")
                    .font(.headline)
                Text("添加你的第一双跑鞋后，就可以把每次跑步绑定到它。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                addShoe()
            } label: {
                Label("添加跑鞋", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(18)
        .cardStyle()
    }
}

struct AddShoeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            ShoePhotoView(photoData: photoData, size: 120)
                                .overlay(alignment: .bottomTrailing) {
                                    Image(systemName: "camera.fill")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 30, height: 30)
                                        .background(.orange, in: Circle())
                                }
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                Section("跑鞋信息") {
                    TextField("跑鞋名称", text: $name)
                }
            }
            .navigationTitle("添加跑鞋")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        addShoe()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .task(id: selectedPhoto) {
                guard let selectedPhoto else {
                    return
                }

                photoData = try? await selectedPhoto.loadTransferable(type: Data.self)
            }
        }
    }

    private func addShoe() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            return
        }

        modelContext.insert(RunningShoe(name: trimmedName, photoData: photoData))
        try? modelContext.save()
    }
}

struct EditShoeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let shoe: RunningShoe
    @State private var name: String
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?

    init(shoe: RunningShoe) {
        self.shoe = shoe
        _name = State(initialValue: shoe.name)
        _photoData = State(initialValue: shoe.photoData)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()

                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            ShoePhotoView(photoData: photoData, size: 120)
                                .overlay(alignment: .bottomTrailing) {
                                    Image(systemName: "camera.fill")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 30, height: 30)
                                        .background(.orange, in: Circle())
                                }
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                Section("跑鞋信息") {
                    TextField("跑鞋名称", text: $name)

                    if photoData != nil {
                        Button(role: .destructive) {
                            photoData = nil
                        } label: {
                            Label("移除照片", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("编辑跑鞋")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveShoe()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .task(id: selectedPhoto) {
                guard let selectedPhoto else {
                    return
                }

                photoData = try? await selectedPhoto.loadTransferable(type: Data.self)
            }
        }
    }

    private func saveShoe() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            return
        }

        shoe.name = trimmedName
        shoe.photoData = photoData
        try? modelContext.save()
    }
}

struct ShoePhotoView: View {
    let photoData: Data?
    let size: CGFloat

    var body: some View {
        Group {
            if let platformImage {
                platformImage
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "shoeprints.fill")
                    .font(.system(size: size * 0.34, weight: .semibold))
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.orange.opacity(0.12))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var platformImage: Image? {
        guard let photoData else {
            return nil
        }

        #if canImport(UIKit)
        if let image = UIImage(data: photoData) {
            return Image(uiImage: image)
        }
        #elseif canImport(AppKit)
        if let image = NSImage(data: photoData) {
            return Image(nsImage: image)
        }
        #endif

        return nil
    }
}
