use sybsystemprocs
go
if object_id('sp__gen_reorg') is not null
        drop proc sp__gen_reorg
go
 create proc sp__gen_reorg      @reorg varchar(30) = 'rebuild', @table varchar(30) = '%', @zero int = 1,
                                                        @minrows float = 1, @maxrows float = 99999999999.0, @index int = 0,
                                                        @online int = 0, @bcp int = 1, @changepct int = -1, @help int = 0
as
set nocount on
print "-- * sp__gen_reorg V 1.6.1"
print "-- * Usage : "
print "-- *    sp__gen_reorg [ @reorg = 'reorg_cmd'] [, @table = 'name' ] [, @zero = 0/1 ]"
print "-- *                  [, @minrows = n ] [, @maxrows =                                                                                                                                                                                                                                                              
 n ] [, @index = 0/1 ]"
print "-- *                  [, @online = 0/1 ] [, @bcp = 0/1 ] [, @changepct = nn ]"
print "-- *                  [, @help = 0/1 ]"
print "-- * Where :"
print "-- *    @reorg     - Reorg command to perform. Default is 'rebuild'."
p                                                                                                                                                            
 rint "-- *                 Valid reorgs are : rebuild, compact, reclaim_space, forwarded_rows"
print "-- *    @table     - Generate reorg script for specific table(s) only."
print "-- *                 Accepts wildcards _ and %%. Default is '%%', which is                                                                                                                                                                                                                                         
  all."
print "-- *    @zero      - Option to generate reorg script for tables with no rows as well."
print "-- *                 If 1 then generate, if 0 then do not generate. Default is 1."
print "-- *    @minrows   - Generate reorg script for tables wit                                                                                                                                                                                                                                                          
 h at least @minrows."
print "-- *                 Default is 1."
print "-- *    @maxrows   - Generate reorg script for tables with no more than @maxrows."
print "-- *                 Default is 99999999999.0 (99 Billion)."
print "-- *    @index     - Opti                                                                                                                             
 on to generate reorg rebuild for indexes only instead of table."
print "-- *                 If 1 then generate rebuild for indexes, else full table. Default is 0."
print "-- *    @online    - Option to generate reorg rebuild for 24/7 used databases. Does                                                                                                                                                                                                                                
  a reorg"
print "-- *                 compact and a reorg rebuild for indexes allowing tables and indexes to"
print "-- *                 remain usable. Default is 0."
print "-- *    @bcp       - The 'select into/bulk copy/pllsort' db option is required f                                                                                                                                                                                                                                   
 or reorgs."
print "-- *                 If @bcp=1 the option is left on.  If 0, it is turned off afterwards."
print "-- *                 The default is to leave it on, i.e. 1"
print "-- *    @changepct - Used to indicate the percentage of data change tha                                                                                                                                                                                                                                            
 t should be taken"
print "-- *                 into account. Default is -1 for no threshold."
print "-- *    @help      - When 1 then show only this help screen & exit. Default is 0."
print "-- *"
declare @reorgcmd varchar(30), @supported varchar(8)
if (                                                                                                                                                         
 @help = 1 )
        return
print "-- * This run :"
select @supported = 'noextra'
if @reorg = 'rebuild'
  if charindex('15.', @@version) > 0
    select @supported = 'allpages'
