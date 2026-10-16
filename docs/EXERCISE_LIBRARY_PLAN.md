# Exercise Library Expansion — Implementation Plan

## Current State

- 58 default exercises with basic metadata (name, category, muscleGroup, equipment)
- 6 categories: arms, back, chest, core, legs, shoulders
- 8 equipment types: barbell, bodyweight, cable, dumbbell, ez_bar, kettlebell, machine, other
- Schema version 6; Exercise table has 10 columns
- Seeding skips entirely if any defaults exist — no mechanism for adding new catalog entries
- No favorites, difficulty levels, instructions, aliases, substitutions, or movement patterns
- No exercise detail screen — form screen doubles as viewer

## Target State

- 150+ distinct exercises across 12 categories
- Rich metadata: difficulty, instructions, safety notes, movement pattern, secondary muscles, aliases, substitutions, default programming (sets/reps/rest/increment)
- Favorites and recently-used tracking
- Search by name and aliases
- Filter by muscle group, equipment, difficulty, home/gym suitability
- Dedicated exercise detail screen
- Idempotent seeding that adds new catalog exercises without overwriting user data

## Implementation Steps

### 1. Database Migration (v6 → v7)

Add columns to `exercises` table:

| Column | Type | Default |
|---|---|---|
| secondary_muscles | TEXT | '' |
| difficulty | TEXT | 'intermediate' |
| description | TEXT | '' |
| instructions | TEXT | '' |
| movement_pattern | TEXT | '' |
| default_sets | INTEGER | 3 |
| default_reps_min | INTEGER | 8 |
| default_reps_max | INTEGER | 12 |
| default_rest_seconds | INTEGER | 60 |
| default_increment_kg | REAL | 2.5 |
| aliases | TEXT | '' |
| substitution_ids | TEXT | '' |
| is_bodyweight | INTEGER | 0 |
| is_unilateral | INTEGER | 0 |
| is_machine | INTEGER | 0 |
| suitable_for_home | INTEGER | 0 |
| suitable_for_gym | INTEGER | 1 |
| is_favorite | INTEGER | 0 |
| last_used_at | TEXT | NULL |
| safety_notes | TEXT | '' |

### 2. Exercise Model Expansion

Add corresponding Dart fields to the `Exercise` class with `toMap`/`fromMap`/`copyWith` support.

### 3. Exercise Catalog (150+ entries)

Categories:
- chest (15)
- back (17)
- shoulders (13)
- biceps (13)
- triceps (10)
- quadriceps (15)
- hamstrings (15)
- calves (6)
- core (16)
- full_body (12)

Each exercise includes: name, category, primary muscle group, secondary muscles, equipment, difficulty, instructions, movement pattern, default programming, aliases, substitutions, home/gym flags, safety notes.

### 4. Seeding Mechanism

Replace skip-if-exists with upsert-by-id:
- INSERT OR IGNORE for new exercises
- UPDATE existing defaults (is_custom = 0) with new metadata
- Never touch user-created exercises (is_custom = 1)
- Preserve is_favorite and last_used_at on updates

### 5. Repository Updates

- Search includes aliases column
- Filter by difficulty, equipment, suitability
- Get favorites
- Get recently used (by last_used_at)
- Update last_used_at when exercise is used in a session
- Toggle favorite

### 6. UI Changes

- New `ExerciseDetailScreen` showing full metadata
- Exercise list: add difficulty and equipment filter chips
- Exercise picker: show difficulty badge
- Exercise form: show all metadata for custom exercises
- Favorites filter chip on library screen

### 7. Testing

- Catalog validation: 150+ entries, no duplicate IDs, valid metadata
- Migration test: v6 → v7 preserves existing data
- Seeding test: idempotent, no duplicates
- Repository tests: search by alias, filter by difficulty, favorites
- UI widget tests: search, filter, detail, favorites

## Risk Mitigation

- Forward-only migration — no dropped columns
- Existing exercise IDs preserved (default-ex-001 through default-ex-058)
- New exercises get IDs default-ex-059 onward
- User data (custom exercises, workout history, favorites) never deleted
