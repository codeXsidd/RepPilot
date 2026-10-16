const int currentSchemaVersion = 6;

const List<String> v1Tables = [
  '''
  CREATE TABLE user_profile (
    id TEXT PRIMARY KEY NOT NULL,
    display_name TEXT NOT NULL DEFAULT '',
    weight_unit TEXT NOT NULL DEFAULT 'kg',
    theme_mode TEXT NOT NULL DEFAULT 'system',
    height_cm REAL,
    date_of_birth TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  )
  ''',
  '''
  CREATE TABLE exercises (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'other',
    muscle_group TEXT NOT NULL DEFAULT '',
    notes TEXT NOT NULL DEFAULT '',
    is_custom INTEGER NOT NULL DEFAULT 1,
    is_archived INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  )
  ''',
  '''
  CREATE TABLE routines (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    day_of_week INTEGER,
    sort_order INTEGER NOT NULL DEFAULT 0,
    notes TEXT NOT NULL DEFAULT '',
    is_archived INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  )
  ''',
  '''
  CREATE TABLE routine_exercises (
    id TEXT PRIMARY KEY NOT NULL,
    routine_id TEXT NOT NULL,
    exercise_id TEXT NOT NULL,
    target_sets INTEGER NOT NULL DEFAULT 3,
    target_reps INTEGER NOT NULL DEFAULT 10,
    target_weight_kg REAL,
    rest_seconds INTEGER NOT NULL DEFAULT 60,
    sort_order INTEGER NOT NULL DEFAULT 0,
    notes TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (routine_id) REFERENCES routines(id) ON DELETE CASCADE,
    FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE RESTRICT
  )
  ''',
  '''
  CREATE TABLE workout_sessions (
    id TEXT PRIMARY KEY NOT NULL,
    routine_id TEXT,
    routine_name TEXT NOT NULL DEFAULT '',
    started_at TEXT NOT NULL,
    completed_at TEXT,
    notes TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (routine_id) REFERENCES routines(id) ON DELETE SET NULL
  )
  ''',
  '''
  CREATE TABLE workout_sets (
    id TEXT PRIMARY KEY NOT NULL,
    session_id TEXT NOT NULL,
    exercise_id TEXT NOT NULL,
    exercise_name TEXT NOT NULL DEFAULT '',
    set_number INTEGER NOT NULL,
    reps INTEGER,
    weight_kg REAL,
    completed INTEGER NOT NULL DEFAULT 0,
    rpe REAL,
    notes TEXT NOT NULL DEFAULT '',
    completed_at TEXT,
    FOREIGN KEY (session_id) REFERENCES workout_sessions(id) ON DELETE CASCADE,
    FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE RESTRICT
  )
  ''',
  '''
  CREATE TABLE body_weight_entries (
    id TEXT PRIMARY KEY NOT NULL,
    date TEXT NOT NULL,
    weight_kg REAL NOT NULL,
    notes TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  )
  ''',
  '''
  CREATE TABLE food_entries (
    id TEXT PRIMARY KEY NOT NULL,
    date TEXT NOT NULL,
    meal_type TEXT NOT NULL DEFAULT 'snack',
    description TEXT NOT NULL DEFAULT '',
    calories REAL,
    protein_grams REAL,
    carbs_grams REAL,
    fat_grams REAL,
    notes TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  )
  ''',
  '''
  CREATE TABLE water_entries (
    id TEXT PRIMARY KEY NOT NULL,
    date TEXT NOT NULL,
    amount_ml INTEGER NOT NULL,
    created_at TEXT NOT NULL
  )
  ''',
  '''
  CREATE TABLE personal_goals (
    id TEXT PRIMARY KEY NOT NULL,
    goal_type TEXT NOT NULL,
    target_value REAL NOT NULL,
    unit TEXT NOT NULL DEFAULT '',
    start_date TEXT,
    end_date TEXT,
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  )
  ''',
];

const List<String> v1Indexes = [
  'CREATE INDEX idx_exercises_category ON exercises(category)',
  'CREATE INDEX idx_exercises_name ON exercises(name)',
  'CREATE INDEX idx_routines_day_of_week ON routines(day_of_week)',
  'CREATE INDEX idx_routine_exercises_routine_id ON routine_exercises(routine_id)',
  'CREATE INDEX idx_workout_sessions_started_at ON workout_sessions(started_at)',
  'CREATE INDEX idx_workout_sessions_routine_id ON workout_sessions(routine_id)',
  'CREATE INDEX idx_workout_sets_session_id ON workout_sets(session_id)',
  'CREATE INDEX idx_workout_sets_exercise_id ON workout_sets(exercise_id)',
  'CREATE UNIQUE INDEX idx_body_weight_entries_date ON body_weight_entries(date)',
  'CREATE INDEX idx_food_entries_date ON food_entries(date)',
  'CREATE INDEX idx_water_entries_date ON water_entries(date)',
  'CREATE INDEX idx_personal_goals_goal_type ON personal_goals(goal_type)',
];

