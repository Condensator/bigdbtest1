SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLeveragedLeaseAmendment]
(
 @val [dbo].[LeveragedLeaseAmendment] READONLY
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
MERGE [dbo].[LeveragedLeaseAmendments] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AmortDocument_Content]=S.[AmortDocument_Content],[AmortDocument_Source]=S.[AmortDocument_Source],[AmortDocument_Type]=S.[AmortDocument_Type],[ContractId]=S.[ContractId],[CurrentLeveragedLeaseId]=S.[CurrentLeveragedLeaseId],[Debt_Amount]=S.[Debt_Amount],[Debt_Currency]=S.[Debt_Currency],[EquipmentCost_Amount]=S.[EquipmentCost_Amount],[EquipmentCost_Currency]=S.[EquipmentCost_Currency],[EquityInvestment_Amount]=S.[EquityInvestment_Amount],[EquityInvestment_Currency]=S.[EquityInvestment_Currency],[IDC_Amount]=S.[IDC_Amount],[IDC_Currency]=S.[IDC_Currency],[IsFromStandalone]=S.[IsFromStandalone],[IsRestructureAtInception]=S.[IsRestructureAtInception],[LeveragedLeaseAmendmentStatus]=S.[LeveragedLeaseAmendmentStatus],[LeveragedLeaseRestructureReasonConfigId]=S.[LeveragedLeaseRestructureReasonConfigId],[LongTermDebt_Amount]=S.[LongTermDebt_Amount],[LongTermDebt_Currency]=S.[LongTermDebt_Currency],[MaturityDate]=S.[MaturityDate],[Name]=S.[Name],[PostDate]=S.[PostDate],[RentalsReceivable_Amount]=S.[RentalsReceivable_Amount],[RentalsReceivable_Currency]=S.[RentalsReceivable_Currency],[ResidualValue_Amount]=S.[ResidualValue_Amount],[ResidualValue_Currency]=S.[ResidualValue_Currency],[RestructureDate]=S.[RestructureDate],[Term]=S.[Term],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AmortDocument_Content],[AmortDocument_Source],[AmortDocument_Type],[ContractId],[CreatedById],[CreatedTime],[CurrentLeveragedLeaseId],[Debt_Amount],[Debt_Currency],[EquipmentCost_Amount],[EquipmentCost_Currency],[EquityInvestment_Amount],[EquityInvestment_Currency],[IDC_Amount],[IDC_Currency],[IsFromStandalone],[IsRestructureAtInception],[LeveragedLeaseAmendmentStatus],[LeveragedLeaseRestructureReasonConfigId],[LongTermDebt_Amount],[LongTermDebt_Currency],[MaturityDate],[Name],[PostDate],[RentalsReceivable_Amount],[RentalsReceivable_Currency],[ResidualValue_Amount],[ResidualValue_Currency],[RestructureDate],[Term])
    VALUES (S.[AmortDocument_Content],S.[AmortDocument_Source],S.[AmortDocument_Type],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[CurrentLeveragedLeaseId],S.[Debt_Amount],S.[Debt_Currency],S.[EquipmentCost_Amount],S.[EquipmentCost_Currency],S.[EquityInvestment_Amount],S.[EquityInvestment_Currency],S.[IDC_Amount],S.[IDC_Currency],S.[IsFromStandalone],S.[IsRestructureAtInception],S.[LeveragedLeaseAmendmentStatus],S.[LeveragedLeaseRestructureReasonConfigId],S.[LongTermDebt_Amount],S.[LongTermDebt_Currency],S.[MaturityDate],S.[Name],S.[PostDate],S.[RentalsReceivable_Amount],S.[RentalsReceivable_Currency],S.[ResidualValue_Amount],S.[ResidualValue_Currency],S.[RestructureDate],S.[Term])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
