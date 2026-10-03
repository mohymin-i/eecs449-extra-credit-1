import from jaclang.server.bridge { BridgeError }
import from cli.commands.common { warn, short_id, resolve_id, EXIT_OK, EXIT_USAGE, EXIT_FAILURE, explain_bridge_error }
import from server.planner { CourseView, list_courses, add_course, delete_course }

def format_course_line(c: CourseView) -> str {
    return short_id(c.id) + "  " + c.name + "  (" + str(c.open_count) + " open / " + str(c.task_count) + " total)";
}

async def run_courses -> int {
    try {
        rows = await list_courses();
    } except BridgeError as e {
        return explain_bridge_error(e);
    }
    if not rows {
        print("no courses yet - add one with `planner course add \"Name\"`");
        return EXIT_OK;
    }
    for c in rows {
        print(format_course_line(c));
    }
    return EXIT_OK;
}

async def run_course_add(name: str, color: str) -> int {
    clean = name.strip();
    if not clean {
        warn("planner course add: a name is required");
        return EXIT_USAGE;
    }
    try {
        created = await add_course(name=clean, color=color);
    } except BridgeError as e {
        return explain_bridge_error(e);
    }
    print("added " + format_course_line(created));
    return EXIT_OK;
}

async def run_course_rm(prefix: str) -> int {
    try {
        rows = await list_courses();
        target = resolve_id(prefix, [c.id for c in rows], "planner course rm");
        if target is None {
            return EXIT_USAGE;
        }
        ok = await delete_course(target);
    } except BridgeError as e {
        return explain_bridge_error(e);
    }
    if not ok {
        warn("planner course rm: that course no longer exists");
        return EXIT_FAILURE;
    }
    print("removed " + short_id(target as str));
    return EXIT_OK;
}
