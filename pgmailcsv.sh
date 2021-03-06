#!/usr/bin/env bash
#
# Script to send the result of a PostgreSQL query as CSV by e-mail.
# Much requested by office clerks.
if [ $# -ne 3 ]; then
  echo "Error...
  
This script needs exactly THREE arguments:

  1. Database name
  2. E-mail address
  3. SQL query, surrounded by DOUBLE QUOTES

Example:
$0 mydb sysadmin@terena.org \"SELECT fname FROM users\"

Long or complicated queries can be stored in an SQL text file:

$0 mydb sysadmin@terena.org \"\`cat complicated.sql\`\"
"
  exit
else
  RAND=$RANDOM

  UTF8_CSV="Database_results_`date +%F_%Hh%Mm%Ss`_MailMarge_UTF8_$RAND.csv"
  UTF16_CSV="Database_results_`date +%F_%Hh%Mm%Ss`_Excel_UTF16_$RAND.csv"
  # LATIN1 is needed, UTF8 borks out on CSV
  psql "$1" -Atc "COPY ($3) to '/tmp/$UTF8_CSV' WITH CSV HEADER" 
  
  (echo -en '\xFF\xFE\c' & iconv -t UTF-16LE "/tmp/$UTF8_CSV") > "/tmp/$UTF16_CSV"
cd /tmp
from="Postgres user <postgres>"
to=$2
subject="Database query results"
boundary="ZZ_/afg6432dfgkl.94531q"
declare -a attachments
attachments=("$UTF8_CSV" "$UTF16_CSV")
body="Please find attached the results of your database query.

This message contains two different attachments.


$UTF16_CSV

This is meant to be used with Microsoft Excel.
Just double clicking it cause all fields to be displayed as one, which renders it useless.
Follow these instructions to use the data properly in Microsoft Excel:

* File -> Open (make sure the filter is set to 'All Files')
* Delimited
* Next
* Delimiters: comma only
* Finish



$UTF8_CSV

This is for use with utilities like Mail Merge for Thunderbird (https://addons.mozilla.org/en-US/thunderbird/addon/mail-merge).



FYI, the query to the '$1' database was:

$3

Best regards,

-- 
The PostgreSQL database user
"

# Build headers
{
printf '%s\n' "From: $from
To: $to
Subject: $subject
Mime-Version: 1.0
Content-Type: multipart/mixed; boundary=\"$boundary\"

--${boundary}
Content-Type: text/plain; charset=\"US-ASCII\"
Content-Transfer-Encoding: 7bit
Content-Disposition: inline

$body
"
 
# now loop over the attachments, guess the type
# and produce the corresponding part, encoded base64
for file in "${attachments[@]}"; do
  [ ! -f "/tmp/$file" ] && echo "Warning: attachment $file not found, skipping" >&2 && continue
  
printf '%s\n' "--${boundary}
Content-Type: text/csv
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename=\"$file\"
"
 
base64 "/tmp/$file"
echo
done

# print last boundary with closing --
printf '%s\n' "--${boundary}--"

} | /usr/sbin/sendmail -t -oi


fi
