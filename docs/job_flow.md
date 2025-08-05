# Job Management Flow Documentation

## Overview

The job management system provides a comprehensive workflow for creating, managing, and tracking jobs within the Choice Lux Cars application. The system implements role-based access control, multi-step job creation, and trip management capabilities.

## User Roles and Permissions

### Administrator & Manager
- **Job Visibility**: Can see all jobs across the system
- **Job Creation**: Can create new jobs
- **Job Management**: Full CRUD operations on jobs

### Driver Manager
- **Job Visibility**: Can see jobs they created or allocated to them
- **Job Creation**: Can create new jobs
- **Job Management**: Can manage jobs they created or were allocated

### Driver
- **Job Visibility**: Can only see jobs allocated to them
- **Job Creation**: Cannot create new jobs
- **Job Management**: Read-only access to their allocated jobs

## Job Statuses

- **`open`**: Newly created jobs awaiting execution
- **`in_progress`**: Jobs currently being executed
- **`completed`**: Finished jobs (includes both 'closed' and 'completed' statuses)

## Database Schema

### Jobs Table (Updated)
```sql
CREATE TABLE jobs (
  id bigint PRIMARY KEY,
  client_id bigint REFERENCES clients(id),
  vehicle_id bigint REFERENCES vehicles(id),
  agent_id bigint REFERENCES agents(id),
  driver_id uuid REFERENCES profiles(id),
  order_date date NOT NULL DEFAULT CURRENT_DATE,
  job_status text NOT NULL DEFAULT 'open',
  amount numeric,
  amount_collect boolean DEFAULT false,
  passenger_name text,
  passenger_contact text,
  number_bags text,
  job_start_date date NOT NULL,
  notes text,
  quote_no bigint,
  voucher_pdf text,
  cancel_reason text,
  location text, -- Branch location (Jhb, Cpt, Dbn)
  created_by text,
  created_at timestampz DEFAULT NOW(),
  updated_at timestampz DEFAULT NOW()
);
```

### Transport Table
```sql
CREATE TABLE transport (
  id bigint PRIMARY KEY,
  job_id bigint REFERENCES jobs(id) ON DELETE CASCADE,
  pickup_date timestamp NOT NULL,
  pickup_location text NOT NULL,
  dropoff_location text NOT NULL,
  client_pickup_time timestamp,
  client_dropoff_time timestamp,
  notes text,
  amount numeric NOT NULL,
  status enum
);
```

## File Structure

```
lib/features/jobs/
├── models/
│   ├── job.dart          # Job data model (UPDATED)
│   └── trip.dart         # Trip data model
├── providers/
│   └── jobs_provider.dart # State management for jobs and trips
├── screens/
│   ├── create_job_screen.dart      # Step 1: Job details creation
│   ├── trip_management_screen.dart # Step 2: Trip management
│   └── job_summary_screen.dart     # Final summary screen
├── widgets/
│   └── job_card.dart     # Job display component (UPDATED)
└── jobs_screen.dart      # Main jobs list screen (UPDATED)
```

## Core Components

### 1. Data Models

#### Job Model (`lib/features/jobs/models/job.dart`) - UPDATED
```dart
class Job {
  final String id;
  final String clientId;
  final String? agentId;
  final String vehicleId;
  final String driverId;
  final DateTime jobStartDate;
  final DateTime orderDate;
  final String? passengerName;
  final String? passengerContact;
  final double pasCount; // Number of customers (pax)
  final String luggageCount; // Number of bags (number_bags as text)
  final String? notes;
  final bool collectPayment;
  final double? paymentAmount;
  final String status; // open, closed, in_progress, completed
  final String? quoteNo;
  final String? voucherPdf;
  final String? cancelReason;
  final String? location; // Branch location (Jhb, Cpt, Dbn)
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Helper getters
  bool get hasCompletePassengerDetails;
  bool get isOpen;
  bool get isInProgress;
  bool get isClosed; // Returns true for both 'closed' and 'completed' statuses
  String get daysUntilStartText;
}
```

#### Trip Model (`lib/features/jobs/models/trip.dart`)
```dart
class Trip {
  final String id;
  final String jobId;
  final DateTime pickupDate;
  final String pickupLocation;
  final String dropoffLocation;
  final DateTime? clientPickupTime;
  final DateTime? clientDropoffTime;
  final String? notes;
  final double amount;
  final String? status;

  // Helper getters
  String get shortSummary;
  String get formattedDateTime;
}
```

