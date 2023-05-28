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

function install_rtw89() {
	log INFO "Installing realtek drivers for wireless."
	sudo dnf -y install kernel-headers kernel-devel git
	sudo dnf -y group install "C Development Tools and Libraries"
	mkdir -p /home/${USER}/.cooking/rtw89
	git clone https://github.com/lwfinger/rtw89.git /home/${USER}/.cooking/rtw89
	cd /home/${USER}/.cooking/rtw89
	make
	sudo make install
	cd -
	log SUCC "Updated rtw89 wireless."
}

function set_hostmane() {
	log INFO "Setting hostname to ${USER}-work ..."
	sudo hostnamectl set-hostname --static ${USER}-work || log ERROR 'Could not set device name...' 1
	sudo sed -i "s/localhost4.localdomain4/localhost4.localdomain4 ${USER}-work/g" /etc/hosts || log ERROR 'Could not set hosts...' 1
	sudo sed -i "s/localhost6.localdomain6/localhost6.localdomain6 ${USER}-work/g" /etc/hosts || log ERROR 'Could not set hosts...' 1
	log SUCC "Updated hostname. This hostname will be updated after reboot"
}

function step2() {
	# install_rtw89
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
	sudo dnf -y install dnf-plugins-core
	sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
	sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
	sudo dnf -y install vim podman curl wget kitty git git-lfs neofetch exa flatpak brave-browser \
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
		com.vscodium.codium \
		org.eclipse.Java \
		com.jetbrains.IntelliJ-IDEA-Community \
		io.dbeaver.DBeaverCommunity \
		com.anydesk.Anydesk \
		org.libreoffice.LibreOffice \
		org.mozilla.Thunderbird \
		com.discordapp.Discord \
		md.obsidian.Obsidian \
		|| log ERROR 'Could not install flatpak software...' 1
	log SUCC "Installed flatpak packages via Flathub."
}

function install_java_versions() {
	log INFO "Setting up JDKs ..."

	## Java 17
	wget -O /home/${USER}/.cooking/jdk17-adoptium.tar.gz 'https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.7%2B7/OpenJDK17U-jdk_x64_linux_hotspot_17.0.7_7.tar.gz'
	mkdir -p /home/${USER}/kits/dev/jdks/jdk17-adoptium
	tar -xzf /home/${USER}/.cooking/jdk17-adoptium.tar.gz -C /home/${USER}/kits/dev/jdks/jdk17-adoptium --strip-components=1

	wget -O /home/${USER}/.cooking/jdk17-zulu.tar.gz 'https://cdn.azul.com/zulu/bin/zulu17.42.19-ca-jdk17.0.7-linux_x64.tar.gz'
	mkdir -p /home/${USER}/kits/dev/jdks/jdk17-zulu
	tar -xzf /home/${USER}/.cooking/jdk17-zulu.tar.gz -C /home/${USER}/kits/dev/jdks/jdk17-zulu --strip-components=1

	wget -O /home/${USER}/.cooking/jdk17-graalvm.tar.gz 'https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-22.3.1/graalvm-ce-java17-linux-amd64-22.3.1.tar.gz'
	mkdir -p /home/${USER}/kits/dev/jdks/jdk17-graalvm
	tar -xzf /home/${USER}/.cooking/jdk17-graalvm.tar.gz -C /home/${USER}/kits/dev/jdks/jdk17-graalvm --strip-components=1

	## Java 11
	wget -O /home/${USER}/.cooking/jdk11-adoptium.tar.gz 'https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.19%2B7/OpenJDK11U-jdk_x64_linux_hotspot_11.0.19_7.tar.gz'
	mkdir -p /home/${USER}/kits/dev/jdks/jdk11-adoptium
	tar -xzf /home/${USER}/.cooking/jdk11-adoptium.tar.gz -C /home/${USER}/kits/dev/jdks/jdk11-adoptium --strip-components=1

	wget -O /home/${USER}/.cooking/jdk11-zulu.tar.gz 'https://cdn.azul.com/zulu/bin/zulu11.64.19-ca-jdk11.0.19-linux_x64.tar.gz'
	mkdir -p /home/${USER}/kits/dev/jdks/jdk11-zulu
	tar -xzf /home/${USER}/.cooking/jdk11-zulu.tar.gz -C /home/${USER}/kits/dev/jdks/jdk11-zulu --strip-components=1

	wget -O /home/${USER}/.cooking/jdk11-graalvm.tar.gz 'https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-22.3.1/graalvm-ce-java11-linux-amd64-22.3.1.tar.gz'
	mkdir -p /home/${USER}/kits/dev/jdks/jdk11-graalvm
	tar -xzf /home/${USER}/.cooking/jdk11-graalvm.tar.gz -C /home/${USER}/kits/dev/jdks/jdk11-graalvm --strip-components=1

	## Java 8
	wget -O /home/${USER}/.cooking/jdk8-adoptium.tar.gz 'https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u362-b09/OpenJDK8U-jdk_x64_linux_hotspot_8u362b09.tar.gz'
	mkdir -p /home/${USER}/kits/dev/jdks/jdk8-adoptium
	tar -xzf /home/${USER}/.cooking/jdk8-adoptium.tar.gz -C /home/${USER}/kits/dev/jdks/jdk8-adoptium --strip-components=1

	wget -O /home/${USER}/.cooking/jdk8-zulu.tar.gz 'https://cdn.azul.com/zulu/bin/zulu8.68.0.21-ca-jdk8.0.362-linux_x64.tar.gz'
	mkdir -p /home/${USER}/kits/dev/jdks/jdk8-zulu
	tar -xzf /home/${USER}/.cooking/jdk8-zulu.tar.gz -C /home/${USER}/kits/dev/jdks/jdk8-zulu --strip-components=1

	log SUCC "JDKs were added."
}

