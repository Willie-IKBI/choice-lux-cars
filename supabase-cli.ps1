# Supabase CLI Environment Setup Script
# This script sets up the environment variables needed for Supabase CLI to connect to production

# Set environment variables for Supabase CLI
$env:SUPABASE_DB_PASSWORD = "0X8ab3bWNL876txl"
$env:PGSSLMODE = "require"

Write-Host "Supabase CLI environment variables set:" -ForegroundColor Green
Write-Host "  SUPABASE_DB_PASSWORD: Set" -ForegroundColor Yellow
Write-Host "  PGSSLMODE: require" -ForegroundColor Yellow
Write-Host ""
Write-Host "You can now use Supabase CLI commands like:" -ForegroundColor Cyan
Write-Host "  supabase db push --linked" -ForegroundColor White
Write-Host "  supabase db pull" -ForegroundColor White
Write-Host "  supabase migration list" -ForegroundColor White
Write-Host "  supabase status" -ForegroundColor White
Write-Host ""
Write-Host "Note: These environment variables are only set for this PowerShell session." -ForegroundColor Gray
