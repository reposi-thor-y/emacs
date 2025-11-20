;;; lang-elisp.el --- Emacs Lisp configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Configuration for Emacs Lisp development

;;; Code:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; BASIC ELISP SETTINGS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Enable eldoc mode for inline documentation
(add-hook 'emacs-lisp-mode-hook #'eldoc-mode)
(add-hook 'lisp-interaction-mode-hook #'eldoc-mode)
(add-hook 'ielm-mode-hook #'eldoc-mode)

;; Set fill column for Elisp
(add-hook 'emacs-lisp-mode-hook
          (lambda ()
            (setq fill-column 80)
            (setq display-fill-column-indicator-column 80)))

;; Enable paredit or smartparens for balanced parens
(use-package smartparens
  :ensure t
  :hook ((emacs-lisp-mode . smartparens-mode)
         (lisp-interaction-mode . smartparens-mode)
         (ielm-mode . smartparens-mode))
  :config
  (require 'smartparens-config))

;; Show paren mode - highlight matching parens
(add-hook 'emacs-lisp-mode-hook #'show-paren-mode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ENHANCED ELISP PACKAGES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Macrostep - interactively expand macros
(use-package macrostep
  :ensure t
  :bind (:map emacs-lisp-mode-map
              ("C-c e m" . macrostep-expand)))

;; EROS - Evaluation Result OverlayS for inline results
(use-package eros
  :ensure t
  :hook ((emacs-lisp-mode . eros-mode)
         (lisp-interaction-mode . eros-mode)))

;; Elisp-demos - show examples in help buffers
(use-package elisp-demos
  :ensure t
  :config
  (advice-add 'describe-function-1 :after #'elisp-demos-advice-describe-function-1)
  (advice-add 'helpful-update :after #'elisp-demos-advice-helpful-update))

;; Highlight-quoted - better syntax highlighting for quoted symbols
(use-package highlight-quoted
  :ensure t
  :hook (emacs-lisp-mode . highlight-quoted-mode))

;; Aggressive indent - auto-indent as you type
(use-package aggressive-indent
  :ensure t
  :hook ((emacs-lisp-mode . aggressive-indent-mode)
         (lisp-interaction-mode . aggressive-indent-mode))
  :config
  ;; Disable in minibuffer
  (add-to-list 'aggressive-indent-excluded-modes 'minibuffer-inactive-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; EVALUATION KEYBINDINGS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Additional evaluation keybindings
(with-eval-after-load 'elisp-mode
  (define-key emacs-lisp-mode-map (kbd "C-c e e") 'eval-last-sexp)
  (define-key emacs-lisp-mode-map (kbd "C-c e b") 'eval-buffer)
  (define-key emacs-lisp-mode-map (kbd "C-c e r") 'eval-region)
  (define-key emacs-lisp-mode-map (kbd "C-c e d") 'eval-defun)
  (define-key emacs-lisp-mode-map (kbd "C-c e f") 'emacs-lisp-byte-compile-and-load))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; BYTE-COMPILATION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Auto-compile elisp files
(use-package auto-compile
  :ensure t
  :config
  (auto-compile-on-load-mode)
  (auto-compile-on-save-mode))

;; Function to byte-compile and load current file
(defun emacs-lisp-byte-compile-and-load ()
  "Byte-compile and load the current elisp file."
  (interactive)
  (save-buffer)
  (byte-compile-file (buffer-file-name) t)
  (message "Compiled and loaded %s" (buffer-file-name)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; LINTING & CHECKING
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Enable checkdoc for documentation checking
(add-hook 'emacs-lisp-mode-hook
          (lambda ()
            (setq checkdoc-minor-mode t)))

;; Flycheck elisp checkers (uses built-in emacs-lisp checker)
(with-eval-after-load 'flycheck
  (setq flycheck-emacs-lisp-load-path 'inherit))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; IMENU INTEGRATION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Better imenu support for elisp
(add-hook 'emacs-lisp-mode-hook
          (lambda ()
            (setq imenu-sort-function 'imenu--sort-by-name)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; DEBUGGING
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Edebug settings
(setq edebug-trace t)
(setq edebug-print-length 50)
(setq edebug-print-level 50)

;; Keybinding for edebug
(with-eval-after-load 'elisp-mode
  (define-key emacs-lisp-mode-map (kbd "C-c e x") 'edebug-defun))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; IELM (Elisp REPL)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Quick access to IELM REPL
(global-set-key (kbd "C-c e i") 'ielm)

;; IELM settings
(add-hook 'ielm-mode-hook
          (lambda ()
            (eldoc-mode 1)
            (smartparens-mode 1)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; HELPFUL FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun my/elisp-eval-and-replace ()
  "Evaluate the sexp before point and replace it with the result."
  (interactive)
  (let ((value (eval (preceding-sexp))))
    (kill-sexp -1)
    (insert (format "%S" value))))

(with-eval-after-load 'elisp-mode
  (define-key emacs-lisp-mode-map (kbd "C-c e =") 'my/elisp-eval-and-replace))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'lang-elisp)
;;; lang-elisp.el ends here
