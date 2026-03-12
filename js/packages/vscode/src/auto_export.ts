import * as vscode from "vscode";

export function registerAutoExport(
  context: vscode.ExtensionContext,
): void {
  const watcher = vscode.workspace.createFileSystemWatcher(
    "{app/types,app/contracts,config/apis}/**/*.rb",
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

      const task = new vscode.Task(
        { type: "zodra", task: "export" },
        vscode.TaskScope.Workspace,
        "export",
        "zodra",
        new vscode.ShellExecution("bundle exec rails zodra:export"),
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
