#!/usr/bin/env bash

set -e

log() {
	ERROR=$'\e[1;31m'
	SUCC=$'\e[1;32m'
	WARN=$'\e[1;33m'
	INFO=$'\e[1;34m'
	end=$'\e[0m'
	printf "${!1}[$1] - $2${end}\n"
	if [ ! -z $3 ]; then exit $3; fi
}

function step1() {
	log INFO "Atempting to update system..."
	sudo dnf update -y || log ERROR 'Could not update...' 1
	log SUCC "Updated system! Setting step 2! Restarting in 10s ..."
	printf "2" > /home/${USER}/.cooking/.step
	sleep 10
	reboot
}

function set_hostmane() {
	log INFO "Setting hostname to ${USER}-work ..."
	sudo hostnamectl set-hostname --static ${USER}-work || log ERROR 'Could not set device name...' 1
	sudo sed -i "s/localhost4.localdomain4/localhost4.localdomain4 ${USER}-work/g" /etc/hosts || log ERROR 'Could not set hosts...' 1
	sudo sed -i "s/localhost6.localdomain6/localhost6.localdomain6 ${USER}-work/g" /etc/hosts || log ERROR 'Could not set hosts...' 1
	log SUCC "Updated hostname. This hostname will be updated after reboot"
}

function step2() {
	set_hostmane

	log SUCC "Updated system! Setting step 3! Restarting in 10s ..."
	printf "3" > /home/${USER}/.cooking/.step
	sleep 10
	reboot
}

function install_dnf_packages() {
	log INFO "Removing software..."
	sudo dnf -y remove java-*
	sudo dnf -y remove thunderbird
	log SUCC "Removed unwanted packages."

	log INFO "Atempting to add Fusion repositories..."
	sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
		|| log ERROR 'Could not set Fusion Free...' 1
	sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm \
		|| log ERROR 'Could not set Fusion Non-Free...' 1
	log SUCC "Added Fusion repositories."
	
	log INFO "Installing other dnf software..."
	sudo dnf -y install dnf-plugins-core vim podman curl wget kitty git git-lfs fastfetch eza flatpak zoxide fzf postgresql\
		|| log ERROR 'Could not install other dnf software...' 1
	log SUCC "Installed dnf packages."
	log INFO "Initializing git lfs..."
	git lfs install
	log SUCC "Initialized git lfs."

}

function install_flatpaks() {
	log INFO "Atempting to add flatpak flathub repository..."
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo \
		|| log ERROR 'Could not set flathub repository...' 1
	log SUCC "Added flatpak Flathub repository."
	log INFO "Installing other flatpak software..."
	flatpak install -y flathub \
		com.github.tchx84.Flatseal \
		io.dbeaver.DBeaverCommunity \
		com.anydesk.Anydesk \
		org.libreoffice.LibreOffice \
		io.podman_desktop.PodmanDesktop \
		org.mozilla.Thunderbird \
		com.discordapp.Discord \
		md.obsidian.Obsidian \
		org.chromium.Chromium \
		|| log ERROR 'Could not install flatpak software...' 1
	log SUCC "Installed flatpak packages via Flathub."
}

function install_nvm() {
	log INFO "Installing nvm ..."
	wget -O /home/${USER}/.cooking/nvm-install.sh https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh
	bash /home/${USER}/.cooking/nvm-install.sh
	log SUCC "Installed nvm."

	log INFO "Installing Node 20 candidates."
	bash -c 'source ~/.bashrc && nvm install 20'
	log SUCC "Installed Node 20 candidates."
}

function install_sdkman() {
	log INFO "Installing sdkman ..."
	wget -O /home/${USER}/.cooking/sdkman-install.sh "https://get.sdkman.io"
	bash /home/${USER}/.cooking/sdkman-install.sh
	log SUCC "Installed sdkman. After reboot we shall set a default Java and Maven."
}

