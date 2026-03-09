# QUICK FIX: Add Missing Import to games_hub_card.dart

## Error
```
The name 'DifficultySelectionDialog' isn't a class.
```

## Solution

Open `lib/widgets/games_hub_card.dart`

Find the line with:
```dart
import 'package:gravity_app/widgets/locked_games_view.dart';
```

Add immediately after it:
```dart
import 'package:gravity_app/widgets/difficulty_selection_dialog.dart';
```

## Result
The file should have both imports:
```dart
import 'package:gravity_app/widgets/locked_games_view.dart';
import 'package:gravity_app/widgets/difficulty_selection_dialog.dart';
```

This will fix the DifficultySelectionDialog error.
