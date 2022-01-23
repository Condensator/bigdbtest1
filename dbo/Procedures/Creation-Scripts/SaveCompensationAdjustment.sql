SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCompensationAdjustment]
(
 @val [dbo].[CompensationAdjustment] READONLY
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
MERGE [dbo].[CompensationAdjustments] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AdditionalComments]=S.[AdditionalComments],[ContractId]=S.[ContractId],[CurrencyType]=S.[CurrencyType],[LineofBusinessId]=S.[LineofBusinessId],[LogDate]=S.[LogDate],[PaymentAmount_Amount]=S.[PaymentAmount_Amount],[PaymentAmount_Currency]=S.[PaymentAmount_Currency],[PaymentDate]=S.[PaymentDate],[PaymentType]=S.[PaymentType],[RelatedBusinessName]=S.[RelatedBusinessName],[SalesOfficerId]=S.[SalesOfficerId],[Status]=S.[Status],[SwapOrSyndicatedFeeIncome_Amount]=S.[SwapOrSyndicatedFeeIncome_Amount],[SwapOrSyndicatedFeeIncome_Currency]=S.[SwapOrSyndicatedFeeIncome_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[YTDVolumeAdjustments_Amount]=S.[YTDVolumeAdjustments_Amount],[YTDVolumeAdjustments_Currency]=S.[YTDVolumeAdjustments_Currency]
WHEN NOT MATCHED THEN
	INSERT ([AdditionalComments],[ContractId],[CreatedById],[CreatedTime],[CurrencyType],[LineofBusinessId],[LogDate],[PaymentAmount_Amount],[PaymentAmount_Currency],[PaymentDate],[PaymentType],[RelatedBusinessName],[SalesOfficerId],[Status],[SwapOrSyndicatedFeeIncome_Amount],[SwapOrSyndicatedFeeIncome_Currency],[YTDVolumeAdjustments_Amount],[YTDVolumeAdjustments_Currency])
    VALUES (S.[AdditionalComments],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[CurrencyType],S.[LineofBusinessId],S.[LogDate],S.[PaymentAmount_Amount],S.[PaymentAmount_Currency],S.[PaymentDate],S.[PaymentType],S.[RelatedBusinessName],S.[SalesOfficerId],S.[Status],S.[SwapOrSyndicatedFeeIncome_Amount],S.[SwapOrSyndicatedFeeIncome_Currency],S.[YTDVolumeAdjustments_Amount],S.[YTDVolumeAdjustments_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
