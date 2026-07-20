#!/bin/bash
# Apple Notes CLI Wrapper for AI Agents (v0.2.0)
# Uses only built-in osascript and Notes.app. No external dependencies.

set -e

# Help / Usage info
show_help() {
    echo "Apple Notes Skill CLI (v0.2.0)"
    echo "Usage: $0 <command> [args...]"
    echo ""
    echo "Commands:"
    echo "  create-note <title> <folder> <body_html>   Create a note in a folder (folder created if missing)"
    echo "  create-folder <folder>                     Create a new folder"
    echo "  read-note <title> [folder]                 Read the body of a note (globally or within folder)"
    echo "  append-note <title> <folder> <body_html>   Append HTML content to a note"
    echo "  move-note <title> <from_folder> <to_folder> Move a note between folders"
    echo "  delete-note <title> <folder>               Delete a note from a folder"
    echo "  search-notes <query>                       Search note titles globally (returns folder and title)"
    echo "  list-folders                               List all folders"
    echo "  list-notes <folder>                        List notes in a folder (returns title and modification date)"
    echo "  get-date <title> <folder>                  Get the modification date of a note"
    echo "  count-all                                  Get total count of all notes"
    echo "  count-folder <folder>                      Get note count in a specific folder"
    exit 1
}

if [ -z "$1" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
fi

COMMAND="$1"
shift

# Function to run inline AppleScript passing arguments safely
run_applescript() {
    osascript - "$@"
}

case "$COMMAND" in
    # --- CREATE ---
    create-note)
        if [ "$#" -lt 3 ]; then
            echo "Usage: $0 create-note <title> <folder> <body_html>"
            exit 1
        fi
        run_applescript "$1" "$2" "$3" <<'EOF'
on run argv
    set noteTitle to item 1 of argv
    set folderName to item 2 of argv
    set noteBody to item 3 of argv
    tell application "Notes"
        if not (exists folder folderName) then
            make new folder with properties {name:folderName}
        end if
        set targetFolder to folder folderName
        make new note at targetFolder with properties {name:noteTitle, body:noteBody}
    end tell
end run
EOF
        ;;

    create-folder)
        if [ "$#" -lt 1 ]; then
            echo "Usage: $0 create-folder <folder>"
            exit 1
        fi
        run_applescript "$1" <<'EOF'
on run argv
    set folderName to item 1 of argv
    tell application "Notes"
        if not (exists folder folderName) then
            make new folder with properties {name:folderName}
        end if
    end tell
end run
EOF
        ;;

    # --- READ ---
    read-note)
        if [ "$#" -lt 1 ]; then
            echo "Usage: $0 read-note <title> [folder]"
            exit 1
        fi
        if [ "$#" -eq 1 ]; then
            # Search globally and return the body of the first matching note
            run_applescript "$1" <<'EOF'
on run argv
    set noteTitle to item 1 of argv
    tell application "Notes"
        set noteList to every note whose name is noteTitle
        if (count of noteList) is 0 then
            error "Note '" & noteTitle & "' not found"
        else
            return body of item 1 of noteList
        end if
    end tell
end run
EOF
        else
            # Get note from specific folder
            run_applescript "$1" "$2" <<'EOF'
on run argv
    set noteTitle to item 1 of argv
    set folderName to item 2 of argv
    tell application "Notes"
        if not (exists folder folderName) then
            error "Folder '" & folderName & "' not found"
        end if
        if not (exists note noteTitle of folder folderName) then
            error "Note '" & noteTitle & "' not found in folder '" & folderName & "'"
        end if
        return body of note noteTitle of folder folderName
    end tell
end run
EOF
        fi
        ;;

    # --- UPDATE ---
    append-note)
        if [ "$#" -lt 3 ]; then
            echo "Usage: $0 append-note <title> <folder> <body_html>"
            exit 1
        fi
        run_applescript "$1" "$2" "$3" <<'EOF'
on run argv
    set noteTitle to item 1 of argv
    set folderName to item 2 of argv
    set appendBody to item 3 of argv
    tell application "Notes"
        if not (exists folder folderName) then
            error "Folder '" & folderName & "' not found"
        end if
        if not (exists note noteTitle of folder folderName) then
            error "Note '" & noteTitle & "' not found in folder '" & folderName & "'"
        end if
        set targetNote to note noteTitle of folder folderName
        set currentBody to body of targetNote
        set body of targetNote to currentBody & appendBody
    end tell
