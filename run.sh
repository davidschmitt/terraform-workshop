#!/bin/bash

info() {
  echo
  tput setaf 2
  echo "$*"
  tput setaf 7
  echo
}

ok() {
  if [ "$?" = "0" ]
  then
    info "$1 succeeded"
  else
    echo >&2
    echo "$1 failed" >&2
    exit 1
  fi
}

prompt() {
  echo
  tput setaf 1
  echo -n "[$*]: "
  tput setaf 7
  read ANS
  echo
}

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

allMarkdown() {
  STEP=1
  while [ -f "steps/step$STEP.sh" ]
  do
    markdown "$STEP"
    (( ++STEP ))
  done
}

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

WORKDIR="`pwd`/work2"
STEPDIR=`pwd`/steps

STEPFILE="$STEPDIR/step$STEP.sh"
if [ '!' -f "$STEPFILE" ]
then
  echo "Step $STEP not found - aborting."
  exit 1
fi

if [ "$STEP" = "1" ]
then
  clear
  if [ -f "$WORKDIR/terraform.tfstate" ]
  then
    prompt "Attempting to clean up any left over resources.  Press ENTER to continue"
    ( cd "$WORKDIR" && terraform destroy -auto-approve )
  fi
  prompt "Cleaning up any left over local files.  Press ENTER to continue"
  rm -rf "$WORKDIR/"*.tf "$WORKDIR/"*.tfvars "$WORKDIR/az" "$WORKDIR/vpc"
fi

mkdir -p "$WORKDIR" &&
  cd "$WORKDIR" || (echo "Unable to cd to $WORKDIR"; exit 1)

while true
do
  clear
  info "Step $STEP (working dir $WORKDIR)"

  tput setaf 6
  grep '^#' <"$STEPFILE"
  echo
  tput setaf 3
  grep -v '^#' <"$STEPFILE"
  echo
  tput setaf 7

  prompt "Press ENTER to execute step $STEP"
  bash "$STEPFILE"
  OK="$?"
  test "$OK" = "0"
  ok "Step $STEP"
  (( ++STEP ))
  echo

  STEPFILE="$STEPDIR/step$STEP.sh"
  if [ -f "$STEPFILE" ]
  then
    prompt "Press ENTER to proceed to step $STEP"
  else
    prompt "Final step reahed. Press ENTER to exit"
    exit 0
  fi
done
