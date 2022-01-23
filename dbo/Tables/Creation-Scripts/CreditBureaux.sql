SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditBureaux](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[BureauCustomerNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[BureauCustomerName] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[AddedDate] [date] NOT NULL,
	[RemovedDate] [date] NULL,
	[IsNoMatchFound] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[BusinessBureauId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditBureaux]  WITH CHECK ADD  CONSTRAINT [ECreditBureau_BusinessBureau] FOREIGN KEY([BusinessBureauId])
REFERENCES [dbo].[CreditBureauConfigs] ([Id])
GO
ALTER TABLE [dbo].[CreditBureaux] CHECK CONSTRAINT [ECreditBureau_BusinessBureau]
GO
ALTER TABLE [dbo].[CreditBureaux]  WITH CHECK ADD  CONSTRAINT [ECustomer_CreditBureaux] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditBureaux] CHECK CONSTRAINT [ECustomer_CreditBureaux]
GO
