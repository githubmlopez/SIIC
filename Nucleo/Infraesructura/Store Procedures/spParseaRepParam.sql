declare @oprmErrorMessage varchar (200), @oprmExecStatus int;  
exec spParseaRepParam 1,'q=@1;IN;(''CC'',''CE'');/@2;Like;''%LICENCIA%'';/@3;>=;500;/',
@oprmExecStatus out, @oprmErrorMessage out
select @oprmErrorMessage 
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
alter procedure [dbo].[spParseaRepParam]  @pIdQuery int,
                                          @pStrParam varchar(200),
                                          @oprmExecStatus int out,
                                          @oprmErrorMessage varchar(100) out

as
begin

--create type PARAM_REMPLAZO as table
--(ReplParameter varchar(4),
-- Operando      varchar(20),
-- Expresion     varchar(50))

--create type   ESTRUCT_QUERY as table
--(IdQuery              int,                  
-- SeqElemento          int,
-- TipoElemento         varchar(4),
-- TxElemento           varchar(MAX)) 

declare @utParam_Remplazo as PARAM_REMPLAZO 
declare @utEstruct_Query  as ESTRUCT_QUERY 

Declare  @posicion         int,
         @sub_string       varchar(50),
         @repl_parameter   varchar(4),
         @operando         varchar(20),
         @expresion        varchar(50),
         @sql_statement    nvarchar(600),
         @sql_statement_r  nvarchar(600),
         @valor_remplazo   varchar(100),
         @num_par_rempl    int,
         @cont_itera       int,
         @seq_inst_rempl   int,
         @b_fin_query      bit,
         @tipo_elemento    varchar(2),
         @tx_elemento      varchar(max),
         @tx_elemento_o    varchar(max)
         
Declare  @k_question       varchar(2),
         @k_delimitador    varchar(1),
         @k_fin_cadena     varchar(1),
         @k_falso          bit,
         @k_verdadero      bit,
         @k_remplazo       varchar(1)

set  @posicion       =  0
set  @sub_string     =  ' '
set  @repl_parameter =  ' '
set  @operando       =  ' '
set  @expresion      =  ' '
set  @oprmErrorMessage      =  ' '

set  @k_verdadero    =  1
set  @k_falso        =  0
set  @k_question     =  'q='
set  @k_delimitador  =  '/'
set  @k_fin_cadena   =  ' '
set  @k_remplazo     =  'R'   

if  substring (@pStrParam,1,2) not in (@k_question)
begin
  set  @oprmErrorMessage  =  'Tipo de consulta inválido' 
end
else
begin

  insert into @utEstruct_Query 
  select * from FC_EST_QUERY WHERE ID_QUERY = @pIdQuery
  
--  SELECT * FROM @utEstruct_Query

  if  substring (@pStrParam,1,2) = @k_question
  begin
--    select ' Entre a Proceso  ' 
    set  @pStrParam  =  SUBSTRING(@pStrParam,3,200)
    while ((len(@pStrParam) > 0) and (@pStrParam <> ''))
    begin
--      select ' Entre a while' + @pStrParam 
      set @posicion  = charindex(@k_delimitador, @pStrParam)
--      select ' Calculo de primera posición ' + CONVERT(varchar(4),@posicion) 
      if  @posicion  >  0
      begin
--        select 'La posición es distinta de cero'
        set @sub_string  = substring(@pStrParam, 1, @Posicion - 1)
--        select 'Primer substing ' + @sub_string
        exec spParseaSubstring @sub_string,  @repl_parameter out, @operando out, @expresion out
 
        insert @utParam_Remplazo
        (ReplParameter,
         Operando,
         Expresion) values
        (@repl_parameter,      
         @operando,
         @expresion)
         
        set @pStrParam   = ltrim(substring(@pStrParam,charindex(@k_delimitador, @pStrParam)+1, 200))
      end
    end
  end
end
-- select * from @utParam_Remplazo

set  @seq_inst_rempl  =  1
set  @b_fin_query     =  0
set  @sql_statement   =  ' '
set  @sql_statement_r =  ' '

while  @b_fin_query  =  @k_falso 
begin
--  select ' entre a while '
  if  exists (select 1 from @utEstruct_Query where SeqElemento = @seq_inst_rempl)
  begin
--    select ' Si existió registro ' + CONVERT(varchar(8), @seq_inst_rempl)
    select @tipo_elemento = TipoElemento, @tx_elemento = TxElemento from @utEstruct_Query where 
    SeqElemento = @seq_inst_rempl
    set   @tx_elemento_o  =   @tx_elemento
    if  SUBSTRING(@tipo_elemento,2,1)  =  @k_remplazo
    begin
--      select ' Si es remplazo '  
      set  @cont_itera  =  1
      select  @num_par_rempl  = COUNT(*) from @utParam_Remplazo
      while @num_par_rempl >= @cont_itera 
      begin 
--        select ' Entre a While interno ' +   '@' + convert(varchar(2),@cont_itera) 
        set   @valor_remplazo  =  (select rtrim(Operando) + ' ' + RTRIM(Expresion)    
        from  @utParam_Remplazo 
        where ReplParameter = '@' + convert(varchar(2),@cont_itera))    
--        select ' Valor remplazo ' + @valor_remplazo
        set @sql_statement_r = (select replace(@tx_elemento,'@' + convert(varchar(2),@cont_itera),@valor_remplazo))

        set @tx_elemento     = @sql_statement_r
--        select ' Valor remplazado ' + @tx_elemento
        set @cont_itera = @cont_itera + 1
      end  
--      select ' Original ' + @tx_elemento
--      select ' Remplazado ' + @tx_elemento
      
      if  @tx_elemento_o = @tx_elemento
      begin
        set @sql_statement_r = ' '
      end
      set @sql_statement =  rtrim(@sql_statement) + ' ' + RTRIM(@sql_statement_r) 
    end
    else
    begin
      set @sql_statement =  rtrim(@sql_statement) + ' ' + RTRIM(@tx_elemento) 
    end
    set  @seq_inst_rempl  =  @seq_inst_rempl + 1
  end
  else
  begin
    set @b_fin_query  =  @k_verdadero
  end
end
                                             
  set @sql_statement = (select replace(@sql_statement,'WHERE AND' , 'WHERE'))

--  select ' @sql_statement Total ' + @sql_statement

  SELECT @sql_statement 
  execute sp_executesql @sql_statement 
			
  if @@ERROR <> 0
  begin
	set @oprmExecStatus = 999
	set @oprmErrorMessage = 'Falló al Ejectar @sql_statement ' 
  end			
  
end


 
 