function install_maven_versions() {
	log INFO "Setting up MVNs ..."

	wget -O /home/${USER}/.cooking/mvn-3.6.tar.gz https://dlcdn.apache.org/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
	mkdir -p /home/${USER}/kits/dev/mavens/mvn-3.6
	tar -xzf /home/${USER}/.cooking/mvn-3.6.tar.gz -C /home/${USER}/kits/dev/mavens/mvn-3.6 --strip-components=1

	wget -O /home/${USER}/.cooking/mvn-3.8.tar.gz https://dlcdn.apache.org/maven/maven-3/3.8.8/binaries/apache-maven-3.8.8-bin.tar.gz
	mkdir -p /home/${USER}/kits/dev/mavens/mvn-3.8
	tar -xzf /home/${USER}/.cooking/mvn-3.8.tar.gz -C /home/${USER}/kits/dev/mavens/mvn-3.8 --strip-components=1

	wget -O /home/${USER}/.cooking/mvn-3.9.tar.gz https://dlcdn.apache.org/maven/maven-3/3.9.2/binaries/apache-maven-3.9.2-bin.tar.gz
	mkdir -p /home/${USER}/kits/dev/mavens/mvn-3.9
	tar -xzf /home/${USER}/.cooking/mvn-3.9.tar.gz -C /home/${USER}/kits/dev/mavens/mvn-3.9 --strip-components=1

	log SUCC "MVNs were added."
}

function install_scripts() {
	log INFO "Installing JDKs and MVNs util scripts..."
	mkdir -p /home/${USER}/kits/dev/scripts
	printf '#!/usr/bin/env bash\nln -snf /home/${USER}/kits/dev/jdks/jdk${1}-${2}/ /home/${USER}/kits/dev/jdk' > /home/${USER}/kits/dev/scripts/set-jdk || log ERROR 'Could not create set-jdk bash script' 1
	chmod +x /home/${USER}/kits/dev/scripts/set-jdk || log ERROR 'Could not make set-jdk bash script executable!' 1
	printf '#!/usr/bin/env bash\nln -snf /home/${USER}/kits/dev/mavens/mvn-${1}/ /home/${USER}/kits/dev/mvn' > /home/${USER}/kits/dev/scripts/set-mvn || log ERROR 'Could not create set-mvn bash script' 1
	chmod +x /home/${USER}/kits/dev/scripts/set-mvn || log ERROR 'Could not make set-mvn bash script executable!' 1
	/home/${USER}/kits/dev/scripts/set-jdk 17 adoptium
	/home/${USER}/kits/dev/scripts/set-mvn 3.8
	log SUCC "Installed scripts and used them to set OpenJDK 17 Adoptium with Maven 3.8."
}

function install_nvm() {
	log INFO "Installing nvm ..."
	wget -O /home/${USER}/.cooking/nvm-install.sh https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh
	bash /home/${USER}/.cooking/nvm-install.sh
	log SUCC "Installed nvm. After reboot we shall set a default NodeJS."
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
}

function customize_bashrc() {
cat >> /home/${USER}/.bashrc <<'EOF'
export JAVA_HOME="/home/${USER}/kits/dev/jdk"
export M2_HOME="/home/${USER}/kits/dev/mvn"
export JDK_MVN_SCRIPTS="/home/${USER}/kits/dev/scripts/"
export PATH="${JAVA_HOME}/bin:${M2_HOME}/bin:${JDK_MVN_SCRIPTS}:${PATH}"

alias upd="sudo dnf update && flatpak update"
alias ssh="TERM=xterm-color ssh"

## Useful aliases
# Replace ls with exa
alias l='exa -1'                                                                    # nothing special
alias ls='exa -al --color=always --group-directories-first --icons'                 # preferred listing
alias la='exa -a --color=always --group-directories-first --icons'                  # all files and dirs
alias ll='exa -laB --sort name --time-style long-iso --git --icons --color=always'  # long format
alias lt='exa -aT --color=always --group-directories-first --icons'                 # tree listing
alias l.="exa -a | egrep '^\.'"                                                     # show only dotfiles

alias code='flatpak run com.vscodium.codium'
alias codium='flatpak run com.vscodium.codium'

eval "$(starship init bash)"

neofetch
EOF
}

function install_font() {
	log INFO "Installing font hack-nerd..."
	wget -O hack-nerd.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.1/Hack.zip
	unzip hack-nerd.zip
	sudo mkdir -p /usr/local/share/fonts/hack-nerd
	sudo mv *.ttf /usr/local/share/fonts/hack-nerd/
	sudo chown -R root: /usr/local/share/fonts/hack-nerd
	sudo chmod 644 /usr/local/share/fonts/hack-nerd/*
	sudo restorecon -vFr /usr/local/share/fonts/hack-nerd
	sudo fc-cache -v
	log SUCC "Installed font hack-nerd."
}

function step3() {
	install_dnf_packages
	install_flatpaks
	install_java_versions
	install_maven_versions
	install_scripts
	install_nvm
	install_terminal
	customize_bashrc
	install_font

	log INFO "Cleaning up..."
	rm -rf /home/${USER}/.cooking/
	log INFO "Everything is done! After a restart, run the following commands:"
	log INFO '$ set-jdk 17 adoptium'
	log INFO '$ set-mvn 3.8'
	log INFO '$ nvm install 18'
	log INFO "After this, JDK and NodeJS sould be ready to use. Besides 17 with adoptium, but there is also JDK 11 and 8 with zulu and graalvm variants."
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
