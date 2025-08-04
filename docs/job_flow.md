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
- **`closed`**: Completed jobs

## Database Schema

### Jobs Table
```sql
CREATE TABLE jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES clients(id),
  agent_id UUID REFERENCES agents(id),
  branch TEXT NOT NULL CHECK (branch IN ('Johannesburg', 'Cape Town', 'Durban')),
  vehicle_id UUID REFERENCES vehicles(id),
  driver_id UUID REFERENCES profiles(id),
  job_start_date DATE NOT NULL,
  order_date DATE NOT NULL DEFAULT CURRENT_DATE,
  passenger_name TEXT,
  passenger_contact TEXT,
  pas_count INTEGER NOT NULL,
  luggage_count INTEGER NOT NULL,
  notes TEXT,
  collect_payment BOOLEAN DEFAULT false,
  payment_amount DECIMAL(10,2),
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'closed')),
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Trips Table
```sql
CREATE TABLE trips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
  trip_date_time TIMESTAMP WITH TIME ZONE NOT NULL,
  pick_up_address TEXT NOT NULL,
  drop_off_address TEXT NOT NULL,
  notes TEXT,
  amount DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## File Structure

```
lib/features/jobs/
├── models/
│   ├── job.dart          # Job data model
│   └── trip.dart         # Trip data model
├── providers/
│   └── jobs_provider.dart # State management for jobs and trips
├── screens/
│   ├── create_job_screen.dart      # Step 1: Job details creation
│   ├── trip_management_screen.dart # Step 2: Trip management
│   └── job_summary_screen.dart     # Final summary screen
├── widgets/
│   └── job_card.dart     # Job display component
└── jobs_screen.dart      # Main jobs list screen
```

## Core Components

### 1. Data Models

#### Job Model (`lib/features/jobs/models/job.dart`)
```dart
class Job {
  final String id;
  final String clientId;
  final String agentId;
  final String branch;
  final String vehicleId;
  final String driverId;
  final DateTime jobStartDate;
  final DateTime orderDate;
  final String? passengerName;
  final String? passengerContact;
  final int pasCount;
  final int luggageCount;
  final String? notes;
  final bool collectPayment;
  final double? paymentAmount;
  final String status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Helper getters
  bool get hasCompletePassengerDetails;
  bool get isOpen;
  bool get isInProgress;
  bool get isClosed;
  String get daysUntilStartText;
}
```

#### Trip Model (`lib/features/jobs/models/trip.dart`)
```dart
class Trip {
  final String id;
  final String jobId;
  final DateTime tripDateTime;
  final String pickUpAddress;
  final String dropOffAddress;
  final String? notes;
  final double amount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Helper getters
  String get shortSummary;
  String get formattedDateTime;
}
```

### 2. State Management (`lib/features/jobs/providers/jobs_provider.dart`)

#### JobsNotifier
- **Purpose**: Manages job state and operations
- **Key Methods**:
  - `getJobs()`: Fetches jobs based on user role
  - `getJobsByDriver()`: Fetches jobs for specific driver
  - `getJobsByDriverManager()`: Fetches jobs for driver manager
  - `createJob()`: Creates new job
  - `updateJob()`: Updates existing job
  - `deleteJob()`: Deletes job

#### TripsNotifier
- **Purpose**: Manages trip state for a specific job
- **Key Methods**:
  - `getTripsForJob()`: Fetches trips for a job
  - `addTrip()`: Adds new trip
  - `updateTrip()`: Updates existing trip
  - `deleteTrip()`: Deletes trip
  - `getTotalAmount()`: Calculates total trip amount

### 3. Database Service (`lib/core/services/supabase_service.dart`)

#### Job Operations
```dart
// Fetch jobs with role-based filtering
Future<List<Job>> getJobs(String? userId, String? userRole);
Future<List<Job>> getJobsByDriver(String driverId);
Future<List<Job>> getJobsByDriverManager(String driverManagerId);

// CRUD operations
Future<Job> createJob(Map<String, dynamic> jobData);
Future<Job> updateJob(String jobId, Map<String, dynamic> updates);
Future<void> deleteJob(String jobId);
```

#### Trip Operations
```dart
// Trip management
Future<List<Trip>> getTripsForJob(String jobId);
Future<Trip> createTrip(Map<String, dynamic> tripData);
Future<Trip> updateTrip(String tripId, Map<String, dynamic> updates);
Future<void> deleteTrip(String tripId);
```

## User Interface Flow

### 1. Jobs List Screen (`lib/features/jobs/jobs_screen.dart`)

**Purpose**: Main entry point for job management

