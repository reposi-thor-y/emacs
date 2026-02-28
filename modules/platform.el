;;; platform.el --- Platform-specific configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Centralizes all platform-specific logic (macOS vs Linux, per-host settings).
;; Loaded first by init.el so other modules can use these variables.

;;; Code:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PLATFORM CONSTANTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defconst my/is-mac (eq system-type 'darwin)
  "Non-nil if running on macOS.")

(defconst my/is-linux (eq system-type 'gnu/linux)
  "Non-nil if running on Linux.")

(defconst my/hostname (system-name)
  "The hostname of the current machine.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; macOS MODIFIER KEYS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(when my/is-mac
  (setq mac-command-modifier 'control
        mac-option-modifier 'meta))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; HOMEBREW EXEC-PATH (macOS)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(when my/is-mac
  (let ((homebrew-prefix (if (file-directory-p "/opt/homebrew")
                             "/opt/homebrew"    ; Apple Silicon
                           "/usr/local")))      ; Intel
    (let ((brew-bin (concat homebrew-prefix "/bin"))
          (brew-sbin (concat homebrew-prefix "/sbin")))
      (unless (member brew-bin exec-path)
        (push brew-bin exec-path))
      (unless (member brew-sbin exec-path)
        (push brew-sbin exec-path))
      (setenv "PATH" (concat brew-bin ":" brew-sbin ":" (getenv "PATH"))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; FONT CONFIGURATION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar my/font-name
  (cond
   (my/is-mac "Source Code Pro")
   ((string-equal my/hostname "rocky-ws") "SauceCodePro NFM")
   (t "Source Code Pro"))
  "Font name for the default face.")

(defvar my/font-height
  (cond
   (my/is-mac 140)
   (t 120))
  "Font height for the default face (in 1/10pt units).")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; FRAME DIMENSIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar my/frame-width  (if my/is-mac 110 120) "Default frame width in columns.")
(defvar my/frame-height (if my/is-mac 55 60)   "Default frame height in lines.")
(defvar my/frame-left   (if my/is-mac 100 800) "Default frame left position in pixels.")
(defvar my/frame-top    30                      "Default frame top position in pixels.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; NATIVE COMPILATION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar my/native-comp-jobs (num-processors)
  "Number of parallel native compilation jobs.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; HELPER FUNCTIONS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun my/find-executable (name)
  "Find executable NAME, with Homebrew path fallback on macOS."
  (or (executable-find name)
      (when my/is-mac
        (let* ((homebrew-prefix (if (file-directory-p "/opt/homebrew")
                                    "/opt/homebrew"
                                  "/usr/local"))
               (brew-path (concat homebrew-prefix "/bin/" name)))
          (when (file-executable-p brew-path)
            brew-path)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'platform)
;;; platform.el ends here
