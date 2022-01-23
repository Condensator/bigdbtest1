SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceiptContractRecoveryDetails_Extract]
(
 @val [dbo].[ReceiptContractRecoveryDetails_Extract] READONLY
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
MERGE [dbo].[ReceiptContractRecoveryDetails_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ChargeOffGLTemplateId]=S.[ChargeOffGLTemplateId],[ChargeOffId]=S.[ChargeOffId],[ChargeOffReasonCodeConfigId]=S.[ChargeOffReasonCodeConfigId],[ContractId]=S.[ContractId],[ContractType]=S.[ContractType],[JobStepInstanceId]=S.[JobStepInstanceId],[LeaseFinanceId]=S.[LeaseFinanceId],[LoanFinanceId]=S.[LoanFinanceId],[NetInvestmentWithBlended]=S.[NetInvestmentWithBlended],[NetWriteDown]=S.[NetWriteDown],[RecoveryGLTemplateId]=S.[RecoveryGLTemplateId],[RecoveryReceivableCodeId]=S.[RecoveryReceivableCodeId],[TotalChargeOffAmount]=S.[TotalChargeOffAmount],[TotalLeaseComponentChargeOffAmount]=S.[TotalLeaseComponentChargeOffAmount],[TotalLeaseComponentGainAmount]=S.[TotalLeaseComponentGainAmount],[TotalLeaseComponentRecoveryAmount]=S.[TotalLeaseComponentRecoveryAmount],[TotalNonLeaseComponentChargeOffAmount]=S.[TotalNonLeaseComponentChargeOffAmount],[TotalNonLeaseComponentGainAmount]=S.[TotalNonLeaseComponentGainAmount],[TotalNonLeaseComponentRecoveryAmount]=S.[TotalNonLeaseComponentRecoveryAmount],[TotalRecoveryAmount]=S.[TotalRecoveryAmount],[TotalRecoveryAmountForWriteDown]=S.[TotalRecoveryAmountForWriteDown],[TotalWriteDownAmount]=S.[TotalWriteDownAmount],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[WriteDownDate]=S.[WriteDownDate],[WriteDownGLTemplateId]=S.[WriteDownGLTemplateId],[WriteDownId]=S.[WriteDownId],[WriteDownReason]=S.[WriteDownReason]
WHEN NOT MATCHED THEN
	INSERT ([ChargeOffGLTemplateId],[ChargeOffId],[ChargeOffReasonCodeConfigId],[ContractId],[ContractType],[CreatedById],[CreatedTime],[JobStepInstanceId],[LeaseFinanceId],[LoanFinanceId],[NetInvestmentWithBlended],[NetWriteDown],[RecoveryGLTemplateId],[RecoveryReceivableCodeId],[TotalChargeOffAmount],[TotalLeaseComponentChargeOffAmount],[TotalLeaseComponentGainAmount],[TotalLeaseComponentRecoveryAmount],[TotalNonLeaseComponentChargeOffAmount],[TotalNonLeaseComponentGainAmount],[TotalNonLeaseComponentRecoveryAmount],[TotalRecoveryAmount],[TotalRecoveryAmountForWriteDown],[TotalWriteDownAmount],[WriteDownDate],[WriteDownGLTemplateId],[WriteDownId],[WriteDownReason])
    VALUES (S.[ChargeOffGLTemplateId],S.[ChargeOffId],S.[ChargeOffReasonCodeConfigId],S.[ContractId],S.[ContractType],S.[CreatedById],S.[CreatedTime],S.[JobStepInstanceId],S.[LeaseFinanceId],S.[LoanFinanceId],S.[NetInvestmentWithBlended],S.[NetWriteDown],S.[RecoveryGLTemplateId],S.[RecoveryReceivableCodeId],S.[TotalChargeOffAmount],S.[TotalLeaseComponentChargeOffAmount],S.[TotalLeaseComponentGainAmount],S.[TotalLeaseComponentRecoveryAmount],S.[TotalNonLeaseComponentChargeOffAmount],S.[TotalNonLeaseComponentGainAmount],S.[TotalNonLeaseComponentRecoveryAmount],S.[TotalRecoveryAmount],S.[TotalRecoveryAmountForWriteDown],S.[TotalWriteDownAmount],S.[WriteDownDate],S.[WriteDownGLTemplateId],S.[WriteDownId],S.[WriteDownReason])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
