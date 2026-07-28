import assert from "node:assert/strict";

import releaseConfig from "../examples/release.config.mjs";

const nodeModulesPath = process.env.SEMANTIC_RELEASE_NODE_MODULES || "/npm/node_modules";
const { analyzeCommits } = await import(`${nodeModulesPath}/@semantic-release/commit-analyzer/index.js`);
const { generateNotes } = await import(`${nodeModulesPath}/@semantic-release/release-notes-generator/index.js`);

function pluginOptions(name) {
  const plugin = releaseConfig.plugins.find((entry) => Array.isArray(entry) && entry[0] === name);

  assert.ok(plugin, `Missing ${name} configuration`);
  return plugin[1];
}

const analyzerOptions = pluginOptions("@semantic-release/commit-analyzer");
const generatorOptions = pluginOptions("@semantic-release/release-notes-generator");
const logger = { log() {} };
const baseContext = {
  cwd: process.cwd(),
  logger,
  options: {
    repositoryUrl: "https://gitlab.example.com/voxpupuli/example.git",
  },
};
const commits = [
  {
    hash: "1111111111111111111111111111111111111111",
    message: "feat: add useful feature",
  },
  {
    hash: "2222222222222222222222222222222222222222",
    message: "fix(api): repair BUG-123",
  },
  {
    hash: "3333333333333333333333333333333333333333",
    message: "chore: document maintenance",
  },
];

const releaseType = await analyzeCommits(analyzerOptions, {
  ...baseContext,
  commits,
});

assert.equal(releaseType, "minor");

const choreReleaseType = await analyzeCommits(analyzerOptions, {
  ...baseContext,
  commits: [commits[2]],
});

assert.equal(choreReleaseType, null);

const notes = await generateNotes(generatorOptions, {
  ...baseContext,
  commits,
  lastRelease: {
    gitHead: "0000000000000000000000000000000000000000",
    gitTag: "v1.0.0",
  },
  nextRelease: {
    gitHead: "3333333333333333333333333333333333333333",
    gitTag: "v1.1.0",
    version: "1.1.0",
  },
});

const expectedNotes = [
  "### 🧹 Chores",
  "document maintenance",
  "### 🚀 Features",
  "add useful feature",
  "### 🛠️ Fixes",
  "repair BUG-123",
  "https://jira.example.com/browse/BUG-123",
];

for (const expected of expectedNotes) {
  assert.match(notes, new RegExp(expected.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")));
}

console.log(notes);
