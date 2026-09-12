import Foundation

struct AppSettings: Codable, Equatable {
    var dailyNudgeHour: Int = 18
    var dailyNudgeMinute: Int = 30
    var dailyNudgeEnabled: Bool = true
    var hasCompletedOnboarding: Bool = false

    init(
        dailyNudgeHour: Int = 18,
        dailyNudgeMinute: Int = 30,
        dailyNudgeEnabled: Bool = true,
        hasCompletedOnboarding: Bool = false
    ) {
        self.dailyNudgeHour = dailyNudgeHour
        self.dailyNudgeMinute = dailyNudgeMinute
        self.dailyNudgeEnabled = dailyNudgeEnabled
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dailyNudgeHour = try container.decodeIfPresent(Int.self, forKey: .dailyNudgeHour) ?? 18
        dailyNudgeMinute = try container.decodeIfPresent(Int.self, forKey: .dailyNudgeMinute) ?? 30
        dailyNudgeEnabled = try container.decodeIfPresent(Bool.self, forKey: .dailyNudgeEnabled) ?? true
        hasCompletedOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? false
    }
}
