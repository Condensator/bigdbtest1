SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROC [dbo].[SaveInsurancePolicy]
(
 @val [dbo].[InsurancePolicy] READONLY
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
MERGE [dbo].[InsurancePolicies] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActivationDate]=S.[ActivationDate],[AdditionalInsured]=S.[AdditionalInsured],[CertificateReceivedDate]=S.[CertificateReceivedDate],[Comment]=S.[Comment],[ContactPersonId]=S.[ContactPersonId],[CurrencyId]=S.[CurrencyId],[CustomerId]=S.[CustomerId],[DeactivationDate]=S.[DeactivationDate],[EffectiveDate]=S.[EffectiveDate],[ExpirationDate]=S.[ExpirationDate],[InsuranceAgencyId]=S.[InsuranceAgencyId],[InsuranceAgentId]=S.[InsuranceAgentId],[InsuranceCompanyId]=S.[InsuranceCompanyId],[IsActive]=S.[IsActive],[IsApplicableToAllStates]=S.[IsApplicableToAllStates],[IsCertificateReceived]=S.[IsCertificateReceived],[IsEditMode]=S.[IsEditMode],[IsSaved]=S.[IsSaved],[IsSelfInsured]=S.[IsSelfInsured],[LastModifiedBy]=S.[LastModifiedBy],[LastModifiedDate]=S.[LastModifiedDate],[LegalEntityId]=S.[LegalEntityId],[LossPayee]=S.[LossPayee],[PolicyNumber]=S.[PolicyNumber],[StateId]=S.[StateId],[Type]=S.[Type],[UniqueIdentificationNumber]=S.[UniqueIdentificationNumber],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VerifiedById]=S.[VerifiedById],[VerifiedDate]=S.[VerifiedDate]
WHEN NOT MATCHED THEN
	INSERT ([ActivationDate],[AdditionalInsured],[CertificateReceivedDate],[Comment],[ContactPersonId],[CreatedById],[CreatedTime],[CurrencyId],[CustomerId],[DeactivationDate],[EffectiveDate],[ExpirationDate],[InsuranceAgencyId],[InsuranceAgentId],[InsuranceCompanyId],[IsActive],[IsApplicableToAllStates],[IsCertificateReceived],[IsEditMode],[IsSaved],[IsSelfInsured],[LastModifiedBy],[LastModifiedDate],[LegalEntityId],[LossPayee],[PolicyNumber],[StateId],[Type],[UniqueIdentificationNumber],[VerifiedById],[VerifiedDate])
    VALUES (S.[ActivationDate],S.[AdditionalInsured],S.[CertificateReceivedDate],S.[Comment],S.[ContactPersonId],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[CustomerId],S.[DeactivationDate],S.[EffectiveDate],S.[ExpirationDate],S.[InsuranceAgencyId],S.[InsuranceAgentId],S.[InsuranceCompanyId],S.[IsActive],S.[IsApplicableToAllStates],S.[IsCertificateReceived],S.[IsEditMode],S.[IsSaved],S.[IsSelfInsured],S.[LastModifiedBy],S.[LastModifiedDate],S.[LegalEntityId],S.[LossPayee],S.[PolicyNumber],S.[StateId],S.[Type],S.[UniqueIdentificationNumber],S.[VerifiedById],S.[VerifiedDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
