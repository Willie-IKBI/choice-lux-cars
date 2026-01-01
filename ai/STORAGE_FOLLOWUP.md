# Storage Bucket Scoping — Follow-Up Requirements

**Generated:** 2025-01-XX  
**Agent:** CLC-REVIEW  
**Purpose:** Define scoping requirements for `messages` and `chats` storage buckets after temporary containment  
**Status:** PLANNING — No implementation until requirements are met

---

## Executive Summary

The `messages` and `chats` storage buckets have been secured with authenticated-only access (temporary containment). This document defines the **scoping requirements** that must be met before implementing ownership/path-based restrictions.

**Current State:** Broad authenticated access (any authenticated user can access any file)  
**Target State:** Scoped access based on ownership, path patterns, or role-based rules  
**Blocking Factor:** Unknown usage patterns and file organization structure

---

## 1. Scoping Signal Requirements

Before implementing scoped policies, we must determine **how files are organized and accessed** in these buckets. The scoping signal can come from:

### 1.1 Object Path Convention Analysis

**Required Information:**
- What path patterns exist in the buckets? (e.g., `user_id/`, `conversation_id/`, `timestamp/`, flat structure)
- Are files organized by user, conversation, date, or other criteria?
- What naming conventions are used? (e.g., `{user_id}/{message_id}.txt`, `{conversation_id}/{file_name}`)

**Investigation Methods:**
1. Query Supabase Storage API to list files in buckets
2. Analyze file paths to identify patterns
3. Check if paths contain user IDs, conversation IDs, or other identifiers
4. Document the path structure

**Example Path Patterns to Look For:**
```
messages/
  ├── {user_id}/message_{id}.txt          # User-scoped
  ├── {conversation_id}/file_{id}.txt     # Conversation-scoped
  ├── {timestamp}/file_{id}.txt           # Time-scoped
  └── file_{id}.txt                        # Flat structure (no scoping)

chats/
  ├── {user_id}/chat_{id}.txt              # User-scoped
  ├── {conversation_id}/message_{id}.txt  # Conversation-scoped
  └── {job_id}/chat_{id}.txt               # Job-scoped
```

**Decision Criteria:**
- If paths contain `user_id` or `auth.uid()` → Implement user-based scoping
- If paths contain `conversation_id` → Implement conversation-based scoping (requires DB mapping)
- If paths contain `job_id` → Implement job-based scoping (requires DB mapping)
- If flat structure → May require DB mapping or different approach

---

### 1.2 Database Mapping Analysis

**Required Information:**
- Do database tables reference files in these buckets?
- What tables/columns store file paths or URLs?
- How are files associated with users, conversations, jobs, or other entities?

**Investigation Methods:**
1. Search database schema for columns that might store storage URLs/paths
2. Check for tables like `messages`, `chats`, `conversations`, `chat_messages`
3. Analyze foreign key relationships to determine ownership
4. Document the data model for file associations

**Example Database Patterns to Look For:**
```sql
-- Pattern 1: Direct file reference in table
CREATE TABLE messages (
  id uuid PRIMARY KEY,
  user_id uuid REFERENCES profiles(id),
  file_url text,  -- Points to storage bucket
  ...
);

-- Pattern 2: Separate file metadata table
CREATE TABLE chat_files (
  id uuid PRIMARY KEY,
  conversation_id uuid REFERENCES conversations(id),
  storage_path text,  -- Path in storage bucket
  uploaded_by uuid REFERENCES profiles(id),
  ...
);

-- Pattern 3: JSONB field with file references
CREATE TABLE conversations (
  id uuid PRIMARY KEY,
  participants jsonb,
  attachments jsonb,  -- Array of file paths
  ...
);
```

**Decision Criteria:**
- If files are mapped to `user_id` in DB → Implement user-based scoping
- If files are mapped to `conversation_id` in DB → Implement conversation-based scoping
- If files are mapped to `job_id` in DB → Implement job-based scoping
- If no DB mapping exists → May require path-based scoping or different approach

---

### 1.3 Usage Pattern Analysis

**Required Information:**
- Are these buckets actively used in production?
- What operations are performed? (upload, download, list, delete)
- Who accesses these files? (specific roles, all users, external systems)
- Are files shared between users or private to one user?

**Investigation Methods:**
1. Check application logs for storage API calls
2. Query Supabase Storage logs (if available)
3. Review Edge Functions that might access these buckets
4. Interview stakeholders about intended usage
5. Check if buckets are empty or contain files

**Decision Criteria:**
- If buckets are unused → May not need scoping (but document decision)
- If buckets are used by specific roles → Implement role-based scoping
- If files are private to users → Implement user-based scoping
- If files are shared in conversations → Implement conversation-based scoping

---

## 2. Next Batch Objective (No Implementation)

### Batch Title: "Storage Bucket Scoping Analysis"

**Objective:** Determine scoping requirements for `messages` and `chats` storage buckets without implementing policy changes.

**Deliverables:**
1. **Path Structure Analysis Document**
   - List of actual file paths in both buckets (sample if large)
   - Identified path patterns and conventions
   - Recommendation for path-based scoping (if applicable)

2. **Database Mapping Analysis Document**
   - Tables/columns that reference files in these buckets
   - Data model for file associations
   - Recommendation for ownership-based scoping (if applicable)

3. **Usage Pattern Analysis Document**
   - Active usage status (used/unused/unknown)
   - Access patterns (who, when, what operations)
   - Recommendation for role-based scoping (if applicable)

4. **Scoping Recommendation Document**
   - Recommended scoping approach (path-based, ownership-based, role-based, or combination)
   - Proposed policy structure
   - Risk assessment of proposed scoping
   - Implementation plan for follow-up batch

