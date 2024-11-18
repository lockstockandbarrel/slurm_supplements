#!/bin/bash
################################################################################
#
#@(#) slurmdur(3f): convert string [[-]dd-]hh:mm:ss to seconds or string HHw IId JJh KKm LLs to seconds using Slurm rules
#
# Slurm duration format:
#
#    Time resolution is one minute and second values are rounded up to the next minute.
#
#    A time limit of zero requests that no time limit be imposed.
#
#    Acceptable time formats include
#             minutes
#             minutes:seconds
#       hours:minutes:seconds
#       days-hours
#       days-hours:minutes
#       days-hours:minutes:seconds
#
################################################################################
ASSERT(){
# test expected value to result
EXPECTED="$1"
shift 1
INPUT="$*"
RESULT="$(DURATION_TO_SECONDS $INPUT)"
STATUS=$?
EXPECTED_ERROR=${EXPECTED_ERROR:-0}
if [ "${EXPECTED/ /}" == "${RESULT/ /}" -a "$STATUS" -eq $EXPECTED_ERROR ]
then
   printf "PASSED: EXPECTED: %10.10s RESULT: %10.10s STATUS: %3.3i INPUT: %s\n" "$EXPECTED" "$RESULT" "$STATUS" "$INPUT"
else
   printf "FAILED: EXPECTED: %10.10s RESULT: %10.10s STATUS: %3.3i INPUT: %s\n" "$EXPECTED" "$RESULT" "$STATUS" "$INPUT"
fi
}
################################################################################
QA(){
export EXPECTED_ERROR=0
echo 'basic time formats'
ASSERT  60        1
ASSERT  60        1:00
ASSERT  3600      1:00:00
ASSERT  86400     1-00:00:00
ASSERT  129860    1-12:04:20
echo 'basic unit time durations'
ASSERT  129600    1.5 days
ASSERT  145800    1.5 days     4hrs  30minutes
ASSERT  129600    1.5d
ASSERT  93784     1d2h3m4s
echo 'spaces are ignored'
ASSERT  74040      1 2  3     4
echo 'duplicate  units  are  allowed'
ASSERT  259200    '           1d       1d    1d  '
echo 'negative values'
ASSERT  302400    4d-12h
ASSERT  -86400     -1d
echo 'reasonable limits'
ASSERT  31536000 365d
echo 'ignore commas'
ASSERT  259267380 4,321,123
ASSERT  259260 4 321,
echo 'prime and double prime (single and double quotes)'
ASSERT  129860    '36h 4'"'"'20"' # 36h 4'20"
echo 'aberant cases'
ASSERT  0 -
export EXPECTED_ERROR=2
ASSERT  0 notavalue
ASSERT  0 1-2-3
ASSERT  0 1d 2z
export EXPECTED_ERROR=1
ASSERT  0 1d 2
}
################################################################################
function UNITS_TO_SECONDS(){
input=${*}
# to go from long names to short names substitute common aliases for units, reducing unit names to a singe character
# days,day to d; hours,hour,hrs,hr to h; minutes,minute,mins,min; seconds,second,secs,sec; weeks,week,wks,wk
input=$(sed -e 's/\([0-9][0-9]*\)\([dhmsw]\)[a-z]*/\1\2/g' <<<$input)
input=$(sed -e 's/[smhdw]/& /g'  <<<$input) # separate with spaces after units into list of words
for UNIT in $input  # convert individual NNunit strings to seconds and add to total
do
   NUM=$(tr -d 'smhdw' <<<$UNIT) # remove the unit so have just the number
   NUM=${NUM:-0}
   # convert just a sign to a zero
   case "$NUM" in
      -) NUM=-0;;
      +) NUM=+0;;
   esac
   # awk will multiply odd strings.
   # Return  a  string indicating the type of x.  The string will
   # be one of "array", "number", "regexp",  "string",  "strnum",
   # "unassigned", or "undefined".
   TYPE="$(awk '{ print typeof($1) }' <<< $NUM)"
   case "$TYPE" in
      strnum|number);;
      *)
         echo "<ERROR> $0: '$NUM' is not a number, type=$TYPE. Input was $original" 1>&2
         STATUS=2
         VALUE=0
         return $STATUS
      ;;
   esac
   case "$UNIT" in
      *s) VALUE=$(awk '{print $1 + $2 * 1}'        <<< "$VALUE $NUM") ;;
      *m) VALUE=$(awk '{print $1 + $2 * 60}'       <<< "$VALUE $NUM") ;;
      *h) VALUE=$(awk '{print $1 + $2 * 3600}'     <<< "$VALUE $NUM") ;;
      *d) VALUE=$(awk '{print $1 + $2 * 86400}'    <<< "$VALUE $NUM") ;;
      *w) VALUE=$(awk '{print $1 + $2 * 86400 * 7}'<<< "$VALUE $NUM") ;;
      *)
         echo "<ERROR> $0: unknown or missing unit in $UNIT. Input was $original" 1>&2
         STATUS=1
         VALUE=0
         return $STATUS
      ;;
   esac
done
}
################################################################################
function TIME_TO_UNITS(){
# convert to units and recursively call the function with the new expression
input=${*}
case "$input" in
   *-*) # dd-hh:mm:ss
   input=${input}':'
   input=${input//d}
   input=${input/-/d}
   input=${input/:/h}
   input=${input/:/m}
   input=${input/:/s}
   input=${input/:/X}
   ;;
*) # hh:mm:ss
   input='s'$(rev <<<${input})
   input=${input/:/m}
   input=${input/:/h}
   input=${input/:/d}
   input=${input/:/w}
   input=${input/:/X}
   input=$(rev <<<$input)
   input=${input:-0}
   ;;
esac
UNITS_TO_SECONDS $input
}
################################################################################
DURATION_TO_SECONDS(){
original="${@}"
VALUE=0
input=${original// }                    # remove whitespace
input=$(tr  "['\"]" '[ms]' <<<$input)   # remove single quote to m, double quote to s
input=$(tr -d "_,", <<<$input)          # remove commas,underscores sometimes used in numbers representing time
input=${input,,}                        # change to lowercase and add whitespace to make room for spaces
input=${input:-0.0}                     # if string is empty change it to a zero
# if see name of a unit assume unit code values not DD-HH:MM:SS
case "$input" in
qa)        QA;                 return ;;
*[smhdw]*) UNITS_TO_SECONDS "$input" ;STATUS=$? ;; # || exit $?;;
*)         TIME_TO_UNITS "$input"    ;STATUS=$? ;; # || exit $?;;
esac
#------------------------------------------------------------------------------#
# print results
# $VALUE should now be set to the number of seconds
# for Slurm one number is minutes, not seconds
case "${original,,}" in
*[smhdw:-]*) echo "${VALUE:-0}"  ;;
*) echo "$(awk '{print $1 * 60}' <<< $VALUE)" ;;
esac
#------------------------------------------------------------------------------#
exit $STATUS
}
################################################################################
#declare -x -g STATUS=0
export STATUS=0
DURATION_TO_SECONDS "${@}"
################################################################################
exit $STATUS
################################################################################
