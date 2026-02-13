# Vercel URL Configuration

The app is now hosted at **https://choice-lux-cars-app.vercel.app**

## Supabase Dashboard (Required)

Update your **production** Supabase project's URL configuration:

1. Go to [Supabase Dashboard](https://supabase.com/dashboard) → your project
2. **Authentication** → **URL Configuration**
3. Update:

| Setting | Old Value | New Value |
|---------|-----------|-----------|
| **Site URL** | `https://choice-lux-cars-8d510.web.app` | `https://choice-lux-cars-app.vercel.app` |
| **Redirect URLs** | Remove Firebase URLs, add: | `https://choice-lux-cars-app.vercel.app` |
| | | `https://choice-lux-cars-app.vercel.app/reset-password` |

4. Keep `com.choiceluxcars.app://reset-password` for Android deep links
5. Click **Save changes**

## What Was Updated in Code

- `supabase/config.toml` – site_url and redirect URLs (for local Supabase)
- `README.md` – Live Demo URL
- Documentation files – RESET_PASSWORD_*, SUPABASE_DEEP_LINK_SETUP, etc.

## App Behavior

The app builds `redirectTo` dynamically from the current page URL (see `lib/core/services/supabase_service.dart`), so password reset emails will use the correct domain when users are on the Vercel site.