### 2. State Management (`lib/features/jobs/providers/jobs_provider.dart`)

#### JobsNotifier
- **Purpose**: Manages job state and operations
- **Key Methods**:
  - `fetchJobs()`: Fetches jobs based on user role
  - `getJobsByDriver()`: Fetches jobs for specific driver
  - `getJobsByDriverManager()`: Fetches jobs for driver manager
  - `createJob()`: Creates new job
  - `updateJob()`: Updates existing job
  - `deleteJob()`: Deletes job
  - `updateJobStatus()`: Updates job status

#### TripsNotifier
- **Purpose**: Manages trip state for a specific job
- **Key Methods**:
  - `fetchTripsForJob()`: Fetches trips for a job
  - `addTrip()`: Adds new trip
  - `updateTrip()`: Updates existing trip
  - `deleteTrip()`: Deletes trip
  - `getTotalAmount()`: Calculates total trip amount

### 3. Database Service (`lib/core/services/supabase_service.dart`) - UPDATED

#### Job Operations
```dart
// Fetch jobs with role-based filtering
Future<List<Map<String, dynamic>>> getJobs();
Future<List<Map<String, dynamic>>> getJobsByDriver(String driverId);
Future<List<Map<String, dynamic>>> getJobsByDriverManager(String driverManagerId);

// CRUD operations
Future<Map<String, dynamic>> createJob(Map<String, dynamic> jobData);
Future<Map<String, dynamic>> updateJob(String jobId, Map<String, dynamic> updates);
Future<void> deleteJob(String jobId);
```

#### Trip Operations
```dart
// Trip management
Future<List<Map<String, dynamic>>> getTripsByJob(String jobId);
Future<Map<String, dynamic>> createTrip(Map<String, dynamic> tripData);
Future<Map<String, dynamic>> updateTrip(String tripId, Map<String, dynamic> updates);
Future<void> deleteTrip(String tripId);
```

## User Interface Flow

### 1. Jobs List Screen (`lib/features/jobs/jobs_screen.dart`) - UPDATED

**Purpose**: Main entry point for job management

**Features**:
- **Status Filtering**: Toggle between open, in_progress, completed, and all jobs
- **Search Functionality**: Search by passenger name, client, or job ID
- **Role-Based Actions**: "Create Job" button only visible to authorized users
- **Job Cards**: Display job information with visual indicators
- **Responsive Design**: Mobile-friendly layout with horizontal scrolling filters

**Key Components**:
```dart
class JobsScreen extends ConsumerStatefulWidget {
  // Status filter buttons (horizontally scrollable)
  // Search bar
  // Create job button (role-based)
  // Job list with JobCard widgets
  // Pagination widget
}
```

### 2. Job Card Widget (`lib/features/jobs/widgets/job_card.dart`) - UPDATED

**Purpose**: Display individual job information

**Features**:
- **Job ID Display**: Shows "Job #ID" instead of branch
- **Status Indicators**: Visual status badges with appropriate colors
- **Passenger Details**: Warning indicator for incomplete passenger information
- **Payment Collection**: Shows payment amount when applicable
- **Days Until Start**: Color-coded countdown display
- **Responsive Layout**: Compact design for mobile screens
- **Interactive View Button**: Clickable action button for job details

**Visual Elements**:
- Status badges (Open: Gold, In Progress: Blue, Completed: Grey)
- Warning indicators for incomplete data
- Payment collection indicators
- Days until start countdown
- Action buttons (VIEW, TRACK, DETAILS) with navigation functionality

### 3. Job Creation - Step 1 (`lib/features/jobs/screens/create_job_screen.dart`)

**Purpose**: Capture initial job details

**Form Fields**:
1. **Client Selection**: Dropdown with search functionality
2. **Agent Selection**: Auto-populated from selected client
3. **Vehicle Selection**: Shows make, model, registration, license validity (sorted alphabetically by make)
4. **Driver Selection**: Shows name, surname, license/PDP validity indicators
5. **Branch (Location)**: Dropdown with options (Johannesburg (Jhb), Cape Town (Cpt), Durban (Dbn))
6. **Job Start Date**: Date picker for job commencement
7. **Passenger Details**: Name and contact (optional with indicator)
8. **Passenger Count**: Number of passengers (pax)
9. **Luggage Count**: Number of bags (number_bags)
10. **Payment Collection**: Toggle switch only (amount completed later in transport details)
11. **Notes**: General job notes (flight details, etc.)

