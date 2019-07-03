
CLASSNAME_PATTERN=' classname="([^"]+)"'
METHODNAME_PATTERN=' name="([^"]+)"'

JUNIT_REPORT=$1
SRC_ROOT=$2
LEVEL=${3:-error}

if [ -z "$JUNIT_REPORT" ] || [ -z "$SRC_ROOT" ]; then
  echo "Usage: clean-up-gp.sh [junit-report.xml] [source root dir]"
  exit
fi

sed -zEi 's/\n[[:blank:]]+<failure/<failure\n/g' "$JUNIT_REPORT"
sed -zEi 's/\n[[:blank:]]+<error/<error\n/g' "$JUNIT_REPORT"

#grep -E "<(error|failure)" "$JUNIT_REPORT" | while read LINE; do
grep -E "<$LEVEL" "$JUNIT_REPORT" | while read LINE; do
  echo "yo : $LINE"
  if [[ $LINE =~ $CLASSNAME_PATTERN ]]; then
    CLASS_NAME="${BASH_REMATCH[1]}"
  fi
  if [[ $LINE =~ $METHODNAME_PATTERN ]]; then
    METHOD_NAME="${BASH_REMATCH[1]}"
  fi

  if [ -z "$CLASS_NAME" ] || [ -z "$METHOD_NAME" ]; then
    echo "classname or method name is empty"
    echo "idhar $LINE"
    continue
  fi

  CLASS_FILE=$SRC_ROOT/${CLASS_NAME//\./\/}.java
  if [ ! -f "$CLASS_FILE" ]; then
    echo "File not found: $CLASS_FILE"
    continue
  fi

  echo -e "Removing test $METHOD_NAME from $CLASS_NAME"
  METHOD_LINE=$( grep -n "$METHOD_NAME" "$CLASS_FILE" | grep -Eo '^[^:]+' )
  FIRST_LINE=$( expr $METHOD_LINE - 2 )
  LAST_LINE=$( expr $METHOD_LINE + 4 )
  sed -i $CLASS_FILE -re "${FIRST_LINE},${LAST_LINE}d"

  TEST_COUNT=`grep '@Test' $CLASS_FILE | wc -l`
  if [ $TEST_COUNT -le 1 ]; then
    rm -f "$CLASS_FILE"
    echo -e "Removed failed test file $CLASS_FILE"
  else
    echo "Keeping $CLASS_FILE"
  fi
done


LEVEL=${3:-failure}

if [ -z "$JUNIT_REPORT" ] || [ -z "$SRC_ROOT" ]; then
  echo "Usage: clean-up-gp.sh [junit-report.xml] [source root dir]"
  exit
fi

sed -zEi 's/\n[[:blank:]]+<failure/<failure\n/g' "$JUNIT_REPORT"
sed -zEi 's/\n[[:blank:]]+<error/<error\n/g' "$JUNIT_REPORT"

#grep -E "<(error|failure)" "$JUNIT_REPORT" | while read LINE; do
grep -E "<$LEVEL" "$JUNIT_REPORT" | while read LINE; do
  echo "yo : $LINE"
  if [[ $LINE =~ $CLASSNAME_PATTERN ]]; then
    CLASS_NAME="${BASH_REMATCH[1]}"
  fi
  if [[ $LINE =~ $METHODNAME_PATTERN ]]; then
    METHOD_NAME="${BASH_REMATCH[1]}"
  fi

  if [ -z "$CLASS_NAME" ] || [ -z "$METHOD_NAME" ]; then
    echo "classname or method name is empty"
    echo "idhar $LINE"
    continue
  fi

  CLASS_FILE=$SRC_ROOT/${CLASS_NAME//\./\/}.java
  if [ ! -f "$CLASS_FILE" ]; then
    echo "File not found: $CLASS_FILE"
    continue
  fi

  echo -e "Removing test $METHOD_NAME from $CLASS_NAME"
  METHOD_LINE=$( grep -n "$METHOD_NAME" "$CLASS_FILE" | grep -Eo '^[^:]+' )
  FIRST_LINE=$( expr $METHOD_LINE - 2 )
  LAST_LINE=$( expr $METHOD_LINE + 4 )
  sed -i $CLASS_FILE -re "${FIRST_LINE},${LAST_LINE}d"

  TEST_COUNT=`grep '@Test' $CLASS_FILE | wc -l`
  if [ $TEST_COUNT -le 1 ]; then
    rm -f "$CLASS_FILE"
    echo -e "Removed failed test file $CLASS_FILE"
  else
    echo "Keeping $CLASS_FILE"
  fi
done
