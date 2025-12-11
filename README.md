# Fusion Rush

An educational puzzle game that teaches formal boolean logic through engaging space exploration gameplay. Master 33+ logical operations across 240+ interstellar challenges, synthesizing fuel to power your rocket through the cosmos.

![Godot Engine](https://img.shields.io/badge/Godot-4.4-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Status](https://img.shields.io/badge/status-feature--complete-brightgreen.svg)

## Overview

**Fusion Rush** transforms the learning of formal logic into an interactive journey through space. Players navigate the galaxy by solving logic puzzles in two phases: first collecting raw data (premises), then refining it using inference rules to synthesize the specific fuel compounds required for travel. The game progressively introduces concepts from simple Modus Ponens to advanced natural language reasoning.

### Educational Objectives

- Master 13 inference rules (Modus Ponens, Hypothetical Syllogism, Resolution, etc.)
- Understand 20+ equivalence laws (De Morgan's, Distributivity, Contrapositive, etc.)
- Practice with 8 boolean operators (AND, OR, XOR, NOT, IMPLIES, BICONDITIONAL, TRUE, FALSE)
- Bridge natural language and formal logic (Level 6)
- Develop logical reasoning and proof construction skills

## Tech Stack

### Frontend (Game)
- **Godot Engine:** 4.5 (GL Compatibility)
- **Language:** GDScript
- **Rendering:** OpenGL ES 3.0 / WebGL 2.0
- **Target Platforms:** Web (HTML5), Android, Windows, macOS, Linux

### Backend (MCP Server)
- **Framework:** FastMCP 1.20.4+
- **Runtime:** Node.js 20.3.1+
- **Language:** TypeScript 5.1.3+
- **Protocol:** Model Context Protocol (stdio transport)
- **Dependencies:**
  - zod: 3.21.4 (schema validation)
  - ws: 8.13.0 (WebSocket client)
  - websocket: 1.0.35

### External Services
- **Supabase:** Cloud database and leaderboard
- **Project ID:** qfqgbcotqqclrgcejhpd

## Features

### Core Gameplay

- **Two-Phase System**: Gather data premises, then refine them using logical rules to power the engine
- **6 Difficulty Levels**: Progressive complexity from orbital hops (1-operation) to deep space travel (5+ step proofs)
- **240+ Missions**: Across classic exploration mode and training modules
- **Hull Integrity & Scoring**: Strategic gameplay with heart-based mistakes and score multipliers
- **Launch Timer**: Timed challenges that increase pressure at higher difficulties

### Logic Engine

- **33+ Boolean Operations**: Comprehensive implementation of formal logic
- **Real-time Validation**: Instant feedback on fuel stability (logical expressions)
- **Expression Cleaning**: Automatic removal of unnecessary parentheses
- **Multi-result Operations**: Some rules produce multiple byproducts simultaneously
- **Robust Parsing**: Supports both Unicode symbols and ASCII alternatives (`->` → `→`, `^` → `⊕`)

### Training System

- **18 Complete Modules**: Each covering a specific logical operation
- **180+ Training Simulations**: Progressive difficulty from Easy to Very Hard
- **Grid Selection Interface**: 3×6 touch-optimized layout
- **Onboard Computer Help**: Context-sensitive hints and rule explanations
- **Progress Tracking**: Per-mission completion and mastery indicators

### Level 6: Universal Translator

The game's most innovative feature bridges everyday language and formal logic:
