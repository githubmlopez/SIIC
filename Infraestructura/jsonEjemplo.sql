USE ADMON01
GO

declare @jsonFile  VARCHAR(MAX);

SET @jsonFile = (SELECT * FROM CI_FOLIO  FOR JSON AUTO)

SELECT @jsonFile

  SELECT
  cveEmpresa,
  folio,
  num_folio
  FROM OPENJSON(@jsonFile)
  WITH (
  cveEmpresa       varchar(4)  '$.CVE_EMPRESA',
  folio            varchar(4)  '$.CVE_FOLIO',
  num_folio        numeric(10) '$.NUM_FOLIO'
  )
