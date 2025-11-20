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
  :bind (("C-c m c" . mc/edit-lines)
         ("C->" . mc/mark-next-like-this)
         ("C-<" . mc/mark-previous-like-this)))

;; ;; Shell script mode
;; (use-package sh-script
;;   :defer t
;;   :delight "δ"
;;   :hook (after-save . executable-make-buffer-file-executable-if-script-p))


;; Enhanced shell script configuration for Emacs
;; With focus on zsh integration

;; Base shell mode configuration
(use-package sh-script
  :defer t
  :delight "δ"
  :hook (after-save . executable-make-buffer-file-executable-if-script-p)
  :config
  ;; Set zsh as the default shell for script mode
  (setq sh-shell-file "/bin/zsh")

  ;; Custom indentation for zsh scripts
  (setq sh-basic-offset 2
        sh-indentation 2)

  ;; Set zsh as default for new shell scripts
  (add-to-list 'auto-mode-alist '("\\.zsh\\'" . sh-mode))
  (add-to-list 'auto-mode-alist '("zshrc\\'" . sh-mode))
  (add-to-list 'auto-mode-alist '("\\.zshenv\\'" . sh-mode))
  (add-to-list 'auto-mode-alist '("\\.zprofile\\'" . sh-mode))

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


;; Function to launch zsh and execute given command
(defun run-zsh-command (command)
  "Run a zsh command in a new buffer."
  (interactive "sZsh command: ")
  (let ((buffer (generate-new-buffer "*zsh-command*")))
    (switch-to-buffer buffer)
    (insert (format "Running: %s\n\n" command))
    (start-process "zsh-command" buffer "zsh" "-c" command)
    (shell-mode)))

;; Key bindings for our zsh integration
(global-set-key (kbd "C-c z c") 'run-zsh-command)
(global-set-key (kbd "C-c z f") 'create-zsh-script)

;; Improved directory navigation with zsh
(defun zsh-find-file ()
  "Use zsh's advanced globbing to find files."
  (interactive)
  (let* ((pattern (read-string "Zsh file pattern: "))
         (command (format "find . -type f -name '%s' | sort" pattern))
         (result (shell-command-to-string command))
         (files (split-string result "\n" t))
         (selected (completing-read "Select file: " files nil t)))
    (when selected
      (find-file selected))))

(global-set-key (kbd "C-c z f") 'zsh-find-file)


;; Add zsh-mode custom keybindings
(defvar zsh-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-e") 'run-zsh-command)
    (define-key map (kbd "C-c C-c") 'zsh-process-csv)
    map)
  "Keymap for zsh-mode.")

(define-derived-mode zsh-mode sh-mode "ZSH"
  "Major mode for editing zsh scripts."
  :group 'sh
  (sh-set-shell "zsh"))

(provide 'zsh-mode)

;; Register zsh-mode for .zsh files
(add-to-list 'auto-mode-alist '("\\.zsh\\'" . zsh-mode))
(add-to-list 'interpreter-mode-alist '("zsh" . zsh-mode))


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
  :defer t)

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
  "Check if buffer contains // comments."
  (save-excursion
    (goto-char (point-min))
    (re-search-forward "//" nil t)))

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
