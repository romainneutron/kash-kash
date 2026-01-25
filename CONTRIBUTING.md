# Contributing to Kash-Kash

## Development Workflow

1. Check the sprint plans in `plan/sprints/`
2. Pick an unchecked task
3. Implement the task
4. Run `make lint` and `make test`
5. Check the box in the sprint document
6. Commit with descriptive message

## Commit Messages

Use conventional commit format:

```
<type>: <description>

[optional body]

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code refactoring
- `docs`: Documentation
- `test`: Tests
- `chore`: Maintenance

## Code Style

- Run `make format` before committing
- Follow Dart/Flutter conventions
- Use Riverpod for state management
- Keep domain layer pure (no Flutter dependencies)

## Testing

- Unit tests for domain layer
- Widget tests for screens
- Integration tests for critical flows

Run tests with:
```bash
make test
make test-coverage
```

## Code Generation

After modifying Drift tables or Riverpod providers:
```bash
make gen
```

Or use watch mode:
```bash
make watch
```
