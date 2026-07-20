#!/bin/bash
# Apple Notes CLI Wrapper for AI Agents (v0.3.1)
# Uses only built-in osascript JXA (JavaScript for Automation) and Notes.app.

set -euo pipefail

# Global variables
CONFIRM=0
JSON_MODE=0
IF_MODIFIED_AT=""
ARGS=()

# Parse global flags and handle -- separator
while [ "$#" -gt 0 ]; do
    case "$1" in
        --json)
            JSON_MODE=1
            shift
            ;;
        --confirm)
            CONFIRM=1
            shift
            ;;
        --if-modified-at)
            if [ "$#" -lt 2 ]; then
                echo "Error: --if-modified-at requires a timestamp value" >&2
                exit 2
            fi
            IF_MODIFIED_AT="$2"
            shift 2
            ;;
        --)
            shift
            while [ "$#" -gt 0 ]; do
                ARGS+=("$1")
                shift
            done
            break
            ;;
        -*)
            echo "Error: Unknown option $1" >&2
            exit 2
            ;;
        *)
            ARGS+=("$1")
            shift
            ;;
    esac
done

show_help() {
    echo "Apple Notes Skill CLI (v0.3.1)"
    echo "Usage: $0 [options] <command> [args...]"
    echo ""
    echo "Options:"
    echo "  --json                       Output machine-readable JSON"
    echo "  --confirm                    Acknowledge and proceed with destructive actions"
    echo "  --if-modified-at <timestamp> Guard updates with optimistic concurrency check"
    echo "  --                           Stop parsing options (useful if inputs start with dashes)"
    echo ""
    echo "Create Commands:"
    echo "  create-note-text <title> <folder> <plain_text>"
    echo "  create-note-html <title> <folder> <body_html>"
    echo "  create-folder <folder>"
    echo ""
    echo "Read Commands:"
    echo "  read-note-id <note_id>"
    echo "  read-note-title <title> [folder]"
    echo ""
    echo "Update Commands:"
    echo "  append-note-text <note_id> <plain_text>"
    echo "  append-note-html <note_id> <body_html>"
    echo ""
    echo "Delete / Move Commands (require --confirm):"
    echo "  move-note-id <note_id> <destination_folder>"
    echo "  move-note-title <title> <from_folder> <to_folder>"
    echo "  delete-note-id <note_id>"
    echo "  delete-note-title <title> <folder>"
    echo "  delete-folder <folder>"
    echo ""
    echo "Query / Utility Commands:"
    echo "  search-notes <query>"
    echo "  list-folders"
    echo "  list-notes <folder>"
    echo "  get-date-id <note_id>"
    echo "  get-date-title <title> <folder>"
    echo "  count-all"
    echo "  count-folder <folder>"
    exit 2
}

