SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeaseLienFilings](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LienFilingId] [bigint] NOT NULL,
	[LeaseFinanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeaseLienFilings]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_LeaseLienFilings] FOREIGN KEY([LeaseFinanceId])
REFERENCES [dbo].[LeaseFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LeaseLienFilings] CHECK CONSTRAINT [ELeaseFinance_LeaseLienFilings]
GO
ALTER TABLE [dbo].[LeaseLienFilings]  WITH CHECK ADD  CONSTRAINT [ELeaseLienFiling_LienFiling] FOREIGN KEY([LienFilingId])
REFERENCES [dbo].[LienFilings] ([Id])
GO
ALTER TABLE [dbo].[LeaseLienFilings] CHECK CONSTRAINT [ELeaseLienFiling_LienFiling]
GO
