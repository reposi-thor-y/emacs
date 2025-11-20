;;; development.el --- Development tools -*- lexical-binding: t; -*-

;;; Commentary:
;; Development tools

;;; Code:

;; 8. DEVELOPMENT TOOLS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Company mode for in-buffer completion
(use-package company
  :ensure t
  :hook (after-init . global-company-mode)
  :custom
  (company-idle-delay 0.1)
  (company-minimum-prefix-length 2)
  (company-selection-wrap-around t)
  (company-tooltip-align-annotations t)
  (company-show-numbers t)
  :config
  (setq company-files-exclusions nil)
  (setq company-files-chop-trailing-slash nil))

;; Debug function to test company status
(defun company-debug ()
  "Show company status and trigger completion."
  (interactive)
  (if company-mode
      (progn
        (message "Company is enabled. Backends: %s" company-backends)
        (company-complete))
    (message "Company is disabled in this buffer!")))

(global-set-key (kbd "C-c C-p") 'company-debug)

;; Simple path completion function
(defun complete-path ()
  "Force file path completion with company-files."
  (interactive)
  (let ((company-backends '(company-files))
        (company-minimum-prefix-length 0)
        (company-idle-delay 0))
    (company-complete)))

(global-set-key (kbd "C-c p") 'complete-path)

;; More advanced path detection and completion
(defun my/file-path-in-context-p ()
  "Detect if point is within a probable file path context."
  (let ((line-start (line-beginning-position))
        (line-end (line-end-position))
        (path-prefixes '("~/" "./" "../" "/" "$HOME/")))
    (save-excursion
      (let ((pos (point))
            (found nil))
        ;; Check if we're inside quotes with a path
        (when (nth 3 (syntax-ppss))
          (let* ((quote-start (nth 8 (syntax-ppss)))
                 (quote-content (buffer-substring-no-properties
                                 (1+ quote-start)
                                 pos)))
            (setq found (seq-some (lambda (prefix)
                                    (string-prefix-p prefix quote-content))
                                  path-prefixes))))

        ;; Or check if we're after a path prefix
        (unless found
          (let ((prefix-end pos)
                (prefix-start (max (- pos 20) line-start)))
            (setq found (seq-some (lambda (prefix)
                                    (string-match-p
                                     (concat (regexp-quote prefix) ".*\\'")
                                     (buffer-substring-no-properties prefix-start prefix-end)))
                                  path-prefixes))))
        found))))

;; Cape for enhanced completion
(use-package cape
  :ensure t
  :config
  ;; Add cape completions to the front of completion-at-point-functions
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev))

;; Smart path completion function
(defun my/smart-file-completion-at-point ()
  "Complete file paths intelligently based on context."
  (when (my/file-path-in-context-p)
    (cape-file)))

;; Add our smart completion function to the front of the list
(defun my/setup-smart-file-capf ()
  "Setup smart file completion-at-point for the current buffer."
  (setq-local completion-at-point-functions
              (cons #'my/smart-file-completion-at-point
                    completion-at-point-functions)))

;; Add the smart file completion to relevant modes
(add-hook 'prog-mode-hook #'my/setup-smart-file-capf)
(add-hook 'text-mode-hook #'my/setup-smart-file-capf)
(add-hook 'sh-mode-hook #'my/setup-smart-file-capf)

;; Key binding to manually trigger completion (Swedish keyboard friendly)
(global-set-key (kbd "M-.") #'completion-at-point)

;; Snippets system
(use-package yasnippet
  :defer t
  :hook ((prog-mode . yas-minor-mode)
         (text-mode . yas-minor-mode))
  :config
  (yas-reload-all))

(use-package yasnippet-snippets
  :defer t
  :after yasnippet)

;; Flycheck for syntax checking - global configuration
(use-package flycheck
  :defer t
  :hook (after-init . global-flycheck-mode)
  :config
  ;; Enable flycheck to search for config files in project directories
  (setq flycheck-flake8-search-path 'nil) ; This allows searching up the directory tree
  (setq-default flycheck-flake8-maximum-complexity 10)
  (setq-default flycheck-flake8-maximum-line-length 100)

  ;; Use project root for Python files when available
  (setq flycheck-python-flake8-executable "flake8"))


(advice-add 'flycheck-start-command-checker
            :around (lambda (orig-fun checker callback)
                      (when (eq checker 'python-flake8)
                        (message "Running flake8 command: %s"
                                 (mapconcat 'identity
                                            (flycheck-checker-substituted-command checker)
                                            " ")))
                      (funcall orig-fun checker callback)))

(advice-add 'flycheck-flake8-config-file
            :around (lambda (orig-fun &rest args)
                      (let ((result (apply orig-fun args)))
                        (message "Flake8 config file: %s" (or result "None"))
                        result)))


;; Project management
(use-package projectile
  :defer t
  :init
  (setq projectile-completion-system 'vertico)
  (setq projectile-indexing-method 'alien)
  (setq projectile-sort-order 'recently-active)
  :config
  (projectile-mode 1))

;; Version Control with Magit
(use-package magit
  :defer t
  :bind (("C-c g" . #'magit-status))
  :custom
  (magit-repository-directories '(("~/code" . 1)))
  :config
  (add-to-list 'magit-no-confirm 'stage-all-changes))

(use-package magit-filenotify
  :defer t
  :commands (magit-filenotify-mode)
  :hook (magit-status-mode . magit-filenotify-mode))

;; Side bar navigation
(use-package dired-sidebar
  :ensure t
  :bind (("C-x C-n" . dired-sidebar-toggle-sidebar))
  :config
  (setq dired-sidebar-use-term-integration t)
  (setq dired-sidebar-use-custom-font t))

;; Ensure Python path is correctly set from shell
(use-package exec-path-from-shell
  :ensure t
  :config
  (when (memq window-system '(mac ns x))
    (exec-path-from-shell-initialize)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'development)
;;; development.el ends here