function install_java_versions() {
	log INFO "Setting up JDKs ..."

	log INFO "Installing Java 8 candidates."
	bash -c 'source ~/.bashrc && sdk install java 8.0.412-zulu'
	log SUCC "Installed Java 8 candidates."

	log INFO "Installing Java 11 candidates."
	bash -c 'source ~/.bashrc && sdk install java 11.0.23-zulu'
	log SUCC "Installed Java 11 candidates."

	log INFO "Installing Java 17 candidates."
	bash -c 'source ~/.bashrc && sdk install java 17.0.11-zulu && sdk install java 17.0.11-oracle'
	log SUCC "Installed Java 17 candidates."

	log INFO "Installing Java 21 candidates."
	bash -c 'source ~/.bashrc && sdk install java 21.0.3-zulu && sdk install java 21.0.3-oracle'
	log SUCC "Installed Java 21 candidates."

	log SUCC "JDKs were added."
}

function install_maven_versions() {
	log INFO "Setting up MVNs ..."

	log INFO "Installing Maven 3.8.8 candidates."
	bash -c 'source ~/.bashrc && sdk install maven 3.8.8'
	log SUCC "Installed Maven 3.8.8 candidates."

	log INFO "Installing Maven 3.9.7 candidates."
	bash -c 'source ~/.bashrc && sdk install maven 3.9.7'
	log SUCC "Installed Maven 3.9.7 candidates."

	log SUCC "MVNs were added."
}

function install_ides {
	log INFO "Installing VSCodium for frontend development..."
	sudo rpmkeys --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg
	printf "[gitlab.com_paulcarroty_vscodium_repo]\nname=download.vscodium.com\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg\nmetadata_expire=1h" | sudo tee -a /etc/yum.repos.d/vscodium.repo
	sudo dnf -y install codium || log ERROR 'Could not install other dnf software...' 1
	log SUCC "Installed VSCodium."

	log INFO "Installing Eclipse and Idea for Java Development..."
	wget -O /home/${USER}/kits/dev/eclipse.tar.gz https://ftp.fau.de/eclipse/technology/epp/downloads/release/2024-06/R/eclipse-jee-2024-06-R-linux-gtk-x86_64.tar.gz
	wget -O /home/${USER}/kits/dev/idea.tar.gz https://download.jetbrains.com/idea/ideaIC-2024.1.3.tar.gz
	cd /home/${USER}/kits/dev/
	mkdir eclipse
	tar -xzvf eclipse.tar.gz -C eclipse --strip-components=1
	mkdir idea
	tar -xzvf idea.tar.gz -C idea --strip-components=1
	rm -rf *.tar.gz
	cd -

	mkdir -p /home/${USER}/.local/share/applications/

	echo "[Desktop Entry]" >> /home/${USER}/.local/share/applications/eclipse.desktop
	echo "Comment=Eclipse IDE installed by cooking script." >> /home/${USER}/.local/share/applications/eclipse.desktop
	echo "Exec=/home/${USER}/kits/dev/eclipse/eclipse" >> /home/${USER}/.local/share/applications/eclipse.desktop
	echo "GenericName=Eclipse IDE for Enterprise Java and Web Developers" >> /home/${USER}/.local/share/applications/eclipse.desktop
	echo "Icon=/home/${USER}/kits/dev/eclipse/icon.xpm" >> /home/${USER}/.local/share/applications/eclipse.desktop
	echo "Name=Eclipse" >> /home/${USER}/.local/share/applications/eclipse.desktop
	echo "NoDisplay=false" >> /home/${USER}/.local/share/applications/eclipse.desktop
	echo "Path=" >> /home/${USER}/.local/share/applications/eclipse.desktop
	echo "StartupNotify=true" >> /home/${USER}/.local/share/applications/eclipse.desktop
	echo "Terminal=false" >> /home/${USER}/.local/share/applications/eclipse.desktop
	echo "TerminalOptions=" >> /home/${USER}/.local/share/applications/eclipse.desktop
	echo "Type=Application" >> /home/${USER}/.local/share/applications/eclipse.desktop

	echo "[Desktop Entry]" >> /home/${USER}/.local/share/applications/idea.desktop
	echo "Comment=IntelliJ IDEA installed by cooking script." >> /home/${USER}/.local/share/applications/idea.desktop
	echo "Exec=/home/${USER}/kits/dev/idea/bin/idea.sh" >> /home/${USER}/.local/share/applications/idea.desktop
	echo "GenericName=IntelliJ IDEA" >> /home/${USER}/.local/share/applications/idea.desktop
	echo "Icon=/home/${USER}/kits/dev/idea/bin/idea.svg" >> /home/${USER}/.local/share/applications/idea.desktop
	echo "Name=IntelliJ IDEA" >> /home/${USER}/.local/share/applications/idea.desktop
	echo "NoDisplay=false" >> /home/${USER}/.local/share/applications/idea.desktop
	echo "Path=" >> /home/${USER}/.local/share/applications/idea.desktop
	echo "StartupNotify=true" >> /home/${USER}/.local/share/applications/idea.desktop
	echo "Terminal=false" >> /home/${USER}/.local/share/applications/idea.desktop
	echo "TerminalOptions=" >> /home/${USER}/.local/share/applications/idea.desktop
	echo "Type=Application" >> /home/${USER}/.local/share/applications/idea.desktop

	log SUCC "Installed Eclipse and Idea."

}

