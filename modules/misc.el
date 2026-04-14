;;; misc.el --- Miscellaneous settings -*- lexical-binding: t; -*-

;;; Commentary:
;; Miscellaneous settings

;;; Code:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; MISCELLANEOUS SETTINGS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq-default
 ad-redefinition-action 'accept                       ; Silence warnings for redefinition
 cursor-in-non-selected-windows nil                    ; Hide the cursor in inactive windows
 display-time-default-load-average nil                ; Don't display load average
 help-window-select t                                 ; Focus new help windows when opened
 inhibit-startup-screen t                             ; Disable start-up screen
 initial-scratch-message ";; scratch\n"                ; Non-empty to avoid Emacs 30 display bug with line numbers on empty buffers
 save-interprogram-paste-before-kill t                ; Preserve system clipboard on kill
 kill-do-not-save-duplicates t                        ; No duplicate kill ring entries
 kill-ring-max 128                                    ; Maximum length of kill ring
 load-prefer-newer t                                  ; Prefer the newest version of a file
 mark-ring-max 128                                    ; Maximum length of mark ring
 read-process-output-max (* 4 1024 1024)              ; Increase the amount of data reads from the process (4MB)
 select-enable-clipboard t                            ; Merge system's and Emacs' clipboard
 user-full-name "Johan Thor"                          ; Set the full name of the current user
 vc-follow-symlinks t                                 ; Always follow the symlinks
 fast-but-imprecise-scrolling t                       ; More scrolling performance!
 view-read-only t                                     ; Always open read-only buffers in view-mode
 highlight-nonselected-windows nil                    ; Don't highlight in non-focused windows
 bidi-display-reordering 'left-to-right               ; Skip full bidi scanning (LTR only)
 bidi-paragraph-direction 'left-to-right              ; Skip bidi paragraph detection
 redisplay-skip-fontification-on-input t)             ; Defer fontification while typing
 ;; NOTE: scroll-conservatively is set to 101 by ultra-scroll in ui.el.
 ;; Do NOT set it to most-positive-fixnum — it causes display-line-numbers
 ;; to hide line 1 on near-empty buffers in Emacs 30.

;; Final UI tweaks
;; (global-hl-line-mode 1)                            ; Highlight current line
(setq bidi-inhibit-bpa t)                               ; Skip bidirectional parenthesis algorithm
(show-paren-mode 1)                                   ; Show matching parenthesis
(fset 'yes-or-no-p 'y-or-n-p)                         ; Replace yes/no prompts with y/n

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'misc)
;;; misc.el ends here
