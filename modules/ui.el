;;; ui.el --- UI and appearance configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; UI and appearance configuration

;;; Code:

;; Allow pixel-precise frame resizing (needed by some window managers/compositors)
(setq frame-resize-pixelwise t)

;; Unified theme and display setup
(defun my/setup-ui ()
  "Set up theme and fonts based on display type and system."
  (interactive)
  ;; Clear existing themes
  (mapc #'disable-theme custom-enabled-themes)

  ;; Theme selection
  (if (display-graphic-p)
      ;; GUI mode - use modus-vivendi-tinted
      (progn
        (load-theme 'modus-vivendi-tinted t)
        ;; Font setup from platform.el
        (set-face-attribute 'default nil :font my/font-name :height my/font-height))
    ;; Terminal mode - use tango-dark with custom faces
    (load-theme 'tango-dark t)
    (set-face-background 'hl-line "gray25")
    (set-face-foreground 'hl-line nil)
    (set-face-attribute 'hl-line nil :inherit nil)
    (with-eval-after-load 'vertico
      (set-face-background 'vertico-current "gray25")
      (set-face-attribute 'vertico-current nil :inherit nil))))

;; Apply UI setup
(if (daemonp)
    ;; Daemon mode - setup for each new frame
    (add-hook 'after-make-frame-functions
              (lambda (frame)
                (with-selected-frame frame
                  (my/setup-ui))))
  ;; Regular Emacs - setup once
  (add-hook 'after-init-hook #'my/setup-ui))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UI & APPEARANCE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Enable current line highlighting
(global-hl-line-mode 1)

;; Require the color library
(require 'color)

;; Define a function to set highlight color based on theme
(defun my/set-hl-line-color ()
  "Set the hl-line face based on whether we're using a light or dark theme."
  (interactive)
  (when (display-graphic-p)
    (let* ((bg (frame-parameter nil 'background-color))
           (is-light (> (color-distance bg "white")
                        (color-distance bg "black"))))
      (if is-light
          ;; For dark themes - darker highlight
          (set-face-attribute 'hl-line nil :background "#3a3a3a" :extend t)
        ;; For light themes - lighter highlight
        (set-face-attribute 'hl-line nil :background "#e0e0e0" :extend t)))))

;; Call it once at startup
(with-eval-after-load 'color
  (my/set-hl-line-color))

;; Make sure highlighting doesn't override selection
(set-face-attribute 'hl-line nil :inherit nil)

;; Add hook to update when theme changes
(add-hook 'after-load-theme-hook 'my/set-hl-line-color)


;; Disable unused UI elements
(custom-set-variables
 '(blink-cursor-mode nil)
 '(menu-bar-mode nil)
 '(scroll-bar-mode nil)
 '(tool-bar-mode nil)
 '(tooltip-mode nil)
 '(warning-suppress-types '((use-package))))

;; Mode line appearance
(set-face-attribute 'mode-line nil :foreground "gray50" :background "black"
                    :box '(:line-width 1 :color "gray50"))
(set-face-attribute 'mode-line-inactive nil :foreground "white" :background "gray20"
                    :box '(:line-width 1 :color "gray20"))

;; Window divider
(setq window-divider-default-places t
      window-divider-default-bottom-width 2
      window-divider-default-right-width 2)
(window-divider-mode 1)

;; Show filename in title
(setq frame-title-format
      (list (format "%s %%S: %%j " (system-name))
            '(buffer-file-name "%f" (dired-directory dired-directory "%b"))))

;; Make commented text stand out better
(custom-set-faces
 '(font-lock-comment-face ((t (:foreground "gray60")))))

;; Dimmer for inactive windows
(use-package dimmer
  :ensure t
  :defer 2  ;; Load after 2 seconds idle
  :config
  (setq dimmer-fraction 0.10)
  (setq dimmer-delay 0.01)
  (add-to-list 'dimmer-exclusion-regexp-list "^\*Minibuf")
  (dimmer-configure-which-key)
  (dimmer-configure-magit)
  (dimmer-mode t))

;; Improved scrolling
(setq mouse-wheel-scroll-amount '(2 ((shift) . 2) ((control) . nil)))
(setq mouse-wheel-progressive-speed nil)

(use-package ultra-scroll
  :straight (ultra-scroll :type git :host github :repo "jdtsmith/ultra-scroll")
  :defer 1  ;; Load after 1 second idle
  :init
  (setq scroll-conservatively 101
        scroll-margin 0)
  :config
  (ultra-scroll-mode 1))

;; Icons for prettier UI
(use-package all-the-icons
  :defer t)

(use-package all-the-icons-completion
  :after (marginalia all-the-icons)
  :hook (marginalia-mode . all-the-icons-completion-marginalia-setup))

;; Rainbow delimiters for better code readability
(use-package rainbow-delimiters
  :hook ((prog-mode . rainbow-delimiters-mode)))
(electric-pair-mode)

;; Delight for cleaner mode line
(use-package delight
  :ensure t)

;; Common mode settings
(defun my/text-mode-setup ()
  "Common setup for text modes."
  (visual-line-mode 1)
  (display-fill-column-indicator-mode 1))

(defun my/prog-mode-setup ()
  "Common setup for programming modes."
  (visual-line-mode 1)
  (display-fill-column-indicator-mode 1)
  (show-paren-mode 1)
  (electric-pair-local-mode 1))

(add-hook 'text-mode-hook #'my/text-mode-setup)
(add-hook 'prog-mode-hook #'my/prog-mode-setup)


;; Enable column number mode globally
(column-number-mode 1)

;; Set default fill-column
(setq-default fill-column 80)

;; Enable fill column indicator globally
(global-display-fill-column-indicator-mode 1)

;; Configure per-mode settings
(add-hook 'elisp-mode-hook
          (lambda ()
            (setq fill-column 80)
            (setq display-fill-column-indicator-column 80)))

(add-hook 'markdown-mode-hook
          (lambda ()
            (setq fill-column 80)
            (setq display-fill-column-indicator-column 80)))

(add-hook 'python-mode-hook
          (lambda ()
            (setq fill-column 88)
            (setq display-fill-column-indicator-column 88)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'ui)
;;; ui.el ends here
