;;; mail.el --- Email configuration with mu4e -*- lexical-binding: t; -*-

;;; Commentary:
;; mu4e configuration for iCloud Mail via mbsync

;;; Code:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; MU4E
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package mu4e
  :straight nil
  :commands (mu4e mu4e-compose-new)
  :bind (("C-c m" . mu4e)
         ("C-c M" . my/mu4e-jump-to-inbox))
  :custom
  ;; General
  (mu4e-confirm-quit nil)
  (mu4e-change-filenames-when-moving t)

  ;; Sync (also pull contacts from Nextcloud via vdirsyncer)
  (mu4e-get-mail-command "vdirsyncer sync 2>/dev/null; mbsync -a")
  (mu4e-update-interval 300)

  ;; Maildir paths (iCloud folder names)
  (mu4e-maildir "~/Mail")
  (mu4e-drafts-folder "/icloud/Drafts")
  (mu4e-sent-folder "/icloud/Sent Messages")
  (mu4e-trash-folder "/icloud/Deleted Messages")
  (mu4e-refile-folder "/icloud/Archive")

  ;; Display
  (mu4e-split-view 'horizontal)
  (mu4e-headers-visible-lines 20)
  (mu4e-view-prefer-html nil)
  (mm-discouraged-alternatives '("text/html" "text/richtext"))
  (shr-use-colors nil)

  ;; Compose
  (mu4e-compose-dont-reply-to-self t)
  (mu4e-compose-format-flowed t)
  (user-mail-address "johanthor@icloud.com")
  (user-full-name "Johan Thor")

  :config
  (defun my/mu4e-jump-to-inbox ()
    "Jump directly to iCloud inbox."
    (interactive)
    (mu4e-search "maildir:/icloud/Inbox"))

  ;; Bookmarks
  (setq mu4e-bookmarks
        '((:name "Unread" :query "flag:unread AND NOT flag:trashed" :key ?u)
          (:name "Today" :query "date:today..now" :key ?t)
          (:name "Week" :query "date:7d..now" :key ?w)
          (:name "Inbox" :query "maildir:/icloud/Inbox" :key ?i)))

  ;; Auto-sign outgoing mail with PGP/MIME
  (add-hook 'mu4e-compose-mode-hook #'mml-secure-message-sign-pgpmime)

  ;; Headers
  (setq mu4e-headers-fields
        '((:human-date . 12)
          (:flags      .  6)
          (:from       . 22)
          (:subject    . nil)))

  ;; Show images inline
  (setq mu4e-view-show-images t)

  ;; Use xdg-open for attachments
  (setq mu4e-view-actions
        '(("capture message" . mu4e-action-capture-message)
          ("view in browser" . mu4e-action-view-in-browser))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; KHARD CONTACTS → MU4E AUTOCOMPLETION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun my/mu4e-add-khard-contacts (&rest _)
  "Inject khard contacts into `mu4e--contacts-set' for autocompletion."
  (when (and (executable-find "khard")
             (hash-table-p mu4e--contacts-set))
    (let ((output (shell-command-to-string "khard email --parsable --search-in-source-files 2>/dev/null")))
      (dolist (line (split-string output "\n" t))
        (let ((fields (split-string line "\t")))
          (when (>= (length fields) 2)
            (let ((email (nth 0 fields))
                  (name (nth 1 fields)))
              (puthash (if (string-empty-p name)
                           email
                         (format "%s <%s>" name email))
                       t mu4e--contacts-set))))))))

(with-eval-after-load 'mu4e
  (advice-add 'mu4e--update-contacts :after #'my/mu4e-add-khard-contacts))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SMTP (SENDING)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(use-package smtpmail
  :straight nil
  :custom
  (message-send-mail-function #'smtpmail-send-it)
  (smtpmail-smtp-server "smtp.mail.me.com")
  (smtpmail-smtp-service 587)
  (smtpmail-stream-type 'starttls)
  (smtpmail-smtp-user "johanthor@icloud.com"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'mail)
;;; mail.el ends here
