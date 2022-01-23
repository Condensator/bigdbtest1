SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAppraisalRequest]
(
 @val [dbo].[AppraisalRequest] READONLY
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
MERGE [dbo].[AppraisalRequests] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AppraisalDate]=S.[AppraisalDate],[AppraisalNumber]=S.[AppraisalNumber],[AppraisedById]=S.[AppraisedById],[BusinessUnitId]=S.[BusinessUnitId],[Comment]=S.[Comment],[CurrencyId]=S.[CurrencyId],[IsApplyByAssets]=S.[IsApplyByAssets],[OriginationType]=S.[OriginationType],[RequestedById]=S.[RequestedById],[RequestedDate]=S.[RequestedDate],[Status]=S.[Status],[ThirdPartyAppraiserId]=S.[ThirdPartyAppraiserId],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Value_Amount]=S.[Value_Amount],[Value_Currency]=S.[Value_Currency]
WHEN NOT MATCHED THEN
	INSERT ([AppraisalDate],[AppraisalNumber],[AppraisedById],[BusinessUnitId],[Comment],[CreatedById],[CreatedTime],[CurrencyId],[IsApplyByAssets],[OriginationType],[RequestedById],[RequestedDate],[Status],[ThirdPartyAppraiserId],[Type],[Value_Amount],[Value_Currency])
    VALUES (S.[AppraisalDate],S.[AppraisalNumber],S.[AppraisedById],S.[BusinessUnitId],S.[Comment],S.[CreatedById],S.[CreatedTime],S.[CurrencyId],S.[IsApplyByAssets],S.[OriginationType],S.[RequestedById],S.[RequestedDate],S.[Status],S.[ThirdPartyAppraiserId],S.[Type],S.[Value_Amount],S.[Value_Currency])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
