// Makes the minimise button in app title bars work. Hyprland receives the request
// (xdg_toplevel.set_minimized) but drops it, so this listens for it on every window and sends the
// window to special:minimized, the same place Super+H and the dock use (the dock restores it).
// Wayland apps only; XWayland apps still ignore the button. Built and loaded by ~/.local/bin/hypr-plugins.
#define WLR_USE_UNSTABLE
#include <format>
#include <unordered_map>
#include <hyprland/src/desktop/state/WindowState.hpp>
#include <hyprland/src/desktop/view/window/Window.hpp>
#include <hyprland/src/event/EventBus.hpp>
#include <hyprland/src/managers/eventLoop/EventLoopManager.hpp>
#include <hyprland/src/plugins/PluginAPI.hpp>
#include <hyprland/src/protocols/XDGShell.hpp>
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

static void watch(PHLWINDOW w) {
    const auto surface = w->backend().surface();
    const auto role    = surface ? dynamicPointerCast<CXDGSurfaceRole>(surface->m_role) : nullptr;
    const auto xdg     = role ? role->m_xdgSurface.lock() : nullptr;
    const auto top     = xdg ? xdg->m_toplevel.lock() : nullptr;
    if (!top)
        return;   // not an xdg-shell toplevel (XWayland, layer surfaces)
    g_listeners[w.get()] = top->m_events.stateChanged.listen([ref = w->m_self, wtop = WP<CXDGToplevelResource>(top)] {
        const auto t = wtop.lock();
        // requestsMinimize is only set while this signal fires
        if (t && t->m_state.requestsMinimize.value_or(false))
            minimise(ref);
    });
}

APICALL EXPORT std::string PLUGIN_API_VERSION() {
    return HYPRLAND_API_VERSION;
}

APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    if (__hyprland_api_get_hash() != std::string(__hyprland_api_get_client_hash()))
        throw std::runtime_error("[minimize] built for another Hyprland version, run hypr-plugins");

    static auto onOpen    = Event::bus()->m_events.window.open.listen([](PHLWINDOW w) { watch(w); });
    static auto onDestroy = Event::bus()->m_events.window.destroy.listen([](PHLWINDOWREF w) { g_listeners.erase(w.get()); });
    for (const auto& w : Desktop::windowState()->windows())
        if (w->mapped())
            watch(w);

    return {"minimize", "Title-bar minimise buttons send windows to the dock", "hyprism", "1.0"};
}

APICALL EXPORT void PLUGIN_EXIT() {
    g_listeners.clear();
}
