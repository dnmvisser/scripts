# scripts
Miscellaneous scripts for use in Linux system administration.

pgmailcsv
========

You are building front ends for databases and web applications, but the project manager or PR person eventually asks you for the only thing they understand: an Excel spread sheet.
Save yourself the trouble and send the results of a PostgreSQL query by e-mail as a CSV attachment.

The script assumes the current account has access to the database. It requires three arguments:

 1. Database name
 2. E-mail address
 3. SQL query, surrounded by **double quotes**

Example:

> ./pgmailcsv mydb sysadmin@terena.org "SELECT fname, lname, email FROM users"

This will trigger an e-mail with two attachments.
One will have UTF-16LE encoding, which can be used by Microsoft Excel, the other one is UTF-8, which can be used by other applications.