const List<String> v1ToV2Migration = [
  "ALTER TABLE exercises ADD COLUMN equipment TEXT NOT NULL DEFAULT ''",
  'ALTER TABLE routine_exercises ADD COLUMN target_reps_min INTEGER',
  'ALTER TABLE routine_exercises ADD COLUMN target_reps_max INTEGER',
];

const List<String> v2Indexes = [
  'CREATE INDEX IF NOT EXISTS idx_exercises_equipment ON exercises(equipment)',
  'CREATE INDEX IF NOT EXISTS idx_exercises_muscle_group ON exercises(muscle_group)',
];

const List<String> v2ToV3Migration = [
  'ALTER TABLE workout_sets ADD COLUMN is_warmup INTEGER NOT NULL DEFAULT 0',
];

const List<String> v3ToV4Migration = [
  '''
  CREATE TABLE exercise_settings (
    id TEXT PRIMARY KEY NOT NULL,
    exercise_id TEXT NOT NULL,
    min_reps INTEGER NOT NULL DEFAULT 8,
    max_reps INTEGER NOT NULL DEFAULT 12,
    weight_increment_kg REAL NOT NULL DEFAULT 2.5,
    is_bodyweight INTEGER NOT NULL DEFAULT 0,
    machine_increment_kg REAL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
  )
  ''',
  '''
  CREATE TABLE overload_recommendations (
    id TEXT PRIMARY KEY NOT NULL,
    exercise_id TEXT NOT NULL,
    session_id TEXT,
    recommended_weight_kg REAL,
    recommended_reps INTEGER,
    previous_weight_kg REAL,
    previous_reps INTEGER,
    reasoning TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TEXT NOT NULL,
    FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE,
    FOREIGN KEY (session_id) REFERENCES workout_sessions(id) ON DELETE SET NULL
  )
  ''',
];

const List<String> v4Indexes = [
  'CREATE UNIQUE INDEX IF NOT EXISTS idx_exercise_settings_exercise_id ON exercise_settings(exercise_id)',
  'CREATE INDEX IF NOT EXISTS idx_overload_recommendations_exercise_id ON overload_recommendations(exercise_id)',
  'CREATE INDEX IF NOT EXISTS idx_overload_recommendations_session_id ON overload_recommendations(session_id)',
];

const List<String> v4ToV5Migration = [
  '''
  CREATE TABLE body_measurements (
    id TEXT PRIMARY KEY NOT NULL,
    date TEXT NOT NULL,
    waist_cm REAL,
    chest_cm REAL,
    left_arm_cm REAL,
    right_arm_cm REAL,
    hips_cm REAL,
    notes TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  )
  ''',
];

const List<String> v5Indexes = [
  'CREATE INDEX IF NOT EXISTS idx_body_measurements_date ON body_measurements(date)',
];

const List<String> v5ToV6Migration = [
  '''
  CREATE TABLE foods (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'other',
    serving_size REAL NOT NULL DEFAULT 1.0,
    serving_unit TEXT NOT NULL DEFAULT 'serving',
    calories_per_serving REAL NOT NULL DEFAULT 0,
    protein_per_serving REAL NOT NULL DEFAULT 0,
    carbs_per_serving REAL NOT NULL DEFAULT 0,
    fat_per_serving REAL NOT NULL DEFAULT 0,
    is_custom INTEGER NOT NULL DEFAULT 1,
    is_estimate INTEGER NOT NULL DEFAULT 0,
    is_favorite INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  )
  ''',
  '''
  CREATE TABLE meal_templates (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    meal_type TEXT NOT NULL DEFAULT 'snack',
    notes TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  )
  ''',
  '''
  CREATE TABLE meal_template_items (
    id TEXT PRIMARY KEY NOT NULL,
    template_id TEXT NOT NULL,
    food_id TEXT NOT NULL,
    servings REAL NOT NULL DEFAULT 1.0,
    created_at TEXT NOT NULL,
    FOREIGN KEY (template_id) REFERENCES meal_templates(id) ON DELETE CASCADE,
    FOREIGN KEY (food_id) REFERENCES foods(id) ON DELETE CASCADE
  )
  ''',
];

const List<String> v6Indexes = [
  'CREATE INDEX IF NOT EXISTS idx_foods_name ON foods(name)',
  'CREATE INDEX IF NOT EXISTS idx_foods_category ON foods(category)',
  'CREATE INDEX IF NOT EXISTS idx_foods_is_favorite ON foods(is_favorite)',
  'CREATE INDEX IF NOT EXISTS idx_meal_template_items_template_id ON meal_template_items(template_id)',
  'CREATE INDEX IF NOT EXISTS idx_meal_template_items_food_id ON meal_template_items(food_id)',
];
