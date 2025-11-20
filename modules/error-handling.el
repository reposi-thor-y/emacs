;;; error-handling.el --- Graceful error handling for missing dependencies -*- lexical-binding: t; -*-

;;; Commentary:
;; Check for required executables and warn gracefully if missing

;;; Code:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; EXECUTABLE CHECKING
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar my/required-executables
  '(;; Language servers
    ("pylsp" "Python LSP" "uv tool install python-lsp-server --with python-lsp-ruff")
    ("texlab" "LaTeX LSP" "Install from your package manager or cargo")
    ("marksman" "Markdown LSP" "Download from https://github.com/artempyanykh/marksman")
    ("bash-language-server" "Shell LSP" "npm install -g bash-language-server")
    ;; Python tools
    ("uv" "Python package manager" "curl -LsSf https://astral.sh/uv/install.sh | sh")
    ("ruff" "Python linter/formatter" "uv tool install ruff")
    ;; Other tools
    ("hunspell" "Spell checker" "Install from your package manager")
    ("pandoc" "Document converter" "Install from your package manager")
    ("git" "Version control" "Install from your package manager"))
  "List of (EXECUTABLE DESCRIPTION INSTALL-HINT) for required tools.")

(defun my/check-executable (exe-info)
  "Check if executable EXE-INFO exists and warn if not.
EXE-INFO is (EXECUTABLE DESCRIPTION INSTALL-HINT)."
  (let ((exe (car exe-info))
        (desc (cadr exe-info))
        (hint (caddr exe-info)))
    (unless (executable-find exe)
      (display-warning
       'emacs-config
       (format "Missing: %s (%s)\nInstall with: %s" exe desc hint)
       :warning))))

(defun my/check-all-executables ()
  "Check all required executables and display warnings for missing ones."
  (interactive)
  (let ((missing-count 0))
    (dolist (exe-info my/required-executables)
      (unless (executable-find (car exe-info))
        (my/check-executable exe-info)
        (setq missing-count (1+ missing-count))))
    (if (= missing-count 0)
        (message "✓ All required executables found")
      (message "⚠ %d executable(s) missing - check *Warnings* buffer" missing-count))))

;; Run check after init (deferred to not slow down startup)
(add-hook 'emacs-startup-hook
          (lambda ()
            (run-with-idle-timer 3 nil #'my/check-all-executables)))

;; Manual check command
(global-set-key (kbd "C-c h e") #'my/check-all-executables)

(provide 'error-handling)
;;; error-handling.el ends here
