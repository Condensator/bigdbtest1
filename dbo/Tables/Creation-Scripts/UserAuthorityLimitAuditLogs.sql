SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserAuthorityLimitAuditLogs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AuditSourceId] [bigint] NOT NULL,
	[AuditOperation] [int] NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Limit_Amount] [decimal](24, 2) NULL,
	[Limit_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NULL,
	[UserId] [bigint] NOT NULL,
	[AuthorityId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
