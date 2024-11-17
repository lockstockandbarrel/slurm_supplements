#!/bin/bash
################################################################################
function HELP(){
cat <<\EOF
NAME
   days2sec(3f) - [M_time:DURATION] convert string of form
   [[-]dd-]hh:mm:ss.nn or [NNw][NNd][NNh][NNm][NNs] to seconds

SYNOPSIS

   days2sec [-V] [[-- -]dd-]hh:mm:ss.nn

     or

   days2sec [NNw][NNd][NNh][NNm][NNs]

     or
   days2sec --help|--version|--usage

DESCRIPTION
  Given a string representing a duration of the form [-][[[dd-]hh:]mm:]ss
  or [NNd][NNh][NNm[]NNs][NNw] return a value representing seconds.

  If the day-prefix "dd-" is present, units for the numbers are assumed to
  proceed from day to hour to minute to second. But if no day is present,
  the units are assumed to proceed from second to minutes to hour from
  left to right. That is ...

      [-]dd-hh:mm:ss
      [-]dd-hh:mm
      [-]dd-hh

      hh:mm:ss
      mm:ss
      ss

  Where dd is days, hh hours, mm minutes and ss seconds.

  Simple numeric values may also be used with unit suffixes; where s,m,h,
  or d represents seconds, minutes, hours or days and w represents a week.

      [NNw][NNd][NNh][NNm][NNs]

        w -  week
        d -  days
        m -  minutes
        h -  hours
        s -  seconds

  + The numeric values may represent floating point numbers.

  + Spaces, commas and case are ignored.

  + A value cannot mix the units format and the dd-hh:mm:ss format.

  + Only the first letter of units are retained, but allowed aliases
    for w,d,h,m, and s units are preferably restricted to

      w -  week, weeks, wk, wks
      d -  days,day
      m -  minutes,minute,min,mins
      h -  hours,hour,hr,hrs
      s -  seconds,second,sec,secs

  + negative values preceded by a space should follow a "-- " option,
    or some edge cases like -[wdhms] will be seen as command switches.
    indicating all options have been supplied.

OPTIONS
      str   string of the general form dd-hh:mm:ss.nn or NwNdNhNmNs
RETURNS
      time  the number of seconds represented by the input string

EXAMPLE
   Sample commands:

   days2sec 1-12:04:20                # 129860
   days2sec 1                         # 1
   days2sec 1:00                      # 60
   days2sec 1:00:00                   # 3600
   days2sec 1-00:00:00                # 86400
   days2sec 1.5 days                  # 129600
   days2sec 1.5 days 4hrs 30minutes   # 145800
   days2sec 1.5d                      # 129600
   days2sec 1d2h3m4s                  # 93784
   # spaces are ignored
   days2sec 1 2 3 4                   # 1234
   # duplicate units are allowed
   days2sec ' 1d 1d 1d                # 259200
   # negative values
   days2sec 4d-12h                    # 302400
   days2sec -- -1d                    # -86400 

AUTHOR
   John S. Urban, 2015

LICENSE
   MIT
EOF
}
################################################################################
function VERSION(){
cat <<\EOF
PRODUCT:        General Purpose Fortran
PROGRAM:        sec2days.sh
DESCRIPTION:    Convert durations of time to seconds
VERSION:        v1.0.0, 2024-11-16
AUTHOR:         John S. Urban
REPORTING BUGS: http://www.urbanjost.altervista.org/
HOME PAGE:      http://www.urbanjost.altervista.org/index.html
LICENSE:        MIT
EOF
}
################################################################################
function USAGE(){
cat <<\EOF
Usage:
    [-]dd-hh:mm:ss
    [-]dd-hh:mm
    [-]dd-hh

    hh:mm:ss
    mm:ss
    ss

    [NNw][NNd][NNh][NNm][NNs][NNw]

      w -  week, weeks, wk, wks
      d -  days,day
      m -  minutes,minute,min,mins
      h -  hours,hour,hr,hrs
      s -  seconds,second,sec,secs
EOF
}
################################################################################
function PARSE(){
# Note that we use "$@" to let each command-line parameter expand to a separate word.
# The quotes around "$@" are essential!
# We need TEMP as the 'eval set --' would nuke the return value of getopt.
# export EDITOR=${FCEDIT:-${EDITOR:-${VISUAL:-vim -c 'set ft=man ts=8 nomod nolist nonu' -c 'nnoremap i <nop>'}}}
export EDIT=FALSE
export VERBOSE=FALSE
NEGATIVE=''
set -- $(sed -e 's/ -\([0-9]\)/X\1/g'<<<" $@")
TEMP=$(getopt -o 'hvVub-long:e::' --long 'help,version,verbose,usage,b-long:,editor::' -n "$(basename $0)" -- "$@")


if [ $? -ne 0 ]; then
   echo '<ERROR> Terminating...'"$0"':' >&2
   exit 1
fi

# Note the quotes around "$TEMP": they are essential!
eval set -- "$TEMP"
unset TEMP
while true; do
        case "$1" in
                '-h'|'--help')    shift;    HELP;    exit ;;
                '-v'|'--version') shift;    VERSION; exit ;;
                '-u'|'--usage')   shift;    USAGE;   exit ;;

                '-V'|'--verbose') shift;    VERBOSE=TRUE;   continue ;;

                '-b'|'--b-long')  shift 2
                        echo "Option b, argument '$2'"
                        continue
                ;;
                '-e'|'--editor')
                        # c has an optional argument. As we are in quoted mode,
                        # an empty parameter will be generated if its optional
                        # argument is not found.
                        case "$2" in
                                '') EDIT=TRUE  EDITOR=$EDITOR ;; # Option e, no argument
                                *)   EDIT=TRUE EDITOR="$2"    ;; # Option e, argument '$2'
                        esac
                        shift 2
                        continue
                ;;
                '--')
                        shift
                        break
                ;;
                *)
                        echo '<ERROR> '"$0: unknown keyword $1" >&2
                        exit 1
                ;;
        esac
