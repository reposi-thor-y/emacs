;;; misc.el --- Miscellaneous settings -*- lexical-binding: t; -*-

;;; Commentary:
;; Miscellaneous settings

;;; Code:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; MISCELLANEOUS SETTINGS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; These settings enhance the overall Emacs experience
(setq-default
 ad-redefinition-action 'accept                       ; Silence warnings for redefinition uv-ruff-migration
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
;; (global-hl-line-mode 1)                            ; Highlight current line
(show-paren-mode 1)                                   ; Show matching parenthesis
(fset 'yes-or-no-p 'y-or-n-p)                         ; Replace yes/no prompts with y/n

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'misc)
;;; misc.el ends here
