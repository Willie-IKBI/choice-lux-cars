#!/usr/bin/env node

/**
 * Validation script for Migration 11/12: Trip Progress RLS and State Enforcement
 * 
 * Tests:
 * - RLS policies on trip_progress table (Migration 11)
 * - State machine trigger enforcement (Migration 12)
 * 
 * Requires environment variables:
 * - SUPABASE_URL
 * - SUPABASE_ANON_KEY
 * - DRIVER_EMAIL
 * - DRIVER_PASSWORD
 * - OTHER_EMAIL
 * - OTHER_PASSWORD
 */

import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Hardcoded test IDs
const JOB_ID = 1145;
const TRIP_PROGRESS_ID = 2;

// Required environment variables
const requiredEnvVars = [
  'SUPABASE_URL',
  'SUPABASE_ANON_KEY',
  'DRIVER_EMAIL',
  'DRIVER_PASSWORD',
  'OTHER_EMAIL',
  'OTHER_PASSWORD'
];

// Validate environment variables
const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);
if (missingVars.length > 0) {
  console.error('❌ Missing required environment variables:');
  missingVars.forEach(varName => console.error(`   - ${varName}`));
  console.error('\nPlease create a .env file based on scripts/.env.example');
  process.exit(1);
}

// Initialize Supabase client
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

// Test results tracking
const results = {
  passed: [],
  failed: []
};

function logTest(name, passed, details = '') {
  const status = passed ? '✅ PASS' : '❌ FAIL';
  console.log(`${status}: ${name}`);
  if (details) {
    console.log(`   ${details}`);
  }
  if (passed) {
    results.passed.push(name);
  } else {
    results.failed.push(name);
  }
}

async function signIn(email, password) {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password
  });
  
  if (error) {
    throw new Error(`Sign in failed: ${error.message}`);
  }
  
  return data;
}

async function signOut() {
  const { error } = await supabase.auth.signOut();
  if (error) {
    console.warn(`Warning: Sign out error: ${error.message}`);
  }
}

