# Emacs Configuration Modules

This directory contains the modular Emacs configuration.

**Version:** 2.0 (Optimized & Simplified)
**Last Updated:** 2025-11-20
**Branch:** feature-optimisations

## Module Structure

| Module | Description | Key Features | Lines |
|--------|-------------|--------------|-------|
| `core.el` | Core settings and package management | straight.el, performance optimizations, essential settings | 274 |
| `error-handling.el` | **NEW** Error handling | Checks for missing executables, helpful warnings | 68 |
| `ui.el` | UI and appearance | Themes, fonts, mode line, spell checking | 241 |
| `completion.el` | Completion frameworks | Vertico, Company, Consult, Orderless, Marginalia | 124 |
| `editing.el` | Editing enhancements | Multiple cursors, which-key, helpful | 109 |
| `development.el` | Development tools | Flycheck, Magit, Projectile, yasnippet | 160 |
| `lang-eglot.el` | Eglot LSP configuration | Language server setup for all languages | 83 |
| `lang-python.el` | Python configuration | uv integration, Python environment detection | 138 |
| `lang-elisp.el` | **NEW** Emacs Lisp configuration | Smartparens, macrostep, EROS, evaluation tools | 166 |
| `lang-cpp.el` | C++ configuration | Clang format, compilation settings | 79 |
| `lang-shell.el` | Shell script configuration | Bash and Zsh mode setup | 32 |
| `lang-latex.el` | LaTeX configuration | AUCTeX, PDF tools, RefTeX | 142 |
| `lang-markdown.el` | Markdown configuration | Markdown mode, Pandoc integration | 54 |
| `lang-other.el` | Other file formats | YAML, JSON, web modes | 176 |
| `misc.el` | Miscellaneous settings | Final tweaks and settings | 37 |
| **Total** | **14 modules** | - | **1,883** |

## Loading Order

Modules are loaded in dependency order by `init.el`:

```elisp
(require 'core)           ;; Must be first (package management)
(require 'ui)             ;; UI setup
(require 'completion)     ;; Completion frameworks
(require 'editing)        ;; Editing tools
(require 'development)    ;; Dev tools
(require 'lang-eglot)     ;; LSP base (before language modules)
(require 'lang-python)    ;; Language-specific configs
(require 'lang-cpp)
(require 'lang-shell)
(require 'lang-latex)
(require 'lang-markdown)
(require 'lang-other)
(require 'misc)           ;; Final settings
```

## Editing Modules

Each module is a self-contained Emacs Lisp file with:
- Proper file headers with `lexical-binding: t`
- Commentary section describing the module
- `(provide 'module-name)` at the end

To edit a specific area of configuration, simply open the relevant module file.

## Adding New Modules

To add a new module:

1. Create `~/.emacs.d/modules/your-module.el`
2. Add proper headers:
```elisp
;;; your-module.el --- Description -*- lexical-binding: t; -*-

;;; Commentary:
;; Your description here

;;; Code:

;; Your configuration here

(provide 'your-module)
;;; your-module.el ends here
```
3. Add `(require 'your-module)` to `init.el` in the appropriate order

## Backup

The original monolithic configuration is backed up as:
- `config.el.backup-YYYYMMDD-HHMMSS`

## Dependencies

Some modules depend on others:
- All language modules depend on `lang-eglot.el`
- `development.el` provides tools used by language modules
- `completion.el` requires `ui.el` for proper theme integration

## Maintenance

To disable a module temporarily, comment out its `(require ...)` line in `init.el`.
To permanently remove a module, delete both the file and the require statement.
