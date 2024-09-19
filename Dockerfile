# THE BASE IMAGE
ARG LAB_BASE=quay.io/jupyter/base-notebook:lab-4.2.5

# minimal, default (empty), full 
ARG ENV

## GENERAL


#######################
# BASE BUILDER        #
#######################
FROM ubuntu AS builder_base
RUN apt-get update \
  && apt-get install -y curl fontconfig git wget zsh \
  && rm -rf /var/lib/apt/lists/*

###############
# ZSH         #
###############
FROM builder_base AS builder_zsh
RUN useradd -ms /bin/bash jovyan
USER jovyan
WORKDIR /home/jovyan

COPY zsh/initzsh.sh /tmp/initzsh.sh
RUN echo -e "\e[93m**** Configure a nice zsh environment ****\e[38;5;241m" && \
        git clone --recursive https://github.com/sorin-ionescu/prezto.git "$HOME/.zprezto" && \
        zsh -c /tmp/initzsh.sh && \
        sed -i -e "s/zstyle ':prezto:module:prompt' theme 'sorin'/zstyle ':prezto:module:prompt' theme 'powerlevel10k'/" ${HOME}/.zpreztorc && \
        echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$HOME"/.zshrc && \
        echo "PATH=/opt/bin:${HOME}/bin:${PATH}" >> "$HOME"/.zshrc && \
        wget https://raw.githubusercontent.com/docker/cli/master/contrib/completion/zsh/_docker -O "$HOME"/.zprezto/modules/completion/external/src/_docker

########### MAIN IMAGE ###########
FROM ${LAB_BASE}

ARG ENV=default

ARG TARGETPLATFORM
ARG BUILDPLATFORM

# Persistent data directory (user working directory)
ENV WORK_DIR=/home/jovyan/work
# Directory for given materials (git_provider/account/repo/...).
ENV MATERIALS_DIR=$WORK_DIR/materials
# Directory to mounts notebooks
ENV NOTEBOOKS_DIR=$WORK_DIR/local

ENV PATH=${HOME}/bin:/opt/bin:${PATH}

USER root

RUN echo "I am running on $BUILDPLATFORM, building for $TARGETPLATFORM" && \
    npm config set registry https://nexus.ebruno.fr/repository/npm-proxy && \
    mkdir -p "$MATERIALS_DIR" "$NOTEBOOKS_DIR" && \
    chown -R ${NB_UID}:${NB_GID} "$MATERIALS_DIR" "$NOTEBOOKS_DIR"

# Set dirs and files that have to exist in $HOME (not persistent)
# create and link them in $HOME/work (to become persistent) after notebook start
# usefull for config files like .gitconfig, .ssh, ...
ENV NEEDED_WORK_DIRS=.ssh
ENV NEEDED_WORK_FILES=.gitconfig


# Install PlantUML
ENV PLANTUML_VERSION=v1.2024.7
ENV PLANTUML_JAR=/usr/share/plantuml/plantuml.jar
RUN mkdir -p /usr/share/plantuml && \
   ln -s "$PLANTUML_JAR" /usr/local/bin/
ADD "https://github.com/plantuml/plantuml/releases/download/${PLANTUML_VERSION}/plantuml-${PLANTUML_VERSION#?}.jar" "${PLANTUML_JAR}" 

# Install needed apt packages
COPY Artefacts/apt_packages* /tmp/
RUN apt-get update && \
	  apt-get install -qq --yes --no-install-recommends \
		  $(cat /tmp/apt_packages_minimal|grep --invert-match "^#") \
      $(if [ "${ENV}" != "minimal" ]; then cat /tmp/apt_*|grep --invert-match "^#"; fi) && \ 
    rm -rf /var/lib/apt/lists/*

# Install Quarto
ARG QUARTO_VERSION=1.5.57
RUN wget --no-verbose --output-document=/tmp/quarto.deb https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-$(echo $TARGETPLATFORM|cut -d '/' -f 2).deb && \
  dpkg -i /tmp/quarto.deb && \
  quarto add quarto-ext/include-code-files --no-prompt && \
  rm /tmp/quarto.deb

# For window manager remote access via VNC
# Install TurboVNC (https://github.com/TurboVNC/turbovnc)
ARG TURBOVNC_VERSION=3.0.3
RUN if [[ "${ENV}" != "minimal" ]] ; then \
      if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
	  	  ARCH_LEG=x86_64; \
	  	  ARCH=amd64; \
	    elif [ "$TARGETPLATFORM" = "linux/arm64/v8" ] || [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
  	  	ARCH_LEG=aarch64; \
	    	ARCH=arm64; \
	    else \
	  	  ARCH_LEG=amd64; \
	  	  ARCH=amd64; \
	    fi && \
      wget --no-verbose --output-document=turbovnc.deb \
        "https://sourceforge.net/projects/turbovnc/files/${TURBOVNC_VERSION}/turbovnc_${TURBOVNC_VERSION}_${ARCH}.deb/download" && \
      dpkg -i ./turbovnc.deb && ln -s /opt/TurboVNC/bin/* /usr/local/bin/ && rm ./turbovnc.deb && \
      # remove light-locker to prevent screen lock
      apt-get remove -y -q light-locker ; \
    fi

## ZSH
COPY --chown=$NB_UID:$NB_GID zsh/p10k.zsh $HOME/.p10k.zsh 
RUN --mount=type=bind,from=builder_zsh,source=/home/jovyan,target=/user \
    cp -a /user/.z* ${HOME} && \
    fix-permissions ${HOME}/.z* ${HOME}/.p10k.zsh
# Preinstall gitstatusd
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
		ARCH_LEG=x86_64; \
		ARCH=amd64; \
	elif [ "$TARGETPLATFORM" = "linux/arm64/v8" ] || [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
		ARCH_LEG=aarch64; \
		ARCH=arm64; \
	else \
		ARCH_LEG=amd64; \
		ARCH=amd64; \
	fi && \
    mkdir -p /home/jovyan/.cache/gitstatus && \ 
    curl -sL "https://github.com/romkatv/gitstatus/releases/download/v1.5.4/gitstatusd-linux-${ARCH_LEG}.tar.gz" | \
      tar --directory="/home/jovyan/.cache/gitstatus" -zx

## DOCKER
# Install docker client binaries
COPY --from=docker:cli /usr/local/bin/docker* /usr/local/bin/
COPY --from=docker/buildx-bin /buildx /usr/libexec/docker/cli-plugins/docker-buildx
COPY --from=docker/compose-bin /docker-compose /usr/libexec/docker/cli-plugins/docker-compose

## PYTHON_DEPENDENCIES
COPY Artefacts/environment.yml /tmp
COPY Artefacts/requirements.txt /tmp

# Installs Python packages and codeserver (if needed)
RUN echo -e "\e[93m***** Install Python packages ****\e[38;5;241m" && \
        pip install -r /tmp/requirements.txt && \
        mamba env update -p ${CONDA_DIR} -f /tmp/environment.yml && \
        echo -e "\e[93m**** Install Shell Kernels for Jupyter ****\e[38;5;241m" && \
            python3 -m zsh_jupyter_kernel.install --sys-prefix && \
            python3 -m bash_kernel.install --sys-prefix

## CODE SERVER
ARG CODE_SERVER_VERSION=4.92.2
ENV CODESERVER_DIR=/opt/codeserver
# Extension are writable for users but not persistent
ENV CODESERVEREXT_DIR=${HOME}/.local/share/code-server/extensions
# Data are persistent and writable
ENV CODE_WORKINGDIR=${WORK_DIR}
ENV CODESERVERDATA_DIR=${CODE_WORKINGDIR}/.config/codeserver/data
ENV CODE_SERVER_CONFIG=${CODE_WORKINGDIR}/.config/code-server/config.yaml

COPY Artefacts/codeserver_extensions /tmp/

RUN if [[ "${ENV}" != "minimal" ]] ; then \
        echo -e "\e[93m**** Installs Code Server Web ****\e[38;5;241m" && \
                curl -fsSL https://code-server.dev/install.sh | \
                  sh -s -- --prefix=/opt --method=standalone --version=${CODE_SERVER_VERSION} && \
                mkdir -p ${CODESERVERDATA_DIR} &&\
                mkdir -p ${CODESERVEREXT_DIR} && \
                PATH=/opt/bin:${PATH} code-server \
                	--user-data-dir ${CODESERVERDATA_DIR}\
                	--extensions-dir ${CODESERVEREXT_DIR} \
                    $(cat /tmp/codeserver_extensions|sed 's/./--install-extension &/') ; \
        chown -R ${NB_UID}:${NB_GID} ${CODESERVEREXT_DIR} ; \
    fi

# Enable persistant conda env
COPY --chown=$NB_UID:$NB_GID condarc /home/jovyan/.condarc
COPY --chown=$NB_USER:$NB_GID conda-activate.sh /home/$NB_USER/
COPY configs/jupyter_condaenv_config.json /tmp
RUN [[ ! -f /home/jovyan/.jupyter/jupyter_config.json ]] && touch /home/jovyan/.jupyter/jupyter_config.json ; \
	cat /tmp/jupyter_condaenv_config.json >> /home/jovyan/.jupyter/jupyter_config.json && \
  echo "source /opt/conda/bin/activate base" >> ${HOME}/.zshrc && \
  chown ${NB_UID}:${NB_GID} ${HOME}/.zshrc

# Configure nbgrader
COPY nbgrader_config.py /etc/jupyter/nbgrader_config.py

RUN mkdir -p ${HOME}/.config ${HOME}/bin ${HOME}/.local ${HOME}/.cache ${HOME}/.ipython ${HOME}/.TinyTeX &&\
    chown -R  ${NB_UID}:${NB_GID} \
      ${HOME}/bin ${HOME}/.config \
      ${HOME}/.local ${HOME}/.cache \
      ${HOME}/.ipython ${HOME}/.TinyTeX

# Install Chromium from debian
#RUN apt-get update && \
#  apt-get install -qq --yes --no-install-recommends gnupg debian-archive-keyring && \
#  apt-key add /usr/share/keyrings/debian-archive-keyring.gpg && \
#  rm -rf /var/lib/apt/lists/*
#COPY chromium/debian-for-nosnaps.list /etc/apt/sources.list.d/debian-for-nosnaps.list
#COPY chromium/debian-for-nosnaps-preferences /etc/apt/preferences.d/debian-for-nosnaps
#RUN apt-get update && \
#  apt-get install --yes --no-install-recommends chromium chromium-sandbox  && \
#  rm -rf /var/lib/apt/lists/*

#RUN apt-get update && \
#  apt-get install -y chromium && \
#  rm -rf /var/lib/apt/lists/* && \
#  ln -s `which chromium` ${HOME}/.local/bin/chromium-browser

RUN mkdir -p /home/jovyan/.local/share/jupyter && \
    chown -R ${NB_UID}:${NB_GID} /home/jovyan/.local/share/jupyter

USER $NB_USER

# Tiny TeX installation
COPY Artefacts/TeXLive /tmp/

ENV TEXDIR=${HOME}/.TinyTeX
ENV TINYTEX_INSTALLER="install-unix"
ENV TINYTEX_VERSION=2024.09
ENV TINYTEX_URL="https://github.com/rstudio/tinytex-releases/releases/download/v$TINYTEX_VERSION/$TINYTEX_INSTALLER-v$TINYTEX_VERSION"

RUN OSNAME=$(uname) && \
    echo "OSNAME=$OSNAME" && \
    OSTYPE=$([ -x "$(command -v bash)" ] && bash -c 'echo $OSTYPE') && \
    echo "OSTYPE=$OSTYPE" && \
    echo "TINYTEX_URL=$TINYTEX_URL" && \
    echo "Arch=$(uname -m)" && \
    echo "TEXDIR=$TEXDIR" && \
    export CTAN_REPO="https://distrib-coffee.ipsl.jussieu.fr/pub/mirrors/ctan/systems/texlive/tlnet" && \
    export PATH=${TEXDIR}/bin:${PATH} && \
    if [ $OSNAME != 'Linux' -o $(uname -m) != 'x86_64' -o "$OSTYPE" != 'linux-gnu' ]; then \
      TINYTEX_INSTALLER="install-unix"; \
    fi ; \
    if [ $TINYTEX_INSTALLER != 'install-unix' ]; then \
      echo "Downloading prebuilt TinyTeX package for this operating system ${OSTYPE}." &&\
      wget --no-verbose --retry-connrefused --progress=dot:giga -O TinyTeX.tar.gz ${TINYTEX_URL}.tar.gz && \
      tar xf TinyTeX.tar.gz -C $(dirname $TEXDIR) &&\
      rm TinyTeX.tar.gz ;\
   else \
      echo "We do not have a prebuilt TinyTeX package for this operating system ${OSTYPE}." &&\
      echo "I will try to install from source for you instead." &&\
      wget --no-verbose --retry-connrefused -O ${TINYTEX_INSTALLER}.tar.gz ${TINYTEX_URL}.tar.gz &&\
      tar xf ${TINYTEX_INSTALLER}.tar.gz &&\
      pwd && \
      ls && \
      ./install.sh &&\
      ls texlive &&\
      mkdir -p $TEXDIR &&\
      mv texlive/* $TEXDIR &&\
      rm -r texlive ${TINYTEX_INSTALLER}.tar.gz install.sh ;\
    fi 
RUN export PATH=$(echo ${HOME}/.TinyTeX/bin/*):${PATH} && \
    ls /home/jovyan/.TinyTeX/bin && \
    tlmgr option repository $CTAN_REPO && \
    tlmgr paper a4 && \
#    tlmgr update --self --all && \
    tlmgr install --verify-repo=none $(cat /tmp/TeXLive|grep --invert-match "^#") && \
#    fmtutil -sys --all && \
    chown -R ${NB_UID}:${NB_GID} ${HOME}/.TinyTeX 

# Install some files in $HOME
COPY --chown=$NB_UID:$NB_GID home/ /home/jovyan/

RUN echo -e "\e[93m**** Update Jupyter config ****\e[38;5;241m" && \
        mkdir -p ${HOME}/jupyter_data && \
        jupyter lab --generate-config && \
        sed -i -e '/c.ServerApp.root_dir =/ s/= .*/= "\/home\/jovyan\/work"/' \
            -e "s/# \(c.ServerApp.root_dir\)/\1/" \ 
            -e '/c.ServerApp.disable_check_xsrf =/ s/= .*/= True/' \
            -e 's/# \(c.ServerApp.disable_check_xsrf\)/\1/' \
            -e '/c.ServerApp.data_dir =/ s/= .*/= "\/home\/jovyan\/jupyter_data"/' \
            -e '/c.ServerApp.db_file =/ s/= .*/= ":memory:"/' \
            -e '/c.JupyterApp.log_level =/ s/= .*/= "DEBUG"/' \
            -e "/c.ServerApp.terminado_settings =/ s/= .*/= { 'shell_command': ['\/bin\/zsh'] }/" \
            -e 's/# \(c.ServerApp.terminado_settings\)/\1/' \ 
        ${HOME}/.jupyter/jupyter_lab_config.py 

