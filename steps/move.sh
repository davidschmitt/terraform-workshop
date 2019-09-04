#!/bin/bash

# Renumbering steps is annoying.  Automate it here

RUN=false
while getopts "i:r:x" OPT
do
  case "$OPT" in
    i )
      INSERT="$OPTARG"
      ;;
    r )
      REMOVE="$OPTARG"
      ;;
    x )
      RUN=true
      ;;
    * )
      echo Invalid argument: "-$OPT" >&2
      exit 1
      ;;
  esac
done

MAX_STEP=$(ls step*.sh | sort --version-sort | tail -1 | sed -e 's/^step//; s/\.sh$//;')
if [ "$MAX_STEP" = "" ]
then
  echo "Unable to determine max step"
  exit 1
fi

if [ "$INSERT" '!=' "" ]
then
  STEP="$MAX_STEP"
  while [ "$STEP" -ge "$INSERT" ]
  do
    NEXT=$(expr "$STEP" + 1)
    echo git mv "step$STEP.sh" "step$NEXT.sh"
    if [ "$RUN" = "true" ]
    then
      git mv "step$STEP.sh" "step$NEXT.sh" || exit 1
    fi
    (( --STEP ))
  done
else
  if [ "$REMOVE" '!=' "" ]
  then
    STEP="$REMOVE"
    if [ -f "step$STEP.sh" ]
    then
      echo git rm "step$STEP.sh"
      if [ "$RUN" = "true" ]
      then
        git rm "step$STEP.sh" || exit 1
      fi
    fi
    while [ "$STEP" -lt "$MAX_STEP" ]
    do
      NEXT=$(expr "$STEP" + 1)
      echo git mv "step$NEXT.sh" "step$STEP.sh"
      if [ "$RUN" = "true" ]
      then
        git mv "step$NEXT.sh" "step$STEP.sh" || exit 1
      fi
      (( ++STEP ))
    done
  else
    echo "You must specify either -i or -r options"
    exit 1
  fi
fi

