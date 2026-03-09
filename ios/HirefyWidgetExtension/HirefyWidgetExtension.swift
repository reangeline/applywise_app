//
//  HirefyWidgetExtension.swift
//  HirefyWidgetExtension
//

import WidgetKit
import SwiftUI

// MARK: - Data Model

struct HirefyEntry: TimelineEntry {
    let date: Date
    let userName: String
    let isPro: Bool
    let credits: Int
    let resumeCount: Int
}

// MARK: - Provider

struct HirefyProvider: TimelineProvider {

    private let appGroupId = "group.careers.hirefy.app"

    func placeholder(in context: Context) -> HirefyEntry {
        HirefyEntry(date: Date(), userName: "User", isPro: false, credits: 3, resumeCount: 2)
    }

    func getSnapshot(in context: Context, completion: @escaping (HirefyEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HirefyEntry>) -> Void) {
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry()], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func entry() -> HirefyEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        return HirefyEntry(
            date: Date(),
            userName: defaults?.string(forKey: "userName") ?? "Hirefy",
            isPro: defaults?.bool(forKey: "isPro") ?? false,
            credits: defaults?.integer(forKey: "credits") ?? 0,
            resumeCount: defaults?.integer(forKey: "resumeCount") ?? 0
        )
    }
}

// MARK: - Colors

private extension Color {
    static let hirefyPrimary       = Color(red: 0.24, green: 0.39, blue: 0.95)
    static let hirefyTextSecondary = Color(red: 0.424, green: 0.451, blue: 0.502)
}

// MARK: - Widget Background Modifier

private struct WidgetBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.containerBackground(.background, for: .widget)
        } else {
            content
                .padding()
                .background(Color(.systemBackground))
        }
    }
}

private extension View {
    func widgetBackground() -> some View {
        modifier(WidgetBackground())
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: HirefyEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.hirefyPrimary)
                Spacer()
                if entry.isPro {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.yellow)
                }
            }
            Spacer()
            Text("\(entry.resumeCount)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Color.hirefyPrimary)
                .minimumScaleFactor(0.7)
            Text("resumes")
                .font(.system(size: 11))
                .foregroundStyle(Color.hirefyTextSecondary)
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.hirefyPrimary)
                Text("\(entry.credits) credits")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.hirefyTextSecondary)
            }
        }
        .padding(14)
        .widgetBackground()
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: HirefyEntry

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.hirefyPrimary)
                    Text("Hirefy")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.primary)
                }
                Text("Hi, \(entry.userName)!")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: entry.isPro ? "crown.fill" : "person.circle")
                        .font(.system(size: 11))
                        .foregroundStyle(entry.isPro ? .yellow : Color.hirefyPrimary)
                    Text(entry.isPro ? "PRO" : "Free Plan")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(entry.isPro ? .yellow : Color.hirefyPrimary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(entry.isPro ? Color.yellow.opacity(0.15) : Color.hirefyPrimary.opacity(0.1))
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider().padding(.vertical, 12)

            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.hirefyPrimary)
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(entry.resumeCount)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("Resumes")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.hirefyTextSecondary)
                    }
                    Spacer()
                }
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.hirefyPrimary)
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(entry.credits)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("Credits")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.hirefyTextSecondary)
                    }
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(14)
        .widgetBackground()
    }
}

// MARK: - Entry View

struct HirefyEntryView: View {
    let entry: HirefyEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        default:
            MediumWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget

struct HirefyWidget: Widget {
    let kind: String = "HirefyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HirefyProvider()) { entry in
            HirefyEntryView(entry: entry)
                .widgetURL(URL(string: "hirefyapp://home"))
        }
        .configurationDisplayName("Hirefy")
        .description("Track your resumes and credits at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
