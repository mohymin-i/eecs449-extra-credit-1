import argparse;
import asyncio;
import sys;

import from cli.commands.common { warn, EXIT_OK, EXIT_USAGE }
import from cli.commands.tasks { run_today, run_add, run_list, run_done, run_rm, run_breakdown }
import from cli.commands.courses { run_courses, run_course_add, run_course_rm }
import from cli.commands.habits { run_habits, run_habit_add, run_habit_done, run_habit_rm }

glob PROG: str = "planner";

obj Invocation {
    has command: str = "",
        course_action: str = "",
        habit_action: str = "",
        title: str = "",
        name: str = "",
        notes: str = "",
        due_date: str = "",
        due_time: str = "",
        priority: str = "medium",
        course_name: str = "",
        color: str = "#7c5cff",
        target_per_week: int = 7,
        show_all: bool = False,
        item_id: str = "";
}

def build_parser -> argparse.ArgumentParser {
    parser = argparse.ArgumentParser(
        prog=PROG,
        description="A personal planner for coursework, schedules, and habits - talks to a running `jac run` server."
    );
    commands = parser.add_subparsers(dest="command", metavar="<command>", required=True);

    commands.add_parser("today", help="show overdue, due-today, and upcoming tasks plus today's habits");

    add_p = commands.add_parser("add", help="add a task");
    add_p.add_argument("title");
    add_p.add_argument("--date", dest="due_date", `default="", help="due date, YYYY-MM-DD");
    add_p.add_argument("--time", dest="due_time", `default="", help="due time, HH:MM");
    add_p.add_argument("--priority", choices=["low", "medium", "high"], `default="medium");
    add_p.add_argument("--notes", `default="");
    add_p.add_argument("--course", dest="course_name", `default="", help="link to an existing course by name");

    list_p = commands.add_parser("list", help="list tasks");
    list_p.add_argument("--course", dest="course_name", `default="");
    list_p.add_argument("--all", dest="show_all", action="store_true", help="include completed tasks");

    done_p = commands.add_parser("done", help="toggle a task complete/incomplete");
    done_p.add_argument("id", help="task id or id prefix, from `planner list`");

    rm_p = commands.add_parser("rm", help="delete a task");
    rm_p.add_argument("id");

    breakdown_p = commands.add_parser("breakdown", help="ask AI to break a task into subtasks");
    breakdown_p.add_argument("id");

    commands.add_parser("courses", help="list courses");

    course_p = commands.add_parser("course", help="manage courses");
    course_sub = course_p.add_subparsers(dest="course_action", metavar="<action>", required=True);
    course_add_p = course_sub.add_parser("add");
    course_add_p.add_argument("name");
    course_add_p.add_argument("--color", `default="#7c5cff");
    course_rm_p = course_sub.add_parser("rm");
    course_rm_p.add_argument("id");

    commands.add_parser("habits", help="list habits");

    habit_p = commands.add_parser("habit", help="manage habits");
    habit_sub = habit_p.add_subparsers(dest="habit_action", metavar="<action>", required=True);
    habit_add_p = habit_sub.add_parser("add");
    habit_add_p.add_argument("name");
    habit_add_p.add_argument("--target", dest="target_per_week", `type=int, `default=7, help="days per week, 1-7");
    habit_done_p = habit_sub.add_parser("done");
    habit_done_p.add_argument("id");
    habit_rm_p = habit_sub.add_parser("rm");
    habit_rm_p.add_argument("id");

    return parser;
}

def parse_args(argv: list[str]) -> Invocation {
    parser = build_parser();
    ns = parser.parse_args(argv);
    return Invocation(
        command=str(getattr(ns, "command", "") or ""),
        course_action=str(getattr(ns, "course_action", "") or ""),
        habit_action=str(getattr(ns, "habit_action", "") or ""),
        title=str(getattr(ns, "title", "") or ""),
        name=str(getattr(ns, "name", "") or ""),
        notes=str(getattr(ns, "notes", "") or ""),
        due_date=str(getattr(ns, "due_date", "") or ""),
        due_time=str(getattr(ns, "due_time", "") or ""),
        priority=str(getattr(ns, "priority", "medium") or "medium"),
        course_name=str(getattr(ns, "course_name", "") or ""),
        color=str(getattr(ns, "color", "#7c5cff") or "#7c5cff"),
        target_per_week=int(getattr(ns, "target_per_week", 7) or 7),
        show_all=bool(getattr(ns, "show_all", False)),
        item_id=str(getattr(ns, "id", "") or "")
    );
}

async def dispatch(inv: Invocation) -> int {
    if inv.command == "today" {
        return await run_today();
    }
    if inv.command == "add" {
        return await run_add(inv.title, inv.notes, inv.due_date, inv.due_time, inv.priority, inv.course_name);
    }
    if inv.command == "list" {
        return await run_list(inv.course_name, inv.show_all);
    }
    if inv.command == "done" {
        return await run_done(inv.item_id);
    }
    if inv.command == "rm" {
        return await run_rm(inv.item_id);
    }
    if inv.command == "breakdown" {
        return await run_breakdown(inv.item_id);
    }
    if inv.command == "courses" {
        return await run_courses();
    }
    if inv.command == "course" {
        if inv.course_action == "add" {
            return await run_course_add(inv.name, inv.color);
        }
        if inv.course_action == "rm" {
            return await run_course_rm(inv.item_id);
        }
    }
    if inv.command == "habits" {
        return await run_habits();
    }
    if inv.command == "habit" {
        if inv.habit_action == "add" {
            return await run_habit_add(inv.name, inv.target_per_week);
        }
        if inv.habit_action == "done" {
            return await run_habit_done(inv.item_id);
        }
        if inv.habit_action == "rm" {
            return await run_habit_rm(inv.item_id);
        }
    }
    warn("planner: unknown command " + inv.command);
    return EXIT_USAGE;
}

async def main(argv: list[str]) -> int {
    return await dispatch(parse_args(argv));
}

with entry:__main__ {
    sys.exit(asyncio.run(main(sys.argv[1:])));
}
