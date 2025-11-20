;;; init.el --- Emacs initialization file -*- lexical-binding: t; -*-

;;; Commentary:
;; Main entry point for Emacs configuration
;; Loads modular configuration files from ~/.emacs.d/modules/

;;; Code:

;; Add modules directory to load path
(add-to-list 'load-path (expand-file-name "modules" user-emacs-directory))

;; Load modules in dependency order
(require 'core)           ;; Core settings and package management
(require 'ui)             ;; UI, themes, and appearance
(require 'completion)     ;; Completion frameworks
(require 'editing)        ;; Editing enhancements
(require 'development)    ;; Development tools (git, flycheck, etc.)
(require 'lang-eglot)     ;; Eglot LSP configuration
(require 'lang-python)    ;; Python configuration
(require 'lang-cpp)       ;; C++ configuration
(require 'lang-shell)     ;; Shell script configuration
(require 'lang-latex)     ;; LaTeX configuration
(require 'lang-markdown)  ;; Markdown configuration
(require 'lang-elisp)     ;; Emacs Lisp configuration
(require 'lang-other)     ;; Other file formats
(require 'misc)           ;; Miscellaneous settings

(provide 'init)
;;; init.el ends here
