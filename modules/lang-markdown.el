;;; lang-markdown.el --- Markdown configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Markdown configuration

;;; Code:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; MARKDOWN CONFIGURATION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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
    (setq markdown-command "/usr/bin/pandoc"))))

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'lang-markdown)
;;; lang-markdown.el ends here
