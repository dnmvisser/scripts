#!/usr/bin/env bash
#
#  Conditional backups of all PostgreSQL databases.
#  Dick Visser <dick@tienhuis.nl>
#
#  Based on ideas of Colin Stearman and Murthy Kambhampaty

if  [ $# -ne 1 ]; then 
  echo "Need one argument: backup destination directory"
  exit
elif [ ! -d $1 ]; then
    echo "Backup destination directory '$1' not accessible";
    exit;
else

  bkpdir="$1"

  ###########  No User Changes needed below this line ###############
#  [ `whoami` != "postgres" ] && \
#    echo "This must be run by user postgres" && \
#    exit

  # Set up some variables
  LogFile="$HOME/fulldump.log"
  Globals="globals.dump"
  Failed=0

  # Switch to backup directory and confirm
  cd $bkpdir
  [ $? -ne 0 ] && echo "Backup directory ($bkpdir) not found. Dump canceled." && exit

  # Delete any earlier logs
  echo -e "Starting Postgres backup at `date`
  Client version: `psql --version`
  Server settings:\n\n\n
  `psql -t -c 'show all'`\n\n" > $LogFile

  # Get the global info (users, etc) from the database
  pg_dumpall -g >$Globals 2>/dev/null
  [ $? -ne 0 ] && echo "[Failed]" && echo "Error dumping globals to $Globals. Dump canceled." && exit
  echo "$(date +%c): Successfully dumped global database data to $Globals" >> $LogFile

  # Dump all databases except templates
  dbs=$(psql -d template1 -t -c "select datname from pg_database where datistemplate='f' order by datname")

  for db in $dbs; do
    echo -en "\n\n\nDumping $db:\n\n" >> $LogFile
    pg_dump -v -v -v -Z 9 --column-inserts -Fc "$db" -f "$bkpdir/$db.pgdump.tmp" >>$LogFile 2>&1 && \
    RETVAL=$?
    if [ -f "$bkpdir/$db.pgdump" ]
      then
      # Compare the two database dumps. Within the first 52 bytes is a
      # timestamp that is not relevant, so skip that part.
      if !(cmp -i 51 "$bkpdir/$db.pgdump" "$bkpdir/$db.pgdump.tmp" > /dev/null 2>&1 ) then
        mv -f "$bkpdir/$db.pgdump.tmp" "$bkpdir/$db.pgdump"
      else
        rm "$bkpdir/$db.pgdump.tmp"
      fi
    else
      mv "$bkpdir/$db.pgdump.tmp" "$bkpdir/$db.pgdump"
    fi
      
    [ $RETVAL -ne 0 ] && echo -en "$FAILED\r\n" && Failed=1
  done

  # Remove old backups that have no corresponding databases anymore
  # This keeps the backups directory a 1:1 representation of the actual
  # database content.
  olddbs=$(find $bkpdir -type f -name "*.pgdump" -exec basename {} \; | sed 's/\.pgdump$//')
  for olddb in $olddbs; do
          stale="yes"
          for db in $dbs; do
                  if [ $db == $olddb ]; then
                          stale="no"
                  fi
          done

          if [ $stale == 'yes' ]; then
                  echo "Removing stale backup of non-existing database '$olddb'" >>$LogFile
                  rm -f "$olddb.pgdump"
          fi
  done



  if [ $Failed -eq 0 ] ; then
    exit 0
  else
    echo "An error occured."
  fi
  #  End of script
fi
