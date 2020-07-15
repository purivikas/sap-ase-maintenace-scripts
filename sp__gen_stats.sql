use sybsystemprocs
go
if object_id('sp__gen_stats') is not null
        drop proc sp__gen_stats
go
create proc sp__gen_stats @zero integer = 1 , @delete integer = 0, @datetime datetime = null, @steps int = 0, @help integer = 0
as
/****************************************************************
*  sp__gen_stats - Generate update statistics script for a db.  *
*  Execute sp__gen_stats inside a user database to generate an  *
*  'update index statistics <owner>.<object>' script, with the  *
*  statements ordered sequentially based on table row counts.   *
****************************************************************/
set nocount on
declare @olderthan datetime
print "-- * Usage : "
print "-- *    sp__gen_stats [ @zero = 0/1 ], [ @delete = 0/1 ] [ @help = 0/1 ]"
print "-- * Where :"
print "-- *    @zero     - Option to generate update stats for tables with no rows as well."
print "-- *                If 1 then generate, if 0 then do not generate. Default is 1."
print "-- *    @delete   - Option to generate delete stats before the update stats to get rid"
print "-- *                of old or unwanted statistics. If 1 then generate, if 0 then do not"
print "-- *                generate delete statistics statements. Default is 0."
print "-- *    @datetime - Only generate stats for tables with stats older that this date."
print "-- *                Should be a valid date or datetime, eg. 10 Mar 2000 or 03/10/2000."
print "-- *    @steps    - Adds the 'using nnn values' clause to the update stats statement, allowing"
print "-- *                the number of required steps to be specified."
print "-- *    @help     - When 1 then show only this help screen & exit. Default is 0"
print "-- *"
if ( @help = 1 )
        return
print "-- * This run :"
if ( @delete = 1)
  print "-- *   INCLUDE delete statistics statements"
else
  print "-- *   EXCLUDE delete statistics statements"

select @olderthan = isnull(@datetime, getdate())
if ( @zero = 1 )
begin
  print "-- *   INCLUDE empty tables"
  select distinct '-- Update_Stats' =
    case
      when @delete <> 0 then
        'print "delete statistics ' + user_name(o.uid) + "." + o.name + ' -- ' + convert(varchar(10),s.rowcnt) + ' row(s)"' +
        char(10) + 'go' + char(10) + 'delete statistics ' + user_name(o.uid) + "." + o.name + char(10) + 'go' + char(10) +
        'print "update index statistics ' + user_name(o.uid) + "." + o.name + ' -- ' + convert(varchar(10),s.rowcnt) + ' row(s)"' +
        char(10) + 'go' + char(10) + 'update index statistics ' + user_name(o.uid) + "." + o.name +
          case when @steps > 0 then " using " + convert(varchar(10),@steps) + " values" end + char(10) + 'go'
    else
        'print "update index statistics ' + user_name(o.uid) + "." + o.name + ' -- ' + convert(varchar(10),s.rowcnt) + ' row(s)"'
        + char(10) + 'go' + char(10) + 'update index statistics ' + user_name(o.uid) + "." + o.name +
          case when @steps > 0 then " using " + convert(varchar(10),@steps) + " values" end + char(10) + 'go'
    end
  from sysobjects o, systabstats s
  where o.type = 'U'
  and o.name not like 'rs[_]%'
  and o.id = s.id
  and s.rowcnt = 0
  and statmoddate <= @olderthan
  and s.id not in ( select distinct id from systabstats where rowcnt > 0 )
  order by s.rowcnt, o.name
end
else
  print "-- *   EXCLUDE empty tables"

select distinct '-- Update_Stats' =
  case
    when @delete <> 0 then
      'print "delete statistics ' + user_name(o.uid) + "." + o.name + ' -- ' + convert(varchar(10),s.rowcnt) + ' row(s)"' +
      char(10) + 'go' + char(10) + 'delete statistics ' + user_name(o.uid) + "." + o.name + char(10) + 'go' + char(10) +
      'print "update index statistics ' + user_name(o.uid) + "." + o.name + ' -- ' + convert(varchar(10),s.rowcnt) + ' row(s)"' +
      char(10) + 'go' + char(10) + 'update index statistics ' + user_name(o.uid) + "." + o.name +
        case when @steps > 0 then " using " + convert(varchar(10),@steps) + " values" end + char(10) + 'go'
  else
    'print "update index statistics ' + user_name(o.uid) + "." + o.name + ' -- ' + convert(varchar(10),s.rowcnt) + ' row(s)"' +
    char(10) + 'go' + char(10) + 'update index statistics ' + user_name(o.uid) + "." + o.name +
      case when @steps > 0 then " using " + convert(varchar(10),@steps) + " values" end + char(10) + 'go'
  end
from sysobjects o, systabstats s
where o.type = 'U'
and o.name not like 'rs[_]%'
and o.id = s.id
and s.rowcnt <> 0
and statmoddate <= @olderthan
order by s.rowcnt, o.name

return
go

