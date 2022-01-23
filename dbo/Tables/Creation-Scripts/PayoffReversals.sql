SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayoffReversals](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReversalPostDate] [date] NOT NULL,
	[ReversalComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PayoffId] [bigint] NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[InitiateCPIPayoffReversal] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PayoffReversals]  WITH CHECK ADD  CONSTRAINT [EPayoffReversal_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[PayoffReversals] CHECK CONSTRAINT [EPayoffReversal_Contract]
GO
ALTER TABLE [dbo].[PayoffReversals]  WITH CHECK ADD  CONSTRAINT [EPayoffReversal_Payoff] FOREIGN KEY([PayoffId])
REFERENCES [dbo].[Payoffs] ([Id])
GO
ALTER TABLE [dbo].[PayoffReversals] CHECK CONSTRAINT [EPayoffReversal_Payoff]
GO
