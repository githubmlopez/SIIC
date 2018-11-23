SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER  procedure [dbo].[spParseaSubstring]  @pSubSstring    varchar(50), 
                                            @pReplParameter varchar(4)   out,
                                            @pOperando      varchar(20)  out,
                                            @pExpresion     varchar(50)  out
as
begin
  
Declare  @posicion         int,
         @sub_string       varchar(50);

Declare  @k_del_substr     varchar(1)

set @k_del_substr  =  ';'

while ((len(@pSubSstring) > 0) and (@pSubSstring <> ''))
begin
--  select ' Substring a analizar ' +  @pSubSstring
  set @posicion  = charindex(@k_del_substr, @pSubSstring)
--  select ' Calculo de posición ' + CONVERT(varchar(4),@posicion) 
  if  @posicion  >  0
  begin
    set @sub_string      = substring(@pSubSstring, 1, @Posicion - 1)
    set @pReplParameter  =  @sub_string;
--    select ' Calculo de primer substring ' + @sub_string 
    set @pSubSstring     = ltrim(substring(@pSubSstring,charindex(@k_del_substr, @pSubSstring)+1, 200))
  end
  set @posicion  = charindex(@k_del_substr, @pSubSstring)
--  select ' Calculo de posición ' + CONVERT(varchar(4),@posicion) 
  if  @posicion  >  0
  begin
    set @sub_string      = substring(@pSubSstring, 1, @Posicion - 1)
    set @pOperando       =  @sub_string;
--    select ' Calculo de primer substring ' + @sub_string 
    set @pSubSstring     = ltrim(substring(@pSubSstring,charindex(@k_del_substr, @pSubSstring)+1, 200))
  end
  set @posicion  = charindex(@k_del_substr, @pSubSstring)
--  select ' Calculo de posición ' + CONVERT(varchar(4),@posicion) 
  if  @posicion  >  0
  begin
    set @sub_string      = substring(@pSubSstring, 1, @Posicion - 1)
    set @pExpresion      =  @sub_string;
--    select ' Calculo de primer substring ' + @sub_string 
    set @pSubSstring     = ltrim(substring(@pSubSstring,charindex(@k_del_substr, @pSubSstring)+1, 200))
  end
end

end