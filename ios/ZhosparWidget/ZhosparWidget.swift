import WidgetKit
import SwiftUI

struct ZhosparWidgetEntry: TimelineEntry {
    let date: Date
    let displayDate: String
    let streak: Int
    let total: Int
    let done: Int
    let pct: Int
    let tasks: [TaskEntry]
}

struct TaskEntry: Identifiable {
    let id: String
    let title: String
    let time: String
    let isDone: Bool
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> ZhosparWidgetEntry {
        ZhosparWidgetEntry(
            date: Date(),
            displayDate: "Бүгін",
            streak: 5,
            total: 4,
            done: 2,
            pct: 50,
            tasks: [
                TaskEntry(id: "1", title: "Жобаны аяқтау", time: "10:00", isDone: true),
                TaskEntry(id: "2", title: "Кітап оқу", time: "18:30", isDone: false)
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ZhosparWidgetEntry) -> ()) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ZhosparWidgetEntry>) -> ()) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> ZhosparWidgetEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.zhospar.zhospar_app")
            ?? UserDefaults.standard

        let displayDate = userDefaults.string(forKey: "flutter.zhospar_widget_date") ?? "Бүгін"
        let streak = userDefaults.integer(forKey: "flutter.zhospar_widget_streak")
        let total = userDefaults.integer(forKey: "flutter.zhospar_widget_total")
        let done = userDefaults.integer(forKey: "flutter.zhospar_widget_done")
        let pct = userDefaults.integer(forKey: "flutter.zhospar_widget_pct")

        var tasks: [TaskEntry] = []
        if let rawJson = userDefaults.string(forKey: "flutter.zhospar_widget_tasks_json"),
           let data = rawJson.data(using: .utf8),
           let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            for item in jsonArray.prefix(3) {
                let id = item["id"] as? String ?? UUID().uuidString
                let title = item["title"] as? String ?? ""
                let time = item["time"] as? String ?? ""
                let isDone = item["isDone"] as? Bool ?? false
                tasks.append(TaskEntry(id: id, title: title, time: time, isDone: isDone))
            }
        }

        return ZhosparWidgetEntry(
            date: Date(),
            displayDate: displayDate,
            streak: streak,
            total: total,
            done: done,
            pct: pct,
            tasks: tasks
        )
    }
}

struct ZhosparWidgetSmallView: View {
    let entry: ZhosparWidgetEntry

    var body: some View {
        ZStack {
            Color(red: 0.11, green: 0.11, blue: 0.12)
            VStack(spacing: 4) {
                HStack {
                    Text("ZHOSPAR")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("🔥 \(entry.streak)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.58, blue: 0.0))
                }
                Spacer()
                Text("\(entry.pct)%")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                Text("\(entry.done)/\(entry.total) орындалды")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(12)
        }
    }
}

struct ZhosparWidgetMediumView: View {
    let entry: ZhosparWidgetEntry

    var body: some View {
        ZStack {
            Color(red: 0.11, green: 0.11, blue: 0.12)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("ZHOSPAR")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.white)
                    Text("• \(entry.displayDate)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("🔥 \(entry.streak) күн")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(6)
                        .foregroundColor(.orange)
                }

                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 5)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(red: 0.0, green: 0.48, blue: 1.0))
                            .frame(width: max(0, geometry.size.width * CGFloat(entry.pct) / 100), height: 5)
                    }
                }
                .frame(height: 5)

                // Task items
                if entry.tasks.isEmpty {
                    Text("• Бүгінге тапсырмалар жоқ")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                } else {
                    ForEach(entry.tasks.prefix(2)) { task in
                        HStack(spacing: 6) {
                            Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 10))
                                .foregroundColor(task.isDone ? .green : .gray)
                            if !task.time.isEmpty {
                                Text(task.time)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                            Text(task.title)
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                                .foregroundColor(task.isDone ? .gray : .white)
                        }
                    }
                }
            }
            .padding(14)
        }
    }
}

@main
struct ZhosparWidget: Widget {
    let kind: String = "ZhosparWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ZhosparWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("ZHOSPAR Widget")
        .description("Бүгінгі тапсырмалар мен серияны басты экранда көріңіз.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct ZhosparWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            ZhosparWidgetSmallView(entry: entry)
        default:
            ZhosparWidgetMediumView(entry: entry)
        }
    }
}
