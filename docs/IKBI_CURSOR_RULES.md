# IKBI Cursor Rules

These are the **IKBI Dev Guardrails** for building safe, scalable, and production-ready apps in Cursor.

---

## 🔒 Safety & Stability
1. **Never perform destructive actions** like `db reset`, `supabase db reset`, or deleting tables without explicit confirmation.  
2. **No “temporary” hacks** – every solution must be production-grade or clearly flagged as experimental.  
3. **Always keep migrations** under version control (`.migrations/`), never apply schema changes without recording them.  
4. **Never auto-generate secrets** or commit `.env` values. Use `.env.example` for reference only.  
5. **Don’t bypass authentication or RLS**. Every query must respect Supabase Row-Level Security rules.

---

## 🎨 Architecture & Consistency
6. **Always use the App Theme** (TradeTrackTheme, imrTheme, etc.) – no inline colors, fonts, or ad-hoc styles.  
7. **Respect folder structure & clean architecture**:
   - `features/` for domain modules  
   - `widgets/` for reusable UI  
   - `controllers/` or `notifiers/` for state  
   - `repositories/` for Supabase access  
8. **No mixing of concerns** – UI should never call Supabase directly.  
9. **Always use Riverpod** (StateNotifier/AsyncNotifier) for state, never `setState` in production code.  
10. **All new screens must be responsive** (web + mobile) and follow Material 3 / theme guidelines.

---

## 📦 Code Quality
11. **Centralize constants** (colors, text styles, padding, enums) – no “magic strings” or duplicate definitions.  
12. **Every new widget must be reusable** if possible – don’t duplicate similar UI.  
13. **Linting must pass** (use `flutter analyze` / `dart fix`) before committing.  
14. **Every model must have fromJson/toJson** – no half-complete data classes.  
15. **Naming must be descriptive** – avoid generic names like `data`, `temp`, `test`.  

---

## 🔗 Supabase & Firebase
16. **All Supabase queries must use typed models** – no raw map handling scattered in UI.  
17. **Always implement error handling** (`try/catch`) and show proper user feedback via snackbars/dialogs.  
18. **No hardcoded user IDs or emails** – always fetch from `auth.currentUser`.  
19. **Never expose storage URLs without signed policies** (unless intended public).  
20. **Edge Functions must be version-controlled** – no inline quick patches.  

---

## 🚀 Development Workflow
21. **Every feature must be incremental** – finish one flow completely before starting another.  
22. **No unused files** – delete stale code/widgets immediately.  
23. **Always write commit messages with context** (e.g., “feat: add ClientOverviewScreen with inline editing”).  
24. **Run the app after every major refactor** to confirm stability before proceeding.  
25. **Do not bypass CI/CD checks** – fix, don’t ignore.

---

## ⚡️ Optional Extras
- **Testing**: Require widget tests or state tests for core flows.  
- **Docs**: Add/update `README` or `ARCHITECTURE.md` when changing structure.  
- **Review**: AI-generated code must be reviewed line by line before merging.  

---
