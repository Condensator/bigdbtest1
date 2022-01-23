CREATE TYPE [dbo].[ApproveOnBehalfOf] AS TABLE(
	[Limit_Amount] [decimal](24, 2) NOT NULL,
	[Limit_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[RowNumber] [int] NOT NULL,
	[ApproveOnBehalfOfUserId] [bigint] NOT NULL,
	[AuthorityId] [bigint] NOT NULL,
	[UserId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
