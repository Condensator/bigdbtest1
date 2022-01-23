SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveGLTransferDealDetail]
(
 @val [dbo].[GLTransferDealDetail] READONLY
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
MERGE [dbo].[GLTransferDealDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BlendedItemCodeId]=S.[BlendedItemCodeId],[BookDepreciationTemplateId]=S.[BookDepreciationTemplateId],[ContractId]=S.[ContractId],[ExistingFinanceId]=S.[ExistingFinanceId],[GLSegmentChangeComment]=S.[GLSegmentChangeComment],[HoldingStatusComment]=S.[HoldingStatusComment],[IncomeBalance_Amount]=S.[IncomeBalance_Amount],[IncomeBalance_Currency]=S.[IncomeBalance_Currency],[InstrumentTypeId]=S.[InstrumentTypeId],[IsActive]=S.[IsActive],[NewAcquisitionId]=S.[NewAcquisitionId],[NewBQNBQ]=S.[NewBQNBQ],[NewBranchId]=S.[NewBranchId],[NewCostCenterId]=S.[NewCostCenterId],[NewLegalEntityId]=S.[NewLegalEntityId],[NewLineofBusinessId]=S.[NewLineofBusinessId],[NewSOP]=S.[NewSOP],[RemitToId]=S.[RemitToId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[ValuationAllowanceBlendedItemId]=S.[ValuationAllowanceBlendedItemId]
WHEN NOT MATCHED THEN
	INSERT ([BlendedItemCodeId],[BookDepreciationTemplateId],[ContractId],[CreatedById],[CreatedTime],[ExistingFinanceId],[GLSegmentChangeComment],[GLTransferId],[HoldingStatusComment],[IncomeBalance_Amount],[IncomeBalance_Currency],[InstrumentTypeId],[IsActive],[NewAcquisitionId],[NewBQNBQ],[NewBranchId],[NewCostCenterId],[NewLegalEntityId],[NewLineofBusinessId],[NewSOP],[RemitToId],[ValuationAllowanceBlendedItemId])
    VALUES (S.[BlendedItemCodeId],S.[BookDepreciationTemplateId],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[ExistingFinanceId],S.[GLSegmentChangeComment],S.[GLTransferId],S.[HoldingStatusComment],S.[IncomeBalance_Amount],S.[IncomeBalance_Currency],S.[InstrumentTypeId],S.[IsActive],S.[NewAcquisitionId],S.[NewBQNBQ],S.[NewBranchId],S.[NewCostCenterId],S.[NewLegalEntityId],S.[NewLineofBusinessId],S.[NewSOP],S.[RemitToId],S.[ValuationAllowanceBlendedItemId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
