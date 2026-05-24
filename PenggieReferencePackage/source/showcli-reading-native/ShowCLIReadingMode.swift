#if os(macOS)
import AppKit
import GhosttyKit
import SwiftUI

private struct ShowCLIReadingSearchMatch: Identifiable, Equatable {
    let id: Int
    let blockID: UUID
    let lineIndex: Int
    let range: NSRange
}

private enum ShowCLIReadingRenderItem: Identifiable, Equatable {
    case block(ShowCLIReadingBlock)
    case toolGroup(id: String, blocks: [ShowCLIReadingBlock])

    var id: String {
        switch self {
        case .block(let block):
            return block.id.uuidString
        case .toolGroup(let id, _):
            return id
        }
    }

    var blocks: [ShowCLIReadingBlock] {
        switch self {
        case .block(let block):
            return [block]
        case .toolGroup(_, let blocks):
            return blocks
        }
    }
}

struct ShowCLIReadingModeView: View {
    @ObservedObject var controller: ShowCLICurrentSessionController

    @State private var query = ""
    @State private var composerText = ""
    @State private var composerTextHeight: CGFloat = 30
    @State private var composerHasVisibleText = false
    @State private var nativeInteractionFocusRequestID = 0
    @State private var ptyProxyText = ""
    @State private var selectedMatchID: Int?
    @State private var foldedBlockIDs: Set<UUID> = []
    @State private var expandedToolGroupIDs: Set<String> = []
    @State private var pinnedBlockIDs: Set<UUID> = []
    @State private var preservedBlockIDs: Set<UUID> = []
    @State private var hoveredBlockID: UUID?
    @FocusState private var focusedField: FocusedField?

    private let topAnchor = "showcli-reading-top"
    private let bottomAnchor = "showcli-reading-bottom"
    private let readerContentMaxWidth: CGFloat = 1160
    private let answerMaxWidth: CGFloat = 980
    private let userBubbleMaxWidth: CGFloat = 420
    private let composerMinTextHeight: CGFloat = 30
    private let composerMaxTextHeight: CGFloat = 140

    private enum FocusedField {
        case search
        case composer
    }

    private var canSubmitComposer: Bool {
        controller.canSubmitComposer(composerText)
    }

    private var canPressSend: Bool {
        canSubmitComposer ||
            (controller.hasCurrentSurface && controller.nativeInteractionPhase.acceptsInput)
    }

    private var visibleText: String {
        controller.visibleText
    }

    private var blocks: [ShowCLIReadingBlock] {
        controller.readingBlocks
    }

    private var pinnedBlocks: [ShowCLIReadingBlock] {
        visibleBlocks.filter { pinnedBlockIDs.contains($0.id) }
    }

    private var nativeInteractionLiveRows: [ShowCLINativeInteractionRow] {
        controller.nativeInteractionPresentationRows
            .map(ShowCLINativeInteractionRow.init(line:))
    }

    private var nativeInteractionRows: [ShowCLINativeInteractionRow] {
        nativeInteractionLiveRows
    }

    private var nativeInteractionOverlayVisible: Bool {
        !nativeInteractionRows.isEmpty
    }

    private var visibleBlocks: [ShowCLIReadingBlock] {
        blocks.filter { !ShowCLIReadingPresentation.isHiddenChromeBlock($0) }
    }

    private var renderItems: [ShowCLIReadingRenderItem] {
        var items: [ShowCLIReadingRenderItem] = []
        var pendingToolBlocks: [ShowCLIReadingBlock] = []

        func flushTools() {
            guard !pendingToolBlocks.isEmpty else { return }
            let first = pendingToolBlocks.first?.id.uuidString ?? UUID().uuidString
            let last = pendingToolBlocks.last?.id.uuidString ?? first
            items.append(.toolGroup(id: "tools-\(first)-\(last)", blocks: pendingToolBlocks))
            pendingToolBlocks.removeAll()
        }

        for block in visibleBlocks {
            if ShowCLIReadingPresentation.isToolChromeBlock(block) {
                pendingToolBlocks.append(block)
            } else {
                flushTools()
                items.append(.block(block))
            }
        }

        flushTools()
        return items
    }

    private var searchableBlocks: [ShowCLIReadingBlock] {
        visibleBlocks.filter { !ShowCLIReadingPresentation.isToolChromeBlock($0) }
    }

    private var searchNeedle: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var searchMatches: [ShowCLIReadingSearchMatch] {
        guard !searchNeedle.isEmpty else { return [] }

        var matches: [ShowCLIReadingSearchMatch] = []
        for block in searchableBlocks {
            for (lineIndex, line) in chatDisplayLines(for: block).enumerated() {
                let nsLine = line as NSString
                var searchRange = NSRange(location: 0, length: nsLine.length)

                while searchRange.location < nsLine.length {
                    let range = nsLine.range(
                        of: searchNeedle,
                        options: [.caseInsensitive, .diacriticInsensitive],
                        range: searchRange
                    )
                    guard range.location != NSNotFound, range.length > 0 else { break }

                    matches.append(.init(
                        id: matches.count,
                        blockID: block.id,
                        lineIndex: lineIndex,
                        range: range
                    ))

                    let nextLocation = range.location + range.length
                    searchRange = NSRange(
                        location: nextLocation,
                        length: nsLine.length - nextLocation
                    )
                }
            }
        }

        return matches
    }

    private var selectedMatchIndex: Int? {
        guard let selectedMatchID else { return nil }
        return searchMatches.firstIndex { $0.id == selectedMatchID }
    }

    private var matchStatus: String {
        guard !searchNeedle.isEmpty else { return "" }
        guard !searchMatches.isEmpty else { return "0" }
        return "\((selectedMatchIndex ?? 0) + 1)/\(searchMatches.count)"
    }

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                toolbar(proxy: proxy)

                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Color.clear
                            .frame(height: 1)
                            .id(topAnchor)

                        if !pinnedBlocks.isEmpty {
                            pinnedSection(proxy: proxy)
                        }