# Sets the jupyter proxy for codeserver
COPY code-server/jupyter_codeserver_config.py /tmp/
COPY --chown=$NB_USER:$NB_GID code-server/icons $HOME/.jupyter/icons
RUN if [[ "${ENV}" != "minimal" ]] ; then \
    [[ ! -f /home/jovyan/.jupyter/jupyter_config.py ]] && touch /home/jovyan/.jupyter/jupyter_config.py ; \
	  cat /tmp/jupyter_codeserver_config.py >> /home/jovyan/.jupyter/jupyter_config.py ; \
  fi 

# Copy scripts that should be executed before notebook start
# Files creation/setup in persistant space.
# Git client default initialisation
COPY before-notebook/ /usr/local/bin/before-notebook.d/

# Generate 
COPY versions/ /versions/
COPY --chown=$NB_UID:$NB_GID README.md ${HOME}/
RUN echo "## Software details" >> ${HOME}/README.md && \
    echo "" >> ${HOME}/README.md ; \
    for versionscript in $(ls -d /versions/*) ; do \
      echo "Executing ($versionscript)"; \
      echo "" >> ${HOME}/README.md ; \
      eval "$versionscript" 2>/dev/null >> ${HOME}/README.md ; \
    done

WORKDIR "${WORK_DIR}"

# Configure container startup adding ssh-agent
CMD ["ssh-agent","start-notebook.sh"]
