SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetGLTransferEntriesForAPI]
@IsGLSegment BIT,
@EffectiveDate DATE,
@GLDealDetail GLDealDetail READONLY
AS
BEGIN
SET NOCOUNT ON;
CREATE TABLE #GLSummary
(
ContractId BIGINT,
ContractSequenceNumber NVARCHAR(40),
NewLineofBusinessId BIGINT,
NewLegalEntityId BIGINT,
RemitToId BIGINT,
GLTransferComment NVARCHAR(500),
NewAcquisitionId NVARCHAR(24),
NewBQNBQ NVARCHAR(16),
LeaseFinanceId BIGINT
);
INSERT INTO #GLSummary(ContractId ,
ContractSequenceNumber,
NewLineofBusinessId ,
NewLegalEntityId ,
RemitToId ,
GLTransferComment,
NewAcquisitionId,
NewBQNBQ,
LeaseFinanceId)
SELECT
C.ID ContractId,
C.SEQUENCENUMBER ContractSequenceNumber,
newLOB.ID NewLineofBusinessId ,
newLE.ID NewLegalEntityId ,
newRemitTo.ID RemitToId ,
GL.GLTransferComment GLTransferComment ,
GL.NewAcquisitionId NewAcquisitionId,
GL.NewBQNBQ NewBQNBQ,
LF.ID LeaseFinanceId
FROM Contracts c
JOIN LeaseFinances LF ON c.ContractType = 'Lease' AND c.Id = LF.ContractId and LF.iscurrent = 1
JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.ID
JOIN LegalEntities LE ON LF.LegalEntityId = LE.Id
JOIN @GLDealDetail GL ON GL.ContractSequenceNumber = c.SEQUENCENUMBER
JOIN LegalEntities newLE ON newLE.LegalEntityNumber = GL.NewLegalEntityNumber AND newLE.STATUS='Active'
JOIN LineofBusinesses newLOB ON newLOB.Name = GL.NewLineofBusinessName AND newLOB.ISACTIVE=1
JOIN LegalEntityRemitToes LEremitTo ON LEremitTo.LegalEntityId = newLE.Id
JOIN RemitToes newRemitTo ON newRemitTo.[UniqueIdentifier] = GL.RemitToUniqueIdentifier AND newRemitTo.Id = LEremitTo.RemitToId AND newRemitTo.ISACTIVE=1
WHERE LE.ID != newLE.ID
AND c.SyndicationType != 'FullSale'
AND LF.BookingStatus = 'Commenced'
AND LFD.CommencementDate <= @EffectiveDate
AND @IsGLSegment = 1
SELECT
*
FROM #GLSummary
DROP TABLE #GLSummary
SET NOCOUNT OFF;
END

GO
