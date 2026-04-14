;;; lang-eglot.el --- Eglot LSP configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Eglot LSP configuration for all languages

;;; Code:

;; Eglot - built-in LSP client (Emacs 29+)
;; Much simpler than lsp-mode, handles Python, Markdown, LaTeX, and shell scripts

(use-package eglot
  :ensure nil  ;; Built into Emacs 29+
  :hook ((python-mode . eglot-ensure)
         (LaTeX-mode . eglot-ensure)     ;; AUCTeX uses LaTeX-mode (capital L)
         (markdown-mode . eglot-ensure)
         (sh-mode . eglot-ensure)
         (zshrc-mode . eglot-ensure))    ;; Custom zsh config mode
  :config
  ;; Performance: read-process-output-max is set globally in misc.el

  ;; Python: use basedpyright for type-aware completions
  ;; Install: uv tool install basedpyright
  ;; Ruff handles linting/formatting separately (via eglot-format on save)
  ;; Call basedpyright directly (not via "uv run") to avoid extra subprocess overhead
  (add-to-list 'eglot-server-programs
               '(python-mode . ("basedpyright-langserver" "--stdio")))

  ;; Make bash-language-server work with zshrc-mode too
  (add-to-list 'eglot-server-programs
               '(zshrc-mode . ("bash-language-server" "start")))

  ;; Eglot already knows about these servers (no config needed):
  ;; - texlab for LaTeX/LaTeX-mode
  ;; - marksman for Markdown
  ;; - bash-language-server for sh-mode

  ;; Disable intrusive UI elements (keep it minimal)
  (setq eglot-autoshutdown t)           ;; Shutdown server when last buffer is killed
  (setq eglot-sync-connect nil)         ;; Don't block on connection
  (setq eglot-autoreconnect 3)          ;; Max 3 reconnect attempts (nil to disable)

  ;; Block LSP file watching entirely (basedpyright requests watching "**"
  ;; which creates 22K+ file watchers per project and exhausts macOS file
  ;; descriptors). Edits in Emacs are still sent via textDocument/didChange.
  (cl-defmethod eglot-register-capability
    (_server (_method (eql workspace/didChangeWatchedFiles)) _id &rest _rest)
    "Ignore file watching requests from LSP servers."
    nil)

  ;; Keybindings
  (define-key eglot-mode-map (kbd "C-c l r") 'eglot-rename)
  (define-key eglot-mode-map (kbd "C-c l a") 'eglot-code-actions)
  (define-key eglot-mode-map (kbd "C-c l f") 'eglot-format))

;; Flycheck is excluded from Eglot-managed modes via flycheck-global-modes
;; in development.el, so no need to disable it in a hook here.

;; Optional: Auto-format Python on save with Ruff
(add-hook 'python-mode-hook
          (lambda ()
            (add-hook 'before-save-hook
                      (lambda ()
                        (when (eglot-managed-p)
                          (eglot-format-buffer)))
                      nil t)))

(provide 'lang-eglot)
;;; lang-eglot.el ends here
