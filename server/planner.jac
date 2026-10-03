import from datetime { date, timedelta, datetime }
import from jaclang.byllm.lib { ByLLMError }

enum Priority: str {
    LOW = "low",
    MEDIUM = "medium",
    HIGH = "high"
}

node Course {
    has name: str;
    has color: str = "#7c5cff";
}

node Task {
    has title: str;
    has notes: str = "";
    has due_date: str = "";
    has due_time: str = "";
    has priority: Priority = Priority.MEDIUM;
    has done: bool = False;
    has created_at: str = "";
}

edge TaskCourse: Task --> Course {}

node Habit {
    has name: str;
    has target_per_week: int = 7;
    has history: list[str] = [];
    has created_at: str = "";
}

obj TaskView {
    has id: str,
        title: str,
        notes: str,
        due_date: str,
        due_time: str,
        priority: str,
        done: bool,
        course_id: str = "",
        course_name: str = "",
        course_color: str = "";
}

obj CourseView {
    has id: str,
        name: str,
        color: str,
        task_count: int = 0,
        open_count: int = 0;
}

obj HabitView {
    has id: str,
        name: str,
        target_per_week: int,
        streak: int,
        best_streak: int,
        done_today: bool,
        history: list[str];
}

obj TodaySummary {
    has today: str,
        overdue: list[TaskView] = [],
        due_today: list[TaskView] = [],
        upcoming: list[TaskView] = [],
        habits_today: list[HabitView] = [];
}

def today_str -> str {
    return date.today().isoformat();
}

def now_str -> str {
    return datetime.now().isoformat();
}

def parse_priority(value: str) -> Priority {
    match value.strip().lower() {
        case "low":
            return Priority.LOW;
        case "high":
            return Priority.HIGH;
        case _:
            return Priority.MEDIUM;
    }
}

def task_sort_key(t: Task) -> tuple[str, str, int] {
    d = t.due_date if t.due_date else "9999-12-31";
    tm = t.due_time if t.due_time else "99:99";
    rank = 0 if t.priority == Priority.HIGH else (1 if t.priority == Priority.MEDIUM else 2);
    return (d, tm, rank);
}

def longest_streak(days: set[str]) -> int {
    best = 0;
    for d_str in days {
        y: int = int(d_str[0:4]);
        m: int = int(d_str[5:7]);
        dd: int = int(d_str[8:10]);
        prev = (date(y, m, dd) - timedelta(days=1)).isoformat();
        if prev in days {
            continue;
        }
        run = 1;
        cur = date(y, m, dd);
        while (cur + timedelta(days=1)).isoformat() in days {
            cur = cur + timedelta(days=1);
            run += 1;
        }
        if run > best {
            best = run;
        }
    }
    return best;
}

def current_streak(history: list[str]) -> int {
    days = set(history);
    cur = date.today();
    if cur.isoformat() not in days {
        cur = cur - timedelta(days=1);
    }
    streak = 0;
    while cur.isoformat() in days {
        streak += 1;
        cur = cur - timedelta(days=1);
    }
    return streak;
}

def task_to_view(t: Task) -> TaskView {
    courses = [t ->:TaskCourse:->];
    course = courses[0] if courses else None;
    return TaskView(
        id=jid(t),
        title=t.title,
        notes=t.notes,
        due_date=t.due_date,
        due_time=t.due_time,
        priority=str(t.priority),
        done=t.done,
        course_id=jid(course) if course else "",
        course_name=course.name if course else "",
        course_color=course.color if course else ""
    );
}

def habit_to_view(h: Habit) -> HabitView {
    return HabitView(
        id=jid(h),
        name=h.name,
        target_per_week=h.target_per_week,
        streak=current_streak(h.history),
        best_streak=longest_streak(set(h.history)),
        done_today=today_str() in h.history,
        history=sorted(h.history)
    );
}

def find_course(course_id: str) -> Course | None {
    if not course_id {
        return None;
    }
    found = jobj(course_id);
    if isinstance(found, Course) {
        return found;
    }
    return None;
}

def find_task(task_id: str) -> Task | None {
    found = jobj(task_id);
    if isinstance(found, Task) {
        return found;
    }
    return None;
}

def find_habit(habit_id: str) -> Habit | None {
    found = jobj(habit_id);
    if isinstance(found, Habit) {
        return found;
    }
    return None;
}

def:pub list_courses -> list[CourseView] {
    views: list[CourseView] = [];
    for c in [root -->][?:Course] {
        tasks = [c <-:TaskCourse:<-][?:Task];
        views.append(CourseView(
            id=jid(c),
            name=c.name,
            color=c.color,
            task_count=len(tasks),
            open_count=len([t for t in tasks if not t.done])
        ));
    }
    return sorted(views, key=lambda (v: CourseView) { v.name; });
}

def:pub add_course(name: str, color: str = "#7c5cff") -> CourseView {
    clean = name.strip() or "Untitled course";
    c = root ++> Course(name=clean, color=color or "#7c5cff");
    return CourseView(id=jid(c), name=c.name, color=c.color, task_count=0, open_count=0);
}

def:pub delete_course(course_id: str) -> bool {
    c = find_course(course_id);
    if c is None {
        return False;
    }
    del c;
    return True;
}

