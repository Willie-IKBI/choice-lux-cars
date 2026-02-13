# Supabase Email Template Update - Password Reset

## Current Template
The current template only shows a link, which doesn't work for mobile OTP flow.

## Updated Template
Replace the email template body in Supabase Dashboard with the following:

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Reset Your Password</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      background-color: #f4f4f4;
      margin: 0;
      padding: 0;
      color: #333;
    }
    .container {
      max-width: 600px;
      margin: 40px auto;
      background-color: #ffffff;
      padding: 30px;
      border-radius: 10px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.05);
    }
    .logo {
      text-align: center;
      margin-bottom: 30px;
    }
    .logo img {
      max-height: 60px;
    }
    h2 {
      color: #1a1a1a;
      text-align: center;
    }
    p {
      font-size: 16px;
      line-height: 1.6;
    }
    .otp-code {
      text-align: center;
      margin: 30px 0;
      padding: 20px;
      background-color: #f8f8f8;
      border-radius: 8px;
      border: 2px dashed #000000;
    }
    .otp-code .code {
      font-size: 32px;
      font-weight: bold;
      letter-spacing: 8px;
      color: #000000;
      font-family: 'Courier New', monospace;
    }
    .otp-label {
      font-size: 14px;
      color: #666;
      margin-bottom: 10px;
    }
    .btn {
      display: inline-block;
      padding: 12px 24px;
      margin-top: 20px;
      background-color: #000000;
      color: #ffffff !important;
      text-decoration: none;
      border-radius: 6px;
      font-weight: bold;
    }
    .divider {
      text-align: center;
      margin: 30px 0;
      color: #888;
      font-size: 14px;
    }
    .footer {
      margin-top: 40px;
      font-size: 13px;
      color: #888;
      text-align: center;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">
      <img src="https://hgqrbekphumdlsifuamq.supabase.co/storage/v1/object/public/clc_images/app_images/logo%20-%20512.png" alt="Choice Lux Cars Logo">
    </div>
    <h2>Reset Your Password</h2>
    <p>Hello,</p>
    <p>We received a request to reset your Choice Lux Cars account password.</p>
    
    {{ if .Token }}
    <!-- OTP Code for Mobile App Users -->
    <div class="otp-code">
      <div class="otp-label">Enter this code in the app:</div>
      <div class="code">{{ .Token }}</div>
      <div style="margin-top: 15px; font-size: 14px; color: #666;">
        This code is valid for 1 hour.
      </div>
    </div>
    <p style="text-align: center; margin-top: 20px;">
      Open the Choice Lux Cars app and enter this code on the verification screen.
    </p>
    {{ end }}
    
    {{ if .ConfirmationURL }}
    <!-- Link for Web Users -->
    {{ if .Token }}
    <div class="divider">OR</div>
    {{ end }}
    <p style="text-align: center;">
      <a href="{{ .ConfirmationURL }}" class="btn">Reset Password via Link</a>
    </p>
    <p style="font-size: 14px; color: #666; text-align: center;">
      Click the button above if you're using the web app.
    </p>
    {{ end }}
    
    <p style="margin-top: 30px;">If you didn't request this, you can safely ignore this email.</p>
    <div class="footer">
      <p>This email was sent by Choice Lux Cars</p>
    </div>
  </div>
</body>
</html>
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
