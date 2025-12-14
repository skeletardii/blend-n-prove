# System Architecture

Fusion Rush is a sophisticated educational puzzle game built using the Godot Engine (4.x). Its architecture is engineered to support a complex interplay of modular gameplay systems, data-driven content pipelines, and robust educational progression, all while maintaining a high degree of maintainability and extensibility through advanced design patterns.

## Core Design Philosophy

The architectural foundation of Fusion Rush is built upon three primary pillars: **Modularity**, **Data-Driven Design**, and **Strict State Management**. These principles ensure that the game remains stable during rapid iteration and can easily accommodate new content types (such as new logic rules or tutorial modules) without requiring significant refactoring of the codebase.

The system is designed to be "content-agnostic" where possible. The engine knows how to process logic, but it doesn't hardcode *what* logic problems exist. This separation of engine and content is achieved through a custom pipeline that compiles Markdown documentation into JSON game data, effectively turning the documentation into the source code for the level design.

## 1. Proxy / Implementation Pattern (The "Manager" System)

To facilitate dynamic loading, hot-swapping of logic, and loose coupling between systems, the game employs a rigorous **Proxy/Implementation** pattern for its core managers. This design is critical for features like modding support, A/B testing different logic implementations, and loading content from external PCK files.

### Conceptual Flow
The following diagram illustrates how a call from the UI travels through the architecture to the logic:

```text
+----------------+       +------------------+       +----------------------+
|   UI Scene     |       |   Proxy (Auto)   |       |   Implementation     |
| (Phase1UI.gd)  |       | (GameManager.gd) |       | (GameManagerImpl.gd) |
+----------------+       +------------------+       +----------------------+
|                |       |                  |       |                      |
|  User Clicks   | ----> |  start_game()    | ----> |  _impl.start_game()  |
|   "Start"      |       |  (Public API)    |       |  (Business Logic)    |
|                |       |                  |       |                      |
|                |       |  [No State]      |       |  [Holds State]       |
|                |       |  [Global Ref]    |       |  [Swappable]         |
+----------------+       +------------------+       +----------------------+
                                  ^
                                  | Injected By
                                  |
                         +------------------------+
                         |   ManagerBootstrap.gd  |
                         |   (Startup Script)     |
                         +------------------------+
```

### The Proxy Layer (Autoloads)
Located in `src/game/autoloads/`, these scripts (e.g., `GameManager.gd`) act as lightweight global singletons. They define the public API surface area that the rest of the game interacts with.
*   **Role**: They are the "Face" of the system.
*   **Behavior**: Critically, these proxies contain **no business logic**. Their sole responsibility is to forward function calls and signals to the underlying implementation instance.
*   **Benefit**: This ensures that the rest of the codebase never holds a direct reference to a heavy logic class, preventing circular dependencies and memory leaks. If the implementation crashes or needs to be reloaded, the proxy remains stable, preserving the reference held by other nodes.

**Example of Proxy Logic:**
```gdscript
# GameManager.gd (Proxy)
extends Node

# The reference to the actual logic node
var _impl: Node = null

# Called by ManagerBootstrap to inject the logic
func _set_impl(impl: Node) -> void:
    _impl = impl
    # Forward signals from logic to proxy listeners
    if _impl.has_signal("game_state_changed"):
        _impl.game_state_changed.connect(func(s): game_state_changed.emit(s))

# Public API - Safe to call from anywhere
func start_new_game() -> void:
    if _impl:
        _impl.start_new_game()
    else:
        push_error("GameManager implementation not loaded!")
```

### The Implementation Layer
Located in `src/managers/` (e.g., `GameManagerImpl.gd`), these classes extend `Node` and contain the actual state, logic, and processing algorithms.
*   **Instantiation**: They are never instantiated directly by the scene tree (`project.godot`). Instead, they are created dynamically.
*   **Lifecycle**: They can be loaded from the main resource pack (`res://`) or injected from an external `.pck` file/DLC.
*   **State**: They hold the "Truth" of the application state (e.g., `current_score`, `active_customer`).

