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

sudo apt install libspdlog-dev
git clone https://github.com/osmocom/gr-osmosdr.git
cd gr-osmosdr
mkdir build && cd build
cmake ..

# Install SoapySDR
git clone https://github.com/pothosware/SoapySDR.git
cd SoapySDR
mkdir build
cd build
cmake ..
make -j4
sudo make install
sudo ldconfig #needed on debian systems
SoapySDRUtil --info

