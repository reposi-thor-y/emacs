;; init.el --- GNU Emacs Configuration

;; Commentary:

;; Following lines build the configuration code out of the config.el file.

;; Code:

;; Make startup faster by reducing the frequency of garbage
;; collection.
(setq gc-cons-threshold (* 100 1024 1024))
(setq default-directory "~/")

(if (file-exists-p (expand-file-name "config.el" user-emacs-directory))
    (load-file (expand-file-name "config.el" user-emacs-directory))
  (org-babel-load-file (expand-file-name "config.org" user-emacs-directory)))

;; init.el ends here
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(blink-cursor-mode nil)
 '(menu-bar-mode nil)
 '(package-vc-selected-packages
   '((ultra-scroll :vc-backend Git :url "https://github.com/jdtsmith/ultra-scroll")))
 '(scroll-bar-mode nil)
 '(tool-bar-mode nil)
 '(tooltip-mode nil)
 '(warning-suppress-types '((use-package))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(font-lock-comment-face ((t (:foreground "gray60")))))
