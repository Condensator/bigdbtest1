SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDriverHistory]
(
 @val [dbo].[DriverHistory] READONLY
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
MERGE [dbo].[DriverHistories] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActivationDate]=S.[ActivationDate],[AssetId]=S.[AssetId],[AssignedDate]=S.[AssignedDate],[ContractId]=S.[ContractId],[CustomerId]=S.[CustomerId],[DeactivationDate]=S.[DeactivationDate],[LicenseExpiryDate]=S.[LicenseExpiryDate],[LicenseIssueDate]=S.[LicenseIssueDate],[LicenseNumber]=S.[LicenseNumber],[ReasonDescription]=S.[ReasonDescription],[RelatedDriverId]=S.[RelatedDriverId],[SourceId]=S.[SourceId],[SourceModule]=S.[SourceModule],[StateId]=S.[StateId],[UnassignedDate]=S.[UnassignedDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ActivationDate],[AssetId],[AssignedDate],[ContractId],[CreatedById],[CreatedTime],[CustomerId],[DeactivationDate],[DriverId],[LicenseExpiryDate],[LicenseIssueDate],[LicenseNumber],[ReasonDescription],[RelatedDriverId],[SourceId],[SourceModule],[StateId],[UnassignedDate])
    VALUES (S.[ActivationDate],S.[AssetId],S.[AssignedDate],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[DeactivationDate],S.[DriverId],S.[LicenseExpiryDate],S.[LicenseIssueDate],S.[LicenseNumber],S.[ReasonDescription],S.[RelatedDriverId],S.[SourceId],S.[SourceModule],S.[StateId],S.[UnassignedDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
