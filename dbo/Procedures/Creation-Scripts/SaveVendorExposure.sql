SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveVendorExposure]
(
 @val [dbo].[VendorExposure] READONLY
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
MERGE [dbo].[VendorExposures] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ExposureDate]=S.[ExposureDate],[ExposureVendorId]=S.[ExposureVendorId],[IsActive]=S.[IsActive],[OwnedDirectExposure_Amount]=S.[OwnedDirectExposure_Amount],[OwnedDirectExposure_Currency]=S.[OwnedDirectExposure_Currency],[OwnedIndirectExposure_Amount]=S.[OwnedIndirectExposure_Amount],[OwnedIndirectExposure_Currency]=S.[OwnedIndirectExposure_Currency],[SyndicatedDirectExposure_Amount]=S.[SyndicatedDirectExposure_Amount],[SyndicatedDirectExposure_Currency]=S.[SyndicatedDirectExposure_Currency],[SyndicatedIndirectExposure_Amount]=S.[SyndicatedIndirectExposure_Amount],[SyndicatedIndirectExposure_Currency]=S.[SyndicatedIndirectExposure_Currency],[TotalVendorExposure_Amount]=S.[TotalVendorExposure_Amount],[TotalVendorExposure_Currency]=S.[TotalVendorExposure_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[ExposureDate],[ExposureVendorId],[IsActive],[OwnedDirectExposure_Amount],[OwnedDirectExposure_Currency],[OwnedIndirectExposure_Amount],[OwnedIndirectExposure_Currency],[SyndicatedDirectExposure_Amount],[SyndicatedDirectExposure_Currency],[SyndicatedIndirectExposure_Amount],[SyndicatedIndirectExposure_Currency],[TotalVendorExposure_Amount],[TotalVendorExposure_Currency])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[ExposureDate],S.[ExposureVendorId],S.[IsActive],S.[OwnedDirectExposure_Amount],S.[OwnedDirectExposure_Currency],S.[OwnedIndirectExposure_Amount],S.[OwnedIndirectExposure_Currency],S.[SyndicatedDirectExposure_Amount],S.[SyndicatedDirectExposure_Currency],S.[SyndicatedIndirectExposure_Amount],S.[SyndicatedIndirectExposure_Currency],S.[TotalVendorExposure_Amount],S.[TotalVendorExposure_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
