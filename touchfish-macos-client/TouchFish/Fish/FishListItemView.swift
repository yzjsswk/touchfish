import SwiftUI

struct FishListItemView: View {
    
    @Binding var fish: Fish
    @Binding var selectedFishUid: String?
    @Binding var hoveringFishUid: String?
    
    @Binding var isEditing: Bool
    @Binding var isMultSelecting: Bool
    @Binding var multSelectedFishUids: Set<String>
    
    @State var showCopyed: Bool = false
    
    @Namespace private var animationNamespace
    
    var isSelected: Bool {
        selectedFishUid == fish.uid
    }
    
    var isHovering: Bool {
        !isMultSelecting && hoveringFishUid == fish.uid
    }
    
    var body: some View {
        HStack() {
            HStack {
                if isMultSelecting {
                    if multSelectedFishUids.contains(fish.uid) {
                        Image(systemName: "checkmark.square")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(isSelected ? "27295F".color : Color.black)
                    } else {
                        Image(systemName: "square")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(isSelected ? "27295F".color : Color.black)
                    }
                } else {
                    fish.fishIcon
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(isSelected ? "27295F".color : Color.black)
                }
            }
            .frame(width: Constant.fishItemIconWidth)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if fish.isMarked {
                        Text(fish.linePreview)
                            .font(.title3)
                            .foregroundColor(isSelected ? Color.black: "222D59".color)
                    } else {
                        Text(fish.linePreview)
                            .font(.title3)
                            .foregroundColor(isSelected ? "666970".color : Color.gray )
                    }
                    Spacer()
                    if fish.isLocked && !isHovering {
                        UnLockButtonView()
                        .matchedGeometryEffect(id: "unlock_button", in: animationNamespace)
                    }
                }
                if isHovering {
                    HStack(spacing: 3) {
                        Text(fish.identity)
                            .font(.caption)
                            .foregroundStyle(.gray)
                            CopyButtonView()
                            .onTapGesture {
                                if let data = fish.identity.data(using: .utf8) {
                                    Functions.copyDataToClipboard(data: data, type: .Text)
                                } else {
                                    Log.warning("copy fish identity to clipboard: fail - fish.identity.data return nil, fish.identity=\(fish.identity)")
                                }
                            }
                        Spacer()
                        // todo: icon move anima when lock
                        if fish.isLocked {
                            UnLockButtonView()
                            .matchedGeometryEffect(id: "unlock_button", in: animationNamespace)
                            .onTapGesture {
                                Task {
                                    await Storage.unLockFish([fish.uid])
                                }
                            }
                        } else {
                            LockButtonView()
                            .onTapGesture {
                                Task {
                                    await Storage.lockFish([fish.uid])
                                }
                            }
                            EditButtonView()
                            .onTapGesture {
                                isEditing = true
                            }
                            if fish.isMarked {
                                UnMarkButtonView()
                                .onTapGesture {
                                    Task {
                                        await Storage.unMarkFish([fish.uid])
                                    }
                                }
                            } else {
                                MarkButtonView()
                                .onTapGesture {
                                    Task {
                                        await Storage.markFish([fish.uid])
                                    }
                                }
                            }
                            DeleteButtonView()
                            .onTapGesture {
                                Task {
                                    await Storage.removeFish([fish.uid])
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(5)
        .background(isSelected ? "EEF2FD".color : .clear)
//        .shadow(color: Color.gray.opacity(0.3), radius: 2, x: 0, y: 2)
        .cornerRadius(5)
        .frame(height: isHovering ? Constant.fishItemHeight+20 : Constant.fishItemHeight)
        .popover(isPresented: $showCopyed, arrowEdge: .trailing) {
            Text("Copyed")
                .padding(10)
        }
        .onHover { isHovered in
            if !isHovered {
                showCopyed = false
            }
        }
        .onTapGesture {
            if isMultSelecting {
                if multSelectedFishUids.contains(fish.uid) {
                    multSelectedFishUids.remove(fish.uid)
                } else {
                    multSelectedFishUids.insert(fish.uid)
                }
            } else {
//                fish.copyToClipboard()
//                if Config.fastPasteToFrontmostApplication {
//                    TouchFishApp.pasteBoardWindow.hide()
//                    pasteToFrontmostApp()
//                } else {
//                    showCopyed = true
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                        showCopyed = false
//                    }
//                }
            }
        }
        .onLongPressGesture(minimumDuration: 0.8) { isPressing in
//            if isPressing {
//                print("Pressing...")
//            }
        } perform: {
            withAnimation {
                isMultSelecting = true
            }
            multSelectedFishUids.insert(fish.uid)
        }
    }
}

struct CopyButtonView: View {
    
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            Image(systemName: isHovered ? "list.clipboard.fill" : "list.clipboard")
                .resizable()
                .scaledToFit()
                .foregroundColor("27295F".color)
                .frame(width: isHovered ? 20 : 18, height: isHovered ? 20 : 18)
        }
        .frame(width: 20, height: 20)
        .onHover { isHovered in
            withAnimation(.spring(duration: 0.1)) {
                self.isHovered = isHovered
            }
        }
    }
}

struct EditButtonView: View {
    
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            Image(systemName: "square.and.pencil")
                .resizable()
                .scaledToFit()
                .foregroundColor("27295F".color)
                .frame(width: isHovered ? 20 : 18, height: isHovered ? 20 : 18)
        }
        .frame(width: 20, height: 20)
        .onHover { isHovered in
            withAnimation(.spring(duration: 0.1)) {
                self.isHovered = isHovered
            }
        }
    }
    
}

struct LockButtonView: View {
    
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            Image(systemName: isHovered ? "lock.fill" : "lock")
                .resizable()
                .scaledToFit()
                .foregroundColor("27295F".color)
                .frame(width: isHovered ? 25 : 23, height: isHovered ? 20 : 18)
        }
        .frame(width: 25, height: 20)
        .onHover { isHovered in
            withAnimation(.spring(duration: 0.1)) {
                self.isHovered = isHovered
            }
        }
    }
}

