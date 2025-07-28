1. Purpose
Enable Admins and Managers to manage the fleet of vehicles used by the company, including adding new vehicles, viewing all existing vehicles, updating details like license expiry, and tracking vehicle status and documentation such as the registration date and fuel type.

2. Supabase Table: vehicles
Fields:
Field Name	Type	Description
id	int8	Primary Key
make	text	Vehicle manufacturer (e.g., Toyota)
model	text	Vehicle model (e.g., Corolla)
reg_plate	text	License plate number
reg_date	date	Registration date
fuel_type	text	Petrol / Diesel / Hybrid / Electric
vehicle_image	text	Supabase Storage path
status	text	active or deactive
license_expiry_date	date	When the license expires
created_at	timestamptz	Auto-generated
updated_at	timestamptz	Auto-updated on edit

📌 License Expiry Validation Logic
✅ Valid = Expiry is more than 3 months from today

⚠️ Expiring Soon = Expiry is within 3 months

❌ Expired = Expiry is in the past

This is visually reflected using badges (green, orange, red) beside the expiry date.

3. Permissions
Action	Role
View all vehicles	All roles
Add new vehicle	Admin, Manager only
Edit vehicle details	Admin, Manager only
Upload/change image	Admin, Manager only

Permission guards will be handled via a utility like PermissionService checking the current user's role before navigating or showing action buttons.

4. Dashboard Quick Action Card
Location:
Top-level dashboard

UI:
Icon: Car or vehicle icon (same visual language as Driver)

Title: “Vehicles”

On Tap: Navigates to VehicleListScreen

5. VehicleListScreen
Shown to All Users:
List of all vehicles with key details:

make + model

reg_plate

FAB:
"Add Vehicle" button only visible for Admin/Manager

Opens VehicleEditorScreen in create mode

Navigation:
Tapping a vehicle opens VehicleEditorScreen in edit mode

6. VehicleEditorScreen
Layout:
Reuse the visual design and structure from EditDriverDialog

Form-based layout with grouped input sections

Fields:
Field	Editable?	Notes
make	❌	Shown, but not editable
model	❌	Shown, but not editable
vehicle_image	✅	Upload/replace via Supabase Storage. Show placeholder if null
reg_plate	✅	Text input
reg_date	✅	Date picker
fuel_type	✅	Dropdown (if fixed options) or text input
status	✅	Dropdown: active / deactive
license_expiry_date	✅	Date picker with badge feedback
license_status_indicator	🟩🟧🟥	Badge displayed based on expiry validation logic

7. Architecture Overview
Layer	Technology
State Management	Riverpod: StateNotifier + VehicleFormState
Backend	Supabase: Postgres DB, Storage, RLS
Routing	GoRouter
Theming	TradeTrack/CLC Material 3 Theme
Form Validation	Basic required field checks on Reg Plate, Expiry Date, Fuel Type

8. Future Enhancements
Associate vehicle with Jobs or Trips

Track maintenance records

Add PDF of vehicle documents (registration, license disk, etc.)

Auto-reminders/notifications for license expiry using Supabase Functions