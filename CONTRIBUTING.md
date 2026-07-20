# Contributing

Contributions are welcome. Please keep changes practical and minimal.

## Guidelines

1. **Native Only**: Use only native macOS tools (`osascript`, Notes.app). Do not add third-party runtimes or dependencies.
2. **Fixed Actions**: Modify `skills/apple-notes/notes.sh` to implement new behaviors or fix bugs. Keep command parameters clean and robust.
3. **Verify Locally**: Test all command paths on local macOS before submitting changes.
4. **Documentation**: Update `SKILL.md` if any command signatures change, and keep `README.md` lightweight.

## Pull Request Flow

1. Fork the repository and create a branch.
2. Implement your changes in `notes.sh` or docs.
3. Run tests and verify the script.
4. Submit a Pull Request.