### The Bootstrap System
The `src/core/ManagerBootstrap.gd` script is the orchestrator of this pattern. It runs during the application startup sequence and is responsible for:
1.  **Integrity Check**: Verifying the integrity of the game files (checking if the main PCK is loaded).
2.  **Instantiation**: Instantiating the specific implementation classes defined in its configuration `MANAGER_PATHS` dictionary.
3.  **Injection**: Injecting these instances into their respective proxies using the private `_set_impl()` method.
4.  **Signaling**: Emitting the `managers_ready` signal only when the entire dependency graph is resolved.

## 2. Strict Dependency Injection

To prevent initialization race conditions—a common plague in complex Godot projects where one Autoload tries to access another before it's ready—the `ManagerBootstrap` enforces a strictly defined load order. Dependencies are resolved in a waterfall manner, ensuring that low-level services are fully operational before high-level game logic attempts to access them.

### The Load Sequence Definition
The order is defined conceptually as follows:

1.  **Level 0: Foundation (Data)**
    *   **ProgressTracker**: The persistence layer is loaded first. It has zero external dependencies and is required by almost every other system to read/write player state (settings, high scores, tutorial progress). It initializes the encrypted file access immediately.

2.  **Level 1: Core Logic (Math)**
    *   **BooleanLogicEngine**: The mathematical core. It is a pure logic class with no dependencies on UI or save data, making it safe to initialize early. It preloads the `BooleanExpression` class to ensure type safety across the domain.

3.  **Level 2: Connectivity (I/O)**
    *   **SupabaseService**: Initializes the HTTPClient and loads API keys from the environment or Javascript bridge.
    *   **OpenRouterService**: Initializes the AI Tutor connection. It needs the network stack to be ready.

4.  **Level 3: Content (Assets)**
    *   **TutorialDataManager**: This manager depends on the `ProgressTracker` to determine which tutorials are unlocked, so it must wait for the tracker to be ready. It also parses the static JSON curriculum upon load.

5.  **Level 4: Features (Utility)**
    *   **UpdateCheckerService**: Checks for application updates, depending on basic network connectivity. It runs asynchronously to avoid blocking the main thread.

6.  **Level 5: Game Flow (Control)**
    *   **TutorialManager**: Orchestrates the flow of specific lessons, dependent on the data manager.
    *   **GameManager**: The "App Controller" and final piece of the puzzle. It depends on *all* previous systems to function, acting as the central hub for gameplay flow.

## 3. Data-Driven Content Pipeline

Fusion Rush avoids hardcoding game content into GDScript whenever possible. Instead, it relies on a robust data pipeline that treats content as configuration.

*   **External Definition**: All levels, logic puzzles, and tutorial steps are defined in external JSON files located in the `data/` directory.
*   **Hot-Reloading**: Because content is loaded at runtime from these files, designers can tweak difficulty curves, edit puzzle text, or fix typos in tutorials without needing to recompile the game binary.
*   **"Docs as Code"**: The project utilizes a unique TypeScript-based toolchain (`devtools/extract_problems.ts`) that compiles human-readable Markdown files from the `docs/` folder into the machine-readable JSON format used by the game. This allows educators to write curriculum in standard Markdown, which is then automatically converted into playable game content.

### Developer Guide: Adding a New Manager
If you need to add a new global system (e.g., `AchievementManager`), follow this strict protocol:

1.  **Create the Proxy**:
    *   Create `src/game/autoloads/AchievementManager.gd`.
    *   Add `var _impl: Node` and `func _set_impl(impl)`.
    *   Add it to `project.godot` Autoloads.

2.  **Create the Implementation**:
    *   Create `src/managers/AchievementManagerImpl.gd`.
    *   Implement your logic (`func unlock_achievement(id): ...`).

3.  **Register in Bootstrap**:
    *   Open `src/core/ManagerBootstrap.gd`.
    *   Add path to `MANAGER_PATHS`: `"AchievementManager": "res://src/managers/AchievementManagerImpl.gd"`.
    *   Add name to `MANAGER_LOAD_ORDER` (likely after `ProgressTracker`).

## High-Level Component Architecture

