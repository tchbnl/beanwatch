#!/bin/bash
# beanwatch - Logger for user_beancounters
# Nathan P. <me@tchbnl.net>
# v0.1 (Updated 5/19/2023)

# TODO:
# - Find love

# Make sure only one instance of beanwatch is running at a time
# Fun fact, this took me an embarassingly long time to realize why -gt 1 wouldn't work
if [[ "$(pgrep -x "$(basename "${0}")" | wc -l)" -gt 2 ]]; then
  echo "Looks like another instance is already running. Bailing out to avoid weirdness."
  exit
fi

# Log file and timestamp format set up
LOGFILE="/var/log/beanwatch.log"
TIMESTAMP="+%Y-%m-%d %H:%M"
echo "[$(date "${TIMESTAMP}")] Logging started" >> "${LOGFILE}"

# Initial numproc and oomguarpages fail values for our checks later
# We also fetch the numproc limit for some extra info in the log if there's a fail
 NUMPROC_INIT="$(grep numproc /proc/user_beancounters | awk '{print $6}')"
NUMPROC_LIMIT="$(grep numproc /proc/user_beancounters | awk '{print $5}')"
OOM_INIT="$(grep oomguarpages /proc/user_beancounters | awk '{print $6}')"

# Logging process. When tripped, logs the _CURRENT value of whatever the argument is
# For numproc fails, we also throw in the total limit for information sake
loggerino()
{
  if [[ "${1}" == "numproc" ]]; then
    echo "[$(date "${TIMESTAMP}")] [numproc] Process limit reached (${NUMPROC_LIMIT}) [Fails: ${NUMPROC_CURRENT}]" >> "${LOGFILE}"
  fi

  if [[ "${1}" == "oom" ]]; then
    echo "[$(date "${TIMESTAMP}")] [oom] Available RAM exhausted [Fails: ${OOM_CURRENT}]" >> "${LOGFILE}"
  fi
}

# The actual checks. Both do the same thing pretty much: Get the current value
# for numproc/oomguarpages from user_beancounters and compare it with the original
# value. If it's higher, trigger the logging process.
numcheck()
{
  NUMPROC_CURRENT="$(grep numproc /proc/user_beancounters | awk '{print $6}')"
  if [[ "${NUMPROC_CURRENT}" -gt "${NUMPROC_INIT}" ]]; then
    loggerino "numproc"

    NUMPROC_INIT="${NUMPROC_CURRENT}"
  fi
}

oomcheck()
{
  OOM_CURRENT="$(grep oomguarpages /proc/user_beancounters | awk '{print $6}')"
  if [[ "${OOM_CURRENT}" -gt "${OOM_INIT}" ]]; then
    loggerino "oom"

    OOM_INIT="${OOM_CURRENT}"
  fi
}

# Have a nice day
echo "Logging output to ${LOGFILE} and running in the background..."

# And lastly, let's run all of the above in an endless loop until it crashes
while true; do
  numcheck
  oomcheck

  sleep 60
done
