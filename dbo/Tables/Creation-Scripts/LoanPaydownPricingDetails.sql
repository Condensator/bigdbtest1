SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanPaydownPricingDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[PaydownAmount_Amount] [decimal](16, 2) NOT NULL,
	[PaydownAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LoanPaydownId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PaydownTemplate] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LoanPaydownPricingDetails]  WITH CHECK ADD  CONSTRAINT [ELoanPaydown_LoanPaydownPricingDetails] FOREIGN KEY([LoanPaydownId])
REFERENCES [dbo].[LoanPaydowns] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LoanPaydownPricingDetails] CHECK CONSTRAINT [ELoanPaydown_LoanPaydownPricingDetails]
GO
