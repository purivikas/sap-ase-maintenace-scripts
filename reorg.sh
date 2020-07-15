#!/bin/bash
#
# Do a table reorg followed by an update index stats on ${dbname} production DB
#

SYBASE=/apps/sybase
DSQUERY=< ADD YOUR SERVER NAME > 
dbname=< ADD DB NAME > 
export SYBASE DSQUERY dbname

MAILLIST=< ADD YOUR MAIL DISTRIBUTION LIST > 


DbUser= < ADD YOUR USER NAME     > 
DbPass= < ADD YOUR USER PASSWORD > 

#
# Generate a Dynamic REORG script
#
isql -U${DbUser} -P${DbPass} -S${DSQUERY} -w999  << .EOF. | egrep -v "affected\)" | grep -v "(return status" | sed -e "s/  */ /g" | tee /tmp/reorg_${dbname}.sql
use master
go
use ${dbname}
go
exec sp__gen_reorg
go
.EOF.

#
# Execute the script that was generated
#
isql -U${DbUser} -P${DbPass} -S${DSQUERY} -w999  -i /tmp/reorg_${dbname}.sql | tee /tmp/reorg_${dbname}.out

#
# Check which tables failed to reorg due to space limitations
# Run a reorg compact and a reorg rebuild on the indexes for each table affected
#

for table in `cat /tmp/reorg_${dbname}.out | grep "allocate space" | cut -f3 -d"'"`
do
isql -U${DbUser} -P${DbPass} -S${DSQUERY} -w999 <<.EOF. | grep -v "affected)" | grep -v "(return status" | sed -e "s/  */ /g" | tee /tmp/reorg_compact_${table}_${dbname}.sql
use ${dbname}
go
sp__gen_reorg @table='${table}', @online=1, @index=1
go
.EOF.

isql -U${DbUser} -P${DbPass} -S${DSQUERY} -w999  -i /dumps/sybase/reorg_compact_${table}_${dbname}.sql | tee -a /tmp/reorg_${dbname}.out

done

isql -U${DbUser} -P${DbPass} -S${DSQUERY} -D${dbname} -w350 <<.EOF. | grep -v "Row{s} affected" |  grep -v "(return status" | sed -e "s/  */ /g"  > /tmp/updstats_Sat.sql
use ${dbname}
go
exec sp__gen_stats @zero=0, @steps=300
go
.EOF.

isql -U${DbUser} -P${DbPass} -S${DSQUERY} -D${dbname} -i /tmp/updstats.sql | tee -a /tmp/reorg_${dbname}.out

cat /dumps/sybase/reorg_${dbname}.out | mailx -s "UK ${dbname} reorg" ${MAILLIST}

#######
# Fin #
#######
