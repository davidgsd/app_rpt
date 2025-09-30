#!/bin/bash
#

EXEC=""
DEBUG=0
VALGRIND=0
UPDATES_EXE=()
UPDATES_LIB=()

#
# From: app_rpt
#

UPDATES_EXE+=("main/asterisk")
UPDATES_EXE+=("utils/simpleusb-tune-menu")
UPDATES_EXE+=("utils/radio-tune-menu")

UPDATES_LIB+=("apps/app_rpt.so")
UPDATES_LIB+=("apps/app_gps.so")
UPDATES_LIB+=("channels/chan_echolink.so")
UPDATES_LIB+=("channels/chan_simpleusb.so")
UPDATES_LIB+=("channels/chan_tlb.so")
UPDATES_LIB+=("channels/chan_usbradio.so")
UPDATES_LIB+=("channels/chan_usrp.so")
UPDATES_LIB+=("channels/chan_voter.so")
UPDATES_LIB+=("res/res_rpt_http_registrations.so")
UPDATES_LIB+=("res/res_usbradio.so")

#
# From: asterisk
#   (and referenced in rpt/modules.conf)
#

UPDATES_LIB+=("apps/app_authenticate.so")
UPDATES_LIB+=("apps/app_dial.so")
UPDATES_LIB+=("apps/app_exec.so")
UPDATES_LIB+=("apps/app_playback.so")
UPDATES_LIB+=("apps/app_sendtext.so")
UPDATES_LIB+=("apps/app_system.so")
UPDATES_LIB+=("apps/app_transfer.so")

UPDATES_LIB+=("channels/chan_dahdi.so")
UPDATES_LIB+=("channels/chan_iax2.so")

UPDATES_LIB+=("codecs/codec_adpcm.so")
UPDATES_LIB+=("codecs/codec_alaw.so")
UPDATES_LIB+=("codecs/codec_a_mu.so")
UPDATES_LIB+=("codecs/codec_dahdi.so")
UPDATES_LIB+=("codecs/codec_g722.so")
UPDATES_LIB+=("codecs/codec_g726.so")
UPDATES_LIB+=("codecs/codec_gsm.so")
UPDATES_LIB+=("codecs/codec_resample.so")
UPDATES_LIB+=("codecs/codec_ulaw.so")

UPDATES_LIB+=("formats/format_g723.so")
UPDATES_LIB+=("formats/format_g726.so")
UPDATES_LIB+=("formats/format_g729.so")
UPDATES_LIB+=("formats/format_gsm.so")
UPDATES_LIB+=("formats/format_h263.so")
UPDATES_LIB+=("formats/format_h264.so")
UPDATES_LIB+=("formats/format_ilbc.so")
#UPDATES_LIB+=("formats/format_mp3.so")
UPDATES_LIB+=("formats/format_pcm.so")
UPDATES_LIB+=("formats/format_sln.so")
UPDATES_LIB+=("formats/format_vox.so")
UPDATES_LIB+=("formats/format_wav_gsm.so")
UPDATES_LIB+=("formats/format_wav.so")

UPDATES_LIB+=("funcs/func_base64.so")
UPDATES_LIB+=("funcs/func_callerid.so")
UPDATES_LIB+=("funcs/func_cdr.so")
UPDATES_LIB+=("funcs/func_channel.so")
UPDATES_LIB+=("funcs/func_curl.so")
UPDATES_LIB+=("funcs/func_cut.so")
UPDATES_LIB+=("funcs/func_db.so")
UPDATES_LIB+=("funcs/func_enum.so")
UPDATES_LIB+=("funcs/func_env.so")
UPDATES_LIB+=("funcs/func_frame_trace.so")
UPDATES_LIB+=("funcs/func_global.so")
UPDATES_LIB+=("funcs/func_groupcount.so")
UPDATES_LIB+=("funcs/func_logic.so")
UPDATES_LIB+=("funcs/func_math.so")
UPDATES_LIB+=("funcs/func_md5.so")
UPDATES_LIB+=("funcs/func_rand.so")
UPDATES_LIB+=("funcs/func_realtime.so")
UPDATES_LIB+=("funcs/func_sha1.so")
UPDATES_LIB+=("funcs/func_strings.so")
UPDATES_LIB+=("funcs/func_timeout.so")
UPDATES_LIB+=("funcs/func_uri.so")

UPDATES_LIB+=("pbx/pbx_config.so")

UPDATES_LIB+=("res/res_crypto.so")
UPDATES_LIB+=("res/res_curl.so")
UPDATES_LIB+=("res/res_smdi.so")
UPDATES_LIB+=("res/res_timing_dahdi.so")
UPDATES_LIB+=("res/res_timing_timerfd.so")

DIR_EXE="/usr/sbin"
DIR_LIB="/usr/lib/`uname -m`-linux-gnu/asterisk/modules"

HOTFIX_DIR="/var/tmp/hotfix"

