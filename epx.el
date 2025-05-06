;;; epx.el --- Manage and run project-specific shell commands -*- lexical-binding: t -*-

;; Copyright (c) 2025 Oleksandr Korzh

;; Author: Oleksandr Korzh <alex@korzh.me>
;; Version: 0.2
;; Package-Requires: ((emacs "29.1"))
;; URL: https://git.sr.ht/~alex-iam/epx
;; Keywords: project, shell, tools

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.


;;; Commentary:

;; epx is a command runner and manager for project.el in Emacs.
;; ’epx’ stands for ’Emacs Project eXecutor’.

;; Warning! Only works in Unix-like systems for now due to
;; how environment variables are processed.  This is temporary.

;; It stores commands in .dir-locals.el or any other dir-locals-file that
;; you set.  It allows you to add or remove commands, no editing
;; capabilities for now.  You can choose whether to use compilation
;; buffer when you create your command.

;; After the command is created, you can execute it using
;; ’epx-run-command-in-shell’ (You’ll probably want to bind it).  Completion
;; for command names is provided.  Executing a command happens in a separate
;; window (either ’shell’ or compilation).

;;; Code:
(require 'project)
(require 'cl-lib)
(require 'files)
(require 'files-x)


(defun epx--find-command-by-prop (prop-name prop-value)
  "Find a command in commands storage by PROP-NAME and PROP-VALUE."
  (cl-find-if (lambda (cmd)
		(equal (plist-get cmd prop-name) prop-value))
	      (epx--read-cmds-locals)))


(defun epx--annotate (candidate)
  "Show command for CANDIDATE along with it’s name on completion."
  (when candidate
    (format "%s %s"
	    (propertize " " 'display '(space :align-to 30))
	    (propertize (plist-get (epx--find-command-by-prop :name candidate) :command) 'face 'completions-annotations))))


(defun epx--current-project-root ()
  "Return current project’s root.  If there’s no project, throw an error."
  (if (project-current)
      (project-root (project-current))
    (error "No project found.  This only works in projects")))


(defun epx--locals-file ()
  "Return the path to the current project's ‘dir-locals-file."
    (expand-file-name dir-locals-file (epx--current-project-root)))


(defun epx--create-locals-file ()
  "Create ‘dir-locals-file’ in current project root.
If the file already exists, do nothing."
  (let ((file (epx--locals-file)))
    (unless (file-exists-p file)
      (write-region "" nil file))))


(defun epx--read-shell-command ()
  "Prompt for a shell command with completion from dir-locals-file'."
  (let* ((locals-file (epx--locals-file))
         (cmds (if (file-exists-p locals-file)
                   (epx--read-cmds-locals)))
         (history (mapcar (lambda (plist) (plist-get plist :name)) cmds))
	 (completion-extra-properties (list :annotation-function #'epx--annotate))
         (name (completing-read "Project command: " history nil t)))
    (cl-find-if (lambda (plist) (string= (plist-get plist :name) name)) cmds)))


(defun epx--get-or-create-shell-window (project-root)
  "Return a window with a shell for PROJECT-ROOT, creating one if necessary."
  (or (cl-find-if
       (lambda (win)
         (with-current-buffer (window-buffer win)
           (and (eq major-mode 'shell-mode)
                (string-prefix-p project-root default-directory))))
       (window-list nil 'nomini))
      (progn
        (split-window-sensibly)
        (other-window 1)
        (project-shell)
        (selected-window))))


;;;###autoload
(defun epx-run-command-in-shell (&optional command)
  "Run COMMAND in a PROJECT shell buffer.
If a shell window already exists, reuse it.  Otherwise open one.
When called interactively, prompt for COMMAND with completion from history."
  (interactive
   (list (epx--read-shell-command)))
  (let* ((root (epx--current-project-root))
        
	 (env-list (plist-get command :env))
	 (cmd (if env-list
		  (concat (epx--prepare-env env-list) " " (plist-get command :command))
		(plist-get command :command)))
	 (use-compilation (plist-get command :compile)))
    (if use-compilation
	(let ((default-directory root))
	  (compilation-start cmd nil )) ;; TODO: research using project-compile instead
      (let* ((win (epx--get-or-create-shell-window root))
	     (proc (get-buffer-process (window-buffer win))))
	(select-window win)
        (comint-send-string proc (concat cmd "\n"))))))

;;;###autoload
(defun epx-remove-command (&optional command)
  "Delete COMMAND from ‘dir-locals-file’."
  (interactive
   (list (epx--read-shell-command)))
  (if (y-or-n-p (format "Are you sure you want to remove command %s?" (plist-get command :name)))
      (let* ((locals-file (epx--locals-file))
	     (local-project-cmds (epx--read-cmds-locals) )
             (updated (cl-remove command local-project-cmds :test #'equal)))
	(with-current-buffer (find-file-noselect locals-file)
	  (delete-dir-local-variable nil 'local-project-cmds)
	  (add-dir-local-variable nil 'local-project-cmds updated)
	  (save-buffer)
	  (kill-buffer)))))


(defun epx--prepare-env (env-list)
  "Convert ENV-LIST from the list of plists into a semicolon-separated string."
  (string-join
   (mapcar (lambda (el)
	     (concat (plist-get el :name) "=" (plist-get el :value)))
	   env-list)
   " "))


;;;###autoload
(defun epx-add-command (&optional cmd name env-vars compile)
  "Add a new command to ‘dir-locals-file’ interactively.
CMD and NAME are expected to be non-empty.
ENV-VARS and COMPILE default to nil."
  (interactive
   (let* ((_ (epx--current-project-root)) ;; to check we’re in the project
	  (cmd (read-string "Shell command to run: "))
          (_ (when (string-empty-p cmd)
               (user-error "Command cannot be empty")))
          (name (read-string "Command name: "))
          (_ (when (string-empty-p name)
               (user-error "Command name cannot be empty")))
	  (compile (y-or-n-p "Do you want to use compilation buffer for your command?"))
          ;; (env (read-string "Env vars (semicolon-separated): "))
	  (env-vars '())
	  (env-name ""))
     (while (progn
	      (setq env-name (read-string "Environment variable name (empty to finish): "))
	      (not (string-empty-p env-name)))
       (let ((env-value (read-string (format "Value for %s: " env-name))))

	 (if (not (string-empty-p env-value))
	     (push (list :name env-name :value env-value) env-vars)
	   (warn "Empty value, skipping this variable"))))

       (list cmd name env-vars compile)))
  (epx--create-locals-file)
  (let ((new-cmd (list :name name :command cmd :env env-vars :compile compile)))
    (epx--record-command new-cmd)))


(defun epx--read-cmds-locals ()
  "Read project commands from ‘dir-locals-file’."
  (hack-dir-local-variables)
  (alist-get 'local-project-cmds file-local-variables-alist nil nil #'equal))


(defun epx--record-command (command)
  "Add COMMAND to `local-project-cmds' in ‘dir-locals-file’.
If a command with the same name already exists, throw an error"
  (let ((locals-file (epx--locals-file)))
    (when (file-exists-p locals-file)
      (let* ((existing-cmds (epx--read-cmds-locals))
             (duplicate (cl-find-if (lambda (cmd)
                                      (string= (plist-get cmd :name)
                                               (plist-get command :name)))
                                    existing-cmds)))
        (if duplicate
            (error "A command with the name '%s' already exists" (plist-get command :name))
          (let ((new-cmds (cons command existing-cmds)))
            (with-current-buffer (find-file-noselect locals-file)
              (add-dir-local-variable nil 'local-project-cmds new-cmds)
              (save-buffer)
              (kill-buffer))))))))

(provide 'epx)

;;; epx.el ends here
