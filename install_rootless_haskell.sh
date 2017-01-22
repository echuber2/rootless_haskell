#!/bin/bash

# Rootless Haskell installer for UIUC EWS users
# Updated 20160122 - Eric Huber
# https://github.com/echuber2/rootless_haskell
# Stack downloader originally based on script by Yury Antonov:
# https://github.com/yantonov/install-ghc/blob/master/ubuntu/install-ghc-ubuntu.md

echo " "
echo "     Rootless Haskell installer for EWS by Eric Huber"
echo "     ------------------------------------------------"
echo " based on a gist by Yury Antonov -- please review the script source"
echo " "
sleep 3
echo "Warning -- this process may take up to one hour to complete!"
echo "Also, it will use over 2 gigabytes of your storage space on EWS."
echo "If a permanent Stack/GHC module is added later, you should clear"
echo "out these files. (Another note will be displayed at the end of"
echo "the install process.)"
echo " "
sleep 3
echo "If you run this over SSH you may get disconnected with a timeout."
echo "The script uses a keepalive functionality to try to avoid that."
echo "I recommend running it in person on a lab computer, if possible."
echo " "
echo "Beginning in 60 seconds... press ctrl-C NOW to cancel."
echo " "
sleep 60

ROOTLESS_HASKELL_FN="${HOME}/rootless_haskell.rc"
echo " " > ${ROOTLESS_HASKELL_FN}

DOWNLOADS_DIR=$HOME/Downloads

# ---- Install GMP

GMP_VERSION="gmp-6.1.2"
GMP_ARCHIVE="${GMP_VERSION}.tar.xz"
GMP_URL="https://gmplib.org/download/gmp/${GMP_ARCHIVE}"

mkdir -p $DOWNLOADS_DIR

cd $DOWNLOADS_DIR

wget "$GMP_URL"
tar -xvf "$GMP_ARCHIVE"

cd $GMP_VERSION

./configure --prefix="${HOME}/.gmp"
make
#make check
make install

cd "${HOME}/.gmp/lib"
rm libgmp.so
rm libgmp.so.10
ln -s /lib64/libgmp.so.10 libgmp.so
ln -s /lib64/libgmp.so.10 libgmp.so.10

# Environment setup file
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${HOME}/.gmp/lib"
echo 'export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${HOME}/.gmp/lib"' >> "${HOME}/rootless_haskell.rc"

cd $DOWNLOADS_DIR
rm -rf $GMP_VERSION
rm $GMP_ARCHIVE

# ---- Install Stack

STACK_VERSION="1.3.2"
STACK_ARCHITECTURE="x86_64"
STACK_PLATFORM="linux"
STACK_DIST_FILENAME="stack-$STACK_VERSION-$STACK_PLATFORM-$STACK_ARCHITECTURE.tar.gz"
STACK_DIST_UNZIPPED_DIR="stack-$STACK_VERSION-$STACK_PLATFORM-$STACK_ARCHITECTURE"
STACK_DIST_URL="https://www.stackage.org/stack/$STACK_PLATFORM-$STACK_ARCHITECTURE"
STACK_INSTALL_DIR="$HOME/stack/bin"
STACK_TARGET_DIR="stack-$STACK_VERSION"

mkdir -p $DOWNLOADS_DIR
mkdir -p $STACK_INSTALL_DIR

cd $DOWNLOADS_DIR

curl -L -o $STACK_DIST_FILENAME $STACK_DIST_URL
tar xvfz $STACK_DIST_FILENAME

# (I don't think this part is necessary currently.)
# in case of error like this:
#curl: (77) error setting certificate verify locations: CAfile:
# /etc/pki/tls/certs/ca-bundle.crt CApath:
# ...
# create ~/.curlrc file
# and put these lines in it
# capath=/etc/ssl/certs/
# cacert=/etc/ssl/certs/ca-certificates.crt

# move to home development dir
rm -rf $STACK_INSTALL_DIR/$STACK_TARGET_DIR
mv $STACK_DIST_UNZIPPED_DIR $STACK_INSTALL_DIR/$STACK_TARGET_DIR

cd $STACK_INSTALL_DIR

# symlink
pwd
rm -f stack
ln -s `pwd`/$STACK_TARGET_DIR stack

# add to PATH environment
export STACK_HOME=$STACK_INSTALL_DIR/stack
export PATH=$STACK_HOME:$PATH

# clean up
cd $DOWNLOADS_DIR
rm -rf stack-$STACK_VERSION*

# ---- Create environment setup file

cd $HOME
echo "export STACK_HOME=${STACK_HOME}" >> "${ROOTLESS_HASKELL_FN}"
echo 'export PATH=${STACK_HOME}:${PATH}' >> "${ROOTLESS_HASKELL_FN}"

# if [[ $(cat "${HOME}/.profile" | grep "${ROOTLESS_HASKELL_FN}" | wc -l) -lt 1 ]]; then
# 	echo "source ${ROOTLESS_HASKELL_FN}" >> "${HOME}/.profile"
# fi

SPIN_FILE="${HOME}/.rootless_haskell_installing"
echo "delete me" > ${SPIN_FILE}

