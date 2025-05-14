[![MELPA](https://melpa.org/packages/epx-badge.svg)](https://melpa.org/#/epx)
[![builds.sr.ht status](https://builds.sr.ht/~alex-iam/epx/commits/master/.build.yml.svg)](https://builds.sr.ht/~alex-iam/epx/commits/master/.build.yml?)
# epx -- Emacs Project eXecutor


Run and manage per-project shell commands with project.el


# Overview

`epx.el` helps you define, manage, and run shell commands specific to
your Emacs projects (those recognized by `project.el`).

It stores named commands, along with optional environment variables and
a flag to use `compilation-mode`, directly in each project's
root: in `.dir-locals.el` or  `.epx.eld` file. You get interactive commands to
easily add, remove, and run these project tasks.

# Features

-   Completion prompt for commands defined in the current project.
-   Re-uses an existing **shell** window or opens one with
    `project-shell`.
-   Can run the command in `compilation-mode` instead of a
    shell.
-   Can use either `.dir-locals.el` or a dedicated `.epx.eld` to store commands.
-   Command storage can be customized by `epx-commands-file-type` variable (globally).
-   Pure Elisp, only depends on built-in `project`.

# Installation

`epx` can be installed from MELPA. A common way to setup the package using `use-package` is:

```
(use-package epx
  :after project
  :bind
  ("C-c p r" . #'epx-run-command-in-shell)
  ("C-c p c" . #'epx-add-command)
  ("C-c p d" . #'epx-remove-command))
```

You can also always install the package using `M-x package-install` instead.

# Usage

- You can use variable `epx-commands-file-type` to control where your commands
  are stored. It accepts the following values: ’locals and ’eld.

- `epx-add-command`
:   Prompt for a command, name, env vars, and whether to use a
    compilation buffer; writes it to commands file.

- `epx-run-command-in-shell`
:   Pick a saved command and execute it in a shell (or compilation)
    buffer scoped to the project.

- `epx-remove-command`
:   Remove a saved command from `.dir-locals.el`.

# Example entries in storage files
## .dir-locals.el

```
((nil . ((local-project-cmds ;; This is the variable epx looks for
          . ((:name "lint"
              :command "ruff check ."
              :compile t)))))
```

## .epx.eld

```
((:name "lint"
  :command "ruff check ."
  :compile t))
```

With this entry present in your project root's `/.dir-locals.el` (and
after you approve loading local variables), running
`M-x epx-run-command-in-shell RET lint RET` will execute `ruff check .`
in a `compilation-mode` buffer, using your project's root as the
working directory.

# Contributing

Patches, bug reports, and suggestions are welcome! Please use the
SourceHut mailing list or issue tracker:
<https://git.sr.ht/~alex-iam/epx>,<https://todo.sr.ht/~alex-iam/epx>

# License

GPL v3 or later. See the LICENSE file for details.
