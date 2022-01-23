SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDiscountingGLTransferDealDetail]
(
 @val [dbo].[DiscountingGLTransferDealDetail] READONLY
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
MERGE [dbo].[DiscountingGLTransferDealDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [DiscountingId]=S.[DiscountingId],[ExistingFinanceId]=S.[ExistingFinanceId],[GLSegmentChangeComment]=S.[GLSegmentChangeComment],[InstrumentTypeId]=S.[InstrumentTypeId],[IsActive]=S.[IsActive],[NewBranchId]=S.[NewBranchId],[NewCostCenterId]=S.[NewCostCenterId],[NewLegalEntityId]=S.[NewLegalEntityId],[NewLineofBusinessId]=S.[NewLineofBusinessId],[RemitToId]=S.[RemitToId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[DiscountingGLTransferId],[DiscountingId],[ExistingFinanceId],[GLSegmentChangeComment],[InstrumentTypeId],[IsActive],[NewBranchId],[NewCostCenterId],[NewLegalEntityId],[NewLineofBusinessId],[RemitToId])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[DiscountingGLTransferId],S.[DiscountingId],S.[ExistingFinanceId],S.[GLSegmentChangeComment],S.[InstrumentTypeId],S.[IsActive],S.[NewBranchId],S.[NewCostCenterId],S.[NewLegalEntityId],S.[NewLineofBusinessId],S.[RemitToId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
