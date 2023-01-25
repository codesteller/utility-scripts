#!/bin/bash

# Setup Brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Sublime, VSCode, Tabby
brew install --cask sublime-text
brew install --cask tabby
brew install --cask visual-studio-code

# Install Mambaforge Python -
