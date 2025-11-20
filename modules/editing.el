;;; editing.el --- Editing enhancements and general functionality -*- lexical-binding: t; -*-

;;; Commentary:
;; Editing enhancements and general functionality

;;; Code:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GENERAL FUNCTIONALITY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'editing)
;;; editing.el ends here
