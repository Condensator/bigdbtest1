SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLeveragedLease]
(
 @val [dbo].[LeveragedLease] READONLY
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
MERGE [dbo].[LeveragedLeases] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AcquisitionId]=S.[AcquisitionId],[AmortDocument_Content]=S.[AmortDocument_Content],[AmortDocument_Source]=S.[AmortDocument_Source],[AmortDocument_Type]=S.[AmortDocument_Type],[AssetDescription]=S.[AssetDescription],[AssetTypeId]=S.[AssetTypeId],[BookingGLTemplateId]=S.[BookingGLTemplateId],[CommencementDate]=S.[CommencementDate],[ContractId]=S.[ContractId],[ContractOriginationId]=S.[ContractOriginationId],[CostCenterId]=S.[CostCenterId],[CustomerId]=S.[CustomerId],[Debt_Amount]=S.[Debt_Amount],[Debt_Currency]=S.[Debt_Currency],[DeferredTaxGLTemplateId]=S.[DeferredTaxGLTemplateId],[EquipmentCost_Amount]=S.[EquipmentCost_Amount],[EquipmentCost_Currency]=S.[EquipmentCost_Currency],[EquityInvestment_Amount]=S.[EquityInvestment_Amount],[EquityInvestment_Currency]=S.[EquityInvestment_Currency],[HoldingStatus]=S.[HoldingStatus],[IDC_Amount]=S.[IDC_Amount],[IDC_Currency]=S.[IDC_Currency],[IncomeGLTemplateId]=S.[IncomeGLTemplateId],[InstrumentTypeId]=S.[InstrumentTypeId],[IsCurrent]=S.[IsCurrent],[LegalEntityId]=S.[LegalEntityId],[LeveragedLeasePartnerId]=S.[LeveragedLeasePartnerId],[LineofBusinessId]=S.[LineofBusinessId],[LongTermDebt_Amount]=S.[LongTermDebt_Amount],[LongTermDebt_Currency]=S.[LongTermDebt_Currency],[MaturityDate]=S.[MaturityDate],[PostDate]=S.[PostDate],[ReferenceLeaseId]=S.[ReferenceLeaseId],[RentalReceivableCodeId]=S.[RentalReceivableCodeId],[RentalsReceivable_Amount]=S.[RentalsReceivable_Amount],[RentalsReceivable_Currency]=S.[RentalsReceivable_Currency],[ResidualValue_Amount]=S.[ResidualValue_Amount],[ResidualValue_Currency]=S.[ResidualValue_Currency],[Status]=S.[Status],[Term]=S.[Term],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AcquisitionId],[AmortDocument_Content],[AmortDocument_Source],[AmortDocument_Type],[AssetDescription],[AssetTypeId],[BookingGLTemplateId],[CommencementDate],[ContractId],[ContractOriginationId],[CostCenterId],[CreatedById],[CreatedTime],[CustomerId],[Debt_Amount],[Debt_Currency],[DeferredTaxGLTemplateId],[EquipmentCost_Amount],[EquipmentCost_Currency],[EquityInvestment_Amount],[EquityInvestment_Currency],[HoldingStatus],[IDC_Amount],[IDC_Currency],[IncomeGLTemplateId],[InstrumentTypeId],[IsCurrent],[LegalEntityId],[LeveragedLeasePartnerId],[LineofBusinessId],[LongTermDebt_Amount],[LongTermDebt_Currency],[MaturityDate],[PostDate],[ReferenceLeaseId],[RentalReceivableCodeId],[RentalsReceivable_Amount],[RentalsReceivable_Currency],[ResidualValue_Amount],[ResidualValue_Currency],[Status],[Term])
    VALUES (S.[AcquisitionId],S.[AmortDocument_Content],S.[AmortDocument_Source],S.[AmortDocument_Type],S.[AssetDescription],S.[AssetTypeId],S.[BookingGLTemplateId],S.[CommencementDate],S.[ContractId],S.[ContractOriginationId],S.[CostCenterId],S.[CreatedById],S.[CreatedTime],S.[CustomerId],S.[Debt_Amount],S.[Debt_Currency],S.[DeferredTaxGLTemplateId],S.[EquipmentCost_Amount],S.[EquipmentCost_Currency],S.[EquityInvestment_Amount],S.[EquityInvestment_Currency],S.[HoldingStatus],S.[IDC_Amount],S.[IDC_Currency],S.[IncomeGLTemplateId],S.[InstrumentTypeId],S.[IsCurrent],S.[LegalEntityId],S.[LeveragedLeasePartnerId],S.[LineofBusinessId],S.[LongTermDebt_Amount],S.[LongTermDebt_Currency],S.[MaturityDate],S.[PostDate],S.[ReferenceLeaseId],S.[RentalReceivableCodeId],S.[RentalsReceivable_Amount],S.[RentalsReceivable_Currency],S.[ResidualValue_Amount],S.[ResidualValue_Currency],S.[Status],S.[Term])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
