SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeaseFundings](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsApproved] [bit] NOT NULL,
	[UsePayDate] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsNewlyAdded] [bit] NOT NULL,
	[Type] [nvarchar](21) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FundingId] [bigint] NOT NULL,
	[LeaseFinanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeaseFundings]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_LeaseFundings] FOREIGN KEY([LeaseFinanceId])
REFERENCES [dbo].[LeaseFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LeaseFundings] CHECK CONSTRAINT [ELeaseFinance_LeaseFundings]
GO
ALTER TABLE [dbo].[LeaseFundings]  WITH CHECK ADD  CONSTRAINT [ELeaseFunding_Funding] FOREIGN KEY([FundingId])
REFERENCES [dbo].[PayableInvoices] ([Id])
GO
ALTER TABLE [dbo].[LeaseFundings] CHECK CONSTRAINT [ELeaseFunding_Funding]
GO
