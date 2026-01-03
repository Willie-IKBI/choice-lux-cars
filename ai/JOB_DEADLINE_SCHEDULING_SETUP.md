# Job Deadline Notification Scheduling Setup

**Date:** 2026-01-04  
**Status:** Workflow Created - Ready for Deployment

---

## 1. Edge Function Verification

✅ **Function Exists:** `supabase/functions/check-job-start-deadlines/index.ts`  
✅ **Function Endpoint:** `https://hgqrbekphumdlsifuamq.supabase.co/functions/v1/check-job-start-deadlines`  
✅ **Function Status:** Ready to deploy

**To Deploy Edge Function:**
```bash
supabase functions deploy check-job-start-deadlines
```

---

## 2. GitHub Actions Workflow

**File Created:** `.github/workflows/check_job_start_deadlines.yml`

**Features:**
- ✅ Scheduled: Every 5 minutes (`*/5 * * * *`)
- ✅ Manual trigger: `workflow_dispatch`
- ✅ Concurrency control: Single run at a time (`cancel-in-progress: true`)
- ✅ Timeout: 2 minutes
- ✅ Uses GitHub Secret: `SUPABASE_SERVICE_ROLE_KEY`
- ✅ Logs HTTP status and response body
- ✅ Fails on non-2xx status codes

**Full YAML:**

```yaml
name: Check Job Start Deadlines

on:
  schedule:
    # Run every 5 minutes
    - cron: '*/5 * * * *'
  workflow_dispatch:
    # Allow manual trigger

concurrency:
  group: check-job-start-deadlines
  cancel-in-progress: true

jobs:
  check-deadlines:
    name: Check Job Start Deadlines
    runs-on: ubuntu-latest
    timeout-minutes: 2

    steps:
      - name: Invoke check-job-start-deadlines Edge Function
        id: invoke-checker
        run: |
          echo "=== CHECK JOB START DEADLINES WORKFLOW STARTED ==="
          echo "Timestamp: $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
          
          # Function endpoint
          FUNCTION_URL="https://hgqrbekphumdlsifuamq.supabase.co/functions/v1/check-job-start-deadlines"
          
          # Invoke function with service role key
          echo "Invoking Edge Function: $FUNCTION_URL"
          
          # Capture both status code and response body in one call
          TEMP_FILE=$(mktemp)
          HTTP_STATUS=$(curl -s -w "%{http_code}" -o "$TEMP_FILE" \
            -X POST \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer ${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}" \
            -d '{}' \
            "$FUNCTION_URL")
          
          HTTP_BODY=$(cat "$TEMP_FILE")
          rm -f "$TEMP_FILE"
          
          echo "HTTP Status Code: $HTTP_STATUS"
          echo "Response Body:"
          echo "$HTTP_BODY" | jq '.' 2>/dev/null || echo "$HTTP_BODY"
          
          # Fail if status code is not 2xx
          if [ "$HTTP_STATUS" -lt 200 ] || [ "$HTTP_STATUS" -ge 300 ]; then
            echo "❌ ERROR: Function returned non-2xx status code: $HTTP_STATUS"
            echo "Response: $HTTP_BODY"
            exit 1
          fi
          
          echo "✅ SUCCESS: Function executed successfully (HTTP $HTTP_STATUS)"
          
          # Extract and display key metrics from response (if available)
          if command -v jq &> /dev/null; then
            CHECKED=$(echo "$HTTP_BODY" | jq -r '.checked // "N/A"')
            NOTIFIED=$(echo "$HTTP_BODY" | jq -r '.notified // "N/A"')
            
            echo "Metrics:"
            echo "  - Jobs Checked: $CHECKED"
            echo "  - Notifications Sent: $NOTIFIED"
          fi

      - name: Workflow Summary
        if: always()
        run: |
          echo "=== WORKFLOW COMPLETED ==="
          echo "Status: ${{ job.status }}"
          echo "Timestamp: $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
```

---

## 3. Git Commands to Deploy to Master

**Current Branch:** `chore/structure-migration`

**Step 1: Stage and commit the workflow file on current branch**
```bash
git add .github/workflows/check_job_start_deadlines.yml
git commit -m "Add scheduled workflow for job start deadline notifications"
```

