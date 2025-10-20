# Phase 1 UI Specification - Boolean Logic Bartender

**Document Version**: 1.0
**Date**: 2025-09-24
**Target Platform**: Godot 4.4.1
**Canvas Size**: 720×1280 (Mobile Portrait)

## Overview

This document provides comprehensive specifications for implementing the Phase 1 UI (Premise Building Phase) of the Boolean Logic Bartender game. The UI enables players to reconstruct logical premises using a virtual keyboard interface, with real-time validation through the Boolean Logic Engine.

## Table of Contents

1. [Canvas Layout & Dimensions](#canvas-layout--dimensions)
2. [Top Status Bar](#top-status-bar)
3. [Customer Display Area](#customer-display-area)
4. [Input System](#input-system)
5. [Virtual Keyboard](#virtual-keyboard)
6. [Feedback Systems](#feedback-systems)
7. [Integration Specifications](#integration-specifications)
8. [Technical Implementation](#technical-implementation)
9. [Color Palette & Typography](#color-palette--typography)
10. [State Management](#state-management)
11. [Accessibility & Responsive Design](#accessibility--responsive-design)

---

## Canvas Layout & Dimensions

### **Primary Canvas**
- **Resolution**: 720×1280 pixels (9:16 aspect ratio)
- **Orientation**: Portrait (mobile-first design)
- **Background**: `#f5f5f5` (light gray)
- **Safe Areas**: 20px margins on left/right for mobile compatibility

### **Layout Structure**
```
┌─────────────── 720px ───────────────┐
├─ Top Status Bar        (60px)       │ 0-60px
├─ Customer Area         (240px)      │ 60-300px
├─ Input Field          (80px)       │ 300-380px
├─ Virtual Keyboard     (300px)      │ 380-680px
├─ Action Buttons       (60px)       │ 680-740px
└─ Bottom Safe Area     (540px)      │ 740-1280px
```

---

## Top Status Bar

### **Component Structure**
**Position**: (0, 0, 720, 60)
**Background**: `#2c3e50` (dark blue-gray)

#### **Lives Display (Left Section)**
- **Position**: (20, 15, 216, 30) - Left 30% minus margins
- **Content**: Heart icons indicating remaining lives
- **Format**: "❤️ ❤️ ❤️" or individual heart sprites
- **Font**: Arial, 14px, white
- **Lives Logic**:
  - 3 hearts = full health
  - 2 hearts = one mistake made
  - 1 heart = critical state
  - 0 hearts = game over

#### **Score Display (Center Section)**
- **Position**: (216, 15, 288, 30) - Center 40%
- **Content**: Current game score
- **Format**: "Score: X,XXX"
- **Font**: Arial, 16px, white, center-aligned
- **Score Range**: 0 to 999,999

#### **Level Display (Right Section)**
- **Position**: (504, 15, 196, 30) - Right 30% minus margins
- **Content**: Current difficulty level
- **Format**: "LV.X"
- **Font**: Arial, 16px, white, right-aligned
- **Level Range**: 1 to 99+

### **Timer/Patience Bar**
**Position**: (20, 45, 680, 12)
**Background**: `#34495e` (dark gray)
**Border Radius**: 6px

#### **Segment Configuration**
The patience bar consists of 3 segments representing score multipliers:

1. **High Multiplier Segment** (Rightmost)
   - **Width**: 226px (1/3 of bar)
   - **Color**: `#e74c3c` (red)
   - **Multiplier**: 3x score
   - **Message**: "Excellent speed!"

2. **Medium Multiplier Segment** (Center)
   - **Width**: 227px (1/3 of bar)
   - **Color**: `#f39c12` (orange)
   - **Multiplier**: 2x score
   - **Message**: "Good timing!"

3. **Low Multiplier Segment** (Leftmost)
   - **Width**: 227px (1/3 of bar)
   - **Color**: `#2ecc71` (green)
   - **Multiplier**: 1x score
   - **Message**: "Just in time!"

#### **Timer Behavior**
- **Direction**: Fills from right to left as time expires
- **Duration**: Variable based on difficulty (60-180 seconds)
- **Visual**: Animated smooth progression
- **Warning**: Pulsing effect when <20% remaining

---

## Customer Display Area

### **Container Specifications**
**Position**: (20, 80, 680, 200)
**Background**: Transparent

#### **Customer Character**
**Position**: (40, 100, 120, 160)

##### **Character Components**
```
Head:
- Circle: center=(70, 130), radius=20px
- Fill: #fdbcb4 (skin tone)
- Stroke: #333333, width=2px

Body:
- Rectangle: (60, 150, 20, 40)
- Fill: #3498db (blue shirt)
- Stroke: #333333, width=2px
- Border-radius: 5px

Arms:
- Left: Line from (50, 165) to (60, 165)
- Right: Line from (80, 165) to (90, 165)
- Stroke: #333333, width=3px

Legs:
- Left: Line from (65, 190) to (65, 210)
- Right: Line from (75, 190) to (75, 210)
- Stroke: #333333, width=3px
```

#### **Speech Bubble**
**Position**: (180, 100, 480, 180)
**Background**: `#ffffff` (white)
**Border**: `#333333`, 2px solid
**Border-radius**: 10px

##### **Speech Bubble Pointer**
- **Type**: Triangle pointing to customer
- **Position**: (180, 140, 160, 150, 180, 160)
- **Fill**: `#ffffff`
- **Stroke**: `#333333`, 2px

##### **Premise Checklist**
**Position**: (200, 120, 440, 140)

###### **Header Text**
- **Text**: "Premises to reconstruct:"
- **Font**: Arial, 14px, bold, `#333333`
- **Position**: (200, 125)

###### **Premise Items**
Each premise item follows this structure:

```
Premise 1: (200, 145, 400, 25)
├─ Checkbox Circle: (210, 150, 16, 16)
│  ├─ Unchecked: fill=#ecf0f1, stroke=#bdc3c7
│  └─ Checked: fill=#2ecc71, checkmark=white
├─ Premise Text: (235, 155)
│  ├─ Font: Arial, 16px
│  ├─ Color: #333333 (valid) | #7f8c8d (unchecked)
│  └─ Example: "P → Q"

Premise 2: (200, 170, 400, 25)
[Same structure, offset by 25px]

Premise 3: (200, 195, 400, 25)
[Same structure, offset by 50px]
```

###### **Target Section**
**Position**: (200, 230, 400, 30)

```
Separator Line:
- Position: (200, 235, 580, 1)
- Color: #bdc3c7

Target Label:
- Text: "TARGET:"
- Font: Arial, 14px, bold
- Color: #e74c3c (red)
- Position: (200, 250)

Target Expression:
- Text: Variable (e.g., "R")
- Font: Arial, 18px, bold
- Color: #e74c3c (red)
- Position: (275, 250)
```

---

## Input System

### **Input Field Container**
**Position**: (60, 320, 600, 60)
**Background**: `#ffffff` (white)
**Border**: `#333333`, 2px solid
**Border-radius**: 5px

#### **Field Label**
- **Text**: "Current Input:"
- **Font**: Arial, 16px, bold, `#333333`
- **Position**: (360, 305) - centered above field

#### **Input Display Area**
**Position**: (80, 340, 560, 20)

##### **Placeholder Text**
- **Text**: "Type your premise here..."
- **Font**: Arial, 18px, `#7f8c8d` (gray)
- **Display**: When field is empty

##### **Active Input Text**
- **Font**: Arial, 18px, `#333333` (black)
- **Alignment**: Left-aligned with 20px padding
- **Cursor**: Blinking vertical line when active

---

## Virtual Keyboard

### **Keyboard Container**
**Position**: (0, 400, 720, 260)
**Background**: Transparent

#### **Row Layout Specifications**

##### **Row 1: Variables (5 buttons)**
**Y-Position**: 400px
**Button Spacing**: 10px between buttons
**Centering**: Total width = 5×60 + 4×10 = 340px, start at (720-340)/2 = 190px

```
Button Positions:
P: (190, 400, 60, 50)
Q: (260, 400, 60, 50)
R: (330, 400, 60, 50)
S: (400, 400, 60, 50)
T: (470, 400, 60, 50)
```

**Button Styling**:
- **Background**: `#3498db` (blue)
- **Border**: `#2980b9` (darker blue), 2px
- **Border-radius**: 5px
- **Text**: Arial, 20px, white, centered
- **Press Effect**: Scale 0.95, background `#2980b9`

##### **Row 2: Logic Operators (4 buttons)**
**Y-Position**: 470px
**Centering**: Total width = 4×60 + 3×10 = 270px, start at (720-270)/2 = 225px

```
Button Positions:
∧: (225, 470, 60, 50)
⊕: (295, 470, 60, 50)
↔: (365, 470, 60, 50)
∨: (435, 470, 60, 50)
```

**Button Styling**:
- **Background**: `#9b59b6` (purple)
- **Border**: `#8e44ad` (darker purple), 2px
- **Border-radius**: 5px
- **Text**: Arial, 20px, white, centered
- **Press Effect**: Scale 0.95, background `#8e44ad`

##### **Row 3: Mixed Operators (5 buttons)**
**Y-Position**: 540px
**Same positioning as Row 1**

```
Button Positions:
→: (190, 540, 60, 50)
(: (260, 540, 60, 50)
): (330, 540, 60, 50)
¬: (400, 540, 60, 50)
⌫: (470, 540, 60, 50)
```

**Button Styling**:
- **→, ¬**: Same purple theme as Row 2
- **(, )**: Gray theme (`#95a5a6` background, `#7f8c8d` border)
- **⌫**: Red theme (`#e74c3c` background, `#c0392b` border)

#### **Symbol Mappings**
The keyboard supports ASCII input conversion:

```
Input Conversions:
^ → ⊕     (Caret to XOR)
XOR → ⊕   (Text to XOR)
xor → ⊕   (Lowercase text to XOR)
<-> → ↔   (ASCII biconditional)
<=> → ↔   (Alternative biconditional)
-> → →    (ASCII arrow)
=> → →    (Alternative arrow)
& → ∧     (Ampersand to AND)
&& → ∧    (Double ampersand to AND)
| → ∨     (Pipe to OR)
|| → ∨    (Double pipe to OR)
~ → ¬     (Tilde to NOT)
! → ¬     (Exclamation to NOT)
```

---

## Action Buttons

### **Button Container**
**Position**: (0, 620, 720, 60)
**Background**: Transparent

#### **Clear Button**
**Position**: (180, 630, 160, 40)
**Background**: `#e74c3c` (red)
**Border**: `#c0392b` (darker red), 2px
**Border-radius**: 20px
**Text**: "CLEAR"
**Font**: Arial, 18px, white, centered
**Function**: Clear current input field

#### **Submit Button**
**Position**: (380, 630, 200, 40)
**Background**: `#2ecc71` (green)
**Border**: `#27ae60` (darker green), 2px
**Border-radius**: 20px
**Text**: "SUBMIT"
**Font**: Arial, 18px, white, centered
**Function**: Validate and submit current premise

---

## Feedback Systems

### **Toast Message System**
**Container**: (160, 250, 400, 60) - Centered overlay

#### **Error Toast (Invalid Premise)**
```
Background: #e74c3c (red)
Border: #c0392b (darker red), 2px
Border-radius: 30px
Text: "Invalid premise!"
Font: Arial, 16px, white, centered
Duration: 2 seconds
Animation: Fade in (0.3s), hold (1.4s), fade out (0.3s)
```

#### **Success Toast (Valid Premise)**
```
Background: #2ecc71 (green)
Border: #27ae60 (darker green), 2px
Border-radius: 30px
Text: "Premise added!"
Font: Arial, 16px, white, centered
Duration: 1.5 seconds
Animation: Fade in (0.2s), hold (1.1s), fade out (0.2s)
```

### **Visual Validation Feedback**
- **Input Field Border**: Changes to green (#2ecc71) when valid expression entered
- **Checkbox Updates**: Immediate checkmark animation when premise validated
- **Button States**: Submit button glows when valid input ready

---

## Integration Specifications

### **Boolean Logic Engine Integration**

#### **Real-time Validation**
```gdscript
# Primary validation call
var expression = BooleanLogicEngine.create_expression(user_input)
if expression.is_valid:
    # Show success feedback
    update_premise_checklist(expression.normalized_string)
else:
    # Show error toast
    show_invalid_premise_toast()
```

#### **Expression Comparison**
```gdscript
# Check against target premises
func check_premise_match(user_expression: BooleanExpression, target_text: String) -> bool:
    var target_expression = BooleanLogicEngine.create_expression(target_text)
    return user_expression.equals(target_expression)
```

#### **Supported Operations**
The engine fully supports:
- **Variables**: A-Z, a-z
- **Operators**: ∧, ∨, ⊕, ¬, →, ↔
- **Grouping**: Parentheses with proper precedence
- **Constants**: TRUE, FALSE

### **Game State Integration**

#### **Premise Progress Tracking**
```gdscript
class_name PremiseTracker

var required_premises: Array[String] = []
var completed_premises: Array[String] = []
var target_conclusion: String = ""

func is_premise_complete(premise: String) -> bool:
    return premise in completed_premises

func get_completion_percentage() -> float:
    return float(completed_premises.size()) / float(required_premises.size())

func is_phase_complete() -> bool:
    return completed_premises.size() == required_premises.size()
```

#### **Timer Integration**
```gdscript
signal patience_expired
signal timer_segment_changed(segment: int)

var patience_duration: float = 120.0  # Base duration in seconds
var current_time: float = 0.0

func _process(delta: float):
    current_time += delta
    update_timer_display()
    check_segment_changes()
    if current_time >= patience_duration:
        patience_expired.emit()
```

---

## Technical Implementation

### **Recommended Godot Scene Structure**
```
Phase1UI (Control)
├── TopStatusBar (Control)
│   ├── LivesDisplay (Label)
│   ├── ScoreDisplay (Label)
│   ├── LevelDisplay (Label)
│   └── PatienceBar (ProgressBar)
├── CustomerArea (Control)
│   ├── CustomerCharacter (Control)
│   └── SpeechBubble (Control)
│       ├── PremiseList (VBoxContainer)
│       └── TargetDisplay (Label)
├── InputSystem (Control)
│   ├── InputLabel (Label)
│   └── InputField (LineEdit)
├── VirtualKeyboard (Control)
│   ├── VariableRow (HBoxContainer)
│   ├── OperatorRow (HBoxContainer)
│   ├── MixedRow (HBoxContainer)
│   └── ActionRow (HBoxContainer)
└── FeedbackLayer (Control)
    ├── ToastMessage (Label)
    └── AnimationPlayer (AnimationPlayer)
```

### **Signal Architecture**
```gdscript
# Main UI Signals
signal premise_submitted(premise_text: String)
signal input_cleared()
signal keyboard_symbol_pressed(symbol: String)
signal premise_validated(is_valid: bool)
signal phase_completed()

# Timer Signals
signal patience_warning()  # <20% remaining
signal patience_expired()
signal multiplier_changed(multiplier: int)
```

### **Input Handling System**
```gdscript
func _on_virtual_key_pressed(symbol: String):
    match symbol:
        "⌫":
            handle_backspace()
        "CLEAR":
            clear_input()
        "SUBMIT":
            submit_current_input()
        _:
            add_symbol_to_input(symbol)

func handle_ascii_conversion(input: String) -> String:
    var converted = input
    converted = converted.replace("->", "→")
    converted = converted.replace("=>", "→")
    converted = converted.replace("<->", "↔")
    converted = converted.replace("<=>", "↔")
    converted = converted.replace("^", "⊕")
    converted = converted.replace("XOR", "⊕")
    converted = converted.replace("xor", "⊕")
    converted = converted.replace("&", "∧")
    converted = converted.replace("&&", "∧")
    converted = converted.replace("|", "∨")
    converted = converted.replace("||", "∨")
    converted = converted.replace("~", "¬")
    converted = converted.replace("!", "¬")
    return converted
```

---

## Color Palette & Typography

### **Primary Color Scheme**
```css
/* Status Elements */
--status-bg: #2c3e50         /* Top bar background */
--status-text: #ffffff       /* Top bar text */

/* Timer Segments */
--timer-high: #e74c3c        /* High multiplier (red) */
--timer-medium: #f39c12      /* Medium multiplier (orange) */
--timer-low: #2ecc71         /* Low multiplier (green) */
--timer-bg: #34495e          /* Timer background */

/* Interface Elements */
--bg-primary: #f5f5f5        /* Main background */
--bg-surface: #ffffff        /* Cards, panels */
--text-primary: #333333      /* Primary text */
--text-secondary: #7f8c8d    /* Secondary text */
--text-placeholder: #bdc3c7  /* Placeholder text */

/* Interactive Elements */
--button-variable: #3498db   /* Variable buttons */
--button-operator: #9b59b6   /* Operator buttons */
--button-utility: #95a5a6    /* Utility buttons */
--button-danger: #e74c3c     /* Clear/delete buttons */
--button-success: #2ecc71    /* Submit button */

/* Feedback Colors */
--success: #2ecc71           /* Valid feedback */
--error: #e74c3c             /* Error feedback */
--warning: #f39c12           /* Warning feedback */
```

### **Typography System**
```css
/* Primary Font Family */
font-family: Arial, sans-serif

/* Text Sizes */
--text-xs: 12px              /* Small labels */
--text-sm: 14px              /* Secondary text */
--text-base: 16px            /* Base text size */
--text-lg: 18px              /* Input text */
--text-xl: 20px              /* Button text */

/* Font Weights */
--weight-normal: 400
--weight-bold: 700

/* Line Heights */
--line-height-tight: 1.2
--line-height-normal: 1.5
```

---

## State Management

### **UI State Enum**
```gdscript
enum UIState {
    WAITING_FOR_INPUT,    # Normal input state
    VALIDATING,           # Processing user input
    SHOWING_FEEDBACK,     # Displaying toast message
    PHASE_COMPLETE        # All premises validated
}
```

### **Data Models**
```gdscript
class_name PremiseItem
extends Resource

@export var text: String = ""
@export var is_completed: bool = false
@export var display_order: int = 0

class_name LevelConfiguration
extends Resource

@export var required_premises: Array[String] = []
@export var target_conclusion: String = ""
@export var patience_duration: float = 120.0
@export var difficulty_level: int = 1
```

### **State Persistence**
```gdscript
# Save current progress
func save_phase_state():
    var state_data = {
        "completed_premises": completed_premises,
        "current_input": input_field.text,
        "remaining_time": patience_duration - current_time
    }
    GameState.save_phase1_data(state_data)

# Restore previous state
func load_phase_state():
    var state_data = GameState.load_phase1_data()
    if state_data:
        completed_premises = state_data.get("completed_premises", [])
        input_field.text = state_data.get("current_input", "")
        update_premise_checklist_display()
```

---

## Accessibility & Responsive Design

### **Accessibility Features**
1. **High Contrast Mode**: Alternative color scheme for visual impairments
2. **Keyboard Navigation**: Tab order through interactive elements
3. **Screen Reader Support**: Proper ARIA labels and descriptions
4. **Font Scaling**: Support for system font size preferences

### **Responsive Design Considerations**
```gdscript
# Screen size adaptation
func adapt_to_screen_size():
    var screen_size = get_viewport().get_visible_rect().size
    var scale_factor = min(screen_size.x / 720.0, screen_size.y / 1280.0)

    if scale_factor < 1.0:
        # Scale down for smaller screens
        scale = Vector2(scale_factor, scale_factor)
    elif screen_size.x > screen_size.y:
        # Adapt for landscape orientation
        adapt_for_landscape()
```

### **Touch Input Optimization**
- **Minimum Touch Target**: 44×44px (Apple HIG compliance)
- **Touch Feedback**: Visual and haptic feedback on interaction
- **Gesture Support**: Swipe to clear input, pinch to zoom
- **Touch Zones**: Generous hit areas around small elements

---

## Performance Considerations

### **Optimization Guidelines**
1. **Texture Compression**: Use appropriate formats for UI elements
2. **Draw Call Reduction**: Batch similar UI elements
3. **Memory Management**: Pool toast messages and animations
4. **Viewport Culling**: Hide off-screen keyboard elements

### **Animation Performance**
```gdscript
# Efficient toast animation
func show_toast_message(message: String, type: ToastType):
    toast_label.text = message
    toast_label.modulate.a = 0.0

    var tween = create_tween()
    tween.tween_property(toast_label, "modulate:a", 1.0, 0.3)
    tween.tween_delay(1.4)
    tween.tween_property(toast_label, "modulate:a", 0.0, 0.3)
```

---

## Testing & Validation

### **UI Testing Checklist**
- [ ] All buttons respond to touch input
- [ ] ASCII conversion works correctly
- [ ] Toast messages display properly
- [ ] Timer countdown functions accurately
- [ ] Premise validation integrates with engine
- [ ] Phase completion triggers correctly
- [ ] Screen rotation handling
- [ ] Performance on target devices

### **Integration Testing**
- [ ] Boolean Logic Engine integration
- [ ] Save/load state functionality
- [ ] Error handling for invalid inputs
- [ ] Memory usage within limits
- [ ] Network connectivity (if applicable)

---

**End of Specification**

*This document provides complete specifications for implementing the Phase 1 UI of Boolean Logic Bartender. All measurements, colors, and behaviors are precisely defined for consistent implementation across different development teams and AI coding assistants.*