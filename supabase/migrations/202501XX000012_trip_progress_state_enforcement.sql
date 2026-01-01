-- Migration 12: Trip Progress State Enforcement
-- Purpose: Enforce state machine rules and data integrity for trip_progress table
-- Based on: ai/DRIVER_JOB_FLOW.md and database contract requirements
-- Prerequisites: Migrations 1-11b must be applied
--
-- This migration:
-- 1) Adds CHECK constraint for allowed status values
-- 2) Creates trigger function to enforce state machine transitions
-- 3) Enforces immutability of job_id, trip_index, and timestamps
-- 4) Automatically sets timestamps on status transitions
-- 5) Ensures updated_at is always current

BEGIN;

-- ============================================================================
-- A) Enforce allowed statuses
-- ============================================================================

-- Check if constraint already exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints
        WHERE table_schema = 'public'
        AND table_name = 'trip_progress'
        AND constraint_name = 'check_trip_progress_status'
    ) THEN
        ALTER TABLE public.trip_progress
        ADD CONSTRAINT check_trip_progress_status
        CHECK (status IN ('pending', 'pickup_arrived', 'passenger_onboard', 'dropoff_arrived', 'completed'));
        
        RAISE NOTICE 'Added CHECK constraint check_trip_progress_status';
    ELSE
        RAISE NOTICE 'CHECK constraint check_trip_progress_status already exists';
    END IF;
END $$;

COMMENT ON CONSTRAINT check_trip_progress_status ON public.trip_progress IS 
    'Enforces that status must be one of: pending, pickup_arrived, passenger_onboard, dropoff_arrived, completed';

-- ============================================================================
-- B) Create trigger function for state machine enforcement
-- ============================================================================

