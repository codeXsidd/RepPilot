# Exercise Library

RepPilot ships with 152 built-in exercises across 10 muscle-group categories. All exercises include complete metadata for guided workouts, progressive overload, and safety.

## Categories

| Category   | Count | Examples                                    |
|------------|-------|---------------------------------------------|
| Chest      | 15    | Flat Barbell Bench Press, Cable Crossover   |
| Back       | 17    | Barbell Bent-Over Row, Pull-Up              |
| Shoulders  | 13    | Overhead Press, Lateral Raise               |
| Biceps     | 13    | Barbell Curl, Hammer Curl                   |
| Triceps    | 10    | Close-Grip Bench Press, Tricep Dip          |
| Legs       | 15    | Barbell Back Squat, Leg Press               |
| Glutes     | 15    | Barbell Hip Thrust, Bulgarian Split Squat   |
| Calves     | 8     | Standing Calf Raise, Seated Calf Raise      |
| Core       | 17    | Plank, Cable Woodchop, Hanging Leg Raise    |
| Full Body  | 29    | Deadlift, Burpee, Farmer's Walk             |

## Exercise Metadata

Each exercise includes:

- **Name** and **aliases** (searchable)
- **Category** and **primary muscle group**
- **Secondary muscles** (e.g., Triceps, Front Deltoids for bench press)
- **Equipment** required (barbell, dumbbell, cable, machine, bodyweight, etc.)
- **Difficulty** level (beginner, intermediate, advanced)
- **Description** and step-by-step **instructions**
- **Safety notes** (displayed with warning styling)
- **Movement pattern** (push, pull, squat, hinge, etc.)
- **Default programming** (sets, rep range, rest period, weight increment)
- **Flags**: bodyweight, unilateral, machine, home-suitable, gym-suitable
- **Substitution IDs** for alternative exercise suggestions

## Equipment Types

barbell, bodyweight, cable, dumbbell, ez_bar, kettlebell, machine, resistance_band, medicine_ball, other

## Difficulty Levels

- **Beginner**: Safe for newcomers, minimal coordination required
- **Intermediate**: Requires some training experience and form awareness
- **Advanced**: Demands significant strength, stability, or technique

## Filtering and Search

The exercise library supports:

- **Text search**: Matches name, muscle group, category, equipment, aliases, and secondary muscles
- **Category filter**: 10 muscle-group categories via horizontal chip bar
- **Difficulty filter**: Beginner, intermediate, advanced
- **Equipment filter**: All 10 equipment types
- **Home suitability**: Toggle to show only exercises doable at home
- **Favorites**: Star exercises for quick access
- **Recently used**: Auto-tracked when completing workouts

## Favorites

Tap the star icon on any exercise's detail screen to mark it as a favorite. Favorites persist across app restarts and catalog updates. The exercise picker has a dedicated "Favorites" quick-access tab.

## Recently Used

When you complete a workout, all exercises in that session are timestamped. The exercise picker shows a "Recent" tab listing your most recently used exercises for quick re-selection.

## Custom Exercises

Users can create unlimited custom exercises with name, category, muscle group, equipment, and notes. Custom exercises are never overwritten by catalog updates.

## Database Schema

Exercises are stored in the `exercises` table (schema v7) with 30 columns. The v6-to-v7 migration adds 20 columns for the expanded metadata. All migrations are forward-only and additive. Catalog seeding uses `ON CONFLICT DO UPDATE` to update metadata while preserving user favorites and last-used timestamps.

## Stable IDs

Built-in exercises use stable IDs (`default-ex-001` through `default-ex-152`). These IDs never change across app updates, ensuring workout history and progressive overload data remain linked correctly.
