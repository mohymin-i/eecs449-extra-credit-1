import from server.planner { HabitView, list_habits, add_habit, toggle_habit_today, delete_habit }

def:pub HabitsPage -> JsxPage {
    has habits: list[HabitView] = [],
        loading: bool = True,
        error: str = "",
        new_name: str = "",
        new_target: int = 7,
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
            error = "Could not load habits - is the server running?";
        }
        loading = False;
    }

    async def handle_add(e: any) {
        e.preventDefault();
        clean = new_name.strip();
        if not clean {
            return;
        }
        try {
            await add_habit(name=clean, target_per_week=new_target);
            new_name = "";
            new_target = 7;
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

    <div className="page">
        <h1>Habits</h1>
        {(<p className="error">{error}</p>) if error else <></>}

        <form className="quick-add" onSubmit={handle_add}>
            <input
                className="input grow"
                placeholder="Habit name (e.g. Stretch, Read 20 min)"
                value={new_name}
                onChange={lambda (e: ChangeEvent) { new_name = e.target.value; }}
            />
            <input
                className="input"
                type="number"
                min="1"
                max="7"
                value={str(new_target)}
                onChange={lambda (e: ChangeEvent) { new_target = int(e.target.value or "7"); }}
            />
            <button className="btn primary" type="submit">Add habit</button>
        </form>

        {(<p className="muted">Loading...</p>) if loading else <></>}
        {(<p className="empty">No habits yet.</p>) if (not loading and not habits) else <></>}

        {[
            <div key={h.id} className="habit-row">
                <input
                    className="checkbox"
                    type="checkbox"
                    checked={h.done_today}
                    disabled={busy_id == h.id}
                    onChange={lambda { handle_toggle(h.id); }}
                />
                <div className="habit-main">
                    <span className="task-title">{h.name}</span>
                    <span className="streak">
                        streak {str(h.streak)} · best {str(h.best_streak)} · target {str(h.target_per_week)}/wk
                    </span>
                </div>
                <button className="btn small danger" disabled={busy_id == h.id} onClick={lambda { handle_delete(h.id); }}>Delete</button>
            </div>
            for h in habits
        ]}
    </div>
}
