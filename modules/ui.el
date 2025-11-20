;;; ui.el --- UI and appearance configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; UI and appearance configuration

;;; Code:

;; 3. OS-SPECIFIC SETTINGS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Define environment variables
(defvar xdg-bin (getenv "XDG_BIN_HOME"))
(defvar xdg-cache (getenv "XDG_CACHE_HOME"))
(defvar xdg-config (getenv "XDG_CONFIG_HOME"))

;; macOS specific settings
;; (when (eq system-type 'darwin)
;;   (setq mac-right-option-modifier 'nil)
;;   (setq mac-command-modifier 'control
;;         select-enable-clipboard t))


;; Resizing Emacs in KDE Plasma isn't nice without this:
;; (setq frame-resize-pixelwise t)

;; Theme setup function
(defun my/setup-themes ()
  "Set up themes based on display type."
  (message "Setting up themes...")
  (mapc #'disable-theme custom-enabled-themes)
  (if (display-graphic-p)
      ;; GUI mode
      (load-theme 'modus-vivendi-tinted t)
    ;; Terminal mode
    (progn
      (load-theme 'tango-dark t)
      ;; Terminal-specific face settings
      (set-face-background 'hl-line "gray25")
      (set-face-foreground 'hl-line nil)
      (set-face-attribute 'hl-line nil :inherit nil)
      ;; Vertico face settings for terminal
      (with-eval-after-load 'vertico
        (set-face-background 'vertico-current "gray25")
        (set-face-attribute 'vertico-current nil :inherit nil)))))

;; System-specific GUI settings
(defun my/setup-system-gui ()
  "Configure system-specific GUI settings"
  (when (display-graphic-p)
    (cond
     ;; Linux specific
     ((eq system-type 'gnu/linux)
      (cond
       ((string-equal (system-name) "rocky-ws")
        ;; (set-frame-size (selected-frame) 120 60)
        ;; (set-frame-position (selected-frame) 400 0)
        (set-face-attribute 'default nil :font "SauceCodePro NFM" :height 120))
       ((string-equal (system-name) "rocky-laptop")
        (set-face-attribute 'default nil :font "Source Code Pro" :height 120))
       )))))

;; Set up hooks
(add-hook 'after-init-hook #'my/setup-themes)
(add-hook 'window-setup-hook #'my/setup-system-gui)

;; For daemon mode
(add-hook 'after-make-frame-functions
          (lambda (frame)
            (with-selected-frame frame
              (my/setup-themes)
              (my/setup-system-gui))))


;; 4. UI & APPEARANCE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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


;; ;; Install mana theme collection
;; (use-package ef-themes
;;   :ensure t
;;   :defer t)

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
  :init
  (setq scroll-conservatively 101
        scroll-margin 0)
  :config
  (ultra-scroll-mode 1))

;; Icons for prettier UI
(use-package all-the-icons
  :defer t)


;; (use-package nerd-icons-completion
;;   :ensure t
;;   :after marginalia
;;   :hook (marginalia-mode . nerd-icons-completion-marginalia-setup)
;;   :config
;;   ;; Only enable in GUI mode, not in terminal
;;   (when (display-graphic-p)
;;     (nerd-icons-completion-mode 1)))


;; (use-package nerd-icons-completion
;;   :ensure t
;;   :after marginalia
;;   :hook (marginalia-mode . nerd-icons-completion-marginalia-setup)
;;   :config
;;   (nerd-icons-completion-mode 1))

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'ui)
;;; ui.el ends here
