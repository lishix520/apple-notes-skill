#!/bin/bash
# Apple Notes CLI Wrapper for AI Agents (v0.3.0)
# Uses only built-in osascript JXA (JavaScript for Automation) and Notes.app.

set -euo pipefail

# Global variables
CONFIRM=0
JSON_MODE=0
ARGS=()

for arg in "$@"; do
    if [ "$arg" = "--json" ]; then
        JSON_MODE=1
    elif [ "$arg" = "--confirm" ]; then
        CONFIRM=1
    else
        ARGS+=("$arg")
    fi
done

show_help() {
    echo "Apple Notes Skill CLI (v0.3.0)"
    echo "Usage: $0 [options] <command> [args...]"
    echo ""
    echo "Options:"
    echo "  --json              Output machine-readable JSON"
    echo "  --confirm           Acknowledge and proceed with destructive actions"
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
    env CONFIRM="$CONFIRM" JSON_MODE="$JSON_MODE" osascript -l JavaScript - "${ARGS[@]}" <<'EOF'
ObjC.import('stdlib');

const confirmMode = $.getenv('CONFIRM') === '1';
const jsonMode = $.getenv('JSON_MODE') === '1';

const Notes = Application('Notes');
Notes.includeStandardAdditions = true;

function escapeHTML(text) {
    return text.replace(/&/g, "&amp;")
               .replace(/</g, "&lt;")
               .replace(/>/g, "&gt;")
               .replace(/"/g, "&quot;")
               .replace(/'/g, "&#039;");
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
        let data = "";
        
        if (cmd === "create-note-text") {
            const title = argv[1];
            const folderName = argv[2];
            const plainText = argv[3];
            if (!title || !folderName || plainText === undefined) throw { code: 2, message: "Usage: create-note-text <title> <folder> <plain_text>" };
            
            const folders = Notes.folders.whose({ name: folderName });
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
            data = jsonMode ? JSON.stringify(meta) : "Created note: " + note.name() + " (" + note.id() + ") in folder " + folderName;
        }
        else if (cmd === "create-note-html") {
            const title = argv[1];
            const folderName = argv[2];
            const htmlContent = argv[3];
            if (!title || !folderName || htmlContent === undefined) throw { code: 2, message: "Usage: create-note-html <title> <folder> <body_html>" };
            
            const folders = Notes.folders.whose({ name: folderName });
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
            data = jsonMode ? JSON.stringify(meta) : "Created note: " + note.name() + " (" + note.id() + ") in folder " + folderName;
        }
        else if (cmd === "create-folder") {
            const folderName = argv[1];
            if (!folderName) throw { code: 2, message: "Usage: create-folder <folder>" };
            
            const folders = Notes.folders.whose({ name: folderName });
            if (folders.length === 0) {
                const folder = Notes.Folder({ name: folderName });
                Notes.folders.push(folder);
            }
            data = jsonMode ? JSON.stringify({ folder: folderName }) : "Created folder: " + folderName;
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
            if (jsonMode) {
                data = JSON.stringify({
                    id: note.id(),
                    title: note.name(),
                    folder: folder.name(),
                    modified_at: note.modificationDate().toISOString(),
                    body: note.body()
                });
            } else {
                data = note.body();
            }
        }
        else if (cmd === "read-note-title") {
            const title = argv[1];
            const folderName = argv[2];
            if (!title) throw { code: 2, message: "Usage: read-note-title <title> [folder]" };
            
            const note = resolveNote(title, folderName);
            const folder = note.container();
            if (jsonMode) {
                data = JSON.stringify({
                    id: note.id(),
                    title: note.name(),
                    folder: folder.name(),
                    modified_at: note.modificationDate().toISOString(),
                    body: note.body()
                });
            } else {
                data = note.body();
            }
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
            const currentBody = note.body();
            const escapedText = "<div>" + escapeHTML(plainText).replace(/\n/g, "<br></div><div>") + "</div>";
            note.body = currentBody + escapedText;
            
            data = jsonMode ? JSON.stringify({ success: true, id: noteId }) : "Appended text to note " + noteId;
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
            const currentBody = note.body();
            note.body = currentBody + htmlContent;
            
            data = jsonMode ? JSON.stringify({ success: true, id: noteId }) : "Appended HTML to note " + noteId;
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
            Notes.move(note, { to: destFolders[0] });
            
            data = jsonMode ? JSON.stringify({ success: true, id: noteId, from_folder: sourceFolder, to_folder: destFolder })
                            : "Moved note " + note.name() + " (" + noteId + ") to folder " + destFolder;
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
            Notes.move(note, { to: destFolders[0] });
            
            data = jsonMode ? JSON.stringify({ success: true, id: noteId, from_folder: fromFolder, to_folder: toFolder })
                            : "Moved note " + title + " (" + noteId + ") to folder " + toFolder;
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
            
            data = jsonMode ? JSON.stringify({ success: true, id: noteId }) : "Deleted note " + noteId;
        }
        else if (cmd === "delete-note-title") {
            const title = argv[1];
            const folderName = argv[2];
            if (!title || !folderName) throw { code: 2, message: "Usage: delete-note-title <title> <folder>" };
            
            const note = resolveNote(title, folderName);
            const noteId = note.id();
            
            enforceConfirm("Delete Note", title, { id: noteId, folder: folderName });
            
            Notes.delete(note);
            
            data = jsonMode ? JSON.stringify({ success: true, id: noteId }) : "Deleted note " + title + " (" + noteId + ")";
        }
        else if (cmd === "delete-folder") {
            const folderName = argv[1];
            if (!folderName) throw { code: 2, message: "Usage: delete-folder <folder>" };
            
            const folders = Notes.folders.whose({ name: folderName });
            if (folders.length === 0) {
                throw { code: 3, message: "Folder '" + folderName + "' not found" };
            }
            const folder = folders[0];
            const count = folder.notes.length;
            
            enforceConfirm("Delete Folder", folderName, { note_count: count });
            
            Notes.delete(folder);
            
            data = jsonMode ? JSON.stringify({ success: true, folder: folderName }) : "Deleted folder " + folderName;
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
            data = jsonMode ? JSON.stringify(result, null, 2)
                            : result.map(r => r.folder + "\t" + r.title + "\t" + r.id).join("\n");
        }
        else if (cmd === "list-folders") {
            const folders = Notes.folders();
            const result = [];
            for (let f = 0; f < folders.length; f++) {
                result.push(folders[f].name());
            }
            data = jsonMode ? JSON.stringify(result) : result.join("\n");
        }
        else if (cmd === "list-notes") {
            const folderName = argv[1];
            if (!folderName) throw { code: 2, message: "Usage: list-notes <folder>" };
            
            const folders = Notes.folders.whose({ name: folderName });
            if (folders.length === 0) {
                throw { code: 3, message: "Folder '" + folderName + "' not found" };
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
            data = jsonMode ? JSON.stringify(result, null, 2)
                            : result.map(r => r.title + "\t" + r.modified_at + "\t" + r.id).join("\n");
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
            const dateStr = note.modificationDate().toISOString();
            data = jsonMode ? JSON.stringify({ id: noteId, modified_at: dateStr }) : dateStr;
        }
        else if (cmd === "get-date-title") {
            const title = argv[1];
            const folderName = argv[2];
            if (!title || !folderName) throw { code: 2, message: "Usage: get-date-title <title> <folder>" };
            
            const note = resolveNote(title, folderName);
            const dateStr = note.modificationDate().toISOString();
            data = jsonMode ? JSON.stringify({ id: note.id(), title: title, folder: folderName, modified_at: dateStr }) : dateStr;
        }
        else if (cmd === "count-all") {
            const count = Notes.notes.length;
            data = jsonMode ? JSON.stringify({ count: count }) : String(count);
        }
        else if (cmd === "count-folder") {
            const folderName = argv[1];
            if (!folderName) throw { code: 2, message: "Usage: count-folder <folder>" };
            
            const folders = Notes.folders.whose({ name: folderName });
            if (folders.length === 0) {
                throw { code: 3, message: "Folder '" + folderName + "' not found" };
            }
            const count = folders[0].notes.length;
            data = jsonMode ? JSON.stringify({ folder: folderName, count: count }) : String(count);
        }
        else {
            throw { code: 2, message: "Unknown command: " + cmd };
        }
        
        return "STATUS:SUCCESS\nDATA:" + data;
    } catch (e) {
        let errData = "";
        if (e.data) {
            errData = "\nDATA:" + JSON.stringify(e.data);
        }
        return "STATUS:ERROR\nCODE:" + (e.code || 6) + "\nMESSAGE:" + (e.message || String(e)) + errData;
    }
}
EOF
}

# Run JXA in the background-safe function to prevent shell parsing bugs
OUTPUT=$(run_jxa)

# Parse JXA output and handle standard exit codes
STATUS=$(echo "$OUTPUT" | grep "^STATUS:" | cut -d':' -f2-)

if [ "$STATUS" = "ERROR" ]; then
    CODE=$(echo "$OUTPUT" | grep "^CODE:" | cut -d':' -f2-)
    MESSAGE=$(echo "$OUTPUT" | grep "^MESSAGE:" | cut -d':' -f2-)
    DATA=$(echo "$OUTPUT" | sed -n '/^DATA:/,$p' | sed 's/^DATA://')
    
    if [ "$JSON_MODE" = "1" ]; then
        # Pure single-quoted shell formatting to prevent nested quote parsing failures
        echo '{"error": "'"$MESSAGE"'", "code": '"$CODE"', "details": '"$DATA"'}' >&2
    else
        echo "Error: $MESSAGE" >&2
        if [ -n "$DATA" ] && [ "$DATA" != "undefined" ]; then
            echo "$DATA" >&2
        fi
    fi
    exit "$CODE"
elif [ "$STATUS" = "SUCCESS" ]; then
    echo "$OUTPUT" | sed -n '/^DATA:/,$p' | sed 's/^DATA://'
else
    echo "Execution failed:" >&2
    echo "$OUTPUT" >&2
    exit 6
fi
