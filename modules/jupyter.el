;;; jupyter.el --- Juoyter for Emacs configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Installation and configuration

;;; Code:
;; Fix org for straight.el
(straight-use-package '(org :type built-in))

;; Deps with corrected simple-httpd recipe
(straight-use-package
 '(simple-httpd :type git
                :host github
                :repo "skeeto/emacs-web-server"
                :local-repo "simple-httpd-skeeto"
                :files ("simple-httpd.el")))
(straight-use-package 'websocket)
(straight-use-package 'zmq)

;; Jupyter
(use-package jupyter
  :straight t
  :demand t
  :after org
  :config
  (require 'ob-jupyter)
  (org-babel-do-load-languages
   'org-babel-load-languages
   (append org-babel-load-languages
           '((jupyter . t))))
  (setq org-babel-default-header-args:jupyter-python
        '((:session . "py")
          (:kernel . "python3")
          (:async . "yes")))
  (add-hook 'org-babel-after-execute-hook 'org-display-inline-images))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'jupyter)
;;; jupyter.el ends here
