import from "@jac/mobui" { View, Text, Pressable, TextInput, ScrollView, Switch }
import from ..theme { styles, C }
import from server.planner { HabitView, list_habits, add_habit, toggle_habit_today, delete_habit }

def:pub HabitsScreen -> JsxElement {
    has habits: list[HabitView] = [],
        loading: bool = True,
        error: str = "",
        new_name: str = "",
        busy_id: str = "";

    async can with entry {
        await load();
    }

    async def load {
        loading = True;
        error = "";
        try {
            habits = await list_habits();
        } except Exception {
            error = "Could not load habits.";
        }
        loading = False;
    }

    async def handle_add {
        clean = new_name.strip();
        if not clean {
            return;
        }
        try {
            await add_habit(name=clean, target_per_week=7);
            new_name = "";
            await load();
        } except Exception {
            error = "Could not add that habit.";
        }
    }

    async def handle_toggle(habit_id: str) {
        busy_id = habit_id;
        try {
            await toggle_habit_today(habit_id);
            await load();
        } except Exception {
            error = "Could not update that habit.";
        }
        busy_id = "";
    }

    async def handle_delete(habit_id: str) {
        busy_id = habit_id;
        try {
            await delete_habit(habit_id);
            await load();
        } except Exception {
            error = "Could not remove that habit.";
        }
        busy_id = "";
    }

    <ScrollView style={styles.screen} contentContainerStyle={styles.scrollBody}>
        <Text style={styles.title}>Habits</Text>
        {(<Text style={styles.error}>{error}</Text>) if error else <View/>}

        <View style={styles.row}>
            <TextInput
                style={[styles.input, styles.grow]}
                placeholder="New habit name..."
                placeholderTextColor={C.muted}
                value={new_name}
                onChangeText={lambda (t: str) { new_name = t; }}
            />
            <Pressable style={styles.button} onPress={handle_add}>
                <Text style={styles.buttonText}>Add</Text>
            </Pressable>
        </View>

        {(<Text style={styles.muted}>Loading...</Text>) if loading else <View/>}
        {(<Text style={styles.muted}>No habits yet.</Text>) if (not loading and not habits) else <View/>}

        {[
            <View key={h.id} style={[styles.card, styles.rowBetween]}>
                <View style={[styles.row, styles.grow]}>
                    <Switch
                        value={h.done_today}
                        disabled={busy_id == h.id}
                        onValueChange={lambda (v: bool) { handle_toggle(h.id); }}
                    />
                    <View style={styles.grow}>
                        <Text style={styles.taskTitle}>{h.name}</Text>
                        <Text style={styles.taskMeta}>streak {str(h.streak)} · best {str(h.best_streak)}</Text>
                    </View>
                </View>
                <Pressable style={styles.deleteButton} onPress={lambda { handle_delete(h.id); }}>
                    <Text style={styles.deleteButtonText}>Delete</Text>
                </Pressable>
            </View>
            for h in habits
        ]}
    </ScrollView>
}
