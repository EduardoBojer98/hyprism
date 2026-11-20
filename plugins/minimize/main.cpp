// Makes the minimise and maximise buttons in app title bars work. Hyprland receives the request
// (xdg_toplevel.set_minimized) but drops it, so this listens for it on every window and sends the
// window to special:minimized, the same place Super+H and the dock use (the dock restores it).
// Maximise requests go to the Lua maximise_button() (modules/windows.lua) with the window's state.
// Wayland apps only; XWayland apps still ignore the button.
// Edge snap: while a floating window is dragged near a screen edge the Lua snap_preview() shows where it will go,
// and edge_snap() places it when dropped (modules/windows.lua). Chrome's tab drag closes the window and opens a new
// one at the drop, so that new window is floated and snapped the same way (tab_drop()).
// Hyprland tells every app it is maximised (so apps skip their own borders), and an app button that already
// asked to un-maximise stays dead. A window floated after it opened, without a title bar, is told it isn't, until
// it is tiled or maximised again, so its own maximise button works.
// Built and loaded by ~/.local/bin/hypr-plugins.
#define WLR_USE_UNSTABLE
#include <chrono>
#include <format>
#include <unordered_map>
#include <hyprland/src/desktop/state/WindowState.hpp>
#include <hyprland/src/desktop/view/window/Window.hpp>
#include <hyprland/src/event/EventBus.hpp>
#include <hyprland/src/layout/LayoutManager.hpp>
#include <hyprland/src/layout/supplementary/DragController.hpp>
#include <hyprland/src/render/decorations/DecorationPositioner.hpp>
#include <hyprland/src/managers/eventLoop/EventLoopManager.hpp>
#include <hyprland/src/managers/fullscreen/FullscreenController.hpp>
#include <hyprland/src/plugins/PluginAPI.hpp>
#include <hyprland/src/desktop/state/FocusState.hpp>
#include <hyprland/src/output/Monitor.hpp>
#include <hyprland/src/protocols/XDGShell.hpp>
#include <hyprland/src/protocols/core/DataDevice.hpp>
#include <hyprland/src/protocols/core/Compositor.hpp>

// one listener per window, dropped when the window closes
static std::unordered_map<Desktop::View::CWindow*, CHyprSignalListener> g_listeners;

static void minimise(PHLWINDOWREF ref) {
    // later, outside the protocol handler: the move goes through the normal dispatcher
    g_pEventLoopManager->doLater([ref] {
        const auto w = ref.lock();
        if (!w || !w->mapped())
            return;
        HyprlandAPI::invokeHyprctlCommand("dispatch",
            std::format("hl.dsp.window.move({{ workspace = \"special:minimized\", follow = false, window = \"address:0x{:x}\" }})", (uintptr_t)w.get()));
    });
}

static SP<CXDGToplevelResource> toplevelOf(PHLWINDOW w) {
    const auto surface = w->backend().surface();
    const auto role    = surface ? dynamicPointerCast<CXDGSurfaceRole>(surface->m_role) : nullptr;
    const auto xdg     = role ? role->m_xdgSurface.lock() : nullptr;
    return xdg ? xdg->m_toplevel.lock() : nullptr;   // null: not an xdg-shell toplevel (XWayland, layer surfaces)
}

// the title bar: what decorations reserve above the window beyond the border (reserved on every side)
static int barHeight(PHLWINDOW w) {
    const auto r = g_pDecorationPositioner->getWindowDecorationReserved(w);
    return (int)(r.topLeft.y - r.bottomRight.y);
}

static void eval(const std::string& lua) {
    HyprlandAPI::invokeHyprctlCommand("eval", lua);
}

// an app's own maximise button: maximise_button() decides. Every window stays told it is maximised (Hyprland
// does that on map): a "restored" Chrome or GTK app draws its own shadow and the border lands outside it. A
// restore request gets a brief "not maximised" first, or Chrome waits for that answer and its button stops working
// Apps also ask on their own (Chrome when tiling resizes it, or restoring its last state), and a tiled window would
// float out of the layout: only a request right after a click, tap or pen touch is the app's button.
static std::chrono::steady_clock::time_point g_lastPress;
static void pressed() {
    g_lastPress = std::chrono::steady_clock::now();
}

