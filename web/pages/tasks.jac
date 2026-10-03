import from server.planner {
    TaskView,
    CourseView,
    SubtaskSuggestion,
    list_courses,
    list_tasks,
    add_task,
    toggle_task,
    delete_task,
    suggest_subtasks
}

def:pub TasksPage -> JsxPage {
    has tasks: list[TaskView] = [],
        courses: list[CourseView] = [],
        loading: bool = True,
        error: str = "",
        show_done: bool = True,
        filter_course: str = "",
        new_title: str = "",
        new_notes: str = "",
        new_due: str = "",
        new_time: str = "",
        new_priority: str = "medium",
        new_course: str = "",
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
            courses = await list_courses();
            tasks = await list_tasks(course_id=filter_course, include_done=show_done);
        } except Exception {
            error = "Could not load tasks - is the server running?";
        }
        loading = False;
    }

    async def handle_filter_change {
        await load();
    }

    async def handle_add(e: any) {
        e.preventDefault();
        clean_title = new_title.strip();
        if not clean_title {
            return;
        }
        try {
            await add_task(
                title=clean_title,
                notes=new_notes,
                due_date=new_due,
                due_time=new_time,
                priority=new_priority,
                course_id=new_course
            );
            new_title = "";
            new_notes = "";
            new_due = "";
            new_time = "";
            new_priority = "medium";
            new_course = "";
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

    <div className="page">
        <h1>Tasks</h1>
        {(<p className="error">{error}</p>) if error else <></>}

        <form className="card" style={{"marginBottom": "20px"}} onSubmit={handle_add}>
            <div className="quick-add">
                <input
                    className="input grow"
                    placeholder="Task title"
                    value={new_title}
                    onChange={lambda (e: ChangeEvent) { new_title = e.target.value; }}
                />
                <input
                    className="input"
                    type="date"
                    value={new_due}
                    onChange={lambda (e: ChangeEvent) { new_due = e.target.value; }}
                />
                <input
                    className="input"
                    type="time"
                    value={new_time}
                    onChange={lambda (e: ChangeEvent) { new_time = e.target.value; }}
                />
            </div>
            <div className="quick-add">
                <textarea
                    className="input grow"
                    placeholder="Notes (optional)"
                    value={new_notes}
                    onChange={lambda (e: ChangeEvent) { new_notes = e.target.value; }}
                />
            </div>
            <div className="quick-add">
                <select
                    className="input"
                    value={new_priority}
                    onChange={lambda (e: ChangeEvent) { new_priority = e.target.value; }}
                >
                    <option value="low">Low</option>
                    <option value="medium">Medium</option>
                    <option value="high">High</option>
                </select>
                <select
                    className="input"
                    value={new_course}
                    onChange={lambda (e: ChangeEvent) { new_course = e.target.value; }}
                >
                    <option value="">No course</option>
                    {[<option key={c.id} value={c.id}>{c.name}</option> for c in courses]}
                </select>
                <button className="btn primary" type="submit">Add task</button>
            </div>
        </form>

        <div className="filters">
            <select
                className="input"
                value={filter_course}
                onChange={lambda (e: ChangeEvent) { filter_course = e.target.value; handle_filter_change(); }}
            >
                <option value="">All courses</option>
                {[<option key={c.id} value={c.id}>{c.name}</option> for c in courses]}
            </select>
            <label className="muted">
                <input
                    type="checkbox"
                    checked={show_done}
                    onChange={lambda (e: ChangeEvent) { show_done = e.target.checked; handle_filter_change(); }}
                />
                {" "}show completed
            </label>
        </div>

        {(<p className="muted">Loading...</p>) if loading else <></>}
        {(<p className="empty">No tasks match these filters yet.</p>) if (not loading and not tasks) else <></>}

        {[
            <div key={t.id} className="card" style={{"marginBottom": "10px"}}>
                <div className="task-row" style={{"border": "none", "margin": "0", "padding": "0"}}>
                    <input
                        className="checkbox"
                        type="checkbox"
                        checked={t.done}
                        disabled={busy_id == t.id}
                        onChange={lambda { handle_toggle(t.id); }}
                    />
                    <div className="task-main">
                        <span className={"task-title done" if t.done else "task-title"}>{t.title}</span>
                        <span className="task-meta">
                            {(t.due_date) if t.due_date else "no date"}{(" " + t.due_time) if t.due_time else ""}{(" · " + t.course_name) if t.course_name else ""}
                        </span>
                        {(<span className="task-meta">{t.notes}</span>) if t.notes else <></>}
                    </div>
                    <span className={"badge " + t.priority}>{t.priority}</span>
                    <button className="btn small" onClick={lambda { handle_breakdown(t); }}>AI breakdown</button>
                    <button className="btn small danger" disabled={busy_id == t.id} onClick={lambda { handle_delete(t.id); }}>Delete</button>
                </div>
                {if ai_task_id == t.id {
                    <div className="ai-box">
                        {(<p className="muted">Thinking...</p>) if ai_loading else <></>}
                        {if (not ai_loading and ai_result is not None) {
                            r = ai_result;
                            (<ul>{[<li key={item}>{item}</li> for item in r.subtasks]}</ul>) if r.ok else <p className="error">{r.error}</p>;
                        } else { <></> }}
                    </div>
                } else { <></> }}
            </div>
            for t in tasks
        ]}
    </div>
}
