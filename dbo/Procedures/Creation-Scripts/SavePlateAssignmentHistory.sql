SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePlateAssignmentHistory]
(
 @val [dbo].[PlateAssignmentHistory] READONLY
)
AS
SET NOCOUNT ON;
DECLARE @Output TABLE(
 [Action] NVARCHAR(10) NOT NULL,
 [Id] bigint NOT NULL,
 [Token] int NOT NULL,
 [RowVersion] BIGINT,
 [OldRowVersion] BIGINT
)
MERGE [dbo].[PlateAssignmentHistories] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetId]=S.[AssetId],[AssignedDate]=S.[AssignedDate],[ContractId]=S.[ContractId],[CustomerId]=S.[CustomerId],[IssuedDate]=S.[IssuedDate],[LastModifiedDate]=S.[LastModifiedDate],[PlateHistoryReason]=S.[PlateHistoryReason],[PlateTypeId]=S.[PlateTypeId],[UnassignedDate]=S.[UnassignedDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UserId]=S.[UserId]
WHEN NOT MATCHED THEN
	INSERT ([AssetId],[AssignedDate],[ContractId],[CreatedById],[CreatedTime],[CustomerId],[IssuedDate],[LastModifiedDate],[PlateHistoryReason],[PlateId],[PlateTypeId],[UnassignedDate],[UserId])
    VALUES (S.[AssetId],S.[AssignedDate],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[IssuedDate],S.[LastModifiedDate],S.[PlateHistoryReason],S.[PlateId],S.[PlateTypeId],S.[UnassignedDate],S.[UserId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
