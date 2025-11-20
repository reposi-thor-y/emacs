;;; lang-shell.el --- Shell and Zsh configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Shell and Zsh configuration

;;; Code:

;; 9.3 SHELL & ZSH
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Specialized mode for zsh configuration files
(define-derived-mode zshrc-mode sh-mode "Zsh-Config"
  "Major mode for editing zsh configuration files."
  (sh-set-shell "zsh"))

;; Use this mode for zshrc files (more specific patterns first)
(add-to-list 'auto-mode-alist '("/\\.zshrc\\'" . zshrc-mode))
(add-to-list 'auto-mode-alist '("/zshrc\\'" . zshrc-mode))
(add-to-list 'auto-mode-alist '("\\.zshenv\\'" . zshrc-mode))
(add-to-list 'auto-mode-alist '("\\.zprofile\\'" . zshrc-mode))
(add-to-list 'auto-mode-alist '("\\.zsh\\'" . sh-mode))

;; Ensure ShellCheck is available for enhanced diagnostics
(with-eval-after-load 'flycheck
  (setq flycheck-shellcheck-follow-sources t))
(add-hook 'sh-mode-hook 'flycheck-mode)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'lang-shell)
;;; lang-shell.el ends here
