# Contributing to macbook-setup

Thank you for your interest in contributing! 🎉

## How to Contribute

### Adding New Tools

1. **Fork the repository** and create a new branch
2. **Add your tool** to the appropriate section in `setup.sh`
3. **Test on both architectures** (Intel and Apple Silicon if possible)
4. **Update the README** to document the new tool
5. **Submit a pull request** with a clear description

### Example Addition

```bash
# In the appropriate section of setup.sh
log_info "Installing YourTool..."
brew install your-tool
```

Then update the README:
```markdown
- **YourTool** - Brief description
```

## Testing Changes

### Syntax Check
```bash
bash -n setup.sh
```

### Dry Run (check detection logic)
```bash
# Check architecture detection
uname -m
```

### Full Test
Run the script on a clean macOS installation or VM if possible.

## Code Style

- Use **4 spaces** for indentation
- Add **comments** for complex logic
- Use **descriptive variable names**
- Follow the existing **logging pattern** (log_info, log_success, etc.)
- Keep **idempotent checks** (script should be safe to run multiple times)

## Pull Request Guidelines

- **One feature per PR** - Keep changes focused
- **Clear commit messages** - Describe what and why
- **Update documentation** - README, comments, etc.
- **Test your changes** - Ensure script still works
- **Check for conflicts** - Rebase on latest main if needed

## Questions?

Open an issue for discussion before making large changes.

---

Happy contributing! 🚀
