zcat $@ \
| awk -F[/:] '{print $4}' \
| sort \
| uniq -c \
| sort -nr
