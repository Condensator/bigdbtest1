SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SavePayoffTradeUpFeeDetail]
(
 @val [dbo].[PayoffTradeUpFeeDetail] READONLY
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
MERGE [dbo].[PayoffTradeUpFeeDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Field1]=S.[Field1],[Field10]=S.[Field10],[Field2]=S.[Field2],[Field3]=S.[Field3],[Field4]=S.[Field4],[Field5]=S.[Field5],[Field6]=S.[Field6],[Field7]=S.[Field7],[Field8]=S.[Field8],[Field9]=S.[Field9],[IsActive]=S.[IsActive],[IsHeaderRecord]=S.[IsHeaderRecord],[NumberOfColumns]=S.[NumberOfColumns],[RemainingNumberofMonths]=S.[RemainingNumberofMonths],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[Field1],[Field10],[Field2],[Field3],[Field4],[Field5],[Field6],[Field7],[Field8],[Field9],[IsActive],[IsHeaderRecord],[NumberOfColumns],[PayoffTradeUpFeeId],[RemainingNumberofMonths])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[Field1],S.[Field10],S.[Field2],S.[Field3],S.[Field4],S.[Field5],S.[Field6],S.[Field7],S.[Field8],S.[Field9],S.[IsActive],S.[IsHeaderRecord],S.[NumberOfColumns],S.[PayoffTradeUpFeeId],S.[RemainingNumberofMonths])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
