SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveAppraisalDetail]
(
 @val [dbo].[AppraisalDetail] READONLY
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
MERGE [dbo].[AppraisalDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AppraisalValue_Amount]=S.[AppraisalValue_Amount],[AppraisalValue_Currency]=S.[AppraisalValue_Currency],[AssetId]=S.[AssetId],[InPlaceCurrencyId]=S.[InPlaceCurrencyId],[InPlaceValue_Amount]=S.[InPlaceValue_Amount],[InPlaceValue_Currency]=S.[InPlaceValue_Currency],[IsActive]=S.[IsActive],[ThirdPartyAppraiserId]=S.[ThirdPartyAppraiserId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AppraisalRequestId],[AppraisalValue_Amount],[AppraisalValue_Currency],[AssetId],[CreatedById],[CreatedTime],[InPlaceCurrencyId],[InPlaceValue_Amount],[InPlaceValue_Currency],[IsActive],[ThirdPartyAppraiserId])
    VALUES (S.[AppraisalRequestId],S.[AppraisalValue_Amount],S.[AppraisalValue_Currency],S.[AssetId],S.[CreatedById],S.[CreatedTime],S.[InPlaceCurrencyId],S.[InPlaceValue_Amount],S.[InPlaceValue_Currency],S.[IsActive],S.[ThirdPartyAppraiserId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
