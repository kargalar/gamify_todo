# SelectTime Dialog - Initialize Previous State (v1.8)

## Overview
When opening the time picker dialog (selectTime), the previously selected notification/alarm state and early reminder minutes are now initialized and displayed. This provides better UX by showing users their last selections instead of starting fresh.

## Changes Made

### 1. Helper.selectTime() Method Enhancement
**File:** `lib/Core/helper.dart` (lines 406-418)

**Added Parameters:**
```dart
Future<Map<String, dynamic>?> selectTime(
  BuildContext context, {
  TimeOfDay? initialTime,
  DateTime? referenceDate,
  int? initialNotificationAlarmState,        // NEW ✅
  int? initialEarlyReminderMinutes,          // NEW ✅
})
```

**Implementation:**
```dart
int notificationAlarmState = initialNotificationAlarmState ?? 0;
int? earlyReminderMinutes = initialEarlyReminderMinutes;
```

**Behavior:**
- If `initialNotificationAlarmState` is provided: dialog shows that state (0=Off, 1=Notification, 2=Alarm)
- If `initialEarlyReminderMinutes` is provided: those reminder buttons are pre-selected
- If neither is provided: defaults to state 0 (Off) with no early reminder

---

### 2. AddTask Page - Time Selection Update
**File:** `lib/Page/Home/Add Task/Widget/date_time_notification_widget.dart` (lines 529-554)

**Before:**
```dart
final result = await Helper().selectTime(context, initialTime: initialTime);
```

**After:**
```dart
// Get current notification/alarm state for initialization
int? initialNotificationState;
if (addTaskProvider.isNotificationOn) {
  initialNotificationState = 1;
} else if (addTaskProvider.isAlarmOn) {
  initialNotificationState = 2;
} else {
  initialNotificationState = 0;
}

final result = await Helper().selectTime(
  context,
  initialTime: initialTime,
  initialNotificationAlarmState: initialNotificationState,
  initialEarlyReminderMinutes: addTaskProvider.earlyReminderMinutes,
);
```

**Benefits:**
- When user reopens time picker, previous notification/alarm choice is shown
- Early reminder minutes are pre-selected if previously set
- Dialog remembers user's last configuration

---

### 3. QuickAddTask Page - Time Selection Update
**File:** `lib/Page/Home/Widget/QuickAddTask/quick_add_date_time_field.dart` (lines 25-40)

**Before:**
```dart
final result = await Helper().selectTime(
  context,
  initialTime: provider.selectedTime ?? TimeOfDay.now(),
);
```

**After:**
```dart
final result = await Helper().selectTime(
  context,
  initialTime: provider.selectedTime ?? TimeOfDay.now(),
  initialNotificationAlarmState: provider.notificationAlarmState,
  initialEarlyReminderMinutes: provider.earlyReminderMinutes,
);
```

**Benefits:**
- Same initialization behavior as AddTask page
- Consistency across both time selection flows

---

## User Experience

### Scenario 1: First Time Setup
```
User: Opens time picker for first time
Dialog: Shows "Off" state, no early reminder selected
Result: Fresh start ✅
```

### Scenario 2: Reopening After Selection
```
User: Previously selected 14:30 with Notification + 15min reminder
User: Taps to change time
Dialog: Opens with:
  - Time wheels at 14:30
  - Notification button highlighted
  - 15 min button selected ✅
Result: User's previous config visible, easy to modify
```

### Scenario 3: Switching Between Notification/Alarm
```
User: Previously set Notification
User: Reopens dialog
Dialog: Shows Notification button as active
User: Clicks button 1x → cycles to Alarm
Result: Previous state remembered and updated easily ✅
```

### Scenario 4: Toggling Off
```
User: Previously had Notification + 5min reminder
User: Reopens dialog  
Dialog: Shows Notification + 5min as initialized
User: Clicks notification button → cycles to Off
User: Confirms
Result: Notification and early reminder removed ✅
```

---

## Technical Details

### State Management Flow
1. **AddTaskProvider/QuickAddTaskProvider** holds current state:
   - `isNotificationOn` / `isAlarmOn` (AddTask) → converted to `notificationAlarmState` int
   - `notificationAlarmState` (QuickAddTask) → directly passed
   - `earlyReminderMinutes` → passed to dialog

2. **Helper.selectTime()** initializes dialog:
   - Sets UI elements (buttons, indicators) based on init parameters
   - Dialog state is independent from provider state until Confirm
   - Cancel/Dismiss: returns `null`, no provider updates

3. **After Confirmation:**
   - Result contains user's selections
   - Provider updated with new state
   - Next time dialog opens: remembers these new values

### Data Flow Diagram
```
Provider State → _selectTime() → Helper.selectTime()
                                    ↓
                            Dialog UI (Initialized)
                                    ↓
                    User selects → result map
                                    ↓
                    Cancel? ⟶ null ⟶ no update
                    Confirm? ⟶ map ⟶ updateProvider
                                    ↓
                            Provider Updated → Next open remembers!
```

---

## Validation Checklist

- ✅ Helper.selectTime() accepts new parameters
- ✅ Parameters default to null (backward compatible)
- ✅ AddTask page passes current notification/alarm state
- ✅ AddTask page passes earlyReminderMinutes
- ✅ QuickAddTask page passes notification/alarm state
- ✅ QuickAddTask page passes earlyReminderMinutes
- ✅ Dialog initializes UI with passed values
- ✅ State preserved on cancel/dismiss (no null return)
- ✅ No errors in compilation
- ✅ Consistent behavior: AddTask + QuickAddTask

---

## Debug Output Examples

**Opening time picker first time:**
```
I/flutter: 🕐 selectTime: initializing with state=0, reminder=null
I/flutter: 🔇 State: Off
```

**Reopening after setting Notification + 15min:**
```
I/flutter: 🕐 selectTime: initializing with state=1, reminder=15
I/flutter: 📢 State: Notification (initialized)
I/flutter: ⏰ Early reminder: 15 min (initialized)
```

**User confirms same settings:**
```
I/flutter: ✅ Time confirmed: 14:30 Notification 15min
```

---

## Related Files
- `lib/Core/helper.dart` - selectTime() method
- `lib/Provider/add_task_provider.dart` - AddTask state
- `lib/Provider/quick_add_task_provider.dart` - QuickAddTask state
- `lib/Page/Home/Add Task/Widget/date_time_notification_widget.dart` - AddTask UI
- `lib/Page/Home/Widget/QuickAddTask/quick_add_date_time_field.dart` - QuickAddTask UI

---

## Version History
- **v1.7** - Added notification/alarm icons and early reminder badges
- **v1.8** - Dialog initialization with previous state (current) ✅