**Validation**:
- Required fields validation (client, vehicle, driver, location, date, passenger count, luggage count)
- Date validation (job start date must be future)
- Contact number format validation
- Branch location selection validation

**Progress Tracking**:
- Dynamic completion percentage (0-100%) based on required fields
- Real-time progress indicator with contextual messages
- Visual progress bar showing completion status
- Step indicator showing "Step 1 of 1: Job Details"

### 4. Job Creation - Step 2 (`lib/features/jobs/screens/trip_management_screen.dart`)

**Purpose**: Manage transport details and trips

**Features**:
- **Add New Trip**: Form for trip details
- **Trip List**: Display existing trips with edit/delete options
- **Trip Summary**: Short summary of each trip
- **Total Amount**: Calculate and display total trip amount
- **Payment Amount**: Complete payment amount for jobs with collection enabled

**Trip Form Fields**:
1. **Date & Time**: DateTime picker
2. **Pick-up Address**: Text input
3. **Drop-off Address**: Text input
4. **Notes**: Trip-specific notes
5. **Amount**: Trip cost
6. **Payment Amount**: Final payment amount (if collection was enabled in Step 1)

**Actions**:
- Add new trip
- Edit existing trip
- Delete trip
- Confirm all trips

### 5. Job Summary Screen (`lib/features/jobs/screens/job_summary_screen.dart`)

**Purpose**: Comprehensive job overview accessible from job cards

**Display Sections**:
1. **Job Status Card**: Visual status indicator with job ID and days until start
2. **Job Details**: All captured job information (ID, status, dates, location)
3. **Client Information**: Client and agent details
4. **Passenger Information**: Name, contact, and completeness warnings
5. **Vehicle Information**: Vehicle details with license status
6. **Driver Information**: Driver details with license/PDP status
7. **Branch Information**: Branch location (Jhb, Cpt, Dbn)
8. **Payment Information**: Collection details and amount
9. **Notes**: Job-specific notes and instructions
10. **Trip Summary**: Overview of all trips and total amounts
11. **Trip Details**: Detailed list of all trips with amounts (when available)

**Navigation**: Accessible via "VIEW" button on job cards or direct URL navigation

## Navigation Flow

### Router Configuration (`lib/app/router.dart`)
```dart
// Job management routes
GoRoute(
  path: '/jobs',
  name: 'jobs',
  builder: (context, state) => const JobsScreen(),
),
GoRoute(
  path: '/jobs/create',
  name: 'create_job',
  builder: (context, state) => const CreateJobScreen(),
),
GoRoute(
  path: '/jobs/:id/trip-management',
  name: 'trip_management',
  builder: (context, state) => TripManagementScreen(
    jobId: state.pathParameters['id']!,
  ),
),
GoRoute(
  path: '/jobs/:id/summary',
  name: 'job_summary',
  builder: (context, state) => JobSummaryScreen(
    jobId: state.pathParameters['id']!,
  ),
),
```

### Navigation Sequence
1. **Jobs List** → **Create Job** (Step 1)
2. **Create Job** → **Trip Management** (Step 2)
3. **Trip Management** → **Job Summary** (Final)
4. **Job Summary** → **Jobs List** (Complete)

### Job Card Navigation
1. **Jobs List** → **Job Summary** (via "VIEW" button)
2. **Job Summary** → **Jobs List** (via "Back to Jobs" button)
3. **Job Summary** → **Edit Job** (via "Edit Job" button - when implemented)

## Key Features

### Role-Based Access Control
- **Visibility**: Jobs filtered based on user role
- **Actions**: Create/edit permissions based on role
- **Data Security**: Users only see authorized data

### Status Management
- **Open Jobs**: Newly created jobs awaiting execution
- **In Progress**: Jobs currently being executed
- **Completed Jobs**: Finished jobs (includes both 'closed' and 'completed' statuses)
- **Filter Integration**: Seamless filtering between status types

