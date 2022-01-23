SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveContractCollectionDetail]
(
 @val [dbo].[ContractCollectionDetail] READONLY
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
MERGE [dbo].[ContractCollectionDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CalculateDeliquencyDetails]=S.[CalculateDeliquencyDetails],[ContractId]=S.[ContractId],[InterestDPD]=S.[InterestDPD],[LegacyNinetyPlusDaysLate]=S.[LegacyNinetyPlusDaysLate],[LegacyOneHundredTwentyPlusDaysLate]=S.[LegacyOneHundredTwentyPlusDaysLate],[LegacySixtyPlusDaysLate]=S.[LegacySixtyPlusDaysLate],[LegacyThirtyPlusDaysLate]=S.[LegacyThirtyPlusDaysLate],[LegacyZeroPlusDaysLate]=S.[LegacyZeroPlusDaysLate],[MaturityDPD]=S.[MaturityDPD],[NinetyPlusDaysLate]=S.[NinetyPlusDaysLate],[OneHundredTwentyPlusDaysLate]=S.[OneHundredTwentyPlusDaysLate],[OneToThirtyDaysLate]=S.[OneToThirtyDaysLate],[OverallDPD]=S.[OverallDPD],[RentOrPrincipalDPD]=S.[RentOrPrincipalDPD],[SixtyPlusDaysLate]=S.[SixtyPlusDaysLate],[ThirtyPlusDaysLate]=S.[ThirtyPlusDaysLate],[TotalNinetyPlusDaysLate]=S.[TotalNinetyPlusDaysLate],[TotalOneHundredTwentyPlusDaysLate]=S.[TotalOneHundredTwentyPlusDaysLate],[TotalOneToThirtyDaysLate]=S.[TotalOneToThirtyDaysLate],[TotalSixtyPlusDaysLate]=S.[TotalSixtyPlusDaysLate],[TotalThirtyPlusDaysLate]=S.[TotalThirtyPlusDaysLate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CalculateDeliquencyDetails],[ContractId],[CreatedById],[CreatedTime],[InterestDPD],[LegacyNinetyPlusDaysLate],[LegacyOneHundredTwentyPlusDaysLate],[LegacySixtyPlusDaysLate],[LegacyThirtyPlusDaysLate],[LegacyZeroPlusDaysLate],[MaturityDPD],[NinetyPlusDaysLate],[OneHundredTwentyPlusDaysLate],[OneToThirtyDaysLate],[OverallDPD],[RentOrPrincipalDPD],[SixtyPlusDaysLate],[ThirtyPlusDaysLate],[TotalNinetyPlusDaysLate],[TotalOneHundredTwentyPlusDaysLate],[TotalOneToThirtyDaysLate],[TotalSixtyPlusDaysLate],[TotalThirtyPlusDaysLate])
    VALUES (S.[CalculateDeliquencyDetails],S.[ContractId],S.[CreatedById],S.[CreatedTime],S.[InterestDPD],S.[LegacyNinetyPlusDaysLate],S.[LegacyOneHundredTwentyPlusDaysLate],S.[LegacySixtyPlusDaysLate],S.[LegacyThirtyPlusDaysLate],S.[LegacyZeroPlusDaysLate],S.[MaturityDPD],S.[NinetyPlusDaysLate],S.[OneHundredTwentyPlusDaysLate],S.[OneToThirtyDaysLate],S.[OverallDPD],S.[RentOrPrincipalDPD],S.[SixtyPlusDaysLate],S.[ThirtyPlusDaysLate],S.[TotalNinetyPlusDaysLate],S.[TotalOneHundredTwentyPlusDaysLate],S.[TotalOneToThirtyDaysLate],S.[TotalSixtyPlusDaysLate],S.[TotalThirtyPlusDaysLate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