CREATE OR REPLACE FUNCTION public.enforce_trip_progress_state()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- D) Bypass rule: Allow postgres/service_role to bypass all checks
    IF current_user IN ('postgres', 'service_role') THEN
        RETURN NEW;
    END IF;
    
    -- C.1) Enforce immutability of job_id and trip_index
    IF NEW.job_id IS DISTINCT FROM OLD.job_id THEN
        RAISE EXCEPTION 'Cannot change job_id. job_id is immutable.';
    END IF;
    
    IF NEW.trip_index IS DISTINCT FROM OLD.trip_index THEN
        RAISE EXCEPTION 'Cannot change trip_index. trip_index is immutable.';
    END IF;
    
    -- C.2) Enforce status progression (forward only or no-op)
    IF NEW.status IS DISTINCT FROM OLD.status THEN
        -- Define allowed transitions
        IF NOT (
            (OLD.status = 'pending' AND NEW.status = 'pickup_arrived') OR
            (OLD.status = 'pickup_arrived' AND NEW.status = 'passenger_onboard') OR
            (OLD.status = 'passenger_onboard' AND NEW.status = 'dropoff_arrived') OR
            (OLD.status = 'dropoff_arrived' AND NEW.status = 'completed')
        ) THEN
            RAISE EXCEPTION 'Invalid status transition from % to %. Status can only move forward: pending -> pickup_arrived -> passenger_onboard -> dropoff_arrived -> completed', 
                OLD.status, NEW.status;
        END IF;
        
        -- Prerequisite timestamp checks: require previous status timestamp to be set
        IF OLD.status = 'pickup_arrived' AND NEW.status = 'passenger_onboard' AND OLD.pickup_arrived_at IS NULL THEN
            RAISE EXCEPTION 'Cannot transition to passenger_onboard: pickup_arrived_at timestamp is missing. Previous status timestamp must be set before advancing.';
        END IF;
        
        IF OLD.status = 'passenger_onboard' AND NEW.status = 'dropoff_arrived' AND OLD.passenger_onboard_at IS NULL THEN
            RAISE EXCEPTION 'Cannot transition to dropoff_arrived: passenger_onboard_at timestamp is missing. Previous status timestamp must be set before advancing.';
        END IF;
        
        IF OLD.status = 'dropoff_arrived' AND NEW.status = 'completed' AND OLD.dropoff_arrived_at IS NULL THEN
            RAISE EXCEPTION 'Cannot transition to completed: dropoff_arrived_at timestamp is missing. Previous status timestamp must be set before advancing.';
        END IF;
    END IF;
    
    -- C.3) Timestamp enforcement on status transitions
    IF NEW.status IS DISTINCT FROM OLD.status THEN
        -- Set pickup_arrived_at when status changes to pickup_arrived
        IF NEW.status = 'pickup_arrived' AND NEW.pickup_arrived_at IS NULL THEN
            NEW.pickup_arrived_at := now();
        END IF;
        
        -- Set passenger_onboard_at when status changes to passenger_onboard
        IF NEW.status = 'passenger_onboard' AND NEW.passenger_onboard_at IS NULL THEN
            NEW.passenger_onboard_at := now();
        END IF;
        
        -- Set dropoff_arrived_at when status changes to dropoff_arrived
        IF NEW.status = 'dropoff_arrived' AND NEW.dropoff_arrived_at IS NULL THEN
            NEW.dropoff_arrived_at := now();
        END IF;
        
        -- Set completed_at when status changes to completed
        IF NEW.status = 'completed' AND NEW.completed_at IS NULL THEN
            NEW.completed_at := now();
        END IF;
    END IF;
    
    -- C.4) Timestamp immutability: Once set, timestamps cannot be changed
    IF OLD.pickup_arrived_at IS NOT NULL AND NEW.pickup_arrived_at IS DISTINCT FROM OLD.pickup_arrived_at THEN
        RAISE EXCEPTION 'Cannot change pickup_arrived_at. Timestamp is immutable once set.';
    END IF;
    
    IF OLD.passenger_onboard_at IS NOT NULL AND NEW.passenger_onboard_at IS DISTINCT FROM OLD.passenger_onboard_at THEN
        RAISE EXCEPTION 'Cannot change passenger_onboard_at. Timestamp is immutable once set.';
    END IF;
    
    IF OLD.dropoff_arrived_at IS NOT NULL AND NEW.dropoff_arrived_at IS DISTINCT FROM OLD.dropoff_arrived_at THEN
        RAISE EXCEPTION 'Cannot change dropoff_arrived_at. Timestamp is immutable once set.';
    END IF;
    
    IF OLD.completed_at IS NOT NULL AND NEW.completed_at IS DISTINCT FROM OLD.completed_at THEN
        RAISE EXCEPTION 'Cannot change completed_at. Timestamp is immutable once set.';
    END IF;
    
    -- C.5) Ensure updated_at is always set
    NEW.updated_at := now();
    
    RETURN NEW;
END;
$$;

-- E) Hardening: Revoke execute from PUBLIC/anon
REVOKE EXECUTE ON FUNCTION public.enforce_trip_progress_state() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.enforce_trip_progress_state() FROM anon;

COMMENT ON FUNCTION public.enforce_trip_progress_state() IS 
    'Trigger function that enforces state machine rules for trip_progress: immutable job_id/trip_index, forward-only status transitions, automatic timestamp setting, and timestamp immutability. Bypasses for postgres/service_role.';

-- ============================================================================
-- Create trigger
-- ============================================================================

DROP TRIGGER IF EXISTS trg_enforce_trip_progress_state ON public.trip_progress;

CREATE TRIGGER trg_enforce_trip_progress_state
BEFORE UPDATE ON public.trip_progress
FOR EACH ROW
EXECUTE FUNCTION public.enforce_trip_progress_state();

COMMENT ON TRIGGER trg_enforce_trip_progress_state ON public.trip_progress IS 
    'Enforces state machine rules and data integrity for trip_progress updates. Prevents invalid status transitions and timestamp modifications.';

-- ============================================================================
-- Migration Complete
-- ============================================================================

COMMIT;