                        if visibleBlocks.isEmpty {
                            emptyState
                        } else {
                            ForEach(renderItems) { item in
                                renderItem(item, proxy: proxy)
                                    .id(renderItemAnchor(item.id))
                            }
                        }

                        Color.clear
                            .frame(height: 1)
                            .id(bottomAnchor)
                    }
                    .frame(maxWidth: readerContentMaxWidth, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 28)
                    .padding(.top, 24)
                    .padding(.bottom, 112)
                }
                .background(readingBackground)
                .onChange(of: query) { _ in
                    selectFirstMatch(proxy: proxy)
                }
                .onChange(of: visibleText) { _ in
                    normalizeSelectedMatch(proxy: proxy)
                }
                .onChange(of: blocks) { _ in
                    pruneManualBlockState()
                    normalizeSelectedMatch(proxy: proxy)
                }
                .safeAreaInset(edge: .bottom) {
                    composerBar
                }
            }
            .background(chatBackground)
            .onAppear {
                controller.refreshProjection()
                normalizeSelectedMatch(proxy: proxy)
                focusComposer()
            }
            .onChange(of: controller.nativeInteractionIsActive) { isActive in
                if !isActive {
                    ptyProxyText = ""
                } else {
                    ptyProxyText = controller.nativeInteractionDisplayText
                    nativeInteractionFocusRequestID += 1
                }
                focusedField = .composer
            }
            .onChange(of: controller.nativeInteractionPhase) { phase in
                guard phase.acceptsInput else { return }
                focusedField = .composer
                nativeInteractionFocusRequestID += 1
            }
            .onChange(of: controller.nativeInteractionDisplayText) { text in
                ptyProxyText = text
            }
        }
        .preferredColorScheme(.light)
    }

    private func toolbar(proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Reading")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(chatTextColor)

                Text(sessionSummary)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(mutedTextColor)
            }
            .frame(width: 172, alignment: .leading)

            Spacer()

            Button {
                proxy.scrollTo(topAnchor, anchor: .top)
            } label: {
                Image(systemName: "arrow.up.to.line")
                    .frame(width: 30, height: 28)
            }
            .buttonStyle(.plain)
            .background(toolbarButtonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .help("Jump to top")

            Button {
                proxy.scrollTo(bottomAnchor, anchor: .bottom)
            } label: {
                Image(systemName: "arrow.down.to.line")
                    .frame(width: 30, height: 28)
            }
            .buttonStyle(.plain)
            .background(toolbarButtonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .help("Jump to live output")

            searchField(proxy: proxy)

            Text(matchStatus)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(mutedTextColor)
                .frame(width: 48, alignment: .trailing)

            Button {
                selectPreviousMatch(proxy: proxy)
            } label: {
                Image(systemName: "chevron.up")
                    .frame(width: 30, height: 28)
            }
            .disabled(searchMatches.isEmpty)
            .buttonStyle(.plain)
            .background(toolbarButtonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .help("Previous match")

            Button {
                selectNextMatch(proxy: proxy)
            } label: {
                Image(systemName: "chevron.down")
                    .frame(width: 30, height: 28)
            }
            .disabled(searchMatches.isEmpty)
            .buttonStyle(.plain)
            .background(toolbarButtonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .help("Next match")

            Button {
                controller.copyCurrentProjection()
            } label: {
                toolbarLabeledIcon("Copy", systemImage: "doc.on.doc")
                    .frame(width: 74, height: 30)
            }
            .disabled(visibleText.isEmpty)
            .buttonStyle(.plain)
            .background(toolbarButtonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .layoutPriority(2)

            Button {
                controller.switchMode(to: .terminal)
            } label: {
                toolbarLabeledIcon("Terminal", systemImage: "terminal")
                    .frame(width: 96, height: 30)
            }
            .buttonStyle(.plain)
            .background(toolbarButtonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .layoutPriority(2)
            .keyboardShortcut("1", modifiers: .command)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(toolbarBackground)
    }

    private func toolbarLabeledIcon(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))

            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundStyle(chatTextColor)
    }

    private var sessionSummary: String {
        var parts = [controller.surfaceStatus.processExited ? "Exited" : "Live"]

        if let ttyName = controller.surfaceStatus.ttyName {
            parts.append(ttyName)
        }

        if let foregroundPID = controller.surfaceStatus.foregroundPID {
            parts.append("PID \(foregroundPID)")
        }

        if let childExitCode = controller.surfaceStatus.childExitCode {
            parts.append("exit \(childExitCode)")
        }

        return parts.joined(separator: "  ")
    }

    private var readingBackground: Color {
        chatBackground
    }

    private var toolbarBackground: Color {
        chatBackground
    }

    private var toolbarButtonBackground: Color {
        Color(red: 0.955, green: 0.953, blue: 0.949)
    }

    private var chatBackground: Color {
        Color(red: 0.986, green: 0.984, blue: 0.980)
    }

    private var composerSurfaceColor: Color {
        Color(red: 0.998, green: 0.997, blue: 0.994)
    }

    private var userBubbleColor: Color {
        Color(red: 0.944, green: 0.943, blue: 0.939)
    }

    private var chatTextColor: Color {
        Color(red: 0.090, green: 0.094, blue: 0.104)
    }

    private var mutedTextColor: Color {
        Color(red: 0.455, green: 0.459, blue: 0.470)
    }

    private var quietIconColor: Color {
        Color(red: 0.610, green: 0.612, blue: 0.620)
    }

    private var chatBorderColor: Color {
        Color(red: 0.875, green: 0.872, blue: 0.862)
    }

    private var chatSeparatorColor: Color {
        Color(red: 0.910, green: 0.906, blue: 0.895)
    }

    private var toolDetailBackground: Color {
        Color(red: 0.972, green: 0.969, blue: 0.962)
    }

    private var accentOrange: Color {
        Color(red: 0.910, green: 0.312, blue: 0.050)
    }

    private func searchField(proxy: ScrollViewProxy) -> some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(mutedTextColor)

            TextField("Find", text: $query)
                .textFieldStyle(.plain)
                .foregroundStyle(chatTextColor)
                .environment(\.colorScheme, .light)
                .focused($focusedField, equals: .search)
                .onSubmit {
                    selectNextMatch(proxy: proxy)
                }
        }
        .padding(.horizontal, 10)
        .frame(width: 220, height: 30)
        .background(composerSurfaceColor)
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay {
            RoundedRectangle(cornerRadius: 9)
                .stroke(chatBorderColor, lineWidth: 1)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "text.alignleft")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(mutedTextColor)

            Text("Waiting for terminal output")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(chatTextColor)

            Text("Reading mirrors the current live PTY.")
                .font(.system(size: 13))
                .foregroundStyle(mutedTextColor)
        }
        .frame(maxWidth: .infinity, minHeight: 360, alignment: .center)
    }

    private func pinnedSection(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: "pin.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(mutedTextColor)

                Text("Pinned")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(mutedTextColor)
            }

            ForEach(pinnedBlocks) { block in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(blockTitle(block))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(chatTextColor)

                        Text(blockPreview(block))
                            .font(.system(size: 12))
                            .foregroundStyle(mutedTextColor)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        proxy.scrollTo(blockAnchor(block.id), anchor: .center)
                    } label: {
                        Image(systemName: "arrow.down.forward.and.arrow.up.backward")
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .help("Jump to block")

                    Button {
                        togglePin(block.id)
                    } label: {
                        Image(systemName: "pin.slash")
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .help("Unpin")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(userBubbleColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func renderItem(_ item: ShowCLIReadingRenderItem, proxy: ScrollViewProxy) -> some View {
        switch item {
        case .block(let block):
            chatBlock(block, proxy: proxy)
                .id(blockAnchor(block.id))
        case .toolGroup(let id, let blocks):
            toolDisclosureGroup(id: id, blocks: blocks)
        }
    }

    @ViewBuilder
    private func chatBlock(_ block: ShowCLIReadingBlock, proxy: ScrollViewProxy) -> some View {
        if ShowCLIReadingPresentation.isUserPromptBlock(block) {
            promptBubble(block)
        } else {
            proseOutput(block)
        }
    }

    private func promptBubble(_ block: ShowCLIReadingBlock) -> some View {
        let lines = chatDisplayLines(for: block)
        let isHovered = hoveredBlockID == block.id

        return HStack(alignment: .top) {
            Spacer(minLength: 96)

            VStack(alignment: .trailing, spacing: 6) {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(lines.indices, id: \.self) { index in
                        Text(highlightedLine(lines[index], blockID: block.id, lineIndex: index))
                            .font(.system(size: 15.5, weight: .regular))
                            .foregroundStyle(chatTextColor)
                            .lineSpacing(3)
                            .textSelection(.enabled)
                            .id(lineAnchor(blockID: block.id, lineIndex: index))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .frame(maxWidth: userBubbleMaxWidth, alignment: .leading)
                .background(userBubbleColor)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                if isHovered {
                    inlineActions(block, isFolded: false, isPreserved: false)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.vertical, 16)
        .onHover { isHovering in
            hoveredBlockID = isHovering ? block.id : nil
        }
    }

    private func proseOutput(_ block: ShowCLIReadingBlock) -> some View {
        let isFolded = foldedBlockIDs.contains(block.id)
        let isPreserved = preservedBlockIDs.contains(block.id)
        let lines = isPreserved
            ? normalizedLines(from: block.text)
            : chatDisplayLines(for: block)
        let isHovered = hoveredBlockID == block.id
        let keepActionsVisible = isHovered || isFolded || isPreserved || pinnedBlockIDs.contains(block.id)

        return VStack(alignment: .leading, spacing: 10) {
            if keepActionsVisible {
                HStack {
                    Spacer()
                    inlineActions(block, isFolded: isFolded, isPreserved: isPreserved)
                }
                .transition(.opacity)
            }

            if isFolded {
                Text(blockPreview(block))
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(mutedTextColor)
                    .lineLimit(2)
                    .textSelection(.enabled)
            } else if isPreserved {
                rawTerminalBody(block, lines: lines)
            } else {
                chatTextBody(block, lines: lines)
            }
        }
        .frame(maxWidth: answerMaxWidth, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 22)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(chatSeparatorColor)
                .frame(height: 1)
        }
        .onHover { isHovering in
            hoveredBlockID = isHovering ? block.id : nil
        }
    }

    private func toolDisclosureGroup(id: String, blocks: [ShowCLIReadingBlock]) -> some View {
        let isExpanded = expandedToolGroupIDs.contains(id)

        return VStack(alignment: .leading, spacing: 10) {
            Button {
                toggleToolGroup(id)
            } label: {
                HStack(spacing: 7) {
                    Text(toolGroupSummary(blocks))
                        .font(.system(size: 14.5, weight: .medium))
                        .foregroundStyle(mutedTextColor)

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(quietIconColor)

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(isExpanded ? "Hide tool details" : "Show tool details")

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(blocks) { block in
                        toolDetailBlock(block)
                    }
                }
                .padding(.leading, 10)
                .transition(.opacity)
            }
        }
        .frame(maxWidth: answerMaxWidth, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }

    private func toolDetailBlock(_ block: ShowCLIReadingBlock) -> some View {
        let lines = normalizedLines(from: block.text)

        return VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Image(systemName: blockIcon(block))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(mutedTextColor)

                Text(blockTitle(block))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(mutedTextColor)

                Text("\(lines.count) rows")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(quietIconColor)

                Spacer()

                blockActionButton(systemImage: "doc.on.doc", help: "Copy raw item") {
                    controller.copyReadingBlock(block)
                }
            }

            rawTerminalBody(block, lines: lines)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(toolDetailBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(chatBorderColor, lineWidth: 1)
        }
    }

    private func chatTextBody(_ block: ShowCLIReadingBlock, lines: [String]) -> some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            ForEach(lines.indices, id: \.self) { index in
                Text(highlightedLine(lines[index], blockID: block.id, lineIndex: index))
                    .font(.system(size: 16.5, weight: .regular))
                    .foregroundStyle(chatTextColor)
                    .lineSpacing(6)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id(lineAnchor(blockID: block.id, lineIndex: index))
            }
        }
    }

    private func rawTerminalBody(_ block: ShowCLIReadingBlock, lines: [String]) -> some View {
        ScrollView(.horizontal) {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(lines.indices, id: \.self) { index in
                    lineView(
                        lines[index],
                        blockID: block.id,
                        lineIndex: index,
                        preserveTerminalRow: true
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func inlineActions(
        _ block: ShowCLIReadingBlock,
        isFolded: Bool,
        isPreserved: Bool
    ) -> some View {
        HStack(spacing: 4) {
            blockActionButton(
                systemImage: isPreserved ? "text.alignleft" : "arrow.left.and.right",
                help: isPreserved ? "Wrap item" : "Preserve terminal rows"
            ) {
                togglePreserve(block.id)
            }

            blockActionButton(
                systemImage: pinnedBlockIDs.contains(block.id) ? "pin.fill" : "pin",
                help: pinnedBlockIDs.contains(block.id) ? "Unpin item" : "Pin item"
            ) {
                togglePin(block.id)
            }

            blockActionButton(systemImage: "doc.on.doc", help: "Copy raw item") {
                controller.copyReadingBlock(block)
            }

            blockActionButton(
                systemImage: isFolded ? "chevron.down" : "chevron.up",
                help: isFolded ? "Expand item" : "Fold item"
            ) {
                toggleFold(block.id)
            }
        }
    }

    private func blockActionButton(
        systemImage: String,
        help: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(mutedTextColor)
        .background(userBubbleColor)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .help(help)
    }

    private func lineView(
        _ line: String,
        blockID: UUID,
        lineIndex: Int,
        preserveTerminalRow: Bool
    ) -> some View {
        Text(highlightedLine(line, blockID: blockID, lineIndex: lineIndex))
            .font(.system(size: 14.5, design: .monospaced))
            .foregroundStyle(chatTextColor)
            .lineSpacing(4)
            .textSelection(.enabled)
            .fixedSize(horizontal: preserveTerminalRow, vertical: false)
            .frame(maxWidth: preserveTerminalRow ? nil : .infinity, alignment: .leading)
            .id(lineAnchor(blockID: blockID, lineIndex: lineIndex))
    }

    private var composerBar: some View {
        VStack(spacing: 0) {
            if nativeInteractionOverlayVisible {
                nativeInteractionLens
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 10)
            }

            Rectangle()
                .fill(chatSeparatorColor)
                .frame(height: 1)

            HStack(alignment: .bottom, spacing: 9) {
                HStack(spacing: 8) {
                    if ShowCLINativeInteractionPresentation.usesNativeComposerInput(
                        phase: controller.nativeInteractionPhase
                    ) {
                        ZStack(alignment: .leading) {
                            Text(ptyProxyText.isEmpty ? "Command" : ptyProxyText)
                                .font(.system(size: 13.5))
                                .foregroundStyle(ptyProxyText.isEmpty ? mutedTextColor : chatTextColor)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            ShowCLIInteractionKeyCaptureView(
                                shouldFocus: focusedField == .composer,
                                isEnabled: controller.hasCurrentSurface && controller.nativeInteractionPhase.acceptsInput,
                                focusRequestID: nativeInteractionFocusRequestID,
                                onCommand: handlePTYInteractionCommand,
                                onKeyEvent: handlePTYInteractionKey,
                                onTextInput: handlePTYInteractionText
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .frame(height: 30)
                        .frame(maxWidth: .infinity, alignment: .leading)
                            .layoutPriority(1)
                    } else {
                        ZStack(alignment: .topLeading) {
                            if !composerHasVisibleText {
                                Text(composerPlaceholder)
                                    .font(.system(size: 13.5))
                                    .foregroundStyle(mutedTextColor)
                                    .padding(.top, 6)
                                    .allowsHitTesting(false)
                            }

                            ShowCLIComposerTextView(
                                text: $composerText,
                                measuredHeight: $composerTextHeight,
                                hasVisibleText: $composerHasVisibleText,
                                isEnabled: controller.hasCurrentSurface &&
                                    ShowCLINativeInteractionPresentation.standardComposerIsEnabled(
                                        phase: controller.nativeInteractionPhase
                                    ),
                                shouldFocus: focusedField == .composer,
                                minHeight: composerMinTextHeight,
                                maxHeight: composerMaxTextHeight,
                                onSubmit: submitComposer,
                                onNativePrefix: { prefix in
                                    startNativeInteractionFromComposer(prefix, origin: .prefix(prefix))
                                }
                            )
                            .frame(height: composerTextHeight)
                        }
                        .frame(minHeight: composerMinTextHeight)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .layoutPriority(1)
                        .onChange(of: composerText) { text in
                            handleComposerTextChange(text)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(minHeight: 42)
                .frame(maxWidth: .infinity)
                .background(composerSurfaceColor)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            ShowCLINativeInteractionPresentation.usesNativeComposerInput(
                                phase: controller.nativeInteractionPhase
                            )
                                ? accentOrange.opacity(0.55)
                                : chatBorderColor,
                            lineWidth: 1
                        )
                }

                Button {
                    submitComposer()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 42, height: 42)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(canPressSend ? chatTextColor : userBubbleColor)
                .foregroundStyle(canPressSend ? composerSurfaceColor : mutedTextColor)
                .clipShape(Circle())
                .disabled(!canPressSend)
                .help(controller.nativeInteractionIsActive ? "Confirm" : "Send")
            }
            .frame(maxWidth: readerContentMaxWidth)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(chatBackground)
    }

    private var composerPlaceholder: String {
        controller.canUseCodexDollarCommand ? "Message, / command, or $ command" : "Message or / command"
    }

    private var nativeInteractionLens: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Spacer()

                Text("↑↓ select · Enter accept · Esc cancel")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(quietIconColor)
            }

            nativeInteractionMenuView
        }
        .frame(maxWidth: readerContentMaxWidth)
        .padding(12)
        .background(Color(red: 0.982, green: 0.980, blue: 0.974))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(chatBorderColor, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.05), radius: 18, x: 0, y: 8)
    }

    private var nativeInteractionMenuView: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(Array(nativeInteractionRows.enumerated()), id: \.element.id) { index, row in
                nativeInteractionRowView(row, index: index)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(composerSurfaceColor)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func nativeInteractionRowView(_ row: ShowCLINativeInteractionRow, index: Int) -> some View {
        let displayText = nativeInteractionDisplayText(for: row)
        let isSelected = row.isSelected
        return Text(displayText.isEmpty ? " " : displayText)
            .font(.system(size: 13.5, design: .monospaced))
            .foregroundStyle(isSelected ? chatTextColor : chatTextColor.opacity(0.92))
            .lineLimit(1)
            .truncationMode(.middle)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(isSelected ? Color.black.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private func nativeInteractionDisplayText(for row: ShowCLINativeInteractionRow) -> String {
        row.text
    }

    private func blockTitle(_ block: ShowCLIReadingBlock) -> String {
        if block.kind == .input {
            return "Input"
        }

        switch block.variant {
        case .startup:
            return "Startup"
        case .prompt:
            return "Prompt"
        case .proseLike:
            return "Output"
        case .toolLike:
            return "Tool"
        case .activity:
            return "Activity"
        case .menu:
            return "Menu"
        case .status:
            return "Status"
        case .unknown:
            return "Terminal"
        }
    }

    private func blockIcon(_ block: ShowCLIReadingBlock) -> String {
        if block.kind == .input {
            return "keyboard"
        }

        switch block.variant {
        case .startup:
            return "sparkles"
        case .prompt:
            return "keyboard"
        case .toolLike:
            return "terminal"
        case .activity:
            return "hourglass"
        case .menu:
            return "list.bullet.rectangle"
        case .status:
            return "clock"
        case .unknown:
            return "questionmark.square"
        case .proseLike:
            return "text.alignleft"
        }
    }

    private func blockMetadata(_ block: ShowCLIReadingBlock, rowCount: Int) -> String {
        var parts = [formatTime(block.createdAt), "\(rowCount) rows"]
        if block.updatedAt.timeIntervalSince(block.createdAt) > 0.5 {
            parts.append("updated \(formatTime(block.updatedAt))")
        }
        if block.isLiveProjection {
            parts.append("terminal-derived")
        } else {
            parts.append("app-owned")
        }
        if block.isLiveProjection {
            parts.append(block.confidence.rawValue)
        }
        return parts.joined(separator: " | ")
    }

    private func toolGroupSummary(_ blocks: [ShowCLIReadingBlock]) -> String {
        let visibleLines = blocks.flatMap { block in
            ShowCLIReadingPresentation.normalizedLines(from: block.displayText)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }

        if let worked = visibleLines.first(where: { $0.hasPrefix("Worked for") }) {
            return worked
        }

        let toolCount = blocks.filter { $0.variant == .toolLike }.count
        let activityCount = blocks.filter { $0.variant == .activity }.count
        let menuCount = blocks.filter { $0.variant == .menu }.count
        let statusCount = blocks.filter { $0.variant == .status }.count

        if toolCount > 0 && activityCount > 0 {
            return "\(toolCount) tools, \(activityCount) activities"
        }

        if toolCount > 0 {
            return toolCount == 1 ? "1 tool event" : "\(toolCount) tool events"
        }

        if activityCount > 0 {
            return activityCount == 1 ? "Activity" : "\(activityCount) activities"
        }

        if menuCount > 0 {
            return menuCount == 1 ? "Menu" : "\(menuCount) menu items"
        }

        if statusCount > 0 {
            return statusCount == 1 ? "Status" : "\(statusCount) status items"
        }

        return blocks.count == 1 ? "Terminal detail" : "\(blocks.count) terminal details"
    }

    private func chatDisplayLines(for block: ShowCLIReadingBlock) -> [String] {
        let text = ShowCLIReadingPresentation.chatText(for: block)
        let lines = normalizedLines(from: text)
        return lines.isEmpty ? [""] : lines
    }

    private func blockPreview(_ block: ShowCLIReadingBlock) -> String {
        chatDisplayLines(for: block)
            .first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? "Empty block"
    }

    private func normalizedLines(from text: String) -> [String] {
        guard !text.isEmpty else { return [] }

        var lines: [String] = []
        var blankRun = 0

        for rawLine in text.components(separatedBy: .newlines) {
            let line = trimmingTrailingWhitespace(from: rawLine)

            if line.isEmpty {
                blankRun += 1
                if blankRun <= 2 {
                    lines.append(line)
                }
            } else {
                blankRun = 0
                lines.append(line)
            }
        }

        while lines.last?.isEmpty == true {
            lines.removeLast()
        }

        return lines.isEmpty ? [""] : lines
    }

    private func trimmingTrailingWhitespace(from line: String) -> String {
        var trimmed = line
        while let lastScalar = trimmed.unicodeScalars.last,
              CharacterSet.whitespaces.contains(lastScalar) {
            trimmed.removeLast()
        }
        return trimmed
    }

    private func submitComposer() {
        if controller.nativeInteractionIsActive {
            guard controller.nativeInteractionPhase.acceptsInput else { return }
            controller.sendNativeInteractionEnter()
            ptyProxyText = controller.nativeInteractionDisplayText
            focusComposer()
            return
        }

        if controller.submitComposer(composerText) {
            composerText = ""
            focusComposer()
        }
    }

    private func handleComposerTextChange(_ text: String) {
        guard let prefix = nativeInteractionPrefix(for: text) else { return }
        _ = startNativeInteractionFromComposer(text, origin: .prefix(prefix))
    }

    @discardableResult
    private func startNativeInteractionFromComposer(
        _ text: String,
        origin: ShowCLINativeInteractionOrigin
    ) -> Bool {
        guard nativeInteractionPrefix(for: text) != nil else { return false }

        if controller.beginNativeInteraction(initialText: text, origin: origin) {
            composerText = ""
            ptyProxyText = controller.nativeInteractionDisplayText
            focusedField = .composer
            return true
        }

        return false
    }

    private func nativeInteractionPrefix(for text: String) -> String? {
        guard controller.hasCurrentSurface,
              !controller.nativeInteractionIsActive else { return nil }

        return ShowCLIComposerNativeTrigger.prefix(
            for: text,
            canUseCodexDollarCommand: controller.canUseCodexDollarCommand
        )
    }

    private func handlePTYInteractionText(_ text: String) -> Bool {
        guard controller.nativeInteractionIsActive,
              controller.nativeInteractionPhase.capturesTextInput else { return false }

        let sent = controller.sendNativeInteractionText(text)
        if sent {
            ptyProxyText = controller.nativeInteractionDisplayText
        }
        return sent
    }

    private func handlePTYInteractionKey(_ event: NSEvent) -> Bool {
        let sent = controller.handlePTYInteractionKey(event)
        if sent {
            ptyProxyText = controller.nativeInteractionDisplayText
        }
        return sent
    }

    private func handlePTYInteractionCommand(_ command: ShowCLIInteractionCommand, event: NSEvent) -> Bool {
        guard controller.nativeInteractionPhase.acceptsInput else { return false }

        switch command {
        case .tab:
            return controller.sendNativeInteractionKey(.tab)
        case .enter:
            let sent = controller.sendNativeInteractionEnter()
            ptyProxyText = controller.nativeInteractionDisplayText
            return sent
        case .escape:
            let sent = controller.cancelNativeInteraction()
            ptyProxyText = ""
            return sent
        case .arrowUp:
            return controller.sendNativeInteractionKey(.arrowUp)
        case .arrowDown:
            return controller.sendNativeInteractionKey(.arrowDown)
        case .arrowLeft:
            return controller.sendNativeInteractionKey(.arrowLeft)
        case .arrowRight:
            return controller.sendNativeInteractionKey(.arrowRight)
        case .backspace:
            let sent = controller.sendNativeInteractionKey(.backspace)
            ptyProxyText = controller.nativeInteractionDisplayText
            return sent
        case .delete:
            let sent = controller.sendNativeInteractionKey(.delete)
            ptyProxyText = controller.nativeInteractionDisplayText
            return sent
        }
    }

    private func focusComposer() {
        Task { @MainActor in
            if controller.hasCurrentSurface {
                focusedField = .composer
            }
        }
    }

    private func highlightedLine(_ line: String, blockID: UUID, lineIndex: Int) -> AttributedString {
        let displayLine = line.isEmpty ? " " : line
        let attributed = NSMutableAttributedString(string: displayLine)
        let lineMatches = searchMatches.filter {
            $0.blockID == blockID && $0.lineIndex == lineIndex
        }

        for match in lineMatches {
            let isSelected = match.id == selectedMatchID
            let backgroundColor = isSelected
                ? NSColor.selectedContentBackgroundColor
                : NSColor.systemYellow.withAlphaComponent(0.35)

            attributed.addAttribute(.backgroundColor, value: backgroundColor, range: match.range)
            if isSelected {
                attributed.addAttribute(.foregroundColor, value: NSColor.selectedTextColor, range: match.range)
            }
        }

        return AttributedString(attributed)
    }

    private func toggleFold(_ blockID: UUID) {
        if foldedBlockIDs.contains(blockID) {
            foldedBlockIDs.remove(blockID)
        } else {
            foldedBlockIDs.insert(blockID)
        }
    }

    private func togglePin(_ blockID: UUID) {
        if pinnedBlockIDs.contains(blockID) {
            pinnedBlockIDs.remove(blockID)
        } else {
            pinnedBlockIDs.insert(blockID)
        }
    }

    private func togglePreserve(_ blockID: UUID) {
        if preservedBlockIDs.contains(blockID) {
            preservedBlockIDs.remove(blockID)
        } else {
            preservedBlockIDs.insert(blockID)
        }
    }

    private func toggleToolGroup(_ groupID: String) {
        if expandedToolGroupIDs.contains(groupID) {
            expandedToolGroupIDs.remove(groupID)
        } else {
            expandedToolGroupIDs.insert(groupID)
        }
    }

    private func pruneManualBlockState() {
        let validBlockIDs = Set(blocks.map(\.id))
        foldedBlockIDs = foldedBlockIDs.intersection(validBlockIDs)
        pinnedBlockIDs = pinnedBlockIDs.intersection(validBlockIDs)
        preservedBlockIDs = preservedBlockIDs.intersection(validBlockIDs)
    }

    private func blockAnchor(_ blockID: UUID) -> String {
        "showcli-reading-block-\(blockID.uuidString)"
    }

    private func renderItemAnchor(_ itemID: String) -> String {
        "showcli-reading-item-\(itemID)"
    }

    private func lineAnchor(blockID: UUID, lineIndex: Int) -> String {
        "showcli-reading-block-\(blockID.uuidString)-line-\(lineIndex)"
    }

    private func selectFirstMatch(proxy: ScrollViewProxy) {
        guard !searchMatches.isEmpty else {
            selectedMatchID = nil
            return
        }

        selectMatch(at: 0, proxy: proxy)
    }

    private func normalizeSelectedMatch(proxy: ScrollViewProxy) {
        guard !searchMatches.isEmpty else {
            selectedMatchID = nil
            return
        }

        if let selectedMatchID,
           let match = searchMatches.first(where: { $0.id == selectedMatchID }) {
            scrollToMatch(match, proxy: proxy)
            return
        }

        selectMatch(at: 0, proxy: proxy)
    }

    private func selectPreviousMatch(proxy: ScrollViewProxy) {
        guard !searchMatches.isEmpty else { return }

        let currentIndex = selectedMatchIndex ?? 0
        let nextIndex = currentIndex == 0 ? searchMatches.count - 1 : currentIndex - 1
        selectMatch(at: nextIndex, proxy: proxy)
    }

    private func selectNextMatch(proxy: ScrollViewProxy) {
        guard !searchMatches.isEmpty else { return }

        let currentIndex = selectedMatchIndex ?? -1
        let nextIndex = (currentIndex + 1) % searchMatches.count
        selectMatch(at: nextIndex, proxy: proxy)
    }

    private func selectMatch(at index: Int, proxy: ScrollViewProxy) {
        guard searchMatches.indices.contains(index) else { return }

        let match = searchMatches[index]
        selectedMatchID = match.id
        scrollToMatch(match, proxy: proxy)
    }

    private func scrollToMatch(_ match: ShowCLIReadingSearchMatch, proxy: ScrollViewProxy) {
        foldedBlockIDs.remove(match.blockID)

        DispatchQueue.main.async {
            proxy.scrollTo(
                lineAnchor(blockID: match.blockID, lineIndex: match.lineIndex),
                anchor: .center
            )
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

}

private enum ShowCLIInteractionCommand {
    case tab
    case enter
    case escape
    case arrowUp
    case arrowDown
    case arrowLeft
    case arrowRight
    case backspace
    case delete
}

private struct ShowCLINativeInteractionRow: Identifiable {
    let id: String
    let text: String
    let isSelected: Bool

    init(blockID: UUID, lineIndex: Int, text: String) {
        self.id = "\(blockID.uuidString)-\(lineIndex)"
        self.text = text
        self.isSelected = false
    }

    init(screenLineIndex: Int, text: String) {
        self.id = "screen-\(screenLineIndex)"
        self.text = text
        self.isSelected = false
    }

    init(line: ShowCLINativeInteractionLine) {
        self.id = line.id
        self.text = line.text
        self.isSelected = line.isSelected
    }
}

private struct ShowCLIComposerTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var measuredHeight: CGFloat
    @Binding var hasVisibleText: Bool

    let isEnabled: Bool
    let shouldFocus: Bool
    let minHeight: CGFloat
    let maxHeight: CGFloat
    let onSubmit: () -> Void
    let onNativePrefix: (String) -> Bool

    private static let enabledTextColor = NSColor(
        calibratedRed: 0.090,
        green: 0.094,
        blue: 0.104,
        alpha: 1
    )
    private static let disabledTextColor = NSColor(
        calibratedRed: 0.455,
        green: 0.459,
        blue: 0.470,
        alpha: 1
    )
    private static let insertionPointColor = NSColor.controlAccentColor

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = false
        scrollView.autohidesScrollers = true

        let textView = ShowCLIComposerNSTextView(frame: .zero)
        let coordinator = context.coordinator
        textView.onFirstCharacterNativePrefix = { [weak coordinator] prefix in
            coordinator?.parent.onNativePrefix(prefix) ?? false
        }
        textView.onVisibleTextStateMayHaveChanged = { [weak coordinator] in
            coordinator?.updateVisibleTextState()
        }
        textView.delegate = context.coordinator
        textView.string = text
        textView.font = .systemFont(ofSize: 13.5)
        textView.textColor = Self.enabledTextColor
        textView.insertionPointColor = Self.insertionPointColor
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.isRichText = false
        textView.importsGraphics = false
        textView.isEditable = isEnabled
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.minSize = NSSize(width: 0, height: minHeight)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.autoresizingMask = [.width]
        textView.textContainerInset = NSSize(width: 0, height: 6)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false

        scrollView.documentView = textView
        context.coordinator.textView = textView
        context.coordinator.scrollView = scrollView
        context.coordinator.updateMeasuredHeight()
        context.coordinator.updateVisibleTextState()

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.scrollView = scrollView

        if let textView = context.coordinator.textView {
            if textView.string != text,
               !textView.hasMarkedText() {
                context.coordinator.isUpdatingFromSwiftUI = true
                textView.string = text
                context.coordinator.isUpdatingFromSwiftUI = false
            }

            textView.isEditable = isEnabled
            textView.textColor = isEnabled ? Self.enabledTextColor : Self.disabledTextColor
            textView.insertionPointColor = Self.insertionPointColor
            context.coordinator.updateMeasuredHeight()
            context.coordinator.updateVisibleTextState()

            if shouldFocus,
               isEnabled,
               scrollView.window?.firstResponder !== textView {
                DispatchQueue.main.async {
                    guard textView.window === scrollView.window else { return }
                    scrollView.window?.makeFirstResponder(textView)
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: ShowCLIComposerTextView
        weak var textView: NSTextView?
        weak var scrollView: NSScrollView?
        var isUpdatingFromSwiftUI = false

        init(parent: ShowCLIComposerTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard !isUpdatingFromSwiftUI,
                  let textView = notification.object as? NSTextView else { return }

            parent.text = textView.string
            updateMeasuredHeight()
            updateVisibleTextState()
        }

        func textDidBeginEditing(_ notification: Notification) {
            updateVisibleTextState()
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            updateVisibleTextState()
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            guard commandSelector == #selector(NSResponder.insertNewline(_:)) ||
                    commandSelector == #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:)) else {
                return false
            }

            if textView.hasMarkedText() {
                return false
            }

            let modifiers = NSApp.currentEvent?.modifierFlags.intersection(.deviceIndependentFlagsMask) ?? []
            if modifiers.contains(.shift) {
                return false
            }

            parent.onSubmit()
            return true
        }

        func updateMeasuredHeight() {
            guard let textView, let scrollView, let textContainer = textView.textContainer else { return }

            let availableWidth = max(1, scrollView.contentSize.width)
            textContainer.containerSize = NSSize(
                width: availableWidth,
                height: CGFloat.greatestFiniteMagnitude
            )
            textView.layoutManager?.ensureLayout(for: textContainer)

            let usedHeight = (textView.layoutManager?.usedRect(for: textContainer).height ?? 0) +
                textView.textContainerInset.height * 2
            let nextHeight = min(max(ceil(usedHeight), parent.minHeight), parent.maxHeight)

            scrollView.hasVerticalScroller = usedHeight > parent.maxHeight + 1

            guard abs(parent.measuredHeight - nextHeight) > 0.5 else { return }
            let measuredHeight = parent.$measuredHeight
            DispatchQueue.main.async {
                measuredHeight.wrappedValue = nextHeight
            }
        }

        func updateVisibleTextState() {
            guard let textView else { return }

            let nextValue = ShowCLIComposerNativeTrigger.hasVisibleComposerText(
                string: textView.string,
                hasMarkedText: textView.hasMarkedText()
            )
            guard parent.hasVisibleText != nextValue else { return }

            parent.hasVisibleText = nextValue
        }
    }
}

private final class ShowCLIComposerNSTextView: NSTextView {
    var onFirstCharacterNativePrefix: ((String) -> Bool)?
    var onVisibleTextStateMayHaveChanged: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        if handleFirstCharacterNativePrefix(event) {
            onVisibleTextStateMayHaveChanged?()
            return
        }

        super.keyDown(with: event)
        onVisibleTextStateMayHaveChanged?()
    }

    override func insertText(_ insertString: Any, replacementRange: NSRange) {
        super.insertText(insertString, replacementRange: replacementRange)
        onVisibleTextStateMayHaveChanged?()
    }

    override func setMarkedText(_ string: Any, selectedRange: NSRange, replacementRange: NSRange) {
        super.setMarkedText(string, selectedRange: selectedRange, replacementRange: replacementRange)
        onVisibleTextStateMayHaveChanged?()
    }

    override func unmarkText() {
        super.unmarkText()
        onVisibleTextStateMayHaveChanged?()
    }

    private func handleFirstCharacterNativePrefix(_ event: NSEvent) -> Bool {
        let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard !modifierFlags.contains(.command),
              !modifierFlags.contains(.control),
              !modifierFlags.contains(.option) else { return false }

        guard let prefix = ShowCLIComposerNativeTrigger.prefixForFirstKeyCharacters(
            event.characters,
            existingText: string,
            hasMarkedText: hasMarkedText(),
            canUseCodexDollarCommand: true
        ) else { return false }

        return onFirstCharacterNativePrefix?(prefix) == true
    }
}

private struct ShowCLIInteractionKeyCaptureView: NSViewRepresentable {
    let shouldFocus: Bool
    let isEnabled: Bool
    let focusRequestID: Int
    let onCommand: (ShowCLIInteractionCommand, NSEvent) -> Bool
    let onKeyEvent: (NSEvent) -> Bool
    let onTextInput: (String) -> Bool

    func makeNSView(context: Context) -> ShowCLIInteractionKeyCaptureNSView {
        let view = ShowCLIInteractionKeyCaptureNSView()
        view.onCommand = onCommand
        view.onKeyEvent = onKeyEvent
        view.onTextInput = onTextInput
        return view
    }

    func updateNSView(_ nsView: ShowCLIInteractionKeyCaptureNSView, context: Context) {
        nsView.onCommand = onCommand
        nsView.onKeyEvent = onKeyEvent
        nsView.onTextInput = onTextInput
        nsView.isEnabled = isEnabled
        let focusRequestChanged = nsView.focusRequestID != focusRequestID
        nsView.focusRequestID = focusRequestID

        if isEnabled, shouldFocus || focusRequestChanged {
            nsView.requestFocus()
        }
    }
}

private final class ShowCLIInteractionKeyCaptureNSView: NSView {
    var isEnabled = true
    var focusRequestID = 0
    var onCommand: ((ShowCLIInteractionCommand, NSEvent) -> Bool)?
    var onKeyEvent: ((NSEvent) -> Bool)?
    var onTextInput: ((String) -> Bool)?
    private var wantsFocus = false

    override var acceptsFirstResponder: Bool { isEnabled }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if wantsFocus {
            requestFocus()
        }
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        requestFocus()
    }

    func requestFocus() {
        wantsFocus = true
        focusAfterLayout(delay: 0)
        focusAfterLayout(delay: 0.03)
        focusAfterLayout(delay: 0.12)
    }

    private func focusAfterLayout(delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, self.isEnabled else { return }
            self.window?.makeFirstResponder(self)
        }
    }

    override func keyDown(with event: NSEvent) {
        guard isEnabled else {
            super.keyDown(with: event)
            return
        }

        if handleCommand(event) {
            return
        }

        if onKeyEvent?(event) == true {
            return
        }

        guard let characters = showCLIInteractionText(for: event) else {
            super.keyDown(with: event)
            return
        }

        guard onTextInput?(characters) == true else {
            super.keyDown(with: event)
            return
        }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if showCLIIsPasteKeyEquivalent(event),
           let pasted = NSPasteboard.general.string(forType: .string),
           !pasted.isEmpty {
            return onTextInput?(pasted) == true
        }

        return super.performKeyEquivalent(with: event)
    }

    private func handleCommand(_ event: NSEvent) -> Bool {
        guard let command = showCLIInteractionCommand(for: event) else { return false }
        return onCommand?(command, event) ?? false
    }
}

private func showCLIInteractionCommand(for event: NSEvent) -> ShowCLIInteractionCommand? {
    let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
    guard !modifierFlags.contains(.command),
          !modifierFlags.contains(.control),
          !modifierFlags.contains(.option) else { return nil }

    switch event.keyCode {
    case 48:
        return .tab
    case 36, 76:
        return .enter
    case 53:
        return .escape
    case 126:
        return .arrowUp
    case 125:
        return .arrowDown
    case 123:
        return .arrowLeft
    case 124:
        return .arrowRight
    case 51:
        return .backspace
    case 117:
        return .delete
    default:
        return nil
    }
}

private func showCLIInteractionText(for event: NSEvent) -> String? {
    let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
    guard !modifierFlags.contains(.command),
          !modifierFlags.contains(.control),
          !modifierFlags.contains(.option),
          let characters = event.characters,
          !characters.isEmpty else { return nil }

    return characters
}

private func showCLIIsPasteKeyEquivalent(_ event: NSEvent) -> Bool {
    let modifierFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
    return modifierFlags.contains(.command)
        && !modifierFlags.contains(.control)
        && !modifierFlags.contains(.option)
        && event.charactersIgnoringModifiers?.lowercased() == "v"
}
#endif
