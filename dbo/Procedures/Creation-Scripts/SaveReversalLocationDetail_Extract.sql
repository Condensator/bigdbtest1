SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReversalLocationDetail_Extract]
(
 @val [dbo].[ReversalLocationDetail_Extract] READONLY
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
MERGE [dbo].[ReversalLocationDetail_Extract] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AcquisitionLocationTaxAreaId]=S.[AcquisitionLocationTaxAreaId],[City]=S.[City],[Country]=S.[Country],[IsVertexSupportedLocation]=S.[IsVertexSupportedLocation],[JobStepInstanceId]=S.[JobStepInstanceId],[LocationCode]=S.[LocationCode],[LocationId]=S.[LocationId],[MainDivision]=S.[MainDivision],[StateId]=S.[StateId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AcquisitionLocationTaxAreaId],[City],[Country],[CreatedById],[CreatedTime],[IsVertexSupportedLocation],[JobStepInstanceId],[LocationCode],[LocationId],[MainDivision],[StateId])
    VALUES (S.[AcquisitionLocationTaxAreaId],S.[City],S.[Country],S.[CreatedById],S.[CreatedTime],S.[IsVertexSupportedLocation],S.[JobStepInstanceId],S.[LocationCode],S.[LocationId],S.[MainDivision],S.[StateId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
