;;; lang-other.el --- Other file formats -*- lexical-binding: t; -*-

;;; Commentary:
;; Other file formats

;;; Code:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; OTHER FILE FORMATS & TEXT EDITING
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Text mode enhancements
(use-package wc-mode
  :defer t
  :hook (text-mode . wc-mode))

;; Enhanced text navigation
(use-package avy
  :defer t
  :bind (("C-:" . avy-goto-char)
         ("C-'" . avy-goto-char-2)))

;; Multiple cursors for text editing
(use-package multiple-cursors
  :defer t
  :bind (("C-S-c C-S-c" . mc/edit-lines)
         ("C->" . mc/mark-next-like-this)
         ("C-<" . mc/mark-previous-like-this)))

;; Shell mode configuration with zsh enhancements
(use-package sh-script
  :defer t
  :delight "δ"
  :hook (after-save . executable-make-buffer-file-executable-if-script-p)
  :config
  (setq sh-shell-file "/bin/zsh")
  (setq sh-basic-offset 2
        sh-indentation 2)

  ;; Custom syntax highlighting for common zsh commands and constructs
  (font-lock-add-keywords
   'sh-mode
   '(("\\<\\(typeset\\|autoload\\|zmodload\\|zstyle\\|compdef\\)\\>"
      . font-lock-keyword-face)
     ("\\<\\(setopt\\|unsetopt\\)\\>"
      . font-lock-builtin-face))))

;; Terminal emulation with better zsh support
(use-package vterm
  :defer t
  :bind (("C-c v t" . vterm))
  :config
  ;; Better zsh integration
  (setq vterm-shell "/bin/zsh")
  (setq vterm-max-scrollback 10000)
  (setq vterm-keymap-exceptions '("C-x" "C-u" "C-g" "C-h" "C-l" "M-x" "M-o" "C-v" "M-v" "C-y" "M-y"
                                  "M-i" "M-j" "M-k" "M-l"))
  :bind (:map vterm-mode-map
              ("M-i" . windmove-up)
              ("M-j" . windmove-left)
              ("M-k" . windmove-down)
              ("M-l" . windmove-right)))


;; Shell command completion (specialized for zsh)
(use-package company-shell
  :ensure t
  :config
  (add-to-list 'company-backends 'company-shell)
  (add-to-list 'company-backends 'company-shell-env))


;; Run a zsh command via compile (reuses buffer, proper process handling)
(defun run-zsh-command (command)
  "Run a zsh COMMAND in a compilation buffer."
  (interactive "sZsh command: ")
  (compile (format "zsh -c %s" (shell-quote-argument command))))

(global-set-key (kbd "C-c z c") 'run-zsh-command)


;; CSV mode
(use-package csv-mode
  :defer t
  :mode ("\\.\\(csv\\|tsv\\)\\'"))
(add-hook 'csv-mode-hook (lambda () (flyspell-mode -1)))

;; Dockerfile mode
(use-package dockerfile-mode
  :defer t
  :delight "δ"
  :mode "Dockerfile\\'")

;; YAML mode
(use-package yaml-mode
  :defer t
  :hook (yaml-mode . (lambda ()
                       (setq-local yaml-indent-offset 2)
                       (setq-local tab-width 2)
                       (setq-local indent-tabs-mode nil))))

;; TOML mode
(use-package toml-mode
  :defer t)


;; Simple JSON/JSONC solution - manual control
;; Simple JSON formatting - no custom modes
(defun my/format-with-jq ()
  "Format JSON using jq."
  (interactive)
  (shell-command-on-region (point-min) (point-max) "jq --indent 4 ." nil t))

(defun my/waybar-mode ()
  "Switch to js-json-mode and format."
  (interactive)
  (js-json-mode)
  (my/format-with-jq)
  (message "Waybar config formatted"))

(defun my/has-comments-p ()
  "Check if buffer contains // line comments (not inside strings or URLs)."
  (save-excursion
    (goto-char (point-min))
    (let ((found nil))
      (while (and (not found) (re-search-forward "^[ \t]*//" nil t))
        (setq found t))
      found)))

(defun my/format-smart ()
  "Use jq for pure JSON, indentation for JSONC with comments."
  (interactive)
  (if (my/has-comments-p)
      (progn
        (indent-region (point-min) (point-max))
        (message "JSONC formatted (indentation only - has comments)"))
    (shell-command-on-region (point-min) (point-max) "jq --indent 4 ." nil t)
    (message "JSON formatted with jq")))

(global-set-key (kbd "C-c C-j") 'my/format-smart)

;; Key bindings
;; (global-set-key (kbd "C-c C-j") 'my/format-with-jq)
(global-set-key (kbd "C-c w") 'my/waybar-mode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'lang-other)
;;; lang-other.el ends here
