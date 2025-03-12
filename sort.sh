# TODO: make this command dynamic

cut -d',' -f4 withdraw.csv | sort | uniq -c | sort -nr