**Step 2: Switch to master and cherry-pick the commit**
```bash
# Switch to master
git checkout master

# Pull latest master (if needed)
git pull origin master

# Cherry-pick the commit (replace COMMIT_HASH with actual hash from step 1)
# First, get the commit hash:
git log --oneline -1 chore/structure-migration

# Then cherry-pick (replace <COMMIT_HASH> with actual hash):
git cherry-pick <COMMIT_HASH>
```

**Alternative: Cherry-pick by file (if commit hash is unknown)**
```bash
# On master branch, checkout just the workflow file
git checkout master
git checkout chore/structure-migration -- .github/workflows/check_job_start_deadlines.yml
git add .github/workflows/check_job_start_deadlines.yml
git commit -m "Add scheduled workflow for job start deadline notifications"
```

**Step 3: Push to master**
```bash
git push origin master
```

**Step 4: Return to your working branch**
```bash
git checkout chore/structure-migration
```

---

## 4. Complete Command Sequence

**Option A: Using Cherry-Pick (Recommended)**

```bash
# 1. Commit on current branch
git add .github/workflows/check_job_start_deadlines.yml
git commit -m "Add scheduled workflow for job start deadline notifications"
COMMIT_HASH=$(git rev-parse HEAD)

# 2. Switch to master and cherry-pick
git checkout master
git pull origin master
git cherry-pick $COMMIT_HASH

# 3. Push to master
git push origin master

# 4. Return to working branch
git checkout chore/structure-migration
```

**Option B: Using File Checkout (Simpler)**

```bash
# 1. Commit on current branch (optional, for tracking)
git add .github/workflows/check_job_start_deadlines.yml
git commit -m "Add scheduled workflow for job start deadline notifications"

# 2. Switch to master and checkout file
git checkout master
git pull origin master
git checkout chore/structure-migration -- .github/workflows/check_job_start_deadlines.yml
git add .github/workflows/check_job_start_deadlines.yml
git commit -m "Add scheduled workflow for job start deadline notifications"

# 3. Push to master
git push origin master

# 4. Return to working branch
git checkout chore/structure-migration
```

---

## 5. Verification Steps

### 5.1 Verify Workflow File on Master
```bash
git checkout master
cat .github/workflows/check_job_start_deadlines.yml
```

### 5.2 Verify GitHub Secret Exists
- Go to: GitHub Repository → Settings → Secrets and variables → Actions
- Confirm: `SUPABASE_SERVICE_ROLE_KEY` exists

### 5.3 Test Manual Trigger
- Go to: GitHub Repository → Actions → "Check Job Start Deadlines"
- Click "Run workflow" → Select branch "master" → Click "Run workflow"
- Verify workflow completes successfully

### 5.4 Verify Scheduled Runs
- Wait 5 minutes after pushing to master
- Go to: GitHub Repository → Actions → "Check Job Start Deadlines"
- Verify scheduled runs appear every 5 minutes

---

## 6. Expected Workflow Output

**Success Response:**
```json
{
  "success": true,
  "checked": 5,
  "notified": 3,
  "errors": []
}
```

**No Jobs Response:**
```json
{
  "success": true,
  "message": "No jobs needing notifications",
  "checked": 0,
  "notified": 0
}
```

**Error Response:**
```json
{
  "success": false,
  "error": "Error message"
}
```

---

## 7. Important Notes

⚠️ **Schedule Only Runs on Default Branch:**
- GitHub Actions scheduled workflows ONLY run from the default branch (master)
- This is why we must commit the workflow to master

⚠️ **Concurrency Control:**
- `cancel-in-progress: true` ensures only one run executes at a time
- If a run takes longer than 5 minutes, the next scheduled run will cancel it

⚠️ **Timeout:**
- 2-minute timeout prevents stuck workflows
- Edge Function should complete in < 30 seconds typically

⚠️ **Secret Required:**
- `SUPABASE_SERVICE_ROLE_KEY` must exist in GitHub Secrets
- Workflow will fail if secret is missing

---

**End of Setup Guide**