### Validation Indicators
- **License Validity**: Visual indicators for expired licenses
- **PDP Status**: Indicators for expired PDP
- **Passenger Details**: Warning for incomplete passenger information
- **Days Until Start**: Countdown display for job start

### Search and Filtering
- **Status Filtering**: Quick toggle between job statuses
- **Text Search**: Search across passenger name, client, and job ID
- **Real-time Results**: Instant filtering and search results
- **Mobile Responsive**: Horizontal scrolling for filter buttons

### Multi-step Form
- **Progressive Disclosure**: Complex form broken into manageable steps
- **Data Persistence**: Form data maintained between steps
- **Validation**: Step-by-step validation with clear error messages

### Trip Management
- **Dynamic Trip Addition**: Add multiple trips to a job
- **Trip Editing**: Modify existing trips
- **Amount Calculation**: Automatic total calculation
- **Trip Summary**: Concise trip information display

## Recent Fixes and Updates

### View Button Functionality Implementation (Latest)
- **Interactive Job Cards**: Added clickable "VIEW" buttons on job cards
- **Job Summary Navigation**: Direct navigation from job cards to detailed job summary
- **Comprehensive Job Details**: Complete job overview with all related information
- **Error Handling**: Graceful handling of missing database tables and short job IDs
- **Responsive Design**: Optimized card layout to prevent overflow errors

### Payment Collection Workflow Update
- **Streamlined Job Creation**: Payment amount field removed from initial job creation
- **Two-Step Payment Process**: 
  - Step 1: Toggle payment collection switch only
  - Step 2: Complete payment amount in transport details
- **Improved User Experience**: Cleaner job creation form with payment details handled later
- **Better Workflow**: Payment amounts are finalized when transport details are known

### Database Field Mapping Corrections
- **Fixed Field Names**: Updated model to match actual database schema
  - `pas_count` → `pax` (passenger count)
  - `luggage_count` → `number_bags` (luggage count)
  - `collect_payment` → `amount_collect` (payment collection flag)
  - `payment_amount` → `amount` (payment amount)
- **Updated Field Types**: Corrected data types to match database
  - `pasCount`: `int` → `double` (to match database `numeric` type)
  - `luggageCount`: `int` → `String` (to match database `text` type)
- **Added Missing Fields**: Included previously missing database fields
  - `quoteNo` (maps to `quote_no`)
  - `voucherPdf` (maps to `voucher_pdf`)
  - `cancelReason` (maps to `cancel_reason`)
