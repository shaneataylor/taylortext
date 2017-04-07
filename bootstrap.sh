#!/bin/bash 
set -e
#
# Bootstrap script - downloads and unpacks necessary tools, installs DITA Open Toolkit & plugins
#
# REQUIRES: curl
#           tar
#           git
#           java (7 or later)
#           zip (only for plugin development with -zip option)  
#

export ANT_ARGS="-logger org.apache.tools.ant.DefaultLogger" # don't use XML logging if set by build

ORIG_CWD=$PWD
ORIG_PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/git/bin

# cleanup if the script fails
function cleanup()
{
    EXITCODE=$?
    echo -e "EXIT CODE ${EXITCODE}"
    if [ ! "$ORIG_CWD" = "$PWD" ]; then
        cd $ORIG_CWD
    fi
    exit ${EXITCODE}
}

trap cleanup SIGINT SIGTERM EXIT;

# fetches a package from a url
#
# Usage: 
#    fetchcmd [URL] [OUTFILE]
#
# Parameters:
#    URL - the url to pull from
#    OUTFILE - what to name the downloaded file
#
function fetchcmd()
{
    URL=$1
    OUTFILE=$2
    
    if [ ! -f "deps/downloads/$OUTFILE" ]; then
        # IMPORTANT:  --no-include necessary to keep header from being saved in output file 
        curl -q --no-include -L --output deps/downloads/$OUTFILE $URL
        CURL_EXIT=$?
        return $CURL_EXIT
    fi
}

# Unpacks an archive file
#
# Usage:
#    unpack FILE DEST PKG_EXT
#
# Parameters:
#    FILE - the archive to unpack
#    DEST - the name of the directory it will go into
#    PKG_EXT - the filename extension of the package: .tar.gz or .zip
function unpack()
{
    FILE=$1
    DEST=$2
    PKG_EXT=$3
    
    if [ -d "deps/$DEST" ]; then
        # clean install
        rm -Rf "deps/$DEST"
    fi 
    if [ "$PKG_EXT" = ".zip" ]; then
        unzip -q "deps/downloads/${FILE}${PKG_EXT}" -d deps
    else
        tar -C deps -zxf "deps/downloads/${FILE}${PKG_EXT}" 
    fi
}

function set_dita_env()
{
    DITA_OT_VERSION=$1
    DITA_DIR="${ORIG_CWD}/deps/DITA-OT${DITA_OT_VERSION}"
    
        export ANT_HOME="$DITA_DIR"/bin
        export PATH="$ORIG_PATH:$ANT_HOME"
        unset CLASSPATH
}

function uninstall_plugin()
{
    PLUGIN=$1
    DITA_OT_VERSION=$2
    DITA_DIR="${ORIG_CWD}/deps/DITA-OT${DITA_OT_VERSION}"
    set_dita_env "${DITA_OT_VERSION}"
    if [ -d "$DITA_DIR/plugins/$PLUGIN" ]; then
        echo -e "\nUninstalling the $PLUGIN plugin for ${DITA_OT_VERSION}..."
               $DITA_DIR/bin/dita -uninstall $PLUGIN
        fi
}
function install_plugin()
{
    PLUGIN=$1
    DITA_OT_VERSION=$2
    DITA_DIR="${ORIG_CWD}/deps/DITA-OT${DITA_OT_VERSION}"
    set_dita_env "${DITA_OT_VERSION}"
    uninstall_plugin $PLUGIN $DITA_OT_VERSION
    echo -e "\nInstalling the $PLUGIN plugin for ${DITA_OT_VERSION}..."
        $DITA_DIR/bin/dita -install dita_ot_plugins/$PLUGIN.zip
}

function main()
{
    mkdir -p deps/downloads
    
    fetchcmd "http://downloads.sourceforge.net/sourceforge/ant-contrib/ant-contrib/1.0b3/ant-contrib-1.0b3-bin.tar.gz" "ant-contrib-1.0b3-bin.tar.gz"
    unpack "ant-contrib-1.0b3-bin" "ant-contrib" ".tar.gz"
    
    fetchcmd "https://github.com/dita-ot/dita-ot/releases/download/2.4.5/dita-ot-2.4.5.zip" "dita-ot-2.4.5.zip"
    unpack "dita-ot-2.4.5" "dita-ot-2.4.5" ".zip"
    DITA_DIR="${ORIG_CWD}/deps/dita-ot-2.4.5"
    
    if [ -f "$DITA_DIR"/tools/ant/bin/ant ] && [ ! -x "$DITA_DIR"/tools/ant/bin/ant ]; then
        chmod +x "$DITA_DIR"/tools/ant/bin/ant
    fi
    $DITA_DIR/bin/dita -install https://github.com/shaneataylor/ditasearch/archive/1.1.zip
    
#    install_plugin com.taylortext.resume $QS_OT_VERSION

}
main
