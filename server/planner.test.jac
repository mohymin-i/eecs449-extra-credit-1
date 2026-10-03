test "add_task creates a task visible in list_tasks" {
    created = add_task(title="TEST__Finish lab report", priority="high", due_date="2026-01-01");
    assert created.title == "TEST__Finish lab report";
    assert created.priority == "high";
    assert not created.done;

    found = [v for v in list_tasks() if v.id == created.id];
    assert len(found) == 1;
}

test "toggle_task flips done and delete_task removes it" {
    created = add_task(title="TEST__Toggle me");
    toggled = toggle_task(created.id);
    assert toggled is not None;
    assert toggled.done;

    toggled_back = toggle_task(created.id);
    assert toggled_back is not None;
    assert not toggled_back.done;

    assert delete_task(created.id);
    assert not delete_task(created.id);
}

test "courses link to tasks and report open counts" {
    course = add_course(name="TEST__EECS 449", color="#00aa00");
    add_task(title="TEST__Read paper", course_id=course.id);
    t2 = add_task(title="TEST__Write snippet", course_id=course.id);
    toggle_task(t2.id);

    views = [c for c in list_courses() if c.id == course.id];
    assert len(views) == 1;
    assert views[0].task_count == 2;
    assert views[0].open_count == 1;

    tasks_for_course = list_tasks(course_id=course.id);
    assert len(tasks_for_course) == 2;
    assert all(v.course_name == "TEST__EECS 449" for v in tasks_for_course);
}

test "habit streak counts consecutive completed days ending today" {
    habit = add_habit(name="TEST__Stretch", target_per_week=7);
    assert habit.streak == 0;
    assert not habit.done_today;

    toggled = toggle_habit_today(habit.id);
    assert toggled is not None;
    assert toggled.done_today;
    assert toggled.streak == 1;

    untoggled = toggle_habit_today(habit.id);
    assert untoggled is not None;
    assert not untoggled.done_today;
    assert untoggled.streak == 0;

    assert delete_habit(habit.id);
}

test "today groups overdue, due-today, and upcoming tasks" {
    past = add_task(title="TEST__Overdue thing", due_date="2000-01-01");
    now_task = add_task(title="TEST__Today thing", due_date=today_str());
    soon = add_task(title="TEST__Soon thing", due_date=(date.today() + timedelta(days=2)).isoformat());

    summary = today();
    overdue_ids = [v.id for v in summary.overdue];
    due_today_ids = [v.id for v in summary.due_today];
    upcoming_ids = [v.id for v in summary.upcoming];

    assert past.id in overdue_ids;
    assert now_task.id in due_today_ids;
    assert soon.id in upcoming_ids;

    delete_task(past.id);
    delete_task(now_task.id);
    delete_task(soon.id);
}
