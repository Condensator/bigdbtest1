SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAcceleratedBalanceQuote]
(
 @val [dbo].[AcceleratedBalanceQuote] READONLY
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
MERGE [dbo].[AcceleratedBalanceQuotes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BuyerAddress]=S.[BuyerAddress],[ChaseOrInspectionFees_Amount]=S.[ChaseOrInspectionFees_Amount],[ChaseOrInspectionFees_Currency]=S.[ChaseOrInspectionFees_Currency],[Comment1]=S.[Comment1],[Comment2]=S.[Comment2],[Comment3]=S.[Comment3],[Credits_Amount]=S.[Credits_Amount],[Credits_Currency]=S.[Credits_Currency],[DirectAllInquiriesTo]=S.[DirectAllInquiriesTo],[DocumentationFees_Amount]=S.[DocumentationFees_Amount],[DocumentationFees_Currency]=S.[DocumentationFees_Currency],[EquipmentRelatedExpenses_Amount]=S.[EquipmentRelatedExpenses_Amount],[EquipmentRelatedExpenses_Currency]=S.[EquipmentRelatedExpenses_Currency],[InsuranceFees_Amount]=S.[InsuranceFees_Amount],[InsuranceFees_Currency]=S.[InsuranceFees_Currency],[LateCharges_Amount]=S.[LateCharges_Amount],[LateCharges_Currency]=S.[LateCharges_Currency],[LegalFeesOrCost_Amount]=S.[LegalFeesOrCost_Amount],[LegalFeesOrCost_Currency]=S.[LegalFeesOrCost_Currency],[NSFOrProcessFeesOrOther_Amount]=S.[NSFOrProcessFeesOrOther_Amount],[NSFOrProcessFeesOrOther_Currency]=S.[NSFOrProcessFeesOrOther_Currency],[PayableTo]=S.[PayableTo],[PerDiem_Amount]=S.[PerDiem_Amount],[PerDiem_Currency]=S.[PerDiem_Currency],[QuoteDate]=S.[QuoteDate],[QuoteGoodThrough]=S.[QuoteGoodThrough],[ToId]=S.[ToId],[TotalDue_Amount]=S.[TotalDue_Amount],[TotalDue_Currency]=S.[TotalDue_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Waivers_Amount]=S.[Waivers_Amount],[Waivers_Currency]=S.[Waivers_Currency]
WHEN NOT MATCHED THEN
	INSERT ([BuyerAddress],[ChaseOrInspectionFees_Amount],[ChaseOrInspectionFees_Currency],[Comment1],[Comment2],[Comment3],[CreatedById],[CreatedTime],[Credits_Amount],[Credits_Currency],[DirectAllInquiriesTo],[DocumentationFees_Amount],[DocumentationFees_Currency],[EquipmentRelatedExpenses_Amount],[EquipmentRelatedExpenses_Currency],[Id],[InsuranceFees_Amount],[InsuranceFees_Currency],[LateCharges_Amount],[LateCharges_Currency],[LegalFeesOrCost_Amount],[LegalFeesOrCost_Currency],[NSFOrProcessFeesOrOther_Amount],[NSFOrProcessFeesOrOther_Currency],[PayableTo],[PerDiem_Amount],[PerDiem_Currency],[QuoteDate],[QuoteGoodThrough],[ToId],[TotalDue_Amount],[TotalDue_Currency],[Waivers_Amount],[Waivers_Currency])
    VALUES (S.[BuyerAddress],S.[ChaseOrInspectionFees_Amount],S.[ChaseOrInspectionFees_Currency],S.[Comment1],S.[Comment2],S.[Comment3],S.[CreatedById],S.[CreatedTime],S.[Credits_Amount],S.[Credits_Currency],S.[DirectAllInquiriesTo],S.[DocumentationFees_Amount],S.[DocumentationFees_Currency],S.[EquipmentRelatedExpenses_Amount],S.[EquipmentRelatedExpenses_Currency],S.[Id],S.[InsuranceFees_Amount],S.[InsuranceFees_Currency],S.[LateCharges_Amount],S.[LateCharges_Currency],S.[LegalFeesOrCost_Amount],S.[LegalFeesOrCost_Currency],S.[NSFOrProcessFeesOrOther_Amount],S.[NSFOrProcessFeesOrOther_Currency],S.[PayableTo],S.[PerDiem_Amount],S.[PerDiem_Currency],S.[QuoteDate],S.[QuoteGoodThrough],S.[ToId],S.[TotalDue_Amount],S.[TotalDue_Currency],S.[Waivers_Amount],S.[Waivers_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
