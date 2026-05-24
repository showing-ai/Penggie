# Regression Checklist

Run these after porting to Penggie.

Composer/native interaction:
- Empty composer `/` opens native slash overlay immediately.
- Empty composer `$` opens native dollar overlay only for Codex sessions.
- ` /model` remains ordinary chat input.
- `hello /model` remains ordinary chat input.
- `/m` filters native overlay to `/model`, `/memories`, `/mention`, `/mcp` as rendered by Codex CLI.
- `/mo` keeps the same native state and shows relevant Codex-rendered suggestions.
- Arrow up/down moves selection immediately, no beep.
- Enter on `/model` opens model selection.
- Model selection supports arrow up/down immediately.
- Esc exits native interaction.
- Backspace from `/m` to `/` keeps slash menu.
- Backspace from `/` to empty exits native interaction.

IME/composer:
- Chinese IME marked text hides placeholder immediately.
- Candidate selection does not duplicate text.
- Esc during IME composition does not enter slash/native state accidentally.
- Ordinary Chinese message submits as chat input.

Mode switching:
- Raw Terminal shows the same underlying PTY state.
- Switching to Raw Terminal during native interaction has an explicitly defined behavior.
- Returning to Reading does not corrupt PTY input.

Output:
- Ordinary submitted message appears as user input block.
- Agent output is preserved in Reading blocks.
- Tool/status/menu-like terminal rows do not hide real answer content.
