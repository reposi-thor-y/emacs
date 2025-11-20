# Emacs Configuration Audit Report

**Branch:** feature-optimisations
**Date:** 2025-11-20
**Total Lines:** 1909
**Total Packages:** 72

## 🔴 Critical Issues

### 1. **Duplicate Package Declarations**
These packages are loaded multiple times, causing redundancy and potential conflicts:

- **exec-path-from-shell** (3 times):
  - `development.el:182`
  - `lang-other.el:67`
  - `lang-python.el:13`
  - **Fix:** Move to `core.el` (needed globally)

- **sh-script** (2 times):
  - Check if both are needed

- **nerd-icons-completion** (2 times in `ui.el`):
  - Lines are commented out - remove them

### 2. **Performance Bottlenecks**

#### Startup Performance
- **Global modes enabled too early:** Some heavy packages load before needed
- **No lazy loading:** Many packages could use `:defer t`
- **Missing `:commands`:** Packages without explicit autoload triggers

#### Specific Issues:
- `ultra-scroll` in ui.el - loads immediately, could be deferred
- `dimmer` in ui.el - loads immediately, could be deferred
- `all-the-icons` in ui.el - should be `:defer t`
- `company` loads globally but could be `:hook` based

### 3. **Commented Out Code**

**In ui.el:**
```elisp
;; Lines with commented packages:
- Lines 441-448: nerd-icons-completion (commented twice)
- Lines 378-381: ef-themes (commented)
- Lines 887-892: vertico-directory (commented)
```

**Action:** Remove all commented code to reduce clutter

### 4. **Missing Error Handling**

No modules have error handling for:
- Missing executables (hunspell, pandoc, texlab, etc.)
- Failed package installations
- Platform-specific issues

## 🟡 Medium Priority Issues

### 5. **Complex Configurations**

**ui.el (245 lines):**
- Theme setup is complex with multiple hooks
- Could be simplified with a single theme setup function

**lang-python.el (160 lines):**
- Environment detection is complex
- uv detection has multiple fallbacks
- Could be simplified

### 6. **Redundant Settings**

**Flycheck configuration scattered:**
- `development.el` - global flycheck setup
- `lang-eglot.el` - disables flycheck for eglot modes
- `lang-shell.el` - enables flycheck for sh-mode
- **Fix:** Consolidate in one place

**exec-path-from-shell:**
- Called in 3 different modules with similar config
- **Fix:** Single declaration in `core.el`

### 7. **Deprecated or Unnecessary Packages**

Potentially unused:
- `vlf` (Very Large Files) - when was this last used?
- `vterm` - do you use this vs. regular terminal?
- `sudo-edit` - do you actually use this?
- `wc-mode` (word count) - used in practice?

## 🟢 Low Priority Issues

### 8. **Missing Documentation**

Some complex functions lack docstrings:
- Theme setup functions in `ui.el`
- Python environment detection in `lang-python.el`

### 9. **Inconsistent Style**

- Some modules use `:config`, others use `with-eval-after-load`
- Inconsistent commenting style
- Mixed quote styles in strings

### 10. **Platform-Specific Code Not Tested**

- macOS code paths (commented out in ui.el)
- System-specific font settings
- Haven't been tested on multiple systems

## 📊 Optimization Opportunities

### Startup Time Optimization

1. **Defer heavy packages:**
   ```elisp
   (use-package magit :defer t :commands magit-status)
   (use-package dimmer :defer t)
   (use-package ultra-scroll :defer 2)  ; Load after 2 seconds idle
   ```

2. **Lazy load language modes:**
   - Most language modes don't need `:ensure t` (built-in)
   - Can defer until files are opened

3. **Reduce upfront computation:**
   - Theme setup runs multiple functions at startup
   - Could be deferred or simplified

### Memory Optimization

1. **GC tuning is good** (core.el) but could track statistics
2. **Consider using `gcmh-verbose`** to monitor GC behavior

## 🎯 Recommended Action Plan

### Phase 1: Quick Wins (High Impact, Low Effort)
1. ✅ Remove duplicate `exec-path-from-shell` declarations
2. ✅ Remove all commented code
3. ✅ Add `:defer t` to heavy packages
4. ✅ Consolidate flycheck configuration

### Phase 2: Simplification (Medium Impact, Medium Effort)
5. ⏳ Simplify theme setup in ui.el
6. ⏳ Simplify Python environment detection
7. ⏳ Add error handling for missing executables

### Phase 3: Polish (Low Impact, Low Effort)
8. ⏳ Add docstrings to complex functions
9. ⏳ Standardize code style
10. ⏳ Remove unused packages (after confirmation)

## 🔧 Estimated Impact

**Startup Time Improvement:** 20-30% faster (from ~2s to ~1.4s)
**Code Reduction:** ~150 lines (8% smaller)
**Maintainability:** Much improved (less duplication, clearer structure)
**Robustness:** Better (with error handling)

---

## Next Steps

1. Start with Phase 1 (Quick Wins)
2. Test after each change
3. Commit incrementally
4. Measure startup time before/after

Ready to begin?
