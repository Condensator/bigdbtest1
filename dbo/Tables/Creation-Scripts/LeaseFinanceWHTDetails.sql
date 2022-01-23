SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeaseFinanceWHTDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsApplicableForWHT] [bit] NOT NULL,
	[EffectiveFromDate] [date] NOT NULL,
	[LeaseFinanceDetailId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeaseFinanceWHTDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceDetail_LeaseFinanceWHTDetails] FOREIGN KEY([LeaseFinanceDetailId])
REFERENCES [dbo].[LeaseFinanceDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LeaseFinanceWHTDetails] CHECK CONSTRAINT [ELeaseFinanceDetail_LeaseFinanceWHTDetails]
GO