### 1. The Game Client (`src/`)
The primary application logic is organized into distinct domains:
*   **Core (`src/core/`)**: Contains the architectural scaffolding, including `ManagerBootstrap.gd` and fundamental type definitions that are shared across the entire project.
*   **Game Logic (`src/game/`)**: Holds the Proxy Autoloads and game-specific utility classes.
*   **User Interface (`src/ui/`)**: A massive collection of scenes and scripts that handle presentation. This includes complex components like the `VirtualKeyboard`, the `Phase1UI` (Translation Interface), and the `Phase2UI` (Deduction Interface).
*   **Managers (`src/managers/`)**: The heavy-lifting implementation classes for all subsystems.
*   **Scenes (`src/scenes/`)**: The high-level "Screen" scenes (e.g., `GameplayScene.tscn`, `MainMenu.tscn`) that act as containers for the various UI modules.

### 2. The Logic Engine (`BooleanLogicEngine`)
This is a self-contained mathematical engine that serves as the "Physics Engine" for logic. It is completely decoupled from the rendering and UI code.
*   **Parsing**: It converts raw user input strings (e.g., "P implies Q") into structured, traversable `BooleanExpression` object trees.
*   **Validation**: It performs rigorous syntax checking, ensuring that expressions are well-formed before they are ever processed by the game rules.
*   **Inference**: It acts as the referee, strictly enforcing the 13 formal rules of inference (Modus Ponens, Resolution, etc.) and rejecting any move that violates logical consistency.
*   **Verification**: It includes a brute-force Truth Table generator used for "Semantic Verification", allowing it to prove equivalence between arbitrary expressions even if they don't match a standard rule pattern.

### 3. Analytics & Persistence (`ProgressTracker`)
A sophisticated data layer responsible for the long-term state of the player.
*   **Secure Persistence**: It implements a custom encrypted save system (`user://game_progress.dat`) that binds save files to the specific device ID, preventing trivial sharing of save files while maintaining a seamless user experience.
*   **Granular Metrics**: It tracks performance at a high resolution, recording specific mistake types, operation usage rates, and timing data to feed into the adaptive difficulty system.
*   **Cloud Synchronization**: It manages the interface with Supabase for leaderboard data, handling the complexities of REST API communication and data serialization.

## Godot Node Hierarchy & Scene Structure

Understanding the scene tree is vital for navigating the project. The `GameplayScene.tscn` is the root of the active game experience and is structured as follows:

```text
GameplayScene (Control)
├── UI Layer (CanvasLayer)
│   ├── MainContainer (VBoxContainer)
│   │   ├── TopBar (HBoxContainer)
│   │   │   ├── ScoreDisplay (Label)
│   │   │   ├── LivesDisplay (Label)
│   │   │   └── PauseButton (Button)
│   │   ├── PatienceBar (ProgressBar + TextureRect Fuel Icon)
│   │   └── GameContentArea (Control)
│   │       ├── CustomerArea (Panel) -> Shows the "Order" text
│   │       └── PhaseContainer (Control) -> Holds dynamic Phase scenes
│   │           ├── Phase1UI (Instance) -> The Translation Keyboard
│   │           │   ├── VirtualKeyboard
│   │           │   └── InputDisplay
│   │           └── Phase2UI (Instance) -> The Deduction Workbench
│   │               ├── PremiseInventory
│   │               ├── RuleButtonsContainer
│   │               └── TargetDisplay
│   └── TutorialOverlay (CanvasLayer) -> Injected dynamically
├── Background (ParallaxLayer)
│   ├── SpaceBG1 (TextureRect) -> Background Layer 1
│   └── SpaceBG2 (TextureRect) -> Background Layer 2 (for looping)
└── Managers (Node)
    └── FirstTimeTutorialManager (Instance)
```

## Performance Considerations

While Fusion Rush is a 2D game, the logic validation can be computationally expensive.
*   **Truth Table Generation**: Generating a truth table for an expression with 8 variables results in $2^8 = 256$ rows. For each row, the engine must recursively evaluate the expression tree. This happens in real-time when the user submits a solution. To maintain 60 FPS, the engine imposes a hard limit of 8 variables, though the game rarely uses more than 5 (`P, Q, R, S, T`).
*   **Object Pooling**: Particle effects for "Shattering" text and "Rocket Exhaust" use `CPUParticles2D` to minimize GPU overhead on mobile devices.
*   **Web Assembly (WASM)**: For the HTML5 export, the project uses a specific `JavaScriptBridge` to handle networking (Supabase/OpenRouter) because the native Godot networking stack can face Cross-Origin Resource Sharing (CORS) blocks in browser environments.

