# Ralph Commands

To watch:

while :; do cat PROMPT.md | claude --dangerously-skip-permissions ; done

To let it run by itself:

while :; do cat PROMPT.md | claude --dangerously-skip-permissions -p - ; done
