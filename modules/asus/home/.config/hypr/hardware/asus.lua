-- ASUS laptops (modules/asus): ROG Control Center opens as a small floating window, like the other tools.
hl.window_rule({
    name  = "float-rog-control-center",
    match = { class = "^(org.opengamingcollective.rog-control-center)$" },
    float = true,
})
