//
//  RightClickSelectable.swift
//  Accio
//

import AppKit
import SwiftUI

/// A view modifier that selects an item on right-click before showing the context menu
struct RightClickSelectable<ID: Hashable>: ViewModifier {
    let id: ID
    @Binding var selection: Set<ID>
    var onRightClick: (() -> Void)?

    func body(content: Content) -> some View {
        RightClickWrapper(id: id, selection: $selection, onRightClick: onRightClick) {
            content
        }
    }
}

/// NSViewRepresentable that wraps content and intercepts right-clicks
private struct RightClickWrapper<ID: Hashable, Content: View>: NSViewRepresentable {
    let id: ID
    @Binding var selection: Set<ID>
    var onRightClick: (() -> Void)?
    @ViewBuilder let content: Content

    func makeNSView(context: Context) -> RightClickHostingView<ID> {
        let hostingView = NSHostingView(rootView: content)
        let wrapper = RightClickHostingView<ID>(hostingView: hostingView)
        wrapper.id = id
        wrapper.selectionBinding = $selection
        wrapper.onRightClick = onRightClick
        return wrapper
    }

    func updateNSView(_ nsView: RightClickHostingView<ID>, context: Context) {
        nsView.hostingView.rootView = AnyView(content)
        nsView.id = id
        nsView.selectionBinding = $selection
        nsView.onRightClick = onRightClick
    }
}

/// Custom NSView that wraps an NSHostingView and intercepts right-clicks
final class RightClickHostingView<ID: Hashable>: NSView {
    let hostingView: NSHostingView<AnyView>
    var id: ID!
    var selectionBinding: Binding<Set<ID>>!
    var onRightClick: (() -> Void)?

    init<Content: View>(hostingView: NSHostingView<Content>) {
        self.hostingView = NSHostingView(rootView: AnyView(hostingView.rootView))
        super.init(frame: .zero)

        self.hostingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(self.hostingView)

        NSLayoutConstraint.activate([
            self.hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            self.hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            self.hostingView.topAnchor.constraint(equalTo: topAnchor),
            self.hostingView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func rightMouseDown(with event: NSEvent) {
        // Perform any additional actions (e.g., focus the list)
        onRightClick?()
        // Select this item before the context menu appears
        selectionBinding.wrappedValue = [id]
        super.rightMouseDown(with: event)
    }
}

extension View {
    /// Makes the view select the given ID on right-click before showing context menu
    func selectOnRightClick<ID: Hashable>(
        id: ID,
        selection: Binding<Set<ID>>,
        onRightClick: (() -> Void)? = nil
    ) -> some View {
        modifier(RightClickSelectable(id: id, selection: selection, onRightClick: onRightClick))
    }
}
