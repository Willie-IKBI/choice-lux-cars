# Supabase Email Template Update - Password Reset

## Current Template
The current template only shows a link, which doesn't work for mobile OTP flow.

## Updated Template
Replace the email template body in Supabase Dashboard with the following:

```html
 
```

## How to Update

1. Go to **Supabase Dashboard** → **Authentication** → **Email Templates**
2. Select **"Reset Password"** template
3. Replace the **Body** content with the template above
4. Click **Save**

## How It Works

- **Mobile App Users**: When `resetPassword()` is called without `redirectTo` (mobile), Supabase sends `{{ .Token }}` (6-digit code). The template shows this prominently.
- **Web Users**: When `resetPassword()` is called with `redirectTo` (web), Supabase sends `{{ .ConfirmationURL }}` (link). The template shows the button.
- **Both**: If both are available, both are shown (OTP first, then link as alternative).

## Testing

After updating the template:

1. **Test Mobile Flow:**
   - Request password reset from Android app
   - Check email - should show 6-digit code
   - Enter code in app
   - Reset password

2. **Test Web Flow:**
   - Request password reset from web app
   - Check email - should show "Reset Password via Link" button
   - Click button
   - Reset password

## Notes

- The template uses Supabase's conditional syntax `{{ if .Token }}` and `{{ if .ConfirmationURL }}`
- OTP code is displayed in a large, easy-to-read format
- Link is shown as a button for web users
- Both can appear in the same email if needed (though typically only one will be present)