if ( @zero = 1 )
begin
  print "-- *   INCLUDE empty tables"
  select @reorgcmd = @reor                                                                                                                                 
 g
  select "-- Timestamp_start" = "select getdate()"+char(10)+"go"
  select "-- Trace4clientcompat" = "dbcc traceon(7717)"+char(10)+"go"
  select "-- DB_Option" = "use master" +char(10)+"go"+char(10)+ "exec sp_dboption '"+db_name()
    +"', 'select into',                                                                                                                                      
  true"+char(10)+"go"+char(10)+"use "+db_name()+char(10)+"go"+char(10)+"checkpoint"+char(10)+"go"
  if ( @reorgcmd in ('forwarded_rows','compact') and @index = 1 )
  begin
    print "-- *  !! @index forced to 0 as @reorg was set to '%1!', which does not su                                                                                                                                                                                                                                      
 pport indexes", @reorg
    select @index = 0
  end
  if ( @online = 1 )
  begin
    select @reorgcmd = 'compact', @index = 1
    select distinct '-- Reorg_cmd tbl cmpq (0)' =
          'print "reorg ' + @reorgcmd + ' ' + user_name(o.uid) + "." + o.name +                                                                                                                                                                                                                                           
 ' -- ' + convert(varchar(14),s.rowcnt) + ' row(s), datachange='
                  + convert(varchar(30),convert(numeric(12,3),isnull(datachange(user_name(o.uid) + '.' + o.name, NULL, NULL),0)),1) + '"'
          + char(10) + 'go' + char(10) + 'reorg ' + @reorgcmd + ' '                                                                                                                                                                                                                                                       
  + user_name(o.uid) + "." + o.name + char(10) + 'go'
    from sysobjects o, systabstats s, sysstatistics ss
    where o.type = 'U'
        and o.name like @table
    and lockscheme(o.id) in ( 'datarows', 'datapages' )
    and o.name not like 'rs[_]%'
    and o.i                                                                                                                                                  
 d = s.id
    and s.id = ss.id
    and s.rowcnt = 0
    and s.id not in ( select distinct id from systabstats where rowcnt > 0 )
    and isnull(datachange(user_name(o.uid) + '.' + o.name, NULL, NULL),0) >= @changepct
    order by s.rowcnt, o.name
  end
                                                                                                                                                             
  if ( @index = 0 )
  begin
    select distinct '-- Reorg_cmd tbl rbld (0)' =
          'print "reorg ' + @reorgcmd + ' ' + user_name(o.uid) + "." + o.name + ' -- ' + convert(varchar(14),s.rowcnt) + ' row(s), datachange='
                  + convert(varchar(30),convert(                                                                                                             
 numeric(12,3),isnull(datachange(user_name(o.uid) + '.' + o.name, NULL, NULL),0)),1) + '"'
          + char(10) + 'go' + char(10) + 'reorg ' + @reorgcmd + ' ' + user_name(o.uid) + "." + o.name + char(10) + 'go'
    from sysobjects o, systabstats s, sysstat                                                                                                                
 istics ss
    where o.type = 'U'
        and o.name like @table
    and lockscheme(o.id) in ( 'datarows', 'datapages', @supported )
    and o.name not like 'rs[_]%'
    and o.id = s.id
    and s.id = ss.id
    and s.rowcnt = 0
    and s.id not in ( select distin                                                                                                                          
 ct id from systabstats where rowcnt > 0 )
    and isnull(datachange(user_name(o.uid) + '.' + o.name, NULL, NULL),0) >= @changepct
    order by s.rowcnt, o.name
  end
  else
  begin
    select @reorgcmd = 'rebuild'
    select distinct '-- Reorg_cmd idx rbl                                                                                                                    
 d (0)' =
          'print "reorg ' + @reorgcmd + ' ' + user_name(o.uid) + "." + o.name + ' ' + si.name + ' -- ' + convert(varchar(14),s.rowcnt) + ' row(s), datachange='
                  + convert(varchar(30),convert(numeric(12,3),isnull(datachange(user_name(o.uid) + '                                                                                                                                                                                                                      
 .' + o.name, NULL, NULL),0)),1) + '"'
          + char(10) + 'go' + char(10) + 'reorg ' + @reorgcmd + ' ' + user_name(o.uid) + "." + o.name + ' ' + si.name + char(10) + 'go'
    from sysobjects o, sysindexes si, systabstats s, sysstatistics ss
    where o                                                                                                                                                  
 .type = 'U'
        and o.name like @table
    and lockscheme(o.id) in ( 'datarows', 'datapages', @supported )
    and o.name not like 'rs[_]%'
    and o.id = s.id
    and s.id = si.id
    and s.id = ss.id
    and si.indid between 1 and 254
    and s.indid = 0
                                                                                                                                                             
    and s.rowcnt = 0
    and s.id not in ( select distinct id from systabstats where rowcnt > 0 )
    and isnull(datachange(user_name(o.uid) + '.' + o.name, NULL, NULL),0) >= @changepct
    order by s.rowcnt, o.name
  end
end
else
begin
  print "-- *   EXC                                                                                                                                          
 LUDE empty tables"
  select "-- Timestamp_start" = "select getdate()"+char(10)+"go"
  select "-- DB_Option_true" = "use master" +char(10)+"go"+char(10)+    "exec sp_dboption '"+db_name()
    +"', 'select into', true"+char(10)+"go"+char(10)+"use "+db_name()+c                                                                                                                                                                                                                                                   
 har(10)+"go"+char(10)+"checkpoint"+char(10)+"go"
end

if ( @online = 1 )
begin
  select @reorgcmd = 'compact', @index = 1
  select distinct '-- Reorg_cmd tbl cmpq (>0)' =
        'print "reorg compact ' + user_name(o.uid) + "." + o.name + ' -- ' + convert                                                                                                                                                                                                                                      
 (varchar(14),s.rowcnt) + ' row(s), datachange='
                  + convert(varchar(30),convert(numeric(12,3),isnull(datachange(user_name(o.uid) + '.' + o.name, NULL, NULL),0)),1) + '"'
        + char(10) + 'go' + char(10) + 'reorg ' + @reorgcmd + ' ' + user_name(o.uid                                                                                                                                                                                                                                       
 ) + "." + o.name + char(10) + 'go'
  from sysobjects o, systabstats s, sysstatistics ss
  where o.type = 'U'
  and o.name like @table
  and lockscheme(o.id) in ( 'datarows', 'datapages' )
  and o.name not like 'rs[_]%'
  and o.id = s.id
  and s.id = ss.id                                                                                                                                           

--  and s.rowcnt <> 0
  and s.rowcnt between @minrows and @maxrows
  and isnull(datachange(user_name(o.uid) + '.' + o.name, NULL, NULL),0) >= @changepct
  order by s.rowcnt, o.name
end
if ( @index = 0 )
begin
   select distinct '-- Reorg_cmd tbl rbld (>0                                                                                                                
 )' =
        'print "reorg ' + @reorgcmd + ' ' + user_name(o.uid) + "." + o.name + ' -- ' + convert(varchar(14),s.rowcnt) + ' row(s), datachange='
                  + convert(varchar(30),convert(numeric(12,3),isnull(datachange(user_name(o.uid) + '.' + o.name, NULL, NUL                                                                                                                                                                                                
 L),0)),1) + '"'
        + char(10) + 'go' + char(10) + 'reorg ' + @reorgcmd + ' ' + user_name(o.uid) + "." + o.name + char(10) + 'go'
  from sysobjects o, systabstats s, sysstatistics ss
  where o.type = 'U'
  and o.name like @table
  and lockscheme(o.id)                                                                                                                                       
  in ( 'datarows', 'datapages', @supported )
  and o.name not like 'rs[_]%'
  and o.id = s.id
  and s.id = ss.id
--  and s.rowcnt <> 0
  and s.rowcnt between @minrows and @maxrows
  and isnull(datachange(user_name(o.uid) + '.' + o.name, NULL, NULL),0) >= @                                                                                                                                                                                                                                              
 changepct
  order by s.rowcnt, o.name
end
else
begin
  select @reorgcmd = 'rebuild'
  select distinct '-- Reorg_cmd idx rbld (>0)' =
        'print "reorg ' + @reorgcmd + ' ' + user_name(o.uid) + "." + o.name + ' ' + si.name + ' -- ' + convert(varchar(14)                                                                                                                                                                                                
 ,s.rowcnt) + ' row(s), datachange='
                  + convert(varchar(30),convert(numeric(12,3),isnull(datachange(user_name(o.uid) + '.' + o.name, NULL, NULL),0)),1) + '"'
        + char(10) + 'go' + char(10) + 'reorg ' + @reorgcmd + ' ' + user_name(o.uid) + "." + o.                                                                                                                                                                                                                           
 name + ' ' + si.name + char(10) + 'go'
  from sysobjects o, sysindexes si, systabstats s, sysstatistics ss
  where o.type = 'U'
  and lockscheme(o.id) in ( 'datarows', 'datapages', @supported )
  and o.name like @table
  and o.name not like 'rs[_]%'
  and                                                                                                                                                        
  o.id = s.id
  and s.id = si.id
  and s.id = ss.id
  and si.indid between 1 and 254
  and s.indid = 0
--  and s.rowcnt <> 0
  and s.rowcnt between @minrows and @maxrows
  and isnull(datachange(user_name(o.uid) + '.' + o.name, NULL, NULL),0) >= @changepct
                                                                                                                                                             
   order by s.rowcnt, o.name, si.indid
end
select "-- Disable trace4clientcompat" = "dbcc traceoff (7717)"+char(10)+"go"
if @bcp = 0
begin
  select "-- DB_Option_false" = "use master" +char(10)+"go"+char(10)+   "exec sp_dboption '"+db_name()
  +"', 'select i                                                                                                                                             
 nto', false"+char(10)+"go"+char(10)+"use "+db_name()+char(10)+"go"+char(10)+"checkpoint"+char(10)+"go"
end
else
begin
  select "-- DB_Option_false" = "-- use master" +char(10)+"-- go"+char(10)+     "-- exec sp_dboption '"+db_name()
  +"', 'select into', false                                                                                                                                  
 "+char(10)+"-- go"+char(10)+"-- use "+db_name()+char(10)+"-- go"+char(10)+"-- checkpoint"+char(10)+"-- go"
end
select "-- Timestamp_end" = "select getdate()"+char(10)+"go"

return
