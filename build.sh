#!/bin/bash
set -e
WORKING_DIR=$PWD

function cleanup()
{
    EXITCODE=$?
    echo -e "\nEXIT CODE ${EXITCODE}"
    echo -e "ENDING BUILD"
    cd $WORKING_DIR
    exit $EXITCODE
}
trap cleanup SIGINT SIGTERM EXIT;

echo "Installing dependencies..."
./bootstrap.sh

echo "Building..."
cd ${WORKING_DIR}
mkdir -p "${WORKING_DIR}/logs"

DITA_DIR="$WORKING_DIR/deps/dita-ot-2.4.5"

# XML Logging
export ANT_OPTS="-Dant.XmlLogger.stylesheet.uri=build_log.xsl" # also unsets anything from previous build
export ANT_ARGS="-logger org.apache.tools.ant.XmlLogger"

"$DITA_DIR"/bin/dita -noclasspath -verbose -propertyfile "taylortext.properties" \
    -Dargs.input.dir="${WORKING_DIR}" -logfile "$WORKING_DIR/logs/taylortext.xml" 

#TEMP
cp ${WORKING_DIR}/style.css ${WORKING_DIR}/out/style.css
cp ${WORKING_DIR}/Shane_Alan_Taylor.pdf ${WORKING_DIR}/out/Shane_Alan_Taylor.pdf

unset ANT_ARGS
