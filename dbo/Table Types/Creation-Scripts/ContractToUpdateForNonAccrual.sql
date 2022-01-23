CREATE TYPE [dbo].[ContractToUpdateForNonAccrual] AS TABLE(
	[Id] [bigint] NOT NULL,
	[IsNonAccrual] [bit] NOT NULL,
	[NonAccrualDate] [date] NULL,
	[ReportStatus] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[DoubtfulCollectability] [bit] NOT NULL
)
GO
