import from server.planner { CourseView, list_courses, add_course, delete_course }

def:pub CoursesPage -> JsxPage {
    has courses: list[CourseView] = [],
        loading: bool = True,
        error: str = "",
        new_name: str = "",
        new_color: str = "#7c5cff",
        busy_id: str = "";

    async can with entry {
        await load();
    }

    async def load {
        loading = True;
        error = "";
        try {
            courses = await list_courses();
        } except Exception {
            error = "Could not load courses - is the server running?";
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
            await add_course(name=clean, color=new_color);
            new_name = "";
            new_color = "#7c5cff";
            await load();
        } except Exception {
            error = "Could not add that course.";
        }
    }

    async def handle_delete(course_id: str) {
        busy_id = course_id;
        try {
            await delete_course(course_id);
            await load();
        } except Exception {
            error = "Could not remove that course.";
        }
        busy_id = "";
    }

    <div className="page">
        <h1>Courses</h1>
        {(<p className="error">{error}</p>) if error else <></>}

        <form className="quick-add" onSubmit={handle_add}>
            <input
                className="input grow"
                placeholder="Course name (e.g. EECS 449)"
                value={new_name}
                onChange={lambda (e: ChangeEvent) { new_name = e.target.value; }}
            />
            <input
                className="input"
                type="color"
                value={new_color}
                onChange={lambda (e: ChangeEvent) { new_color = e.target.value; }}
            />
            <button className="btn primary" type="submit">Add course</button>
        </form>

        {(<p className="muted">Loading...</p>) if loading else <></>}
        {(<p className="empty">No courses yet.</p>) if (not loading and not courses) else <></>}

        {[
            <div key={c.id} className="course-row">
                <span className="swatch" style={{"backgroundColor": c.color}}></span>
                <div className="course-main">
                    <span className="task-title">{c.name}</span>
                    <span className="task-meta">{str(c.open_count)} open / {str(c.task_count)} total tasks</span>
                </div>
                <button className="btn small danger" disabled={busy_id == c.id} onClick={lambda { handle_delete(c.id); }}>Delete</button>
            </div>
            for c in courses
        ]}
    </div>
}
