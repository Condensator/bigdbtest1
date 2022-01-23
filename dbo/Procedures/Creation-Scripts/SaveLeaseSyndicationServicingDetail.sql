SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveLeaseSyndicationServicingDetail]
(
 @val [dbo].[LeaseSyndicationServicingDetail] READONLY
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
MERGE [dbo].[LeaseSyndicationServicingDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [EffectiveDate]=S.[EffectiveDate],[IsActive]=S.[IsActive],[IsCobrand]=S.[IsCobrand],[IsCollected]=S.[IsCollected],[IsPerfectPay]=S.[IsPerfectPay],[IsPrivateLabel]=S.[IsPrivateLabel],[IsServiced]=S.[IsServiced],[PropertyTaxResponsibility]=S.[PropertyTaxResponsibility],[RemitToId]=S.[RemitToId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[EffectiveDate],[IsActive],[IsCobrand],[IsCollected],[IsPerfectPay],[IsPrivateLabel],[IsServiced],[LeaseSyndicationId],[PropertyTaxResponsibility],[RemitToId])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[EffectiveDate],S.[IsActive],S.[IsCobrand],S.[IsCollected],S.[IsPerfectPay],S.[IsPrivateLabel],S.[IsServiced],S.[LeaseSyndicationId],S.[PropertyTaxResponsibility],S.[RemitToId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