end run
EOF
        ;;

    # --- DELETE / MOVE ---
    move-note)
        if [ "$#" -lt 3 ]; then
            echo "Usage: $0 move-note <title> <from_folder> <to_folder>"
            exit 1
        fi
        run_applescript "$1" "$2" "$3" <<'EOF'
on run argv
    set noteTitle to item 1 of argv
    set fromFolder to item 2 of argv
    set toFolder to item 3 of argv
    tell application "Notes"
        if not (exists folder fromFolder) then
            error "Source folder '" & fromFolder & "' not found"
        end if
        if not (exists folder toFolder) then
            error "Destination folder '" & toFolder & "' not found (please create it first)"
        end if
        if not (exists note noteTitle of folder fromFolder) then
            error "Note '" & noteTitle & "' not found in folder '" & fromFolder & "'"
        end if
        move note noteTitle of folder fromFolder to folder toFolder
    end tell
end run
EOF
        ;;

    delete-note)
        if [ "$#" -lt 2 ]; then
            echo "Usage: $0 delete-note <title> <folder>"
            exit 1
        fi
        run_applescript "$1" "$2" <<'EOF'
on run argv
    set noteTitle to item 1 of argv
    set folderName to item 2 of argv
    tell application "Notes"
        if not (exists folder folderName) then
            error "Folder '" & folderName & "' not found"
        end if
        if not (exists note noteTitle of folder folderName) then
            error "Note '" & noteTitle & "' not found in folder '" & folderName & "'"
        end if
        delete note noteTitle of folder folderName
    end tell
end run
EOF
        ;;

    # --- QUERY / INFO ---
    search-notes)
        if [ "$#" -lt 1 ]; then
            echo "Usage: $0 search-notes <query>"
            exit 1
        fi
        run_applescript "$1" <<'EOF'
on run argv
    set queryText to item 1 of argv
    tell application "Notes"
        set noteNames to {}
        set folderList to every folder
        repeat with aFolder in folderList
            set folderName to name of aFolder
            set noteList to (every note of aFolder whose name contains queryText)
            repeat with aNote in noteList
                set end of noteNames to folderName & "\t" & (name of aNote)
            end repeat
        end repeat
        set AppleScript's text item delimiters to linefeed
        return noteNames as string
    end tell
end run
EOF
        ;;

    list-folders)
        run_applescript <<'EOF'
tell application "Notes"
    set folderNames to name of every folder
    set AppleScript's text item delimiters to linefeed
    return folderNames as string
end tell
EOF
        ;;

    list-notes)
        if [ "$#" -lt 1 ]; then
            echo "Usage: $0 list-notes <folder>"
            exit 1
        fi
        run_applescript "$1" <<'EOF'
on run argv
    set folderName to item 1 of argv
    tell application "Notes"
        if not (exists folder folderName) then
            error "Folder '" & folderName & "' not found"
        end if
        set noteList to every note of folder folderName
        set resultList to {}
        repeat with aNote in noteList
            set end of resultList to (name of aNote) & "\t" & ((modification date of aNote) as string)
        end repeat
        set AppleScript's text item delimiters to linefeed
        return resultList as string
    end tell
end run
EOF
        ;;

    get-date)
        if [ "$#" -lt 2 ]; then
            echo "Usage: $0 get-date <title> <folder>"
            exit 1
        fi
        run_applescript "$1" "$2" <<'EOF'
on run argv
    set noteTitle to item 1 of argv
    set folderName to item 2 of argv
    tell application "Notes"
        if not (exists folder folderName) then
            error "Folder '" & folderName & "' not found"
        end if
        if not (exists note noteTitle of folder folderName) then
            error "Note '" & noteTitle & "' not found in folder '" & folderName & "'"
        end if
        return (modification date of note noteTitle of folder folderName) as string
    end tell
end run
EOF
        ;;

    count-all)
        run_applescript <<'EOF'
tell application "Notes"
    return count of notes
end tell
EOF
        ;;

    count-folder)
        if [ "$#" -lt 1 ]; then
            echo "Usage: $0 count-folder <folder>"
            exit 1
        fi
        run_applescript "$1" <<'EOF'
on run argv
    set folderName to item 1 of argv
    tell application "Notes"
        if not (exists folder folderName) then
            error "Folder '" & folderName & "' not found"
        end if
        return count of notes of folder folderName
    end tell
end run
EOF
        ;;

    *)
        echo "Unknown command: $COMMAND"
        show_help
        ;;
esac