function set_kitty_config() {
cat > /home/${USER}/.config/kitty/kitty.conf <<'EOF'
font_family Hack Regular Nerd Font Complete
bold_font auto
italic_font auto
bold_italic_font auto
font_size 12.0
background_opacity 0.8
EOF
}

function install_terminal() {
	log INFO "Installing and configuring starship..."
	wget -O /home/${USER}/.cooking/starship-install.sh https://starship.rs/install.sh
	sh /home/${USER}/.cooking/starship-install.sh -V -y || log ERROR 'Could not install starship.' 1
	wget -O /home/${USER}/.config/starship.toml https://raw.githubusercontent.com/w3samiulazim/garuda-starship.toml/main/starship.toml
	mkdir -p /home/${USER}/.config/kitty
	set_kitty_config
	log SUCC "Installed starship and configured kitty terminal."

	log INFO "Installing mcfly..."
	curl -LSfs https://raw.githubusercontent.com/cantino/mcfly/master/ci/install.sh | sudo sh -s -- --git cantino/mcfly
	log SUCC "Installed mcfly."

	log INFO "Atempting to install fish shell..."
	sudo dnf install fish -y
	sudo chsh -s $(which fish) ${USER}
	fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'
	fish -c 'fisher install jorgebucaran/nvm.fish'
	fish -c 'fisher install reitzig/sdkman-for-fish@v2.1.0'
	log SUCC "Added fish shell as default..."
}

function customize_bashrc() {
cat >> /home/${USER}/.bashrc <<'EOF'

alias upd="sudo dnf update && flatpak update"
alias update="sudo dnf update && flatpak update"

alias grubup="sudo update-grub"

alias ssh="TERM=xterm-color ssh"

## Useful aliases
# Replace ls with exa
alias l='eza -1'                                                                    # nothing special
alias ls='eza -al --color=always --group-directories-first --icons'                 # preferred listing
alias la='eza -a --color=always --group-directories-first --icons'                  # all files and dirs
alias ll='eza -laB --sort name --time-style long-iso --git --icons --color=always'  # long format
alias lt='eza -aT --color=always --group-directories-first --icons'                 # tree listing
alias l.="eza -a | egrep '^\.'"                                                     # show only dotfiles

eval "$(zoxide init --cmd cd bash)"
eval "$(mcfly init bash)"

EOF
}

