CREATE TYPE [dbo].[PrincipalDeclineReasonCodeConfig] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PrincipalDeclineReasonCode] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
