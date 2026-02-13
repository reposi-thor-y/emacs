;;; init.el --- Emacs initialization file -*- lexical-binding: t; -*-

;;; Commentary:
;; Main entry point for Emacs configuration
;; Loads modular configuration files from ~/.emacs.d/modules/

;;; Code:

;; Add modules directory to load path
(add-to-list 'load-path (expand-file-name "modules" user-emacs-directory))

;; Load platform detection first (defines my/frame-*, my/font-*, my/is-mac, etc.)
(require 'platform)

;; Set initial frame size and position
(push `(width  . ,my/frame-width)  default-frame-alist)
(push `(height . ,my/frame-height) default-frame-alist)
(push `(left   . ,my/frame-left)   default-frame-alist)
(push `(top    . ,my/frame-top)    default-frame-alist)

;; Load modules in dependency order
(require 'core)           ;; Core settings and package management
(require 'error-handling) ;; Error handling for missing dependencies
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
(require 'ai)             ;; AI assistant (Claude Code)
(require 'misc)           ;; Miscellaneous settings

(provide 'init)
;;; init.el ends here
