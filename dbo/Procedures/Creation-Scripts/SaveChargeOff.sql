SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveChargeOff]
(
 @val [dbo].[ChargeOff] READONLY
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
MERGE [dbo].[ChargeOffs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ChargeOffAmount_Amount]=S.[ChargeOffAmount_Amount],[ChargeOffAmount_Currency]=S.[ChargeOffAmount_Currency],[ChargeOffDate]=S.[ChargeOffDate],[ChargeOffProcessingDate]=S.[ChargeOffProcessingDate],[ChargeOffReasonCodeConfigId]=S.[ChargeOffReasonCodeConfigId],[Comment]=S.[Comment],[ContractId]=S.[ContractId],[ContractType]=S.[ContractType],[GLTemplateId]=S.[GLTemplateId],[GrossWritedown_Amount]=S.[GrossWritedown_Amount],[GrossWritedown_Currency]=S.[GrossWritedown_Currency],[IsActive]=S.[IsActive],[IsRecovery]=S.[IsRecovery],[LeaseComponentAmount_Amount]=S.[LeaseComponentAmount_Amount],[LeaseComponentAmount_Currency]=S.[LeaseComponentAmount_Currency],[LeaseComponentGain_Amount]=S.[LeaseComponentGain_Amount],[LeaseComponentGain_Currency]=S.[LeaseComponentGain_Currency],[NetInvestmentWithBlended_Amount]=S.[NetInvestmentWithBlended_Amount],[NetInvestmentWithBlended_Currency]=S.[NetInvestmentWithBlended_Currency],[NetWritedown_Amount]=S.[NetWritedown_Amount],[NetWritedown_Currency]=S.[NetWritedown_Currency],[NonLeaseComponentAmount_Amount]=S.[NonLeaseComponentAmount_Amount],[NonLeaseComponentAmount_Currency]=S.[NonLeaseComponentAmount_Currency],[NonLeaseComponentGain_Amount]=S.[NonLeaseComponentGain_Amount],[NonLeaseComponentGain_Currency]=S.[NonLeaseComponentGain_Currency],[PostDate]=S.[PostDate],[ReceiptId]=S.[ReceiptId],[Status]=S.[Status],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ChargeOffAmount_Amount],[ChargeOffAmount_Currency],[ChargeOffDate],[ChargeOffProcessingDate],[ChargeOffReasonCodeConfigId],[Comment],[ContractId],[ContractType],[CreatedById],[CreatedTime],[GLTemplateId],[GrossWritedown_Amount],[GrossWritedown_Currency],[IsActive],[IsRecovery],[LeaseComponentAmount_Amount],[LeaseComponentAmount_Currency],[LeaseComponentGain_Amount],[LeaseComponentGain_Currency],[NetInvestmentWithBlended_Amount],[NetInvestmentWithBlended_Currency],[NetWritedown_Amount],[NetWritedown_Currency],[NonLeaseComponentAmount_Amount],[NonLeaseComponentAmount_Currency],[NonLeaseComponentGain_Amount],[NonLeaseComponentGain_Currency],[PostDate],[ReceiptId],[Status])
    VALUES (S.[ChargeOffAmount_Amount],S.[ChargeOffAmount_Currency],S.[ChargeOffDate],S.[ChargeOffProcessingDate],S.[ChargeOffReasonCodeConfigId],S.[Comment],S.[ContractId],S.[ContractType],S.[CreatedById],S.[CreatedTime],S.[GLTemplateId],S.[GrossWritedown_Amount],S.[GrossWritedown_Currency],S.[IsActive],S.[IsRecovery],S.[LeaseComponentAmount_Amount],S.[LeaseComponentAmount_Currency],S.[LeaseComponentGain_Amount],S.[LeaseComponentGain_Currency],S.[NetInvestmentWithBlended_Amount],S.[NetInvestmentWithBlended_Currency],S.[NetWritedown_Amount],S.[NetWritedown_Currency],S.[NonLeaseComponentAmount_Amount],S.[NonLeaseComponentAmount_Currency],S.[NonLeaseComponentGain_Amount],S.[NonLeaseComponentGain_Currency],S.[PostDate],S.[ReceiptId],S.[Status])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
