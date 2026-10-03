import from "@jac/mobui" { View, Text, Pressable, TextInput, ScrollView, Switch }
import from "@jac/runtime" { BridgeError }
import from ..theme { styles, C }
import from server.planner { TodaySummary, TaskView, HabitView, today, toggle_task, toggle_habit_today, add_task }

def:pub TodayScreen -> JsxElement {
    has summary: TodaySummary | None = None,
        loading: bool = True,
        error: str = "",
        new_title: str = "",
        busy_id: str = "";

    async can with entry {
        await load();
    }

    async def load {
        loading = True;
        error = "";
        try {
            summary = await today();
        } except BridgeError {
            error = "Could not reach the planner server.";
        } except Exception {
            error = "Could not load today's plan.";
        }
        loading = False;
    }

    async def handle_toggle_task(task_id: str) {
        busy_id = task_id;
        try {
            await toggle_task(task_id);
            await load();
        } except Exception {
            error = "Could not update that task.";
        }
        busy_id = "";
    }

    async def handle_toggle_habit(habit_id: str) {
        busy_id = habit_id;
        try {
            await toggle_habit_today(habit_id);
            await load();
        } except Exception {
            error = "Could not update that habit.";
        }
        busy_id = "";
    }

    async def handle_quick_add {
        clean = new_title.strip();
        if not clean {
            return;
        }
        try {
            await add_task(title=clean, due_date="", due_time="", priority="medium", course_id="");
            new_title = "";
            await load();
        } except Exception {
            error = "Could not add that task.";
        }
    }

    s = summary;

    <ScrollView style={styles.screen} contentContainerStyle={styles.scrollBody}>
        <Text style={styles.title}>Today</Text>
        {(<Text style={styles.error}>{error}</Text>) if error else <View/>}

        <View style={styles.row}>
            <TextInput
                style={[styles.input, styles.grow]}
                placeholder="Add a task..."
                placeholderTextColor={C.muted}
                value={new_title}
                onChangeText={lambda (t: str) { new_title = t; }}
            />
            <Pressable style={styles.button} onPress={handle_quick_add}>
                <Text style={styles.buttonText}>Add</Text>
            </Pressable>
        </View>

        {(<Text style={styles.muted}>Loading...</Text>) if (loading and s is None) else <View/>}

        {if s is not None {
            <>
                <Text style={styles.sectionTitle}>Overdue ({str(len(s.overdue))})</Text>
                {(<Text style={styles.muted}>Nothing overdue.</Text>) if not s.overdue else <View/>}
                {[
                    <View key={t.id} style={[styles.card, styles.row]}>
                        <Switch
                            value={t.done}
                            disabled={busy_id == t.id}
                            onValueChange={lambda (v: bool) { handle_toggle_task(t.id); }}
                        />
                        <View style={styles.grow}>
                            <Text style={styles.taskTitleDone if t.done else styles.taskTitle}>{t.title}</Text>
                            <Text style={styles.taskMeta}>{t.due_date}{(" · " + t.course_name) if t.course_name else ""}</Text>
                        </View>
                    </View>
                    for t in s.overdue
                ]}

                <Text style={styles.sectionTitle}>Due today ({str(len(s.due_today))})</Text>
                {(<Text style={styles.muted}>Nothing due today.</Text>) if not s.due_today else <View/>}
                {[
                    <View key={t.id} style={[styles.card, styles.row]}>
                        <Switch
                            value={t.done}
                            disabled={busy_id == t.id}
                            onValueChange={lambda (v: bool) { handle_toggle_task(t.id); }}
                        />
                        <View style={styles.grow}>
                            <Text style={styles.taskTitleDone if t.done else styles.taskTitle}>{t.title}</Text>
                            <Text style={styles.taskMeta}>{(t.due_time) if t.due_time else ""}{(" · " + t.course_name) if t.course_name else ""}</Text>
                        </View>
                    </View>
                    for t in s.due_today
                ]}

                <Text style={styles.sectionTitle}>Habits today</Text>
                {(<Text style={styles.muted}>No habits yet.</Text>) if not s.habits_today else <View/>}
                {[
                    <View key={h.id} style={[styles.card, styles.row]}>
                        <Switch
                            value={h.done_today}
                            disabled={busy_id == h.id}
                            onValueChange={lambda (v: bool) { handle_toggle_habit(h.id); }}
                        />
                        <View style={styles.grow}>
                            <Text style={styles.taskTitle}>{h.name}</Text>
                            <Text style={styles.taskMeta}>streak: {str(h.streak)}</Text>
                        </View>
                    </View>
                    for h in s.habits_today
                ]}
            </>
        } else { <View/> }}
    </ScrollView>
}
