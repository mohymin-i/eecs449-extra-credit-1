import sys;
import from jaclang.server.bridge {
    BridgeError,
    BridgeRejected,
    BridgeTimeout,
    BridgeUnavailable
}

glob EXIT_OK: int = 0,
     EXIT_FAILURE: int = 1,
     EXIT_USAGE: int = 2,
     EXIT_UNAVAILABLE: int = 3,
     EXIT_TIMEOUT: int = 4,
     EXIT_REJECTED: int = 5;

glob START_HINT: str = "hint: start the planner with `jac run` (serves the web app + backend at :8000)";

def warn(text: str) {
    print(text, file=sys.stderr);
}

def short_id(full_id: str) -> str {
    return full_id[:8];
}

def resolve_id(prefix: str, ids: list[str], label: str) -> str | None {
    if not prefix {
        warn(f"{label}: an id is required");
        return None;
    }
    needle = prefix.strip().lower();
    matches = [i for i in ids if i.lower().startswith(needle)];
    if not matches {
        warn(f"{label}: no match for '{prefix}'");
        return None;
    }
    if len(matches) > 1 {
        warn(f"{label}: '{prefix}' is ambiguous ({len(matches)} matches) - use more characters");
        return None;
    }
    return matches[0];
}

def _suffix(detail: str) -> str {
    return " (" + detail + ")" if detail else "";
}

def explain_bridge_error(e: BridgeError) -> int {
    where = e.app + "." + e.name;
    if isinstance(e, BridgeUnavailable) {
        warn("planner: " + where + " is not reachable" + _suffix(e.detail));
        warn(START_HINT);
        return EXIT_UNAVAILABLE;
    }
    if isinstance(e, BridgeTimeout) {
        warn("planner: " + where + " timed out" + _suffix(e.detail));
        return EXIT_TIMEOUT;
    }
    if isinstance(e, BridgeRejected) {
        warn("planner: " + where + " rejected the call" + _suffix(e.detail));
        return EXIT_REJECTED;
    }
    warn("planner: " + where + " failed" + _suffix(e.detail));
    return EXIT_FAILURE;
}