// Leaving fullscreen (a video's exit button: a click) makes Chrome ask to be maximised again; that is no button
// press, and taking it for one floated the tiled window. Requests this soon after a fullscreen change are the app's own.
static std::unordered_map<Desktop::View::CWindow*, std::chrono::steady_clock::time_point> g_fullscreenAt;

static void maximise(PHLWINDOWREF ref, bool asked) {
    const auto now     = std::chrono::steady_clock::now();
    const auto fsAt    = g_fullscreenAt.find(ref.get());
    const bool afterFs = fsAt != g_fullscreenAt.end() && now - fsAt->second < std::chrono::milliseconds(1000);
    const bool clicked = !afterFs && now - g_lastPress < std::chrono::milliseconds(1500);
    g_pEventLoopManager->doLater([ref, asked, clicked] {
        const auto w = ref.lock();
        if (!w || !w->mapped())
            return;
        const int fs = (int)Fullscreen::controller()->getFullscreenModes(w).internal;
        if (clicked)
            eval(std::format("maximise_button(\"0x{:x}\", {}, {})", (uintptr_t)w.get(), w->isFloating() ? "true" : "false", fs));
        const auto top = toplevelOf(w);
        if (!top || asked)
            return;
        top->setMaximized(false);
        g_pEventLoopManager->doLater([ref] {   // the next turn, after that configure went out
            if (const auto w = ref.lock(); w && w->mapped())
                if (const auto top = toplevelOf(w))
                    top->setMaximized(true);
        });
    });
}

// the window being moved by a drag, set while it moves (a click without a move never gets here)
static PHLWINDOWREF g_dragged;
static bool         g_previewing = false;

// the pointer near a screen edge, or a preview up that must follow or go: ask Lua where it would land
static void preview(int bar) {
    const auto at = g_pInputManager->getMouseCoordsInternal();
    const auto m  = Desktop::focusState()->monitor();
    if (!m)
        return;
    const auto b    = m->logicalBox();
    const bool near = at.x <= b.x + 4 || at.x >= b.x + b.w - 5 || at.y <= b.y + 4 || at.y >= b.y + b.h - 5;
    if (!near && !g_previewing)
        return;
    g_previewing = near;
    eval(std::format("snap_preview({}, {}, {})", (int)at.x, (int)at.y, bar));
}

static void dragMoved() {
    const auto& d = g_layoutManager->dragController();
    const auto  t = d->target();
    g_dragged     = d->mode() == MBIND_MOVE && !d->draggingTiled() && t ? t->window() : nullptr;
    if (const auto w = g_dragged.lock())
        preview(barHeight(w));
}

static void dragEnded() {
    const auto ref = g_dragged;
    g_dragged.reset();
    if (!ref.lock())
        return;
    g_previewing = false;
    g_pEventLoopManager->doLater([ref] {
        const auto w = ref.lock();
        if (!w || !w->mapped() || !w->isFloating()) {
            eval("snap_preview()");
            return;
        }
        const auto at = g_pInputManager->getMouseCoordsInternal();
        eval(std::format("edge_snap(\"0x{:x}\", {}, {}, {})", (uintptr_t)w.get(), (int)at.x, (int)at.y, barHeight(w)));
    });
}

// Chrome's tab drag: a floating window that closes as a drag and drop starts comes back as a new window at the drop
static struct {
    std::string                           cls;
    int                                   w = 0, h = 0;
    std::chrono::steady_clock::time_point seen;   // the drag was last seen going on
} g_tabDrag;

static bool tabDragLive() {
    return !g_tabDrag.cls.empty() && std::chrono::steady_clock::now() - g_tabDrag.seen < std::chrono::milliseconds(800);
}

static void closing(PHLWINDOW w) {
    if (!w->isFloating() || barHeight(w) > 0)
        return;
    const auto box = w->layoutBox();
    g_tabDrag      = {w->metadata().appID(), (int)box.w, (int)box.h, std::chrono::steady_clock::now()};
}

