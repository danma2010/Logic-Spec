# Agent Interaction Guidelines

When working on a task, do not ask for permission before performing read-only operations. You should proactively use tools to read files, search the codebase, and list directories to gather the context you need autonomously. 

Only ask for permission, approval, or user input when:
- Executing destructive actions or modifying critical files
- Encountering plan/validation gates explicitly defined in other rules
- Making significant design choices where the intent is ambiguous
