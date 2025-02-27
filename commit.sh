#!/bin/bash

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <TaskID> <Commit Message> [-p] [-r <repo>]"
    exit 1
fi

EXCEL_FILE="tasks.xlsx"
CSV_FILE="tasks.csv"
REPO_DIR="./"
PUSH_FLAG="n"

TASK_ID="$1"
COMMIT_NOTE="$2"
shift 2  

while [[ -n "$1" ]]; do
    case "$1" in
        -p) PUSH_FLAG="y"; shift ;;
        -r) REPO_DIR="$2"; shift 2 ;;
        *) echo "Error: Unknown option '$1'"; exit 1 ;;
    esac
done

if [[ ! -f "$EXCEL_FILE" ]]; then
    echo "Error: Can't find '$EXCEL_FILE'."
    exit 1
fi

if [[ -z "$REPO_DIR" ]]; then
    echo "Error: Missing repository path."
    exit 1
fi

xlsx2csv "$EXCEL_FILE" "$CSV_FILE"

TASK_DESC=$(grep "^${TASK_ID}," "$CSV_FILE" | cut -d',' -f2)
[[ -z "$TASK_DESC" ]] && echo "Error: Task ID '$TASK_ID' not found." && exit 1

BRANCH=$(grep "^${TASK_ID}," "$CSV_FILE" | cut -d',' -f3)
ACTIVE_BRANCH=$(git branch --show-current)

if [[ "$ACTIVE_BRANCH" != "$BRANCH" ]]; then
    echo "Error: Expected branch '$BRANCH', but currently on '$ACTIVE_BRANCH'."
    exit 1
fi

DEV_NAME=$(grep "^${TASK_ID}," "$CSV_FILE" | cut -d',' -f4)
[[ -z "$DEV_NAME" ]] && echo "Error: Developer name not found for task '$TASK_ID'." && exit 1

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
COMMIT_MSG="$TASK_ID - $TIMESTAMP - $BRANCH - $DEV_NAME - $TASK_DESC - $COMMIT_NOTE"

CUR_DIR=$(pwd)
cd "$REPO_DIR" || { echo "Error: Failed to access '$REPO_DIR'"; exit 1; }

git add .
git commit -m "$COMMIT_MSG"
[[ "$PUSH_FLAG" == "y" ]] && git push

cd "$CUR_DIR"

echo "Commit completed successfully!"
