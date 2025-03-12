# TODO: make this command dynamic

FILE=$1
I=$2
DELIMETER=$3
cut -d"$DELIMETER" -f"$I" "$FILE" | sort | uniq -c | sort -nr

