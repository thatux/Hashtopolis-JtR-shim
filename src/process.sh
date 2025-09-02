#!/bin/bash
# ln -s process.sh hashcat.bin
# Example input
#  './hashcat.bin' --machine-readable --quiet --status --restore-disable --session=hashtopolis --status-timer 5 --outfile-check-timer=5 --outfile-check-dir="/app/src/hashlist_1" -o "/app/src/hashlists/1.out" --outfile-format=1,2,3,4 -p "0x09" -s 562511 -l 220531 --potfile-disable --remove --remove-timer=5  "/app/src/hashlists/1" -a3 ?a?a?a?a?a?a?a   --hash-type=0

rm ./john/run/john.rec 2>/dev/null
rm ./john/run/john.pot 2>/dev/null #always start with empty potfile..

# Read full input line(s) from stdin
input="$*"
# Subsitute content after -p flag with real tab character
input=$(echo "$input" | sed 's/-p /-p0x09 /g')

# Define the expected start prefix string
prefix="--machine-readable --quiet --status --restore-disable --session=hashtopolis --status-timer 5"

# Check if $input starts with the prefix
if [[ "$input" != "$prefix"* ]]; then
#   echo "Input does NOT start with expected prefix. Running ./hashcat with input:"
  ./hashcat $input
  exit $?
fi

echo "input=$input"

# Extract the hashlist path from the input line (the path /app/src/hashlists/[digit])
# We'll grab the first occurrence
hashlist=$(echo "$input" | grep -oP '/app/src/hashlists/\d+' | head -n1 | tr -d '"')
outfile=$(echo "$input" | grep -oP '/app/src/hashlists/[0-9]+\.out')
skip=$(echo "$input" | grep -oP '\-s [0-9]+' | cut -d' ' -f2)

# echo "skip=$skip"
# exit 1

if [[ -z "$hashlist" ]]; then
  echo "Error: Could not extract hashlist path from input."
  exit 1
fi

# Remove the parts:
#   - the hashlist path (e.g. "/app/src/hashlists/1")
#   - the output file option (e.g. -o "/app/src/hashlists/1.out")
#   - the --hash-type option (e.g. --hash-type=0)
cmd=$(echo "$input" | \
  sed -E 's| -o /app/src/hashlists/[0-9]+\.out||g' | \
  sed -E 's| /app/src/hashlists/[0-9]+||g' | \
  sed -E 's|--hash-type=[0-9]+||g' | \
  sed 's/$/ --stdout/')

echo "cmd=$cmd"

# Run the resulting command and pipe output to John the Ripper
# echo "./hashcat $cmd | ./john/run/john --format=raw-md5 $hashlist --stdin"
bash -c "./hashcat $cmd" | ./john/run/john --format=raw-md5 "$hashlist" --stdin 1>/dev/null 2>/dev/null &
# cat ./john/run/john.pot | sed -E 's|\$dynamic_0\$||g' > hashcat.potfile
# we need to write the outfile for Hashtopolis to detect a crack
# './hashcat' --machine-readable --quiet --status --restore-disable --session=hashtopolis --status-timer 5 --outfile-check-timer=5 --outfile-check-dir="/app/src/hashlist_1" -o "/app/src/hashlists/1.out" --outfile-format=1,2,3,4 -p "0x09" -s 562511 -l 220531 --potfile-disable --remove --remove-timer=5  "/app/src/hashlists/1" -a3 ?a?a?a?a?a?a   --hash-type=99999

while true; do
  if pgrep -f "john" >/dev/null || [ -s ./john/run/john.pot ]; then
    sleep 2

    # john still running
    if [ -s john/run/john.pot ]; then
        # Read first line into variable
        read -r line < john/run/john.pot #read line
        sed -i '1d' john/run/john.pot #remove line
        # echo "JOHN found a password: $line"

        pw=$(echo $line | sed -E 's|\$dynamic_0\$||g' | rev | cut -d: -f1 | rev)
        hash=$(echo $line | sed -E 's|\$dynamic_0\$||g' | rev | cut -d: -f2 | rev)
        pw_hex=$(echo -n $pw | hexdump -ve '1/1 "%02x"')
        
        echo -e "$hash\t$pw\t$pw_hex\t 1234" > $outfile
    fi

    #TODO improve status reporting from john
    #  currently we only report progress (always 100%)
    #  we should also report speed
    #    -->  Press Ctrl-C to abort, or send SIGUSR1 to john process for status 
    #    in hashcat the status line is built like this hashcat/blob/master/src/terminal.c#L2679
    #    but maybe it's easier to rewrite Hashtopolis' hashcat_cracker.py to john_cracker.py

    # //hashcat types.h
    # typedef enum status_rc
    # {
    #   STATUS_INIT               = 0,
    #   STATUS_AUTOTUNE           = 1,
    #   STATUS_SELFTEST           = 2,
    #   STATUS_RUNNING            = 3,
    #   STATUS_PAUSED             = 4,
    #   STATUS_EXHAUSTED          = 5,
    #   STATUS_CRACKED            = 6,
    #   STATUS_ABORTED            = 7,
    #   STATUS_QUIT               = 8,
    #   STATUS_BYPASS             = 9,
    #   STATUS_ABORTED_CHECKPOINT = 10,
    #   STATUS_ABORTED_RUNTIME    = 11,
    #   STATUS_ERROR              = 13,
    #   STATUS_ABORTED_FINISH     = 14,
    #   STATUS_AUTODETECT         = 16,

    # } status_rc_t;

    #always print status
    echo -e "STATUS\t3\tSPEED\t826247260\t1000\tEXEC_RUNTIME\t12.689601\tCURKU\t562511\tPROGRESS\t$skip\t$skip\tRECHASH\t0\t1\tRECSALT\t0\t1\tTEMP\t95\tREJECTED\t0\tUTIL\t0\tPOWER\t-1"
  else
    break
  fi
done

#print cracked password
echo -e "STATUS\t5\tSPEED\t826247260\t1000\tEXEC_RUNTIME\t12.689601\tCURKU\t562511\tPROGRESS\t$skip\t$skip\tRECHASH\t0\t1\tRECSALT\t0\t1\tTEMP\t95\tREJECTED\t0\tUTIL\t0\tPOWER\t-1"
