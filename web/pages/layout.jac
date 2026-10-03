import from "@jac/runtime" { Link, Outlet, useLocation }

def:pub Shell -> JsxLayout {
    loc = useLocation();

    <div className="shell">
        <header className="topbar">
            <div className="brand">Campus Planner</div>
            <nav className="nav">
                <Link to="/" className={"navlink active" if loc.pathname == "/" else "navlink"}>Today</Link>
                <Link to="/tasks" className={"navlink active" if loc.pathname == "/tasks" else "navlink"}>Tasks</Link>
                <Link to="/courses" className={"navlink active" if loc.pathname == "/courses" else "navlink"}>Courses</Link>
                <Link to="/habits" className={"navlink active" if loc.pathname == "/habits" else "navlink"}>Habits</Link>
            </nav>
        </header>
        <main className="content">
            <Outlet />
        </main>
    </div>
}
