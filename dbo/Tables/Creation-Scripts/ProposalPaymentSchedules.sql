SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProposalPaymentSchedules](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PaymentNumber] [int] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DueDate] [date] NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PaymentStructure] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[Calculate] [bit] NOT NULL,
	[PaymentType] [nvarchar](28) COLLATE Latin1_General_CI_AS NOT NULL,
	[StartDate] [date] NULL,
	[EndDate] [date] NULL,
	[BeginBalance_Amount] [decimal](16, 2) NOT NULL,
	[BeginBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EndBalance_Amount] [decimal](16, 2) NOT NULL,
	[EndBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Principal_Amount] [decimal](16, 2) NOT NULL,
	[Principal_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Interest_Amount] [decimal](16, 2) NOT NULL,
	[Interest_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ProposalExhibitId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PricingStartDate] [date] NOT NULL,
	[PricingEndDate] [date] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ProposalPaymentSchedules]  WITH CHECK ADD  CONSTRAINT [EProposalExhibit_ProposalPaymentSchedules] FOREIGN KEY([ProposalExhibitId])
REFERENCES [dbo].[ProposalExhibits] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ProposalPaymentSchedules] CHECK CONSTRAINT [EProposalExhibit_ProposalPaymentSchedules]
GO
