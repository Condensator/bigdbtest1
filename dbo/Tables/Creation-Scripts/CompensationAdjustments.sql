SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CompensationAdjustments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PaymentType] [nvarchar](29) COLLATE Latin1_General_CI_AS NOT NULL,
	[SwapOrSyndicatedFeeIncome_Amount] [decimal](16, 2) NULL,
	[SwapOrSyndicatedFeeIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[RelatedBusinessName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PaymentAmount_Amount] [decimal](16, 2) NOT NULL,
	[PaymentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PaymentDate] [date] NOT NULL,
	[LogDate] [date] NOT NULL,
	[AdditionalComments] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[YTDVolumeAdjustments_Amount] [decimal](16, 2) NULL,
	[YTDVolumeAdjustments_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](9) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NULL,
	[SalesOfficerId] [bigint] NOT NULL,
	[LineofBusinessId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CurrencyType] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CompensationAdjustments]  WITH CHECK ADD  CONSTRAINT [ECompensationAdjustment_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[CompensationAdjustments] CHECK CONSTRAINT [ECompensationAdjustment_Contract]
GO
ALTER TABLE [dbo].[CompensationAdjustments]  WITH CHECK ADD  CONSTRAINT [ECompensationAdjustment_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[CompensationAdjustments] CHECK CONSTRAINT [ECompensationAdjustment_LineofBusiness]
GO
ALTER TABLE [dbo].[CompensationAdjustments]  WITH CHECK ADD  CONSTRAINT [ECompensationAdjustment_SalesOfficer] FOREIGN KEY([SalesOfficerId])
REFERENCES [dbo].[SalesOfficers] ([Id])
GO
ALTER TABLE [dbo].[CompensationAdjustments] CHECK CONSTRAINT [ECompensationAdjustment_SalesOfficer]
GO
