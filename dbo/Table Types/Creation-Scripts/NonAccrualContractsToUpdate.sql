CREATE TYPE [dbo].[NonAccrualContractsToUpdate] AS TABLE(
	[Id] [bigint] NOT NULL,
	[IsNonAccrualApproved] [bit] NOT NULL,
	[PostDate] [date] NULL
)
GO
