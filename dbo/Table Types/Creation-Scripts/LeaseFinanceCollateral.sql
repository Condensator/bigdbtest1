CREATE TYPE [dbo].[LeaseFinanceCollateral] AS TABLE(
	[Type] [nvarchar](500) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DateOfIncorporation] [date] NOT NULL,
	[ExpirationDate] [date] NOT NULL,
	[IsReleased] [bit] NULL,
	[IsActive] [bit] NOT NULL,
	[LeaseFinanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
