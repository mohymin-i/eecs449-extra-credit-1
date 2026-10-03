import from "@jac/mobui" { StyleSheet }

obj Colors {
    has bg: str = "#0f1115",
        surface: str = "#171a21",
        border: str = "#22262f",
        text: str = "#e6e9ef",
        muted: str = "#8a93a6",
        accent: str = "#7c5cff",
        danger: str = "#f4544e",
        high: str = "#f4a0a0",
        medium: str = "#e3c56a",
        low: str = "#7fd6a4";
}

obj Spacing {
    has xs: int = 4, sm: int = 8, md: int = 12, lg: int = 16, xl: int = 20;
}

obj Radii {
    has sm: int = 8, md: int = 12, lg: int = 16, pill: int = 999;
}

glob:pub C = Colors(), S = Spacing(), R = Radii();

glob:pub styles = StyleSheet.create({
    "screen": {"flex": 1, "backgroundColor": C.bg},
    "scrollBody": {"padding": S.lg, "gap": S.md, "paddingBottom": 100},
    "title": {"color": C.text, "fontSize": 26, "fontWeight": "bold", "marginBottom": S.sm},
    "sectionTitle": {"color": C.muted, "fontSize": 14, "marginTop": S.md, "marginBottom": S.xs},
    "muted": {"color": C.muted, "fontSize": 14},
    "error": {"color": C.danger, "fontSize": 14, "marginBottom": S.sm},
    "card": {
        "backgroundColor": C.surface,
        "borderRadius": R.md,
        "borderWidth": 1,
        "borderColor": C.border,
        "padding": S.md,
        "marginBottom": S.sm
    },
    "row": {"flexDirection": "row", "alignItems": "center", "gap": S.md},
    "rowBetween": {
        "flexDirection": "row",
        "alignItems": "center",
        "justifyContent": "space-between",
        "gap": S.sm
    },
    "grow": {"flex": 1},
    "taskTitle": {"color": C.text, "fontSize": 15},
    "taskTitleDone": {"color": C.muted, "fontSize": 15, "textDecorationLine": "line-through"},
    "taskMeta": {"color": C.muted, "fontSize": 12, "marginTop": 2},
    "input": {
        "backgroundColor": C.bg,
        "borderWidth": 1,
        "borderColor": C.border,
        "borderRadius": R.sm,
        "color": C.text,
        "paddingVertical": S.sm,
        "paddingHorizontal": S.md,
        "fontSize": 14
    },
    "badge": {
        "paddingVertical": 4,
        "paddingHorizontal": S.sm,
        "borderRadius": R.pill,
        "backgroundColor": C.border
    },
    "badgeText": {"color": C.muted, "fontSize": 11, "fontWeight": "bold"},
    "button": {
        "backgroundColor": C.accent,
        "borderRadius": R.sm,
        "paddingVertical": S.sm,
        "paddingHorizontal": S.lg,
        "alignItems": "center"
    },
    "buttonText": {"color": "#ffffff", "fontSize": 14, "fontWeight": "bold"},
    "deleteButton": {
        "backgroundColor": "#2a1518",
        "borderRadius": R.sm,
        "paddingVertical": 6,
        "paddingHorizontal": S.sm
    },
    "deleteButtonText": {"color": C.danger, "fontSize": 12},
    "tabBar": {
        "flexDirection": "row",
        "borderTopWidth": 1,
        "borderColor": C.border,
        "backgroundColor": C.surface,
        "paddingVertical": S.sm
    },
    "tab": {"flex": 1, "alignItems": "center", "paddingVertical": S.xs},
    "tabText": {"color": C.muted, "fontSize": 12},
    "tabTextActive": {"color": C.accent, "fontSize": 12, "fontWeight": "bold"},
    "checkbox": {
        "width": 24,
        "height": 24,
        "borderRadius": R.sm,
        "borderWidth": 2,
        "borderColor": C.accent,
        "alignItems": "center",
        "justifyContent": "center"
    },
    "checkboxOn": {"backgroundColor": C.accent}
});
