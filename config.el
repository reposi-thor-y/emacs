;;; config.el --- Optimized Emacs Configuration

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

;; center buffer:
(use-package centered-cursor-mode
  :ensure t
  :bind ("C-c l" . centered-cursor-mode))

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
(unbind-key "C-x C-z") ;; Disable suspend-frame

;; Edit config file quickly
(defun open-init-file ()
  "Open this very file."
  (interactive)
  (find-file "~/.emacs.d/config.el"))
(bind-key "C-c e" #'open-init-file)


;; Enhanced comment/uncomment function with multi-language support
(defun comment-or-uncomment-line-or-region ()
  "Comments or uncomments the current line or region intelligently.
Handles different languages including C++, Python, JSON, shell scripts, and R.
For regions in C-like languages, uses block comments when appropriate."
  (interactive)
  (let* ((start (if (region-active-p)
                    (save-excursion
                      (goto-char (region-beginning))
                      (line-beginning-position))
                  (line-beginning-position)))
         (end (if (region-active-p)
                  (save-excursion
                    (goto-char (region-end))
                    (line-end-position))
                (line-end-position)))
         (use-block-comments (and (region-active-p)
                                  (> (count-lines start end) 3) ; Only for 4+ lines
                                  (or (derived-mode-p 'c-mode)
                                      (derived-mode-p 'c++-mode)
                                      (derived-mode-p 'java-mode)
                                      (derived-mode-p 'js-mode)
                                      (derived-mode-p 'css-mode)))))
    (cond
     ;; Block comment case for multi-line C-style languages
     (use-block-comments
      (let ((already-commented (save-excursion
                                 (goto-char start)
                                 (and (re-search-forward "^[ \t]*/\\*" (line-end-position) t)
                                      (save-excursion
                                        (goto-char end)
                                        (beginning-of-line)
                                        (re-search-backward "\\*/[ \t]*$" start t))))))
        (if already-commented
            ;; Remove block comment
            (save-excursion
              ;; Remove opening comment
              (goto-char start)
              (when (re-search-forward "^\\([ \t]*\\)/\\*[ \t]*" (line-end-position) t)
                (replace-match "\\1"))
              ;; Remove closing comment
              (goto-char end)
              (beginning-of-line)
              (when (re-search-backward "[ \t]*\\*/\\([ \t]*\\)$" start t)
                (replace-match "\\1")))
          ;; Add block comment
          (save-excursion
            (goto-char end)
            (end-of-line)
            (insert " */")
            (goto-char start)
            (beginning-of-line)
            (when (looking-at "\\([ \t]*\\)")
              (goto-char (match-end 1))
              (insert "/* "))))))

     ;; JSON mode (which doesn't have built-in comment functionality)
     ((derived-mode-p 'json-mode)
      (save-excursion
        (goto-char start)
        (while (<= (point) end)
          (beginning-of-line)
          (if (looking-at "^[ \t]*//[ \t]*")
              ;; Remove comment
              (replace-match (match-string 0) nil nil nil 0)
            ;; Add comment
            (when (looking-at "^[ \t]*")
              (goto-char (match-end 0))
              (insert "// ")))
          (forward-line 1)
          (when (> (point) end) (goto-char (1+ end))))))

     ;; YAML mode (commonly used in data science)
     ((derived-mode-p 'yaml-mode)
      (save-excursion
        (goto-char start)
        (while (<= (point) end)
          (beginning-of-line)
          (if (looking-at "^[ \t]*#[ \t]*")
              ;; Remove comment
              (replace-match "" nil nil)
            ;; Add comment
            (when (looking-at "^[ \t]*")
              (goto-char (match-end 0))
              (insert "# ")))
          (forward-line 1)
          (when (> (point) end) (goto-char (1+ end))))))

     ;; R mode (useful for data scientists)
     ((derived-mode-p 'ess-r-mode)
      (comment-or-uncomment-region start end))

     ;; Default for all other cases - use the built-in function
     (t (comment-or-uncomment-region start end)))))

;; Bind to Meta-1 (Alt-1)
(global-set-key (kbd "M-1") 'comment-or-uncomment-line-or-region)



;; Smart buffer indentation with file type awareness
(defun indent-buffer-smart ()
  "Indent buffer while preserving point and window position.
Also handles various cleanup tasks like removing trailing whitespace.
Skips indentation for certain file types where it might cause issues."
  (interactive)
  ;; List of file extensions/modes where we should skip full indentation
  (let ((skip-indent-extensions '(".flake8" "flake8rc" ".gitignore" ".ini" ".conf" ".cfg" ".toml"))
        (skip-indent-modes '(conf-mode ini-mode)))

    ;; Check if current file should skip indentation
    (let ((should-indent t)
          (file-name (buffer-file-name)))

      ;; Skip based on file extension
      (when file-name
        (dolist (ext skip-indent-extensions)
          (when (string-match-p (regexp-quote ext) file-name)
            (setq should-indent nil))))

      ;; Skip based on major mode
      (when (member major-mode skip-indent-modes)
        (setq should-indent nil))

      ;; Remember window position
      (let ((window-start (window-start)))
        ;; Remember cursor position
        (let ((current-point (point)))
          ;; Cleanup and conditional indentation
          (save-excursion
            (delete-trailing-whitespace)
            (when should-indent
              (indent-region (point-min) (point-max) nil)
              (untabify (point-min) (point-max))))
          ;; Restore cursor and window position
          (goto-char current-point)
          (set-window-start (selected-window) window-start))
        (if should-indent
            (message "Buffer indented and cleaned up!")
          (message "Buffer cleaned up! (Indentation skipped for this file type)"))
        ;; Flash modeline to indicate completion
        (force-mode-line-update)
        (sit-for 0.5)))))

(global-set-key (kbd "M-2") 'indent-buffer-smart)


(bind-key "C-z" #'undo)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
(setq frame-resize-pixelwise t)

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
     ;; Linux specific
     ((eq system-type 'gnu/linux)
      (cond
       ((string-equal (system-name) "rocky-ws")
        ;; (set-frame-size (selected-frame) 120 60)
        ;; (set-frame-position (selected-frame) 400 0)
        (set-face-attribute 'default nil :font "SauceCodePro NFM" :height 120))
       ((string-equal (system-name) "macbook13-linux")
        (add-to-list 'default-frame-alist '(fullscreen . maximized))
        (set-face-attribute 'default nil :font "SauceCodePro NFM" :height 200))
       ((string-equal (system-name) "sodra-ds-test")
        (set-face-attribute 'default nil :font "SauceCodePro NFM" :height 120))
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

;; Column settings
(setq-default fill-column 88)
(setq-default display-fill-column-indicator-column 88)
(column-number-mode 1)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 5. SPELL CHECKING
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Spell checking configuration for Swedish and English (UK)
;; Requires hunspell and appropriate dictionaries to be installed

;; Set hunspell as the spell checker
(when (executable-find "hunspell")
  (setq ispell-program-name "hunspell")

  ;; Use simple dictionary names that match your hunspell -D output
  (setq ispell-dictionary "en_GB-large")

  ;; Set personal dictionary location
  (setq ispell-personal-dictionary "~/.local/share/spelling/personal.dic")

  ;; Create the personal dictionary file if it doesn't exist
  (unless (file-exists-p ispell-personal-dictionary)
    (let ((dict-dir (file-name-directory ispell-personal-dictionary)))
      (unless (file-exists-p dict-dir)
        (make-directory dict-dir t)))
    (with-temp-file ispell-personal-dictionary
      (insert "0\n")))

  ;; Don't use complex dictionary definitions - let hunspell handle it
  (setq ispell-local-dictionary-alist nil)

  ;; Set up hunspell arguments properly
  (setq ispell-extra-args '("--sug-mode=ultra")))

;; Enable flyspell for text modes
(add-hook 'text-mode-hook 'flyspell-mode)
(add-hook 'prog-mode-hook 'flyspell-prog-mode)

;; Language switching functions
(defun switch-spell-language ()
  "Switch between English, Swedish, and bilingual spell checking."
  (interactive)
  (let ((current ispell-dictionary))
    (cond
     ((string= current "en_GB-large")
      (setq ispell-dictionary "sv_SE")
      (message "Switched to Swedish"))
     ((string= current "sv_SE")
      (setq ispell-dictionary "en_GB-large,sv_SE")
      (message "Switched to bilingual"))
     (t
      (setq ispell-dictionary "en_GB-large")
      (message "Switched to English"))))
  ;; Kill and restart ispell process with new dictionary
  (ispell-kill-ispell)
  (when flyspell-mode
    (flyspell-buffer)))

;; Individual language switching functions
(defun spell-english ()
  "Switch to English spell checking."
  (interactive)
  (setq ispell-dictionary "en_GB-large")
  (ispell-kill-ispell)
  (when flyspell-mode (flyspell-buffer))
  (message "Switched to English spell checking"))

(defun spell-swedish ()
  "Switch to Swedish spell checking."
  (interactive)
  (setq ispell-dictionary "sv_SE")
  (ispell-kill-ispell)
  (when flyspell-mode (flyspell-buffer))
  (message "Switched to Swedish spell checking"))

(defun spell-bilingual ()
  "Switch to bilingual (English + Swedish) spell checking."
  (interactive)
  (setq ispell-dictionary "en_GB-large,sv_SE")
  (ispell-kill-ispell)
  (when flyspell-mode (flyspell-buffer))
  (message "Switched to bilingual spell checking"))

;; Auto-detect language function
(defun auto-detect-spell-language ()
  "Automatically set spell checking language based on buffer content."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (let ((swedish-indicators '("och" "att" "som" "för" "på" "av" "är" "det" "med" "har" "från" "vid" "till" "då" "över" "så" "här" "där" "när" "bara" "den" "ett" "ska" "skulle" "kan" "kommer" "blir" "blev" "vara" "varit" "under" "mellan" "inom" "utan" "genom" "enligt" "efter" "innan" "sedan" "medan" "därför" "därmed" "alltså" "även" "dock" "redan" "ännu" "kanske" "ibland" "ofta" "aldrig" "alltid" "mycket" "många" "några" "alla" "varje" "denna" "detta" "dessa" "samma" "andra" "första" "andra" "tredje" "svenska" "engelsk" "språk"))
          (english-indicators '("the" "and" "that" "for" "you" "with" "not" "this" "but" "his" "her" "they" "have" "from" "had" "she" "which" "their" "said" "each" "make" "like" "into" "time" "very" "when" "much" "new" "some" "could" "know" "take" "than" "only" "little" "good" "way" "too" "any" "may" "say" "must" "such" "here" "take" "made" "most" "over" "think" "also" "back" "after" "use" "her" "can" "out" "just" "where" "see" "how" "its" "our" "out" "many" "them" "these" "so" "some" "her" "would" "make" "like" "him" "has" "two" "more" "very" "what" "know" "just" "first" "get" "has" "him" "his" "had" "let" "put" "end" "why" "try" "god" "six" "dog" "eat" "ago" "sit" "fun" "bad" "yes" "yet" "arm" "far" "off" "ill" "egg" "add" "men" "run" "eye" "mrs" "mix" "oil" "sit" "log" "let" "gun" "war" "far" "bus" "oak" "sea" "who" "oil" "its" "sit" "own" "say" "she" "may" "way" "day" "boy" "did" "old" "see" "now" "way" "may" "say" "new" "try" "ask" "men" "old" "see" "him" "two" "how" "its" "who" "oil" "sit" "own" "say" "she" "may" "way" "day" "boy" "did" "old" "see" "now" "way" "may" "say" "new" "try" "ask" "men" "old" "see" "him" "two" "how" "its" "who" "oil" "sit" "own" "say" "she" "may" "way" "day" "boy" "did" "old" "see" "now" "way" "may" "say" "new" "try" "ask" "men" "old" "see" "him" "two" "how" "its" "who" "oil" "sit" "own" "say" "she" "may" "way" "day" "boy"))
          (swedish-count 0)
          (english-count 0)
          (words-checked 0))
      ;; Count indicators in first 2000 characters
      (while (and (< (point) (point-max)) (< (point) 2000) (< words-checked 100))
        (let* ((word-bounds (bounds-of-thing-at-point 'word))
               (word (when word-bounds
                       (downcase (buffer-substring-no-properties
                                  (car word-bounds) (cdr word-bounds))))))
          (when word
            (setq words-checked (1+ words-checked))
            (when (member word swedish-indicators)
              (setq swedish-count (1+ swedish-count)))
            (when (member word english-indicators)
              (setq english-count (1+ english-count)))))
        (forward-word 1))
      ;; Set dictionary based on detection
      (cond
       ((and (> swedish-count 2) (> swedish-count (* english-count 1.5)))
        (spell-swedish))
       ((and (> english-count 2) (> english-count (* swedish-count 1.5)))
        (spell-english))
       (t
        (spell-bilingual))))))


                                        ; Office-suite style binding
(global-set-key (kbd "<f7>") 'flyspell-buffer)

;; Main spell checking commands
(global-set-key (kbd "C-c s c") 'flyspell-buffer-with-highlighting)  ; Use enhanced version
(global-set-key (kbd "C-c s w") 'ispell-word)
(global-set-key (kbd "C-c s r") 'ispell-region)
(global-set-key (kbd "C-c s d") 'ispell-change-dictionary)
(global-set-key (kbd "C-c s n") 'flyspell-goto-next-error)

;; Language switching
(global-set-key (kbd "C-c s t") 'switch-spell-language)
(global-set-key (kbd "C-c s a") 'auto-detect-spell-language)
(global-set-key (kbd "C-c s e") 'spell-english)
(global-set-key (kbd "C-c s s") 'spell-swedish)
(global-set-key (kbd "C-c s b") 'spell-bilingual)

;; Debug/test functions
(global-set-key (kbd "C-c s f") 'flyspell-force-highlight)
(global-set-key (kbd "C-c s T") 'test-spell-with-highlighting)       ; Use enhanced version
(global-set-key (kbd "C-c s D") 'debug-flyspell-overlays)


;; Mouse binding fix: Use right-click instead of middle-click for flyspell menu
(eval-after-load "flyspell"
  '(progn
     ;; Remove the default middle-click binding
     (define-key flyspell-mouse-map [down-mouse-2] nil)
     (define-key flyspell-mouse-map [mouse-2] nil)
     ;; Add right-click binding for correction menu
     (define-key flyspell-mouse-map [down-mouse-3] 'flyspell-correct-word)
     (define-key flyspell-mouse-map [mouse-3] 'flyspell-correct-word)))

;; Test function
(defun test-spell-simple ()
  "Create a test buffer with misspelled words."
  (interactive)
  (let ((test-buffer (get-buffer-create "*spell-test*")))
    (with-current-buffer test-buffer
      (erase-buffer)
      (insert "This is a tesst of speling chekcing.\n")
      (insert "Thsi shoudl be highlited in red.\n")
      (insert "Hej världen och hello world.\n")
      (text-mode)
      (flyspell-mode 1)
      (flyspell-buffer))
    (switch-to-buffer test-buffer)
    (message "Test buffer created - misspelled words should be highlighted")))

(global-set-key (kbd "C-c s T") 'test-spell-simple)


;; Ensure flyspell faces are properly defined
(custom-set-faces
 '(flyspell-incorrect ((t (:underline (:color "red" :style wave)))))
 '(flyspell-duplicate ((t (:underline (:color "orange" :style wave))))))

;; Force flyspell to use overlays (not just run silently)
(setq flyspell-use-meta-tab nil)
(setq flyspell-consider-dash-as-word-delimiter-flag t)

;; Enhanced flyspell-buffer function that ensures highlighting
(defun flyspell-buffer-with-highlighting ()
  "Run flyspell-buffer and ensure errors are visually highlighted."
  (interactive)
  (flyspell-mode 1)  ; Ensure flyspell-mode is on
  (flyspell-buffer)
  (flyspell-overlay-p (point-min))  ; Force overlay check
  (message "Spell checking complete - errors should be highlighted in red"))

;; Better test function that ensures flyspell-mode is active
(defun test-spell-with-highlighting ()
  "Create a test buffer with guaranteed flyspell highlighting."
  (interactive)
  (let ((test-buffer (get-buffer-create "*spell-visual-test*")))
    (with-current-buffer test-buffer
      (erase-buffer)
      (insert "This is a tesst of speling chekcing.\n")
      (insert "Thsi shoudl be highlited in red.\n")
      (insert "Hej världen och hello world.\n")
      (text-mode)
      (flyspell-mode 1)
      ;; Force flyspell to check and highlight
      (flyspell-buffer)
      (goto-char (point-min))
      ;; Manually trigger highlighting if needed
      (while (< (point) (point-max))
        (flyspell-word)
        (forward-word 1)))
    (switch-to-buffer test-buffer)
    (message "Test buffer created - misspelled words should have red underlines")))

;; Debug function to check flyspell overlays
(defun debug-flyspell-overlays ()
  "Debug flyspell overlays in current buffer."
  (interactive)
  (let ((overlays (overlays-in (point-min) (point-max)))
        (flyspell-overlays 0))
    (dolist (overlay overlays)
      (when (overlay-get overlay 'flyspell-overlay)
        (setq flyspell-overlays (1+ flyspell-overlays))
        (message "Flyspell overlay at %d-%d: %s"
                 (overlay-start overlay)
                 (overlay-end overlay)
                 (buffer-substring (overlay-start overlay) (overlay-end overlay)))))
    (message "Total flyspell overlays: %d" flyspell-overlays)))

;; Alternative: Use flyspell-word on each word to force highlighting
(defun flyspell-force-highlight ()
  "Force flyspell to highlight all errors by checking each word."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (< (point) (point-max))
      (flyspell-word)
      (forward-word 1)))
  (message "Force highlighting complete"))

;; Key bindings
(global-set-key (kbd "C-c s c") 'flyspell-buffer-with-highlighting)
(global-set-key (kbd "C-c s f") 'flyspell-force-highlight)
(global-set-key (kbd "C-c s T") 'test-spell-with-highlighting)
(global-set-key (kbd "C-c s D") 'debug-flyspell-overlays)

;; Hook to ensure flyspell works properly in text mode
(add-hook 'text-mode-hook
          (lambda ()
            (flyspell-mode 1)
            (setq flyspell-issue-message-flag nil)))  ; Reduce message noise


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 6. GENERAL FUNCTIONALITY
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
;; 7. COMPLETION FRAMEWORK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Vertico for vertical completion UI
(use-package vertico
  :ensure t
  :init
  (vertico-mode)
  :bind (:map vertico-map
                                        ;              ("C-<backspace>" . vertico-directory-delete-char)
              ("C-<return>" . vertico-exit-input)
                                        ;             ("RET" . vertico-directory-enter)
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

  ;; ;; Load the vertico directory extension
  ;; (use-package vertico-directory
  ;;   :ensure nil ;; Part of vertico
  ;;   :after vertico
  ;;   :load-path "straight/build/vertico/extensions"
  ;;   :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

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
         ("C-c l" . consult-line)         ;; Search in current buffer
         ("C-c f d" . consult-find)       ;; Add find as a separate command
         ("C-c f g" . consult-ripgrep))   ;; Add ripgrep search
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
;; 9. LANGUAGE SUPPORT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Global LSP configuration - used by all language modes
(use-package lsp-mode
  :ensure t
  :commands (lsp lsp-deferred)
  :hook ((python-mode . lsp-deferred)
         (c++-mode . lsp-deferred)
         (latex-mode . lsp-deferred)
         (markdown-mode . lsp-deferred)
         (sh-mode . lsp-deferred)
         (zshrc-mode . lsp-deferred))
  :init
  ;; Performance optimizations
  (setq lsp-enable-file-watchers nil)           ;; Disable file watchers (better performance)
  (setq lsp-idle-delay 0.500)                   ;; How often to refresh
  (setq lsp-log-io nil)                         ;; Disable logging for better performance
  (setq lsp-completion-provider :capf)          ;; Use capf for completion
  (setq lsp-prefer-flymake nil)                 ;; Use flycheck instead of flymake
  (setq read-process-output-max (* 1024 1024))  ;; Increase read output for better performance

  ;; Features - disable intrusive UI elements
  (setq lsp-enable-symbol-highlighting t)
  (setq lsp-enable-indentation nil)             ;; Don't use LSP's indentation
  (setq lsp-enable-on-type-formatting nil)      ;; Disable automatic formatting
  (setq lsp-signature-auto-activate nil)        ;; Don't show signature help automatically
  (setq lsp-signature-render-documentation nil) ;; Don't render doc with signature
  (setq lsp-eldoc-hook nil)                     ;; Disable eldoc for LSP (can be noisy)
  (setq lsp-modeline-code-actions-enable nil)   ;; Disable code actions on modeline
  (setq lsp-modeline-diagnostics-enable nil)    ;; Disable diagnostics on modeline
  (setq lsp-headerline-breadcrumb-enable nil)   ;; Disable breadcrumbs in header line

  :config
  ;; Diagnostics setup
  (setq lsp-diagnostics-provider :flycheck)     ;; Use flycheck for displaying diagnostics

  ;; Python-specific LSP configuration
  (setq lsp-pylsp-plugins-flake8-enabled t)     ;; Enable flake8 plugin
  (setq lsp-pylsp-plugins-flake8-config nil)    ;; Use project's .flake8 file

  ;; Disable redundant linters to avoid conflicts with flake8
  (setq lsp-pylsp-plugins-pycodestyle-enabled nil)  ;; Let flake8 handle style
  (setq lsp-pylsp-plugins-mccabe-enabled nil)       ;; Let flake8 handle complexity
  (setq lsp-pylsp-plugins-pyflakes-enabled nil)     ;; Let flake8 handle basic checks

  ;; Configure docstring checking
  (setq lsp-pylsp-plugins-pydocstyle-enabled nil)   ;; Let flake8 handle docstrings

  ;; Add LSP restart function for when config files change
  (defun restart-lsp-server ()
    "Restart the LSP server for the current project."
    (interactive)
    (lsp-workspace-restart (lsp--session-workspace (lsp-session) (lsp--buffer-uri))))

  ;; Add keybinding for restarting LSP
  (define-key lsp-mode-map (kbd "C-c C-l r") 'restart-lsp-server))

;; LSP UI enhancements - apply to all LSP instances
(use-package lsp-ui
  :after lsp-mode
  :commands lsp-ui-mode
  :config
  (setq lsp-ui-doc-enable nil                   ;; Disable documentation popup
        lsp-ui-sideline-enable nil))            ;; Disable sideline

;; Tree view for LSP - used by all LSP instances
(use-package lsp-treemacs
  :defer t
  :commands lsp-treemacs-errors-list)

;; Debugging helper function for any language
(defun force-lsp-for-current-buffer ()
  "Force LSP to start for the current buffer regardless of file type."
  (interactive)
  (let ((lsp-auto-guess-root t))
    (lsp)))

;; Disable Flycheck's flake8 checker to avoid duplication with LSP
(with-eval-after-load 'flycheck
  (setq-default flycheck-disabled-checkers '(python-flake8)))

;; Turn off LSP debugging (was previously enabled)
(setq lsp-log-io nil)

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ;; 9.1 PYTHON
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; ;;; 1. Basic Python settings
;; ;; Set indentation level
;; (setq python-indent-offset 4)

;; ;;; 2. Python Environment Management (pyenv)
;; (use-package pyenv-mode
;;   :defer t
;;   :init
;;   (add-to-list 'exec-path "~/.pyenv/shims")
;;   :config
;;   (pyenv-mode)
;;   (when (executable-find "pyenv")
;;     (setenv "PYENV_ROOT" (replace-regexp-in-string "\n" "" (shell-command-to-string "pyenv root")))
;;     (add-to-list 'exec-path (concat (getenv "PYENV_ROOT") "/shims")))
;;   :hook (python-mode . pyenv-mode)
;;   :bind ("C-c C-s" . pyenv-mode-set))

;; ;;; 3. Python Linting with flake8
;; ;; Define flake8 as a Python syntax checker in Flycheck
;; (with-eval-after-load 'flycheck
;;   (setq flycheck-python-flake8-executable "flake8")

;;   ;; Configure flake8 options
;;   (setq flycheck-flake8rc ".flake8")  ;; Use .flake8 config file if present
;;   (setq flycheck-flake8-maximum-line-length 88)  ;; Match Black's default line length

;;   ;; Prioritize flake8 for Python
;;   (flycheck-add-next-checker 'python-flake8 'python-pylint t))

;; ;; Enable flycheck in Python mode
;; (add-hook 'python-mode-hook 'flycheck-mode)

;; ;;; 4. Python LSP Configuration
;; (with-eval-after-load 'lsp-mode
;;   ;; Python LSP settings
;;   (setq lsp-pylsp-plugins-flake8-enabled t)  ;; Enable flake8
;;   (setq lsp-pylsp-plugins-flake8-max-line-length 88)  ;; Match Black's default

;;   ;; Disable tools we're not using
;;   (setq lsp-pylsp-plugins-pycodestyle-enabled nil)
;;   (setq lsp-pylsp-plugins-mccabe-enabled nil)

;;   ;; Ensure we're only using a single LSP server (pylsp)
;;   (setq lsp-pylsp-server-command "pylsp")
;;   (setq lsp-clients-pylsp-library-directories '("/usr"))

;;   ;; Configure server for Python
;;   (lsp-register-custom-settings
;;    '(("pylsp.plugins.flake8.maxLineLength" 88 t)
;;      ("pylsp.plugins.pyflakes.enabled" t t)
;;      ("pylsp.plugins.black.enabled" t t)
;;      ("pylsp.plugins.isort.enabled" t t))))

;; ;; Virtual env support
;; (defun my/setup-python-lsp ()
;;   "Set up Python LSP environment with current pyenv."
;;   (interactive)
;;   ;; Skip the auto-detection of pyenv versions - this was causing the error

;;   ;; Just use the current Python executable, whatever it might be
;;   (let ((python-executable (executable-find "python")))
;;     ;; Update Python executable for LSP
;;     (when python-executable
;;       (setq-local lsp-pylsp-server-command python-executable))

;;     ;; Log info for debugging
;;     (message "Using Python: %s" python-executable)))

;; ;; Add hook to setup Python LSP environment
;; (add-hook 'python-mode-hook #'my/setup-python-lsp)

;; ;; ;;; 5. Format on Save with Black and isort
;; ;; (defun my/format-python-with-black ()
;; ;;   "Format the current buffer with Black."
;; ;;   (interactive)
;; ;;   (when (derived-mode-p 'python-mode)
;; ;;     (let* ((file-name (buffer-file-name))
;; ;;            (temp-buffer (generate-new-buffer " *black-temp*")))
;; ;;       (unwind-protect
;; ;;           (when file-name  ;; Only proceed if buffer is visiting a file
;; ;;             ;; Run black with explicit line length
;; ;;             (if (zerop (call-process "black" nil temp-buffer nil
;; ;;                                      "--line-length=88" file-name))
;; ;;                 (progn
;; ;;                   ;; Reload the file content after formatting
;; ;;                   (revert-buffer t t t)
;; ;;                   (message "Formatted with Black"))
;; ;;               (with-current-buffer temp-buffer
;; ;;                 (message "Black format failed: %s" (buffer-string)))))
;; ;;         (kill-buffer temp-buffer)))))

;; ;; (defun my/sort-imports-with-isort ()
;; ;;   "Sort Python imports with isort."
;; ;;   (interactive)
;; ;;   (when (derived-mode-p 'python-mode)
;; ;;     (let* ((file-name (buffer-file-name))
;; ;;            (temp-buffer (generate-new-buffer " *isort-temp*")))
;; ;;       (unwind-protect
;; ;;           (when file-name  ;; Only proceed if buffer is visiting a file
;; ;;             ;; Run isort with profile black to ensure compatibility
;; ;;             (if (zerop (call-process "isort" nil temp-buffer nil
;; ;;                                      "--profile=black" file-name))
;; ;;                 (progn
;; ;;                   ;; Reload the file content after sorting imports
;; ;;                   (revert-buffer t t t)
;; ;;                   (message "Imports sorted with isort"))
;; ;;               (with-current-buffer temp-buffer
;; ;;                 (message "isort failed: %s" (buffer-string)))))
;; ;;         (kill-buffer temp-buffer)))))

;; ;; (defun my/format-python-buffer ()
;; ;;   "Format Python buffer with Black and isort."
;; ;;   (interactive)
;; ;;   (when (derived-mode-p 'python-mode)
;; ;;     (my/sort-imports-with-isort)
;; ;;     (my/format-python-with-black)))

;; ;; ;; Set keybinding for formatting
;; ;; (with-eval-after-load 'python
;; ;;   (define-key python-mode-map (kbd "M-3") #'my/format-python-buffer))


;; ;; ;; Add a toggle function for format-on-save
;; ;; (defun my/toggle-python-format-on-save ()
;; ;;   "Toggle format-on-save for Python buffers."
;; ;;   (interactive)
;; ;;   (if (member #'my/format-python-buffer before-save-hook)
;; ;;       (progn
;; ;;         (remove-hook 'before-save-hook #'my/format-python-buffer t)
;; ;;         (message "Python format-on-save disabled"))
;; ;;     (add-hook 'before-save-hook #'my/format-python-buffer nil t)
;; ;;     (message "Python format-on-save enabled")))

;; ;; ;; Bind the toggle function to a key
;; ;; (with-eval-after-load 'python
;; ;;   (define-key python-mode-map (kbd "C-c C-t") #'my/toggle-python-format-on-save))

;; ;;; 6. Visual Indentation Guides for Python
;; (use-package indent-bars
;;   :defer t
;;   :straight (indent-bars :type git :host github :repo "jdtsmith/indent-bars")
;;   :custom
;;   (indent-bars-treesit-support t)
;;   (indent-bars-no-descend-string t)
;;   (indent-bars-treesit-ignore-blank-lines-types '("module"))
;;   (indent-bars-treesit-wrap '((python argument_list parameters
;;                                       list list_comprehension
;;                                       dictionary dictionary_comprehension
;;                                       parenthesized_expression subscript)))
;;   :config
;;   (setq
;;    indent-bars-color '(highlight :face-bg t :blend 0.3)
;;    indent-bars-prefer-character 1
;;    indent-bars-width-frac 0.9
;;    indent-bars-pad-frac 0.2
;;    indent-bars-zigzag 0.1
;;    indent-bars-color-by-depth '(:palette ("red" "green" "orange" "cyan") :blend 1)
;;    indent-bars-highlight-current-depth '(:blend 0.5))
;;   :hook ((python-base-mode) . indent-bars-mode))

;; ;;; Format on Save with Black and isort
;; (use-package python-black
;;   :ensure t
;;   :after python
;;   :config
;;   ;; Configure black with your preferred settings
;;   (setq python-black-extra-args '("--line-length=88"))
;;   ;; Set up format-on-save
;;   (setq python-black-on-save-mode nil)  ;; Start disabled - enable per-project as needed
;;   ;; Keybinding for manual formatting
;;   (define-key python-mode-map (kbd "C-c b") 'python-black-buffer)
;;   ;; Command to toggle format-on-save
;;   (define-key python-mode-map (kbd "C-c C-b") 'python-black-on-save-mode))

;; (use-package py-isort
;;   :ensure t
;;   :after python
;;   :config
;;   ;; Configure isort with your preferred settings
;;   (setq py-isort-options '("--profile=black"))
;;   ;; Don't auto-save by default - enable per-project as needed
;;   (remove-hook 'before-save-hook 'py-isort-before-save)
;;   ;; Keybinding for manual sorting
;;   (define-key python-mode-map (kbd "C-c i") 'py-isort-buffer)
;;   ;; Toggle auto-isort-on-save
;;   (defun toggle-py-isort-on-save ()
;;     "Toggle isort-on-save."
;;     (interactive)
;;     (if (member 'py-isort-before-save before-save-hook)
;;         (progn
;;           (remove-hook 'before-save-hook 'py-isort-before-save)
;;           (message "isort before save disabled"))
;;       (add-hook 'before-save-hook 'py-isort-before-save)
;;       (message "isort before save enabled")))
;;   (define-key python-mode-map (kbd "C-c C-i") 'toggle-py-isort-on-save))

;; ;; Combined format function (like your previous my/format-python-buffer)
;; (defun format-python-buffer-with-black-and-isort ()
;;   "Format Python buffer with Black and isort."
;;   (interactive)
;;   (when (derived-mode-p 'python-mode)
;;     (py-isort-buffer)
;;     (python-black-buffer)))

;; ;; Combine the two actions with your existing keybinding
;; (with-eval-after-load 'python
;;   (define-key python-mode-map (kbd "M-3") 'format-python-buffer-with-black-and-isort))

;; ;; Optional: Enable both for all Python files (alternative to per-project approach above)
;; ;; (add-hook 'python-mode-hook 'python-black-on-save-mode)
;; ;; (add-hook 'before-save-hook 'py-isort-before-save)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 9.2 C++
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; --- Basic C++ settings with consistent 4-space indentation ---
(setq-default c-basic-offset 4)
(setq-default tab-width 4)
(setq-default indent-tabs-mode nil)  ; Use spaces, not tabs

;; Custom C++ style based on a modified version of "stroustrup" style
(c-add-style "cpp-custom"
             '("stroustrup"
               (c-basic-offset . 4)
               (c-offsets-alist
                (access-label . -)
                (arglist-cont-nonempty . +)
                (arglist-intro . +)
                (case-label . 0)
                (func-decl-cont . +)
                (inclass . +)
                (inher-cont . c-lineup-multi-inher)
                (inline-open . 0)
                (innamespace . 0)      ; No extra indentation in namespaces
                (label . /)
                (member-init-intro . +)
                (namespaces . 0)
                (statement-cont . +)
                (substatement-open . 0)
                (template-args-cont . +))))

;; Apply our custom style to C++ files
(add-hook 'c++-mode-hook
          (lambda ()
            (c-set-style "cpp-custom")
            ;; Only enable auto-newline and hungry-delete for smaller files
            (when (< (buffer-size) 1000000)
              (c-toggle-auto-newline 1)
              (c-toggle-hungry-state 1))))

;; --- Performance optimizations for large files ---
(use-package so-long
  :config
  (global-so-long-mode 1))

(defun my/setup-cpp-for-large-files ()
  "Optimize settings for large C++ files."
  (when (> (buffer-size) 1000000) ; For files larger than ~1MB
    (setq-local font-lock-maximum-decoration 2)
    (font-lock-mode -1)
    (font-lock-mode 1)
    (setq-local font-lock-support-mode nil)
    (c-toggle-auto-newline -1)
    (c-toggle-hungry-state -1)))

(add-hook 'c++-mode-hook 'my/setup-cpp-for-large-files)

;; --- Modern C++ font lock ---
(use-package modern-cpp-font-lock
  :hook (c++-mode . modern-c++-font-lock-mode))

;; --- Clang Format ---
(use-package clang-format
  :bind (("C-c c f" . clang-format-buffer)
         ("C-c c r" . clang-format-region)))

;; LSP configuration for C++ with clangd
(with-eval-after-load 'lsp-mode
  (add-to-list 'lsp-language-id-configuration '(c++-mode . "cpp"))

  ;; Register clangd as the LSP server for C++
  (lsp-register-client
   (make-lsp-client :new-connection (lsp-stdio-connection
                                     '("clangd" "--header-insertion=never"
                                       "--completion-style=detailed"
                                       "--background-index"
                                       "--clang-tidy"
                                       "--suggest-missing-includes"))
                    :major-modes '(c++-mode c-mode)
                    :priority -1
                    :server-id 'clangd)))

;; --- Compilation settings ---
(setq compile-command "cmake -B build -G Ninja && cmake --build build")
(global-set-key (kbd "C-c C-c") 'compile)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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

;; Shell script LSP configuration
(with-eval-after-load 'lsp-mode
  ;; Configure bash-language-server
  (setq lsp-bash-highlight-parsing-errors t)
  (setq lsp-bash-explainshellendpoint "https://explainshell.com/api/explain")
  (setq lsp-bash-cmd '("bash-language-server" "start"))

  ;; Register bash-language-server for both sh-mode and zshrc-mode
  (lsp-register-client
   (make-lsp-client :new-connection (lsp-stdio-connection lsp-bash-cmd)
                    :major-modes '(sh-mode zshrc-mode)
                    :priority -1
                    :server-id 'bash-ls
                    :activation-fn (lambda (&rest _)
                                     (executable-find (car lsp-bash-cmd))))))

;; Add hook for the new mode to enable LSP
(add-hook 'zshrc-mode-hook #'lsp-deferred)
(add-hook 'sh-mode-hook #'lsp-deferred)

;; Ensure ShellCheck is available for enhanced diagnostics
(with-eval-after-load 'flycheck
  (setq flycheck-shellcheck-follow-sources t))
(add-hook 'sh-mode-hook 'flycheck-mode)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 9.4 LATEX
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
;; (use-package math-preview
;;   :defer t
;;   :after tex
;;   :custom
;;   (math-preview-command "/usr/local/sbin/math-preview"))

;; Keybinding for error navigation (Swedish keyboard friendly)
(with-eval-after-load 'tex
  (define-key TeX-mode-map (kbd "C-c n") 'TeX-next-error))

;; Optional: Set up structure folding
(add-hook 'LaTeX-mode-hook 'outline-minor-mode)
(add-hook 'LaTeX-mode-hook 'TeX-fold-mode)

;; Set up proper list environment indentation
(with-eval-after-load "latex"
  (add-to-list 'LaTeX-indent-environment-list '("itemize" LaTeX-indent-item))
  (add-to-list 'LaTeX-indent-environment-list '("enumerate" LaTeX-indent-item))
  (add-to-list 'LaTeX-indent-environment-list '("description" LaTeX-indent-item)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 9.5 MARKDOWN
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
;; 9.6 OTHER FILE FORMATS
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

;; ;; Shell script mode
;; (use-package sh-script
;;   :defer t
;;   :delight "δ"
;;   :hook (after-save . executable-make-buffer-file-executable-if-script-p))


;; Enhanced shell script configuration for Emacs
;; With focus on zsh integration

;; Base shell mode configuration
(use-package sh-script
  :defer t
  :delight "δ"
  :hook (after-save . executable-make-buffer-file-executable-if-script-p)
  :config
  ;; Set zsh as the default shell for script mode
  (setq sh-shell-file "/bin/zsh")

  ;; Custom indentation for zsh scripts
  (setq sh-basic-offset 2
        sh-indentation 2)

  ;; Set zsh as default for new shell scripts
  (add-to-list 'auto-mode-alist '("\\.zsh\\'" . sh-mode))
  (add-to-list 'auto-mode-alist '("zshrc\\'" . sh-mode))
  (add-to-list 'auto-mode-alist '("\\.zshenv\\'" . sh-mode))
  (add-to-list 'auto-mode-alist '("\\.zprofile\\'" . sh-mode))

  ;; Custom syntax highlighting for common zsh commands and constructs
  (font-lock-add-keywords
   'sh-mode
   '(("\\<\\(typeset\\|autoload\\|zmodload\\|zstyle\\|compdef\\)\\>"
      . font-lock-keyword-face)
     ("\\<\\(setopt\\|unsetopt\\)\\>"
      . font-lock-builtin-face))))

;; Shell execution environment
(use-package exec-path-from-shell
  :ensure t
  :init
  (when (memq window-system '(mac ns x))
    (exec-path-from-shell-initialize))
  ;; Copy important shell environment variables
  (exec-path-from-shell-copy-envs '("PATH" "MANPATH" "LANG" "LC_ALL")))

;; Terminal emulation with better zsh support
(use-package vterm
  :defer t
  :bind (("C-c v t" . vterm))
  :config
  ;; Better zsh integration
  (setq vterm-shell "/bin/zsh")
  (setq vterm-max-scrollback 10000)
  (setq vterm-keymap-exceptions '("C-x" "C-u" "C-g" "C-h" "C-l" "M-x" "M-o" "C-v" "M-v" "C-y" "M-y"
                                  "M-i" "M-j" "M-k" "M-l"))
  :bind (:map vterm-mode-map
              ("M-i" . windmove-up)
              ("M-j" . windmove-left)
              ("M-k" . windmove-down)
              ("M-l" . windmove-right)))


;; Shell command completion (specialized for zsh)
(use-package company-shell
  :ensure t
  :config
  (add-to-list 'company-backends 'company-shell)
  (add-to-list 'company-backends 'company-shell-env))


;; Function to launch zsh and execute given command
(defun run-zsh-command (command)
  "Run a zsh command in a new buffer."
  (interactive "sZsh command: ")
  (let ((buffer (generate-new-buffer "*zsh-command*")))
    (switch-to-buffer buffer)
    (insert (format "Running: %s\n\n" command))
    (start-process "zsh-command" buffer "zsh" "-c" command)
    (shell-mode)))

;; Key bindings for our zsh integration
(global-set-key (kbd "C-c z c") 'run-zsh-command)
(global-set-key (kbd "C-c z f") 'create-zsh-script)

;; Improved directory navigation with zsh
(defun zsh-find-file ()
  "Use zsh's advanced globbing to find files."
  (interactive)
  (let* ((pattern (read-string "Zsh file pattern: "))
         (command (format "find . -type f -name '%s' | sort" pattern))
         (result (shell-command-to-string command))
         (files (split-string result "\n" t))
         (selected (completing-read "Select file: " files nil t)))
    (when selected
      (find-file selected))))

(global-set-key (kbd "C-c z f") 'zsh-find-file)


;; Add zsh-mode custom keybindings
(defvar zsh-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-e") 'run-zsh-command)
    (define-key map (kbd "C-c C-c") 'zsh-process-csv)
    map)
  "Keymap for zsh-mode.")

(define-derived-mode zsh-mode sh-mode "ZSH"
  "Major mode for editing zsh scripts."
  :group 'sh
  (sh-set-shell "zsh"))

(provide 'zsh-mode)

;; Register zsh-mode for .zsh files
(add-to-list 'auto-mode-alist '("\\.zsh\\'" . zsh-mode))
(add-to-list 'interpreter-mode-alist '("zsh" . zsh-mode))


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
;; 10. MISC SETTINGS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; These settings enhance the overall Emacs experience
(setq-default
 v ad-redefinition-action 'accept                       ; Silence warnings for redefinition
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
;; 11. FINALIZATION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Custom file location
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

(provide 'config)
;;; config.el ends here
