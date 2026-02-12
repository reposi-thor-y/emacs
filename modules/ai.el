;;; ai.el --- AI assistant integration -*- lexical-binding: t; -*-

;;; Commentary:
;; Claude Code integration via claude-code.el

;;; Code:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CLAUDE CODE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Required dependency for environment variable inheritance
(use-package inheritenv
  :straight (:type git :host github :repo "purcell/inheritenv"))

;; Claude Code - AI coding assistant inside Emacs
(use-package claude-code
  :straight (:type git :host github :repo "stevemolitor/claude-code.el"
                   :branch "main" :depth 1)
  :custom
  (claude-code-terminal-backend 'vterm)
  :config
  (claude-code-mode)
  :bind-keymap ("C-c c" . claude-code-command-map))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'ai)
;;; ai.el ends here
