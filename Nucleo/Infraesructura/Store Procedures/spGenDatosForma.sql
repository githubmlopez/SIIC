-- select * from FC_PARAM_FORMA
-- exec spGenDatosForma 'ADMIN01','CI_FACTURA'
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
alter procedure [dbo].[spGenDatosForma]  @pbase_datos varchar(30), @pnom_tabla varchar(30)
as
begin

declare  @tipo_componente  varchar(4),
         @b_requerido      bit,
         @long_max         int,
         @long_campo       int,
         @pref_comp        varchar(3)

declare  @nom_tabla   varchar(30),
         @nom_campo   varchar(30),
         @tipo_campo  varchar(20),
         @longitud    int,
         @enteros     int,
         @decimales   int,
         @b_nulo      bit,
         @etiqueta    varchar(20)

declare  @k_fecha     varchar(4),
         @k_numerico  varchar(7),
         @k_varchar   varchar(7),  
         @k_bit       varchar(3),
         @k_label     varchar(2),
         @k_inp_Text  varchar(2),
         @k_ck_box_u  varchar(3),
         @k_inp_fecha varchar(3),
         @k_radio_bot varchar(2),
         @k_falso     bit,
         @k_verdadero bit
      
set  @k_fecha     = 'date'
set  @k_numerico  = 'numeric'
set  @k_varchar   = 'varchar'
set  @k_label     = 'lb'
set  @k_inp_text  = 'it'
set  @k_ck_box_u  = 'cku'
set  @k_inp_fecha = 'itf'
set  @k_radio_bot = 'rb'
set  @k_verdadero = 1
set  @k_falso     = 0

declare cur_tabla_campo cursor for SELECT  tab.NOM_TABLA, tcol.NOM_CAMPO, tcol.TIPO_CAMPO, tcol.LONGITUD,
                                           tcol.ENTEROS, tcol.DECIMALES, tcol.B_NULO, tcex.ETIQUETA                  
FROM FC_TABLA tab, FC_TABLA_COLUMNA tcol, FC_TABLA_COL_EX tcex
WHERE
tab.NOM_TABLA   =  @pnom_tabla      and
tab.NOM_TABLA   =  tcol.NOM_TABLA   and
tcol.NOM_TABLA  =  tcex.NOM_TABLA   and
tcol.NOM_CAMPO  =  tcex.NOM_CAMPO
    
open  cur_tabla_campo

FETCH cur_tabla_campo INTO  @nom_tabla, @nom_campo, @tipo_campo, 
                            @longitud, @enteros, @decimales, @b_nulo, @etiqueta

WHILE (@@fetch_status = 0 )
BEGIN
  if  substring(@tipo_campo,1,4)  =  @k_fecha
  begin
    set  @tipo_componente  =  'date'
    set  @pref_comp        =  @k_inp_fecha
  end
  else
  if  @tipo_campo  =  @k_bit
  begin
    set  @tipo_componente  =  'chxi'
    set  @pref_comp        =  @k_ck_box_u
  end  
  else
  begin
    set  @tipo_componente  =  'intx'
    set  @pref_comp        =  @k_inp_Text
  end

  set  @b_requerido  =  @k_falso

  if @b_nulo  =  @k_falso
  begin
    set  @b_requerido  =  @k_verdadero
  end  

  if  substring(@tipo_campo,1,4)  =  @k_fecha
  begin 
    set @long_max  =  9
  end 
  else
  if  @tipo_campo  =  @k_numerico
  begin
    set  @long_max  =  @enteros
  end
  else
  if  @tipo_campo  =  @k_varchar
  begin
    set  @long_max  =  @longitud
  end
  else
  if  @tipo_campo  =  @k_bit
  begin
    set  @long_max  =  0
  end

  if  @long_max >= 1  and @long_max  <= 4
  begin
    set  @long_campo  =  4
  end
  else
  if  @long_max >= 5  and @long_max <= 10
  begin
    set  @long_campo  =  10
  end
  else
  if  @long_max >= 11  and @long_max  <= 18
  begin
    set  @long_campo  =  10
  end
  else
  if  @long_max >= 19  and @long_max  <= 25
  begin
    set  @long_campo  =  10
  end
  else
  if  @long_max >= 25  and @long_max  <= 40
  begin
    set  @long_campo  =  40
  end
  else
  if  @long_max >= 41  and @long_max  <= 80
  begin
    set  @long_campo  =  80
  end
  if  @long_max >= 80  and @long_max  <= 2000
  begin
    set  @long_campo  =  200
    set  @tipo_componente  =  'itlg'
  end

  insert  FC_PARAM_FORMA 
         (BASE_DATOS,
          NOM_TABLA,
          TX_ETIQUETA,
          NOM_ETIQUETA,
          NOM_CAMPO,
          TIPO_COMPONENTE,
          B_REQUERIDO,
          LONG_CAMPO,
          LONG_MAXIMA,
          SQL_COMPONENTE,
          LONG_LOOKUP,
          LONG_MAX_LKUP,
          SQL_LKUP,
          PATRON_UBIC,
          PATRON_UBIC_B,
          PARAM_VALIDA,
          TIPO_CAMPO,
          LONGITUD,
          ENTEROS,
          DECIMALES,
          LINEA,
          B_BUSCADOR) values
          (@pbase_datos,
           @pnom_tabla,
           @etiqueta,
           @k_label + ltrim(dbo.fnConvierteCamello(@nom_campo)),
           rtrim(@pref_comp) + ltrim(dbo.fnConvierteCamello(@nom_campo)),
           @tipo_componente,
           @b_requerido,
           isnull(@long_campo,0),
           isnull(@long_max,0),
           0,
           0,
           0,
           0,
           ' ',
           ' ',
           ' ',
           @tipo_campo,
           isnull(@longitud,0),
           isnull(@enteros,0),
           isnull(@decimales,0),
           0,
           0)
           
  FETCH cur_tabla_campo INTO  @nom_tabla, @nom_campo, @tipo_campo, 
                            @longitud, @enteros, @decimales, @b_nulo, @etiqueta

END

close cur_tabla_campo

deallocate cur_tabla_campo
end