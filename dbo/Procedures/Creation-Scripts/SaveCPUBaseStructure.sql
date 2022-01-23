SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCPUBaseStructure]
(
 @val [dbo].[CPUBaseStructure] READONLY
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
MERGE [dbo].[CPUBaseStructures] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AssetPaymentScheduleUpload_Content]=S.[AssetPaymentScheduleUpload_Content],[AssetPaymentScheduleUpload_Source]=S.[AssetPaymentScheduleUpload_Source],[AssetPaymentScheduleUpload_Type]=S.[AssetPaymentScheduleUpload_Type],[BaseAmount_Amount]=S.[BaseAmount_Amount],[BaseAmount_Currency]=S.[BaseAmount_Currency],[BaseUnit]=S.[BaseUnit],[DistributionBasis]=S.[DistributionBasis],[FrequencyStartDate]=S.[FrequencyStartDate],[IsAggregate]=S.[IsAggregate],[IsRegularPaymentStream]=S.[IsRegularPaymentStream],[NumberofPayments]=S.[NumberofPayments],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AssetPaymentScheduleUpload_Content],[AssetPaymentScheduleUpload_Source],[AssetPaymentScheduleUpload_Type],[BaseAmount_Amount],[BaseAmount_Currency],[BaseUnit],[CreatedById],[CreatedTime],[DistributionBasis],[FrequencyStartDate],[Id],[IsAggregate],[IsRegularPaymentStream],[NumberofPayments])
    VALUES (S.[AssetPaymentScheduleUpload_Content],S.[AssetPaymentScheduleUpload_Source],S.[AssetPaymentScheduleUpload_Type],S.[BaseAmount_Amount],S.[BaseAmount_Currency],S.[BaseUnit],S.[CreatedById],S.[CreatedTime],S.[DistributionBasis],S.[FrequencyStartDate],S.[Id],S.[IsAggregate],S.[IsRegularPaymentStream],S.[NumberofPayments])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