struct UnLockButtonView: View {
    
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            Image(systemName: "lock.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor("27295F".color.opacity(isHovered ? 0.5 : 1.0))
                .frame(width: isHovered ? 25 : 23, height: isHovered ? 20 : 18)
        }
        .frame(width: 25, height: 20)
        .onHover { isHovered in
            withAnimation(.spring(duration: 0.1)) {
                self.isHovered = isHovered
            }
        }
    }
}

struct MarkButtonView: View {
    
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            Image(systemName: isHovered ? "bookmark.fill" : "bookmark")
                .resizable()
                .scaledToFit()
                .foregroundColor("27295F".color)
                .frame(width: isHovered ? 20 : 18, height: isHovered ? 20 : 18)
        }
        .frame(width: 20, height: 20)
        .offset(y:1)
        .onHover { isHovered in
            withAnimation(.spring(duration: 0.1)) {
                self.isHovered = isHovered
            }
        }
    }
}

struct UnMarkButtonView: View {
    
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            Image(systemName: "bookmark.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor("27295F".color.opacity(isHovered ? 0.5 : 1.0))
                .frame(width: isHovered ? 20 : 18, height: isHovered ? 20 : 18)
        }
        .frame(width: 20, height: 20)
        .offset(y:1)
        .onHover { isHovered in
            withAnimation(.spring(duration: 0.1)) {
                self.isHovered = isHovered
            }
        }
    }
}

struct DeleteButtonView: View {
    
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            Image(systemName: isHovered ? "trash.fill" : "trash")
                .resizable()
                .scaledToFit()
                .foregroundStyle("27295F".color)
                .frame(width: isHovered ? 20 : 18, height: isHovered ? 20 : 18)
        }
        .frame(width: 20, height: 20)
        .onHover { isHovered in
            withAnimation(.spring(duration: 0.1)) {
                self.isHovered = isHovered
            }
        }
    }
}