static void mouseMoved() {
    if (g_tabDrag.cls.empty())
        return;
    if (!PROTO::data->dndActive()) {
        if (g_previewing && !tabDragLive()) {
            g_previewing = false;
            eval("snap_preview()");
        }
        return;
    }
    g_tabDrag.seen = std::chrono::steady_clock::now();
    preview(0);
}

static void opened(PHLWINDOW w) {
    if (!tabDragLive() && !(PROTO::data->dndActive() && !g_tabDrag.cls.empty()))
        return;
    if (w->metadata().appID() != g_tabDrag.cls)
        return;
    const int ww = g_tabDrag.w, wh = g_tabDrag.h;
    g_tabDrag.cls.clear();
    g_previewing = false;
    g_pEventLoopManager->doLater([ref = w->m_self, ww, wh] {
        const auto w = ref.lock();
        if (!w || !w->mapped())
            return;
        const auto at = g_pInputManager->getMouseCoordsInternal();
        eval(std::format("tab_drop(\"0x{:x}\", {}, {}, {}, {})", (uintptr_t)w.get(), ww, wh, (int)at.x, (int)at.y));
    });
}

static void watch(PHLWINDOW w) {
    const auto top = toplevelOf(w);
    if (!top)
        return;
    g_listeners[w.get()] = top->m_events.stateChanged.listen([ref = w->m_self, wtop = WP<CXDGToplevelResource>(top)] {
        const auto t = wtop.lock();
        // requestsMinimize is only set while this signal fires
        if (t && t->m_state.requestsMinimize.value_or(false))
            minimise(ref);
        if (t && t->m_state.requestsMaximize.has_value())
            maximise(ref, *t->m_state.requestsMaximize);
    });
}

APICALL EXPORT std::string PLUGIN_API_VERSION() {
    return HYPRLAND_API_VERSION;
}

APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    if (__hyprland_api_get_hash() != std::string(__hyprland_api_get_client_hash()))
        throw std::runtime_error("[minimize] built for another Hyprland version, run hypr-plugins");

    static auto onOpen    = Event::bus()->m_events.window.open.listen([](PHLWINDOW w) { watch(w); opened(w); });
    static auto onClose   = Event::bus()->m_events.window.close.listen([](PHLWINDOW w) { closing(w); });
    static auto onDestroy = Event::bus()->m_events.window.destroy.listen([](PHLWINDOWREF w) { g_listeners.erase(w.get()); g_fullscreenAt.erase(w.get()); });
    static auto onFs      = Event::bus()->m_events.window.fullscreen.listen([](PHLWINDOW w) { g_fullscreenAt[w.get()] = std::chrono::steady_clock::now(); });
    static auto onMouse   = Event::bus()->m_events.input.mouse.move.listen([](Vector2D, Event::SCallbackInfo&) { mouseMoved(); });
    static auto onButton  = Event::bus()->m_events.input.mouse.button.listen([](IPointer::SButtonEvent e, Event::SCallbackInfo&) {
        if (e.state == WL_POINTER_BUTTON_STATE_PRESSED)
            pressed();
    });
    static auto onTouch   = Event::bus()->m_events.input.touch.down.listen([](ITouch::SDownEvent, Event::SCallbackInfo&) { pressed(); });
    static auto onTip     = Event::bus()->m_events.input.tablet.tip.listen([](CTablet::STipEvent, Event::SCallbackInfo&) { pressed(); });
    static auto onDrag    = g_layoutManager->dragController()->m_events.motion.listen(dragMoved);
    static auto onDrop    = g_layoutManager->dragController()->m_events.ended.listen(dragEnded);
    for (const auto& w : Desktop::windowState()->windows())
        if (w->mapped()) {
            watch(w);
            if (const auto top = toplevelOf(w))
                top->setMaximized(true);   // an older build told floating windows otherwise
        }

    return {"minimize", "Title-bar minimise and maximise buttons work, floating windows snap to screen edges", "hyprism", "1.0"};
}

APICALL EXPORT void PLUGIN_EXIT() {
    g_listeners.clear();
}
