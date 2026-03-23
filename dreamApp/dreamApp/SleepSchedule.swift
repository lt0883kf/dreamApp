import Foundation
import SwiftData

@Model
final class SleepSchedule {
    var bedtime: Date
    var wakeUpTime: Date
    var updatedAt: Date

    var user: User?

    init(bedtime: Date, wakeUpTime: Date) {
        self.bedtime = bedtime
        self.wakeUpTime = wakeUpTime
        self.updatedAt = Date()
    }
}