done

# Remaining arguments:
OTHER="$NEGATIVE"
for arg; do
   OTHER="$OTHER $arg"
done
OTHER=${OTHER/X/-}
}
################################################################################
#
#@(#) days2sec(3f): convert string [[-]dd-]hh:mm:ss.nn to seconds or string IId JJh KKm LLs to seconds
#
export EDITOR=${FCEDIT:-${EDITOR:-${VISUAL:-vi}}}
PARSE "$@"
str="$OTHER"
input=${str// }                                # remove whitespace
input=$(tr -d "_',", <<<$input)                # remove single quotes,underscores sometimes used in numbers
input=${input,,}                               # change to lowercase and add whitespace to make room for spaces
input=${input:-0.0}
time=0.0
case "$input" in
   *[smhdw]*)                        # assume unit code values not DD-HH:MM:SS
   # to go from long names to short names substitute common aliases for units
   # days,day to d; hours,hour,hrs,hr to h; minutes,minute,mins,min; seconds,second,secs,sec; weeks,week,wks,wk
   input=$(sed -e 's/\([0-9][0-9]*\)\([dhmsw]\)[a-z]*/\1\2/g' <<<$input)
   input=$(sed -e 's/[smhdw]/& /g'  <<<$input) # separate with spaces after units
   VALUE=0
   for UNIT in $input
   do
   NUM=$(tr -d 'smhdw' <<<$UNIT)
   NUM=${NUM:-0}

   # awk will multiply odd strings.
   # Return  a  string indicating the type of x.  The string will
   # be one of "array", "number", "regexp",  "string",  "strnum",
   # "unassigned", or "undefined".
   TYPE="$(awk '{ print typeof($1) }' <<< $NUM)"
   case "$TYPE" in
   strnum|number);;
   *)
      echo "<ERROR> $0: '$NUM' is not a number, type=$TYPE. Input was $str" 1>&2
      echo 0
      exit 2
   ;;
   esac
   case "$UNIT" in
   *s) VALUE=$(awk '{print $1 + ($2) * 1}'        <<< "$VALUE $NUM") ;;
   *m) VALUE=$(awk '{print $1 + ($2) * 60}'       <<< "$VALUE $NUM") ;;
   *h) VALUE=$(awk '{print $1 + ($2) * 3600}'     <<< "$VALUE $NUM") ;;
   *d) VALUE=$(awk '{print $1 + ($2) * 86400}'    <<< "$VALUE $NUM") ;;
   *w) VALUE=$(awk '{print $1 + ($2) * 86400 * 7}'<<< "$VALUE $NUM") ;;
   *)
   echo "<ERROR> $0: unknown or missing unit in $UNIT. Input was $str" 1>&2
   echo 0
   exit 1
   ;;
   esac
   done
;;
*)
   # convert to units and recursively call the function with the new expression
   case "$input" in # allow negative prefix as first character but remove it and change sign of value at end
   -*) sign='-' input=${input/-};;
   +*) sign=''  input=${input/ / };;
   *)  sign='' ;;
   esac
   case "$input" in # allow negative prefix as first character but remove it and change sign of value at end
   *-*) # dd-hh:mm:ss
   input=${input}':'
   input=${input//d}
   input=${input/-/d}
   input=${input/:/h}
   input=${input/:/m}
   input=${input/:/s}
   input=${input/:/X}
   VALUE=$(bash $0 -- $input)
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
   VALUE=$(bash $0 -- $input)
   ;;
   esac
;;
esac
if [ "$VERBOSE" != 'FALSE' ]
then
   IFS=' -:wdhms'
   declare -a array=($input)
   IFS=
   echo "
   ARRAY ${array[@]}
   STR   $str
   INPUT $input
   VALUE ${sign}$VALUE
   " 1>&2
fi
echo "${sign}${VALUE:-0}"
################################################################################
exit
################################################################################
