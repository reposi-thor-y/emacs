;;; init.el --- GNU Emacs Bootstrap Configuration

;;; Commentary:
;; This is a minimal bootstrap file that loads the main configuration
;; from config.el, optimized for faster startup and better organization.

;;; Code:

;; Measure startup time
(add-hook 'emacs-startup-hook
          (lambda ()
            (message "Emacs loaded in %s seconds with %d garbage collections."
                     (emacs-init-time)
                     gcs-done)))

;; Make startup faster by reducing the frequency of garbage collection
(setq gc-cons-threshold (* 100 1024 1024))  ;; 100MB


;; Disable startup screen
(setq inhibit-startup-screen t)
(setq inhibit-splash-screen t)
(setq initial-scratch-message "")


;; Set default directory
;; (setq default-directory "~/")

;; Create custom file
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

;; Load main configuration file
(if (file-exists-p (expand-file-name "config.el" user-emacs-directory))
    (load-file (expand-file-name "config.el" user-emacs-directory))
  (if (file-exists-p (expand-file-name "config.org" user-emacs-directory))
      (org-babel-load-file (expand-file-name "config.org" user-emacs-directory))
    (message "Neither config.el nor config.org found. Using minimal configuration.")))

;; Load custom file if it exists
(when (file-exists-p custom-file)
  (load-file custom-file))

;; Reset garbage collection threshold to a reasonable value for regular use
(setq gc-cons-threshold (* 2 1024 1024))  ;; 2MB

(provide 'init)
;;; init.el ends here
