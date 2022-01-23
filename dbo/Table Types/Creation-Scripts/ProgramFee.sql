CREATE TYPE [dbo].[ProgramFee] AS TABLE(
	[MinApplicationAmt] [decimal](16, 2) NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MaxApplicationAmt] [decimal](16, 2) NULL,
	[AdditionalFixedAmt] [decimal](16, 2) NULL,
	[FeePercentage] [decimal](5, 2) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ProgramDetailId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
