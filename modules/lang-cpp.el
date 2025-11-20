;;; lang-cpp.el --- C++ configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; C++ configuration

;;; Code:

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

;; --- Compilation settings ---
(setq compile-command "cmake -B build -G Ninja && cmake --build build")
(global-set-key (kbd "C-c C-c") 'compile)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'lang-cpp)
;;; lang-cpp.el ends here
