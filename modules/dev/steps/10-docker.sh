# shellcheck shell=bash
# Docker: start it on first use (not at boot), and offer to let you run it without sudo.
# The docker group can do anything root can, so joining it is asked separately.
sys_enable docker.socket
sys_disable docker.service
if ! id -nG "$USER" | grep -qw docker; then
    if ask "Add $USER to the docker group (run docker without sudo; that group is as powerful as root)?"; then
        run sudo usermod -aG docker "$USER"
        sys_note "you were added to the docker group (undo: sudo gpasswd -d $USER docker)"
        say "Log out and back in once for the docker group to apply."
    fi
fi