## Build & Deployment Pipeline

The project is structured to support multiple export targets:
*   **Android (.apk)**: The primary target. Uses the encrypted save system (`user://` mapping to internal storage) and native networking.
*   **Web (.html/.wasm)**: Uses the JavaScript Bridge for networking and `localStorage` (via the Godot `user://` abstraction) for saving.
*   **Windows/Linux (.exe)**: Primarily for development and testing.

The `devtools/` directory contains the content compilation scripts (`extract_problems.ts`) which must be run *before* exporting the game to ensure the `data/` JSON files are up-to-date with the `docs/`. This separation ensures that content changes are tracked in version control (Git) as human-readable diffs (Markdown), rather than opaque JSON blobs.

## Troubleshooting Architecture

### Common Issues
1.  **Manager Not Found**:
    *   *Symptom*: Accessing `GameManager` crashes with null reference.
    *   *Cause*: `ManagerBootstrap` failed to load.
    *   *Fix*: Check the Output log for "PCK not loaded" or "Script not found" errors. Ensure the `MANAGER_PATHS` dictionary is correct.

2.  **Save Data Corruption**:
    *   *Symptom*: Progress resets on every launch.
    *   *Cause*: Encryption key mismatch.
    *   *Fix*: Ensure `ENCRYPTION_SALT` matches across versions and that `OS.get_unique_id()` is stable on the testing device.

3.  **CORS Errors (Web)**:
    *   *Symptom*: API calls fail only on Web export.
    *   *Cause*: Browser blocking cross-origin requests.
    *   *Fix*: Ensure `web_config.js` is properly injecting the `SUPABASE_URL` and that the server supports the Origin header.

## Global Autoload Reference

| Autoload Name | Implementation Path | Dependencies | Purpose |
| :--- | :--- | :--- | :--- |
| `GameManager` | `src/managers/GameManagerImpl.gd` | All | Central game controller |
| `BooleanLogicEngine` | `src/managers/BooleanLogicEngineImpl.gd` | None | Math & Logic core |
| `ProgressTracker` | `src/managers/ProgressTrackerImpl.gd` | None | Saves & Analytics |
| `TutorialManager` | `src/managers/TutorialManagerImpl.gd` | Data | Tutorial flow |
| `SupabaseService` | `src/managers/SupabaseServiceImpl.gd` | Network | Leaderboards |
| `OpenRouterService` | `src/managers/OpenRouterServiceImpl.gd` | Network | AI Chatbot |
| `AppConstants` | `src/game/autoloads/AppConstants.gd` | None | Global constants |
| `AudioManager` | `src/managers/AudioManagerImpl.gd` | None | Sound & Music |

## Detailed File System Map

| Directory | File | Description |
| :--- | :--- | :--- |
| `src/core/` | `ManagerBootstrap.gd` | Dependency injection container |
| `src/game/expressions/` | `BooleanExpression.gd` | Logic data class with parsing |
| `src/managers/` | `*Impl.gd` | All heavy logic implementations |
| `src/scenes/` | `GameplayScene.tscn` | Main game loop scene |
| `src/scenes/` | `MainMenu.tscn` | Start screen & settings |
| `src/ui/` | `Phase1UI.gd` | Natural Language Translation logic |
| `src/ui/` | `Phase2UI.gd` | Deduction/Transformation logic |
| `src/ui/` | `AITutorScene.gd` | Chatbot interface |
| `src/ui/` | `VirtualKeyboard.gd` | Custom input control |
| `data/classic/` | `level-*.json` | Level definitions |
| `data/tutorial/` | `*.json` | Tutorial lesson definitions |
| `devtools/` | `extract_problems.ts` | Compiler for docs-to-data |

## Project Configuration (ProjectSettings)

The `project.godot` file contains critical overrides that make this architecture work:

*   **Display/Window/Size**: `720x1280` (Mobile Portrait)
*   **Display/Window/Stretch**: `canvas_items` / `keep_width`
*   **Application/Run/Main_Scene**: `src/scenes/MainMenu.tscn`
*   **Autoloads**:
    *   `GameManager`: `*res://src/game/autoloads/GameManager.gd`
    *   `...` (See Autoload Reference above)
*   **Editor/Plugins**: `godot_mcp` (Enabled for development, disabled for release)
