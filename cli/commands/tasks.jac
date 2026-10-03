import from jaclang.server.bridge { BridgeError }
import from cli.commands.common { warn, short_id, resolve_id, EXIT_OK, EXIT_USAGE, EXIT_FAILURE, explain_bridge_error }
import from server.planner {
    TaskView,
    list_courses,
    list_tasks,
    add_task,
    toggle_task,
    delete_task,
    today,
    suggest_subtasks
}

def format_task_line(t: TaskView) -> str {
    mark = "x" if t.done else " ";
    due = t.due_date if t.due_date else "no date";
    if t.due_time {
        due = due + " " + t.due_time;
    }
    course = " (" + t.course_name + ")" if t.course_name else "";
    return "[" + mark + "] " + short_id(t.id) + "  " + t.priority.upper() + "  " + due + "  " + t.title + course;
}

async def resolve_course_id(course_name: str) -> str {
    if not course_name {
        return "";
    }
    courses = await list_courses();
    matches = [c for c in courses if c.name.lower() == course_name.strip().lower()];
    if not matches {
        warn("planner: no course named '" + course_name + "' - add it with `planner course add \"" + course_name + "\"`");
        return "";
    }
    return matches[0].id;
}

async def run_today -> int {
    try {
        summary = await today();
    } except BridgeError as e {
        return explain_bridge_error(e);
    }
    print("Today - " + summary.today);
    if summary.overdue {
        print("");
        print("Overdue:");
        for t in summary.overdue {
            print("  " + format_task_line(t));
        }
    }
    print("");
    print("Due today:");
    if not summary.due_today {
        print("  nothing due today");
    }
    for t in summary.due_today {
        print("  " + format_task_line(t));
    }
    if summary.upcoming {
        print("");
        print("Upcoming (next 7 days):");
        for t in summary.upcoming {
            print("  " + format_task_line(t));
        }
    }
    print("");
    print("Habits today:");
    if not summary.habits_today {
        print("  no habits yet - add one with `planner habit add \"Name\"`");
    }
    for h in summary.habits_today {
        mark = "x" if h.done_today else " ";
        print("  [" + mark + "] " + short_id(h.id) + "  " + h.name + "  (streak: " + str(h.streak) + ")");
    }
    return EXIT_OK;
}

async def run_add(
    title: str,
    notes: str,
    due_date: str,
    due_time: str,
    priority: str,
    course_name: str
) -> int {
    clean = title.strip();
    if not clean {
        warn("planner add: a title is required");
        return EXIT_USAGE;
    }
    try {
        course_id = await resolve_course_id(course_name);
        created = await add_task(
            title=clean,
            notes=notes,
            due_date=due_date,
            due_time=due_time,
            priority=priority,
            course_id=course_id
        );
    } except BridgeError as e {
        return explain_bridge_error(e);
    }
    print("added " + format_task_line(created));
    return EXIT_OK;
}

async def run_list(course_name: str, show_all: bool) -> int {
    try {
        course_id = await resolve_course_id(course_name) if course_name else "";
        rows = await list_tasks(course_id=course_id, include_done=show_all);
    } except BridgeError as e {
        return explain_bridge_error(e);
    }
    if not rows {
        print("no tasks yet - add one with `planner add \"Title\"`");
        return EXIT_OK;
    }
    for t in rows {
        print(format_task_line(t));
    }
    return EXIT_OK;
}

async def run_done(prefix: str) -> int {
    try {
        rows = await list_tasks(course_id="", include_done=True);
        target = resolve_id(prefix, [t.id for t in rows], "planner done");
        if target is None {
            return EXIT_USAGE;
        }
        updated = await toggle_task(target);
    } except BridgeError as e {
        return explain_bridge_error(e);
    }
    if updated is None {
        warn("planner done: that task no longer exists");
        return EXIT_FAILURE;
    }
    print(("completed " if updated.done else "reopened ") + format_task_line(updated));
    return EXIT_OK;
}

async def run_rm(prefix: str) -> int {
    try {
        rows = await list_tasks(course_id="", include_done=True);
        target = resolve_id(prefix, [t.id for t in rows], "planner rm");
        if target is None {
            return EXIT_USAGE;
        }
        ok = await delete_task(target);
    } except BridgeError as e {
        return explain_bridge_error(e);
    }
    if not ok {
        warn("planner rm: that task no longer exists");
        return EXIT_FAILURE;
    }
    print("removed " + short_id(target as str));
    return EXIT_OK;
}

async def run_breakdown(prefix: str) -> int {
    try {
        rows = await list_tasks(course_id="", include_done=True);
        target = resolve_id(prefix, [t.id for t in rows], "planner breakdown");
        if target is None {
            return EXIT_USAGE;
        }
        task = [t for t in rows if t.id == target][0];
        suggestion = await suggest_subtasks(title=task.title, notes=task.notes);
    } except BridgeError as e {
        return explain_bridge_error(e);
    }
    if not suggestion.ok {
        warn("planner breakdown: " + (suggestion.error or "AI breakdown is unavailable"));
        warn("hint: set ANTHROPIC_API_KEY on the server for AI features");
        return EXIT_FAILURE;
    }
    print("Subtask suggestions for: " + task.title);
    for item in suggestion.subtasks {
        print("  - " + item);
    }
    return EXIT_OK;
}
