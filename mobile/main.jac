import from "@jac/mobui" { View, Text, Pressable }
import from .theme { styles, C }
import from .screens.today { TodayScreen }
import from .screens.tasks { TasksScreen }
import from .screens.habits { HabitsScreen }

def:pub app -> JsxElement {
    has screen: str = "today";

    <View style={styles.screen}>
        <View style={{"flex": 1}}>
            {
                (<TodayScreen/>) if screen == "today" else
                (<TasksScreen/>) if screen == "tasks" else
                <HabitsScreen/>
            }
        </View>
        <View style={styles.tabBar}>
            <Pressable style={styles.tab} onPress={lambda { screen = "today"; }}>
                <Text style={styles.tabTextActive if screen == "today" else styles.tabText}>Today</Text>
            </Pressable>
            <Pressable style={styles.tab} onPress={lambda { screen = "tasks"; }}>
                <Text style={styles.tabTextActive if screen == "tasks" else styles.tabText}>Tasks</Text>
            </Pressable>
            <Pressable style={styles.tab} onPress={lambda { screen = "habits"; }}>
                <Text style={styles.tabTextActive if screen == "habits" else styles.tabText}>Habits</Text>
            </Pressable>
        </View>
    </View>
}
