import * as vscode from "vscode";

function buildWatcherPattern(): string {
  const config = vscode.workspace.getConfiguration("zodra");
  const paths = config.get<string[]>("sourcePaths", [
    "app/types",
    "app/contracts",
    "config/apis",
  ]);

  return `{${paths.join(",")}}/**/*.rb`;
}

export function registerAutoExport(
  context: vscode.ExtensionContext,
): void {
  const watcher = vscode.workspace.createFileSystemWatcher(
    buildWatcherPattern(),
  );

  let debounceTimer: ReturnType<typeof setTimeout> | undefined;
  const statusBarItem = vscode.window.createStatusBarItem(
    vscode.StatusBarAlignment.Left,
  );

  function triggerExport(): void {
    const config = vscode.workspace.getConfiguration("zodra");
    if (!config.get<boolean>("autoExport", true)) return;

    const debounceMs = config.get<number>("exportDebounceMs", 1500);

    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(async () => {
      statusBarItem.text = "$(sync~spin) Zodra: exporting...";
      statusBarItem.show();

      const command = config.get<string>(
        "exportCommand",
        "bundle exec rails zodra:export",
      );

      const task = new vscode.Task(
        { type: "zodra", task: "export" },
        vscode.TaskScope.Workspace,
        "export",
        "zodra",
        new vscode.ShellExecution(command),
      );
      task.presentationOptions = { reveal: vscode.TaskRevealKind.Silent };

      const execution = await vscode.tasks.executeTask(task);

      const endListener = vscode.tasks.onDidEndTask((event) => {
        if (event.execution === execution) {
          endListener.dispose();
          statusBarItem.text = "$(check) Zodra: exported";
          setTimeout(() => statusBarItem.hide(), 3000);
        }
      });
    }, debounceMs);
  }

  watcher.onDidChange(triggerExport);
  watcher.onDidCreate(triggerExport);
  watcher.onDidDelete(triggerExport);

  context.subscriptions.push(watcher, statusBarItem);
}
