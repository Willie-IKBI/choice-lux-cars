# Quote Management Flow Documentation

## Overview
The Quote Management System is a comprehensive feature that allows users to create, manage, and share professional quotes for luxury car transportation services. The system mirrors the jobs flow but operates independently with its own data structure and workflow.

## Table of Contents
1. [Database Schema](#database-schema)
2. [User Roles & Permissions](#user-roles--permissions)
3. [Core Components](#core-components)
4. [Quote Lifecycle](#quote-lifecycle)
5. [UI Flow & Screens](#ui-flow--screens)
6. [PDF Generation](#pdf-generation)
7. [Transport Details Management](#transport-details-management)
8. [API Integration](#api-integration)
9. [Error Handling](#error-handling)
10. [Future Enhancements](#future-enhancements)

---

## Database Schema

### Quotes Table
```sql
CREATE TABLE quotes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES clients(id),
  agent_id UUID REFERENCES profiles(id),
  vehicle_id UUID REFERENCES vehicles(id),
  driver_id UUID REFERENCES profiles(id),
  job_date DATE NOT NULL,
  vehicle_type VARCHAR(50),
  quote_status VARCHAR(20) DEFAULT 'draft',
  pas_count DECIMAL NOT NULL,
  luggage TEXT NOT NULL,
  passenger_name VARCHAR(255),
  passenger_contact VARCHAR(50),
  notes TEXT,
  quote_pdf TEXT,
  quote_date TIMESTAMP DEFAULT NOW(),
  quote_amount DECIMAL(10,2),
  quote_title VARCHAR(255),
  quote_description TEXT,
  location VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Quotes Transport Details Table
```sql
CREATE TABLE quotes_transport_details (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_id UUID REFERENCES quotes(id) ON DELETE CASCADE,
  pickup_date TIMESTAMP NOT NULL,
  pickup_location TEXT NOT NULL,
  dropoff_location TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Key Relationships
- **quotes.client_id** → **clients.id** (Client information)
- **quotes.agent_id** → **profiles.id** (Agent/Manager who created the quote)
- **quotes.vehicle_id** → **vehicles.id** (Assigned vehicle)
- **quotes.driver_id** → **profiles.id** (Assigned driver)
- **quotes_transport_details.quote_id** → **quotes.id** (Transport legs for the quote)

---

## User Roles & Permissions

### Role-Based Access Control
- **Administrator**: Full access to create, edit, delete, and manage all quotes
- **Manager**: Full access to create, edit, and manage quotes
- **Agent**: Read-only access to quotes (can view but not edit)
- **Driver**: Read-only access to assigned quotes

### Permission Matrix
| Action | Admin | Manager | Agent | Driver |
|--------|-------|---------|-------|--------|
| Create Quote | ✅ | ✅ | ❌ | ❌ |
| Edit Quote | ✅ | ✅ | ❌ | ❌ |
| Delete Quote | ✅ | ❌ | ❌ | ❌ |
| Generate PDF | ✅ | ✅ | ❌ | ❌ |
| View PDF | ✅ | ✅ | ✅ | ✅ |
| Share Quote | ✅ | ✅ | ✅ | ✅ |
| Manage Transport Details | ✅ | ✅ | ❌ | ❌ |
| Update Status | ✅ | ✅ | ❌ | ❌ |

---

## Core Components

### 1. Data Models

#### Quote Model (`lib/features/quotes/models/quote.dart`)
```dart
class Quote {
  final String id;
  final String clientId;
  final String? agentId;
  final String? vehicleId;
  final String? driverId;
  final DateTime jobDate;
  final String? vehicleType;
  final String quoteStatus;
  final double pasCount;
  final String luggage;
  final String? passengerName;
  final String? passengerContact;
  final String? notes;
  final String? quotePdf;
  final DateTime quoteDate;
  final double? quoteAmount;
  final String? quoteTitle;
  final String? quoteDescription;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

#### QuoteTransportDetail Model (`lib/features/quotes/models/quote_transport_detail.dart`)
```dart
class QuoteTransportDetail {
  final String id;
  final String quoteId;
  final DateTime pickupDate;
  final String pickupLocation;
  final String dropoffLocation;
  final double amount;
  final String? notes;
}
```

### 2. State Management

#### Quotes Provider (`lib/features/quotes/providers/quotes_provider.dart`)
- **StateNotifierProvider**: Manages quotes list and operations
- **FutureProvider.family**: Manages transport details for specific quotes
- **Methods**:
  - `fetchQuotes()`: Load all quotes for current user
  - `createQuote()`: Create new quote
  - `updateQuote()`: Update existing quote
  - `deleteQuote()`: Delete quote
  - `getQuote()`: Fetch single quote by ID
  - `getQuoteTransportDetails()`: Fetch transport details for quote

### 3. Services

#### Supabase Service Integration (`lib/core/services/supabase_service.dart`)
- **Database Operations**:
  - `createQuote()`: Insert new quote
  - `getQuotes()`: Fetch quotes with filters
  - `updateQuote()`: Update quote data
  - `deleteQuote()`: Remove quote
  - `getQuoteTransportDetails()`: Fetch transport legs
  - `createQuoteTransportDetail()`: Add transport leg
  - `updateQuoteTransportDetail()`: Update transport leg
  - `deleteQuoteTransportDetail()`: Remove transport leg

#### PDF Service (`lib/features/quotes/services/quote_pdf_service.dart`)
- **PDF Generation**: Creates professional quote PDFs
- **Features**:
  - Company branding with Choice Lux Cars logo
  - Dynamic data integration
  - Transport details breakdown
  - Professional formatting
  - Supabase Storage integration

---

## Quote Lifecycle

### 1. Quote Creation
```
User Action → Form Validation → Database Insert → Success Notification
```

**Process Flow**:
1. User clicks "Create Quote" from dashboard
2. Form validation ensures required fields
3. Quote saved with status "draft"
4. User redirected to quote details

### 2. Quote Status Progression
```
Draft → Open → Sent → Accepted/Rejected → Closed
```

**Status Definitions**:
- **Draft**: Initial state, editable
- **Open**: Ready for review
- **Sent**: Sent to client
- **Accepted**: Client approved
- **Rejected**: Client declined
- **Expired**: Past validity period
- **Closed**: Completed or cancelled

### 3. PDF Generation Workflow
```
Generate Request → Data Fetch → PDF Creation → Storage Upload → URL Update
```

**Technical Process**:
1. Fetch quote data and related entities
2. Generate PDF using QuotePdfService
3. Upload to Supabase Storage bucket "pdfdocuments"
4. Update quote with public URL
5. Provide user feedback with view option

---

## UI Flow & Screens

### 1. Dashboard Integration
**Location**: `lib/features/dashboard/dashboard_screen.dart`
- **Quote Card**: Shows quote statistics and quick actions
- **Navigation**: Direct link to quotes list

### 2. Quotes List Screen (`lib/features/quotes/quotes_screen.dart`)
**Features**:
- **Responsive Design**: Mobile, tablet, and desktop layouts
- **Search & Filter**: By status, date, client
- **View Toggle**: Grid and list views
- **Status Indicators**: Color-coded status badges
- **Quick Actions**: View details, generate PDF

**Layout Options**:
- **Desktop**: 3-column grid
- **Tablet**: 2-column grid
- **Mobile**: Single column list

### 3. Create Quote Screen (`lib/features/quotes/screens/create_quote_screen.dart`)
**Form Sections**:
- **Client Selection**: Dropdown with search
- **Agent Assignment**: Based on selected client
- **Trip Details**: Date, location, vehicle type
- **Passenger Information**: Count, luggage, contact
- **Quote Details**: Title, description, amount
- **Driver Assignment**: Available drivers with validation

**Validation Rules**:
- Required fields: client, job date, passenger count, luggage
- Date validation: Job date must be future date
- Driver validation: Check PDP and license expiry

### 4. Quote Details Screen (`lib/features/quotes/screens/quote_details_screen.dart`)
**View Modes**:
- **Read Mode**: Display quote information
- **Edit Mode**: Form-based editing (Admin/Manager only)

**Action Buttons**:
- **Generate PDF**: Create new PDF (when none exists)
- **Regenerate PDF**: Recreate existing PDF
- **Share Quote**: Copy link or email
- **View PDF**: Open existing PDF
- **Transport Details**: Navigate to transport management
- **Status Management**: Update quote status

**Information Sections**:
- **Header**: Quote ID, title, status, amounts
- **Passenger Information**: Name, contact, count, luggage
- **Trip Information**: Date, location, vehicle type
- **Quote Details**: Title, description, status
- **Additional Notes**: Optional notes section

### 5. Transport Details Screen (`lib/features/quotes/screens/quote_transport_details_screen.dart`)
**Features**:
- **Transport Legs**: Multiple pickup/dropoff points
- **Pricing Calculation**: Automatic total calculation
- **Visual Route**: Map-like display of route
- **CRUD Operations**: Add, edit, delete transport legs

---

## PDF Generation

### PDF Service Architecture
**File**: `lib/features/quotes/services/quote_pdf_service.dart`

**Components**:
- **Header**: Company logo and branding
- **Quote Information**: ID, date, status, amounts
- **Client Details**: Name, contact, address
- **Trip Information**: Date, location, vehicle details
- **Transport Breakdown**: Individual leg details with pricing
- **Terms & Conditions**: Standard terms
- **Footer**: Contact information

**Technical Implementation**:
```dart
Future<Uint8List> buildQuotePdf({
  required Quote quote,
  required List<QuoteTransportDetail> transportDetails,
  required Map<String, dynamic> clientData,
  required Map<String, dynamic>? agentData,
  required Map<String, dynamic>? vehicleData,
  required Map<String, dynamic>? driverData,
}) async
```

### Storage Integration
- **Bucket**: `pdfdocuments`
- **Path Structure**: `quotes/quote_{id}.pdf`
- **Public URLs**: Automatically generated for sharing
- **Cache Busting**: URL parameters prevent caching issues

---

## Transport Details Management

### Transport Leg Structure
Each transport leg contains:
- **Pickup Date/Time**: When to collect passenger
- **Pickup Location**: Where to collect from
- **Dropoff Location**: Where to deliver to
- **Amount**: Cost for this leg
- **Notes**: Additional instructions

### Pricing Calculation
- **Individual Legs**: Each leg has its own pricing
- **Total Calculation**: Sum of all transport legs
- **Quote Amount**: Base quote + transport total
- **Display**: Shows breakdown in quote details

---

## API Integration

### Supabase Integration Points

#### Authentication
- **Row Level Security (RLS)**: Ensures users only see their data
- **Role-based Policies**: Different access levels per role
- **Real-time Updates**: Live data synchronization

#### Storage
- **PDF Documents**: Stored in `pdfdocuments` bucket
- **Public Access**: PDFs accessible via public URLs
- **File Management**: Automatic cleanup and overwrite handling

#### Database Operations
```dart
// Create quote
final response = await supabase
    .from('quotes')
    .insert(quoteData)
    .select()
    .single();

// Update quote
await supabase
    .from('quotes')
    .update(updateData)
    .eq('id', quoteId);

// Fetch with relations
final response = await supabase
    .from('quotes')
    .select('*, clients(*), profiles(*)')
    .eq('id', quoteId);
```

---

## Error Handling

### Common Error Scenarios

#### 1. Database Errors
- **Missing Columns**: Graceful handling of schema mismatches
- **Foreign Key Violations**: Validation before operations
- **Connection Issues**: Retry mechanisms and user feedback

#### 2. PDF Generation Errors
- **Missing Data**: Validation of required fields
- **Storage Issues**: Fallback mechanisms
- **Format Errors**: Error logging and user notification

#### 3. Permission Errors
- **Unauthorized Access**: Role-based UI hiding
- **Invalid Operations**: Clear error messages
- **Session Expiry**: Automatic redirect to login

### Error Recovery
- **Automatic Retries**: For transient failures
- **User Feedback**: Clear error messages with actions
- **Fallback Options**: Alternative paths when primary fails

---

## Future Enhancements

### Planned Features

#### 1. Advanced PDF Features
- **Custom Templates**: Multiple quote templates
- **Digital Signatures**: Client approval workflow
- **Multi-language Support**: International quote support

#### 2. Communication Integration
- **Email Automation**: Automatic quote sending
- **SMS Notifications**: Status updates via SMS
- **Client Portal**: Self-service quote access

#### 3. Analytics & Reporting
- **Quote Analytics**: Success rates, conversion tracking
- **Financial Reports**: Revenue analysis by quote type
- **Performance Metrics**: Agent and driver performance

#### 4. Workflow Automation
- **Approval Workflows**: Multi-level quote approval
- **Expiry Management**: Automatic status updates
- **Follow-up Reminders**: Automated client communication

### Technical Improvements
- **Caching**: PDF caching for faster access
- **Batch Operations**: Bulk quote management
- **API Rate Limiting**: Protection against abuse
- **Audit Trail**: Complete action logging

---

## Configuration & Setup

### Environment Variables
```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
STORAGE_BUCKET=pdfdocuments
```

### Required Dependencies
```yaml
dependencies:
  supabase_flutter: ^latest
  flutter_riverpod: ^latest
  go_router: ^latest
  pdf: ^latest
  url_launcher: ^latest
  intl: ^latest
```

### Database Setup
1. Run migration scripts for quotes tables
2. Set up RLS policies
3. Configure storage bucket permissions
4. Test user role assignments

---

## Testing Strategy

### Unit Tests
- **Model Validation**: Quote and transport detail models
- **Provider Logic**: State management operations
- **PDF Generation**: Service functionality

### Integration Tests
- **Database Operations**: CRUD operations
- **PDF Workflow**: End-to-end PDF generation
- **Permission System**: Role-based access

### UI Tests
- **Screen Navigation**: Flow between screens
- **Form Validation**: Input validation and error handling
- **Responsive Design**: Different screen sizes

---

## Performance Considerations

### Optimization Strategies
- **Lazy Loading**: Load data on demand
- **Caching**: Cache frequently accessed data
- **Pagination**: Large quote lists
- **Image Optimization**: Compressed PDFs

### Monitoring
- **Error Tracking**: Comprehensive error logging
- **Performance Metrics**: Response times and throughput
- **User Analytics**: Usage patterns and bottlenecks

---

## Security Considerations

### Data Protection
- **Encryption**: Sensitive data encryption
- **Access Control**: Strict permission enforcement
- **Audit Logging**: Complete action tracking
- **Input Validation**: Prevent injection attacks

### Compliance
- **GDPR**: Data privacy compliance
- **PCI DSS**: Payment data security
- **Local Regulations**: Country-specific requirements

---

This documentation provides a comprehensive overview of the Quote Management System. For specific implementation details, refer to the individual source files and their inline documentation.
