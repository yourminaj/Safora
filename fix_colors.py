import os
import re

def process_dir(directory):
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r') as f:
                    content = f.read()
                
                orig = content
                
                # Careful replacements to handle text colors in dark mode
                content = content.replace('AppColors.textPrimary', '(Theme.of(context).brightness == Brightness.dark ? AppColors.darkOnSurface : AppColors.textPrimary)')
                content = content.replace('AppColors.textSecondary', '(Theme.of(context).brightness == Brightness.dark ? AppColors.textDisabled : AppColors.textSecondary)')
                
                # Also fix the specific getter in alert_card.dart
                if 'alert_card.dart' in filepath:
                    content = content.replace('Color get _confidenceColor {', 'Color _confidenceColor(BuildContext context) {')
                    content = content.replace('color: _confidenceColor,', 'color: _confidenceColor(context),')
                
                if content != orig:
                    # Fix any double insertions if they already had it
                    content = content.replace('isDark ? Colors.white70 : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkOnSurface : AppColors.textPrimary)', 'isDark ? Colors.white70 : AppColors.textPrimary')
                    content = content.replace('isDark ? AppColors.darkOnSurface : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkOnSurface : AppColors.textPrimary)', '(Theme.of(context).brightness == Brightness.dark ? AppColors.darkOnSurface : AppColors.textPrimary)')
                    
                    with open(filepath, 'w') as f:
                        f.write(content)
                    print(f"Fixed {filepath}")

process_dir('lib')
