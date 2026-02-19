# AI Agent Guide

## Development Philosophy

### Test-Driven Development (TDD)

- Follow Test-Driven Development (TDD) as advocated by Kent Beck and t-wada
- Write tests first based on expected inputs and outputs
- Prepare only tests without writing implementation code
- Run tests and confirm they fail
- Commit once you've confirmed the tests are correct
- Then proceed with implementation to make the tests pass
- Do not modify tests during implementation; only modify the code
- Repeat until all tests pass

### Package Management

- Use project-specific package management
- Use [`mise`](https://mise.jdx.dev/) for globally installed tools

### GitHub

- Use the `gh` command for GitHub operations

### Review Gate

Run reviews at important milestones and repeat the cycle of "review → fix → re-review" until the code is clean.

Important milestones include: after updating specs or plans, after major implementation steps (changes to 5+ files, public API updates, infrastructure config updates, etc.), and before commits/PRs/releases.

Review methods:

- Use a subagent to perform the review. Choose a subagent appropriate for the changes.
- Use commands such as `/review` to perform the review.
- Use agent skills to perform the review.
- If none of the above are available, perform the review yourself.

## Web Application Development

### Manual Testing & Evidence

After implementing a feature, always create E2E tests and capture evidence to verify functionality. This ensures humans don't need to manually verify the implementation.

**Requirements:**

- Implement E2E tests that verify the feature
- Capture screenshots of each relevant page
- Record a video demonstrating the entire flow, then open it for review
- Use available MCP tools: Chrome Dev Tools MCP or Playwright MCP

**E2E Test Rules:**

- `goto` is only allowed for the initial navigation to `/`
- Always start from sign-up flow
- Navigate through the app by clicking buttons (no direct URL navigation)
- Test the target functionality through natural user flow

**If stuck:**

- If you encounter issues during browser operations or testing, ask the human for assistance

### Browser Automation

Use `agent-browser` for web automation. Run `agent-browser --help` for all commands.

Core workflow:

1. `agent-browser open <url>` - Navigate to page
2. `agent-browser snapshot -i` - Get interactive elements with refs (@e1, @e2)
3. `agent-browser click @e1` / `fill @e2 "text"` - Interact using refs
4. Re-snapshot after page changes

## Investigation

If you encounter technical blockers, unknowns, or unresolvable errors during design or development, try the following in order:

1. Use a subagent to investigate
2. Use the Web Search tool to investigate
