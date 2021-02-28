# Install HomeBrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
# Install Tesseract
brew install imagemagick
brew install tesseract
brew install tesseract-lang
# Install Miniconda
# If using zsh shell, then run "/opt/miniconda3/condabin/conda init zsh" after running the brew command
brew install --cask miniconda # Add Prefix and then export the bin folder in PATH, or run conda init "$(basename "${SHELL}")"



# -------------- Bash Profile ---------------------
export PATH=/bin:/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:$PATH

# Add Sublime Text to Path
export PATH="/Applications/Sublime Text.app/Contents/SharedSupport/bin":$PATH

# Add Flutter Path
export PATH="/Users/codesteller/Apsoft/flutter/bin":$PATH

# Add android Path
export ANDROID_HOME=/Users/$USER/Library/Android/sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
PATH="$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools"

# Add Alias
alias ll="ls -al"

function env_conda()	{
	# >>> conda initialize >>>
	# !! Contents within this block are managed by 'conda init' !!
	__conda_setup="$('/Users/codesteller/Apsoft/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
	if [ $? -eq 0 ]; then
	    eval "$__conda_setup"
	else
	    if [ -f "/Users/codesteller/Apsoft/miniconda3/etc/profile.d/conda.sh" ]; then
	        . "/Users/codesteller/Apsoft/miniconda3/etc/profile.d/conda.sh"
	    else
	        export PATH="/Users/codesteller/Apsoft/miniconda3/bin:$PATH"
	    fi
	fi
	unset __conda_setup
	# <<< conda initialize <<<
}


function mldev()	{
	env_conda
	conda activate py38ml
}

