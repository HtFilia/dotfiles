// chezmoi passes the deployed file on stdin and writes what this prints.
// `kind` ("settings" or "keybindings") and `managedText` (the dotfiles'
// JSONC) are defined by the modify_ script that includes this file.
//
// Settings: the dotfiles' keys win over the UI, keys only the UI wrote stay,
// and <kind>.local.json wins over both. Keybindings (VS Code lets later
// entries win): the dotfiles' entries, then the ones only the UI added, then
// the local file's.
//
// Assumption: a key or entry removed from the dotfiles or the local file is
// indistinguishable from one the UI wrote, so it stays until removed in
// VS Code.
const fs = require("fs");
const path = require("path");

/** Parse JSON with comments and trailing commas, as VS Code writes it. */
function parseJsonc(text, source) {
  let json = "";
  let inString = false;
  for (let i = 0; i < text.length; i++) {
    const char = text[i];
    const next = text[i + 1];
    if (inString) {
      json += char;
      if (char === "\\") json += text[++i];
      else if (char === '"') inString = false;
    } else if (char === '"') {
      inString = true;
      json += char;
    } else if (char === "/" && next === "/") {
      while (i < text.length && text[i] !== "\n") i++;
      json += "\n";
    } else if (char === "/" && next === "*") {
      const end = text.indexOf("*/", i + 2);
      i = end < 0 ? text.length : end + 1;
    } else {
      if (char === "}" || char === "]") json = json.replace(/,\s*$/, "");
      json += char;
    }
  }
  if (json.trim() === "") return undefined;
  try {
    return JSON.parse(json);
  } catch (error) {
    throw new Error(`${source}: ${error.message}`);
  }
}

const userDir = path.join(process.env.HOME, ".config", "Code", "User");
const localPath = path.join(userDir, `${kind}.local.json`);
const empty = kind === "settings" ? {} : [];
const managed = parseJsonc(managedText, `dotfiles ${kind}`) ?? empty;
const current = parseJsonc(fs.readFileSync(0, "utf8"), `${kind}.json`) ?? empty;
const local = fs.existsSync(localPath)
  ? (parseJsonc(fs.readFileSync(localPath, "utf8"), localPath) ?? empty)
  : empty;

let merged;
if (kind === "settings") {
  merged = { ...managed };
  for (const [key, value] of Object.entries(current)) {
    if (!(key in managed)) merged[key] = value;
  }
  Object.assign(merged, local);
} else {
  const identity = (entry) => JSON.stringify(entry);
  const known = new Set([...managed, ...local].map(identity));
  const uiOnly = current.filter((entry) => !known.has(identity(entry)));
  merged = [...managed, ...uiOnly, ...local];
}

process.stdout.write(
  `// Written by chezmoi: the dotfiles' ${kind}, those added in VS Code, then\n` +
    `// ~/.config/Code/User/${kind}.local.json. On apply the dotfiles win over\n` +
    `// VS Code; overrides for this machine go in the local file.\n` +
    JSON.stringify(merged, null, 2) +
    "\n",
);
