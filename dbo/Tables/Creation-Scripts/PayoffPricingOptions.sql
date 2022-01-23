SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayoffPricingOptions](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PayoffAmount_Amount] [decimal](16, 2) NOT NULL,
	[PayoffAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PayoffId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[TerminationOption] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[DefaultpayoffTemplate] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsSelected] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PayoffPricingOptions]  WITH CHECK ADD  CONSTRAINT [EPayoff_PayoffPricingOptions] FOREIGN KEY([PayoffId])
REFERENCES [dbo].[Payoffs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PayoffPricingOptions] CHECK CONSTRAINT [EPayoff_PayoffPricingOptions]
GO
