import QtQuick
import QtQuick.Layouts

// A menu: a column of MenuRows (with headers or dividers between them) that the keyboard can walk.
// Up / Down move between rows (wrapping), Home / End jump to the ends, Enter or Space picks, Escape goes up
// to the panel, which closes. Give the list the keyboard when the menu opens (CursorPopup's focusItem).
//   MenuList { MenuRow { … }  MenuDivider {}  Repeater { model: …; MenuRow { … } } }
ColumnLayout {
    id: list
    spacing: 0

    // the rows that can be picked, in order (a row inside a Loader counts too)
    function rows() {
        const out = []
        for (const c of children) {
            const r = c.menuRow ? c : c.item?.menuRow ? c.item : null
            if (r && r.visible && r.enabled) out.push(r)
        }
        return out
    }
    function move(step, to) {
        const r = rows()
        if (!r.length) return
        let i = r.findIndex(x => x.activeFocus)
        i = to !== undefined ? to : i < 0 ? (step > 0 ? 0 : r.length - 1) : (i + step + r.length) % r.length
        r[Math.max(0, Math.min(i, r.length - 1))].forceActiveFocus()
    }
    Keys.onUpPressed: move(-1)
    Keys.onDownPressed: move(1)
    Keys.onPressed: e => {
        if (e.key === Qt.Key_Home) { move(0, 0); e.accepted = true }
        else if (e.key === Qt.Key_End) { move(0, rows().length - 1); e.accepted = true }
    }

}
