SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCreditBureauConsumerDetail]
(
 @val [dbo].[CreditBureauConsumerDetail] READONLY
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
MERGE [dbo].[CreditBureauConsumerDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Address]=S.[Address],[BankruptcyAssetAmount]=S.[BankruptcyAssetAmount],[BankruptcyChapterNumber]=S.[BankruptcyChapterNumber],[BankruptcyVolutaryIndicator]=S.[BankruptcyVolutaryIndicator],[City]=S.[City],[ConsentDate]=S.[ConsentDate],[ConsenttoPullCredit]=S.[ConsenttoPullCredit],[ConsumerBureauScore]=S.[ConsumerBureauScore],[CreditBureauDirectConfigId]=S.[CreditBureauDirectConfigId],[CreditRatingRequestJson]=S.[CreditRatingRequestJson],[CreditRatingResponseJson]=S.[CreditRatingResponseJson],[CreditReport_Content]=S.[CreditReport_Content],[CreditReport_Source]=S.[CreditReport_Source],[CreditReport_Type]=S.[CreditReport_Type],[CreditReportRequestJson]=S.[CreditReportRequestJson],[CreditReportResponseJson]=S.[CreditReportResponseJson],[DataReceivedDate]=S.[DataReceivedDate],[DataRequestStatus]=S.[DataRequestStatus],[DisputedAccountIndicator]=S.[DisputedAccountIndicator],[FileVariationIndicator]=S.[FileVariationIndicator],[FirstName]=S.[FirstName],[HomeAddress]=S.[HomeAddress],[IsActive]=S.[IsActive],[IsCorporate]=S.[IsCorporate],[IsSoleProprietor]=S.[IsSoleProprietor],[LastFourDigitRequestedSSN]=S.[LastFourDigitRequestedSSN],[LastName]=S.[LastName],[MiddleInitial]=S.[MiddleInitial],[MosSncMostRcnt30pDelq]=S.[MosSncMostRcnt30pDelq],[MosSncMostRcnt60pDelq]=S.[MosSncMostRcnt60pDelq],[PartyId]=S.[PartyId],[ReportFormat]=S.[ReportFormat],[ReportType]=S.[ReportType],[RequestedAddress]=S.[RequestedAddress],[RequestedBy]=S.[RequestedBy],[RequestedCity]=S.[RequestedCity],[RequestedDate]=S.[RequestedDate],[RequestedFirstName]=S.[RequestedFirstName],[RequestedLastName]=S.[RequestedLastName],[RequestedSSN_CT]=S.[RequestedSSN_CT],[RequestedState]=S.[RequestedState],[RequestedZip]=S.[RequestedZip],[RequestSourceId]=S.[RequestSourceId],[ReviewStatus]=S.[ReviewStatus],[ScorePercentile]=S.[ScorePercentile],[SocialSecurityNumber_CT]=S.[SocialSecurityNumber_CT],[Source]=S.[Source],[SSN_CT]=S.[SSN_CT],[State]=S.[State],[TradelineBalanceAmount]=S.[TradelineBalanceAmount],[TradelineBalanceDate]=S.[TradelineBalanceDate],[TradelinePastDueAmount]=S.[TradelinePastDueAmount],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Zip]=S.[Zip]
WHEN NOT MATCHED THEN
	INSERT ([Address],[BankruptcyAssetAmount],[BankruptcyChapterNumber],[BankruptcyVolutaryIndicator],[City],[ConsentDate],[ConsenttoPullCredit],[ConsumerBureauScore],[CreatedById],[CreatedTime],[CreditBureauDirectConfigId],[CreditRatingRequestJson],[CreditRatingResponseJson],[CreditReport_Content],[CreditReport_Source],[CreditReport_Type],[CreditReportRequestJson],[CreditReportResponseJson],[DataReceivedDate],[DataRequestStatus],[DisputedAccountIndicator],[FileVariationIndicator],[FirstName],[HomeAddress],[IsActive],[IsCorporate],[IsSoleProprietor],[LastFourDigitRequestedSSN],[LastName],[MiddleInitial],[MosSncMostRcnt30pDelq],[MosSncMostRcnt60pDelq],[PartyId],[ReportFormat],[ReportType],[RequestedAddress],[RequestedBy],[RequestedCity],[RequestedDate],[RequestedFirstName],[RequestedLastName],[RequestedSSN_CT],[RequestedState],[RequestedZip],[RequestSourceId],[ReviewStatus],[ScorePercentile],[SocialSecurityNumber_CT],[Source],[SSN_CT],[State],[TradelineBalanceAmount],[TradelineBalanceDate],[TradelinePastDueAmount],[Zip])
    VALUES (S.[Address],S.[BankruptcyAssetAmount],S.[BankruptcyChapterNumber],S.[BankruptcyVolutaryIndicator],S.[City],S.[ConsentDate],S.[ConsenttoPullCredit],S.[ConsumerBureauScore],S.[CreatedById],S.[CreatedTime],S.[CreditBureauDirectConfigId],S.[CreditRatingRequestJson],S.[CreditRatingResponseJson],S.[CreditReport_Content],S.[CreditReport_Source],S.[CreditReport_Type],S.[CreditReportRequestJson],S.[CreditReportResponseJson],S.[DataReceivedDate],S.[DataRequestStatus],S.[DisputedAccountIndicator],S.[FileVariationIndicator],S.[FirstName],S.[HomeAddress],S.[IsActive],S.[IsCorporate],S.[IsSoleProprietor],S.[LastFourDigitRequestedSSN],S.[LastName],S.[MiddleInitial],S.[MosSncMostRcnt30pDelq],S.[MosSncMostRcnt60pDelq],S.[PartyId],S.[ReportFormat],S.[ReportType],S.[RequestedAddress],S.[RequestedBy],S.[RequestedCity],S.[RequestedDate],S.[RequestedFirstName],S.[RequestedLastName],S.[RequestedSSN_CT],S.[RequestedState],S.[RequestedZip],S.[RequestSourceId],S.[ReviewStatus],S.[ScorePercentile],S.[SocialSecurityNumber_CT],S.[Source],S.[SSN_CT],S.[State],S.[TradelineBalanceAmount],S.[TradelineBalanceDate],S.[TradelinePastDueAmount],S.[Zip])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