function customize_fish() {
cat >> /home/${USER}/.config/fish/config.fish <<'EOF'
# Common use
alias upd="sudo dnf update && flatpak update"
alias update="sudo dnf update && flatpak update"

alias grubup="sudo update-grub"

alias ssh="TERM=xterm-color ssh"

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'

alias code='codium'

alias l='eza -1'                                                                    # nothing special
alias ls='eza -al --color=always --group-directories-first --icons'                 # preferred listing
alias la='eza -a --color=always --group-directories-first --icons'                  # all files and dirs
alias ll='eza -laB --sort name --time-style long-iso --git --icons --color=always'  # long format
alias lt='eza -aT --color=always --group-directories-first --icons'                 # tree listing
alias l.="eza -a | egrep '^\.'"                                                     # show only dotfiles

alias web-ip="curl ifconfig.me"

starship init fish | source
zoxide init --cmd cd fish | source
mcfly init fish | source

fastfetch
EOF

echo "SETUVAR --export JAVA_HOME:/home/${USER}/kits/dev/jdk" >> /home/${USER}/.config/fish/fish_variables
echo "SETUVAR --export M2_HOME:/home/${USER}/kits/dev/mvn" >> /home/${USER}/.config/fish/fish_variables
echo "SETUVAR fish_greeting:" >> /home/${USER}/.config/fish/fish_variables
echo "SETUVAR fish_user_paths:/home/${USER}/kits/dev/scripts\x1e/home/${USER}/kits/dev/mvn/bin\x1e/home/${USER}/kits/dev/jdk/bin" >> /home/${USER}/.config/fish/fish_variables
}

function install_font() {
	log INFO "Installing font hack-nerd..."
	cd /home/${USER}/.cooking/
	wget -O hack-nerd.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Hack.zip
	unzip hack-nerd.zip
	sudo mkdir -p /usr/local/share/fonts/hack-nerd
	sudo mv *.ttf /usr/local/share/fonts/hack-nerd/
	sudo chown -R root: /usr/local/share/fonts/hack-nerd
	sudo chmod 644 /usr/local/share/fonts/hack-nerd/*
	sudo restorecon -vFr /usr/local/share/fonts/hack-nerd
	sudo fc-cache -v
	cd -
	log SUCC "Installed font hack-nerd."
}

function install_containers() {
log INFO "Installing postgresql as a development container..."
podman pull	docker.io/library/postgres:16-bookworm || log ERROR 'Could not pull postgresql container.' 1
mkdir -p ${HOME}/volumes/dev-postgres/ || log ERROR 'Could not create volume folder.' 1
mkdir -p ${HOME}/.config/containers/systemd/ || log ERROR 'Could not create user systemd folder.' 1
cat >> /home/${USER}/.config/containers/systemd/dev-postgres.container <<'EOF'
[Unit]
Description=PostgreSQL Container for Development
After=local-fs.target network-online.target
Wants=network-online.target

[Container]
Image=docker.io/library/postgres:15-bookworm
AutoUpdate=registry
PublishPort=5432:5432
Volume=%h/volumes/dev-postgres:/var/lib/postgresql/data:Z
Environment=POSTGRES_PASSWORD=postgres

[Service]
Restart=always

[Install]
WantedBy=default.target
EOF
systemctl --user daemon-reload || log ERROR 'Could not daemon-reload.' 1
systemctl --user start dev-postgres || log ERROR 'Could not start postgresql container as a service.' 1
log SUCC "Installed postgresql as a development container."
}

function step3() {
	install_dnf_packages
	install_flatpaks
	install_nvm
	install_sdkman
	install_java_versions
	install_maven_versions
	install_ides
	install_terminal
	customize_bashrc
	customize_fish
	install_font
	install_containers

	log INFO "Cleaning up..."
	rm -rf /home/${USER}/.cooking/
	log INFO "Everything is done!"
	log INFO "To set JAVA or Maven, please read the documentation provided for sdkman: https://sdkman.io/usage#installdefault"
	log INFO "Full log available at /home/${USER}/cook.log"
	log SUCC "Completed! Restarting in 10s ... "
	sleep 10
	reboot
}

function installstep() {
	step$(cat /home/${USER}/.cooking/.step) | tee -a /home/${USER}/cook.log
}

if [ -s /home/${USER}/.cooking/.step ]; then
	installstep
else
	mkdir -p /home/${USER}/.cooking
	printf "1" > /home/${USER}/.cooking/.step
	installstep
fi