async function runTests() {
  console.log('='.repeat(60));
  console.log('Trip Progress RLS and Trigger Validation');
  console.log('='.repeat(60));
  console.log(`Job ID: ${JOB_ID}`);
  console.log(`Trip Progress ID: ${TRIP_PROGRESS_ID}`);
  console.log('');

  try {
    // ========================================================================
    // Test 1: Sign in as driver
    // ========================================================================
    console.log('📝 Step 1: Signing in as driver...');
    await signIn(process.env.DRIVER_EMAIL, process.env.DRIVER_PASSWORD);
    console.log('✅ Signed in as driver\n');

    // ========================================================================
    // Test 2: SELECT as driver (should return rows)
    // ========================================================================
    console.log('📝 Step 2: SELECT trip_progress as driver...');
    const { data: selectData, error: selectError } = await supabase
      .from('trip_progress')
      .select('*')
      .eq('job_id', JOB_ID);

    if (selectError) {
      logTest(
        'SELECT as driver',
        false,
        `Error: ${selectError.message}`
      );
    } else {
      const rowCount = selectData?.length || 0;
      logTest(
        'SELECT as driver',
        rowCount >= 1,
        `Returned ${rowCount} row(s) (expected >= 1)`
      );
    }

    // ========================================================================
    // Test 3: Invalid transition (pending -> passenger_onboard)
    // ========================================================================
    console.log('\n📝 Step 3: Attempting invalid transition (pending -> passenger_onboard)...');
    const { error: invalidTransitionError } = await supabase
      .from('trip_progress')
      .update({ status: 'passenger_onboard' })
      .eq('id', TRIP_PROGRESS_ID);

    if (invalidTransitionError) {
      const expectedError = 'Invalid status transition';
      const hasExpectedError = invalidTransitionError.message.includes(expectedError);
      logTest(
        'Invalid transition blocked',
        hasExpectedError,
        `Error: ${invalidTransitionError.message}`
      );
    } else {
      logTest(
        'Invalid transition blocked',
        false,
        'Update succeeded but should have failed'
      );
    }

    // ========================================================================
    // Test 4: Valid transition (pending -> pickup_arrived)
    // ========================================================================
    console.log('\n📝 Step 4: Attempting valid transition (pending -> pickup_arrived)...');
    const { error: validTransitionError } = await supabase
      .from('trip_progress')
      .update({ status: 'pickup_arrived' })
      .eq('id', TRIP_PROGRESS_ID);

    if (validTransitionError) {
      logTest(
        'Valid transition succeeded',
        false,
        `Error: ${validTransitionError.message}`
      );
    } else {
      logTest(
        'Valid transition succeeded',
        true,
        'Status updated to pickup_arrived'
      );
    }

    // ========================================================================
    // Test 5: Verify timestamp auto-set
    // ========================================================================
    console.log('\n📝 Step 5: Verifying pickup_arrived_at was auto-set...');
    const { data: verifyData, error: verifyError } = await supabase
      .from('trip_progress')
      .select('id, status, pickup_arrived_at, updated_at')
      .eq('id', TRIP_PROGRESS_ID)
      .single();

    if (verifyError) {
      logTest(
        'Timestamp auto-set verification',
        false,
        `Error reading back: ${verifyError.message}`
      );
    } else {
      const hasTimestamp = verifyData.pickup_arrived_at !== null;
      logTest(
        'Timestamp auto-set verification',
        hasTimestamp,
        `Status: ${verifyData.status}, pickup_arrived_at: ${verifyData.pickup_arrived_at}, updated_at: ${verifyData.updated_at}`
      );
    }

    // ========================================================================
    // Test 6: Attempt to modify timestamp (should fail)
    // ========================================================================
    console.log('\n📝 Step 6: Attempting to modify pickup_arrived_at...');
    const { error: timestampModifyError } = await supabase
      .from('trip_progress')
      .update({ pickup_arrived_at: '2020-01-01T00:00:00Z' })
      .eq('id', TRIP_PROGRESS_ID);

    if (timestampModifyError) {
      const expectedError = 'Cannot change pickup_arrived_at';
      const hasExpectedError = timestampModifyError.message.includes(expectedError);
      logTest(
        'Timestamp immutability enforced',
        hasExpectedError,
        `Error: ${timestampModifyError.message}`
      );
    } else {
      logTest(
        'Timestamp immutability enforced',
        false,
        'Update succeeded but should have failed'
      );
    }

    // ========================================================================
    // Test 7: Sign out and sign in as other user
    // ========================================================================
    console.log('\n📝 Step 7: Signing out and signing in as other user...');
    await signOut();
    await signIn(process.env.OTHER_EMAIL, process.env.OTHER_PASSWORD);
    console.log('✅ Signed in as other user\n');

    // ========================================================================
    // Test 8: SELECT as other user (should return 0 rows)
    // ========================================================================
    console.log('📝 Step 8: SELECT trip_progress as other user...');
    const { data: otherSelectData, error: otherSelectError } = await supabase
      .from('trip_progress')
      .select('*')
      .eq('job_id', JOB_ID);

    if (otherSelectError) {
      logTest(
        'SELECT as other user (RLS block)',
        false,
        `Error: ${otherSelectError.message}`
      );
    } else {
      const rowCount = otherSelectData?.length || 0;
      logTest(
        'SELECT as other user (RLS block)',
        rowCount === 0,
        `Returned ${rowCount} row(s) (expected 0)`
      );
    }

    // ========================================================================
    // Cleanup: Sign out
    // ========================================================================
    await signOut();

  } catch (error) {
    console.error('\n❌ Fatal error during testing:');
    console.error(error.message);
    results.failed.push('Fatal error');
  }

  // ========================================================================
  // Summary
  // ========================================================================
  console.log('\n' + '='.repeat(60));
  console.log('Test Summary');
  console.log('='.repeat(60));
  console.log(`✅ Passed: ${results.passed.length}`);
  results.passed.forEach(test => console.log(`   - ${test}`));
  console.log(`\n❌ Failed: ${results.failed.length}`);
  results.failed.forEach(test => console.log(`   - ${test}`));
  console.log('');

  if (results.failed.length === 0) {
    console.log('🎉 All tests PASSED!');
    process.exit(0);
  } else {
    console.log('⚠️  Some tests FAILED. Please review the errors above.');
    process.exit(1);
  }
}

// Run tests
runTests().catch(error => {
  console.error('Unhandled error:', error);
  process.exit(1);
});

