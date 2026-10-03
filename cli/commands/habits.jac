import from jaclang.server.bridge { BridgeError }
import from cli.commands.common { warn, short_id, resolve_id, EXIT_OK, EXIT_USAGE, EXIT_FAILURE, explain_bridge_error }
import from server.planner { HabitView, list_habits, add_habit, toggle_habit_today, delete_habit }

def format_habit_line(h: HabitView) -> str {
    mark = "x" if h.done_today else " ";
    return (
        "[" + mark + "] " + short_id(h.id) + "  " + h.name
            + "  (streak " + str(h.streak) + ", best " + str(h.best_streak)
            + ", target " + str(h.target_per_week) + "/wk)"
    );
}

async def run_habits -> int {
    try {
        rows = await list_habits();
    } except BridgeError as e {
        return explain_bridge_error(e);
    }
    if not rows {
        print("no habits yet - add one with `planner habit add \"Name\"`");
        return EXIT_OK;
    }
    for h in rows {
        print(format_habit_line(h));
    }
    return EXIT_OK;
}

async def run_habit_add(name: str, target_per_week: int) -> int {
    clean = name.strip();
    if not clean {
        warn("planner habit add: a name is required");
        return EXIT_USAGE;
    }
    try {
        created = await add_habit(name=clean, target_per_week=target_per_week);
    } except BridgeError as e {
        return explain_bridge_error(e);
    }
    print("added " + format_habit_line(created));
    return EXIT_OK;
}

async def run_habit_done(prefix: str) -> int {
    try {
        rows = await list_habits();
        target = resolve_id(prefix, [h.id for h in rows], "planner habit done");
        if target is None {
            return EXIT_USAGE;
        }
        updated = await toggle_habit_today(target);
    } except BridgeError as e {
        return explain_bridge_error(e);
    }
    if updated is None {
        warn("planner habit done: that habit no longer exists");
        return EXIT_FAILURE;
    }
    print(("checked off " if updated.done_today else "unchecked ") + format_habit_line(updated));
    return EXIT_OK;
}

async def run_habit_rm(prefix: str) -> int {
    try {
        rows = await list_habits();
        target = resolve_id(prefix, [h.id for h in rows], "planner habit rm");
        if target is None {
            return EXIT_USAGE;
        }
        ok = await delete_habit(target);
    } except BridgeError as e {
        return explain_bridge_error(e);
    }
    if not ok {
        warn("planner habit rm: that habit no longer exists");
        return EXIT_FAILURE;
    }
    print("removed " + short_id(target as str));
    return EXIT_OK;
}