**Features**:
- **Status Filtering**: Toggle between open, in_progress, closed, and all jobs
- **Search Functionality**: Search by passenger name, client, or branch
- **Role-Based Actions**: "Create Job" button only visible to authorized users
- **Job Cards**: Display job information with visual indicators

**Key Components**:
```dart
class JobsScreen extends ConsumerStatefulWidget {
  // Status filter dropdown
  // Search bar
  // Create job button (role-based)
  // Job list with JobCard widgets
}
```

### 2. Job Creation - Step 1 (`lib/features/jobs/screens/create_job_screen.dart`)

**Purpose**: Capture initial job details

**Form Fields**:
1. **Client Selection**: Dropdown with search functionality
2. **Agent Selection**: Auto-populated from selected client
3. **Branch Selection**: Johannesburg, Cape Town, or Durban
4. **Vehicle Selection**: Shows make, model, registration, license validity
5. **Driver Selection**: Shows name, surname, license/PDP validity indicators
6. **Job Start Date**: Date picker for job commencement
7. **Passenger Details**: Name and contact (optional with indicator)
8. **Passenger Count**: Number of passengers (PAS)
9. **Luggage Count**: Number of bags
10. **Payment Collection**: Toggle with amount field
11. **Notes**: General job notes (flight details, etc.)

**Validation**:
- Required fields validation
- Date validation (job start date must be future)
- Contact number format validation

### 3. Job Creation - Step 2 (`lib/features/jobs/screens/trip_management_screen.dart`)

**Purpose**: Manage transport details and trips

**Features**:
- **Add New Trip**: Form for trip details
- **Trip List**: Display existing trips with edit/delete options
- **Trip Summary**: Short summary of each trip
- **Total Amount**: Calculate and display total trip amount

**Trip Form Fields**:
1. **Date & Time**: DateTime picker
2. **Pick-up Address**: Text input
3. **Drop-off Address**: Text input
4. **Notes**: Trip-specific notes
5. **Amount**: Trip cost

**Actions**:
- Add new trip
- Edit existing trip
- Delete trip
- Confirm all trips

### 4. Job Summary Screen (`lib/features/jobs/screens/job_summary_screen.dart`)

**Purpose**: Final overview of created job

**Display Sections**:
1. **Job Details**: All captured job information
2. **Client Information**: Client and agent details
3. **Vehicle Information**: Vehicle details with license status
4. **Driver Information**: Driver details with license/PDP status
5. **Payment Information**: Collection details and amount
6. **Trip Summary**: Overview of all trips
7. **Trip Details**: Detailed list of all trips with amounts

## Navigation Flow

### Router Configuration (`lib/app/router.dart`)
```dart
// Job management routes
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

## Key Features

### Role-Based Access Control
- **Visibility**: Jobs filtered based on user role
- **Actions**: Create/edit permissions based on role
- **Data Security**: Users only see authorized data

### Validation Indicators
- **License Validity**: Visual indicators for expired licenses
- **PDP Status**: Indicators for expired PDP
- **Passenger Details**: Warning for incomplete passenger information
- **Days Until Start**: Countdown display for job start

### Search and Filtering
- **Status Filtering**: Quick toggle between job statuses
- **Text Search**: Search across multiple fields
- **Real-time Results**: Instant filtering and search results

### Multi-step Form
- **Progressive Disclosure**: Complex form broken into manageable steps
- **Data Persistence**: Form data maintained between steps
- **Validation**: Step-by-step validation with clear error messages

### Trip Management
- **Dynamic Trip Addition**: Add multiple trips to a job
- **Trip Editing**: Modify existing trips
- **Amount Calculation**: Automatic total calculation
- **Trip Summary**: Concise trip information display

## Error Handling

### Form Validation
- Required field validation
- Date range validation
- Contact number format validation
- Amount validation (positive numbers)

### Database Errors
- Connection error handling
- Constraint violation handling
- Rollback mechanisms for failed operations

### User Feedback
- Loading states during operations
- Success/error messages
- Confirmation dialogs for destructive actions

## Performance Considerations

### Data Loading
- **Lazy Loading**: Load job details on demand
- **Pagination**: Implement pagination for large job lists
- **Caching**: Cache frequently accessed data

### UI Responsiveness
- **Async Operations**: Non-blocking UI during database operations
- **Loading States**: Visual feedback during data operations
- **Optimistic Updates**: Immediate UI updates with rollback on failure

## Security Considerations

### Data Access
- **Row-Level Security**: Database-level access control
- **Role Validation**: Server-side role verification
- **Input Sanitization**: Prevent SQL injection and XSS

### User Permissions
- **Action Authorization**: Verify permissions before operations
- **Data Filtering**: Filter data based on user role
- **Audit Trail**: Track job creation and modifications

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