def:pub list_tasks(course_id: str = "", include_done: bool = True) -> list[TaskView] {
    tasks = [root -->][?:Task];
    if course_id {
        tasks = [t for t in tasks if [t ->:TaskCourse:->] and jid([t ->:TaskCourse:->][0]) == course_id];
    }
    if not include_done {
        tasks = [t for t in tasks if not t.done];
    }
    tasks = sorted(tasks, key=task_sort_key);
    return [task_to_view(t) for t in tasks];
}

def:pub add_task(
    title: str,
    notes: str = "",
    due_date: str = "",
    due_time: str = "",
    priority: str = "medium",
    course_id: str = ""
) -> TaskView {
    clean = title.strip() or "Untitled task";
    t = root ++> Task(
        title=clean,
        notes=notes,
        due_date=due_date,
        due_time=due_time,
        priority=parse_priority(priority),
        created_at=now_str()
    );
    course = find_course(course_id);
    if course is not None {
        t +>:TaskCourse():+> course;
    }
    return task_to_view(t);
}

def:pub update_task(
    task_id: str,
    title: str | None = None,
    notes: str | None = None,
    due_date: str | None = None,
    due_time: str | None = None,
    priority: str | None = None,
    course_id: str | None = None
) -> TaskView | None {
    t = find_task(task_id);
    if t is None {
        return None;
    }
    if title is not None {
        t.title = title.strip() or t.title;
    }
    if notes is not None {
        t.notes = notes;
    }
    if due_date is not None {
        t.due_date = due_date;
    }
    if due_time is not None {
        t.due_time = due_time;
    }
    if priority is not None {
        t.priority = parse_priority(priority);
    }
    if course_id is not None {
        del [edge t ->:TaskCourse:->];
        course = find_course(course_id);
        if course is not None {
            t +>:TaskCourse():+> course;
        }
    }
    return task_to_view(t);
}

def:pub toggle_task(task_id: str) -> TaskView | None {
    t = find_task(task_id);
    if t is None {
        return None;
    }
    t.done = not t.done;
    return task_to_view(t);
}

def:pub delete_task(task_id: str) -> bool {
    t = find_task(task_id);
    if t is None {
        return False;
    }
    del t;
    return True;
}

def:pub list_habits -> list[HabitView] {
    habits = [root -->][?:Habit];
    views = [habit_to_view(h) for h in habits];
    return sorted(views, key=lambda (v: HabitView) { v.name; });
}

def:pub add_habit(name: str, target_per_week: int = 7) -> HabitView {
    clean = name.strip() or "Untitled habit";
    target = target_per_week if 1 <= target_per_week <= 7 else 7;
    h = root ++> Habit(name=clean, target_per_week=target, created_at=now_str());
    return habit_to_view(h);
}

def:pub toggle_habit_today(habit_id: str) -> HabitView | None {
    h = find_habit(habit_id);
    if h is None {
        return None;
    }
    today = today_str();
    if today in h.history {
        h.history = [d for d in h.history if d != today];
    } else {
        h.history = h.history + [today];
    }
    return habit_to_view(h);
}

def:pub delete_habit(habit_id: str) -> bool {
    h = find_habit(habit_id);
    if h is None {
        return False;
    }
    del h;
    return True;
}

def:pub today -> TodaySummary {
    the_today = today_str();
    horizon = (date.today() + timedelta(days=7)).isoformat();
    tasks = [t for t in [root -->][?:Task] if not t.done];
    overdue = [t for t in tasks if t.due_date and t.due_date < the_today];
    due_today = [t for t in tasks if t.due_date == the_today];
    upcoming = [t for t in tasks if t.due_date and the_today < t.due_date <= horizon];
    overdue = sorted(overdue, key=task_sort_key);
    due_today = sorted(due_today, key=task_sort_key);
    upcoming = sorted(upcoming, key=task_sort_key);
    habits = [root -->][?:Habit];
    return TodaySummary(
        today=the_today,
        overdue=[task_to_view(t) for t in overdue],
        due_today=[task_to_view(t) for t in due_today],
        upcoming=[task_to_view(t) for t in upcoming],
        habits_today=[habit_to_view(h) for h in habits]
    );
}

obj SubtaskSuggestion {
    has ok: bool,
        subtasks: list[str] = [],
        error: str = "";
}

def breakdown_task(title: str, notes: str) -> list[str] by llm();
sem breakdown_task = "Break a task into 3-5 small, concrete, actionable subtasks a student could check off independently.";
sem breakdown_task.title = "The task's title.";
sem breakdown_task.notes = "Optional extra context or notes about the task; may be empty.";

def:pub suggest_subtasks(title: str, notes: str = "") -> SubtaskSuggestion {
    clean = title.strip();
    if not clean {
        return SubtaskSuggestion(ok=False, subtasks=[], error="Task title is empty.");
    }
    try {
        subtasks = breakdown_task(clean, notes);
        return SubtaskSuggestion(ok=True, subtasks=subtasks);
    } except ByLLMError as e {
        return SubtaskSuggestion(ok=False, subtasks=[], error=str(e));
    } except Exception {
        return SubtaskSuggestion(ok=False, subtasks=[], error="AI breakdown is unavailable right now.");
    }
}
