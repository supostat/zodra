import * as vscode from "vscode";
import * as fs from "fs/promises";
import * as path from "path";

export function registerStaleCheck(
  context: vscode.ExtensionContext,
): void {
  checkStaleFiles();

  const interval = setInterval(checkStaleFiles, 60_000);
  context.subscriptions.push({ dispose: () => clearInterval(interval) });
}

async function checkStaleFiles(): Promise<void> {
  const config = vscode.workspace.getConfiguration("zodra");
  const outputPath = config.get<string>(
    "outputPath",
    "app/javascript/types",
  );
  const root = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
  if (!root) return;

  const indexTs = path.join(root, outputPath, "index.ts");

  let tsTime: number;
  try {
    const stat = await fs.stat(indexTs);
    tsTime = stat.mtimeMs;
  } catch {
    return;
  }

  for (const dir of ["app/types", "app/contracts", "config/apis"]) {
    const fullDir = path.join(root, dir);

    let files: string[];
    try {
      files = (await fs.readdir(fullDir)).filter((f) => f.endsWith(".rb"));
    } catch {
      continue;
    }

    for (const file of files) {
      const stat = await fs.stat(path.join(fullDir, file));
      if (stat.mtimeMs > tsTime) {
        const choice = await vscode.window.showInformationMessage(
          "Zodra: generated TypeScript files may be outdated. Run export?",
          "Export Now",
        );
        if (choice === "Export Now") {
          vscode.commands.executeCommand("zodra.export");
        }
        return;
      }
    }
  }
}
