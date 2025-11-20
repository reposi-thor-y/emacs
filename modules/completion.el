;;; completion.el --- Completion frameworks -*- lexical-binding: t; -*-

;;; Commentary:
;; Completion frameworks

;;; Code:

;; 7. COMPLETION FRAMEWORK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Vertico for vertical completion UI
(use-package vertico
  :ensure t
  :init
  (vertico-mode)
  :bind (:map vertico-map
                                        ;              ("C-<backspace>" . vertico-directory-delete-char)
              ("C-<return>" . vertico-exit-input)
                                        ;             ("RET" . vertico-directory-enter)
              ("C-n" . vertico-next)
              ("C-p" . vertico-previous)
              ("TAB" . vertico-insert))
  :bind (:map minibuffer-local-map
              ("TAB" . vertico-insert))
  :custom
  (vertico-cycle t)
  (vertico-preselect 'prompt)
  (vertico-count 20)
  (vertico-resize t)
  (vertico-multiform-commands
   '((consult-line buffer)
     (consult-imenu buffer)
     (consult-ripgrep buffer)))
  :config

  ;; ;; Load the vertico directory extension
  ;; (use-package vertico-directory
  ;;   :ensure nil ;; Part of vertico
  ;;   :after vertico
  ;;   :load-path "straight/build/vertico/extensions"
  ;;   :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

  (setq vertico-count-format nil)
  :custom-face
  (vertico-current ((t (:background "#1d1f21")))))

;; Orderless for flexible matching
(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic partial-completion))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles orderless basic partial-completion))))
  (completion-ignore-case t)
  (read-file-name-completion-ignore-case t)
  (read-buffer-completion-ignore-case t))

;; Consult for enhanced commands

(use-package consult
  :ensure t
  :bind (;; Keep standard find-file but enhance it through completion framework
         ("C-x b" . consult-buffer)       ;; Replace switch-to-buffer
         ("C-c l" . consult-line)         ;; Search in current buffer
         ("C-c f d" . consult-find)       ;; Add find as a separate command
         ("C-c f g" . consult-ripgrep))   ;; Add ripgrep search
  :config
  (setq consult-find-command "find . -type f -not -path \"*/\\.git/*\" -not -path \"*/node_modules/*\" -not -path \"*/build/*\"")
  (setq consult-project-function #'consult--default-project-function))


;; Marginalia for rich annotations
(use-package marginalia
  :ensure t
  :after vertico
  :init (marginalia-mode)
  :custom
  (marginalia-annotators '(marginalia-annotators-heavy
                           marginalia-annotators-light
                           nil))
  :bind (:map minibuffer-local-map
              ("M-A" . marginalia-cycle)))

;; Prescient for better sorting
(use-package prescient
  :ensure t
  :config
  (prescient-persist-mode +1))

(use-package vertico-prescient
  :ensure t
  :after (vertico prescient)
  :config
  (vertico-prescient-mode +1))

;; Custom function for zsh-like completion
(defun my/zsh-like-completion ()
  "Complete like zsh - complete until ambiguity."
  (interactive)
  (let ((completion-styles '(basic partial-completion))
        (completion-category-overrides nil)
        (completion-cycle-threshold nil))
    (minibuffer-complete)))

;; Enhanced Tab completion for Vertico
(defun my/vertico-tab ()
  "Smart tab in Vertico: complete common prefix or select current candidate."
  (interactive)
  (if (= vertico--index -1)
      ;; No candidate selected - complete common prefix
      (my/zsh-like-completion)
    ;; Candidate is selected - accept it
    (vertico-exit)))

;; Global completion settings
(setq completion-styles '(basic partial-completion orderless)
      completion-category-defaults nil
      completion-category-overrides '((file (styles . (basic partial-completion))))
      completion-ignore-case t)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'completion)
;;; completion.el ends here
