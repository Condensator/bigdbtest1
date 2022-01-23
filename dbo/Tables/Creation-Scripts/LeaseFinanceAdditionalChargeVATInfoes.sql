SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeaseFinanceAdditionalChargeVATInfoes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[VATAmount_Amount] [decimal](16, 2) NOT NULL,
	[VATAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DueDate] [date] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[AdditionalChargeId] [bigint] NOT NULL,
	[LeaseFinanceAdditionalChargeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeaseFinanceAdditionalChargeVATInfoes]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceAdditionalCharge_LeaseFinanceAdditionalChargeVATInfoes] FOREIGN KEY([LeaseFinanceAdditionalChargeId])
REFERENCES [dbo].[LeaseFinanceAdditionalCharges] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LeaseFinanceAdditionalChargeVATInfoes] CHECK CONSTRAINT [ELeaseFinanceAdditionalCharge_LeaseFinanceAdditionalChargeVATInfoes]
GO
ALTER TABLE [dbo].[LeaseFinanceAdditionalChargeVATInfoes]  WITH CHECK ADD  CONSTRAINT [ELeaseFinanceAdditionalChargeVATInfo_AdditionalCharge] FOREIGN KEY([AdditionalChargeId])
REFERENCES [dbo].[AdditionalCharges] ([Id])
GO
ALTER TABLE [dbo].[LeaseFinanceAdditionalChargeVATInfoes] CHECK CONSTRAINT [ELeaseFinanceAdditionalChargeVATInfo_AdditionalCharge]
GO
