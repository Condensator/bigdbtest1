CREATE TYPE [dbo].[PayoffTerminationExpression] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Query] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsLease] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Parameters] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
