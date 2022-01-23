SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[VP_GetContractInfo]
(
@OpportunityNumber NVARCHAR(MAX)=NULL,
@ProgramVendor NVARCHAR(MAX)=NULL,
@DealerOrDistributor NVARCHAR(MAX)=NULL,
@IsProgramVendor NVARCHAR(1)=NULL
)
AS
DECLARE @Query NVARCHAR(MAX)
DECLARE @ORIGINATIONJOINCONDITION NVARCHAR(MAX)
DECLARE @ORIGINATIONWHERECONDITION NVARCHAR(MAX)
BEGIN
SET @Query =N'
WITH CTE_Contracts
AS
(
SELECT
C.SequenceNumber AS SequenceNumber,
C.ContractType As ContractType,
CASE
WHEN C.ContractType = ''Lease''
THEN  LE.ApprovalStatus
WHEN C.ContractType = ''Loan'' OR C.ContractType = ''ProgressLoan''
THEN  LO.ApprovalStatus
ELSE
'' ''
END AS ApprovalStatus,
CAST(COALESCE(
CASE
WHEN C.ContractType = ''Lease''
THEN  LE.UpdatedTime
WHEN C.ContractType = ''Loan'' OR C.ContractType = ''ProgressLoan''
THEN  LO.UpdatedTime
END,NULL) AS DATE) AS StatusDate
FROM Opportunities O
JOIN CreditApplications CApp on CApp.Id = O.Id
JOIN CreditProfiles CP on O.Id = CP.OpportunityId
JOIN CreditApprovedStructures CA on CP.Id = CA.CreditProfileId
JOIN Contracts C on CA.Id = C.CreditApprovedStructureId
LEFT JOIN LeaseFinances LE on C.Id = LE.ContractId
LEFT JOIN LoanFinances LO on C.Id = LO.ContractId
ORIGINATIONJOINCONDITION
WHERE (O.Number IN (SELECT Item FROM ConvertCSVToStringTable(@OpportunityNumber,'',''))
OR ORIGINATIONWHERECONDITION)
)
SELECT
SequenceNumber
,ContractType
,ApprovalStatus
,StatusDate
FROM CTE_Contracts
GROUP BY
SequenceNumber
,ContractType
,ApprovalStatus
,StatusDate
'
IF(@IsProgramVendor = '0')
SET @ORIGINATIONJOINCONDITION = 'LEFT JOIN Parties Dealer ON Dealer.Id = O.OriginationSourceId'
ELSE
SET @ORIGINATIONJOINCONDITION = 'LEFT JOIN Parties Dealer ON Dealer.Id = O.OriginationSourceId OR Dealer.Id = CApp.VendorId'
IF(@IsProgramVendor = '0')
SET @ORIGINATIONWHERECONDITION = '(@DealerOrDistributor IS NULL OR @DealerOrDistributor =''''
OR Dealer.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@DealerOrDistributor,'','')))'
ELSE
SET @ORIGINATIONWHERECONDITION = '((@DealerOrDistributor IS NULL OR @DealerOrDistributor ='''' OR
Dealer.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@DealerOrDistributor,'','')))
OR (@ProgramVendor IS NULL OR @ProgramVendor =''''  OR
@ProgramVendor ='''' OR Dealer.PartyNumber IN (SELECT Item FROM ConvertCSVToStringTable(@ProgramVendor,'',''))))'
SET @Query =  REPLACE(@Query, 'ORIGINATIONJOINCONDITION', @ORIGINATIONJOINCONDITION);
SET @Query =  REPLACE(@Query, 'ORIGINATIONWHERECONDITION', @ORIGINATIONWHERECONDITION);
print @ORIGINATIONJOINCONDITION
print @ORIGINATIONWHERECONDITION
print @Query
EXEC sp_executesql @Query,N'
@OpportunityNumber NVARCHAR(MAX)=NULL
,@ProgramVendor NVARCHAR(MAX)=NULL
,@DealerOrDistributor NVARCHAR(MAX)=NULL
,@IsProgramVendor NVARCHAR(1)=NULL'
,@OpportunityNumber
,@ProgramVendor
,@DealerOrDistributor
,@IsProgramVendor
END

GO
