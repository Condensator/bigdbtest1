SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[InitializeBuildDB](
@KeyPath NVARCHAR(max),
@KeyPassword NVARCHAR(max),
@DLLPath NVARCHAR(max),
@MigrationHelperDB NVARCHAR(100),
@IntermediateDB NVARCHAR(100)
)
AS
BEGIN
EXEC CreateSynonymForTables @MigrationHelperDB,'stg'
EXEC CreateSynonymForTables @IntermediateDB,'stg'
ALTER TABLE LegalEntities ALTER COLUMN NonUSDeferredTaxAccountNumber nvarchar(12) MASKED WITH (FUNCTION = 'default()');
ALTER TABLE Parties ALTER COLUMN DateOfBirth date MASKED WITH (FUNCTION = 'default()');
ALTER TABLE DriverContacts ALTER COLUMN DateOfBirth date MASKED WITH (FUNCTION = 'default()');
ALTER TABLE PartyContacts ALTER COLUMN DateOfBirth date MASKED WITH (FUNCTION = 'default()');
EXEC [dbo].[DeployLwCLRAssembly] @KeyPath ,@KeyPassword ,@DLLPath
END

GO