**Out of Scope:**
- ❌ No policy changes
- ❌ No code changes
- ❌ No database migrations
- ❌ No file structure modifications

**In Scope:**
- ✅ Analysis and documentation only
- ✅ Querying storage to understand structure
- ✅ Querying database to find mappings
- ✅ Reviewing logs and usage patterns
- ✅ Creating recommendations

---

## 3. Minimal Validation Plan

After the scoping batch completes, the following validation must occur before implementing scoped policies:

### 3.1 Pre-Implementation Validation

**Required Checks:**
- [ ] Path structure is documented and understood
- [ ] Database mappings are identified (if applicable)
- [ ] Usage patterns are confirmed
- [ ] Scoping approach is recommended and justified
- [ ] Risk assessment is completed
- [ ] Stakeholder approval obtained (if buckets are actively used)

---

### 3.2 Implementation Validation (For Follow-Up Batch)

**Policy Testing:**
- [ ] Test that scoped policies allow intended access
- [ ] Test that scoped policies block unintended access
- [ ] Test all user roles (admin, manager, driver, driver_manager)
- [ ] Test edge cases (file ownership, shared files, etc.)

**Functionality Testing:**
- [ ] Existing file uploads still work
- [ ] Existing file downloads still work
- [ ] Existing file updates still work
- [ ] Existing file deletions still work
- [ ] No errors in application logs
- [ ] No user-reported access issues

**Security Testing:**
- [ ] Users cannot access files they shouldn't have access to
- [ ] Users can access files they should have access to
- [ ] Role-based restrictions work correctly (if applicable)
- [ ] Path-based restrictions work correctly (if applicable)
- [ ] Ownership-based restrictions work correctly (if applicable)

---

## 4. Scoping Approaches (Reference)

### 4.1 Path-Based Scoping

**Use Case:** Files are organized by path patterns (e.g., `user_id/`, `conversation_id/`)

**Example Policy:**
```sql
-- User-scoped: Users can only access files in their own folder
CREATE POLICY "messages_user_scoped_select"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'messages' 
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
```

**Requirements:**
- Path structure must be consistent
- Path must contain scoping identifier (user_id, conversation_id, etc.)
- Identifier must be extractable from path

---

### 4.2 Ownership-Based Scoping (via Database)

**Use Case:** Files are referenced in database tables with ownership information

**Example Policy:**
```sql
-- Ownership-scoped: Users can only access files they own (per DB)
CREATE POLICY "messages_ownership_scoped_select"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'messages'
    AND EXISTS (
      SELECT 1 FROM messages
      WHERE file_url LIKE '%' || storage.objects.name
      AND user_id = auth.uid()
    )
  );
```

**Requirements:**
- Database table must exist with file references
- Table must have ownership column (user_id, conversation_id, etc.)
- File path/URL must be mappable to database record

---

### 4.3 Role-Based Scoping

**Use Case:** Access is determined by user role, not ownership

**Example Policy:**
```sql
-- Role-scoped: Only admins and managers can access
CREATE POLICY "messages_role_scoped_select"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'messages'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
      AND role IN ('administrator', 'manager', 'super_admin')
    )
  );
```

**Requirements:**
- Role requirements must be clearly defined
- Role information must be available in profiles table

---

### 4.4 Combination Scoping

**Use Case:** Multiple scoping rules apply (e.g., role-based + ownership-based)

**Example Policy:**
```sql
-- Combined: Admins can access all, users can access their own
CREATE POLICY "messages_combined_scoped_select"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'messages'
    AND (
      -- Admins can access all
      EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid()
        AND role IN ('administrator', 'super_admin')
      )
      OR
      -- Users can access their own
      (storage.foldername(name))[1] = auth.uid()::text
    )
  );
```

**Requirements:**
- Multiple scoping signals must be available
- Logic must be clearly defined

---

## 5. Decision Matrix

| Scenario | Scoping Approach | Signal Required |
|----------|-----------------|-----------------|
| Files organized by `user_id/` in path | Path-based | Path pattern analysis |
| Files referenced in DB with `user_id` | Ownership-based | Database mapping |
| Only admins should access | Role-based | Role requirements |
| Files organized by `conversation_id/` | Path-based + DB mapping | Path pattern + DB mapping |
| Users access own files, admins access all | Combination | Path pattern + role requirements |
| Buckets are unused | No scoping needed | Usage pattern analysis |
| Unknown structure | Investigation required | All signals |

---

## 6. Success Criteria

The scoping batch is considered successful when:

1. ✅ **Path structure is documented** (if files exist)
2. ✅ **Database mappings are identified** (if applicable)
3. ✅ **Usage patterns are confirmed** (active/inactive/unknown)
4. ✅ **Scoping approach is recommended** with justification
5. ✅ **Risk assessment is completed** for recommended approach
6. ✅ **Implementation plan is created** for follow-up batch

**Blocking Criteria:**
- ❌ Cannot proceed if usage is unknown and buckets contain files
- ❌ Cannot proceed if path structure is inconsistent
- ❌ Cannot proceed if database mappings are unclear

---

## 7. Next Steps

1. **Create scoping analysis batch** (CLC-ARCH to define, CLC-BUILD to implement)
2. **Execute analysis** (query storage, database, logs)
3. **Document findings** (path structure, DB mappings, usage patterns)
4. **Recommend scoping approach** (with justification)
5. **Review and approve** (CLC-REVIEW)
6. **Implement scoped policies** (follow-up batch)

---

**Status:** PLANNING — Awaiting scoping analysis batch  
**Blocking:** None — Can proceed immediately after temporary containment is deployed  
**Priority:** MEDIUM — Required before production use (if buckets are actively used)

