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
  (when-let ((pandoc (my/find-executable "pandoc")))
    (setq markdown-command pandoc))
  :config
  ;; Enable language-specific syntax highlighting in fenced code blocks
  (setq markdown-fontify-code-blocks-natively t))

(use-package markdown-preview-mode
  :defer t
  :after markdown-mode)


;; auto-fill-mode wraps lines at fill-column as you type.
;; After editing mid-paragraph, use M-q to refill.
(add-hook 'markdown-mode-hook #'auto-fill-mode)

(defun markdown-export-pdf ()
  "Export the current Markdown file to PDF using Pandoc."
  (interactive)
  (let* ((input-file (buffer-file-name))
         (output-file (concat (file-name-sans-extension input-file) ".pdf"))
         (pdf-engine (if my/is-mac "tectonic" "xelatex"))
         (error-buf (get-buffer-create "*pandoc-errors*"))
         (exit-code (progn
                      (with-current-buffer error-buf (erase-buffer))
                      (call-process "pandoc" nil error-buf nil
                                    input-file
                                    "-o" output-file
                                    (concat "--pdf-engine=" pdf-engine)
                                    "-V" "geometry:margin=1in"))))
    (if (= exit-code 0)
        (message "Exported to %s" output-file)
      (display-buffer error-buf)
      (message "PDF export failed (exit %d) — see *pandoc-errors*" exit-code))))

;; Markdownlint via Flymake (works alongside Eglot/marksman)
;; markdownlint writes to stderr, so we shell-wrap with 2>&1 to capture output.
;; The backend must be re-added after Eglot connects (depth 95) since Eglot
;; resets flymake-diagnostic-functions when it takes over.

(defvar-local my/flymake-markdownlint--proc nil
  "Running markdownlint process for the current buffer.")

(defun my/flymake-markdownlint--parse (source report-fn)
  "Parse markdownlint output in current buffer for SOURCE, call REPORT-FN."
  (goto-char (point-min))
  (let (diags)
    (while (search-forward-regexp
            "^stdin:\\([0-9]+\\)\\(?::\\([0-9]*\\)\\)? \\([a-z]+\\) \\(MD[0-9]+/[^ ]+\\) \\(.*\\)$"
            nil t)
      (let* ((line (string-to-number (match-string 1)))
             (col (if (and (match-string 2) (not (string-empty-p (match-string 2))))
                      (string-to-number (match-string 2))
                    1))
             (type (if (string= (match-string 3) "error") :error :warning))
             (msg (format "%s: %s" (match-string 4) (match-string 5))))
        (with-current-buffer source
          (save-excursion
            (widen)
            (goto-char (point-min))
            (forward-line (1- line))
            (push (flymake-make-diagnostic
                   source
                   (+ (line-beginning-position) (1- col))
                   (line-end-position)
                   type msg)
                  diags)))))
    (funcall report-fn (nreverse diags))))

(defun my/flymake-markdownlint (report-fn &rest _args)
  "Flymake backend for markdownlint.
REPORT-FN is the reporting function provided by Flymake."
  (when (process-live-p my/flymake-markdownlint--proc)
    (kill-process my/flymake-markdownlint--proc))
  (let ((source (current-buffer))
        (mdl (executable-find "markdownlint"))
        (buf (generate-new-buffer " *flymake-markdownlint*")))
    (save-restriction
      (widen)
      (setq my/flymake-markdownlint--proc
            (make-process
             :name "flymake-markdownlint"
             :noquery t
             :connection-type 'pipe
             :buffer buf
             :command (list shell-file-name shell-command-switch
                           (format "%s --stdin 2>&1" (shell-quote-argument mdl)))
             :sentinel
             (lambda (proc _event)
               (when (memq (process-status proc) '(exit signal))
                 (unwind-protect
                     (if (with-current-buffer source
                           (eq proc my/flymake-markdownlint--proc))
                         (with-current-buffer (process-buffer proc)
                           (my/flymake-markdownlint--parse source report-fn))
                       (flymake-log :warning "Canceling obsolete markdownlint check"))
                   (kill-buffer (process-buffer proc)))))))
      (process-send-region my/flymake-markdownlint--proc (point-min) (point-max))
      (process-send-eof my/flymake-markdownlint--proc))))

(defun my/flymake-markdownlint-setup ()
  "Add markdownlint to Flymake backends for the current buffer."
  (when (executable-find "markdownlint")
    (add-hook 'flymake-diagnostic-functions #'my/flymake-markdownlint nil t)))

(add-hook 'markdown-mode-hook #'my/flymake-markdownlint-setup)

;; Re-add after Eglot connects (it resets flymake-diagnostic-functions)
(add-hook 'eglot-managed-mode-hook
          (lambda ()
            (when (derived-mode-p 'markdown-mode)
              (my/flymake-markdownlint-setup)
              (flymake-start)))
          95)

;; Prettier disabled for markdown — it joins consecutive lines within
;; a paragraph, breaking our hard-wrapped lines and triggering MD013.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'lang-markdown)
;;; lang-markdown.el ends here
