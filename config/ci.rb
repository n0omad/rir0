# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"

  step "Style: Ruby", "bin/rubocop"

  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: Importmap vulnerability audit", "bin/importmap audit"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

  step "Tests: Rails", "bin/rails test"
  step "Tests: System", "bin/rails test:system"
  step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"

  if success?
    step "Auto-PR Workflow: Create, Approve, and Merge PR if CI passes", <<~BASH
      # Create PR with autofill from commits
      gh pr create --fill --base develop --title 'Auto-PR from successful local CI' --body 'Local CI passed all steps. Auto-approving and merging.'

      # Approve the PR (as current user)
      gh pr review --approve

      # Merge with squash (or --merge/--rebase) and delete branch
      gh pr merge --squash --delete-branch --admin  # Use --admin if protections; change to --merge if preferred
    BASH
  else
    failure "CI Failed: No PR actions taken", "echo 'CI failed - fix issues and re-run bin/ci.'"
  end
end