- **Removed Non-Existent Field**: Removed `branch` field (doesn't exist in database)

### UI Improvements
- **Mobile Responsiveness**: Fixed filter button overflow on mobile screens
- **Job Card Updates**: Updated to show job ID instead of non-existent branch field
- **Search Functionality**: Updated to search by job ID instead of branch
- **Status Handling**: Improved handling of 'completed' vs 'closed' statuses
- **Form Simplification**: Removed payment amount field from job creation for cleaner workflow
- **Payment Workflow**: Payment amounts now completed in transport details step
- **Interactive Job Cards**: Added clickable view buttons with navigation functionality
- **Card Layout Optimization**: Reduced card height and spacing to prevent overflow errors
- **Job Summary Screen**: Enhanced with comprehensive job details and error handling

### Performance Optimizations
- **Database Queries**: Simplified queries by removing problematic joins
- **Field Mapping**: Efficient type conversion for database fields
- **Error Handling**: Improved error handling for database operations

## Error Handling

### Form Validation
- Required field validation
- Date range validation
- Contact number format validation
- Amount validation (positive numbers) - now handled in transport details step
- Job ID length validation - prevents substring errors on short IDs

### Database Errors
- Connection error handling
- Constraint violation handling
- Rollback mechanisms for failed operations
- Field mapping error handling

### User Feedback
- Loading states during operations
- Success/error messages
- Confirmation dialogs for destructive actions
- Debug output for troubleshooting

## Performance Considerations

### Data Loading
- **Lazy Loading**: Load job details on demand
- **Pagination**: Implement pagination for large job lists
- **Caching**: Cache frequently accessed data
- **Optimized Queries**: Simplified database queries for better performance

### UI Responsiveness
- **Async Operations**: Non-blocking UI during database operations
- **Loading States**: Visual feedback during data operations
- **Optimistic Updates**: Immediate UI updates with rollback on failure
- **Mobile Optimization**: Responsive design for all screen sizes

## Security Considerations

### Data Access
- **Row-Level Security**: Database-level access control
- **Role Validation**: Server-side role verification
- **Input Sanitization**: Prevent SQL injection and XSS
- **Field Validation**: Proper type checking and validation

### User Permissions
- **Action Authorization**: Verify permissions before operations
- **Data Filtering**: Filter data based on user role
- **Audit Trail**: Track job creation and modifications
- **Secure Field Mapping**: Proper handling of database field names

## Current Implementation Status

### ✅ Completed Features
- **Database Integration**: Successfully connected to Supabase
- **Field Mapping**: All database fields correctly mapped
- **Job Listing**: Jobs display correctly with proper filtering
- **Status Management**: Open, in progress, and completed jobs working
- **Search Functionality**: Search by passenger name, client, and job ID
- **Mobile Responsiveness**: Filter buttons work on mobile screens
- **Role-Based Access**: Proper job visibility based on user role
- **Payment Workflow**: Streamlined payment collection process (toggle in Step 1, amount in Step 2)
- **View Button Functionality**: Interactive job cards with navigation to detailed job summaries
- **Job Summary Screen**: Comprehensive job details display with error handling
- **Card Layout Optimization**: Fixed overflow issues and improved responsive design
- **Branch Location Field**: Added location field to jobs table and job creation form
- **Progress Indicator**: Dynamic completion tracking (0-100%) with contextual messages
- **Vehicle Sorting**: Alphabetical sorting of vehicles by make in dropdown
- **Multi-step Navigation**: Seamless navigation from job creation to trip management
- **Error Handling**: Improved error messages and validation feedback

### 🔄 In Progress
- **Job Creation Flow**: Multi-step form implementation
- **Trip Management**: Trip creation and management
- **Job Editing**: Edit functionality for existing jobs

### 📋 Planned Features
- **Job Templates**: Pre-defined job configurations
- **Bulk Operations**: Multi-job management
- **Advanced Reporting**: Job analytics and reporting
- **Notification System**: Job status change notifications
- **Export Functionality**: Export job data to various formats

## Future Enhancements

### Planned Features
- **Job Templates**: Pre-defined job configurations
- **Bulk Operations**: Multi-job management
- **Advanced Reporting**: Job analytics and reporting
- **Notification System**: Job status change notifications
- **Mobile Optimization**: Enhanced mobile experience

### Technical Improvements
- **Offline Support**: Work offline with sync capabilities
- **Real-time Updates**: WebSocket integration for live updates
- **Advanced Search**: Full-text search with filters
- **Export Functionality**: Export job data to various formats
- **Performance Monitoring**: Track and optimize database queries

## Recent Updates (Latest Implementation)

### Branch Location Feature
- **Database Schema**: Added `location` field to jobs table
- **Job Model**: Updated to include location field with proper mapping
- **Form Integration**: Added Branch dropdown with three options (Jhb, Cpt, Dbn)
- **Validation**: Required field validation for location selection
- **Data Persistence**: Location value saved to database on job creation

### Progress Indicator Enhancement
- **Dynamic Calculation**: Real-time completion percentage based on required fields
- **Visual Feedback**: Progress bar with percentage display
- **Contextual Messages**: Helpful status messages based on completion level
- **Required Fields**: Updated to include location field (7 total required fields)

### Vehicle Dropdown Improvements
- **Alphabetical Sorting**: Vehicles sorted by make for better usability
- **Visual Indicators**: License expiry warnings for vehicles
- **Consistent Styling**: Matches other dropdown components

### Multi-step Form Flow
- **Step 1 to Step 2 Navigation**: Automatic navigation to trip management after job creation
- **Data Continuity**: Job ID passed to trip management screen
- **User Feedback**: Success message and clear navigation flow

### Error Handling Improvements
- **User-friendly Messages**: Clear error messages instead of technical details
- **Form Validation**: Enhanced validation with specific field requirements
- **Database Error Resolution**: Fixed PostgreSQL type mismatches and constraint violations
- **Table Name Correction**: Fixed trip management to use correct `transport` table instead of non-existent `trips` table
