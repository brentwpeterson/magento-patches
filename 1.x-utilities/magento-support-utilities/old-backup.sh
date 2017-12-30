#!/bin/bash

################################################################################
# FUNCTIONS
################################################################################

# 1. Check required system tools
_check_installed_tools() {
    local missed=""

    until [ -z "$1" ]; do
        type -t $1 >/dev/null 2>/dev/null
        if (( $? != 0 )); then
            missed="$missed $1"
        fi
        shift
    done

    echo $missed
}

# 2. Selftest for checking tools which will used
checkTools() {
    REQUIRED_UTILS='nice sed tar mysqldump head gzip getopt lsof'
    MISSED_REQUIRED_TOOLS=`_check_installed_tools $REQUIRED_UTILS`
    if (( `echo $MISSED_REQUIRED_TOOLS | wc -w` > 0 ));
    then
        echo -e "Error! Some required system tools, that are utilized in this bash script, are not installed:\n$MISSED_REQUIRED_TOOLS"
        exit 1
    fi
}

# 3. Create code dump function
createCodeDump() {
    # Content of file archive
    DISTR="
    app
    downloader
    errors
    includes
    js
    lib
    pkginfo
    shell
    skin
    .htaccess
    cron.php
    get.php
    index.php
    install.php
    mage
    *.patch
    *.sh"

    # Create code dump
    DISTRNAMES=
    for ARCHPART in $DISTR; do
        if [ -r "$MAGENTOROOT$ARCHPART" ]; then
            DISTRNAMES="$DISTRNAMES $MAGENTOROOT$ARCHPART"
        fi
    done
    if [ -n "$DISTRNAMES" ]; then
        echo nice -n 15 tar -czhf $CODEFILENAME $DISTRNAMES
        nice -n 15 tar -czhf $CODEFILENAME $DISTRNAMES
    fi
}

# 4. Create DB dump function
createDbDump() {
    # Set path of local.xml
    LOCALXMLPATH=${MAGENTOROOT}app/etc/local.xml

    # Get mysql credentials from local.xml
    getLocalValue() {
        PARAMVALUE=`sed -n "/<resources>/,/<\/resources>/p" $LOCALXMLPATH | sed -n -e "s/.*<$PARAMNAME><!\[CDATA\[\(.*\)\]\]><\/$PARAMNAME>.*/\1/p" | head -n 1`
    }

    # Connection parameters
    DBHOST=
    DBUSER=
    DBNAME=
    DBPASSWORD=
    TBLPRF=

    # Include DB logs option
    SKIPLOGS=1

    # Ignored table names
    IGNOREDTABLES="
    core_cache
    core_cache_option
    core_cache_tag
    core_session
    log_customer
    log_quote
    log_summary
    log_summary_type
    log_url
    log_url_info
    log_visitor
    log_visitor_info
    log_visitor_online
    enterprise_logging_event
    enterprise_logging_event_changes
    index_event
    index_process_event
    report_event
    report_viewed_product_index
    dataflow_batch_export
    dataflow_batch_import"

    # Get DB HOST from local.xml
    if [ -z "$DBHOST" ]; then
        PARAMNAME=host
        getLocalValue
        DBHOST=$PARAMVALUE
    fi

    # Get DB USER from local.xml
    if [ -z "$DBUSER" ]; then
        PARAMNAME=username
        getLocalValue
        DBUSER=$PARAMVALUE
    fi

    # Get DB PASSWORD from local.xml
    if [ -z "$DBPASSWORD" ]; then
        PARAMNAME=password
        getLocalValue
        DBPASSWORD=${PARAMVALUE//\"/\\\"}
    fi

    # Get DB NAME from local.xml
    if [ -z "$DBNAME" ]; then
        PARAMNAME=dbname
        getLocalValue
        DBNAME=$PARAMVALUE
    fi

    # Get DB TABLE PREFIX from local.xml
    if [ -z "$TBLPRF" ]; then
        PARAMNAME=table_prefix
        getLocalValue
        TBLPRF=$PARAMVALUE
    fi

    # Check DB credentials for existsing
    if [ -z "$DBHOST" -o -z "$DBUSER" -o -z "$DBNAME" ]; then
        echo "Skip DB dumping due lack of parameters host=$DBHOST; username=$DBUSER; dbname=$DBNAME;";
        exit 0
    fi

    # Set connection params
    if [ -n "$DBPASSWORD" ]; then
        CONNECTIONPARAMS=" -u$DBUSER -h$DBHOST -p\"$DBPASSWORD\" $DBNAME --force --triggers --single-transaction --opt --skip-lock-tables"
    else
        CONNECTIONPARAMS=" -u$DBUSER -h$DBHOST $DBNAME --force --triggers --single-transaction --opt --skip-lock-tables"
    fi

    # Create DB dump
    IGN_SCH=
    IGN_IGN=
    if [ -n "$SKIPLOGS" ] ; then
        for TABLENAME in $IGNOREDTABLES; do
            IGN_SCH="$IGN_SCH $TBLPRF$TABLENAME"
            IGN_IGN="$IGN_IGN --ignore-table='$DBNAME'.'$TBLPRF$TABLENAME'"
        done
    fi

    if [ -z "$IGN_IGN" ]; then
        DBDUMPCMD="nice -n 15 mysqldump $CONNECTIONPARAMS"
    else
        DBDUMPCMD="( nice -n 15 mysqldump $CONNECTIONPARAMS $IGN_IGN ; nice -n 15 mysqldump --no-data $CONNECTIONPARAMS $IGN_SCH )"
    fi

    DBDUMPCMD="$DBDUMPCMD | sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/' | gzip > $DBFILENAME"

    echo ${DBDUMPCMD//"p\"$DBPASSWORD\""/p[******]}

    eval "$DBDUMPCMD"
}

################################################################################
# CODE
################################################################################

# Selftest
checkTools

# Magento folder
MAGENTOROOT=./

# Output path
OUTPUTPATH=$MAGENTOROOT

# Input parameters
MODE=
NAME=

OPTS=`getopt -o m:n:o: -l mode:,name:,outputpath: -- "$@"`

if [ $? != 0 ]
then
    exit 1
fi

eval set -- "$OPTS"

while true ; do
    case "$1" in
        -m|--mode) MODE=$2; shift 2;;
        -n|--name) NAME=$2; shift 2;;
        -o|--outputpath) OUTPUTPATH=$2; shift 2;;
        --) shift; break;;
    esac
done

if [ -n "$NAME" ]; then
    CODEFILENAME="$OUTPUTPATH$NAME.tar.gz"
    DBFILENAME="$OUTPUTPATH$NAME.sql.gz"
else
    # Get random file name - some secret link for downloading from magento instance :)
    MD5=`echo \`date\` $RANDOM | md5sum | cut -d ' ' -f 1`
    DATETIME=`date -u +"%Y%m%d%H%M"`
    CODEFILENAME="$OUTPUTPATH$MD5.$DATETIME.tar.gz"
    DBFILENAME="$OUTPUTPATH$MD5.$DATETIME.sql.gz"
fi

if [ -n "$MODE" ]; then
    case $MODE in
        db) createDbDump; exit 0;;
        code) createCodeDump; exit 0;;
        check) exit 0;;
        *) echo Invalid mode; exit 1;;
    esac
fi

createCodeDump
createDbDump

exit 0
