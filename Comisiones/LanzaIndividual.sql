Declare @id_cxc int,
        @id_concilia_cxc int

set @id_cxc = 864

SELECT * FROM CI_CUPON_COMISION WHERE ID_CXC = @id_cxc
SELECT * FROM CI_FACTURA WHERE ID_CXC = @id_cxc AND SERIE = 'CUM' and CVE_EMPRESA = 'CU'
SELECT * FROM CI_ITEM_C_X_C WHERE ID_CXC = @id_cxc AND SERIE = 'CUM' and CVE_EMPRESA = 'CU'

DELETE FROM CI_CUPON_COMISION WHERE ID_CXC = @id_cxc
UPDATE CI_FACTURA SET B_FACTURA_PAGADA = 0, FIRMA = ' '  WHERE ID_CXC = @id_cxc AND SERIE = 'CUM' and CVE_EMPRESA = 'CU'

SELECT @id_concilia_cxc = ID_CONCILIA_CXC FROM CI_FACTURA WHERE ID_CXC = @id_cxc AND SERIE = 'CUM' and CVE_EMPRESA = 'CU'

EXEC spCalculaComisionV2 2017, 05, @id_concilia_cxc, 46

