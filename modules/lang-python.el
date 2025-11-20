;;; lang-python.el --- Python configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Python configuration

;;; Code:

;; 9.1 PYTHON
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; 0. Ensure PATH includes ~/.local/bin (for uv)
;; This fixes the issue where GUI-launched Emacs doesn't inherit shell PATH
(use-package exec-path-from-shell
  :ensure t
  :config
  (when (memq window-system '(x pclone))
    (exec-path-from-shell-initialize)))

;;; 1. Basic Python settings
;; Set indentation level (Black uses 4 spaces)
(setq python-indent-offset 4)

;; Display inline images in Python shell (for matplotlib plots)
(add-hook 'inferior-python-mode-hook
          (lambda ()
            (setq-local comint-output-filter-functions
                        (cons 'comint-truncate-buffer comint-output-filter-functions))))

;;; 2. Python Environment Detection
(defun my/find-python-executable ()
  "Find the appropriate Python executable, preferring uv environments.
Returns a cons cell (INTERPRETER . ARGS) or just INTERPRETER string."
  (let ((uv-path (or (executable-find "uv")
                     (expand-file-name "~/.local/bin/uv"))))
    (cond
     ;; If we're in a project with pyproject.toml and uv is available
     ((and (locate-dominating-file default-directory "pyproject.toml")
           (file-executable-p uv-path))
      (cons uv-path '("run" "python")))
     ;; If .venv exists in project, use it directly
     ((and (project-current)
           (file-exists-p (expand-file-name ".venv/bin/python"
                                            (project-root (project-current)))))
      (expand-file-name ".venv/bin/python" (project-root (project-current))))
     ;; Fall back to system python
     (t (or (executable-find "python3") (executable-find "python"))))))


;;; 3. Python Environment Setup for uv
;; Auto-detect .venv in project root and configure Python shell
(defun my/setup-python-environment ()
  "Set up Python environment with uv-aware detection for Python shell."
  (let ((python-executable (my/find-python-executable)))
    (when python-executable
      (if (consp python-executable)
          ;; If it's a cons cell (command . args), set both interpreter and args
          (progn
            (setq-local python-shell-interpreter (car python-executable))
            (setq-local python-shell-interpreter-args
                        (mapconcat 'identity (cdr python-executable) " "))
            (message "Using Python: %s %s"
                     (car python-executable)
                     (mapconcat 'identity (cdr python-executable) " ")))
        ;; If it's just a string, set only the interpreter
        (progn
          (setq-local python-shell-interpreter python-executable)
          (setq-local python-shell-interpreter-args "")
          (message "Using Python: %s" python-executable)))))
  ;; Also set VIRTUAL_ENV if .venv exists
  (when-let ((venv-dir (locate-dominating-file default-directory ".venv")))
    (setenv "VIRTUAL_ENV" (expand-file-name ".venv" venv-dir))
    (setq python-shell-virtualenv-root (expand-file-name ".venv" venv-dir))))

;; Add hook to setup Python environment
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'lang-python)
;;; lang-python.el ends here
