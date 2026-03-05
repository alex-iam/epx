# 0.3.2
- fix: `epx--rename-deprecated-variable` no longer always returns `t`; callers now correctly fall back to the old variable name when the user declines the rename
- fix: `epx--current-project-root` uses `if-let` to avoid calling `project-current` twice
- fix: rename local variable `local-project-cmds` to `existing-cmds` in `epx-remove-command` for consistency
- fix: add missing space before argument list in `epx--write-command-to-eld`
- fix: remove trailing whitespace on blank line after `epx--write-command-to-eld`
- fix: add `;;;###autoload` cookie to `epx-commands-file-type` defcustom
- docs: update `.dir-locals.el` example in README to use `epx-commands` instead of deprecated `local-project-cmds`
# 0.3.1
- rename .dir-locals variable from ‘local-project-cmds’ to ‘epx-commands’ for consistency
# 0.3.0
- added possibility to store commands in the dedicated file in project root.
# 0.2.0
- environment variables rework
- command prompt annotation
- comments improvements
# 0.1.0
- ready to use
