SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveValuationAllowance]
(
 @val [dbo].[ValuationAllowance] READONLY
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
MERGE [dbo].[ValuationAllowances] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Allowance_Amount]=S.[Allowance_Amount],[Allowance_Currency]=S.[Allowance_Currency],[BusinessUnitId]=S.[BusinessUnitId],[Comment]=S.[Comment],[ContractHoldingStatusHistoryId]=S.[ContractHoldingStatusHistoryId],[ContractId]=S.[ContractId],[GLTemplateId]=S.[GLTemplateId],[HFIStatusHistoriesId]=S.[HFIStatusHistoriesId],[IsActive]=S.[IsActive],[JobStepInstanceId]=S.[JobStepInstanceId],[NBV_Amount]=S.[NBV_Amount],[NBV_Currency]=S.[NBV_Currency],[NetInvestmentWithBlended_Amount]=S.[NetInvestmentWithBlended_Amount],[NetInvestmentWithBlended_Currency]=S.[NetInvestmentWithBlended_Currency],[NetInvestmentWithReserve_Amount]=S.[NetInvestmentWithReserve_Amount],[NetInvestmentWithReserve_Currency]=S.[NetInvestmentWithReserve_Currency],[OriginalBookValue_Amount]=S.[OriginalBookValue_Amount],[OriginalBookValue_Currency]=S.[OriginalBookValue_Currency],[PostDate]=S.[PostDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[ValuationReserveBalance_Amount]=S.[ValuationReserveBalance_Amount],[ValuationReserveBalance_Currency]=S.[ValuationReserveBalance_Currency],[WrittenDownNBV_Amount]=S.[WrittenDownNBV_Amount],[WrittenDownNBV_Currency]=S.[WrittenDownNBV_Currency]
WHEN NOT MATCHED THEN
	INSERT ([Allowance_Amount],[Allowance_Currency],[BusinessUnitId],[Comment],[ContractHoldingStatusHistoryId],[ContractId],[CreatedById],[CreatedTime],[GLTemplateId],[HFIStatusHistoriesId],[IsActive],[JobStepInstanceId],[NBV_Amount],[NBV_Currency],[NetInvestmentWithBlended_Amount],[NetInvestmentWithBlended_Currency],[NetInvestmentWithReserve_Amount],[NetInvestmentWithReserve_Currency],[OriginalBookValue_Amount],[OriginalBookValue_Currency],[PostDate],[ValuationReserveBalance_Amount],[ValuationReserveBalance_Currency],[WrittenDownNBV_Amount],[WrittenDownNBV_Currency])
    VALUES (S.[Allowance_Amount],S.[Allowance_Currency],S.[BusinessUnitId],S.[Comment],S.[ContractHoldingStatusHistoryId],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[GLTemplateId],S.[HFIStatusHistoriesId],S.[IsActive],S.[JobStepInstanceId],S.[NBV_Amount],S.[NBV_Currency],S.[NetInvestmentWithBlended_Amount],S.[NetInvestmentWithBlended_Currency],S.[NetInvestmentWithReserve_Amount],S.[NetInvestmentWithReserve_Currency],S.[OriginalBookValue_Amount],S.[OriginalBookValue_Currency],S.[PostDate],S.[ValuationReserveBalance_Amount],S.[ValuationReserveBalance_Currency],S.[WrittenDownNBV_Amount],S.[WrittenDownNBV_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
