import SwiftUI

struct DynamicRecipeItemView: View {
    
    @Binding var context: RecipeExecutionContext
    
    var item: DynamicRecipeViewInfo.ViewItem
    
    @Binding var info: DynamicRecipeViewInfo
    
    var paraFieldEnable: Bool
    
    var body: some View {
        switch item {
        case .Info(let title, let body, let value, let selectable):
            VStack {
                Text(title)
                .font(.title2)
                .bold()
                .padding(.bottom, 5)
                if let body = body {
                    if let bodyMd = try? AttributedString(markdown: body) {
                        Text(bodyMd)
                        .font(.body)
                    } else {
                        Text(body)
                        .font(.body)
                    }
                }
            }
            .padding(.vertical, 5)
        case .Warn(let title, let body, let value, let selectable):
            VStack {
                HStack {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.yellow)
                    }
                    .frame(width: 30)
                    Text(title)
                    .font(.title2)
                    .foregroundStyle(.yellow)
                    .bold()
                }
                .padding(.bottom, 5)
                if let body = body {
                    if let bodyMd = try? AttributedString(markdown: body) {
                        Text(bodyMd)
                        .font(.body)
                    } else {
                        Text(body)
                        .font(.body)
                    }
                }
            }
            .padding(.vertical, 5)
        case .Error(let title, let body, let value, let selectable):
            VStack {
                HStack {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.red)
                    }
                    .frame(width: 30)
                    Text(title)
                    .font(.title2)
                    .foregroundStyle(.red)
                    .bold()
                }
                .padding(.bottom, 5)
                if let body = body {
                    if let bodyMd = try? AttributedString(markdown: body) {
                        Text(bodyMd)
                        .font(.body)
                    } else {
                        Text(body)
                        .font(.body)
                    }
                }
            }
            .padding(.vertical, 5)
        case .Strip(
            let size, let title, let description, let iconPattern, let tags,
            let hoverEffects, let operation, let value, let selectable
        ):
            DynamicRecipeStripItemView(
                size: size, title: title, description: description, iconPattern: iconPattern, tags: tags,
                hoverEffects: hoverEffects, operation: operation, value: value, selectable: selectable,
                info: $info, context:$context, paraFieldEnable: paraFieldEnable
            )
        case .TextCard(
            let size, let title, let description, let iconPattern, let tags,
            let body, let properties, let showProperties, let operations,
            let value, let selectable
        ):
            DynamicRecipeTextCardItemView(
                size: size, title: title, description: description, iconPattern: iconPattern, tags: tags,
                content: body, properties: properties, showProperties: showProperties, operations: operations,
                value: value, selectable: selectable, info: $info, context:$context, paraFieldEnable: paraFieldEnable
            )
        case .ImageCard(
            let size, let title, let description, let iconPattern, let tags,
            let imagePatterns, let properties, let showProperties, let operations,
            let value, let selectable
        ):
            DynamicRecipeImageCardItemView(
                size: size, title: title, description: description, iconPattern: iconPattern, tags: tags,
                imagePatterns: imagePatterns, properties: properties, showProperties: showProperties, operations: operations,
                value: value, selectable: selectable, info: $info, context:$context, paraFieldEnable: paraFieldEnable
            )
        }
    }
    
}

struct DynamicRecipeErrorItemView: View {

    var title: String
    var datail: String?
    var value: String?
    var selectable: Bool
    
    @Binding var info: DynamicRecipeViewInfo
    
    @State var isHovered: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.red)
                }
                .frame(width: 30)
                Text("Some errors occurred while executing the recipe")
                .font(.title2)
                .foregroundColor(.red)
            }
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                .font(.title3)
                .bold()
                if let datail = datail {
                    Text(datail)
                    .font(.body)
                }
            }
        }
    }
    
}
