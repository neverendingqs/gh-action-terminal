# gh-action-terminal

Run any terminal command by making a comment using this GitHub Action.

**DISCLAIMER**: this GitHub Action allows for _arbtrary_ code execution by any user that can make a comment on an issue or a pull request. You should probably never use this except to explore what GitHub Actions could do.

## Examples

### Run Command and Comment Back Output

```yaml
on:
  issue_comment:
    types: [created]

jobs:
  terminal:
    runs-on: ubuntu-latest
    steps:
      - id: terminal
        uses: neverendingqs/gh-action-terminal@main
      - uses: actions/github-script@v3
        env:
          COMMAND: ${{ steps.terminal.outputs.command }}
          EXIT_CODE: ${{ steps.terminal.outputs.exit-code }}
          STDOUT: ${{ steps.terminal.outputs.stdout }}
        with:
          script: |
            const command = process.env.COMMAND;
            const exitCode = process.env.EXIT_CODE;
            const stdout = process.env.STDOUT;

            const body = `\`${command}\` had an exit code of ${exitCode}:\n`
              + '\n```\n'
              + stdout
              + '\n```\n';

            github.reactions.createForIssueComment({
              comment_id: context.payload.comment.id,
              owner: context.repo.owner,
              repo: context.repo.repo,
              content: '+1',
            });

            github.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body
            });
```

If I comment with `/terminal date`, the GitHub Action will react with a `+1` and comment back with:

```
`date` had an exit code of 0:


Sat Aug 29 23:04:14 UTC 2020
```

### Run a Command and Commit Resulting Changes

```yaml
on:
  issue_comment:
    types: [created]

jobs:
  run-and-update:
    if: contains(github.event.comment.html_url, '/pull/') && startsWith( github.event.comment.body, '/terminal ' )
    runs-on: ubuntu-latest
    steps:
      - name: Acknowledge command
        uses: actions/github-script@v3
        with:
          script: |
            github.reactions.createForIssueComment({
              comment_id: context.payload.comment.id,
              owner: context.repo.owner,
              repo: context.repo.repo,
              content: '+1',
            });
      - id: get-ref
        name: Get branch name
        uses: actions/github-script@v3
        with:
          result-encoding: string
          script: |
            const response = await github.pulls.get({
              owner: context.repo.owner,
              repo: context.repo.repo,
              pull_number: context.payload.issue.number
            });

            return response.data.head.ref;
      - uses: actions/checkout@v2
        with:
          ref: ${{ steps.get-ref.outputs.result }}
      - uses: actions/setup-node@v1
        with:
          node-version: '12'
      - id: terminal
        uses: neverendingqs/gh-action-terminal@main
      - run: |
          git config user.name github-actions[bot]
          git config user.email 41898282+github-actions[bot]@users.noreply.github.com

          git commit -am "chore: update after '${COMMAND}'."
          git push
        env:
          COMMAND: ${{ steps.terminal.outputs.command }}
```

If this was set up for a GitHub repository for a Node library and I comment `/terminal npm version patch --no-git-tag-version` on a pull request, this workflow will bump the patch version of the library and commit it to the same pull request with message `chore: update after 'npm version patch --no-git-tag-version'.`.
