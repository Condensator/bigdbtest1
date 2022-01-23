CREATE TYPE [dbo].[LegalReliefBankruptcyChapter] AS TABLE(
	[Chapter] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Date] [date] NULL,
	[Active] [bit] NOT NULL,
	[LegalReliefId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
