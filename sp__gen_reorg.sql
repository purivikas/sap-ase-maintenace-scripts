use sybsystemprocs
go
if object_id('sp__gen_reorg') is not null
        drop proc sp__gen_reorg
go
create proc sp__gen_reorg @zero integer = 1 , @help integer = 0
as
/****************************************************************
*  sp__gen_reorg - Generate reorg rebuild scripts for a db.     *
*  Execute sp__gen_reorg inside a user database to generate a   *
*  'reorg rebuild <owner>.<object>' script, with the statements *
*  ordered sequentially based on table row counts.              *
****************************************************************/
set nocount on
print "-- * Usage : "
print "-- *    sp__gen_reorg [ @zero = 0/1 ] [, @help = 0/1 ]"
print "-- * Where :"
print "-- *    @zero     - Option to generate reorg script for tables with no rows as well." print "-- *                If 1 then generate, if 0 then do not generate. Default is 1."
print "-- *    @help     - When 1 then show only this help screen & exit. Default is 0"
print "-- *"
if ( @help = 1 )
        return
print "-- * This run :"
if ( @zero = 1 )
begin
  print "-- *   INCLUDE empty tables"
  select "-- Timestamp_start" = "select getdate()"+char(10)+"go"
  select "-- Trace4clientcompat" = "dbcc traceon(7717)"+char(10)+"go"
  select "-- DB_Option" = "use master" +char(10)+"go"+char(10)+ "exec sp_dboption '"+db_name()
    +"', 'select into', true"+char(10)+"go"+char(10)+"use "+db_name()+char(10)+"go"+char(10)+"checkpoint"+char(10)+"go"
  select distinct '-- Reorg_Rebuild' =
        'print "reorg rebuild ' + user_name(o.uid) + "." + o.name + ' -- ' + convert(varchar(10),s.rowcnt) + ' row(s)"'
        + char(10) + 'go' + char(10) + 'reorg rebuild ' + user_name(o.uid) + "." + o.name + char(10) + 'go'
  from sysobjects o, systabstats s, sysstatistics ss
  where o.type = 'U'
  and lockscheme(o.id) != 'allpages'
  and o.name not like 'rs[_]%'
  and o.id = s.id
  and s.id = ss.id
  and s.rowcnt = 0
  and s.id not in ( select distinct id from systabstats where rowcnt > 0 )
  order by s.rowcnt, o.name
end
else
begin
  print "-- *   EXCLUDE empty tables"
  select "-- Timestamp_start" = "select getdate()"+char(10)+"go"
  select "-- DB_Option_true" = "use master" +char(10)+"go"+char(10)+    "exec sp_dboption '"+db_name()
    +"', 'select into', true"+char(10)+"go"+char(10)+"use "+db_name()+char(10)+"go"+char(10)+"checkpoint"+char(10)+"go"
end

select distinct '-- Reorg_Rebuild' =
    'print "reorg rebuild ' + user_name(o.uid) + "." + o.name + ' -- ' + convert(varchar(10),s.rowcnt) + ' row(s)"' +
    char(10) + 'go' + char(10) + 'reorg rebuild ' + user_name(o.uid) + "." + o.name + char(10) + 'go'
from sysobjects o, systabstats s, sysstatistics ss
where o.type = 'U'
and lockscheme(o.id) != 'allpages'
and o.name not like 'rs[_]%'
and o.id = s.id
and s.id = ss.id
and s.rowcnt <> 0
order by s.rowcnt, o.name

select "-- Disable trace4clientcompat" = "dbcc traceoff (7717)"+char(10)+"go"
select "-- DB_Option_false" = "use master" +char(10)+"go"+char(10)+     "exec sp_dboption '"+db_name()
  +"', 'select into', false"+char(10)+"go"+char(10)+"use "+db_name()+char(10)+"go"+char(10)+"checkpoint"+char(10)+"go"
select "-- Timestamp_end" = "select getdate()"+char(10)+"go"

return
go

