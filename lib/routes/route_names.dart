/// Route names for the application
/// All route names are defined as constants for type-safety and easy refactoring
class RouteNames {
  // Root
  static const String root = '/';

  // Meal Planner Routes (Schd: Thành viên 2)
  static const String mealPlanner = '/meal-planner';
  static const String calendarScreen = '/meal-planner/calendar';
  static const String mealDetailsScreen = '/meal-planner/meal-details';

  // Pantry Routes (Scheduled: Thành viên 1)
  static const String pantry = '/pantry';
  static const String pantryScreen = '/pantry/pantry-screen';
  static const String addItemScreen = '/pantry/add-item';
  static const String receiptScannerScreen = '/pantry/receipt-scanner';

  // Recipes Routes (Scheduled: Thành viên 2)
  static const String recipes = '/recipes';
  static const String recipesListScreen = '/recipes/list';
  static const String recipeDetailsScreen = '/recipes/details';

  // Shopping List Routes (Scheduled: Thành viên 2)
  static const String shoppingList = '/shopping-list';
  static const String shoppingListScreen = '/shopping-list/list';
  static const String shoppingItemDetailsScreen = '/shopping-list/item-details';
}