if [ ${#ARGS[@]} -eq 0 ] || [ "${ARGS[0]}" = "-h" ] || [ "${ARGS[0]}" = "--help" ]; then
    show_help
fi

# Function containing the JXA heredoc to prevent shell quoting bugs inside command substitutions
run_jxa() {
    env CONFIRM="$CONFIRM" JSON_MODE="$JSON_MODE" IF_MODIFIED_AT="$IF_MODIFIED_AT" osascript -l JavaScript - "${ARGS[@]}" <<'EOF'
ObjC.import('stdlib');

const confirmMode = $.getenv('CONFIRM') === '1';
const jsonMode = $.getenv('JSON_MODE') === '1';
const expectedModifiedAt = $.getenv('IF_MODIFIED_AT') || "";

const Notes = Application('Notes');
Notes.includeStandardAdditions = true;

function escapeHTML(text) {
    return text.replace(/&/g, "&amp;")
               .replace(/</g, "&lt;")
               .replace(/>/g, "&gt;")
               .replace(/"/g, "&quot;")
               .replace(/'/g, "&#039;");
}

function successPayload(data) {
    if (jsonMode) {
        return "JSON_SUCCESS:" + JSON.stringify({ ok: true, data: data });
    } else {
        return "TEXT_SUCCESS:" + (typeof data === 'string' ? data : JSON.stringify(data));
    }
}

function errorPayload(code, message, details) {
    if (jsonMode) {
        return "JSON_ERROR:" + code + ":" + JSON.stringify({
            ok: false,
            error: {
                code: code,
                message: message,
                details: details || null
            }
        });
    } else {
        return "TEXT_ERROR:" + code + ":" + message + (details ? "\nDETAILS: " + JSON.stringify(details) : "");
    }
}

function resolveNote(title, folderName) {
    const result = [];
    const folders = folderName ? Notes.folders.whose({ name: folderName }) : Notes.folders();
    if (folderName && folders.length === 0) {
        throw { code: 3, message: "Folder '" + folderName + "' not found" };
    }
    for (let f = 0; f < folders.length; f++) {
        const folder = folders[f];
        const fName = folder.name();
        const notes = folder.notes();
        for (let n = 0; n < notes.length; n++) {
            if (notes[n].name() === title) {
                result.push({
                    note: notes[n],
                    id: notes[n].id(),
                    title: notes[n].name(),
                    folder: fName,
                    modified_at: notes[n].modificationDate().toISOString()
                });
            }
        }
    }
    if (result.length === 0) {
        throw { code: 3, message: "Note '" + title + "'" + (folderName ? " in folder '" + folderName + "'" : "") + " not found" };
    }
    if (result.length > 1) {
        const candidates = result.map(r => ({ id: r.id, title: r.title, folder: r.folder, modified_at: r.modified_at }));
        throw { code: 4, message: "Multiple notes match. Please use an ID-based command.", data: candidates };
    }
    return result[0].note;
}

function enforceConfirm(targetType, targetName, targetDetails) {
    if (!confirmMode) {
        throw {
            code: 5,
            message: "Confirmation required",
            data: {
                action: targetType,
                name: targetName,
                details: targetDetails
            }
        };
    }
}

function run(argv) {
    try {
        const cmd = argv[0];
        
        if (cmd === "create-note-text") {
            const title = argv[1];
            const folderName = argv[2];
            const plainText = argv[3];
            if (!title || !folderName || plainText === undefined) throw { code: 2, message: "Usage: create-note-text <title> <folder> <plain_text>" };
            
            const folders = Notes.folders.whose({ name: folderName });
            if (folders.length > 1) {
                throw { code: 4, message: "Multiple folders found with the name '" + folderName + "'. Operation aborted to prevent ambiguous location." };
            }
            let folder;
            if (folders.length === 0) {
                folder = Notes.Folder({ name: folderName });
                Notes.folders.push(folder);
            } else {
                folder = folders[0];
            }
            const bodyHTML = "<div>" + escapeHTML(plainText).replace(/\n/g, "<br></div><div>") + "</div>";
            const note = Notes.Note({ name: title, body: bodyHTML });
            folder.notes.push(note);
            
            const meta = { id: note.id(), title: note.name(), folder: folderName, modified_at: note.modificationDate().toISOString() };
            return successPayload(meta);
        }
        else if (cmd === "create-note-html") {
            const title = argv[1];
            const folderName = argv[2];
            const htmlContent = argv[3];
            if (!title || !folderName || htmlContent === undefined) throw { code: 2, message: "Usage: create-note-html <title> <folder> <body_html>" };
            
            const folders = Notes.folders.whose({ name: folderName });
            if (folders.length > 1) {
                throw { code: 4, message: "Multiple folders found with the name '" + folderName + "'. Operation aborted to prevent ambiguous location." };
            }
            let folder;
            if (folders.length === 0) {
                folder = Notes.Folder({ name: folderName });
                Notes.folders.push(folder);
            } else {
                folder = folders[0];
            }
            const note = Notes.Note({ name: title, body: htmlContent });
            folder.notes.push(note);
            
            const meta = { id: note.id(), title: note.name(), folder: folderName, modified_at: note.modificationDate().toISOString() };
            return successPayload(meta);
        }
        else if (cmd === "create-folder") {
            const folderName = argv[1];
            if (!folderName) throw { code: 2, message: "Usage: create-folder <folder>" };
            
            const folders = Notes.folders.whose({ name: folderName });
            if (folders.length > 0) {
                return successPayload({ already_exists: true, folder: folderName });
            }
            const folder = Notes.Folder({ name: folderName });
            Notes.folders.push(folder);
            return successPayload({ already_exists: false, folder: folderName });
        }
        else if (cmd === "read-note-id") {
            const noteId = argv[1];
            if (!noteId) throw { code: 2, message: "Usage: read-note-id <note_id>" };
            
            let note;
            try {
                note = Notes.notes.byId(noteId);
                note.name();
            } catch (e) {
                throw { code: 3, message: "Note with ID '" + noteId + "' not found" };
            }
            const folder = note.container();
            return successPayload({
                id: note.id(),
                title: note.name(),
                folder: folder.name(),
                modified_at: note.modificationDate().toISOString(),
                body: note.body()
            });
        }
        else if (cmd === "read-note-title") {
            const title = argv[1];
            const folderName = argv[2];
            if (!title) throw { code: 2, message: "Usage: read-note-title <title> [folder]" };
            
            const note = resolveNote(title, folderName);
            const folder = note.container();
            return successPayload({
                id: note.id(),
                title: note.name(),
                folder: folder.name(),
                modified_at: note.modificationDate().toISOString(),
                body: note.body()
            });
        }
        else if (cmd === "append-note-text") {
            const noteId = argv[1];
            const plainText = argv[2];
            if (!noteId || plainText === undefined) throw { code: 2, message: "Usage: append-note-text <note_id> <plain_text>" };
            
            let note;
            try {
                note = Notes.notes.byId(noteId);
                note.name();
            } catch (e) {
                throw { code: 3, message: "Note with ID '" + noteId + "' not found" };
            }
            
            const lastModified = note.modificationDate().toISOString();
            if (expectedModifiedAt && lastModified !== expectedModifiedAt) {
                throw { code: 7, message: "Optimistic concurrency check failed. Note was modified since read.", data: { current_modified_at: lastModified, expected_modified_at: expectedModifiedAt } };
            }
            
            const currentBody = note.body();
            const escapedText = "<div>" + escapeHTML(plainText).replace(/\n/g, "<br></div><div>") + "</div>";
            note.body = currentBody + escapedText;
            
            return successPayload({ success: true, id: noteId, modified_at: note.modificationDate().toISOString() });
        }
        else if (cmd === "append-note-html") {
            const noteId = argv[1];
            const htmlContent = argv[2];
            if (!noteId || htmlContent === undefined) throw { code: 2, message: "Usage: append-note-html <note_id> <body_html>" };
            
            let note;
            try {
                note = Notes.notes.byId(noteId);
                note.name();
            } catch (e) {
                throw { code: 3, message: "Note with ID '" + noteId + "' not found" };
            }
            
            const lastModified = note.modificationDate().toISOString();
            if (expectedModifiedAt && lastModified !== expectedModifiedAt) {
                throw { code: 7, message: "Optimistic concurrency check failed. Note was modified since read.", data: { current_modified_at: lastModified, expected_modified_at: expectedModifiedAt } };
            }
            
            const currentBody = note.body();
            note.body = currentBody + htmlContent;
            
            return successPayload({ success: true, id: noteId, modified_at: note.modificationDate().toISOString() });
        }
        else if (cmd === "move-note-id") {
            const noteId = argv[1];
            const destFolder = argv[2];
            if (!noteId || !destFolder) throw { code: 2, message: "Usage: move-note-id <note_id> <destination_folder>" };
            
            let note;
            try {
                note = Notes.notes.byId(noteId);
                note.name();
            } catch (e) {
                throw { code: 3, message: "Note with ID '" + noteId + "' not found" };
            }
            const sourceFolder = note.container().name();
            
            enforceConfirm("Move Note", note.name(), { id: noteId, from_folder: sourceFolder, to_folder: destFolder });
            
            const destFolders = Notes.folders.whose({ name: destFolder });
            if (destFolders.length === 0) {
                throw { code: 3, message: "Destination folder '" + destFolder + "' not found. Please create it first." };
            }
            if (destFolders.length > 1) {
                throw { code: 4, message: "Multiple destination folders found with the name '" + destFolder + "'. Move aborted." };
            }
            Notes.move(note, { to: destFolders[0] });
            
            return successPayload({ success: true, id: noteId, from_folder: sourceFolder, to_folder: destFolder });
        }
        else if (cmd === "move-note-title") {
            const title = argv[1];
            const fromFolder = argv[2];
            const toFolder = argv[3];
            if (!title || !fromFolder || !toFolder) throw { code: 2, message: "Usage: move-note-title <title> <from_folder> <to_folder>" };
            
            const note = resolveNote(title, fromFolder);
            const noteId = note.id();
            
            enforceConfirm("Move Note", title, { id: noteId, from_folder: fromFolder, to_folder: toFolder });
            
            const destFolders = Notes.folders.whose({ name: toFolder });
            if (destFolders.length === 0) {
                throw { code: 3, message: "Destination folder '" + toFolder + "' not found. Please create it first." };
            }
            if (destFolders.length > 1) {
                throw { code: 4, message: "Multiple destination folders found with the name '" + toFolder + "'. Move aborted." };
            }
            Notes.move(note, { to: destFolders[0] });
            
            return successPayload({ success: true, id: noteId, from_folder: fromFolder, to_folder: toFolder });
        }
        else if (cmd === "delete-note-id") {
            const noteId = argv[1];
            if (!noteId) throw { code: 2, message: "Usage: delete-note-id <note_id>" };
            
            let note;
            try {
                note = Notes.notes.byId(noteId);
                note.name();
            } catch (e) {
                throw { code: 3, message: "Note with ID '" + noteId + "' not found" };
            }
            const folderName = note.container().name();
            
            enforceConfirm("Delete Note", note.name(), { id: noteId, folder: folderName });
            
            Notes.delete(note);
            return successPayload({ success: true, id: noteId });
        }
        else if (cmd === "delete-note-title") {
            const title = argv[1];
            const folderName = argv[2];
            if (!title || !folderName) throw { code: 2, message: "Usage: delete-note-title <title> <folder>" };
            
            const note = resolveNote(title, folderName);
            const noteId = note.id();
            
            enforceConfirm("Delete Note", title, { id: noteId, folder: folderName });
            
            Notes.delete(note);
            return successPayload({ success: true, id: noteId });
        }
        else if (cmd === "delete-folder") {
            const folderName = argv[1];
            if (!folderName) throw { code: 2, message: "Usage: delete-folder <folder>" };
            
            const folders = Notes.folders.whose({ name: folderName });
            if (folders.length === 0) {
                throw { code: 3, message: "Folder '" + folderName + "' not found" };
            }
            if (folders.length > 1) {
                throw { code: 4, message: "Multiple folders match the name '" + folderName + "'. Please rename them to be unique before deletion." };
            }
            const folder = folders[0];
            const count = folder.notes.length;
            
            enforceConfirm("Delete Folder", folderName, { note_count: count });
            
            Notes.delete(folder);
            return successPayload({ success: true, folder: folderName });
        }
        else if (cmd === "search-notes") {
            const queryText = argv[1];
            if (!queryText) throw { code: 2, message: "Usage: search-notes <query>" };
            
            const result = [];
            const folders = Notes.folders();
            for (let f = 0; f < folders.length; f++) {
                const folder = folders[f];
                const fName = folder.name();
                const notes = folder.notes();
                for (let n = 0; n < notes.length; n++) {
                    const title = notes[n].name();
                    if (title.toLowerCase().includes(queryText.toLowerCase())) {
                        result.push({
                            id: notes[n].id(),
                            title: title,
                            folder: fName,
                            modified_at: notes[n].modificationDate().toISOString()
                        });
                    }
                }
            }
            return successPayload(result);
        }
        else if (cmd === "list-folders") {
            const folders = Notes.folders();
            const result = [];
            for (let f = 0; f < folders.length; f++) {
                result.push(folders[f].name());
            }
            return successPayload(result);
        }
        else if (cmd === "list-notes") {
            const folderName = argv[1];
            if (!folderName) throw { code: 2, message: "Usage: list-notes <folder>" };
            
            const folders = Notes.folders.whose({ name: folderName });
            if (folders.length === 0) {
                throw { code: 3, message: "Folder '" + folderName + "' not found" };
            }
            if (folders.length > 1) {
                throw { code: 4, message: "Multiple folders found with the name '" + folderName + "'. Operation aborted to prevent ambiguous location." };
            }
            const notes = folders[0].notes();
            const result = [];
            for (let n = 0; n < notes.length; n++) {
                result.push({
                    id: notes[n].id(),
                    title: notes[n].name(),
                    folder: folderName,
                    modified_at: notes[n].modificationDate().toISOString()
                });
            }
            return successPayload(result);
        }
        else if (cmd === "get-date-id") {
            const noteId = argv[1];
            if (!noteId) throw { code: 2, message: "Usage: get-date-id <note_id>" };
            
            let note;
            try {
                note = Notes.notes.byId(noteId);
                note.name();
            } catch (e) {
                throw { code: 3, message: "Note with ID '" + noteId + "' not found" };
            }
            return successPayload({ id: noteId, modified_at: note.modificationDate().toISOString() });
        }
        else if (cmd === "get-date-title") {
            const title = argv[1];
            const folderName = argv[2];
            if (!title || !folderName) throw { code: 2, message: "Usage: get-date-title <title> <folder>" };
            
            const note = resolveNote(title, folderName);
            return successPayload({ id: note.id(), title: title, folder: folderName, modified_at: note.modificationDate().toISOString() });
        }
        else if (cmd === "count-all") {
            const count = Notes.notes.length;
            return successPayload(jsonMode ? { count: count } : String(count));
        }
        else if (cmd === "count-folder") {
            const folderName = argv[1];
            if (!folderName) throw { code: 2, message: "Usage: count-folder <folder>" };
            
            const folders = Notes.folders.whose({ name: folderName });
            if (folders.length === 0) {
                throw { code: 3, message: "Folder '" + folderName + "' not found" };
            }
            if (folders.length > 1) {
                throw { code: 4, message: "Multiple folders found with the name '" + folderName + "'. Operation aborted." };
            }
            const count = folders[0].notes.length;
            return successPayload(jsonMode ? { folder: folderName, count: count } : String(count));
        }
        else {
            throw { code: 2, message: "Unknown command: " + cmd };
        }
        
    } catch (e) {
        return errorPayload(e.code || 6, e.message || String(e), e.data);
    }
}
EOF
}

# Run JXA in the background-safe function to prevent shell parsing bugs
OUTPUT=$(run_jxa)

# Parse JXA output and handle standard exit codes
FIRST_LINE=$(echo "$OUTPUT" | head -n 1)
TYPE=$(echo "$FIRST_LINE" | cut -d':' -f1)

if [ "$TYPE" = "JSON_SUCCESS" ]; then
    # Output standard JSON to stdout
    echo "$OUTPUT" | sed 's/^JSON_SUCCESS://'
    exit 0
elif [ "$TYPE" = "JSON_ERROR" ]; then
    CODE=$(echo "$FIRST_LINE" | cut -d':' -f2)
    # Output standard JSON error payload to stderr
    echo "$OUTPUT" | sed "s/^JSON_ERROR:$CODE://" >&2
    exit "$CODE"
elif [ "$TYPE" = "TEXT_SUCCESS" ]; then
    # Output raw text to stdout
    echo "$OUTPUT" | sed 's/^TEXT_SUCCESS://'
    exit 0
elif [ "$TYPE" = "TEXT_ERROR" ]; then
    CODE=$(echo "$FIRST_LINE" | cut -d':' -f2)
    # Output error details to stderr
    echo "$OUTPUT" | sed "s/^TEXT_ERROR:$CODE://" >&2
    exit "$CODE"
else
    echo "Execution failed:" >&2
    echo "$OUTPUT" >&2
    exit 6
fi
