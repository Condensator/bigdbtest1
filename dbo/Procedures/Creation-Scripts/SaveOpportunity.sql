SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveOpportunity]
(
 @val [dbo].[Opportunity] READONLY
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
MERGE [dbo].[Opportunities] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AcquiredPortfolioId]=S.[AcquiredPortfolioId],[BankQualified]=S.[BankQualified],[BranchId]=S.[BranchId],[BusinessUnitId]=S.[BusinessUnitId],[CapitalStreamUniqueId]=S.[CapitalStreamUniqueId],[Conduit]=S.[Conduit],[Confidential]=S.[Confidential],[CostCenterId]=S.[CostCenterId],[CountryId]=S.[CountryId],[CurrencyId]=S.[CurrencyId],[CustomerId]=S.[CustomerId],[IsAMReviewDone]=S.[IsAMReviewDone],[IsAutomaticScoringSkipped]=S.[IsAutomaticScoringSkipped],[IsCustomerCreationRequired]=S.[IsCustomerCreationRequired],[IsFederalIncomeTaxExempt]=S.[IsFederalIncomeTaxExempt],[IsLeaseCreated]=S.[IsLeaseCreated],[IsOriginatedinLW]=S.[IsOriginatedinLW],[LegalEntityId]=S.[LegalEntityId],[LineofBusinessId]=S.[LineofBusinessId],[ManagementSegment]=S.[ManagementSegment],[Number]=S.[Number],[OpportunityLostReason]=S.[OpportunityLostReason],[OriginationChannelId]=S.[OriginationChannelId],[OriginationSourceId]=S.[OriginationSourceId],[OriginationSourceTypeId]=S.[OriginationSourceTypeId],[OriginationSourceUserId]=S.[OriginationSourceUserId],[ReferralBankerId]=S.[ReferralBankerId],[ReplacementSchedule]=S.[ReplacementSchedule],[ReportStatus]=S.[ReportStatus],[ShellCustomerAddressId]=S.[ShellCustomerAddressId],[ShellCustomerContactId]=S.[ShellCustomerContactId],[ShellCustomerDetailId]=S.[ShellCustomerDetailId],[SingleSignOnIdentification]=S.[SingleSignOnIdentification],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[WithdrawnReasonCode]=S.[WithdrawnReasonCode]
WHEN NOT MATCHED THEN
	INSERT ([AcquiredPortfolioId],[BankQualified],[BranchId],[BusinessUnitId],[CapitalStreamUniqueId],[Conduit],[Confidential],[CostCenterId],[CountryId],[CreatedById],[CreatedTime],[CurrencyId],[CustomerId],[IsAMReviewDone],[IsAutomaticScoringSkipped],[IsCustomerCreationRequired],[IsFederalIncomeTaxExempt],[IsLeaseCreated],[IsOriginatedinLW],[LegalEntityId],[LineofBusinessId],[ManagementSegment],[Number],[OpportunityLostReason],[OriginationChannelId],[OriginationSourceId],[OriginationSourceTypeId],[OriginationSourceUserId],[ReferralBankerId],[ReplacementSchedule],[ReportStatus],[ShellCustomerAddressId],[ShellCustomerContactId],[ShellCustomerDetailId],[SingleSignOnIdentification],[Type],[WithdrawnReasonCode])
    VALUES (S.[AcquiredPortfolioId],S.[BankQualified],S.[BranchId],S.[BusinessUnitId],S.[CapitalStreamUniqueId],S.[Conduit],S.[Confidential],S.[CostCenterId],S.[CountryId],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[CustomerId],S.[IsAMReviewDone],S.[IsAutomaticScoringSkipped],S.[IsCustomerCreationRequired],S.[IsFederalIncomeTaxExempt],S.[IsLeaseCreated],S.[IsOriginatedinLW],S.[LegalEntityId],S.[LineofBusinessId],S.[ManagementSegment],S.[Number],S.[OpportunityLostReason],S.[OriginationChannelId],S.[OriginationSourceId],S.[OriginationSourceTypeId],S.[OriginationSourceUserId],S.[ReferralBankerId],S.[ReplacementSchedule],S.[ReportStatus],S.[ShellCustomerAddressId],S.[ShellCustomerContactId],S.[ShellCustomerDetailId],S.[SingleSignOnIdentification],S.[Type],S.[WithdrawnReasonCode])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
