# Development Guidelines Extracted from IC Metrics Analysis

**Source:** AI Analysis of Robert Douglas (@anucreative) GitHub Activity  
**Date Created:** October 27, 2025  
**Status:** Recommended for Team Implementation

---

## Table of Contents

1. [Git Commit Standards](#git-commit-standards)
2. [Pull Request Guidelines](#pull-request-guidelines)
3. [Branch Management Policy](#branch-management-policy)
4. [CI/CD Quality Gates](#cicd-quality-gates)
5. [Code Review Expectations](#code-review-expectations)
6. [Daily Development Practices](#daily-development-practices)

---

## Git Commit Standards

### Commit Message Format

**Rule:** All commits must follow [Conventional Commits](https://www.conventionalcommits.org/) format

**Format:**
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat:` - New functionality
- `fix:` - Bug fix
- `refactor:` - Code restructure (no functionality change)
- `docs:` - Documentation only
- `test:` - Test additions/changes
- `chore:` - Build, tooling, dependency updates
- `style:` - Code formatting (no logic change)

**Subject Line Rules:**
- ✅ Use imperative mood ("add" not "added" or "adds")
- ✅ Don't capitalize first letter
- ✅ Don't end with period
- ✅ Keep under 72 characters
- ✅ Be specific (not "fix bug", but "fix memory leak in WebSocket connection")

**Body Guidelines:**
- One blank line between subject and body
- Wrap at 72 characters
- Explain WHAT and WHY, not HOW
- Reference issue tickets: `Fixes #123`
- Keep to 1-3 paragraphs max

**Footer:**
- Reference issues: `Closes #123`
- Note breaking changes: `BREAKING CHANGE: description`

**Examples:**

❌ **Bad:**
```
fixed stuff
Update files
chore: improvements
```

✅ **Good:**
```
feat: add email validation to sign-up form

Validates email format using RFC 5322 regex pattern.
Prevents invalid emails from being submitted to backend.

Fixes #456
```

---

### Commit Size Limits

**Hard Limits:**
- **Maximum: 500 lines per commit** (warnings at 300, errors at 500)
- **Ideal range: 50-300 lines** per commit
- **Absolute maximum: 1000 lines** (emergency cases only, requires tech lead review)
- **Never allowed: >2000 line commits**

**Micro Commit Threshold:**
- Commits <10 lines should be squashed into related commits
- Exception: Simple dependency updates, single-line fixes (allowed 1-10 lines)

**Logic Behind Sizes:**
| Size | Status | Reason |
|------|--------|--------|
| 0-10 lines | ⚠️ Questionable | Too granular, create noise |
| 10-100 lines | ✅ Good | Reviewable in 5 minutes |
| 100-300 lines | ✅ Excellent | Reviewable in 10-15 minutes |
| 300-500 lines | ✅ Acceptable | Starts getting large, but manageable |
| 500-1000 lines | ❌ Large | Requires split into multiple commits |
| 1000+ lines | 🚫 Not Allowed | Never acceptable without exception |

**How to Manage Commit Size:**

For large changes:
1. Break feature into multiple logical commits:
   - Commit 1: Infrastructure/utilities
   - Commit 2: Core implementation
   - Commit 3: Edge cases/error handling
   - Commit 4: Tests
   - Commit 5: Documentation

2. Use `git add -p` for interactive staging:
   ```bash
   git add -p  # Interactively choose which chunks to stage
   ```

3. Use `git rebase -i` to clean up history before pushing:
   ```bash
   git rebase -i main  # Squash micro commits, split large commits
   ```

---

### Commit Message Length

**Limits:**
- Subject: max 72 characters
- Total message (subject + body): max 500 characters for typical commits
- Exception: Complex changes with detailed explanation (max 1000 chars, but use separate documentation instead)

**The 500 Character Rule:**
If your commit message exceeds 500 characters, consider:
- Is detailed context better in the PR description?
- Should this be a migration/RFC document?
- Are you trying to document in git history what belongs in project wiki?

**Guidelines:**
- 1-3 line subject + body = ✅ Good (50-300 characters)
- 10+ paragraphs = ❌ Wrong place (this is PR description or wiki)

---

### Prohibited Patterns

**Never use these in commit messages on main/develop branches:**
- ❌ "wip" or "work in progress"
- ❌ "todo" or "TODO"
- ❌ "fixme" or "FIXME"
- ❌ "temp" or "temporary"
- ❌ "test" or "testing"
- ❌ "asdf" or "xyz" or placeholder text
- ❌ All caps rants ("FIX THIS STUPID BUG")

**These are only acceptable on personal feature branches** - they must be cleaned up (squashed/rebased) before merging.

---

## Pull Request Guidelines

### PR Description Requirements

**Rule:** Every PR must have a complete description following the template

**Template:**
```markdown
## What
Brief 2-3 sentence description of what changed

## Why
Why is this change needed? What problem does it solve?
- Reference issue: Fixes #123
- Provide business/technical context

## How to Test
Step-by-step instructions for QA/reviewers to verify:
1. Start the app with `npm run dev`
2. Navigate to Settings
3. Change email address
4. Verify confirmation email sent
5. Verify user can confirm email

## Screenshots/Videos
(For UI changes) Include before/after screenshots or video

## Breaking Changes
List any breaking changes:
- ❌ Old API: `doSomething(user)` 
- ✅ New API: `doSomething(userId)`

## Checklist
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No console errors/warnings
- [ ] Tested on mobile (if UI change)
- [ ] Ready for review
```

**Validation Rules:**
- ✅ Description required (>50 characters)
- ✅ Template must be used
- ✅ At least one item in checklist
- ✅ Link to at least one issue/ticket

**Minimum Acceptable:**
```markdown
## What
Fixes typo in email validation

## Why
Fixes #789

## How to Test
Run tests: npm run test -- email.test.js
```

**Not Acceptable:**
```
(empty)
```

```
update stuff
```

---

### PR Size Limits

**Rules:**
- **Ideal: 150-400 lines** changed per PR
- **Maximum: 750 lines** changed per PR
- **Hard limit: 1000 lines** (requires extra review)
- **Absolute maximum: Never >2000 lines**

**What "lines changed" means:**
- Additions + deletions
- Don't count generated code
- Don't count dependency updates (unless significant refactor)

**If PR is too large:**
1. Split into multiple PRs:
   - PR #1: Infrastructure changes
   - PR #2: Core implementation
   - PR #3: Tests & edge cases
2. Use feature flags to merge incrementally
3. Document dependencies between PRs

---

### PR Lifetime

**Rules:**
- **Ideal: 1-3 days** (merge within 1 business day)
- **Maximum: 5 days** (branch can live this long)
- **Hard limit: 7 days** (branches >7 days require tech lead approval)
- **Never: >14 days** (must merge, close, or reset)

**Timeline:**
| Age | Status | Action |
|-----|--------|--------|
| 0-1 day | ✅ Good | Normal flow |
| 1-3 days | ✅ OK | Start reviewing |
| 3-5 days | ⚠️ Attention needed | Escalate for review |
| 5-7 days | 🔴 High risk | Tech lead review required |
| 7-14 days | 🚫 Unacceptable | Must merge, close, or reset |
| >14 days | 🚫 Not allowed | Automatic escalation |

**Best Practices:**
- Open PR immediately when starting work (even if WIP)
- Update frequently (daily or more)
- Clear blockers fast (don't wait weeks for review)
- Merge small PRs first to reduce conflicts

---

### PR Review Expectations

**Reviewer Responsibilities:**
- Review within 24 hours
- Flag quality issues (see Quality Gates below)
- Request changes if:
  - Missing tests
  - Empty PR description
  - Too large (>750 lines)
  - Too many commits (>10)
  - Branches too old (>5 days)
  - Poor commit messages

**Approval Criteria:**
- ✅ 2+ reviewers approved (or tech lead + 1)
- ✅ All CI checks pass
- ✅ All comments resolved
- ✅ PR description complete
- ✅ Tests added/updated
- ✅ No WIP commits

---

## Branch Management Policy

### Branch Naming

**Pattern:**
```
<type>/<scope>/<description>

Examples:
feature/auth/email-validation
fix/header/logo-alignment
refactor/api/error-handling
docs/setup-instructions
```

**Types:**
- `feature/` - New functionality
- `fix/` - Bug fixes
- `refactor/` - Code restructuring
- `docs/` - Documentation
- `test/` - Test additions
- `chore/` - Tooling, dependencies

**Rules:**
- ✅ Use hyphens, not underscores
- ✅ Keep under 50 characters total
- ✅ Be descriptive
- ✅ Use lowercase

❌ **Bad:**
```
feature_123
my_branch
fix-stuff
```

✅ **Good:**
```
feature/auth/email-validation
fix/cart/checkout-button
refactor/api/error-handling
```

---

### Branch Synchronization

**Rule:** Must sync with main at least daily

**Process:**
```bash
# Before starting work
git pull origin main

# During the day (if main changes)
git fetch origin
git rebase origin/main

# Before pushing
git fetch origin
git rebase origin/main
git push -f
```

**Why:**
- Catch integration issues early
- Reduce merge conflicts
- Keep codebase fresh
- Support continuous integration

**Frequency:**
- Start of day: ✅ Always
- Before commits: ✅ If >4 hours since last sync
- Before pushing: ✅ Always
- Throughout day: ✅ At least once every 4 hours on long-lived branches

---

### Long-Lived Branches

**Policy:**
- **Maximum life: 5 days** without tech lead approval
- **Approval required:** Tech lead review for 5-7 day branches
- **Break down:** Feature branches >5 days should be split into multiple PRs

**For longer-running features (5+ days):**
1. Split into smaller PRs:
   - PR 1: Infrastructure (days 1-2)
   - PR 2: Core feature (days 2-3)
   - PR 3: Tests & polish (days 3-4)
   - PR 4: Edge cases (days 4-5)
2. Use feature flags to merge incrementally
3. Keep main branch always deployable
4. Sync with main daily

**Example:**
```
Days 1-2: feature/auth/login-form (100 lines) → Merged
Days 2-3: feature/auth/password-validation (120 lines) → Merged
Days 3-4: feature/auth/remember-me (80 lines) → Merged
Days 4-5: feature/auth/2fa-support (150 lines) → Merged

Total impact: 4 small, focused PRs instead of 1 massive PR
```

---

## CI/CD Quality Gates

### Automated Checks (Pre-Commit Hooks)

**Install Git Hooks:**
```bash
npm run setup-hooks  # or your setup command
```

**Checks:**
1. ✅ Commit message format (conventional commits)
2. ✅ Commit size (<500 lines warning, error at 1000)
3. ✅ Blocked patterns (wip, todo, fixme)
4. ✅ Staged files only (no unstaged code)
5. ✅ Line length (<120 characters)

**Example Hook Output:**
```
✓ Checking commit message format...
✓ Checking commit size (247 lines) - OK
✓ Checking for prohibited patterns...
✓ All pre-commit checks passed!
```

---

### Automated Checks (CI Pipeline)

**On every push to any branch:**

1. **Commit validation:**
   - ✅ All commits follow conventional commits format
   - ✅ No commits >1000 lines
   - ✅ No WIP/TODO/FIXME commits
   - ✅ Message length <500 chars (warning), <1000 (error)

2. **PR validation:**
   - ✅ PR description not empty (>50 chars)
   - ✅ PR template used
   - ✅ PR size <1000 lines changed
   - ✅ Number of commits ≤15
   - ✅ Branch age ≤7 days (warning if >5)

3. **Code quality:**
   - ✅ Linting passes (ESLint, Prettier)
   - ✅ Type checking passes (TypeScript)
   - ✅ Tests pass (Jest, Vitest, or equivalent)
   - ✅ Code coverage maintained (>80% threshold)
   - ✅ No security vulnerabilities (npm audit)

4. **Build quality:**
   - ✅ Build succeeds
   - ✅ No console errors/warnings
   - ✅ Bundle size doesn't increase >10% unexpectedly
   - ✅ Performance metrics maintained

**Failure Handling:**
| Check | Fail Behavior | Resolution |
|-------|---------------|-----------|
| Format/size | Block merge | Fix commits and force-push |
| Linting | Block merge | Run `npm run lint --fix` |
| Tests | Block merge | Add/fix tests |
| Build | Block merge | Fix build errors |
| Coverage | Block merge | Add tests |

---

### Dashboard Monitoring

**Metrics to Track:**
1. **Commit health:**
   - % of commits following conventional commits (target: >95%)
   - Average commit size (target: <200 lines)
   - Commits with WIP/TODO/FIXME (target: 0)

2. **PR health:**
   - Average PR size (target: <400 lines)
   - Average PR lifetime (target: <3 days)
   - % PRs merged on time (target: >95%)

3. **Quality metrics:**
   - Test pass rate (target: 100%)
   - Code coverage (target: >80%)
   - Build success rate (target: >99%)

4. **Team metrics:**
   - Average review time (target: <24 hours)
   - % PRs approved (target: >95%)
   - Merge conflicts per week (target: <2)

---

## Code Review Expectations

### Review Standards

**Every review should check:**

1. **Correctness:**
   - Does the code do what it claims?
   - Are there edge cases missed?
   - Could this break other code?

2. **Quality:**
   - Is there duplicate code that should be shared?
   - Could this be simpler?
   - Is error handling complete?

3. **Testing:**
   - Are there tests for happy path?
   - Are there tests for edge cases?
   - Is code coverage maintained?

4. **Documentation:**
   - Is code self-explanatory?
   - Should there be comments?
   - Is public API documented?

5. **Style:**
   - Does it follow team standards?
   - Is formatting consistent?
   - Any security concerns?

---

### Review Tone & Approach

**Good Review Comment:**
```
"This could be more efficient using a Map instead of an array 
since we're doing O(n) lookups. This would change complexity 
from O(n²) to O(n)."
```

**Poor Review Comment:**
```
"This is inefficient"
```

**Good Review Question:**
```
"Should we validate the email format here or in the backend? 
I'm thinking backend is better for security, but want your thoughts."
```

**Poor Review Question:**
```
"Why did you do it this way?"
```

**Guidelines:**
- Ask questions, don't demand changes
- Explain the reasoning
- Suggest improvements, not just criticisms
- Acknowledge good work
- Be constructive and educational

---

### Required Reviewers

**Rules:**
- Minimum 2 approved reviewers
- OR 1 tech lead + 1 other reviewer
- At least 1 from core team (not always same person)
- For critical paths (auth, payments): 3 reviewers

**Reviewer Assignment:**
- Rotate reviewers (don't always be the same 2 people)
- Include junior developers (for learning)
- Include domain experts for specialized code

---

## Daily Development Practices

### Morning Routine

**First 30 minutes of day:**

1. **Sync with main:**
   ```bash
   git fetch origin
   git rebase origin/main
   ```

2. **Check for comments:**
   - Read new PR comments
   - Respond to questions
   - Make requested changes

3. **Review others' code:**
   - Review 1-2 open PRs from teammates
   - Leave constructive feedback
   - Approve ready PRs

4. **Plan the day:**
   - Pick ticket to work on
   - Break into commits
   - Estimate commit count

---

### During the Day

**Every 2-4 hours:**

1. **Sync with main** (if branch is >2 days old):
   ```bash
   git fetch origin
   git rebase origin/main
   ```

2. **Commit granularly:**
   - Commit every small logical unit
   - Don't wait until end of day
   - More frequent commits = easier to review

3. **Use descriptive commit messages:**
   - Follow conventional commits format
   - Explain the "why" not just the "what"
   - Include issue references

4. **Check CI results:**
   - Watch for build failures
   - Fix immediately (don't ignore red CI)
   - Debug locally first

---

### End of Day

**Last 30 minutes of day:**

1. **Push commits:**
   ```bash
   git push origin feature/my-branch
   ```

2. **Create/update PR:**
   - Fill out complete PR description
   - Include testing instructions
   - Link to related issues

3. **Request reviews:**
   - Tag reviewers
   - Comment about any blockers
   - Ask specific questions if needed

4. **Clean workspace:**
   - Commit any pending work (or stash)
   - Close unnecessary files
   - Write tomorrow's plan in a note

---

### Code Organization by Commit

**Example: Implementing Email Validation**

❌ **Bad: All in one commit (500 lines)**
```
commit: "feat: add email validation"
- Added validation function
- Updated component
- Added tests
- Updated types
- Added documentation
```

✅ **Good: Multiple logical commits**
```
commit 1: "feat: add email validation utility"
- Email validation function
- Regex patterns
- Error handling

commit 2: "feat: integrate email validation in form"
- Update form component
- Add error messages
- Update UI

commit 3: "test: add tests for email validation"
- Unit tests for validator
- Integration tests for form

commit 4: "docs: document email validation"
- Add JSDoc comments
- Update README
```

---

### Interactive Rebase Before Pushing

**Clean up your branch before merging:**

```bash
# View commits you're about to push
git log main..HEAD --oneline

# Start interactive rebase
git rebase -i main

# In the editor, consider:
# - Squash micro commits (< 10 lines)
# - Split large commits (> 500 lines)
# - Reorder commits logically
# - Clean up message typos
```

**Interactive rebase commands:**
```
pick   = use commit
reword = use commit, but edit message
squash = use commit, but meld into previous
split  = split commit into multiple
```

---

### Handling Large Features

**For features that take 3+ days:**

1. **Plan architecture first (day 1)**
   - Document approach
   - Get team feedback
   - Open RFC/discussion

2. **Implement incrementally (days 2-3)**
   - Day 2 PR: Infrastructure/utilities (100 lines)
   - Day 3 PR: Core feature (150 lines)
   - Day 4 PR: Edge cases (80 lines)

3. **Use feature flags (optional)**
   ```javascript
   if (featureFlags.newEmailValidation) {
     // Use new validation
   } else {
     // Use old validation
   }
   ```

4. **Merge early and often**
   - Keep main deployable
   - Reduce integration risk
   - Get early feedback

---

### Common Scenarios & Solutions

**Scenario: I committed too much in one commit**

Solution: Split using interactive rebase
```bash
git rebase -i HEAD~1
# Mark commit as "split"
# Stage files for first commit: git add file1
# Create first commit: git commit --amend
# Stage remaining files: git add file2 file3
# Create second commit: git commit
```

**Scenario: I have 3 tiny commits that should be one**

Solution: Squash using interactive rebase
```bash
git rebase -i HEAD~3
# Mark 2nd and 3rd as "squash"
# Combine messages as needed
```

**Scenario: My branch is 5 days old and conflicts with main**

Solution: Rebase onto main
```bash
git fetch origin
git rebase origin/main
# Resolve conflicts
git add .
git rebase --continue
git push -f  # Force push to your branch
```

**Scenario: I need to amend my last commit**

Solution: Amend and force push
```bash
git add .
git commit --amend --no-edit
git push -f
```

**Scenario: I forgot to add a file to the last commit**

Solution: Add file and amend
```bash
git add forgotten_file.js
git commit --amend
git push -f
```

---

## Tools & Setup

### Git Hooks Setup

**Install husky:**
```bash
npm install husky --save-dev
npx husky install
```

**Add commit-msg hook:**
```bash
npx husky add .husky/commit-msg \
  'npx --no -- commitlint --edit "$1"'
```

**Add pre-commit hook:**
```bash
npx husky add .husky/pre-commit \
  'npm run lint:staged'
```

### Configuration Files

**commitlint.config.js:**
```javascript
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'subject-case': [2, 'never', ['start-case', 'pascal-case']],
    'subject-full-stop': [2, 'never', '.'],
    'subject-empty': [2, 'never'],
    'type-case': [2, 'always', 'lowercase'],
    'type-empty': [2, 'never'],
    'type-enum': [
      2,
      'always',
      ['feat', 'fix', 'refactor', 'docs', 'test', 'chore', 'style'],
    ],
  },
};
```

**Git alias for common commands:**
```bash
# Add to ~/.gitconfig
[alias]
  co = checkout
  br = branch
  ci = commit
  st = status
  unstage = reset HEAD --
  last = log -1 HEAD
  visual = log --graph --oneline --all
```

---

## Metrics & Monitoring

### Track These Metrics Monthly

| Metric | Target | How to Track |
|--------|--------|-------------|
| Conventional commits % | >95% | GitHub Actions report |
| Avg commit size | <200 lines | Script checking commit stats |
| Avg PR size | <400 lines | GitHub API |
| Avg PR lifetime | <3 days | GitHub API |
| Test pass rate | 100% | CI/CD dashboard |
| Code coverage | >80% | Coverage tool |
| Review time | <24 hours | GitHub API |
| Build success rate | >99% | CI/CD logs |

### Dashboard Setup

Create a team dashboard showing:
- % of commits following conventions
- Average commit size trend
- Average PR size trend
- Average PR lifetime
- Test coverage percentage
- Build success rate

**Tools:**
- GitHub Actions dashboard
- Grafana
- Custom script reading GitHub API
- DataBox

---

## FAQ & Troubleshooting

**Q: Is a 20-line change in 3 commits better than 1 commit?**
A: Maybe. If they're logically related (e.g., all fixing one bug), squash them. If they're independent, keep separate.

**Q: Should every commit be deployable?**
A: Ideal yes, but not always practical. At least every PR should be deployable.

**Q: Is rebasing dangerous?**
A: On shared branches, yes (don't rebase). On personal branches, no (rebase all you want).

**Q: How do I write a good commit message?**
A: Read the "Git Commit Standards" section above, then practice.

**Q: What if my PR is 1001 lines?**
A: Split it. Either into multiple PRs or ask tech lead why it's so large.

**Q: Can I merge my own PR?**
A: No. Requires at least 2 reviewers (or 1 tech lead + 1 other).

**Q: How long should I wait for a review?**
A: 24 hours max. After that, escalate to tech lead.

---

## Implementation Plan

### Week 1: Foundation
- [ ] Set up git hooks (pre-commit, commit-msg)
- [ ] Configure commitlint
- [ ] Add PR validation to CI/CD
- [ ] Create team communication

### Week 2: Enforcement
- [ ] Enable quality gates on main branch
- [ ] Block merges that fail checks
- [ ] Update CI/CD pipeline
- [ ] Train team on new standards

### Week 3: Monitoring
- [ ] Set up metrics dashboard
- [ ] Create weekly reports
- [ ] Adjust policies based on data
- [ ] Celebrate wins!

### Ongoing
- [ ] Review metrics monthly
- [ ] Adjust limits based on team feedback
- [ ] Share best practices in retrospectives
- [ ] Celebrate developers following standards well

---

## References

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Git Workflows](https://www.atlassian.com/git/tutorials/comparing-workflows)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [Code Review Best Practices](https://google.github.io/eng-practices/review/)
- [Commit Message Guidelines](https://chris.beams.io/posts/git-commit/)

---

**Document Version:** 1.0  
**Last Updated:** October 27, 2025  
**Approved By:** [Engineering Leadership]  
**Review Cycle:** Quarterly
