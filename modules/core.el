;;; core.el --- Core Emacs configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Startup optimizations and essential settings

;;; Code:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PACKAGE MANAGEMENT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Set repositories to use
(setq package-archives '(("elpa" . "https://elpa.gnu.org/packages/")
                         ("melpa" . "https://melpa.org/packages/")))

;; Bootstrap straight.el
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        (or (bound-and-true-p straight-base-dir)
            user-emacs-directory)))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; Use straight.el for package management
(straight-use-package 'use-package)
(setq straight-use-package-by-default t)
(setq straight-check-for-modifications '(find-when-checking))

;; Ensure PATH is inherited from shell (needed for GUI Emacs)
(use-package exec-path-from-shell
  :ensure t
  :demand t  ;; Load immediately
  :config
  (when (or (memq window-system '(mac ns x pclone))
            (daemonp))
    (exec-path-from-shell-initialize)
    ;; Copy important shell environment variables
    (exec-path-from-shell-copy-envs '("PATH" "MANPATH" "LANG" "LC_ALL"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PERFORMANCE OPTIMIZATIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
  (setq native-comp-async-jobs-number my/native-comp-jobs)

  ;; Set up a dedicated native compilation cache directory
  (when (boundp 'comp-eln-load-path)
    (let ((eln-cache-dir (expand-file-name "eln-cache/" user-emacs-directory)))
      (add-to-list 'comp-eln-load-path eln-cache-dir)
      (setq native-comp-eln-load-path
            (list (expand-file-name "eln-cache/" user-emacs-directory))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ESSENTIAL SETTINGS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Encoding
(set-charset-priority 'unicode)
(prefer-coding-system 'utf-8-unix)
(set-default-coding-systems 'utf-8)

;; Line numbers with fixed width
(setq-default display-line-numbers-width-start t)
(global-display-line-numbers-mode t)

;; Center buffer mode
(use-package centered-cursor-mode
  :ensure t
  :bind ("C-c l" . centered-cursor-mode))

;; Backup and autosave
(setq make-backup-files nil
      auto-save-default nil
      create-lockfiles nil)

;; Auto-revert buffers when files change on disk (e.g. from external tools)
(global-auto-revert-mode 1)
(setq auto-revert-use-notify t)
(setq auto-revert-verbose nil)

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
(bind-key "C-z" #'undo)

;; Edit config file quickly
(defun open-init-file ()
  "Open the init file."
  (interactive)
  (find-file (expand-file-name "init.el" user-emacs-directory)))
(bind-key "C-c E" #'open-init-file)  ;; Changed to capital E to avoid conflict with elisp eval prefix

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; EDITING UTILITIES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
        (skip-indent-modes '(conf-mode ini-mode markdown-mode gfm-mode)))

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'core)
;;; core.el ends here
