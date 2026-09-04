# Git Collaboration Templates

Use repo-provided templates first. These are fallbacks when no project-specific template exists.

Commit and release templates live in `agentic-rules:changelog-release`; keep them there.

## Pull request / merge request

```markdown
## Summary
- 
- 
- 

## Motivation / context
Closes #

## Testing
- [ ] `<command>`

## Risk and impact
- Risk level: low / medium / high
- User/operator impact:
- Rollback plan:

## Review notes
- 

## Screenshots / logs
<!-- Add when UI, CLI, dashboards, or error output changed. -->
```

## Bug issue

```markdown
## Summary

## Steps to reproduce
1. 
2. 
3. 

## Expected behavior

## Actual behavior

## Environment
- OS:
- Version / commit:
- Configuration:

## Logs / screenshots

## Acceptance criteria
- [ ] 
```

## Feature issue

```markdown
## Summary

## Problem / user need

## Proposed behavior

## Alternatives considered

## Constraints / non-goals

## Acceptance criteria
- [ ] 
- [ ] Tests/docs updated if needed
```

## Code review comment

```markdown
suggestion: Could we validate `<condition>` before calling `<function>`?

If `<condition>` is false, this path can return `<bad outcome>`. A small guard
here would make the failure mode explicit and easier to test.
```

## Discussion post

```markdown
## Context

## Proposal / question

## Options considered
1. 
2. 
3. 

## Trade-offs

## Recommendation

## Next steps
- [ ] 
```
