import SwiftUI
import SwiftData

struct SleepScheduleView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("currentUserId") private var currentUserId: String = ""
    @Query private var users: [User]

    @State private var bedtime = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var wakeUpTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var remPeriods: [REMPeriod] = []
    @State private var isSaved = false

    private var currentUser: User? {
        users.first { $0.userId == currentUserId }
    }

    var body: some View {
        Form {
            Section("就寝時間") {
                DatePicker("就寝", selection: $bedtime, displayedComponents: .hourAndMinute)
            }

            Section("起床時間") {
                DatePicker("起床", selection: $wakeUpTime, displayedComponents: .hourAndMinute)
            }

            Section {
                Button {
                    saveSchedule()
                } label: {
                    HStack {
                        Spacer()
                        Text("保存")
                        Spacer()
                    }
                }
            }

            if !remPeriods.isEmpty {
                Section("推定レム睡眠タイミング") {
                    ForEach(remPeriods) { period in
                        HStack {
                            Text("第\(period.cycleNumber)周期")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(formatted(period.startTime)) 〜 \(formatted(period.endTime))")
                        }
                    }
                }
            }

            if isSaved {
                Section {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("保存しました")
                    }
                }
            }
        }
        .navigationTitle("睡眠設定")
        .onAppear {
            loadSchedule()
        }
        .onChange(of: bedtime) {
            updateREMPeriods()
        }
        .onChange(of: wakeUpTime) {
            updateREMPeriods()
        }
    }

    private func loadSchedule() {
        if let schedule = currentUser?.sleepSchedule {
            bedtime = schedule.bedtime
            wakeUpTime = schedule.wakeUpTime
        }
        updateREMPeriods()
    }

    private func saveSchedule() {
        guard let user = currentUser else { return }

        if let schedule = user.sleepSchedule {
            schedule.bedtime = bedtime
            schedule.wakeUpTime = wakeUpTime
            schedule.updatedAt = Date()
        } else {
            let schedule = SleepSchedule(bedtime: bedtime, wakeUpTime: wakeUpTime)
            schedule.user = user
            user.sleepSchedule = schedule
            modelContext.insert(schedule)
        }

        try? modelContext.save()
        isSaved = true
        updateREMPeriods()
    }

    private func updateREMPeriods() {
        let times = SleepCycleService.resolveActualTimes(bedtime: bedtime, wakeUpTime: wakeUpTime)
        remPeriods = SleepCycleService.calculateREMPeriods(bedtime: times.actualBedtime, wakeUpTime: times.actualWakeUpTime)
    }

    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
