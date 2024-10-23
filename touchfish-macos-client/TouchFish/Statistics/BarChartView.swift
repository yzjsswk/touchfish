import SwiftUI

struct BarSlice {
    
    var label: String
    var value: Int
    var color: Color
    var extraColor: [Color]? = nil
    
    var colors: [Color] {
        var ret = [self.color]
        if let extraColor = extraColor {
            ret.append(contentsOf: extraColor)
        }
        return ret
    }
    
}

struct BarChartView: View {
    
    @State var title: String
    @State var slices: [[BarSlice]]
    @State var heights: [[CGFloat]]
    @State var series: [String]
    @State var selectedSeriesIdx = 0
    
    var maxHeights: [[CGFloat]] = []
    
    init(title: String, data: [[BarSlice]], seriesName: [String], maxHeight: Int) {
        self.title = title
        var slices: [[BarSlice]] = []
        var heights: [[CGFloat]] = []
        for curSlices in data {
            slices.append(curSlices)
            var curHeights: [CGFloat] = []
            var curMaxHeights: [CGFloat] = []
            let maxValue: Int = curSlices.reduce(0) { max($0, $1.value) }
            for slice in curSlices {
                curHeights.append(0)
                curMaxHeights.append(Double(slice.value * maxHeight / maxValue))
            }
            self.maxHeights.append(curMaxHeights)
            heights.append(curHeights)
        }
        self.series = seriesName
        self.slices = slices
        self.heights = heights
    }
    
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(radius: 10)
            VStack {
                HStack {
                    Text(title)
                        .font(.title2)
                        .padding()
                    Spacer()
                    if series.count > 1 {
                        Picker("", selection: $selectedSeriesIdx) {
                            ForEach(Array(series.enumerated()), id: \.0) { (idx, ser) in
                                Text(ser).tag(idx)
                            }
                        }
                        .frame(width: CGFloat(series.count*50))
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                    }
                }
                Spacer()
                if slices[selectedSeriesIdx].reduce(0, {$0 + $1.label.count*3}) + slices[selectedSeriesIdx].count*16 > 300 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .bottom, spacing: 16) {
                            ForEach(Array(slices[selectedSeriesIdx].enumerated()), id: \.0) { (idx, slice) in
                                BarSliceView(slice: $slices[selectedSeriesIdx][idx], height: $heights[selectedSeriesIdx][idx])
                            }
                        }
                    }
                    .padding(.horizontal, 5)
                } else {
                    HStack(alignment: .bottom, spacing: 16) {
                        ForEach(Array(slices[selectedSeriesIdx].enumerated()), id: \.0) { (idx, slice) in
                            BarSliceView(slice: $slices[selectedSeriesIdx][idx], height: $heights[selectedSeriesIdx][idx])
                        }
                    }
                }

            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                for i in 0..<heights[selectedSeriesIdx].count {
                    heights[selectedSeriesIdx][i] = maxHeights[selectedSeriesIdx][i]
                }
            }
        }
        .onChange(of: selectedSeriesIdx) { oldValue, newValue in
            for i in 0..<heights[oldValue].count {
                heights[oldValue][i] = 0
            }
            withAnimation(.easeInOut(duration: 0.8)) {
                for i in 0..<heights[newValue].count {
                    heights[newValue][i] = maxHeights[newValue][i]
                }
            }
        }
    }
}

struct BarSliceView: View {
    
    @Binding var slice: BarSlice
    @Binding var height: CGFloat
    
    @State var isSelected: Bool = false
    
    var body: some View {
        VStack {
            Text(slice.label)
                .font(.title3)
                .foregroundStyle(.gray)
                .italic()
                .padding(5)
            Text(String(slice.value))
                .font(.title3)
                .padding(.bottom, 5)
            Rectangle()
                .fill(slice.color)
                .frame(width: isSelected ? 40 : 30, height: height+(isSelected ? 10 : 0))
                .padding(.bottom, 5)
        }
        .onHover { isHovered in
            withAnimation {
                isSelected = isHovered
            }
        }
    }
    
}
