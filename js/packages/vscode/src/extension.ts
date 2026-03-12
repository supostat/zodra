import * as vscode from "vscode";
import { registerAutoExport } from "./auto_export";
import { registerNavigation } from "./navigation";
import { registerStaleCheck } from "./stale_check";

export function activate(context: vscode.ExtensionContext): void {
  const outputChannel = vscode.window.createOutputChannel("Zodra");
  outputChannel.appendLine("Zodra extension activated");
  context.subscriptions.push(outputChannel);

  context.subscriptions.push(
    vscode.commands.registerCommand("zodra.export", () => {
      const config = vscode.workspace.getConfiguration("zodra");
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
      vscode.tasks.executeTask(task);
    }),
  );

  registerAutoExport(context);
  registerNavigation(context);
  registerStaleCheck(context);
}

export function deactivate(): void {}
