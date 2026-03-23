import Testing
@testable import dreamApp
import Foundation

struct dreamAppTests {

    @Test func passwordHasherGeneratesSalt() {
        let salt1 = PasswordHasher.generateSalt()
        let salt2 = PasswordHasher.generateSalt()
        #expect(salt1 != salt2)
        #expect(!salt1.isEmpty)
    }

    @Test func passwordHasherProducesConsistentHash() {
        let salt = PasswordHasher.generateSalt()
        let hash1 = PasswordHasher.hash(password: "testPassword", salt: salt)
        let hash2 = PasswordHasher.hash(password: "testPassword", salt: salt)
        #expect(hash1 == hash2)
    }

    @Test func passwordHasherDifferentPasswordsDifferentHashes() {
        let salt = PasswordHasher.generateSalt()
        let hash1 = PasswordHasher.hash(password: "password1", salt: salt)
        let hash2 = PasswordHasher.hash(password: "password2", salt: salt)
        #expect(hash1 != hash2)
    }

    @Test func passwordHasherVerifyWorks() {
        let salt = PasswordHasher.generateSalt()
        let hash = PasswordHasher.hash(password: "myPassword", salt: salt)
        #expect(PasswordHasher.verify(password: "myPassword", salt: salt, hash: hash))
        #expect(!PasswordHasher.verify(password: "wrongPassword", salt: salt, hash: hash))
    }

    @Test func sleepCycleServiceCalculatesREMPeriods() {
        let calendar = Calendar.current
        let bedtime = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: Date())!
        let wakeUp = calendar.date(byAdding: .hour, value: 8, to: bedtime)!

        let periods = SleepCycleService.calculateREMPeriods(bedtime: bedtime, wakeUpTime: wakeUp)

        #expect(!periods.isEmpty)
        #expect(periods.count >= 4) // 8時間で4-5サイクル
        #expect(periods[0].cycleNumber == 1)

        // レム睡眠の開始時間が就寝時間より後であること
        for period in periods {
            #expect(period.startTime > bedtime)
            #expect(period.endTime <= wakeUp)
            #expect(period.endTime > period.startTime)
        }
    }

    @Test func sleepCycleServiceResolvesTimes() {
        let calendar = Calendar.current
        let bedtime = calendar.date(bySettingHour: 23, minute: 30, second: 0, of: Date())!
        let wakeUp = calendar.date(bySettingHour: 6, minute: 30, second: 0, of: Date())!

        let resolved = SleepCycleService.resolveActualTimes(bedtime: bedtime, wakeUpTime: wakeUp)

        // 起床時間が就寝時間より後であること
        #expect(resolved.actualWakeUpTime > resolved.actualBedtime)
    }
}
