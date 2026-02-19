---
name: review
description: Conduct comprehensive code reviews using 5 specialized subagents (code quality, performance, test coverage, documentation accuracy, security) in parallel, providing an integrated report. Use at important milestones (5+ file changes, public API updates, infrastructure config updates, before commits/PRs/releases). Triggers on requests like "review this", "check the code", "review the changes".
---

# Review - Comprehensive Code Review

Conduct multi-perspective code reviews using specialized subagents.

## When to Use This Skill

Automatically suggest a review in the following situations:

- User says "review this", "check the code", or "review the changes"
- After completing an implementation involving 5+ file changes
- After public API updates
- Before creating a commit or PR
- User runs `/review`

## Review Perspectives

| Subagent | Perspective | Focus |
|---|---|---|
| **code-quality-reviewer** | Code Quality | Clean code, SOLID principles, readability, maintainability |
| **performance-reviewer** | Performance | Bottlenecks, N+1 queries, memory efficiency |
| **test-coverage-reviewer** | Test Coverage | Completeness, test quality, boundary values |
| **documentation-accuracy-reviewer** | Documentation Accuracy | Code-documentation alignment |
| **security-code-reviewer** | Security | OWASP Top 10, input validation, authentication & authorization |

## Execution Flow

### Step 1: Identify Review Targets

1. Use `git diff` and `git diff --staged` to check changes
2. If changes are extensive, list changed files to understand the review scope

### Step 2: Parallel Subagent Execution

**IMPORTANT**: Execute all 5 subagents **in parallel**.

Provide each subagent with:
- Diffs of changed files
- Relevant context (existing code, design intent)
- Instructions to report only noteworthy findings

### Step 3: Create Integrated Report

Once all reviews are complete, synthesize feedback into the following format:

1. **Summary**: Concise assessment of overall change quality
2. **Critical Issues** (if any): Issues requiring immediate attention
3. **Improvement Suggestions** (if any): Suggestions for quality enhancement
4. **Positive Highlights** (if any): Excellent implementations and good practices

### Step 4: Review Cycle

If issues are found:
1. Fix the issues
2. Run `/review` again
3. Repeat until no issues remain

## Conflict Resolution

When reviewers disagree or a design trade-off is unclear, use `/magi-decision-support` to get multi-perspective analysis. The MAGI system provides three viewpoints (Scientist, Mother, Realist) that can help resolve:

- Contradicting recommendations from different reviewers
- Architectural trade-offs with no clear winner
- Performance vs. readability vs. security trade-offs
- Any decision where reasonable engineers would disagree

## Notes

- Keep feedback concise and focus on important issues only
- Avoid burying critical problems under trivial concerns
- When code is well-written, acknowledge it explicitly
