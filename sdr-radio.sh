# Install GNU Radio
sudo add-apt-repository ppa:gnuradio/gnuradio-releases
sudo apt-get update
sudo apt-get install gnuradio

# Install osmo
wget https://downloads.osmocom.org/packages/osmocom:/latest/Debian_11/Release.key
sudo mv Release.key /etc/apt/trusted.gpg.d/osmocom-latest.asc
echo "deb https://downloads.osmocom.org/packages/osmocom:/latest/Debian_11/ ./" | sudo tee /etc/apt/sources.list.d/osmocom-latest.list
sudo apt-get update
sudo apt-get upgrade

