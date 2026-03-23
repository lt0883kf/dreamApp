import Foundation
import SwiftData

@Model
final class SleepSession {
    @Attribute(.unique) var id: UUID
    var startTime: Date
    var endTime: Date?
    var actualBedtime: Date
    var actualWakeUpTime: Date
    var isActive: Bool

    var user: User?

    init(startTime: Date, actualBedtime: Date, actualWakeUpTime: Date) {
        self.id = UUID()
        self.startTime = startTime
        self.actualBedtime = actualBedtime
        self.actualWakeUpTime = actualWakeUpTime
        self.isActive = true
    }
}
