import Foundation

struct REMPeriod: Identifiable {
    let id = UUID()
    let startTime: Date
    let endTime: Date
    let cycleNumber: Int
}

enum SleepCycleService {
    /// 1サイクル: 約90分
    static let cycleDurationMinutes: Double = 90
    /// 入眠潜時: 約14分
    static let sleepOnsetLatencyMinutes: Double = 14
    /// 初回レム睡眠: 約10分
    static let initialREMDurationMinutes: Double = 10
    /// サイクルごとのレム睡眠増加分: 約5分
    static let remDurationIncrementMinutes: Double = 5

    /// 就寝時間と起床時間からレム睡眠の時間帯を計算する
    static func calculateREMPeriods(bedtime: Date, wakeUpTime: Date) -> [REMPeriod] {
        let sleepOnset = bedtime.addingTimeInterval(sleepOnsetLatencyMinutes * 60)
        var periods: [REMPeriod] = []
        var cycleStart = sleepOnset
        var cycleNumber = 1

        while true {
            let cycleEnd = cycleStart.addingTimeInterval(cycleDurationMinutes * 60)
            let remDuration = initialREMDurationMinutes + Double(cycleNumber - 1) * remDurationIncrementMinutes
            let remStart = cycleEnd.addingTimeInterval(-remDuration * 60)

            if remStart >= wakeUpTime { break }

            let clampedEnd = min(remEnd: cycleEnd, wakeUp: wakeUpTime)
            periods.append(REMPeriod(
                startTime: remStart,
                endTime: clampedEnd,
                cycleNumber: cycleNumber
            ))

            cycleStart = cycleEnd
            cycleNumber += 1
        }
        return periods
    }

    private static func min(remEnd: Date, wakeUp: Date) -> Date {
        return remEnd < wakeUp ? remEnd : wakeUp
    }

    /// 今夜の就寝時間と明日の起床時間を計算する
    static func resolveActualTimes(bedtime: Date, wakeUpTime: Date) -> (actualBedtime: Date, actualWakeUpTime: Date) {
        let calendar = Calendar.current
        let now = Date()

        let bedtimeComponents = calendar.dateComponents([.hour, .minute], from: bedtime)
        let wakeUpComponents = calendar.dateComponents([.hour, .minute], from: wakeUpTime)

        var actualBedtime = calendar.date(bySettingHour: bedtimeComponents.hour ?? 23,
                                          minute: bedtimeComponents.minute ?? 0,
                                          second: 0, of: now) ?? now

        // 就寝時間が既に過ぎていたら翌日にはしない（今日寝る前提）
        // ただし起床時間は就寝時間より後になるように調整
        var actualWakeUp = calendar.date(bySettingHour: wakeUpComponents.hour ?? 7,
                                         minute: wakeUpComponents.minute ?? 0,
                                         second: 0, of: now) ?? now

        // 起床時間が就寝時間以前なら翌日とみなす
        if actualWakeUp <= actualBedtime {
            actualWakeUp = calendar.date(byAdding: .day, value: 1, to: actualWakeUp) ?? actualWakeUp
        }

        return (actualBedtime, actualWakeUp)
    }
}
