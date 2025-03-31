# ✨ Backlog Manager Excel ✨

[![Code Coverage](https://img.shields.io/codecov/c/github/0Vipin0/backlog_helper)](https://codecov.io/gh/0Vipin0/backlog_helper)
[![Dart Version](https://img.shields.io/badge/Dart-%3E%3D3.0.0-blue.svg)](https://dart.dev)
[![Style Guide: Effective Dart](https://img.shields.io/badge/style-effective_dart-40c4ff.svg)](https://dart.dev/guides/language/effective-dart)

Manage your project backlogs, goals, plans, and obstacles directly within an Excel spreadsheet using a simple and efficient command-line interface (or integrate as a Dart library). Keep your project data structured, accessible, and easily shareable without needing complex databases or external tools.

---

## 🚀 Key Features

*   **Excel Backend:** Uses a standard `.xlsx` file as the data store – easy to view, share, and manually edit if needed.
*   **Structured Data:** Manages distinct project item types:
    *   **Tasks:** Actionable items with priority, status, due dates, etc.
    *   **Goals:** Strategic objectives with targets, KPIs, and status.
    *   **Plans:** Tactical or operational plans linking goals and tasks.
    *   **Obstacles:** Potential risks or blockers with likelihood, impact, and mitigation.
*   **CRUD Operations:** Provides functionality to Add, List, Update, and potentially Delete items (via `ExcelService`).
*   **Command-Line Interface (Implied):** Designed for easy interaction from your terminal (requires CLI implementation using `ExcelService`).
*   **Data Validation:** Enforces types and required fields (like IDs, titles, priorities) during creation/update.
*   **UUID Identifiers:** Automatically assigns unique IDs to new items.
*   **Timestamps:** Automatically tracks `createdAt` and `updatedAt` timestamps for all items.
*   **Cross-Platform:** Runs anywhere the Dart SDK is available (Windows, macOS, Linux).
*   **Extensible:** Base `ExcelStorable` class allows for adding new types of items easily.

## 🔧 Installation

### Prerequisites

*   [Dart SDK](https://dart.dev/get-dart) version 3.0.0 or higher.


### Run Application

Clone the repository:

git clone https://github.com/0Vipin0/backlog_helper.git

Install dependencies:

dart pub get

Run using dart run:

### Example (replace with your actual entry point)
dart run bin/backlog_manager.dart <command> [options]

💻 Usage (Command-Line Examples)

(Note: These are illustrative examples. Replace <command>, <type>, and options with your actual implementation based on how you build your command-line argument parser (e.g., using package:args).)

```bash
# General structure (example)
backlog_manager <command> <type> [options]

# --- Listing Items ---
# List all tasks
backlog_manager list tasks

# List all goals
backlog_manager list goals

# --- Adding Items ---
# Add a new high-priority task
backlog_manager add task --taskTitle "Implement user authentication" --priority high --description "Use JWT for auth"

# Add a new strategic goal
backlog_manager add goal --goalDescription "Increase Q4 revenue by 15%" --targetCompletionDate 2024-12-31 --priority high --typeOfPlan strategic

# --- Updating Items ---
# Update the status of a task
backlog_manager update task --id "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" --status inProgress

# Change the priority of a goal
backlog_manager update goal --id "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy" --priority medium

# --- Showing Item Details (Example) ---
# Show details for a specific task
backlog_manager show task --id "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# --- Other Potential Commands ---
# backlog_manager delete task --id "zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz"
# backlog_manager find tasks --priority high --status toDo
```

📊 Data Model & Excel Structure

The application stores data in an Excel file (default: backlog_data.xlsx in the execution directory). The file contains separate sheets for each item type, with specific headers.

Default Filename: backlog_data.xlsx (can be overridden via ExcelService constructor)

Sheets and Headers:

Sheet: BacklogTasks

Headers: ID, Task Title, Description, Priority, Estimated Effort, Status, Due Date, Tags/Categories, Dependencies, Reasoning, Resolution, CreatedAt, UpdatedAt

Sheet: FutureGoals

Headers: ID, Goal Title, Target Completion Date, Priority, KPIs, Resources Required, Current Status, Motivation, First Step, Potential Challenges, Support Contacts, CreatedAt, UpdatedAt

Sheet: PlanningItems

Headers: ID, Plan Title, Type of Plan, Start Date, End Date, Dependencies, Progress, Status, Related Goal, Key Milestones, Allocated Resources, CreatedAt, UpdatedAt

Sheet: Obstacles

Headers: ID, Obstacle Title, Likelihood of Occurrence, Potential Impact, Mitigation Strategies, Contingency Plans, Category, Status, Related Item, Assigned To, Date Identified, CreatedAt, UpdatedAt

(These headers are defined in lib/constants/excel_constants.dart)

##⚙️ Configuration

The primary configuration is the path to the Excel data file. By default, it looks for backlog_data.xlsx in the current working directory.

You can specify a different path when creating the ExcelService instance if using it as a library, or potentially via a command-line argument or environment variable in your CLI application.

🤝 Contributing

Contributions are welcome! Please follow these steps:

Fork the repository on GitHub.

Create a new branch for your feature or bug fix (git checkout -b feature/my-new-feature or git checkout -b fix/issue-123).

Make your changes, adhering to the Effective Dart style guide.

Add tests for your changes. Ensure all tests pass (dart test).

Commit your changes (git commit -m 'Add some feature').

Push to your branch (git push origin feature/my-new-feature).

Create a Pull Request on GitHub.

Please provide a clear description of your changes in the pull request.

📜 License

This project is licensed under the MIT License. See the LICENSE file for details.
