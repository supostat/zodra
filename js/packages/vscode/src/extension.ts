import * as vscode from "vscode";

export function activate(context: vscode.ExtensionContext): void {
  const outputChannel = vscode.window.createOutputChannel("Zodra");
  outputChannel.appendLine("Zodra extension activated");
  context.subscriptions.push(outputChannel);
}

export function deactivate(): void {
  // cleanup
}
