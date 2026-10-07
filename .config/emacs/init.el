;; Emacs starting configuration which recembles
;; my kitty config
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(set-fringe-mode 10)

(setq inhibit-startup-screen t)
(setq ring-bell-function 'ignore)
(setq visible-bell nil)

(global-display-line-numbers-mode 1)

(setq scroll-conservatively 101)
(setq scroll-margin 3)
(setq mouse-wheel-scroll-amount '(1 ((shift) . 1)))
(setq mouse-wheel-progressive-speed nil)

(set-face-attribute 'default nil
                    :font "FiraCode Nerd Font"
                    :height 120
                    :weight 'bold)


(set-frame-parameter (selected-frame) 'alpha-background 90)
(add-to-list 'default-frame-alist '(alpha-background . 90))

(set-face-attribute 'default nil
                    :foreground "#FFFFFF"
                    :background "#0A0A20")

(set-cursor-color "#FFFFFF")

(set-face-attribute 'region nil
                    :background "#80deea"
                    :foreground "#000000")

(set-face-attribute 'font-lock-comment-face nil :foreground "#607D8B")
(set-face-attribute 'font-lock-keyword-face nil :foreground "#FF4081")
(set-face-attribute 'font-lock-string-face nil :foreground "#4CAF50")
(set-face-attribute 'font-lock-function-name-face nil :foreground "#2196F3")
(set-face-attribute 'font-lock-variable-name-face nil :foreground "#FFEB3B")
(set-face-attribute 'font-lock-type-face nil :foreground "#9C27B0")

;; ---- Vertico (minibuffer completion)
(require 'vertico)
(vertico-mode 1)

;; ---- Orderless (fuzzy matching)
(require 'orderless)
(setq completion-styles '(orderless basic))

;; ---- Corfu (in-buffer completion)
(require 'corfu)
(global-corfu-mode 1)

(require 'evil)
(evil-mode 1)

(require 'projectile)
(projectile-mode 1)

(require 'treemacs)

(require 'doom-modeline)
(doom-modeline-mode 1)

(setq doom-modeline-height 25)
(setq doom-modeline-bar-width 4)
(setq doom-modeline-icon t)
(setq doom-modeline-major-mode-icon t)
(setq doom-modeline-buffer-file-name-style 'truncate-upto-root)
(setq doom-modeline-project-detection 'project)
(setq doom-modeline-vcs-max-length 20)
(setq doom-modeline-minor-modes nil)
(setq doom-modeline-enable-word-count t)

(setq-default header-line-format
              '(" "
                (:eval (getenv "USER"))
                "@"
                (:eval (system-name))
                "  |  "
                (:eval (when buffer-file-name
                         (abbreviate-file-name buffer-file-name)))
                "  |  "
                (:eval (when (vc-backend buffer-file-name)
                         (format "[%s]" (vc-working-revision buffer-file-name))))
                ))

(require 'dashboard)
(dashboard-setup-startup-hook)

(setq dashboard-banner-logo-title " Welcome back")
(setq dashboard-center-content t)
(setq dashboard-set-heading-icons t)
(setq dashboard-set-file-icons t)
(setq dashboard-items '((recents  . 5)
                        (projects . 5)))

(require 'nerd-icons)

(require 'nerd-icons-dired)
(add-hook 'dired-mode-hook #'nerd-icons-dired-mode)

(require 'nerd-icons-completion)
(nerd-icons-completion-mode 1)

(setq treesit-auto-install 'prompt)

(setq-default tab-width 2)
(setq-default indent-tabs-mode nil)

;; (load-theme 'doom-one t)