usage()
{
    echo "Usage: $0 backup"
    echo "Usage: $0 restore"
    echo "Usage: $0 install"
    echo "Usage: $0 [ gdb ] ( asterisk | simpleusb-tune-menu | radio-tune-menu )"
    echo "Usage: $0 [ valgrind ] ( asterisk | simpleusb-tune-menu | radio-tune-menu )"
    exit
}

updates_backup()
{
    UPDATE_VER="$(pwd -P)"
    if [[ -f "/etc/asl-debug-version" ]]; then
	CURRENT_VER="$(cat /etc/asl-debug-version)"
        if [[ -n "${CURRENT_VER}" && "${CURRENT_VER}" != "${UPDATE_VER}" ]]; then
	    echo "Backup for \"${CURRENT_VER}\" already exists"
	    exit 1
	fi
    fi

    for x in ${UPDATES_EXE[@]}; do
	f=$(basename "${x}")
	if [[ ! -f "${DIR_EXE}/${f}-SAVE" ]]; then
	    ${SUDO} cp -p "${DIR_EXE}/${f}" "${DIR_EXE}/${f}-SAVE"
	    echo "Saved \"${DIR_EXE}/${f}\""
	else
	    echo "\"${DIR_EXE}/${f}\" already saved"
	fi
    done
    for x in ${UPDATES_LIB[@]}; do
	f=$(basename "${x}")
	if [[ ! -f "${DIR_LIB}/${f}-SAVE" ]]; then
	    ${SUDO} cp -p "${DIR_LIB}/${f}" "${DIR_LIB}/${f}-SAVE"
	    echo "Saved \"${DIR_LIB}/${f}\""
	else
	    echo "\"${DIR_LIB}/${f}\" already saved"
	fi
    done

    echo "${UPDATE_VER}" | ${SUDO} tee "/etc/asl-debug-version"	2>/dev/null
}

updates_restore()
{
    PID=$(pgrep asterisk)
    if [[ -n "${PID}" ]]; then
	echo "Shutting down \"asterisk\" before restore"
	${SUDO} /usr/bin/astdn.sh
    fi

    N=0
    for x in ${UPDATES_EXE[@]}; do
	f=$(basename "${x}")
	if [[ -f "${DIR_EXE}/${f}-SAVE" ]]; then
	    ${SUDO} mv "${DIR_EXE}/${f}-SAVE" "${DIR_EXE}/${f}"
	    echo "Restored \"${DIR_EXE}/${f}\""
	    N=$((N + 1))
	fi
    done
    for x in ${UPDATES_LIB[@]}; do
	f=$(basename "${x}")
	if [[ -f "${DIR_LIB}/${f}-SAVE" ]]; then
	    ${SUDO} mv "${DIR_LIB}/${f}-SAVE" "${DIR_LIB}/${f}"
	    echo "Restored \"${DIR_LIB}/${f}\""
	    N=$((N + 1))
	fi
    done

    if [[ $N -eq 0 ]]; then
	echo "All files [already] restored"
    fi

    ${SUDO} rm -f "/etc/asl-debug-version"

    if [[ -n "${PID}" ]]; then
	echo "Restarting \"asterisk\" after restore"
	${SUDO} /usr/bin/astup.sh
    fi
}

updates_check()
{
    #
    # ensure that we have a backup
    #
    ERR=0
    for x in ${UPDATES_EXE[@]}; do
	f=$(basename "${x}")
	if [[ ! -f "${DIR_EXE}/${f}-SAVE" ]]; then
	    echo "*** \"${f}\" not saved"
	    ERR=$((ERR + 1))
	fi
    done
    for x in ${UPDATES_LIB[@]}; do
	f=$(basename "${x}")
	if [[ ! -f "${DIR_LIB}/${f}-SAVE" ]]; then
	    echo "*** \"${f}\" not saved"
	    ERR=$((ERR + 1))
	fi
    done
    if [[ $ERR -ne 0 ]]; then
	echo "You must use \"$0 backup\" to preserve the original executables/libraries."
	exit
    fi
}

