import from "@jac/mobui" { View, Text, Pressable, TextInput, ScrollView, Switch }
import from ..theme { styles, C }
import from server.planner {
    TaskView,
    SubtaskSuggestion,
    list_tasks,
    add_task,
    toggle_task,
    delete_task,
    suggest_subtasks
}

def:pub TasksScreen -> JsxElement {
    has tasks: list[TaskView] = [],
        loading: bool = True,
        error: str = "",
        new_title: str = "",
        busy_id: str = "",
        ai_task_id: str = "",
        ai_loading: bool = False,
        ai_result: SubtaskSuggestion | None = None;

    async can with entry {
        await load();
    }

    async def load {
        loading = True;
        error = "";
        try {
            tasks = await list_tasks(course_id="", include_done=True);
        } except Exception {
            error = "Could not load tasks.";
        }
        loading = False;
    }

    async def handle_add {
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

    async def handle_toggle(task_id: str) {
        busy_id = task_id;
        try {
            await toggle_task(task_id);
            await load();
        } except Exception {
            error = "Could not update that task.";
        }
        busy_id = "";
    }

    async def handle_delete(task_id: str) {
        busy_id = task_id;
        try {
            await delete_task(task_id);
            if ai_task_id == task_id {
                ai_task_id = "";
                ai_result = None;
            }
            await load();
        } except Exception {
            error = "Could not remove that task.";
        }
        busy_id = "";
    }

    async def handle_breakdown(t: TaskView) {
        ai_task_id = t.id;
        ai_result = None;
        ai_loading = True;
        try {
            ai_result = await suggest_subtasks(title=t.title, notes=t.notes);
        } except Exception {
            ai_result = SubtaskSuggestion(ok=False, subtasks=[], error="AI breakdown is unavailable right now.");
        }
        ai_loading = False;
    }

    <ScrollView style={styles.screen} contentContainerStyle={styles.scrollBody}>
        <Text style={styles.title}>Tasks</Text>
        {(<Text style={styles.error}>{error}</Text>) if error else <View/>}

        <View style={styles.row}>
            <TextInput
                style={[styles.input, styles.grow]}
                placeholder="New task title..."
                placeholderTextColor={C.muted}
                value={new_title}
                onChangeText={lambda (t: str) { new_title = t; }}
            />
            <Pressable style={styles.button} onPress={handle_add}>
                <Text style={styles.buttonText}>Add</Text>
            </Pressable>
        </View>

        {(<Text style={styles.muted}>Loading...</Text>) if loading else <View/>}
        {(<Text style={styles.muted}>No tasks yet.</Text>) if (not loading and not tasks) else <View/>}

        {[
            <View key={t.id} style={styles.card}>
                <View style={styles.rowBetween}>
                    <View style={[styles.row, styles.grow]}>
                        <Switch
                            value={t.done}
                            disabled={busy_id == t.id}
                            onValueChange={lambda (v: bool) { handle_toggle(t.id); }}
                        />
                        <View style={styles.grow}>
                            <Text style={styles.taskTitleDone if t.done else styles.taskTitle}>{t.title}</Text>
                            <Text style={styles.taskMeta}>
                                {(t.due_date) if t.due_date else "no date"}{(" · " + t.course_name) if t.course_name else ""}
                            </Text>
                        </View>
                    </View>
                    <View style={styles.badge}>
                        <Text style={styles.badgeText}>{t.priority.upper()}</Text>
                    </View>
                </View>
                <View style={[styles.row, {"marginTop": 10}]}>
                    <Pressable style={styles.deleteButton} onPress={lambda { handle_breakdown(t); }}>
                        <Text style={styles.deleteButtonText}>AI breakdown</Text>
                    </Pressable>
                    <Pressable style={styles.deleteButton} onPress={lambda { handle_delete(t.id); }}>
                        <Text style={styles.deleteButtonText}>Delete</Text>
                    </Pressable>
                </View>
                {if ai_task_id == t.id {
                    <View style={{"marginTop": 10}}>
                        {(<Text style={styles.muted}>Thinking...</Text>) if ai_loading else <View/>}
                        {if (not ai_loading and ai_result is not None) {
                            r = ai_result;
                            (<View>{[<Text key={item} style={styles.taskMeta}>- {item}</Text> for item in r.subtasks]}</View>) if r.ok else <Text style={styles.error}>{r.error}</Text>;
                        } else { <View/> }}
                    </View>
                } else { <View/> }}
            </View>
            for t in tasks
        ]}
    </ScrollView>
}
