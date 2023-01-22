// The MIT License (MIT)
//
// Copyright (c) 2020–2023 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import Pulse
import CoreData
import Combine

#if os(iOS)

struct ConsoleToolbarView: View {
    let viewModel: ConsoleViewModel

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if viewModel.isNetworkModeEnabled {
                ConsoleToolbarTitle(viewModel: viewModel)
            } else {
                ConsoleModePicker(viewModel: viewModel)
            }
            Spacer()
            HStack(spacing: 14) {
                ConsoleFiltersView(viewModel: viewModel.searchCriteriaViewModel, router: viewModel.router)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct ConsoleModePicker: View {
    let viewModel: ConsoleViewModel
    @ObservedObject var logsCounter: ManagedObjectsCountObserver
    @ObservedObject var tasksCounter: ManagedObjectsCountObserver

    @State private var mode: ConsoleMode = .all
    @State private var title: String = ""

    init(viewModel: ConsoleViewModel) {
        self.viewModel = viewModel
        self.logsCounter = viewModel.list.logCountObserver
        self.tasksCounter = viewModel.list.taskCountObserver
    }

    var body: some View {
        HStack(spacing: 12) {
            ConsoleModeButton(title: "All", isSelected: mode == .all) {
                viewModel.mode = .all
            }
            ConsoleModeButton(title: "Logs", details: "\(logsCounter.count)", isSelected: mode == .logs) {
                viewModel.mode = .logs
            }
            ConsoleModeButton(title: "Tasks", details: "\(tasksCounter.count)", isSelected: mode == .tasks) {
                viewModel.mode = .tasks
            }
        }
        .onReceive(viewModel.list.$mode) { mode = $0 }
    }
}

private struct ConsoleToolbarTitle: View {
    let viewModel: ConsoleViewModel

    @State private var title: String = ""

    var body: some View {
        Text(title)
            .foregroundColor(.secondary)
            .font(.subheadline.weight(.medium))
            .onReceive(titlePublisher) { title = $0 }
    }

    private var titlePublisher: some Publisher<String, Never> {
        viewModel.list.$entities.map { entities in
            "\(entities.count) Requests"
        }
    }
}

private struct ConsoleModeButton: View {
    let title: String
    var details: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .foregroundColor(isSelected ? Color.blue : Color.secondary)
                    .font(.subheadline.weight(.medium))
                if let details = details {
                    Text("(\(details))")
                        .foregroundColor(Color.separator)
                        .font(.subheadline)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct ConsoleFiltersView: View {
    @ObservedObject var viewModel: ConsoleSearchCriteriaViewModel
    @ObservedObject var router: ConsoleRouter

    var body: some View {
        Button(action: { viewModel.isOnlyErrors.toggle() }) {
            Image(systemName: viewModel.isOnlyErrors ? "exclamationmark.octagon.fill" : "exclamationmark.octagon")
                .font(.system(size: 20))
                .foregroundColor(viewModel.isOnlyErrors ? .red : .accentColor)
        }
        Button(action: { router.isShowingFilters = true }) {
            Image(systemName: viewModel.isCriteriaDefault ? "line.horizontal.3.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.accentColor)
        }
    }
}

#endif
