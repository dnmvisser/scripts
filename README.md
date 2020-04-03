Miscellaneous scripts for use in Linux system administration.

# generate_ecc_csr.sh

Generates an ECC private key and corresponding Certificate Signing Request.
The output is sent to `stdout` to prevent key materials from leaking to disk,
and to allow copy/pasting into more secure storage such as HashiCorp Vault,
ansible vault, hiera-eyaml, etc.

The first argument will be treated as the Common Name.
Any further arguments will treated as Subject Altenative Names.
Example:

```bash
dnmvisser@NUC8i5BEK scripts$ ./generate_ecc_csr.sh www.domain.com domain.com
-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQggd2jlxW9tHd0cl9I
JXbN+PFgZSRWqNJxAOShiH6N87WhRANCAAR3a6kJy4psUgICFa7t+OaRXj6H9rzM
mhoUUJfTC4jh0F/vsXFRoB4uXA2awrbhM4RKxrWl11WKa2C9zgHnHzox
-----END PRIVATE KEY-----
-----BEGIN CERTIFICATE REQUEST-----
MIHzMIGaAgEAMAAwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAAR3a6kJy4psUgIC
Fa7t+OaRXj6H9rzMmhoUUJfTC4jh0F/vsXFRoB4uXA2awrbhM4RKxrWl11WKa2C9
zgHnHzoxoDgwNgYJKoZIhvcNAQkOMSkwJzAlBgNVHREEHjAcgg53d3cuZG9tYWlu
LmNvbYIKZG9tYWluLmNvbTAKBggqhkjOPQQDAgNIADBFAiAC/DNVwVQnhmIbIzsY
27A4id1BeWbUsED4pz0W1FvO7AIhAMWEOfV38pCtwHnhzUKRFec5E5oGyfe3dYxO
62NQ1pqG
-----END CERTIFICATE REQUEST-----
```

# pgmailcsv.sh

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

# pg_backup_all

Intended to be run by the postgres super user, this script will iterate through all databases, and create individual backups of them.
On the next run, it will compare the backup with the previous version and only overwrite it when there are differences.
When run regularly you will build up a directory with backups where you can easily spot when databases have changed.
This obviously saves disk space as well.
