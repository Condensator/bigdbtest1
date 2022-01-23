SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveProgramPromotion]
(
 @val [dbo].[ProgramPromotion] READONLY
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
MERGE [dbo].[ProgramPromotions] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [BeginDate]=S.[BeginDate],[BlendedItemCodeId]=S.[BlendedItemCodeId],[CommissionPercentage]=S.[CommissionPercentage],[Description]=S.[Description],[EndDate]=S.[EndDate],[IsActive]=S.[IsActive],[IsBlindPromotion]=S.[IsBlindPromotion],[IsLessorCollected]=S.[IsLessorCollected],[IsLessorServiced]=S.[IsLessorServiced],[IsNonNotification]=S.[IsNonNotification],[IsPerfectPay]=S.[IsPerfectPay],[IsPrivateLabel]=S.[IsPrivateLabel],[ProgramRateCardId]=S.[ProgramRateCardId],[PromotionCode]=S.[PromotionCode],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([BeginDate],[BlendedItemCodeId],[CommissionPercentage],[CreatedById],[CreatedTime],[Description],[EndDate],[IsActive],[IsBlindPromotion],[IsLessorCollected],[IsLessorServiced],[IsNonNotification],[IsPerfectPay],[IsPrivateLabel],[ProgramDetailId],[ProgramRateCardId],[PromotionCode])
    VALUES (S.[BeginDate],S.[BlendedItemCodeId],S.[CommissionPercentage],S.[CreatedById],S.[CreatedTime],S.[Description],S.[EndDate],S.[IsActive],S.[IsBlindPromotion],S.[IsLessorCollected],S.[IsLessorServiced],S.[IsNonNotification],S.[IsPerfectPay],S.[IsPrivateLabel],S.[ProgramDetailId],S.[ProgramRateCardId],S.[PromotionCode])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
