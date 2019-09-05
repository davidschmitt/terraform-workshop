#!/bin/bash

################################################################################
# Informational message (in green)
################################################################################
info() {
  echo
  tput setaf 2
  echo "$*"
  tput setaf 7
}

################################################################################
# Warning message (in red)
################################################################################
warn() {
  echo
  tput setaf 1
  echo "$@"
  tput setaf 7
}

################################################################################
# Make sure previous command succeeded
################################################################################
ok() {
  if [ "$?" = "0" ]
  then
    info "$1 succeeded"
  else
    warn "$1 failed"
    exit 1
  fi
}

################################################################################
# Prompt the user for input before proceeding
################################################################################
prompt() {
  warn -n "[$*]: "
  read ANS
}

################################################################################
# Generate markdown from a single step
################################################################################
markdown() {
  echo -n "$1. "
  sed -ne 's/^# //p' <"steps/step$1.sh"
  echo
  echo '```'
  echo -n '$ '
  grep -v '^#' <"steps/step$1.sh"
  echo '```'
  echo
}

################################################################################
# Generate markdown from all steps (to generate much of the README.md)
################################################################################
allMarkdown() {
  STEP=1
  while [ -f "steps/step$STEP.sh" ]
  do
    markdown "$STEP"
    (( ++STEP ))
  done
}

################################################################################
# Parse the command line options
################################################################################
STEP=1
while getopts "s:m" OPT
do
  case "$OPT" in
    s )
      STEP="$OPTARG"
      ;;
    m )
      allMarkdown
      exit 0
      ;;
    * )
      echo Invalid argument: "-$OPT" >&2
      exit 1
      ;;
  esac
done

################################################################################
# Begin the actual steps here
################################################################################
WORKDIR="`pwd`/tmp"
STEPDIR=`pwd`/steps

################################################################################
# Abort if they passed in a garbage step
################################################################################
STEPFILE="$STEPDIR/step$STEP.sh"
if [ '!' -f "$STEPFILE" ]
then
  echo "Step $STEP not found - aborting."
  exit 1
fi

################################################################################
# Try to clean up if it has been run before
################################################################################
if [ "$STEP" = "1" -a -d "$WORKDIR" ]
then
  clear
  prompt "Attempting to clean up any left over resources from prior runs.  Press ENTER to continue"
  bash steps/cleanup.sh "$WORKDIR"
  ok "Prior run cleanup"
  prompt "Press ENTER to proceed to step 1"
fi

################################################################################
# Create the working directory
################################################################################
mkdir -p "$WORKDIR" &&
  cd "$WORKDIR" || (echo "Unable to cd to $WORKDIR"; exit 1)

################################################################################
# Loop through the remaining steps
################################################################################
while true
do
  clear
  info "Step $STEP (working dir $WORKDIR)"

  tput setaf 6
  echo
  grep '^#' <"$STEPFILE"
  tput setaf 3
  echo
  grep -v '^#' <"$STEPFILE"

  prompt "Press ENTER to execute step $STEP"

  echo
  bash "$STEPFILE"
  ok "Step $STEP"

  (( ++STEP ))

  STEPFILE="$STEPDIR/step$STEP.sh"
  if [ -f "$STEPFILE" ]
  then
    prompt "Press ENTER to proceed to step $STEP"
  else
    prompt "Final step reached. Press ENTER to exit workshop"
    exit 0
  fi
done
