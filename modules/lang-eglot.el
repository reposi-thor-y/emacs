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
  ;; Performance: increase read output for better performance
  (setq read-process-output-max (* 1024 1024))  ;; 1MB

  ;; Python: use python-lsp-server (pylsp) with Jedi for completions
  ;; Install: uv tool install python-lsp-server --with python-lsp-ruff --with 'python-lsp-server[all]'
  ;; This gives you: Jedi completions + Ruff linting/formatting in one server
  (add-to-list 'eglot-server-programs
               '(python-mode . ("pylsp")))

  ;; Configure pylsp via Eglot workspace configuration
  (setq-default eglot-workspace-configuration
                '(:pylsp (:plugins (:jedi_completion (:enabled t
                                                       :include_params t
                                                       :include_class_objects t
                                                       :fuzzy t)
                                    :jedi_hover (:enabled t)
                                    :jedi_references (:enabled t)
                                    :jedi_signature_help (:enabled t)
                                    :jedi_symbols (:enabled t
                                                   :all_scopes t)
                                    :ruff (:enabled t
                                           :format (:enabled t)
                                           :lineLength 88)
                                    ;; Disable other linters to avoid conflicts with Ruff
                                    :pycodestyle (:enabled :json-false)
                                    :flake8 (:enabled :json-false)
                                    :mccabe (:enabled :json-false)
                                    :pyflakes (:enabled :json-false)
                                    :pylint (:enabled :json-false)
                                    :yapf (:enabled :json-false)
                                    :autopep8 (:enabled :json-false)
                                    :black (:enabled :json-false)))))

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

  ;; Keybindings
  (define-key eglot-mode-map (kbd "C-c l r") 'eglot-rename)
  (define-key eglot-mode-map (kbd "C-c l a") 'eglot-code-actions)
  (define-key eglot-mode-map (kbd "C-c l f") 'eglot-format))

;; Disable Flycheck when Eglot is active (Eglot provides diagnostics via Flymake)
(with-eval-after-load 'flycheck
  (add-hook 'eglot-managed-mode-hook
            (lambda ()
              (when (derived-mode-p 'python-mode 'LaTeX-mode 'markdown-mode 'sh-mode 'zshrc-mode)
                (flycheck-mode -1)))))

;; Optional: Auto-format Python on save with Ruff
(add-hook 'python-mode-hook
          (lambda ()
            (add-hook 'before-save-hook 'eglot-format-buffer nil t)))

(provide 'lang-eglot)
;;; lang-eglot.el ends here
