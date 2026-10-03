import from server.planner { TodaySummary, TaskView, HabitView, today, toggle_task, toggle_habit_today, add_task }

def:pub TodayPage -> JsxPage {
    has summary: TodaySummary | None = None,
        loading: bool = True,
        error: str = "",
        new_title: str = "",
        new_due: str = "",
        new_priority: str = "medium",
        busy_id: str = "";

    async can with entry {
        await load();
    }

    async def load {
        loading = True;
        error = "";
        try {
            summary = await today();
        } except Exception {
            error = "Could not load today's plan - is the server running?";
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

    async def handle_quick_add(e: any) {
        e.preventDefault();
        clean_title = new_title.strip();
        if not clean_title {
            return;
        }
        try {
            await add_task(title=clean_title, due_date=new_due, priority=new_priority);
            new_title = "";
            new_due = "";
            new_priority = "medium";
            await load();
        } except Exception {
            error = "Could not add that task.";
        }
    }

    if loading and summary is None {
        return <div className="page"><p className="muted">Loading today's plan...</p></div>;
    }

    s = summary;

    <div className="page">
        <h1>Today</h1>
        {(<p className="error">{error}</p>) if error else <></>}

        <form className="quick-add" onSubmit={handle_quick_add}>
            <input
                className="input grow"
                placeholder="Add a task for today..."
                value={new_title}
                onChange={lambda (e: ChangeEvent) { new_title = e.target.value; }}
            />
            <input
                className="input"
                type="date"
                value={new_due}
                onChange={lambda (e: ChangeEvent) { new_due = e.target.value; }}
            />
            <select
                className="input"
                value={new_priority}
                onChange={lambda (e: ChangeEvent) { new_priority = e.target.value; }}
            >
                <option value="low">Low</option>
                <option value="medium">Medium</option>
                <option value="high">High</option>
            </select>
            <button className="btn primary" type="submit">Add</button>
        </form>

        {if s is not None {
            <>
                <section className="section">
                    <h2>Overdue ({len(s.overdue)})</h2>
                    {(<p className="muted">Nothing overdue.</p>) if not s.overdue else <></>}
                    {[
                        <div key={t.id} className="task-row">
                            <input
                                className="checkbox"
                                type="checkbox"
                                checked={t.done}
                                disabled={busy_id == t.id}
                                onChange={lambda { handle_toggle_task(t.id); }}
                            />
                            <div className="task-main">
                                <span className={"task-title done" if t.done else "task-title"}>{t.title}</span>
                                <span className="task-meta">
                                    {t.due_date}{(" " + t.due_time) if t.due_time else ""}{(" · " + t.course_name) if t.course_name else ""}
                                </span>
                            </div>
                            <span className={"badge " + t.priority}>{t.priority}</span>
                        </div>
                        for t in s.overdue
                    ]}
                </section>

                <section className="section">
                    <h2>Due today ({len(s.due_today)})</h2>
                    {(<p className="muted">Nothing due today.</p>) if not s.due_today else <></>}
                    {[
                        <div key={t.id} className="task-row">
                            <input
                                className="checkbox"
                                type="checkbox"
                                checked={t.done}
                                disabled={busy_id == t.id}
                                onChange={lambda { handle_toggle_task(t.id); }}
                            />
                            <div className="task-main">
                                <span className={"task-title done" if t.done else "task-title"}>{t.title}</span>
                                <span className="task-meta">
                                    {(t.due_time) if t.due_time else ""}{(" · " + t.course_name) if t.course_name else ""}
                                </span>
                            </div>
                            <span className={"badge " + t.priority}>{t.priority}</span>
                        </div>
                        for t in s.due_today
                    ]}
                </section>

                {if s.upcoming {
                    <section className="section">
                        <h2>Upcoming (next 7 days)</h2>
                        {[
                            <div key={t.id} className="task-row">
                                <input
                                    className="checkbox"
                                    type="checkbox"
                                    checked={t.done}
                                    disabled={busy_id == t.id}
                                    onChange={lambda { handle_toggle_task(t.id); }}
                                />
                                <div className="task-main">
                                    <span className="task-title">{t.title}</span>
                                    <span className="task-meta">
                                        {t.due_date}{(" · " + t.course_name) if t.course_name else ""}
                                    </span>
                                </div>
                                <span className={"badge " + t.priority}>{t.priority}</span>
                            </div>
                            for t in s.upcoming
                        ]}
                    </section>
                } else { <></> }}

                <section className="section">
                    <h2>Habits today</h2>
                    {(<p className="muted">No habits yet - add one on the Habits page.</p>) if not s.habits_today else <></>}
                    {[
                        <div key={h.id} className="habit-row">
                            <input
                                className="checkbox"
                                type="checkbox"
                                checked={h.done_today}
                                disabled={busy_id == h.id}
                                onChange={lambda { handle_toggle_habit(h.id); }}
                            />
                            <div className="habit-main">
                                <span className="task-title">{h.name}</span>
                                <span className="streak">streak: {str(h.streak)}</span>
                            </div>
                        </div>
                        for h in s.habits_today
                    ]}
                </section>
            </>
        } else { <></> }}
    </div>
}
