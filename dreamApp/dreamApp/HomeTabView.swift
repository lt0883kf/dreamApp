import SwiftUI

struct HomeTabView: View {
    @AppStorage("currentUserId") private var currentUserId: String = ""

    var body: some View {
        TabView {
            Tab("睡眠設定", systemImage: "moon.zzz") {
                NavigationStack {
                    SleepScheduleView()
                        .toolbar {
                            ToolbarItem(placement: .automatic) {
                                Button("ログアウト") {
                                    currentUserId = ""
                                }
                            }
                        }
                }
            }

            Tab("音声", systemImage: "music.note") {
                NavigationStack {
                    AudioSettingsView()
                }
            }

            Tab("モニター", systemImage: "bed.double") {
                NavigationStack {
                    SleepMonitorView()
                }
            }
        }
    }
}
