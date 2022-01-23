CREATE TYPE [dbo].[LegalReliefContract] AS TABLE(
	[Date] [date] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Intention] [nvarchar](27) COLLATE Latin1_General_CI_AS NOT NULL,
	[Active] [bit] NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[LegalReliefId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
