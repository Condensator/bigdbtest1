SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAssetService]
(
 @val [dbo].[AssetService] READONLY
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
MERGE [dbo].[AssetServices] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [GracePeriodInMonths]=S.[GracePeriodInMonths],[GracePeriodStopDate]=S.[GracePeriodStopDate],[IsFreeAnnualTechnicalCheck]=S.[IsFreeAnnualTechnicalCheck],[IsFreeAutobox]=S.[IsFreeAutobox],[IsFreeChangeOfTires]=S.[IsFreeChangeOfTires],[IsFreeInsuranceDamage]=S.[IsFreeInsuranceDamage],[IsFreeReplacementCar]=S.[IsFreeReplacementCar],[IsSBACard]=S.[IsSBACard],[IsSimplAssistant]=S.[IsSimplAssistant],[IsVignette]=S.[IsVignette],[NextAnnualTechnicalCheck]=S.[NextAnnualTechnicalCheck],[NextAutobox]=S.[NextAutobox],[NextChangeOfTires]=S.[NextChangeOfTires],[NextSBACardRenew]=S.[NextSBACardRenew],[NextVignetteRenew]=S.[NextVignetteRenew],[ServiceStartDate]=S.[ServiceStartDate],[ServiceStopDate]=S.[ServiceStopDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[GracePeriodInMonths],[GracePeriodStopDate],[Id],[IsFreeAnnualTechnicalCheck],[IsFreeAutobox],[IsFreeChangeOfTires],[IsFreeInsuranceDamage],[IsFreeReplacementCar],[IsSBACard],[IsSimplAssistant],[IsVignette],[NextAnnualTechnicalCheck],[NextAutobox],[NextChangeOfTires],[NextSBACardRenew],[NextVignetteRenew],[ServiceStartDate],[ServiceStopDate])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[GracePeriodInMonths],S.[GracePeriodStopDate],S.[Id],S.[IsFreeAnnualTechnicalCheck],S.[IsFreeAutobox],S.[IsFreeChangeOfTires],S.[IsFreeInsuranceDamage],S.[IsFreeReplacementCar],S.[IsSBACard],S.[IsSimplAssistant],S.[IsVignette],S.[NextAnnualTechnicalCheck],S.[NextAutobox],S.[NextChangeOfTires],S.[NextSBACardRenew],S.[NextVignetteRenew],S.[ServiceStartDate],S.[ServiceStopDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
