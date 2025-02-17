import SwiftUI

struct FishStatsView: View {
    
    var statistics: CountFishResp
    
    var body: some View {
        VStack {
            HStack {
                PieChartView(
                    title: "Historical Total Count",
                    slices: [
                        PieSlice(
                            label: "Active",
                            value: statistics.activeCount,
                            color: Color.blue,
                            extraColor: [Color.purple]
                        ),
                        PieSlice(
                            label: "Expired",
                            value: statistics.expiredCount,
                            color: "#B7C9F3".color,
                            extraColor: ["#F4E0E3".color]
                        ),
                    ],
                    radius: 80
                )
                .frame(height: 250)
                .padding()
                PieChartView(
                    title: "Count By Type",
                    slices: [
                        PieSlice(
                            label: "Text",
                            value: statistics.typeCount["Text", default: 0],
                            color: "#F0D5D5".color,
                            extraColor: ["#FCFBC2".color]
                        ),
                        PieSlice(
                            label: "Image",
                            value: statistics.typeCount["Image", default: 0],
                            color: "#5291C3".color,
                            extraColor: ["#E9F7FD".color]
                        ),
                        PieSlice(
                            label: "Other",
                            value: statistics.typeCount["Other", default: 0],
                            color: "#6F5AA2".color,
                            extraColor: ["#D7A9C4".color]
                        ),
                    ],
                    radius: 80
                )
                .frame(height: 250)
                .padding()
            }
            HStack {
                PieChartView(
                    title: "Count By Mark Status",
                    slices: [
                        PieSlice(
                            label: "Marked",
                            value: statistics.markedCount,
                            color: "#E24A42".color,
                            extraColor: ["#E3C180".color]
                        ),
                        PieSlice(
                            label: "Unmarked",
                            value: statistics.unmarkedCount,
                            color: "#FDF5E6".color,
                            extraColor: ["#FDF6EE".color]
                        ),
                    ],
                    radius: 80
                )
                .frame(height: 250)
                .padding()
                PieChartView(
                    title: "Count By Lock Status",
                    slices: [
                        PieSlice(
                            label: "Locked",
                            value: statistics.lockedCount,
                            color: "#E24A42".color,
                            extraColor: ["#E3C180".color]
                        ),
                        PieSlice(
                            label: "Unlocked",
                            value: statistics.unlockedCount,
                            color: "#FDF5E6".color,
                            extraColor: ["#FDF6EE".color]
                        ),
                    ],
                    radius: 80
                )
                .frame(height: 250)
                .padding()
            }
            BarChartView(
                title: "Count By Tag",
                data: [
                        statistics.tagCount.map {
                            BarSlice(
                                label: $0.key == "" ? "NO TAG" : $0.key,
                                value: $0.value,
                                color: String(Functions.getMD5(of: $0.key).suffix(6)).color
                            )
                        }.sorted {$0.value > $1.value}
                ],
                seriesName: ["default"],
                maxHeight: 120
            )
            .frame(height: 300)
            .padding()
            BarChartView(
                title: "Count By Create Time",
                data: [
                    buildDaySlices(data: statistics.dayCount),
                    buildWeekSlices(data: statistics.dayCount),
                    buildMonthSlices(data: statistics.dayCount),
                    buildYearSlices(data: statistics.dayCount),
                ],
                seriesName: ["Day", "Week", "Month", "Year"],
                maxHeight: 120
            )
            .frame(height: 300)
            .padding()
        }
    }
    
}

func buildDaySlices(data: [String:Int]) -> [BarSlice] {
    data.map {
        BarSlice(
            label: $0.key,
            value: $0.value,
            color: String(Functions.getMD5(of: $0.key).suffix(6)).color
        )
    }.sorted { $0.label < $1.label }
}

func buildWeekSlices(data: [String:Int]) -> [BarSlice] {
    var countByWeek: [String:Int] = [:]
    for (date, cnt) in data {
        guard let curWeek = Functions.convertDateToWeek(date) else {
            Log.warning("compute fish statistics of create week - some data is skipped: parse data string to week failed, date=\(date), cnt=\(cnt)")
            continue
        }
        countByWeek[curWeek, default: 0] += cnt
    }
    return countByWeek.map {
        BarSlice(
            label: $0.key,
            value: $0.value,
            color: String(Functions.getMD5(of: $0.key).suffix(6)).color
        )
    }.sorted { $0.label < $1.label }
}

func buildMonthSlices(data: [String:Int]) -> [BarSlice] {
    var countByMonth: [String:Int] = [:]
    for (date, cnt) in data {
        let curMonth = String(date.prefix(7))
        countByMonth[curMonth, default: 0] += cnt
    }
    return countByMonth.map {
        BarSlice(
            label: $0.key,
            value: $0.value,
            color: String(Functions.getMD5(of: $0.key).suffix(6)).color
        )
    }.sorted { $0.label < $1.label }
}

func buildYearSlices(data: [String:Int]) -> [BarSlice] {
    var countByYear: [String:Int] = [:]
    for (date, cnt) in data {
        let curYear = String(date.prefix(4))
        countByYear[curYear, default: 0] += cnt
    }
    return countByYear.map {
        BarSlice(
            label: $0.key,
            value: $0.value,
            color: String(Functions.getMD5(of: $0.key).suffix(6)).color
        )
    }.sorted { $0.label < $1.label }
}
