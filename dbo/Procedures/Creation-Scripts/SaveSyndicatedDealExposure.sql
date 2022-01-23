SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveSyndicatedDealExposure]
(
 @val [dbo].[SyndicatedDealExposure] READONLY
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
MERGE [dbo].[SyndicatedDealExposures] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [EntityId]=S.[EntityId],[EntityType]=S.[EntityType],[ExposureDate]=S.[ExposureDate],[IsActive]=S.[IsActive],[OriginationVendorId]=S.[OriginationVendorId],[RNIId]=S.[RNIId],[SyndicatedContractExposure_Amount]=S.[SyndicatedContractExposure_Amount],[SyndicatedContractExposure_Currency]=S.[SyndicatedContractExposure_Currency],[SyndicatedLOCBalanceExposureNonRevolving_Amount]=S.[SyndicatedLOCBalanceExposureNonRevolving_Amount],[SyndicatedLOCBalanceExposureNonRevolving_Currency]=S.[SyndicatedLOCBalanceExposureNonRevolving_Currency],[SyndicatedLOCBalanceExposureRevolving_Amount]=S.[SyndicatedLOCBalanceExposureRevolving_Amount],[SyndicatedLOCBalanceExposureRevolving_Currency]=S.[SyndicatedLOCBalanceExposureRevolving_Currency],[TotalSyndicatedExposures_Amount]=S.[TotalSyndicatedExposures_Amount],[TotalSyndicatedExposures_Currency]=S.[TotalSyndicatedExposures_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[EntityId],[EntityType],[ExposureDate],[IsActive],[OriginationVendorId],[RNIId],[SyndicatedContractExposure_Amount],[SyndicatedContractExposure_Currency],[SyndicatedLOCBalanceExposureNonRevolving_Amount],[SyndicatedLOCBalanceExposureNonRevolving_Currency],[SyndicatedLOCBalanceExposureRevolving_Amount],[SyndicatedLOCBalanceExposureRevolving_Currency],[TotalSyndicatedExposures_Amount],[TotalSyndicatedExposures_Currency])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[EntityId],S.[EntityType],S.[ExposureDate],S.[IsActive],S.[OriginationVendorId],S.[RNIId],S.[SyndicatedContractExposure_Amount],S.[SyndicatedContractExposure_Currency],S.[SyndicatedLOCBalanceExposureNonRevolving_Amount],S.[SyndicatedLOCBalanceExposureNonRevolving_Currency],S.[SyndicatedLOCBalanceExposureRevolving_Amount],S.[SyndicatedLOCBalanceExposureRevolving_Currency],S.[TotalSyndicatedExposures_Amount],S.[TotalSyndicatedExposures_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
