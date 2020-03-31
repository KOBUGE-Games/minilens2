extends Node

enum GoalType {
	BARREL
	FLOWER
}

var goals_left = {} # Object => GoalType
var goal_counts = {} # GoalType => int

func add_goal(goal: Object, type: int, pass_on_exit_tree: bool = true) -> void:
	if goals_left.has(goal):
		goal_counts[goals_left[goal]] -= 1
	
	goals_left[goal] = type
	
	goal_counts[type] = goal_counts.get(type, 0) + 1
	
	if pass_on_exit_tree:
		goal.connect("tree_exited", self, "remove_goal", [goal])

func remove_goal(goal: Object) -> void:
	if goals_left.has(goal):
		goal_counts[goals_left[goal]] -= 1
	
	goals_left.erase(goal)
	
	if goal.is_connected("tree_exited", self, "remove_goal"):
		goal.disconnect("tree_exited", self, "remove_goal")

func get_goal_count_left(type: int) -> int:
	return goal_counts.get(type, 0)

func get_total_goals_left() -> int:
	var total = 0
	for count in goal_counts.values():
		total += count
	return total
