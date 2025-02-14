import SwiftUI

struct RecipeExecutionView: View {
    
    @Binding var context: RecipeExecutionContext
    @State var contextUid: UUID
    
    @State var paraFieldEnable: Bool = Config.paraFieldEnable
    @State var fishSideEnable: Bool = Config.fishSideEnable
    @State var topicSideEnable: Bool = Config.topicSideEnable
    
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                if fishSideEnable {
                    DynamicRecipeFishSideView()
                    .frame(width: Constant.sideWidth)
                    Divider()
                }
                if paraFieldEnable {
//                    DynamicRecipeParaFieldView()
//                    .frame(width: Constant.mainWidth * 0.3)
//                    .padding(5)
//                    Divider()
                }
                Spacer()
                if let _ = context.activeRecipe {
                    if let info = context.executeResult.viewInfo {
                        DynamicRecipeView(dynamicRecipeViewInfo: info, paraFieldEnable: paraFieldEnable)
                    } else {
                        EmptyView()
                    }
                } else {
                    RecipeListView()
                }
                Spacer()
                if topicSideEnable {
                    Divider()
                    DynamicRecipeTopicSideView()
                    .frame(width: Constant.sideWidth)
                }
            }
            Spacer()
            HStack {
                HStack(spacing: 10) {
                    FishSideButtonView(fishSideEnable: $fishSideEnable)
                    if let info = context.executeResult.viewInfo, info.items.count > 0 && info.items.count > 0 {
                        ParaFieldButtonView(withAnima: true, paraFieldEnable: $paraFieldEnable)
                    } else {
                        ParaFieldButtonView(withAnima: false, paraFieldEnable: $paraFieldEnable)
                    }
                    TopicSideButtonView(topicSideEnable: $topicSideEnable)
                }
                .frame(height: 16)
                Spacer()
                if let info = context.executeResult.viewInfo {
                    HStack(spacing: 20) {
                        Text("\(info.items.count) items")
                            .font(.callout)
                            .foregroundStyle(.gray)
                        if let timeCost = context.executeResult.timeCost {
                            Text(Functions.descTimeInterval(timeCost))
                                .font(.callout)
                                .foregroundStyle(.gray)
                        }
                    }
                }
            }
            .padding(.horizontal, 3)
        }
        .onReceive(NotificationCenter.default.publisher(for: .RecipeExecutionContextChanged.group(contextUid.uuidString))) { _ in
            withAnimation {
                self.context = self.context
            }
        }
        
    }
    
    struct ParaFieldButtonView: View {
        
        var withAnima: Bool = true
        
        @State var isHovered: Bool = false
        @Binding var paraFieldEnable: Bool
        
        var body: some View {
            HStack {
                Image(systemName: "square.split.2x1.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(paraFieldEnable ? "27295F".color : .gray)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(isHovered ? Color.gray.opacity(0.5) : Color.clear, lineWidth: 5)
                )
            }
            .onHover { isHovered in
                self.isHovered = isHovered
            }
            .onTapGesture {
                if withAnima {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        self.paraFieldEnable.toggle()
                    }
                } else {
                    self.paraFieldEnable.toggle()
                }
                Config.paraFieldEnable = paraFieldEnable
                let _ = Config.save()

            }
        }
        
    }

    struct FishSideButtonView: View {
        
        @State var isHovered: Bool = false
        @Binding var fishSideEnable: Bool
        
        var body: some View {
            HStack {
                Image(systemName: "square.lefthalf.filled")
                .resizable()
                .scaledToFit()
                .foregroundStyle(fishSideEnable ? "27295F".color : .gray)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(isHovered ? Color.gray.opacity(0.5) : Color.clear, lineWidth: 5)
                )
            }
            .onHover { isHovered in
                self.isHovered = isHovered
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.fishSideEnable.toggle()
                    Config.fishSideEnable = fishSideEnable
                    let _ = Config.save()
                }
            }
        }
        
    }
    
    struct TopicSideButtonView: View {
        
        @State var isHovered: Bool = false
        @Binding var topicSideEnable: Bool
        
        var body: some View {
            HStack {
                Image(systemName: "square.righthalf.filled")
                .resizable()
                .scaledToFit()
                .foregroundStyle(topicSideEnable ? "27295F".color : .gray)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(isHovered ? Color.gray.opacity(0.5) : Color.clear, lineWidth: 5)
                )
            }
            .onHover { isHovered in
                self.isHovered = isHovered
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.topicSideEnable.toggle()
                    Config.topicSideEnable = topicSideEnable
                    let _ = Config.save()
                }
            }
        }
        
    }
    
}
