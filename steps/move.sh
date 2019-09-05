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

if [ "$RUN" '!=' 'true' ]
then
  echo "### Dry run: add -x option to actually run the commands listed below"
fi

if [ "$INSERT" '!=' "" ]
then
  STEP="$MAX_STEP"
  while [ "$STEP" -ge "$INSERT" ]
  do
    NEXT=$(expr "$STEP" + 1)
    git ls-files --error-unmatch "step$STEP.sh" >/dev/null 2>&1 && MV="git mv" || MV="mv"
    echo $MV "step$STEP.sh" "step$NEXT.sh"
    if [ "$RUN" = "true" ]
    then
      $MV "step$STEP.sh" "step$NEXT.sh" || exit 1
    fi
    (( --STEP ))
  done
else
  if [ "$REMOVE" '!=' "" ]
  then
    STEP="$REMOVE"
    if [ -f "step$STEP.sh" ]
    then
      git ls-files --error-unmatch "step$STEP.sh" >/dev/null 2>&1 && RM="git rm" || RM="rm"
      echo $RM "step$STEP.sh"
      if [ "$RUN" = "true" ]
      then
        $RM "step$STEP.sh" || exit 1
      fi
    fi
    while [ "$STEP" -lt "$MAX_STEP" ]
    do
      NEXT=$(expr "$STEP" + 1)
      git ls-files --error-unmatch "step$NEXT.sh" >/dev/null 2>&1 && RM="git mv" || RM="rm"
      echo $RM "step$NEXT.sh" "step$STEP.sh"
      if [ "$RUN" = "true" ]
      then
        $RM "step$NEXT.sh" "step$STEP.sh" || exit 1
      fi
      (( ++STEP ))
    done
  else
    echo "Usage:"
    echo "move.sh -i N        - Dry run to insert a step number N"
    echo "move.sh -i N -x     - Run commands to insert a step"
    echo "move.sh -r N        - Dry run to remove a step"
    echo "move.sh -r N -x     - Run commands to remove a step number N"
    exit 1
  fi
fi

if [ "$RUN" '!=' 'true' ]
then
  echo "### Dry run: add -x option to actually run the commands listed above"
fi

