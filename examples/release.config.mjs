const types = [
  { type: "build", section: "👷 Build", effect: "bump" },
  { type: "chore", section: "🧹 Chores", effect: "changelog" },
  { type: "ci", section: "🚦 CI/CD", effect: "changelog" },
  { type: "dep", section: "👾 Dependencies", effect: "bump" },
  { type: "docs", section: "📚 Docs", effect: "bump" },
  { type: "feat", section: "🚀 Features", effect: "bump" },
  { type: "fix", section: "🛠️ Fixes", effect: "bump" },
  { type: "perf", section: "⏩ Performance", effect: "bump" },
  { type: "refactor", section: "🔨 Refactor", effect: "changelog" },
  { type: "revert", section: "🙅 Reverts", effect: "bump" },
  { type: "test", section: "🚥 Tests", effect: "changelog" },
];

export default {
  branches: ["main"],

  gitlabUrl: "https://gitlab.example.com",
  gitlabApiPathPrefix: "/api/v4",

  plugins: [
    [
      "@semantic-release/commit-analyzer",
      {
        preset: "conventionalcommits",
        presetConfig: {
          types,
        },
      },
    ],
    [
      "@semantic-release/release-notes-generator",
      {
        preset: "conventionalcommits",
        parserOpts: {
          issuePrefixes: ["SUP-", "BUG-", "FEATURE-"],
          noteKeywords: ["BREAKING CHANGE", "BREAKING CHANGES", "BREAKING"],
        },
        presetConfig: {
          types,
          formatIssueUrl: (_context, { prefix, issue }) =>
            `https://jira.example.com/browse/${prefix}${issue}`,
        },
      },
    ],
    [
      "@semantic-release/changelog",
      {
        changelogFile: "CHANGELOG.md",
      },
    ],
    [
      "@semantic-release/git",
      {
        assets: ["CHANGELOG.md"],
      },
    ],
    "@semantic-release/gitlab",
  ],
};
