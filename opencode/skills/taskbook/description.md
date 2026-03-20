# Taskbook Skill

A skill for managing tasks using Taskbook (`tb`), a terminal-based task management tool.

## Commands

### View Tasks
- `tb` - Display all items organized by board (default)
- `tb --timeline` / `tb -i` - Display items in chronological order
- `tb --archive` / `tb -a` - Display archived (deleted) items

### Create Items
- `tb --task <description>` / `tb -t <description>` - Create a new task
- `tb --note <description>` / `tb -n <description>` - Create a note
- `tb --note` - Create a note in external editor

### Board & Priority
- `tb --task @board "description"` - Assign task to a board
- `tb --task "description" p:3` - Set priority (1=normal, 2=medium, 3=high)
- `tb --task @work @urgent "Task" p:3` - Combined example

### Modify Tasks
- `tb --check <id>` / `tb -c <id>` - Toggle task completion
- `tb --begin <id>` / `tb -b <id>` - Toggle in-progress status
- `tb --star <id>` / `tb -s <id>` - Toggle starred status
- `tb --edit @<id> <new description>` / `tb -e` - Edit task description
- `tb --priority @<id> <1-3>` / `tb -p` - Set task priority
- `tb --move @<id> <board>` / `tb -m` - Move task to another board

### Delete & Restore
- `tb --delete <id>` / `tb -d <id>` - Delete task (moves to archive)
- `tb --restore <id>` / `tb -r <id>` - Restore from archive
- `tb --clear` - Permanently delete completed tasks

### Search & Filter
- `tb --find <term>` / `tb -f <term>` - Search tasks
- `tb --list <attributes>` / `tb -l <attributes>` - Filter by attributes
  - Attributes: `pending`, `done`, `task`, `note`, `starred`

### Clipboard
- `tb --copy <id>` / `tb -y <id>` - Copy task description to clipboard

## Examples

```bash
# View tasks
tb

# Create tasks
tb --task @personal "Buy groceries" p:2
tb --task @work "Review PR #123"
tb --note @meetings "Standup at 9am daily"

# Update tasks
tb --begin 1       # Start working on task 1
tb --check 1       # Mark as complete
tb --star 1        # Star task
tb --priority @1 3 # Set high priority

# Organize
tb --move @1 shopping
tb --find meeting

# Clean up
tb --delete 5
tb --clear
```

## Non-Interactive / Headless Environments

In environments without a TTY (CI, scripts, remote shells), use the `--cli` flag:

```bash
tb --cli              # Display tasks in CLI mode (non-interactive)
tb --cli --list       # List all tasks
tb --cli --list done  # List completed tasks
tb --cli --list pending  # List pending tasks
```

The plain `tb` command launches a TUI and will fail in headless environments with:
`TUI error: No such device or address (os error 6)`

## Notes
- Tasks can be checked off when completed, notes cannot
- Use `@boardname` to organize tasks by board
- Priority levels: 1 (normal), 2 (medium), 3 (high)
- Deleted items go to archive and can be restored
