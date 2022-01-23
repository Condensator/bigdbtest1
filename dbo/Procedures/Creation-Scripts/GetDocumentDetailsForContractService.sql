SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetDocumentDetailsForContractService]
(
@ContractSequenceNumber nvarchar(80),
@RelatedDocumentInstanceIds NVARCHAR(MAX) = ''
)
AS
SET NOCOUNT ON
BEGIN
DECLARE @EntityId BIGINT = (Select TOP 1 ISNULL(leaseFinance.Id,loanFinance.Id) from Contracts C
Left Join LeaseFinances leaseFinance on C.Id= leaseFinance.ContractId AND leaseFinance.IsCurrent=1
Left Join LoanFinances loanFinance on C.Id= loanFinance.ContractId AND loanFinance.IsCurrent=1
where C.SequenceNumber = @ContractSequenceNumber)
DECLARE @ContractId BIGINT = (Select Id from Contracts C
where C.SequenceNumber = @ContractSequenceNumber)
SELECT ID INTO #RelatedInstancesIds FROM ConvertCSVToBigIntTable(@RelatedDocumentInstanceIds, ',')
;WITH CTE_Documents
AS
(
SELECT DISTINCT
DT.Name AS DocumentType,
DSC.SystemStatus AS Status,
DSH.AsOfDate AS StatusDate,
DI.CreatedTime AS CreatedDate,
DocTemp.Name AS Template,
'' AS GeneratedFileLink,
DI.IsActive AS IsActive,
U.FullName ,
DECEC.UserFriendlyName AS EntityType,
DI.Id AS DocumentInstanceId
FROM DocumentHeaders DH
INNER JOIN EntityHeaders EH ON EH.Id = DH.Id
INNER JOIN EntityConfigs EC ON EH.EntityTypeId = EC.Id
INNER JOIN DocumentLists DL on  DH.Id = DL.DocumentHeaderId
INNER JOIN DocumentInstances DI ON DL.DocumentId = DI.Id
INNER JOIN DocumentStatusConfigs DSC on DI.StatusId= DSC.Id
INNER JOIN DocumentStatusHistories DSH on DI.Id = DSH.DocumentInstanceId
INNER JOIN DocumentStatusConfigs DSCDSH on DSH.StatusId= DSCDSH.Id AND DSCDSH.SystemStatus = DSC.SystemStatus AND DSCDSH.IsActive=1
INNER JOIN DocumentTypes DT ON DI.DocumentTypeId = DT.Id
INNER JOIN dbo.DocumentEntityConfigs dec ON DT.EntityId = dec.Id
INNER JOIN EntityConfigs DECEC ON DEC.Id = DECEC.Id
LEFT JOIN LeaseFinances LF ON EH.EntityId = LF.Id ANd LF.IsCurrent = 1 AND EC.Name = 'LeaseFinance'  AND LF.ContractId = @ContractId
LEFT JOIN LoanFinances LFin ON EH.EntityId = LFin.Id ANd LFin.IsCurrent = 1 AND EC.Name = 'LoanFinance' AND LFin.ContractId = @ContractId
LEFT JOIN Users U ON DI.UpdatedById = U.Id
LEFT JOIN DocumentTemplates DocTemp on DI.DocumentTemplateId= DocTemp.Id
WHERE
(EH.EntityId= @EntityId
AND (LF.ContractId = @ContractId OR LFin.ContractId = @ContractId))
OR DI.Id IN (SELECT ID FROM #RelatedInstancesIds)
),
CTE_DocumentDetails
AS
(
SELECT cte.DocumentInstanceId,
A.CreatedTime,
A.AttachedDate,
A.File_Source as AttachmentLink ,
A.File_Source as Attachment_Source,
A.File_Content as Attachment_Content,
CASE WHEN AD.IsGenerated = 1 THEN 'Generated'
WHEN AD.IsPacked = 1 THEN 'Packed'
ELSE 'Attached'
END [Attachment_Type],
ROW_NUMBER() OVER(PARTITION BY cte.DocumentType ORDER BY A.CreatedTime DESC) AS row_number
FROM CTE_Documents cte
LEFT JOIN DocumentAttachments DA on DA.DocumentInstanceId= cte.DocumentInstanceId
LEFT JOIN AttachmentForDocs AD on DA.AttachmentId = AD.Id
LEFT JOIN Attachments A on A.Id =  AD.AttachmentId
)
SELECT
cte.DocumentType,
cte.Status,
cte.StatusDate,
CAST (cte.CreatedDate AS DATE ) AS CreatedDate,
cte.Template,
'' as GeneratedFileLink,
cteDocDetail.AttachmentLink ,
cteDocDetail.Attachment_Source,
cteDocDetail.Attachment_Content,
cteDocDetail.Attachment_Type,
cte.IsActive AS IsActive,
cte.FullName as StatusUpdatedUserName,
cte.EntityType AS EntityType
FROM CTE_Documents cte
join CTE_DocumentDetails  cteDocDetail on cte.DocumentInstanceId=cteDocDetail.DocumentInstanceId
WHERE row_number=1
DROP TABLE #RelatedInstancesIds
END

GO
