SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCreditDecisionExposure]
(
 @val [dbo].[CreditDecisionExposure] READONLY
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
MERGE [dbo].[CreditDecisionExposures] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AsOfDate]=S.[AsOfDate],[Direct_Amount]=S.[Direct_Amount],[Direct_Currency]=S.[Direct_Currency],[ExposureType]=S.[ExposureType],[Indirect_Amount]=S.[Indirect_Amount],[Indirect_Currency]=S.[Indirect_Currency],[PrimaryCustomer_Amount]=S.[PrimaryCustomer_Amount],[PrimaryCustomer_Currency]=S.[PrimaryCustomer_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AsOfDate],[CreatedById],[CreatedTime],[CreditDecisionId],[Direct_Amount],[Direct_Currency],[ExposureType],[Indirect_Amount],[Indirect_Currency],[PrimaryCustomer_Amount],[PrimaryCustomer_Currency])
    VALUES (S.[AsOfDate],S.[CreatedById],S.[CreatedTime],S.[CreditDecisionId],S.[Direct_Amount],S.[Direct_Currency],S.[ExposureType],S.[Indirect_Amount],S.[Indirect_Currency],S.[PrimaryCustomer_Amount],S.[PrimaryCustomer_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
