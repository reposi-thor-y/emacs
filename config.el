;; package --- Summary

;;; Commentary:
;; Optimized Emacs configuration by Johan Thor
;; To install programs called for in the below code, install them on Ubuntu
;; using the following command:
;; $ sudo apt install npm hunspell cargo pandoc
;;
;; Besides the above, also install texlive-type of package to handle Tex-files.
;;
;; Also, install the following:
;; $ brew install marksman # markdown LSP-server
;; $ npm install -g prettier # markdown formatting in Emacs
;; $ npm install dictionary-sv
;; $ npm install dictionary-en-gb
;; $ sudo npm install -g pyright
;;
;; Every other package should be installed using use-package.

;;; Code:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Performance optimizations
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(message "0. Performance optimizations...")

;; Increase garbage collection threshold for faster startup
(setq gc-cons-threshold (* 50 1000 1000))

;; Set repositories to use
(setq package-archives '(("elpa" . "https://elpa.gnu.org/packages/")
                         ("melpa" . "https://melpa.org/packages/")))

;; Bootstrap straight
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

;; Suppress a warning about Emacs complaining about straight not being defined
(declare-function straight-use-package "ext:straight.el")

;; Integrate `straight' with `use-package'
(straight-use-package 'use-package)
(setq straight-use-package-by-default t)
(setq straight-check-for-modifications '(find-when-checking))

;; Better garbage collection strategy using gcmh
(use-package gcmh
  :ensure t
  :demand t
  :init
  (setq gcmh-high-cons-threshold (* 100 1000 1000)) ; 100MB
  (setq gcmh-idle-delay 5)
  :config
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
  (setq native-comp-async-jobs-number 4) ; Adjust based on your CPU
  
  ;; Set up a dedicated native compilation cache directory
  (when (boundp 'comp-eln-load-path)
    (let ((eln-cache-dir (expand-file-name "eln-cache/" user-emacs-directory)))
      (add-to-list 'comp-eln-load-path eln-cache-dir)
      (setq native-comp-eln-load-path
            (list (expand-file-name "eln-cache/" user-emacs-directory))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Global settings
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(message "1. Applying global settings...")
;; Always use utf-8
(set-charset-priority 'unicode)
(prefer-coding-system 'utf-8-unix)

;; Set the width of the line numbers to be fixed, depending on the number of lines
(setq display-line-numbers-width-start t)

;; Don't produce backup files
(setq make-backup-files nil
      auto-save-default nil
      create-lockfiles nil)

;; Don't write sensitive info in plain text
(setq auth-sources '("~/.authinfo.gpg")
      auth-source-save-behavior t)

;; Stop Emacs from hiding
(unbind-key "C-z") ;; suspend-frame

;; Stop Emacs from throwing up buffers with warnings
(defvar warning-minimum-level)
(setq warning-minimum-level :emergency)

;; Common keybindings
(global-set-key (kbd "C-c a") 'mark-whole-buffer)
(global-set-key (kbd "C-c i") 'indent-region)

;; Short-cut for editing config.el
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

;; Create a function to indent buffers
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

;; Always show linenumbers in the left margin
(global-display-line-numbers-mode 1)

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
;; OS-specifics:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(message "2. OS-specifics...")
(defvar mac-right-option-modifier)
(defvar mac-command-modifier)
(defvar xdg-bin (getenv "XDG_BIN_HOME"))
(defvar xdg-cache (getenv "XDG_CACHE_HOME"))
(defvar xdg-config (getenv "XDG_CONFIG_HOME"))

;; Theme setup function
(defun my/setup-themes ()
  "Set up themes based on display type."
  (message "3. Setting up themes...")
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

;; Set up non-GUI specific settings immediately
(cond
 ((eq system-type 'darwin)
  ;; macOS keybinding-fixes:
  (setq mac-right-option-modifier 'nil)
  (setq mac-command-modifier 'control
        select-enable-clipboard t)))

;; For daemon mode, also set up GUI settings when creating new frames
(add-hook 'after-make-frame-functions
          (lambda (frame)
            (with-selected-frame frame
              (my/setup-themes)
              (my/setup-system-gui))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Look and feel:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(message "4. Look and feel...")

;; Common text mode settings
(defun my/text-mode-setup ()
  "Common setup for text modes."
  (visual-line-mode 1)
  (display-fill-column-indicator-mode 1))

;; Common programming mode settings
(defun my/prog-mode-setup ()
  "Common setup for programming modes."
  (visual-line-mode 1)
  (display-fill-column-indicator-mode 1)
  (show-paren-mode 1)
  (electric-pair-local-mode 1))

;; Apply settings to mode hooks
(add-hook 'text-mode-hook #'my/text-mode-setup)
(add-hook 'prog-mode-hook #'my/prog-mode-setup)

;; For text files: auto-fill for actual line breaks at 88 chars
(setq-default fill-column 88)
(setq-default display-fill-column-indicator-column 88)

;; User interface settings
(custom-set-variables
 '(blink-cursor-mode nil)
 '(menu-bar-mode nil)
 '(scroll-bar-mode nil)
 '(tool-bar-mode nil)
 '(tooltip-mode nil)
 '(warning-suppress-types '((use-package))))

;; Customize mode line appearance for active and inactive buffers
(set-face-attribute 'mode-line nil :foreground "gray50" :background "black" :box '(:line-width 1 :color "gray50"))
(set-face-attribute 'mode-line-inactive nil :foreground "white" :background "gray20" :box '(:line-width 1 :color "gray20"))

;; Make the window divider line thicker
(setq window-divider-default-places t
      window-divider-default-bottom-width 2
      window-divider-default-right-width 2)

;; Show filename in title
(setq frame-title-format
      (list (format "%s %%S: %%j " (system-name))
            '(buffer-file-name "%f" (dired-directory dired-directory "%b"))))

;; Make commented text stand out better
(custom-set-faces
 '(font-lock-comment-face ((t (:foreground "gray60")))))

;; Make a greater difference between active and inactive buffers
(use-package dimmer
  :ensure t
  :config
  ;; Adjust the dimming fraction (the default is 0.20)
  (setq dimmer-fraction 0.10)
  (setq dimmer-delay 0.01) ; Adjust the delay in seconds

  ;; Exclude some buffers from being dimmed
  (add-to-list 'dimmer-exclusion-regexp-list "^\*Minibuf")

  ;; Configure and activate dimmer
  (dimmer-configure-which-key)
  (dimmer-configure-magit)
  (dimmer-mode t))

;; Mouse scroll speed
(setq mouse-wheel-scroll-amount '(2 ((shift) . 2) ((control) . nil)))
(setq mouse-wheel-progressive-speed nil)

;; Scroll speed improvements
(use-package ultra-scroll
  :straight (ultra-scroll :type git :host github :repo "jdtsmith/ultra-scroll")
  :init
  (setq scroll-conservatively 101 ; important!
        scroll-margin 0)
  :config
  (ultra-scroll-mode 1))

;; Install icons
(use-package all-the-icons
  :defer t)

(use-package nerd-icons
  :defer t)

;; Add icons to the files
(use-package all-the-icons-completion
  :after (marginalia all-the-icons)
  :hook (marginalia-mode . all-the-icons-completion-marginalia-setup))

;; Rainbow delimiters for better code readability
(use-package rainbow-delimiters
  :hook ((prog-mode . rainbow-delimiters-mode)))
(electric-pair-mode)

;; Delight lets you customize how modes are displayed (or hidden)
(use-package delight
  :ensure t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Misc settings:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(message "5. Misc settings...")
(setq-default
 ad-redefinition-action 'accept                       ; Silence warnings for redefinition
 cursor-in-non-selected-windows t                     ; Hide the cursor in inactive windows
 display-time-default-load-average nil                ; Don't display load average
 help-window-select t                                 ; Focus new help windows when opened
 indent-tabs-mode nil                                 ; Prefer spaces over tabs
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
(column-number-mode 1)                                ; Show the column number
(fset 'yes-or-no-p 'y-or-n-p)                         ; Replace yes/no prompts with y/n
(global-hl-line-mode)                                 ; Highlight current line
(set-default-coding-systems 'utf-8)                   ; Default to utf-8 encoding
(show-paren-mode 1)                                   ; Show the parent

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Addons and customisations:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(message "6. Addons and customisations...")

;; Enhanced file finding with consult and ido fallback
(use-package consult
  :bind (("C-x C-f" . consult-find-file) ;; Replace default find-file
         ("C-x b" . consult-buffer)       ;; Replace switch-to-buffer
         ("C-s" . consult-line))          ;; Search in current buffer
  :config
  ;; If consult fails to find file, fall back to ido
  (defun consult-find-file ()
    "Use `find-file' enhanced by consult and ido as fallback."
    (interactive)
    (call-interactively 'find-file)))

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


;; Install and configure dired-sidebar for easy file navigation
(use-package dired-sidebar
  :ensure t
  :bind (("C-x C-n" . dired-sidebar-toggle-sidebar))
  :config
  (setq dired-sidebar-use-term-integration t)
  (setq dired-sidebar-use-custom-font t))


;; Vertico configuration for better completion
(use-package vertico
  :init
  (vertico-mode)
  :bind (:map vertico-map
              ("C-<backspace>" . vertico-directory-up)
              ("C-n" . vertico-next)
              ("C-p" . vertico-previous)
              ("TAB" . my/zsh-like-completion))
  :bind (:map minibuffer-local-map
              ("TAB" . my/zsh-like-completion))
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
  (setq vertico-count-format nil)
  :custom-face
  (vertico-current ((t (:background "#1d1f21")))))

;; Marginalia adds more information to minibuffer completions
(use-package marginalia
  :ensure t
  :straight t
  :after vertico
  :init (marginalia-mode)
  :custom
  (marginalia-annotators '(marginalia-annotators-heavy
                           marginalia-annotators-light
                           nil))
  :bind (:map minibuffer-local-map
              ("M-A" . marginalia-cycle)))

;; Orderless provides more flexible matching for completions
(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles . (basic partial-completion))))))

;; Terminal emulation within Emacs
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

;; Project management with Projectile
(use-package projectile
  :defer t
  :bind-keymap ("C-c p" . projectile-command-map)
  :init
  (setq projectile-completion-system 'vertico)
  (setq projectile-indexing-method 'alien)
  (setq projectile-sort-order 'recently-active)
  :config
  (projectile-mode 1))

;; Recent files tracking
(use-package recentf
  :defer t
  :init
  (setq recentf-max-saved-items 100
        recentf-exclude '("/tmp/" "/ssh:"))
  :config
  (recentf-mode 1))

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

;; Async operations for better responsiveness
(use-package async
  :defer t
  :init
  (setq async-bytecomp-allowed-packages '(all))
  :config
  (async-bytecomp-package-mode 1)
  (dired-async-mode 1))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; LaTeX support
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(message "7. LaTeX...")

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
;; Markdown support
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(message "8. Markdown support...")

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
;; Code completion and tools
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(message "9. Code completion and tools...")

;; Unified completion system
(use-package company
  :ensure t
  :defer 1
  :hook (after-init . global-company-mode)
  :config
  (setq company-minimum-prefix-length 1
        company-idle-delay 0.0
        company-backends '((company-files
                           company-keywords
                           company-capf
                           company-yasnippet)))
  ;; Make TAB behave less aggressively
  (define-key company-active-map [tab] nil)
  (define-key company-active-map (kbd "TAB") nil))

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

;; Unified LSP configuration
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

;; Use flycheck to check code
(use-package flycheck
  :defer t
  :hook (after-init . global-flycheck-mode)
  :config
  (cond
   ((eq system-type 'darwin)
    (setq flycheck-flake8rc "/Users/johanthor/.config/flake8"))
   ((eq system-type 'gnu/linux)
    (setq flycheck-flake8rc "/home/johanthor/.config/flake8"))))

;; Helper function to set Python interpreter
(defun my/set-flycheck-python-interpreter ()
  "Set Flycheck Python interpreter to the one specified by pyenv."
  (let ((pyenv-path (executable-find "python")))
    (setq-local flycheck-python-pyflakes-executable pyenv-path)
    (setq-local flycheck-python-flake8-executable pyenv-path)))

(add-hook 'python-mode-hook #'my/set-flycheck-python-interpreter)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Python-section:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(message "10. Python-specifics...")

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

;; Indentation guides
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
;; C++
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(message "11. C++ configuration...")

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
(setq-default indent-tabs-mode nil)
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
;; Version Control
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(message "12. Version Control...")

;; Magit for Git integration
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; File type modes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(message "13. File type modes...")

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

;;; config.el ends here
