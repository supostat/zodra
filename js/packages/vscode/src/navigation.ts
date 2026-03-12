import * as vscode from "vscode";
import * as path from "path";

export function registerNavigation(
  context: vscode.ExtensionContext,
): void {
  context.subscriptions.push(
    vscode.commands.registerCommand(
      "zodra.openGeneratedTS",
      async (relativeTsPath?: string) => {
        const config = vscode.workspace.getConfiguration("zodra");
        const outputPath = config.get<string>(
          "outputPath",
          "app/javascript/types",
        );
        const workspaceRoot =
          vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
        if (!workspaceRoot) return;

        if (relativeTsPath) {
          const fullPath = path.join(workspaceRoot, outputPath, relativeTsPath);
          return openFileOrWarn(fullPath);
        }

        const editor = vscode.window.activeTextEditor;
        if (!editor) return;

        const rubyPath = editor.document.uri.fsPath;
        const tsPath = rubyToTsPath(rubyPath, workspaceRoot, outputPath);
        if (tsPath) return openFileOrWarn(tsPath);
      },
    ),
  );

  context.subscriptions.push(
    vscode.commands.registerCommand("zodra.openRubySource", async () => {
      const editor = vscode.window.activeTextEditor;
      if (!editor) return;

      const config = vscode.workspace.getConfiguration("zodra");
      const outputPath = config.get<string>(
        "outputPath",
        "app/javascript/types",
      );
      const workspaceRoot =
        vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
      if (!workspaceRoot) return;

      const tsPath = editor.document.uri.fsPath;
      const rubyPath = tsToRubyPath(tsPath, workspaceRoot, outputPath);
      if (rubyPath) return openFileOrWarn(rubyPath);
    }),
  );
}

function rubyToTsPath(
  rubyPath: string,
  root: string,
  outputPath: string,
): string | null {
  const relative = path.relative(root, rubyPath);
  const match = relative.match(/^app\/(types|contracts)\/(.+)\.rb$/);
  if (!match) return null;

  const [, dir, name] = match;
  const kebabName = name.replace(/_/g, "-");
  return path.join(root, outputPath, dir, `${kebabName}.ts`);
}

function tsToRubyPath(
  tsPath: string,
  root: string,
  outputPath: string,
): string | null {
  const relative = path.relative(path.join(root, outputPath), tsPath);
  const match = relative.match(/^(types|contracts)\/(.+)\.ts$/);
  if (!match) return null;

  const [, dir, name] = match;
  if (name === "index") return null;
  const snakeName = name.replace(/-/g, "_");
  return path.join(root, "app", dir, `${snakeName}.rb`);
}

async function openFileOrWarn(filePath: string): Promise<void> {
  try {
    const uri = vscode.Uri.file(filePath);
    await vscode.workspace.fs.stat(uri);
    const doc = await vscode.workspace.openTextDocument(uri);
    await vscode.window.showTextDocument(doc);
  } catch {
    vscode.window.showWarningMessage(
      "File not found. Run 'rails zodra:export' to generate TypeScript files.",
    );
  }
}
