SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CustomerBondRatings](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Agency] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[AgencyCustomerName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[AgencyCustomerNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[AsOfDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[BondratingId] [bigint] NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CustomerBondRatings]  WITH CHECK ADD  CONSTRAINT [ECustomer_CustomerBondRatings] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CustomerBondRatings] CHECK CONSTRAINT [ECustomer_CustomerBondRatings]
GO
ALTER TABLE [dbo].[CustomerBondRatings]  WITH CHECK ADD  CONSTRAINT [ECustomerBondRating_BondRating] FOREIGN KEY([BondratingId])
REFERENCES [dbo].[BondRatings] ([Id])
GO
ALTER TABLE [dbo].[CustomerBondRatings] CHECK CONSTRAINT [ECustomerBondRating_BondRating]
GO
