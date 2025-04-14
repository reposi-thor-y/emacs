;;; init.el --- Optimized Emacs Configuration

;;; Commentary:
;; Optimized Emacs configuration by Johan Thor
;; Restructured for better organization and performance

;;; Code:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 1. STARTUP OPTIMIZATIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Set repositories to use
(setq package-archives '(("elpa" . "https://elpa.gnu.org/packages/")
                         ("melpa" . "https://melpa.org/packages/")))

;; Bootstrap straight.el
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; Integrate `straight' with `use-package'
(straight-use-package 'use-package)
(setq straight-use-package-by-default t)
(setq straight-check-for-modifications '(find-when-checking))

;; Set up package.el to work with straight.el
(require 'package)
(package-initialize)

;; Better garbage collection strategy using gcmh
(use-package gcmh
  :ensure t
  :demand t
  :config
  (setq gcmh-high-cons-threshold (* 100 1000 1000)) ; 100MB
  (setq gcmh-idle-delay 5)
  (gcmh-mode 1))

;; Optimize garbage collection during minibuffer usage
(defun my/gc-minibuffer-setup-hook ()
  "Increase GC threshold when minibuffer is active."
  (setq gc-cons-threshold most-positive-fixnum))

(defun my/gc-minibuffer-exit-hook ()
  "Reset GC threshold when minibuffer is inactive."
  (setq gc-cons-threshold (* 50 1000 1000)))

(add-hook 'minibuffer-setup-hook #'my/gc-minibuffer-setup-hook)
(add-hook 'minibuffer-exit-hook #'my/gc-minibuffer-exit-hook)

;; Enable native compilation if available (Emacs 28+)
(when (and (fboundp 'native-comp-available-p)
           (native-comp-available-p))
  (setq native-comp-async-report-warnings-errors nil)
  (setq native-comp-deferred-compilation t)
  (setq native-comp-async-jobs-number 12)
  
  ;; Set up a dedicated native compilation cache directory
  (when (boundp 'comp-eln-load-path)
    (let ((eln-cache-dir (expand-file-name "eln-cache/" user-emacs-directory)))
      (add-to-list 'comp-eln-load-path eln-cache-dir)
      (setq native-comp-eln-load-path
            (list (expand-file-name "eln-cache/" user-emacs-directory))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 2. ESSENTIAL SETTINGS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Encoding
(set-charset-priority 'unicode)
(prefer-coding-system 'utf-8-unix)
(set-default-coding-systems 'utf-8)

;; Line numbers:
;; set a fixed width for line numbers:
(setq-default display-line-numbers-width-start t)
;; 
(global-display-line-numbers-mode t)

;; Backup and autosave
(setq make-backup-files nil
      auto-save-default nil
      create-lockfiles nil)

;; Security
(setq auth-sources '("~/.authinfo.gpg")
      auth-source-save-behavior t)

;; Warning levels
(setq warning-minimum-level :emergency)

;; Global key bindings
(global-set-key (kbd "C-c a") 'mark-whole-buffer)
(global-set-key (kbd "C-c i") 'indent-region)
(unbind-key "C-z") ;; Disable suspend-frame

;; Edit config file quickly
(defun open-init-file ()
  "Open this very file."
  (interactive)
  (find-file "~/.emacs.d/config.el"))
(bind-key "C-c e" #'open-init-file)

;; Enhanced comment/uncomment function with multi-language support
(defun comment-or-uncomment-line-or-region ()
  "Comments or uncomments the current line or region intelligently.
Handles different languages including C++, Python, JSON, and shell scripts.
For regions in C-like languages, uses block comments when appropriate."
  (interactive)
  (let* ((start (if (region-active-p)
                    (region-beginning)
                  (line-beginning-position)))
         (end (if (region-active-p)
                  (region-end)
                (line-end-position)))
         (use-block-comments (and (region-active-p)
                                 (> (count-lines start end) 1)
                                 (or (derived-mode-p 'c-mode)
                                     (derived-mode-p 'c++-mode)
                                     (derived-mode-p 'js-mode)
                                     (derived-mode-p 'css-mode)))))
    (cond
     ;; Block comment case for multi-line C-style languages
     (use-block-comments
      (let ((already-commented (save-excursion
                                 (goto-char start)
                                 (looking-at-p "[ \t]*/\\*"))))
        (if already-commented
            ;; Remove block comment
            (save-excursion
              ;; Find and remove opening comment
              (goto-char start)
              (when (re-search-forward "/\\*" (+ start 10) t)
                (replace-match "" nil nil))
              ;; Find and remove closing comment
              (goto-char (max (- end 10) start))
              (when (re-search-forward "\\*/" (+ end 10) t)
                (replace-match "" nil nil)))
          ;; Add block comment
          (save-excursion
            (goto-char end)
            (insert "*/")
            (goto-char start)
            (insert "/*")))))
     
     ;; JSON mode (which doesn't have a built-in comment functionality)
     ((derived-mode-p 'json-mode)
      (save-excursion
        (let ((line-count 0))
          (goto-char start)
          (while (< (point) end)
            (beginning-of-line)
            (if (looking-at "^[ \t]*//")
                ;; Remove comment
                (delete-region (match-beginning 0) (+ (match-end 0) 
                                                     (if (looking-at "^[ \t]*// ") 1 0)))
              ;; Add comment
              (insert "// "))
            (setq line-count (1+ line-count))
            (when (= line-count 100) (error "Safety limit reached"))
            (forward-line 1)))))
     
     ;; Default for all other cases - use the built-in function
     (t (comment-or-uncomment-region start end)))))

(global-set-key (kbd "M-1") 'comment-or-uncomment-line-or-region)

;; Smart buffer indentation
(defun indent-buffer-smart ()
  "Indent buffer while preserving point and window position.
Also handles various cleanup tasks like removing trailing whitespace."
  (interactive)
  ;; Remember window position
  (let ((window-start (window-start)))
    ;; Remember cursor position
    (let ((current-point (point)))
      ;; Indent and cleanup
      (save-excursion
        (delete-trailing-whitespace)
        (indent-region (point-min) (point-max) nil)
        (untabify (point-min) (point-max)))
      ;; Restore cursor and window position
      (goto-char current-point)
      (set-window-start (selected-window) window-start))
    (message "Buffer indented and cleaned up!"))
  ;; Flash modeline to indicate completion
  (force-mode-line-update)
  (sit-for 0.5))

(global-set-key (kbd "M-2") 'indent-buffer-smart)

;; Enhanced yank that indents pasted code
(defun pt-yank ()
  "Call yank, then indent the pasted region, as TextMate does."
  (interactive)
  (let ((point-before (point)))
    (when mark-active (call-interactively 'delete-backward-char))
    (yank)
    (indent-region point-before (point))))

(bind-key "C-y" #'pt-yank)
(bind-key "C-z" #'undo)
(bind-key "s-v" #'pt-yank)
(bind-key "C-Y" #'yank)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 3. OS-SPECIFIC SETTINGS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Define environment variables
(defvar xdg-bin (getenv "XDG_BIN_HOME"))
(defvar xdg-cache (getenv "XDG_CACHE_HOME"))
(defvar xdg-config (getenv "XDG_CONFIG_HOME"))

;; macOS specific settings
(when (eq system-type 'darwin)
  (setq mac-right-option-modifier 'nil)
  (setq mac-command-modifier 'control
        select-enable-clipboard t))

;; Theme setup function
(defun my/setup-themes ()
  "Set up themes based on display type."
  (message "Setting up themes...")
  (mapc #'disable-theme custom-enabled-themes)
  (if (display-graphic-p)
      ;; GUI mode
      (load-theme 'ef-owl t)
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
     ;; macOS specific
     ((and (eq system-type 'darwin)
           (string-equal (system-name) "macbook15-macos.vilanelva.se"))
      (add-to-list 'default-frame-alist '(fullscreen . maximized))
      (set-face-attribute 'default nil :font "Source Code Pro" :height 180))
     ;; Linux specific
     ((eq system-type 'gnu/linux)
      (cond
       ((string-equal (system-name) "rocky-ws")
        (set-frame-size (selected-frame) 120 70)
        (set-frame-position (selected-frame) 850 0)
        (set-face-attribute 'default nil :font "SauceCodePro NFM" :height 160))
       ((string-equal (system-name) "macbook13-linux")
        (add-to-list 'default-frame-alist '(fullscreen . maximized))
        (set-face-attribute 'default nil :font "SauceCodePro NFM" :height 200))
       ((string-equal (system-name) "sodra-ds-test")
        (set-face-attribute 'default nil :font "SauceCodePro NFM" :height 180))
       ((string-equal (system-name) "sod-as103403")
        (set-frame-size (selected-frame) 160 90)
        (set-face-attribute 'default nil :font "SauceCodePro NFM" :height 240)))))))

;; Set up hooks
(add-hook 'after-init-hook #'my/setup-themes)
(add-hook 'window-setup-hook #'my/setup-system-gui)

;; For daemon mode
(add-hook 'after-make-frame-functions
          (lambda (frame)
            (with-selected-frame frame
              (my/setup-themes)
              (my/setup-system-gui))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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


;; Install mana theme collection
(use-package ef-themes
  :ensure t
  :defer t)

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

(use-package nerd-icons-completion
  :ensure t
  :after marginalia
  :hook (marginalia-mode . nerd-icons-completion-marginalia-setup)
  :config
  (nerd-icons-completion-mode 1))

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

;; Column settings
(setq-default fill-column 88)
(setq-default display-fill-column-indicator-column 88)
(column-number-mode 1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 5. GENERAL FUNCTIONALITY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Indentation settings
(setq-default indent-tabs-mode nil)

;; Window management
(global-set-key (kbd "C-x 2") 'split-window-below)
(global-set-key (kbd "C-x 3") 'split-window-right)

;; Windmove for easier window navigation
(use-package windmove
  :ensure t
  :bind
  (("M-j" . windmove-left)
   ("M-i" . windmove-up)
   ("M-k" . windmove-down)
   ("M-l" . windmove-right)
   ("C-c M-l" . windmove-delete-left)
   ("C-c M-r" . windmove-delete-right)
   ("C-c M-d" . windmove-delete-down)
   ("C-c M-u" . windmove-delete-up)))

;; which-key helps you learn and remember keybindings
(use-package which-key
  :ensure t
  :config
  (which-key-mode)
  (setq which-key-idle-delay 0.5)
  (setq which-key-popup-type 'side-window)
  (setq which-key-side-window-location 'bottom)
  (setq which-key-side-window-max-height 0.60))

;; Edit files with sudo
(use-package sudo-edit
  :defer t)

;; ibuffer for better buffer management
(use-package ibuffer
  :ensure nil
  :preface
  (defvar protected-buffers '("*scratch*" "*Messages*")
    "Buffer that cannot be killed.")

  (defun my/protected-buffers ()
    "Protect some buffers from being killed."
    (dolist (buffer protected-buffers)
      (with-current-buffer buffer
        (emacs-lock-mode 'kill))))
  :bind ("C-x C-b" . ibuffer)
  :init (my/protected-buffers))

;; For large files, use more efficient methods
(use-package vlf
  :defer t
  :config
  (require 'vlf-setup))

(defun my/find-file-hook-large-file ()
  "If a file is over 5MB, use vlf mode to open it."
  (when (> (buffer-size) (* 5 1024 1024))
    (progn
      (setq buffer-read-only t)
      (buffer-disable-undo)
      (fundamental-mode)
      (vlf-mode 1))))

(add-hook 'find-file-hook 'my/find-file-hook-large-file)

;; Save history between sessions
(use-package savehist
  :init
  (setq history-length 1000
        savehist-additional-variables '(mark-ring
                                       global-mark-ring
                                       search-ring
                                       regexp-search-ring
                                       extended-command-history))
  :config
  (savehist-mode 1))

;; Recent files tracking
(use-package recentf
  :defer t
  :init
  (setq recentf-max-saved-items 100
        recentf-exclude '("/tmp/" "/ssh:"))
  :config
  (recentf-mode 1))

;; Async operations for better responsiveness
(use-package async
  :defer t
  :init
  (setq async-bytecomp-allowed-packages '(all))
  :config
  (async-bytecomp-package-mode 1)
  (dired-async-mode 1))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6. COMPLETION FRAMEWORK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Vertico for vertical completion UI
(use-package vertico
  :ensure t
  :init
  (vertico-mode)
  :bind (:map vertico-map
              ("C-<backspace>" . vertico-directory-delete-char)
              ("C-<return>" . vertico-exit-input)
              ("RET" . vertico-directory-enter)
              ("C-n" . vertico-next)
              ("C-p" . vertico-previous)
              ("TAB" . vertico-insert))
  :bind (:map minibuffer-local-map
              ("TAB" . vertico-insert))
  :custom
  (vertico-cycle t)
  (vertico-preselect 'prompt)
  (vertico-count 20)
  (vertico-resize t)
  (vertico-multiform-commands
   '((consult-line buffer)
     (consult-imenu buffer)
     (consult-ripgrep buffer)))
  :config
  ;; Load the vertico directory extension
  (use-package vertico-directory
    :ensure nil ;; Part of vertico
    :after vertico
    :load-path "straight/build/vertico/extensions"
    :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))
  
  (setq vertico-count-format nil)
  :custom-face
  (vertico-current ((t (:background "#1d1f21")))))

;; Orderless for flexible matching
(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic partial-completion))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles orderless basic partial-completion))))
  (completion-ignore-case t)
  (read-file-name-completion-ignore-case t)
  (read-buffer-completion-ignore-case t))

;; Consult for enhanced commands
(use-package consult
  :ensure t
  :bind (;; Keep standard find-file but enhance it through completion framework
         ("C-x b" . consult-buffer)       ;; Replace switch-to-buffer
         ("C-s" . consult-line)           ;; Search in current buffer
         ("C-c f f" . consult-find)       ;; Add find as a separate command
         ("C-c f r" . consult-ripgrep))   ;; Add ripgrep search
  :config
  (setq consult-find-command "find . -type f -not -path \"*/\\.git/*\" -not -path \"*/node_modules/*\" -not -path \"*/build/*\"")
  (setq consult-project-function #'consult--default-project-function))

;; Marginalia for rich annotations
(use-package marginalia
  :ensure t
  :after vertico
  :init (marginalia-mode)
  :custom
  (marginalia-annotators '(marginalia-annotators-heavy
                           marginalia-annotators-light
                           nil))
  :bind (:map minibuffer-local-map
              ("M-A" . marginalia-cycle)))

;; Prescient for better sorting
(use-package prescient
  :ensure t
  :config
  (prescient-persist-mode +1))

(use-package vertico-prescient
  :ensure t
  :after (vertico prescient)
  :config
  (vertico-prescient-mode +1))

;; Custom function for zsh-like completion
(defun my/zsh-like-completion ()
  "Complete like zsh - complete until ambiguity."
  (interactive)
  (let ((completion-styles '(basic partial-completion))
        (completion-category-overrides nil)
        (completion-cycle-threshold nil))
    (minibuffer-complete)))

;; Enhanced Tab completion for Vertico
(defun my/vertico-tab ()
  "Smart tab in Vertico: complete common prefix or select current candidate."
  (interactive)
  (if (= vertico--index -1)
      ;; No candidate selected - complete common prefix
      (my/zsh-like-completion)
    ;; Candidate is selected - accept it
    (vertico-exit)))

;; Global completion settings
(setq completion-styles '(basic partial-completion orderless)
      completion-category-defaults nil
      completion-category-overrides '((file (styles . (basic partial-completion))))
      completion-ignore-case t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 7. DEVELOPMENT TOOLS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Company mode for in-buffer completion
(use-package company
  :ensure t
  :hook (after-init . global-company-mode)
  :custom
  (company-idle-delay 0.1)
  (company-minimum-prefix-length 2)
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

;; Flycheck for syntax checking
(use-package flycheck
  :defer t
  :hook (after-init . global-flycheck-mode)
  :config
  (cond
   ((eq system-type 'darwin)
    (setq flycheck-flake8rc "/Users/johanthor/.config/flake8"))
   ((eq system-type 'gnu/linux)
    (setq flycheck-flake8rc "/home/johanthor/.config/flake8"))))

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

;; Terminal emulation
(use-package vterm
  :defer t
  :config
  (setq vterm-max-scrollback 10000)
  (setq vterm-keymap-exceptions '("C-x" "C-u" "C-g" "C-h" "C-l" "M-x" "M-o" "C-v" "M-v" "C-y" "M-y"
                                  "M-i" "M-j" "M-k" "M-l"))
  :bind (:map vterm-mode-map
              ("M-i" . windmove-up)
              ("M-j" . windmove-left)
              ("M-k" . windmove-down)
              ("M-l" . windmove-right))
  :bind (("C-c t" . vterm)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 8. LANGUAGE SUPPORT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; LSP (Language Server Protocol) Mode
(use-package lsp-mode
  :defer t
  :commands (lsp lsp-deferred)
  :hook ((python-mode . lsp-deferred)
         (c++-mode . lsp-deferred)
         (latex-mode . lsp-deferred)
         (markdown-mode . lsp-deferred))
  :init
  (setq lsp-keymap-prefix "C-c l")
  :config
  ;; Performance optimizations
  (setq lsp-enable-file-watchers nil)
  (setq lsp-idle-delay 0.500)
  (setq lsp-log-io nil)
  (setq lsp-completion-provider :capf)
  (setq lsp-prefer-flymake nil)
  (setq read-process-output-max (* 1024 1024))
  
  ;; Features
  (setq lsp-enable-symbol-highlighting t)
  (setq lsp-enable-indentation nil)
  (setq lsp-enable-on-type-formatting nil)
  (setq lsp-signature-auto-activate nil)
  (setq lsp-signature-render-documentation nil)
  (setq lsp-eldoc-hook nil)
  (setq lsp-modeline-code-actions-enable nil)
  (setq lsp-modeline-diagnostics-enable nil)
  (setq lsp-headerline-breadcrumb-enable nil)
  
  ;; Language-specific settings
  (lsp-register-custom-settings
   '(("pyls.plugins.pycodestyle.enabled" t t)
     ("pyls.plugins.pycodestyle.maxLineLength" 88 t))))

;; LSP UI enhancements
(use-package lsp-ui
  :defer t
  :after lsp-mode
  :commands lsp-ui-mode
  :config
  (setq lsp-ui-doc-enable nil
        lsp-ui-sideline-enable nil))

;; Tree view for LSP
(use-package lsp-treemacs
  :defer t
  :commands lsp-treemacs-errors-list)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 8.1 PYTHON
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Basic Python settings
(setq python-indent-offset 4)

;; Pyenv configuration
(use-package pyenv-mode
  :defer t
  :init
  (add-to-list 'exec-path "~/.pyenv/shims")
  :config
  (pyenv-mode)
  (when (executable-find "pyenv")
    (setenv "PYENV_ROOT" (replace-regexp-in-string "\n" "" (shell-command-to-string "pyenv root")))
    (add-to-list 'exec-path (concat (getenv "PYENV_ROOT") "/shims")))
  :hook (python-mode . pyenv-mode)
  :bind ("C-c C-s" . pyenv-mode-set))

;; Ruff for Python linting
(use-package flymake-ruff
  :defer t
  :hook (python-mode . flymake-ruff-load))

;; Helper function to set Python interpreter
(defun my/set-flycheck-python-interpreter ()
  "Set Flycheck Python interpreter to the one specified by pyenv."
  (let ((pyenv-path (executable-find "python")))
    (setq-local flycheck-python-pyflakes-executable pyenv-path)
    (setq-local flycheck-python-flake8-executable pyenv-path)))

(add-hook 'python-mode-hook #'my/set-flycheck-python-interpreter)

;; Indentation guides for Python
(use-package indent-bars
  :defer t
  :straight (indent-bars :type git :host github :repo "jdtsmith/indent-bars")
  :custom
  (indent-bars-treesit-support t)
  (indent-bars-no-descend-string t)
  (indent-bars-treesit-ignore-blank-lines-types '("module"))
  (indent-bars-treesit-wrap '((python argument_list parameters
                                      list list_comprehension
                                      dictionary dictionary_comprehension
                                      parenthesized_expression subscript)))
  :config
  (setq
   indent-bars-color '(highlight :face-bg t :blend 0.3)
   indent-bars-prefer-character 1
   indent-bars-width-frac 0.9
   indent-bars-pad-frac 0.2
   indent-bars-zigzag 0.1
   indent-bars-color-by-depth '(:palette ("red" "green" "orange" "cyan") :blend 1)
   indent-bars-highlight-current-depth '(:blend 0.5))
  :hook ((python-base-mode) . indent-bars-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 8.2 C++
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Define Google C++ style
(c-add-style "google"
             '("stroustrup"
               (c-basic-offset . 2)
               (c-offsets-alist
                (access-label . -)
                (arglist-cont-nonempty . +)
                (arglist-intro . +)
                (case-label . 0)
                (func-decl-cont . +)
                (inclass . +)
                (inher-cont . c-lineup-multi-inher)
                (inline-open . 0)
                (label . /)
                (member-init-intro . +)
                (namespaces . 0)
                (statement-cont . +)
                (substatement-open . 0)
                (template-args-cont . +))))

;; Clang formatting
(use-package clang-format
  :defer t
  :bind (("C-c f" . clang-format-buffer)
         ("C-c r f" . clang-format-region)))

;; Modern C++ syntax highlighting
(use-package modern-cpp-font-lock
  :defer t
  :hook (c++-mode . modern-c++-font-lock-mode))

;; Basic C++ mode settings
(setq-default c-basic-offset 4)
(setq-default tab-width 4)
(setq compile-command "cmake -B build -G Ninja && cmake --build build")

(add-hook 'c++-mode-hook
          (lambda ()
            (c-set-style "google")
            (c-set-offset 'innamespace 0)
            (c-toggle-auto-newline 1)
            (c-toggle-hungry-state 1)
            (c-set-offset 'substatement-open 0)))

(global-set-key (kbd "C-c C-c") 'compile)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 8.3 LATEX
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Set indentation for LaTeX lists
(setq LaTeX-indent-level 2)
(setq LaTeX-item-indent 0)
(setq LaTeX-indent-level-item-continuation 4)

;; Define the indentation function for list environments
(defun LaTeX-indent-item ()
  "Provide proper indentation for LaTeX \"itemize\",\"enumerate\", and
\"description\" environments. \"\\item\" is indented 'LaTeX-indent-level'
spaces relative to the beginning of the environment.

Continuation lines are indented either twice 'LaTeX-indent-level',
or 'LaTeX-indent-level-item-continuation' if the latter is bound."
  (save-match-data
    (let* ((offset LaTeX-indent-level)
           (contin (or (and (boundp 'LaTeX-indent-level-item-continuation)
                            LaTeX-indent-level-item-continuation)
                       (* 2 LaTeX-indent-level)))
           (re-beg "\\\\begin{")
           (re-end "\\\\end{")
           (re-env "\\(itemize\\|\\enumerate\\|description\\)")
           (indent (save-excursion
                     (when (looking-at (concat re-beg re-env "}"))
                       (end-of-line))
                     (LaTeX-find-matching-begin)
                     (current-column))))
      (cond ((looking-at (concat re-beg re-env "}"))
             (or (save-excursion
                   (beginning-of-line)
                   (ignore-errors
                     (LaTeX-find-matching-begin)
                     (+ (current-column)
                        (if (looking-at (concat re-beg re-env "}"))
                            contin
                          offset))))
                 indent))
            ((looking-at (concat re-end re-env "}"))
             indent)
            ((looking-at "\\\\item")
             (+ offset indent))
            (t
             (+ contin indent))))))

(use-package tex
  :ensure auctex
  :defer t
  :mode ("\\.tex\\'" . latex-mode)
  :init
  (setq-default TeX-engine 'luatex)  ; Set default engine
  :config
  (setq TeX-auto-save t
        TeX-parse-self t
        TeX-master nil
        TeX-engine 'luatex
        ;; Use PDF mode by default
        TeX-PDF-mode t
        ;; Prevent confirmation for cleaning generated files
        TeX-clean-confirm nil
        ;; Add -shell-escape by default for minted package
        LaTeX-command-style '(("" "%(PDF)%(latex) -shell-escape %S%(PDFout)"))
        ;; Swedish quotes
        TeX-quote-language-alist '(("swedish" "\"" "\"" t))
        TeX-quote-language "swedish"))

;; Set up PDF Tools as the viewer
(use-package pdf-tools
  :defer t
  :magic ("%PDF" . pdf-view-mode)
  :config
  (pdf-tools-install :no-query)
  ;; Don't ask to reload when the PDF changes
  (setq revert-without-query '(".*"))
  (setq TeX-view-program-selection '((output-pdf "PDF Tools")))
  (add-hook 'TeX-after-compilation-finished-functions
            #'TeX-revert-document-buffer)

  ;; Enable useful minor modes
  (add-hook 'LaTeX-mode-hook #'flyspell-mode)
  (add-hook 'LaTeX-mode-hook #'reftex-mode)
  (add-hook 'LaTeX-mode-hook
            (lambda ()
              (add-hook 'post-self-insert-hook
                        (lambda ()
                          (when (eq last-command-event ?-)
                            (message "Dash typed: preceding-char is '%c'"
                                     (char-before (1- (point))))))
                        nil t)))

  ;; Enable minted for code highlighting
  (add-to-list 'LaTeX-verbatim-environments "minted")
  (add-to-list 'LaTeX-verbatim-macros-with-braces "mintinline"))

;; Enhanced reference management
(use-package reftex
  :defer t
  :after tex
  :config
  (setq reftex-plug-into-AUCTeX t
        ;; Ensure RefTeX finds your bibliography files
        reftex-default-bibliography '("references.bib")))

;; Completion support for LaTeX
(use-package company-auctex
  :defer t
  :after (company tex)
  :config
  (company-auctex-init))

;; LSP support through texlab
(use-package lsp-latex
  :defer t
  :after tex
  :hook ((LaTeX-mode . lsp)
         (lsp-mode . lsp-enable-which-key-integration))
  :config
  (setq lsp-latex-texlab-executable "/usr/bin/texlab"
        lsp-latex-build-on-save t))

;; Preview equations inline
(use-package math-preview
  :defer t
  :after tex
  :custom
  (math-preview-command "/usr/local/bin/math-preview"))

;; Keybinding for error navigation (Swedish keyboard friendly)
(with-eval-after-load 'tex
  (define-key TeX-mode-map (kbd "C-c f") 'TeX-next-error))

;; Optional: Set up structure folding
(add-hook 'LaTeX-mode-hook 'outline-minor-mode)
(add-hook 'LaTeX-mode-hook 'TeX-fold-mode)

;; Set up proper list environment indentation
(with-eval-after-load "latex"
  (add-to-list 'LaTeX-indent-environment-list '("itemize" LaTeX-indent-item))
  (add-to-list 'LaTeX-indent-environment-list '("enumerate" LaTeX-indent-item))
  (add-to-list 'LaTeX-indent-environment-list '("description" LaTeX-indent-item)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 8.4 MARKDOWN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package markdown-mode
  :defer t
  :commands (markdown-mode gfm-mode)
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'" . markdown-mode)
         ("\\.markdown\\'" . markdown-mode))
  :init
  ;; Pandoc is located at different places:
  (cond
   ((eq system-type 'darwin)
    ;; macOS:
    (setq markdown-command "/usr/local/bin/pandoc"))
   ;; Linux-specific configurations
   ((eq system-type 'gnu/linux)
    (setq markdown-command "/usr/bin/pandoc")))
  :hook (markdown-mode . lsp-deferred)
  :config
  (require 'lsp-marksman))

(add-hook 'markdown-mode-hook 
          (lambda ()
            (display-fill-column-indicator-mode 1)))

(use-package markdown-preview-mode
  :defer t
  :after markdown-mode)

(defun markdown-export-pdf ()
  "Export the current Markdown file to PDF using Pandoc."
  (interactive)
  (let* ((input-file (buffer-file-name))
         (output-file (concat (file-name-sans-extension input-file) ".pdf")))
    (call-process "pandoc" nil nil nil
                  input-file
                  "-o" output-file
                  "--pdf-engine=xelatex"
                  "-V" "geometry:margin=1in")
    (message "Exported to %s" output-file)))

;; Markdown code formatting
(use-package prettier-js
  :defer t
  :hook (markdown-mode . prettier-js-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 8.5 OTHER FILE FORMATS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

;; Shell script mode
(use-package sh-script
  :defer t
  :delight "δ"
  :hook (after-save . executable-make-buffer-file-executable-if-script-p))

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

;; JSON mode with improvements
(use-package json-mode
  :defer t
  :delight "J"
  :mode (("\\.json\\'" . my-json-mode)
         ("\\.jsonc\\'" . my-jsonc-mode)
         ("\\.json5\\'" . my-jsonc-mode))
  :hook ((json-mode . my/json-mode-setup)
         (before-save . my/json-mode-before-save-hook))
  :preface
  (defun my/json-mode-setup ()
    "Setup function for JSON modes."
    (make-local-variable 'js-indent-level)
    (setq js-indent-level 2)
    (setq-local indent-tabs-mode nil))

  (defun my/json-mode-before-save-hook ()
    "Format JSON buffer before saving, if in a JSON mode."
    (when (derived-mode-p 'json-mode)
      (when (not (bound-and-true-p my-json-format-disabled))
        (json-pretty-print-buffer))))

  (defun my/json-array-of-numbers-on-one-line (encode array)
    "Print arrays of numbers in one line."
    (let* ((is-all-numbers (catch 'not-all-numbers
                             (dotimes (i (length array))
                               (unless (numberp (aref array i))
                                 (throw 'not-all-numbers nil)))
                             t))
           (json-encoding-pretty-print
            (and json-encoding-pretty-print
                 (not is-all-numbers)))
           (json-encoding-separator (if json-encoding-pretty-print "," ", ")))
      (funcall encode array)))

  (defun my/toggle-json-format-on-save ()
    "Toggle JSON formatting on save."
    (interactive)
    (setq-local my-json-format-disabled (not (bound-and-true-p my-json-format-disabled)))
    (message "JSON format on save %s" (if my-json-format-disabled "disabled" "enabled")))

  :config
  (advice-add 'json-encode-array :around #'my/json-array-of-numbers-on-one-line)

  ;; Base JSON mode with comments
  (define-derived-mode my-json-mode json-mode "JSON"
    "Major mode for editing JSON files."
    (setq-local indent-tabs-mode nil)
    (setq-local js-indent-level 2))

  ;; JSONC mode (JSON with Comments)
  (define-derived-mode my-jsonc-mode my-json-mode "JSONC"
    "Major mode for editing JSON files with C-style comments."
    (setq-local comment-start "// ")
    (setq-local comment-end "")
    (setq-local comment-start-skip "//+\\s-*")
    (setq-local comment-use-syntax t)
    (modify-syntax-entry ?/ ". 124b" syntax-table)
    (modify-syntax-entry ?* ". 23" syntax-table)
    (modify-syntax-entry ?\n "> b" syntax-table))

  (define-key json-mode-map (kbd "C-c C-t") 'my/toggle-json-format-on-save)
  (define-key json-mode-map (kbd "C-c C-f") 'json-pretty-print-buffer))

(use-package json-navigator
  :defer t
  :after json-mode)

(use-package prettier
  :defer t
  :hook ((json-mode . prettier-mode)
         (my-jsonc-mode . prettier-mode)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 9. MISC SETTINGS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; These settings enhance the overall Emacs experience
(setq-default
 ad-redefinition-action 'accept                       ; Silence warnings for redefinition
 cursor-in-non-selected-windows t                     ; Hide the cursor in inactive windows
 display-time-default-load-average nil                ; Don't display load average
 help-window-select t                                 ; Focus new help windows when opened
 inhibit-startup-screen t                             ; Disable start-up screen
 initial-scratch-message ""                           ; Empty the initial *scratch* buffer
 kill-ring-max 128                                    ; Maximum length of kill ring
 load-prefer-newer t                                  ; Prefer the newest version of a file
 mark-ring-max 128                                    ; Maximum length of mark ring
 read-process-output-max (* 1024 1024)                ; Increase the amount of data reads from the process
 scroll-conservatively most-positive-fixnum           ; Always scroll by one line
 select-enable-clipboard t                            ; Merge system's and Emacs' clipboard
 user-full-name "Johan Thor"                          ; Set the full name of the current user
 vc-follow-symlinks t                                 ; Always follow the symlinks
 fast-but-imprecise-scrolling t                       ; More scrolling performance!
 view-read-only t)                                    ; Always open read-only buffers in view-mode

;; Final UI tweaks
;; (global-hl-line-mode 1)                                 ; Highlight current line
(show-paren-mode 1)                                   ; Show matching parenthesis
(fset 'yes-or-no-p 'y-or-n-p)                         ; Replace yes/no prompts with y/n

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 10. FINALIZATION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Custom file location
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

(provide 'config)
;;; config.el ends here
