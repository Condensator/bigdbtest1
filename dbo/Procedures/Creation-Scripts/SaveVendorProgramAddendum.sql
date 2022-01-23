SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveVendorProgramAddendum]
(
 @val [dbo].[VendorProgramAddendum] READONLY
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
MERGE [dbo].[VendorProgramAddendums] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Amount1_Amount]=S.[Amount1_Amount],[Amount1_Currency]=S.[Amount1_Currency],[Amount2_Amount]=S.[Amount2_Amount],[Amount2_Currency]=S.[Amount2_Currency],[Comment1]=S.[Comment1],[Date1]=S.[Date1],[Date2]=S.[Date2],[Flag1]=S.[Flag1],[IsActive]=S.[IsActive],[Number1]=S.[Number1],[Percentage1]=S.[Percentage1],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[VendorProgramAddendumTypeId]=S.[VendorProgramAddendumTypeId]
WHEN NOT MATCHED THEN
	INSERT ([Amount1_Amount],[Amount1_Currency],[Amount2_Amount],[Amount2_Currency],[Comment1],[CreatedById],[CreatedTime],[Date1],[Date2],[Flag1],[IsActive],[Number1],[Percentage1],[VendorId],[VendorProgramAddendumTypeId])
    VALUES (S.[Amount1_Amount],S.[Amount1_Currency],S.[Amount2_Amount],S.[Amount2_Currency],S.[Comment1],S.[CreatedById],S.[CreatedTime],S.[Date1],S.[Date2],S.[Flag1],S.[IsActive],S.[Number1],S.[Percentage1],S.[VendorId],S.[VendorProgramAddendumTypeId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
