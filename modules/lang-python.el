;;; lang-python.el --- Python configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Python configuration

;;; Code:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PYTHON CONFIGURATION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; 1. Basic Python settings
;; Set indentation level (Black uses 4 spaces)
(setq python-indent-offset 4)

;; Display inline images in Python shell (for matplotlib plots)
(add-hook 'inferior-python-mode-hook
          (lambda ()
            (setq-local comint-output-filter-functions
                        (cons 'comint-truncate-buffer comint-output-filter-functions))))

;;; 2. Python Environment Setup
(defun my/setup-python-environment ()
  "Set up Python environment with uv-aware detection.
Tries in order: uv (with pyproject.toml), .venv, system python."
  (let* ((uv (or (executable-find "uv") "~/.local/bin/uv"))
         (has-pyproject (locate-dominating-file default-directory "pyproject.toml"))
         (venv-python (when (project-current)
                        (expand-file-name ".venv/bin/python" (project-root (project-current)))))
         (python nil)
         (args ""))

    ;; Determine Python interpreter
    (cond
     ;; 1. Use uv if in a uv project
     ((and has-pyproject (file-executable-p (expand-file-name uv)))
      (setq python uv args "run python"))
     ;; 2. Use .venv if it exists
     ((and venv-python (file-exists-p venv-python))
      (setq python venv-python))
     ;; 3. Fall back to system Python
     (t
      (setq python (or (executable-find "python3") (executable-find "python") "python"))))

    ;; Configure Python shell
    (setq-local python-shell-interpreter python)
    (setq-local python-shell-interpreter-args args)
    (message "Python: %s %s" python (if (string-empty-p args) "" args))

    ;; Set VIRTUAL_ENV if .venv exists
    (when-let ((venv-dir (locate-dominating-file default-directory ".venv")))
      (setenv "VIRTUAL_ENV" (expand-file-name ".venv" venv-dir))
      (setq python-shell-virtualenv-root (expand-file-name ".venv" venv-dir)))))

(add-hook 'python-mode-hook #'my/setup-python-environment)

;;; 4. Project Management Integration
;; Add pyproject.toml as a project root indicator
(with-eval-after-load 'project
  (add-to-list 'project-find-functions
               (lambda (dir)
                 (when-let ((root (locate-dominating-file dir "pyproject.toml")))
                   (cons 'pyproject root))))

  ;; Define how to get the root from our custom project type
  (cl-defmethod project-root ((project (head pyproject)))
    (cdr project)))

;; UV command helpers with proper path handling
(defun my/uv-command ()
  "Get the uv command, checking multiple locations."
  (or (executable-find "uv")
      (let ((home-uv (expand-file-name "~/bin/uv")))
        (when (file-executable-p home-uv)
          home-uv))
      "uv"))

(defun my/uv-add-dependency ()
  "Add a dependency using uv."
  (interactive)
  (let ((dep (read-string "Dependency to add: "))
        (uv-cmd (my/uv-command)))
    (when (and dep (not (string-empty-p dep)))
      (compile (format "%s add %s" uv-cmd dep)))))

(defun my/uv-add-dev-dependency ()
  "Add a dev dependency using uv."
  (interactive)
  (let ((dep (read-string "Dev dependency to add: "))
        (uv-cmd (my/uv-command)))
    (when (and dep (not (string-empty-p dep)))
      (compile (format "%s add --dev %s" uv-cmd dep)))))

(defun my/uv-sync ()
  "Sync dependencies using uv."
  (interactive)
  (compile (format "%s sync" (my/uv-command))))

(defun my/uv-run-script ()
  "Run a script using uv run."
  (interactive)
  (let ((script (read-string "Script to run: " (buffer-file-name)))
        (uv-cmd (my/uv-command)))
    (when (and script (not (string-empty-p script)))
      (compile (format "%s run %s" uv-cmd script)))))

;; Additional keybindings for uv commands
(with-eval-after-load 'python
  (define-key python-mode-map (kbd "C-c u a") #'my/uv-add-dependency)
  (define-key python-mode-map (kbd "C-c u d") #'my/uv-add-dev-dependency)
  (define-key python-mode-map (kbd "C-c u s") #'my/uv-sync)
  (define-key python-mode-map (kbd "C-c u r") #'my/uv-run-script))

;;; 5. Visual Indentation Guides for Python
(use-package indent-bars
  :defer t
  :straight (indent-bars :type git :host github :repo "jdtsmith/indent-bars")
  :custom
  (indent-bars-treesit-support t)
  (indent-bars-no-descend-string t)
  (indent-bars-treesit-ignore-blank-lines-types '("module"))
  (indent-bars-treesit-wrap '((python argument_list parameters
                                      list list_comprehension
                                      dictionary dictionary_comprehension
                                      parenthesized_expression subscript)))
  :config
  (setq
   indent-bars-color '(highlight :face-bg t :blend 0.3)
   indent-bars-prefer-character 1
   indent-bars-width-frac 0.9
   indent-bars-pad-frac 0.2
   indent-bars-zigzag 0.1
   indent-bars-color-by-depth '(:palette ("red" "green" "orange" "cyan") :blend 1)
   indent-bars-highlight-current-depth '(:blend 0.5))
  :hook ((python-base-mode) . indent-bars-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'lang-python)
;;; lang-python.el ends here