updates_install()
{
    PID=$(pgrep asterisk)
    if [[ -n "${PID}" ]]; then
	echo "Shutting down \"asterisk\" before updating"
	${SUDO} /usr/bin/astdn.sh
    fi

    #
    # install the updated (debug) binaries
    #
    for x in ${UPDATES_EXE[@]}; do
	if [[ ! -f "${x}" ]]; then
	    continue
	fi
	f=$(basename "${x}")
	sum1=$(sum "${x}"			2>/dev/null)
	sum1="${sum1% *}"
	sum2=$(sum "${DIR_EXE}/${f}"		2>/dev/null)
	sum2="${sum2% *}"
	if [[ "$sum1" != "$sum2" ]]; then
	    echo "Updating: \"${DIR_EXE}/${f}\""
	    ${SUDO} cp -p "${x}" "${DIR_EXE}/${f}"

	    ${SUDO} mkdir -p "${HOTFIX_DIR}/${DIR_EXE}"
	    ${SUDO} cp -p "${x}" "${HOTFIX_DIR}/${DIR_EXE}/${f}"
	fi
    done
    for x in ${UPDATES_LIB[@]}; do
	if [[ ! -f "${x}" ]]; then
	    continue
	fi
	f=$(basename "${x}")
	sum1=$(sum "${x}"			2>/dev/null)
	sum1="${sum1% *}"
	sum2=$(sum "${DIR_LIB}/${f}"		2>/dev/null)
	sum2="${sum2% *}"
	if [[ "$sum1" != "$sum2" ]]; then
	    echo "Updating: \"${DIR_LIB}/${f}\""
	    ${SUDO} cp -p "${x}" "${DIR_LIB}/${f}"

	    ${SUDO} mkdir -p "${HOTFIX_DIR}/${DIR_LIB}"
	    ${SUDO} cp -p "${x}" "${HOTFIX_DIR}/${DIR_LIB}/${f}"
	fi
    done

    if [[ -d "${HOTFIX_DIR}" ]]; then
	${SUDO} chown -R root: "${HOTFIX_DIR}"
    fi

    if [[ -n "${PID}" ]]; then
	echo "Restarting \"asterisk\" after updating"
	${SUDO} /usr/bin/astup.sh
    fi
}

#
# check if root
#
SUDO=""
if [[ $EUID != 0 ]]; then
    SUDO="sudo"
    SUDO_EUID=$(${SUDO} id -u)
    if [[ ${SUDO_EUID} -ne 0 ]]; then
	echo "This script must be run as root or with sudo"
	exit 1
    fi
fi

#
# check if we are in an asl3-asterisk "build" directory
#
for x in ${UPDATES_EXE[@]} ${UPDATES_LIB[@]}; do
    if [[ ! -f "${x}" ]]; then
	s="${x%.so}.c"
	if [[ ! -f "${s}" ]]; then
	    echo "\"${x}\" not found.  Are you in the correct source/build directory?"
	    exit
	fi
    fi
done

while [[ $# -gt 0 ]]; do
    case $1 in
	"backup" | "save" )
	    updates_backup
	    exit
	    ;;
	"restore" )
	    updates_restore
	    exit
	    ;;
	"install" )
	    updates_check
	    updates_install
	    exit
	    ;;
	"gdb" )
	    DEBUG=1
	    shift
	    ;;
	"valgrind" )
	    if [[ ! -x /usr/bin/valgrind ]]; then
		echo "\"valgrind\" is not installed."
		exit 1
	    fi
	    VALGRIND=1
	    shift
	    ;;
	"asterisk" | "main/asterisk" )
	    EXEC="main/asterisk"
	    shift
	    break
	    ;;
	"simpleusb-tune-menu" | "utils/simpleusb-tune-menu" )
	    EXEC="utils/simpleusb-tune-menu"
	    shift
	    break
	    ;;
	"radio-tune-menu" | "utils/radio-tune-menu" )
	    EXEC="utils/radio-tune-menu"
	    shift
	    break
	    ;;
	* )
	    echo "Huh?"
	    echo ""
	    usage
	    ;;
    esac
done

if [[ -z "${EXEC}" ]]; then
    usage
fi

if [[ "${EXEC}" =~ "main/asterisk" ]]; then
    pgrep asterisk >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
	echo "Asterisk is still running"
	exit 1
    fi
fi

updates_check
updates_install

#
# run (or debug) the executable
#
if [[ $DEBUG -gt 0 ]]; then
    #
    # Use "gdb"
    #
    if [[ "${EXEC}" = "main/asterisk" && $# -eq 0 ]]; then
	exec ${SUDO}							\
	    gdb								\
		-iex='echo \nstart with "r -c -g -p -U asterisk"\n\n'	\
	    ${EXEC}
    else
	exec ${SUDO}							\
	    gdb								\
	    ${EXEC}

    fi

elif [[ $VALGRIND -gt 0 ]]; then
    #
    # Use "valgrind"
    #
    if [[ "${EXEC}" = "main/asterisk" && $# -eq 0 ]]; then
	set -- -c -g -p -U asterisk
    fi

    exec ${SUDO}							\
	valgrind							\
	    --log-file=/var/tmp/valgrind.txt				\
	    --leak-check=full						\
	    --show-leak-kinds=all					\
	    --track-origins=yes						\
	    --vgdb=no 							\
	${EXEC} $*

#	    --suppressions=/var/tmp/valgrind.supp			\
#	    --trace-children=yes					\

else
    #
    # If not debugging, do not exec "asterisk" with no arguments
    #
    if [[ "${EXEC}" = "main/asterisk" && $# -eq 0 ]]; then
	set -- -c -g -p -U asterisk
	echo "Exec'ing ${EXEC} $*"
    fi

    exec ${SUDO}					\
	${EXEC} $*

fi

exit 0
