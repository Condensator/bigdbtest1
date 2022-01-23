SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



Create Procedure [dbo].[CreateSNCHistory]
(
@SNCRating as NVARCHAR(50) ,
@SNCRole as NVARCHAR(50) ,
@SNCAgent as NVARCHAR(50) ,
@SNCRatingDate as DateTime,
@CreatedById as NVARCHAR(50),
@CreatedTime as DATETIMEOFFSET
)
AS
BEGIN
if(@SNCRatingDate <= '1/1/1753')
begin
SET @SNCRatingDate = null
end
INSERT INTO CreditSNCHistories(IsSNCCode,SNCRAting,SNCRole,SNCAgent,SNCRatingDate,CreatedById,CreatedTime)
VALUES(1,@SNCRating,@SNCRole,@SNCAgent,@SNCRatingDate,@CreatedById,@CreatedTime)
END

GO