keepalive_msg () {

	COUNTER=0

	while true; do
		if [ -f ${SPIN_FILE} ]; then
			if [ $COUNTER -gt 30 ]; then
				return 1
			fi
			if [ $(( $COUNTER % 2 )) -eq 0 ]; then
				echo "Working..."
			else
				echo "Working......"
			fi
			sleep 30
			if [ ! -f ${SPIN_FILE} ]; then
				return 0
			fi
			sleep 30
			if [ ! -f ${SPIN_FILE} ]; then
				return 0
			fi
			sleep 30
			if [ ! -f ${SPIN_FILE} ]; then
				return 0
			fi
			sleep 30
			((COUNTER++))
		else
			return 0
		fi
	done
	
}


echo " "
echo "Stack installer about to begin -- it will run twice."
sleep 2
echo "It is normal for it to report an error the first time."
sleep 2
echo "This will take 30-45 minutes. Beginning in 10 seconds..."
echo " "
sleep 10

keepalive_msg &
child_pid=$!

ROOTLESS_GMP="${HOME}/.gmp/lib"

echo " " > "${HOME}/stacklog.txt"

echo " " >> "${HOME}/stacklog.txt"
uptime >> "${HOME}/stacklog.txt"
echo "Beginning stack install" >> "${HOME}/stacklog.txt"
stack setup --extra-lib-dirs="${ROOTLESS_GMP}"

ROOTLESS_GHC_SETTINGS_DIR="${HOME}/.stack/programs/x86_64-linux/ghc-8.0.1/lib/ghc-8.0.1"
mkdir -p "${ROOTLESS_GHC_SETTINGS_DIR}"
GHC_EXTRA_LIBS_SETTINGS="[(\"GCC extra via C opts\", \" -fwrapv -fno-builtin\"),  (\"C compiler command\", \"/usr/bin/gcc\"),  (\"C compiler flags\", \" -fno-stack-protector\"),  (\"C compiler link flags\", \"-L${ROOTLESS_GMP}\"),  (\"Haskell CPP command\",\"/usr/bin/gcc\"),  (\"Haskell CPP flags\",\"-E -undef -traditional -L${ROOTLESS_GMP}\"),  (\"ld command\", \"/usr/bin/ld\"),  (\"ld flags\", \"-L ${ROOTLESS_GMP}\"),  (\"ld supports compact unwind\", \"YES\"),  (\"ld supports build-id\", \"YES\"),  (\"ld supports filelist\", \"NO\"),  (\"ld is GNU ld\", \"YES\"),  (\"ar command\", \"/usr/bin/ar\"),  (\"ar flags\", \"q\"),  (\"ar supports at file\", \"YES\"),  (\"touch command\", \"touch\"),  (\"dllwrap command\", \"/bin/false\"),  (\"windres command\", \"/bin/false\"),  (\"libtool command\", \"libtool\"),  (\"perl command\", \"/usr/bin/perl\"),  (\"cross compiling\", \"NO\"),  (\"target os\", \"OSLinux\"),  (\"target arch\", \"ArchX86_64\"),  (\"target word size\", \"8\"),  (\"target has GNU nonexec stack\", \"False\"),  (\"target has .ident directive\", \"False\"),  (\"target has subsections via symbols\", \"False\"),  (\"Unregisterised\", \"NO\"),  (\"LLVM llc command\", \"llc\"),  (\"LLVM opt command\", \"opt\")  ]"
echo ${GHC_EXTRA_LIBS_SETTINGS} > "${ROOTLESS_GHC_SETTINGS_DIR}/settings"
mkdir -p "${HOME}/.stack/"
echo " " >> "${HOME}/.stack/config.yaml"
echo "extra-lib-dirs: [ ${HOME}/.gmp/lib ]" >> "${HOME}/.stack/config.yaml"

echo " " >> "${HOME}/stacklog.txt"
uptime >> "${HOME}/stacklog.txt"
echo "2nd round stack install" >> "${HOME}/stacklog.txt"

echo " "
echo "Fixing link libraries now..."
stack -v setup --extra-lib-dirs="${ROOTLESS_GMP}"

echo " " >> "${HOME}/stacklog.txt"
uptime >> "${HOME}/stacklog.txt"
echo "finished stack install" >> "${HOME}/stacklog.txt"

rm -f ${SPIN_FILE}
kill $child_pid
wait

echo "================================================================="
echo "                                       (Hopefully that worked?)"
echo "  "
echo "Stack install complete. The EWS environment must be manually"
echo "initalized like this before each terminal session:"
echo "  "
echo "  source ~/rootless_haskell.rc"
echo "  "
# echo "(This should be done for you automatically if you log in again.)"
echo 'Please use the above command now. Then you can move to your working'
echo 'directory and do "stack build" and "stack test". (The FIRST run of'
echo '"stack test" will install some more files for a few minutes.)'
echo ' '
echo 'Again, note: this installer used up >2GB of your storage on EWS.'
echo "If you don't need rootless Haskell any more, CAREFULLY delete"
echo 'these paths created in your home directory:'
echo " .gmp  .stack  stack"
echo " "
